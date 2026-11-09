# 0001. Player states as a hierarchical state machine

**Status:** Accepted

## Context

The player holds either the handgun or the flashlight. With the handgun, the player can be ready, shooting or reloading. Each combination changes what input does and which torso animation plays:

- With the flashlight, the player cannot shoot.
- While shooting or reloading, the player cannot shoot or start a reload.
- `Q` switches between the handgun and the flashlight.

Tracking this with flags such as `isReloading` and `hasFlashlight` would spread the rules across `if` statements, and every new action would multiply the cases to check.

## Decision

Use the **State** pattern from [*Game Programming Patterns*](https://gameprogrammingpatterns.com/state.html), with a **hierarchical** state machine:

```
flashlight
handgun (superstate)
├── handgunReady
├── handgunShooting
└── handgunReloading
```

- **One table per state** in `src/game/player_states.lua`. Each implements `enter`, `update`, `keypressed`, `mousepressed`, and `torso`, which returns the name of the torso animation.
- **Hierarchy through metatables.** Handgun substates use `__index` to inherit from the `Handgun` superstate and override only what differs. Switching to the flashlight is defined once, in `Handgun`.
- **Static states.** States hold no data of their own, so each is a single shared table and every function receives the player it acts on. The book calls these *static states*.
- **Animations set the timing.** Shooting and reloading end when their animation finishes, so the reload time is the length of the reload animation.
- **`Q` cancels a reload.** Since switching is defined in the superstate, it works from every handgun substate. Interrupting a reload loses it, which adds tension.

## Consequences

- Each state's rules live in one place. Adding a state, such as a melee attack or the shotgun, does not touch the others.
- The player module only delegates input and asks the state which torso animation to play.
- If a state ever needs its own data, such as a timer independent of the animation, it would have to become an instance created on `enter` instead of a shared table.
- Tying the reload time to the animation keeps them in sync, but changing the reload time means changing the animation speed.
