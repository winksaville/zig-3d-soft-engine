const builtin = @import("builtin");
const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const warn = std.debug.warn;
const gl = @import("../modules/zig-sdl2/src/index.zig");

const math3d = @import("math3d.zig");
const Camera = @import("camera.zig").Camera;
const Mesh = @import("mesh.zig").Mesh;

const DBG = true;

pub const Window = struct.{
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
        var self = Self.{
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

        self.setBgColor(0xffffffff);

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
        pSelf.pixels[(y * @intCast(usize, pSelf.widthci)) + x] = color;
    }

    pub fn getPixel(pSelf: *Self, x: usize, y: usize) u32 {
        return pSelf.pixels[(y * @intCast(usize, pSelf.widthci)) + x];
    }

    pub fn present(pSelf: *Self) void {
        _ = gl.SDL_UpdateTexture(pSelf.sdl_texture, null, @ptrCast(*const c_void, &pSelf.pixels[0]), pSelf.widthci * @sizeOf(@typeOf(pSelf.pixels[0])));
        _ = gl.SDL_RenderClear(pSelf.sdl_renderer);
        _ = gl.SDL_RenderCopy(pSelf.sdl_renderer, pSelf.sdl_texture, null, null);
        _ = gl.SDL_RenderPresent(pSelf.sdl_renderer);
    }

    /// Project takes a 3D coord and converts it to a 2D coordinate
    /// using the transform matrix.
    pub fn project(pSelf: *Self, coord: math3d.Vec3, transMat: *const math3d.Mat4x4) math3d.Vec2 {
        // Transform coord in 3D
        var point = coord.transform(transMat);

        // The transformed coord is based on a coordinate system
        // where the origin is the center of the screen. Convert
        // them to coordindates where x:0, y:0 is the upper left.
        var x = (point.x() * pSelf.widthf) + (pSelf.widthf / 2.0);
        var y = (-point.y() * pSelf.heightf) + (pSelf.heightf / 2.0);
        return math3d.Vec2.init(x, y);
    }

    /// Draw a Vec2 point clipping it if its outside the screen
    pub fn drawPoint(pSelf: *Self, point: math3d.Vec2, color: u32) void {
        if ((point.x() >= 0) and (point.y() >= 0) and (point.x() < pSelf.widthf) and (point.y() < pSelf.heightf)) {
            pSelf.putPixel(@floatToInt(usize, point.x()), @floatToInt(usize, point.y()), color);
        }
    }

    /// Render the meshes into the window from the camera's point of view
    pub fn render(pSelf: *Self, camera: *const Camera, meshes: []const Mesh) void {
        var view_matrix = math3d.lookAtLh(&camera.position, &camera.target, &math3d.Vec3.unitY());
        if (DBG) math3d.printMat4x4("view_matrix:\n", &view_matrix);

        var fov: f32 = 0.78;
        var znear: f32 = 0.01;
        var zvar: f32 = 1.0;
        var projection_matrix = math3d.perspectiveFovRh(fov, pSelf.widthf / pSelf.heightf, znear, zvar);
        if (DBG) math3d.printMat4x4("projection_matrix:\n", &projection_matrix);

        for (meshes) |mesh| {
            var world_matrix = math3d.translation(mesh.position.x(), mesh.position.y(), mesh.position.z()).mult(&math3d.rotationYawPitchRoll(mesh.rotation.x(), mesh.rotation.y(), mesh.rotation.z()));
            if (DBG) math3d.printMat4x4("world_matrix:\n", &world_matrix);

            var transform_matrix = world_matrix.mult(&view_matrix.mult(&projection_matrix));
            if (DBG) math3d.printMat4x4("transform_matrix:\n", &transform_matrix);

            for (mesh.vertices) |vertex| {
                var point = pSelf.project(vertex, &transform_matrix);
                pSelf.drawPoint(point, 0xffffffff);
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

    window.present();
}

test "window.project" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 640, 480, "testWindow");
    defer window.deinit();

    var v1 = math3d.Vec3.init(0, 0, 0);
    var r = window.project(v1, &math3d.mat4x4_identity);
    assert(r.x() == window.widthf / 2.0);
    assert(r.y() == window.heightf / 2.0);

    v1 = math3d.Vec3.init(-0.5, 0.5, 0);
    r = window.project(v1, &math3d.mat4x4_identity);
    assert(r.x() == 0);
    assert(r.y() == 0);

    v1 = math3d.Vec3.init(0.5, -0.5, 0);
    r = window.project(v1, &math3d.mat4x4_identity);
    assert(r.x() == window.widthf);
    assert(r.y() == window.heightf);

    v1 = math3d.Vec3.init(-0.5, -0.5, 0);
    r = window.project(v1, &math3d.mat4x4_identity);
    assert(r.x() == 0);
    assert(r.y() == window.heightf);

    v1 = math3d.Vec3.init(0.5, 0.5, 0);
    r = window.project(v1, &math3d.mat4x4_identity);
    assert(r.x() == window.widthf);
    assert(r.y() == 0);
}

test "window.drawPoint" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 640, 480, "testWindow");
    defer window.deinit();

    var p1 = math3d.Vec2.init(0, 0);
    window.drawPoint(p1, 0x80808080);
    assert(window.getPixel(0, 0) == 0x80808080);

    p1 = math3d.Vec2.init(window.widthf / 2, window.heightf / 2);
    window.drawPoint(p1, 0x80808080);
    assert(window.getPixel(window.width / 2, window.height / 2) == 0x80808080);
}

test "window.render" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 640, 480, "testWindow");
    defer window.deinit();

    // Black background color
    window.setBgColor(0);

    // Unit cube about 0,0,0
    var cube_mesh = try Mesh.init(pAllocator, "mesh1", 8);
    cube_mesh.vertices[0] = math3d.vec3(-1, 1, 1);
    cube_mesh.vertices[1] = math3d.vec3(1, 1, 1);
    cube_mesh.vertices[2] = math3d.vec3(-1, -1, 1);
    cube_mesh.vertices[3] = math3d.vec3(-1, -1, -1);
    cube_mesh.vertices[4] = math3d.vec3(-1, 1, -1);
    cube_mesh.vertices[5] = math3d.vec3(1, 1, -1);
    cube_mesh.vertices[6] = math3d.vec3(1, -1, 1);
    cube_mesh.vertices[7] = math3d.vec3(1, -1, -1);

    var camera_position = math3d.Vec3.init(0, 0, 10);
    var camera_target = math3d.Vec3.zero();
    var camera = Camera.init(camera_position, camera_target);

    var meshes = []Mesh.{cube_mesh};
    window.render(&camera, &meshes);
}
