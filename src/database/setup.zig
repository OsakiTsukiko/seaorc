const std = @import("std");
const zqlite = @import("zqlite");

pub fn setupDatabase(conn: *zqlite.Conn) !void {
    try conn.exec(
        \\create table if not exists users (
        \\user_id integer primary key autoincrement,
        \\username text not null,
        \\passwordhash text not null,
        \\constraint unique_username unique(username)
        \\)
    , .{});
}