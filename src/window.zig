const builtin = @import("builtin");
const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const warn = std.debug.warn;
const gl = @import("../modules/zig-sdl2/src/index.zig");

pub const Window = struct. {
    const Self = @This();

    pAllocator: *Allocator,
    width: c_int,
    height: c_int,
    name: []const u8,
    bg_color: u32,
    pixels: []u32,
    sdl_window: *gl.SDL_Window,
    sdl_renderer: *gl.SDL_Renderer,
    sdl_texture: *gl.SDL_Texture,

    pub fn init(pAllocator: *Allocator, width: usize, height: usize, name: []const u8) !Self {
        var self = Self.{
            .pAllocator = pAllocator,
            .bg_color = undefined,
            .width = @intCast(c_int, width),
            .height = @intCast(c_int, height),
            .name = name,
            .pixels = try pAllocator.alloc(u32, width * height),
            .sdl_window = undefined,
            .sdl_renderer = undefined,
            .sdl_texture = undefined,
        };

        self.setBgColor(0xffffffff);

        // Initialize SDL
        if (gl.SDL_Init(gl.SDL_INIT_VIDEO | gl.SDL_INIT_AUDIO) != 0) {
            return error.FailedSdlInitialization;
        }
        errdefer gl.SDL_Quit();

        // Create Window
        const x_pos: c_int = gl.SDL_WINDOWPOS_UNDEFINED;
        const y_pos: c_int = gl.SDL_WINDOWPOS_UNDEFINED;
        var window_flags: u32 = 0;
        self.sdl_window = gl.SDL_CreateWindow(c"zig-3d-soft-engine", x_pos, y_pos, self.width, self.height, window_flags) orelse {
            return error.FailedSdlWindowInitialization;
        };
        errdefer gl.SDL_DestroyWindow(self.sdl_window);

        // This reduces CPU utilization but now dragging window is jerky
        {
            var r = gl.SDL_GL_SetSwapInterval(1);
            if (r != 0) {
                var b = gl.SDL_SetHint(gl.SDL_HINT_RENDER_VSYNC, c"1");
                if (b != gl.SDL_bool.SDL_TRUE) {
                    warn("No VSYNC cpu utilization may be high!\n");
                }
            }
        }

        // Create Renderer
        var renderer_flags: u32 = 0;
        self.sdl_renderer = gl.SDL_CreateRenderer(self.sdl_window, -1, renderer_flags) orelse {
            return error.FailedSdlRendererInitialization;
        };
        errdefer gl.SDL_DestroyRenderer(self.sdl_renderer);

        // Create Texture
        self.sdl_texture = gl.SDL_CreateTexture(self.sdl_renderer, gl.SDL_PIXELFORMAT_ARGB8888, gl.SDL_TEXTUREACCESS_STATIC, self.width, self.height) orelse {
            return error.FailedSdlTextureInitialization;
        };
        errdefer gl.SDL_DestroyTexture(self.sdl_texture);

        self.clear();

        return self;
    }

    pub fn deinit(self: *Self) void {
        gl.SDL_DestroyTexture(self.sdl_texture);
        gl.SDL_DestroyRenderer(self.sdl_renderer);
        gl.SDL_DestroyWindow(self.sdl_window);
        gl.SDL_Quit();
    }

    pub fn setBgColor(self: *Self, color: u32) void {
        self.bg_color = color;
    }

    pub fn clear(self: *Self) void {
        // Init Pixel buffer
        for (self.pixels) |*pixel| {
            pixel.* = self.bg_color;
        }
    }

    pub fn putPixel(self: *Self, x: usize, y: usize, color: u32) void {
        self.pixels[(y * @intCast(usize, self.width)) + x] = color;
    }
        
    pub fn getPixel(self: *Self, x: usize, y: usize) u32 {
        return self.pixels[(y * @intCast(usize, self.width)) + x];
    }
        
    pub fn present(self: *Self,) void {
        _ = gl.SDL_UpdateTexture(self.sdl_texture, null, @ptrCast(*const c_void, &self.pixels[0]), self.width * @sizeOf(@typeOf(self.pixels[0])));
        _ = gl.SDL_RenderClear(self.sdl_renderer);
        _ = gl.SDL_RenderCopy(self.sdl_renderer, self.sdl_texture, null, null);
        _ = gl.SDL_RenderPresent(self.sdl_renderer);
    }
};

// Test

test "Window" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 640, 480, "testWindow");
    defer window.deinit();

    assert(window.width == 640);
    assert(window.height == 480);
    assert(mem.eql(u8, window.name, "testWindow"));
    window.putPixel(0, 0, 0x01020304);
    assert(window.getPixel(0, 0) == 0x01020304);

    window.present();
}
