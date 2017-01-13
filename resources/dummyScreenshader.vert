varying vec2 v_coords;

void main () {
    v_coords = gl_Vertex.st;
    gl_Position = vec4 (1.0 - gl_Vertex.x, 1.0 - gl_Vertex.y, 0.0, 1.0);
}