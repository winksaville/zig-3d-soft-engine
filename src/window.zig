const builtin = @import("builtin");
const TypeId = builtin.TypeId;

const std = @import("std");
const time = std.os.time;
const mem = std.mem;
const math = std.math;
const Allocator = mem.Allocator;
const assert = std.debug.assert;
const warn = std.debug.warn;
const gl = @import("../modules/zig-sdl2/src/index.zig");

const misc = @import("../modules/zig-misc/index.zig");
const saturateCast = misc.saturateCast;

const colorns = @import("color.zig");
const Color = colorns.Color;
const ColorU8 = colorns.ColorU8;

const geo = @import("../modules/zig-geometry/index.zig");
const V2f32 = geo.V2f32;
const V3f32 = geo.V3f32;
const M44f32 = geo.M44f32;

const parseJsonFile = @import("../modules/zig-json/parse_json_file.zig").parseJsonFile;
const createMeshFromBabylonJson = @import("create_mesh_from_babylon_json.zig").createMeshFromBabylonJson;

const Camera = @import("camera.zig").Camera;

const meshns = @import("../modules/zig-geometry/mesh.zig");
const Mesh = meshns.Mesh;
const Vertex = meshns.Vertex;
const Face = meshns.Face;

const Texture = @import("texture.zig").Texture;

const ki = @import("keyboard_input.zig");

const DBG = true;
const DBG1 = false;
const DBG2 = false;
const DBG3 = false;
const DBG_RenderUsingMode = false;
const DBG_RenderUsingModeInner = false;
const DBG_RenderUsingModeWaitForKey = false;
const DBG_PutPixel = false;
const DBG_DrawTriangle = false;
const DBG_DrawTriangleInner = false;
const DBG_ProcessScanLine = false;
const DBG_ProcessScanLineInner = false;

pub const Entity = struct {
    mesh: Mesh,
    texture: ?Texture,
};

pub const RenderMode = enum {
    Points,
    Lines,
    Triangles,
};
const DBG_RenderMode = RenderMode.Points;

const ScanLineData = struct {
    pub y: isize,
    pub ndotla: f32,
    pub ndotlb: f32,
    pub ndotlc: f32,
    pub ndotld: f32,

    pub ua: f32,
    pub ub: f32,
    pub uc: f32,
    pub ud: f32,

    pub va: f32,
    pub vb: f32,
    pub vc: f32,
    pub vd: f32,
};

