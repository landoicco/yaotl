-- Paths around the walls toward a target, shared by every zombie (see docs/adr/0004-zombie-navigation.md)
-- Each open cell knows how many steps it is from the target's cell
local FlowField = {}
FlowField.__index = FlowField

-- Neighbors a step can go to: sideways first, then diagonals
-- stylua: ignore
local NEIGHBORS = {
    { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
    { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 },
}

function FlowField.new(map)
    local self = setmetatable({}, FlowField)
    self.map = map
    self.targetIndex = nil
    -- Steps to the target, by cell index; walls and cells it cannot reach have none
    self.distances = {}
    return self
end

function FlowField:cellIndex(column, row)
    return row * self.map.width + column + 1
end

-- Recompute the distances when the target moves to another cell
-- A breadth-first search from the target: each cell is reached by its shortest path first
function FlowField:update(targetX, targetY)
    local map = self.map
    local column, row = math.floor(targetX / map.tileSize), math.floor(targetY / map.tileSize)
    local index = self:cellIndex(column, row)
    if index == self.targetIndex then
        return
    end
    self.targetIndex = index

    local distances = { [index] = 0 }
    local columns, rows = { column }, { row }
    local head = 1
    while head <= #columns do
        local currentColumn, currentRow = columns[head], rows[head]
        local stepDistance = distances[self:cellIndex(currentColumn, currentRow)] + 1
        head = head + 1
        -- Sideways neighbors only, so a step always crosses a whole edge
        for i = 1, 4 do
            local neighbor, neighborRow = currentColumn + NEIGHBORS[i][1], currentRow + NEIGHBORS[i][2]
            local neighborIndex = self:cellIndex(neighbor, neighborRow)
            if not map:isWall(neighbor, neighborRow) and not distances[neighborIndex] then
                distances[neighborIndex] = stepDistance
                table.insert(columns, neighbor)
                table.insert(rows, neighborRow)
            end
        end
    end
    self.distances = distances
end

-- Steps from a cell to the target, or nil for walls and cells it cannot reach
function FlowField:distanceAt(column, row)
    if self.map:isWall(column, row) then
        return nil
    end
    return self.distances[self:cellIndex(column, row)]
end

-- Center of the neighboring cell one step closer to the target, or nil in the target's cell
-- A diagonal step needs both cells beside it open, so paths never cut a wall's corner
function FlowField:nextStep(x, y)
    local map = self.map
    local size = map.tileSize
    local column, row = math.floor(x / size), math.floor(y / size)
    local best = self:distanceAt(column, row)
    if not best then
        return nil
    end

    local bestColumn, bestRow
    for _, offset in ipairs(NEIGHBORS) do
        local dx, dy = offset[1], offset[2]
        local isDiagonal = dx ~= 0 and dy ~= 0
        local blocked = isDiagonal and (map:isWall(column + dx, row) or map:isWall(column, row + dy))
        local distance = not blocked and self:distanceAt(column + dx, row + dy)
        if distance and distance < best then
            best, bestColumn, bestRow = distance, column + dx, row + dy
        end
    end

    if not bestColumn then
        return nil
    end
    return (bestColumn + 0.5) * size, (bestRow + 0.5) * size
end

return FlowField
