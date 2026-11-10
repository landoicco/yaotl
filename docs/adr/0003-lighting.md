# 0003. Lighting: a lightmap of visibility polygons

**Status:** Accepted

## Context

Darkness carries the game's mood, and light is its main system. The lighting has to:

- Darken the whole scene, and let several lights lift it at once: the flashlight's cone and the halo around the player, muzzle flashes and the map's lamps.
- Give each light a soft look: fading with distance, and toward the edges of a cone.
- Stop at walls, so that rooms and corridors cast shadows and the flashlight cannot see through them.

## Decision

### A lightmap that multiplies the scene

Every frame, `src/game/lighting.lua` clears a screen-sized canvas to the ambient color (almost black) and adds each light to it with additive blending. The canvas is then drawn over the scene with multiplicative blending: where the lightmap is black the scene is hidden, where it is white the scene shows as drawn. Overlapping lights add up. Bullet tracers are drawn after the lightmap, so they glow in the dark.

### The look of a light comes from a shader

`assets/shaders/light.glsl` shades every pixel of a light's area: a quadratic falloff with distance, which looks closer to real light than a linear one, and a smooth edge between the inner and outer angles of a cone. A point light is a cone that covers every direction.

**The shader works in screen pixels.** LÖVE 11 batches simple draws and transforms their vertices on the CPU, so the vertex shader may receive positions that already include the camera's offset. Computing the light's shape from vertex positions in world coordinates broke as soon as the camera moved: the light drifted away from its source. The pixel shader now uses the pixel's screen position, and each light's origin is converted to screen space with `love.graphics.transformPoint` before it is sent. Since the camera only moves the view, direction and range need no conversion.

### Walls block the light: visibility polygons

`Lighting:litArea` is the only place that decides what a light reaches. It builds a **visibility polygon**: the area seen from the light, cut by the walls.

1. **Rays to the corners.** The polygon's shape only changes at wall corners, so a ray is cast to every wall corner within the light's range, plus one just to each side of it (`CORNER_OFFSET`), to see past the corner when it hides nothing behind it. A corner is a grid point where one or three of the four cells around it are walls, or two that touch only diagonally (`Map:isCorner`). Points along a straight wall need no ray.
2. **Rays along the edge.** Rays at evenly spaced angles (`ARC_SEGMENTS`) round off the parts of the edge where no wall stops the light, and a cone's two sides.
3. **Each ray stops at the first wall.** `Map:castRay` walks the grid cell by cell (a DDA traversal), so it never skips a wall. Bullets use the same function.
4. **Rays sorted by angle** give the polygon's outline, as a fan around the light.

**Light goes a few pixels into the walls** (`WALL_BLEED`). Otherwise the walls themselves would never be lit, and rooms would have no visible edges.

**The polygon is drawn as a fan mesh.** It is concave wherever a wall casts a shadow, and `love.graphics.polygon` only promises to fill convex polygons. A `Mesh` in `"fan"` mode, reused every frame, fills from the light outward, which is always correct for an area seen from a single point.

**Held lights stay in front of walls.** The flashlight's lens and the muzzle reach past the player's body, further than a wall's thickness. Against a wall, `Player:torsoPoint` pulls them back to just in front of it, so the light never starts on the other side.

## Consequences

- Shadows have hard edges, softened only by each light's falloff. Soft shadows (penumbras) would need several polygons per light or a blur pass.
- The cost of a light grows with the wall corners in its range: in the sandbox, at most a few dozen rays per light, every frame. The lamps never move, so their polygons could be cached if the cost ever shows.
- Anything that needs to know what can be seen, such as zombies spotting the player or sound blocked by walls, can reuse `Map:castRay`.
- Maps should not have walls that touch only at a corner: the gap between them has no width, and rays and movement could slip through it.
