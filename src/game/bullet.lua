-- A bullet that flies straight until it leaves the screen
local Bullet = {}
Bullet.__index = Bullet

local SPEED = 900 -- pixels per second
local LENGTH = 10
local WIDTH = 2
local COLOR = { 1, 0.9, 0.5 }

function Bullet.new(x, y, angle)
    local self = setmetatable({}, Bullet)
    self.x = x
    self.y = y
    self.dirX = math.cos(angle)
    self.dirY = math.sin(angle)
    self.isDead = false
    return self
end

function Bullet:update(dt)
    self.x = self.x + self.dirX * SPEED * dt
    self.y = self.y + self.dirY * SPEED * dt

    local width, height = love.graphics.getDimensions()
    if self.x < 0 or self.x > width or self.y < 0 or self.y > height then
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
