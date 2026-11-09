-- Player states, a hierarchical state machine (see docs/adr/0001-player-state-machine.md)
-- Each state implements: enter, update, keypressed, mousepressed, torso
local states = {}

local SWITCH_KEY = "q"
local RELOAD_KEY = "r"
local SHOOT_BUTTON = 1

-- Holding the flashlight: lights the way, but cannot shoot
local Flashlight = {}

function Flashlight.enter(player) end

function Flashlight.update(player, dt) end

function Flashlight.keypressed(player, key)
    if key == SWITCH_KEY then
        player:changeState(states.handgunReady)
    end
end

function Flashlight.mousepressed(player, button) end

function Flashlight.torso(player)
    return player.isMoving and "flashlightMove" or "flashlightIdle"
end

-- Holding the handgun. Superstate of the handgun states below
local Handgun = {}

function Handgun.enter(player) end

function Handgun.update(player, dt) end

-- Works from every handgun substate, cancelling a reload
function Handgun.keypressed(player, key)
    if key == SWITCH_KEY then
        player:changeState(states.flashlight)
    end
end

function Handgun.mousepressed(player, button) end

-- New substate inheriting from Handgun
local function handgunState()
    return setmetatable({}, { __index = Handgun })
end

-- Aiming, ready to shoot or reload
local HandgunReady = handgunState()

function HandgunReady.keypressed(player, key)
    if key == RELOAD_KEY and player.weapon:canReload() then
        player:changeState(states.handgunReloading)
    else
        Handgun.keypressed(player, key)
    end
end

function HandgunReady.mousepressed(player, button)
    if button == SHOOT_BUTTON and player.weapon:canShoot() then
        player:changeState(states.handgunShooting)
    end
end

function HandgunReady.torso(player)
    return player.isMoving and "handgunMove" or "handgunIdle"
end

-- Firing a shot. Ready again once the shot animation ends
local HandgunShooting = handgunState()

function HandgunShooting.enter(player)
    player:shoot()
end

function HandgunShooting.update(player, dt)
    if player.torso:isFinished() then
        player:changeState(states.handgunReady)
    end
end

function HandgunShooting.torso(player)
    return "handgunShoot"
end

-- Reloading. Cannot shoot until the reload animation ends
local HandgunReloading = handgunState()

-- Rounds move into the magazine only if the reload completes
function HandgunReloading.update(player, dt)
    if player.torso:isFinished() then
        player.weapon:reload()
        player:changeState(states.handgunReady)
    end
end

function HandgunReloading.torso(player)
    return "handgunReload"
end

states.flashlight = Flashlight
states.handgunReady = HandgunReady
states.handgunShooting = HandgunShooting
states.handgunReloading = HandgunReloading

return states
