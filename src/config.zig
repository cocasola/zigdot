const std = @import("std");

const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

pub const ConfigMode = struct {
    from_file: bool = false
};

pub fn Config(comptime mode: ConfigMode) type {
    return struct {
        schedule: [][][]const u8,
        fixed_rate: i32,
        allocator: if (mode.from_file) ArenaAllocator else void,

        const Self = @This();

        inline fn from_file(allocator: Allocator) !Self {
            const ConfigJson = struct {
                root: []const u8 = "Limerence Config",
                schedule: [][][]const u8,
                fixed_rate: i32,
            };

            var arena = ArenaAllocator.init(allocator);

            const config = try std.json.parseFromSliceLeaky(
                ConfigJson,
                arena.allocator(),
                @embedFile("lim.config.json"),
                .{}
            );

            return Self{
                .schedule = config.schedule,
                .fixed_rate = config.fixed_rate,
                .allocator = arena
            };
        }

        pub const init = if (mode.from_file) from_file else void;

        fn deinit_from_file(this: *Self) void {
            this.allocator.deinit();
        }

        pub const deinit = if (mode.from_file) deinit_from_file else void;
    };
}