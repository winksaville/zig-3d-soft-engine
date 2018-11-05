/// Some 3D Math code
///
/// BasedOn: [math3d.zig from Andrew Kelly tetris](https://github.com/andrewrk/tetris/blob/master/src/math3d.zig)
/// and enhancements from [SharpDx](https://github.com/sharpdx/SharpDX).
const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
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

    /// Builds a rotation 4 * 4 matrix created from an axis vector and an angle.
    /// Input matrix multiplied by this rotation matrix.
    /// angle: Rotation angle expressed in radians.
    /// axis: Rotation axis, recommended to be normalized.
    pub fn rotate(m: *const Mat4x4, angle: f32, axis_unnormalized: *const Vec3) Mat4x4 {
        const cos = math.cos(angle);
        const s = math.sin(angle);
        const axis = axis_unnormalized.normalize();
        const temp = axis.scale(1.0 - cos);

        const rot = Mat4x4.{ .data = [][4]f32.{
            []f32.{ cos + temp.data[0] * axis.data[0], 0.0 + temp.data[1] * axis.data[0] - s * axis.data[2], 0.0 + temp.data[2] * axis.data[0] + s * axis.data[1], 0.0 },
            []f32.{ 0.0 + temp.data[0] * axis.data[1] + s * axis.data[2], cos + temp.data[1] * axis.data[1], 0.0 + temp.data[2] * axis.data[1] - s * axis.data[0], 0.0 },
            []f32.{ 0.0 + temp.data[0] * axis.data[2] - s * axis.data[1], 0.0 + temp.data[1] * axis.data[2] + s * axis.data[0], cos + temp.data[2] * axis.data[2], 0.0 },
            []f32.{ 0.0, 0.0, 0.0, 0.0 },
        } };

        return Mat4x4.{ .data = [][4]f32.{
            []f32.{
                m.data[0][0] * rot.data[0][0] + m.data[0][1] * rot.data[1][0] + m.data[0][2] * rot.data[2][0],
                m.data[0][0] * rot.data[0][1] + m.data[0][1] * rot.data[1][1] + m.data[0][2] * rot.data[2][1],
                m.data[0][0] * rot.data[0][2] + m.data[0][1] * rot.data[1][2] + m.data[0][2] * rot.data[2][2],
                m.data[0][3],
            },
            []f32.{
                m.data[1][0] * rot.data[0][0] + m.data[1][1] * rot.data[1][0] + m.data[1][2] * rot.data[2][0],
                m.data[1][0] * rot.data[0][1] + m.data[1][1] * rot.data[1][1] + m.data[1][2] * rot.data[2][1],
                m.data[1][0] * rot.data[0][2] + m.data[1][1] * rot.data[1][2] + m.data[1][2] * rot.data[2][2],
                m.data[1][3],
            },
            []f32.{
                m.data[2][0] * rot.data[0][0] + m.data[2][1] * rot.data[1][0] + m.data[2][2] * rot.data[2][0],
                m.data[2][0] * rot.data[0][1] + m.data[2][1] * rot.data[1][1] + m.data[2][2] * rot.data[2][1],
                m.data[2][0] * rot.data[0][2] + m.data[2][1] * rot.data[1][2] + m.data[2][2] * rot.data[2][2],
                m.data[2][3],
            },
            []f32.{
                m.data[3][0] * rot.data[0][0] + m.data[3][1] * rot.data[1][0] + m.data[3][2] * rot.data[2][0],
                m.data[3][0] * rot.data[0][1] + m.data[3][1] * rot.data[1][1] + m.data[3][2] * rot.data[2][1],
                m.data[3][0] * rot.data[0][2] + m.data[3][1] * rot.data[1][2] + m.data[3][2] * rot.data[2][2],
                m.data[3][3],
            },
        } };
    }

    /// Builds a translation 4 * 4 matrix created from a vector of 3 components.
    /// Input matrix multiplied by this translation matrix.
    pub fn translate(m: *const Mat4x4, x: f32, y: f32, z: f32) Mat4x4 {
        return Mat4x4.{ .data = [][4]f32.{
            []f32.{ m.data[0][0], m.data[0][1], m.data[0][2], m.data[0][3] + m.data[0][0] * x + m.data[0][1] * y + m.data[0][2] * z },
            []f32.{ m.data[1][0], m.data[1][1], m.data[1][2], m.data[1][3] + m.data[1][0] * x + m.data[1][1] * y + m.data[1][2] * z },
            []f32.{ m.data[2][0], m.data[2][1], m.data[2][2], m.data[2][3] + m.data[2][0] * x + m.data[2][1] * y + m.data[2][2] * z },
            []f32.{ m.data[3][0], m.data[3][1], m.data[3][2], m.data[3][3] },
        } };
    }

    pub fn translate_by_vec(m: *const Mat4x4, v: *const Vec3) Mat4x4 {
        return m.translate(v.data[0], v.data[1], v.data[2]);
    }

    /// Builds a scale 4 * 4 matrix created from 3 scalars.
    /// Input matrix multiplied by this scale matrix.
    pub fn scale(m: *const Mat4x4, x: f32, y: f32, z: f32) Mat4x4 {
        return Mat4x4.{ .data = [][4]f32.{
            []f32.{ m.data[0][0] * x, m.data[0][1] * y, m.data[0][2] * z, m.data[0][3] },
            []f32.{ m.data[1][0] * x, m.data[1][1] * y, m.data[1][2] * z, m.data[1][3] },
            []f32.{ m.data[2][0] * x, m.data[2][1] * y, m.data[2][2] * z, m.data[2][3] },
            []f32.{ m.data[3][0] * x, m.data[3][1] * y, m.data[3][2] * z, m.data[3][3] },
        } };
    }

    pub fn transpose(m: *const Mat4x4) Mat4x4 {
        return Mat4x4.{ .data = [][4]f32.{
            []f32.{ m.data[0][0], m.data[1][0], m.data[2][0], m.data[3][0] },
            []f32.{ m.data[0][1], m.data[1][1], m.data[2][1], m.data[3][1] },
            []f32.{ m.data[0][2], m.data[1][2], m.data[2][2], m.data[3][2] },
            []f32.{ m.data[0][3], m.data[1][3], m.data[2][3], m.data[3][3] },
        } };
    }
};

