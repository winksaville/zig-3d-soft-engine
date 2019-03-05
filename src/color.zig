const builtin = @import("builtin");
const TypeId = builtin.TypeId;

const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const warn = std.debug.warn;

const misc = @import("modules/zig-misc/index.zig");
const saturateCast = misc.saturateCast;

const DBG = false;

pub const ColorU8 = Color(u8, u8, u8, u8);

pub fn Color(comptime A: type, comptime R: type, comptime G: type, comptime B: type) type {
    return struct {
        const Self = @This();

        pub const Black = Self{ .a = misc.maxValue(A), .r = misc.minValue(R), .g = misc.minValue(G), .b = misc.minValue(B) };
        pub const White = Self{ .a = misc.maxValue(A), .r = misc.maxValue(R), .g = misc.maxValue(G), .b = misc.maxValue(B) };
        pub const Red = Self{ .a = misc.maxValue(A), .r = misc.maxValue(R), .g = misc.minValue(G), .b = misc.minValue(B) };
        pub const Green = Self{ .a = misc.maxValue(A), .r = misc.minValue(R), .g = misc.maxValue(G), .b = misc.minValue(B) };
        pub const Blue = Self{ .a = misc.maxValue(A), .r = misc.minValue(R), .g = misc.minValue(G), .b = misc.maxValue(B) };

        a: A,
        r: R,
        g: G,
        b: B,

        pub fn init(a: A, r: R, g: G, b: B) Self {
            return Self{
                .a = saturateCast(A, a),
                .r = saturateCast(R, r),
                .g = saturateCast(G, g),
                .b = saturateCast(B, b),
            };
        }

        /// Return color as a a:r:g:b u32
        pub fn asU32Argb(pSelf: *const Self) u32 {
            var a = @intCast(u32, saturateCast(u8, pSelf.a));
            var r = @intCast(u32, saturateCast(u8, pSelf.r));
            var g = @intCast(u32, saturateCast(u8, pSelf.g));
            var b = @intCast(u32, saturateCast(u8, pSelf.b));
            return (a << 24) | (r << 16) | (g << 8) | (b << 0);
        }

        /// Scale each of the rgb components by other
        pub fn colorScale(color: Self, other: f32) Self {
            var a: A = color.a;
            var r: R = saturateCast(R, math.round(saturateCast(f32, (color.r)) * other));
            var g: G = saturateCast(G, math.round(saturateCast(f32, (color.g)) * other));
            var b: B = saturateCast(B, math.round(saturateCast(f32, (color.b)) * other));

            var result = Self{
                .a = a,
                .r = r,
                .g = g,
                .b = b,
            };
            return result;
        }

        /// Custom format routine
        pub fn format(
            pSelf: *const Self,
            comptime fmt: []const u8,
            context: var,
            comptime FmtError: type,
            output: fn (@typeOf(context), []const u8) FmtError!void,
        ) FmtError!void {
            try std.fmt.format(context, FmtError, output, "{{ ");
            try formatOneColor(A, pSelf.a, fmt, context, FmtError, output, false);
            try formatOneColor(R, pSelf.r, fmt, context, FmtError, output, false);
            try formatOneColor(G, pSelf.g, fmt, context, FmtError, output, false);
            try formatOneColor(B, pSelf.b, fmt, context, FmtError, output, true);
            try std.fmt.format(context, FmtError, output, "}}");
        }
    };
}

fn formatOneColor(
    comptime T: type,
    color: T,
    comptime fmt: []const u8,
    context: var,
    comptime FmtError: type,
    output: fn (@typeOf(context), []const u8) FmtError!void,
    last: bool,
) FmtError!void {
    switch (@typeId(T)) {
        TypeId.Float => try std.fmt.format(context, FmtError, output, "{}{.3}{}", if (math.signbit(color)) "-" else " ", if (math.signbit(color)) -color else color, if (!last) ", " else " "),
        TypeId.Int => try std.fmt.format(context, FmtError, output, "{d6}{}", color, if (!last) ", " else " "),
        else => @compileError("Expected Float or Int type"),
    }
}

test "Color" {
    warn("\n");

    var cu8 = ColorU8.White;
    assert(cu8.a == 0xFF);
    assert(cu8.r == 0xFF);
    assert(cu8.g == 0xFF);
    assert(cu8.b == 0xFF);
    assert(cu8.asU32Argb() == 0xFFFFFFFF);

    cu8 = ColorU8.Black;
    assert(cu8.a == 0xFF);
    assert(cu8.r == 0x00);
    assert(cu8.g == 0x00);
    assert(cu8.b == 0x00);
    assert(cu8.asU32Argb() == 0xFF000000);

    cu8 = ColorU8.Red;
    assert(cu8.a == 0xFF);
    assert(cu8.r == 0xFF);
    assert(cu8.g == 0x00);
    assert(cu8.b == 0x00);
    assert(cu8.asU32Argb() == 0xFFFF0000);

    cu8 = ColorU8.Green;
    assert(cu8.a == 0xFF);
    assert(cu8.r == 0x00);
    assert(cu8.g == 0xFF);
    assert(cu8.b == 0x00);
    assert(cu8.asU32Argb() == 0xFF00FF00);

    cu8 = ColorU8.Blue;
    assert(cu8.a == 0xFF);
    assert(cu8.r == 0x00);
    assert(cu8.g == 0x00);
    assert(cu8.b == 0xFF);
    assert(cu8.asU32Argb() == 0xFF0000FF);

    var c = Color(f32, f32, f32, f32).init(1, 2, 3, 4);
    assert(c.a == f32(1));
    assert(c.r == f32(2));
    assert(c.g == f32(3));
    assert(c.b == f32(4));
    assert(c.asU32Argb() == 0x01020304);
    warn("c={}:{x8}\n", &c, c.asU32Argb());

    var d = Color(u2, i10, i10, i10).init(3, -3, -2, 2);
    assert(d.a == u2(3));
    assert(d.r == i10(-3));
    assert(d.g == i10(-2));
    assert(d.b == i10(2));
    // This is probably wrong, we should unbias the result!
    assert(d.asU32Argb() == 0x03000002);
    warn("d={}:{x8}\n", &d, d.asU32Argb());

    var u = Color(u2, u10, u10, u10).init(0, 3, 2, 1);
    assert(u.a == u2(0));
    assert(u.r == u10(3));
    assert(u.g == u10(2));
    assert(u.b == u10(1));
    assert(u.asU32Argb() == 0x00030201);
    warn("u={}:{x8}\n", &u, u.asU32Argb());
}
