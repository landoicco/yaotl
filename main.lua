local Player = require("src.game.player")

local player

-- This function is called once at the beginning of the game
function love.load()
    -- Neutral floor tone so the dark sprites stay visible, until the map is drawn
    love.graphics.setBackgroundColor(0.45, 0.45, 0.42)

    local windowWidth, windowHeight = love.graphics.getDimensions()
    player = Player.new(windowWidth / 2, windowHeight / 2)
end

function love.update(dt)
    player:update(dt)
end

function love.keypressed(key)
    player:keypressed(key)
end

function love.mousepressed(x, y, btn, istouch, presses)
    player:mousepressed(btn)
end

-- Callback function used to draw on screen every frame
function love.draw()
    player:draw()
end
