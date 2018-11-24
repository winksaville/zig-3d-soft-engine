const builtin = @import("builtin");
const std = @import("std");
const time = std.os.time;
const mem = std.mem;
const math = std.math;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const warn = std.debug.warn;
const gl = @import("../modules/zig-sdl2/src/index.zig");

const geo = @import("../modules/zig-geometry/index.zig");

const parseJsonFile = @import("parse_json_file.zig").parseJsonFile;

const Camera = @import("camera.zig").Camera;
const Mesh = @import("mesh.zig").Mesh;
const Face = @import("mesh.zig").Face;
const ie = @import("input_events.zig");

const DBG = false;
const DBG1 = false;
const DBG2 = false;
const DBG3 = false;

const DBG_RenderPoints = true;

pub const Window = struct {
    const Self = @This();

    pAllocator: *Allocator,
    width: usize,
    widthci: c_int,
    widthf: f32,
    height: usize,
    heightci: c_int,
    heightf: f32,
    name: []const u8,
    bg_color: u32,
    pixels: []u32,
    sdl_window: *gl.SDL_Window,
    sdl_renderer: *gl.SDL_Renderer,
    sdl_texture: *gl.SDL_Texture,

    pub fn init(pAllocator: *Allocator, width: usize, height: usize, name: []const u8) !Self {
        var self = Self{
            .pAllocator = pAllocator,
            .bg_color = undefined,
            .width = width,
            .widthci = @intCast(c_int, width),
            .widthf = @intToFloat(f32, width),
            .height = height,
            .heightci = @intCast(c_int, height),
            .heightf = @intToFloat(f32, height),
            .name = name,
            .pixels = try pAllocator.alloc(u32, width * height),
            .sdl_window = undefined,
            .sdl_renderer = undefined,
            .sdl_texture = undefined,
        };

        self.setBgColor(0); //xffffffff);

        // Initialize SDL
        if (gl.SDL_Init(gl.SDL_INIT_VIDEO | gl.SDL_INIT_AUDIO) != 0) {
            return error.FailedSdlInitialization;
        }
        errdefer gl.SDL_Quit();

        // Create Window
        const x_pos: c_int = gl.SDL_WINDOWPOS_UNDEFINED;
        const y_pos: c_int = gl.SDL_WINDOWPOS_UNDEFINED;
        var window_flags: u32 = 0;
        self.sdl_window = gl.SDL_CreateWindow(c"zig-3d-soft-engine", x_pos, y_pos, self.widthci, self.heightci, window_flags) orelse {
            return error.FailedSdlWindowInitialization;
        };
        errdefer gl.SDL_DestroyWindow(self.sdl_window);

        // This reduces CPU utilization but now dragging window is jerky
        {
            var r = gl.SDL_GL_SetSwapInterval(1);
            if (r != 0) {
                var b = gl.SDL_SetHint(gl.SDL_HINT_RENDER_VSYNC, c"1");
                if (b != gl.SDL_bool.SDL_TRUE) {
                    warn("No VSYNC cpu utilization may be high!\n");
                }
            }
        }

        // Create Renderer
        var renderer_flags: u32 = 0;
        self.sdl_renderer = gl.SDL_CreateRenderer(self.sdl_window, -1, renderer_flags) orelse {
            return error.FailedSdlRendererInitialization;
        };
        errdefer gl.SDL_DestroyRenderer(self.sdl_renderer);

        // Create Texture
        self.sdl_texture = gl.SDL_CreateTexture(self.sdl_renderer, gl.SDL_PIXELFORMAT_ARGB8888, gl.SDL_TEXTUREACCESS_STATIC, self.widthci, self.heightci) orelse {
            return error.FailedSdlTextureInitialization;
        };
        errdefer gl.SDL_DestroyTexture(self.sdl_texture);

        self.clear();

        return self;
    }

    pub fn deinit(pSelf: *Self) void {
        gl.SDL_DestroyTexture(pSelf.sdl_texture);
        gl.SDL_DestroyRenderer(pSelf.sdl_renderer);
        gl.SDL_DestroyWindow(pSelf.sdl_window);
        gl.SDL_Quit();
    }

    pub fn setBgColor(pSelf: *Self, color: u32) void {
        pSelf.bg_color = color;
    }

    pub fn clear(pSelf: *Self) void {
        // Init Pixel buffer
        for (pSelf.pixels) |*pixel| {
            pixel.* = pSelf.bg_color;
        }
    }

    pub fn putPixel(pSelf: *Self, x: usize, y: usize, color: u32) void {
        if (DBG3) warn("putPixel: x={} y={} c={x}\n", x, y, color);
        pSelf.pixels[(y * pSelf.width) + x] = color;
    }

    pub fn getPixel(pSelf: *Self, x: usize, y: usize) u32 {
        return pSelf.pixels[(y * pSelf.width) + x];
    }

    pub fn present(pSelf: *Self) void {
        _ = gl.SDL_UpdateTexture(pSelf.sdl_texture, null, @ptrCast(*const c_void, &pSelf.pixels[0]), pSelf.widthci * @sizeOf(@typeOf(pSelf.pixels[0])));
        _ = gl.SDL_RenderClear(pSelf.sdl_renderer);
        _ = gl.SDL_RenderCopy(pSelf.sdl_renderer, pSelf.sdl_texture, null, null);
        _ = gl.SDL_RenderPresent(pSelf.sdl_renderer);
    }

    /// Project takes a 3D coord and converts it to a 2D point
    /// using the transform matrix.
    pub fn projectRetV2f32(pSelf: *Self, coord: geo.V3f32, transMat: *const geo.M44f32) geo.V2f32 {
        if (DBG1) warn("projectRetV2f32:    original coord={} widthf={.3} heightf={.3}\n", &coord, pSelf.widthf, pSelf.heightf);
        return geo.projectToScreenCoord(pSelf.widthf, pSelf.heightf, coord, transMat);
    }

    /// Draw a Vec2 point in screen coordinates clipping it if its outside the screen
    pub fn drawPointV2f32(pSelf: *Self, point: geo.V2f32, color: u32) void {
        pSelf.drawPointXy(@floatToInt(isize, point.x()), @floatToInt(isize, point.y()), color);
    }

    /// Draw a point defined by x, y in screen coordinates clipping it if its outside the screen
    pub fn drawPointXy(pSelf: *Self, x: isize, y: isize, color: u32) void {
        //if (DBG) warn("drawPointXy: x={.3} y={.3} c={x}\n", x, y, color);
        if ((x >= 0) and (y >= 0)) {
            var ux = @bitCast(usize, x);
            var uy = @bitCast(usize, y);
            if ((ux < pSelf.width) and (uy < pSelf.height)) {
                //if (DBG) warn("drawPointXy: putting x={} y={} c={x}\n", ux, uy, color);
                pSelf.putPixel(ux, uy, color);
            }
        }
    }

    /// Draw a line point0 and 1 are in screen coordinates
    pub fn drawLine(pSelf: *Self, point0: geo.V2f32, point1: geo.V2f32, color: u32) void {
        var diff = point1.sub(&point0);
        var dist = diff.length();
        //if (DBG) warn("drawLine: diff={} dist={}\n", diff, dist);
        if (dist < 2)
            return;

        var diff_half = diff.scale(0.5);
        var mid_point = point0.add(&diff_half);
        //if (DBG) warn("drawLe: diff_half={} mid_point={}\n", diff_half, mid_point);
        pSelf.drawPointV2f32(mid_point, color);

        pSelf.drawLine(point0, mid_point, color);
        pSelf.drawLine(mid_point, point1, color);
    }

    /// Draw a line point0 and 1 are in screen coordinates using Bresnham algorithm
    pub fn drawBline(pSelf: *Self, point0: geo.V2f32, point1: geo.V2f32, color: u32) void {
        //@setRuntimeSafety(false);
        var x0 = @floatToInt(isize, point0.x());
        var y0 = @floatToInt(isize, point0.y());
        var x1 = @floatToInt(isize, point1.x());
        var y1 = @floatToInt(isize, point1.y());

        var dx: isize = math.absInt(x1 - x0) catch unreachable;
        var dy: isize = math.absInt(y1 - y0) catch unreachable;
        var sx: isize = if (x0 < x1) isize(1) else isize(-1);
        var sy: isize = if (y0 < y1) isize(1) else isize(-1);
        var err: isize = dx - dy;

        while (true) {
            pSelf.drawPointXy(x0, y0, color);
            if ((x0 == x1) and (y0 == y1)) break;
            var e2: isize = 2 * err;
            if (e2 > -dy) {
                err -= dy;
                x0 += sx;
            } else {
                err += dx;
                y0 += sy;
            }
        }
    }

    /// Project takes a 3D coord and converts it to a 2D point
    /// using the transform matrix.
    pub fn projectRetV3f32(pSelf: *Self, coord: geo.V3f32, transMat: *const geo.M44f32) geo.V3f32 {
        if (DBG1) warn("projectRetV3f32:    original coord={} widthf={.3} heightf={.3}\n", &coord, pSelf.widthf, pSelf.heightf);
        var point = coord.transform(transMat);

        var x = (point.x() * pSelf.widthf) + (pSelf.widthf / 2.0);
        var y = (-point.y() * pSelf.heightf) + (pSelf.heightf / 2.0);

        return geo.V3f32.init(x, y, point.z());
    }

    /// Draw a Vec2 point in screen coordinates clipping it if its outside the screen
    pub fn drawPointV3f32(pSelf: *Self, point: geo.V3f32, color: u32) void {
        pSelf.drawPointXy(@floatToInt(isize, point.x()), @floatToInt(isize, point.y()), color);
    }

    /// Render the meshes into the window from the camera's point of view
    pub fn render(pSelf: *Self, camera: *const Camera, meshes: []const Mesh) void {
        var view_matrix = geo.lookAtLh(&camera.position, &camera.target, &geo.V3f32.unitY());
        if (DBG) warn("view_matrix:\n{}", &view_matrix);

        var fov: f32 = 90;
        var znear: f32 = 0.01;
        var zfar: f32 = 1.0;
        var perspective_matrix = geo.perspectiveM44(f32, fov, pSelf.widthf / pSelf.heightf, znear, zfar);
        if (DBG) warn("\nperspective_matrix: fov={.3}, znear={.3} zfar={.3}\n{}", fov, znear, zfar, &perspective_matrix);

        for (meshes) |mesh| {
            var rotation_matrix = geo.rotationYawPitchRollV3f32(mesh.rotation);
            var translation_matrix = geo.translationV3f32(mesh.position);
            var world_matrix = geo.mulM44f32(&translation_matrix, &rotation_matrix);
            if (DBG) warn("\nworld_matrix:\n{}", &world_matrix);

            var world_to_view_matrix = geo.mulM44f32(&world_matrix, &view_matrix);
            var transform_matrix = geo.mulM44f32(&world_to_view_matrix, &perspective_matrix);
            if (DBG) warn("\ntransform_matrix:\n{}", &transform_matrix);

            for (mesh.faces) |face| {
                const va = mesh.vertices[face.a];
                const vb = mesh.vertices[face.b];
                const vc = mesh.vertices[face.c];
                if (DBG3) warn("\nva={} vb={} vc={}\n", va, vb, vc);

                const pa = pSelf.projectRetV2f32(va, &transform_matrix);
                const pb = pSelf.projectRetV2f32(vb, &transform_matrix);
                const pc = pSelf.projectRetV2f32(vc, &transform_matrix);
                if (DBG3) warn("pa={} pb={} pc={}\n", pa, pb, pc);
                const color = 0xffff00ff;

                if (DBG_RenderPoints) {
                    pSelf.drawPointV2f32(pa, color);
                    pSelf.drawPointV2f32(pb, color);
                    pSelf.drawPointV2f32(pc, color);
                } else {
                    pSelf.drawBline(pa, pb, color);
                    pSelf.drawBline(pb, pc, color);
                    pSelf.drawBline(pc, pa, color);
                }
            }
        }
    }
};

