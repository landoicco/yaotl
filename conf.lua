-- LÖVE configuration, applied before the game modules are loaded
function love.conf(t)
    t.version = "11.5"

    t.window.title = "Yaotl"
    t.window.width = 800
    t.window.height = 600
    t.window.resizable = false
    t.window.vsync = 1
end
