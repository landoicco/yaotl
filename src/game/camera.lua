-- The view over the world: follows a target smoothly and never shows past the world's edges
local Camera = {}
Camera.__index = Camera

-- How fast the view catches up with its target; higher is snappier
local FOLLOW_RATE = 8

-- worldWidth, worldHeight: size of the world in pixels
function Camera.new(worldWidth, worldHeight)
    local self = setmetatable({}, Camera)
    self.worldWidth = worldWidth
    self.worldHeight = worldHeight
    -- Top-left corner of the view, in world pixels
    self.x = 0
    self.y = 0
    return self
end

-- Keep the view inside the world; a world smaller than the screen stays centered
function Camera:clamp()
    local width, height = love.graphics.getDimensions()
    if self.worldWidth <= width then
        self.x = (self.worldWidth - width) / 2
    else
        self.x = math.max(0, math.min(self.x, self.worldWidth - width))
    end
    if self.worldHeight <= height then
        self.y = (self.worldHeight - height) / 2
    else
        self.y = math.max(0, math.min(self.y, self.worldHeight - height))
    end
end

-- Jump straight to a point, such as the player's spawn
function Camera:centerOn(x, y)
    local width, height = love.graphics.getDimensions()
    self.x, self.y = x - width / 2, y - height / 2
    self:clamp()
end

-- Move part of the way toward a point; the same feel at any frame rate
function Camera:follow(x, y, dt)
    local width, height = love.graphics.getDimensions()
    local t = 1 - math.exp(-FOLLOW_RATE * dt)
    self.x = self.x + (x - width / 2 - self.x) * t
    self.y = self.y + (y - height / 2 - self.y) * t
    self:clamp()
end

-- Whole pixels, so tiles and sprites do not shimmer while the view moves
function Camera:offset()
    return math.floor(self.x + 0.5), math.floor(self.y + 0.5)
end

-- Everything drawn between attach and detach is placed in world coordinates
function Camera:attach()
    local x, y = self:offset()
    love.graphics.push()
    love.graphics.translate(-x, -y)
end

function Camera:detach()
    love.graphics.pop()
end

-- World position under a point on the screen, such as the mouse
function Camera:toWorld(screenX, screenY)
    local x, y = self:offset()
    return screenX + x, screenY + y
end

return Camera
