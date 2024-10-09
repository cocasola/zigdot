const std = @import("std");

const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const DepGraph = @import("dep_graph.zig").DepGraph;

const Systems = @This();

const System = struct {
    pub const Callback = *const fn () anyerror!void;

    callback: Callback,
    resources: [][]u8
};

const SystemGroup = struct {
    systems: ArrayList(System)
};

allocator: Allocator,
graph: DepGraph(SystemGroup),

pub fn init(allocator: Allocator) Systems {
    return Systems{
        .graph = DepGraph(SystemGroup).init(allocator),
        .allocator = allocator
    };
}

pub fn deinit(systems: *Systems) void {
    for (systems.graph.walker) |node| {
        for (node.systems.items) |system| {
            systems.allocator.free(system.resources);
        }

        node.systems.deinit();
    }

    systems.graph.deinit();
}