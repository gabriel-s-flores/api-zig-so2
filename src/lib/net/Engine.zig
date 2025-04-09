const Ethernet = @import("Ethernet.zig");

/// Engine is an Interface that handles the actual differences between the different network drivers.
/// Represents an Interface in the following format
/// ```
/// interface Engine {
///    u8[] alloc(Address dst, Protocol_Number protocol, usize size);
///    void free(u8[] buffer);
///    int send(u8[] buffer);
///    int receive(u8[] buffer, Address src, Address dst, u8[] data, usize size);
/// }
/// ```
const Self = @This();
const Buffer = []u8;

ptr: *anyopaque,
_allocFn: *const fn (self: *anyopaque, dst: Ethernet.Address, protocol: Ethernet.EtherType, size: usize) Buffer,
_freeFn: *const fn (self: *anyopaque, buffer: Buffer) void,
_sendFn: *const fn (self: *anyopaque, buffer: Buffer) usize,
_receiveFn: *const fn (self: *anyopaque, buffer: Buffer, src: Ethernet.Address, dst: Ethernet.Address, data: Buffer, size: usize) usize,

pub fn init(ptr: anytype) Self {
    const T = @TypeOf(ptr);
    const ptr_info = @typeInfo(@TypeOf(ptr));
    if (ptr_info != .Pointer) @compileError("ptr must be a pointer");
    if (ptr_info.Pointer.size != .One) @compileError("ptr must be a single item pointer");

    const impl = struct {
        pub fn alloc(pointer: *anyopaque, dst: Ethernet.Address, protocol: Ethernet.EtherType, size: usize) Buffer {
            const self: T = @ptrCast(@alignCast(pointer));
            return @call(.always_inline, ptr_info.pointer.child.alloc, .{ self, dst, protocol, size });
        }
        pub fn free(pointer: *anyopaque, buffer: Buffer) void {
            const self: T = @ptrCast(@alignCast(pointer));
            return @call(.always_inline, ptr_info.pointer.child.free, .{ self, buffer });
        }
        pub fn send(pointer: *anyopaque, buffer: Buffer) usize {
            const self: T = @ptrCast(@alignCast(pointer));
            return @call(.always_inline, ptr_info.pointer.child.send, .{ self, buffer });
        }
        pub fn receive(pointer: *anyopaque, buffer: Buffer, src: Ethernet.Address, dst: Ethernet.Address, data: Buffer, size: usize) usize {
            const self: T = @ptrCast(@alignCast(pointer));
            return @call(.always_inline, ptr_info.pointer.child.receive, .{ self, buffer, src, dst, data, size });
        }
    };

    return .{
        .ptr = ptr,
        ._allocFn = impl.alloc,
        ._freeFn = impl.free,
        ._sendFn = impl.send,
        ._receiveFn = impl.receive,
    };
}

pub fn alloc(self: Self, dst: Ethernet.Address, protocol: Ethernet.EtherType, size: usize) Buffer {
    return self._allocFn(self, dst, protocol, size);
}

pub fn free(self: Self, buffer: Buffer) void {
    return self._freeFn(self, buffer);
}

pub fn send(self: Self, buffer: Buffer) usize {
    return self._sendFn(self, buffer);
}
pub fn receive(self: Self, buffer: Buffer, src: Ethernet.Address, dst: Ethernet.Address, data: Buffer, size: usize) usize {
    return self._receiveFn(self, buffer, src, dst, data, size);
}
