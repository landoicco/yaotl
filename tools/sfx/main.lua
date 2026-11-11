-- Generates the placeholder sound effects as WAV files, from the recipes below.
-- Run it from the project root:
--   nix develop -c love tools/sfx
-- Each sound is a mix of layers: filtered noise for cracks, hisses and whooshes,
-- and a falling tone for thumps. A fixed seed per sound keeps the files the same on every run.

local OUTPUT_DIR = "assets/sounds/"
local SAMPLE_RATE = 44100
local PEAK = 0.9 -- every sound is normalized to this peak; the game sets the volume

-- Layer fields, all optional:
--   kind: "noise" or "tone"; gain: loudness in the mix; delay: start time, in seconds
--   attack, decay: seconds to rise to full, then the time constant of the fall
--   from, to, sweep: a tone's frequency, falling from `from` to `to` with time constant `sweep`
--   lowpass, lowpassTo, highpass: a noise's filter cutoffs, in Hz; lowpass sweeps to lowpassTo
-- drive: how hard the mix is saturated; more gives more punch
-- stylua: ignore
local SOUNDS = {
    handgun_shot = {
        duration = 0.45, drive = 2.5,
        layers = {
            { kind = "noise", decay = 0.04, lowpass = 9000, lowpassTo = 1500 },
            { kind = "noise", decay = 0.12, lowpass = 1200, lowpassTo = 300, gain = 0.6 },
            { kind = "tone", decay = 0.08, from = 160, to = 45, sweep = 0.05, gain = 0.9 },
        },
    },
    shotgun_shot = {
        duration = 0.8, drive = 3,
        layers = {
            { kind = "noise", decay = 0.06, lowpass = 7000, lowpassTo = 1000 },
            { kind = "noise", decay = 0.25, lowpass = 900, lowpassTo = 200, gain = 0.8 },
            { kind = "tone", decay = 0.15, from = 110, to = 35, sweep = 0.08 },
        },
    },
    -- Trigger and hammer on an empty chamber
    dry_fire = {
        duration = 0.1, drive = 1,
        layers = {
            { kind = "noise", decay = 0.004, lowpass = 8000, highpass = 2500 },
            { kind = "tone", decay = 0.006, from = 1800, to = 1700, gain = 0.4 },
            { kind = "noise", delay = 0.035, decay = 0.005, lowpass = 6000, highpass = 1500, gain = 0.8 },
        },
    },
    -- Air pushed by the arm: dull and low, so it does not sound like a blade
    melee_swing = {
        duration = 0.3, drive = 1,
        layers = {
            { kind = "noise", attack = 0.12, decay = 0.08, lowpass = 250, lowpassTo = 800, highpass = 120 },
        },
    },
    melee_hit = {
        duration = 0.3, drive = 2,
        layers = {
            { kind = "tone", decay = 0.06, from = 120, to = 50, sweep = 0.04 },
            { kind = "noise", decay = 0.05, lowpass = 800, lowpassTo = 200, gain = 0.7 },
        },
    },
    flashlight_click = {
        duration = 0.06, drive = 1,
        layers = {
            { kind = "noise", decay = 0.002, lowpass = 10000, highpass = 3000 },
            { kind = "tone", decay = 0.004, from = 3000, to = 3000, gain = 0.3 },
            { kind = "noise", delay = 0.012, decay = 0.002, lowpass = 8000, highpass = 3000, gain = 0.5 },
        },
    },
}

-- Moves from `from` toward `to` as t grows, with time constant `tau`
local function approach(from, to, t, tau)
    return to + (from - to) * math.exp(-t / tau)
end

-- How far a one-pole filter moves toward its input each sample, for a cutoff in Hz
local function filterCoefficient(cutoff)
    return 1 - math.exp(-2 * math.pi * cutoff / SAMPLE_RATE)
end

local function envelope(layer, t)
    local attack = layer.attack or 0.001
    if t < attack then
        return t / attack
    end
    return math.exp(-(t - attack) / layer.decay)
end

-- Adds one layer into the samples
local function mixLayer(samples, layer, duration)
    local gain = layer.gain or 1
    local first = math.floor((layer.delay or 0) * SAMPLE_RATE) + 1
    local phase, low, highLow = 0, 0, 0
    for i = first, #samples do
        local t = (i - first) / SAMPLE_RATE
        local value
        if layer.kind == "tone" then
            local frequency = approach(layer.from, layer.to, t, layer.sweep or duration)
            phase = phase + 2 * math.pi * frequency / SAMPLE_RATE
            value = math.sin(phase)
        else
            local cutoff = approach(layer.lowpass, layer.lowpassTo or layer.lowpass, t, duration / 3)
            low = low + filterCoefficient(cutoff) * (math.random() * 2 - 1 - low)
            value = low
            if layer.highpass then
                -- Highpass: what is left once the lows are taken out
                highLow = highLow + filterCoefficient(layer.highpass) * (value - highLow)
                value = value - highLow
            end
        end
        samples[i] = samples[i] + value * envelope(layer, t) * gain
    end
end

local function render(recipe)
    local samples = {}
    for i = 1, math.floor(recipe.duration * SAMPLE_RATE) do
        samples[i] = 0
    end
    for _, layer in ipairs(recipe.layers) do
        mixLayer(samples, layer, recipe.duration)
    end

    -- Saturate, then scale so the loudest sample hits PEAK
    local loudest = 0
    for i, sample in ipairs(samples) do
        samples[i] = math.tanh(sample * recipe.drive)
        loudest = math.max(loudest, math.abs(samples[i]))
    end
    for i, sample in ipairs(samples) do
        samples[i] = sample * PEAK / loudest
    end
    return samples
end

-- Little-endian unsigned integer of `bytes` bytes
local function int(value, bytes)
    local chars = {}
    for i = 1, bytes do
        chars[i] = string.char(value % 256)
        value = math.floor(value / 256)
    end
    return table.concat(chars)
end

-- 16-bit mono PCM
local function writeWav(path, samples)
    local data = {}
    for i, sample in ipairs(samples) do
        local value = math.floor(sample * 32767 + 0.5)
        data[i] = int(value % 65536, 2)
    end
    local dataSize = #samples * 2

    local file = assert(io.open(path, "wb"))
    file:write("RIFF", int(36 + dataSize, 4), "WAVE")
    file:write("fmt ", int(16, 4), int(1, 2), int(1, 2), int(SAMPLE_RATE, 4), int(SAMPLE_RATE * 2, 4))
    file:write(int(2, 2), int(16, 2))
    file:write("data", int(dataSize, 4), table.concat(data))
    file:close()
end

function love.load()
    for name, recipe in pairs(SOUNDS) do
        math.randomseed(1)
        writeWav(OUTPUT_DIR .. name .. ".wav", render(recipe))
        print("wrote " .. OUTPUT_DIR .. name .. ".wav")
    end
    love.event.quit()
end
