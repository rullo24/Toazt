// std zig includes
const std = @import("std");
const builtin = @import("builtin");

// user zig imports
const get_uuid: type = @import("get_uuid.zig");
const strmod: type = @import("strmod.zig");

pub const Duration: type =  enum {
    long,
    short,
};

pub const Notification: type = struct {
    title: []const u8 = "",
    message: []const u8 = "",
    icon_loc_abs: []const u8 = "",
    duration: Duration = Duration.short,

    pub fn push(self: *Notification, alloc: std.mem.Allocator) !void {
        // panic if executable is run on a non-windows system
        if (builtin.target.os.tag != .windows) {
            std.debug.panic("ERROR: Toazt binaries only run on Windows\n", .{});
        }

        // checking the validity of user parsed values       
        try self.setNotificationDefaults();

        // building the xml for parsing
        const ps_script_w_user_xml: []const u8 = try self.getToastTemplateScript(alloc);
        defer alloc.free(ps_script_w_user_xml);

        // creating a ps1 script in temp dir and running it (shows toast)
        try createAndRunTempFolderScript(alloc, ps_script_w_user_xml);
    }

    fn setNotificationDefaults(self: *Notification) !void {
        // checking the validity of the provided icon path (must be absolute)
        if (!strmod.absolutePathIsValid(self.icon_loc_abs)) {
            self.icon_loc_abs = ""; // setting back to default values
        }
    }

    fn getToastTemplateScript(self: *Notification, alloc: std.mem.Allocator) ![]u8 {
        // equation chosen duration to a string (as required by PowerShell)
        var duration_string: []const u8 = "short";
        if (self.duration != Duration.short) {
            duration_string = "long";
        }

        const xml_template: []const u8 = 
\\<toast duration="{s}">
\\<visual>
\\  <binding template="ToastGeneric">
\\      <text>{s}</text>
\\      <text>{s}</text>
\\      <image placement="appLogoOverride" src="{s}"/>
\\  </binding>
\\</visual>
\\</toast>
    ;
        // formatting XML based on user input
        const xml_text: []const u8 = try std.fmt.allocPrint(alloc, xml_template, .{ duration_string, self.title, self.message, self.icon_loc_abs });
        defer alloc.free(xml_text);

        // defining constant variables for the other portions of the ps1 script
        const first_ps_script_line: []const u8 = "$xml = @\"";
        const last_five_ps_script_lines: []const u8 = 
\\"@
\\$XmlDocument = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]::New()
\\$XmlDocument.loadXml($xml)
\\$AppId = '{1AC14E77-02E7-4E5D-B744-2EB1AE5198B7}\WindowsPowerShell\v1.0\powershell.exe'
\\[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]::CreateToastNotifier($AppId).Show($XmlDocument)
;
        return try std.fmt.allocPrint(alloc, "{s}\n{s}\n{s}", .{ first_ps_script_line, xml_text, last_five_ps_script_lines });
    }
};

fn createAndRunTempFolderScript(alloc: std.mem.Allocator, ps_script: []const u8) !void {
    // creating GUID v4 for temporary file
    const guid_slice: []u8 = try get_uuid.createHeapGuidStr(alloc);
    defer alloc.free(guid_slice);

    // finding the location of the temp folder on the target machine
    const temp_dir_str: []u8 = try strmod.getTempDir(alloc);
    defer alloc.free(temp_dir_str); 

    // creating a location for the PowerShell script within temp folder
    const paths = [_][]const u8{ temp_dir_str, guid_slice };
    const ps_path_no_ext_slice: []u8 = try std.fs.path.join(alloc, &paths);
    defer alloc.free(ps_path_no_ext_slice); // freeing memory once no longer needed to avoid big cleanup on func end
    const ps_full_path: []u8 = try std.fmt.allocPrint(alloc, "{s}.ps1", .{ps_path_no_ext_slice});
    defer alloc.free(ps_full_path);

    // getting the toast template and relevant bytes
    const bom_utf8: [3]u8 = [3]u8{ 0xef, 0xbb, 0xbf };
    const toast_output_str: []const u8 = try std.fmt.allocPrint(alloc, "{s}{s}", .{bom_utf8, ps_script});
    defer alloc.free(toast_output_str);

    // creating the temp ps1 file and writing the formed script content to it
    const ps_file: std.fs.File = try std.fs.createFileAbsolute(ps_full_path, .{});
    try ps_file.writeAll(toast_output_str);
    ps_file.close(); // closing the file handle so that it can be opened by PowerShell (ext process)

    // running the PowerShell command as a child process
    const ps_argv = [_][]const u8{ "PowerShell", "-ExecutionPolicy", "Bypass", "-File", ps_full_path };
    var ps_child_proc = std.process.Child.init(&ps_argv, alloc);
    try ps_child_proc.spawn(); // attempting to start the PowerShell cmd
    _ = try ps_child_proc.wait(); // waits for execution completion before cleaning all resources

    return;
}

