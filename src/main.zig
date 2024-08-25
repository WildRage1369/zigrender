const std = @import("std");
const gl = @import("zgl");
const glfw = @cImport({
    @cInclude("GLFW/glfw3.h");
});

pub fn main() !void {
    if (glfw.glfwInit() == 0) {
        std.debug.panic("Error: GLFW Init failed", .{});
    }
    defer glfw.glfwTerminate();

    _ = glfw.glfwSetErrorCallback(errorCallback);

    const window: ?*glfw.struct_GLFWwindow = glfw.glfwCreateWindow(800, 640, "ZigTracer", null, null);
    if (window == undefined) {
        std.debug.panic("Error: Window or OpenGL context creation failed", .{});
    }
    defer glfw.glfwDestroyWindow(window);

    glfw.glfwMakeContextCurrent(window);

    // Enable VSync
    glfw.glfwSwapInterval(1);

    //----- end window setup -----
    //
    const vertices: [6]gl.Float = .{
        0.0, 0.5, // Vertex 1 (X, Y)
        0.5, -0.5, // Vertex 2 (X, Y)
        -0.5, -0.5, // Vertex 3 (X, Y)
    };

    var vbo: gl.UInt = undefined;
    gl.genBuffers(vbo);

    gl.createBuffers(&vbo); // make Vertex Buffer Object (comptime int)
    gl.bindBuffer(vbo[0], gl.BufferTarget.array_buffer); // make vbo active

    gl.bufferData(gl.BufferTarget.array_buffer, gl.Float, &vertices, gl.BufferUsage.static_draw);
    //
    // // gl.clearColor(0.2, 0.3, 0.3, 1.0);
    // // gl.clear(gl.binding.COLOR_BUFFER_BIT);

    // ----- begin main loop -----

    while (glfw.glfwWindowShouldClose(window) == 0) {
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_ESCAPE) == glfw.GLFW_PRESS) {
            glfw.glfwSetWindowShouldClose(window, 1);
        }
        glfw.glfwSwapBuffers(window);
        glfw.glfwPollEvents();
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
