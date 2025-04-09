const std = @import("std");
const mem = std.mem;

pub fn Address(comptime bytes: comptime_int) type {
    return extern struct {
        // Default Structures
        const Self = @This();
        pub const Null = Self{
            .address = 0x00,
        };
        pub const Broadcast = Self{
            .address = 0xFF ** bytes,
        };
        // Private
        address: [bytes]u8 align(1) = .{0} ** bytes,

        // Constructors
        pub fn init() Self {
            return {};
        }

        // Methods
        pub fn eql(self: Self, other: Self) bool {
            return mem.eql(self.address, other.address);
        }

        pub fn neq(self: Self, other: Self) bool {
            return !mem.eql(self.address, other.address);
        }

        pub fn bitwiseAnd(self: Self, other: Self) Self {
            const result = Self.init();
            for (0..bytes) |i| {
                result.address[i] = self.address[i] & other.address[i];
            }
            return result;
        }

        pub fn bitwiseOr(self: Self, other: Self) Self {
            const result = Self.init();
            for (0..bytes) |i| {
                result.address[i] = self.address[i] | other.address[i];
            }
            return result;
        }

        pub fn some(self: Self) bool {
            for (self.address) |byte| {
                if (byte != 0) return true;
            }

            return false;
        }
    };
}
