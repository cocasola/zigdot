const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const std = @import("std");
const util = @import("../../util.zig");
const gfx = @import("../graphics/gfx.zig");

const Instance = @import("../../Instance.zig");
const Constraints = @import("../../Systems.zig").Constraints;
const RGfx = gfx.RGfx;

pub const RWindow = struct {
    width: i32,
    height: i32,
    title: [*:0]const u8,
    quit: bool,
    handle: *c.SDL_Window,
    gfx: *RGfx
};

pub const SClearWindow = struct {
    pub const constraints = Constraints{
        .after = &.{ gfx.SBeginCmdBuf },
        .before = &.{ gfx.SBeginRender }
    };

    window: *RWindow,

    pub fn run(this: *SClearWindow) anyerror!void {
        _ = this;
    }
};

pub const SUpdateWindow = struct {
    pub const constraints = Constraints{
        .after = &.{ gfx.SEndCmdBuf }
    };

    window: *RWindow,

    pub fn run(this: *SUpdateWindow) anyerror!void {
        var event: c.SDL_Event = undefined;

        while (c.SDL_PollEvent(&event)) {
            if (event.type == c.SDL_EVENT_QUIT)
                this.window.quit = true;
        }
    }
};

pub const Error = error {
    CreateWindowFail
};

fn sdl_error(err: Error) Error {
    std.debug.print("SDL Error: {s}\n", .{ c.SDL_GetError() });
    return err;
}

pub const deps = .{ gfx };

pub fn init(instance: *Instance) anyerror!*RWindow {
    const window = try instance.register_resource(RWindow{
        .width = 1280,
        .height = 720,
        .title = "Zigdot",
        .quit = false,
        .handle = undefined,
        .gfx = instance.get_resource(RGfx) orelse unreachable
    });

    try instance.register_system(SClearWindow{ .window = window });
    try instance.register_system(SUpdateWindow{ .window = window });

    window.handle =
        c.SDL_CreateWindow(window.title, window.width, window.height, 0)
    orelse
        return sdl_error(Error.CreateWindowFail);
    errdefer c.SDL_DestroyWindow(window.handle);

	if (!c.SDL_ClaimWindowForGPUDevice(@ptrCast(window.gfx.device), window.handle))
        return sdl_error(Error.CreateWindowFail);
    errdefer c.SDL_ReleaseWindowFromGPUDevice(window.gfx.device, window.handle);

    return window;
}

pub fn deinit(window: *RWindow) void {
    c.SDL_ReleaseWindowFromGPUDevice(@ptrCast(window.gfx.device), window.handle);
    c.SDL_DestroyWindow(window.handle);
}