// std zig includes
const std: type = @import("std");
const c: type = std.c;
const arrlist = std.ArrayList;

const GUID = extern struct {
    data1: u32,
    data2: u16,
    data3: u16,
    data4: [8]u8,
};
extern "ole32" fn CoCreateGuid(p_guid: *GUID) u32; // declaring C function as external

fn createGuid(alloc: std.mem.Allocator) !*GUID {
    // alloc memory for the GUID (to avoid stacked value being popped on scope leave)
    const p_guid: *GUID = try alloc.create(GUID);
    errdefer alloc.destroy(p_guid);

    // generate the GUID
    const createGuid_i32_res: u32 = CoCreateGuid(p_guid);
    if (createGuid_i32_res != 0) {
        std.debug.print("ERROR: failed to create the GUID using the win32 CoCreateGuid func\n", .{});
        return error.FailedToCreateGuid;
    }

    return p_guid; // return GUID mem ptr if successful
}

// GUID: u32[0..8]-u16[0..4]-u16[0..4]-u8[0..2]-u8[2..8]
pub fn createHeapGuidStr(alloc: std.mem.Allocator) ![]u8 {
    // creating GUID struct for use in windows func
    const p_guid: *GUID = createGuid(alloc) catch |guid_create_err| {
        std.debug.print("ERROR: failed to create a GUID using CoCreateGuid()\n", .{});
        return guid_create_err;
    };
    defer alloc.destroy(p_guid); // freeing the alloc'd memory at the end of the function scope

    // need to split the []u8 slice
    var guid_list: std.ArrayList(u8) = arrlist(u8).init(alloc);

    // lowercase hex formatting the p_guid integer data as per GUID v4 expectations
    guid_list.writer().print("{x}-{x}-{x}-", .{p_guid.data1, p_guid.data2, p_guid.data3}) catch |init_format_err| {
        std.debug.print("ERROR: failed to write the initial hex values to the std.ArrayList(u8)\n", .{});
        return init_format_err;
    };

    
    // iterating over all values within the data4 [8]u8 array
    for (0..p_guid.data4.len) |i| {
        guid_list.writer().print("{x}", .{p_guid.data4[i]}) catch |final_format_err| {
            std.debug.print("ERROR: failed to write the final hex values to the std.ArrayList(u8)\n", .{});
            return final_format_err;
        };

        // adding separator between first 2 and last 6 bytes "-"
        if (i == 1) {
            guid_list.append('-') catch |dash_err| {
            std.debug.print("ERROR: failed to write the final dash to the std.ArrayList(u8)\n", .{});
            return dash_err;
            };
        } 
    }

    return try guid_list.toOwnedSlice(); // converted to slice to avoid memory freeing
}
