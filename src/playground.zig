const std = @import("std");
const zigdot = @import("root.zig");

const GPA = std.heap.GeneralPurposeAllocator;
const Window = zigdot.ui.Window;
const Config = zigdot.Config;
const Instance = zigdot.Instance;

pub fn main() !void {
    var gpa = GPA(.{}){};
    defer if (gpa.deinit() == std.heap.Check.leak) unreachable;
    const allocator = gpa.allocator();

    var config = try Config.Static.init(allocator, "test_config.json");
    defer config.deinit();

    var instance = try Instance.init(allocator, config.config);
    defer instance.deinit();

    // const window = instance.get_module(Window).?;
    //
    // while (!window.quit) {
    //     try instance.schedule.run();
    // }
}