// Test

test "window" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 640, 480, "testWindow");
    defer window.deinit();

    assert(window.width == 640);
    assert(window.widthci == 640);
    assert(window.widthf == f32(640));
    assert(window.height == 480);
    assert(window.heightci == 480);
    assert(window.heightf == f32(480));
    assert(mem.eql(u8, window.name, "testWindow"));
    window.putPixel(0, 0, 0x01020304);
    assert(window.getPixel(0, 0) == 0x01020304);
}

test "window.projectRetV2f32" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 640, 480, "testWindow");
    defer window.deinit();

    var v1 = geo.V3f32.init(0, 0, 0);
    var r = window.projectRetV2f32(v1, &geo.m44f32_unit);
    assert(r.x() == window.widthf / 2.0);
    assert(r.y() == window.heightf / 2.0);

    v1 = geo.V3f32.init(-1.0, 1.0, 0);
    r = window.projectRetV2f32(v1, &geo.m44f32_unit);
    assert(r.x() == 0);
    assert(r.y() == 0);

    v1 = geo.V3f32.init(1.0, -1.0, 0);
    r = window.projectRetV2f32(v1, &geo.m44f32_unit);
    assert(r.x() == window.widthf);
    assert(r.y() == window.heightf);

    v1 = geo.V3f32.init(-1.0, -1.0, 0);
    r = window.projectRetV2f32(v1, &geo.m44f32_unit);
    assert(r.x() == 0);
    assert(r.y() == window.heightf);

    v1 = geo.V3f32.init(1.0, 1.0, 0);
    r = window.projectRetV2f32(v1, &geo.m44f32_unit);
    assert(r.x() == window.widthf);
    assert(r.y() == 0);
}

