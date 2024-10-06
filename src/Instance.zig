const std = @import("std");
const builtin = @import("builtin");
const util = @import("util.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Config = @import("Config.zig");
const Module = @import("Module.zig");
const Schedule = @import("Schedule.zig");

schedule: Schedule,
config: *const Config,
allocator: Allocator,
modules: AutoHashMap(u32, Module),

const Instance = @This();

pub fn init(allocator: Allocator, config: Config) !Instance {
    var modules = AutoHashMap(u32, Module).init(allocator);
    errdefer modules.deinit();

    var schedule = try Schedule.init(allocator, config.schedule);
    errdefer schedule.deinit();

    var instance = Instance{
        .schedule = schedule,
        .config = &config,
        .allocator = allocator,
        .modules = modules
    };

    try Module.init_all(&instance);

    return instance;
}

pub fn deinit(this: *Instance) void {
    Module.deinit_all(this);

    var module_iter = this.modules.valueIterator();
    while (module_iter.next()) |module| {
        this.allocator.free(module.data);
    }
    this.modules.deinit();

    this.schedule.deinit();
}

pub fn register_callback(this: *Instance, callback: Schedule.CallbackPtr, label: []const u8, data: *anyopaque) !bool {
    return try this.schedule.register_callback(callback, label, data);
}

pub fn get_module(this: *Instance, comptime T: type) ?*T {
    const module = this.modules.get(util.typeid(T)) orelse return null;
    return @ptrCast(@alignCast(module.data.ptr));
}