pub const Window = struct {
    const Self = @This();

    const ZbufferType = f32;

    pAllocator: *Allocator,
    width: usize,
    widthci: c_int,
    widthf: f32,
    height: usize,
    heightci: c_int,
    heightf: f32,
    name: []const u8,
    bg_color: ColorU8,
    pixels: []u32,
    zbuffer: []ZbufferType,
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

        self.setBgColor(ColorU8.Black);

        // Initialize SDL
        if (gl.SDL_Init(gl.SDL_INIT_VIDEO | gl.SDL_INIT_AUDIO) != 0) {
            return error.FailedSdlInitialization;
        }
        errdefer gl.SDL_Quit();

        // Initialize SDL image
        if (gl.IMG_Init(gl.IMG_INIT_JPG) != @intCast(c_int, gl.IMG_INIT_JPG)) {
            return error.FailedSdlImageInitialization;
        }
        errdefer gl.IMG_Quit();

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

    pub fn setBgColor(pSelf: *Self, color: ColorU8) void {
        pSelf.bg_color = color;
    }

    pub fn clearZbufferValue(pSelf: *Self) ZbufferType {
        return misc.maxValue(ZbufferType);
    }

    pub fn clear(pSelf: *Self) void {
        // Init Pixel buffer
        for (pSelf.pixels) |*pixel| {
            pixel.* = pSelf.bg_color.asU32Argb();
        }
        for (pSelf.zbuffer) |*elem| {
            elem.* = pSelf.clearZbufferValue();
        }
    }

    pub fn putPixel(pSelf: *Self, x: usize, y: usize, z: f32, color: ColorU8) void {
        if (DBG_PutPixel) warn("putPixel: x={} y={} z={.3} c={}\n", x, y, z, &color);
        var index = (y * pSelf.width) + x;

        // +Z is towards screen so (-Z is away from screen) so if z is behind
        // or equal to (>=) a previouly written pixel just return.
        // NOTE: First value written, if they are equal, will be visible. Is this what we want?
        if (z >= pSelf.zbuffer[index]) return;
        pSelf.zbuffer[index] = z;

        pSelf.pixels[index] = color.asU32Argb();
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
    pub fn projectRetV2f32(pSelf: *Self, coord: V3f32, transMat: *const M44f32) V2f32 {
        if (DBG1) warn("projectRetV2f32:    original coord={} widthf={.3} heightf={.3}\n", &coord, pSelf.widthf, pSelf.heightf);
        return geo.projectToScreenCoord(pSelf.widthf, pSelf.heightf, coord, transMat);
    }

    /// Draw a Vec2 point in screen coordinates clipping it if its outside the screen
    pub fn drawPointV2f32(pSelf: *Self, point: V2f32, color: ColorU8) void {
        pSelf.drawPointXy(@floatToInt(isize, point.x()), @floatToInt(isize, point.y()), color);
    }

    /// Draw a point defined by x, y in screen coordinates clipping it if its outside the screen
    pub fn drawPointXy(pSelf: *Self, x: isize, y: isize, color: ColorU8) void {
        //if (DBG) warn("drawPointXy: x={} y={} c={}\n", x, y, &color);
        if ((x >= 0) and (y >= 0)) {
            var ux = @bitCast(usize, x);
            var uy = @bitCast(usize, y);
            if ((ux < pSelf.width) and (uy < pSelf.height)) {
                //if (DBG) warn("drawPointXy: putting x={} y={} c={}\n", ux, uy, &color);
                pSelf.putPixel(ux, uy, -pSelf.clearZbufferValue(), color);
            }
        }
    }

    /// Draw a point defined by x, y in screen coordinates clipping it if its outside the screen
    pub fn drawPointXyz(pSelf: *Self, x: isize, y: isize, z: f32, color: ColorU8) void {
        //if (DBG) warn("drawPointXyz: x={} y={} z={.3} c={}\n", x, y, &color);
        if ((x >= 0) and (y >= 0)) {
            var ux = @bitCast(usize, x);
            var uy = @bitCast(usize, y);
            if ((ux < pSelf.width) and (uy < pSelf.height)) {
                //if (DBG) warn("drawPointXyz: putting x={} y={} c={}\n", ux, uy, &color);
                pSelf.putPixel(ux, uy, z, color);
            }
        }
    }

    /// Draw a line point0 and 1 are in screen coordinates
    pub fn drawLine(pSelf: *Self, point0: V2f32, point1: V2f32, color: ColorU8) void {
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
    pub fn drawBline(pSelf: *Self, point0: V2f32, point1: V2f32, color: ColorU8) void {
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

        return Vertex{
            .coord = V3f32.init(x, y, point.z()),
            .world_coord = point_world,
            .normal_coord = normal_world,
            .texture_coord = vertex.texture_coord,
        };
    }

    /// Draw a V3f32 point in screen coordinates clipping it if its outside the screen
    pub fn drawPointV3f32(pSelf: *Self, point: V3f32, color: ColorU8) void {
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

    /// Draw a horzitontal scan line at y between line a lined defined by
    /// va:vb to another defined line vc:vd. It is assumed they have
    /// already been sorted and we're drawing horizontal lines with
    /// line va:vb on the left and vc:vd on the right.
    pub fn processScanLine(pSelf: *Self, scanLineData: ScanLineData, va: Vertex, vb: Vertex, vc: Vertex, vd: Vertex, color: ColorU8, texture: ?Texture) void {
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

        // Define the start and end for texture u/v
        var su: f32 = interpolate(scanLineData.ua, scanLineData.ub, gradient1);
        var eu: f32 = interpolate(scanLineData.uc, scanLineData.ud, gradient2);
        var sv: f32 = interpolate(scanLineData.va, scanLineData.vb, gradient1);
        var ev: f32 = interpolate(scanLineData.vc, scanLineData.vd, gradient2);

        // Draw a horzitional line between start and end
        if (scanLineData.y >= 0) { // Check if y is negative so our v casting works
            var x: isize = sx;
            if (DBG_ProcessScanLine) warn("processScanLine: y={} sx={} ex={} cnt={}\n", scanLineData.y, sx, ex, ex - sx);
            while (x < ex) : (x += 1) {
                var gradient: f32 = @intToFloat(f32, (x - sx)) / @intToFloat(f32, (ex - sx));
                var z = interpolate(sz, ez, gradient);
                var ndotl = interpolate(snl, enl, gradient);
                var u = interpolate(su, eu, gradient);
                var v = interpolate(sv, ev, gradient);

                if (x >= 0) { // Check if x is negative so our u casting works
                    var c: ColorU8 = undefined;
                    if (texture) |t| {
                        c = t.map(u, v, color);
                        if (DBG_ProcessScanLineInner) warn("processScanLine: c={}\n", &c);
                    } else {
                        c = color;
                    }
                    pSelf.drawPointXyz(x, scanLineData.y, z, c.colorScale(ndotl));
                }
            }
        }
    }

    pub fn drawTriangle(pSelf: *Self, v1: Vertex, v2: Vertex, v3: Vertex, color: ColorU8, texture: ?Texture) void {
        if (DBG_DrawTriangle) warn("drawTriangle:\n v1={}\n v2={}\n v3={}\n", v1, v2, v3);

        // Sort the points finding top, mid, bottom.
        var t = v1; // Top
        var m = v2; // Mid
        var b = v3; // Bottom

        // Find top, i.e. the point with the smallest y value
        if (t.coord.y() > m.coord.y()) {
            mem.swap(Vertex, &t, &m);
        }
        if (m.coord.y() > b.coord.y()) {
            mem.swap(Vertex, &m, &b);
        }
        if (t.coord.y() > m.coord.y()) {
            mem.swap(Vertex, &t, &m);
        }
        if (DBG_DrawTriangle) warn("drawTriangle:\n t={}\n m={}\n b={}\n", t, m, b);

        var light_pos = V3f32.init(0, 10, -10);

        var t_ndotl = computeNormalDotLight(t.world_coord, t.normal_coord, light_pos);
        var m_ndotl = computeNormalDotLight(m.world_coord, m.normal_coord, light_pos);
        var b_ndotl = computeNormalDotLight(b.world_coord, b.normal_coord, light_pos);
        if (DBG_DrawTriangle) warn("drawTriangle:\n t_ndotl={}\n m_ndotl={}\n b_ndotl={}\n", t_ndotl, m_ndotl, b_ndotl);

        var scanLineData: ScanLineData = undefined;

        // Convert the top.coord.y, mid.coord.y and bottom.coord.y to integers
        var t_y = @floatToInt(isize, math.trunc(t.coord.y()));
        var m_y = @floatToInt(isize, math.trunc(m.coord.y()));
        var b_y = @floatToInt(isize, math.trunc(b.coord.y()));

        // Create top to mid line and top to bottom lines.
        // We then take the cross product of these lines and
        // if the result is positive then the mid is on the right
        // otherwise mid is on the left.
        //
        // See: https://www.davrous.com/2013/06/21/tutorial-part-4-learning-how-to-write-a-3d-software-engine-in-c-ts-or-js-rasterization-z-buffering/#comment-737
        // and https://stackoverflow.com/questions/243945/calculating-a-2d-vectors-cross-product?answertab=votes#tab-top
        var t_m = V2f32.init(m.coord.x() - t.coord.x(), m.coord.y() - t.coord.y());
        var t_b = V2f32.init(b.coord.x() - t.coord.x(), b.coord.y() - t.coord.y());
        var t_m_cross_t_b = t_m.cross(&t_b);

        // Two cases, 1) triangles with mid on the right
        if (t_m_cross_t_b > 0) {
            if (DBG_DrawTriangle) warn("drawTriangle: mid RIGHT t_m_cross_t_b:{.5} > 0\n", t_m_cross_t_b);

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
            scanLineData.y = t_y;
            while (scanLineData.y <= b_y) : (scanLineData.y += 1) {
                if (scanLineData.y < m_y) {
                    if (DBG_DrawTriangleInner) warn("drawTriangle: scanLineData.y:{} < m_y:{}\n", scanLineData.y, m_y);
                    scanLineData.ndotla = t_ndotl;
                    scanLineData.ndotlb = b_ndotl;
                    scanLineData.ndotlc = t_ndotl;
                    scanLineData.ndotld = m_ndotl;
                    scanLineData.ua = v1.texture_coord.x();
                    scanLineData.ub = v3.texture_coord.x();
                    scanLineData.uc = v1.texture_coord.x();
                    scanLineData.ud = v2.texture_coord.x();
                    scanLineData.va = v1.texture_coord.y();
                    scanLineData.vb = v3.texture_coord.y();
                    scanLineData.vc = v1.texture_coord.y();
                    scanLineData.vd = v2.texture_coord.y();
                    pSelf.processScanLine(scanLineData, t, b, t, m, color, texture);
                } else {
                    if (DBG_DrawTriangleInner) warn("drawTriangle: scanLineData.y:{} >= m_y:{}\n", scanLineData.y, m_y);
                    scanLineData.ndotla = t_ndotl;
                    scanLineData.ndotlb = b_ndotl;
                    scanLineData.ndotlc = m_ndotl;
                    scanLineData.ndotld = b_ndotl;
                    scanLineData.ua = v1.texture_coord.x();
                    scanLineData.ub = v3.texture_coord.x();
                    scanLineData.uc = v2.texture_coord.x();
                    scanLineData.ud = v3.texture_coord.x();
                    scanLineData.va = v1.texture_coord.y();
                    scanLineData.vb = v3.texture_coord.y();
                    scanLineData.vc = v2.texture_coord.y();
                    scanLineData.vd = v3.texture_coord.y();
                    pSelf.processScanLine(scanLineData, t, b, m, b, color, texture);
                }
            }
        } else {
            if (DBG_DrawTriangle) warn("drawTriangle: mid LEFT  t_m_cross_t_b:{.5} > 0\n", t_m_cross_t_b);

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
            scanLineData.y = t_y;
            while (scanLineData.y <= b_y) : (scanLineData.y += 1) {
                if (scanLineData.y < m_y) {
                    if (DBG_DrawTriangleInner) warn("drawTriangle: scanLineData.y:{} < m_y:{}\n", scanLineData.y, m_y);
                    scanLineData.ndotla = t_ndotl;
                    scanLineData.ndotlb = m_ndotl;
                    scanLineData.ndotlc = t_ndotl;
                    scanLineData.ndotld = b_ndotl;
                    scanLineData.ua = v1.texture_coord.x();
                    scanLineData.ub = v2.texture_coord.x();
                    scanLineData.uc = v1.texture_coord.x();
                    scanLineData.ud = v3.texture_coord.x();
                    scanLineData.va = v1.texture_coord.y();
                    scanLineData.vb = v2.texture_coord.y();
                    scanLineData.vc = v1.texture_coord.y();
                    scanLineData.vd = v3.texture_coord.y();
                    pSelf.processScanLine(scanLineData, t, m, t, b, color, texture);
                } else {
                    if (DBG_DrawTriangleInner) warn("drawTriangle: scanLineData.y:{} >= m_y:{}\n", scanLineData.y, m_y);
                    scanLineData.ndotla = m_ndotl;
                    scanLineData.ndotlb = b_ndotl;
                    scanLineData.ndotlc = t_ndotl;
                    scanLineData.ndotld = b_ndotl;
                    scanLineData.ua = v2.texture_coord.x();
                    scanLineData.ub = v3.texture_coord.x();
                    scanLineData.uc = v1.texture_coord.x();
                    scanLineData.ud = v3.texture_coord.x();
                    scanLineData.va = v2.texture_coord.y();
                    scanLineData.vb = v3.texture_coord.y();
                    scanLineData.vc = v1.texture_coord.y();
                    scanLineData.vd = v3.texture_coord.y();
                    pSelf.processScanLine(scanLineData, m, b, t, b, color, texture);
                }
            }
        }
    }

    /// Render the entities into the window from the camera's point of view
    pub fn renderUsingMode(pSelf: *Self, renderMode: RenderMode, camera: *const Camera, entities: []const Entity, negate_tnz: bool) void {
        var view_matrix: geo.M44f32 = undefined;
        view_matrix = geo.lookAtLh(&camera.position, &camera.target, &V3f32.unitY());
        if (DBG_RenderUsingMode) warn("view_matrix:\n{}\n", &view_matrix);

        var fov: f32 = 70;
        var znear: f32 = 0.1;
        var zfar: f32 = 1000.0;
        var perspective_matrix = geo.perspectiveM44(f32, geo.rad(fov), pSelf.widthf / pSelf.heightf, znear, zfar);
        if (DBG_RenderUsingMode) warn("perspective_matrix: fov={.3}, znear={.3} zfar={.3}\n{}\n", fov, znear, zfar, &perspective_matrix);

        for (entities) |entity| {
            var mesh = entity.mesh;
            var rotation_matrix = geo.rotateCwPitchYawRollV3f32(mesh.rotation);
            if (DBG_RenderUsingMode) warn("rotation_matrix:\n{}\n", &rotation_matrix);
            var translation_matrix = geo.translationV3f32(mesh.position);
            if (DBG_RenderUsingMode) warn("translation_matrix:\n{}\n", &translation_matrix);
            var world_matrix = geo.mulM44f32(&translation_matrix, &rotation_matrix);
            if (DBG_RenderUsingMode) warn("world_matrix:\n{}\n", &world_matrix);

            var world_to_view_matrix = geo.mulM44f32(&world_matrix, &view_matrix);
            var transform_matrix = geo.mulM44f32(&world_to_view_matrix, &perspective_matrix);
            if (DBG_RenderUsingMode) warn("transform_matrix:\n{}\n", &transform_matrix);


            if (DBG_RenderUsingMode) warn("\n");
            for (mesh.faces) |face, i| {
                const va = mesh.vertices[face.a];
                const vb = mesh.vertices[face.b];
                const vc = mesh.vertices[face.c];
                if (DBG_RenderUsingModeInner) warn("va={} vb={} vc={}\n", va.coord, vb.coord, vc.coord);

                var color = ColorU8.init(0xff, 0, 0xff, 0xff);

                switch (renderMode) {
                    RenderMode.Points => {
                        const pa = pSelf.projectRetV2f32(va.coord, &transform_matrix);
                        const pb = pSelf.projectRetV2f32(vb.coord, &transform_matrix);
                        const pc = pSelf.projectRetV2f32(vc.coord, &transform_matrix);
                        if (DBG_RenderUsingModeInner) warn("pa={} pb={} pc={}\n", pa, pb, pc);

                        pSelf.drawPointV2f32(pa, color);
                        pSelf.drawPointV2f32(pb, color);
                        pSelf.drawPointV2f32(pc, color);
                    },
                    RenderMode.Lines => {
                        const pa = pSelf.projectRetV2f32(va.coord, &transform_matrix);
                        const pb = pSelf.projectRetV2f32(vb.coord, &transform_matrix);
                        const pc = pSelf.projectRetV2f32(vc.coord, &transform_matrix);
                        if (DBG_RenderUsingModeInner) warn("pa={} pb={} pc={}\n", pa, pb, pc);

                        pSelf.drawBline(pa, pb, color);
                        pSelf.drawBline(pb, pc, color);
                        pSelf.drawBline(pc, pa, color);
                    },
                    RenderMode.Triangles => {
                        // Transform face.normal to world_to_view_matrix and only render
                        // faces which can be "seen" by the camera.
                        // Bugs: 1) See "rendering bug"
                        //          https://www.davrous.com/2013/07/18/tutorial-part-6-learning-how-to-write-a-3d-software-engine-in-c-ts-or-js-texture-mapping-back-face-culling-webgl
                        //          it says that perspective isn't being taken into account and some triangles are not drawn when they should be.
                        //
                        //       2) I have to "negate_tnz" tnz so the expected triangles are VISIBLE so "if (tnz < 0) {" works.
                        //          In the tutorial we have "if (transformedNormal < 0) {",
                        //          see: http://david.blob.core.windows.net/softengine3d/SoftEngineJSPart6Sample2.zip
                        var tnz = face.normal.transformNormal(&world_to_view_matrix).z();
                        tnz = if (negate_tnz) -tnz else tnz;
                        if (tnz < 0) {
                            if (DBG_RenderUsingModeInner) warn("VISIBLE face.normal:{} tnz:{}\n", &face.normal, &tnz);

                            // Transform the vertex's
                            const tva = pSelf.projectRetVertex(va, &transform_matrix, &world_matrix);
                            const tvb = pSelf.projectRetVertex(vb, &transform_matrix, &world_matrix);
                            const tvc = pSelf.projectRetVertex(vc, &transform_matrix, &world_matrix);

                            var colorF32: f32 = undefined;
                            //colorF32 = 0.25 + @intToFloat(f32, i % mesh.faces.len) * (0.75 / @intToFloat(f32, mesh.faces.len));
                            colorF32 = 1.0;
                            var colorU8: u8 = saturateCast(u8, math.round(colorF32 * 256.0));
                            color = ColorU8.init(colorU8, colorU8, colorU8, colorU8);
                            pSelf.drawTriangle(tva, tvb, tvc, color, entity.texture);
                            if (DBG_RenderUsingModeInner) warn("tva={} tvb={} tvc={} color={}\n", tva.coord, tvb.coord, tvc.coord, &color);
                        } else {
                            if (DBG_RenderUsingModeInner) warn("HIDDEN  face.normal:{} tnz:{}\n", &face.normal, &tnz);
                        }
                    },
                }
                if (DBG_RenderUsingModeWaitForKey) {
                    pSelf.present();
                    _ = ki.waitForKey("dt", true, DBG_RenderUsingModeWaitForKey);
                }
            }
        }
    }

    pub fn render(pSelf: *Self, camera: *const Camera, entities: []const Entity) void {
        renderUsingMode(pSelf, DBG_RenderMode, camera, entities, true);
    }
};
