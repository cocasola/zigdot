const std = @import("std");
const raylib = @import("raylib");

const Instance = @import("../../Instance.zig");
const Constraints = @import("../../Systems.zig").Constraints;

pub const Window = struct {
    width: i32,
    height: i32,
    name: [*:0]const u8,
    quit: bool
};

pub const SClearWindow = struct {
    window: *Window,

    pub fn run(this: *SClearWindow) anyerror!void {
        _ = this;
        std.debug.print("clear\n", .{});
    }
};

pub const SUpdateWindow = struct {
    pub const constraints = Constraints{
        .after = &.{ SClearWindow }
    };

    window: *Window,

    pub fn run(this: *SUpdateWindow) anyerror!void {
        _ = this;
        std.debug.print("update\n", .{});
    }
};

pub fn init(instance: *Instance) anyerror!*Window {
    const window = try instance.register_resource(Window);

    try instance.register_system(SClearWindow{ .window = window });
    try instance.register_system(SUpdateWindow{ .window = window });

    std.debug.print("window init\n", .{});

    return window;
}

pub fn deinit(window: *Window) void {
    _ = window;

    std.debug.print("window deinit\n", .{});
}