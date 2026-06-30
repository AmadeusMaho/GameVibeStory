function love.conf(t)
    t.identity = "studio_empire"
    t.version = "11.4"
    t.window.title = "Studio Empire - Incremental Game Dev"
    t.window.width = 1920
    t.window.height = 1080
    t.window.resizable = true
    t.window.minwidth = 800
    t.window.minheight = 600
    t.window.fullscreen = true
    t.window.fullscreentype = "desktop"
    t.window.vsync = 1
    t.window.highdpi = false
    
    t.modules.joystick = false
    t.modules.physics = false
end
