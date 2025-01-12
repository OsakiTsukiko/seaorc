const std = @import("std");
const zqlite = @import("zqlite");

pub const Global = struct {
    allocator: std.mem.Allocator,
    dbconn: *zqlite.Conn,
};