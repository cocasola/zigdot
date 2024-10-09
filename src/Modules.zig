const std = @import("std");
const util = @import("util.zig");
const module_tree = @import("module_tree.zig");

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;
const Instance = @import("Instance.zig");
const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const DepGraph = @import("dep_graph.zig").DepGraph;

const Modules = @This();

fn Init(comptime T: type) type {
    return *const fn (instance: *Instance) anyerror!?*T;
}

fn Deinit(comptime T: type) type {
    return *const fn (data: *T) void;
}

pub const Module = struct {
    init: Init(void),
    deinit: ?Deinit(void),
    data: ?*void
};

graph: DepGraph(Module),

pub fn init(allocator: Allocator, instance: *Instance) !Modules {
    var graph = DepGraph(Module).init(allocator);
    errdefer graph.deinit();

    inline for (@typeInfo(module_tree).Struct.decls) |group_decl| {
        const group = @field(module_tree, group_decl.name);

        inline for (@typeInfo(group).Struct.decls) |module_decl| {
            const Type = @field(group, module_decl.name);
            const typeid = util.typeid(Type);

            if (!@hasDecl(Type, "init"))
                continue;

            const module_ret_type = @typeInfo(@TypeOf(Type.init)).Fn.return_type.?;
            const payload_type = @typeInfo(module_ret_type).ErrorUnion.payload;
            const module_inner_ret_type = @typeInfo(payload_type).Pointer.child;

            const p_init: Init(module_inner_ret_type) = Type.init;
            const p_deinit: ?Deinit(module_inner_ret_type) = if (@hasDecl(Type, "deinit")) Type.deinit else null;

            const module = Module{
                .data = null,
                .deinit = @ptrCast(p_deinit),
                .init = @ptrCast(p_init)
            };

            if (@hasDecl(Module, "deps")) {
                const deps = try allocator.alloc(u32, Module.deps.len);
                defer allocator.free(deps);

                inline for (deps, Module.deps) |*to, from| {
                    to.* = util.typeid(from);
                }

                try graph.add(module, typeid, deps);
            } else {
                try graph.add(module, typeid, &.{});
            }
        }
    }

    try graph.build_walker();

    for (graph.walker) |*module| {
        module.data = try module.init(instance);
    }

    return Modules{
        .graph = graph
    };
}

pub fn deinit(modules: *Modules) void {
    var i: usize = modules.graph.walker.len;
    while (i > 0) {
        i -= 1;

        const node = modules.graph.walker[i];
        if (node.deinit) |deinit_node| {
            if (node.data) |data| {
                deinit_node(data);
            }
        }
    }

    modules.graph.deinit();

    modules.* = undefined;
}