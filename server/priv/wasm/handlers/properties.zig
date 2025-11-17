const std = @import("std");

// Allocator for Wasm memory management
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

/// Allocate memory accessible from host
export fn alloc(size: usize) ?[*]u8 {
    const buf = allocator.alloc(u8, size) catch return null;
    return buf.ptr;
}

/// Free memory allocated by alloc
export fn dealloc(ptr: [*]u8, size: usize) void {
    const slice = ptr[0..size];
    allocator.free(slice);
}

/// Simple but robust Java .properties file validator
/// Validates basic structure: key=value or key:value pairs with comments
export fn validate(content_ptr: [*]const u8, content_len: usize) i32 {
    const content = content_ptr[0..content_len];

    var lines = std.mem.split(u8, content, "\n");
    var has_entry = false;

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");

        // Skip empty lines
        if (trimmed.len == 0) continue;

        // Skip comments (# or !)
        if (trimmed[0] == '#' or trimmed[0] == '!') continue;

        // Check for key=value or key:value format
        var has_separator = false;
        for (trimmed) |c| {
            if (c == '=' or c == ':') {
                has_separator = true;
                has_entry = true;
                break;
            }
        }

        // Non-empty, non-comment line must have a separator
        if (!has_separator) return -1;
    }

    // Must have at least one valid entry
    if (!has_entry) return -1;

    return 0;
}
