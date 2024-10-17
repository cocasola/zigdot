const builtin = @import("builtin");
const std = @import("std");

pub inline fn assign(from: anytype, comptime T: type) T {
    var r: T = undefined;

    inline for (@typeInfo(@TypeOf(from)).Struct.fields) |field| {
        if (@hasField(T, field.name))
            @field(r, field.name) = @field(from, field.name);
    }

    return r;
}

pub fn typeid(comptime T: type) u32 {
    return @intFromError(@field(anyerror, @typeName(T)));
}

pub const debug: bool = builtin.mode == std.builtin.OptimizeMode.Debug;