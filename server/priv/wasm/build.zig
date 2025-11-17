const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const optimize = .ReleaseSmall;

    // Find all .zig files in handlers/ directory
    const handlers_dir = "handlers";
    const build_dir = "build";

    // List of handler files to compile
    const handlers = [_][]const u8{
        "ftl",
        "po",
        "properties",
    };

    // Compile each handler
    inline for (handlers) |handler_name| {
        const source_path = b.fmt("{s}/{s}.zig", .{ handlers_dir, handler_name });

        const lib = b.addExecutable(.{
            .name = handler_name,
            .root_source_file = b.path(source_path),
            .target = target,
            .optimize = optimize,
        });

        lib.entry = .disabled;
        lib.rdynamic = true;

        // Output to build/ directory
        const install = b.addInstallArtifact(lib, .{
            .dest_dir = .{ .override = .{ .custom = build_dir } },
        });

        b.getInstallStep().dependOn(&install.step);
    }
}
