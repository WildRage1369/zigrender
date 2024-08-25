const std = @import("std");
const gl = @import("zgl");
const c = @cImport({
    @cInclude("GLFW/glfw3.h");
});

pub fn main() !void {
    if (c.glfwInit() == 0) {
        std.debug.panic("Error: GLFW Init failed", .{});
    }
    defer c.glfwTerminate();

    _ = c.glfwSetErrorCallback(errorCallback);

    const window: ?*c.struct_GLFWwindow = c.glfwCreateWindow(800, 640, "ZigTracer", null, null);
    if (window == undefined) {
        std.debug.panic("Error: Window or OpenGL context creation failed", .{});
    }
    defer c.glfwDestroyWindow(window);

    // Enable VSync
    c.glfwSwapInterval(1);

    //----- end window setup -----
    //
    // const vertices: [6]gl.Float = .{
    //     0.0, 0.5, // Vertex 1 (X, Y)
    //     0.5, -0.5, // Vertex 2 (X, Y)
    //     -0.5, -0.5, // Vertex 3 (X, Y)
    // };
    // _ = vertices;
    //
    // // const vbo: []gl.Buffer = undefined;
    // // gl.createBuffers(&vbo); // make Vertex Buffer Object (comptime int)
    // // gl.bindBuffer(vbo[0], gl.BufferTarget.array_buffer); // make vbo active
    // //
    // // gl.bufferData(gl.BufferTarget.array_buffer, gl.Float, &vertices, gl.BufferUsage.static_draw);
    //
    // // gl.clearColor(0.2, 0.3, 0.3, 1.0);
    // // gl.clear(gl.binding.COLOR_BUFFER_BIT);

    // ----- begin main loop -----

    while (c.glfwWindowShouldClose(window) == 0) {
        if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
            c.glfwSetWindowShouldClose(window, 1);
        }
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

// Default GLFW error handling callback
fn errorCallback(error_code: c_int, description: [*c]const u8) callconv(.C) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}
