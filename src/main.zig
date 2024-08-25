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

    // initialize the vertex buffer
    var vertex_buffer: gl.GLuint = undefined;
    gl.glCreateBuffers().?(1, &vertex_buffer);
    gl.glBindBuffer().?(gl.GL_ARRAY_BUFFER, vertex_buffer); // make vbo active
    gl.glBufferData().?(gl.GL_ARRAY_BUFFER, @sizeOf(gl.GLfloat), &vertices, gl.GL_STATIC_DRAW);

    // compile the vertex shader
    const vertex_shader: gl.GLuint = gl.glCreateShader().?(gl.GL_VERTEX_SHADER);
    gl.glShaderSource().?(vertex_shader, 1, &vertex_shader_source, null);
    gl.glCompileShader().?(vertex_shader);

    // check for compile errors
    var vertex_status: gl.GLint = undefined;
    gl.glGetShaderiv().?(vertex_shader, gl.GL_COMPILE_STATUS, &vertex_status);
    if (vertex_status == gl.GL_FALSE) {
        std.debug.print("Vertex shader failed to compile", .{});
        var compile_log: [512]u8 = undefined;
        gl.glGetShaderInfoLog().?(vertex_shader, 512, null, compile_log[0..]);
        std.debug.panic("Shader Log:\n{s}", .{compile_log});
    }

    // compile the fragment shader
    const fragment_shader: gl.GLuint = gl.glCreateShader().?(gl.GL_FRAGMENT_SHADER);
    gl.glShaderSource().?(fragment_shader, 1, &fragment_shader_source, null);
    gl.glCompileShader().?(fragment_shader);

    // check for compile errors
    var fragment_status: gl.GLint = undefined;
    gl.glGetShaderiv().?(fragment_shader, gl.GL_COMPILE_STATUS, &fragment_status);
    if (fragment_status == gl.GL_FALSE) {
        std.debug.print("fragment shader failed to compile", .{});
        var compile_log: [512]u8 = undefined;
        gl.glGetShaderInfoLog().?(fragment_shader, 512, null, compile_log[0..]);
        std.debug.panic("Shader Log:\n{s}", .{compile_log});
    }

    // link the shaders to create a shader program
    const shader_program = gl.glCreateProgram().?();
    gl.glAttachShader().?(shader_program, vertex_shader);
    gl.glAttachShader().?(shader_program, fragment_shader);

    gl.glBindFragDataLocation().?(shader_program, 0, "outColor");
    gl.glLinkProgram().?(shader_program);
    gl.glUseProgram().?(shader_program);

    const position: gl.GLuint = @intCast(gl.glGetAttribLocation().?(shader_program, "position"));
    // Tells OpenGL that the shader has 2 components, of type float with stride and offset = 0
    gl.glVertexAttribPointer().?(position, 2, gl.GL_FLOAT, gl.GL_FALSE, 0, null);
    gl.glEnableVertexAttribArray().?(position);

    // initialize the vertex array
    var vertex_array: gl.GLuint = undefined;
    gl.glGenVertexArrays().?(1, &vertex_array);
    gl.glBindVertexArray().?(vertex_array);

    if (gl.glGetError() != 0) {
        std.debug.panic("Error: glGetError() returned {d}\n", .{gl.glGetError()});
    }
    // ----- begin main loop -----
    while (glfw.glfwWindowShouldClose(window) == glfw.GLFW_FALSE) {
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_CAPS_LOCK) == glfw.GLFW_PRESS) {
            glfw.glfwSetWindowShouldClose(window, glfw.GL_TRUE);
        }
        const pressed = glfw.glfwGetKey(window, glfw.GLFW_KEY_CAPS_LOCK) == glfw.GLFW_PRESS;
        std.debug.print("{any}", .{pressed});
        // clear screen to black
        gl.glClearColor(0.0, 0.0, 0.0, 1.0);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT);

        // draw a triangle from the 3 vertices
        gl.glDrawArrays(gl.GL_TRIANGLES, 0, 3);

        // swap buffers
        glfw.glfwSwapBuffers(window);
    }
}

// Default GLFW error handling callback
fn errorCallback(error_code: c_int, description: [*c]const u8) callconv(.C) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}
