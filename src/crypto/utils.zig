const std = @import("std");
const crypto = std.crypto;
const argon2 = crypto.pwhash.argon2;
const scrypt = crypto.pwhash.scrypt;
const bcrypt = crypto.pwhash.bcrypt;

pub const CryptoUtils = struct {
    pub fn hashPassword(allocator: std.mem.Allocator, password: []const u8) ![60]u8 {
        var buff: [60]u8 = undefined;
        _ = try bcrypt.strHash(password, .{ .allocator = allocator, .encoding = .crypt, .params = .{ .rounds_log = 10, } }, &buff);
        // maybe return res?
        return buff;
    }

    pub fn verifyPassword(allocator: std.mem.Allocator, password: []const u8, hash: []const u8) !bool {
        bcrypt.strVerify(hash, password, .{ .allocator = allocator }) catch |err| {
            switch (err) {
                crypto.pwhash.HasherError.PasswordVerificationFailed => {
                    return false;
                },
                else => {
                    return err;
                }
            }
        };
        return true;
    }
};