pub const mat4x4_identity = Mat4x4.{ .data = [][4]f32.{
    []f32.{ 1.0, 0.0, 0.0, 0.0 },
    []f32.{ 0.0, 1.0, 0.0, 0.0 },
    []f32.{ 0.0, 0.0, 1.0, 0.0 },
    []f32.{ 0.0, 0.0, 0.0, 1.0 },
} };

/// Creates a matrix for an orthographic parallel viewing volume.
pub fn mat4x4_ortho(left: f32, right: f32, bottom: f32, top: f32) Mat4x4 {
    var m = mat4x4_identity;
    m.data[0][0] = 2.0 / (right - left);
    m.data[1][1] = 2.0 / (top - bottom);
    m.data[2][2] = -1.0;
    m.data[0][3] = -(right + left) / (right - left);
    m.data[1][3] = -(top + bottom) / (top - bottom);
    return m;
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

/// Builds a Yaw Pitch Roll Rotation matrix from x, y, z angles in radians.
pub fn rotationYawPitchRoll(x: f32, y: f32, z: f32) Mat4x4 {
    const rz = Mat4x4.{ .data = [][4]f32.{
        []f32.{ math.cos(z), -math.sin(z), 0.0, 0.0 },
        []f32.{ math.sin(z), math.cos(z), 0.0, 0.0 },
        []f32.{ 0.0, 0.0, 1.0, 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    //printMat4x4("rotationYawPitchRoll rz:\n", &rz);

    const rx = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 1.0, 0.0, 0.0, 0.0 },
        []f32.{ 0.0, math.cos(x), -math.sin(x), 0.0 },
        []f32.{ 0.0, math.sin(x), math.cos(x), 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    //printMat4x4("rotationYawPitchRoll rx:\n", &rx);

    const ry = Mat4x4.{ .data = [][4]f32.{
        []f32.{ math.cos(y), 0.0, -math.sin(y), 0.0 },
        []f32.{ 0.0, 1.0, 0.0, 0.0 },
        []f32.{ math.sin(y), 0.0, math.cos(y), 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    //printMat4x4("rotationYawPitchRoll ry:\n", &ry);

    var m = rz.mult(&ry.mult(&rx));
    //printMat4x4("rotationYawPitchRoll m:\n", &m);

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
    //printMat4x4("rotationYawPitchRollNeg rz:\n", &rz);

    const rx = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 1.0, 0.0, 0.0, 0.0 },
        []f32.{ 0.0, math.cos(x), -math.sin(x), 0.0 },
        []f32.{ 0.0, math.sin(x), math.cos(x), 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    //printMat4x4("rotationYawPitchRollNeg rx:\n", &rx);

    const ry = Mat4x4.{ .data = [][4]f32.{
        []f32.{ math.cos(y), 0.0, -math.sin(y), 0.0 },
        []f32.{ 0.0, 1.0, 0.0, 0.0 },
        []f32.{ math.sin(y), 0.0, math.cos(y), 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    //printMat4x4("rotationYawPitchRollNeg ry:\n", &ry);

    var m = rx.mult(&ry.mult(&rz));
    //printMat4x4("rotationYawPitchRollNeg m:\n", &m);

    return m;
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

pub fn printMat4x4(s: []const u8, m: *const Mat4x4) void {
    warn("{}", s);
    for (m.data) |row, i| {
        //warn("{}: []f32.{{ ", i);
        warn("    []f32.{{ ");
        for (row) |col, j| {
            warn("{.7}{} ", col, if (j < (row.len - 1)) "," else "");
        }
        warn("}},\n");
    }
}

const warn = std.debug.warn;

test "math3d.scale" {
    const m = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 0.840188, 0.911647, 0.277775, 0.364784 },
        []f32.{ 0.394383, 0.197551, 0.55397, 0.513401 },
        []f32.{ 0.783099, 0.335223, 0.477397, 0.95223 },
        []f32.{ 0.79844, 0.76823, 0.628871, 0.916195 },
    } };
    printMat4x4("scale: m:\n", &m);
    const expected = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 0.1189731, 0.6539217, 0.1765849, 0.3647840 },
        []f32.{ 0.0558458, 0.1417027, 0.3521654, 0.5134010 },
        []f32.{ 0.1108892, 0.2404545, 0.3034870, 0.9522300 },
        []f32.{ 0.1130615, 0.5510491, 0.3997809, 0.9161950 },
    } };
    printMat4x4("scale: expected:\n", &expected);
    const answer = m.scale(0.141603, 0.717297, 0.635712);
    printMat4x4("scale: answer:\n", &answer);
    assert_matrix_eq(answer, expected);
}

test "math3d.translate" {
    const m = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 0.840188, 0.911647, 0.277775, 0.364784 },
        []f32.{ 0.394383, 0.197551, 0.55397, 0.513401 },
        []f32.{ 0.783099, 0.335223, 0.477397, 0.95223 },
        []f32.{ 0.79844, 0.76823, 0.628871, 1.0 },
    } };
    printMat4x4("translate: m:\n", &m);
    const expected = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 0.8401880, 0.9116470, 0.2777750, 1.3142638 },
        []f32.{ 0.3943830, 0.1975510, 0.5539700, 1.0631149 },
        []f32.{ 0.7830990, 0.3352230, 0.4773970, 1.6070607 },
        []f32.{ 0.7984400, 0.7682300, 0.6288710, 1.0000000 },
    } };
    printMat4x4("translate: expected:\n", &expected);
    const answer = m.translate(0.141603, 0.717297, 0.635712);
    printMat4x4("translate: answer:\n", &answer);
    assert_matrix_eq(answer, expected);
}

