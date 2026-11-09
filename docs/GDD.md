# Yaotl: Game Design Document

| | |
|---|---|
| **Genre** | Top-down survival shooter |
| **Engine** | LÖVE 11.5 (Lua) |
| **Scope** | Small to medium, single player |

## 1. Vision

A survivor has to clear a house overrun by zombies, wave after wave. The scope stays small to medium, so that everything in the game is finished and polished.

## 2. Player

- Moves with WASD and faces the mouse cursor.
- Carries a single weapon.

## 3. Weapon

- A single weapon.
- Limited ammo, with reloading.

## 4. Enemies

- Zombies, arriving in waves.
- They enter the house through doors and windows.
- They navigate the house toward the player using a flow field.

## 5. World

- The setting is a house.
- The map is larger than the screen, and a camera follows the player.
- The map is built in [Tiled](https://www.mapeditor.org/) and loaded with a custom loader.

## 6. Technical design

- Design patterns come from Robert Nystrom's [*Game Programming Patterns*](https://gameprogrammingpatterns.com/).
- A pattern is introduced only when the project's complexity calls for it, and it is documented here when that happens.

### Distribution

- A CI pipeline builds executables of the game for Linux and Windows.

## 7. Assets

- All art and audio are free third-party assets.
- Every asset is credited in the README with its author, source and license.
- The setting and tone will be defined by the assets found.
