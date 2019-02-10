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

const ie = @import("input_events.zig");

const DBG = true;
const DBG1 = false;
const DBG2 = false;
const DBG3 = false;
const DBG_RenderUsingMode = false;
const DBG_RenderUsingModeInner = false;
const DBG_RenderUsingModeWaitForKey = false;
const DBG_PutPixel = false;
const DBG_Rotate = false;
const DBG_Translate = false;
const DBG_DrawTriangle = false;
const DBG_DrawTriangleInner = false;
const DBG_ProcessScanLine = false;
const DBG_ProcessScanLineInner = false;
const DBG_world_to_screen = false;
const DBG_drawToTexture = false;

const Entity = struct {
    mesh: Mesh,
    texture: ?Texture,
};

const RenderMode = enum {
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
                    _ = waitForKey("dt", true, DBG_RenderUsingModeWaitForKey);
                }
            }
        }
    }

    pub fn render(pSelf: *Self, camera: *const Camera, entities: []const Entity) void {
        renderUsingMode(pSelf, DBG_RenderMode, camera, entities, true);
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
    var color = ColorU8.init(0x01, 02, 03, 04);
    window.putPixel(0, 0, 0, color);
    assert(window.getPixel(0, 0) == color.asU32Argb());
}

test "window.projectRetV2f32" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 640, 480, "testWindow");
    defer window.deinit();

    var v1 = V3f32.init(0, 0, 0);
    var r = window.projectRetV2f32(v1, &geo.m44f32_unit);
    assert(r.x() == window.widthf / 2.0);
    assert(r.y() == window.heightf / 2.0);

    v1 = V3f32.init(-1.0, 1.0, 0);
    r = window.projectRetV2f32(v1, &geo.m44f32_unit);
    assert(r.x() == 0);
    assert(r.y() == 0);

    v1 = V3f32.init(1.0, -1.0, 0);
    r = window.projectRetV2f32(v1, &geo.m44f32_unit);
    assert(r.x() == window.widthf);
    assert(r.y() == window.heightf);

    v1 = V3f32.init(-1.0, -1.0, 0);
    r = window.projectRetV2f32(v1, &geo.m44f32_unit);
    assert(r.x() == 0);
    assert(r.y() == window.heightf);

    v1 = V3f32.init(1.0, 1.0, 0);
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

    var p1 = V2f32.init(0, 0);
    var color = ColorU8.init(0x80, 0x80, 0x80, 0x80);
    window.drawPointV2f32(p1, color);
    assert(window.getPixel(0, 0) == color.asU32Argb());

    p1 = V2f32.init(window.widthf / 2, window.heightf / 2);
    window.drawPointV2f32(p1, color);
    assert(window.getPixel(window.width / 2, window.height / 2) == color.asU32Argb());
}

test "window.projectRetVertex" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 640, 480, "testWindow");
    defer window.deinit();

    var v1 = Vertex.init(0, 0, 0);
    var r = window.projectRetVertex(v1, &geo.m44f32_unit, &geo.m44f32_unit);
    assert(r.coord.x() == window.widthf / 2.0);
    assert(r.coord.y() == window.heightf / 2.0);

    v1 = Vertex.init(-0.5, 0.5, 0);
    r = window.projectRetVertex(v1, &geo.m44f32_unit, &geo.m44f32_unit);
    assert(r.coord.x() == 0);
    assert(r.coord.y() == 0);

    v1 = Vertex.init(0.5, -0.5, 0);
    r = window.projectRetVertex(v1, &geo.m44f32_unit, &geo.m44f32_unit);
    assert(r.coord.x() == window.widthf);
    assert(r.coord.y() == window.heightf);

    v1 = Vertex.init(-0.5, -0.5, 0);
    r = window.projectRetVertex(v1, &geo.m44f32_unit, &geo.m44f32_unit);
    assert(r.coord.x() == 0);
    assert(r.coord.y() == window.heightf);

    v1 = Vertex.init(0.5, 0.5, 0);
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

    var point1 = V2f32.init(1, 1);
    var point2 = V2f32.init(4, 4);
    var color = ColorU8.init(0x80, 0x80, 0x80, 0x80);
    window.drawLine(point1, point2, color);
    assert(window.getPixel(1, 1) == color.asU32Argb());
    assert(window.getPixel(2, 2) == color.asU32Argb());
    assert(window.getPixel(3, 3) == color.asU32Argb());
}

