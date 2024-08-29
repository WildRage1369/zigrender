#version 460 core

in vec3 position;
in vec3 color;

uniform mat4 transform;

out vec3 Color;

void main() {
    Color = color;
    gl_Position = transform * vec4(position, 1.0);
}
