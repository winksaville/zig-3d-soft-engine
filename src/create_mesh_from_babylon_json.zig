const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;

const geo = @import("../modules/zig-geometry/index.zig");
const json = @import("../modules/zig-json/json.zig");
const parseJsonFile = @import("../modules/zig-json/parse_json_file.zig").parseJsonFile;

const DBG = false;
const DBG1 = false;

pub fn createMeshFromBabylonJson(pAllocator: *Allocator, name: []const u8, tree: json.ValueTree) !geo.Mesh {
    var root = tree.root;

    var meshes = root.Object.get("meshes").?.value.Array;

    var positions = meshes.items[0].Object.get("positions").?.value.Array;
    if (DBG) warn("positions.len={}\n", positions.len);

    var normals = meshes.items[0].Object.get("normals").?.value.Array;
    if (DBG) warn("normals.len={}\n", normals.len);

    // If uvs isn't available then an empyt list
    var uvs = if (meshes.items[0].Object.get("uvs")) |pUvs| pUvs.value.Array else std.ArrayList(json.Value).init(pAllocator);
    if (DBG) warn("uvs.len={}\n", uvs.len);

    var indices = meshes.items[0].Object.get("indices").?.value.Array;
    if (DBG) warn("indices.len={}\n", indices.len);

    var vertices_count = positions.len / 3;
    var faces_count = indices.len / 3;
    if (DBG) warn("vertices_count={} faces_count={}\n", vertices_count, faces_count);

    var mesh = try geo.Mesh.init(pAllocator, name, vertices_count, faces_count);

    var i: usize = 0;
    var pos_iter = positions.iterator();
    var nrml_iter = normals.iterator();
    var uvs_iter = uvs.iterator();
    while (i < vertices_count) : (i += 1) {
        var x = try pos_iter.next().?.asFloat(f32);
        var y = try pos_iter.next().?.asFloat(f32);
        var z = try pos_iter.next().?.asFloat(f32);

        var nx = try nrml_iter.next().?.asFloat(f32);
        var ny = try nrml_iter.next().?.asFloat(f32);
        var nz = try nrml_iter.next().?.asFloat(f32);

        // Len of uvs maybe zero
        var u: f32 = if (uvs_iter.next()) |nu| try nu.asFloat(f32) else 0.0;
        var v: f32 = if (uvs_iter.next()) |nv| try nv.asFloat(f32) else 0.0;

        mesh.vertices[i] = geo.Vertex {
            .coord = geo.V3f32.init(x, y, z),
            .world_coord = geo.V3f32.init(0, 0, 0),
            .normal_coord = geo.V3f32.init(nx, ny, nz),
            .texture_coord = geo.V2f32.init(u, v),
        };
    }
    i = 0;
    var indicies_iter = indices.iterator();
    while (i < faces_count) : (i += 1) {
        // Get the indexes for a,b,c
        var a = @intCast(usize, indicies_iter.next().?.Integer);
        var b = @intCast(usize, indicies_iter.next().?.Integer);
        var c = @intCast(usize, indicies_iter.next().?.Integer);

        var normal = geo.computeFaceNormal(mesh.vertices, a, b, c);

        mesh.faces[i] = geo.Face { .a=a, .b=b, .c=c, .normal=normal };
        if (DBG1) warn("face[{}]={{ .a={} .b={} .c={} .normal={} }}\n", i, mesh.faces[i].a, mesh.faces[i].b, mesh.faces[i].c, mesh.faces[i].normal);
    }

    return mesh;
}

test "create_mesh_from_babylon_json.cube" {
    var file_name = "modules/3d-test-resources/cube.babylon";
    var pAllocator = std.heap.c_allocator;
    var tree = try parseJsonFile(pAllocator, file_name);
    defer tree.deinit();

    var mesh = try createMeshFromBabylonJson(pAllocator, "cube", tree);
    if (DBG) warn("mesh.vertices.len={} faces.len={}\n", mesh.vertices.len, mesh.faces.len);
    assert(mesh.vertices.len == 8);
    assert(mesh.faces.len == 12);
}

test "create_mesh_from_babylon_json.suzanne" {
    var file_name = "modules/3d-test-resources/suzanne.babylon";
    var pAllocator = std.heap.c_allocator;
    var tree = try parseJsonFile(pAllocator, file_name);
    defer tree.deinit();

    var mesh = try createMeshFromBabylonJson(pAllocator, "suzanne", tree);
    if (DBG) warn("mesh.vertices.len={} faces.len={}\n", mesh.vertices.len, mesh.faces.len);
    assert(mesh.vertices.len == 507);
    assert(mesh.faces.len == 968);
}
