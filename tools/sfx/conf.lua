-- Only the event loop: the generator draws nothing and plays nothing
function love.conf(t)
    t.version = "11.5"
    t.modules.audio = false
    t.modules.graphics = false
    t.modules.joystick = false
    t.modules.keyboard = false
    t.modules.mouse = false
    t.modules.physics = false
    t.modules.sound = false
    t.modules.touch = false
    t.modules.video = false
    t.modules.window = false
end
