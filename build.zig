// importing std zig libs
const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    // creating the lib name based on versioning and architecture information
    const version_str: []const u8 = "v1_0_0";
    const output_lib_name: []const u8 = "Toazt" ++ "_" ++ version_str ++ "_" ++ comptime builtin.target.osArchName(); // need to act on \0

    const toazt_lib = b.addStaticLibrary(.{
        .name = output_lib_name,
        .root_source_file = b.path("./src/toazt.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
        }
    );

    b.reference_trace = 10;
    b.installArtifact(toazt_lib);
}