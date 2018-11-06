/// Some 3D Math code
///
/// BasedOn: [math3d.zig from Andrew Kelly tetris](https://github.com/andrewrk/tetris/blob/master/src/math3d.zig)
/// and enhancements from [SharpDx](https://github.com/sharpdx/SharpDX).
const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const warn = std.debug.warn;
const approxEql = @import("../modules/zig-approxeql/approxeql.zig").approxEql;

pub const Mat4x4 = struct.{
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
        assert(approxEql(pSelf.data[0][0], pOther.data[0][0], digits));
        assert(approxEql(pSelf.data[0][1], pOther.data[0][1], digits));
        assert(approxEql(pSelf.data[0][2], pOther.data[0][2], digits));
        assert(approxEql(pSelf.data[0][3], pOther.data[0][3], digits));

        assert(approxEql(pSelf.data[1][0], pOther.data[1][0], digits));
        assert(approxEql(pSelf.data[1][1], pOther.data[1][1], digits));
        assert(approxEql(pSelf.data[1][2], pOther.data[1][2], digits));
        assert(approxEql(pSelf.data[1][3], pOther.data[1][3], digits));

        assert(approxEql(pSelf.data[2][0], pOther.data[2][0], digits));
        assert(approxEql(pSelf.data[2][1], pOther.data[2][1], digits));
        assert(approxEql(pSelf.data[2][2], pOther.data[2][2], digits));
        assert(approxEql(pSelf.data[2][3], pOther.data[2][3], digits));

        assert(approxEql(pSelf.data[3][0], pOther.data[3][0], digits));
        assert(approxEql(pSelf.data[3][1], pOther.data[3][1], digits));
        assert(approxEql(pSelf.data[3][2], pOther.data[3][2], digits));
        assert(approxEql(pSelf.data[3][3], pOther.data[3][3], digits));
    }

    pub fn print(pSelf: *const Mat4x4, s: []const u8) void {
        warn("{}", s);
        for (pSelf.data) |row, i| {
            //warn("{}: []f32.{{ ", i);
            warn("    []f32.{{ ");
            for (row) |col, j| {
                warn("{.7}{} ", col, if (j < (row.len - 1)) "," else "");
            }
            warn("}},\n");
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

    pub fn length(v: Vec2) f32 {
        return math.sqrt(v.dot(v));
    }

    pub fn add(v: *const Vec2, other: *const Vec2) Vec2 {
        return Vec2.{ .data = []f32.{
            v.data[0] + other.data[0],
            v.data[1] + other.data[1],
        } };
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
        return Vec3.{ .data = []f32.{
            v.data[0] * scalar,
            v.data[1] * scalar,
            v.data[2] * scalar,
        } };
    }

    pub fn dot(v: *const Vec3, other: *const Vec3) f32 {
        return v.data[0] * other.data[0] +
            v.data[1] * other.data[1] +
            v.data[2] * other.data[2];
    }

    pub fn length(v: Vec3) f32 {
        return math.sqrt(v.dot(v));
    }

    /// returns the cross product
    pub fn cross(v: *const Vec3, other: *const Vec3) Vec3 {
        return Vec3.{ .data = []f32.{
            v.data[1] * other.data[2] - other.data[1] * v.data[2],
            v.data[2] * other.data[0] - other.data[2] * v.data[0],
            v.data[0] * other.data[1] - other.data[0] * v.data[1],
        } };
    }

    pub fn add(v: *const Vec3, other: *const Vec3) Vec3 {
        return Vec3.{ .data = []f32.{
            v.data[0] + other.data[0],
            v.data[1] + other.data[1],
            v.data[2] + other.data[2],
        } };
    }

    pub fn subtract(v: *const Vec3, other: *const Vec3) Vec3 {
        return Vec3.init(v.x() - other.x(), v.y() - other.y(), v.z() - other.z());
    }

    /// Transform the v using m returning a new Vec3.
    /// BasedOn: https://github.com/sharpdx/SharpDX/blob/755cb46d59f4bfb94386ff2df3fceccc511c216b/Source/SharpDX.Mathematics/Vector3.cs#L1388
    pub fn transform(v: *const Vec3, m: *const Mat4x4) Vec3 {
        var v4: Vec4 = undefined;
        v4.setX((v.x() * m.data[0][0]) + (v.y() * m.data[1][0]) + (v.z() * m.data[2][0]) + m.data[3][0]);
        v4.setY((v.x() * m.data[0][1]) + (v.y() * m.data[1][1]) + (v.z() * m.data[2][1]) + m.data[3][1]);
        v4.setZ((v.x() * m.data[0][2]) + (v.y() * m.data[1][2]) + (v.z() * m.data[2][2]) + m.data[3][2]);
        v4.setW(1.0 / ((v.x() * m.data[0][3]) + (v.y() * m.data[1][3]) + (v.z() * m.data[2][3]) + m.data[3][3]));

        return Vec3.init(v4.x() * v4.w(), v4.y() * v4.w(), v4.z() * v4.w());
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
    warn("\n");
    var m = translation(1, 2, 3);
    const expected = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 1.0, 0.0, 0.0, 1.0 },
        []f32.{ 0.0, 1.0, 0.0, 2.0 },
        []f32.{ 0.0, 0.0, 1.0, 3.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    expected.print("translation: expected\n");
    m.assert_matrix_eq(&expected);
}

/// Create a left-handed, look-at matrix
/// BasedOn: https://github.com/sharpdx/SharpDX/blob/755cb46d59f4bfb94386ff2df3fceccc511c216b/Source/SharpDX.Mathematics/Matrix.cs#L2010
pub fn lookAtLh(eye: *const Vec3, target: *const Vec3, up: *const Vec3) Mat4x4 {
    var zaxis = target.subtract(eye).normalize();
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

    return rmo;
}

test "math3d.lookAtLh" {
    var eye = Vec3.init(0, 0, 10);
    var target = Vec3.init(0, 0, 0);
    var view_matrix = lookAtLh(&eye, &target, &Vec3.unitY());
    view_matrix.print("\nview_matrix:\n");

    const expected = Mat4x4.{ .data = [][4]f32.{
        []f32.{ -1.00000, 0.00000, 0.00000, -0.00000 },
        []f32.{ 0.00000, 1.00000, 0.00000, -0.00000 },
        []f32.{ 0.00000, 0.00000, -1.00000, 10.00000 },
        []f32.{ 0.00000, 0.00000, 0.00000, 1.00000 },
    } };
    view_matrix.assert_matrix_eq(&expected);
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
    projection_matrix.print("\nprojection_matrix:\n");

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
    //rz.print("rotationYawPitchRoll rz:\n");

    const rx = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 1.0, 0.0, 0.0, 0.0 },
        []f32.{ 0.0, math.cos(x), -math.sin(x), 0.0 },
        []f32.{ 0.0, math.sin(x), math.cos(x), 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    //rx.print("rotationYawPitchRoll rx:\n");

    const ry = Mat4x4.{ .data = [][4]f32.{
        []f32.{ math.cos(y), 0.0, -math.sin(y), 0.0 },
        []f32.{ 0.0, 1.0, 0.0, 0.0 },
        []f32.{ math.sin(y), 0.0, math.cos(y), 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    //ry.print("rotationYawPitchRoll ry:\n");

    var m = rz.mult(&ry.mult(&rx));
    //m.print("rotationYawPitchRoll m:\n");

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
    //rz.print("rotationYawPitchRollNeg rz:\n");

    const rx = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 1.0, 0.0, 0.0, 0.0 },
        []f32.{ 0.0, math.cos(x), -math.sin(x), 0.0 },
        []f32.{ 0.0, math.sin(x), math.cos(x), 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    //rx.print("rotationYawPitchRollNeg rx:\n");

    const ry = Mat4x4.{ .data = [][4]f32.{
        []f32.{ math.cos(y), 0.0, -math.sin(y), 0.0 },
        []f32.{ 0.0, 1.0, 0.0, 0.0 },
        []f32.{ math.sin(y), 0.0, math.cos(y), 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    //ry.print("rotationYawPitchRollNeg ry:\n");

    var m = rx.mult(&ry.mult(&rz));
    //m.print("rotationYawPitchRollNeg m:\n");

    return m;
}

test "math3d.rotationYawPitchRoll" {
    warn("\n");
    const deg10rad: f32 = 0.174522;
    var m_zero = rotationYawPitchRoll(0, 0, 0);
    m_zero.print("m_zero:\n");

    var m_x_pos_ten_deg = rotationYawPitchRoll(deg10rad, 0, 0);
    m_x_pos_ten_deg.print("m_x_pos_ten_deg:\n");
    var m_x_neg_ten_deg = rotationYawPitchRoll(-deg10rad, 0, 0);
    m_x_neg_ten_deg.print("m_x_neg_ten_deg:\n");
    var x = m_x_pos_ten_deg.mult(&m_x_neg_ten_deg);
    x.print("x = pos * neg:\n");
    m_zero.assert_matrix_eq(&x);

    warn("\n");
    var m_y_pos_ten_deg = rotationYawPitchRoll(0, deg10rad, 0);
    m_y_pos_ten_deg.print("m_y_pos_ten_deg:\n");
    var m_y_neg_ten_deg = rotationYawPitchRoll(0, -deg10rad, 0);
    m_y_neg_ten_deg.print("m_y_neg_ten_deg:\n");
    var y = m_y_pos_ten_deg.mult(&m_y_neg_ten_deg);
    y.print("y = pos * neg:\n");
    m_zero.assert_matrix_eq(&y);

    warn("\n");
    var m_z_pos_ten_deg = rotationYawPitchRoll(0, 0, deg10rad);
    m_z_pos_ten_deg.print("m_z_pos_ten_deg:\n");
    var m_z_neg_ten_deg = rotationYawPitchRoll(0, 0, -deg10rad);
    m_z_neg_ten_deg.print("m_z_neg_ten_deg:\n");
    var z = m_z_pos_ten_deg.mult(&m_z_neg_ten_deg);
    z.print("z = pos * neg:\n");
    m_zero.assert_matrix_eq(&z);

    warn("\n");
    var xy_pos = m_x_pos_ten_deg.mult(&m_y_pos_ten_deg);
    xy_pos.print("xy_pos = x_pos_ten * y_pos_ten:\n");
    var a = xy_pos.mult(&m_y_neg_ten_deg);
    a.print("a = xy_pos * y_pos_ten\n");
    var b = a.mult(&m_x_neg_ten_deg);
    b.print("b = a * x_pos_ten\n");
    m_zero.assert_matrix_eq(&b);

    // To undo a rotationYayPitchRoll the multiplication in rotationYawPitch
    // must be applied reverse order. So rz.mult(&ry.mult(&rx)) which is
    //   1) r1 = ry * rx
    //   2) r2 = rz * r1
    // must be applied:
    //   1) r3 = -rz * r2
    //   2) r4 = -ry * r3
    //   3) r5 = -rx * r4
    warn("\n");
    var r2 = rotationYawPitchRoll(deg10rad, deg10rad, deg10rad);
    r2.print("r2:\n");
    var r3 = m_z_neg_ten_deg.mult(&r2);
    var r4 = m_y_neg_ten_deg.mult(&r3);
    var r5 = m_x_neg_ten_deg.mult(&r4);
    r5.print("r5:\n");
    m_zero.assert_matrix_eq(&r5);

    // Here is the above as a single line both are equal to m_zero
    r5 = m_x_neg_ten_deg.mult(&m_y_neg_ten_deg.mult(&m_z_neg_ten_deg.mult(&r2)));
    r5.print("r5 one line:\n");
    m_zero.assert_matrix_eq(&r5);

    // Or you can use rotationYawPitchRollNeg
    var rneg = rotationYawPitchRollNeg(-deg10rad, -deg10rad, -deg10rad);
    rneg.print("rneg:\n");
    r5 = rneg.mult(&r2);
    r5.print("r5:\n");
    m_zero.assert_matrix_eq(&r5);
}
