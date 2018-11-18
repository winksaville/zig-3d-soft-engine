const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;

const os = std.os;
const File = os.File;

const json = @import("../modules/zig-json/json.zig");

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
    var allocator = std.heap.c_allocator;
    var contents = try readFile(allocator, file_name);
    //warn("suzanne contents:\n{}\n", contents);
    var file_size = try getFileSize(file_name);
    assert(contents[0] == '{');
    assert(contents[file_size-1] == '}');
}

test "parse_json_file.parseJsonFile" {
    var file_name = "../3d-objects/suzanne.babylon";
    var allocator = std.heap.c_allocator;
    var tree = try parseJsonFile(allocator, file_name);
    defer tree.deinit();

    var root = tree.root;

    var meshes = root.Object.get("meshes");
    assert(meshes != null);

    var mesh_array = meshes.?.value.Array;
    if (DBG) warn("mesh_array.len={}\n", mesh_array.len);
}
