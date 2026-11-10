# 0005. Melee as a substate of whatever is held

**Status:** Accepted. Extends the state machine of [ADR 0001](0001-player-state-machine.md) and [ADR 0002](0002-shared-weapon-states.md).

## Context

The player can strike with whatever is held: a punch with the flashlight, a blow with the butt of the handgun or the shotgun. Each has its own animation. A strike must:

- Keep what is held working: the flashlight stays lit while punching.
- Go back to holding the same thing once the swing ends.
- Land once per swing, on the frame where the blow connects, which differs between animations.
- Not happen while running, which is for fleeing.

## Decision

### A melee substate under each holder

```
flashlight (superstate)
└── flashlightMelee
armed (superstate)
├── weaponReady
├── weaponShooting
├── weaponMelee
└── weaponReloading
```

- **`flashlightMelee` inherits from `flashlight`**, which becomes a superstate as `armed` already was. Whether the flashlight is on is a property of the state, `holdsFlashlight`, which the substate inherits: the light stays on with no special case.
- **`weaponMelee` is one more weapon state.** As in ADR 0002, it serves every weapon: `weapon:animation("Melee")` finds the handgun's or the shotgun's.
- **Both go back to their holder's ready state** when the swing's animation ends. Switching with `Q`, `1` or `2` cancels a swing, as it cancels a reload.

### The hit frame lives in the animation

Each melee animation's definition in `src/game/player.lua` has a `hitFrame`, the frame where the blow connects, found by measuring how far each frame reaches forward. `Player:updateMelee` strikes once the torso's animation reaches it.

This also answers whether the swing is on screen yet: when the state changes, the torso still plays the previous animation for a frame, and that animation has no hit frame. The check needs no extra flag.

The strike itself is resolved by the world, as shots are: the player calls `strike(x, y, angle)`, and `World:strike` shoves every zombie in reach.

### Running blocks the hands in one place

`Player:mousepressed` ignores the mouse while running, so neither shooting nor striking needs its own check. Running is not a state: it concerns the legs, and the states describe the hands. Mixing them would double every state.

## Consequences

- A new held item with a melee animation gets its strike for free: its animation and hit frame are enough.
- Movement (walking, running) and the hands (the states) stay independent. If running ever needs rules of its own, such as stamina, it could become a second state machine for the legs, as *Game Programming Patterns* suggests for concurrent states.
- The strike's reach and arc live in the world, the shove's strength in the zombie. Tuning one does not touch the states.
