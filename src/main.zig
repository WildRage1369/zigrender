const std = @import("std");
pub const gl = @cImport({
    @cInclude("GL/glew.h");
});
pub const glfw = @cImport({
    @cInclude("GLFW/glfw3.h");
});
const zm = @import("zmath");

const shader_input_len = 6;

const vertex_shader_source: [*c]const u8 = @embedFile("vertex_source.glsl");
const fragment_shader_source: [*c]const u8 = @embedFile("fragment_source.glsl");

const vertex_shader_source: [*c]const u8 = @embedFile("vertex_source.glsl");
const fragment_shader_source: [*c]const u8 = @embedFile("fragment_source.glsl");

pub fn main() !void {
    if (glfw.glfwInit() == glfw.GLFW_FALSE) {
        std.debug.panic("Error: GLFW Init failed\n", .{});
    }

    defer glfw.glfwTerminate();
    _ = glfw.glfwSetErrorCallback(errorCallback);

    const window: ?*glfw.struct_GLFWwindow = glfw.glfwCreateWindow(800, 640, "ZigTracer", null, null);
    if (window == undefined) {
        std.debug.panic("Error: Window or OpenGL context creation failed\n", .{});
    }
    defer glfw.glfwDestroyWindow(window);
    glfw.glfwMakeContextCurrent(window);

    // Enable VSync
    // glfw.glfwSwapInterval(1);

    gl.glewExperimental = gl.GL_TRUE;
    _ = gl.glewInit();

    var width: c_int = undefined;
    var height: c_int = undefined;
    glfw.glfwGetFramebufferSize(window, &width, &height);
    gl.glViewport(0, 0, width, height);

    //----- end window setup -----

    // initialize the vertex array
    var vertex_array: gl.GLuint = undefined;
    gl.glGenVertexArrays().?(1, &vertex_array);
    gl.glBindVertexArray().?(vertex_array);

    // initialize the vertex buffer
    var vertex_buffer: gl.GLuint = undefined;
    gl.glCreateBuffers().?(1, &vertex_buffer);
    gl.glBindBuffer().?(gl.GL_ARRAY_BUFFER, vertex_buffer); // make vbo active
    gl.glBufferData().?(gl.GL_ARRAY_BUFFER, vertices.len, &vertices, gl.GL_STATIC_DRAW);

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

    if (gl.glGetError() != 0) {
        std.debug.panic("Error: glGetError() returned {d}\n", .{gl.glGetError()});
    }
    // ----- begin main loop -----
    while (glfw.glfwWindowShouldClose(window) == glfw.GLFW_FALSE) {
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_CAPS_LOCK) == glfw.GLFW_PRESS) {
            glfw.glfwSetWindowShouldClose(window, glfw.GL_TRUE);
        }
        gl.glClearColor(0.0, 0.0, 0.0, 1.0);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);

        gl.glDrawElements(gl.GL_TRIANGLES, obj_buf.elements_len, gl.GL_UNSIGNED_INT, null);

        glfw.glfwSwapBuffers(window);
    }
}

/// Default GLFW error handling callback
fn errorCallback(error_code: c_int, description: [*c]const u8) callconv(.C) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

