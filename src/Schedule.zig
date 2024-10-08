const std = @import("std");

// const ArrayList = std.ArrayList;
// const StringHashMap = std.StringHashMap;
// const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;

const Schedule = @This();

// pub fn CallbackPtrGeneric(comptime T: type) type { return *const fn (data: *T) anyerror!void; }
// pub const CallbackPtr = CallbackPtrGeneric(anyopaque);
//
// const Callback = struct {
//     func: *const fn (data: *anyopaque) anyerror!void,
//     data: *anyopaque
// };
//
// callbacks: []ArrayList(Callback),
// allocator: Allocator,

pub fn init(allocator: Allocator) !Schedule {

    _ = allocator;
    return undefined;

    //
    // for (callbacks) |*group| {
    //     group.* = ArrayList(Callback).init(allocator);
    // }
    // errdefer for (callbacks) |*group| {
    //     group.deinit();
    // };
    //
    // var label_map = StringHashMap(usize).init(allocator);
    // errdefer label_map.deinit();
    //
    // for (schedule_config, 0..) |group, i| {
    //     for (group) |label| {
    //         try label_map.putNoClobber(label, i);
    //     }
    // }
    //
    // return Schedule{
    //     .callbacks = callbacks,
    //     .label_map = label_map,
    //     .allocator = allocator
    // };
}

pub fn run(this: *Schedule) !void {
    _ = this;
    // for (this.callbacks) |group| {
    //     for (group.items) |callback| {
    //         try callback.func(callback.data);
    //     }
    // }
}

pub fn deinit(this: *Schedule) void {
    _ = this;

    // for (this.callbacks) |*group| {
    //     group.deinit();
    // }
    // this.allocator.free(this.callbacks);
}