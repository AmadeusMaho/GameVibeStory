local Trabajo = {}
Trabajo.__index = Trabajo

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
    tabActive = {0.75, 0.75, 0.75},
    tabInactive = {0.65, 0.65, 0.65},
    blue = {0.2, 0.4, 0.9},
}

local freelanceTasks = {
    {name = "Entrada de datos", reward = 1, time = 1.0},
    {name = "Correccion de documentos", reward = 2, time = 1.5},
    {name = "Clasificacion de archivos", reward = 1, time = 0.8},
    {name = "Revision de facturas", reward = 1, time = 1.2},
    {name = "Digitacion de formularios", reward = 2, time = 1.3},
    {name = "Procesamiento de nominas", reward = 2, time = 2.0},
    {name = "Inventario de equipo", reward = 1, time = 1.0},
    {name = "Archivo de correspondencia", reward = 1, time = 0.6},
}

local componentDefs = {
    gpu = {
        label = "GPU",
        color = {0.2, 0.5, 1.0},
        baseInterval = 2.0,
        basePower = 4,
        tiers = {
            {interval = 2.0, power = 4},
            {interval = 1.4, power = 5},
            {interval = 0.9, power = 7},
            {interval = 0.5, power = 9},
        },
    },
    cpu = {
        label = "CPU",
        color = {0.2, 0.8, 0.3},
        baseInterval = 3.0,
        basePower = 2,
        tiers = {
            {interval = 3.0, power = 2},
            {interval = 2.2, power = 3},
            {interval = 1.5, power = 4},
            {interval = 0.9, power = 5},
        },
    },
    ram = {
        label = "RAM",
        color = {0.9, 0.8, 0.2},
        baseInterval = 4.0,
        basePower = 3,
        tiers = {
            {interval = 4.0, power = 3},
            {interval = 3.0, power = 4},
            {interval = 2.0, power = 5},
            {interval = 1.2, power = 6},
        },
    },
    cooling = {
        label = "Refrigeracion",
        color = {0.2, 0.8, 0.8},
        baseInterval = 5.0,
        basePower = 2,
        tiers = {
            {interval = 5.0, power = 2},
            {interval = 3.5, power = 3},
            {interval = 2.5, power = 4},
            {interval = 1.5, power = 5},
        },
    },
}

local componentOrder = {"gpu", "cpu", "ram", "cooling"}

function Trabajo.new(x, y)
    local self = setmetatable({}, Trabajo)
    self.window = WindowManager.new("Trabajo Freelance", x or 250, y or 120, 460, 400)

    self.money = 0
    self.totalEarned = 0
    self.tasksCompleted = 0
    self.currentTask = nil
    self.taskProgress = 0
    self.cooldown = 0
    self.cooldownMax = 0.3
    self.level = 1
    self.baseReward = 1
    self.onWorkDone = nil
    self.emailRef = nil
    self.pcStatsRef = nil
    self.explorerRef = nil
    self.achievementsRef = nil
    self.completedProjects = 0

    self.selectedTab = 1
    self.tabs = {
        {label = "Trabajo Freelance", id = "freelance"},
        {label = "Trabajo Particular", id = "particular"},
    }
    self.tabUnlocked = false

    self.activeProject = nil
    self.projectProgress = 0
    self.projectMaxProgress = 100
    self.projectDaysLeft = 14
    self.projectMaxDays = 14
    self.projectReward = 0
    self.projectDesc = ""
    self.resultMessage = ""
    self.resultTimer = 0
    self.projectCooldown = 0

    self.components = {}
    self.circles = {}
    self.floatingNumbers = {}
    self.barShake = 0
    self.barShakeIntensity = 0

    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, x, y, button)
        return self:handleClick(x, y, button)
    end

    self.moneySounds = {}
    for i = 1, 3 do
        local ok, snd = pcall(love.audio.newSource, "assets/sounds/money" .. i .. ".wav", "static")
        if ok then
            snd:setVolume(0.6)
            table.insert(self.moneySounds, snd)
        end
    end

    return self
end

function Trabajo:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function Trabajo:getUpgrades()
    local upgMap = {}
    if self.explorerRef then
        for _, upg in ipairs(self.explorerRef.upgrades) do
            if upg.purchased then
                upgMap[upg.stat] = true
            end
        end
    end
    return upgMap
end

