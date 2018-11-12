/// Some 3D Math code
///
/// BasedOn: [math3d.zig from Andrew Kelly tetris](https://github.com/andrewrk/tetris/blob/master/src/math3d.zig)
/// and enhancements from [SharpDx](https://github.com/sharpdx/SharpDX).
const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const warn = std.debug.warn;
const ae = @import("../modules/zig-approxeql/approxeql.zig");

const DBG = true;

pub const Mat4x4 = struct.{
    const Self = @This();

    data: [4][4]f32,

    /// matrix multiplication
    pub fn mult(m: *const Mat4x4, other: *const Mat4x4) Mat4x4 {
        return Mat4x4.{ .data = [][4]f32.{
            []f32.{
                m.data[0][0] * other.data[0][0] + m.data[0][1] * other.data[1][0] + m.data[0][2] * other.data[2][0] + m.data[0][3] * other.data[3][0],
                m.data[0][0] * other.data[0][1] + m.data[0][1] * other.data[1][1] + m.data[0][2] * other.data[2][1] + m.data[0][3] * other.data[3][1],
                m.data[0][0] * other.data[0][2] + m.data[0][1] * other.data[1][2] + m.data[0][2] * other.data[2][2] + m.data[0][3] * other.data[3][2],
                m.data[0][0] * other.data[0][3] + m.data[0][1] * other.data[1][3] + m.data[0][2] * other.data[2][3] + m.data[0][3] * other.data[3][3],
            },
            []f32.{
                m.data[1][0] * other.data[0][0] + m.data[1][1] * other.data[1][0] + m.data[1][2] * other.data[2][0] + m.data[1][3] * other.data[3][0],
                m.data[1][0] * other.data[0][1] + m.data[1][1] * other.data[1][1] + m.data[1][2] * other.data[2][1] + m.data[1][3] * other.data[3][1],
                m.data[1][0] * other.data[0][2] + m.data[1][1] * other.data[1][2] + m.data[1][2] * other.data[2][2] + m.data[1][3] * other.data[3][2],
                m.data[1][0] * other.data[0][3] + m.data[1][1] * other.data[1][3] + m.data[1][2] * other.data[2][3] + m.data[1][3] * other.data[3][3],
            },
            []f32.{
                m.data[2][0] * other.data[0][0] + m.data[2][1] * other.data[1][0] + m.data[2][2] * other.data[2][0] + m.data[2][3] * other.data[3][0],
                m.data[2][0] * other.data[0][1] + m.data[2][1] * other.data[1][1] + m.data[2][2] * other.data[2][1] + m.data[2][3] * other.data[3][1],
                m.data[2][0] * other.data[0][2] + m.data[2][1] * other.data[1][2] + m.data[2][2] * other.data[2][2] + m.data[2][3] * other.data[3][2],
                m.data[2][0] * other.data[0][3] + m.data[2][1] * other.data[1][3] + m.data[2][2] * other.data[2][3] + m.data[2][3] * other.data[3][3],
            },
            []f32.{
                m.data[3][0] * other.data[0][0] + m.data[3][1] * other.data[1][0] + m.data[3][2] * other.data[2][0] + m.data[3][3] * other.data[3][0],
                m.data[3][0] * other.data[0][1] + m.data[3][1] * other.data[1][1] + m.data[3][2] * other.data[2][1] + m.data[3][3] * other.data[3][1],
                m.data[3][0] * other.data[0][2] + m.data[3][1] * other.data[1][2] + m.data[3][2] * other.data[2][2] + m.data[3][3] * other.data[3][2],
                m.data[3][0] * other.data[0][3] + m.data[3][1] * other.data[1][3] + m.data[3][2] * other.data[2][3] + m.data[3][3] * other.data[3][3],
            },
        } };
    }

    pub fn assert_matrix_eq(pSelf: *const Mat4x4, pOther: *const Mat4x4) void {
        const digits = 7;
        assert(ae.approxEql(pSelf.data[0][0], pOther.data[0][0], digits));
        assert(ae.approxEql(pSelf.data[0][1], pOther.data[0][1], digits));
        assert(ae.approxEql(pSelf.data[0][2], pOther.data[0][2], digits));
        assert(ae.approxEql(pSelf.data[0][3], pOther.data[0][3], digits));

        assert(ae.approxEql(pSelf.data[1][0], pOther.data[1][0], digits));
        assert(ae.approxEql(pSelf.data[1][1], pOther.data[1][1], digits));
        assert(ae.approxEql(pSelf.data[1][2], pOther.data[1][2], digits));
        assert(ae.approxEql(pSelf.data[1][3], pOther.data[1][3], digits));

        assert(ae.approxEql(pSelf.data[2][0], pOther.data[2][0], digits));
        assert(ae.approxEql(pSelf.data[2][1], pOther.data[2][1], digits));
        assert(ae.approxEql(pSelf.data[2][2], pOther.data[2][2], digits));
        assert(ae.approxEql(pSelf.data[2][3], pOther.data[2][3], digits));

        assert(ae.approxEql(pSelf.data[3][0], pOther.data[3][0], digits));
        assert(ae.approxEql(pSelf.data[3][1], pOther.data[3][1], digits));
        assert(ae.approxEql(pSelf.data[3][2], pOther.data[3][2], digits));
        assert(ae.approxEql(pSelf.data[3][3], pOther.data[3][3], digits));
    }

    /// Custom format routine for Mat4x4
    pub fn format(self: *const Self,
        comptime fmt: []const u8,
        context: var,
        comptime FmtError: type,
        output: fn (@typeOf(context), []const u8) FmtError!void
    ) FmtError!void {
        for (self.data) |row, i| {
            try std.fmt.format(context, FmtError, output, " []f32.{{ ");
            for (row) |col, j| {
                try std.fmt.format(context, FmtError, output, "{.7}{} ", col, if (j < (row.len - 1)) "," else "");
            }
            try std.fmt.format(context, FmtError, output, "}},\n");
        }
    }
};

