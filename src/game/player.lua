local Animation = require("src.engine.animation")
local Flashlight = require("src.game.flashlight")
local MuzzleFlash = require("src.game.muzzle_flash")
local states = require("src.game.player_states")
local Weapon = require("src.game.weapon")

-- The survivor: the torso aims at the mouse, the feet follow the movement
local Player = {}
Player.__index = Player

local SPEED = 150 -- pixels per second
local RUN_SPEED = 240
local HEALTH = 5 -- zombie hits to kill
-- Body size against walls, in pixels after scaling
local RADIUS = 18
local SCALE = 0.35
local DEFAULT_FPS = 15

local SHEETS_DIR = "assets/sprites/player/"

-- Layouts from tools/pack-sprites.sh; the origin is the center of the body
-- stylua: ignore
local ANIMATIONS = {
    flashlightIdle = {
        sheet = "flashlight_idle.png",
        frameWidth = 303, frameHeight = 223, frameCount = 20,
        originX = 95, originY = 120,
    },
    flashlightMove = {
        sheet = "flashlight_move.png",
        frameWidth = 305, frameHeight = 231, frameCount = 20,
        originX = 95, originY = 120,
    },
    -- Melee strikes: 15 frames at 20 fps = 0.75 s; hitFrame is where the blow lands
    -- With the flashlight, the free hand punches
    flashlightMelee = {
        sheet = "flashlight_melee.png",
        frameWidth = 316, frameHeight = 246, frameCount = 15,
        originX = 101, originY = 144,
        fps = 20, loops = false, hitFrame = 9,
    },
    handgunMelee = {
        sheet = "handgun_melee.png",
        frameWidth = 291, frameHeight = 256, frameCount = 15,
        originX = 117, originY = 124,
        fps = 20, loops = false, hitFrame = 8,
    },
    shotgunMelee = {
        sheet = "shotgun_melee.png",
        frameWidth = 358, frameHeight = 353, frameCount = 15,
        originX = 132, originY = 199,
        fps = 20, loops = false, hitFrame = 9,
    },
    handgunIdle = {
        sheet = "handgun_idle.png",
        frameWidth = 253, frameHeight = 216, frameCount = 20,
        originX = 110, originY = 120,
    },
    handgunMove = {
        sheet = "handgun_move.png",
        frameWidth = 258, frameHeight = 220, frameCount = 20,
        originX = 110, originY = 120,
    },
    handgunShoot = {
        sheet = "handgun_shoot.png",
        frameWidth = 255, frameHeight = 215, frameCount = 3,
        originX = 110, originY = 120,
        fps = 20, loops = false,
    },
    -- Sets the reload time: 15 frames at 15 fps = 1 s
    handgunReload = {
        sheet = "handgun_reload.png",
        frameWidth = 260, frameHeight = 230, frameCount = 15,
        originX = 110, originY = 120,
        loops = false,
    },
    shotgunIdle = {
        sheet = "shotgun_idle.png",
        frameWidth = 313, frameHeight = 207, frameCount = 20,
        originX = 112, originY = 118,
    },
    shotgunMove = {
        sheet = "shotgun_move.png",
        frameWidth = 313, frameHeight = 206, frameCount = 20,
        originX = 112, originY = 118,
    },
    -- Slower than the handgun's, so the shotgun fires less often
    shotgunShoot = {
        sheet = "shotgun_shoot.png",
        frameWidth = 312, frameHeight = 206, frameCount = 3,
        originX = 112, originY = 118,
        fps = 6, loops = false,
    },
    -- 20 frames at 15 fps = 1.33 s
    shotgunReload = {
        sheet = "shotgun_reload.png",
        frameWidth = 322, frameHeight = 217, frameCount = 20,
        originX = 116, originY = 119,
        loops = false,
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
    -- Faster than the walk, so the longer strides keep up with the speed
    feetRun = {
        sheet = "feet_run.png",
        frameWidth = 204, frameHeight = 124, frameCount = 20,
        originX = 102, originY = 62,
        fps = 20,
    },
    feetStrafeLeft = {
        sheet = "feet_strafe_left.png",
        frameWidth = 155, frameHeight = 174, frameCount = 20,
        originX = 77, originY = 87,
    },
    feetStrafeRight = {
        sheet = "feet_strafe_right.png",
        frameWidth = 154, frameHeight = 176, frameCount = 20,
        originX = 77, originY = 88,
    },
}

-- Flashlight lens, in sprite pixels from the origin
local LENS_X, LENS_Y = 200, -16

-- name matches the animations' prefix; spread is the half-angle of the pellets, in radians;
-- flashSize scales the muzzle flash; the muzzle is in sprite pixels from the origin
-- stylua: ignore
local WEAPONS = {
    handgun = {
        name = "handgun", label = "Handgun",
        magazineSize = 12, reserve = 36,
        pellets = 1, spread = 0, flashSize = 1,
        muzzleX = 133, muzzleY = 38,
    },
    shotgun = {
        name = "shotgun", label = "Shotgun",
        magazineSize = 6, reserve = 18,
        pellets = 7, spread = 0.15, flashSize = 1.6,
        muzzleX = 181, muzzleY = 34,
    },
}

-- Angles from the aim that separate walking forward, strafing and walking backwards
local FORWARD_LIMIT = math.pi / 4
local BACKWARD_LIMIT = 3 * math.pi / 4

-- Fastest the torso turns toward the aim, so turning around takes a moment
local TURN_SPEED = math.rad(600) -- radians per second
-- Close to the player, small mouse moves swing the aim wildly: inside this distance it is ignored
local AIM_DEAD_ZONE = 30 -- pixels

-- Shared by every player
Animation.loadDefinitions(SHEETS_DIR, ANIMATIONS, DEFAULT_FPS)

-- Wrap an angle to the range [-pi, pi)
local function normalizeAngle(angle)
    return (angle + math.pi) % (2 * math.pi) - math.pi
end

-- map: the walls the player cannot cross
-- spawnBullet(x, y, angle) is called on every shot, strike(x, y, angle) when a melee blow lands
function Player.new(x, y, map, spawnBullet, strike)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.map = map
    self.spawnBullet = spawnBullet
    self.strike = strike
    -- Whether the current melee swing already landed
    self.hasStruck = false
    self.health = HEALTH
    self.weapons = {
        handgun = Weapon.new(WEAPONS.handgun),
        shotgun = Weapon.new(WEAPONS.shotgun),
    }
    -- The weapon in hand, or the last one used while holding the flashlight
    self.weapon = self.weapons.handgun
    self.flashlight = Flashlight.new()
    self.muzzleFlash = MuzzleFlash.new()
    self.aimAngle = 0
    self.feetAngle = 0
    self.feetReversed = false
    self.isMoving = false
    self.isRunning = false

    self.animations = Animation.newSet(ANIMATIONS)

    -- The player starts with the flashlight out
    self:changeState(states.flashlight)
    self.torso = self.animations[self.state.torso(self)]
    self.feet = self.animations.feetIdle

    return self
end

function Player:changeState(state)
    self.state = state
    state.enter(self)
end

function Player:isAlive()
    return self.health > 0
end

function Player:takeHit()
    self.health = math.max(self.health - 1, 0)
end

-- World position of a point on the torso sprite, rotated with the aim
-- The lens and the muzzle reach past the body, so against a wall they could poke through it:
-- a point beyond a wall is pulled back to just in front of it
function Player:torsoPoint(spriteX, spriteY)
    local cos, sin = math.cos(self.aimAngle), math.sin(self.aimAngle)
    local offsetX, offsetY = spriteX * SCALE, spriteY * SCALE
    local dx, dy = offsetX * cos - offsetY * sin, offsetX * sin + offsetY * cos

    local length = math.sqrt(dx * dx + dy * dy)
    local wallDistance = self.map:castRay(self.x, self.y, dx / length, dy / length, length)
    if wallDistance then
        local scale = math.max(wallDistance - 1, 0) / length
        dx, dy = dx * scale, dy * scale
    end
    return self.x + dx, self.y + dy
end

function Player:equip(weaponName)
    self.weapon = self.weapons[weaponName]
end

-- Fire the weapon's pellets from the muzzle, each at a random angle within the spread
function Player:shoot()
    local stats = self.weapon.stats
    local x, y = self:torsoPoint(stats.muzzleX, stats.muzzleY)
    self.weapon:consumeRound()
    for _ = 1, stats.pellets do
        local offset = (love.math.random() * 2 - 1) * stats.spread
        self.spawnBullet(x, y, self.aimAngle + offset)
    end
    self.muzzleFlash:fire(x, y, stats.flashSize)
end

function Player:startMelee()
    self.hasStruck = false
end

-- Lands the blow once per swing, on the frame where it connects
-- Only melee animations have a hit frame, so this waits until the swing is on screen
function Player:updateMelee()
    local hitFrame = self.torso.definition.hitFrame
    if not self.hasStruck and hitFrame and self.torso:frameIndex() >= hitFrame then
        self.hasStruck = true
        self.strike(self.x, self.y, self.aimAngle)
    end
end

-- The flashlight state and its substates hold it
function Player:isHoldingFlashlight()
    return self.state.holdsFlashlight == true
end

-- Add the lights the player gives off this frame
function Player:addLights(lights)
    if self:isHoldingFlashlight() then
        self.flashlight:addLights(lights)
    end
    -- Whatever is held now, a recent shot fades out on its own
    self.muzzleFlash:addLights(lights)
end

function Player:keypressed(key)
    self.state.keypressed(self, key)
end

-- Running is for fleeing: the hands do nothing until the player slows down
function Player:mousepressed(button)
    if not self.isRunning then
        self.state.mousepressed(self, button)
    end
end

-- aimX, aimY: the world point the torso faces, usually under the mouse
function Player:update(dt, aimX, aimY)
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
    self.isMoving = length > 0
    self.isRunning = self.isMoving and (love.keyboard.isDown("lshift") or love.keyboard.isDown("rshift"))
    local moveAngle = math.atan2(dirY, dirX)
    if self.isMoving then
        local step = (self.isRunning and RUN_SPEED or SPEED) * dt / length
        self.x, self.y = self.map:pushOut(self.x + dirX * step, self.y + dirY * step, RADIUS)
    end

    -- Running faces the way ahead; otherwise the torso follows the aim
    local aimDX, aimDY = aimX - self.x, aimY - self.y
    if self.isRunning then
        self:turnToward(moveAngle, dt)
    elseif aimDX * aimDX + aimDY * aimDY > AIM_DEAD_ZONE * AIM_DEAD_ZONE then
        self:turnToward(math.atan2(aimDY, aimDX), dt)
    end

    -- The state decides what the torso does
    self.state.update(self, dt)
    self.torso = Animation.switch(self.torso, self.animations[self.state.torso(self)])

    if self.isRunning then
        -- The run only has a forward animation
        self.feet = Animation.switch(self.feet, self.animations.feetRun)
        self.feetAngle = moveAngle
        self.feetReversed = false
    elseif self.isMoving then
        self:updateFeet(moveAngle)
    else
        self.feet = Animation.switch(self.feet, self.animations.feetIdle)
        self.feetAngle = self.aimAngle
        self.feetReversed = false
    end

    self.torso:update(dt)
    self.feet:update(self.feetReversed and -dt or dt)

    local lensX, lensY = self:torsoPoint(LENS_X, LENS_Y)
    self.flashlight:place(lensX, lensY, self.aimAngle, self.x, self.y)
    self.flashlight:update(dt, self:isHoldingFlashlight())
    self.muzzleFlash:update(dt)
end

-- Turn the torso toward an angle, the short way round and no faster than TURN_SPEED
function Player:turnToward(angle, dt)
    local difference = normalizeAngle(angle - self.aimAngle)
    local maxTurn = TURN_SPEED * dt
    self.aimAngle = normalizeAngle(self.aimAngle + math.max(-maxTurn, math.min(difference, maxTurn)))
end

-- Feet animation and angle from the movement relative to the aim
function Player:updateFeet(moveAngle)
    local animations = self.animations
    local relative = normalizeAngle(moveAngle - self.aimAngle)

    self.feetReversed = false
    if math.abs(relative) <= FORWARD_LIMIT then
        self.feet = Animation.switch(self.feet, animations.feetWalk)
        self.feetAngle = moveAngle
    elseif math.abs(relative) >= BACKWARD_LIMIT then
        -- Backwards: feet face the aim, walk plays in reverse
        self.feet = Animation.switch(self.feet, animations.feetWalk)
        self.feetAngle = moveAngle + math.pi
        self.feetReversed = true
    elseif relative < 0 then
        -- Strafe sprites step sideways
        self.feet = Animation.switch(self.feet, animations.feetStrafeLeft)
        self.feetAngle = moveAngle + math.pi / 2
    else
        self.feet = Animation.switch(self.feet, animations.feetStrafeRight)
        self.feetAngle = moveAngle - math.pi / 2
    end
end

function Player:draw()
    -- Feet first, so the torso is drawn on top of them
    self.feet:draw(self.x, self.y, self.feetAngle, SCALE)
    self.torso:draw(self.x, self.y, self.aimAngle, SCALE)
end

return Player
