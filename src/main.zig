const std = @import("std");
const warn = std.debug.warn;
const os = std.os;
const gl = @cImport({
    @cInclude("epoxy/gl.h");
    @cInclude("GLFW/glfw3.h");
});
const heap = std.heap;

// Convert a C pointer parameter of the form
// `*type` such as `*c_int` to `?[*]type` or `?[*]const type`.
// Thanks to [dbanstra on IRC](http://bit.ly/2Ommi0V).
fn cvrtPtrToOptionalPtrArray(comptime T: type) type {
  const info = @typeInfo(T).Pointer;
  return if (info.is_const) ?[*]const info.child else ?[*]info.child;
}

pub fn ptr(p: var) cvrtPtrToOptionalPtrArray(@typeOf(p)) {
  return @ptrCast(cvrtPtrToOptionalPtrArray(@typeOf(p)), p);
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

pub fn main() !void {
    warn("main:+\n");
    defer warn("main:-\n");

    var pAllocator = heap.c_allocator;
    
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

    // Allocate a pixel buffer and associate it with a texture
    var num_pixels: usize = @intCast(usize, width * height);
    var pixels = try pAllocator.alignedAlloc(u8, 16, num_pixels * 4); // Fails if alignment > 16, Why?
    defer pAllocator.free(pixels);
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA8, width, height,
            0, gl.GL_RGBA8, gl.GL_UNSIGNED_BYTE, @ptrCast(*const c_void, &pixels[0]));

    var frame_buffer: gl.GLuint = undefined;
    gl.glGenFramebuffers(1, ptr(&frame_buffer));
    warn("frame_buffer[0]={}\n", frame_buffer);
    defer gl.glDeleteFramebuffers(1, ptr(&frame_buffer));

    while (gl.glfwWindowShouldClose(window) == gl.GL_FALSE) {
        gl.glfwPollEvents();
    }
}
