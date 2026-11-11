-- Sound effects and music, played by name. Each name maps to one file here, so replacing a sound
-- means changing one line, never the code that plays it
local Sound = {}

local SOUNDS_DIR = "assets/sounds/"
local DEFAULT_PITCH_VARIATION = 0.05

-- How loud each kind of sound is, on top of each sound's own volume, so the music sits under the effects
local CHANNELS = { effects = 1, music = 0.5 }

-- file: in SOUNDS_DIR; volume: from 0 to 1
-- pitchVariation: how far each play may shift the pitch, up or down, so repeats do not sound the same
-- stylua: ignore
local SOUNDS = {
    handgunShot = { file = "handgun_shot.wav", volume = 1, pitchVariation = 0.08 },
    shotgunShot = { file = "shotgun_shot.wav", volume = 1, pitchVariation = 0.08 },
    dryFire = { file = "dry_fire.wav", volume = 0.7 },
    meleeSwing = { file = "melee_swing.wav", volume = 0.6, pitchVariation = 0.1 },
    meleeHit = { file = "melee_hit.wav", volume = 0.9, pitchVariation = 0.1 },
    flashlightClick = { file = "flashlight_click.wav", volume = 0.5 },
    clipOut = { file = "clip_out.wav", volume = 0.8 },
    clipIn = { file = "clip_in.wav", volume = 0.8 },
    shellIn = { file = "shell_in.wav", volume = 0.8, pitchVariation = 0.1 },
}

-- Looping tracks, streamed from disk instead of loaded whole
-- stylua: ignore
local MUSIC = {
    ambient = { file = "ambient.ogg", volume = 1 },
}

-- Loaded once; every play is a clone, so the same sound can overlap itself
local sources = {}
for name, definition in pairs(SOUNDS) do
    sources[name] = love.audio.newSource(SOUNDS_DIR .. definition.file, "static")
end

-- The track playing now, if any
local music

function Sound.play(name)
    local definition = SOUNDS[name]
    local variation = definition.pitchVariation or DEFAULT_PITCH_VARIATION
    local source = sources[name]:clone()
    source:setVolume(definition.volume * CHANNELS.effects)
    source:setPitch(1 + (love.math.random() * 2 - 1) * variation)
    source:play()
end

-- Loops a track, replacing the one playing
function Sound.playMusic(name)
    if music then
        music:stop()
    end
    local definition = MUSIC[name]
    music = love.audio.newSource(SOUNDS_DIR .. definition.file, "stream")
    music:setLooping(true)
    music:setVolume(definition.volume * CHANNELS.music)
    music:play()
end

return Sound
