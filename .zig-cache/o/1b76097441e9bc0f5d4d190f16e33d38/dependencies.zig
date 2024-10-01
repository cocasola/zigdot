pub const packages = struct {
    pub const @"122002d98ca255ec706ef8e5497b3723d6c6e163511761d116dac3aee87747d46cf1" = struct {
        pub const build_root = "C:\\Users\\keega\\AppData\\Local\\zig\\p\\122002d98ca255ec706ef8e5497b3723d6c6e163511761d116dac3aee87747d46cf1";
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
    pub const @"1220c1b7e14d6e41479e7f8c0a99b99c4ee953da58ce3987c1ab5840bf5266d81e67" = struct {
        pub const build_root = "C:\\Users\\keega\\AppData\\Local\\zig\\p\\1220c1b7e14d6e41479e7f8c0a99b99c4ee953da58ce3987c1ab5840bf5266d81e67";
        pub const build_zig = @import("1220c1b7e14d6e41479e7f8c0a99b99c4ee953da58ce3987c1ab5840bf5266d81e67");
        pub const deps: []const struct { []const u8, []const u8 } = &.{
            .{ "raylib", "1220f655fd57d8e10b5dbe7d99c45a0b9836a13cea085d75cd4c15f6e603a1fcb058" },
            .{ "raygui", "122002d98ca255ec706ef8e5497b3723d6c6e163511761d116dac3aee87747d46cf1" },
        };
    };
    pub const @"1220f655fd57d8e10b5dbe7d99c45a0b9836a13cea085d75cd4c15f6e603a1fcb058" = struct {
        pub const build_root = "C:\\Users\\keega\\AppData\\Local\\zig\\p\\1220f655fd57d8e10b5dbe7d99c45a0b9836a13cea085d75cd4c15f6e603a1fcb058";
        pub const build_zig = @import("1220f655fd57d8e10b5dbe7d99c45a0b9836a13cea085d75cd4c15f6e603a1fcb058");
        pub const deps: []const struct { []const u8, []const u8 } = &.{};
    };
};

pub const root_deps: []const struct { []const u8, []const u8 } = &.{
    .{ "raylib-zig", "1220c1b7e14d6e41479e7f8c0a99b99c4ee953da58ce3987c1ab5840bf5266d81e67" },
};
