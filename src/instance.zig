const std = @import("std");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

const schedule = @import("schedule.zig");

const Config = @import("config.zig").Config;
const ConfigFromFile = @import("config.zig").ConfigFromFile;

pub const Instance = struct {
    schedule: []schedule.CallbackGroup,
    allocator: Allocator,

    const Self = @This();

    pub fn init(allocator: Allocator, lim_config: Config, callbacks: []schedule.LabelledCallback) !Self {
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
