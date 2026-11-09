-- The flash of a shot: a brief burst of light at the muzzle that fades out fast
local MuzzleFlash = {}
MuzzleFlash.__index = MuzzleFlash

local COLOR = { 1, 0.75, 0.4 } -- warm orange
local RANGE = 250 -- pixels
-- Each shot's range varies by up to this fraction, so no two flashes look alike
local RANGE_JITTER = 0.15
local DURATION = 0.08 -- seconds from full light to dark

function MuzzleFlash.new()
    local self = setmetatable({}, MuzzleFlash)
    self.light = {
        x = 0,
        y = 0,
        angle = 0,
        range = RANGE,
        innerAngle = math.pi,
        outerAngle = math.pi,
        color = COLOR,
        intensity = 0,
    }
    self.remaining = 0 -- seconds left of the current flash
    return self
end

-- Light up at the muzzle; the flash stays where the shot was fired
function MuzzleFlash:fire(x, y)
    self.light.x, self.light.y = x, y
    self.light.range = RANGE * (1 + (love.math.random() * 2 - 1) * RANGE_JITTER)
    self.remaining = DURATION
end

-- Brightness comes before the countdown, so the first frame of a shot is at full light
function MuzzleFlash:update(dt)
    -- Squared, so the light drops fast and lingers a little at the end
    local left = self.remaining / DURATION
    self.light.intensity = left * left
    self.remaining = math.max(self.remaining - dt, 0)
end

function MuzzleFlash:addLights(lights)
    table.insert(lights, self.light)
end

return MuzzleFlash
