### Zig Build for the OpenCL ICD Loader

This project builds the [OpenCL ICD](https://github.com/KhronosGroup/OpenCL-ICD-Loader) with the Zig Build System. The OpenCL ICD takes care of finding appropriate drivers across different hardware and operating systems.

Traditionally, you install the ICD on your system with `sudo apt install ocl-icd-opencl-dev` and use `$(CC) ... -lOpenCL` to build your program.

This is not desirable becuase the linking is dynamic against `libOpenCL.so`.

Static linking with zig provides better portability and reliability.

### Usage
Add the right release to your `build.zig.zon`
```
zig fetch --save https://github.com/e253/zig-ocl/archive/refs/tags/v3.0.16.tar.gz
```


and add the following to your `build.zig`
```zig
pub fn build(b: *std.Build) void {
    const ocl_icd = b.dependency("zig-ocl", .{
        .target = target,
        .optimize = optimize
    });
    your_compilation.linkLibrary(ocl_icd.artifact("opencl")); 
}
```

Also, see how `test.c` is built in the `build.zig` of this repository.

### Supported Platforms

Tested on
- [x] Windows
- [x] Linux (Ubuntu 22.04 WSL)
- [ ] MacOS 
