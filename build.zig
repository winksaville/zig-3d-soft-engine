const Builder = @import("std").build.Builder;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const windows = b.option(bool, "windows", "create windows build") orelse false;

    var exe = b.addExecutable("3d-soft-engine", "src/main.zig");
    exe.setBuildMode(mode);

    if (windows) {
        exe.setTarget(builtin.Arch.x86_64, builtin.Os.windows, builtin.Environ.gnu);
    }

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("SDL2");
    exe.setOutputPath("./3d-soft-engine");
    
    b.default_step.dependOn(&exe.step);

    b.installArtifact(exe);
}

