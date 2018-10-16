const std = @import("std");
const warn = std.debug.warn;
const gl = @import("../modules/zig-sdl2/src/index.zig");

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

    gl.SDL_SetWindowTitle(window, c"zig-sdl");

    var quit = false;
    while (!quit) {
        // One event per loop for now, later limit the time?
        var event: gl.SDL_Event = undefined;
        if (gl.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                gl.SDL_QUIT => {
                    warn("SDL_QUIT\n");
                    quit = true;
                    break;
                },
                else => {}
            }
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
