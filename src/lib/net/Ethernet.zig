const std = @import("std");
const mem = std.mem;
const common = @import("common.zig");

pub const Address = common.Address(6);
pub const MTU = 1500;
pub const EtherType = enum(u16) {
    /// Internet Protocol version 4 (IPv4)
    IP = 0x0800,
    /// Address Resolution Protocol (ARP)
    ARP = 0x0806,
    /// Reverse Address Resolution Protocol (RARP)
    RARP = 0x8035,
    /// Precision Time Protocol (PTP) over IEEE 802.3 Ethernet
    PTP = 0x88f7,
};

pub const Header = extern struct {
    const Self = @This();
    // Type Definitions
    // Private
    destination: Address align(1),
    source: Address align(1),
    /// STORED AS BIG ENDIAN | Specifies the type of protocol used in the payload of the frame
    ether_type: EtherType align(1),

    // Constructors
    pub fn init(destination: Address, source: Address, ether_type: EtherType) Header {
        return Header{
            .destination = destination,
            .source = source,
            .ether_type = mem.nativeToBig(@TypeOf(ether_type), ether_type),
        };
    }

    pub fn etherType(self: Self) EtherType {
        return mem.bigToNative(EtherType, self.protocol);
    }
};

pub const Frame = extern struct {
    const Self = @This();
    // Type Definitions
    const Data = [MTU]u8;
    const CRC32 = u32;
    // Private
    header: Header align(1),
    payload: Data align(1),
    crc: CRC32 align(1),

    // Constructors
    pub fn init(header: Header, payload: []u8) Frame {
        return Frame{
            .header = header,
            .payload = payload,
        };
    }

    // Methods
    pub fn data(self: Self, comptime T: type) *const T {
        return @ptrCast(@alignCast(&self.payload));
    }
};
