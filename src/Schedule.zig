const std = @import("std");

const ArrayList = std.ArrayList;
const StringHashMap = std.StringHashMap;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

pub fn CallbackPtrGeneric(comptime T: type) type { return *const fn (data: *T) anyerror!void; }
pub const CallbackPtr = CallbackPtrGeneric(anyopaque);

const Callback = struct {
    func: *const fn (data: *anyopaque) anyerror!void,
    data: *anyopaque
};

callbacks: []ArrayList(Callback),
label_map: StringHashMap(usize),
allocator: Allocator,

const Schedule = @This();

pub fn init(
    allocator: Allocator,
    schedule_config: [][][]const u8
) !Schedule {
    const callbacks = try allocator.alloc(ArrayList(Callback), schedule_config.len);
    errdefer allocator.free(callbacks);

    for (callbacks) |*group| {
        group.* = ArrayList(Callback).init(allocator);
    }
    errdefer for (callbacks) |*group| {
        group.deinit();
    };

    var label_map = StringHashMap(usize).init(allocator);
    errdefer label_map.deinit();

    for (schedule_config, 0..) |group, i| {
        for (group) |label| {
            try label_map.putNoClobber(label, i);
        }
    }

    return Schedule{
        .callbacks = callbacks,
        .label_map = label_map,
        .allocator = allocator
    };
}

pub fn run(this: *Schedule) !void {
    for (this.callbacks) |group| {
        for (group.items) |callback| {
            try callback.func(callback.data);
        }
    }
}

pub fn register_callback(this: *Schedule, callback: CallbackPtr, label: []const u8, data: *anyopaque) !bool {
    if (this.label_map.get(label)) |group| {
        try this.callbacks[group].append(Callback{ .func = callback, .data = data });
        return true;
    } else {
        return false;
    }
}

pub fn deinit(this: *Schedule) void {
    for (this.callbacks) |*group| {
        group.deinit();
    }
    this.allocator.free(this.callbacks);

    this.label_map.deinit();
}