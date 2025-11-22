const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    // Add httpz as a dependency
    const httpz = b.dependency("httpz", .{
        .target = target,
        .optimize = optimize,
    });
    const pg = b.dependency("pg", .{
        .target = target,
        .optimize = optimize,
    });
    const dotenv = b.dependency("dotenv", .{
        .target = target,
        .optimize = optimize,
    });
    const logz = b.dependency("logz", .{
        .target = target,
        .optimize = optimize,
    });
    const zul = b.dependency("zul", .{
        .target = target,
        .optimize = optimize,
    });
    const otp_zig = b.dependency("otp_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const cache = b.dependency("cache", .{
        .target = target,
        .optimize = optimize,
    });

    const mod = b.addModule("vendor_server", .{
        .root_source_file = b.path("src/root.zig"),

        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "vendor_server",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),

            .target = target,
            .optimize = optimize,

            .imports = &.{
                .{ .name = "vendor_server", .module = mod },
                .{ .name = "httpz", .module = httpz.module("httpz") },
                .{ .name = "pg", .module = pg.module("pg") },
                .{ .name = "dotenv", .module = dotenv.module("dotenv") },
                .{ .name = "logz", .module = logz.module("logz") },
                .{ .name = "zul", .module = zul.module("zul") },
                .{ .name = "otp_zig", .module = otp_zig.module("otp") },
                .{ .name = "cache", .module = cache.module("cache") },
            },
        }),
    });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
