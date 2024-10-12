const std = @import("std");

const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const DepGraph = @import("dep_graph.zig").DepGraph;
const Instance = @import("Instance.zig");

const Systems = @This();

pub const System = struct {
    after: []type,
    callback: *void
};

const RegisteredSystem = struct {
    pub const Callback = *const fn () anyerror!void;

    callback: Callback,
    resources: [][]u8
};

allocator: Allocator,
graph: DepGraph(RegisteredSystem),

pub fn init(allocator: Allocator) Systems {
    return Systems{
        .graph = DepGraph(RegisteredSystem).init(allocator),
        .allocator = allocator
    };
}

pub fn register_system(systems: *Systems, instance: *Instance, comptime T: type) !void {
    _ = systems;
    _ = instance;
    _ = T;
}

pub fn deinit(systems: *Systems) void {
    for (systems.graph.walker) |node| {
        systems.allocator.free(node.resources);
    }

    systems.graph.deinit();

    systems.* = undefined;
}