pub const mat4x4_identity = Mat4x4.{ .data = [][4]f32.{
    []f32.{ 1.0, 0.0, 0.0, 0.0 },
    []f32.{ 0.0, 1.0, 0.0, 0.0 },
    []f32.{ 0.0, 0.0, 1.0, 0.0 },
    []f32.{ 0.0, 0.0, 0.0, 1.0 },
} };

pub const Vec2 = struct.{
    const Self = @This();

    data: [2]f32,

    pub fn init(xp: f32, yp: f32) Vec2 {
        return vec2(xp, yp);
    }

    pub fn x(v: *const Vec2) f32 {
        return v.data[0];
    }

    pub fn y(v: *const Vec2) f32 {
        return v.data[1];
    }

    pub fn setX(v: *Vec2, xp: f32) void {
        v.data[0] = xp;
    }

    pub fn setY(v: *Vec2, yp: f32) void {
        v.data[1] = yp;
    }

    pub fn normalize(v: *const Vec2) Vec2 {
        return v.scale(1.0 / math.sqrt(v.dot(v)));
    }

    pub fn scale(v: *const Vec2, scalar: f32) Vec2 {
        return Vec2.{ .data = []f32.{
            v.data[0] * scalar,
            v.data[1] * scalar,
        } };
    }

    pub fn dot(v: *const Vec2, other: *const Vec2) f32 {
        return v.data[0] * other.data[0] + v.data[1] * other.data[1];
    }

    pub fn length(v: *const Vec2) f32 {
        return math.sqrt(v.dot(v));
    }

    pub fn add(v: *const Vec2, other: *const Vec2) Vec2 {
        return Vec2.init(v.x() + other.x(), v.y() + other.y());
    }

    /// Custom format routine for Vec2
    pub fn format(self: *const Self,
        comptime fmt: []const u8,
        context: var,
        comptime FmtError: type,
        output: fn (@typeOf(context), []const u8) FmtError!void
    ) FmtError!void {
        try std.fmt.format(context, FmtError, output, "x={.3} y={.3}", self.x(), self.y());
    }
};

pub fn vec2(x: f32, y: f32) Vec2 {
    return Vec2.{ .data = []f32.{
        x,
        y,
    } };
}

test "math3d.vec2" {
    var v1 = vec2(1, 2);
    var v2 = Vec2.init(0.1, 0.2);

    assert(v1.x() == 1.0);
    assert(v1.y() == 2.0);
    assert(v2.x() == 0.1);
    assert(v2.y() == 0.2);

    v1.setX(v2.x());
    v1.setY(v2.y());
    assert(v1.x() == v2.x());
    assert(v1.y() == v2.y());

    // TODO: More tests
}

