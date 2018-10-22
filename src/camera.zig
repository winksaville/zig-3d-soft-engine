const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const math = std.math;
const math3d = @import("math3d.zig");

const Camera = struct.{
    const Self = @This();

    pub position: math3d.Vec3,
    pub target: math3d.Vec3,

    pub fn init(position: math3d.Vec3, target: math3d.Vec3) Self {
        return Self.{
            .position = position,
            .target = target,
        };
    }
};

test "camera" {
    var camera = Camera.init(math3d.vec3(0.1, 0.2, 0.3), math3d.vec3(0.4, 0.5, 0.6));

    assert(camera.position.data[0] == 0.1);
    assert(camera.position.data[1] == 0.2);
    assert(camera.position.data[2] == 0.3);
    assert(camera.target.data[0] == 0.4);
    assert(camera.target.data[1] == 0.5);
    assert(camera.target.data[2] == 0.6);
}
