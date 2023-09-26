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

uniform vec4 u_InnerColor; // The inner color with which to render this instance of geometry.
uniform vec4 u_OuterColor; // The outer color with which to render this instance of geometry.
uniform float u_Time;

// These are the interpolated values out of the rasterizer, so you can't know
// their specific values without knowing the vertices that contributed to them
in vec4 fs_Nor;
in vec4 fs_LightVec;
in vec4 fs_Col;
in vec4 fs_Pos;
in float fs_Displacement;

out vec4 out_Col; // This is the final output color that you will see on your
                  // screen for the pixel that is currently being processed.


float bias(float t, float b) {
    return pow(t, log(b) / log(0.5));
}

float triangleWave(float x, float freq, float amplitude) {
    return abs(mod((x * freq), amplitude) - (0.5 * amplitude));
}

void main()
{
    float biasValue = bias(fs_Displacement * 1.2, 0.3);     // Bias based on displacement
    vec4 newColor = mix(u_InnerColor, u_OuterColor, biasValue);

    float triangleValue = triangleWave(u_Time / 1000.f, 0.6, 2.0);  // Change color based on time
    out_Col = mix(u_InnerColor, newColor, triangleValue);
}
