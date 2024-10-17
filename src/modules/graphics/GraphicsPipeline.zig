const c = @cImport({
    @cInclude("SDL3/SDL.h");
});

const Instance = @import("../../Instance.zig");
const Constraints = @import("../../Systems.zig").Constraints;

const GraphicsPipeline = @This();

pub const SBeginDraw = struct {
    pipeline: *GraphicsPipeline,

    pub fn run(this: *SBeginDraw) anyerror!void {
        this.pipeline.command_buf = c.SDL_AcquireGPUCommandBuffer(this.pipeline.device);
    }
};

pub const SEndDraw = struct {

};

pub const Error = error {
    InitGraphicsFail
};

device: *c.SDL_GPUDevice,
command_buf: *c.SDL_GPUCommandBuffer,

fn sdl_error(err: Error) Error {
    std.debug.print("SDL Error: {s}\n", .{ c.SDL_GetError() });
    return err;
}

pub fn init(instance: *Instance) anyerror!*GraphicsPipeline {
    var pipeline = try instance.register_resource(GraphicsPipeline);

    if (!c.SDL_Init(c.SDL_INIT_VIDEO | c.SDL_INIT_AUDIO | c.SDL_INIT_EVENTS))
        return sdl_error(Error.InitGraphicsFail);
    errdefer c.SDL_Quit();

    if (!c.SDL_ShaderCross_Init())
        return sdl_error(Error.InitGraphicsFail);

    window.device = 
        c.SDL_CreateGPUDevice(c.SDL_ShaderCross_GetSPIRVShaderFormats(), util.debug, null)
    orelse
        return sdl_error(Error.InitGraphicsFail);
    errdefer c.SDL_DestroyGPUDevice(window.device);

    return pipeline;
}
