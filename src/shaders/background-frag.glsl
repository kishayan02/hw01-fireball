#version 300 es

// This is a fragment shader. If you've opened this file first, please
// open and read lambert.vert.glsl before reading on.
// Unlike the vertex shader, the fragment shader actually does compute
// the shading of geometry. For every pixel in your program's output
// screen, the fragment shader is run for every bit of geometry that
// particular pixel overlaps. By implicitly interpolating the position
// data passed into the fragment shader by the vertex shader, the fragment shader
// can compute what color to apply to its pixel based on things like vertex
// position, light position, and vertex color.
precision highp float;

uniform vec4 u_InnerColor; // The color with which to render this instance of geometry.

// // These are the interpolated values out of the rasterizer, so you can't know
// // their specific values without knowing the vertices that contributed to them
// in vec4 fs_Nor;
// in vec4 fs_LightVec;
// in vec4 fs_Col;

// out vec4 out_Col; // This is the final output color that you will see on your
//                   // screen for the pixel that is currently being processed.

uniform vec3 u_Eye, u_Ref, u_Up;
uniform vec2 u_Dimensions;
uniform float u_Time;

in vec2 fs_Pos;
out vec4 out_Col;

float noise2D(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 269.5))) * 43758.5453);
}

float interpNoise2D(vec2 p) {
    int intX = int(floor(p[0]));
    float fractX = fract(p[0]);
    int intY = int(floor(p[1]));
    float fractY = fract(p[1]);

    float v1 = noise2D(vec2(intX, intY));
    float v2 = noise2D(vec2(intX + 1, intY));
    float v3 = noise2D(vec2(intX, intY + 1));
    float v4 = noise2D(vec2(intX + 1, intY + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);

    return mix(i1, i2, fractY);
}

float fbm(vec2 p) {
    float total = 0.f;
    float persistence = 0.75f;
    int octaves = 8;
    float freq = 2.f;
    float amp = 0.5f;

    for(int i = 1; i <= octaves; i++) {
        total += interpNoise2D(vec2(p[0] * freq,
                                    p[1] * freq)) * amp;

        freq *= 2.f;
        amp *= persistence;
    }

    return total;
}

void main()
{
    float fbmValue = fbm((fs_Pos) * 10.f);
    out_Col = u_InnerColor + vec4(fbmValue * abs(cos(u_Time / 500.)), 
                                fbmValue * abs(cos(u_Time / 500.)), 
                                fbmValue * abs(cos(u_Time / 500.)), 
                                1.f);
}