fn assert_matrix_eq(left: Mat4x4, right: Mat4x4) void {
    const digits = 7;
    assert(approxEql(left.data[0][0], right.data[0][0], digits));
    assert(approxEql(left.data[0][1], right.data[0][1], digits));
    assert(approxEql(left.data[0][2], right.data[0][2], digits));
    assert(approxEql(left.data[0][3], right.data[0][3], digits));

    assert(approxEql(left.data[1][0], right.data[1][0], digits));
    assert(approxEql(left.data[1][1], right.data[1][1], digits));
    assert(approxEql(left.data[1][2], right.data[1][2], digits));
    assert(approxEql(left.data[1][3], right.data[1][3], digits));

    assert(approxEql(left.data[2][0], right.data[2][0], digits));
    assert(approxEql(left.data[2][1], right.data[2][1], digits));
    assert(approxEql(left.data[2][2], right.data[2][2], digits));
    assert(approxEql(left.data[2][3], right.data[2][3], digits));

    assert(approxEql(left.data[3][0], right.data[3][0], digits));
    assert(approxEql(left.data[3][1], right.data[3][1], digits));
    assert(approxEql(left.data[3][2], right.data[3][2], digits));
    assert(approxEql(left.data[3][3], right.data[3][3], digits));
}

test "math3d.ortho" {
    const m = mat4x4_ortho(0.840188, 0.394383, 0.783099, 0.79844);

    const expected = Mat4x4.{ .data = [][4]f32.{
        []f32.{ -4.4862661, 0.0, 0.0, 2.7693071 },
        []f32.{ 0.0, 130.36974, 0.0, -103.09241 },
        []f32.{ 0.0, 0.0, -1.0, 0.0 },
        []f32.{ 0.0, 0.0, 0.0, 1.0 },
    } };
    printMat4x4("\nm:\n", &m);
    printMat4x4("expected:\n", &expected);

    assert_matrix_eq(m, expected);
}

