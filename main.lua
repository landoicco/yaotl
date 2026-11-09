local Player = require("src.player")

local player

-- This function is called once at the beginning of the game
function love.load()
    local windowWidth, windowHeight = love.graphics.getDimensions()
    player = Player.new(windowWidth / 2, windowHeight / 2)
end

function love.update(dt)
    player:update(dt)
end

function love.mousepressed(x, y, btn, istouch, presses)
    if btn == 1 then
        print("Shoot")
    end
end

-- Callback function used to draw on screen every frame
function love.draw()
    player:draw()
end
