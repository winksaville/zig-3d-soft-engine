const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;
const math = std.math;

const geo = @import("../modules/zig-geometry/index.zig");

const parseJsonFile = @import("parse_json_file.zig").parseJsonFile;

const json = @import("../modules/zig-json/json.zig");

const DBG = false;
const DBG1 = false;

pub const Face = struct {
    a: usize,
    b: usize,
    c: usize,
};

pub const Mesh = struct {
    const Self = @This();

    pub name: []const u8,
    pub position: geo.V3f32,
    pub rotation: geo.V3f32,
    pub vertices: []geo.V3f32,
    pub faces: []Face,

    pub fn init(pAllocator: *Allocator, name: []const u8, vertices_count: usize, faces_count: usize) !Self {
        return Self{
            .name = name,
            .position = geo.V3f32.init(0.0, 0.0, 0.0),
            .rotation = geo.V3f32.init(0.0, 0.0, 0.0),
            .vertices = try pAllocator.alloc(geo.V3f32, vertices_count),
            .faces = try pAllocator.alloc(Face, faces_count),
        };
    }

    pub fn initJson(pAllocator: *Allocator, name: []const u8, tree: json.ValueTree) !Self {
        var root = tree.root;

        var meshes = root.Object.get("meshes").?.value.Array;

        var positions = meshes.items[0].Object.get("positions").?.value.Array;
        if (DBG) warn("positions.len={}\n", positions.len);

        var normals = meshes.items[0].Object.get("normals").?.value.Array;
        if (DBG) warn("normals.len={}\n", normals.len);

        var indices = meshes.items[0].Object.get("indices").?.value.Array;
        if (DBG) warn("indices.len={}\n", indices.len);

        var vertices_count = positions.len / 3;
        var faces_count = indices.len / 3;
        if (DBG) warn("vertices_count={} faces_count={}\n", vertices_count, faces_count);

        var mesh = try Mesh.init(pAllocator, name, vertices_count, faces_count);

        var i: usize = 0;
        var pos_iter = positions.iterator();
        while (i < vertices_count) : (i += 1) {
            var x = try pos_iter.next().?.asFloat(f32);
            var y = try pos_iter.next().?.asFloat(f32);
            var z = try pos_iter.next().?.asFloat(f32);
            mesh.vertices[i] = geo.V3f32.init(x, y, z);
        }
        i = 0;
        var indicies_iter = indices.iterator();
        while (i < faces_count) : (i += 1) {
            var a = @intCast(usize, indicies_iter.next().?.Integer);
            var b = @intCast(usize, indicies_iter.next().?.Integer);
            var c = @intCast(usize, indicies_iter.next().?.Integer);
            if (DBG1) warn("face[{}]={{ .a={} .b={} .c={} }}\n", i, a, b, c);
            mesh.faces[i] = Face { .a=a, .b=b, .c=c };
        }

        return mesh;
    }
};

test "mesh" {
    if (DBG or DBG1) warn("\n");
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var mesh = try Mesh.init(pAllocator, "mesh1", 8, 12);
    assert(std.mem.eql(u8, mesh.name[0..], "mesh1"));
    assert(mesh.position.x() == 0.0);
    assert(mesh.position.data[1] == 0.0);
    assert(mesh.position.data[2] == 0.0);
    assert(mesh.rotation.data[0] == 0.0);
    assert(mesh.rotation.data[1] == 0.0);
    assert(mesh.rotation.data[2] == 0.0);

    // Unit cube about 0,0,0
    mesh.vertices[0] = geo.V3f32.init(-1, 1, 1);
    assert(mesh.vertices[0].x() == -1);
    assert(mesh.vertices[0].y() == 1);
    assert(mesh.vertices[0].z() == 1);
    mesh.vertices[1] = geo.V3f32.init(1, 1, 1);
    assert(mesh.vertices[1].x() == 1);
    assert(mesh.vertices[1].y() == 1);
    assert(mesh.vertices[1].z() == 1);
    mesh.vertices[2] = geo.V3f32.init(-1, -1, 1);
    assert(mesh.vertices[2].x() == -1);
    assert(mesh.vertices[2].y() == -1);
    assert(mesh.vertices[2].z() == 1);
    mesh.vertices[3] = geo.V3f32.init(1, -1, 1);
    assert(mesh.vertices[3].x() == 1);
    assert(mesh.vertices[3].y() == -1);
    assert(mesh.vertices[3].z() == 1);

    mesh.vertices[4] = geo.V3f32.init(-1, 1, -1);
    assert(mesh.vertices[4].x() == -1);
    assert(mesh.vertices[4].y() == 1);
    assert(mesh.vertices[4].z() == -1);
    mesh.vertices[5] = geo.V3f32.init(1, 1, -1);
    assert(mesh.vertices[5].x() == 1);
    assert(mesh.vertices[5].y() == 1);
    assert(mesh.vertices[5].z() == -1);
    mesh.vertices[6] = geo.V3f32.init(1, -1, -1);
    assert(mesh.vertices[6].x() == 1);
    assert(mesh.vertices[6].y() == -1);
    assert(mesh.vertices[6].z() == -1);
    mesh.vertices[7] = geo.V3f32.init(-1, -1, -1);
    assert(mesh.vertices[7].x() == -1);
    assert(mesh.vertices[7].y() == -1);
    assert(mesh.vertices[7].z() == -1);

    // The cube has 6 side each composed
    // of 2 trianglar faces on the side
    // for 12 faces;
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
}

test "mesh.suzanne" {
    if (DBG or DBG1) warn("\n");
    var file_name = "3d-objects/suzanne.babylon";
    var pAllocator = std.heap.c_allocator;
    var tree = try parseJsonFile(pAllocator, file_name);
    defer tree.deinit();

    var mesh = try Mesh.initJson(pAllocator, "suzanne", tree);
    assert(std.mem.eql(u8, mesh.name, "suzanne"));
    assert(mesh.vertices.len == 507);
    assert(mesh.faces.len == 968);
}
