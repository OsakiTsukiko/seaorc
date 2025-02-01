const std = @import("std");
const log = std.log;
const json = std.json;
const fmt = std.fmt;
const httpz = @import("httpz");

const Global = @import("../domain/global.zig").Global;
const DBUtils = @import("../database/utils.zig").DBUtils;

const AuthMiddleware = @import("../middleware/auth.zig").AuthMiddleware;

pub const Message = struct {
    sender: []const u8,
    timestamp: i64,
    content: []const u8,
};

pub fn receive(global: *Global, req: *httpz.Request, res: *httpz.Response) !void {
    const uid = AuthMiddleware.auth(global, req, res) catch |err| switch (err) {
        error.AuthFail => {
            return;
        },
        else => { return err; }
    };

    var messages = try DBUtils.getMessages(global.dbconn, global.allocator, uid);
    defer {
        for (messages.items) |msg| {
            msg.deinit();
        }

        messages.deinit();
    }

    var list = std.ArrayList(Message).init(global.allocator);
    defer list.deinit();

    for (messages.items) |msg| {
        try list.append(Message {
            .sender = msg.sender,
            .timestamp = msg.timestamp,
            .content = msg.message,
        });
    }

    res.status = 200; // OK
    try res.json(.{
        .messages = list.items,
    }, .{});

    return;
}