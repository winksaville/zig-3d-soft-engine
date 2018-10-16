const std = @import("std");
const assert = std.debug.assert;
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

extern fn windowPosCallback(window: ?*gl.GLFWwindow, xpos: c_int, ypos: c_int) void {
    warn("windowPosCallback: xpos={} ypos={}\n", xpos, ypos);
}

extern fn cursorEnterCallback(window: ?*gl.GLFWwindow, entered: c_int) void {
    warn("cursorEnterCallback: entered={}\n", entered);
}

extern fn cursorPosCallback(window: ?*gl.GLFWwindow, xpos: f64, ypos: f64) void {
    warn("cursorPosCallback: xpos={} ypos={}\n", xpos, ypos);
}

extern fn mouseButtonCallback(window: ?*gl.GLFWwindow, button: c_int, action: c_int, mods: c_int) void {
    warn("keyCallback: button={x} action={x} mods={x}\n", button, action, mods);
}

pub fn errorExit(strg: []const u8) noreturn {
    warn("{}", strg);
    os.abort();
}

fn getActiveTexture() gl.GLuint {
    var texture: gl.GLint = undefined;
    gl.glGetIntegerv(gl.GL_ACTIVE_TEXTURE, ptr(&texture));
    return @intCast(gl.GLuint, texture);
}

fn setActiveTexture(texture: gl.GLuint) void {
    gl.glActiveTexture(texture);
}

fn fboStatusStr(fbo_status: gl.GLuint) []const u8 {
    var fbo_status_str: []const u8 = switch (fbo_status) {
        gl.GL_FRAMEBUFFER_UNDEFINED => "UNDEFINED",
        gl.GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT => "INCOMPLETE_ATTACHMENT",
        gl.GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT => "INCOMPLETE_MISSING_ATTACHMENT",
        gl.GL_FRAMEBUFFER_UNSUPPORTED => "UNSUPPORTED",
        gl.GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE => "INCOMPLETE_MULTISAMPLE",
        gl.GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS => "INCOMPLETE_LAYER_TARGETS",
        else => "<unknown>",
    };
    return fbo_status_str;
}

pub fn main() !void {
    warn("main:+\n");
    defer warn("main:-\n");

    var pAllocator = heap.c_allocator;
    
    // Ignore the previous callback funtion returned
    _ = gl.glfwSetErrorCallback(errorCallback);

    // Init glfw
    if (gl.glfwInit() == gl.GL_FALSE) {
        errorExit("glfwInit failed\n");
    }
    defer gl.glfwTerminate();
    gl.glfwWindowHint(gl.GLFW_CONTEXT_VERSION_MAJOR, 3);
    gl.glfwWindowHint(gl.GLFW_CONTEXT_VERSION_MINOR, 2);

    // Create a window
    var width: gl.GLint = 640;
    var height: gl.GLint = 480;
    var window = gl.glfwCreateWindow(width, height, c"My Title", null, null) orelse {
        errorExit("glfwCreateWindow failed\n");
    };
    defer gl.glfwDestroyWindow(window);

    // Setup input event call backs, ignore previous values
    _ = gl.glfwSetWindowCloseCallback(window, windowCloseCallback);
    _ = gl.glfwSetWindowPosCallback(window, windowPosCallback);
    _ = gl.glfwSetKeyCallback(window, keyCallback);
    _ = gl.glfwSetCursorEnterCallback(window, cursorEnterCallback);
    _ = gl.glfwSetCursorPosCallback(window, cursorPosCallback);
    _ = gl.glfwSetMouseButtonCallback(window, mouseButtonCallback);

    // Make the window context current and setup swap interval
    gl.glfwMakeContextCurrent(window);
    gl.glfwSwapInterval(1);

    // Allocate a pixel buffer
    var num_pixels: usize = @intCast(usize, width * height);
    var pixels: []u8 = undefined;
    pixels = try pAllocator.alignedAlloc(u8, 16, num_pixels * 3);
    defer pAllocator.free(pixels);

    // Clear the pixels
    for (pixels) |*pixel| {
        pixel.* = 0;
    }

    // Create a texture.
    // from https://www.programcreek.com/python/example/95549/OpenGL.GL.glTexImage2D
    var tid: gl.GLuint = undefined;
    gl.glGenTextures(1, ptr(&tid));
    gl.glBindTexture(gl.GL_TEXTURE_2D, tid);
    gl.glPixelStorei(gl.GL_UNPACK_ALIGNMENT, 1);
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGB, width, height, 0,
                    gl.GL_RGB, gl.GL_UNSIGNED_BYTE, @ptrCast(*const c_void, &pixels[0]));
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MAG_FILTER, gl.GL_LINEAR);
    gl.glTexParameteri(gl.GL_TEXTURE_2D, gl.GL_TEXTURE_MIN_FILTER, gl.GL_LINEAR);

    // Generate a framebuffer object, fb0 and bind it
    var fbo: gl.GLuint = undefined;
    gl.glGenFramebuffers(1, ptr(&fbo));
    warn("frame_buffer[0]={}\n", fbo);
    defer gl.glDeleteFramebuffers(1, ptr(&fbo));

    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, fbo);
    var fbo_status = gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER);
    warn("fb0_status={} \"{}\"\n", fbo_status, fboStatusStr(fbo_status));

    // Initialization
    gl.glClearColor(0.0, 0.0, 0.0, 0.0); // black
    gl.glEnable(gl.GL_BLEND);
    gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA);
    gl.glPixelStorei(gl.GL_UNPACK_ALIGNMENT, 1);
    gl.glViewport(0, 0, width, height);

    // Keep track of the previous time
    var prev_time = gl.glfwGetTime();

    while (gl.glfwWindowShouldClose(window) == gl.GL_FALSE) {
        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT | gl.GL_STENCIL_BUFFER_BIT);

        // Compute elapsed and prev_time
        const now_time = gl.glfwGetTime();
        const elapsed = now_time - prev_time;
        prev_time = now_time;

        // Change all pixels on each frame.
        for (pixels) |*pixel| {
            pixel.* +%= 1;
        }

        // Dislay the "current" buffer for the remaining glfwSwapInterval.
        // See https://www.glfw.org/docs/3.0/window.html#window_swap for more info.
        gl.glfwSwapBuffers(window);

        // Check for events
        gl.glfwPollEvents();
        //warn(".");
    }
}
