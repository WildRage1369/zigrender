#version 460 core

in vec3 position;
in vec3 color;

out vec3 Color;

void main() {
    // Color.r = color.r * abs(position.y);
    // Color.g = color.g * abs(position.y);
    // Color.b = color.b * abs(position.y);
    Color = color;
    gl_Position = vec4(position, 1.0);
}
