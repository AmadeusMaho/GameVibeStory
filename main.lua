local Game = require("src.game")
local UI = require("src.ui")
local CursorManager = require("src.cursor")

local game
local gameState = "boot"
local bootSound = nil
local clickSound = nil
local startupSound = nil
local bootFont = nil
local desktopBg = nil

local bootLines = {
    {text = "American  Megatrends  Released: 12/01/94", x = 80, y = 20, color = {0.8, 0.8, 0.8}},
    {text = "             AMIBIOS (C)1994 American Megatrends Inc..", x = 80, y = 40, color = {0.8, 0.8, 0.8}},
    {text = "", x = 80, y = 60, color = {0.8, 0.8, 0.8}},
    {text = "BCN SIT 1989-1994 Special UC612C", x = 80, y = 80, color = {0.8, 0.8, 0.8}},
    {text = "SIT Rehab(tm) XX 115", x = 80, y = 100, color = {0.8, 0.8, 0.8}},
    {text = "Checking RAM  :  12000K OK", x = 80, y = 120, color = {0.8, 0.8, 0.8}},
    {text = "", x = 80, y = 140, color = {0.8, 0.8, 0.8}},
    {text = "WAIT...", x = 80, y = 160, color = {0.8, 0.8, 0.8}},
}
local bottomLines = {
    "Press DEL to enter SETUP , ESC to skip memory test",
    "08/06/2011-Soon-in-Tokyo-Rehab-Studio"
}

local bootLineIndex = 0
local bootCharIndex = 0
local bootDone = false
local bootLineDelay = 0.15
local bootCharDelay = 0.02
local bootTimerAccum = 0
local showAllLines = false
local showBottom = false

local countdownActive = false
local countdownValue = 3
local countdownTimer = 0

local startMenuOpen = false

local iconImages = {}

local desktopIcons = {
    {label = "Studio Empire", icon = "game", x = 40, y = 40},
    {label = "Recycle Bin", icon = "trash", x = 40, y = 140},
    {label = "Notepad", icon = "text", x = 40, y = 240},
}
local W95 = {
    bg = {0.75, 0.75, 0.75},
    titleActive = {0.0, 0.0, 0.5},
    highlight = {0, 0, 0.5},
    highlightText = {1, 1, 1},
    fieldBg = {1, 1, 1},
    fieldText = {0, 0, 0},
    borderLight = {1, 1, 1},
    borderDark = {0.5, 0.5, 0.5},
    borderUltra = {0.25, 0.25, 0.25},
    borderInner = {0.7, 0.7, 0.7},
    desktopBg = {0, 0, 0.5},
    iconText = {1, 1, 1},
}

function playClick()
    if clickSound then
        clickSound:stop()
        clickSound:play()
    end
end

function love.load()
    love.graphics.setBackgroundColor(0, 0, 0)
    love.graphics.setDefaultFilter("nearest", "nearest")

    local ok, snd = pcall(love.audio.newSource, "assets/sounds/start.wav", "static")
    if ok then
        bootSound = snd
        bootSound:play()
    end

    local ok2, snd2 = pcall(love.audio.newSource, "assets/sounds/click.wav", "static")
    if ok2 then clickSound = snd2 end

    local ok3, snd3 = pcall(love.audio.newSource, "assets/sounds/startupWindows.wav", "static")
    if ok3 then startupSound = snd3 end

    local ok4, img4 = pcall(love.graphics.newImage, "assets/sprites/bg.jpg")
    if ok4 then desktopBg = img4 end

    local ok5, img5 = pcall(love.graphics.newImage, "assets/sprites/recyclebin.png")
    if ok5 then iconImages["trash"] = img5 end
    local ok6, img6 = pcall(love.graphics.newImage, "assets/sprites/notepad.png")
    if ok6 then iconImages["text"] = img6 end

    local font = love.graphics.newFont(16)
    love.graphics.setFont(font)
    bootFont = font

    game = Game.new()
    UI.init()
    UI.onClose = function()
        gameState = "desktop"
        CursorManager.show(true)
    end
    CursorManager.init()
end

