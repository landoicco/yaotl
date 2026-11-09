-- A bullet that flies straight until it reaches its range
local Bullet = {}
Bullet.__index = Bullet

local SPEED = 900 -- pixels per second
local RANGE = 1000 -- pixels, so stray bullets do not fly forever
local LENGTH = 10
local WIDTH = 2
local COLOR = { 1, 0.9, 0.5 }

function Bullet.new(x, y, angle)
    local self = setmetatable({}, Bullet)
    self.x = x
    self.y = y
    self.dirX = math.cos(angle)
    self.dirY = math.sin(angle)
    self.distance = 0 -- traveled so far
    self.isDead = false
    return self
end

function Bullet:update(dt)
    local step = SPEED * dt
    self.x = self.x + self.dirX * step
    self.y = self.y + self.dirY * step

    self.distance = self.distance + step
    if self.distance >= RANGE then
        self.isDead = true
    end
end

function Bullet:draw()
    love.graphics.push("all")
    love.graphics.setColor(COLOR)
    love.graphics.setLineWidth(WIDTH)
    love.graphics.line(self.x, self.y, self.x - self.dirX * LENGTH, self.y - self.dirY * LENGTH)
    love.graphics.pop()
end

return Bullet
