# Yaotl: Game Design Document

| | |
|---|---|
| **Genre** | Top-down survival shooter |
| **Engine** | LÖVE 11.5 (Lua) |
| **Scope** | Small to medium, single player |

## 1. Vision

A survivor has to clear a house overrun by zombies, wave after wave. The scope stays small to medium, so that everything in the game is finished and polished.

## 2. Player

- Moves with WASD. The torso faces the mouse cursor and the feet follow the movement: walking, walking backwards or strafing.
- Holds either the weapon or the flashlight, and switches between them with `Q`.
- Cannot shoot while holding the flashlight, so seeing and defending become a trade-off.

## 3. Weapon

- The player starts with a handgun.
- Limited ammo, with reloading.
- Reloading is manual, with `R`, and never automatic: the player has to remember to reload.

## 4. Enemies

- Zombies, arriving in waves.
- A zombie takes three handgun shots to kill, and fades out when it dies.
- They enter the house through doors and windows.
- They navigate the house toward the player using a flow field.

## 5. World

- The setting is a house.
- The map is larger than the screen, and a camera follows the player.
- The map is built in [Tiled](https://www.mapeditor.org/) and loaded with a custom loader.

## 6. Technical design

- Design patterns come from Robert Nystrom's [*Game Programming Patterns*](https://gameprogrammingpatterns.com/).
- A pattern is introduced only when the project's complexity calls for it, and it is documented here when that happens.
- Design decisions are recorded as [Architecture Decision Records](adr/README.md).

### Patterns in use

| Pattern | Where | Decision |
|---|---|---|
| State (hierarchical) | Player states | [ADR 0001](adr/0001-player-state-machine.md) |
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

### Distribution

- A CI pipeline builds executables of the game for Linux and Windows.

## 7. Assets

- All art and audio are free third-party assets.
- Every asset is credited in the README with its author, source and license.
- The setting and tone will be defined by the assets found.
