const std = @import("std");
const util = @import("util.zig");

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

const Config = @This();

modules: ?std.json.Value = null,
fixed_rate: i32 = 60,
module_blacklist: [][]const u8 = &.{},

pub const Static = struct {
    config: Config,
    arena: ArenaAllocator,

    pub inline fn init(allocator: Allocator, comptime path: []const u8) !Static {
        var arena = ArenaAllocator.init(allocator);
        errdefer arena.deinit();

        const config = try std.json.parseFromSliceLeaky(
            Config,
            arena.allocator(),
            @embedFile(path),
            .{ .allocate = .alloc_always, .ignore_unknown_fields = true }
        );

        return Static{
            .config = config,
            .arena = arena
        };
    }

    pub fn deinit(this: *Static) void {
        this.arena.deinit();

        this.* = undefined;
    }
};