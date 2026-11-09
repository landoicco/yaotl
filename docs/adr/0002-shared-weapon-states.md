# 0002. One set of states for every weapon

**Status:** Accepted. Generalizes the handgun states of [ADR 0001](0001-player-state-machine.md).

## Context

ADR 0001 gave the handgun its own states: ready, shooting and reloading. The shotgun needs the same three, with the same rules: it cannot shoot while reloading, `R` reloads, and the animations set the timing.

Copying the handgun states for the shotgun would double the code, and every rule change would have to be made twice. A third weapon would make it worse.

The player also holds three things now, not two. The key scheme is in the [GDD](../GDD.md#3-player): `Q` switches between the flashlight and the last weapon used, and `1` and `2` take out the handgun or the shotgun.

## Decision

The handgun states become **weapon states** that serve every weapon:

```
flashlight
armed (superstate)
├── weaponReady
├── weaponShooting
└── weaponReloading
```

- **The player holds the current weapon** in `player.weapon`. The states act on it: they shoot it, reload it and ask it for its animations.
- **What changes between weapons is data, not states.** Each weapon's stats (magazine, reserve, pellets per shot, spread, muzzle position, flash size) live in a table in `src/game/player.lua`.
- **Animations are named after the weapon**, such as `shotgunReload`, so `weapon:animation("Reload")` finds them. The shot and reload times are still set by the animations.
- **`player.weapon` is also the last weapon used.** It keeps its value while the flashlight is out, so `Q` takes it out again without extra state.
- **Switching weapons works from every weapon state**, because it lives in the `armed` superstate. Like switching to the flashlight, it cancels a reload.

## Consequences

- Adding a weapon means adding its stats, its animations and a key. No new states.
- The states stay static, as in ADR 0001: the data lives in the player and its weapons.
- A weapon that needs different rules, such as reloading one shell at a time, would need states of its own. They would still inherit from `armed`.
