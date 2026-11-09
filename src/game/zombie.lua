local Animation = require("src.engine.animation")

-- A zombie that walks straight at its target
local Zombie = {}
Zombie.__index = Zombie

local SPEED = 60 -- pixels per second
local SCALE = 0.35
local DEFAULT_FPS = 15
-- Stops at this distance from the target instead of overlapping it
local REACH = 30
-- The swing only lands if the target is still this close; stepping back dodges it
local ATTACK_RANGE = 50
-- Frame of the attack where the arms close on the target
local HIT_FRAME = 6
local HEALTH = 3 -- handgun shots to kill
-- Body size for collisions, in pixels after scaling
local RADIUS = 25
local FADE_DURATION = 0.3 -- seconds

local SHEETS_DIR = "assets/sprites/zombie/"

-- Layouts from tools/pack-sprites.sh; the origin is the center of the body
-- stylua: ignore
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
    -- 9 frames at 15 fps: one swing every 0.6 s
    attack = {
        sheet = "attack.png",
        frameWidth = 318, frameHeight = 294, frameCount = 9,
        originX = 135, originY = 150,
        loops = false,
    },
}

-- Shared by every zombie
Animation.loadDefinitions(SHEETS_DIR, ANIMATIONS, DEFAULT_FPS)

-- target: x, y and takeHit(), usually the player
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
    -- Whether the current swing already landed or missed
    self.hasHit = false

    self.animations = Animation.newSet(ANIMATIONS)
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

    if self.animation == self.animations.attack then
        self:updateAttack(distance)
    elseif distance > REACH then
        self.angle = math.atan2(dy, dx)
        self.x = self.x + dx / distance * SPEED * dt
        self.y = self.y + dy / distance * SPEED * dt
        self:switchTo(self.animations.move)
    else
        -- The swing keeps the angle it started with
        self.angle = math.atan2(dy, dx)
        self.hasHit = false
        self:switchTo(self.animations.attack)
    end

    self.animation:update(dt)
end

-- Lands the hit once per swing and chases again when the swing ends
function Zombie:updateAttack(distance)
    local attack = self.animations.attack
    if not self.hasHit and attack:frameIndex() >= HIT_FRAME then
        self.hasHit = true
        if distance <= ATTACK_RANGE then
            self.target:takeHit()
        end
    end
    if attack:isFinished() then
        self:switchTo(self.animations.move)
    end
end

function Zombie:switchTo(animation)
    self.animation = Animation.switch(self.animation, animation)
end

function Zombie:draw()
    love.graphics.push("all")
    love.graphics.setColor(1, 1, 1, math.max(self.fadeTime / FADE_DURATION, 0))
    self.animation:draw(self.x, self.y, self.angle, SCALE)
    love.graphics.pop()
end

return Zombie
