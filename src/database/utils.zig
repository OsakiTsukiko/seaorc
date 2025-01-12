const std = @import("std");
const log = std.log;
const zqlite = @import("zqlite");

pub const DBUtils = struct {
    pub fn addUser(conn: *zqlite.Conn, username: []const u8, passwordHash: []const u8) !i64 {
        log.debug("🌻 Adding User to DB {s}", .{username});
        try conn.exec("insert into users (username, passwordhash) values (?1, ?2)", .{username, passwordHash});
        const user_id = conn.lastInsertedRowId();
        return user_id;
    }

    pub fn getUser(conn: *zqlite.Conn, username: []const u8, passwordHash: []const u8) !i64 {
        const row = try conn.row("select * from users where username = ?1 and passwordhash = ?2 limit 1", .{username, passwordHash});
        if (row) |user| {
            defer user.deinit();
            return user.int(0);
        } else {
            return error.UserNotInDatabase;
        }
    }
};