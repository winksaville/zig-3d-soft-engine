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

const windowns = @import("window.zig");
const Entity = windowns.Entity;
const RenderMode = windowns.RenderMode;
const Window = windowns.Window;

const DBG = true;
const DBG1 = false;
const DBG2 = false;
const DBG3 = false;
const DBG_RenderUsingModeWaitForKey = false;
const DBG_Rotate = false;
const DBG_Translate = false;
const DBG_world_to_screen = false;
const DBG_drawToTexture = false;

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

const CHAR_SIZE: Zcint = 14; // 14 "points" for character size
const DPI: Zcint = 140;      // dots per inch of my display

fn fixed26_6(whole26: u26, frac6: u6) ft2.FT_F26Dot6 {
    return @intCast(ft2.FT_F26Dot6, (whole26 << 6) | frac6);
}

fn f64_fixed26_6(v: f64) ft2.FT_F26Dot6 {
    return @floatToInt(ft2.FT_F26Dot6, v * @intToFloat(f64, 0x40));
}

test "fixed26_6" {
    assert(0x40 == fixed26_6(1, 0));
    assert(fixed26_6(1, 0) == f64_fixed26_6(1.0));
    assert(fixed26_6(1, 0x20) == f64_fixed26_6(1.5));
    assert(fixed26_6(2, 0) == f64_fixed26_6(2));
}

fn fixed16_16(whole16: u16, frac16: u16) ft2.FT_Fixed {
    return @intCast(ft2.FT_Fixed, (@intCast(u32, whole16) << 16) | @intCast(u32, frac16));
}

fn f64_fixed16_16(v: f64) ft2.FT_Fixed {
    return @floatToInt(ft2.FT_Fixed, v * @intToFloat(f64, 0x10000));
}