test "window.drawPointV2f32" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 640, 480, "testWindow");
    defer window.deinit();

    var p1 = geo.V2f32.init(0, 0);
    window.drawPointV2f32(p1, 0x80808080);
    assert(window.getPixel(0, 0) == 0x80808080);

    p1 = geo.V2f32.init(window.widthf / 2, window.heightf / 2);
    window.drawPointV2f32(p1, 0x80808080);
    assert(window.getPixel(window.width / 2, window.height / 2) == 0x80808080);
}

test "window.projectRetV3f32" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 640, 480, "testWindow");
    defer window.deinit();

    var v1 = geo.V3f32.init(0, 0, 0);
    var r = window.projectRetV3f32(v1, &geo.m44f32_unit);
    assert(r.x() == window.widthf / 2.0);
    assert(r.y() == window.heightf / 2.0);

    v1 = geo.V3f32.init(-0.5, 0.5, 0);
    r = window.projectRetV3f32(v1, &geo.m44f32_unit);
    assert(r.x() == 0);
    assert(r.y() == 0);

    v1 = geo.V3f32.init(0.5, -0.5, 0);
    r = window.projectRetV3f32(v1, &geo.m44f32_unit);
    assert(r.x() == window.widthf);
    assert(r.y() == window.heightf);

    v1 = geo.V3f32.init(-0.5, -0.5, 0);
    r = window.projectRetV3f32(v1, &geo.m44f32_unit);
    assert(r.x() == 0);
    assert(r.y() == window.heightf);

    v1 = geo.V3f32.init(0.5, 0.5, 0);
    r = window.projectRetV3f32(v1, &geo.m44f32_unit);
    assert(r.x() == window.widthf);
    assert(r.y() == 0);
}

