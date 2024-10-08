const std = @import("std");
const builtin = @import("builtin");
const util = @import("util.zig");

const Allocator = std.mem.Allocator;
const AutoHashMap = std.AutoHashMap;
const Config = @import("Config.zig");
const Schedule = @import("Schedule.zig");
const ModuleGraph = @import("ModuleGraph.zig");

const Instance = @This();

config: *const Config,
allocator: Allocator,
modules: ModuleGraph,
resources: AutoHashMap(u32, []u8),

pub fn init(allocator: Allocator, config: Config) !Instance {
    var instance = Instance{
        .config = &config,
        .allocator = allocator,
        .resources = undefined,
        .modules = undefined
    };

    instance.resources = AutoHashMap(u32, []u8).init(allocator);
    errdefer instance.resources.deinit();

    instance.modules = try ModuleGraph.init(allocator, &instance);
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
}

pub fn create_resource(instance: *Instance, comptime T: type) !*T {
    const resource = try instance.allocator.create(T);
    errdefer instance.allocator.destroy(resource);

    if (@typeInfo(type) == .Struct)
        resource.* = T{};

    instance.resources.putNoClobber(util.typeid(T), std.mem.asBytes(resource));

    return resource;
}

pub fn get_resource(instance: *Instance, comptime T: type) ?*T {
    const bytes = instance.resources.get(util.typeid(T)) orelse return null;
    return @ptrCast(@alignCast(bytes));
}