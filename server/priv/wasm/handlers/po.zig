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

/// Simple but robust PO file validator
/// Validates basic structure: msgid/msgstr pairing with proper quoted strings
export fn validate(content_ptr: [*]const u8, content_len: usize) i32 {
    const content = content_ptr[0..content_len];

    var msgid_count: usize = 0;
    var msgstr_count: usize = 0;
    var lines = std.mem.split(u8, content, "\n");

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");

        // Skip empty lines
        if (trimmed.len == 0) continue;

        // Skip comments
        if (trimmed[0] == '#') continue;

        // Check for msgid
        if (std.mem.startsWith(u8, trimmed, "msgid")) {
            msgid_count += 1;

            // Must have space and quoted string after msgid
            if (trimmed.len < 7) return -1; // "msgid " is 6 chars
            const after = std.mem.trimLeft(u8, trimmed[5..], " \t");
            if (after.len == 0 or after[0] != '"') return -1;
            continue;
        }

        // Check for msgid_plural
        if (std.mem.startsWith(u8, trimmed, "msgid_plural")) {
            if (trimmed.len < 14) return -1;
            const after = std.mem.trimLeft(u8, trimmed[12..], " \t");
            if (after.len == 0 or after[0] != '"') return -1;
            continue;
        }

        // Check for msgctxt (context)
        if (std.mem.startsWith(u8, trimmed, "msgctxt")) {
            if (trimmed.len < 9) return -1;
            const after = std.mem.trimLeft(u8, trimmed[7..], " \t");
            if (after.len == 0 or after[0] != '"') return -1;
            continue;
        }

        // Check for msgstr or msgstr[n]
        if (std.mem.startsWith(u8, trimmed, "msgstr")) {
            msgstr_count += 1;

            // Check for msgstr[n] format
            if (trimmed.len > 6 and trimmed[6] == '[') {
                // Find closing ]
                var found_bracket = false;
                for (trimmed[7..], 0..) |c, i| {
                    if (c == ']') {
                        found_bracket = true;
                        // Check for quoted string after ]
                        const after = std.mem.trimLeft(u8, trimmed[7 + i + 1 ..], " \t");
                        if (after.len == 0 or after[0] != '"') return -1;
                        break;
                    }
                    // Only digits allowed inside brackets
                    if (c < '0' or c > '9') return -1;
                }
                if (!found_bracket) return -1;
            } else {
                // Regular msgstr
                if (trimmed.len < 8) return -1;
                const after = std.mem.trimLeft(u8, trimmed[6..], " \t");
                if (after.len == 0 or after[0] != '"') return -1;
            }
            continue;
        }

        // Lines starting with " are continuation strings
        if (trimmed[0] == '"') {
            // Valid continuation - must end with "
            if (trimmed[trimmed.len - 1] != '"') return -1;
            continue;
        }

        // Any other non-empty, non-comment line is invalid
        return -1;
    }

    // Must have at least one msgid and one msgstr
    if (msgid_count == 0 or msgstr_count == 0) return -1;

    // msgid and msgstr counts should match (accounting for plurals)
    // For simplicity, we just check both exist
    if (msgid_count > msgstr_count) return -1;

    return 0;
}

test "validate accepts valid PO content" {
    const valid_po =
        \\msgid "hello"
        \\msgstr "world"
        \\
    ;
    const result = validate(valid_po.ptr, valid_po.len);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "validate accepts PO with comments" {
    const po_with_comments =
        \\# Comment
        \\msgid "hello"
        \\msgstr "world"
        \\
    ;
    const result = validate(po_with_comments.ptr, po_with_comments.len);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "validate accepts PO with empty msgstr" {
    const po_with_empty =
        \\msgid "hello"
        \\msgstr ""
        \\
    ;
    const result = validate(po_with_empty.ptr, po_with_empty.len);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "validate accepts simple PO with multiple entries" {
    const po_with_multiple =
        \\msgid "hello"
        \\msgstr "bonjour"
        \\
        \\msgid "world"
        \\msgstr "monde"
        \\
    ;
    const result = validate(po_with_multiple.ptr, po_with_multiple.len);
    try std.testing.expectEqual(@as(i32, 0), result);
}

test "validate rejects PO missing msgid" {
    const invalid_po = "msgstr \"world\"\n";
    const result = validate(invalid_po.ptr, invalid_po.len);
    try std.testing.expectEqual(@as(i32, -1), result);
}

test "validate rejects PO missing msgstr" {
    const invalid_po = "msgid \"hello\"\n";
    const result = validate(invalid_po.ptr, invalid_po.len);
    try std.testing.expectEqual(@as(i32, -1), result);
}

test "validate rejects PO with invalid syntax" {
    const invalid_po = "this is not valid\n";
    const result = validate(invalid_po.ptr, invalid_po.len);
    try std.testing.expectEqual(@as(i32, -1), result);
}