test "math3d.mult" {
    const m1 = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 0.635712, 0.717297, 0.141603, 0.606969 },
        []f32.{ 0.0163006, 0.242887, 0.137232, 0.804177 },
        []f32.{ 0.156679, 0.400944, 0.12979, 0.108809 },
        []f32.{ 0.998924, 0.218257, 0.512932, 0.839112 },
    } };
    const m2 = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 0.840188, 0.394383, 0.783099, 0.79844 },
        []f32.{ 0.911647, 0.197551, 0.335223, 0.76823 },
        []f32.{ 0.277775, 0.55397, 0.477397, 0.628871 },
        []f32.{ 0.364784, 0.513401, 0.95223, 0.916195 },
    } };
    const answer = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 1.4487857, 0.7824790, 1.3838549, 1.7037790 },
        []f32.{ 0.5665933, 0.5432989, 0.9254619, 1.0226922 },
        []f32.{ 0.5729035, 0.2687608, 0.4226734, 0.6144274 },
        []f32.{ 1.4868317, 1.1520255, 1.8993208, 2.0566108 },
    } };
    const tmp = m1.mult(&m2);
    printMat4x4("\ntmp:\n", &tmp);
    assert_matrix_eq(tmp, answer);
}

test "math3d.rotate" {
    const m1 = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 0.840188, 0.911647, 0.277775, 0.364784 },
        []f32.{ 0.394383, 0.197551, 0.55397, 0.513401 },
        []f32.{ 0.783099, 0.335223, 0.477397, 0.95223 },
        []f32.{ 0.79844, 0.76823, 0.628871, 0.916195 },
    } };
    const angle = 0.635712;

    const axis = vec3(0.606969, 0.141603, 0.717297);

    const expected = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 1.1701527, 0.4880189, 0.0821917, 0.3647840 },
        []f32.{ 0.4441513, 0.2126591, 0.5088741, 0.5134010 },
        []f32.{ 0.8517390, 0.1263189, 0.4605548, 0.9522300 },
        []f32.{ 1.0682929, 0.5308014, 0.4473957, 0.9161950 },
    } };
    printMat4x4("\nexpected:\n", &expected);

    const actual = m1.rotate(angle, &axis);
    printMat4x4("actual:\n", &actual);
    assert_matrix_eq(actual, expected);
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

