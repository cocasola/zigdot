const std = @import("std");
const raylib = @import("raylib");

const Instance = @import("../../Instance.zig");

pub const Window = struct {
    width: i32,
    height: i32,
    name: [*:0]const u8,
    quit: bool
};

pub fn init(instance: *Instance) anyerror!*Window {
    const window = try instance.create_resource(Window);

    // raylib.initWindow(window.width, window.height, window.name);
    // raylib.disableEventWaiting();

    return window;
}

pub fn deinit(window: *Window) void {
    _ = window;

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