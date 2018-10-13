const std = @import("std");
const warn = std.debug.warn;
const os = std.os;
const gl = @cImport({@cInclude("GLFW/glfw3.h");});

extern fn errorCallback(err: c_int, description: ?[*]const u8) void {
    warn("GLFW Error: {}\n", description);
    os.abort();
}

pub fn main() void {
    warn("main:+\n");
    defer warn("main:-\n");

    _ = gl.glfwSetErrorCallback(errorCallback);
    if (gl.glfwInit() == gl.GL_FALSE) {
        warn("glfwInit failed\n");
        os.abort();
    }
    defer gl.glfwTerminate();
}
