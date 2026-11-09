-- A looping animation played from a grid spritesheet
local Animation = {}
Animation.__index = Animation

-- The definition describes the spritesheet:
--   image                    grid spritesheet, frames read left to right, top to bottom
--   frameWidth, frameHeight  size of one frame
--   frameCount               number of frames
--   originX, originY         point of the frame the sprite is drawn and rotated around
function Animation.new(definition, fps)
    local self = setmetatable({}, Animation)
    self.definition = definition
    self.fps = fps
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

    return self
end

-- A negative dt plays the animation backwards
function Animation:update(dt)
    -- Wrap around the loop length so the timer never grows unbounded.
    -- Lua's modulo takes the sign of the divisor, so the result stays positive
    local duration = #self.frames / self.fps
    self.time = (self.time + dt) % duration
end

-- Restart from the first frame, e.g. when switching to this animation
function Animation:reset()
    self.time = 0
end

function Animation:draw(x, y, angle, scale)
    -- Clamp in case floating-point rounding lands exactly on the loop length
    local index = math.min(math.floor(self.time * self.fps) + 1, #self.frames)
    local definition = self.definition
    love.graphics.draw(
        definition.image, self.frames[index],
        x, y, angle, scale, scale,
        definition.originX, definition.originY
    )
end

return Animation