function love.update(dt)
    if gameState == "boot" then
        bootTimerAccum = bootTimerAccum + dt

        if not showAllLines and bootLineIndex < #bootLines then
            local currentLine = bootLines[bootLineIndex + 1]
            if currentLine and currentLine.text == "" then
                if bootTimerAccum >= bootLineDelay then
                    bootTimerAccum = 0
                    bootLineIndex = bootLineIndex + 1
                    bootCharIndex = 0
                    if bootLineIndex >= #bootLines then
                        bootDone = true
                        showAllLines = true
                        showBottom = true
                    end
                end
            elseif currentLine then
                if bootCharIndex < #currentLine.text then
                    while bootTimerAccum >= bootCharDelay and bootCharIndex < #currentLine.text do
                        bootTimerAccum = bootTimerAccum - bootCharDelay
                        bootCharIndex = bootCharIndex + 1
                    end
                else
                    if bootTimerAccum >= bootLineDelay then
                        bootTimerAccum = 0
                        bootLineIndex = bootLineIndex + 1
                        bootCharIndex = 0
                        if bootLineIndex >= #bootLines then
                            bootDone = true
                            showAllLines = true
                            showBottom = true
                        end
                    end
                end
            end
        elseif not bootDone then
            bootDone = true
            showAllLines = true
            showBottom = true
        end

        if bootDone and not countdownActive then
            countdownActive = true
            countdownValue = 3
            countdownTimer = 0
        end

        if countdownActive then
            countdownTimer = countdownTimer + dt
            if countdownTimer >= 1.0 then
                countdownTimer = countdownTimer - 1.0
                countdownValue = countdownValue - 1
                if countdownValue <= 0 then
                    gameState = "desktop"
                    if startupSound then startupSound:play() end
                end
            end
        end

    elseif gameState == "play" then
        game:update(dt)
    end
end

function drawAMIBIOSLogo(x, y)
    love.graphics.setColor(0.8, 0, 0)
    love.graphics.polygon("fill", x, y + 24, x + 12, y, x + 24, y + 24)
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.print("AMI", x - 2, y + 28)
end

function drawEnergyStar(x, y)
    love.graphics.setColor(0.8, 0.8, 0)
    love.graphics.setLineWidth(2)
    love.graphics.arc("line", "open", x + 30, y + 5, 30, -math.pi * 0.8, -math.pi * 0.2)
    love.graphics.line(x + 10, y + 30, x + 20, y + 10)
    love.graphics.line(x + 20, y + 10, x + 25, y + 20)
    love.graphics.line(x + 25, y + 20, x + 35, y + 5)
    love.graphics.line(x + 35, y + 5, x + 45, y + 20)
    love.graphics.line(x + 45, y + 20, x + 50, y + 10)
    love.graphics.line(x + 50, y + 10, x + 60, y + 30)
    love.graphics.print("Energy", x + 5, y + 38)
    love.graphics.setLineWidth(1)
end

