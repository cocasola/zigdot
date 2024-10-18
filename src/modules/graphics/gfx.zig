const c = @cImport({
    @cInclude("SDL3/SDL.h");
    @cDefine("SDL_GPU_SHADERCROSS_IMPLEMENTATION", {});
    @cInclude("SDL_gpu_shadercross.h");
});

const std = @import("std");
const util = @import("../../util.zig");

const Instance = @import("../../Instance.zig");
const Constraints = @import("../../Systems.zig").Constraints;

pub const RGfx = struct {
    device: *c.SDL_GPUDevice,
    cmd_buf: *c.SDL_GPUCommandBuffer,
};

pub const SBeginCmdBuf = struct {
    gfx: *RGfx,

    pub fn run(this: *SBeginCmdBuf) anyerror!void {
        // this.gfx.cmd_buf = c.SDL_AcquireGPUCommandBuffer(this.gfx.device);
        _ = this;
    }
};

pub const SBeginRender = struct {
    pub const constraints = Constraints{
        .after = &.{ SBeginCmdBuf },
    };
};

pub const SEndRender = struct {
    pub const constraints = Constraints{
        .after = &.{ SBeginRender },
    };
};

pub const SEndCmdBuf = struct {
    pub const constraints = Constraints{
        .after = &.{ SEndRender }
    };

    gfx: *RGfx,

    pub fn run(this: *SEndCmdBuf) anyerror!void {
        _ = this;
    }
};

pub const Error = error {
    InitGraphicsFail
};

fn sdl_error(err: Error) Error {
    std.debug.print("SDL Error: {s}\n", .{ c.SDL_GetError() });
    return err;
}

pub fn init(instance: *Instance) anyerror!*RGfx {
    var gfx = try instance.register_resource(RGfx{ .cmd_buf = undefined, .device = undefined });

    try instance.register_system(SBeginCmdBuf{ .gfx = gfx });
    try instance.register_system(SBeginRender{});
    try instance.register_system(SEndRender{});
    try instance.register_system(SEndCmdBuf{ .gfx = gfx });

    if (!c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_AUDIO | c.SDL_INIT_EVENTS))
        return sdl_error(Error.InitGraphicsFail);
    errdefer c.SDL_Quit();

    if (!c.SDL_ShaderCross_Init())
        return sdl_error(Error.InitGraphicsFail);
    errdefer c.SDL_ShaderCross_Quit();

    gfx.device = 
        c.SDL_CreateGPUDevice(c.SDL_ShaderCross_GetSPIRVShaderFormats(), util.debug, null)
    orelse
        return sdl_error(Error.InitGraphicsFail);
    errdefer c.SDL_DestroyGPUDevice(gfx.device);

    return gfx;
}

pub fn deinit(gfx: *RGfx) void {
    c.SDL_DestroyGPUDevice(gfx.device);
    c.SDL_ShaderCross_Quit();
    c.SDL_Quit();
}
