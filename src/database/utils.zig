const std = @import("std");
const log = std.log;
const zqlite = @import("zqlite");

pub const DBUtils = struct {
    pub fn addUser(conn: *zqlite.Conn, username: []const u8, passwordHash: []const u8) ![16]u8 {
        log.debug("🌻 Adding User to DB {s}", .{username});
        var rand_bytes: [16]u8 = undefined;
        std.crypto.random.bytes(&rand_bytes);
        // const hex_rand = std.fmt.bytesToHex(rand_bytes, .lower);
        try conn.exec("insert into users (username, passwordhash, token) values (?1, ?2, ?3)", .{username, passwordHash, &rand_bytes});
        // ^ here, for some reason it has to be a pointer??? otherwise data gets messed up
        // const user_id = conn.lastInsertedRowId();
        // return user_id;
        return rand_bytes;
    }

    pub fn getUserPWHash(conn: *zqlite.Conn, username: []const u8) ![120]u8 {
        const row = try conn.row("select * from users where username = ?1 limit 1", .{username});
        if (row) |user| {
            defer user.deinit();
            const pwhash_hex = user.text(2);
            var res: [120]u8 = undefined;
            @memcpy(&res, pwhash_hex);
            return res;
        } else {
            return error.UserNotInDatabase;
        }
    }

    pub fn getUserID(conn: *zqlite.Conn, username: []const u8) !i64 {
        const row = try conn.row("select * from users where username = ?1 limit 1", .{username});
        if (row) |user| {
            defer user.deinit();
            return user.int(0);
        } else {
            return error.UserNotInDatabase;
        }
    }

    pub fn getUserUsernameID(conn: *zqlite.Conn, allocator: std.mem.Allocator, uid: i64) ![]u8 {
        const row = try conn.row("select * from users where user_id = ?1 limit 1", .{uid});
        if (row) |user| {
            defer user.deinit();
            const len = user.textLen(1);
            const res = try allocator.alloc(u8, len);
            @memcpy(res, user.text(1));
            return res;
        } else {
            return error.UserNotInDatabase;
        }
    }

    pub fn getUserTokenU(conn: *zqlite.Conn, username: []const u8) ![16]u8 {
        const row = try conn.row("select * from users where username = ?1 limit 1", .{username});
        if (row) |user| {
            defer user.deinit();
            var res: [16]u8 = undefined;
            @memcpy(&res, user.blob(3)[0..16]);
            return res;
        } else {
            return error.UserNotInDatabase;
        }
    }

    pub fn getUserIDT(conn: *zqlite.Conn, token: [16]u8) !i64 {
        const row = try conn.row("select * from users where token = ?1 limit 1", .{&token});
        if (row) |user| {
            defer user.deinit();
            return user.int(0);
        } else {
            return error.UserNotInDatabase;
        }
    }
};