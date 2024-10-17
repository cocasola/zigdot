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
walker: []Module,
allocator: Allocator,

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
            const p_deinit: ?Deinit(module_inner_ret_type) =
                if (@hasDecl(Type, "deinit"))
                    Type.deinit
                else
                    null;

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

                try graph.add(module, typeid, deps, &.{});
            } else {
                try graph.add(module, typeid, &.{}, &.{});
            }
        }
    }

    const walker = try graph.build_walker();

    for (walker, 0..) |*module, i| {
        module.data = module.init(instance) catch |err| {
            var j: usize = i;
            while (j > 0) {
                j -= 1;

                const node = walker[j];
                if (node.deinit) |deinit_node| {
                    if (node.data) |data| {
                        deinit_node(data);
                    }
                }
            }

            allocator.free(walker);

            return err;
        };
    }

    return Modules{
        .graph = graph,
        .walker = walker,
        .allocator = allocator
    };
}

pub fn deinit(modules: *Modules) void {
    var i: usize = modules.walker.len;
    while (i > 0) {
        i -= 1;

        const node = modules.walker[i];
        if (node.deinit) |deinit_node| {
            if (node.data) |data| {
                deinit_node(data);
            }
        }
    }
    modules.allocator.free(modules.walker);

    modules.graph.deinit();

    modules.* = undefined;
}