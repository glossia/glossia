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

/// Validate FTL content
/// Returns 0 if valid, -1 if invalid
export fn validate(content_ptr: [*]const u8, content_len: usize) i32 {
    const content = content_ptr[0..content_len];

    // Basic FTL syntax validation
    // Check for valid structure: keys, comments, attributes
    var lines = std.mem.split(u8, content, "\n");

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");

        // Skip empty lines and comments
        if (trimmed.len == 0 or trimmed[0] == '#') continue;

        // Check for indented lines (attributes or multiline)
        if (line.len > 0 and (line[0] == ' ' or line[0] == '\t')) {
            // Attributes should start with a dot
            const attr_trimmed = std.mem.trimLeft(u8, line, " \t");
            if (attr_trimmed.len > 0 and attr_trimmed[0] == '.') {
                // Valid attribute line
                continue;
            }
            // Might be continuation of multiline - accept for now
            continue;
        }

        // Main messages should have key = value format
        if (std.mem.indexOf(u8, trimmed, "=")) |eq_pos| {
            const key = std.mem.trim(u8, trimmed[0..eq_pos], " \t");

            // Key should not be empty
            if (key.len == 0) return -1;

            // Key should be valid identifier (alphanumeric, dash, underscore)
            for (key) |c| {
                const valid = (c >= 'a' and c <= 'z') or
                             (c >= 'A' and c <= 'Z') or
                             (c >= '0' and c <= '9') or
                             c == '-' or c == '_';
                if (!valid) return -1;
            }
        } else {
            // Non-comment, non-empty line without = is invalid
            // unless it's part of a select expression or multiline
            // For now, be permissive
            continue;
        }
    }

    return 0;
}