test "fixed16_16" {
    assert(0x10000 == fixed16_16(1, 0));
    assert(fixed16_16(1, 0) == f64_fixed16_16(1.0));
    assert(fixed16_16(1, 0x8000) == f64_fixed16_16(1.5));
    assert(fixed16_16(2, 0) == f64_fixed16_16(2));
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

                // From http://web.comhem.se/~u34598116/content/FreeType2/main.html
                var ptr: *u8 = @intToPtr(*u8, @ptrToInt(bitmap.buffer.?) + idx);
                var opacity: f32 = @intToFloat(f32, ptr.*) / 255.0;
                var r: u8 = undefined;
                var g: u8 = undefined;
                var b: u8 = undefined;
                var c = background;
                if (opacity > 0) {
                    r = @floatToInt(u8, (@intToFloat(f32, color.r) * opacity) + ((f32(1.0) - opacity) * @intToFloat(f32, background.r)));
                    g = @floatToInt(u8, (@intToFloat(f32, color.g) * opacity) + ((f32(1.0) - opacity) * @intToFloat(f32, background.g)));
                    b = @floatToInt(u8, (@intToFloat(f32, color.b) * opacity) + ((f32(1.0) - opacity) * @intToFloat(f32, background.b)));
                    c = ColorU8.init(color.a, r, g, b);
                    if (DBG_drawToTexture) warn("<[{},{}]={.2}:{}> ", j, i, opacity, b);
                }
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

test "test-freetype2" {
    // Based on https://www.freetype.org/freetype2/docs/tutorial/example1.c
    if (DBG) warn("\n");

    // Init Window
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var window = try Window.init(pAllocator, 1024, 1024, "testWindow");
    defer window.deinit();

    // Create a plane to write on.
    var mesh = try Mesh.init(pAllocator, "square", 4, 2);
    defer mesh.deinit();
    assert(std.mem.eql(u8, mesh.name, "square"));
    assert(mesh.vertices.len == 4);
    assert(mesh.faces.len == 2);

    // Position and orient the Mesh
    mesh.position.set(0, 0, 0);
    mesh.rotation.set(0, 0, 0);

    // upside down triangle
    //-1,1    1,1
    //  _____
    // |    /|
    // |   / |
    // |  /  |
    // | /   |
    // |/    |
    //  _____
    // -1,-1  1,-1
    mesh.vertices[0] = Vertex.init(-1, 1, 0);
    mesh.vertices[1] = Vertex.init(1, 1, 0);
    mesh.vertices[2] = Vertex.init(-1, -1, 0);
    mesh.vertices[3] = Vertex.init(1, -1, 0);

    // Compute the normal for the face and since both faces
    // are in the same plane the normal is the same.
    var normal = geo.computeFaceNormal(mesh.vertices, 0, 1, 2);

    // Define the two faces and since this is a planeand the face normal is the same for both
    mesh.faces[0] = geo.Face.init(0, 1, 2, normal);
    mesh.faces[1] = geo.Face.init(1, 3, 2, normal);

    // In addition, since this is a plane all the vertice normals are the same as the face normal
    mesh.vertices[0].normal_coord = normal;
    mesh.vertices[1].normal_coord = normal;
    mesh.vertices[2].normal_coord = normal;
    mesh.vertices[3].normal_coord = normal;

    // The texture_coord is a unit square and we map to the two triangles
    // "L" and "R":
    // 0,0   1,0
    //  _____
    // |    /|
    // | L / |
    // |  /  |
    // | / R |
    // |/    |
    // _______
    // 0,1   1,1
    mesh.vertices[0].texture_coord = V2f32.init(0, 0); // -1, 1
    mesh.vertices[1].texture_coord = V2f32.init(1, 0); //  1, 1
    mesh.vertices[2].texture_coord = V2f32.init(0, 1); // -1,-1
    mesh.vertices[3].texture_coord = V2f32.init(1, 1); //  1,-1

    // Setup parameters

    // Filename for font
    const cfilename = c"modules/3d-test-resources/liberation-fonts-ttf-2.00.4/LiberationMono-Regular.ttf";

    // Convert Rotate angle in radians for font
    var angleInDegrees = f64(0.0);
    var angle = (angleInDegrees / 360.0) * math.pi * 2.0;

    // Text to display
    var text = "abcdefghijklmnopqrstuvwxyz";

    // Init FT library
    var pLibrary: ?*ft2.FT_Library = undefined;
    assert( ft2.FT_Init_FreeType( &pLibrary ) == 0);
    defer assert(ft2.FT_Done_FreeType(pLibrary) == 0);

    // Load a type face
    var pFace: ?*ft2.FT_Face = undefined;
    assert(ft2.FT_New_Face(pLibrary, cfilename, 0, &pFace) == 0);
    defer assert(ft2.FT_Done_Face(pFace) == 0);

    // Set character size
    assert(ft2.FT_Set_Char_Size(pFace, fixed26_6(CHAR_SIZE, 0), 0, DPI, DPI) == 0);

    // Setup matrix
    var matrix: ft2.FT_Matrix = undefined;
    matrix.xx = f64_fixed16_16(math.cos(angle));
    matrix.xy = f64_fixed16_16(-math.sin(angle));
    matrix.yx = f64_fixed16_16(math.sin(angle));
    matrix.yy = f64_fixed16_16(math.cos(angle));

    // Setup pen location
    var pen: ft2.FT_Vector = undefined;
    pen.x = f64_fixed26_6(5);   // x = 5 points from left side
    pen.y = f64_fixed26_6(CHAR_SIZE); // y = CHAR_SIZE in points from top

    // Create and Initialize texture
    var texture = try Texture.initPixels(pAllocator, 600, 600, ColorU8.White);

    // Loop to print characters to texture
    var slot: *ft2.FT_GlyphSlot = (pFace.?.glyph) orelse return error.NoGlyphSlot;
    var n: usize = 0;
    while (n < text.len) : (n += 1) {
        // Setup transform
        ft2.FT_Set_Transform(pFace, &matrix, &pen);

        // Load glyph image into slot
        assert(ft2.FT_Load_Char(pFace, text[n], ft2.FT_LOAD_RENDER) == 0);

        if (DBG) {
            warn("{c} position: left={} top={} width={} rows={} pitch={} adv_x={} hAdv={} hBearingX=={}\n",
                text[n], slot.bitmap_left, slot.bitmap_top, slot.bitmap.width, slot.bitmap.rows, slot.bitmap.pitch,
                slot.advance.x, slot.metrics.horiAdvance, slot.metrics.horiBearingX);
        }

        // Draw the character at top of texture
        var line_spacing: c_int = 50; // > Maximum "top" of character
        drawToTexture(&texture, &slot.bitmap, slot.bitmap_left, (6 * line_spacing) - slot.bitmap_top, ColorU8.Black, ColorU8.White);

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

    //showTexture(&window, &texture);

    // Render any entities but I do NOT need to negate_tnz
    window.renderUsingMode(RenderMode.Triangles, &camera, entities, false);
    window.present();

    if (DBG) {
        waitForEsc("Prese ESC to stop");
    }
}
