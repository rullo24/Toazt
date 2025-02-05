// importing std zig libs
const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    b.reference_trace = 10; // error messages
    const target = b.standardTargetOptions(.{});
    const optimise = b.standardOptimizeOption(.{});

    const toazt_lib = b.addStaticLibrary(.{
        .name = "toazt",
        .root_source_file = b.path("./src/toazt.zig"),
        .target = target,
        .optimize = optimise,
        }
    );

    _ = b.addModule("toazt", .{
        .root_source_file = b.path("./src/toazt.zig"),
        .target = target,
        .optimize = optimise,
    });

    b.installArtifact(toazt_lib);
}