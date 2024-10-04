const std = @import("std");
const builtin = @import("builtin");

pub const window = @import("window.zig");
pub const schedule = @import("schedule.zig");
pub const config = @import("config.zig");

const Allocator = std.mem.Allocator;
const GPA = std.heap.GeneralPurposeAllocator;
const ArrayList = std.ArrayList;
const Config = config.Config;

pub const Instance = struct {
    schedule: []schedule.CallbackGroup,
    allocator: Allocator,

    const Self = @This();

    pub fn init(allocator: Allocator, lim_config: anytype, callbacks: []schedule.LabelledCallback) !Self {
        var callbacks_list = ArrayList(schedule.LabelledCallback).init(allocator);
        try callbacks_list.appendSlice(callbacks);

        const all_callbacks = try callbacks_list.toOwnedSlice();
        defer allocator.free(all_callbacks);

        return Instance{
            .allocator = allocator,
            .schedule = try schedule.GenerateSchedule(
                allocator,
                all_callbacks,
                lim_config.schedule
            )
        };
    }

    pub fn run_schedule(this: *Self) !void {
        for (this.schedule) |callback_group| {
            for (callback_group) |callback| {
                try callback.func(callback.data);
            }
        }
    }

    pub fn deinit(this: *Self) void {
        for (this.schedule) |*group| {
            group.callbacks.deinit();
        }

        this.allocator.free(this.schedule);
    }
};

test "playground" {
    var gpa = GPA(.{}){};
    const allocator = gpa.allocator();
    defer if (gpa.deinit() == std.heap.Check.leak) unreachable;

    var lim_config = try Config(.{ .from_file = true }).init(allocator);
    defer lim_config.deinit();

    var instance = try Instance.init(allocator, lim_config, &.{});
    defer instance.deinit();
}