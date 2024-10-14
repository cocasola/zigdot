const std = @import("std");
const raylib = @import("raylib");

const sdl = @cImport({
    @cInclude("SDL3/SDL.h");
});

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

pub const Error = error {
    SdlFail
};

pub fn init(instance: *Instance) anyerror!*Window {
    const window = try instance.register_resource(Window);

    try instance.register_system(SClearWindow{ .window = window });
    try instance.register_system(SUpdateWindow{ .window = window });

    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO | sdl.SDL_INIT_AUDIO | sdl.SDL_INIT_EVENTS)) {
        std.debug.print("SDL Error: {s}\n", .{ sdl.SDL_GetError() });
        return Error.SdlFail;
    }



    return window;
}

pub fn deinit(window: *Window) void {
    _ = window;

    sdl.SDL_Quit();
}