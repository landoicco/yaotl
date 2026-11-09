-- A weapon: how it fires, and its ammo, a magazine refilled from a reserve
local Weapon = {}
Weapon.__index = Weapon

-- stats: name, label, magazineSize, reserve, pellets, spread, flashSize, muzzleX, muzzleY
-- Starts with a full magazine
function Weapon.new(stats)
    local self = setmetatable({}, Weapon)
    self.stats = stats
    self.magazine = stats.magazineSize
    self.reserve = stats.reserve
    return self
end

function Weapon:canShoot()
    return self.magazine > 0
end

function Weapon:consumeRound()
    self.magazine = self.magazine - 1
end

function Weapon:canReload()
    return self.magazine < self.stats.magazineSize and self.reserve > 0
end

-- Move as many rounds as fit from the reserve into the magazine
function Weapon:reload()
    local rounds = math.min(self.stats.magazineSize - self.magazine, self.reserve)
    self.magazine = self.magazine + rounds
    self.reserve = self.reserve - rounds
end

-- Name of the torso animation for an action: "Idle", "Move", "Shoot" or "Reload"
function Weapon:animation(action)
    return self.stats.name .. action
end

return Weapon
