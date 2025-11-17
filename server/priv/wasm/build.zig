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
        "strings",
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

        // Add test step for this handler
        const test_step = b.addTest(.{
            .root_source_file = b.path(source_path),
            .target = b.host,
        });

        const run_test = b.addRunArtifact(test_step);
        b.step(b.fmt("test-{s}", .{handler_name}), b.fmt("Run {s} tests", .{handler_name})).dependOn(&run_test.step);
    }

    // Add a "test" step that runs all handler tests
    const test_step = b.step("test", "Run all handler tests");
    inline for (handlers) |handler_name| {
        const source_path = b.fmt("{s}/{s}.zig", .{ handlers_dir, handler_name });
        const handler_test = b.addTest(.{
            .root_source_file = b.path(source_path),
            .target = b.host,
        });
        const run_test = b.addRunArtifact(handler_test);
        test_step.dependOn(&run_test.step);
    }
}
