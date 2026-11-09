local Animation = require("src.engine.animation")

-- A zombie that walks straight at its target
local Zombie = {}
Zombie.__index = Zombie

local SPEED = 60 -- pixels per second
local SCALE = 0.35
local DEFAULT_FPS = 15
-- Stops at this distance from the target instead of overlapping it
local REACH = 30
local HEALTH = 3 -- handgun shots to kill
-- Body size for collisions, in pixels after scaling
local RADIUS = 25
local FADE_DURATION = 0.3 -- seconds

local SHEETS_DIR = "assets/sprites/zombie/"

-- Layouts from tools/pack-sprites.sh; the origin is the center of the body
local ANIMATIONS = {
    idle = {
        sheet = "idle.png",
        frameWidth = 241, frameHeight = 222, frameCount = 17,
        originX = 95, originY = 110,
    },
    move = {
        sheet = "move.png",
        frameWidth = 288, frameHeight = 311, frameCount = 17,
        originX = 120, originY = 170,
    },
}

-- Load each spritesheet once, shared by every zombie
for _, definition in pairs(ANIMATIONS) do
    definition.image = love.graphics.newImage(SHEETS_DIR .. definition.sheet)
    definition.fps = definition.fps or DEFAULT_FPS
end

-- target: any table with x and y, usually the player
function Zombie.new(x, y, target)
    local self = setmetatable({}, Zombie)
    self.x = x
    self.y = y
    self.target = target
    self.angle = 0
    self.radius = RADIUS
    self.health = HEALTH
    -- Counts down once health reaches 0; the zombie is removed at 0
    self.fadeTime = FADE_DURATION
    self.isDead = false

    self.animations = {}
    for name, definition in pairs(ANIMATIONS) do
        self.animations[name] = Animation.new(definition)
    end
    self.animation = self.animations.idle

    return self
end

-- Dying zombies are fading out and no longer take hits
function Zombie:isAlive()
    return self.health > 0
end

function Zombie:takeHit()
    self.health = self.health - 1
end

function Zombie:update(dt)
    if not self:isAlive() then
        self.fadeTime = self.fadeTime - dt
        self.isDead = self.fadeTime <= 0
        return
    end

    local dx, dy = self.target.x - self.x, self.target.y - self.y
    local distance = math.sqrt(dx * dx + dy * dy)
    self.angle = math.atan2(dy, dx)

    local nextAnimation = self.animations.idle
    if distance > REACH then
        self.x = self.x + dx / distance * SPEED * dt
        self.y = self.y + dy / distance * SPEED * dt
        nextAnimation = self.animations.move
    end

    if nextAnimation ~= self.animation then
        nextAnimation:reset()
        self.animation = nextAnimation
    end
    self.animation:update(dt)
end

function Zombie:draw()
    love.graphics.push("all")
    love.graphics.setColor(1, 1, 1, math.max(self.fadeTime / FADE_DURATION, 0))
    self.animation:draw(self.x, self.y, self.angle, SCALE)
    love.graphics.pop()
end

return Zombie
