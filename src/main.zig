const std = @import("std");
const log = std.log;
const httpz = @import("httpz");

const login = @import("./handler/login.zig").login;
const Global = @import("./domain/global.zig").Global;

pub fn main() !void {
    log.info("🐉 Initialize SeaOrc!", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    var global = Global{.allocator = allocator};
    var server = try httpz.ServerApp(*Global).init(
        allocator, 
        .{
            .port = 5882,
        },
        &global
    );
    defer {
        server.stop();
        server.deinit();
    }
    
    var router = server.router();
    router.post("/login", login);

    // blocks
    try server.listen(); 
}