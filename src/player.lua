local Animation = require("src.animation")

-- The survivor: moves with WASD, the torso faces the mouse cursor
-- and the feet face the direction of movement
local Player = {}
Player.__index = Player

local SPEED = 150 -- pixels per second
local SCALE = 0.35
local ANIMATION_FPS = 15

local SHEETS_DIR = "assets/sprites/player/"

-- Frame layout as printed by tools/pack-sprites.sh. The origin is the center
-- of the body, which for the torso is offset by the extended arm
local ANIMATIONS = {
    torsoIdle = {
        sheet = "flashlight_idle.png",
        frameWidth = 303, frameHeight = 223, frameCount = 20,
        originX = 95, originY = 120,
    },
    torsoMove = {
        sheet = "flashlight_move.png",
        frameWidth = 305, frameHeight = 231, frameCount = 20,
        originX = 95, originY = 120,
    },
    feetIdle = {
        sheet = "feet_idle.png",
        frameWidth = 132, frameHeight = 155, frameCount = 1,
        originX = 66, originY = 78,
    },
    feetWalk = {
        sheet = "feet_walk.png",
        frameWidth = 172, frameHeight = 124, frameCount = 20,
        originX = 86, originY = 62,
    },
}

-- Load each spritesheet once, shared by every player
for _, definition in pairs(ANIMATIONS) do
    definition.image = love.graphics.newImage(SHEETS_DIR .. definition.sheet)
end

-- Switch to another animation, restarting it only when it actually changes
local function switchTo(current, nextAnimation)
    if current ~= nextAnimation then
        nextAnimation:reset()
    end
    return nextAnimation
end

function Player.new(x, y)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.aimAngle = 0
    self.feetAngle = 0

    self.animations = {}
    for name, definition in pairs(ANIMATIONS) do
        self.animations[name] = Animation.new(definition, ANIMATION_FPS)
    end
    self.torso = self.animations.torsoIdle
    self.feet = self.animations.feetIdle

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
    local isMoving = length > 0
    if isMoving then
        self.x = self.x + dirX / length * SPEED * dt
        self.y = self.y + dirY / length * SPEED * dt
    end

    -- The torso faces the mouse cursor
    local mouseX, mouseY = love.mouse.getPosition()
    self.aimAngle = math.atan2(mouseY - self.y, mouseX - self.x)

    -- The feet face the movement, or the aim when standing still
    if isMoving then
        self.feetAngle = math.atan2(dirY, dirX)
    else
        self.feetAngle = self.aimAngle
    end

    local animations = self.animations
    if isMoving then
        self.torso = switchTo(self.torso, animations.torsoMove)
        self.feet = switchTo(self.feet, animations.feetWalk)
    else
        self.torso = switchTo(self.torso, animations.torsoIdle)
        self.feet = switchTo(self.feet, animations.feetIdle)
    end

    self.torso:update(dt)
    self.feet:update(dt)
end

function Player:draw()
    -- Feet first, so the torso is drawn on top of them
    self.feet:draw(self.x, self.y, self.feetAngle, SCALE)
    self.torso:draw(self.x, self.y, self.aimAngle, SCALE)
end

return Player
