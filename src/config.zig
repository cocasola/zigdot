const std = @import("std");

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

pub const Config = struct {
    schedule: [][][]const u8,
    fixed_rate: i32,
    modules: ?std.json.Value = null,
    module_blacklist: [][]const u8
};

pub const ConfigFromFile = struct {
    config: Config,
    allocator: ArenaAllocator,

    const Self = @This();

    pub inline fn init(allocator: Allocator) !Self {
        const ConfigJson = struct {
            root: []const u8 = "Limerence Config",
            usingnamespace Config;
        };

        var arena = ArenaAllocator.init(allocator);

        const config = try std.json.parseFromSliceLeaky(
            ConfigJson,
            arena.allocator(),
            @embedFile("lim.config.json"),
            .{}
        );

        return Self{

            .allocator = arena
        };
    }

    pub fn deinit(this: *Self) void {
        this.allocator.deinit();
    }
};
