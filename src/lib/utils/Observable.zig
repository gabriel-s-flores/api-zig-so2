const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn Observable(comptime T: type) type {
    return struct {
        // Type Definitions
        const Self = @This();
        pub const Observer = struct {
            ptr: *anyopaque,
            updateFn: *const fn (self: *anyopaque, value: T) void,

            pub fn update(self: *const Observer, value: T) void {
                self.updateFn(self.ptr, value);
            }
        };
        // Fields
        observers: std.ArrayList(*const Observer),

        // Constructor
        pub fn init(allocator: Allocator) Self {
            return .{ .observers = std.ArrayList(*const Observer).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.observers.deinit();
        }

        // Methods
        pub fn addObserver(self: *Self, observer: *const Observer) Allocator.Error!void {
            try self.observers.append(observer);
        }

        pub fn removeObserver(self: *Self, observer: *const Observer) void {
            for (0..self.observers.items.len) |index| {
                if (self.observers.items[index] == observer) {
                    _ = self.observers.orderedRemove(index);
                    break;
                }
            }
        }

        pub fn notify(self: *Self, value: T) bool {
            var some_notified = false;

            for (self.observers.items) |observer| {
                observer.update(value);
                some_notified = true;
            }

            return some_notified;
        }
    };
}

test "can add observers" {
    const testing = std.testing;
    var subject = Observable(f32).init(testing.allocator);
    defer subject.deinit();

    const TestingObserver = struct {
        const Self = @This();
        fn observer(self: *Self) Observable(f32).Observer {
            return .{
                .ptr = self,
                .updateFn = update,
            };
        }
        fn update(self: *anyopaque, value: f32) void {
            _ = value;
            _ = self;
        }
    };
    var testing_observer = TestingObserver{};
    var observer = testing_observer.observer();

    try subject.addObserver(&observer);
    try testing.expect(subject.observers.items.len == 1);
}

test "can remove observers" {
    const testing = std.testing;
    var subject = Observable(f32).init(testing.allocator);
    defer subject.deinit();

    const TestingObserver = struct {
        const Self = @This();
        fn observer(self: *Self) Observable(f32).Observer {
            return .{
                .ptr = self,
                .updateFn = update,
            };
        }
        fn update(self: *anyopaque, value: f32) void {
            _ = value;
            _ = self;
        }
    };
    var testing_observer = TestingObserver{};
    var observer = testing_observer.observer();

    try subject.addObserver(&observer);
    try testing.expect(subject.observers.items.len == 1);

    subject.removeObserver(&observer);
    try testing.expect(subject.observers.items.len == 0);
}

test "can notify observers" {
    const testing = std.testing;
    var subject = Observable(f32).init(testing.allocator);
    defer subject.deinit();

    const TestingObserver = struct {
        const Self = @This();
        notified: bool = false,

        fn observer(self: *Self) Observable(f32).Observer {
            return .{
                .ptr = self,
                .updateFn = update,
            };
        }

        fn update(ptr: *anyopaque, value: f32) void {
            const self: *Self = @ptrCast(@alignCast(ptr));
            self.notified = true;
            std.debug.print("Hey!", .{});
            _ = value;
        }
    };
    var observer: TestingObserver = .{
        .notified = false,
    };
    try subject.addObserver(&observer.observer());
    try testing.expect(subject.observers.items.len == 1);

    _ = subject.notify(0.0);
    try testing.expect(observer.notified);
}
