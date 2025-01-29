const std = @import("std");
const log = std.log;
const json = std.json;
const fmt = std.fmt;
const httpz = @import("httpz");

const Global = @import("../domain/global.zig").Global;
const DBUtils = @import("../database/utils.zig").DBUtils;

const AuthMiddleware = @import("../middleware/auth.zig").AuthMiddleware;

const SendBody = struct {
    receiver: []const u8,
    message: []const u8,
};

pub fn send(global: *Global, req: *httpz.Request, res: *httpz.Response) !void {
    const uid = AuthMiddleware.auth(global, req, res) catch |err| switch (err) {
        error.AuthFail => {
            return;
        },
        else => { return err; }
    };

    if (req.body()) |body| {
        const parsed_body = json.parseFromSlice(
            SendBody, 
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

        if (parsed_body.value.receiver.len > 32) {
            res.status = 400; // BAD REQUEST
            try res.json(.{
                .err = "Receiver username too long!",
            }, .{});
            return;
        }

        if (parsed_body.value.message.len > 3000) {
            res.status = 400; // BAD REQUEST
            try res.json(.{
                .err = "Message too long!",
            }, .{});
            return;
        }

        const sender = try DBUtils.getUserUsernameID(global.dbconn, global.allocator, uid);
        defer global.allocator.free(sender);
        
        const receiver_id = DBUtils.getUserID(global.dbconn, parsed_body.value.receiver) catch |err| switch (err) {
            error.UserNotInDatabase => {
                res.status = 400; // BAD REQUEST
                try res.json(.{
                    .err = "Receiver does not exist!",
                }, .{});
                return;
            },
            else => { return err; }
        };

        std.debug.print("{d} -> {d} : {s}\n", .{uid, receiver_id, parsed_body.value.message});

        res.status = 200; // OK
        try res.json(.{
            .msg = "Message sent successfully!",
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