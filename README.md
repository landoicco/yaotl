# 🧟 Yaotl

![LÖVE](https://img.shields.io/badge/L%C3%96VE-11.5-e64a8b?logo=lua&logoColor=white)
![Lua](https://img.shields.io/badge/Lua-5.1%20%2F%20LuaJIT-2c2d72?logo=lua&logoColor=white)
![Nix](https://img.shields.io/badge/Nix-flake-5277c3?logo=nixos&logoColor=white)
![Status](https://img.shields.io/badge/status-in%20development-orange)

A top-down horror shooter made with [LÖVE](https://love2d.org/). You wake up in a dark, unknown place with only a flashlight, and the only way out is forward.

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

### 📦 Downloads

Every pull request builds the game for Windows and Linux; the builds are under the run's *Artifacts* in the Actions tab. Tagged versions are published as [releases](https://github.com/landoicco/yaotl/releases).

- **Windows:** extract the whole zip first, then run `yaotl.exe`; it does not run from inside the zip.
- **Linux:** make the AppImage executable (`chmod +x yaotl-linux.AppImage`) and run it. It needs FUSE 2 (`libfuse2`).

### 🛠️ Building

`tools/build.sh` builds the same files into `build/`. It needs `curl`, `zip`, `unzip` and `squashfs-tools`. With Nix:

```bash
nix shell nixpkgs#zip nixpkgs#unzip nixpkgs#squashfsTools --command tools/build.sh
```

## 🔍 Checking the code

CI rejects code that fails [luacheck](https://github.com/lunarmodules/luacheck) or [StyLua](https://github.com/JohnnyMorganz/StyLua). Both come with the Nix dev shell, at the same versions CI uses:

```bash
luacheck .
stylua --check .  # or `stylua .` to format
```

## 🎮 Controls

| Action | Input |
|---|---|
| Move | `W` `A` `S` `D` |
| Aim | Mouse |
| Shoot | Left click |
| Reload | `R` |
| Switch between handgun and flashlight | `Q` |

## 💡 Ideas

Under consideration, not yet part of the design:

- 🔫 **Finding a shotgun.** A second weapon, found after the handgun.
- 🧪 **Zombie variants by recoloring.** One zombie sprite, with each type getting its own color (a tint or a shader) and scale, so new types need no new art.
- 🍎 **A macOS build.** Built from LÖVE's official `love.app` like the Windows and Linux ones. It would not be signed, so macOS would ask players to allow it by hand.
- 🔋 **Pickups.** Batteries for the flashlight, health and ammo, found along the way.
- 🚪 **The ending.** Either the player escapes the dark place, or wakes up.

## 🙏 Credits

All art and audio come from free third-party assets. Each one is credited here with its author, source and license.

| Asset | Author | Source | License |
|---|---|---|---|
| Survivor sprites | rileygombart | [Animated Top Down Survivor Player](https://opengameart.org/content/animated-top-down-survivor-player) | [CC-BY 3.0](https://creativecommons.org/licenses/by/3.0/) |
| Zombie sprites | rileygombart | [Animated Top Down Zombie](https://opengameart.org/content/animated-top-down-zombie) | [CC0](https://creativecommons.org/publicdomain/zero/1.0/) |
