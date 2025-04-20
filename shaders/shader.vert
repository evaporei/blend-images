#version 330 core

uniform vec2 mouse_pos;

out vec2 uv;

void main() {
    float scale = 0.5;

    // glDrawArrays(0, 4) -> gl_VertexID = 0 | 1 | 2 | 3
    // [{0, 0}, {1, 0}, {0, 1}, {1, 1}]
    vec2 raw_pos = vec2(gl_VertexID % 2, gl_VertexID / 2);
    // vec2 raw_pos = vec2(gl_VertexID & 1, gl_VertexID >> 1); // same as above
    uv = raw_pos;
    // [{0, 0}, {2, 0}, {0, 2}, {2, 2}] (* 2.0)
    // [{-1, -1}, {1, -1}, {-1, 1}, {1, 1}] (- 1.0)
    vec2 pos = (raw_pos * 2.0 - 1.0) * scale; // scale screen-space quad

    gl_Position = vec4(pos + mouse_pos, 0, 1.0);
}
