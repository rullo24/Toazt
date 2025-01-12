const std = @import("std");

// building a Windows example executable of Toazt usage
pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "Toazt",
        .root_source_file = b.path("./example.zig"),
        .target = b.standardTargetOptions(.{}),
        .optimize = b.standardOptimizeOption(.{}),
    });

    // linking the toazt code to the example binary --> so that functions can be called by @import()ing
    const toazt_module = b.addModule("toazt", .{ // add toazt code for include via @import("toazt")
        .root_source_file = b.path("../src/toazt.zig"),
    });
    exe.root_module.addImport("toazt", toazt_module); // linking the module in with executable

    // building executable
    b.reference_trace = 10; // better stdout during compiling
    b.installArtifact(exe);
}
