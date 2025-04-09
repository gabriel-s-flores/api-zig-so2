const std = @import("std");
const posix = std.posix;

const Engine = @import("../Engine.zig");

const Self = @This();
socket: posix.socket_t,

pub fn init() !Self {
    const socket = try posix.socket(posix.AF.PACKET, posix.SOCK.RAW, std.mem.nativeToBig(u32, 0x0003));
    return .{ .socket = socket };
}

pub fn engine(self: *Self) Engine {
    return Engine.init(self);
}

// pub fn
