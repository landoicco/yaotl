local Animation = require("src.engine.animation")

-- A zombie that hunts its target: straight at it when it can, around the walls when it cannot
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
-- Rays that check a straight walk: the center of the body, then its left and right edges
local BODY_SIDES = { 0, -1, 1 }
-- A melee shove throws the zombie back and leaves it reeling for a moment
local SHOVE_SPEED = 500 -- pixels per second at the start
local SHOVE_DECAY = 10 -- how fast it slows down; the shove covers SHOVE_SPEED / SHOVE_DECAY = 50 px
local STAGGER_DURATION = 0.4 -- seconds

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

-- target: x, y and takeHit(), usually the player; map: the walls it cannot cross;
-- flowField: the paths around the walls toward the target
function Zombie.new(x, y, target, map, flowField)
    local self = setmetatable({}, Zombie)
    self.x = x
    self.y = y
    self.target = target
    self.map = map
    self.flowField = flowField
    self.angle = 0
    self.radius = RADIUS
    self.health = HEALTH
    -- Counts down once health reaches 0; the zombie is removed at 0
    self.fadeTime = FADE_DURATION
    self.isDead = false
    -- Whether the current swing already landed or missed
    self.hasHit = false
    -- Seconds left reeling from a shove, and the speed it was thrown back at
    self.staggerTime = 0
    self.shoveX, self.shoveY = 0, 0

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

-- A melee blow: it hurts, throws the zombie back along dirX, dirY and cuts its swing short
function Zombie:shove(dirX, dirY)
    self:takeHit()
    self.staggerTime = STAGGER_DURATION
    self.shoveX, self.shoveY = dirX * SHOVE_SPEED, dirY * SHOVE_SPEED
    self:switchTo(self.animations.idle)
end

-- Sliding back from a shove, slowing down; walls stop it like they stop a walk
-- Moves by the exact distance the decaying speed covers this frame, so the shove is the same at any frame rate
function Zombie:updateStagger(dt)
    self.staggerTime = self.staggerTime - dt
    local slowdown = math.exp(-SHOVE_DECAY * dt)
    local travel = (1 - slowdown) / SHOVE_DECAY
    self.x, self.y = self.map:pushOut(self.x + self.shoveX * travel, self.y + self.shoveY * travel, self.radius)
    self.shoveX, self.shoveY = self.shoveX * slowdown, self.shoveY * slowdown
end

function Zombie:update(dt)
    if not self:isAlive() then
        self.fadeTime = self.fadeTime - dt
        self.isDead = self.fadeTime <= 0
        return
    end

    if self.staggerTime > 0 then
        self:updateStagger(dt)
        self.animation:update(dt)
        return
    end

    local dx, dy = self.target.x - self.x, self.target.y - self.y
    local distance = math.sqrt(dx * dx + dy * dy)

    if self.animation == self.animations.attack then
        self:updateAttack(distance)
    elseif distance > REACH then
        local dirX, dirY = self:walkDirection(dx / distance, dy / distance, distance)
        self.angle = math.atan2(dirY, dirX)
        local step = SPEED * dt
        self.x, self.y = self.map:pushOut(self.x + dirX * step, self.y + dirY * step, self.radius)
        self:switchTo(self.animations.move)
    else
        -- The swing keeps the angle it started with
        self.angle = math.atan2(dy, dx)
        self.hasHit = false
        self:switchTo(self.animations.attack)
    end

    self.animation:update(dt)
end

-- Whether the whole body fits a straight walk to the target: rays from its center and both sides
function Zombie:hasClearPath(dirX, dirY, distance)
    for _, side in ipairs(BODY_SIDES) do
        local offsetX, offsetY = -dirY * side * self.radius, dirX * side * self.radius
        if self.map:castRay(self.x + offsetX, self.y + offsetY, dirX, dirY, distance) then
            return false
        end
    end
    return true
end

-- Straight at the target when nothing is in the way; otherwise along the flow field, around the walls
-- dirX, dirY: the unit vector to the target
function Zombie:walkDirection(dirX, dirY, distance)
    if self:hasClearPath(dirX, dirY, distance) then
        return dirX, dirY
    end

    local stepX, stepY = self.flowField:nextStep(self.x, self.y)
    if not stepX then
        return dirX, dirY
    end
    local dx, dy = stepX - self.x, stepY - self.y
    local length = math.sqrt(dx * dx + dy * dy)
    if length == 0 then
        return dirX, dirY
    end
    return dx / length, dy / length
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
