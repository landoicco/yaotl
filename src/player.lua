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

-- Movement within this angle of the aim walks forward, and beyond
-- BACKWARD_LIMIT walks backwards. Anything in between strafes
local FORWARD_LIMIT = math.pi / 4
local BACKWARD_LIMIT = 3 * math.pi / 4

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

-- Wrap an angle to the range [-pi, pi)
local function normalizeAngle(angle)
    return (angle + math.pi) % (2 * math.pi) - math.pi
end

function Player.new(x, y)
    local self = setmetatable({}, Player)
    self.x = x
    self.y = y
    self.aimAngle = 0
    self.feetAngle = 0
    self.feetReversed = false

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

    local animations = self.animations
    if isMoving then
        self.torso = switchTo(self.torso, animations.torsoMove)
        self:updateFeet(math.atan2(dirY, dirX))
    else
        self.torso = switchTo(self.torso, animations.torsoIdle)
        self.feet = switchTo(self.feet, animations.feetIdle)
        self.feetAngle = self.aimAngle
        self.feetReversed = false
    end

    self.torso:update(dt)
    self.feet:update(self.feetReversed and -dt or dt)
end

-- Pick the feet animation and angle from the movement direction relative to the aim
function Player:updateFeet(moveAngle)
    local animations = self.animations
    local relative = normalizeAngle(moveAngle - self.aimAngle)

    self.feetReversed = false
    if math.abs(relative) <= FORWARD_LIMIT then
        self.feet = switchTo(self.feet, animations.feetWalk)
        self.feetAngle = moveAngle
    elseif math.abs(relative) >= BACKWARD_LIMIT then
        -- Walking backwards: the feet face away from the movement and the walk plays in reverse
        self.feet = switchTo(self.feet, animations.feetWalk)
        self.feetAngle = moveAngle + math.pi
        self.feetReversed = true
    elseif relative < 0 then
        -- The strafe sprites step sideways, so the feet face perpendicular to the movement
        self.feet = switchTo(self.feet, animations.feetStrafeLeft)
        self.feetAngle = moveAngle + math.pi / 2
    else
        self.feet = switchTo(self.feet, animations.feetStrafeRight)
        self.feetAngle = moveAngle - math.pi / 2
    end
end

function Player:draw()
    -- Feet first, so the torso is drawn on top of them
    self.feet:draw(self.x, self.y, self.feetAngle, SCALE)
    self.torso:draw(self.x, self.y, self.aimAngle, SCALE)
end

return Player
