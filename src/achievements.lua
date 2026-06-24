local Achievements = {}
Achievements.__index = Achievements

local WindowManager = require("src.window")

local W95 = {
    bg = {0.75, 0.75, 0.75},
    titleActive = {0.0, 0.0, 0.5},
    titleText = {1, 1, 1},
    borderLight = {1, 1, 1},
    borderDark = {0.5, 0.5, 0.5},
    borderUltra = {0.25, 0.25, 0.25},
    text = {0, 0, 0},
    textDim = {0.4, 0.4, 0.4},
    white = {1, 1, 1},
    fieldBg = {1, 1, 1},
    highlight = {0, 0, 0.5},
    highlightText = {1, 1, 1},
    green = {0, 0.5, 0},
    red = {0.8, 0, 0},
    yellow = {0.8, 0.6, 0},
    orange = {0.9, 0.5, 0},
    gold = {0.85, 0.65, 0},
    tabInactive = {0.65, 0.65, 0.65},
}

local achievementDefs = {
    {id = "first_task", name = "Primer Empleo", desc = "Completa tu primera tarea", icon = "1$", condition = function(s) return s.stats.tasksCompleted >= 1 end, reward = 10},
    {id = "task_10", name = "Trabajador", desc = "Completa 10 tareas", icon = "10", condition = function(s) return s.stats.tasksCompleted >= 10 end, reward = 25},
    {id = "task_50", name = "Veterano", desc = "Completa 50 tareas", icon = "50", condition = function(s) return s.stats.tasksCompleted >= 50 end, reward = 50},
    {id = "task_100", name = "Maestro del Teclado", desc = "Completa 100 tareas", icon = "100", condition = function(s) return s.stats.tasksCompleted >= 100 end, reward = 100},
    {id = "money_100", name = "Ahorrista", desc = "Gana $100 en total", icon = "$$", condition = function(s) return s.stats.totalEarned >= 100 end, reward = 20},
    {id = "money_500", name = "Emprendedor", desc = "Gana $500 en total", icon = "$$", condition = function(s) return s.stats.totalEarned >= 500 end, reward = 50},
    {id = "money_1000", name = "Magnate", desc = "Gana $1,000 en total", icon = "$$", condition = function(s) return s.stats.totalEarned >= 1000 end, reward = 100},
    {id = "money_5000", name = "Millonario", desc = "Gana $5,000 en total", icon = "$$", condition = function(s) return s.stats.totalEarned >= 5000 end, reward = 250},
    {id = "first_project", name = "Constructor", desc = "Completa tu primer proyecto", icon = "P1", condition = function(s) return s.stats.projectsCompleted >= 1 end, reward = 30},
    {id = "project_5", name = "Contratista", desc = "Completa 5 proyectos", icon = "P5", condition = function(s) return s.stats.projectsCompleted >= 5 end, reward = 75},
    {id = "project_10", name = "Director de Proyectos", desc = "Completa 10 proyectos", icon = "P10", condition = function(s) return s.stats.projectsCompleted >= 10 end, reward = 150},
    {id = "first_upgrade", name = "Mejorando", desc = "Compra tu primera mejora", icon = "U1", condition = function(s) return s.stats.upgradesPurchased >= 1 end, reward = 15},
    {id = "upgrade_5", name = "Inversionista", desc = "Compra 5 mejoras", icon = "U5", condition = function(s) return s.stats.upgradesPurchased >= 5 end, reward = 50},
    {id = "upgrade_10", name = "Tecnologo", desc = "Compra 10 mejoras", icon = "U10", condition = function(s) return s.stats.upgradesPurchased >= 10 end, reward = 100},
    -- COMBO ACHIEVEMENTS (disabled)
    -- {id = "combo_5", name = "En Racha", desc = "Alcanza combo de 5", icon = "C5", condition = function(s) return s.stats.highestCombo >= 5 end, reward = 25},
    -- {id = "combo_10", name = "Imparable", desc = "Alcanza combo de 10", icon = "C10", condition = function(s) return s.stats.highestCombo >= 10 end, reward = 75},
    -- {id = "combo_25", name = "Leyenda", desc = "Alcanza combo de 25", icon = "C25", condition = function(s) return s.stats.highestCombo >= 25 end, reward = 200},
    {id = "first_hire", name = "Jefe", desc = "Contrata tu primer empleado", icon = "E1", condition = function(s) return s.stats.employeesHired >= 1 end, reward = 20},
    {id = "hire_5", name = "Empresario", desc = "Contrata 5 empleados", icon = "E5", condition = function(s) return s.stats.employeesHired >= 5 end, reward = 100},
    {id = "first_crit", name = "Golpe Critico", desc = "Logra un golpe critico", icon = "!!", condition = function(s) return s.stats.critsLanded >= 1 end, reward = 15},
    {id = "overheat", name = "Sobrecalentado", desc = "Sobrecalienta tu PC", icon = "~~", condition = function(s) return s.stats.overheats >= 1 end, reward = 10},
    {id = "fail_project", name = "Fracaso", desc = "Falla un proyecto", icon = "X1", condition = function(s) return s.stats.projectsFailed >= 1 end, reward = 5},
    {id = "survive_overheat", name = " superviviente", desc = "Completa un proyecto sobrecalentado", icon = "SV", condition = function(s) return s.stats.overheatProjectsCompleted >= 1 end, reward = 30},
}