pub const Vec3 = struct.{
    const Self = @This();

    data: [3]f32,

    pub fn init(xp: f32, yp: f32, zp: f32) Vec3 {
        return vec3(xp, yp, zp);
    }

    pub fn x(v: *const Vec3) f32 {
        return v.data[0];
    }

    pub fn y(v: *const Vec3) f32 {
        return v.data[1];
    }

    pub fn z(v: *const Vec3) f32 {
        return v.data[2];
    }

    pub fn setX(v: *Vec3, xp: f32) void {
        v.data[0] = xp;
    }

    pub fn setY(v: *Vec3, yp: f32) void {
        v.data[1] = yp;
    }

    pub fn setZ(v: *Vec3, zp: f32) void {
        v.data[2] = zp;
    }

    pub fn unitX() Vec3 {
        return Vec3.init(1, 0, 0);
    }

    pub fn unitY() Vec3 {
        return Vec3.init(0, 1, 0);
    }

    pub fn unitZ() Vec3 {
        return Vec3.init(0, 0, 1);
    }

    pub fn zero() Vec3 {
        return Vec3.init(0, 0, 0);
    }

    pub fn normalize(v: *const Vec3) Vec3 {
        return v.scale(1.0 / math.sqrt(v.dot(v)));
    }

    pub fn scale(v: *const Vec3, scalar: f32) Vec3 {
        return Vec3.init(v.x() * scalar, v.y() * scalar, v.z() * scalar);
    }

    pub fn dot(v: *const Vec3, other: *const Vec3) f32 {
        return (v.x() * other.x()) + (v.y() * other.y()) + (v.z() * other.z());
    }

    pub fn length(v: *const Vec3) f32 {
        return math.sqrt(v.dot(v));
    }

    /// returns the cross product
    pub fn cross(v: *const Vec3, other: *const Vec3) Vec3 {
        var rx = (v.y() * other.z()) - (other.y() * v.z());
        var ry = (v.z() * other.x()) - (other.z() * v.z());
        var rz = (v.x() * other.y()) - (other.x() * v.y());
        return Vec3.init(rx, ry, rz);
    }

    pub fn eql(v: *const Vec3, other: *const Vec3) bool {
        return v.x() == other.x() and v.y() == other.y() and v.z() == other.z();
    }

    pub fn approxEql(v: *const Vec3, other: *const Vec3, digits: usize) bool {
        return ae.approxEql(v.x(), other.x(), digits) and ae.approxEql(v.y(), other.y(), digits) and ae.approxEql(v.z(), other.z(), digits);
    }

    pub fn add(v: *const Vec3, other: *const Vec3) Vec3 {
        return Vec3.init(v.x() + other.x(), v.y() + other.y(), v.z() + other.z());
    }

    pub fn subtract(v: *const Vec3, other: *const Vec3) Vec3 {
        return Vec3.init(v.x() - other.x(), v.y() - other.y(), v.z() - other.z());
    }

    /// Transform the v using m returning a new Vec3.
    /// BasedOn: https://github.com/sharpdx/SharpDX/blob/755cb46d59f4bfb94386ff2df3fceccc511c216b/Source/SharpDX.Mathematics/Vector3.cs#L1388
    pub fn transform(v: *const Vec3, m: *const Mat4x4) Vec3 {
        const rx = (v.x() * m.data[0][0]) + (v.y() * m.data[1][0]) + (v.z() * m.data[2][0]) + m.data[3][0];
        const ry = (v.x() * m.data[0][1]) + (v.y() * m.data[1][1]) + (v.z() * m.data[2][1]) + m.data[3][1];
        const rz = (v.x() * m.data[0][2]) + (v.y() * m.data[1][2]) + (v.z() * m.data[2][2]) + m.data[3][2];
        const rw = 1.0 / ((v.x() * m.data[0][3]) + (v.y() * m.data[1][3]) + (v.z() * m.data[2][3]) + m.data[3][3]);

        return Vec3.init(rx * rw, ry * rw, rz * rw);
    }

    /// Custom format routine for Vec3
    pub fn format(self: *const Self,
        comptime fmt: []const u8,
        context: var,
        comptime FmtError: type,
        output: fn (@typeOf(context), []const u8) FmtError!void
    ) FmtError!void {
        try std.fmt.format(context, FmtError, output, "{{.x={.3} .y={.3} .z={.3}}}", self.data[0], self.data[1], self.data[2]);
    }
};

