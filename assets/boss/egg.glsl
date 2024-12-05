// written by groverbuger for g3d
// september 2021
// MIT license
// define some varying vectors that are useful for writing custom fragment shaders
varying vec4 worldPosition;
varying vec4 viewPosition;
varying vec4 screenPosition;
varying vec3 vertexNormal;
varying vec4 vertexColor;

#ifdef VERTEX
// this vertex shader is what projects 3d vertices in models onto your 2d screen

uniform mat4 projectionMatrix; // handled by the camera
uniform mat4 viewMatrix;       // handled by the camera
uniform mat4 modelMatrix;      // models send their own model matrices when drawn

uniform float time;

// the vertex normal attribute must be defined, as it is custom unlike the other attributes
attribute layout(location = 3) vec3 VertexNormal;


vec4 position(mat4 transformProjection, vec4 vertexPosition) {
    // calculate the positions of the transformed coordinates on the screen
    // save each step of the process, as these are often useful when writing custom fragment shaders
    worldPosition = TransformMatrix * modelMatrix * vertexPosition;

    float pulseFactor = sin(time * 2.0 + worldPosition.z) * 0.1;
    float pulseFactor2 = cos(time * 3.5 + worldPosition.z) * 0.05 + 1.0;
    vec3 offset = vec3(sin(time * 3.0) * pulseFactor * pulseFactor2,
                       cos(time * 3.0) * pulseFactor * pulseFactor2, 1.0);

    worldPosition += vec4(offset, 0.0);


    viewPosition = viewMatrix * worldPosition;
    screenPosition = projectionMatrix * viewPosition;

    // save some data from this vertex for use in fragment shaders
    mat3 normalMatrix = transpose(inverse(mat3(modelMatrix)));
    vertexNormal = normalize(normalMatrix * VertexNormal);

    vertexColor = VertexColor;

    return screenPosition;
}
#endif

#ifdef PIXEL
vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 texturecolor = Texel(tex, texture_coords);
    if (texturecolor.a <= 0.01)
        discard;
    return texturecolor * color;
}
#endif