-- The player's flashlight: a cone of light from the lens and a faint halo around the holder
local Flashlight = {}
Flashlight.__index = Flashlight

local COLOR = { 1, 0.95, 0.8 } -- warm white
local CONE_RANGE = 380 -- pixels
local CONE_INNER = 0.3 -- half-angle at full light, radians
local CONE_OUTER = 0.45 -- half-angle where the light ends
-- Spill around the holder, just enough to see them
local HALO_RANGE = 90
local HALO_INTENSITY = 0.25

function Flashlight.new()
    local self = setmetatable({}, Flashlight)
    self.cone = {
        x = 0,
        y = 0,
        angle = 0,
        range = CONE_RANGE,
        innerAngle = CONE_INNER,
        outerAngle = CONE_OUTER,
        color = COLOR,
        intensity = 1,
    }
    self.halo = {
        x = 0,
        y = 0,
        angle = 0,
        range = HALO_RANGE,
        innerAngle = math.pi,
        outerAngle = math.pi,
        color = COLOR,
        intensity = HALO_INTENSITY,
    }
    return self
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
