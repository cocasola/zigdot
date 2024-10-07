pub usingnamespace @import("module_tree.zig");

pub const Config = @import("Config.zig");
pub const Schedule = @import("Schedule.zig");
pub const Instance = @import("Instance.zig");

test "test" {
    {

    const std = @import("std");
    const zigdot = @import("root.zig");

    const GPA = std.heap.GeneralPurposeAllocator;
    const Window = zigdot.ui.Window;

    var gpa = GPA(.{}){};
    defer if (gpa.deinit() == std.heap.Check.leak) unreachable;
    const allocator = gpa.allocator();

    var config = try Config.Static.init(allocator, "test_config.json");
    defer config.deinit();

    var instance = try Instance.init(allocator, config.config);
    defer instance.deinit();

    const window = instance.get_module(Window).?;

    while (!window.quit) {
        try instance.schedule.run();
    }

    }

    @panic("help me");
}