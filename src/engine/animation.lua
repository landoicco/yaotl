-- An animation played from a grid spritesheet, looping or played once
local Animation = {}
Animation.__index = Animation

local function buildFrames(definition)
    local frames = {}
    local image = definition.image
    local width, height = definition.frameWidth, definition.frameHeight
    local columns = math.floor(image:getWidth() / width)
    for i = 0, definition.frameCount - 1 do
        local column = i % columns
        local row = math.floor(i / columns)
        frames[i + 1] = love.graphics.newQuad(column * width, row * height, width, height, image:getDimensions())
    end
    return frames
end

-- definition: image, frameWidth, frameHeight, frameCount, originX, originY, fps, loops (default true)
function Animation.new(definition)
    local self = setmetatable({}, Animation)
    self.definition = definition
    self.loops = definition.loops ~= false
    self:reset()

    -- Flyweight: frames are built once and shared by every instance of the definition
    definition.frames = definition.frames or buildFrames(definition)
    self.frames = definition.frames
    self.duration = #self.frames / definition.fps

    return self
end

-- Load each definition's spritesheet once, from dir + sheet; fps defaults to defaultFps
function Animation.loadDefinitions(dir, definitions, defaultFps)
    for _, definition in pairs(definitions) do
        definition.image = love.graphics.newImage(dir .. definition.sheet)
        definition.fps = definition.fps or defaultFps
    end
    return definitions
end

-- One animation per definition, under the same names
function Animation.newSet(definitions)
    local set = {}
    for name, definition in pairs(definitions) do
        set[name] = Animation.new(definition)
    end
    return set
end

-- The animation to play next, restarted only when it differs from the current one
function Animation.switch(current, nextAnimation)
    if nextAnimation ~= current then
        nextAnimation:reset()
    end
    return nextAnimation
end

-- A negative dt plays the animation backwards
function Animation:update(dt)
    -- Right after a reset, the update starts just before the first frame, so it enters it
    self.previousTime = self.restarted and -1 or self.time
    self.restarted = false
    self.forward = dt > 0
    if self.loops then
        -- Wrap to the loop length; Lua's % keeps it positive when dt < 0
        local time = self.time + dt
        self.wrapped = time >= self.duration or time < 0
        self.time = time % self.duration
    else
        self.time = math.min(self.time + dt, self.duration)
    end
end

-- Restart from the first frame
function Animation:reset()
    self.time = 0
    self.restarted = true
    self.wrapped = false
end

-- True if the last update entered the frame, playing forward; for things tied to a frame, like sounds
function Animation:enteredFrame(index)
    if not self.forward then
        return false
    end
    local start = (index - 1) / self.definition.fps
    if self.wrapped then
        return start > self.previousTime or start <= self.time
    end
    return start > self.previousTime and start <= self.time
end

-- True once a non-looping animation reaches its end
function Animation:isFinished()
    return not self.loops and self.time >= self.duration
end

-- Current frame, starting at 1 and clamped to the last one
function Animation:frameIndex()
    return math.min(math.floor(self.time * self.definition.fps) + 1, #self.frames)
end

function Animation:draw(x, y, angle, scale)
    local definition = self.definition
    love.graphics.draw(
        definition.image,
        self.frames[self:frameIndex()],
        x,
        y,
        angle,
        scale,
        scale,
        definition.originX,
        definition.originY
    )
end

return Animation
