const builtin = @import("builtin");
const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const warn = std.debug.warn;
const gl = @import("../modules/zig-sdl2/src/index.zig");

const ie = @import("input_events.zig");
const wdw = @import("window.zig");

const WindowState = struct {
    window: wdw.Window,
    quit: bool,
    leftMouseButtonDown: bool,
    ei: ie.EventInterface,
    bg_color: u32,
    fg_color: u32,
    width: usize,
    height: usize,
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
                pWs.window.putPixel(mouse_x, mouse_y, pWs.fg_color);
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

    var ws = WindowState{
        .window = undefined,
        .quit = false,
        .leftMouseButtonDown = false,
        .ei = ie.EventInterface{
            .event = undefined,
            .handleKeyEvent = handleKeyEvent,
            .handleMouseEvent = handleMouseEvent,
            .handleOtherEvent = handleOtherEvent,
        },
        .bg_color = 0x00000000, // black
        .fg_color = 0xffffffff, // white
        .width = 640,
        .height = 480,
    };

    ws.window = wdw.Window.init(pAllocator, ws.width, ws.height, "zig-3d-soft-engine") catch |e| {
        warn("Could not init window: {}\n", e);
        return 1;
    };
    defer ws.window.deinit();

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
        ws.window.present();
    }

    return 0;
}
