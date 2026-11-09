local Player = require("src.game.player")
local Bullet = require("src.game.bullet")

local player
local bullets = {}

local function spawnBullet(x, y, angle)
    table.insert(bullets, Bullet.new(x, y, angle))
end

-- This function is called once at the beginning of the game
function love.load()
    -- Placeholder floor color until there is a map
    love.graphics.setBackgroundColor(0.45, 0.45, 0.42)

    local windowWidth, windowHeight = love.graphics.getDimensions()
    player = Player.new(windowWidth / 2, windowHeight / 2, spawnBullet)
end

function love.update(dt)
    player:update(dt)

    -- Backwards, so removing a bullet does not skip the next one
    for i = #bullets, 1, -1 do
        local bullet = bullets[i]
        bullet:update(dt)
        if bullet.isDead then
            table.remove(bullets, i)
        end
    end
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
    for _, bullet in ipairs(bullets) do
        bullet:draw()
    end

    -- Temporary debug readout until there is a HUD
    local weapon = player.weapon
    love.graphics.print(string.format("Ammo: %d / %d", weapon.magazine, weapon.reserve), 10, 10)
end
