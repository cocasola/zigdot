const std = @import("std");

const ArrayList = std.ArrayList;
const AutoHashMap = std.AutoHashMap;
const Allocator = std.mem.Allocator;
const List = std.SinglyLinkedList;

pub fn DepGraph(comptime T: type) type {
    return struct {
        pub const Node = struct {
            deps: ArrayList(*Node),
            dep_for: ArrayList(*Node),
            data: T,
            seen: bool
        };

        const Error = error {
            CyclicDependency,
            InvalidDependency,
            InvalidDependencyFor
        };

        map: AutoHashMap(u32, *Node),
        nodes: List(Node),
        node_count: u32,
        allocator: Allocator,

        pub fn init(allocator: Allocator) DepGraph(T) {
            const map = AutoHashMap(u32, *Node).init(allocator);
            const nodes = List(Node){};

            return DepGraph(T){
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

                node.data.deps.deinit();
                node.data.dep_for.deinit();
                graph.allocator.destroy(node);

                it = next;
            }

            graph.map.deinit();

            graph.* = undefined;
        }

        pub fn get_ptr(graph: *DepGraph(T), id: u32) ?*T {
            const node = graph.map.get(id) orelse return null;
            return &node.data;
        }

        pub fn add(graph: *DepGraph(T), data: T, id: u32, deps: []u32, dep_for: []u32) !void {
            const list_node = try graph.allocator.create(List(Node).Node);
            const node = &list_node.data;

            errdefer graph.allocator.destroy(node);

            try graph.map.putNoClobber(id, node);

            node.data = data;
            node.seen = false;

            node.dep_for = ArrayList(*Node).init(graph.allocator);
            errdefer node.dep_for.deinit();
            node.deps = ArrayList(*Node).init(graph.allocator);
            errdefer node.deps.deinit();

            for (deps) |dep| {
                const dep_node = graph.map.get(dep) orelse return Error.InvalidDependency;

                try node.deps.append(dep_node);
                try dep_node.dep_for.append(node);
            }

            for (dep_for) |it| {
                const dep_for_node = graph.map.get(it) orelse return Error.InvalidDependencyFor;

                try node.dep_for.append(dep_for_node);
                try dep_for_node.deps.append(node);
            }

            graph.node_count += 1;
            graph.nodes.prepend(list_node);
        }

        fn walk(graph: *DepGraph(T), node: *Node, walker: [*]T, index: *usize) void {
            node.seen = true;
            walker[index.*] = node.data;
            index.* += 1;

            outer: for (node.dep_for.items) |dep_for| {
                if (dep_for.seen)
                    continue;

                for (dep_for.deps.items) |dep| {
                    if (!dep.seen)
                        continue :outer;
                }

                graph.walk(dep_for, walker, index);
            }
        }

        pub fn build_walker(graph: *DepGraph(T)) ![]T {
            const walker = try graph.allocator.alloc(T, graph.node_count);
            errdefer graph.allocator.free(walker);

            var index: usize = 0;

            var it = graph.nodes.first;
            while (it) |node| {
                if (node.data.deps.items.len == 0)
                    graph.walk(&node.data, walker.ptr, &index);

                it = node.next;
            }

            it = graph.nodes.first;
            while (it) |node| {
                if (!node.data.seen)
                    return Error.CyclicDependency;

                node.data.seen = false;
                it = node.next;
            }

            return walker;
        }
    };
}
