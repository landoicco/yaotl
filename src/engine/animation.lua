-- An animation played from a grid spritesheet, looping or played once
local Animation = {}
Animation.__index = Animation

-- definition: image, frameWidth, frameHeight, frameCount, originX, originY, fps, loops (default true)
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
        -- Wrap to the loop length; Lua's % keeps it positive when dt < 0
        self.time = (self.time + dt) % self.duration
    else
        self.time = math.min(self.time + dt, self.duration)
    end
end

-- Restart from the first frame
function Animation:reset()
    self.time = 0
end

-- True once a non-looping animation reaches its end
function Animation:isFinished()
    return not self.loops and self.time >= self.duration
end

function Animation:draw(x, y, angle, scale)
    -- Clamp to the last frame
    local index = math.min(math.floor(self.time * self.definition.fps) + 1, #self.frames)
    local definition = self.definition
    love.graphics.draw(
        definition.image, self.frames[index],
        x, y, angle, scale, scale,
        definition.originX, definition.originY
    )
end

return Animation
