local Animation = require("src.engine.animation")
local states = require("src.game.player_states")
local Weapon = require("src.game.weapon")

-- The survivor: the torso aims at the mouse, the feet follow the movement
local Player = {}
Player.__index = Player

local SPEED = 150 -- pixels per second
local HEALTH = 5 -- zombie hits to kill
local SCALE = 0.35
local DEFAULT_FPS = 15

local SHEETS_DIR = "assets/sprites/player/"

-- Layouts from tools/pack-sprites.sh; the origin is the center of the body
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

-- Handgun muzzle, in sprite pixels from the origin
local MUZZLE_X, MUZZLE_Y = 133, 38

local HANDGUN_MAGAZINE = 12
local HANDGUN_RESERVE = 36

-- Angles from the aim that separate walking forward, strafing and walking backwards
local FORWARD_LIMIT = math.pi / 4
local BACKWARD_LIMIT = 3 * math.pi / 4

-- Shared by every player
Animation.loadDefinitions(SHEETS_DIR, ANIMATIONS, DEFAULT_FPS)

-- Wrap an angle to the range [-pi, pi)
local function normalizeAngle(angle)
    return (angle + math.pi) % (2 * math.pi) - math.pi
end

-- spawnBullet(x, y, angle) is called on every shot
function Player.new(x, y, spawnBullet)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.spawnBullet = spawnBullet
    self.health = HEALTH
    self.weapon = Weapon.new(HANDGUN_MAGAZINE, HANDGUN_RESERVE)
    self.aimAngle = 0
    self.feetAngle = 0
    self.feetReversed = false
    self.isMoving = false

    self.animations = Animation.newSet(ANIMATIONS)

    -- The player starts with the handgun
    self:changeState(states.handgunReady)
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

-- Fire a bullet from the muzzle, rotated with the aim
function Player:shoot()
    local cos, sin = math.cos(self.aimAngle), math.sin(self.aimAngle)
    local offsetX, offsetY = MUZZLE_X * SCALE, MUZZLE_Y * SCALE
    local x = self.x + offsetX * cos - offsetY * sin
    local y = self.y + offsetX * sin + offsetY * cos
    self.weapon:consumeRound()
    self.spawnBullet(x, y, self.aimAngle)
end

function Player:keypressed(key)
    self.state.keypressed(self, key)
end

function Player:mousepressed(button)
    self.state.mousepressed(self, button)
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
    self.isMoving = length > 0
    if self.isMoving then
        self.x = self.x + dirX / length * SPEED * dt
        self.y = self.y + dirY / length * SPEED * dt
    end

    -- The torso faces the mouse cursor
    local mouseX, mouseY = love.mouse.getPosition()
    self.aimAngle = math.atan2(mouseY - self.y, mouseX - self.x)

    -- The state decides what the torso does
    self.state.update(self, dt)
    self.torso = Animation.switch(self.torso, self.animations[self.state.torso(self)])

    if self.isMoving then
        self:updateFeet(math.atan2(dirY, dirX))
    else
        self.feet = Animation.switch(self.feet, self.animations.feetIdle)
        self.feetAngle = self.aimAngle
        self.feetReversed = false
    end

    self.torso:update(dt)
    self.feet:update(self.feetReversed and -dt or dt)
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
