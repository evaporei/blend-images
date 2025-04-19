#version 330 core

uniform sampler2D tex;

in vec2 uv;

out vec4 o_color;

void main() {
    // o_color = vec4(1.0, 0.0, 0.0, 1.0);
    o_color = texture(tex, uv);
}