test "window.drawPointV3f32" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 640, 480, "testWindow");
    defer window.deinit();

    var p1 = geo.V3f32.init(0, 0, 0);
    window.drawPointV3f32(p1, 0x80808080);
    assert(window.getPixel(0, 0) == 0x80808080);

    p1 = geo.V3f32.init(window.widthf / 2, window.heightf / 2, 0);
    window.drawPointV3f32(p1, 0x80808080);
    assert(window.getPixel(window.width / 2, window.height / 2) == 0x80808080);
}

test "window.drawLine" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 640, 480, "testWindow");
    defer window.deinit();

    var point1 = geo.V2f32.init(1, 1);
    var point2 = geo.V2f32.init(4, 4);
    window.drawLine(point1, point2, 0x80808080);
    assert(window.getPixel(1, 1) == 0x80808080);
    assert(window.getPixel(2, 2) == 0x80808080);
    assert(window.getPixel(3, 3) == 0x80808080);
}

test "window.render.cube" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 640, 480, "testWindow");
    defer window.deinit();

    var mesh: Mesh = undefined;

    // Unit cube about 0,0,0
    mesh = try Mesh.init(pAllocator, "mesh1", 8, 12);

    // Unit cube about 0,0,0
    mesh.vertices[0] = geo.V3f32.init(-1, 1, 1);
    mesh.vertices[1] = geo.V3f32.init(1, 1, 1);
    mesh.vertices[2] = geo.V3f32.init(-1, -1, 1);
    mesh.vertices[3] = geo.V3f32.init(1, -1, 1);

    mesh.vertices[4] = geo.V3f32.init(-1, 1, -1);
    mesh.vertices[5] = geo.V3f32.init(1, 1, -1);
    mesh.vertices[6] = geo.V3f32.init(1, -1, -1);
    mesh.vertices[7] = geo.V3f32.init(-1, -1, -1);

    // 12 faces
    mesh.faces[0] = Face { .a=0, .b=1, .c=2, };
    mesh.faces[1] = Face { .a=1, .b=2, .c=3, };
    mesh.faces[2] = Face { .a=1, .b=3, .c=6, };
    mesh.faces[3] = Face { .a=1, .b=5, .c=6, };
    mesh.faces[4] = Face { .a=0, .b=1, .c=4, };
    mesh.faces[5] = Face { .a=1, .b=4, .c=5, };

    mesh.faces[6] = Face { .a=2, .b=3, .c=7, };
    mesh.faces[7] = Face { .a=3, .b=6, .c=7, };
    mesh.faces[8] = Face { .a=0, .b=2, .c=7, };
    mesh.faces[9] = Face { .a=0, .b=4, .c=7, };
    mesh.faces[10] = Face { .a=4, .b=5, .c=6, };
    mesh.faces[11] = Face { .a=4, .b=6, .c=7, };

    var meshes = []Mesh{mesh};

    var movement = geo.V3f32.init(0.01, 0.01, 0); // Small amount of movement

    var camera_position = geo.V3f32.init(0, 0, 3);
    var camera_target = geo.V3f32.initVal(0);
    var camera = Camera.init(camera_position, camera_target);

    // Loop until end_time is reached but always loop once :)
    var ms_factor: u64 = time.ns_per_s / time.ms_per_s;
    var timer = try time.Timer.start();
    var end_time: u64 = if (DBG or DBG1 or DBG2) (5000 * ms_factor) else (100 * ms_factor);
    while (true) {
        window.clear();

        if (DBG1) warn("rotation={.5}:{.5}:{.5}\n", meshes[0].rotation.x(), meshes[0].rotation.y(), meshes[0].rotation.z());
        window.render(&camera, &meshes);

        var center = geo.V2f32.init(window.widthf / 2, window.heightf / 2);
        window.drawPointV2f32(center, 0xffffffff);

        window.present();

        meshes[0].rotation = meshes[0].rotation.add(&movement);

        if (timer.read() > end_time) break;
    }
}

