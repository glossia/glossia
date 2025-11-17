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

test "validate accepts valid properties with =" {
    const valid_props = "hello=world\nfoo=bar\n";
    const result = validate(valid_props.ptr, valid_props.len);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "validate accepts valid properties with :" {
    const valid_props = "hello:world\nfoo:bar\n";
    const result = validate(valid_props.ptr, valid_props.len);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "validate accepts properties with # comments" {
    const props_with_comments =
        \\# Comment
        \\hello=world
        \\
    ;
    const result = validate(props_with_comments.ptr, props_with_comments.len);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "validate accepts properties with ! comments" {
    const props_with_comments =
        \\! Comment
        \\hello=world
        \\
    ;
    const result = validate(props_with_comments.ptr, props_with_comments.len);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "validate accepts properties with empty lines" {
    const props_with_empty =
        \\hello=world
        \\
        \\foo=bar
        \\
    ;
    const result = validate(props_with_empty.ptr, props_with_empty.len);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "validate rejects properties without separator" {
    const invalid_props = "this is not valid\n";
    const result = validate(invalid_props.ptr, invalid_props.len);
    try std.testing.expectEqual(@as(i32, -1), result);
}

test "validate rejects empty content" {
    const empty = "";
    const result = validate(empty.ptr, empty.len);
    try std.testing.expectEqual(@as(i32, -1), result);
}
