local UI = {}

local CursorManager = require("src.cursor")

local shader = nil
local canvas = nil
local CANVAS_W = 1920
local CANVAS_H = 1080
local CURVATURE = 0.02
local S = 1.35

local selectedTab = "main"
local selectedGenre = "RPG"
local selectedPlatform = "PC"
local buttons = {}

local W95 = {
    bg = {0.75, 0.75, 0.75},
    titleActive = {0.0, 0.0, 0.5},
    titleInactive = {0.5, 0.5, 0.5},
    titleText = {1, 1, 1},
    buttonFace = {0.75, 0.75, 0.75},
    buttonText = {0, 0, 0},
    highlight = {0, 0, 0.5},
    highlightText = {1, 1, 1},
    windowBg = {0.75, 0.75, 0.75},
    fieldBg = {1, 1, 1},
    fieldText = {0, 0, 0},
    borderLight = {1, 1, 1},
    borderDark = {0.5, 0.5, 0.5},
    borderUltra = {0.25, 0.25, 0.25},
    borderInner = {0.7, 0.7, 0.7},
    money = {0, 0, 0},
    research = {0, 0, 0.5},
    fame = {0.5, 0, 0},
    rep = {0, 0.4, 0}
}

function UI.init()
    shader = love.graphics.newShader("assets/shaders/crt.glsl")
    canvas = love.graphics.newCanvas(CANVAS_W, CANVAS_H)
    love.graphics.setBackgroundColor(0, 0, 0)
end

function UI.distortUV(uv)
    local centered = {uv[1] - 0.5, uv[2] - 0.5}
    local r2 = centered[1] * centered[1] + centered[2] * centered[2]
    local distorted = {
        centered[1] * (1.0 + CURVATURE * r2),
        centered[2] * (1.0 + CURVATURE * r2)
    }
    return {distorted[1] / 2.0 + 0.5, distorted[2] / 2.0 + 0.5}
end

function UI.getCanvasTransform()
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    local scaleX = winW / CANVAS_W
    local scaleY = winH / CANVAS_H
    local scale = math.min(scaleX, scaleY)
    local drawX = (winW - CANVAS_W * scale) / 2
    local drawY = (winH - CANVAS_H * scale) / 2
    return drawX, drawY, scale
end

function UI.screenToCanvas(mx, my)
    local drawX, drawY, scale = UI.getCanvasTransform()
    local canvasX = (mx - drawX) / scale
    local canvasY = (my - drawY) / scale
    return canvasX, canvasY
end

function UI.applyDistortion(canvasX, canvasY)
    local uvX = canvasX / CANVAS_W
    local uvY = canvasY / CANVAS_H
    local centeredX = uvX - 0.5
    local centeredY = uvY - 0.5
    
    local r2 = centeredX * centeredX + centeredY * centeredY
    local factor = 1.0 + CURVATURE * r2
    
    local distortedX = centeredX * factor + 0.5
    local distortedY = centeredY * factor + 0.5
    
    return distortedX * CANVAS_W, distortedY * CANVAS_H
end

function UI.inverseDistortScreen(mx, my)
    local canvasX, canvasY = UI.screenToCanvas(mx, my)
    
    if canvasX < 0 or canvasX > CANVAS_W or canvasY < 0 or canvasY > CANVAS_H then
        return -1, -1
    end
    
    return UI.applyDistortion(canvasX, canvasY)
end

function UI.draw(game)
    buttons = {}
    
    love.graphics.setCanvas(canvas)
    love.graphics.clear(W95.bg)
    
    UI.drawDesktop()
    UI.drawTaskbar(game)
    UI.drawWindow(game)
    
    love.graphics.setCanvas()
    
    local winW = love.graphics.getWidth()
    local winH = love.graphics.getHeight()
    local scaleX = winW / CANVAS_W
    local scaleY = winH / CANVAS_H
    local scale = math.min(scaleX, scaleY)
    local drawX = (winW - CANVAS_W * scale) / 2
    local drawY = (winH - CANVAS_H * scale) / 2
    
    shader:send("screen_size", {CANVAS_W, CANVAS_H})
    shader:send("time", love.timer.getTime())
    shader:send("curvature", CURVATURE)
    love.graphics.setShader(shader)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(canvas, drawX, drawY, 0, scale, scale)
    love.graphics.setShader()
    
    UI.updateCursor()
