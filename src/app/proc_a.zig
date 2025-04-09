const ass = @import("ass_lib");
const std = @import("std");
const NIC = ass.NIC;
const RawSocketsEngine = ass.RawSocketsEngine;

const MyNic = NIC.NIC(RawSocketsEngine);
pub fn main() !void {
    const nic = MyNic.init();
    _ = nic;
    std.debug.print("Hello, World!", .{});
}
