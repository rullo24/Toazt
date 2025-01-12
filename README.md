# Toazt - A Windows 10 Toast Notification Module
A lightweight and simple module for displaying toast notifications in Windows 10/11 applications, written entirely in Zig.

## Features
- Native support for Windows 10/11 toast notifications. No dependencies required.
- Simplistic syntax for creating and pushing toast notifications (2x commands required)
- Customisable notification properties including: title, message, included icon and show duration (very basic)

## Importing & Building
NOTE: As of Toazt v1.0.0's release, this module is working on Zig version 0.13.0.

To utilise Toazt in your projects, this repo must be cloned and linked in your project's build.zig script. An example build.zig script (with relevant example program) can be seen in the /example folder. Steps for building/importing are shown below. 

### Cloning the Repo
```bash
cd *your_repo*
git clone https://github.com/rullo24/Toazt
```
Note that only the code found in the /src folder is required for this to work. If you would like, upon cloning the entire repo, only the /src folder (and its files) needs to be kept (all other files can be deleted).

### Adding the Toazt Dependency in build.zig
Whereby build.zig follows the build.zig standard syntax, the only requirement is that a new module is added to the project and imported to the executable.
```bash
pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .name = "*project name*",
        .root_source_file = b.path(*project entry zig file*),
    });

    const toazt_module = b.addModule("toazt", .{ 
        .root_source_file = b.path(*path to toazt.zig*),
    });
    exe.root_module.addImport("toazt", toazt_module);
    b.installArtifact(exe);
``` 

### Example
The following example can be built by moving to the /example folder and running *zig build*.
```bash
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
```

## Usage
Despite the complexity of toast notifications (behind-the-scenes), this module implements a "two-command implementation" concept. This means that all complexity is hidden behind an abstraction layer.

To use Toazt notifications in your code, ensure that the module is correctly imported in your build.zig file (as above) and add the following line to the top of your .zig files:
```bash
const toazt: type = @import("Toazt")
```

### Example
```bash
// std zig includes
const std = @import("std");

// including toazt package
const toazt: type = @import("toazt");

pub fn main() !void {
    // init allocator --> GPA used instead of page_allocator to reduce memory consumption
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const alloc = gpa.allocator();
    defer _ = gpa.deinit();

    // creating test notification
    var test_notification: toazt.Notification = toazt.Notification {
        .title = "Example Title",
        .message = "Test Message!",
        .icon_loc_abs = "C:\\Windows\\IdentityCRL\\WLive48x48.png",
        .duration = toazt.Duration.short,
    };

    // pushing the notification to the Windows screen
    try test_notification.push(alloc);

    return;
}
```
![Toazt_Example_Code](images/example_toazt_notification.png)

## Thanks
Considering I have never before worked with toast notifications (without use of a module), some inspiration was needed to start this project. I would like to thank *go-toast/toast* and *GitHub30/toast-notification-examples* for their work on toast-related projects. Referenced links can be found here:
- https://github.com/GitHub30/toast-notification-examples
- https://github.com/go-toast/toast?tab=readme-ov-file