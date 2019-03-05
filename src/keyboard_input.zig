const std = @import("std");
const warn = std.debug.warn;

const gl = @import("modules/zig-sdl2/src/index.zig");
const ie = @import("input_events.zig");

pub const KeyState = struct {
    new_key: bool,
    code: gl.SDL_Keycode,
    mod: u16,
    ei: ie.EventInterface,
};

var g_ks = KeyState{
    .new_key = false,
    .code = undefined,
    .mod = undefined,
    .ei = ie.EventInterface{
        .event = undefined,
        .handleKeyEvent = handleKeyEvent,
        .handleMouseEvent = ignoreEvent,
        .handleOtherEvent = ignoreEvent,
    },
};

fn handleKeyEvent(pThing: *c_void, event: *gl.SDL_Event) ie.EventResult {
    var pKey_state = @intToPtr(*KeyState, @ptrToInt(pThing));
    switch (event.type) {
        gl.SDL_KEYUP => {
            pKey_state.*.new_key = true;
            pKey_state.*.code = event.key.keysym.sym;
            pKey_state.*.mod = event.key.keysym.mod;
        },
        else => {},
    }
    return ie.EventResult.Continue;
}

fn ignoreEvent(pThing: *c_void, event: *gl.SDL_Event) ie.EventResult {
    return ie.EventResult.Continue;
}

/// Wait for a key
pub fn waitForKey(s: []const u8, exitOnEscape: bool, debug: bool) *KeyState {
    if (debug) warn("{}, waiting for key: ...", s);

    g_ks.new_key = false;
    while (g_ks.new_key == false) {
        _ = ie.pollInputEvent(&g_ks, &g_ks.ei);
    }

    if (debug) warn(" g_ks.mod={} g_ks.code={}\n", g_ks.mod, g_ks.code);

    if (g_ks.code == gl.SDLK_ESCAPE) if (exitOnEscape) std.os.exit(1);

    return &g_ks;
}

/// Wait for Esc key
pub fn waitForEsc(s: []const u8) void {
    done: while (true) {
        // Wait for a key
        var ks = waitForKey(s, false, true);

        // Stop if ESCAPE
        switch (ks.code) {
            gl.SDLK_ESCAPE => break :done,
            else => {},
        }
    }
}