test "window.world.to.screen" {
    if (DBG) warn("\n");
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    const T = f32;
    const widthf: T = 512;
    const heightf: T = 512;
    const width: u32 = @floatToInt(u32, widthf);
    const height: u32 = @floatToInt(u32, heightf);
    const fov: T = 90;
    const aspect: T = widthf / heightf;
    const znear: T = 0.01;
    const zfar: T = 1.0;

    var window = try Window.init(pAllocator, width, height, "testWindow");
    defer window.deinit();

    var camera_to_perspective_matrix = geo.perspectiveM44(f32, fov, aspect, znear, zfar);

    var world_to_camera_matrix = geo.m44f32_unit;
    world_to_camera_matrix.data[3][2] = 2;

    var world_vertexs = []geo.V3f32{
        geo.V3f32.init(0, 1.0, 0),
        geo.V3f32.init(0, -1.0, 0),
        geo.V3f32.init(0, 1.0, 0.2),
        geo.V3f32.init(0, -1.0, -0.2),
    };
    var expected_camera_vertexs = []geo.V3f32{
        geo.V3f32.init(0, 1.0, 2),
        geo.V3f32.init(0, -1.0, 2.0),
        geo.V3f32.init(0, 1.0, 2.2),
        geo.V3f32.init(0, -1.0, 1.8),
    };
    var expected_projected_vertexs = []geo.V3f32{
        geo.V3f32.init(0, 0.5, -1.0151515),
        geo.V3f32.init(0, -0.5, -1.0151515),
        geo.V3f32.init(0, 0.4545454, -1.0146923),
        geo.V3f32.init(0, -0.5555555, -1.0157126),
    };
    var expected_screen_vertexs = [][2]u32{
        []u32{ 256, 128 },
        []u32{ 256, 384 },
        []u32{ 256, 139 },
        []u32{ 256, 398 },
    };

    // Loop until end_time is reached but always loop once :)
    var msf: u64 = time.ns_per_s / time.ms_per_s;
    var timer = try time.Timer.start();
    var end_time: u64 = 0;
    if (DBG or DBG1 or DBG2 or DBG3) end_time += (2000 * msf);
    while (true) {
        window.clear();

        for (world_vertexs) |world_vert, i| {
            if (DBG) warn("world_vert[{}]  = {}\n", i, &world_vert);

            var camera_vert = world_vert.transform(&world_to_camera_matrix);
            if (DBG) warn("camera_vert    = {}\n", camera_vert);
            assert(camera_vert.approxEql(&expected_camera_vertexs[i], 6));

            var projected_vert = camera_vert.transform(&camera_to_perspective_matrix);
            if (DBG) warn("projected_vert = {}\n", projected_vert);
            assert(projected_vert.approxEql(&expected_projected_vertexs[i], 6));

            var point = window.projectRetV2f32(projected_vert, &geo.m44f32_unit);
            window.drawPointV2f32(point, 0xffff00ff);
            assert(window.getPixel(expected_screen_vertexs[i][0], expected_screen_vertexs[i][1]) == 0xffff00ff);
        }

        var center = geo.V2f32.init(window.widthf / 2, window.heightf / 2);
        window.drawPointV2f32(center, 0xffffffff);

        window.present();

        if (timer.read() > end_time) break;
    }
}

