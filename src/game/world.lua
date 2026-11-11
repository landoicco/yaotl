local Player = require("src.game.player")
local Bullet = require("src.game.bullet")
local Camera = require("src.game.camera")
local FlowField = require("src.game.flow_field")
local Lighting = require("src.game.lighting")
local Map = require("src.game.map")
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

-- Almost black, with a hint of blue
local AMBIENT = { 0.02, 0.02, 0.03 }

-- Bullets are points; zombies are circles
local function isHitting(bullet, zombie)
    local dx, dy = bullet.x - zombie.x, bullet.y - zombie.y
    return dx * dx + dy * dy <= zombie.radius * zombie.radius
end

-- Each bullet hits at most one living zombie
local function resolveHits(bullets, zombies)
    for _, bullet in ipairs(bullets) do
        for _, zombie in ipairs(zombies) do
            if not bullet.isDead and zombie:isAlive() and isHitting(bullet, zombie) then
                zombie:takeHit()
                bullet.isDead = true
            end
        end
    end
end

-- A melee blow reaches zombies this close to the striker, center to center
local MELEE_RANGE = 70
-- ...and within this angle to either side of where the striker faces
local MELEE_ARC = math.pi / 4

-- Shove every living zombie in reach of a melee blow, unless a wall is in between
-- Returns whether any zombie was hit
function World:strike(x, y, angle)
    local cosArc = math.cos(MELEE_ARC)
    local hitAny = false
    for _, zombie in ipairs(self.zombies) do
        local dx, dy = zombie.x - x, zombie.y - y
        local distance = math.sqrt(dx * dx + dy * dy)
        if zombie:isAlive() and distance > 0 and distance <= MELEE_RANGE then
            local dirX, dirY = dx / distance, dy / distance
            local isInFront = dirX * math.cos(angle) + dirY * math.sin(angle) >= cosArc
            if isInFront and not self.map:castRay(x, y, dirX, dirY, distance) then
                zombie:shove(dirX, dirY)
                hitAny = true
            end
        end
    end
    return hitAny
end

local function drawAll(entities)
    for _, entity in ipairs(entities) do
        -- Hits mark entities dead after their update; removal waits for the next frame
        if not entity.isDead then
            entity:draw()
        end
    end
end

function World.new()
    local self = setmetatable({}, World)
    self.bullets = {}
    self.zombies = {}
    self.map = Map.load("sandbox")
    self.lighting = Lighting.new(AMBIENT, self.map)
    self.flowField = FlowField.new(self.map)

    local spawn = self.map.playerSpawn
    self.player = Player.new(spawn.x, spawn.y, self.map, function(x, y, angle)
        self:spawnBullet(x, y, angle)
    end, function(x, y, angle)
        return self:strike(x, y, angle)
    end)

    for _, zombieSpawn in ipairs(self.map.zombieSpawns) do
        self:spawnZombie(zombieSpawn.x, zombieSpawn.y)
    end

    self.camera = Camera.new(self.map:getDimensions())
    self.camera:centerOn(spawn.x, spawn.y)

    return self
end

function World:spawnZombie(x, y)
    table.insert(self.zombies, Zombie.new(x, y, self.player, self.map, self.flowField))
end

function World:spawnBullet(x, y, angle)
    table.insert(self.bullets, Bullet.new(x, y, angle, self.map))
end

function World:update(dt)
    local player = self.player
    -- Through last frame's view, which is the one on screen
    player:update(dt, self.camera:toWorld(love.mouse.getPosition()))
    self.camera:follow(player.x, player.y, dt)
    self.flowField:update(player.x, player.y)
    updateAll(self.bullets, dt)
    resolveHits(self.bullets, self.zombies)
    updateAll(self.zombies, dt)
end

-- The match is lost once the player dies
function World:isOver()
    return not self.player:isAlive()
end

function World:draw()
    self.camera:attach()
    self.map:draw()
    drawAll(self.zombies)
    self.player:draw()

    local lights = {}
    self.map:addLights(lights)
    self.player:addLights(lights)
    self.lighting:draw(lights)

    -- Tracers glow, so the darkness does not cover them
    drawAll(self.bullets)
    self.camera:detach()
end

function World:keypressed(key)
    self.player:keypressed(key)
end

function World:mousepressed(button)
    self.player:mousepressed(button)
end

return World
