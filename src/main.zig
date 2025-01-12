const std = @import("std");
const log = std.log;
const fs = std.fs;
const httpz = @import("httpz");
const zqlite = @import("zqlite");

const login = @import("./handler/login.zig").login;
const Global = @import("./domain/global.zig").Global;

const setupDatabase = @import("./database/setup.zig").setupDatabase;

const DATABASE_FILENAME = "seaorc.sqlite";

pub fn main() !void {
    log.info("🐉 Initialize SeaOrc!", .{});

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
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
    setupDatabase(&conn);

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
    router.post("/login", login);

    // blocks
    try server.listen(); 
}