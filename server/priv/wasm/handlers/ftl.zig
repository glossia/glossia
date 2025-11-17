const std = @import("std");

// Allocator for Wasm memory management
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = gpa.allocator();

// Memory for passing strings between Wasm and host
var output_buffer: [1024 * 1024]u8 = undefined; // 1MB buffer
var output_len: usize = 0;

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

/// Get pointer to output buffer
export fn get_output_ptr() [*]u8 {
    return &output_buffer;
}

/// Get length of output buffer
export fn get_output_len() usize {
    return output_len;
}

/// Validate FTL content
/// Returns 0 if valid, -1 if invalid
export fn validate(content_ptr: [*]const u8, content_len: usize) i32 {
    _ = content_ptr;
    _ = content_len;
    // For now, accept all content as valid
    // TODO: Add actual FTL syntax validation
    return 0;
}

const TranslatableString = struct {
    index: usize,
    key: []const u8,
    value: []const u8,
};

/// Check if a line contains only variables like {$var}
fn isOnlyVariables(text: []const u8) bool {
    var in_var = false;
    var has_text = false;

    for (text) |c| {
        if (c == '{') {
            in_var = true;
        } else if (c == '}') {
            in_var = false;
        } else if (!in_var and c != ' ' and c != '\t' and c != '$') {
            has_text = true;
            break;
        }
    }

    return !has_text;
}

/// Extract translatable strings from FTL content
/// Returns JSON array of {index, key, value} objects
/// Result is written to output_buffer
export fn extract_strings(content_ptr: [*]const u8, content_len: usize) i32 {
    const content = content_ptr[0..content_len];

    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    list.appendSlice("[") catch return -1;

    var lines = std.mem.split(u8, content, "\n");
    var index: usize = 0;
    var first = true;

    while (lines.next()) |line| : (index += 1) {
        const trimmed = std.mem.trim(u8, line, " \t\r");

        // Skip comments and empty lines
        if (trimmed.len == 0 or trimmed[0] == '#') continue;

        // Check for key = value pattern
        if (std.mem.indexOf(u8, line, "=")) |eq_pos| {
            const key = std.mem.trim(u8, line[0..eq_pos], " \t");
            const value = std.mem.trim(u8, line[eq_pos + 1..], " \t");

            // Skip if empty or only variables
            if (value.len == 0 or isOnlyVariables(value)) continue;

            // Skip indented lines (attributes)
            if (line[0] == ' ' or line[0] == '\t') continue;

            // Add to JSON array
            if (!first) {
                list.appendSlice(",") catch return -1;
            }
            first = false;

            // Build JSON object: {"index":N,"key":"...","value":"..."}
            list.appendSlice("{\"index\":") catch return -1;
            const index_str = std.fmt.allocPrint(allocator, "{d}", .{index}) catch return -1;
            defer allocator.free(index_str);
            list.appendSlice(index_str) catch return -1;

            list.appendSlice(",\"key\":\"") catch return -1;
            list.appendSlice(key) catch return -1;

            list.appendSlice("\",\"value\":\"") catch return -1;
            // Escape quotes in value
            for (value) |c| {
                if (c == '"') {
                    list.appendSlice("\\\"") catch return -1;
                } else {
                    list.append(c) catch return -1;
                }
            }
            list.appendSlice("\"}") catch return -1;
        }
    }

    list.appendSlice("]") catch return -1;

    // Copy to output buffer
    const result = list.items;
    if (result.len > output_buffer.len) return -1;

    @memcpy(output_buffer[0..result.len], result);
    output_len = result.len;

    return 0;
}

/// Apply translations to FTL content
/// translations_ptr points to JSON array: [{"index":N,"translation":"..."}]
/// Result is written to output_buffer
export fn apply_translations(
    content_ptr: [*]const u8,
    content_len: usize,
    translations_ptr: [*]const u8,
    translations_len: usize,
) i32 {
    const content = content_ptr[0..content_len];
    const translations_json = translations_ptr[0..translations_len];

    // Parse translations JSON (simple parser for our specific format)
    var translation_map = std.StringHashMap([]const u8).init(allocator);
    defer translation_map.deinit();

    // Simple JSON parsing - look for "index":N,"translation":"..."
    var i: usize = 0;
    while (i < translations_json.len) {
        // Find "index":
        if (std.mem.indexOf(u8, translations_json[i..], "\"index\":")) |idx_pos| {
            i += idx_pos + 8; // Skip "index":

            // Read index number
            const num_start = i;
            while (i < translations_json.len and translations_json[i] >= '0' and translations_json[i] <= '9') : (i += 1) {}
            const index_str = translations_json[num_start..i];

            // Find "translation":"
            if (std.mem.indexOf(u8, translations_json[i..], "\"translation\":\"")) |trans_pos| {
                i += trans_pos + 15; // Skip "translation":"

                // Read translation value (until unescaped ")
                const trans_start = i;
                while (i < translations_json.len) : (i += 1) {
                    if (translations_json[i] == '"' and (i == trans_start or translations_json[i-1] != '\\')) {
                        const translation = translations_json[trans_start..i];
                        translation_map.put(index_str, translation) catch return -1;
                        break;
                    }
                }
            }
        } else {
            break;
        }
    }

    // Rebuild content with translations
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    var lines = std.mem.split(u8, content, "\n");
    var line_index: usize = 0;

    while (lines.next()) |line| : (line_index += 1) {
        // Check if this line has a translation
        const index_str = std.fmt.allocPrint(allocator, "{d}", .{line_index}) catch return -1;
        defer allocator.free(index_str);

        if (translation_map.get(index_str)) |translation| {
            // Replace the value part
            if (std.mem.indexOf(u8, line, "=")) |eq_pos| {
                const key_part = line[0..eq_pos];
                result.appendSlice(key_part) catch return -1;
                result.appendSlice("= ") catch return -1;
                result.appendSlice(translation) catch return -1;
            } else {
                result.appendSlice(line) catch return -1;
            }
        } else {
            result.appendSlice(line) catch return -1;
        }

        result.append('\n') catch return -1;
    }

    // Remove trailing newline if original didn't have one
    if (content.len > 0 and content[content.len - 1] != '\n') {
        if (result.items.len > 0 and result.items[result.items.len - 1] == '\n') {
            _ = result.pop();
        }
    }

    // Copy to output buffer
    const final_result = result.items;
    if (final_result.len > output_buffer.len) return -1;

    @memcpy(output_buffer[0..final_result.len], final_result);
    output_len = final_result.len;

    return 0;
}
