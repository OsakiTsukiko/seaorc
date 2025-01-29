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

    // MESSAGES

    pub fn addMessage(conn: *zqlite.Conn, receiver_id: i64, sender: []const u8, message: []const u8) !i64 {
        log.debug("✉️  Adding Message to DB from {s}", .{sender});
        
        const timestamp = std.time.timestamp();

        try conn.exec("insert into messages (receiver_id, sender, timestamp, message) values (?1, ?2, ?3, ?4)", .{receiver_id, sender, timestamp, message});
        const msg_id = conn.lastInsertedRowId();
        return msg_id;
    }

    pub const Message = struct {
        allocator: std.mem.Allocator,
        sender: []const u8,
        timestamp: i64,
        message: []const u8,

        pub fn new(allocator: std.mem.Allocator, sender: []const u8, timestamp: i64, message: []const u8) !Message {
            return Message {
                .allocator = allocator,
                .sender = try allocator.dupe(u8, sender),
                .timestamp = timestamp,
                .message = try allocator.dupe(u8, message),  
            };
        }

        pub fn deinit(self: *const Message) void {
            self.allocator.free(self.sender);
            self.allocator.free(self.message);
        }
    };

    pub fn getMessages(conn: *zqlite.Conn, allocator: std.mem.Allocator, uid: i64) !std.ArrayList(Message) {
        var rows = try conn.rows("select * from messages where receiver_id = ?1", .{uid});
        defer rows.deinit();

        var res = std.ArrayList(Message).init(allocator);
        
        while (rows.next()) |row| {
            const sender = row.text(2);
            const timestamp = row.int(3);
            const message = row.text(4);

            const msg = try Message.new(allocator, sender, timestamp, message);
            try res.append(msg);
        }

        try conn.exec("delete from messages where receiver_id = ?1", .{uid});

        return res;
    }

};