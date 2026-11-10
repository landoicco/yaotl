# Maps

Maps are made in [Tiled](https://www.mapeditor.org/), included in the Nix dev shell. This folder holds the sources (`.tmx`); the game loads their Lua exports from `assets/maps/`.

| Map | Purpose |
|---|---|
| `sandbox.tmx` | Development map with a few rooms and corridors to try features on. Not the game's level. |

## Editing a map

```bash
nix develop
tiled maps/sandbox.tmx
```

1. Edit and save the `.tmx`.
2. Export with **File → Export** (`Ctrl+E`). The map already points to its export in `assets/maps/`.
3. Commit both files: the `.tmx` is the source, the `.lua` is what the game reads.

From the command line, without opening the editor:

```bash
tiled --export-map lua maps/sandbox.tmx assets/maps/sandbox.lua
```

## What the game expects

The layer names are the contract between the editor and the code. The game stops with an error if one is missing.

| Layer | Type | Meaning |
|---|---|---|
| `floor` | Tile layer | Drawn only |
| `walls` | Tile layer | Any tile here is a wall |
| `spawns` | Object layer | Points named `player` (exactly one) and `zombie` |
| `lights` | Object layer | Points named `lamp`, with `range` (float), `intensity` (float) and `color` (color) |

Other rules:

- **Orthogonal, fixed size, 32 × 32 tiles.** Infinite maps are not supported.
- **One tileset, embedded in the map**, with its image in `assets/maps/`.
- **Objects are placed in pixels**, tiles in cells. The loader converts between them.
- **Walls must not touch only at a corner.** The gap between two diagonal walls has no width, and light and movement could slip through it ([ADR 0003](../docs/adr/0003-lighting.md)).
