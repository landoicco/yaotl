-- A looping animation played from a grid spritesheet
local Animation = {}
Animation.__index = Animation

-- Frames are read left to right, top to bottom, starting at the top-left cell
function Animation.new(image, frameWidth, frameHeight, frameCount, fps)
    local self = setmetatable({}, Animation)
    self.image = image
    self.fps = fps
    self.time = 0
    self.frames = {}

    local columns = math.floor(image:getWidth() / frameWidth)
    for i = 0, frameCount - 1 do
        local column = i % columns
        local row = math.floor(i / columns)
        self.frames[i + 1] = love.graphics.newQuad(
            column * frameWidth, row * frameHeight,
            frameWidth, frameHeight,
            image:getDimensions()
        )
    end

    return self
end

function Animation:update(dt)
    -- Wrap around the loop length so the timer never grows unbounded
    local duration = #self.frames / self.fps
    self.time = (self.time + dt) % duration
end

-- Restart from the first frame, e.g. when switching to this animation
function Animation:reset()
    self.time = 0
end

function Animation:draw(x, y, angle, scale, originX, originY)
    -- Clamp in case floating-point rounding lands exactly on the loop length
    local index = math.min(math.floor(self.time * self.fps) + 1, #self.frames)
    love.graphics.draw(self.image, self.frames[index], x, y, angle, scale, scale, originX, originY)
end

return Animation
