const std = @import("std");
const log = std.log;
const json = std.json;
const httpz = @import("httpz");

const Global = @import("../domain/global.zig").Global;

const LoginBody = struct {
    username: []const u8,
    password: []const u8,
};

pub fn login(global: *Global, req: *httpz.Request, res: *httpz.Response) !void {
    if (req.body()) |body| { // if has body
        // parse body
        const parsed_body = json.parseFromSlice(
            LoginBody, 
            global.allocator, 
            body, 
            .{}
        ) catch {
            // parse error
            // TODO: maybe add a switch?
            // error.SyntaxError
            // error.UnknownField
            // error.MissingField
            
            res.status = 400; // BAD REQUEST
            try res.json(.{
                .err = "Bad request body!",
            }, .{});
            return;
        };
        defer parsed_body.deinit();

        std.debug.print("USER: {s} {s}\n", .{parsed_body.value.username, parsed_body.value.password});
    } else { // no body
        res.status = 400; // BAD REQUEST
        try res.json(.{
            .err = "Empty request body!",
        }, .{});
        return;
    }
}