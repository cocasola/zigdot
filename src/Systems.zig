const std = @import("std");
const util = @import("util.zig");

const AutoHashMap = std.AutoHashMap;
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const DepGraph = @import("dep_graph.zig").DepGraph;
const Instance = @import("Instance.zig");

const Systems = @This();

pub const Constraints = struct {
    after: []const type = &.{},
    before: []const type = &.{}
};

const RegisteredSystem = struct {
    callback: *const fn (system: *anyopaque) anyerror!void,
    bytes: []u8
};

allocator: Allocator,
graph: DepGraph(?RegisteredSystem),
walker: []?RegisteredSystem,

pub fn init(allocator: Allocator) Systems {
    return Systems{
        .graph = DepGraph(?RegisteredSystem).init(allocator),
        .allocator = allocator,
        .walker = &.{}
    };
}

pub fn register_system(systems: *Systems, system: anytype) !void {
    const SystemType = @TypeOf(system);

    const RunPtr = *const fn (system: *@TypeOf(system)) anyerror!void;
    const run: ?RunPtr = 
        if (@hasDecl(@TypeOf(system), "run"))
            SystemType.run
        else
            null;

    const constraints: ?Constraints = blk: {
        inline for (@typeInfo(SystemType).Struct.decls) |decl| {
            if (@TypeOf(@field(SystemType, decl.name)) == Constraints)
                break :blk @field(SystemType, decl.name);
        }

        break :blk null;
    };

    const deps = 
        if (constraints) |v|
            try systems.allocator.alloc(u32, v.after.len)
        else 
            &.{};
    defer if (deps.len > 0) systems.allocator.free(deps);

    const dep_for = 
        if (constraints) |v|
            try systems.allocator.alloc(u32, v.before.len)
        else 
            &.{};
    defer if (dep_for.len > 0) systems.allocator.free(dep_for);

    if (constraints) |v| {
        inline for (deps, v.after) |*to, from| {
            to.* = util.typeid(from);
        }

        inline for (dep_for, v.before) |*to, from| {
            to.* = util.typeid(from);
        }
    }

    if (run) |v| {
        const registered_system = RegisteredSystem{
            .callback = @ptrCast(v),
            .bytes = try systems.allocator.alloc(u8, @sizeOf(SystemType))
        };
        errdefer systems.allocator.free(registered_system.bytes);

        const from_bytes = std.mem.asBytes(&system);
        @memcpy(registered_system.bytes, from_bytes);

        try systems.graph.add(registered_system, util.typeid(SystemType), deps, dep_for);
    } else {
        try systems.graph.add(null, util.typeid(SystemType), deps, dep_for);
    }
}

pub fn build_walker(systems: *Systems) !void {
    systems.walker = try systems.graph.build_walker();
}

pub fn deinit(systems: *Systems) void {
    for (systems.walker) |maybe_system| {
        if (maybe_system) |system| {
            systems.allocator.free(system.bytes);
        }
    }

    systems.graph.deinit();
    systems.allocator.free(systems.walker);

    systems.* = undefined;
}