-- A weapon's ammo: a magazine refilled from a reserve
local Weapon = {}
Weapon.__index = Weapon

-- Starts with a full magazine
function Weapon.new(magazineSize, reserve)
    local self = setmetatable({}, Weapon)
    self.magazineSize = magazineSize
    self.magazine = magazineSize
    self.reserve = reserve
    return self
end

function Weapon:canShoot()
    return self.magazine > 0
end

function Weapon:consumeRound()
    self.magazine = self.magazine - 1
end

function Weapon:canReload()
    return self.magazine < self.magazineSize and self.reserve > 0
end

-- Move as many rounds as fit from the reserve into the magazine
function Weapon:reload()
    local rounds = math.min(self.magazineSize - self.magazine, self.reserve)
    self.magazine = self.magazine + rounds
    self.reserve = self.reserve - rounds
end

return Weapon