function Trabajo:getComponentTier(componentId)
    local upgMap = self:getUpgrades()
    local statMap = {
        gpu = "display",
        cpu = "cpu",
        ram = "ram",
        cooling = "cooling",
    }
    local stat = statMap[componentId]
    if not stat then return 0 end

    local tierCount = 0
    if self.explorerRef then
        for _, upg in ipairs(self.explorerRef.upgrades) do
            if upg.stat == stat and upg.purchased then
                tierCount = tierCount + 1
            end
        end
    end
    return math.min(tierCount, 4)
end

function Trabajo:getComponentInterval(componentId)
    local def = componentDefs[componentId]
    local tier = self:getComponentTier(componentId)
    if tier == 0 then return def.baseInterval end
    return def.tiers[tier].interval
end

function Trabajo:getComponentPower(componentId)
    local def = componentDefs[componentId]
    local tier = self:getComponentTier(componentId)
    if tier == 0 then return def.basePower end
    return def.tiers[tier].power
end

function Trabajo:recalcComponents()
    self.components = {}
    for _, id in ipairs(componentOrder) do
        local def = componentDefs[id]
        local tier = self:getComponentTier(id)
        table.insert(self.components, {
            id = id,
            label = def.label,
            color = def.color,
            tier = tier,
            timer = 0,
            interval = self:getComponentInterval(id),
            power = self:getComponentPower(id),
            vibration = 0,
        })
    end
end

function Trabajo:startProject(projectData)
    self.activeProject = projectData.name
    self.projectDesc = projectData.desc
    self.projectProgress = 0
    self.projectMaxProgress = 100
    self.projectDaysLeft = projectData.days or 14
    self.projectMaxDays = projectData.days or 14
    self.projectReward = projectData.reward
    self.resultMessage = ""
    self.resultTimer = 0
    self.selectedTab = 2
    self.circles = {}
    self.floatingNumbers = {}
    self.barShake = 0

    self:recalcComponents()
end

