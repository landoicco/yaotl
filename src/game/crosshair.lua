-- The crosshair drawn in place of the system cursor, so it shows over the darkness
local Crosshair = {}

local ARM_LENGTH = 6 -- pixels
local GAP = 4 -- from the center to where each arm starts
local COLOR = { 0.92, 0.88, 0.8, 0.9 }
-- A dark outline keeps it visible over lit, pale floors
local OUTLINE_COLOR = { 0, 0, 0, 0.6 }

local function drawArms(x, y)
    love.graphics.line(x - GAP - ARM_LENGTH, y, x - GAP, y)
    love.graphics.line(x + GAP, y, x + GAP + ARM_LENGTH, y)
    love.graphics.line(x, y - GAP - ARM_LENGTH, x, y - GAP)
    love.graphics.line(x, y + GAP, x, y + GAP + ARM_LENGTH)
end

-- x, y: screen position, usually the mouse
function Crosshair.draw(x, y)
    love.graphics.push("all")
    love.graphics.setLineStyle("rough")
    love.graphics.setColor(OUTLINE_COLOR)
    love.graphics.setLineWidth(4)
    drawArms(x, y)
    love.graphics.setColor(COLOR)
    love.graphics.setLineWidth(2)
    drawArms(x, y)
    love.graphics.pop()
end

return Crosshair
