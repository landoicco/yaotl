-- What the player is holding and doing, following the State pattern from
-- Game Programming Patterns. The handgun is a superstate: its substates
-- inherit its behavior, such as switching to the flashlight, and override
-- only what differs.
--
-- States hold no data of their own, so a single table per state is shared.
-- Every function receives the player it acts on.
--
-- Each state implements:
--   enter(player)                called when the player switches to this state
--   update(player, dt)
--   keypressed(player, key)
--   mousepressed(player, button)
--   torso(player)                name of the torso animation to play
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

-- Switching to the flashlight works from any handgun state, even mid-reload
function Handgun.keypressed(player, key)
    if key == SWITCH_KEY then
        player:changeState(states.flashlight)
    end
end

function Handgun.mousepressed(player, button) end

-- Substates inherit whatever they do not override from the handgun
local function handgunState()
    return setmetatable({}, { __index = Handgun })
end

-- Aiming, ready to shoot or reload
local HandgunReady = handgunState()

function HandgunReady.keypressed(player, key)
    if key == RELOAD_KEY then
        player:changeState(states.handgunReloading)
    else
        Handgun.keypressed(player, key)
    end
end

function HandgunReady.mousepressed(player, button)
    if button == SHOOT_BUTTON then
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

function HandgunReloading.update(player, dt)
    if player.torso:isFinished() then
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
