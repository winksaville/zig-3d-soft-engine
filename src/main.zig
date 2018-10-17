const builtin = @import("builtin");
const std = @import("std");
const mem = std.mem;
const warn = std.debug.warn;
const gl = @import("../modules/zig-sdl2/src/index.zig");

const glSDL_WINDOWPOS_UNDEFINED_MASK: c_int = 0x1FFF0000;
const glSDL_WINDOWPOS_UNDEFINED: c_int = glSDL_WINDOWPOS_UNDEFINED_MASK | 0;

fn glSDL_WindowPosIsUndefined(pos: c_int) bool {
    return (pos & glSDL_WINDOWPOS_UNDEFINED_MASK) == glSDL_WINDOWPOS_UNDEFINED_MASK;
}

const EventResult = enum {
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
        gl.SDL_KEYUP,
        gl.SDL_KEYDOWN => |et| {
            result = handleKeyEvent(et, event.key);
        },
        else => {}
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
    var x_pos: c_int = glSDL_WINDOWPOS_UNDEFINED;
    var y_pos: c_int = glSDL_WINDOWPOS_UNDEFINED;
    var width: c_int = 640;
    var height: c_int = 480;

    var window_flags: u32 = 0;
    var window: *gl.SDL_Window = gl.SDL_CreateWindow(
            c"zig-3d-soft-engine", x_pos, y_pos, width, height, window_flags
        ) orelse {
            warn("Could not create Window error: {}\n", gl.SDL_GetError());
            return 1;
        };
    defer gl.SDL_DestroyWindow(window);

    // This reduces CPU utilization but now dragging window is jerky.
    // Another possible option was:
    //   `var r = gl.SDL_SetHint(gl.SDL_HINT_RENDER_VSYNC, c"1");`
    // But that didn't work on my system, CPU utilization was still 100%
    // although dragging the window was fine.
    var r = gl.SDL_GL_SetSwapInterval(1);
    if (r != 0) {
        warn("SetSwapInterval(1)={} cpu utilization may be high!\n", r);
    }

    // Create Renderer
    var renderer_flags: u32 = 0;
    var renderer: *gl.SDL_Renderer = gl.SDL_CreateRenderer(window, -1, renderer_flags
        ) orelse {
            warn("Could not create Renderer error: {}\n", gl.SDL_GetError());
            return 1;
        };
    defer gl.SDL_DestroyRenderer(renderer);

    // Create Texture
    var texture: *gl.SDL_Texture = gl.SDL_CreateTexture(renderer,
        gl.SDL_PIXELFORMAT_ARGB8888, gl.SDL_TESTUREACCESS_STATIC, width, height
        ) orelse {
            warn("Could not create Texture error: {}\n", gl.SDL_GetError());
            return 1;
        };

    // Create Pixel buffer
    var bg_color = 0xffffffff; // white
    var fg_color = 0x00000000; // black
    var pixels: [width * height]u32 = undefined;
    mem.WriteInt(pixels[0..], bg_color, builtin.endian);

    var quit = false;
    var leftMouseButtonDown = false;
    while (!quit) {
        // One event per loop for now, later limit the time?
        var event: gl.SDL_Event = undefined;
        if (gl.SDL_PollEvent(&event) != 0) {
            quit = handleEvent(event) == EventResult.Quit;
            if (!quit) {
                switch (event.type) {
                    gl.SDL_MOUSEBUTTONUP => {
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
                            pixels[(mouse_x * width) + mouse_y] = fg_color;
                        }
                    },
                    else => {}
                }
            }
        }

        _ = gl.SDL_RenderClear(renderer);
        _ = gl.SDL_RenderCopy(renderer, texture, null, null);
        _ = gl.SDL_RenderPresent(renderer);
    }

    return 0;
}