local randomEvents = {
    {type = "good", name = "Bonus de productividad", desc = "Ganas $15 extra!", effect = function(t) t.money = t.money + 15 end},
    {type = "good", name = "Cliente satisfecho", desc = "Propina de $10!", effect = function(t) t.money = t.money + 10 end},
    {type = "good", name = "Descubrimiento tecnico", desc = "+1 accion este turno", effect = function(t) t.actionsRemaining = t.actionsRemaining + 1 end},
    {type = "good", name = "Enfriamiento rapido", desc = "-15 calor", effect = function(t) t.heat = math.max(0, t.heat - 15) end},
    {type = "good", name = "Recarga de RAM", desc = "+3 RAM", effect = function(t) t.ram = math.min(t.maxRAM, t.ram + 3) end},
    {type = "bad", name = "Error de sistema", desc = "Pierdes $8", effect = function(t) t.money = math.max(0, t.money - 8) end},
    {type = "bad", name = "Sobrecalentamiento", desc = "+10 calor", effect = function(t) t.heat = math.min(100, t.heat + 10) end},
    {type = "bad", name = "Lag del sistema", desc = "-1 RAM", effect = function(t) t.ram = math.max(0, t.ram - 1) end},
    {type = "bad", name = "Pantallazo azul", desc = "Pierdes 15 HP de progreso", effect = function(t) if t.activeProject then t.projectHP = math.min(t.projectMaxHP, t.projectHP + 15) end end},
}

function Achievements.new(x, y)
    local self = setmetatable({}, Achievements)
    self.window = WindowManager.new("Logros y Estadisticas", x or 160, y or 80, 460, 400)

    self.trabajoRef = nil
    self.explorerRef = nil
    self.personalRef = nil

    self.stats = {
        totalEarned = 0,
        tasksCompleted = 0,
        projectsCompleted = 0,
        projectsFailed = 0,
        upgradesPurchased = 0,
        highestCombo = 0,
        employeesHired = 0,
        critsLanded = 0,
        overheats = 0,
        overheatProjectsCompleted = 0,
        playTime = 0,
    }

    -- COMBO SYSTEM (disabled for now, keep code)
    --[[
    self.combo = 0
    self.comboMultiplier = 1.0
    self.comboTimer = 0
    self.comboMaxTime = 30.0
    ]]

    self.achievements = {}
    for _, def in ipairs(achievementDefs) do
        self.achievements[def.id] = {
            name = def.name,
            desc = def.desc,
            icon = def.icon,
            reward = def.reward,
            unlocked = false,
            shown = false,
        }
    end

    self.pendingNotifications = {}
    self.currentEvent = nil
    self.eventTimer = 0

    self.selectedTab = 1
    self.tabs = {
        {label = "Logros", id = "achievements"},
        {label = "Estadisticas", id = "stats"},
    }

    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, x, y, button)
        return self:handleClick(x, y, button)
    end

    return self
