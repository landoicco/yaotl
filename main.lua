local World = require("src.game.world")

local world

-- This function is called once at the beginning of the game
function love.load()
    -- Placeholder floor color until there is a map
    love.graphics.setBackgroundColor(0.45, 0.45, 0.42)

    world = World.new()
end

function love.update(dt)
    world:update(dt)

    -- Temporary: restart right away until there is a game over screen
    if world:isOver() then
        world = World.new()
    end
end

function love.keypressed(key)
    world:keypressed(key)
end

function love.mousepressed(x, y, btn, istouch, presses)
    world:mousepressed(btn)
end

-- Callback function used to draw on screen every frame
function love.draw()
    world:draw()

    -- Temporary debug readout until there is a HUD
    local player = world.player
    local weapon = player.weapon
    love.graphics.print(string.format("Ammo: %d / %d", weapon.magazine, weapon.reserve), 10, 10)
    love.graphics.print(string.format("Health: %d", player.health), 10, 30)
    love.graphics.print(string.format("Battery: %d%%", math.ceil(player.flashlight.charge * 100)), 10, 50)
end
