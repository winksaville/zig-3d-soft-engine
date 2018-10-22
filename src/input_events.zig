const builtin = @import("builtin");
const std = @import("std");
const mem = std.mem;
const assert = std.debug.assert;
const warn = std.debug.warn;
const gl = @import("../modules/zig-sdl2/src/index.zig");

pub const EventResult = enum.{
    NoEvents,
    Continue,
    Quit,
};

pub const EventInterface = struct.{
    event: gl.SDL_Event,
    handleKeyEvent: fn (pThing: *c_void, event: *gl.SDL_Event) EventResult,
    handleMouseEvent: fn (pThing: *c_void, event: *gl.SDL_Event) EventResult,
    handleOtherEvent: fn (pThing: *c_void, event: *gl.SDL_Event) EventResult,
};

pub fn processEvent(pThing: *c_void, pEi: *EventInterface, event: *gl.SDL_Event) EventResult {
    switch (event.type) {
        gl.SDL_QUIT => {
            return EventResult.Quit;
        },
        gl.SDL_KEYUP, gl.SDL_KEYDOWN => |et| {
            return pEi.handleKeyEvent(pThing, event);
        },
        gl.SDL_MOUSEBUTTONUP, gl.SDL_MOUSEBUTTONDOWN, gl.SDL_MOUSEMOTION => |et| {
            return pEi.handleMouseEvent(pThing, event);
        },
        else => return pEi.handleOtherEvent(pThing, event),
    }
}

pub fn pollInputEvent(pThing: *c_void, pEi: *EventInterface) EventResult {
    var event: gl.SDL_Event = undefined;
    if (gl.SDL_PollEvent(&event) == 0) return EventResult.NoEvents;
    return processEvent(pThing, pEi, &event);
}

// Test

fn handleKeyEvent(pThing: *c_void, event: *gl.SDL_Event) EventResult {
    var pMyThing: *Thing = @intToPtr(*Thing, @ptrToInt(pThing));
    pMyThing.key_count += 1;
    return EventResult.Continue;
}

fn handleMouseEvent(pThing: *c_void, event: *gl.SDL_Event) EventResult {
    var pMyThing: *Thing = @intToPtr(*Thing, @ptrToInt(pThing));
    pMyThing.mouse_count += 1;
    return EventResult.Continue;
}

fn handleOtherEvent(pThing: *c_void, event: *gl.SDL_Event) EventResult {
    var pMyThing: *Thing = @intToPtr(*Thing, @ptrToInt(pThing));
    pMyThing.other_count += 1;
    return EventResult.Continue;
}

const Thing = struct.{
    key_count: usize,
    mouse_count: usize,
    other_count: usize,
};

test "inputEvent" {
    var thing = Thing.{
        .key_count = 0,
        .mouse_count = 0,
        .other_count = 0,
    };

    var ei = EventInterface.{
        .event = undefined,
        .handleKeyEvent = handleKeyEvent,
        .handleMouseEvent = handleMouseEvent,
        .handleOtherEvent = handleOtherEvent,
    };

    var event: gl.SDL_Event = undefined;
    event.type = gl.SDL_KEYDOWN;
    assert(processEvent(&thing, &ei, &event) == EventResult.Continue);
    assert(thing.key_count == 1);
    event.type = gl.SDL_KEYUP;
    assert(processEvent(&thing, &ei, &event) == EventResult.Continue);
    assert(thing.key_count == 2);

    event.type = gl.SDL_MOUSEBUTTONDOWN;
    assert(processEvent(&thing, &ei, &event) == EventResult.Continue);
    assert(thing.mouse_count == 1);
    event.type = gl.SDL_MOUSEBUTTONUP;
    assert(processEvent(&thing, &ei, &event) == EventResult.Continue);
    assert(thing.mouse_count == 2);
    event.type = gl.SDL_MOUSEMOTION;
    assert(processEvent(&thing, &ei, &event) == EventResult.Continue);
    assert(thing.mouse_count == 3);
}
