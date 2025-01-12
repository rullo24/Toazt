// std zig includes
const std = @import("std");

pub fn getTempDir(alloc: std.mem.Allocator) ![]u8 {
    // checking system env vars for "TEMP"
    const temp_dir_opt: ?[]u8 = std.process.getEnvVarOwned(alloc, "TEMP") catch null;
    if (temp_dir_opt) |temp_dir| { // returns if a value was found (!= NULL)
        return temp_dir;
    }

    // checking system env vars for "TMP"
    const tmp_dir_opt: ?[]u8 = std.process.getEnvVarOwned(alloc, "TMP") catch null;
    if (tmp_dir_opt) |tmp_dir| { // returns if a value was found (!= NULL)
        return tmp_dir;
    }

    return error.InvalidVarErr;
}

pub fn absolutePathIsValid(path: []const u8) bool {
    // ensuring that the provided path is absolute
    if (!std.fs.path.isAbsolute(path)) {
        return false;
    }

    // checking if the path is accessible --> trying to open file
    const potential_null: ?void = std.fs.accessAbsolute(path, .{}) catch null;
    if (potential_null == null) {
        return false;
    }

    return true;
}