test "math3d.vec3.transform.identity" {
    var v1 = vec3(0, 0, 0);
    var r = v1.transform(&mat4x4_identity);
    assert(r.x() == 0);
    assert(r.y() == 0);
    assert(r.z() == 0);

    v1 = vec3(0.5, 0.5, 0.5);
    r = v1.transform(&mat4x4_identity);
    assert(r.x() == 0.5);
    assert(r.y() == 0.5);
    assert(r.z() == 0.5);

    v1 = vec3(1, 1, 1);
    r = v1.transform(&mat4x4_identity);
    assert(r.x() == 1);
    assert(r.y() == 1);
    assert(r.z() == 1);
}

test "math3d.vec3.transform" {
    const v1 = vec3(0.606969, 0.141603, 0.717297);
    const m1 = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 0.840188, 0.911647, 0.277775, 0.364784 },
        []f32.{ 0.394383, 0.197551, 0.55397, 0.513401 },
        []f32.{ 0.783099, 0.335223, 0.477397, 0.95223 },
        []f32.{ 0.79844, 0.76823, 0.628871, 0.916195 },
    } };
    var r = v1.transform(&m1);

    //warn("r.x={} r.y={} r.z={}\n", r.x(), r.y(), r.z());
    // Asserts maybe wrong, I've got the values by printing the results
    assert(r.x() == 1.0172341);
    assert(r.y() == 0.8397864);
    assert(r.z() == 0.6434936);
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

test "math3d.vec3.subtract" {
    var v1 = vec3(0, 0, 0);
    var v2 = vec3(0, 0, 0);
    var r = v1.subtract(&v2);
    assert(r.x() == 0);
    assert(r.y() == 0);
    assert(r.z() == 0);

    v1 = vec3(1, 2, 3);
    v2 = vec3(1, -2, 4);
    r = v1.subtract(&v2);
    assert(r.x() == 0);
    assert(r.y() == 4);
    assert(r.z() == -1);
}

test "math3d.lookAtLh" {
    var eye = Vec3.init(0, 0, 10);
    var target = Vec3.init(0, 0, 0);
    var view_matrix = lookAtLh(&eye, &target, &Vec3.unitY());
    printMat4x4("\nview_matrix:\n", &view_matrix);

    const expected = Mat4x4.{ .data = [][4]f32.{
        []f32.{ -1.00000, 0.00000, 0.00000, -0.00000 },
        []f32.{ 0.00000, 1.00000, 0.00000, -0.00000 },
        []f32.{ 0.00000, 0.00000, -1.00000, 10.00000 },
        []f32.{ 0.00000, 0.00000, 0.00000, 1.00000 },
    } };
    assert_matrix_eq(view_matrix, expected);
}

test "math3d.perspectiveFovRh" {
    var fov: f32 = 0.78;
    var widthf: f32 = 640;
    var heightf: f32 = 480;
    var znear: f32 = 0.01;
    var zvar: f32 = 1.0;
    var projection_matrix = perspectiveFovRh(fov, widthf / heightf, znear, zvar);
    printMat4x4("\nprojection_matrix:\n", &projection_matrix);

    const expected = Mat4x4.{ .data = [][4]f32.{
        []f32.{ 1.8245738, 0.0000000, 0.0000000, 0.0000000 },
        []f32.{ 0.0000000, 2.4327650, 0.0000000, 0.0000000 },
        []f32.{ 0.0000000, 0.0000000, -1.0101010, -1.0000000 },
        []f32.{ 0.0000000, 0.0000000, -0.0101010, 0.0000000 },
    } };
    assert_matrix_eq(projection_matrix, expected);
}

