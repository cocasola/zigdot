pub const window = @import("window.zig");

pub const Instance = struct {
    pub fn create() !Instance {
        try window.create_window();

        return Instance{

        };
    }

    pub fn destroy(this: @This()) void {
        window.destroy_window();

        _ = this;
    }
};

test "playground" {
    const std = @import("std");

    std.testing.refAllDecls(@This());

    var instance = try Instance.create();
    defer instance.destroy();
}