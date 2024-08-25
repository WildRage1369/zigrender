const std = @import("std");
const gl = @cImport({
    @cInclude("GL/glew.h");
});
const glfw = @cImport({
    @cInclude("GLFW/glfw3.h");
});

pub fn main() !void {
    // @setRuntimeSafety(false);
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

    gl.glewExperimental = gl.GL_TRUE;
    _ = gl.glewInit();

    //----- end window setup -----

    var width: c_int = undefined;
    var height: c_int = undefined;
    glfw.glfwGetFramebufferSize(window, &width, &height);
    gl.glViewport(0, 0, width, height);

    const vertices: [6]gl.GLfloat = .{
        0.0, 0.5, // Vertex 1 (X, Y)
        0.5, -0.5, // Vertex 2 (X, Y)
        -0.5, -0.5, // Vertex 3 (X, Y)
    };

    var vertex_buffer: gl.GLuint = undefined;
    gl.glCreateBuffers().?(1, &vertex_buffer);
    gl.glBindBuffer().?(gl.GL_ARRAY_BUFFER, vertex_buffer); // make vbo active

    gl.glBufferData().?(gl.GL_ARRAY_BUFFER, @sizeOf(gl.GLfloat), &vertices, gl.GL_STATIC_DRAW);

    gl.glClearColor(0.2, 0.3, 0.3, 1.0);
    gl.glClear(gl.GL_COLOR_BUFFER_BIT);

    // ----- begin main loop -----

    while (glfw.glfwWindowShouldClose(window) == 0) {
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_CAPS_LOCK) == glfw.GLFW_PRESS) {
            glfw.glfwSetWindowShouldClose(window, glfw.GL_TRUE);
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

const ConvertError = error{
    TooBig,
    TooSmall,
};

// Default GLFW error handling callback
fn errorCallback(error_code: c_int, description: [*c]const u8) callconv(.C) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}
