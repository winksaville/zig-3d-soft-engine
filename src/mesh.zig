const std = @import("std");
const assert = std.debug.assert;
const warn = std.debug.warn;
const Allocator = std.mem.Allocator;
const math = std.math;
const math3d = @import("math3d.zig");

const Mesh = struct {
    const Self = @This();

    pub name: []const u8,
    pub position: math3d.Vec3,
    pub rotation: math3d.Vec3,
    pub vertices: []math3d.Vec3,

    pub fn init(pAllocator: *Allocator, name:[]const u8, vertices_count: usize) !Self {
        return Self {
            .name = name,
            .position = math3d.vec3(0.0, 0.0, 0.0),
            .rotation = math3d.vec3(0.0, 0.0, 0.0),
            .vertices = try pAllocator.alloc(math3d.Vec3, vertices_count),
        };
    }
};

test "mesh" {
    var direct_allocator = std.heap.DirectAllocator.init();
    var arena_allocator = std.heap.ArenaAllocator.init(&direct_allocator.allocator);
    defer arena_allocator.deinit();
    var pAllocator = &arena_allocator.allocator;

    var mesh = try Mesh.init(pAllocator, "mesh1", 8);
    assert(std.mem.eql(u8, mesh.name[0..], "mesh1"));
    assert(mesh.position.data[0] == 0.0);
    assert(mesh.position.data[1] == 0.0);
    assert(mesh.position.data[2] == 0.0);
    assert(mesh.rotation.data[0] == 0.0);
    assert(mesh.rotation.data[1] == 0.0);
    assert(mesh.rotation.data[2] == 0.0);

    // Unit cube about 0,0,0
    mesh.vertices[0] = math3d.vec3(-1, 1, 1);
    mesh.vertices[1] = math3d.vec3(1, 1, 1);
    mesh.vertices[2] = math3d.vec3(-1, -1, 1);
    mesh.vertices[3] = math3d.vec3(-1, -1, -1);
    mesh.vertices[4] = math3d.vec3(-1, 1, -1);
    mesh.vertices[5] = math3d.vec3(1, 1, -1);
    mesh.vertices[6] = math3d.vec3(1, -1, 1);
    mesh.vertices[7] = math3d.vec3(1, -1, -1);
}