pub fn vec3(x: f32, y: f32, z: f32) Vec3 {
    return Vec3.{ .data = []f32.{
        x,
        y,
        z,
    } };
}

test "math3d.vec3" {
    var v1 = vec3(1, 2, 3);
    var v2 = Vec3.init(0.1, 0.2, 0.3);

    assert(v1.x() == 1.0);
    assert(v1.y() == 2.0);
    assert(v1.z() == 3.0);
    assert(v2.x() == 0.1);
    assert(v2.y() == 0.2);
    assert(v2.z() == 0.3);

    v1.setX(v2.x());
    v1.setY(v2.y());
    v1.setZ(v2.z());
    assert(v1.x() == v2.x());
    assert(v1.y() == v2.y());
    assert(v1.z() == v2.z());

    v1 = Vec3.unitX();
    assert(v1.x() == 1);
    assert(v1.y() == 0);
    assert(v1.z() == 0);

    v1 = Vec3.unitY();
    assert(v1.x() == 0);
    assert(v1.y() == 1);
    assert(v1.z() == 0);

    v1 = Vec3.unitZ();
    assert(v1.x() == 0);
    assert(v1.y() == 0);
    assert(v1.z() == 1);

    // TODO: More tests
}

test "math3d.vec3.add" {
    var v1 = vec3(0, 0, 0);
    var v2 = vec3(0, 0, 0);
    var r = v1.add(&v2);
    assert(r.x() == 0);
    assert(r.y() == 0);
    assert(r.z() == 0);

    v1 = vec3(1, 2, 3);
    v2 = vec3(0.1, 0.2, 0.3);
    r = v1.add(&v2);
    assert(r.x() == 1.1);
    assert(r.y() == 2.2);
    assert(r.z() == 3.3);
}

pub const Vec4 = struct.{
    const Self = @This();

    data: [4]f32,

    pub fn init(xp: f32, yp: f32, zp: f32, wp: f32) Vec4 {
        return vec4(xp, yp, zp, wp);
    }

    pub fn x(v: *const Vec4) f32 {
        return v.data[0];
    }

    pub fn y(v: *const Vec4) f32 {
        return v.data[1];
    }

    pub fn z(v: *const Vec4) f32 {
        return v.data[2];
    }

    pub fn w(v: *const Vec4) f32 {
        return v.data[3];
    }

    pub fn setX(v: *Vec4, xp: f32) void {
        v.data[0] = xp;
    }

    pub fn setY(v: *Vec4, yp: f32) void {
        v.data[1] = yp;
    }

    pub fn setZ(v: *Vec4, zp: f32) void {
        v.data[2] = zp;
    }

    pub fn setW(v: *Vec4, wp: f32) void {
        v.data[3] = wp;
    }

    /// Custom format routine for Vec4
    pub fn format(self: *const Self,
        comptime fmt: []const u8,
        context: var,
        comptime FmtError: type,
        output: fn (@typeOf(context), []const u8) FmtError!void
    ) FmtError!void {
        try std.fmt.format(context, FmtError, output, "x={.3} y={.3} z={.3} w={.3}", self.x(), self.y(), self.z(), self.w());
    }
};

pub fn vec4(x: f32, y: f32, z: f32, w: f32) Vec4 {
    return Vec4.{ .data = []f32.{
        x,
        y,
        z,
        w,
    } };
}

test "math3d.vec4" {
    var v1 = vec4(1, 2, 3, 0.0);
    var v2 = Vec4.init(0.1, 0.2, 0.3, 1.0);

    assert(v1.x() == 1.0);
    assert(v1.y() == 2.0);
    assert(v1.z() == 3.0);
    assert(v1.w() == 0.0);
    assert(v2.x() == 0.1);
    assert(v2.y() == 0.2);
    assert(v2.z() == 0.3);
    assert(v2.w() == 1.0);

    v1.setX(v2.x());
    v1.setY(v2.y());
    v1.setZ(v2.z());
    v1.setW(v2.w());
    assert(v1.x() == v2.x());
    assert(v1.y() == v2.y());
    assert(v1.z() == v2.z());
    assert(v1.w() == v2.w());
}