end

function UI.drawDesktop()
    love.graphics.setColor(0, 0, 0.5)
    love.graphics.rectangle("fill", 0, 0, CANVAS_W, CANVAS_H - 40 * S)
end

function UI.drawTaskbar(game)
    local taskY = CANVAS_H - 40 * S
    local taskH = 40 * S
    
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", 0, taskY, CANVAS_W, taskH)
    
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(0, taskY, CANVAS_W, taskY)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(0, taskY + 1, CANVAS_W, taskY + 1)
    
    UI.drawWin95Button(5, taskY + 5, 120 * S, taskH - 10, "Inicio", false)
    
    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", 130 * S, taskY + 5, 280 * S, taskH - 10, 2, 2)
    love.graphics.setColor(W95.fieldText)
    love.graphics.print("Studio Empire", 140 * S, taskY + (taskH - 16) / 2)
    
    local time = os.date("%H:%M")
    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", CANVAS_W - 140, taskY + 5, 130, taskH - 10, 2, 2)
    love.graphics.setColor(W95.fieldText)
    love.graphics.printf(time, CANVAS_W - 135, taskY + (taskH - 16) / 2, 120, "right")
end

function UI.drawWindow(game)
    local taskH = 40 * S
    local winX, winY, winW, winH = 40, 40, CANVAS_W - 80, CANVAS_H - 90 - taskH
    
    love.graphics.setColor(W95.borderUltra)
    love.graphics.rectangle("fill", winX, winY, winW, winH)
    love.graphics.setColor(W95.borderDark)
    love.graphics.rectangle("fill", winX + 1, winY + 1, winW - 2, winH - 2)
    love.graphics.setColor(W95.borderLight)
    love.graphics.rectangle("fill", winX + 2, winY + 2, winW - 4, winH - 4)
    love.graphics.setColor(W95.borderInner)
    love.graphics.rectangle("fill", winX + 3, winY + 3, winW - 6, winH - 6)
    love.graphics.setColor(W95.windowBg)
    love.graphics.rectangle("fill", winX + 4, winY + 4, winW - 8, winH - 8)
    
    love.graphics.setColor(W95.titleActive)
    love.graphics.rectangle("fill", winX + 4, winY + 4, winW - 8, 30 * S)
    
    love.graphics.setColor(W95.titleText)
    love.graphics.print("Studio Empire", winX + 10, winY + 8)
    
    local btnX = winX + winW - 30 * S
    UI.drawWin95TitleButton(btnX, winY + 5, 24 * S, 24 * S, "X")
    UI.addButton("win_close", btnX, winY + 5, 24 * S, 24 * S, function()
        if UI.onClose then UI.onClose() end
    end)
    UI.drawWin95TitleButton(btnX - 30 * S, winY + 5, 24 * S, 24 * S, "_")
    UI.addButton("win_min", btnX - 30 * S, winY + 5, 24 * S, 24 * S, function()
    end)
    UI.drawWin95TitleButton(btnX - 60 * S, winY + 5, 24 * S, 24 * S, "□")
    UI.addButton("win_max", btnX - 60 * S, winY + 5, 24 * S, 24 * S, function()
    end)
    
    love.graphics.setColor(W95.windowBg)
    love.graphics.rectangle("fill", winX + 8, winY + 34 * S, winW - 16, 26 * S)
    love.graphics.setColor(W95.buttonText)
    local menus = {"Archivo", "Edición", "Ver", "Ayuda"}
    local mx = winX + 12
    for _, menu in ipairs(menus) do
        love.graphics.print(menu, mx, winY + 34 * S + 4)
        mx = mx + love.graphics.getFont():getWidth(menu) + 28
    end
    
    UI.drawMainWindow(game, winX + 8, winY + 62 * S, winW - 16, winH - 70 * S)
end

