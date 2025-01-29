const std = @import("std");
const log = std.log;
const json = std.json;
const fmt = std.fmt;
const httpz = @import("httpz");

const Global = @import("../domain/global.zig").Global;
const DBUtils = @import("../database/utils.zig").DBUtils;

pub const AuthMiddleware = struct {
    pub fn auth(global: *Global, req: *httpz.Request, res: *httpz.Response) !i64 {
        if (req.header("authorization")) |bearer| {
            if (bearer.len == 39 and std.mem.startsWith(u8, bearer, "Bearer")) {
                const token = bearer[7..39];
                var buff: [16]u8 = undefined;
                _ = fmt.hexToBytes(&buff, token) catch {
                    res.status = 401; // UNAUTHORIZED
                    try res.json(.{
                        .err = "Bad authorization token!",
                    }, .{});
                    return error.AuthFail;
                }; 

                const uid = DBUtils.getUserIDT(global.dbconn, buff) catch |err| {
                    switch (err) {
                        error.UserNotInDatabase => {
                            res.status = 401; // UNAUTHORIZED
                            try res.json(.{
                                .err = "Bad authorization token!",
                            }, .{});
                            return error.AuthFail;
                        },
                        else => {
                            res.status = 500; // INTERNAL SERVER ERROR
                            try res.json(.{
                                .err = "Internal server error!",
                            }, .{});
                            return error.AuthFail;
                        }
                    }
                };

                return uid;
            }

            // for (0..req.headers.len) |i| {
            //     std.debug.print("`{s}` `{s}` {d}\n", .{req.headers.keys[i], req.headers.values[i], req.headers.values[i].len});
            // } // debug

            res.status = 401; // UNAUTHORIZED
            try res.json(.{
                .err = "Bad authorization token format!",
            }, .{});
            return error.AuthFail;
        }

        res.status = 401; // UNAUTHORIZED
        try res.json(.{
            .err = "No authorization token!",
        }, .{});
        return error.AuthFail;
    }
};