test "window.keyctrl.triangle" {
    if (DBG) {
        var direct_allocator = std.heap.DirectAllocator.init();
        var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
        defer arena_allocator.deinit();
        var pAllocator = &arena_allocator.allocator;

        var window = try Window.init(pAllocator, 512, 512, "testWindow");
        defer window.deinit();

        // Black background color
        window.setBgColor(0);

        var mesh: Mesh = undefined;

        // Triangle
        mesh = try Mesh.init(pAllocator, "mesh1", 3, 1);
        mesh.vertices[0] = geo.V3f32.init(0, 1, 0);
        mesh.vertices[1] = geo.V3f32.init(0.5, -0.5, 0);
        mesh.vertices[2] = geo.V3f32.init(-1, -1, 0);
        mesh.faces[0] = Face { .a=0, .b=1, .c=2 };

        var meshes = []Mesh{mesh};

        keyCtrlMeshes(&window, &meshes);
    }
}

test "window.keyctrl.suzanne" {
    if (DBG) {
        var direct_allocator = std.heap.DirectAllocator.init();
        var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
        defer arena_allocator.deinit();
        var pAllocator = &arena_allocator.allocator;

        var window = try Window.init(pAllocator, 512, 512, "testWindow");
        defer window.deinit();

        // Black background color
        window.setBgColor(0);

        var file_name = "3d-objects/suzanne.babylon";
        var tree = try parseJsonFile(pAllocator, file_name);
        defer tree.deinit();

        var mesh = try Mesh.initJson(pAllocator, "suzanne", tree);
        assert(std.mem.eql(u8, mesh.name, "suzanne"));
        assert(mesh.vertices.len == 507);
        assert(mesh.faces.len == 968);

        var meshes = []Mesh{mesh};
        keyCtrlMeshes(&window, &meshes);
    }
}

