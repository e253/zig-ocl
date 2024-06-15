const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const ocl_icd_upstream = b.dependency("ocl_icd", .{});
    const cl_h = b.dependency("cl_h", .{});

    const opencl = b.addStaticLibrary(.{
        .name = "OpenCL",
        .target = target,
        .optimize = optimize,
    });

    const flags = [_][]const u8{
        "-DCL_TARGET_OPENCL_VERSION=300",
        "-DCL_NO_NON_ICD_DISPATCH_EXTENSION_PROTOTYPES",
        "-DOPENCL_ICD_LOADER_VERSION_MAJOR=3",
        "-DOPENCL_ICD_LOADER_VERSION_MINOR=0",
        "-DOPENCL_ICD_LOADER_VERSION_REV=6",
    };
    opencl.addCSourceFiles(.{
        .root = ocl_icd_upstream.path("loader"),
        .files = &.{
            "icd.c",
            "icd_dispatch.c",
            "icd_dispatch_generated.c",
        },
        .flags = &flags,
    });
    if (target.result.os.tag == .windows) {
        opencl.addCSourceFiles(.{
            .root = ocl_icd_upstream.path("loader"),
            .files = &.{
                "windows/icd_windows.c",
                "windows/icd_windows_dxgk.c",
                "windows/icd_windows_envvars.c",
                "windows/icd_windows_hkr.c",
                "windows/icd_windows_apppackage.c",
            },
            .flags = &flags,
        });
        opencl.linkSystemLibrary("cfgmgr32");
        opencl.linkSystemLibrary("Ole32"); // runtimeobject
    } else if (target.result.os.tag == .linux) {
        opencl.addCSourceFiles(.{
            .root = ocl_icd_upstream.path("loader"),
            .files = &.{
                "linux/icd_linux.c",
                "linux/icd_linux_envvars.c",
            },
            .flags = &flags,
        });
        const icd_config_header = b.addConfigHeader(.{
            .style = .blank,
            .include_path = "icd_cmake_config.h",
        }, .{
            // we know this becuase musl libc linked by zig provides these functions.
            .HAVE_SECURE_GETENV = true,
            .HAVE___SECURE_GETENV = true,
        });
        opencl.addConfigHeader(icd_config_header);
    }

    opencl.addIncludePath(cl_h.path(""));
    opencl.addIncludePath(ocl_icd_upstream.path("loader"));
    opencl.linkLibC();
    opencl.linkLibCpp();
    opencl.installHeadersDirectory(cl_h.path(""), "", .{});

    b.installArtifact(opencl);

    const tests = b.addExecutable(.{
        .name = "test",
        .target = target,
        .optimize = optimize,
    });
    tests.addCSourceFile(.{ .file = b.path("test.c") });
    tests.linkLibC();
    tests.linkLibrary(opencl);

    b.installArtifact(tests);

    const test_cmd = b.addRunArtifact(tests);
    test_cmd.step.dependOn(b.getInstallStep());
    const test_step = b.step("test", "Run OpenCL Tests in `test.zig`");
    test_step.dependOn(&test_cmd.step);

    // const tests = b.addTest(.{
    //     .name = "test",
    //     .root_source_file = b.path("test.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    // tests.linkLibrary(opencl);
    // b.installArtifact(tests);

    //b.installDirectory(cl_h.path(""));
    // const exe = b.addExecutable(.{
    //     .name = "zig-ocl",
    //     .root_source_file = b.path("src/main.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // This declares intent for the executable to be installed into the
    // standard location when the user invokes the "install" step (the default
    // step when running `zig build`).
    // b.installArtifact(exe);

    // This *creates* a Run step in the build graph, to be executed when another
    // step is evaluated that depends on it. The next line below will establish
    // such a dependency.
    // const run_cmd = b.addRunArtifact(exe);

    // By making the run step depend on the install step, it will be run from the
    // installation directory rather than directly from within the cache directory.
    // This is not necessary, however, if the application depends on other installed
    // files, this ensures they will be present and in the expected location.
    // run_cmd.step.dependOn(b.getInstallStep());

    // This allows the user to pass arguments to the application in the build
    // command itself, like this: `zig build run -- arg1 arg2 etc`
    // if (b.args) |args| {
    //     run_cmd.addArgs(args);
    // }

    // This creates a build step. It will be visible in the `zig build --help` menu,
    // and can be selected like this: `zig build run`
    // This will evaluate the `run` step rather than the default, which is "install".
    // const run_step = b.step("run", "Run the app");
    // run_step.dependOn(&run_cmd.step);

    // Creates a step for unit testing. This only builds the test executable
    // but does not run it.
    // const lib_unit_tests = b.addTest(.{
    //     .root_source_file = b.path("src/root.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    // const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    // const exe_unit_tests = b.addTest(.{
    //     .root_source_file = b.path("src/main.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });

    //const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    // Similar to creating the run step earlier, this exposes a `test` step to
    // the `zig build --help` menu, providing a way for the user to request
    // running the unit tests.
    // const test_step = b.step("test", "Run unit tests");
    // test_step.dependOn(&run_lib_unit_tests.step);
    // test_step.dependOn(&run_exe_unit_tests.step);
}