function drawDesktopIcon(icon, mx, my)
    local hovered = mx >= icon.x and mx <= icon.x + 90 and my >= icon.y and my <= icon.y + 90
    local iconX = icon.x + 10
    local iconY = icon.y + 2
    local iconW = 64
    local iconH = 64

    if icon.icon == "game" then
        love.graphics.setColor(0, 0.5, 0)
        love.graphics.rectangle("fill", iconX, iconY, iconW, iconH, 4, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf("SE", iconX, iconY + 24, iconW, "center")
    elseif iconImages[icon.icon] then
        love.graphics.setColor(1, 1, 1)
        local img = iconImages[icon.icon]
        local imgW, imgH = img:getDimensions()
        local scale = math.min(iconW / imgW, iconH / imgH)
        love.graphics.draw(img, iconX + (iconW - imgW * scale) / 2, iconY + (iconH - imgH * scale) / 2, 0, scale, scale)
    end

    if hovered then
        love.graphics.setColor(0, 0, 0.8)
        love.graphics.rectangle("fill", icon.x, icon.y + 68, 90, 20)
        love.graphics.setColor(1, 1, 1)
    else
        love.graphics.setColor(1, 1, 1)
    end
    love.graphics.printf(icon.label, icon.x, icon.y + 70, 90, "center")
end

function drawDesktop()
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    local taskH = 40
    local mx, my = love.mouse.getPosition()

    CursorManager.set("normal")

    if desktopBg then
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(desktopBg, 0, 0, 0, winW / desktopBg:getWidth(), (winH - taskH) / desktopBg:getHeight())
    else
        love.graphics.setColor(W95.desktopBg)
        love.graphics.rectangle("fill", 0, 0, winW, winH - taskH)
    end

    for _, icon in ipairs(desktopIcons) do
        drawDesktopIcon(icon, mx, my)
        if mx >= icon.x and mx <= icon.x + 90 and my >= icon.y and my <= icon.y + 90 then
            CursorManager.set("link")
        end
    end

    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", 0, winH - taskH, winW, taskH)

    love.graphics.setColor(W95.borderLight)
    love.graphics.line(0, winH - taskH, winW, winH - taskH)
    love.graphics.setColor(W95.borderUltra)
    love.graphics.line(0, winH - taskH + 1, winW, winH - taskH + 1)

    local startHover = mx >= 2 and mx <= 90 and my >= winH - taskH + 2 and my <= winH - 2
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", 2, winH - taskH + 2, 88, taskH - 4)
    if startHover then
        love.graphics.setColor(W95.borderDark)
        love.graphics.line(2, winH - taskH + 2, 89, winH - taskH + 2)
        love.graphics.line(2, winH - taskH + 2, 2, winH - 3)
        love.graphics.setColor(W95.borderUltra)
        love.graphics.line(89, winH - taskH + 3, 89, winH - 3)
        love.graphics.line(3, winH - 3, 89, winH - 3)
    else
        love.graphics.setColor(W95.borderLight)
        love.graphics.line(2, winH - taskH + 2, 89, winH - taskH + 2)
        love.graphics.line(2, winH - taskH + 2, 2, winH - 3)
        love.graphics.setColor(W95.borderUltra)
        love.graphics.line(89, winH - taskH + 3, 89, winH - 3)
        love.graphics.line(3, winH - 3, 89, winH - 3)
    end
    love.graphics.setColor(W95.fieldText)
    love.graphics.print("Start", 20, winH - taskH + 12)

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(94, winH - taskH + 4, 94, winH - 5)

    local taskBtnX = 100
    local taskBtnW = 160
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", taskBtnX, winH - taskH + 2, taskBtnW, taskH - 4)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(taskBtnX, winH - taskH + 2, taskBtnX + taskBtnW, winH - taskH + 2)
    love.graphics.line(taskBtnX, winH - taskH + 2, taskBtnX, winH - 3)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(taskBtnX + taskBtnW - 1, winH - taskH + 3, taskBtnX + taskBtnW - 1, winH - 3)
    love.graphics.line(taskBtnX + 1, winH - 3, taskBtnX + taskBtnW - 1, winH - 3)
    love.graphics.setColor(W95.fieldText)
    love.graphics.print("Studio Empire", taskBtnX + 8, winH - taskH + 12)

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(264, winH - taskH + 4, 264, winH - 5)

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(winW - 135, winH - taskH + 4, winW - 135, winH - 5)
    local time = os.date("%H:%M")
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(winW - 132, winH - taskH + 4, winW - 132, winH - 5)
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", winW - 130, winH - taskH + 4, 126, taskH - 8)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(winW - 130, winH - taskH + 4, winW - 5, winH - taskH + 4)
    love.graphics.line(winW - 130, winH - taskH + 4, winW - 130, winH - 5)
    love.graphics.setColor(W95.borderUltra)
    love.graphics.line(winW - 5, winH - taskH + 5, winW - 5, winH - 5)
    love.graphics.line(winW - 129, winH - 5, winW - 5, winH - 5)
    love.graphics.setColor(W95.fieldText)
    love.graphics.printf(time, winW - 125, winH - taskH + 12, 110, "right")

    if startMenuOpen then
        local menuX = 2
        local menuY = winH - taskH - 180
        local menuW = 180
        local menuH = 180

        love.graphics.setColor(W95.bg)
        love.graphics.rectangle("fill", menuX, menuY, menuW, menuH)
        love.graphics.setColor(W95.borderLight)
        love.graphics.rectangle("line", menuX, menuY, menuX + menuW, menuY)
        love.graphics.setColor(W95.borderDark)
        love.graphics.rectangle("line", menuX + menuW, menuY, menuX + menuW, menuY + menuH)
        love.graphics.rectangle("line", menuX, menuY + menuH, menuX + menuW, menuY + menuH)
        love.graphics.rectangle("line", menuX, menuY, menuX, menuY + menuH)

        local menuItems = {
            {label = "Studio Empire", action = "game"},
            {label = "Notepad", action = "none"},
            {label = "---", action = "none"},
            {label = "Shut Down...", action = "quit"},
        }

        for i, item in ipairs(menuItems) do
            local itemY = menuY + (i - 1) * 25
            local hovered = mx >= menuX and mx <= menuX + menuW and my >= itemY and my <= itemY + 23

            if item.label == "---" then
                love.graphics.setColor(W95.borderDark)
                love.graphics.line(menuX + 5, itemY + 12, menuX + menuW - 5, itemY + 12)
            else
                if hovered then
                    love.graphics.setColor(W95.highlight)
                    love.graphics.rectangle("fill", menuX + 2, itemY + 1, menuW - 4, 22)
                    love.graphics.setColor(W95.highlightText)
                else
                    love.graphics.setColor(W95.fieldText)
                end
                love.graphics.print(item.label, menuX + 10, itemY + 6)
            end
        end

        love.graphics.setColor(W95.borderUltra)
        love.graphics.rectangle("line", menuX, menuY, menuW, menuH)
    end
end

function love.draw()
    if gameState == "boot" then
        love.graphics.clear(0, 0, 0)
        drawAMIBIOSLogo(80, 10)
        drawEnergyStar(1680, 10)
        love.graphics.setColor(0.8, 0.8, 0.8)
        love.graphics.setFont(bootFont)

        for i = 1, math.min(bootLineIndex, #bootLines) do
            local line = bootLines[i]
            if line.text ~= "" then
                love.graphics.setColor(line.color[1], line.color[2], line.color[3])
                love.graphics.print(line.text, line.x, line.y)
            end
        end

        if not showAllLines and bootLineIndex < #bootLines then
            local currentLine = bootLines[bootLineIndex + 1]
            if currentLine and currentLine.text ~= "" then
                local visibleText = currentLine.text:sub(1, bootCharIndex)
                love.graphics.setColor(currentLine.color[1], currentLine.color[2], currentLine.color[3])
                love.graphics.print(visibleText, currentLine.x, currentLine.y)
            end
        end

        if showBottom then
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print(bottomLines[1], 80, 1020)
            love.graphics.print(bottomLines[2], 80, 1045)
        end

        if countdownActive and countdownValue > 0 then
            love.graphics.setColor(0.8, 0.8, 0.8)
            love.graphics.print("Iniciando en " .. countdownValue .. "...", 80, 200)
        end

    elseif gameState == "desktop" then
        drawDesktop()
    elseif gameState == "play" then
        UI.draw(game)
    end
    CursorManager.draw()
end

function love.mousepressed(x, y, button)
    if button ~= 1 then return end

    if gameState == "boot" then
        return
    elseif gameState == "desktop" then
        playClick()
        local winH = love.graphics.getHeight()
        local taskH = 40
        local startHover = x >= 2 and x <= 90 and y >= winH - taskH + 2 and y <= winH - 2

        if startHover then
            startMenuOpen = not startMenuOpen
            return
        end

        if startMenuOpen then
            local menuX = 2
            local menuY = winH - taskH - 180
            local menuW = 180
            local menuItems = {
                {action = "game"},
                {action = "none"},
                {action = "none"},
                {action = "quit"},
            }

            if x >= menuX and x <= menuX + menuW and y >= menuY and y <= menuY + 180 then
                for i, item in ipairs(menuItems) do
                    local itemY = menuY + (i - 1) * 25
                    if y >= itemY and y <= itemY + 23 then
                        if item.action == "game" then
                            gameState = "play"
                            startMenuOpen = false
                        elseif item.action == "quit" then
                            love.event.quit()
                        end
                        break
                    end
                end
                return
            else
                startMenuOpen = false
            end
        end

        for _, icon in ipairs(desktopIcons) do
            if x >= icon.x and x <= icon.x + 90 and y >= icon.y and y <= icon.y + 90 then
                if icon.icon == "game" then
                    gameState = "play"
                end
                break
            end
        end
    elseif gameState == "play" then
        UI.mousepressed(x, y, button, game)
    end
end

function love.mousereleased(x, y, button)
    if gameState == "play" then
        UI.mousereleased(x, y, button, game)
    end
end

function love.keypressed(key)
    if gameState == "boot" then
        return
    elseif gameState == "play" then
        if key == "escape" then
            gameState = "desktop"
            CursorManager.show(true)
        else
            UI.keypressed(key, game)
        end
    end
end

function love.textinput(text)
    if gameState == "play" then
        UI.textinput(text)
    end
end