const KeyState = struct {
    new_key: bool,
    code: gl.SDL_Keycode,
    mod: u16,
    ei: ie.EventInterface,
};

fn rotate(mod: u16, pos: geo.V3f32, val: f32) geo.V3f32 {
    var r = geo.rad(val);
    if (DBG) warn("rotate: mod={x} pos={} rad(val)={}\n", mod, pos, r);
    var new_pos = pos;
    if ((mod & gl.KMOD_LCTRL) != 0) {
        new_pos = new_pos.add(&geo.V3f32.init(r, 0, 0));
        if (DBG) warn("rotate: add X\n");
    }
    if ((mod & gl.KMOD_LSHIFT) != 0) {
        new_pos = new_pos.add(&geo.V3f32.init(0, r, 0));
        if (DBG) warn("rotate: add Y\n");
    }
    if ((mod & gl.KMOD_RCTRL) != 0) {
        new_pos = new_pos.add(&geo.V3f32.init(0, 0, r));
        if (DBG) warn("rotate: add Z\n");
    }
    if (DBG and !pos.approxEql(&new_pos, 4)) {
        warn("rotate: new_pos={}\n", new_pos);
    }
    return new_pos;
}

fn translate(mod: u16, pos: geo.V3f32, val: f32) geo.V3f32 {
    if (DBG) warn("translate: pos={}\n", pos);
    var new_pos = pos;
    if ((mod & gl.KMOD_LCTRL) != 0) {
        new_pos = pos.add(&geo.V3f32.init(val, 0, 0));
        if (DBG) warn("translate: add X\n");
    }
    if ((mod & gl.KMOD_LSHIFT) != 0) {
        new_pos = pos.add(&geo.V3f32.init(0, val, 0));
        if (DBG) warn("translate: add Y\n");
    }
    if ((mod & gl.KMOD_LALT) != 0) {
        new_pos = pos.add(&geo.V3f32.init(0, 0, val));
        if (DBG) warn("translate: add Z\n");
    }
    if (DBG and !pos.eql(&new_pos)) {
        warn("translate: new_pos={}\n", new_pos);
    }
    return new_pos;
}

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

fn keyCtrlMeshes(pWindow: *Window, meshes: [] Mesh) void {
    var camera_position = geo.V3f32.init(0, 0, 3);
    var camera_target = geo.V3f32.initVal(0);
    var camera = Camera.init(camera_position, camera_target);

    var ks = KeyState{
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

    done: while (true) {
        // Update the display
        pWindow.clear();

        if (DBG or DBG1 or DBG2) warn("\n");

        if (DBG1) warn("camera={}\n", &camera.position);
        if (DBG1) warn("rotation={}\n", meshes[0].rotation);
        pWindow.render(&camera, meshes);

        var center = geo.V2f32.init(pWindow.widthf / 2, pWindow.heightf / 2);
        pWindow.drawPointV2f32(center, 0xffffffff);

        pWindow.present();

        // Wait for a key
        ks.new_key = false;
        noEvents: while (ks.new_key == false) {
            _ = ie.pollInputEvent(&ks, &ks.ei);
        }

        // Process the key
        if (DBG) warn("ks.mod={}\n", ks.mod);
        switch (ks.code) {
            gl.SDLK_ESCAPE => break :done,
            gl.SDLK_LEFT => meshes[0].rotation = rotate(ks.mod, meshes[0].rotation, f32(15)),
            gl.SDLK_RIGHT => meshes[0].rotation = rotate(ks.mod, meshes[0].rotation, -f32(15)),

            // Not working well
            //gl.SDLK_UP => camera.position = translate(ks.mod, camera.position, f32(10)),
            //gl.SDLK_DOWN => camera.position = translate(ks.mod, camera.position, -f32(10)),
            else => {},
        }
    }
}
