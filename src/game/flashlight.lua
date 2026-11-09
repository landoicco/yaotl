-- The player's flashlight: a cone of light from the lens and a faint halo around the holder
-- The battery drains while it is on, and the light falters as it runs low
local Flashlight = {}
Flashlight.__index = Flashlight

local COLOR = { 1, 0.95, 0.8 } -- warm white
local CONE_RANGE = 380 -- pixels
local CONE_INNER = 0.3 -- half-angle at full light, radians
local CONE_OUTER = 0.45 -- half-angle where the light ends
-- Spill around the holder, just enough to see them
local HALO_RANGE = 90
local HALO_INTENSITY = 0.25

local BATTERY_LIFE = 120 -- seconds of light on a full charge
-- Below this charge the light dims and flickers, worse the lower it gets
local LOW_CHARGE = 0.3
-- How much the light dims when the battery is almost empty
local DIM_DEPTH = 0.4
-- Slow, uneven wobble of the brightness
local WOBBLE_SPEED = 6 -- noise units per second
local WOBBLE_DEPTH = 0.3
-- Short blackouts; they get more frequent as the charge drops
local DROPOUT_SPEED = 9
local DROPOUT_CHANCE = 0.4 -- noise threshold on an almost empty battery
local DROPOUT_LEVEL = 0.05

-- A light with the fields Lighting expects
local function newLight(range, innerAngle, outerAngle)
    return {
        x = 0,
        y = 0,
        angle = 0,
        range = range,
        innerAngle = innerAngle,
        outerAngle = outerAngle,
        color = COLOR,
        intensity = 0,
    }
end

function Flashlight.new()
    local self = setmetatable({}, Flashlight)
    self.cone = newLight(CONE_RANGE, CONE_INNER, CONE_OUTER)
    self.halo = newLight(HALO_RANGE, math.pi, math.pi)
    self.charge = 1 -- from 1 (full) to 0 (empty)
    self.time = 0 -- drives the flicker noise
    return self
end

-- Brightness from 0 to 1 for the current charge and moment
function Flashlight:brightness()
    if self.charge <= 0 then
        return 0
    end

    -- 0 while the charge is fine, 1 when the battery is about to die
    local low = math.max(1 - self.charge / LOW_CHARGE, 0)
    local brightness = 1 - low * DIM_DEPTH
    brightness = brightness * (1 - low * WOBBLE_DEPTH * love.math.noise(self.time * WOBBLE_SPEED))

    -- A second noise channel, so blackouts do not follow the wobble
    if love.math.noise(self.time * DROPOUT_SPEED, 100) < low * DROPOUT_CHANCE then
        brightness = brightness * DROPOUT_LEVEL
    end
    return brightness
end

-- Drains the battery only while the flashlight is on; an empty one stays empty
function Flashlight:update(dt, isOn)
    self.time = self.time + dt
    if isOn then
        self.charge = math.max(self.charge - dt / BATTERY_LIFE, 0)
    end

    local brightness = self:brightness()
    self.cone.intensity = brightness
    self.halo.intensity = brightness * HALO_INTENSITY
end

-- The cone starts at the lens and points along angle; the halo surrounds the holder
function Flashlight:place(lensX, lensY, angle, holderX, holderY)
    self.cone.x, self.cone.y, self.cone.angle = lensX, lensY, angle
    self.halo.x, self.halo.y = holderX, holderY
end

function Flashlight:addLights(lights)
    table.insert(lights, self.cone)
    table.insert(lights, self.halo)
end

return Flashlight
