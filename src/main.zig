const std = @import("std");
const gl = @cImport({
    @cInclude("GL/glew.h");
});
const glfw = @cImport({
    @cInclude("GLFW/glfw3.h");
});

const vertex_shader_source: [*c]const u8 = @embedFile("vertex_source.glsl");
const fragment_shader_source: [*c]const u8 = @embedFile("fragment_source.glsl");

pub fn main() !void {
    if (glfw.glfwInit() == glfw.GLFW_FALSE) {
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

    const vertex_shader: gl.GLuint = gl.glCreateShader().?(gl.GL_VERTEX_SHADER);
    gl.glShaderSource().?(vertex_shader, 1, &vertex_shader_source, null);

    gl.glCompileShader().?(vertex_shader);

    var status: gl.GLint = undefined;
    gl.glGetShaderiv().?(vertex_shader, gl.GL_COMPILE_STATUS, &status);
    if (status == gl.GL_FALSE) {
        std.debug.print("Shader failed to compile", .{});
        var compile_log: [512]u8 = undefined;
        gl.glGetShaderInfoLog().?(vertex_shader, 512, null, compile_log[0..]);
        std.debug.panic("Shader Log:\n{s}", .{compile_log});
    }
    // gl.glClearColor(0.2, 0.3, 0.3, 1.0);
    // gl.glClear(gl.GL_COLOR_BUFFER_BIT);

    // ----- begin main loop -----
    while (glfw.glfwWindowShouldClose(window) == glfw.GLFW_FALSE) {
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
