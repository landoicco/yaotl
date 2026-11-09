-- A map made in Tiled and exported to Lua (see maps/README.md)
-- The layer names are the contract with the editor: floor, walls, spawns
local Map = {}
Map.__index = Map

local MAPS_DIR = "assets/maps/"

local function findLayer(data, name, layerType)
    for _, layer in ipairs(data.layers) do
        if layer.name == name and layer.type == layerType then
            return layer
        end
    end
    error(string.format("map has no %s layer named '%s'", layerType, name))
end

-- One quad per tile of the tileset, indexed by its global id
local function buildQuads(tileset, image)
    local quads = {}
    for i = 0, tileset.tilecount - 1 do
        local x = (i % tileset.columns) * tileset.tilewidth
        local y = math.floor(i / tileset.columns) * tileset.tileheight
        quads[tileset.firstgid + i] = love.graphics.newQuad(x, y, tileset.tilewidth, tileset.tileheight, image)
    end
    return quads
end

-- Every tile of a layer goes into the batch once; 0 is an empty cell
function Map:addLayer(layer, quads)
    for i, gid in ipairs(layer.data) do
        if gid > 0 then
            local column, row = (i - 1) % self.width, math.floor((i - 1) / self.width)
            self.batch:add(quads[gid], column * self.tileSize, row * self.tileSize)
        end
    end
end

-- name: the file in assets/maps/, without extension
function Map.load(name)
    local data = love.filesystem.load(MAPS_DIR .. name .. ".lua")()
    assert(#data.tilesets == 1, "maps use a single embedded tileset")

    local self = setmetatable({}, Map)
    self.width, self.height = data.width, data.height -- in tiles
    self.tileSize = data.tilewidth

    local tileset = data.tilesets[1]
    local image = love.graphics.newImage(MAPS_DIR .. tileset.image)
    -- Keeps tile edges sharp, so neighbors do not bleed in
    image:setFilter("nearest", "nearest")
    local quads = buildQuads(tileset, image)

    local floor = findLayer(data, "floor", "tilelayer")
    local walls = findLayer(data, "walls", "tilelayer")
    self.batch = love.graphics.newSpriteBatch(image, #floor.data + #walls.data, "static")
    self:addLayer(floor, quads)
    self:addLayer(walls, quads)

    -- A cell is solid when the walls layer has any tile in it
    self.solid = {}
    for i, gid in ipairs(walls.data) do
        self.solid[i] = gid > 0
    end

    self.playerSpawn = nil
    self.zombieSpawns = {}
    for _, object in ipairs(findLayer(data, "spawns", "objectgroup").objects) do
        if object.name == "player" then
            self.playerSpawn = { x = object.x, y = object.y }
        elseif object.name == "zombie" then
            table.insert(self.zombieSpawns, { x = object.x, y = object.y })
        end
    end
    assert(self.playerSpawn, "map has no player spawn")

    return self
end

-- Size in pixels
function Map:getDimensions()
    return self.width * self.tileSize, self.height * self.tileSize
end

-- Cells outside the map count as walls, so nothing leaves it
function Map:isWall(column, row)
    if column < 0 or row < 0 or column >= self.width or row >= self.height then
        return true
    end
    return self.solid[row * self.width + column + 1]
end

local function clamp(value, low, high)
    return math.max(low, math.min(value, high))
end

-- Point of a cell closest to (x, y), and its distance
function Map:nearestPoint(column, row, x, y)
    local size = self.tileSize
    local nearestX = clamp(x, column * size, (column + 1) * size)
    local nearestY = clamp(y, row * size, (row + 1) * size)
    local dx, dy = x - nearestX, y - nearestY
    return nearestX, nearestY, math.sqrt(dx * dx + dy * dy)
end

local function byDistance(a, b)
    return a.distance < b.distance
end

-- Push a circle out of the walls it overlaps, so it slides along them; returns the new center
-- Moves are small next to a cell, so a center never ends up inside a wall
function Map:pushOut(x, y, radius)
    local size = self.tileSize
    local overlaps = {}
    for row = math.floor((y - radius) / size), math.floor((y + radius) / size) do
        for column = math.floor((x - radius) / size), math.floor((x + radius) / size) do
            if self:isWall(column, row) then
                local _, _, distance = self:nearestPoint(column, row, x, y)
                if distance < radius then
                    table.insert(overlaps, { column = column, row = row, distance = distance })
                end
            end
        end
    end

    -- Closest cells first: along a flat wall, the cell beside the circle pushes it straight out,
    -- and the corners of its neighbors no longer reach it
    table.sort(overlaps, byDistance)
    for _, cell in ipairs(overlaps) do
        local nearestX, nearestY, distance = self:nearestPoint(cell.column, cell.row, x, y)
        if distance > 0 and distance < radius then
            x = nearestX + (x - nearestX) / distance * radius
            y = nearestY + (y - nearestY) / distance * radius
        end
    end
    return x, y
end

-- Distance along a ray to the first wall, or nil if there is none within maxDistance
-- Walks the grid cell by cell (DDA), so no wall is skipped however fast the ray goes
-- dirX, dirY: a unit vector
function Map:castRay(x, y, dirX, dirY, maxDistance)
    local size = self.tileSize
    local column, row = math.floor(x / size), math.floor(y / size)
    if self:isWall(column, row) then
        return 0
    end

    local stepColumn = dirX > 0 and 1 or -1
    local stepRow = dirY > 0 and 1 or -1
    -- Distance along the ray to cross a whole cell, sideways or up and down
    local cellX = dirX ~= 0 and math.abs(size / dirX) or math.huge
    local cellY = dirY ~= 0 and math.abs(size / dirY) or math.huge
    -- Distance along the ray to the next vertical and horizontal grid lines
    local nextX = math.huge
    if dirX ~= 0 then
        nextX = ((column + (dirX > 0 and 1 or 0)) * size - x) / dirX
    end
    local nextY = math.huge
    if dirY ~= 0 then
        nextY = ((row + (dirY > 0 and 1 or 0)) * size - y) / dirY
    end

    -- Ends at the latest at the map's edge, which counts as a wall
    while true do
        local distance
        if nextX < nextY then
            distance = nextX
            column = column + stepColumn
            nextX = nextX + cellX
        else
            distance = nextY
            row = row + stepRow
            nextY = nextY + cellY
        end
        if distance > maxDistance then
            return nil
        end
        if self:isWall(column, row) then
            return distance
        end
    end
end

function Map:draw()
    love.graphics.draw(self.batch)
end

return Map
