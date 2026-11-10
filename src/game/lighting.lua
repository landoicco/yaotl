-- Darkness over the scene, lifted where lights shine
-- Lights add up in a lightmap, which then multiplies the scene below it
local Lighting = {}
Lighting.__index = Lighting

local SHADER_PATH = "assets/shaders/light.glsl"
-- Points along the edge of a light's area
local ARC_SEGMENTS = 32

-- ambient: the color of the darkness, { r, g, b }
function Lighting.new(ambient)
    local self = setmetatable({}, Lighting)
    self.ambient = ambient
    self.canvas = love.graphics.newCanvas()
    self.shader = love.graphics.newShader(SHADER_PATH)
    return self
end

-- A light lighting every direction around it, not a cone
local function isPoint(light)
    return light.outerAngle >= math.pi
end

-- Polygon a light can reach, starting at the light so it fills as a fan
-- The only place that decides what is lit: walls will clip this area
function Lighting.litArea(light)
    local points = { light.x, light.y }
    local from = light.angle - light.outerAngle
    local to = light.angle + light.outerAngle
    if isPoint(light) then
        from, to = 0, 2 * math.pi
    end

    for i = 0, ARC_SEGMENTS do
        local angle = from + (to - from) * i / ARC_SEGMENTS
        table.insert(points, light.x + math.cos(angle) * light.range)
        table.insert(points, light.y + math.sin(angle) * light.range)
    end
    return points
end

-- The camera only moves the view, so direction and range need no conversion, only the origin
function Lighting:drawLight(light)
    local shader = self.shader
    shader:send("origin", { love.graphics.transformPoint(light.x, light.y) })
    shader:send("direction", { math.cos(light.angle), math.sin(light.angle) })
    shader:send("range", light.range)
    if isPoint(light) then
        -- Every direction falls inside the cone
        shader:send("innerCos", -1)
        shader:send("outerCos", -2)
    else
        shader:send("innerCos", math.cos(light.innerAngle))
        shader:send("outerCos", math.cos(light.outerAngle))
    end

    local r, g, b = unpack(light.color)
    love.graphics.setColor(r * light.intensity, g * light.intensity, b * light.intensity)
    love.graphics.polygon("fill", Lighting.litArea(light))
end

-- Darken everything drawn so far, except where the lights reach
-- light: x, y, angle, range, color, intensity, and the half-angles of its cone:
-- innerAngle (full light) and outerAngle (no light); outerAngle >= pi makes a point light
function Lighting:draw(lights)
    love.graphics.push("all")
    love.graphics.setCanvas(self.canvas)
    love.graphics.clear(self.ambient[1], self.ambient[2], self.ambient[3], 1)
    love.graphics.setBlendMode("add")
    love.graphics.setShader(self.shader)
    for _, light in ipairs(lights) do
        if light.intensity > 0 then
            self:drawLight(light)
        end
    end
    love.graphics.pop()

    -- The lightmap covers the screen, whatever the view transform
    love.graphics.push("all")
    love.graphics.origin()
    love.graphics.setBlendMode("multiply", "premultiplied")
    love.graphics.draw(self.canvas)
    love.graphics.pop()
end

return Lighting