test "math3d.rotationYawPitchRoll" {
    warn("\n");
    const deg10rad: f32 = 0.174522;
    var m_zero = rotationYawPitchRoll(0, 0, 0);
    printMat4x4("m_zero:\n", &m_zero);

    var m_x_pos_ten_deg = rotationYawPitchRoll(deg10rad, 0, 0);
    printMat4x4("m_x_pos_ten_deg:\n", &m_x_pos_ten_deg);
    var m_x_neg_ten_deg = rotationYawPitchRoll(-deg10rad, 0, 0);
    printMat4x4("m_x_neg_ten_deg:\n", &m_x_neg_ten_deg);
    var x = m_x_pos_ten_deg.mult(&m_x_neg_ten_deg);
    printMat4x4("x = pos * neg:\n", &x);
    assert_matrix_eq(m_zero, x);

    warn("\n");
    var m_y_pos_ten_deg = rotationYawPitchRoll(0, deg10rad, 0);
    printMat4x4("m_y_pos_ten_deg:\n", &m_y_pos_ten_deg);
    var m_y_neg_ten_deg = rotationYawPitchRoll(0, -deg10rad, 0);
    printMat4x4("m_y_neg_ten_deg:\n", &m_y_neg_ten_deg);
    var y = m_y_pos_ten_deg.mult(&m_y_neg_ten_deg);
    printMat4x4("y = pos * neg:\n", &y);
    assert_matrix_eq(m_zero, y);

    warn("\n");
    var m_z_pos_ten_deg = rotationYawPitchRoll(0, 0, deg10rad);
    printMat4x4("m_z_pos_ten_deg:\n", &m_z_pos_ten_deg);
    var m_z_neg_ten_deg = rotationYawPitchRoll(0, 0, -deg10rad);
    printMat4x4("m_z_neg_ten_deg:\n", &m_z_neg_ten_deg);
    var z = m_z_pos_ten_deg.mult(&m_z_neg_ten_deg);
    printMat4x4("z = pos * neg:\n", &z);
    assert_matrix_eq(m_zero, z);

    warn("\n");
    var xy_pos = m_x_pos_ten_deg.mult(&m_y_pos_ten_deg);
    printMat4x4("xy_pos = x_pos_ten * y_pos_ten:\n", &xy_pos);
    var a = xy_pos.mult(&m_y_neg_ten_deg);
    printMat4x4("a = xy_pos * y_pos_ten\n", &a);
    var b = a.mult(&m_x_neg_ten_deg);
    printMat4x4("b = a * x_pos_ten\n", &b);
    assert_matrix_eq(m_zero, b);

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
    printMat4x4("r2:\n", &r2);
    var r3 = m_z_neg_ten_deg.mult(&r2);
    var r4 = m_y_neg_ten_deg.mult(&r3);
    var r5 = m_x_neg_ten_deg.mult(&r4);
    printMat4x4("r5:\n", &r5);
    assert_matrix_eq(m_zero, r5);

    // Here is the above as a single line both are equal to m_zero
    r5 = m_x_neg_ten_deg.mult(&m_y_neg_ten_deg.mult(&m_z_neg_ten_deg.mult(&r2)));
    printMat4x4("r5 one line:\n", &r5);
    assert_matrix_eq(m_zero, r5);

    // Or you can use rotationYawPitchRollNeg
    var rneg = rotationYawPitchRollNeg(-deg10rad, -deg10rad, -deg10rad);
    printMat4x4("rneg:\n", &rneg);
    r5 = rneg.mult(&r2);
    printMat4x4("r5:\n", &r5);
    assert_matrix_eq(m_zero, r5);
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
    printMat4x4("translation: expected\n", &expected);
    assert_matrix_eq(m, expected);
}
