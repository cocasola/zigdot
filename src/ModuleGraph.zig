const std = @import("std");
const util = @import("util.zig");
const module_tree = @import("module_tree.zig");

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const Instance = @import("Instance.zig");
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;

const ModuleGraph = @This();

fn Init(comptime T: type) type {
    return *const fn (instance: *Instance) anyerror!?*T;
}

fn Deinit(comptime T: type) type {
    return *const fn (data: *T) void;
}

pub const Node = struct {
    typeid: u32,
    name: []const u8,
    init: Init(void),
    deinit: ?Deinit(void),
    data: ?*void,
    deps: ArrayList(*Node),
    dependees: ArrayList(*Node),
    initialized: bool,
    deinitialized: bool
};

const Error = error {
    CyclicDependency
};

arena: ArenaAllocator,
nodes: ArrayList(Node),
root_nodes: ArrayList(*Node),
init_order: ArrayList(*Node),

fn build_graph(graph: *ModuleGraph) !void {
    const allocator = graph.arena.allocator();

    var type_map = AutoHashMap(u32, *Node).init(allocator);
    defer type_map.deinit();

    inline for (@typeInfo(module_tree).Struct.decls) |group_decl| {
        const group = @field(module_tree, group_decl.name);

        inline for (@typeInfo(group).Struct.decls) |module_decl| {
            const Module = @field(group, module_decl.name);

            if (!@hasDecl(Module, "init"))
                continue;

            const module_ret_type = @typeInfo(@TypeOf(Module.init)).Fn.return_type.?;
            const payload_type = @typeInfo(module_ret_type).ErrorUnion.payload;
            const module_inner_ret_type = @typeInfo(payload_type).Pointer.child;

            const p_init: Init(module_inner_ret_type) = Module.init;
            const p_deinit: ?Deinit(module_inner_ret_type) = if (@hasDecl(Module, "deinit")) Module.deinit else null;

            try graph.nodes.append(Node{
                .init = @ptrCast(p_init),
                .deinit = @ptrCast(p_deinit),
                .data = null,
                .name = @typeName(Module),
                .typeid = util.typeid(Module),
                .dependees = ArrayList(*Node).init(allocator),
                .deps = ArrayList(*Node).init(allocator),
                .initialized = false,
                .deinitialized = false
            });

            const node = &graph.nodes.items[graph.nodes.items.len - 1];

            if (!@hasDecl(Module, "deps"))
                try graph.root_nodes.append(node);

            type_map.putNoClobber(util.typeid(Module), node) catch |err| {
                std.log.err("Module {s} already exists.", .{ @typeName(Module) });
                return err;
            };
        }
    }

    inline for (@typeInfo(module_tree).Struct.decls) |group_decl| {
        const group = @field(module_tree, group_decl.name);

        inline for (@typeInfo(group).Struct.decls) |module_decl| {
            const Module = @field(group, module_decl.name);

            if (!@hasDecl(Module, "init") or !@hasDecl(Module, "deps"))
                continue;

            const node = type_map.get(util.typeid(Module)).?;

            const deps: []type = Module.deps;

            inline for (deps) |dep| {
                const dep_node = type_map.get(util.typeid(dep)).?;
                try dep_node.dependees.append(node);
                try node.deps.append(dep_node);
            }
        }
    }
}

fn init_recursive(node: *Node, instance: *Instance, init_order: *ArrayList(*Node)) !void {
    node.data = try node.init(instance);
    node.initialized = true;
    try init_order.append(node);

    outer: for (node.dependees.items) |dependee| {
        if (dependee.initialized == true)
            continue;

        for (dependee.deps.items) |dep| {
            if (!dep.initialized)
                continue :outer;
        }

        try init_recursive(dependee, instance, init_order);
    }
}

fn init_modules(graph: *ModuleGraph, instance: *Instance) !void {
    for (graph.root_nodes.items) |node| {
        try init_recursive(node, instance, &graph.init_order);
    }
}

fn verify(graph: *ModuleGraph) !void {
    for (graph.nodes.items) |node| {
        if (!node.initialized) {
            std.log.err("Could not initialize {s}, cyclic dependency present.", .{ node.name });
            return Error.CyclicDependency;
        }
    }
}

fn deinit_modules(graph: *ModuleGraph) void {
    var i: usize = graph.init_order.items.len;
    while (i > 0) {
        i -= 1;

        const node = graph.init_order.items[i];
        if (node.deinit) |deinit_node| {
            if (node.data) |data| {
                deinit_node(data);
            }
        }
    }
}

pub fn init(allocator: Allocator, instance: *Instance) !ModuleGraph {
    var arena = ArenaAllocator.init(allocator);
    errdefer arena.deinit();

    var graph = ModuleGraph{
        .arena = arena,
        .init_order = ArrayList(*Node).init(arena.allocator()),
        .nodes = ArrayList(Node).init(arena.allocator()),
        .root_nodes = ArrayList(*Node).init(arena.allocator())
    };

    try graph.build_graph();
    try graph.init_modules(instance);
    try graph.verify();

    return graph;
}

pub fn deinit(graph: *ModuleGraph) void {
    graph.deinit_modules();

    graph.arena.deinit();
}