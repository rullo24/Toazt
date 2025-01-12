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
