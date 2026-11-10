-- Darkness over the scene, lifted where lights shine (see docs/adr/0003-lighting.md)
-- Lights add up in a lightmap, which then multiplies the scene below it
local Lighting = {}
Lighting.__index = Lighting

local SHADER_PATH = "assets/shaders/light.glsl"
-- Points along the edge of a light's area where no wall stops it
local ARC_SEGMENTS = 32
-- Rays aimed just beside each wall corner, in radians, to see past it
local CORNER_OFFSET = 0.0001
-- How far light goes into a wall, in pixels, so the edges of the walls show
local WALL_BLEED = 6
-- Most vertices a light's area can have
local MAX_VERTICES = 4096

-- ambient: the color of the darkness, { r, g, b }; map: the walls that block the light
function Lighting.new(ambient, map)
    local self = setmetatable({}, Lighting)
    self.ambient = ambient
    self.map = map
    self.canvas = love.graphics.newCanvas()
    self.shader = love.graphics.newShader(SHADER_PATH)
    -- A fan from the light, so a concave area fills correctly
    self.mesh = love.graphics.newMesh({ { "VertexPosition", "float", 2 } }, MAX_VERTICES, "fan", "stream")
    return self
end

-- A light lighting every direction around it, not a cone
local function isPoint(light)
    return light.outerAngle >= math.pi
end

-- Wrap an angle to the range [-pi, pi)
local function normalizeAngle(angle)
    return (angle + math.pi) % (2 * math.pi) - math.pi
end

-- Angles of the rays to cast, relative to the light's direction and sorted:
-- evenly spaced along the light's edge, plus one at and beside every wall corner in reach
function Lighting:rayAngles(light, halfWidth)
    local angles = {}
    for i = 0, ARC_SEGMENTS do
        table.insert(angles, -halfWidth + 2 * halfWidth * i / ARC_SEGMENTS)
    end

    for _, corner in ipairs(self.map:cornersNear(light.x, light.y, light.range)) do
        local angle = normalizeAngle(math.atan2(corner.y - light.y, corner.x - light.x) - light.angle)
        for _, aimed in ipairs({ angle - CORNER_OFFSET, angle, angle + CORNER_OFFSET }) do
            if math.abs(aimed) < halfWidth then
                table.insert(angles, aimed)
            end
        end
    end

    table.sort(angles)
    return angles
end

-- Area a light reaches, as the vertices of a fan that starts at the light
-- The only place that decides what is lit: rays stop a little into the first wall they meet
function Lighting:litArea(light)
    local halfWidth = isPoint(light) and math.pi or light.outerAngle
    local vertices = { { light.x, light.y } }
    for _, relative in ipairs(self:rayAngles(light, halfWidth)) do
        local angle = light.angle + relative
        local dirX, dirY = math.cos(angle), math.sin(angle)
        local distance = light.range
        local wallDistance = self.map:castRay(light.x, light.y, dirX, dirY, light.range)
        if wallDistance then
            distance = math.min(wallDistance + WALL_BLEED, light.range)
        end
        table.insert(vertices, { light.x + dirX * distance, light.y + dirY * distance })
    end
    return vertices
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

    local vertices = self:litArea(light)
    assert(#vertices <= MAX_VERTICES, "too many wall corners around a light")
    self.mesh:setVertices(vertices)
    self.mesh:setDrawRange(1, #vertices)

    local r, g, b = unpack(light.color)
    love.graphics.setColor(r * light.intensity, g * light.intensity, b * light.intensity)
    love.graphics.draw(self.mesh)
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
