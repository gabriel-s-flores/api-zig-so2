const std = @import("std");
const Allocator = std.mem.Allocator;

pub fn ConditionallyObservable(comptime T: type, comptime C: type) type {
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

        pub const ObserversElement = struct {
            rank: C,
            el: *const Observer,
        };
        // Fields
        observers: std.ArrayList(ObserversElement),

        // Constructor
        pub fn init(allocator: Allocator) Self {
            return .{ .observers = std.ArrayList(ObserversElement).init(allocator) };
        }

        pub fn deinit(self: *Self) void {
            self.observers.deinit();
        }

        // Methods
        pub fn addObserver(self: *Self, observer: *const Observer, condition: C) Allocator.Error!void {
            try self.observers.append(.{ .el = observer, .rank = condition });
        }

        pub fn removeObserver(self: *Self, observer: *const Observer) void {
            for (0..self.observers.items.len) |index| {
                if (self.observers.items[index].el == observer) {
                    _ = self.observers.orderedRemove(index);
                    break;
                }
            }
        }

        pub fn notify(self: *Self, value: T, condition: ?C) bool {
            var some_notified = false;

            for (self.observers.items) |observerElement| {
                // Invert logic to act as a guard clause
                if (condition != null and observerElement.rank != condition) continue;
                const observer = observerElement.el;
                observer.update(value);
                some_notified = true;
            }

            return some_notified;
        }
    };
}

test "can add observers" {
    const testing = std.testing;
    var subject = ConditionallyObservable(f32, u8).init(testing.allocator);
    defer subject.deinit();

    const TestingObserver = struct {
        const Self = @This();
        fn observer(self: *Self) ConditionallyObservable(f32, u8).Observer {
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

    try subject.addObserver(&observer, 5);
    try testing.expect(subject.observers.items.len == 1);
}

test "can remove observers" {
    const testing = std.testing;
    const ISubject = ConditionallyObservable(f32, u8);
    var subject = ISubject.init(testing.allocator);
    defer subject.deinit();

    const TestingObserver = struct {
        const Self = @This();
        fn observer(self: *Self) ISubject.Observer {
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

    try subject.addObserver(&observer, 5);
    try testing.expect(subject.observers.items.len == 1);

    subject.removeObserver(&observer);
    try testing.expect(subject.observers.items.len == 0);
}

test "can conditionally notify observers" {
    const testing = std.testing;
    const ISubject = ConditionallyObservable(f32, u8);
    var subject = ISubject.init(testing.allocator);
    defer subject.deinit();

    const TestingObserver = struct {
        const Self = @This();
        notified: bool = false,
        expected: u8,

        fn observer(self: *Self) ISubject.Observer {
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
    var observer1: TestingObserver = .{
        .expected = 1,
        .notified = false,
    };
    var observer2: TestingObserver = .{
        .expected = 2,
        .notified = false,
    };

    try subject.addObserver(&observer1.observer(), observer1.expected);
    try subject.addObserver(&observer2.observer(), observer2.expected);
    try testing.expect(subject.observers.items.len == 2);

    _ = subject.notify(0.0, 1);
    try testing.expect(observer1.notified);
    try testing.expect(!observer2.notified);
}
