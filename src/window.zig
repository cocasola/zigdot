const raylib = @import("raylib");

const width: i32 = 1920;
const height: i32 = 1080;
const name = "Limerence";

pub var quit = false;

pub fn create_window() void {
    raylib.initWindow(width, height, name);
    raylib.setTargetFPS(60);
}

pub fn clear_window() void {
    raylib.beginDrawing();
    raylib.clearBackground(raylib.Color.black);
}

pub fn update_window() void {
    raylib.endDrawing();
}

pub fn destroy_window() void {
    raylib.closeWindow();
}