// One light drawn into the lightmap: fades with distance and toward the cone's edges
varying vec2 worldPosition;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    // Before the transform, so lights keep working once a camera moves the view
    worldPosition = vertex_position.xy;
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
uniform vec2 origin;
uniform vec2 direction; // unit vector
uniform float range;
// Cosines of the half-angles: full light inside innerCos, none outside outerCos
uniform float innerCos;
uniform float outerCos;

vec4 effect(vec4 color, Image tex, vec2 textureCoords, vec2 screenCoords)
{
    vec2 toPixel = worldPosition - origin;
    float pixelDistance = length(toPixel);

    // Quadratic falloff looks closer to real light than a linear one
    float falloff = 1.0 - clamp(pixelDistance / range, 0.0, 1.0);
    falloff *= falloff;

    float cosAngle = dot(toPixel / max(pixelDistance, 0.001), direction);
    float edge = smoothstep(outerCos, innerCos, cosAngle);

    return vec4(color.rgb * falloff * edge, 1.0);
}
#endif
