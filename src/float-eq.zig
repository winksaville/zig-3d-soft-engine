const std = @import("std");
const math = std.math;
const assert = std.debug.assert;
const warn = std.debug.warn;

fn significantDigitsDbg(v: f32, digits: usize, comptime dbg: bool) f32 {
    var vabs: f32 = math.fabs(v);
    if (dbg) warn("significantDigits: v={} vabs={}", v, vabs);
    defer { if (dbg) warn("\n"); }
    if (digits == 0) return 0.0;
    if (v == 0.0) return v;
    if (math.isNan(v)) return v;
    if (math.isPositiveInf(vabs)) return v;
    var fexp: f32 = math.log10(vabs);
    if (dbg) warn(" fexp={}", fexp);
    var exp: i32 = @floatToInt(i32, math.floor(fexp));
    if (dbg) warn(" exp={}", exp);
    var mf: f32 = math.pow(f32, 10, @intToFloat(f32, digits - 1));
    if (dbg) warn(" mf={}", mf);
    var df = math.pow(f32, 10, @intToFloat(f32, exp));
    if (dbg) warn(" df={}", df);
    var f = mf / df;
    if (dbg) warn(" f={}", f);
    var sig: f32 = math.floor(math.round(vabs * f));
    //var sig: f32 = vabs * mf / df;
    //var sig: f32 = vabs / (df / 10.0);
    if (dbg) warn(" sig={} ", sig);

    //var round_factor = math.pow(f32, 10, @intToFloat(f32, -(@bitCast(isize, digits-1)))) / 2.0;
    //var rv: f32 = v;
    //if (math.signbit(v)) {
    //    rv = -rv;
    //}
    //rv += round_factor;
    //if (dbg) warn("significantDigits: v={} rv={} rf={} vabs={}", v, rv, round_factor, vabs);

    var r = if (math.signbit(v)) -sig else sig;
    if (dbg) warn(" r={}", r);
    return sig;
}

test "significantDigitsDbg" {
    warn("\n");
    //assert(significantDigitsDbg(0.9999999999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.999999999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.99999999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.9999999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.999999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.99999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.9999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.99, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.9, 1, true) == 1.0);
    //_ = significantDigitsDbg(10.0, 1, true);
    //_ = significantDigitsDbg(1.0, 1, true);
    _ = significantDigitsDbg(9.0, 1, true);
    _ = significantDigitsDbg(0.9, 1, true);
    _ = significantDigitsDbg(0.99, 1, true);
    _ = significantDigitsDbg(0.999, 1, true);
    _ = significantDigitsDbg(0.9999, 1, true);
    _ = significantDigitsDbg(0.99999, 1, true);
    _ = significantDigitsDbg(0.999999, 1, true);
    _ = significantDigitsDbg(0.9999999, 1, true);
    _ = significantDigitsDbg(0.99999999, 1, true);
    //_ = significantDigitsDbg(0.5, 1, true);
    //_ = significantDigitsDbg(0.2, 1, true);
    //_ = significantDigitsDbg(0.1, 1, true);

    //assert(significantDigitsDbg(-0.9, 1, true) == -1.0);
    //assert(significantDigitsDbg(0.9999999999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.9999999999, 2, true) == 10.0);
    //assert(significantDigitsDbg(0.9999999999, 3, true) == 100.0);
    //assert(significantDigitsDbg(0.9999999999, 4, true) == 1000.0);
    //assert(significantDigitsDbg(0.9999999999, 5, true) == 10000.0);
    //assert(significantDigitsDbg(0.9999999999, 6, true) == 100000.0);
}

fn significantDigits(v: f32, digits: usize) f32 {
    return significantDigitsDbg(v, digits, false);
}

pub fn approxEqDbg(l: f32, r: f32, digits: usize, comptime dbg: bool) bool {
    var result = true;
    if (dbg) warn("apporxEq: l={} r={}", l, r);
    defer { if (dbg) warn(" result={}\n", result); }
    if (digits == 0) {
        if (dbg) warn(" digits0");
        return result;
    }
    if (l == r) {
        if (dbg) warn(" identical");
        return result;
    }
    if (math.isNan(l) and math.isNan(r)) {
        if (dbg) warn(" isNan");
        return result;
    }
    if (math.isPositiveInf(l) and math.isPositiveInf(r)) {
        if (dbg) warn(" IsPosInf");
        return result;
    }
    if (math.isNegativeInf(l) and math.isNegativeInf(r)) {
        if (dbg) warn(" IsNegInf");
        return result;
    }
    if (dbg) warn("\n");
    var l_sig = significantDigitsDbg(l, digits, dbg);
    var r_sig = significantDigitsDbg(r, digits, dbg);
    var diff = math.fabs(r_sig - l_sig);
    result = diff == 0;
    if (dbg) warn(" l_sig={} r_sig={} diff={}", l_sig, r_sig, diff);
    return result;
}

pub fn approxEq(l: f32, r: f32, digits: usize) bool {
    var result: bool = approxEqDbg(l, r, digits, false);
    return if (result) result else approxEqDbg(l, r, digits, true);
}

pub fn assert_f_eq(left: f32, right: f32) void {
    assert(approxEq(left, right, 5));
}

