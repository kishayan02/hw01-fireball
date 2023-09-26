#version 300 es

//This is a vertex shader. While it is called a "shader" due to outdated conventions, this file
//is used to apply matrix transformations to the arrays of vertex data passed to it.
//Since this code is run on your GPU, each vertex is transformed simultaneously.
//If it were run on your CPU, each vertex would have to be processed in a FOR loop, one at a time.
//This simultaneous transformation allows your program to run much faster, especially when rendering
//geometry with millions of vertices.

uniform mat4 u_Model;       // The matrix that defines the transformation of the
                            // object we're rendering. In this assignment,
                            // this will be the result of traversing your scene graph.

uniform mat4 u_ModelInvTr;  // The inverse transpose of the model matrix.
                            // This allows us to transform the object's normals properly
                            // if the object has been non-uniformly scaled.

uniform mat4 u_ViewProj;    // The matrix that defines the camera's transformation.
                            // We've written a static matrix for you to use for HW2,
                            // but in HW3 you'll have to generate one yourself
uniform int u_Octaves;
uniform float u_Strength;
uniform float u_Time;

in vec4 vs_Pos;             // The array of vertex positions passed to the shader
in vec4 vs_Nor;             // The array of vertex normals passed to the shader
in vec4 vs_Col;             // The array of vertex colors passed to the shader.

out vec4 fs_Nor;            // The array of normals that has been transformed by u_ModelInvTr. This is implicitly passed to the fragment shader.
out vec4 fs_LightVec;       // The direction in which our virtual light lies, relative to each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Col;            // The color of each vertex. This is implicitly passed to the fragment shader.
out vec4 fs_Pos;
out float fs_Displacement;

const vec4 lightPos = vec4(5, 5, 3, 1); //The position of our virtual light, which is used to compute the shading of
                                        //the geometry in the fragment shader.

float noise3D(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 269.5, 631.2))) * 43758.5453);
}

float interpNoise3D(vec3 p) {
    int intX = int(floor(p[0]));
    float fractX = fract(p[0]);
    int intY = int(floor(p[1]));
    float fractY = fract(p[1]);
    int intZ = int(floor(p[2]));
    float fractZ = fract(p[2]);

    float v1 = noise3D(vec3(intX, intY, intZ));
    float v2 = noise3D(vec3(intX + 1, intY, intZ));
    float v3 = noise3D(vec3(intX, intY + 1, intZ));
    float v4 = noise3D(vec3(intX + 1, intY + 1, intZ));
    float v5 = noise3D(vec3(intX, intY, intZ + 1));
    float v6 = noise3D(vec3(intX + 1, intY, intZ + 1));
    float v7 = noise3D(vec3(intX, intY + 1, intZ + 1));
    float v8 = noise3D(vec3(intX + 1, intY + 1, intZ + 1));

    float i1 = mix(v1, v2, fractX);
    float i2 = mix(v3, v4, fractX);
    float i3 = mix(v5, v6, fractX);
    float i4 = mix(v7, v8, fractX);

    float m0 = mix(i1, i2, fractY);
    float m1 = mix(i3, i4, fractY);

    return mix(m0, m1, fractZ);
}

float fbm(vec3 p, int octaves) {
    float total = 0.f;
    float persistence = 0.75f;
    float freq = 2.f;
    float amp = 0.5f;

    for(int i = 1; i <= octaves; i++) {
        total += interpNoise3D(vec3(p[0] * freq,
                                    p[1] * freq,
                                    p[2] * freq)) * amp;

        freq *= 2.f;
        amp *= persistence;
    }

    return total;
}

float impulse(float k, float x) {
    float h = k * x;
    return h * exp(1.f - h);
}

float triangleWave(float x, float freq, float amplitude) {
    return abs(mod((x * freq), amplitude) - (0.5 * amplitude));
}

void main()
{
    mat3 invTranspose = mat3(u_ModelInvTr);
    fs_Nor = vec4(invTranspose * vec3(vs_Nor), 0);          // Pass the vertex normals to the fragment shader for interpolation.
                                                            // Transform the geometry's normals by the inverse transpose of the
                                                            // model matrix. This is necessary to ensure the normals remain
                                                            // perpendicular to the surface after the surface is transformed by
                                                            // the model matrix.

    float sphereDisplacement = 0.2 * abs(sin(1.8 * vs_Pos.x + 3.5) + impulse(0.3, vs_Pos.y) + + impulse(0.2, vs_Pos.z)); // low-frequency, high-amplitude displacement of your sphere so as to make it less uniformly sphere-like

    vec3 point = vec3(triangleWave(vs_Pos.x + u_Time / 1000.f, 0.6, 2.0),
                        triangleWave(vs_Pos.y + u_Time / 1000.f, 0.6, 2.0),
                        triangleWave(vs_Pos.z + u_Time / 1000.f, 0.6, 2.0));
    float fbmDisplacement = u_Strength * fbm(point, u_Octaves); // higher-frequency, lower-amplitude layer of fbm to apply a finer level of distortion
    
    // add variables^ vs_FbmStrength, vs_Octaves
    fs_Displacement = sphereDisplacement + fbmDisplacement;
    
    vec4 modelposition = u_Model * (vs_Pos + (vs_Nor * fs_Displacement));
    fs_Pos = modelposition;
    fs_LightVec = lightPos - modelposition;     // Compute the direction in which the light source lies
    gl_Position = u_ViewProj * modelposition;   // gl_Position is a built-in variable of OpenGL which is
                                                // used to render the final positions of the geometry's vertices
}
