const raylib = @import("raylib");

const WIDTH = 1920;
const HEIGHT = 1080;
const NAME = "Limerence";

pub fn create_window() !void {
    try raylib.initWindow(WIDTH, HEIGHT, NAME);
}

pub fn destroy_window() void {
    raylib.closeWindow();
}