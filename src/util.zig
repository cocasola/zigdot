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