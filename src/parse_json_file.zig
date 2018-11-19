const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;

const os = std.os;
const File = os.File;

const json = @import("../modules/zig-json/json.zig");

const meshns = @import("mesh.zig");
const Mesh = meshns.Mesh;
const Face = meshns.Face;

const geo = @import("../modules/zig-geometry/index.zig");


const DBG = true;

pub fn parseJsonFile(pAllocator: *Allocator, file_name: []const u8) !json.ValueTree {
    var contents = try readFile(pAllocator, file_name);
    if (!json.validate(contents)) return error.InvalidJsonFile;
    var parser = json.Parser.init(pAllocator, false);
    return try parser.parse(contents);
}

fn readFile(pAllocator: *Allocator, file_name: []const u8) ![]const u8 {
    if (DBG) warn("parse_json_file: readFile file_name={}\n", file_name);
    var file = try os.File.openRead(file_name);
    defer file.close();

    const file_size = try file.getEndPos();
    var buff = try pAllocator.alloc(u8, file_size);
    _ = try file.read(buff);
    return buff;
}

fn getFileSize(file_name: []const u8) !usize {
    var file = try os.File.openRead(file_name);
    defer file.close();

    return try file.getEndPos();
}

test "parse_json_file.readFile" {
    var file_name = "../3d-objects/suzanne.babylon";
    var pAllocator = std.heap.c_allocator;
    var contents = try readFile(pAllocator, file_name);
    //warn("suzanne contents:\n{}\n", contents);
    var file_size = try getFileSize(file_name);
    assert(contents[0] == '{');
    assert(contents[file_size-1] == '}');
}

test "parse_json_file.dump.suzanne" {
    var file_name = "../3d-objects/suzanne.babylon";
    var pAllocator = std.heap.c_allocator;
    var tree = try parseJsonFile(pAllocator, file_name);
    defer tree.deinit();

    var root = tree.root;
    root.dump();

    var meshes = root.Object.get("meshes");
    assert(meshes != null);
}

test "parse_json_file.parse.suzanne" {
    var file_name = "../3d-objects/suzanne.babylon";
    var pAllocator = std.heap.c_allocator;
    var tree = try parseJsonFile(pAllocator, file_name);
    defer tree.deinit();

    var root = tree.root;

    var meshes = root.Object.get("meshes").?.value.Array;

    if (DBG) warn("mesh_array.len={}\n", meshes.len);
    assert(meshes.len == 1);

    var positions = meshes.items[0].Object.get("positions").?.value.Array;
    if (DBG) warn("positions.len={}\n", positions.len);

    var normals = meshes.items[0].Object.get("normals").?.value.Array;
    if (DBG) warn("normals.len={}\n", normals.len);

    var indices = meshes.items[0].Object.get("indices").?.value.Array;
    if (DBG) warn("indices.len={}\n", indices.len);

    var vertices_count = positions.len / 3;
    var faces_count = indices.len / 3;
    if (DBG) warn("vertices_count={} faces_count={}\n", vertices_count, faces_count);

    var mesh = try Mesh.init(pAllocator, "suzanne", vertices_count, faces_count);
    var i: usize = 0;
    var pos_iter = positions.iterator();
    while (i < vertices_count) : (i += 1) {
        var x = @floatCast(f32, pos_iter.next().?.Float);
        var y = @floatCast(f32, pos_iter.next().?.Float);
        var z = @floatCast(f32, pos_iter.next().?.Float);
        mesh.vertices[i] = geo.V3f32.init(x, y, z);
    }
    i = 0;
    var indicies_iter = indices.iterator();
    while (i < faces_count) : (i += 1) {
        // TODO: These should be Integers?
        var a = @floatToInt(usize, indicies_iter.next().?.Float);
        var b = @floatToInt(usize, indicies_iter.next().?.Float);
        var c = @floatToInt(usize, indicies_iter.next().?.Float);
        if (DBG) warn("face[{}]={{ .a={} .b={} .c={} }}\n", i, a, b, c);
        mesh.faces[i] = Face { .a=a, .b=b, .c=c };
    }
}
