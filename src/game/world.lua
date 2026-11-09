local Player = require("src.game.player")
local Bullet = require("src.game.bullet")
local Zombie = require("src.game.zombie")

-- A match: the player and every entity around it
local World = {}
World.__index = World

-- Backwards, so removing an entity does not skip the next one
local function updateAll(entities, dt)
    for i = #entities, 1, -1 do
        local entity = entities[i]
        entity:update(dt)
        if entity.isDead then
            table.remove(entities, i)
        end
    end
end

local function drawAll(entities)
    for _, entity in ipairs(entities) do
        entity:draw()
    end
end

function World.new()
    local self = setmetatable({}, World)
    self.bullets = {}
    self.zombies = {}

    local width, height = love.graphics.getDimensions()
    self.player = Player.new(width / 2, height / 2, function(x, y, angle)
        self:spawnBullet(x, y, angle)
    end)

    -- Temporary test zombies until there is a spawner
    self:spawnZombie(0, 0)
    self:spawnZombie(width, 0)
    self:spawnZombie(width / 2, height)

    return self
end

function World:spawnZombie(x, y)
    table.insert(self.zombies, Zombie.new(x, y, self.player))
end

function World:spawnBullet(x, y, angle)
    table.insert(self.bullets, Bullet.new(x, y, angle))
end

function World:update(dt)
    self.player:update(dt)
    updateAll(self.zombies, dt)
    updateAll(self.bullets, dt)
end

function World:draw()
    drawAll(self.zombies)
    self.player:draw()
    drawAll(self.bullets)
end

function World:keypressed(key)
    self.player:keypressed(key)
end

function World:mousepressed(button)
    self.player:mousepressed(button)
end

return World