function Trabajo:update(dt)
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - dt
    end

    if self.currentTask then
        self.taskProgress = self.taskProgress + dt
        local adjustedTime = self.currentTask.time * self:getTaskTimeMultiplier()
        if self.taskProgress >= adjustedTime then
            local baseReward = self.currentTask.reward + (self.level - 1) * 1
            local comboMult = 1.0
            if self.achievementsRef then
                comboMult = self.achievementsRef.comboMultiplier or 1.0
            end
            local reward = math.floor(baseReward * comboMult)
            self.money = self.money + reward
            self.totalEarned = self.totalEarned + reward
            self.tasksCompleted = self.tasksCompleted + 1
            self.currentTask = nil
            self.taskProgress = 0
            self.cooldown = self.cooldownMax
            if self.moneySounds and #self.moneySounds > 0 then
                local snd = self.moneySounds[math.random(#self.moneySounds)]
                snd:stop()
                snd:play()
            end
            if self.achievementsRef then
                self.achievementsRef:onTaskComplete(reward)
            end
            if self.onWorkDone then self.onWorkDone() end
        end
    end

    if self.resultTimer > 0 then
        self.resultTimer = self.resultTimer - dt
        if self.resultTimer <= 0 then
            self.resultMessage = ""
        end
    end

    if self.projectCooldown > 0 then
        self.projectCooldown = self.projectCooldown - dt
    end

    if self.barShake > 0 then
        self.barShake = self.barShake - dt
    end

    for i = #self.floatingNumbers, 1, -1 do
        local num = self.floatingNumbers[i]
        num.timer = num.timer - dt
        num.y = num.y + num.vy * dt
        if num.timer <= 0 then
            table.remove(self.floatingNumbers, i)
        end
    end

    if self.activeProject then
        for _, comp in ipairs(self.components) do
            comp.timer = comp.timer + dt
            if comp.timer >= comp.interval then
                comp.timer = comp.timer - comp.interval
                self:generateCircle(comp)
            end
            if comp.vibration > 0 then
                comp.vibration = comp.vibration - dt
            end
        end

        for i = #self.circles, 1, -1 do
            local circ = self.circles[i]
            circ.x = circ.x + circ.vx * dt
            circ.y = circ.y + circ.vy * dt
            circ.life = circ.life - dt
            if circ.life <= 0 then
                self.projectProgress = self.projectProgress + circ.power
                table.insert(self.floatingNumbers, {
                    text = "+" .. circ.power .. "%",
                    x = circ.targetX,
                    y = circ.targetY,
                    timer = 1.0,
                    maxTimer = 1.0,
                    vy = -40,
                })
                self.barShake = 0.15
                self.barShakeIntensity = 2
                table.remove(self.circles, i)

                if self.projectProgress >= self.projectMaxProgress then
                    self:winProject()
                    return
                end
            end
        end

        self.projectDaysLeft = self.projectDaysLeft - dt * 0.05
        if self.projectDaysLeft <= 0 then
            self.projectDaysLeft = 0
            self:failProject()
        end
    end
end

function Trabajo:generateCircle(comp)
    local startX = comp.screenX or 0
    local startY = comp.screenY or 0
    local targetX = comp.barX or 0
    local targetY = comp.barY or 0

    local dx = targetX - startX
    local dy = targetY - startY
    local dist = math.sqrt(dx * dx + dy * dy)
    local speed = 200

    table.insert(self.circles, {
        x = startX,
        y = startY,
        vx = (dx / dist) * speed,
        vy = (dy / dist) * speed,
        targetX = targetX,
        targetY = targetY,
        color = comp.color,
        power = comp.power,
        life = dist / speed + 0.1,
        radius = 12,
        componentLabel = comp.label,
    })

    comp.vibration = 0.2
end

function Trabajo:winProject()
    local reward = self.projectReward
    self.money = self.money + reward
    self.totalEarned = self.totalEarned + reward
    self.completedProjects = (self.completedProjects or 0) + 1
    self.resultMessage = "Proyecto completado! +$" .. reward
    self.resultTimer = 3.0

    if self.achievementsRef then
        self.achievementsRef:onProjectComplete(reward, false)
    end

    if self.emailRef then
        self.emailRef:addEmailToInbox({
            subject = "Proyecto completado: " .. self.activeProject,
            sender = "clientes@freelance.com",
            type = "news",
            body = "Estimado freelancer:\n\nFelicidades! Ha completado\nel proyecto \"" .. self.activeProject .. "\"\nsatisfactoriamente.\n\nSu trabajo es de excelente\ncalidad. Seguiremos contactandole\npara futuros proyectos.\n\nRecompensa recibida: $" .. reward .. "\n\nSaludos cordiales.",
        })
    end
    self:clearProject()
    if self.onWorkDone then self.onWorkDone() end
end

function Trabajo:failProject()
    local penalty = math.floor(self.projectReward * 0.15)
    self.money = math.max(0, self.money - penalty)
    self.resultMessage = "Proyecto fracasado! -$" .. penalty
    self.resultTimer = 3.0

    if self.achievementsRef then
        self.achievementsRef:onProjectFail()
    end

    if self.emailRef then
        self.emailRef:addEmailToInbox({
            subject = "Proyecto fracasado - " .. self.activeProject,
            sender = "clientes@freelance.com",
            type = "news",
            body = "Estimado freelancer:\n\nLamentamos informarle que\nno pudo completar el proyecto\na tiempo.\n\nSe le ha cobrado una penalizacion\nde $" .. penalty .. " por los\ninconvenientes.\n\nLe recomendamos mejorar\nsus componentes de PC.",
        })
    end
    self:clearProject()
end

function Trabajo:clearProject()
    self.activeProject = nil
    self.projectProgress = 0
    self.projectMaxProgress = 100
    self.projectDaysLeft = 14
    self.projectMaxDays = 14
    self.projectReward = 0
    self.projectDesc = ""
    self.resultMessage = ""
    self.projectCooldown = 3.0
    self.selectedTab = 1
    self.circles = {}
    self.floatingNumbers = {}
    self.components = {}
    self.barShake = 0
end

function Trabajo:getEarningsPerClick()
    return self.baseReward + (self.level - 1) * 1
end

function Trabajo:getTaskTimeMultiplier()
    local mult = 1.43
    local upgMap = self:getUpgrades()
    if upgMap.cpu then mult = mult - 0.10 end
    if upgMap.display then mult = mult - 0.05 end
    if upgMap.ram then mult = mult - 0.05 end
    if mult < 0.7 then mult = 0.7 end
    return mult
end

function Trabajo:drawBevel(x, y, w, h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Trabajo:drawInset(x, y, w, h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Trabajo:drawContent(cx, cy, cw, ch)
    self.buttons = {}
    local prevFont = love.graphics.getFont()
    local smallFont = love.graphics.newFont(11)
    love.graphics.setFont(smallFont)

    local tabY = cy + 4
    local tabH = 20
    local tabStartX = cx + 8
    local tabW = 120

    for i, tab in ipairs(self.tabs) do
        local tx = tabStartX + (i - 1) * (tabW + 2)
        local isActive = (i == self.selectedTab)
        local isLocked = (i == 2 and not self.tabUnlocked)

        if isLocked then
            love.graphics.setColor(W95.tabInactive)
            love.graphics.rectangle("fill", tx, tabY + 4, tabW, tabH - 4)
            love.graphics.setColor(W95.textDim)
            love.graphics.printf(tab.label, tx, tabY + 6, tabW, "center")
        else
            if isActive then
                love.graphics.setColor(W95.tabActive)
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
    end

    local panelY = tabY + tabH + 4
    local panelH = ch - tabH - 16

    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx + 6, panelY, cw - 12, panelH)
    self:drawBevel(cx + 6, panelY, cw - 12, panelH)

    if self.selectedTab == 1 or not self.tabUnlocked then
        self:drawFreelanceTab(cx + 12, panelY + 6, cw - 24, panelH - 12)
    else
        self:drawParticularTab(cx + 12, panelY + 6, cw - 24, panelH - 12)
    end

    love.graphics.setFont(prevFont)
end

function Trabajo:drawFreelanceTab(x, y, w, h)
    love.graphics.setColor(W95.text)
    love.graphics.printf("Trabajo Freelance", x + 8, y + 8, w - 16, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 8, y + 26, x + w - 8, y + 26)

    love.graphics.setColor(W95.text)
    love.graphics.print("Tareas completadas: " .. self.tasksCompleted, x + 8, y + 34)
    love.graphics.setColor(W95.green)
    love.graphics.print("Dinero: $" .. self.money, x + 8, y + 52)

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 8, y + 72, x + w - 8, y + 72)

    if self.currentTask then
        love.graphics.setColor(W95.text)
        love.graphics.printf("Trabajando en:", x + 8, y + 82, w - 16, "center")
        love.graphics.setColor(W95.highlight)
        love.graphics.printf(self.currentTask.name, x + 8, y + 98, w - 16, "center")

        local barX = x + 20
        local barY = y + 118
        local barW = w - 40
        local barH = 20

        love.graphics.setColor(W95.fieldBg)
        love.graphics.rectangle("fill", barX, barY, barW, barH)
        self:drawInset(barX, barY, barW, barH)

        local progress = math.min(self.taskProgress / (self.currentTask.time * self:getTaskTimeMultiplier()), 1)
        love.graphics.setColor(W95.highlight)
        love.graphics.rectangle("fill", barX + 2, barY + 2, (barW - 4) * progress, barH - 4)

        love.graphics.setColor(W95.white)
        love.graphics.printf(math.floor(progress * 100) .. "%", barX, barY + 3, barW, "center")

        local cancelW = 70
        local cancelX = x + (w - cancelW) / 2
        local cancelY = y + 146
        local mx, my = love.mouse.getPosition()
        local cancelHov = mx >= cancelX and mx <= cancelX + cancelW and my >= cancelY and my <= cancelY + 20
        love.graphics.setColor(cancelHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", cancelX, cancelY, cancelW, 20)
        self:drawBevel(cancelX, cancelY, cancelW, 20)
        love.graphics.setColor(W95.red)
        love.graphics.printf("Cancelar", cancelX, cancelY + 3, cancelW, "center")
        table.insert(self.buttons, {x = cancelX, y = cancelY, w = cancelW, h = 20, action = "cancel"})
    else
        local earnings = self:getEarningsPerClick()
        love.graphics.setColor(W95.text)
        love.graphics.printf("Ganancia por tarea: $" .. earnings, x + 8, y + 82, w - 16, "center")

        local btnW = 140
        local btnH = 32
        local btnX = x + (w - btnW) / 2
        local btnY = y + 106
        local mx, my = love.mouse.getPosition()
        local btnHov = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH

        if self.cooldown > 0 then
            love.graphics.setColor(W95.textDim)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
            self:drawBevel(btnX, btnY, btnW, btnH)
            love.graphics.setColor(W95.textDim)
            love.graphics.printf("Esperar...", btnX, btnY + 9, btnW, "center")
        else
            love.graphics.setColor(btnHov and {0.85, 0.85, 0.85} or W95.bg)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
            self:drawBevel(btnX, btnY, btnW, btnH)
            love.graphics.setColor(W95.green)
            love.graphics.printf("Trabajar", btnX, btnY + 9, btnW, "center")
            table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "work"})
        end

        love.graphics.setColor(W95.borderDark)
        love.graphics.line(x + 8, y + 148, x + w - 8, y + 148)

        love.graphics.setColor(W95.textDim)
        love.graphics.print("Nivel: " .. self.level, x + 8, y + 156)
    end
end

function Trabajo:drawParticularTab(x, y, w, h)
    if not self.activeProject then
        love.graphics.setColor(W95.text)
        love.graphics.printf("Sin proyecto activo", x + 8, y + h / 2 - 20, w - 16, "center")
        love.graphics.setColor(W95.textDim)
        love.graphics.printf("Acepte un proyecto del correo\npara comenzar a trabajar.", x + 8, y + h / 2, w - 16, "center")
        if self.resultMessage ~= "" then
            love.graphics.setColor(W95.yellow)
            love.graphics.printf(self.resultMessage, x + 8, y + h - 16, w - 16, "center")
        end
        return
    end

    love.graphics.setColor(W95.text)
    love.graphics.printf("Proyecto Activo", x + 8, y + 4, w - 16, "center")
    love.graphics.setColor(W95.highlight)
    love.graphics.printf(self.activeProject, x + 8, y + 18, w - 16, "center")

    love.graphics.setColor(W95.textDim)
    local descLines = {}
    for line in self.projectDesc:gmatch("[^\n]*") do
        table.insert(descLines, line)
    end
    for i, line in ipairs(descLines) do
        love.graphics.printf(line, x + 8, y + 32 + (i - 1) * 12, w - 16, "center")
    end

    local barX = x + 16
    local barY = y + 60
    local barW = w - 32
    local barH = 16

    local shakeOffsetX = 0
    if self.barShake > 0 then
        shakeOffsetX = (math.random() - 0.5) * self.barShakeIntensity * 2
    end

    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", barX + shakeOffsetX, barY, barW, barH)
    self:drawInset(barX + shakeOffsetX, barY, barW, barH)
    local hpRatio = math.min(self.projectProgress / self.projectMaxProgress, 1)
    local barColor = hpRatio > 0.5 and W95.green or (hpRatio > 0.25 and W95.yellow or W95.red)
    love.graphics.setColor(barColor)
    love.graphics.rectangle("fill", barX + 2 + shakeOffsetX, barY + 2, (barW - 4) * hpRatio, barH - 4)

    love.graphics.setColor(W95.white)
    love.graphics.printf(math.floor(self.projectProgress) .. "/" .. self.projectMaxProgress, barX + shakeOffsetX, barY + 1, barW, "center")

    for _, num in ipairs(self.floatingNumbers) do
        local alpha = num.timer / num.maxTimer
        love.graphics.setColor(0.2, 1, 0.2, alpha)
        love.graphics.printf(num.text, num.x - 30, num.y, 60, "center")
    end

    local infoY = barY + barH + 6
    love.graphics.setColor(W95.text)
    love.graphics.print("Dias: " .. math.ceil(self.projectDaysLeft) .. "/" .. self.projectMaxDays, x + 16, infoY)
    love.graphics.setColor(W95.green)
    love.graphics.print("$" .. self.projectReward, x + w - 60, infoY)

    local gridY = infoY + 18
    local gridX = x + 16
    local boxW = (w - 40) / 2
    local boxH = 60
    local gapX = 8
    local gapY = 6

    local tierColors = {
        {0.5, 0.5, 0.5},
        {0.5, 0.5, 0.5},
        {0.2, 0.7, 0.2},
        {0.2, 0.4, 0.9},
        {0.6, 0.2, 0.9},
        {0.9, 0.6, 0.1},
    }

    local tierNames = {"Basico", "Basico", "Avanzado", "Elite", "Legendario"}

    local componentNames = {
        gpu = "S3 Trio64",
        cpu = "Pentium 133",
        ram = "16MB EDO",
        cooling = "Cooler Master",
    }

    for i, comp in ipairs(self.components) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local bx = gridX + col * (boxW + gapX)
        local by = gridY + row * (boxH + gapY)

        local vibOff = 0
        if comp.vibration > 0 then
            vibOff = (math.random() - 0.5) * 4
        end

        local tierCol = tierColors[comp.tier + 1] or tierColors[1]

        love.graphics.setColor(W95.fieldBg)
        love.graphics.rectangle("fill", bx + vibOff, by, boxW, boxH)

        love.graphics.setColor(tierCol[1] * 0.3, tierCol[2] * 0.3, tierCol[3] * 0.3)
        love.graphics.rectangle("fill", bx + vibOff, by, boxW, 3)
        love.graphics.rectangle("fill", bx + vibOff, by + boxH - 3, boxW, 3)
        love.graphics.rectangle("fill", bx + vibOff, by, 3, boxH)
        love.graphics.rectangle("fill", bx + vibOff + boxW - 3, by, 3, boxH)

        love.graphics.setColor(tierCol)
        love.graphics.rectangle("fill", bx + vibOff, by, boxW, 2)
        love.graphics.rectangle("fill", bx + vibOff, by + boxH - 2, boxW, 2)
        love.graphics.rectangle("fill", bx + vibOff, by, 2, boxH)
        love.graphics.rectangle("fill", bx + vibOff + boxW - 2, by, 2, boxH)

        love.graphics.setColor(W95.text)
        love.graphics.printf(comp.label, bx + vibOff, by + 5, boxW, "center")

        love.graphics.setColor(tierCol)
        love.graphics.printf(tierNames[comp.tier + 1] or "Basico", bx + vibOff, by + 17, boxW, "center")

        love.graphics.setColor(W95.textDim)
        love.graphics.printf(componentNames[comp.id] or comp.label, bx + vibOff, by + 29, boxW, "center")

        love.graphics.setColor(comp.color)
        love.graphics.printf(comp.power .. "%/circulo", bx + vibOff, by + 41, boxW, "center")

        comp.screenX = bx + boxW / 2 + vibOff
        comp.screenY = by + boxH / 2
        comp.barX = barX + barW * hpRatio
        comp.barY = barY + barH / 2
    end

    for _, circ in ipairs(self.circles) do
        local r = circ.radius
        local cx, cy = circ.x, circ.y

        love.graphics.setColor(0, 0, 0, 0.3)
        love.graphics.circle("fill", cx + 2, cy + 2, r)

        love.graphics.setColor(circ.color[1] * 0.5, circ.color[2] * 0.5, circ.color[3] * 0.5)
        love.graphics.circle("fill", cx, cy, r)

        love.graphics.setColor(circ.color[1] * 0.8, circ.color[2] * 0.8, circ.color[3] * 0.8)
        love.graphics.circle("fill", cx, cy, r * 0.75)

        love.graphics.setColor(circ.color)
        love.graphics.circle("fill", cx, cy, r * 0.55)

        love.graphics.setColor(circ.color[1] * 1.2, circ.color[2] * 1.2, circ.color[3] * 1.2)
        love.graphics.circle("fill", cx - r * 0.2, cy - r * 0.2, r * 0.25)

        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.circle("line", cx, cy, r)

        local prevFont = love.graphics.getFont()
        local bigFont = love.graphics.newFont(13)
        love.graphics.setFont(bigFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(circ.power .. "%", cx - 16, cy - 8, 32, "center")
        love.graphics.setFont(prevFont)
    end

    if self.resultMessage ~= "" then
        love.graphics.setColor(W95.yellow)
        love.graphics.printf(self.resultMessage, x + 8, y + h - 14, w - 16, "center")
    end
end

function Trabajo:handleClick(x, y, button)
    if button ~= 1 then return false end

    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "tab" then
                if btn.index == 2 and not self.tabUnlocked then
                    return true
                end
                self.selectedTab = btn.index
            elseif btn.action == "work" and self.cooldown <= 0 and not self.currentTask then
                self.currentTask = freelanceTasks[math.random(#freelanceTasks)]
                self.taskProgress = 0
            elseif btn.action == "cancel" then
                self.currentTask = nil
                self.taskProgress = 0
                self.cooldown = self.cooldownMax
            end
            return true
        end
    end
    return true
end

function Trabajo:draw(mx, my)
    self.window:drawFrame()
end

function Trabajo:hitTest(mx, my)
    return self.window:hitTest(mx, my)
end

function Trabajo:mousepressed(x, y, button)
    return self.window:mousepressed(x, y, button)
end

function Trabajo:mousereleased(x, y, button)
    self.window:mousereleased(x, y, button)
end

function Trabajo:mousemoved(x, y)
    self.window:mousemoved(x, y)
end

return Trabajo
