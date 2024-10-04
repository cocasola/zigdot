const ArrayList = @import("std").ArrayList;
const StringHashMap = @import("std").StringHashMap;
const Allocator = @import("std").mem.Allocator;

pub const Fn = *const fn (data: *void) anyerror!void;

pub const Callback = struct {
    func: Fn,
    data: *void
};

pub const CallbackGroup = struct {
    callbacks: ArrayList(Callback)
};

pub const LabelledCallback = struct {
    label: []const u8,
    callback: Callback
};

pub fn GenerateSchedule(
    allocator: Allocator,
    callbacks: []LabelledCallback,
    schedule_config: [][][]const u8
) ![]CallbackGroup {
    var schedule = try allocator.alloc(CallbackGroup, schedule_config.len);
    errdefer allocator.free(schedule);

    var map = StringHashMap(usize).init(allocator);
    defer map.deinit();

    for (0..schedule.len) |i| {
        schedule[i].callbacks = ArrayList(Callback).init(allocator);

        for (schedule_config[i]) |label| {
            try map.put(label, i);
        }
    }

    for (callbacks) |callback| {
        const i = map.get(callback.label) orelse continue;
        try schedule[i].callbacks.append(callback.callback);
    }

    return schedule;
}