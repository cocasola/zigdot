const std = @import("std");
const raylib = @import("raylib");

const Instance = @import("../../Instance.zig");
const System = @import("../../Systems.zig").System;
const SystemConfig = @import("../../Systems.zig").SystemConfig;

pub const Window = struct {
    width: i32,
    height: i32,
    name: [*:0]const u8,
    quit: bool
};

pub const UiEvents = struct {

};

pub const system = System(.{ .callback = @ptrCast(@constCast(&x)) });

pub fn init(instance: *Instance) anyerror!*Window {
    const window = try instance.register_resource(Window);
    try instance.register_system(system);

    std.debug.print("window init\n", .{});

    // raylib.initWindow(window.width, window.height, window.name);
    // raylib.disableEventWaiting();

    return window;
}

pub fn deinit(window: *Window) void {
    _ = window;

    std.debug.print("window deinit\n", .{});

    // raylib.closeWindow();
}

// pub fn lim_ui_events(module: *Module) anyerror!void {
//     raylib.pollInputEvents();
//     module.quit = raylib.windowShouldClose();
// }
//
// pub fn lim_pre_render(module: *Module) anyerror!void {
//     _ = module;
//
//     raylib.beginDrawing();
//     raylib.clearBackground(raylib.Color.black);
// }
//
// pub fn lim_post_render(module: *Module) anyerror!void {
//     _ = module;
//
//     raylib.endDrawing();
//     raylib.swapScreenBuffer();
// }