test "window.world.to.screen" {
    if (DBG_world_to_screen) warn("\n");
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
    var camera_position = V3f32.init(0, 0, 2);
    var camera_target = V3f32.initVal(0);
    var camera = Camera.init(camera_position, camera_target);

    var window = try Window.init(pAllocator, width, height, "testWindow");
    defer window.deinit();

    var view_to_perspective_matrix = geo.perspectiveM44(f32, geo.rad(fov), aspect, znear, zfar);
    if (DBG_world_to_screen) warn("view_to_perspective_matrix=\n{}\n", view_to_perspective_matrix);

    var world_to_view_matrix: geo.M44f32 = undefined;

    world_to_view_matrix = geo.lookAtRh(&camera.position, &camera.target, &V3f32.unitY());
    world_to_view_matrix = geo.m44f32_unit;
    world_to_view_matrix.data[3][2] = 2;
    if (DBG_world_to_screen) warn("world_to_view_matrix=\n{}\n", world_to_view_matrix);

    var world_vertexs = []V3f32{
        V3f32.init(0, 1, 0),
        V3f32.init(-1, -1, 0),
        V3f32.init(0.5, -0.5, 0),
    };
    var expected_view_vertexs = []V3f32{
        V3f32.init(0, 1, 2),
        V3f32.init(-1, -1, 2),
        V3f32.init(0.5, -0.5, 2),
    };
    var expected_projected_vertexs = []V3f32{
        V3f32.init(0, 0.5, 1.00505),
        V3f32.init(-0.5, -0.5, 1.00505),
        V3f32.init(0.25, -0.25, 1.00505),
    };
    var expected_screen_vertexs = [][2]u32{
        []u32{ 256, 128 },
        []u32{ 128, 384 },
        []u32{ 320, 320 },
    };

    // Loop until end_time is reached but always loop once :)
    var msf: u64 = time.ns_per_s / time.ms_per_s;
    var timer = try time.Timer.start();
    var end_time: u64 = 0;
    if (DBG_world_to_screen) end_time += (4000 * msf);

    while (true) {
        window.clear();

        for (world_vertexs) |world_vert, i| {
            if (DBG_world_to_screen) warn("world_vert[{}]  = {}\n", i, &world_vert);

            var view_vert = world_vert.transform(&world_to_view_matrix);
            if (DBG_world_to_screen) warn("view_vert      = {}\n", view_vert);
            assert(view_vert.approxEql(&expected_view_vertexs[i], 5));

            var projected_vert = view_vert.transform(&view_to_perspective_matrix);
            if (DBG_world_to_screen) warn("projected_vert = {}\n", projected_vert);
            assert(projected_vert.approxEql(&expected_projected_vertexs[i], 5));

            var point = window.projectRetV2f32(projected_vert, &geo.m44f32_unit);

            var color = ColorU8.init(0xff, 0xff, 00, 0xff);
            window.drawPointV2f32(point, color);
            assert(window.getPixel(expected_screen_vertexs[i][0], expected_screen_vertexs[i][1]) == color.asU32Argb());
        }

        var center = V2f32.init(window.widthf / 2, window.heightf / 2);
        window.drawPointV2f32(center, ColorU8.White);

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
    defer mesh.deinit();

    // Unit cube about 0,0,0
    mesh.vertices[0] = Vertex.init(-1, 1, 1);
    mesh.vertices[1] = Vertex.init(-1, -1, 1);
    mesh.vertices[2] = Vertex.init(1, -1, 1);
    mesh.vertices[3] = Vertex.init(1, 1, 1);

    mesh.vertices[4] = Vertex.init(-1, 1, -1);
    mesh.vertices[5] = Vertex.init(-1, -1, -1);
    mesh.vertices[6] = Vertex.init(1, -1, -1);
    mesh.vertices[7] = Vertex.init(1, 1, -1);

    // 12 faces
    mesh.faces[0] = Face{ .a = 0, .b = 1, .c = 2, .normal = undefined };
    mesh.faces[1] = Face{ .a = 0, .b = 2, .c = 3, .normal = undefined };
    mesh.faces[2] = Face{ .a = 3, .b = 2, .c = 6, .normal = undefined };
    mesh.faces[3] = Face{ .a = 3, .b = 6, .c = 7, .normal = undefined };
    mesh.faces[4] = Face{ .a = 7, .b = 6, .c = 5, .normal = undefined };
    mesh.faces[5] = Face{ .a = 7, .b = 5, .c = 4, .normal = undefined };

    mesh.faces[6] = Face{ .a = 4, .b = 5, .c = 1, .normal = undefined };
    mesh.faces[7] = Face{ .a = 4, .b = 1, .c = 0, .normal = undefined };
    mesh.faces[8] = Face{ .a = 0, .b = 3, .c = 4, .normal = undefined };
    mesh.faces[9] = Face{ .a = 3, .b = 7, .c = 4, .normal = undefined };
    mesh.faces[10] = Face{ .a = 1, .b = 6, .c = 2, .normal = undefined };
    mesh.faces[11] = Face{ .a = 1, .b = 5, .c = 6, .normal = undefined };

    var entity = Entity {
        .texture = null,
        .mesh = mesh,
    };
    var entities = []Entity { entity };

    var movement = V3f32.init(0.01, 0.01, 0); // Small amount of movement

    var camera_position = V3f32.init(0, 0, -5);
    var camera_target = V3f32.initVal(0);
    var camera = Camera.init(camera_position, camera_target);

    // Loop until end_time is reached but always loop once :)
    var ms_factor: u64 = time.ns_per_s / time.ms_per_s;
    var timer = try time.Timer.start();
    var end_time: u64 = if (DBG or DBG1 or DBG2) (5000 * ms_factor) else (100 * ms_factor);
    while (true) {
        window.clear();

        if (DBG1) warn("rotation={.5}:{.5}:{.5}\n", entities[0].mesh.rotation.x(), entities[0].mesh.rotation.y(), entities[0].mesh.rotation.z());
        window.render(&camera, entities);

        var center = V2f32.init(window.widthf / 2, window.heightf / 2);
        window.drawPointV2f32(center, ColorU8.White);

        window.present();

        entities[0].mesh.rotation = entities[0].mesh.rotation.add(&movement);

        if (timer.read() > end_time) break;
    }
}


test "window.keyctrl.triangle" {
    if (DBG) {
        var direct_allocator = std.heap.DirectAllocator.init();
        var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
        defer arena_allocator.deinit();
        var pAllocator = &arena_allocator.allocator;

        var window = try Window.init(pAllocator, 1000, 1000, "testWindow");
        defer window.deinit();

        // Black background color
        window.setBgColor(ColorU8.Black);

        // Triangle
        var mesh: Mesh = try Mesh.init(pAllocator, "triangle", 3, 1);
        defer mesh.deinit();
        mesh.vertices[0] = Vertex.init(0, 1, 0);
        mesh.vertices[1] = Vertex.init(-1, -1, 0);
        mesh.vertices[2] = Vertex.init(0.5, -0.5, 0);

        mesh.faces[0] = Face.initComputeNormal(mesh.vertices, 0, 1, 2);

        var entities = []Entity{
            Entity{
                .texture = null,
                .mesh = mesh,
            },
        };
        keyCtrlEntities(&window, RenderMode.Points, entities[0..]);
    }
}

test "window.keyctrl.cube" {
    if (DBG) {
        var direct_allocator = std.heap.DirectAllocator.init();
        var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
        defer arena_allocator.deinit();
        var pAllocator = &arena_allocator.allocator;

        var window = try Window.init(pAllocator, 1000, 1000, "render.cube");
        defer window.deinit();

        var file_name = "modules/3d-test-resources/cube.babylon";
        var tree = try parseJsonFile(pAllocator, file_name);
        defer tree.deinit();

        var mesh = try createMeshFromBabylonJson(pAllocator, "cube", tree);
        defer mesh.deinit();
        assert(std.mem.eql(u8, mesh.name, "cube"));

        var entities = []Entity{
            Entity{
                .texture = null,
                .mesh = mesh,
            },
        };
        keyCtrlEntities(&window, RenderMode.Points, entities[0..]);
    }
}

test "window.keyctrl.pyramid" {
    if (DBG) {
        warn("\n");
        var direct_allocator = std.heap.DirectAllocator.init();
        var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
        defer arena_allocator.deinit();
        var pAllocator = &arena_allocator.allocator;

        var window = try Window.init(pAllocator, 1000, 1000, "testWindow");
        defer window.deinit();

        // Black background color
        window.setBgColor(ColorU8.Black);

        var file_name = "modules/3d-test-resources/pyramid.babylon";
        var tree = try parseJsonFile(pAllocator, file_name);
        defer tree.deinit();

        var mesh = try createMeshFromBabylonJson(pAllocator, "pyramid", tree);
        defer mesh.deinit();
        assert(std.mem.eql(u8, mesh.name, "pyramid"));

        var texture = Texture.init(pAllocator);
        defer texture.deinit();
        try texture.loadFile("modules/3d-test-resources/bricks2.jpg");

        var entities = []Entity{
            Entity{
                .texture = texture, //null,
                .mesh = mesh,
            },
        };
        keyCtrlEntities(&window, RenderMode.Triangles, entities[0..]);
    }
}

test "window.keyctrl.tilted.pyramid" {
    if (DBG) {
        var direct_allocator = std.heap.DirectAllocator.init();
        var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
        defer arena_allocator.deinit();
        var pAllocator = &arena_allocator.allocator;

        var window = try Window.init(pAllocator, 1000, 1000, "testWindow");
        defer window.deinit();

        // Black background color
        window.setBgColor(ColorU8.Black);

        var file_name = "modules/3d-test-resources/tilted-pyramid.babylon";
        var tree = try parseJsonFile(pAllocator, file_name);
        defer tree.deinit();

        var mesh = try createMeshFromBabylonJson(pAllocator, "pyramid", tree);
        defer mesh.deinit();
        assert(std.mem.eql(u8, mesh.name, "pyramid"));

        var entities = []Entity{
            Entity{
                .texture = null,
                .mesh = mesh,
            },
        };
        keyCtrlEntities(&window, RenderMode.Triangles, entities[0..]);
    }
}

test "window.keyctrl.suzanne" {
    if (DBG) {
        var direct_allocator = std.heap.DirectAllocator.init();
        var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
        defer arena_allocator.deinit();
        var pAllocator = &arena_allocator.allocator;

        var window = try Window.init(pAllocator, 1000, 1000, "testWindow");
        defer window.deinit();

        // Black background color
        window.setBgColor(ColorU8.Black);

        var file_name = "modules/3d-test-resources/suzanne.babylon";
        var tree = try parseJsonFile(pAllocator, file_name);
        defer tree.deinit();

        var mesh = try createMeshFromBabylonJson(pAllocator, "suzanne", tree);
        defer mesh.deinit();
        assert(std.mem.eql(u8, mesh.name, "suzanne"));
        assert(mesh.vertices.len == 507);
        assert(mesh.faces.len == 968);

        var entities = []Entity{
            Entity{
                .texture = null,
                .mesh = mesh,
            },
        };
        keyCtrlEntities(&window, RenderMode.Triangles, entities[0..]);
    }
}

const KeyState = struct {
    new_key: bool,
    code: gl.SDL_Keycode,
    mod: u16,
    ei: ie.EventInterface,
};

fn rotate(mod: u16, angles: V3f32, val: f32) V3f32 {
    var r = geo.rad(val);
    if (DBG_Rotate) warn("rotate: mod={x} angles={} rad(val)={}\n", mod, angles, r);
    var new_angles = angles;
    if ((mod & gl.KMOD_LCTRL) != 0) {
        new_angles = new_angles.add(&V3f32.init(r, 0, 0));
        if (DBG_Rotate) warn("rotate: add X\n");
    }
    if ((mod & gl.KMOD_LSHIFT) != 0) {
        new_angles = new_angles.add(&V3f32.init(0, r, 0));
        if (DBG_Rotate) warn("rotate: add Y\n");
    }
    if ((mod & gl.KMOD_RCTRL) != 0) {
        new_angles = new_angles.add(&V3f32.init(0, 0, r));
        if (DBG_Rotate) warn("rotate: add Z\n");
    }
    if (DBG_Rotate and !angles.approxEql(&new_angles, 4)) {
        warn("rotate: new_angles={}\n", new_angles);
    }
    return new_angles;
}

fn translate(mod: u16, pos: V3f32, val: f32) V3f32 {
    if (DBG_Translate) warn("translate: pos={}\n", pos);
    var new_pos = pos;
    if ((mod & gl.KMOD_LCTRL) != 0) {
        new_pos = pos.add(&V3f32.init(val, 0, 0));
        if (DBG_Translate) warn("translate: add X\n");
    }
    if ((mod & gl.KMOD_LSHIFT) != 0) {
        new_pos = pos.add(&V3f32.init(0, val, 0));
        if (DBG_Translate) warn("translate: add Y\n");
    }
    if ((mod & gl.KMOD_RCTRL) != 0) {
        new_pos = pos.add(&V3f32.init(0, 0, val));
        if (DBG_Translate) warn("translate: add Z\n");
    }
    if (DBG_Translate and !pos.eql(&new_pos)) {
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

var g_ks = KeyState{
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

/// Wait for a key
fn waitForKey(s: []const u8, exitOnEscape: bool, debug: bool) *KeyState {
    if (debug) warn("{}, waiting for key: ...", s);

    g_ks.new_key = false;
    while (g_ks.new_key == false) {
        _ = ie.pollInputEvent(&g_ks, &g_ks.ei);
    }

    if (debug) warn(" g_ks.mod={} g_ks.code={}\n", g_ks.mod, g_ks.code);

    if (g_ks.code == gl.SDLK_ESCAPE) if (exitOnEscape) std.os.exit(1);

    return &g_ks;
}

/// Wait for Esc key
fn waitForEsc(s: []const u8) void {
    done: while (DBG) {
        // Wait for a key
        var ks = waitForKey(s, false, true);

        // Stop if ESCAPE
        switch (ks.code) {
            gl.SDLK_ESCAPE => break :done,
            else => {},
        }
    }
}

fn keyCtrlEntities(pWindow: *Window, renderMode: RenderMode, entities: []Entity) void {
    const FocusType = enum {
        Camera,
        Object,
    };
    var focus = FocusType.Object;

    var camera_position = V3f32.init(0, 0, -5);
    var camera_target = V3f32.init(0, 0, 0);
    var camera = Camera.init(camera_position, camera_target);

    done: while (true) {
        // Update the display
        pWindow.clear();

        var center = V2f32.init(pWindow.widthf / 2, pWindow.heightf / 2);
        pWindow.drawPointV2f32(center, ColorU8.White);
        if (DBG_RenderUsingModeWaitForKey) {
            pWindow.present();
        }

        if (DBG1) warn("camera={}\n", &camera.position);
        if (DBG1) warn("rotation={}\n", entities[0].mesh.rotation);
        pWindow.renderUsingMode(renderMode, &camera, entities[0..], true);

        pWindow.present();

        // Wait for a key
        var ks = waitForKey("keyCtrlEntities", false, false);

        // Process the key

        // Check if changing focus
        switch (ks.code) {
            gl.SDLK_ESCAPE => break :done,
            gl.SDLK_c => { focus = FocusType.Camera; if (DBG) warn("focus = Camera"); },
            gl.SDLK_o => { focus = FocusType.Object; if (DBG) warn("focus = Object"); },
            else => {},
        }

        if (focus == FocusType.Object) {
            // Process for Object
            switch (ks.code) {
                gl.SDLK_LEFT => entities[0].mesh.rotation = rotate(ks.mod, entities[0].mesh.rotation, f32(15)),
                gl.SDLK_RIGHT => entities[0].mesh.rotation = rotate(ks.mod, entities[0].mesh.rotation, -f32(15)),
                gl.SDLK_UP => entities[0].mesh.position = translate(ks.mod, entities[0].mesh.position, f32(1)),
                gl.SDLK_DOWN => entities[0].mesh.position = translate(ks.mod, entities[0].mesh.position, -f32(1)),
                else => {},
            }
        }
            
        if (focus == FocusType.Camera) {
            // Process for Camera
            switch (ks.code) {
                gl.SDLK_LEFT => camera.target = rotate(ks.mod, camera.target, f32(15)),
                gl.SDLK_RIGHT => camera.target = rotate(ks.mod, camera.target, -f32(15)),
                gl.SDLK_UP => camera.position = translate(ks.mod, camera.position, f32(1)),
                gl.SDLK_DOWN => camera.position = translate(ks.mod, camera.position, -f32(1)),
                else => {},
            }
        }
    }
}

test "window.bm.suzanne" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 1000, 1000, "testWindow");
    defer window.deinit();

    // Black background color
    window.setBgColor(ColorU8.Black);

    var file_name = "modules/3d-test-resources/suzanne.babylon";
    var tree = try parseJsonFile(pAllocator, file_name);
    defer tree.deinit();

    var mesh = try createMeshFromBabylonJson(pAllocator, "suzanne", tree);
    defer mesh.deinit();
    assert(std.mem.eql(u8, mesh.name, "suzanne"));
    assert(mesh.vertices.len == 507);
    assert(mesh.faces.len == 968);

    var durationInMs: u64 = 1000;
    var entities = []Entity{
        Entity{
            .texture = null,
            .mesh = mesh,
        },
    };
    var loops = try timeRenderer(&window, durationInMs, RenderMode.Triangles, entities[0..]);

    var fps: f32 = @intToFloat(f32, loops * time.ms_per_s) / @intToFloat(f32, durationInMs);
    warn("\nwindow.bm.suzanne: fps={.5}\n", fps);
}

fn timeRenderer(pWindow: *Window, durationInMs: u64, renderMode: RenderMode, entities: []Entity) !u64 {
    var camera_position = V3f32.init(0, 0, -5);
    var camera_target = V3f32.init(0, 0, 0);
    var camera = Camera.init(camera_position, camera_target);

    // Loop until end_time is reached but always loop once :)
    var msf: u64 = time.ns_per_s / time.ms_per_s;
    var timer = try time.Timer.start();
    var end_time: u64 = timer.read() + (durationInMs * msf);

    var loops: u64 = 0;
    while (true) {
        loops = loops + 1;

        // Render into a cleared screen
        pWindow.clear();
        pWindow.renderUsingMode(renderMode, &camera, entities[0..], true);

        // Disable presenting as it limits framerate
        //pWindow.present();

        // Rotate entities[0] around Y axis
        var rotation = geo.degToRad(f32(1));
        var rotationVec = V3f32.init(0, rotation, 0);
        entities[0].mesh.rotation = entities[0].mesh.rotation.add(&rotationVec);

        if (timer.read() > end_time) break;
    }

    return loops;
}

const ft2 = @import("../modules/zig-freetype2/freetype2.zig");

fn mapCtoZigTypeFloat(comptime T: type) type {
    return switch (@sizeOf(T)) {
        2 => f16,
        4 => f32,
        8 => f64,
        else => @compileError("Unsupported float type"),
    };
}

fn mapCtoZigTypeInt(comptime T: type) type {
    if (T.is_signed) {
        return switch (@sizeOf(T)) {
            1 => i8,
            2 => i16,
            4 => i32,
            8 => i64,
            else => @compileError("Unsupported signed integer type"),
        };
    } else {
        return switch (@sizeOf(T)) {
            1 => u8,
            2 => u16,
            4 => u32,
            8 => u64,
            else => @compileError("Unsupported unsigned integer type"),
        };
    }
}

pub fn mapCtoZigType(comptime T: type) type {
    return switch (@typeId(T)) {
        TypeId.Int => mapCtoZigTypeInt(T),
        TypeId.Float => mapCtoZigTypeFloat(T),
        else => @compileError("Only TypeId.Int and TypeId.Float are supported"),
    };
}

const Zcint = c_int; // mapCtoZigType(c_int);

const POINTS: Zcint = 64;    // 64 points i.e. 1/64 of inch
const CHAR_SIZE: Zcint = 20;       // 20 "points" for character size 20/64 of inch
const DPI: Zcint = 100;      // dots per inch

const WIDTH: Zcint =  128;  // image width
const HEIGHT: Zcint = 64;   // image height

fn scaledInt(comptime IntType: type, v: f64, scale: IntType) IntType {
     return @floatToInt(IntType, v * @intToFloat(f64, scale));
}

fn drawToTexture(texture: *Texture, bitmap: *ft2.FT_Bitmap, x: Zcint, y: Zcint, color: ColorU8, background: ColorU8) void {
    var i: Zcint = 0;
    var j: Zcint = 0;
    var p: Zcint = 0;
    var q: Zcint = 0;
    var glyph_width: Zcint = @intCast(Zcint, bitmap.width);
    var glyph_height: Zcint = @intCast(Zcint, bitmap.rows);
    var x_max: Zcint = x + glyph_width;
    var y_max: Zcint = y + glyph_height;
    if (DBG_drawToTexture) warn("drawToTexture: x={} y={} x_max={} y_max={} glyph_width={} glyph_height={} buffer={*}\n",
        x, y, x_max, y_max, glyph_width, glyph_height, bitmap.buffer);

    i = x;
    p = 0;
    while (i < x_max) {
        j = y;
        q = 0;
        while (j < y_max) {
            if ((i >= 0) and (j >= 0) and (i < @intCast(c_int, texture.width)) and (j < @intCast(c_int, texture.height))) {
                var idx: usize = @intCast(usize, (q * glyph_width) + p);
                if (bitmap.buffer == null) return;
                var ptr: *u8 = @intToPtr(*u8, @ptrToInt(bitmap.buffer.?) + idx);
                var grey: f32 = @intToFloat(f32, ptr.*) / 255.0;
                var r: u8 = undefined;
                var g: u8 = undefined;
                var b: u8 = undefined;
                var c = background;
                if (grey > 0) {
                    r = @floatToInt(u8, @intToFloat(f32, color.r) * grey);
                    g = @floatToInt(u8, @intToFloat(f32, color.g) * grey);
                    b = @floatToInt(u8, @intToFloat(f32, color.b) * grey);
                    c = ColorU8.init(color.a, r, g, b);
                }
                if (DBG_drawToTexture) warn("<{p}={.1} {},{}={}> ", ptr, grey, j, i, b);
                texture.pixels.?[(@intCast(usize, j) * texture.width) + @intCast(usize, i)] = c;
            }
            j += 1;
            q += 1;
        }
        if (DBG_drawToTexture) warn("\n");

        i += 1;
        p += 1;
    }
}

fn showTexture(window: *Window, texture: *Texture) void {
    var y: usize = 0;
    while (y < texture.height) : (y += 1) {
        var x: usize = 0;
        while (x < texture.width) : (x += 1) {
            var color = texture.pixels.?[(@intCast(usize, y) * texture.width) + @intCast(usize, x)];
            window.drawPointXy(@intCast(isize, x), @intCast(isize, y), color);
        }
    }

    window.present();
}

test "test-freetype2.show" {
    if (DBG) warn("\n");

    // Init Window
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 512, 512, "testWindow");
    defer window.deinit();

    var file_name = "modules/3d-test-resources/unit-plane.babylon";
    var tree = try parseJsonFile(pAllocator, file_name);
    defer tree.deinit();

    var mesh = try createMeshFromBabylonJson(pAllocator, "unit-plane", tree);
    defer mesh.deinit();
    assert(std.mem.eql(u8, mesh.name, "unit-plane"));

    // Setup parameters

    // Filename for font
    const cfilename = c"modules/3d-test-resources/liberation-fonts-ttf-2.00.4/LiberationSans-Regular.ttf";

    // Convert Rotate angle in radians for font
    var angleInDegrees = f64(0.0);
    var angle = (angleInDegrees / 360.0) * math.pi * 2.0;

    // Text to display
    var text = "pinky";

    // Init FT library
    var pLibrary: ?*ft2.FT_Library = undefined;
    assert( ft2.FT_Init_FreeType( &pLibrary ) == 0);
    defer assert(ft2.FT_Done_FreeType(pLibrary) == 0);

    // Load a type face
    var pFace: ?*ft2.FT_Face = undefined;
    assert(ft2.FT_New_Face(pLibrary, cfilename, 0, &pFace) == 0);
    defer assert(ft2.FT_Done_Face(pFace) == 0);

    // Set character size
    assert(ft2.FT_Set_Char_Size(pFace, CHAR_SIZE * POINTS, 0, DPI, 0) == 0);

    // Setup matrix
    var matrix: ft2.FT_Matrix = undefined;
    matrix.xx = scaledInt(ft2.FT_Fixed, math.cos(angle), 0x10000);
    matrix.xy = scaledInt(ft2.FT_Fixed, -math.sin(angle), 0x10000);
    matrix.yx = scaledInt(ft2.FT_Fixed, math.sin(angle), 0x10000);
    matrix.yy = scaledInt(ft2.FT_Fixed, math.cos(angle), 0x10000);

    // Setup pen location
    var pen: ft2.FT_Vector = undefined;
    pen.x = 10 * POINTS;
    pen.y = 10 * POINTS;

    // Create and Initialize image
    var texture = try Texture.initPixels(pAllocator, WIDTH, HEIGHT, ColorU8.Black);

    // Loop to print characters to texture
    var slot: *ft2.FT_GlyphSlot = (pFace.?.glyph) orelse return error.NoGlyphSlot;
    var n: usize = 0;
    while (n < text.len) : (n += 1) {
        // Setup transform
        ft2.FT_Set_Transform(pFace, &matrix, &pen);

        // Load glyph image into slot
        assert(ft2.FT_Load_Char(pFace, text[n], ft2.FT_LOAD_RENDER) == 0);

        // Draw the character
        drawToTexture(&texture, &slot.bitmap, slot.bitmap_left, @intCast(c_int, texture.height) - slot.bitmap_top, ColorU8.Blue, ColorU8.Black);

        // Move the pen
        pen.x += slot.advance.x;
        pen.y += slot.advance.y;
    }

    // Setup camera
    var camera_position = V3f32.init(0, 0, -5);
    var camera_target = V3f32.initVal(0);
    var camera = Camera.init(camera_position, camera_target);

    // Black background color
    window.setBgColor(ColorU8.Black);
    window.clear();

    var entity = Entity {
        .texture = null,
        .mesh = mesh,
    };
    var entities = []Entity { entity };

    // Show
    showTexture(&window, &texture);

    if (DBG) {
        waitForEsc("Prese ESC to stop");
    }
}

test "test-freetype2.triangle" {
    if (DBG) warn("\n");

    // Init Window
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 512, 512, "testWindow");
    defer window.deinit();

    var file_name = "modules/3d-test-resources/unit-plane.babylon";
    var tree = try parseJsonFile(pAllocator, file_name);
    defer tree.deinit();

    // Create a piece of paper to write on.
    var mesh = try Mesh.init(pAllocator, "triangle", 3, 1);
    defer mesh.deinit();
    assert(std.mem.eql(u8, mesh.name, "triangle"));
    assert(mesh.vertices.len == 3);
    assert(mesh.faces.len == 1);

    // Centered at 0
    mesh.position.set(0, 0, 0);
    mesh.rotation.set(0, 0, 0);

    // upside down triangle
    // ------
    // \    /
    //  \  /
    //   \/
    mesh.vertices[0] = Vertex.init(-1, 1, 0);
    mesh.vertices[1] = Vertex.init(1, 1, 0);
    mesh.vertices[2] = Vertex.init(0, -1, 0);
    var face = geo.Face.init(0, 1, 2, geo.computeFaceNormal(mesh.vertices, 0, 1, 2));
    mesh.faces[0] = face;

    // Since this is a plane the normal for each vertex is the face normal
    mesh.vertices[0].normal_coord = face.normal;
    mesh.vertices[1].normal_coord = face.normal;
    mesh.vertices[2].normal_coord = face.normal;

    // The texture_coord will be the same as the coord
    mesh.vertices[0].texture_coord = V2f32.init(0, 0);
    mesh.vertices[1].texture_coord = V2f32.init(0, 1);
    mesh.vertices[2].texture_coord = V2f32.init(0.5, 1);

    // Setup parameters

    // Filename for font
    const cfilename = c"modules/3d-test-resources/liberation-fonts-ttf-2.00.4/LiberationSans-Regular.ttf";

    // Convert Rotate angle in radians for font
    var angleInDegrees = f64(0.0);
    var angle = (angleInDegrees / 360.0) * math.pi * 2.0;

    // Text to display
    var text = "pinky";

    // Init FT library
    var pLibrary: ?*ft2.FT_Library = undefined;
    assert( ft2.FT_Init_FreeType( &pLibrary ) == 0);
    defer assert(ft2.FT_Done_FreeType(pLibrary) == 0);

    // Load a type face
    var pFace: ?*ft2.FT_Face = undefined;
    assert(ft2.FT_New_Face(pLibrary, cfilename, 0, &pFace) == 0);
    defer assert(ft2.FT_Done_Face(pFace) == 0);

    // Set character size
    assert(ft2.FT_Set_Char_Size(pFace, CHAR_SIZE * POINTS, 0, DPI, 0) == 0);

    // Setup matrix
    var matrix: ft2.FT_Matrix = undefined;
    matrix.xx = scaledInt(ft2.FT_Fixed, math.cos(angle), 0x10000);
    matrix.xy = scaledInt(ft2.FT_Fixed, -math.sin(angle), 0x10000);
    matrix.yx = scaledInt(ft2.FT_Fixed, math.sin(angle), 0x10000);
    matrix.yy = scaledInt(ft2.FT_Fixed, math.cos(angle), 0x10000);

    // Setup pen location
    var pen: ft2.FT_Vector = undefined;
    pen.x = 5 * POINTS;   // x = 5 * POINTS to move pen in from "left" side.
    pen.y = CHAR_SIZE * POINTS; // y = CHAR_SIZE * POINTS to move pen to "bottom" of character

    // Create and Initialize image
    var texture = try Texture.initPixels(pAllocator, WIDTH, HEIGHT, ColorU8.White);

    // Loop to print characters to texture
    var slot: *ft2.FT_GlyphSlot = (pFace.?.glyph) orelse return error.NoGlyphSlot;
    var n: usize = 0;
    while (n < text.len) : (n += 1) {
        // Setup transform
        ft2.FT_Set_Transform(pFace, &matrix, &pen);

        // Load glyph image into slot
        assert(ft2.FT_Load_Char(pFace, text[n], ft2.FT_LOAD_RENDER) == 0);

        if (DBG) warn("{c} position: left={} top={} width={} rows={} pitch={}\n", text[n], slot.bitmap_left, slot.bitmap_top, slot.bitmap.width, slot.bitmap.rows, slot.bitmap.pitch);
        // Draw the character at top of texture
        var char_top_max: c_int = 40; // Maximum "top" of character
        drawToTexture(&texture, &slot.bitmap, slot.bitmap_left, char_top_max - slot.bitmap_top, ColorU8.Blue, ColorU8.White);
        // Draw the character at bottom of texture
        //drawToTexture(&texture, &slot.bitmap, slot.bitmap_left, @intCast(c_int, texture.height) - slot.bitmap_top, ColorU8.Blue, ColorU8.White);

        // Move the pen
        pen.x += slot.advance.x;
        pen.y += slot.advance.y;
    }

    // Setup camera
    var camera_position = V3f32.init(0, 0, -5);
    var camera_target = V3f32.initVal(0);
    var camera = Camera.init(camera_position, camera_target);

    // background color
    window.setBgColor(ColorU8.Black);
    window.clear();

    var entity = Entity {
        .texture = texture,
        .mesh = mesh,
    };
    var entities = []Entity { entity };

    showTexture(&window, &texture);

    // Render any entities but I do NOT need to negate_tnz
    window.renderUsingMode(RenderMode.Triangles, &camera, entities, false);
    window.present();

    if (DBG) {
        waitForEsc("Prese ESC to stop");
    }
}
