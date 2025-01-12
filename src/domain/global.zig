const std = @import("std");

pub const Global = struct {
    allocator: std.mem.Allocator,
};