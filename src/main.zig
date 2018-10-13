const std = @import("std");
const warn = std.debug.warn;
const os = std.os;
const gl = @cImport({@cInclude("GLFW/glfw3.h");});

// Convert a C pointer parameter of the form
// `*type` such as `*c_int` to `?[*]type` or `?[*]const type`.
// This is necessary because in C pointers can be null and
// point to one or more items which is exactly `?[*]type` in zig.
//
// From: https://github.com/andrewrk/tetris/src/c.zig ptr
// This is using labeled breaks, see [Blocks](https://ziglang.org/documentation/master/#blocks),
// to return the const or non-const optional (aka. nullable) pointer.
pub fn ptr(p: var) t: {
    const T = @typeOf(p);
    const info = @typeInfo(@typeOf(p)).Pointer;
    break :t if (info.is_const) ?[*]const info.child else ?[*]info.child;
} {
    const ReturnType = t: {
        const T = @typeOf(p);
        const info = @typeInfo(@typeOf(p)).Pointer;
        break :t if (info.is_const) ?[*]const info.child else ?[*]info.child;
    };
    return @ptrCast(ReturnType, p);
}

extern fn errorCallback(err: c_int, description: ?[*]const u8) void {
    warn("GLFW Error: {}\n", description);
    os.abort();
}

extern fn windowCloseCallback(window: ?*gl.GLFWwindow) void {
    warn("windwoCloseCallback called window={*}\n", window);
}

extern fn keyCallback(window: ?*gl.GLFWwindow, key: c_int,  scancode: c_int, action: c_int, mods: c_int) void {
    warn("keyCallback: key={x} scancode={x} action={x} mods={x}\n", key, scancode, action, mods);
    if ((key == gl.GLFW_KEY_ESCAPE) and (action == gl.GLFW_PRESS)) {
        gl.glfwSetWindowShouldClose(window, gl.GLFW_TRUE);
    }
}

pub fn errorExit(strg: []const u8) noreturn {
    warn("{}", strg);
    os.abort();
}

pub fn main() void {
    warn("main:+\n");
    defer warn("main:-\n");

    // Ignore the previous callback funtion returned, we know it'll be null
    _ = gl.glfwSetErrorCallback(errorCallback);

    if (gl.glfwInit() == gl.GL_FALSE) {
        errorExit("glfwInit failed\n");
    }
    defer gl.glfwTerminate();

    var window = gl.glfwCreateWindow(640, 480, c"My Title", null, null) orelse {
        errorExit("glfwCreateWindow failed\n");
    };
    defer gl.glfwDestroyWindow(window);

    gl.glfwWindowHint(gl.GLFW_CONTEXT_VERSION_MAJOR, 3);
    gl.glfwWindowHint(gl.GLFW_CONTEXT_VERSION_MINOR, 2);

    // Ignore the previous callback funtion returned, we know it'll be null
    _ = gl.glfwSetWindowCloseCallback(window, windowCloseCallback);

    // Ignore the previous callback funtion returned, we know it'll be null
    _ = gl.glfwSetKeyCallback(window, keyCallback);

    gl.glfwMakeContextCurrent(window);

    var width: c_int = undefined;
    var height: c_int = undefined;
    gl.glfwGetFramebufferSize(window, ptr(&width), ptr(&height));
    warn("main: framebuffer width={} height={}\n", width, height);

    while (gl.glfwWindowShouldClose(window) == gl.GL_FALSE) {
        gl.glfwPollEvents();
    }
}
