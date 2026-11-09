local Animation = require("src.animation")

-- The survivor: moves with WASD and faces the mouse cursor
local Player = {}
Player.__index = Player

local idleSheet = love.graphics.newImage("assets/sprites/player/flashlight_idle.png")

local SPEED = 150 -- pixels per second
local SCALE = 0.35
local ANIMATION_FPS = 15

-- Point of the sprite the player rotates around: the center of the body,
-- not the center of the image, which is offset by the extended arm
local PIVOT_X, PIVOT_Y = 95, 120

function Player.new(x, y)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.angle = 0
    self.animation = Animation.new(idleSheet, 303, 223, 20, ANIMATION_FPS)
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

    self.animation:update(dt)
end

function Player:draw()
    self.animation:draw(self.x, self.y, self.angle, SCALE, PIVOT_X, PIVOT_Y)
end

return Player
