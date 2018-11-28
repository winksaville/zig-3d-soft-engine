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
const V2f32 = geo.V2f32;
const V3f32 = geo.V3f32;
const M44f32 = geo.M44f32;

const parseJsonFile = @import("parse_json_file.zig").parseJsonFile;

const Camera = @import("camera.zig").Camera;

const Mesh = @import("mesh.zig").Mesh;
const Vertex = @import("mesh.zig").Vertex;
const Face = @import("mesh.zig").Face;
const computeVerticeNormals = @import("mesh.zig").computeVerticeNormals;
const computeVerticeNormalsDbg = @import("mesh.zig").computeVerticeNormalsDbg;

const ie = @import("input_events.zig");

const DBG = true;
const DBG1 = false;
const DBG2 = false;
const DBG3 = false;

const RenderMode = enum {
    Points,
    Lines,
    Triangles,
};
const DBG_RenderMode = RenderMode.Triangles;

const ScanLineData = struct {
    pub y: isize,
    pub ndotla: f32,
    pub ndotlb: f32,
    pub ndotlc: f32,
    pub ndotld: f32,
};

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
    zbuffer: []f32,
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
            .zbuffer = try pAllocator.alloc(f32, width * height),
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
        for (pSelf.zbuffer) |*elem| {
            elem.* = math.f32_max; //math.maxValue(@typeOf(elem.*));
        }
    }

    pub fn putPixel(pSelf: *Self, x: usize, y: usize, z: f32, color: u32) void {
        if (DBG3) warn("putPixel: x={} y={} z={.3} c={x}\n", x, y, color);
        var index = (y * pSelf.width) + x;

        // If z is behind or equal to (>=) a previouly written pixel just return.
        // NOTE: First value written, if they are equal, will be visible. Is this what we want?
        if (z >= pSelf.zbuffer[index]) return;
        pSelf.zbuffer[index] = z;

        pSelf.pixels[index] = color;
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
        //if (DBG) warn("drawPointXy: x={} y={} c={x}\n", x, y, color);
        if ((x >= 0) and (y >= 0)) {
            var ux = @bitCast(usize, x);
            var uy = @bitCast(usize, y);
            if ((ux < pSelf.width) and (uy < pSelf.height)) {
                //if (DBG) warn("drawPointXy: putting x={} y={} c={x}\n", ux, uy, color);
                pSelf.putPixel(ux, uy, -math.f32_max, color);
            }
        }
    }

    /// Draw a point defined by x, y in screen coordinates clipping it if its outside the screen
    pub fn drawPointXyz(pSelf: *Self, x: isize, y: isize, z: f32, color: u32) void {
        //if (DBG) warn("drawPointXy: x={} y={} z={.3} c={x}\n", x, y, color);
        if ((x >= 0) and (y >= 0)) {
            var ux = @bitCast(usize, x);
            var uy = @bitCast(usize, y);
            if ((ux < pSelf.width) and (uy < pSelf.height)) {
                //if (DBG) warn("drawPointXy: putting x={} y={} c={x}\n", ux, uy, color);
                pSelf.putPixel(ux, uy, z, color);
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
    pub fn projectRetVertex(pSelf: *Self, vertex: Vertex, transMat: *const M44f32, worldMat: *const M44f32) Vertex {
        if (DBG1) warn("projectRetVertex:    original coord={} widthf={.3} heightf={.3}\n", &vertex.coord, pSelf.widthf, pSelf.heightf);
        var point = vertex.coord.transform(transMat);
        var point_world = vertex.coord.transform(worldMat);
        var normal_world = vertex.normal_coord.transform(worldMat);

        var x = (point.x() * pSelf.widthf) + (pSelf.widthf / 2.0);
        var y = (-point.y() * pSelf.heightf) + (pSelf.heightf / 2.0);

        return Vertex {
            .coord = V3f32.init(x, y, point.z()),
            .world_coord = point_world,
            .normal_coord = normal_world,
        };
    }

    /// Draw a V3f32 point in screen coordinates clipping it if its outside the screen
    pub fn drawPointV3f32(pSelf: *Self, point: geo.V3f32, color: u32) void {
        pSelf.drawPointXyz(@floatToInt(isize, math.trunc(point.x())), @floatToInt(isize, math.trunc(point.y())), point.z(), color);
    }

    /// Clamp value to between min and max parameters
    pub fn clamp(value: f32, min: f32, max: f32) f32 {
        return math.max(min, math.min(value, max));
    }

    /// Interplate between min and max as a percentage between
    /// min and max as defined by the gradient. With 0.0 <= gradiant <= 1.0.
    pub fn interpolate(min: f32, max: f32, gradient: f32) f32 {
        return min + (max - min) * clamp(gradient, 0, 1);
    }

    /// Compute the normal dot light
    pub fn computeNormalDotLight(vertex: V3f32, normal: V3f32, light_pos: V3f32) f32 {
        var light_direction = light_pos.sub(&vertex);
        var nrml = normal.normalize();
        light_direction = light_direction.normalize();

        var ndotl = nrml.dot(&light_direction);
        var r = math.max(0, ndotl);

        if (DBG3) warn("computeNormalDotLight: ndotl={} r={}\n", ndotl, r);
        return r;
    }

    /// Scale each of the rgb components by other
    pub fn colorScale(color: u32, other: f32) u32 {
        var b: u32 = @floatToInt(u32, math.round(@intToFloat(f32, (color >> 0) & 0xff) * other));
        var g: u32 = @floatToInt(u32, math.round(@intToFloat(f32, (color >> 8) & 0xff) * other));
        var r: u32 = @floatToInt(u32, math.round(@intToFloat(f32, (color >> 16) & 0xff) * other));
        var a: u32 = (color >> 24) & 0xff;

        var result = (a << 24) | (r << 16) | (g << 8) | (b << 0);
        if (DBG3) warn("colorScale: color={x} other={.5} r={x}\n", color, other, result);
        return result;
    }

    /// Draw a horzitontal scan line at y between line a lined defined by
    /// va:vb to another defined line vc:vd. It is assumed they have
    /// already been sorted and we're drawing horizontal lines with
    /// line va:vb on the left and vc:vd on the right.
    pub fn processScanLine(pSelf: *Self, scanLineData: ScanLineData, va: Vertex, vb: Vertex, vc: Vertex, vd: Vertex, color: u32) void {
        var pa = va.coord;
        var pb = vb.coord;
        var pc = vc.coord;
        var pd = vd.coord;

        // Compute the gradiants and if the line are just points then gradient is 1
        const gradient1: f32 = if (pa.y() == pb.y()) 1 else (@intToFloat(f32, scanLineData.y) - pa.y()) / (pb.y() - pa.y());
        const gradient2: f32 = if (pc.y() == pd.y()) 1 else (@intToFloat(f32, scanLineData.y) - pc.y()) / (pd.y() - pc.y());

        // Define the start and end point for x
        var sx: isize = @floatToInt(isize, interpolate(pa.x(), pb.x(), gradient1));
        var ex: isize = @floatToInt(isize, interpolate(pc.x(), pd.x(), gradient2));

        // Define the start and end point for z
        var sz: f32 = interpolate(pa.z(), pb.z(), gradient1);
        var ez: f32 = interpolate(pc.z(), pd.z(), gradient2);

        // Define the start and end point for normal dot light
        var snl: f32 = interpolate(scanLineData.ndotla, scanLineData.ndotlb, gradient1);
        var enl: f32 = interpolate(scanLineData.ndotlc, scanLineData.ndotld, gradient2);

        // Draw a horzitional line between start and end x
        var x: isize = sx;
        while (x < ex) : (x += 1) {
            var gradient: f32 = @intToFloat(f32, (x - sx)) / @intToFloat(f32, (ex -sx));
            var z = interpolate(sz, ez, gradient);
            var ndotl = interpolate(snl, enl, gradient);

            pSelf.drawPointXyz(x, scanLineData.y, z, colorScale(color, ndotl));
        }
    }

    pub fn drawTriangle(pSelf: *Self, v1: Vertex, v2: Vertex, v3: Vertex, color: u32) void {
        // Sort the points finding top, mid, bottom.
        var t = v1; // Top
        var m = v2; // Mid
        var b = v3; // Bottom

        // Find top, i.e. the point with the smallest y value
        if (t.coord.y() > m.coord.y()) {
            mem.swap(Vertex, &t, &m);
        }
        if (t.coord.y() > b.coord.y()) {
            mem.swap(Vertex, &t, &b);
        }

        // Now switch mid and bottom if they are out of order
        if (m.coord.y() > b.coord.y()) {
            mem.swap(Vertex, &m, &b);
        }

        var light_pos = V3f32.init(0, 10, 10);

        var t_ndotl = computeNormalDotLight(t.world_coord, t.normal_coord, light_pos);
        var m_ndotl = computeNormalDotLight(m.world_coord, m.normal_coord, light_pos);
        var b_ndotl = computeNormalDotLight(b.world_coord, b.normal_coord, light_pos);

        var scanLineData: ScanLineData = undefined;

        // Compute the inverse slopes
        // http://en.wikipedia.org/wiki/Slope
        var slope_t_m: f32 = if ((m.coord.y() - t.coord.y()) > 0) (m.coord.x() - t.coord.x()) / (m.coord.y() - t.coord.y()) else 0;
        var slope_t_b: f32 = if ((b.coord.y() - t.coord.y()) > 0) (b.coord.x() - t.coord.x()) / (b.coord.y() - t.coord.y()) else 0;

        // Two cases, 1) triangles with mid on the right
        if (slope_t_m > slope_t_b) {
            // Triangles with mid on the right
            // t
            // |\
            // | \
            // |  \
            // |   m
            // |  /
            // | /
            // |/
            // b
            scanLineData.y = @floatToInt(isize, math.trunc(t.coord.y()));
            while (scanLineData.y <= @floatToInt(isize, math.trunc(b.coord.y()))) : (scanLineData.y += 1) {
                if (scanLineData.y < @floatToInt(isize, math.trunc(m.coord.y()))) {
                    scanLineData.ndotla = t_ndotl;
                    scanLineData.ndotlb = b_ndotl;
                    scanLineData.ndotlc = t_ndotl;
                    scanLineData.ndotld = m_ndotl;
                    pSelf.processScanLine(scanLineData, t, b, t, m, color);
                } else {
                    scanLineData.ndotla = t_ndotl;
                    scanLineData.ndotlb = b_ndotl;
                    scanLineData.ndotlc = m_ndotl;
                    scanLineData.ndotld = b_ndotl;
                    pSelf.processScanLine(scanLineData, t, b, m, b, color);
                }
            }
        } else {
            // Triangles with mid on the left
            //     t
            //    /|
            //   / |
            //  /  |
            // m   |
            //  \  |
            //   \ |
            //    \|
            //     b
            scanLineData.y = @floatToInt(isize, math.trunc(t.coord.y()));
            while (scanLineData.y <= @floatToInt(isize, math.trunc(b.coord.y()))) : (scanLineData.y += 1) {
                if (scanLineData.y < @floatToInt(isize, math.trunc(m.coord.y()))) {
                    scanLineData.ndotla = t_ndotl;
                    scanLineData.ndotlb = m_ndotl;
                    scanLineData.ndotlc = t_ndotl;
                    scanLineData.ndotld = b_ndotl;
                    pSelf.processScanLine(scanLineData, t, m, t, b, color);
                } else {
                    scanLineData.ndotla = m_ndotl;
                    scanLineData.ndotlb = b_ndotl;
                    scanLineData.ndotlc = t_ndotl;
                    scanLineData.ndotld = b_ndotl;
                    pSelf.processScanLine(scanLineData, m, b, t, b, color);
                }
            }
        }
    }

    /// Render the meshes into the window from the camera's point of view
    pub fn render(pSelf: *Self, camera: *const Camera, meshes: []const Mesh) void {
        var view_matrix = geo.lookAtLh(&camera.position, &camera.target, &geo.V3f32.unitY());
        if (DBG) warn("\nview_matrix:\n{}", &view_matrix);

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

            for (mesh.faces) |face, i| {
                const va = mesh.vertices[face.a];
                const vb = mesh.vertices[face.b];
                const vc = mesh.vertices[face.c];
                if (DBG3) warn("\nva={} vb={} vc={}\n", va.coord, vb.coord, vc.coord);

                var color: u32 = 0xffff00ff;

                switch (DBG_RenderMode) {
                    RenderMode.Points => {
                        const pa = pSelf.projectRetV2f32(va.coord, &transform_matrix);
                        const pb = pSelf.projectRetV2f32(vb.coord, &transform_matrix);
                        const pc = pSelf.projectRetV2f32(vc.coord, &transform_matrix);
                        if (DBG3) warn("pa={} pb={} pc={}\n", pa, pb, pc);

                        pSelf.drawPointV2f32(pa, color);
                        pSelf.drawPointV2f32(pb, color);
                        pSelf.drawPointV2f32(pc, color);
                    },
                    RenderMode.Lines => {
                        const pa = pSelf.projectRetV2f32(va.coord, &transform_matrix);
                        const pb = pSelf.projectRetV2f32(vb.coord, &transform_matrix);
                        const pc = pSelf.projectRetV2f32(vc.coord, &transform_matrix);
                        if (DBG3) warn("pa={} pb={} pc={}\n", pa, pb, pc);

                        pSelf.drawBline(pa, pb, color);
                        pSelf.drawBline(pb, pc, color);
                        pSelf.drawBline(pc, pa, color);
                    },
                    RenderMode.Triangles => {
                        // Transform the vertex's
                        const tva = pSelf.projectRetVertex(va, &transform_matrix, &world_matrix);
                        const tvb = pSelf.projectRetVertex(vb, &transform_matrix, &world_matrix);
                        const tvc = pSelf.projectRetVertex(vc, &transform_matrix, &world_matrix);
                        if (DBG3) warn("tva={} tvb={} tvc={}\n", tva.coord, tvb.coord, tvc.coord);

                        var colorF32: f32 = 0.25 + @intToFloat(f32, i % mesh.faces.len) * (0.75 / @intToFloat(f32, mesh.faces.len));
                        var colorU32: u32 = @floatToInt(u32, math.round(colorF32 * 256.0)) & 0xff;
                        color = (0xFF << 24) | (colorU32 << 16) | (colorU32 << 8) | colorU32;
                        pSelf.drawTriangle(tva, tvb, tvc, color);
                    },
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
    window.putPixel(0, 0, 0, 0x01020304);
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

test "window.projectRetVertex" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 640, 480, "testWindow");
    defer window.deinit();

    var v1 = Vertex { .coord = geo.V3f32.init(0, 0, 0), .world_coord = undefined, .normal_coord = undefined, };
    var r = window.projectRetVertex(v1, &geo.m44f32_unit, &geo.m44f32_unit);
    assert(r.coord.x() == window.widthf / 2.0);
    assert(r.coord.y() == window.heightf / 2.0);

    v1 = Vertex { .coord = geo.V3f32.init(-0.5, 0.5, 0), .world_coord = undefined, .normal_coord = undefined, };
    r = window.projectRetVertex(v1, &geo.m44f32_unit, &geo.m44f32_unit);
    assert(r.coord.x() == 0);
    assert(r.coord.y() == 0);

    v1 = Vertex { .coord = geo.V3f32.init(0.5, -0.5, 0), .world_coord = undefined, .normal_coord = undefined, };
    r = window.projectRetVertex(v1, &geo.m44f32_unit, &geo.m44f32_unit);
    assert(r.coord.x() == window.widthf);
    assert(r.coord.y() == window.heightf);

    v1 = Vertex { .coord = geo.V3f32.init(-0.5, -0.5, 0), .world_coord = undefined, .normal_coord = undefined, };
    r = window.projectRetVertex(v1, &geo.m44f32_unit, &geo.m44f32_unit);
    assert(r.coord.x() == 0);
    assert(r.coord.y() == window.heightf);

    v1 = Vertex { .coord = geo.V3f32.init(0.5, 0.5, 0), .world_coord = undefined, .normal_coord = undefined, };
    r = window.projectRetVertex(v1, &geo.m44f32_unit, &geo.m44f32_unit);
    assert(r.coord.x() == window.widthf);
    assert(r.coord.y() == 0);
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
    mesh.vertices[0] = Vertex { .coord = V3f32.init(-1, 1, 1), .world_coord = V3f32.init(0, 0, 0), .normal_coord = V3f32.init(0, 0, 0), };
    mesh.vertices[1] = Vertex { .coord = geo.V3f32.init(-1, -1, 1), .world_coord = V3f32.init(0, 0, 0), .normal_coord = V3f32.init(0, 0, 0), };
    mesh.vertices[2] = Vertex { .coord = geo.V3f32.init(1, -1, 1), .world_coord = V3f32.init(0, 0, 0), .normal_coord = V3f32.init(0, 0, 0), };
    mesh.vertices[3] = Vertex { .coord = geo.V3f32.init(1, 1, 1), .world_coord = V3f32.init(0, 0, 0), .normal_coord = V3f32.init(0, 0, 0), };

    mesh.vertices[4] = Vertex { .coord = V3f32.init(-1, 1, -1), .world_coord = V3f32.init(0, 0, 0), .normal_coord = V3f32.init(0, 0, 0), };
    mesh.vertices[5] = Vertex { .coord = geo.V3f32.init(-1, -1, -1), .world_coord = V3f32.init(0, 0, 0), .normal_coord = V3f32.init(0, 0, 0), };
    mesh.vertices[6] = Vertex { .coord = geo.V3f32.init(1, -1, -1), .world_coord = V3f32.init(0, 0, 0), .normal_coord = V3f32.init(0, 0, 0), };
    mesh.vertices[7] = Vertex { .coord = geo.V3f32.init(1, 1, -1), .world_coord = V3f32.init(0, 0, 0), .normal_coord = V3f32.init(0, 0, 0), };

    // 12 faces
    mesh.faces[0] = Face { .a=0, .b=1, .c=2, };
    mesh.faces[1] = Face { .a=0, .b=2, .c=3, };
    mesh.faces[2] = Face { .a=3, .b=2, .c=6, };
    mesh.faces[3] = Face { .a=3, .b=6, .c=7, };
    mesh.faces[4] = Face { .a=7, .b=6, .c=5, };
    mesh.faces[5] = Face { .a=7, .b=5, .c=4, };

    mesh.faces[6] = Face { .a=4, .b=5, .c=1, };
    mesh.faces[7] = Face { .a=4, .b=1, .c=0, };
    mesh.faces[8] = Face { .a=0, .b=3, .c=4, };
    mesh.faces[9] = Face { .a=3, .b=7, .c=4, };
    mesh.faces[10] = Face { .a=1, .b=6, .c=2, };
    mesh.faces[11] = Face { .a=1, .b=5, .c=6, };

    var meshes = []Mesh{mesh};

    warn("\n");
    computeVerticeNormalsDbg(true, meshes[0..]);

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

test "window.keyctrl.triangle" {
    if (DBG) {
        var direct_allocator = std.heap.DirectAllocator.init();
        var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
        defer arena_allocator.deinit();
        var pAllocator = &arena_allocator.allocator;

        var window = try Window.init(pAllocator, 800, 600, "testWindow");
        defer window.deinit();

        // Black background color
        window.setBgColor(0);

        // Triangle
        var mesh: Mesh = try Mesh.init(pAllocator, "triangle", 3, 1);
        mesh.vertices[0] = Vertex { .coord = geo.V3f32.init(0, 1, 0), .world_coord = V3f32.init(0, 0, 0), .normal_coord = V3f32.init(0, 0, 0), };
        mesh.vertices[1] = Vertex { .coord = geo.V3f32.init(-1, -1, 0), .world_coord = V3f32.init(0, 0, 0), .normal_coord = V3f32.init(0, 0, 0), };
        mesh.vertices[2] = Vertex { .coord = geo.V3f32.init(0.5, -0.5, 0), .world_coord = V3f32.init(0, 0, 0), .normal_coord = V3f32.init(0, 0, 0), };

        mesh.faces[0] = Face { .a=0, .b=1, .c=2 };

        var meshes = []Mesh{mesh};

        computeVerticeNormals(meshes[0..]);

        keyCtrlMeshes(&window, &meshes);
    }
}

test "window.keyctrl.suzanne" {
    if (DBG) {
        var direct_allocator = std.heap.DirectAllocator.init();
        var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
        defer arena_allocator.deinit();
        var pAllocator = &arena_allocator.allocator;

        var window = try Window.init(pAllocator, 800, 600, "testWindow");
        defer window.deinit();

        // Black background color
        window.setBgColor(0);

        var file_name = "res/suzanne.babylon";
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

        var center = geo.V2f32.init(pWindow.widthf / 2, pWindow.heightf / 2);
        pWindow.drawPointV2f32(center, 0xffffffff);

        if (DBG or DBG1 or DBG2) warn("\n");

        if (DBG1) warn("camera={}\n", &camera.position);
        if (DBG1) warn("rotation={}\n", meshes[0].rotation);
        pWindow.render(&camera, meshes);

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
