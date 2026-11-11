# 0006. Audio: sounds by name, tied to animation frames

**Status:** Accepted.

## Context

The game is carried by its systems more than by its art, and sound builds much of the tension. The first sounds are the player's: shots, reloads, melee and the flashlight, with an ambient track underneath. They must:

- Be easy to replace. Good free sounds take time to find, so placeholders come first and get swapped one by one.
- Stay in step with what is on screen: a reload's clicks when the hand reaches the gun, a swing's whoosh before the blow lands.
- Not sound the same on every repeat, since shots and steps repeat constantly.

## Decision

### A registry plays sounds by name

`src/game/sound.lua` maps each sound's name to its file, volume and pitch variation. The rest of the code only says `Sound.play("handgunShot")`, never a path. Replacing a sound is one line in the registry, or a new file with the same name.

- **Loaded once, cloned per play.** Each effect is loaded once as a static source. Every play is a clone, so a sound can overlap itself, as quick shots do.
- **Pitch varies a little on every play,** a few percent up or down, so repeats do not sound identical.
- **Music is streamed.** Tracks are read from disk as they play instead of loaded whole, and loop. The music starts in `main.lua`, outside the world, so it keeps playing when the world restarts.
- **Channels.** Each sound belongs to a channel, effects or music, with its own volume on top of the sound's. One number balances the music under the effects, and a future options menu has a place to plug in.

### Animations say which frames make sounds

An animation's definition lists sounds by frame, next to the `hitFrame` of [ADR 0005](0005-melee-states.md):

```lua
handgunReload = {
    ...
    sounds = { [3] = "clipOut", [13] = "clipIn" },
},
```

`Animation:enteredFrame(index)` tells whether the last update entered a frame. It compares the time before and after the update, so a frame is not missed when a long update skips past it, and it handles a loop wrapping around. It reports nothing while an animation plays backwards, as the feet do when walking backwards. After a reset, the first update enters the first frame.

The player plays the sounds of the frames the torso enters. As a result:

- The sounds follow the animation, whatever its speed.
- A reload cut short by a weapon switch stops making sounds, with no special case.
- The shotgun loads all its rounds at once, but three shells are heard along the animation.

Sounds tied to an event rather than a frame are played where the event happens: the shot in `Player:shoot`, the melee hit only when `World:strike` reports that the blow hit a zombie, the flashlight click when holding it changes.

### Placeholder effects are generated

`tools/sfx` is a small LÖVE program that writes some effects as WAV files, from recipes of filtered noise and falling tones. It runs with the LÖVE of the dev shell, so it adds nothing to the Nix flake. Each sound uses a fixed seed, so every run writes the same bytes and changing a recipe changes only that sound's file in git.

The generated files are ordinary files for the game, which cannot tell them from downloaded ones. `tools/` is not part of the build.

## Consequences

- Replacing a sound touches the registry and the README's credits, never the code that plays it.
- Any animation can get sounds through its definition, such as footsteps on the feet animations: `enteredFrame` already handles loops.
- Sounds are not positioned yet: the player's own sounds play at the listener. Zombie sounds will need positions, a hearing range and walls muffling them, which `Map:castRay` can answer as it does for light.
- Generated sounds sound like game effects, not recordings. They are placeholders.
