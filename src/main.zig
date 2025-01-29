const std = @import("std");
const log = std.log;
const fs = std.fs;
const httpz = @import("httpz");
const zqlite = @import("zqlite");

const Global = @import("./domain/global.zig").Global;
const login = @import("./handler/login.zig").login;
const register = @import("./handler/register.zig").register;
const send = @import("./handler/send.zig").send;
const setupDatabase = @import("./database/setup.zig").setupDatabase;

const DATABASE_FILENAME = "seaorc.sqlite";

pub fn main() !void {
    log.info("🐉 Initialize SeaOrc!", .{});

    // Initialize Allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true
    }){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Setup Paths

    const exe_dir_path = try fs.selfExeDirPathAlloc(allocator);
    defer allocator.free(exe_dir_path);

    const database_path: [:0]u8 = try std.fmt.allocPrintZ(allocator, "{s}/{s}", .{exe_dir_path, DATABASE_FILENAME});
    defer allocator.free(database_path);

    // DATABASE
    log.info("📁 Connecting to DataBase!", .{});
    const flags =  zqlite.OpenFlags.Create | zqlite.OpenFlags.EXResCode;
    var conn = try zqlite.open(database_path, flags);
    defer conn.close();
    try setupDatabase(&conn);

    // Setup Global

    var global = Global{
        .allocator = allocator,
        .dbconn = &conn,
    };
    
    // WEB
    log.info("🌐 Starting WEB Server!", .{});
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
    router.post("/register", register);
    router.post("/login", login);
    router.post("/send", send);

    // blocks
    try server.listen(); 
}