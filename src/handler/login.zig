const std = @import("std");
const log = std.log;
const json = std.json;
const httpz = @import("httpz");

const Global = @import("../domain/global.zig").Global;
const DBUtils = @import("../database/utils.zig").DBUtils;
const CryUtils = @import("../crypto/utils.zig").CryptoUtils;

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
        
        const pwhash_hex = DBUtils.getUserPWHash(global.dbconn, parsed_body.value.username) catch |err| {
            switch (err) {
                error.UserNotInDatabase => {
                    res.status = 401; // UNAUTHORIZED
                    try res.json(.{
                        .err = "Wrong username and password!",
                    }, .{});
                    return;
                },
                else => {
                    log.debug("⚠️  DataBase error on login: {s} {any}", .{parsed_body.value.username, err});
                    res.status = 500; // INTERNAL SERVER ERROR
                    try res.json(.{
                        .err = "Some database error OCCURED!",
                    }, .{});
                    return;
                }
            }
        };

        var pwhash: [60]u8 = undefined;
        _ = try std.fmt.hexToBytes(&pwhash, &pwhash_hex);

        const verif = CryUtils.verifyPassword(global.allocator, parsed_body.value.password, &pwhash) catch {
            log.debug("⚠️  Unable to verify password!: {s} {any}", .{parsed_body.value.username, pwhash.len});
            res.status = 500; // INTERNAL SERVER ERROR
            try res.json(.{
                .err = "Unable to VERIFY password!",
            }, .{});
            return;
        };

        if (verif) {
            const user_id = try DBUtils.getUserID(global.dbconn, parsed_body.value.username);
            res.status = 200; // OK
            try res.json(.{
                .user_id = user_id,
            }, .{});
            return;
        } else {
            res.status = 400; // OK
            try res.json(.{
                .err = "Incorrect Password!",
            }, .{});
            return;
        }
        
    } else { // no body
        res.status = 400; // BAD REQUEST
        try res.json(.{
            .err = "Empty request body!",
        }, .{});
        return;
    }
}