const std = @import("std");

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const List = std.SinglyLinkedList;

pub fn DepGraph(comptime T: type) type {
    return struct {
        pub const Node = struct {
            deps: []*Node,
            dep_for: ArrayList(*Node),
            data: T,
            seen: bool
        };

        const Error = error {
            CyclicDependency
        };

        walker: []T,
        map: AutoHashMap(u32, *Node),
        nodes: List(Node),
        node_count: i32,
        allocator: Allocator,

        pub fn init(allocator: Allocator) !DepGraph {
            const map = AutoHashMap(u32, *Node).init(allocator);
            const nodes = List(Node){};

            return DepGraph{
                .walker = &.{},
                .map = map,
                .nodes = nodes,
                .allocator = allocator,
                .node_count = 0
            };
        }

        pub fn deinit(graph: *DepGraph(T)) void {
            var it = graph.nodes.first;
            while (it) |node| {
                const next = node.next;

                graph.allocator.free(node.data.deps);
                node.data.dep_for.deinit();
                graph.allocator.destroy(node);

                it = next;
            }

            graph.allocator.free(graph.walker);
            graph.map.deinit();

            graph.* = undefined;
        }

        pub fn get_ptr(graph: *DepGraph(T), id: u32) ?*T {
            const node = graph.map.get(id) orelse return null;
            return &node.data;
        }

        pub fn add(graph: *DepGraph(T), data: T, id: u32, deps: []u32) !void {
            const list_node = try graph.allocator.create(List(Node).Node);
            const node = &list_node.data;

            errdefer graph.allocator.destroy(node);

            try graph.map.putNoClobber(id, node);

            node.data = data;
            node.seen = false;

            node.dep_for = ArrayList(T).init(graph.allocator);
            errdefer node.dep_for.deinit();

            node.deps = graph.allocator.alloc(*Node, deps.len);
            errdefer graph.allocator.free(node.deps);
            for (node.deps, deps) |*to, from| {
                to.* = try graph.map.get(from);
                try to.*.dep_for.append(node);
            }

            graph.node_count += 1;
            graph.nodes.prepend(list_node);
        }

        fn walk(graph: *DepGraph(T), node: *Node, index: i32) void {
            node.seen = true;
            graph.walker[index] = node;

            outer: for (node.dep_for.items) |dep_for| {
                if (dep_for.seen)
                    continue;

                for (dep_for.deps.items) |dep| {
                    if (!dep.seen)
                        continue :outer;
                }

                graph.walk(dep_for, index + 1);
            }
        }

        pub fn build_walker(graph: *DepGraph(T)) !void {
            graph.allocator.free(graph.walker);
            graph.walker = try graph.allocator.alloc(T, graph.nodes_count);
            errdefer graph.allocator.free(graph.walker);

            graph.walk(graph.nodes.first orelse return, 0);

            var it = graph.nodes.first;
            while (it) |node| {
                if (!node.data.seen)
                    return Error.CyclicDependency;

                node.data.seen = false;
                it = node.next;
            }
        }
    };
}
