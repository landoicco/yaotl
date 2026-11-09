-- The survivor: moves with WASD and faces the mouse cursor
local Player = {}
Player.__index = Player

local sprite = love.graphics.newImage("assets/sprites/player/flashlight_idle.png")
-- First frame of the spritesheet, until animations are added
local frame = love.graphics.newQuad(0, 0, 303, 223, sprite:getDimensions())

local SPEED = 150 -- pixels per second
local SCALE = 0.35

-- Point of the sprite the player rotates around: the center of the body,
-- not the center of the image, which is offset by the extended arm
local PIVOT_X, PIVOT_Y = 95, 120

function Player.new(x, y)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.angle = 0
    return self
end

function Player:update(dt)
    -- Build the movement direction from the pressed keys
    local dirX, dirY = 0, 0
    if love.keyboard.isDown("w") then
        dirY = dirY - 1
    end
    if love.keyboard.isDown("s") then
        dirY = dirY + 1
    end
    if love.keyboard.isDown("a") then
        dirX = dirX - 1
    end
    if love.keyboard.isDown("d") then
        dirX = dirX + 1
    end

    -- Normalize so diagonal movement is not faster
    local length = math.sqrt(dirX * dirX + dirY * dirY)
    if length > 0 then
        self.x = self.x + dirX / length * SPEED * dt
        self.y = self.y + dirY / length * SPEED * dt
    end

    -- Face the mouse cursor
    local mouseX, mouseY = love.mouse.getPosition()
    self.angle = math.atan2(mouseY - self.y, mouseX - self.x)
end

function Player:draw()
    love.graphics.draw(sprite, frame, self.x, self.y, self.angle, SCALE, SCALE, PIVOT_X, PIVOT_Y)
end

return Player
