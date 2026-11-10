# Yaotl: Game Design Document

| | |
|---|---|
| **Genre** | Top-down horror shooter |
| **Engine** | LÖVE 11.5 (Lua) |
| **Scope** | Small, single player, about 15–20 minutes |

## 1. Vision

Someone wakes up in a dark, unknown place, with no idea how they got there, and the only way is forward. The game is horror and suspense first: darkness and sound build the tension, and the player still has to fight to get through.

The art stays simple on purpose. An empty place made only of floors, walls and doors feels wrong, and that emptiness is part of the mood. The game is carried by its systems (light, sound, game feel) more than by its art.

The scope stays small, so that everything in the game is finished and polished.

## 2. Structure

- The game is a single run forward through the place, not waves in an arena.
- It opens with a short message: the player has just appeared there and knows nothing else.
- At first there are no zombies, only their sounds.
- Seeing the first zombie means running the other way, and that escape leads to the handgun. From then on the player can fight back.
- Dying restarts the game from the beginning.

## 3. Player

- Moves with WASD. The torso faces the mouse cursor and the feet follow the movement: walking, walking backwards or strafing.
- Starts with only the flashlight.
- Holds one thing at a time: the flashlight or a weapon.
- `Q` switches between the flashlight and the last weapon used, so choosing between light and defense takes a single key.
- `1` and `2` take out the handgun or the shotgun directly, once found.
- Survives five zombie hits.

## 4. Light

- The place is dark. The flashlight is the only real source of light.
- The flashlight casts a cone of light in the direction the player aims.
- Its battery runs down, and the light flickers more and more as it gets low.
- With a weapon out, the player is in the dark: only the flash of each shot lights the surroundings for an instant.
- Seeing and defending become a trade-off: the player cannot light the way and shoot at the same time.
- Walls block every light and cast shadows, so what lies around a corner stays hidden. How the lighting works is in [ADR 0003](adr/0003-lighting.md).

## 5. Weapons

- The handgun is found early on, while escaping the first zombie.
- The shotgun is found after the handgun. It fires a spread of pellets, and its shots give a bigger flash.
- Each weapon has its own limited ammo, with reloading.
- Reloading is manual, with `R`, and never automatic: the player has to remember to reload.

## 6. Enemies

- Zombies. They are heard before they are seen.
- A zombie takes three handgun shots to kill, and fades out when it dies.
- Up close, a zombie swings at the player. Stepping back before the arms close dodges the hit.
- Zombies are slower than the player, so running away is always an option.
- They navigate toward the player using a flow field.

## 7. World

- An unknown place made only of floors, walls and doors.
- The map is larger than the screen, and a camera follows the player.
- The map is built in [Tiled](https://www.mapeditor.org/) and loaded with a custom loader.
- During development, features are tried on a sandbox map of a few rooms and corridors, separate from the level.

## 8. Technical design

- Design patterns come from Robert Nystrom's [*Game Programming Patterns*](https://gameprogrammingpatterns.com/).
- A pattern is introduced only when the project's complexity calls for it, and it is documented here when that happens.
- Design decisions are recorded as [Architecture Decision Records](adr/README.md).

### Patterns in use

| Pattern | Where | Decision |
|---|---|---|
| State (hierarchical) | Player states, shared by every weapon | [ADR 0001](adr/0001-player-state-machine.md), [ADR 0002](adr/0002-shared-weapon-states.md) |
| Update Method | The world updates every entity and removes the dead ones | — |
| Flyweight | Animation frames are shared by every instance of a spritesheet | — |

### Code structure

The code is split so that a reusable engine can grow out of the game:

- `src/engine/`: generic modules that know nothing about Yaotl.
- `src/game/`: everything specific to Yaotl.

Rules:

- `game/` may require `engine/`, but `engine/` never requires `game/`.
- A module moves into `engine/` only after the game has used it and it has proved to be generic.
- Nothing is added to `engine/` that the game does not need.

### Code quality

- CI checks every pull request with luacheck (static analysis) and StyLua (formatting).
- The Nix flake pins both tools, so local checks and CI run the same versions.

### Distribution

- A CI pipeline builds executables of the game for Linux and Windows.
- Every pull request uploads its builds as artifacts, so each feature can be tested as players will run it.
- Pushing a `v*` tag publishes a GitHub release with the builds.
- The builds fuse the game into the official LÖVE binaries, pinned by checksum.

## 9. Assets

- All art and audio are free third-party assets.
- Every asset is credited in the README with its author, source and license.
- The art is kept simple: darkness, light and sound carry the mood.
