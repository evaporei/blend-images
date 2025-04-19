#version 330 core

out vec2 uv;

void main() {
    float scale = 0.5;

    vec2 rawPos = vec2(gl_VertexID % 2, gl_VertexID / 2);
    uv = rawPos; // [0,1] range directly
    vec2 pos = (rawPos * 2.0 - 1.0) * scale; // scale screen-space quad

    gl_Position = vec4(pos, 0, 1.0);
}