end

function Achievements:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function Achievements:update(dt)
    self.stats.playTime = self.stats.playTime + dt

    -- COMBO UPDATE (disabled)
    --[[
    if self.combo > 0 then
        self.comboTimer = self.comboTimer + dt
        if self.comboTimer >= self.comboMaxTime then
            self.combo = 0
            self.comboMultiplier = 1.0
        end
    end
    ]]

    if self.eventTimer > 0 then
        self.eventTimer = self.eventTimer - dt
        if self.eventTimer <= 0 then
            self.currentEvent = nil
        end
    end

    for i = #self.pendingNotifications, 1, -1 do
        self.pendingNotifications[i].timer = self.pendingNotifications[i].timer - dt
        if self.pendingNotifications[i].timer <= 0 then
            table.remove(self.pendingNotifications, i)
        end
    end

    self:checkAchievements()
end

function Achievements:checkAchievements()
    for id, def in ipairs(achievementDefs) do
        local ach = self.achievements[def.id]
        if not ach.unlocked and def.condition(self) then
            ach.unlocked = true
            if self.trabajoRef then
                self.trabajoRef.money = self.trabajoRef.money + def.reward
                self.trabajoRef.totalEarned = self.trabajoRef.totalEarned + def.reward
            end
            table.insert(self.pendingNotifications, {
                title = "LOGRO DESBLOQUEADO!",
                name = ach.name,
                reward = def.reward,
                timer = 4.0,
            })
        end
    end
end

function Achievements:onTaskComplete(money)
    self.stats.tasksCompleted = self.stats.tasksCompleted + 1
    self.stats.totalEarned = self.stats.totalEarned + money
    -- COMBO (disabled)
    --[[
    self.combo = self.combo + 1
    self.comboTimer = 0
    if self.combo > self.stats.highestCombo then
        self.stats.highestCombo = self.combo
    end
    self.comboMultiplier = 1.0 + math.floor(self.combo / 3) * 0.25
    if self.comboMultiplier > 3.0 then self.comboMultiplier = 3.0 end
    ]]
end

function Achievements:onProjectComplete(reward, wasOverheated)
    self.stats.projectsCompleted = self.stats.projectsCompleted + 1
    self.stats.totalEarned = self.stats.totalEarned + reward
    if wasOverheated then
        self.stats.overheatProjectsCompleted = self.stats.overheatProjectsCompleted + 1
    end
end

function Achievements:onProjectFail()
    self.stats.projectsFailed = self.stats.projectsFailed + 1
    -- COMBO RESET (disabled)
    --[[
    self.combo = 0
    self.comboMultiplier = 1.0
    ]]
end

function Achievements:onUpgradePurchased()
    self.stats.upgradesPurchased = self.stats.upgradesPurchased + 1
end

function Achievements:onEmployeeHired()
    self.stats.employeesHired = self.stats.employeesHired + 1
end

function Achievements:onCrit()
    self.stats.critsLanded = self.stats.critsLanded + 1
end

function Achievements:onOverheat()
    self.stats.overheats = self.stats.overheats + 1
end

