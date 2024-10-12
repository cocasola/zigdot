const std = @import("std");
const builtin = @import("builtin");
const util = @import("util.zig");

const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const Config = @import("Config.zig");
const Schedule = @import("Schedule.zig");
const Modules = @import("Modules.zig");
const Systems = @import("Systems.zig");

const Instance = @This();

config: *const Config,
allocator: Allocator,
modules: Modules,
resources: AutoHashMap(u32, []u8),
systems: Systems,

pub fn init(allocator: Allocator, config: Config) !Instance {
    var instance = Instance{
        .config = &config,
        .allocator = allocator,
        .resources = undefined,
        .modules = undefined,
        .systems = undefined
    };

    instance.systems = Systems.init(allocator);
    errdefer instance.systems.deinit();

    instance.resources = AutoHashMap(u32, []u8).init(allocator);
    errdefer instance.resources.deinit();

    instance.modules = try Modules.init(allocator, &instance);
    errdefer instance.modules.deinit();

    return instance;
}

pub fn deinit(instance: *Instance) void {
    instance.modules.deinit();

    var iter = instance.resources.valueIterator();
    while (iter.next()) |resource| {
        instance.allocator.free(resource.*);
    }

    instance.resources.deinit();
    instance.systems.deinit();

    instance.* = undefined;
}

pub fn register_resource(instance: *Instance, comptime T: type) !*T {
    const resource = try instance.allocator.alloc(u8, @sizeOf(T));
    errdefer instance.allocator.free(resource);

    if (@typeInfo(type) == .Struct)
        @memcpy(resource, std.mem.toBytes(T{}));

    try instance.resources.putNoClobber(util.typeid(T), resource);

    return @ptrCast(@alignCast(resource));
}

pub fn get_resource(instance: *Instance, comptime T: type) ?*T {
    const bytes = instance.resources.get(util.typeid(T)) orelse return null;
    return @ptrCast(@alignCast(bytes));
}

pub fn register_system(instance: *Instance, system: anytype) !void {
    _ = instance;
    _ = system;
}