const std = @import("std");
const builtin = @import("builtin");
const paths = @import("paths.zig");

const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const StringMap = std.StringHashMap;

const Module = struct { path: []const u8, name: []const u8 };

fn map_modules(root_dir: std.fs.Dir, allocator: Allocator) !void {
    var modules_file = try root_dir.createFile("src/module_tree.zig", .{});
    defer modules_file.close();

    var modules = StringMap(ArrayList(Module)).init(allocator);

    var module_dir = try root_dir.openDir("src/modules/", .{ .iterate = true });
    defer module_dir.close();

    var walker = try module_dir.walk(allocator);
    defer walker.deinit();

    while (try walker.next()) |entry| {
        const path = try allocator.dupe(u8, entry.path);

        if (!std.mem.eql(u8, std.fs.path.extension(path), ".zig"))
            continue;

        var iter = std.mem.splitSequence(u8, path, &.{std.fs.path.sep});
        const first = iter.first();

        if (modules.getPtr(first)) |group| {
            try group.append(Module{ .name = std.fs.path.stem(path), .path = path });
        } else {
            var group = ArrayList(Module).init(allocator);

            try group.append(Module{ .name = std.fs.path.stem(path), .path = try std.mem.replaceOwned(u8, allocator, path, "\\", "/") });

            try modules.put(first, group);
        }
    }

    var iter = modules.iterator();
    while (iter.next()) |entry| {
        const key = entry.key_ptr.*;

        try modules_file.writeAll(try std.fmt.allocPrint(allocator, "pub const {s} = struct {{\n", .{key}));

        for (entry.value_ptr.items) |module| {
            try modules_file.writeAll(
                try std.fmt.allocPrint(
                    allocator,
                    "\tpub const {s} = @import(\"modules/{s}\");\n",
                    .{ module.name, module.path }
                )
            );
        }

        try modules_file.writeAll("};\n\n");
    }
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    var arena = ArenaAllocator.init(b.allocator);
    try map_modules(b.build_root.handle, arena.allocator());
    arena.deinit();

    const lib = b.addStaticLibrary(.{
        .name = "zigdot",
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const playground = b.addExecutable(.{
        .name = "zigdot-playground",
        .root_source_file = b.path("src/playground.zig"),
        .target = target,
        .optimize = optimize
    });

    switch (builtin.os.tag) {
        .macos => {
            playground.addRPath(.{ .cwd_relative = paths.sdl });
            playground.addFrameworkPath(.{ .cwd_relative = paths.sdl });
            playground.linkFramework("SDL3");
            playground.addIncludePath(.{ .cwd_relative = paths.sdl ++ "SDL3.framework/" ++ "include/"});
            lib.addRPath(.{ .cwd_relative = paths.sdl });
            lib.addFrameworkPath(.{ .cwd_relative = paths.sdl });
            lib.linkFramework("SDL3");
            lib.addIncludePath(.{ .cwd_relative = paths.sdl ++ "include/"});
        },
        .windows => {
            playground.addLibraryPath(.{ .cwd_relative = paths.sdl ++ "lib/" });
            playground.addIncludePath(.{ .cwd_relative = paths.sdl ++ "include/" });
            playground.addIncludePath(.{ .cwd_relative = paths.sdl_shader_cross });
            playground.linkSystemLibrary("SDL3.dll");
            playground.linkLibC();
            lib.addLibraryPath(.{ .cwd_relative = paths.sdl ++ "lib/" });
            lib.addIncludePath(.{ .cwd_relative = paths.sdl ++ "include/" });
            lib.addIncludePath(.{ .cwd_relative = paths.sdl_shader_cross });
            lib.linkSystemLibrary("SDL3.dll");
            lib.linkLibC();
        },
        else => {},
    }

    b.installArtifact(lib);
    b.installArtifact(playground);
}
