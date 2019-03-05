const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const math = std.math;

const Allocator = std.mem.Allocator;

const geo = @import("modules/zig-geometry/index.zig");
const gl = @import("modules/zig-sdl2/src/index.zig");
const ColorU8 = @import("../src/color.zig").ColorU8;

const DBG = false;

pub const Texture = struct {
    const Self = @This();

    pAllocator: *Allocator,
    pub width: usize,
    pub height: usize,
    pub pixels: ?[]ColorU8,
    pub pixels_owned: bool,

    pub fn init(pAllocator: *Allocator) Self {
        return Self{
            .pAllocator = pAllocator,
            .width = 0,
            .height = 0,
            .pixels = null,
            .pixels_owned = false,
        };
    }

    pub fn initPixels(pAllocator: *Allocator, width: usize, height: usize, color: ColorU8) anyerror!Self {
        var count: usize = width * height;
        var pixels = try pAllocator.alloc(ColorU8, count);
        var i: usize = 0;
        while (i < count) : (i += 1) {
            pixels[i] = color;
        }
        return Self{
            .pAllocator = pAllocator,
            .width = width,
            .height = height,
            .pixels = pixels,
            .pixels_owned = true,
        };
    }

    pub fn deinit(pSelf: *Self) void {
        if ((pSelf.pixels_owned) and (pSelf.pixels != null)) {
            pSelf.pAllocator.free(pSelf.pixels.?);
        }
    }

    pub fn loadFile(pSelf: *Self, filename: []const u8) anyerror!void {
        var cfilename = try std.cstr.addNullByte(pSelf.pAllocator, filename);
        defer pSelf.pAllocator.free(cfilename);

        var surface = gl.IMG_Load(cfilename.ptr) orelse return error.UnableToLoadImage;
        defer gl.SDL_FreeSurface(surface);

        pSelf.width = @intCast(usize, surface.w);
        pSelf.height = @intCast(usize, surface.h);

        var bpp: usize = @intCast(usize, surface.format.BytesPerPixel);
        switch (bpp) {
            1, 2, 3, 4 => {},
            else => return error.UnsupportedBytesPerPixel,
        }
        var pitch: usize = @intCast(usize, surface.pitch);
        var count: usize = pSelf.width * pSelf.height * bpp;
        var pPixels: []const u8 = if (surface.pixels) |p| @ptrCast([*]u8, p)[0..count] else return error.NoPixels;

        pSelf.pixels = try pSelf.pAllocator.alloc(ColorU8, count);
        pSelf.pixels_owned = true;
        var y: usize = 0;
        var line_offset: usize = 0;
        var dest_offset: usize = 0;
        while (y < pSelf.height) : (y += 1) {
            // Looping through the lines of pixels
            var pLine: []const u8 = pPixels[line_offset..];
            var x: usize = 0;
            var src_offset: usize = 0;
            while (x < pSelf.width) : (x += 1) {
                // Loopting through the pixels on a line

                // Create a slice of this pixels bytes
                var pPixel: []const u8 = pLine[src_offset..(src_offset + bpp)];
                src_offset += bpp;

                // Extract the bytes into a u32
                var raw_pixel: u32 = switch (bpp) {
                    1 => @intCast(u32, pPixel[0]),
                    2 => @intCast(u32, pPixel[0]) << 0 | @intCast(u32, pPixel[1]) << 8,
                    3 => @intCast(u32, pPixel[0]) << 0 | @intCast(u32, pPixel[1]) << 8 | @intCast(u32, pPixel[2]) << 16,
                    4 => @intCast(u32, pPixel[0]) << 0 | @intCast(u32, pPixel[1]) << 8 | @intCast(u32, pPixel[2]) << 16 | @intCast(u32, pPixel[3]) << 24,
                    else => unreachable,
                };

                // Extract the components from the raw_pixel
                var a: u8 = undefined;
                var r: u8 = undefined;
                var g: u8 = undefined;
                var b: u8 = undefined;
                gl.SDL_GetRGBA(raw_pixel, surface.format, &r, &g, &b, &a);

                // Store in texture pixels slice
                pSelf.pixels.?[dest_offset] = ColorU8.init(a, r, g, b);
                dest_offset += 1;
            }
            line_offset += pitch;
        }
    }

    pub fn map(pSelf: *const Self, tu: f32, tv: f32, defaultColor: ColorU8) ColorU8 {
        if (pSelf.pixels) |pPixels| {
            var u = @floatToInt(usize, tu * @intToFloat(f32, pSelf.width)) % pSelf.width;
            var v = @floatToInt(usize, tv * @intToFloat(f32, pSelf.height)) % pSelf.height;

            var c = pPixels[(v * pSelf.width) + u];
            if (DBG) warn("map: tu={.3} tv={.3} u={} v={} c={}... ", tu, tv, u, v, &c);

            return c;
        } else {
            return defaultColor;
        }
    }
};

test "texture.empty" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var texture = Texture.init(pAllocator);
    defer texture.deinit();
}

test "texture.known.TODO" {
    // TODO: Add a test with known contents so we truly validate
}

test "texture.initPixels" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    // Create and Initialize text.pixels
    var texture = try Texture.initPixels(pAllocator, 1024, 512, ColorU8.Black);
    defer texture.deinit();

    assert(texture.width == 1024);
    assert(texture.height == 512);
    assert(texture.pixels.?[0].r == ColorU8.Black.r);
    assert(texture.pixels.?[0].g == ColorU8.Black.g);
    assert(texture.pixels.?[0].b == ColorU8.Black.b);
}

test "texture.loadFile.bricks2" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var texture = Texture.init(pAllocator);
    defer texture.deinit();
    try texture.loadFile("src/modules/3d-test-resources/bricks2.jpg");

    assert(texture.pixels != null);

    // We "know" the first pixel isn't 0
    assert(texture.pixels.?[0].asU32Argb() != 0);
}
