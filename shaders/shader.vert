#version 330 core

out vec2 uv;

void main() {
    vec2 pos = vec2(gl_VertexID % 2, gl_VertexID / 2) * 4.0 - 1;
    uv = (pos + 1) * 0.5;

    gl_Position = vec4(pos, 0, 1.0);
}