function UI.drawMainWindow(game, x, y, w, h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.rectangle("fill", x + 1, y + 1, w - 2, h - 2)
    love.graphics.setColor(W95.windowBg)
    love.graphics.rectangle("fill", x + 2, y + 2, w - 4, h - 4)
    
    local tabH = 26 * S
    local tabY = y + 6
    local tabs = {
        {id = "main", label = "Principal"},
        {id = "staff", label = "Staff"},
        {id = "office", label = "Oficina"},
        {id = "prestige", label = "Consolas"}
    }
    
    local tx = x + 8
    for _, tab in ipairs(tabs) do
        local tw = love.graphics.getFont():getWidth(tab.label) + 30
        local isActive = selectedTab == tab.id
        
        if isActive then
            love.graphics.setColor(W95.windowBg)
            love.graphics.rectangle("fill", tx, tabY, tw, tabH)
            love.graphics.setColor(W95.borderDark)
            love.graphics.line(tx, tabY + tabH - 1, tx + tw - 1, tabY + tabH - 1)
            love.graphics.line(tx + tw - 1, tabY, tx + tw - 1, tabY + tabH - 1)
        else
            love.graphics.setColor(W95.buttonFace)
            love.graphics.rectangle("fill", tx, tabY, tw, tabH - 2)
            UI.drawWin95Border(tx, tabY, tw, tabH - 2, false)
        end
        
        love.graphics.setColor(W95.buttonText)
        love.graphics.printf(tab.label, tx, tabY + (tabH - 16) / 2, tw, "center")
        
        UI.addButton("tab_" .. tab.id, tx, tabY, tw, tabH, function()
            selectedTab = tab.id
        end)
        
        tx = tx + tw + 3
    end
    
    love.graphics.setColor(W95.borderDark)
    love.graphics.rectangle("fill", x + 4, tabY + tabH + 2, w - 8, 2)
    love.graphics.setColor(W95.borderLight)
    love.graphics.rectangle("fill", x + 4, tabY + tabH + 3, w - 8, 1)
    
    local contentY = tabY + tabH + 8
    local contentH = h - tabH - 14
    
    if selectedTab == "main" then
        UI.drawMainTab(game, x + 8, contentY, w - 16, contentH)
    elseif selectedTab == "staff" then
        UI.drawStaffTab(game, x + 8, contentY, w - 16, contentH)
    elseif selectedTab == "office" then
        UI.drawOfficeTab(game, x + 8, contentY, w - 16, contentH)
    elseif selectedTab == "prestige" then
        UI.drawPrestigeTab(game, x + 8, contentY, w - 16, contentH)
    end
end

function UI.drawMainTab(game, x, y, w, h)
    local boxW = 500 * S
    local boxH = 280 * S
    UI.drawWin95Groupbox(x, y, boxW, boxH, "Desarrollo")
    
    love.graphics.setColor(W95.buttonText)
    love.graphics.print("Género:", x + 20, y + 35)
    
    local genres = game.development.unlockedGenres
    local gx = x + 20
    for _, genre in ipairs(genres) do
        local isSelected = selectedGenre == genre
        UI.drawWin95RadioButton(gx, y + 55, genre, isSelected)
        UI.addButton("genre_" .. genre, gx, y + 53, love.graphics.getFont():getWidth(genre) + 28, 24, function()
            selectedGenre = genre
        end)
        gx = gx + love.graphics.getFont():getWidth(genre) + 40
    end
    
    love.graphics.setColor(W95.buttonText)
    love.graphics.print("Plataforma:", x + 20, y + 95)
    
    local platforms = game.development.unlockedPlatforms
    local px = x + 20
    for _, platform in ipairs(platforms) do
        local isSelected = selectedPlatform == platform
        UI.drawWin95RadioButton(px, y + 115, platform, isSelected)
        UI.addButton("platform_" .. platform, px, y + 113, love.graphics.getFont():getWidth(platform) + 28, 24, function()
            selectedPlatform = platform
        end)
        px = px + love.graphics.getFont():getWidth(platform) + 40
    end
    
    local canStart = not game.development.currentProject
    UI.drawWin95Button(x + 20, y + 155, boxW - 40, 36 * S, "Iniciar Desarrollo", canStart)
    if canStart then
        UI.addButton("start_dev", x + 20, y + 155, boxW - 40, 36 * S, function()
            game.development:startProject(selectedGenre, selectedPlatform)
        end)
    end
    
    if game.development.currentProject then
        local proj = game.development.currentProject
        local progress = proj.progress / proj.required
        
        love.graphics.setColor(W95.buttonText)
        love.graphics.print("Proyecto: " .. proj.genre .. " - " .. proj.platform, x + 20, y + 200)
        
        UI.drawWin95ProgressBar(x + 20, y + 222, boxW - 40, 22 * S, progress)
    end
    
    local gamesBoxX = x + boxW + 20
    local gamesBoxW = w - boxW - 20
    UI.drawWin95Groupbox(gamesBoxX, y, gamesBoxW, boxH, "Juegos Completados")
    
    local gamesPerRow = math.floor((gamesBoxW - 30) / 110)
    local gx2 = gamesBoxX + 15
    local gy = y + 35
    local startIdx = math.max(1, #game.development.completedGames - gamesPerRow * 5 + 1)
    
    for i = startIdx, #game.development.completedGames do
        local g = game.development.completedGames[i]
        if g then
            love.graphics.setColor(W95.fieldBg)
            love.graphics.rectangle("fill", gx2, gy, 100 * S, 70 * S, 2, 2)
            UI.drawWin95Border(gx2, gy, 100 * S, 70 * S, true)
            
            love.graphics.setColor(W95.buttonText)
            love.graphics.printf(g.genre:sub(1, 7), gx2, gy + 6, 100 * S, "center")
            
            love.graphics.setColor(g.quality >= 50 and {0, 0.4, 0} or W95.fame)
            love.graphics.print("Q:" .. g.quality, gx2 + 10, gy + 28)
            
            love.graphics.setColor(W95.money)
            love.graphics.print("$" .. game:formatNumber(g.income), gx2 + 10, gy + 48)
        end
        
        gx2 = gx2 + 110 * S
        if (gx2 - gamesBoxX - 15) >= gamesPerRow * 110 * S then
            gx2 = gamesBoxX + 15
            gy = gy + 78 * S
        end
    end
    
    local statsBoxY = y + boxH + 20
    UI.drawWin95Groupbox(x, statsBoxY, w, h - boxH - 25, "Estadísticas")
    
    love.graphics.setColor(W95.buttonText)
    local stats = {
        {"Dinero:", "$" .. game:formatNumber(game.stats.money), W95.money},
        {"Fama:", game:formatNumber(game.stats.fame), W95.fame},
        {"Rep:", math.floor(game.stats.reputation), W95.rep},
        {"Juegos:", game.stats.totalGamesMade, W95.buttonText},
        {"Investigación:", game:formatNumber(game.stats.research), W95.research}
    }
    
    local sx = x + 20
    for _, stat in ipairs(stats) do
        love.graphics.setColor(W95.buttonText)
        love.graphics.print(stat[1], sx, statsBoxY + 30)
        love.graphics.setColor(stat[3])
        love.graphics.print(stat[2], sx, statsBoxY + 55)
        sx = sx + 250
    end
end

function UI.drawStaffTab(game, x, y, w, h)
    local leftW = 700 * S
    UI.drawWin95Groupbox(x, y, leftW, h - 5, "Empleados (" .. #game.staff.members .. "/" .. game.staff.maxMembers .. ")")
    
    local sy = y + 30
    for i, member in ipairs(game.staff.members) do
        love.graphics.setColor(W95.fieldBg)
        love.graphics.rectangle("fill", x + 15, sy, leftW - 30, 65 * S, 2, 2)
        UI.drawWin95Border(x + 15, sy, leftW - 30, 65 * S, true)
        
        love.graphics.setColor(W95.buttonText)
        love.graphics.print(member.name .. " - " .. member.career, x + 25, sy + 8)
        love.graphics.setColor(W95.research)
        love.graphics.print("Nv." .. member.level .. " (" .. game.staff:getCareerLevelName(member.level) .. ")", x + 25, sy + 30)
        
        love.graphics.setColor(W95.buttonText)
        love.graphics.print("EXP:", x + 380, sy + 8)
        love.graphics.setColor(W95.research)
        love.graphics.print(math.floor(member.experience) .. "/" .. game.staff:getExperienceNeeded(member.level), x + 430, sy + 8)
        
        UI.drawWin95Button(x + 520, sy + 8, 120 * S, 26, "Entrenar", true)
        UI.addButton("train_" .. i, x + 520, sy + 8, 120 * S, 26, function()
            game.staff:train(i)
        end)
        
        UI.drawWin95Button(x + 520, sy + 36, 120 * S, 22, "Despedir", true)
        UI.addButton("fire_" .. i, x + 520, sy + 36, 120 * S, 22, function()
            game.staff:fire(i)
        end)
        
        sy = sy + 72 * S
    end
    
    local hireCost = game.staff.hireCost
    local canHire = #game.staff.members < game.staff.maxMembers
    UI.drawWin95Button(x + 15, sy + 15, 340 * S, 36 * S, "Contratar ($" .. game:formatNumber(hireCost) .. ")", canHire)
    if canHire then
        UI.addButton("hire", x + 15, sy + 15, 340 * S, 36 * S, function()
            game.staff:hire()
        end)
    end
    
    local rightX = x + leftW + 20
    local rightW = w - leftW - 20
    UI.drawWin95Groupbox(rightX, y, rightW, h - 5, "Estadísticas Totales")
    
    local totals = game.staff:getTotalStats()
    local statsY = y + 30
    local statsNames = {
        {"programming", "Programación"},
        {"design", "Diseño"},
        {"art", "Arte"},
        {"sound", "Sonido"},
        {"marketing", "Marketing"}
    }
    
    for _, stat in ipairs(statsNames) do
        love.graphics.setColor(W95.buttonText)
        love.graphics.print(stat[2] .. ":", rightX + 20, statsY)
        love.graphics.setColor(W95.research)
        love.graphics.print(math.floor(totals[stat[1]]), rightX + 170, statsY)
        
        UI.drawWin95ProgressBar(rightX + 240, statsY, rightW - 270, 20, math.min(1, totals[stat[1]] / 100))
        
        statsY = statsY + 38
    end
end

function UI.drawOfficeTab(game, x, y, w, h)
    local currentLevel = game.office:getCurrentLevel()
    local nextLevel = game.office:getNextLevel()
    
    local leftW = 500 * S
    UI.drawWin95Groupbox(x, y, leftW, 200 * S, "Oficina Actual")
    
    love.graphics.setColor(W95.buttonText)
    love.graphics.print("Nivel: " .. currentLevel.name, x + 20, y + 35)
    love.graphics.print("Capacidad: " .. currentLevel.capacity .. " empleados", x + 20, y + 62)
    love.graphics.print("Bonus Velocidad: +" .. math.floor(currentLevel.speedBonus * 100) .. "%", x + 20, y + 89)
    love.graphics.print("Bonus Calidad: +" .. math.floor(currentLevel.qualityBonus * 100) .. "%", x + 20, y + 116)
    
    if nextLevel then
        local canUpgrade = game.stats.money >= nextLevel.cost
        UI.drawWin95Button(x + 20, y + 150, leftW - 40, 32 * S, "Mejorar a " .. nextLevel.name, canUpgrade)
        if canUpgrade then
            UI.addButton("upgrade_office", x + 20, y + 150, leftW - 40, 32 * S, function()
                game.office:upgradeOffice()
            end)
        end
    end
    
    local rightX = x + leftW + 20
    local rightW = w - leftW - 20
    UI.drawWin95Groupbox(rightX, y, rightW, 200 * S, "Equipo")
    
    local equipment = game.office:getAllEquipment()
    local ex = rightX + 15
    local ey = y + 30
    
    for i, equip in ipairs(equipment) do
        local owned = game.office:hasEquipment(i)
        local canBuy = not owned and game.stats.money >= equip.cost
        
        love.graphics.setColor(W95.fieldBg)
        love.graphics.rectangle("fill", ex, ey, 190 * S, 75 * S, 2, 2)
        UI.drawWin95Border(ex, ey, 190 * S, 75 * S, true)
        
        love.graphics.setColor(W95.buttonText)
        love.graphics.printf(equip.name, ex, ey + 6, 190 * S, "center")
        
        if owned then
            love.graphics.setColor(W95.rep)
            love.graphics.printf("COMPRADO", ex, ey + 28, 190 * S, "center")
        else
            love.graphics.setColor(W95.buttonText)
            love.graphics.printf("$" .. game:formatNumber(equip.cost), ex, ey + 28, 190 * S, "center")
        end
        
        if equip.speedBonus > 0 then
            love.graphics.setColor(W95.research)
            love.graphics.printf("+" .. math.floor(equip.speedBonus * 100) .. "% Vel", ex, ey + 50, 190 * S, "center")
        end
        if equip.qualityBonus > 0 then
            love.graphics.setColor(W95.fame)
            love.graphics.printf("+" .. math.floor(equip.qualityBonus * 100) .. "% Cal", ex, ey + 50, 190 * S, "center")
        end
        
        if canBuy then
            UI.addButton("equip_" .. i, ex, ey, 190 * S, 75 * S, function()
                game.office:buyEquipment(i)
            end)
        end
        
        ex = ex + 200 * S
        if ex + 190 * S > rightX + rightW then
            ex = rightX + 15
            ey = ey + 82 * S
        end
    end
end

function UI.drawPrestigeTab(game, x, y, w, h)
    local leftW = 500 * S
    UI.drawWin95Groupbox(x, y, leftW, 220 * S, "Prestige")
    
    love.graphics.setColor(W95.buttonText)
    love.graphics.print("Legado: " .. game.prestige.legacy, x + 20, y + 35)
    love.graphics.print("Total: " .. game.prestige.totalLegacy, x + 20, y + 62)
    love.graphics.print("Prestiges: " .. game.prestige.prestigeCount, x + 20, y + 89)
    
    local legacyGain = game.prestige:getLegacyGain()
    love.graphics.print("Ganarías: +" .. legacyGain, x + 20, y + 120)
    
    local canPrestige = game.prestige:canPrestige()
    UI.drawWin95Button(x + 20, y + 160, leftW - 40, 36 * S, "PRESTIGEAR", canPrestige)
    if canPrestige then
        UI.addButton("prestige", x + 20, y + 160, leftW - 40, 36 * S, function()
            game.prestige:prestige()
        end)
    end
    
    local rightX = x + leftW + 20
    local rightW = w - leftW - 20
    UI.drawWin95Groupbox(rightX, y, rightW, 220 * S, "Consolas")
    
    local consoles = game.prestige:getConsoles()
    local cx = rightX + 20
    for i, console in ipairs(consoles) do
        local unlocked = i <= game.prestige.consoleGen
        
        love.graphics.setColor(W95.fieldBg)
        love.graphics.rectangle("fill", cx, y + 35, 160 * S, 80 * S, 2, 2)
        UI.drawWin95Border(cx, y + 35, 160 * S, 80 * S, true)
        
        love.graphics.setColor(W95.buttonText)
        love.graphics.printf(console.name, cx, y + 40, 160 * S, "center")
        love.graphics.setColor(W95.research)
        love.graphics.printf(console.era, cx, y + 62, 160 * S, "center")
        
        if unlocked then
            love.graphics.setColor(W95.rep)
            love.graphics.printf("OK", cx, y + 88, 160 * S, "center")
        else
            love.graphics.setColor(W95.buttonText)
            love.graphics.printf("$" .. game:formatNumber(console.cost), cx, y + 88, 160 * S, "center")
        end
        
        cx = cx + 175 * S
    end
    
    local upgradesBoxY = y + 235 * S
    UI.drawWin95Groupbox(x, upgradesBoxY, w, h - 240 * S, "Mejoras de Legado")
    
    local upgrades = game.prestige:getAllUpgrades()
    local ux = x + 20
    local uy = upgradesBoxY + 30
    
    for i, upgrade in ipairs(upgrades) do
        local owned = game.prestige:hasUpgrade(i)
        local canBuy = not owned and game.prestige.legacy >= upgrade.cost
        
        love.graphics.setColor(W95.fieldBg)
        love.graphics.rectangle("fill", ux, uy, 220 * S, 80 * S, 2, 2)
        UI.drawWin95Border(ux, uy, 220 * S, 80 * S, true)
        
        love.graphics.setColor(W95.buttonText)
        love.graphics.printf(upgrade.name, ux, uy + 6, 220 * S, "center")
        
        if owned then
            love.graphics.setColor(W95.rep)
            love.graphics.printf("COMPRADO", ux, uy + 28, 220 * S, "center")
        else
            love.graphics.setColor(W95.buttonText)
            love.graphics.printf(upgrade.cost .. " Legado", ux, uy + 28, 220 * S, "center")
        end
        
        love.graphics.setColor(W95.research)
        love.graphics.printf(upgrade.description, ux, uy + 52, 220 * S, "center")
        
        if canBuy then
            UI.addButton("upgrade_legacy_" .. i, ux, uy, 220 * S, 80 * S, function()
                game.prestige:buyUpgrade(i)
            end)
        end
        
        ux = ux + 235 * S
        if ux + 220 * S > x + w then
            ux = x + 20
            uy = uy + 90 * S
        end
    end
end

function UI.drawWin95Border(x, y, w, h, sunken)
    if sunken then
        love.graphics.setColor(W95.borderUltra)
        love.graphics.line(x, y, x + w - 1, y)
        love.graphics.line(x, y, x, y + h - 1)
        love.graphics.setColor(W95.borderDark)
        love.graphics.line(x + 1, y + 1, x + w - 2, y + 1)
        love.graphics.line(x + 1, y + 1, x + 1, y + h - 2)
        love.graphics.setColor(W95.borderInner)
        love.graphics.line(x + w - 2, y + 1, x + w - 2, y + h - 2)
        love.graphics.line(x + 1, y + h - 2, x + w - 2, y + h - 2)
        love.graphics.setColor(W95.borderLight)
        love.graphics.line(x + w - 1, y, x + w - 1, y + h - 1)
        love.graphics.line(x, y + h - 1, x + w - 1, y + h - 1)
    else
        love.graphics.setColor(W95.borderLight)
        love.graphics.line(x, y, x + w - 1, y)
        love.graphics.line(x, y, x, y + h - 1)
        love.graphics.setColor(W95.borderInner)
        love.graphics.line(x + 1, y + 1, x + w - 2, y + 1)
        love.graphics.line(x + 1, y + 1, x + 1, y + h - 2)
        love.graphics.setColor(W95.borderDark)
        love.graphics.line(x + w - 2, y + 1, x + w - 2, y + h - 2)
        love.graphics.line(x + 1, y + h - 2, x + w - 2, y + h - 2)
        love.graphics.setColor(W95.borderUltra)
        love.graphics.line(x + w - 1, y, x + w - 1, y + h - 1)
        love.graphics.line(x, y + h - 1, x + w - 1, y + h - 1)
    end
end

function UI.drawWin95Button(x, y, w, h, text, enabled)
    enabled = enabled ~= false
    
    love.graphics.setColor(W95.buttonFace)
    love.graphics.rectangle("fill", x, y, w, h)
    
    if enabled then
        love.graphics.setColor(W95.borderLight)
        love.graphics.line(x, y, x + w - 2, y)
        love.graphics.line(x, y, x, y + h - 2)
        love.graphics.setColor(W95.borderUltra)
        love.graphics.line(x + 1, y + h - 1, x + w - 1, y + h - 1)
        love.graphics.line(x + w - 1, y + 1, x + w - 1, y + h - 1)
    else
        love.graphics.setColor(W95.borderDark)
        love.graphics.line(x, y, x + w - 2, y)
        love.graphics.line(x, y, x, y + h - 2)
        love.graphics.setColor(W95.borderDark)
        love.graphics.line(x + 1, y + h - 1, x + w - 1, y + h - 1)
        love.graphics.line(x + w - 1, y + 1, x + w - 1, y + h - 1)
    end
    
    love.graphics.setColor(enabled and W95.buttonText or W95.borderDark)
    love.graphics.printf(text, x, y + (h - 16 * S / 1.4) / 2, w, "center")
end

function UI.drawWin95TitleButton(x, y, w, h, text)
    local isHover = UI.isHovered(x, y, w, h)
    
    love.graphics.setColor(W95.buttonFace)
    love.graphics.rectangle("fill", x, y, w, h)
    
    if isHover then
        love.graphics.setColor(W95.borderDark)
        love.graphics.line(x, y, x + w - 2, y)
        love.graphics.line(x, y, x, y + h - 2)
        love.graphics.setColor(W95.borderUltra)
        love.graphics.line(x + 1, y + h - 1, x + w - 1, y + h - 1)
        love.graphics.line(x + w - 1, y + 1, x + w - 1, y + h - 1)
    else
        love.graphics.setColor(W95.borderLight)
        love.graphics.line(x, y, x + w - 2, y)
        love.graphics.line(x, y, x, y + h - 2)
        love.graphics.setColor(W95.borderUltra)
        love.graphics.line(x + 1, y + h - 1, x + w - 1, y + h - 1)
        love.graphics.line(x + w - 1, y + 1, x + w - 1, y + h - 1)
    end
    
    love.graphics.setColor(W95.buttonText)
    love.graphics.printf(text, x, y + (h - 10) / 2, w, "center")
end

function UI.drawWin95Groupbox(x, y, w, h, title)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 12, y + 10, x + w - 1, y + 10)
    love.graphics.line(x, y + 14, x, y + h - 1)
    love.graphics.line(x + w - 1, y + 14, x + w - 1, y + h - 1)
    love.graphics.line(x, y + h - 1, x + w - 1, y + h - 1)
    
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x + 13, y + 11, x + w - 2, y + 11)
    love.graphics.line(x + 1, y + 15, x + 1, y + h - 2)
    love.graphics.line(x + w - 2, y + 15, x + w - 2, y + h - 2)
    love.graphics.line(x + 1, y + h - 2, x + w - 2, y + h - 2)
    
    love.graphics.setColor(W95.windowBg)
    love.graphics.rectangle("fill", x + 2, y + 16, w - 4, h - 18)
    
    love.graphics.setColor(W95.buttonText)
    love.graphics.print(title, x + 18, y + 2)
end

function UI.drawWin95RadioButton(x, y, text, selected)
    love.graphics.setColor(W95.fieldBg)
    love.graphics.circle("fill", x + 10, y + 12, 10)
    UI.drawWin95Border(x + 1, y + 3, 21, 21, true)
    
    if selected then
        love.graphics.setColor(W95.buttonText)
        love.graphics.circle("fill", x + 10, y + 12, 6)
    end
    
    love.graphics.setColor(W95.buttonText)
    love.graphics.print(text, x + 28, y + 3)
end

function UI.drawWin95ProgressBar(x, y, w, h, progress)
    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", x, y, w, h)
    UI.drawWin95Border(x, y, w, h, true)
    
    love.graphics.setColor(W95.highlight)
    love.graphics.rectangle("fill", x + 2, y + 2, (w - 4) * progress, h - 4)
end

function UI.isHovered(x, y, w, h)
    local mx, my = UI.inverseDistortScreen(love.mouse.getPosition())
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

function UI.addButton(id, x, y, w, h, callback)
    table.insert(buttons, {
        id = id,
        x = x,
        y = y,
        w = w,
        h = h,
        callback = callback
    })
end

function UI.mousepressed(x, y, button, game)
    if button == 1 then
        local cx, cy = UI.inverseDistortScreen(x, y)
        for _, btn in ipairs(buttons) do
            if cx >= btn.x and cx <= btn.x + btn.w and cy >= btn.y and cy <= btn.y + btn.h then
                if playClick then playClick() end
                btn.callback()
                break
            end
        end
    end
end

function UI.mousereleased(x, y, button, game)
end

function UI.keypressed(key, game)
    if key == "s" then
        game:save()
    end
end

function UI.textinput(text)
end

function UI.updateCursor()
    local mx, my = love.mouse.getPosition()
    local isOverButton = false
    local isOverClickable = false
    
    for _, btn in ipairs(buttons) do
        local cx, cy = UI.inverseDistortScreen(mx, my)
        if cx >= btn.x and cx <= btn.x + btn.w and cy >= btn.y and cy <= btn.y + btn.h then
            isOverButton = true
            break
        end
    end
    
    if isOverButton then
        CursorManager.set("link")
    else
        CursorManager.set("normal")
    end
end

return UI
