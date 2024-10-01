const lim = @import("root.zig");
const std = @import("std");

const Window = lim.window.Window;

test "playground" {
    const window = Window{};
    std.debug.print("%d", .{ window.a });
}