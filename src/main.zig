const builtin = @import("builtin");
const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const warn = std.debug.warn;
const gl = @import("../modules/zig-sdl2/src/index.zig");

const ie = @import("input_events.zig");

const WindowState = struct.{
    quit: bool,
    leftMouseButtonDown: bool,
    ei: ie.EventInterface,
    bg_color: u32,
    fg_color: u32,
    width: c_int,
    height: c_int,
    pixels: []u32,
};

fn handleKeyEvent(pThing: *c_void, event: *gl.SDL_Event) ie.EventResult {
    var pWs = @intToPtr(*WindowState, @ptrToInt(pThing));
    switch (event.type) {
        gl.SDL_KEYUP => {
            if (event.key.keysym.sym == gl.SDLK_ESCAPE) {
                pWs.quit = true;
                return ie.EventResult.Quit;
            }
        },
        else => {},
    }
    return ie.EventResult.Continue;
}

fn handleMouseEvent(pThing: *c_void, event: *gl.SDL_Event) ie.EventResult {
    var pWs = @intToPtr(*WindowState, @ptrToInt(pThing));
    switch (event.type) {
        gl.SDL_MOUSEBUTTONUP => {
            assert(gl.SDL_BUTTON_LMASK == 1);
            if (event.button.button == gl.SDL_BUTTON_LEFT) {
                pWs.leftMouseButtonDown = false;
            }
        },
        gl.SDL_MOUSEBUTTONDOWN => {
            if (event.button.button == gl.SDL_BUTTON_LEFT) {
                pWs.leftMouseButtonDown = true;
            }
        },
        gl.SDL_MOUSEMOTION => {
            if (pWs.leftMouseButtonDown) {
                var mouse_x: usize = @intCast(usize, event.motion.x);
                var mouse_y: usize = @intCast(usize, event.motion.y);
                pWs.pixels[(mouse_y * @intCast(usize, pWs.width)) + mouse_x] = pWs.fg_color;
            }
        },
        else => {},
    }
    return ie.EventResult.Continue;
}

fn handleOtherEvent(pThing: *c_void, event: *gl.SDL_Event) ie.EventResult {
    return ie.EventResult.Continue;
}

pub fn main() u8 {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var ws = WindowState.{
        .quit = false,
        .leftMouseButtonDown = false,
        .ei = ie.EventInterface.{
            .event = undefined,
            .handleKeyEvent = handleKeyEvent,
            .handleMouseEvent = handleMouseEvent,
            .handleOtherEvent = handleOtherEvent,
        },
        .bg_color = 0xffffffff, // white
        .fg_color = 0x00000000, // black
        .width = 640,
        .height = 480,
        .pixels = pAllocator.alloc(u32, 640 * 480) catch |e| {
            warn("Could not allocate pixels: {}\n", e);
            return 1;
        },
    };

    // Initialize SDL
    if (gl.SDL_Init(gl.SDL_INIT_VIDEO | gl.SDL_INIT_AUDIO) != 0) {
        gl.SDL_Log(c"failed to initialized SDL\n");
        return 1;
    }
    defer gl.SDL_Quit();

    // Create Window
    const x_pos: c_int = gl.SDL_WINDOWPOS_UNDEFINED;
    const y_pos: c_int = gl.SDL_WINDOWPOS_UNDEFINED;
    var window_flags: u32 = 0;
    var window: *gl.SDL_Window = gl.SDL_CreateWindow(c"zig-3d-soft-engine", x_pos, y_pos, ws.width, ws.height, window_flags) orelse {
        warn("Could not create Window error: {}\n", gl.SDL_GetError());
        return 1;
    };
    defer gl.SDL_DestroyWindow(window);

    // This reduces CPU utilization but now dragging window is jerky
    var r = gl.SDL_GL_SetSwapInterval(1);
    if (r != 0) {
        var b = gl.SDL_SetHint(gl.SDL_HINT_RENDER_VSYNC, c"1");
        if (b != gl.SDL_bool.SDL_TRUE) {
            warn("No VSYNC cpu utilization may be high!\n");
        }
    }

    // Create Renderer
    var renderer_flags: u32 = 0;
    var renderer: *gl.SDL_Renderer = gl.SDL_CreateRenderer(window, -1, renderer_flags) orelse {
        warn("Could not create Renderer error: {}\n", gl.SDL_GetError());
        return 1;
    };
    defer gl.SDL_DestroyRenderer(renderer);

    // Create Texture
    var texture: *gl.SDL_Texture = gl.SDL_CreateTexture(renderer, gl.SDL_PIXELFORMAT_ARGB8888, gl.SDL_TEXTUREACCESS_STATIC, ws.width, ws.height) orelse {
        warn("Could not create Texture error: {}\n", gl.SDL_GetError());
        return 1;
    };
    defer gl.SDL_DestroyTexture(texture);

    // Create Pixel buffer
    for (ws.pixels) |*pixel| {
        pixel.* = ws.bg_color;
    }

    while (!ws.quit) {
        // Process all events
        noEvents: while (true) {
            switch (ie.pollInputEvent(&ws, &ws.ei)) {
                ie.EventResult.NoEvents => {
                    break :noEvents;
                },
                ie.EventResult.Quit => {
                    ws.quit = true;
                    break :noEvents;
                },
                ie.EventResult.Continue => {},
            }
        }

        // Update display
        _ = gl.SDL_UpdateTexture(texture, null, @ptrCast(*const c_void, &ws.pixels[0]), ws.width * @sizeOf(u32));
        _ = gl.SDL_RenderClear(renderer);
        _ = gl.SDL_RenderCopy(renderer, texture, null, null);
        _ = gl.SDL_RenderPresent(renderer);
    }

    return 0;
}
