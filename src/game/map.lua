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

function Map:draw()
    love.graphics.draw(self.batch)
end

return Map
