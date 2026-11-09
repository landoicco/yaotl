-- An animation played from a grid spritesheet, looping or played once
local Animation = {}
Animation.__index = Animation

-- The definition describes the spritesheet and how to play it:
--   image                    grid spritesheet, frames read left to right, top to bottom
--   frameWidth, frameHeight  size of one frame
--   frameCount               number of frames
--   originX, originY         point of the frame the sprite is drawn and rotated around
--   fps                      frames per second
--   loops                    false to play once and stop on the last frame (default true)
function Animation.new(definition)
    local self = setmetatable({}, Animation)
    self.definition = definition
    self.loops = definition.loops ~= false
    self.time = 0
    self.frames = {}

    local image = definition.image
    local width, height = definition.frameWidth, definition.frameHeight
    local columns = math.floor(image:getWidth() / width)
    for i = 0, definition.frameCount - 1 do
        local column = i % columns
        local row = math.floor(i / columns)
        self.frames[i + 1] = love.graphics.newQuad(
            column * width, row * height,
            width, height,
            image:getDimensions()
        )
    end

    self.duration = #self.frames / definition.fps

    return self
end

-- A negative dt plays the animation backwards
function Animation:update(dt)
    if self.loops then
        -- Wrap around the loop length so the timer never grows unbounded.
        -- Lua's modulo takes the sign of the divisor, so the result stays positive
        self.time = (self.time + dt) % self.duration
    else
        self.time = math.min(self.time + dt, self.duration)
    end
end

-- Restart from the first frame, e.g. when switching to this animation
function Animation:reset()
    self.time = 0
end

-- Whether an animation that plays once has reached its end. Looping ones never finish
function Animation:isFinished()
    return not self.loops and self.time >= self.duration
end

function Animation:draw(x, y, angle, scale)
    -- Clamp so the end of the loop, or of a finished animation, shows the last frame
    local index = math.min(math.floor(self.time * self.definition.fps) + 1, #self.frames)
    local definition = self.definition
    love.graphics.draw(
        definition.image, self.frames[index],
        x, y, angle, scale, scale,
        definition.originX, definition.originY
    )
end

return Animation
