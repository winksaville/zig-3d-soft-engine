const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const math = std.math;

const geo = @import("modules/zig-geometry/index.zig");

pub const Camera = struct {
    const Self = @This();

    pub position: geo.V3f32,
    pub target: geo.V3f32,

    pub fn init(position: geo.V3f32, target: geo.V3f32) Self {
        return Self{
            .position = position,
            .target = target,
        };
    }
};

test "camera" {
    var camera = Camera.init(geo.V3f32.init(0.1, 0.2, 0.3), geo.V3f32.init(0.4, 0.5, 0.6));

    assert(camera.position.data[0] == 0.1);
    assert(camera.position.data[1] == 0.2);
    assert(camera.position.data[2] == 0.3);
    assert(camera.target.data[0] == 0.4);
    assert(camera.target.data[1] == 0.5);
    assert(camera.target.data[2] == 0.6);
}
