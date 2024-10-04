test "playground" {
    const std = @import("std");

    const GPA = std.heap.GeneralPurposeAllocator;

    const ConfigFromFile = @import("config.zig").ConfigFromFile;
    const Instance = @import("instance.zig").Instance;

    var gpa = GPA(.{}){};
    const allocator = gpa.allocator();
    defer if (gpa.deinit() == std.heap.Check.leak) unreachable;

    var config = try ConfigFromFile.init(allocator);
    defer config.deinit();

    var instance = try Instance.init(allocator, config.config, &.{});
    defer instance.deinit();
}