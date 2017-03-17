#version 330 core

uniform float ticks;
uniform vec2 resolution;

out vec4 color;

void main(){
    vec2 uv = gl_FragCoord.xy / resolution;
    color = vec4(uv.x, uv.y, sin(ticks / 60.0), 1.0);
}
