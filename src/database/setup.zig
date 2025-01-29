const std = @import("std");
const zqlite = @import("zqlite");

pub fn setupDatabase(conn: *zqlite.Conn) !void {
    try conn.exec(
        \\create table if not exists users (
        \\user_id integer primary key autoincrement,
        \\username text not null,
        \\passwordhash text not null,
        \\token blob not null,
        \\constraint unique_username unique(username)
        \\constraint unique_token unique(token)
        \\)
    , .{});

    try conn.exec(
        \\create table if not exists messages (
        \\message_id integer primary key autoincrement,
        \\receiver_id integer not null,
        \\sender text not null,
        \\timestamp integer not null,
        \\message text not null,
        \\foreign key (receiver_id) references users(user_id)
        \\);
        \\
        \\
        \\create index if not exists idx_receiver_id on messages(receiver_id);
    , .{});
}