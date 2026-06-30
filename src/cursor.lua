local CursorManager = {}

local cursorImages = {}
local currentCursor = "normal"
local gameVisible = true

function CursorManager.init()
    local transData = love.image.newImageData(16, 16)
    love.mouse.setCursor(love.mouse.newCursor(transData, 0, 0))

    local ok1, img1 = pcall(love.graphics.newImage, "assets/cursors/Arrow1.png")
    if ok1 then cursorImages["normal"] = img1 end

    local ok2, img2 = pcall(love.graphics.newImage, "assets/cursors/Hand1.png")
    if ok2 then cursorImages["link"] = img2 end

    if not cursorImages["normal"] then
        local c = love.image.newImageData(16, 16)
        for y = 0, 15 do for x = 0, 15 do
            if (x == 0 or y == 0) and x < 12 and y < 12 then
                c:setPixel(x, y, 1, 1, 1, 1)
            end
        end end
        cursorImages["normal"] = love.graphics.newImage(c)
    end
    if not cursorImages["link"] then
        cursorImages["link"] = cursorImages["normal"]
    end
end

function CursorManager.draw()
    if not gameVisible then return end
    local img = cursorImages[currentCursor]
    if img then
        local mx, my = love.mouse.getPosition()
        local scale = 0.75
        local ox, oy = 0, 0
        if currentCursor == "normal" then
            ox, oy = 1, 1
        elseif currentCursor == "link" then
            ox, oy = 4, 1
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, mx - ox * scale, my - oy * scale, 0, scale, scale)
    end
end

function CursorManager.drawAt(vx, vy)
    if not gameVisible then return end
    local img = cursorImages[currentCursor]
    if img then
        local scale = 0.75
        local ox, oy = 0, 0
        if currentCursor == "normal" then
            ox, oy = 1, 1
        elseif currentCursor == "link" then
            ox, oy = 4, 1
        end
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(img, vx - ox * scale, vy - oy * scale, 0, scale, scale)
    end
end

function CursorManager.set(name)
    if cursorImages[name] then
        currentCursor = name
    end
end

function CursorManager.get()
    return currentCursor
end

function CursorManager.show(v)
    gameVisible = v
end

return CursorManager
