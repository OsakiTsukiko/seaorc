const std = @import("std");
const log = std.log;
const json = std.json;
const httpz = @import("httpz");

const Global = @import("../domain/global.zig").Global;
const DBUtils = @import("../database/utils.zig").DBUtils;

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
        
        // TODO: HASH PASSWORD!!!!
        const user_id = DBUtils.getUser(global.dbconn, parsed_body.value.username, parsed_body.value.password) catch |err| {
            switch (err) {
                error.UserNotInDatabase => {
                    res.status = 401; // UNAUTHORIZED
                    try res.json(.{
                        .err = "WRONG USERNAME or PASSWORD!",
                    }, .{});
                    return;
                },
                else => {
                    log.debug("⚠️  DATABASE ERROR on LOGIN: {s} {any}", .{parsed_body.value.username, err});
                    res.status = 500; // INTERNAL SERVER ERROR
                    try res.json(.{
                        .err = "Some database error OCCURED!",
                    }, .{});
                    return;
                }
            }
        };
        
        res.status = 200; // OK
        try res.json(.{
            .user_id = user_id,
        }, .{});
        return;
    } else { // no body
        res.status = 400; // BAD REQUEST
        try res.json(.{
            .err = "Empty request body!",
        }, .{});
        return;
    }
}