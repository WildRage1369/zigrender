const std = @import("std");
pub const gl = @cImport({
    @cInclude("GL/glew.h");
});
pub const glfw = @cImport({
    @cInclude("GLFW/glfw3.h");
});
// const sphere = @import("sphere.zig");

const shader_input_len = 6;

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
    glfw.glfwSwapInterval(1);

    gl.glewExperimental = gl.GL_TRUE;
    _ = gl.glewInit();

    var width: c_int = undefined;
    var height: c_int = undefined;
    glfw.glfwGetFramebufferSize(window, &width, &height);
    gl.glViewport(0, 0, width, height);

    //----- end window setup -----
    //

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
    const shader_program = gl.glCreateProgram().?();
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

    // ----- end shader setup ----

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var obj_buf: ObjectBuffer = .{ .allocator = gpa.allocator() };
    defer obj_buf.dealloc();

    const vertices: []const gl.GLfloat = &.{
        0.5, -0.5, 0.5, 1.0, 0.0, 0.0, // Bottom-right far : red
        0.5, -0.5, -0.5, 0.0, 1.0, 0.0, // Bottom-right close : green
        -0.5, -0.5, 0.5, 0.0, 0.0, 1.0, // Bottom-left far : blue
        -0.5, -0.5, -0.5, 1.0, 1.0, 0.0, // Bottom-left close : yellow
        0.0, 0.5, 0.0, 1.0, 1.0, 1.0, // Top : white
    };
    const elements: []const gl.GLuint = &.{
        4, 0, 2, // far face
        4, 0, 1, // right face
        4, 3, 2, // left face
        4, 1, 3, // close face
    };
    try obj_buf.concatenateObject(vertices, elements);

    const plane_vert: []const gl.GLfloat = &.{
        -0.5, 0.0, 0.0, 1.0, 0.0, 0.0, // Vertex 1: Red
        0.0, -1.0, 0.0, 0.0, 1.0, 0.0, // Vertex 2: Green
        -1.0, -1.0, 0.0, 0.0, 0.0, 1.0, // Vertex 3: Blue
    };

    const plane_elems: []const gl.GLuint = &.{ 0, 1, 2, 1, 2, 0 };
    try obj_buf.concatenateObject(plane_vert, plane_elems);

    gl.glEnable(gl.GL_DEPTH_TEST);
    gl.glDepthFunc(gl.GL_LESS);

    // initialize the vertex array
    var vertex_array: gl.GLuint = undefined;
    gl.glGenVertexArrays().?(1, &vertex_array);
    gl.glBindVertexArray().?(vertex_array);

    // initialize the vertex buffer
    var vertex_buffer: gl.GLuint = undefined;
    gl.glCreateBuffers().?(1, &vertex_buffer);
    gl.glBindBuffer().?(gl.GL_ARRAY_BUFFER, vertex_buffer);
    gl.glBufferData().?(gl.GL_ARRAY_BUFFER, obj_buf.vertices_len * @sizeOf(gl.GLfloat), obj_buf.vertices.ptr, gl.GL_STATIC_DRAW);

    // initalize the element buffer
    var element_buffer: gl.GLuint = undefined;
    gl.glGenBuffers().?(1, &element_buffer);
    gl.glBindBuffer().?(gl.GL_ELEMENT_ARRAY_BUFFER, element_buffer);
    gl.glBufferData().?(gl.GL_ELEMENT_ARRAY_BUFFER, obj_buf.elements_len * @sizeOf(gl.GLuint), obj_buf.elements.ptr, gl.GL_STATIC_DRAW);

    const position: gl.GLuint = @intCast(gl.glGetAttribLocation().?(shader_program, "position"));
    gl.glVertexAttribPointer().?(position, 3, gl.GL_FLOAT, gl.GL_FALSE, shader_input_len * @sizeOf(gl.GLfloat), null);
    gl.glEnableVertexAttribArray().?(position);

    const color: gl.GLuint = @intCast(@abs(gl.glGetAttribLocation().?(shader_program, "color")));
    gl.glVertexAttribPointer().?(color, 3, gl.GL_FLOAT, gl.GL_FALSE, shader_input_len * @sizeOf(gl.GLfloat), @ptrFromInt(3 * @sizeOf(gl.GLfloat)));
    gl.glEnableVertexAttribArray().?(color);

    if (gl.glGetError() != 0) {
        std.debug.panic("Error: glGetError() returned {d}\n", .{gl.glGetError()});
    }

    // ----- begin main loop -----
    while (glfw.glfwWindowShouldClose(window) == glfw.GLFW_FALSE) {
        // for (0..@intCast(obj_buf.elements_len)) |i| {
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_CAPS_LOCK) == glfw.GLFW_PRESS) {
            glfw.glfwSetWindowShouldClose(window, glfw.GL_TRUE);
        }
        gl.glClearColor(0.0, 0.0, 0.0, 1.0);
        gl.glClear(gl.GL_COLOR_BUFFER_BIT | gl.GL_DEPTH_BUFFER_BIT);

        // gl.glDrawElements(gl.GL_TRIANGLES, @intCast(i), gl.GL_UNSIGNED_INT, null);
        gl.glDrawElements(gl.GL_TRIANGLES, obj_buf.elements_len, gl.GL_UNSIGNED_INT, null);

        glfw.glfwSwapBuffers(window);
        glfw.glfwPollEvents();
        // std.time.sleep(150 * std.time.ns_per_ms);
        // std.debug.print("i: {d}\n", .{i});
        // }
    }
}

// Default GLFW error handling callback
fn errorCallback(error_code: c_int, description: [*c]const u8) callconv(.C) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

const ObjectLocations = struct { vertex_start: []gl.GLfloat, element_start: []gl.GLuint };

const ObjectBuffer = struct {
    vertices: []gl.GLfloat = undefined, // slice of type GLfloat
    vertices_len: c_int = 0,
    object_locations: ?ObjectLocations = undefined,
    elements: []gl.GLuint = undefined, // slice of type GLuint
    elements_len: c_int = 0,
    allocator: std.mem.Allocator,
    tri_param_len: u32 = 6,

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

            // offset all new elements by the number of verteces in the last object
            for (tmp_elems[self.elements.len..]) |*num| {
                num.* += tri_offset;
            }

            self.allocator.free(self.vertices);
            self.allocator.free(self.elements);

            self.vertices = tmp_vert;
            self.elements = tmp_elems;
        }
        // self.tri_param_len += tri_count;
        self.elements_len = @intCast(self.elements.len);
        self.vertices_len = @intCast(self.vertices.len);
    }

    pub fn dealloc(self: ObjectBuffer) void {
        self.allocator.free(self.vertices);
        self.allocator.free(self.elements);
    }
};