function Achievements:triggerRandomEvent(target)
    if math.random() > 0.15 then return nil end

    local event = randomEvents[math.random(#randomEvents)]
    event.effect(target)
    self.currentEvent = event
    self.eventTimer = 3.0
    return event
end

function Achievements:getComboColor()
    if self.combo >= 25 then return W95.gold
    elseif self.combo >= 10 then return {0.9, 0.3, 0.9}
    elseif self.combo >= 5 then return {0.2, 0.8, 0.2}
    elseif self.combo >= 3 then return {0.2, 0.6, 0.9}
    else return W95.text end
end

function Achievements:drawBevel(x, y, w, h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Achievements:drawInset(x, y, w, h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Achievements:drawContent(cx, cy, cw, ch)
    self.buttons = {}
    local prevFont = love.graphics.getFont()
    local smallFont = love.graphics.newFont(11)
    love.graphics.setFont(smallFont)

    local tabY = cy + 4
    local tabH = 20
    local tabStartX = cx + 8
    local tabW = 100

    for i, tab in ipairs(self.tabs) do
        local tx = tabStartX + (i - 1) * (tabW + 2)
        local isActive = (i == self.selectedTab)

        if isActive then
            love.graphics.setColor(W95.bg)
            love.graphics.rectangle("fill", tx, tabY, tabW, tabH)
            love.graphics.setColor(W95.borderLight)
            love.graphics.line(tx, tabY, tx + tabW, tabY)
            love.graphics.line(tx, tabY, tx, tabY + tabH)
            love.graphics.setColor(W95.borderDark)
            love.graphics.line(tx + tabW, tabY, tx + tabW, tabY + tabH)
        else
            love.graphics.setColor(W95.tabInactive)
            love.graphics.rectangle("fill", tx, tabY + 4, tabW, tabH - 4)
            love.graphics.setColor(W95.borderLight)
            love.graphics.line(tx, tabY + 4, tx + tabW, tabY + 4)
            love.graphics.setColor(W95.borderDark)
            love.graphics.line(tx + tabW, tabY + 4, tx + tabW, tabY + tabH)
        end
        love.graphics.setColor(W95.text)
        love.graphics.printf(tab.label, tx, tabY + (isActive and 4 or 6), tabW, "center")
        table.insert(self.buttons, {x = tx, y = tabY, w = tabW, h = tabH, action = "tab", index = i})
    end

    local panelY = tabY + tabH + 4
    local panelH = ch - tabH - 16

    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx + 6, panelY, cw - 12, panelH)
    self:drawBevel(cx + 6, panelY, cw - 12, panelH)

    if self.selectedTab == 1 then
        self:drawAchievementsTab(cx + 12, panelY + 6, cw - 24, panelH - 12)
    else
        self:drawStatsTab(cx + 12, panelY + 6, cw - 24, panelH - 12)
    end

    love.graphics.setFont(prevFont)
end

function Achievements:drawAchievementsTab(x, y, w, h)
    local unlocked = 0
    local total = #achievementDefs
    for _, ach in pairs(self.achievements) do
        if ach.unlocked then unlocked = unlocked + 1 end
    end

    love.graphics.setColor(W95.text)
    love.graphics.printf("Logros: " .. unlocked .. "/" .. total, x + 8, y + 4, w - 16, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 8, y + 20, x + w - 8, y + 20)

    local scrollArea = y + 24
    local scrollH = h - 28
    love.graphics.setScissor(x, scrollArea, w, scrollH)

    local rowH = 36
    local rowY = scrollArea + 2

    for i, def in ipairs(achievementDefs) do
        local ach = self.achievements[def.id]
        if rowY + rowH > scrollArea and rowY < scrollArea + scrollH then
            local isEven = i % 2 == 0
            if isEven then
                love.graphics.setColor({0.92, 0.92, 0.92})
                love.graphics.rectangle("fill", x + 2, rowY, w - 4, rowH)
            end

            if ach.unlocked then
                love.graphics.setColor(W95.gold)
                love.graphics.rectangle("fill", x + 8, rowY + 4, 28, 28)
                love.graphics.setColor(W95.text)
                love.graphics.printf(ach.icon, x + 8, rowY + 10, 28, "center")

                love.graphics.setColor(W95.green)
                love.graphics.print(ach.name, x + 42, rowY + 4)
                love.graphics.setColor(W95.textDim)
                love.graphics.print(ach.desc, x + 42, rowY + 18)

                love.graphics.setColor(W95.green)
                love.graphics.print("+$" .. ach.reward, x + w - 60, rowY + 10)
            else
                love.graphics.setColor({0.6, 0.6, 0.6})
                love.graphics.rectangle("fill", x + 8, rowY + 4, 28, 28)
                love.graphics.setColor(W95.textDim)
                love.graphics.printf("?", x + 8, rowY + 10, 28, "center")

                love.graphics.setColor(W95.textDim)
                love.graphics.print("???", x + 42, rowY + 4)
                love.graphics.setColor({0.5, 0.5, 0.5})
                love.graphics.print(ach.desc, x + 42, rowY + 18)
            end
        end
        rowY = rowY + rowH
    end

    love.graphics.setScissor()
end

function Achievements:drawStatsTab(x, y, w, h)
    love.graphics.setColor(W95.text)
    love.graphics.printf("=== ESTADISTICAS ===", x + 8, y + 4, w - 16, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 8, y + 20, x + w - 8, y + 20)

    local statY = y + 28
    local lineH = 18
    local col1X = x + 16
    local col2X = x + w / 2 + 8

    local function drawStat(label, value, sx, sy)
        love.graphics.setColor(W95.text)
        love.graphics.print(label, sx, sy)
        love.graphics.setColor(W95.green)
        love.graphics.print(tostring(value), sx + 140, sy)
    end

    local money = self.trabajoRef and self.trabajoRef.money or 0
    drawStat("Dinero actual:", "$" .. money, col1X, statY)
    statY = statY + lineH
    drawStat("Dinero total:", "$" .. self.stats.totalEarned, col1X, statY)
    statY = statY + lineH
    drawStat("Tareas completadas:", self.stats.tasksCompleted, col1X, statY)
    statY = statY + lineH
    drawStat("Proyectos completados:", self.stats.projectsCompleted, col1X, statY)
    statY = statY + lineH
    drawStat("Proyectos fallidos:", self.stats.projectsFailed, col1X, statY)
    statY = statY + lineH
    drawStat("Mejoras compradas:", self.stats.upgradesPurchased, col1X, statY)
    statY = statY + lineH
    drawStat("Empleados contratados:", self.stats.employeesHired, col1X, statY)
    statY = statY + lineH
    drawStat("Criticos logrados:", self.stats.critsLanded, col1X, statY)
    statY = statY + lineH
    drawStat("Sobrecalentamientos:", self.stats.overheats, col1X, statY)
    statY = statY + lineH

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 8, statY, x + w - 8, statY)
    statY = statY + 8

    -- COMBO STATS (disabled)
    --[[
    local comboColor = self:getComboColor()
    love.graphics.setColor(comboColor)
    love.graphics.print("RACHA ACTUAL: " .. self.combo, col1X, statY)
    love.graphics.setColor(W95.text)
    love.graphics.print("x" .. string.format("%.2f", self.comboMultiplier), col1X + 160, statY)
    statY = statY + lineH

    love.graphics.setColor(W95.gold)
    love.graphics.print("MEJOR RACHA: " .. self.stats.highestCombo, col1X, statY)
    statY = statY + lineH + 4
    ]]

    local minutes = math.floor(self.stats.playTime / 60)
    local hours = math.floor(minutes / 60)
    minutes = minutes % 60
    love.graphics.setColor(W95.text)
    love.graphics.print("Tiempo jugado: " .. hours .. "h " .. minutes .. "m", col1X, statY)
    statY = statY + lineH

    if self.currentEvent then
        love.graphics.setColor(W95.borderDark)
        love.graphics.line(x + 8, statY, x + w - 8, statY)
        statY = statY + 8
        local eventColor = self.currentEvent.type == "good" and W95.green or W95.red
        love.graphics.setColor(eventColor)
        love.graphics.print("EVENTO: " .. self.currentEvent.name, col1X, statY)
        statY = statY + lineH
        love.graphics.setColor(W95.text)
        love.graphics.print(self.currentEvent.desc, col1X, statY)
    end
end

function Achievements:drawNotifications()
    local prevFont = love.graphics.getFont()
    local smallFont = love.graphics.newFont(12)
    love.graphics.setFont(smallFont)

    local screenW, screenH = love.graphics.getDimensions()

    for i = #self.pendingNotifications, 1, -1 do
        local notif = self.pendingNotifications[i]
        if notif.timer > 0 then
            local alpha = math.min(1, notif.timer / 0.5)
            if notif.timer < 1.0 then
                alpha = notif.timer
            end

            local notifW = 280
            local notifH = 60
            local notifX = screenW - notifW - 20
            local notifY = 60 + (i - 1) * (notifH + 10)

            love.graphics.setColor(0, 0, 0, alpha * 0.5)
            love.graphics.rectangle("fill", notifX + 2, notifY + 2, notifW, notifH, 4, 4)

            love.graphics.setColor(0.1, 0.1, 0.1, alpha)
            love.graphics.rectangle("fill", notifX, notifY, notifW, notifH, 4, 4)

            love.graphics.setColor(W95.gold[1], W95.gold[2], W95.gold[3], alpha)
            love.graphics.rectangle("line", notifX, notifY, notifW, notifH, 4, 4)

            love.graphics.setColor(W95.gold[1], W95.gold[2], W95.gold[3], alpha)
            love.graphics.printf(notif.title, notifX, notifY + 6, notifW, "center")

            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.printf(notif.name, notifX, notifY + 22, notifW, "center")

            love.graphics.setColor(W95.green[1], W95.green[2], W95.green[3], alpha)
            love.graphics.printf("+$" .. notif.reward, notifX, notifY + 38, notifW, "center")
        else
            table.remove(self.pendingNotifications, i)
        end
    end

    love.graphics.setFont(prevFont)
end

function Achievements:drawComboHud()
    -- COMBO HUD (disabled)
    --[[
    if self.combo < 3 then return end

    local prevFont = love.graphics.getFont()
    local bigFont = love.graphics.newFont(18)
    love.graphics.setFont(bigFont)

    local screenW, screenH = love.graphics.getDimensions()
    local comboColor = self:getComboColor()

    local hudW = 140
    local hudH = 50
    local hudX = screenW - hudW - 20
    local hudY = screenH - 80

    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.rectangle("fill", hudX + 2, hudY + 2, hudW, hudH, 4, 4)

    love.graphics.setColor(0.1, 0.1, 0.1, 0.8)
    love.graphics.rectangle("fill", hudX, hudY, hudW, hudH, 4, 4)

    love.graphics.setColor(comboColor[1], comboColor[2], comboColor[3], 0.9)
    love.graphics.rectangle("line", hudX, hudY, hudW, hudH, 4, 4)

    love.graphics.setColor(comboColor[1], comboColor[2], comboColor[3], 1)
    love.graphics.printf("RACHA x" .. self.combo, hudX, hudY + 4, hudW, "center")

    love.graphics.setColor(W95.white)
    love.graphics.printf("x" .. string.format("%.2f", self.comboMultiplier), hudX, hudY + 26, hudW, "center")

    love.graphics.setFont(prevFont)
    ]]
end

function Achievements:draw(mx, my)
    self.window:drawFrame()
end

function Achievements:hitTest(mx, my)
    return self.window:hitTest(mx, my)
end

function Achievements:handleClick(x, y, button)
    if button ~= 1 then return false end

    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "tab" then
                self.selectedTab = btn.index
            end
            return true
        end
    end
    return true
end

function Achievements:mousepressed(x, y, button)
    return self.window:mousepressed(x, y, button)
end

function Achievements:mousereleased(x, y, button)
    self.window:mousereleased(x, y, button)
end

function Achievements:mousemoved(x, y)
    self.window:mousemoved(x, y)
end

return Achievements
