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

    // Texture properties after initialization
    const texture_min: gl.GLuint = gl.GL_TEXTURE0;
    const texture_max: gl.GLuint = gl.GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS;
    const texture_count: gl.GLuint = texture_max - texture_min;
    assert(texture_count >= 32);
    assert(getActiveTexture() == texture_min);

    // What is the current active texture and what is the min/max/count
    warn("Current: active texture={} min={} max={} count={}\n",
        getActiveTexture(), texture_min, texture_max, texture_count);

    // Allocate two pixel buffers and associate them with a texture
    var num_pixels: usize = @intCast(usize, width * height);
    var pixels: [2][]u8 = undefined;
    pixels[0] = try pAllocator.alignedAlloc(u8, 16, num_pixels * 4); // Fails if alignment > 16, Why?
    pixels[1] = try pAllocator.alignedAlloc(u8, 16, num_pixels * 4);
    defer pAllocator.free(pixels[0]);
    defer pAllocator.free(pixels[1]);

    // Array of textures
    var textures: [2] gl.GLuint = undefined;

    // Initialize the GL_TEXTURE0
    textures[0] = gl.GL_TEXTURE0;
    setActiveTexture(textures[0]);
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA8, width, height,
            0, gl.GL_RGBA8, gl.GL_UNSIGNED_BYTE, @ptrCast(*const c_void, &pixels[0][0]));
    warn("texture[0]={}\n", textures[0]);
    assert(getActiveTexture() == textures[0]);

    // Initialize the GL_TEXTURE1
    textures[1] = gl.GL_TEXTURE1;
    setActiveTexture(textures[1]);
    gl.glTexImage2D(gl.GL_TEXTURE_2D, 0, gl.GL_RGBA8, width, height,
            0, gl.GL_RGBA8, gl.GL_UNSIGNED_BYTE, @ptrCast(*const c_void, &pixels[1][0]));
    warn("texture[1]={}\n", textures[1]);
    assert(getActiveTexture() == textures[1]);

    // Generate a framebuffer object, fb0
    var fbo: gl.GLuint = undefined;
    gl.glGenFramebuffers(1, ptr(&fbo));
    warn("frame_buffer[0]={}\n", fbo);
    defer gl.glDeleteFramebuffers(1, ptr(&fbo));

    gl.glBindFramebuffer(gl.GL_FRAMEBUFFER, fbo);
    var fbo_status = gl.glCheckFramebufferStatus(gl.GL_FRAMEBUFFER);
    warn("fb0_status={} \"{}\"\n", fbo_status, fboStatusStr(fbo_status));

    //glFramebufferTexture2D(gl.GL_FRAMEBUFFER, gl.GL_COLOR_ATTACHMENT0, gl.GL_TEXTURE_2D, texture, 0);

    while (gl.glfwWindowShouldClose(window) == gl.GL_FALSE) {
        gl.glfwPollEvents();
    }
}
