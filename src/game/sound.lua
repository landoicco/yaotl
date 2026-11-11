-- Sound effects, played by name. Each name maps to one file here, so replacing a sound
-- means changing one line, never the code that plays it
local Sound = {}

local SOUNDS_DIR = "assets/sounds/"
local DEFAULT_PITCH_VARIATION = 0.05

-- file: in SOUNDS_DIR; volume: from 0 to 1
-- pitchVariation: how far each play may shift the pitch, up or down, so repeats do not sound the same
-- stylua: ignore
local SOUNDS = {
    clipOut = { file = "clip_out.wav", volume = 0.8 },
    clipIn = { file = "clip_in.wav", volume = 0.8 },
    shellIn = { file = "shell_in.wav", volume = 0.8, pitchVariation = 0.1 },
}

-- Loaded once; every play is a clone, so the same sound can overlap itself
local sources = {}
for name, definition in pairs(SOUNDS) do
    sources[name] = love.audio.newSource(SOUNDS_DIR .. definition.file, "static")
end

function Sound.play(name)
    local definition = SOUNDS[name]
    local variation = definition.pitchVariation or DEFAULT_PITCH_VARIATION
    local source = sources[name]:clone()
    source:setVolume(definition.volume)
    source:setPitch(1 + (love.math.random() * 2 - 1) * variation)
    source:play()
end

return Sound
