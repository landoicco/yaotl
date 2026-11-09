-- Player states, a hierarchical state machine (see docs/adr/0001-player-state-machine.md)
-- The weapon states serve every weapon (see docs/adr/0002-shared-weapon-states.md)
-- Each state implements: enter, update, keypressed, mousepressed, torso
local states = {}

local SWITCH_KEY = "q"
local RELOAD_KEY = "r"
local SHOOT_BUTTON = 1
-- Key that takes out each weapon
local WEAPON_KEYS = { ["1"] = "handgun", ["2"] = "shotgun" }

-- Take out a weapon, ready to fire
local function takeOut(player, weaponName)
    player:equip(weaponName)
    player:changeState(states.weaponReady)
end

-- Holding the flashlight: lights the way, but cannot shoot
local Flashlight = {}

function Flashlight.enter(player) end

function Flashlight.update(player, dt) end

-- Q brings back the last weapon used
function Flashlight.keypressed(player, key)
    if key == SWITCH_KEY then
        player:changeState(states.weaponReady)
    elseif WEAPON_KEYS[key] then
        takeOut(player, WEAPON_KEYS[key])
    end
end

function Flashlight.mousepressed(player, button) end

function Flashlight.torso(player)
    return player.isMoving and "flashlightMove" or "flashlightIdle"
end

-- Holding a weapon. Superstate of the weapon states below
local Armed = {}

function Armed.enter(player) end

function Armed.update(player, dt) end

-- Works from every weapon substate, cancelling a reload
function Armed.keypressed(player, key)
    local weaponName = WEAPON_KEYS[key]
    if key == SWITCH_KEY then
        player:changeState(states.flashlight)
    elseif weaponName and weaponName ~= player.weapon.stats.name then
        takeOut(player, weaponName)
    end
end

function Armed.mousepressed(player, button) end

-- New substate inheriting from Armed
local function weaponState()
    return setmetatable({}, { __index = Armed })
end

-- Aiming, ready to shoot or reload
local WeaponReady = weaponState()

function WeaponReady.keypressed(player, key)
    if key == RELOAD_KEY and player.weapon:canReload() then
        player:changeState(states.weaponReloading)
    else
        Armed.keypressed(player, key)
    end
end

function WeaponReady.mousepressed(player, button)
    if button == SHOOT_BUTTON and player.weapon:canShoot() then
        player:changeState(states.weaponShooting)
    end
end

function WeaponReady.torso(player)
    return player.weapon:animation(player.isMoving and "Move" or "Idle")
end

-- Firing a shot. Ready again once the shot animation ends
local WeaponShooting = weaponState()

function WeaponShooting.enter(player)
    player:shoot()
end

function WeaponShooting.update(player, dt)
    if player.torso:isFinished() then
        player:changeState(states.weaponReady)
    end
end

function WeaponShooting.torso(player)
    return player.weapon:animation("Shoot")
end

-- Reloading. Cannot shoot until the reload animation ends
local WeaponReloading = weaponState()

-- Rounds move into the magazine only if the reload completes
function WeaponReloading.update(player, dt)
    if player.torso:isFinished() then
        player.weapon:reload()
        player:changeState(states.weaponReady)
    end
end

function WeaponReloading.torso(player)
    return player.weapon:animation("Reload")
end

states.flashlight = Flashlight
states.weaponReady = WeaponReady
states.weaponShooting = WeaponShooting
states.weaponReloading = WeaponReloading

return states
