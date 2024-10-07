const std = @import("std");
const raylib = @import("raylib");

const Instance = @import("../../Instance.zig");

width: i32 = 1080,
height: i32 = 720,
name: [*:0]const u8 = "Zigdot",
quit: bool = false,

const WindowModule = @This();

pub fn init(this: *WindowModule, instance: *Instance) anyerror!void {
    _ = instance;

    raylib.initWindow(this.width, this.height, this.name);
    raylib.disableEventWaiting();
}

pub fn deinit(this: *WindowModule) void {
    _ = this;

    raylib.closeWindow();
}

pub fn lim_ui_events(this: *WindowModule) anyerror!void {
    raylib.pollInputEvents();
    this.quit = raylib.windowShouldClose();
}

pub fn lim_pre_render(this: *WindowModule) anyerror!void {
    _ = this;

    raylib.beginDrawing();
    raylib.clearBackground(raylib.Color.black);
}

pub fn lim_post_render(this: *WindowModule) anyerror!void {
    _ = this;

    raylib.endDrawing();
    raylib.swapScreenBuffer();
}