/// Builds a 4x4 translation matrix
pub fn translation(x: f32, y: f32, z: f32) Mat4x4 {
    return Mat4x4.{ .data = [][4]f32.{
        []f32.{ 1.0, 0.0, 0.0, x },
        []f32.{ 0.0, 1.0, 0.0, y },
        []f32.{ 0.0, 0.0, 1.0, z },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
}

pub fn translationVec3(vertex: Vec3) Mat4x4 {
    return translation(vertex.x(), vertex.y(), vertex.z());
}

test "math3d.translation" {
    if (DBG) warn("\n");
    var m = translation(1, 2, 3);
    const expected = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 1.0, 0.0, 0.0, 1.0 },
        []f32.{ 0.0, 1.0, 0.0, 2.0 },
        []f32.{ 0.0, 0.0, 1.0, 3.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    if (DBG) warn("translation: expected\n{}", &expected);
    m.assert_matrix_eq(&expected);
}

/// Create a left-handed, look-at matrix
/// BasedOn: https://github.com/sharpdx/SharpDX/blob/755cb46d59f4bfb94386ff2df3fceccc511c216b/Source/SharpDX.Mathematics/Matrix.cs#L2010
pub fn lookAtLh(eye: *const Vec3, target: *const Vec3, up: *const Vec3) Mat4x4 {
    if (DBG) warn("math3d.lookAtLh: eye {} target {}\n", eye, target);

    // TODO: lookAtLh: Why do I need to eye - target
    //
    // In the SharpDx.Mathematics/Matrix.cs code they
    // they set zaxis to target - eye but reversing the
    // order, eye - target, gives "correct" results
    // in test "mathed.lookAtLh". Certainly its a problem
    // on my side, but for now we'll use eye - target.
    var zaxis = eye.subtract(target).normalize(); // target.subtract(eye).normalize();
    var xaxis = up.cross(&zaxis).normalize();
    var yaxis = zaxis.cross(&xaxis);

    // Column major order?
    var cmo = Mat4x4.{ .data = [][4]f32.{
        []f32.{ xaxis.x(), yaxis.x(), zaxis.x(), 0 },
        []f32.{ xaxis.y(), yaxis.y(), zaxis.y(), 0 },
        []f32.{ xaxis.z(), yaxis.z(), zaxis.z(), 0 },
        []f32.{ -xaxis.dot(eye), -yaxis.dot(eye), -zaxis.dot(eye), 1 },
    } };

    // Row major order?
    var rmo = Mat4x4.{ .data = [][4]f32.{
        []f32.{ xaxis.x(), xaxis.y(), xaxis.z(), -xaxis.dot(eye) },
        []f32.{ yaxis.x(), yaxis.y(), yaxis.z(), -yaxis.dot(eye) },
        []f32.{ zaxis.x(), zaxis.y(), zaxis.z(), -zaxis.dot(eye) },
        []f32.{ 0, 0, 0, 1 },
    } };

    var result = rmo;
    if (DBG) warn("math3d.lookAtLh: result\n{}", &result);
    return result;
}

test "math3d.lookAtLh" {
    var width: f32 = 640;
    var height: f32 = 480;
    var pos_x: f32 = undefined;
    var pos_y: f32 = undefined;

    var eye = Vec3.init(0, 0, 10);
    var target = Vec3.init(0, 0, 0);
    var view_matrix = lookAtLh(&eye, &target, &Vec3.unitY());

    const expected = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 1.00000, 0.00000, 0.00000, 0.00000 },
        []f32.{ 0.00000, 1.00000, 0.00000, 0.00000 },
        []f32.{ 0.00000, 0.00000, 1.00000, -10.00000 },
        []f32.{ 0.00000, 0.00000, 0.00000, 1.00000 },
    } };
    view_matrix.assert_matrix_eq(&expected);

    var coord = Vec3.init(0, 0, 0);
    var screen = project(width, height, coord, &view_matrix);
    if (DBG) warn("math3d.lookAtLh: coord={} screen={}\n", &coord, &screen);
    assert(screen.x() == 320);
    assert(screen.y() == 240);

    coord = Vec3.init(0.1, 0.1, 0);
    screen = project(width, height, coord, &view_matrix);
    if (DBG) warn("math3d.lookAtLh: coord={} screen={}\n", &coord, &screen);
    pos_x = 0.1 * width;
    pos_y = 0.1 * height;
    assert(screen.x() == width/2.0 + pos_x);
    assert(screen.y() == height/2.0 - pos_y);

    coord = Vec3.init(-0.1, -0.1, 0);
    screen = project(width, height, coord, &view_matrix);
    if (DBG) warn("math3d.lookAtLh: coord={} screen={}\n", &coord, &screen);
    assert(screen.x() == width/2.0 - pos_x);
    assert(screen.y() == height/2.0 + pos_y);
}

