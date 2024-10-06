const std = @import("std");
const util = @import("util.zig");
const module_tree = @import("module_tree.zig");

const Allocator = std.mem.Allocator;
const StringMap = std.hash_map.StringHashMap;
const Instance = @import("Instance.zig");
const Config = @import("Config.zig");
const Schedule = @import("Schedule.zig");

pub fn Init(comptime T: type) type {
    return *const fn (module: *T, instance: *Instance) anyerror!void;
}

pub fn Deinit(comptime T:type) type {
    return *const fn (module: *T) void;
}

fn get_callback(
    comptime name: []const u8,
    comptime ModuleType: type,
    comptime CallbackGeneric: *const fn (comptime T: type) type
) ?CallbackGeneric(anyopaque) {
    if (!@hasDecl(ModuleType, name))
        return null;

    const Callback: CallbackGeneric(ModuleType) = @field(ModuleType, name);
    return @ptrCast(Callback);
}

name: []const u8,
typeid: u32,
deps: [][]const u8,
init: ?Init(anyopaque),
deinit: ?Deinit(anyopaque),
data: []u8,

const Module = @This();

pub fn init_all(instance: *Instance) !void {
    inline for (@typeInfo(module_tree).Struct.decls) |group_decl| {
        const group = @field(module_tree, group_decl.name);

        inline for (@typeInfo(group).Struct.decls) |module_decl| {
            const ModuleType = @field(group, module_decl.name);
            const module_name = module_decl.name;

            const module = Module{
                .name = module_name,
                .typeid = util.typeid(ModuleType),
                .data = try instance.allocator.alloc(u8, @sizeOf(ModuleType)),
                .deps = if (@hasDecl(ModuleType, "deps")) ModuleType.deps else &.{},
                .init = get_callback("init", ModuleType, Init),
                .deinit = get_callback("deinit", ModuleType, Deinit)
            };

            @memcpy(module.data, std.mem.asBytes(&ModuleType{}));

            inline for (@typeInfo(ModuleType).Struct.decls) |decl| {
                const field = @field(ModuleType, decl.name);

                if (@typeInfo(@TypeOf(field)) != .Fn)
                    continue;

                comptime if (std.mem.eql(u8, decl.name, "init") or std.mem.eql(u8, decl.name, "deinit"))
                    continue;

                const callback: Schedule.CallbackPtrGeneric(ModuleType) = field;

                _ = try instance.register_callback(@ptrCast(callback), decl.name, @ptrCast(module.data.ptr));
            }

            try instance.modules.putNoClobber(module.typeid, module);
        }
    }

    var module_iter = instance.modules.valueIterator();
    while (module_iter.next()) |module| {
        if (module.init) |init| {
            try init(@ptrCast(module.data.ptr), instance);
        }
    }
}

pub fn deinit_all(instance: *Instance) void {
    var module_iter = instance.modules.valueIterator();
    while (module_iter.next()) |module| {
        if (module.deinit) |deinit| {
            deinit(@ptrCast(module.data.ptr));
        }
    }
}