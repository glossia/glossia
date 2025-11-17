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

/// Simple but robust iOS .strings file validator
/// Validates basic structure: "key" = "value"; with comments
export fn validate(content_ptr: [*]const u8, content_len: usize) i32 {
    const content = content_ptr[0..content_len];

    var lines = std.mem.split(u8, content, "\n");
    var has_entry = false;
    var in_block_comment = false;

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");

        // Handle block comment state
        if (in_block_comment) {
            if (std.mem.indexOf(u8, line, "*/")) |_| {
                in_block_comment = false;
            }
            continue;
        }

        // Check for start of block comment
        if (std.mem.indexOf(u8, line, "/*")) |_| {
            // Check if it also ends on the same line
            if (std.mem.indexOf(u8, line, "*/")) |_| {
                // Block comment opens and closes on same line
                continue;
            } else {
                in_block_comment = true;
                continue;
            }
        }

        // Skip empty lines
        if (trimmed.len == 0) continue;

        // Skip line comments (// or #)
        if (std.mem.startsWith(u8, trimmed, "//") or std.mem.startsWith(u8, trimmed, "#")) continue;

        // Check for "key" = "value"; format
        // Must have = and end with semicolon
        var has_equals = false;
        for (trimmed) |c| {
            if (c == '=') {
                has_equals = true;
                break;
            }
        }

        if (!has_equals) return -1;

        // Must end with semicolon (after trimming)
        if (trimmed[trimmed.len - 1] != ';') return -1;

        has_entry = true;
    }

    // Must have at least one valid entry
    if (!has_entry) return -1;

    return 0;
}

test "validate accepts valid strings content" {
    const valid_strings =
        \\"hello" = "world";
        \\"foo" = "bar";
        \\
    ;
    const result = validate(valid_strings.ptr, valid_strings.len);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "validate accepts strings with // comments" {
    const strings_with_comments =
        \\// Comment
        \\"hello" = "world";
        \\
    ;
    const result = validate(strings_with_comments.ptr, strings_with_comments.len);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "validate accepts strings with # comments" {
    const strings_with_comments =
        \\# Comment
        \\"hello" = "world";
        \\
    ;
    const result = validate(strings_with_comments.ptr, strings_with_comments.len);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "validate accepts strings with block comments" {
    const strings_with_block =
        \\/* Block comment */
        \\"hello" = "world";
        \\
    ;
    const result = validate(strings_with_block.ptr, strings_with_block.len);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "validate accepts strings with multiline block comments" {
    const strings_with_multiline =
        \\/*
        \\ * Multiline comment
        \\ */
        \\"hello" = "world";
        \\
    ;
    const result = validate(strings_with_multiline.ptr, strings_with_multiline.len);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "validate accepts strings with empty lines" {
    const strings_with_empty =
        \\"hello" = "world";
        \\
        \\"foo" = "bar";
        \\
    ;
    const result = validate(strings_with_empty.ptr, strings_with_empty.len);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "validate rejects strings without semicolon" {
    const invalid_strings = "\"hello\" = \"world\"\n";
    const result = validate(invalid_strings.ptr, invalid_strings.len);
    try std.testing.expectEqual(@as(i32, -1), result);
}

test "validate rejects strings without equals" {
    const invalid_strings = "\"hello\" \"world\";\n";
    const result = validate(invalid_strings.ptr, invalid_strings.len);
    try std.testing.expectEqual(@as(i32, -1), result);
}

test "validate rejects empty content" {
    const empty = "";
    const result = validate(empty.ptr, empty.len);
    try std.testing.expectEqual(@as(i32, -1), result);
}
