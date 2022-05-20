const std = @import("std");

const bench = std.build.Pkg{
    .name = "bench",
    .path = .{ .path = "src/bench.zig" },
};

pub fn build(b: *std.build.Builder) void {
    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const fib2 = b.addExecutable("fib2", "examples/fib2.zig");
    fib2.addPackage(bench);
    fib2.setBuildMode(mode);

    const fib_build = addBench(b, "examples/fib_build.zig", .ReleaseSafe);

    const examples = [_]*std.build.LibExeObjStep{
        fib2,
        fib_build,
    };

    const examples_step = b.step("examples", "Build the examples");
    const bench_step = b.step("run", "Run the examples");

    for (examples) |example| {
        const install = b.addInstallArtifact(example);
        const run_cmd = example.run();
        run_cmd.step.dependOn(&install.step);

        examples_step.dependOn(&install.step);
        bench_step.dependOn(&run_cmd.step);
    }

    const main_tests = b.addTest("src/bench.zig");
    main_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&main_tests.step);
}

pub fn addBench(
    b: *std.build.Builder,
    path: []const u8,
    mode: std.builtin.Mode,
) *std.build.LibExeObjStep {
    const basename = std.fs.path.basename(path);
    const no_ext = if (std.mem.lastIndexOfScalar(u8, basename, '.')) |index|
        basename[0..index]
    else
        basename;

    const name = std.fmt.allocPrint(b.allocator, "zubench-{s}-{s}", .{
        no_ext,
        @tagName(mode),
    }) catch unreachable;

    const root = std.build.Pkg{
        .name = "@bench",
        .path = .{ .path = path },
        .dependencies = &.{bench},
    };

    const exe = b.addExecutable(name, "src/bench_runner.zig");
    exe.addPackage(root);
    exe.setBuildMode(mode);

    return exe;
}
