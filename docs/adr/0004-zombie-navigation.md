# 0004. Zombie navigation: a shared flow field and a straight walk when the way is clear

**Status:** Accepted

## Context

With walls in the map, zombies that walk straight at the player get stuck on the first wall in between. They need to find their way through rooms and corridors, as the GDD asks.

There can be many zombies, and they all chase the same target, the player. The map is a grid of cells, either wall or open.

## Decision

### One flow field for every zombie

`src/game/flow_field.lua` runs a **breadth-first search** from the player's cell over the open cells, and stores in each one how many steps it is from the player. A zombie only has to look at the cells around it and step toward the one closest to the player.

- **One search serves every zombie**, however many there are. Searching a path for each zombie (A*, for example) would cost more with every zombie added.
- **It is recomputed only when the player moves to another cell**, not every frame. In the sandbox, a search takes about 0.2 ms.
- **The search spreads to the four sideways neighbors**, so every step crosses a whole edge between cells.
- **Zombies may step diagonally**, which makes their paths less blocky, but only when both cells beside the diagonal are open. Paths never cut a wall's corner.
- Walls and cells the search cannot reach, such as the space outside the walls, have no distance.

### A straight walk when nothing is in the way

Following cell centers looks mechanical in open rooms. When a zombie can reach the player in a straight line, it walks straight at them instead.

A single ray from its center is not enough: the center could pass beside a corner while the shoulder hits it. `Zombie:hasClearPath` casts three rays with `Map:castRay`, from the center of the body and from its left and right edges. The straight walk is taken only if none of them meets a wall.

Walls still push zombies out with `Map:pushOut`, as they do the player, so a zombie that brushes a corner slides past it.

## Consequences

- Adding zombies costs one look at their neighbors each, and three rays.
- Zombies always know where the player is, even with walls in between. When they hear or see the player becomes its own decision, later: this only decides how they get there.
- Zombies do not avoid each other, and can overlap while following the same path.
- Paths are shortest in cells, not in pixels: in a wide room a zombie may follow the field in steps of 45° until the straight walk takes over.
- The search covers the whole map. On a much bigger map, it could stop at a distance beyond which zombies do not hunt.
