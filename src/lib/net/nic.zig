const std = @import("std");
const Ethernet = @import("Ethernet.zig");
const Engine = @import("Engine.zig");

pub fn NIC(comptime EngineConcrete: type) type {
    return struct {
        // Type Definitions
        const Self = @This();
        const BUFFER_SIZE = 128 * @sizeOf(Ethernet.Frame);
        const Address = Ethernet.Address;
        const Buffer = Ethernet.Frame;
        const ProtocolNumber = Ethernet.EtherType;
        // Properties
        _engine: Engine = EngineConcrete.init().engine(),
        _address: Address = Address.Broadcast,
        _buffer: [BUFFER_SIZE]Ethernet.Frame = undefined,
        _buffer_allocator: *std.mem.Allocator = undefined,
        // Constructor
        pub fn init() Self {
            const self = Self{};
            self._buffer_allocator = std.heap.FixedBufferAllocator.init(&self._buffer);

            return self;
        }
        // Methods
        pub fn address(self: Self) Address {
            return self._address;
        }

        pub fn setAddress(self: Self, addr: Address) void {
            self._address = addr;
        }

        pub fn alloc(self: Self, destination: Address, protocol: ProtocolNumber, size: u32) !*const Buffer {
            // return self._engine.alloc(destination, protocol, size);
            _ = size;
            const frame_buf = try self._buffer_allocator.alloc(Ethernet.Frame, 1);
            frame_buf[0] = Ethernet.Frame.init(Ethernet.Header.init(destination, self._address, protocol), undefined);
            return frame_buf[0];
        }
        pub fn free(self: Self) void {
            return self._engine.free();
        }
        pub fn send(self: Self, buffer: Buffer) void {
            return self._engine.send(buffer);
        }
        pub fn receive(self: Self, buffer: Buffer, source: Address, destination: Address, data: [*]u8, size: u32) void {
            return self._engine.receive(buffer, source, destination, data, size);
        }
    };
}
