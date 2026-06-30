local Screen = {}

Screen.VIRTUAL_W = 1920
Screen.VIRTUAL_H = 1080

local isFullscreen = false
local scale = 1.0
local offsetX = 0
local offsetY = 0
local canvasPad = 0

function Screen.init()
    isFullscreen = true
    Screen.recalc()
end

function Screen.setCanvasPad(pad)
    canvasPad = pad
end

function Screen.recalc()
    local actualW = love.graphics.getWidth()
    local actualH = love.graphics.getHeight()
    local scaleX = actualW / Screen.VIRTUAL_W
    local scaleY = actualH / Screen.VIRTUAL_H
    scale = math.min(scaleX, scaleY)
    offsetX = (actualW - Screen.VIRTUAL_W * scale) / 2
    offsetY = (actualH - Screen.VIRTUAL_H * scale) / 2
end

function Screen.toggleFullscreen()
    isFullscreen = not isFullscreen
    love.window.setFullscreen(isFullscreen, "desktop")
    Screen.recalc()
end

function Screen.setFullscreen(v)
    isFullscreen = v
    love.window.setFullscreen(isFullscreen, "desktop")
    Screen.recalc()
end

function Screen.isFullscreen()
    return isFullscreen
end

function Screen.getScale()
    return scale
end

function Screen.getOffset()
    return offsetX, offsetY
end

function Screen.getWidth()
    return Screen.VIRTUAL_W
end

function Screen.getHeight()
    return Screen.VIRTUAL_H
end

function Screen.toVirtual(screenX, screenY)
    local vx = (screenX - offsetX) / scale
    local vy = (screenY - offsetY) / scale
    return vx, vy
end

function Screen.toScreen(virtualX, virtualY)
    local sx = virtualX * scale + offsetX
    local sy = virtualY * scale + offsetY
    return sx, sy
end

function Screen.getMouse()
    local mx, my
    if love._realGetPosition then
        mx, my = love._realGetPosition()
    else
        mx, my = love.mouse.getPosition()
    end
    return Screen.toVirtual(mx, my)
end

function Screen.setScissor(x, y, w, h)
    if x then
        love.graphics.setScissor(x + canvasPad, y + canvasPad, w, h)
    else
        love.graphics.setScissor()
    end
end

function Screen.applyTransform()
    love.graphics.translate(offsetX, offsetY)
    love.graphics.scale(scale, scale)
end

function Screen.isInside(x, y)
    local vx, vy = Screen.toVirtual(x, y)
    return vx >= 0 and vx <= Screen.VIRTUAL_W and vy >= 0 and vy <= Screen.VIRTUAL_H
end

return Screen