pub fn project(widthf: f32, heightf: f32, coord: Vec3, transMat: *const Mat4x4) Vec2 {
    if (DBG) warn("project:    original coord={} widthf={.3} heightf={.3}\n", &coord, widthf, heightf);

    // Transform coord in 3D
    var point = coord.transform(transMat);
    if (DBG) warn("project: transformed point={}\n", &point);

    // The transformed coord is based on a coordinate system
    // where the origin is the center of the screen. Convert
    // them to coordindates where x:0, y:0 is the upper left.
    var x = (point.x() * widthf) + (widthf / 2.0);
    var y = (-point.y() * heightf) + (heightf / 2.0);
    var centered = Vec2.init(x, y);
    if (DBG) warn("project:   centered={}\n", &centered);
    return centered;
}


/// Creates a right-handed perspective project matrix
/// BasedOn: https://github.com/sharpdx/SharpDX/blob/755cb46d59f4bfb94386ff2df3fceccc511c216b/Source/SharpDX.Mathematics/Matrix.cs#L2328
pub fn perspectiveFovRh(fov: f32, aspect: f32, znear: f32, zfar: f32) Mat4x4 {
    var y_scale: f32 = 1.0 / math.tan(fov * 0.5);
    var q = zfar / (znear - zfar);

    return Mat4x4.{ .data = [][4]f32.{
        []f32.{ y_scale / aspect, 0, 0, 0 },
        []f32.{ 0, y_scale, 0, 0 },
        []f32.{ 0, 0, q, -1.0 },
        []f32.{ 0, 0, q * znear, 0 },
    } };
}

test "math3d.perspectiveFovRh" {
    var fov: f32 = 0.78;
    var widthf: f32 = 640;
    var heightf: f32 = 480;
    var znear: f32 = 0.01;
    var zvar: f32 = 1.0;
    var projection_matrix = perspectiveFovRh(fov, widthf / heightf, znear, zvar);
    if (DBG) warn("\nprojection_matrix:\n{}", &projection_matrix);

    const expected = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 1.8245738, 0.0000000, 0.0000000, 0.0000000 },
        []f32.{ 0.0000000, 2.4327650, 0.0000000, 0.0000000 },
        []f32.{ 0.0000000, 0.0000000, -1.0101010, -1.0000000 },
        []f32.{ 0.0000000, 0.0000000, -0.0101010, 0.0000000 },
    } };
    projection_matrix.assert_matrix_eq(&expected);
}

