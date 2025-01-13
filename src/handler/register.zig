const std = @import("std");
const log = std.log;
const json = std.json;
const httpz = @import("httpz");

const Global = @import("../domain/global.zig").Global;
const DBUtils = @import("../database/utils.zig").DBUtils;
const CryUtils = @import("../crypto/utils.zig").CryptoUtils;

const RegisterBody = struct {
    username: []const u8,
    password: []const u8,
};

pub fn register(global: *Global, req: *httpz.Request, res: *httpz.Response) !void {
    if (req.body()) |body| { // if has body
        // parse body
        const parsed_body = json.parseFromSlice(
            RegisterBody, 
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

        const pwhash = CryUtils.hashPassword(global.allocator, parsed_body.value.password) catch {
            res.status = 500; // INTERNAL SERVER ERROR
            try res.json(.{
                .err = "Unable to HASH password!",
            }, .{});
            return;
        };

        const pwhash_hex = std.fmt.bytesToHex(pwhash, .lower);

        const user_id = DBUtils.addUser(global.dbconn, parsed_body.value.username, &pwhash_hex) catch |err| {
            switch (err) {
                error.ConstraintUnique => {
                    res.status = 400; // BAD REQUEST
                    try res.json(.{
                        .err = "USERNAME already REGISTERED!",
                    }, .{});
                    return;
                },
                else => {
                    log.debug("⚠️  UNABLE TO ADD USER {s} TO DB: {any}", .{parsed_body.value.username, err});
                    res.status = 500; // INTERNAL SERVER ERROR
                    try res.json(.{
                        .err = "Unable to create user!",
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