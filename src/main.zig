const builtin = @import("builtin");
const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const warn = std.debug.warn;
const gl = @import("../modules/zig-sdl2/src/index.zig");

const EventResult = enum.{
    Continue,
    Quit,
};

fn handleKeyEvent(et: u32, key: gl.SDL_KeyboardEvent) EventResult {
    warn("handleKeyEvent: et={} key={}\n", et, key);
    var result: EventResult = EventResult.Continue;
    switch (et) {
        gl.SDL_KEYUP => {
            if (key.keysym.sym == gl.SDLK_ESCAPE) {
                result = EventResult.Quit;
            }
        },
        else => {},
    }
    return result;
}

fn handleEvent(event: gl.SDL_Event) EventResult {
    var result: EventResult = EventResult.Continue;
    switch (event.type) {
        gl.SDL_QUIT => {
            warn("SDL_QUIT\n");
            result = EventResult.Quit;
        },
        gl.SDL_KEYUP, gl.SDL_KEYDOWN => |et| {
            result = handleKeyEvent(et, event.key);
        },
        else => {},
    }
    return result;
}

pub fn main() u8 {
    // Initialize SDL
    if (gl.SDL_Init(gl.SDL_INIT_VIDEO | gl.SDL_INIT_AUDIO) != 0) {
        gl.SDL_Log(c"failed to initialized SDL\n");
        return 1;
    }
    defer gl.SDL_Quit();

    // Create Window
    const x_pos: c_int = gl.SDL_WINDOWPOS_UNDEFINED;
    const y_pos: c_int = gl.SDL_WINDOWPOS_UNDEFINED;
    const width: c_int = 640;
    const height: c_int = 480;

    var window_flags: u32 = 0;
    var window: *gl.SDL_Window = gl.SDL_CreateWindow(c"zig-3d-soft-engine", x_pos, y_pos, width, height, window_flags) orelse {
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
    var texture: *gl.SDL_Texture = gl.SDL_CreateTexture(renderer, gl.SDL_PIXELFORMAT_ARGB8888, gl.SDL_TEXTUREACCESS_STATIC, width, height) orelse {
        warn("Could not create Texture error: {}\n", gl.SDL_GetError());
        return 1;
    };

    // Create Pixel buffer
    var bg_color: u32 = 0xffffffff; // white
    var fg_color: u32 = 0x00000000; // black
    var pixels: [@intCast(usize, width) * @intCast(usize, height)]u32 = undefined;
    for (pixels) |*pixel| {
        pixel.* = bg_color;
    }

    var quit = false;
    var leftMouseButtonDown = false;
    while (!quit) {
        // Process all events
        var event: gl.SDL_Event = undefined;
        while (gl.SDL_PollEvent(&event) != 0) {
            quit = handleEvent(event) == EventResult.Quit;
            if (!quit) {
                switch (event.type) {
                    gl.SDL_MOUSEBUTTONUP => {
                        assert(gl.SDL_BUTTON_LMASK == 1);
                        if (event.button.button == gl.SDL_BUTTON_LEFT) {
                            leftMouseButtonDown = false;
                        }
                    },
                    gl.SDL_MOUSEBUTTONDOWN => {
                        if (event.button.button == gl.SDL_BUTTON_LEFT) {
                            leftMouseButtonDown = true;
                        }
                    },
                    gl.SDL_MOUSEMOTION => {
                        if (leftMouseButtonDown) {
                            var mouse_x: usize = @intCast(usize, event.motion.x);
                            var mouse_y: usize = @intCast(usize, event.motion.y);
                            pixels[(mouse_y * @intCast(usize, width)) + mouse_x] = fg_color;
                        }
                    },
                    else => {},
                }
            }
        }

        // Update display
        _ = gl.SDL_UpdateTexture(texture, null, @ptrCast(*const c_void, &pixels[0]), width * @sizeOf(u32));
        _ = gl.SDL_RenderClear(renderer);
        _ = gl.SDL_RenderCopy(renderer, texture, null, null);
        _ = gl.SDL_RenderPresent(renderer);
    }

    return 0;
}
