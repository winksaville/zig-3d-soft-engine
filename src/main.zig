const std = @import("std");
const warn = std.debug.warn;
const gl = @import("../modules/zig-sdl2/src/index.zig");

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
    if (gl.SDL_Init(gl.SDL_INIT_VIDEO | gl.SDL_INIT_AUDIO) != 0) {
        gl.SDL_Log(c"failed to initialized SDL\n");
        return 1;
    }
    defer gl.SDL_Quit();

    var renderer: *gl.SDL_Renderer = undefined;
    var window: *gl.SDL_Window = undefined;

    if (gl.SDL_CreateWindowAndRenderer(640, 480, gl.SDL_WINDOW_SHOWN, &window, &renderer) != 0) {
        gl.SDL_Log(c"failed to initialize window and renderer\n");
        return 1;
    }
    defer gl.SDL_DestroyRenderer(renderer);
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

    gl.SDL_SetWindowTitle(window, c"zig-sdl");

    var quit = false;
    while (!quit) {
        // One event per loop for now, later limit the time?
        var event: gl.SDL_Event = undefined;
        if (gl.SDL_PollEvent(&event) != 0) {
            quit = handleEvent(event) == EventResult.Quit;
        }

        _ = gl.SDL_SetRenderDrawColor(renderer, 0, 64, 128, 255);
        _ = gl.SDL_RenderClear(renderer);

        const r1 = gl.SDL_Rect{ .x = 10, .y = 10, .w = 10, .h = 10 };
        const r2 = gl.SDL_Rect{ .x = 40, .y = 10, .w = 10, .h = 10 };
        var rects = []gl.SDL_Rect{ r1, r2 };

        _ = gl.SDL_SetRenderDrawColor(renderer, 0, 128, 128, 255);
        _ = gl.SDL_RenderFillRects(renderer, @ptrCast([*]gl.SDL_Rect, &rects[0]), 2);

        _ = gl.SDL_RenderPresent(renderer);
    }

    return 0;
}
