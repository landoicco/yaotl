local playerSprite = love.graphics.newImage("survivor.png")
local playerAngle = 0
local playerSpeed = 2
local projectiles = 0
local projectileSpeed = 5

-- This funtion is called one at the beginning of the game
function love.load()
    setPlayerSpawnPosition()
end

function love.update(dt)

    -- Move the player
    if love.keyboard.isDown("w") then
        player.y = player.y - playerSpeed
    end
    if love.keyboard.isDown("s") then
        player.y = player.y + playerSpeed
    end
    if love.keyboard.isDown("a") then
        player.x = player.x - playerSpeed
    end
    if love.keyboard.isDown("d") then
        player.x = player.x + playerSpeed
    end

    -- Rotate player
    local mouseX, mouseY = love.mouse.getPosition()
    local distanceX = mouseX - player.x
    local distanceY = mouseY - player.y
    playerAngle = math.atan2(distanceY - player.h, distanceX - player.w)

end

function love.mousepressed(x, y, btn, istouch, presses)
    if btn == 1 then
        print("Shoot")
    end
end

-- Callback function used to draw on screen every frame
function love.draw()
    love.graphics.draw(playerSprite, player.x, player.y, playerAngle)
end

--[[
    INIT FUNCTIONS
]]

-- Define spawn position for the player
function setPlayerSpawnPosition()
    local playerHeight = playerSprite:getHeight()
    local playerWidth = playerSprite:getWidth()
    local windowWidth, windowHeight = love.graphics.getDimensions()

    local playerXPos = (windowWidth / 2) - (playerWidth / 2)
    local playerYPos = (windowHeight / 2) - (playerHeight / 2)

    player = {}
    player.x = playerXPos
    player.y = playerYPos
    player.w = playerWidth
    player.h = playerHeight
end