/// Builds a Yaw Pitch Roll Rotation matrix from x, y, z angles in radians.
pub fn rotationYawPitchRoll(x: f32, y: f32, z: f32) Mat4x4 {
    const rz = Mat4x4.{ .data = [][4]f32.{
        []f32.{ math.cos(z), -math.sin(z), 0.0, 0.0 },
        []f32.{ math.sin(z), math.cos(z), 0.0, 0.0 },
        []f32.{ 0.0, 0.0, 1.0, 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    if (DBG) warn("rotationYawPitchRoll rz:\n{}", &rz);

    const rx = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 1.0, 0.0, 0.0, 0.0 },
        []f32.{ 0.0, math.cos(x), -math.sin(x), 0.0 },
        []f32.{ 0.0, math.sin(x), math.cos(x), 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    if (DBG) warn("rotationYawPitchRoll rx:\n{}", &rx);

    const ry = Mat4x4.{ .data = [][4]f32.{
        []f32.{ math.cos(y), 0.0, math.sin(y), 0.0 },
        []f32.{ 0.0, 1.0, 0.0, 0.0 },
        []f32.{ -math.sin(y), 0.0, math.cos(y), 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    if (DBG) warn("rotationYawPitchRoll ry:\n{}", &ry);

    var m = rz.mult(&ry.mult(&rx));
    if (DBG) warn("rotationYawPitchRoll m:\n{}", &m);

    return m;
}

pub fn rotationYawPitchRollVec3(point: Vec3) Mat4x4 {
    return rotationYawPitchRoll(point.x(), point.y(), point.z());
}

/// Builds a Yaw Pitch Roll Rotation matrix from x, y, z angles in radians.
/// With the x, y, z applied in the opposite order then rotationYawPitchRoll.
pub fn rotationYawPitchRollNeg(x: f32, y: f32, z: f32) Mat4x4 {
    const rz = Mat4x4.{ .data = [][4]f32.{
        []f32.{ math.cos(z), -math.sin(z), 0.0, 0.0 },
        []f32.{ math.sin(z), math.cos(z), 0.0, 0.0 },
        []f32.{ 0.0, 0.0, 1.0, 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    if (DBG) warn("rotationYawPitchRollNeg rz:\n{}", &rz);

    const rx = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 1.0, 0.0, 0.0, 0.0 },
        []f32.{ 0.0, math.cos(x), -math.sin(x), 0.0 },
        []f32.{ 0.0, math.sin(x), math.cos(x), 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    if (DBG) warn("rotationYawPitchRollNeg rx:\n{}", &rx);

    const ry = Mat4x4.{ .data = [][4]f32.{
        []f32.{ math.cos(y), 0.0, math.sin(y), 0.0 },
        []f32.{ 0.0, 1.0, 0.0, 0.0 },
        []f32.{ -math.sin(y), 0.0, math.cos(y), 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    if (DBG) warn("rotationYawPitchRollNeg ry:\n{}", &ry);

    var m = rx.mult(&ry.mult(&rz));
    if (DBG) warn("rotationYawPitchRollNeg m:\n{}", &m);

    return m;
}

test "math3d.rotationYawPitchRoll" {
    if (DBG) warn("\n");
    const deg10rad: f32 = 0.174522;
    var m_zero = rotationYawPitchRoll(0, 0, 0);
    if (DBG) warn("m_zero:\n{}", &m_zero);

    var m_x_pos_ten_deg = rotationYawPitchRoll(deg10rad, 0, 0);
    if (DBG) warn("m_x_pos_ten_deg:\n{}", &m_x_pos_ten_deg);
    var m_x_neg_ten_deg = rotationYawPitchRoll(-deg10rad, 0, 0);
    if (DBG) warn("m_x_neg_ten_deg:\n{}", &m_x_neg_ten_deg);
    var x = m_x_pos_ten_deg.mult(&m_x_neg_ten_deg);
    if (DBG) warn("x = pos * neg:\n{}", & x);
    m_zero.assert_matrix_eq(&x);

    if (DBG) warn("\n");
    var m_y_pos_ten_deg = rotationYawPitchRoll(0, deg10rad, 0);
    if (DBG) warn("m_y_pos_ten_deg:\n{}", m_y_pos_ten_deg);
    var m_y_neg_ten_deg = rotationYawPitchRoll(0, -deg10rad, 0);
    if (DBG) warn("m_y_neg_ten_deg:\n{}", m_y_neg_ten_deg);
    var y = m_y_pos_ten_deg.mult(&m_y_neg_ten_deg);
    if (DBG) warn("y = pos * neg:\n{}", &y);
    m_zero.assert_matrix_eq(&y);

    if (DBG) warn("\n");
    var m_z_pos_ten_deg = rotationYawPitchRoll(0, 0, deg10rad);
    if (DBG) warn("m_z_pos_ten_deg:\n{}", m_z_pos_ten_deg);
    var m_z_neg_ten_deg = rotationYawPitchRoll(0, 0, -deg10rad);
    if (DBG) warn("m_z_neg_ten_deg:\n{}", m_z_neg_ten_deg);
    var z = m_z_pos_ten_deg.mult(&m_z_neg_ten_deg);
    if (DBG) warn("z = pos * neg:\n{}", &z);
    m_zero.assert_matrix_eq(&z);

    if (DBG) warn("\n");
    var xy_pos = m_x_pos_ten_deg.mult(&m_y_pos_ten_deg);
    if (DBG) warn("xy_pos = x_pos_ten * y_pos_ten:\n{}", &xy_pos);
    var a = xy_pos.mult(&m_y_neg_ten_deg);
    if (DBG) warn("a = xy_pos * y_pos_ten\n{}", &a);
    var b = a.mult(&m_x_neg_ten_deg);
    if (DBG) warn("b = a * x_pos_ten\n{}", &b);
    m_zero.assert_matrix_eq(&b);

    // To undo a rotationYayPitchRoll the multiplication in rotationYawPitch
    // must be applied reverse order. So rz.mult(&ry.mult(&rx)) which is
    //   1) r1 = ry * rx
    //   2) r2 = rz * r1
    // must be applied:
    //   1) r3 = -rz * r2
    //   2) r4 = -ry * r3
    //   3) r5 = -rx * r4
    if (DBG) warn("\n");
    var r2 = rotationYawPitchRoll(deg10rad, deg10rad, deg10rad);
    if (DBG) warn("r2:\n{}", &r2);
    var r3 = m_z_neg_ten_deg.mult(&r2);
    var r4 = m_y_neg_ten_deg.mult(&r3);
    var r5 = m_x_neg_ten_deg.mult(&r4);
    if (DBG) warn("r5:\n{}", &r5);
    m_zero.assert_matrix_eq(&r5);

    // Here is the above as a single line both are equal to m_zero
    r5 = m_x_neg_ten_deg.mult(&m_y_neg_ten_deg.mult(&m_z_neg_ten_deg.mult(&r2)));
    if (DBG) warn("r5 one line:\n{}", &r5);
    m_zero.assert_matrix_eq(&r5);

    // Or you can use rotationYawPitchRollNeg
    var rneg = rotationYawPitchRollNeg(-deg10rad, -deg10rad, -deg10rad);
    if (DBG) warn("rneg:\n{}", &rneg);
    r5 = rneg.mult(&r2);
    if (DBG) warn("r5:\n{}", &r5);
    m_zero.assert_matrix_eq(&r5);
}

test "math3d.world_to_screen" {
    if (DBG) warn("\n");
    const T = f32;
    const fov: T = 90;
    const widthf: T = 512;
    const heightf: T = 512;
    const width: u32 = @floatToInt(u32, 512);
    const height: u32 = @floatToInt(u32, 512);
    const aspect: T = widthf / heightf;
    const znear: T = 0.01;
    const zfar: T = 1.0;
    var camera_to_perspective_matrix = perspectiveFovRh(fov * math.pi/180, aspect, znear, zfar);

    var world_to_camera_matrix = mat4x4_identity;
    world_to_camera_matrix.data[3][2] = -2;

    var world_vertexs = []Vec3.{
        Vec3.init(0, 1.0, 0),
        Vec3.init(0, -1.0, 0),
        Vec3.init(0, 1.0, 0.2),
        Vec3.init(0, -1.0, -0.2),
    };
    var expected_camera_vertexs = []Vec3.{
        Vec3.init(0, 1.0, -2),
        Vec3.init(0, -1.0, -2),
        Vec3.init(0, 1.0, -1.8),
        Vec3.init(0, -1.0, -2.2),
    };
    var expected_projected_vertexs = []Vec3.{
        Vec3.init(0, 0.5, 1.0050504),
        Vec3.init(0, -0.5, 1.0050504),
        Vec3.init(0, 0.5555555, 1.0044893),
        Vec3.init(0, -0.4545454, 1.0055095),
    };
    var expected_screen_vertexs = [][2]u32.{
        []u32.{256, 128},
        []u32.{256, 384},
        []u32.{256, 113},
        []u32.{256, 372},
    };
    for (world_vertexs) |world_vert, i| {
        if (DBG) warn("world_vert[{}]  = {}\n", i, &world_vert);

        var camera_vert = world_vert.transform(&world_to_camera_matrix);
        if (DBG) warn("camera_vert    = {}\n", camera_vert);
        assert(camera_vert.approxEql(&expected_camera_vertexs[i], 6));

        var projected_vert = camera_vert.transform(&camera_to_perspective_matrix);
        if (DBG) warn("projected_vert = {}", projected_vert);
        assert(projected_vert.approxEql(&expected_projected_vertexs[i], 6));

        var xf = projected_vert.x();
        var yf = projected_vert.y();
        if (DBG) warn(" {.3}:{.3}", xf, yf);
        if ((xf < -1) or (xf > 1) or (yf < -1) or (yf > 1)) {
            if (DBG) warn(" clipped\n");
        }

        var x = @floatToInt(u32, math.min(widthf - 1, (xf + 1) * 0.5 * widthf));
        var y = @floatToInt(u32, math.min(heightf - 1, (1 - (yf + 1) * 0.5) * heightf));
        if (DBG) warn (" visible {}:{}\n", x, y);
        assert(x == expected_screen_vertexs[i][0]);
        assert(y == expected_screen_vertexs[i][1]);
    }
}
