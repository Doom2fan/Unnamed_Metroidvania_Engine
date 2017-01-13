#define PI 3.1415926535897932385

uniform float u_time;
vec2 u_k = vec2 (9, 9);
varying vec2 v_coords;

void main () {
    float v = 0.0;
    vec2 c = v_coords * u_k - u_k / 2.0;

    v += sin ((c.x + u_time));
    v += sin ((c.y + u_time) / 2.0);
    v += sin ((c.x + c.y + u_time) / 2.0);

    c += u_k / 2.0 * vec2 (sin (u_time / 3.0), cos (u_time / 2.0));
    v += sin (sqrt (c.x*c.x + c.y*c.y + 1.0) + u_time);
    v = v / 2.0;

    vec3 col = vec3 (atan (v), sin (PI * v), cosh (PI * v));
    gl_FragColor = vec4 (col * .5 + .5, 1);
}