# 🧟 Yaotl

![LÖVE](https://img.shields.io/badge/L%C3%96VE-11.5-e64a8b?logo=lua&logoColor=white)
![Lua](https://img.shields.io/badge/Lua-5.1%20%2F%20LuaJIT-2c2d72?logo=lua&logoColor=white)
![Nix](https://img.shields.io/badge/Nix-flake-5277c3?logo=nixos&logoColor=white)
![Status](https://img.shields.io/badge/status-in%20development-orange)

A top-down survival shooter made with [LÖVE](https://love2d.org/). Clear a house of zombies, wave after wave, with a single gun and limited ammo.

📄 See the [Game Design Document](docs/GDD.md) for the design.

## 🪶 About the name

*Yaotl* (pronounced *YA-otl*) is a Nahuatl word meaning **enemy**, and by extension **combat** or **war**. Some sources also translate it as **warrior**, which fits a game about a lone survivor facing a horde. See the entry in the [Gran Diccionario Náhuatl](https://gdn.iib.unam.mx/diccionario/yaotl/18899) (UNAM).

## 🚀 Running the game

The game targets **LÖVE 11.5**.

### ❄️ With Nix

```bash
nix develop
love .
```

### 💻 Without Nix

Install [LÖVE 11.5](https://love2d.org/), then run from the project root:

```bash
love .
```

## 🎮 Controls

| Action | Input |
|---|---|
| Move | `W` `A` `S` `D` |
| Aim | Mouse |
| Shoot | Left click |

## 💡 Ideas

Under consideration, not yet part of the design:

- 🎨 **Art from [Riley Gombart](https://opengameart.org/users/rileygombart).** His animated survivor and zombie sprites have many states (idle, move, shoot, reload, melee), which fits a game where reloading matters.
- 🧪 **Zombie variants by recoloring.** One zombie sprite, with each type getting its own color (a tint or a shader) and scale, so new types need no new art.
- 🔦 **A dark house.** The house stays in darkness and the player only sees what the flashlight and a few fixed lights (lamps, windows) reveal. This adds tension and gives assets from different sources a unified look.
- 🔁 **Flashlight or weapon.** The player switches between the flashlight and the weapon and cannot shoot while holding the flashlight, so seeing and defending become a trade-off.

## 🙏 Credits

All art and audio come from free third-party assets. Each one is credited here with its author, source and license.