test "significantDigits" {
    warn("\n");
    //assert(significantDigitsDbg(0.9999999999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.999999999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.99999999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.9999999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.999999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.99999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.9999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.99, 1, true) == 1.0);
    assert(significantDigitsDbg(0.9, 1, true) == 1.0);
    assert(significantDigitsDbg(-0.9, 1, true) == -1.0);
    //assert(significantDigitsDbg(0.9999999999, 1, true) == 1.0);
    //assert(significantDigitsDbg(0.9999999999, 2, true) == 10.0);
    //assert(significantDigitsDbg(0.9999999999, 3, true) == 100.0);
    //assert(significantDigitsDbg(0.9999999999, 4, true) == 1000.0);
    //assert(significantDigitsDbg(0.9999999999, 5, true) == 10000.0);
    //assert(significantDigitsDbg(0.9999999999, 6, true) == 100000.0);
    //assert(significantDigits(1.0, 0) == 0.0);
    //assert(significantDigits(1.0, 0) == 0.0);
    //assert(significantDigits(9999e100, 0) == 0.0);
    //assert(significantDigits(0.0, 1) == 0.0);
    //assert(significantDigits(0.0, 6) == 0.0);
    //assert(significantDigits(0.1, 1) == 1.0);
    //assert(significantDigits(0.12, 1) == 1.0);
    //assert(significantDigits(0.14, 1) == 1.0);
    //assert(significantDigits(0.15, 1) == 2.0);
    //assert(significantDigits(-0.1, 1) == -1.0);
    //assert(significantDigits(1.0, 1) == 1.0);
    //assert(significantDigits(-1.0, 1) == -1.0);
    //assert(significantDigits(1.4, 1) == 1.0);
    //assert(significantDigits(1.5, 1) == 2.0);
    //assert(significantDigits(1.9, 1) == 2.0);
    //assert(significantDigits(9.0, 1) == 9);
    //assert(significantDigits(9.5, 2) == 95);
    //assert(significantDigits(9.95, 2) == 100);
    //assert(significantDigits(1.0, 3) == 100);
    //assert(significantDigits(9.95, 3) == 995);
    //assert(significantDigits(10.1, 2) == 10.0);
    //assert(significantDigits(123.0e12, 3) == 123);
    //assert(significantDigits(123.4e12, 3) == 123);
    //assert(significantDigits(123.5e14, 3) == 124);
    //assert(significantDigits(123.5e15, 3) == 123); // WTF:??
    //assert(significantDigits(123.5e16, 3) == 124);
    //assert(significantDigits(123.6e15, 3) == 124);

    //assert(math.isNan(significantDigits(math.nan(f32), 1)));
    //assert(math.isPositiveInf(significantDigits(math.inf(f32), 2)));
    //assert(math.isNegativeInf(significantDigits(-math.inf(f32), 2)));
    //assert(significantDigits(1.0e1, 1) == 1.0);
    //assert(significantDigits(-1.0e-1, 1) == -1.0);
    //assert(significantDigits(1.1e2, 2) == 11.0);
    //assert(significantDigits(10001, 5) == 10001);
    //assert(significantDigits(9999, 5) == 99990);
    //assert(significantDigits(9999, 4) == 9999);
}

test "approxEq" {
    warn("\n");
    assert(approxEq(1.0, 2.0, 0)); // If digits 0 then always true
    assert(approxEq(-0.12, 0.12, 0)); // ?? Maybe 0 digits should mean sign is compared only and this should fail?
    assert(approxEq(math.nan(f32), math.nan(f32), 1));
    assert(approxEq(math.inf(f32), math.inf(f32), 1));
    assert(approxEq(-math.inf(f32), -math.inf(f32), 1));
    assert(!approxEq(math.inf(f32), -math.inf(f32), 1));
    assert(approxEq(0.0, 0.0, 1));
    assert(approxEq(0.0, 0.0, 1000));
    assert(approxEq(10, 10, 1));
    assert(approxEq(10, 11, 1));
    assert(approxEq(10, 12, 1));
    assert(approxEq(10, 13, 1));
    assert(approxEq(10, 14, 1));
    assert(!approxEq(10, 15, 1));
    assert(!approxEq(10, 16, 1));
    assert(!approxEq(10, 17, 1));
    assert(!approxEq(10, 19, 1));

    assert(approxEq(0.12, 0.13, 1));
    assert(approxEq(1.1, 1.2, 1));
    assert(approxEq(1.1, 1.4, 1));
    assert(!approxEq(1.1, 1.5, 1));
    assert(approxEq(1.01, 1.02, 2));
    assert(approxEq(1.01, 1.04, 2));
    assert(!approxEq(1.01, 1.05, 2));

    assert(!approxEq(-0.12, 0.12, 1));
    assert(!approxEq(-0.12, 0.12, 2));

    assert(approxEq(-0.12, -0.13, 1));
    assert(approxEq(-0.13, -0.12, 1));
    assert(!approxEq(-0.12, -0.13, 2));
    assert(approxEq(-0.22, -0.222, 2));
    assert(approxEq(-0.222, -0.22, 2));
    assert(approxEq(-0.222, -0.2224, 3));
    assert(approxEq(-0.2224, -0.222, 3));
    assert(!approxEq(-0.222, -0.2225, 3));
    assert(!approxEq(-0.2225, -0.222, 3));

    assert(approxEq(123.0e12, 123.1e12, 3));
}

test "assert_f_eq" {
    warn("\n");
    var v1: f32 = 10.1234;
    var v2: f32 = 10.1235;
    var digits: usize = 1;
    while (digits <= 6) : (digits += 1) {
        if (digits < 5) {
            assert(approxEq(v1, v2, digits));
        } else {
            assert(!approxEq(v1, v2, digits));
        }
        warn("approxEq({}, {}, {})={}\n", v1, v2, digits, approxEq(v1, v2, digits));
    }
}