/// Compiles the vertex and fragment shaders and returns the shader program
fn compileShaders() gl.GLuint {
    // compile the vertex shader
    const vertex_shader: gl.GLuint = gl.glCreateShader().?(gl.GL_VERTEX_SHADER);
    gl.glShaderSource().?(vertex_shader, 1, &vertex_shader_source, null);
    gl.glCompileShader().?(vertex_shader);

    // check for compile errors
    var vertex_status: gl.GLint = undefined;
    gl.glGetShaderiv().?(vertex_shader, gl.GL_COMPILE_STATUS, &vertex_status);
    if (vertex_status == gl.GL_FALSE) {
        std.debug.print("Vertex shader failed to compile.\n", .{});
        var compile_log: [512]u8 = undefined;
        gl.glGetShaderInfoLog().?(vertex_shader, 512, null, compile_log[0..]);
        std.debug.panic("Shader Log: \n{s}\n", .{compile_log});
    }

    // compile the fragment shader
    const fragment_shader: gl.GLuint = gl.glCreateShader().?(gl.GL_FRAGMENT_SHADER);
    gl.glShaderSource().?(fragment_shader, 1, &fragment_shader_source, null);
    gl.glCompileShader().?(fragment_shader);

    // check for compile errors
    var fragment_status: gl.GLint = undefined;
    gl.glGetShaderiv().?(fragment_shader, gl.GL_COMPILE_STATUS, &fragment_status);
    if (fragment_status == gl.GL_FALSE) {
        std.debug.print("Fragment shader failed to compile.\n", .{});
        var compile_log: [512]u8 = undefined;
        gl.glGetShaderInfoLog().?(fragment_shader, 512, null, compile_log[0..]);
        std.debug.panic("Shader Log: \n{s}\n", .{compile_log});
    }

    // link the shaders to create a shader program
    const shader_program: gl.GLuint = gl.glCreateProgram().?();
    gl.glAttachShader().?(shader_program, vertex_shader);
    gl.glAttachShader().?(shader_program, fragment_shader);
    gl.glBindFragDataLocation().?(shader_program, 0, "outColor");

    gl.glLinkProgram().?(shader_program);

    // check for compile errors
    var program_status: gl.GLint = undefined;
    gl.glGetProgramiv().?(shader_program, gl.GL_LINK_STATUS, &program_status);
    if (program_status == gl.GL_FALSE) {
        std.debug.print("Program failed to link.\n", .{});
        var compile_log: [512]u8 = undefined;
        gl.glGetShaderInfoLog().?(shader_program, 512, null, compile_log[0..]);
        std.debug.panic("Program Log:\n{s}\n", .{compile_log});
    }
    gl.glUseProgram().?(shader_program);
    gl.glDeleteShader().?(vertex_shader);
    gl.glDeleteShader().?(fragment_shader);
    return shader_program;
}

/// A structure to hold and manage the vertex and element buffers
/// and help manage different objects to assist in adding and
/// removing objects from the buffers
const ObjectBuffer = struct {
    object_locations: struct { vertex_start: []gl.GLfloat, element_start: []gl.GLuint } = undefined,
    vertices: []gl.GLfloat = undefined,
    elements: []gl.GLuint = undefined,
    vertices_len: c_int = 0,
    elements_len: c_int = 0,
    allocator: std.mem.Allocator,
    tri_param_len: u32 = 6,

    /// Concatenates a new object to the vertex and element buffers
    pub fn concatenateObject(self: *ObjectBuffer, vert: []const gl.GLfloat, elems: []const gl.GLuint) !void {
        if (self.elements_len == 0) {
            self.vertices = try self.allocator.alloc(gl.GLfloat, vert.len);
            self.elements = try self.allocator.alloc(gl.GLuint, elems.len);
            @memcpy(self.vertices, vert);
            @memcpy(self.elements, elems);
        } else {
            const tmp_vert = try self.allocator.alloc(gl.GLfloat, self.vertices.len + vert.len);
            const tmp_elems = try self.allocator.alloc(gl.GLuint, self.elements.len + elems.len);

            const tri_offset: c_uint = @intCast(self.vertices.len / self.tri_param_len);

            @memcpy(tmp_vert[0..self.vertices.len], self.vertices);
            @memcpy(tmp_elems[0..self.elements.len], self.elements);

            @memcpy(tmp_vert[self.vertices.len..], vert);
            @memcpy(tmp_elems[self.elements.len..], elems);

            // offset all new elements by the number of verteces in the objects
            for (tmp_elems[self.elements.len..]) |*num| {
                num.* += tri_offset;
            }

            self.allocator.free(self.vertices);
            self.allocator.free(self.elements);

            self.vertices = tmp_vert;
            self.elements = tmp_elems;
        }
        self.elements_len = @intCast(self.elements.len);
        self.vertices_len = @intCast(self.vertices.len);
    }

    /// Deallocates the memory used by the vertex and element buffers
    pub fn dealloc(self: ObjectBuffer) void {
        self.allocator.free(self.vertices);
        self.allocator.free(self.elements);
    }
};
