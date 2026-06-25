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

local hardwareComponents = {
    cpu = {
        base = {name = "Procesamiento", critChance = 0.05, actionsPerTurn = 1, gpuLock = 0},
        cpu100 = {name = "Lote de datos", critChance = 0.10, actionsPerTurn = 1, gpuLock = 1},
        pentium133 = {name = "Multitarea", critChance = 0.15, actionsPerTurn = 2, gpuLock = 2},
        pentium200 = {name = "SQL Avanzado", critChance = 0.20, actionsPerTurn = 2, gpuLock = 3},
    },
    gpu = {
        base = {name = "Render basico", power = 8, heatPerAttack = 5},
        s3trio = {name = "Graficos 2D", power = 14, heatPerAttack = 8},
        virge = {name = "Rendimiento 3D", power = 22, heatPerAttack = 12},
        banshee = {name = "Aceleracion 3D", power = 30, heatPerAttack = 16},
    },
    ram = {
        base = {name = "Carga rapida", special = "none"},
        ram32 = {name = "Buffer amplio", special = "none"},
        ram64 = {name = "Cache activo", special = "none"},
        ram128 = {name = "Virtualizacion", special = "none"},
    },
    cooling = {
        base = {name = "Disipador basico", coolPerTurn = 3, maxHeatTolerance = 60},
        cool1 = {name = "Ventilador activo", coolPerTurn = 5, maxHeatTolerance = 70},
        cool2 = {name = "Cooler avanzado", coolPerTurn = 8, maxHeatTolerance = 80},
        cool3 = {name = "Refrigeracion liquida", coolPerTurn = 12, maxHeatTolerance = 90},
    },
}

local gpuTierNames = {"Render basico", "S3 Trio64", "ViRGE", "Banshee"}

local projectTypes = {
    {name = "Base de datos Access", desc = "Crear sistema de inventario\npara empresa local.", hp = 100, days = 14, reward = 80},
    {name = "Pagina web corporativa", desc = "Diseno de sitio web\ncon HTML y tablas.", hp = 120, days = 14, reward = 100},
    {name = "Reporte de nominas", desc = "Sistema de nomina\nen Hoja de calculo.", hp = 80, days = 14, reward = 60},
    {name = "Presentacion multimedia", desc = "Slides con animaciones\ny transiciones.", hp = 90, days = 14, reward = 70},
    {name = "Soporte de red", desc = "Configurar red local\nentre 5 computadoras.", hp = 110, days = 14, reward = 90},
    {name = "App de inventario", desc = "Programa de control\nde stock en Visual Basic.", hp = 140, days = 14, reward = 120},
    {name = "Sistema de facturacion", desc = "Generador de facturas\ncon base de datos.", hp = 130, days = 14, reward = 110},
    {name = "Conversor de formatos", desc = "Herramienta para convertir\narchivos entre formatos.", hp = 70, days = 14, reward = 50},
}

function Trabajo.new(x, y)
    local self = setmetatable({}, Trabajo)
    self.window = WindowManager.new("Trabajo Freelance", x or 250, y or 120, 420, 380)

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
    self.projectHP = 0
    self.projectMaxHP = 0
    self.projectDays = 0
    self.projectMaxDays = 14
    self.projectReward = 0
    self.projectDesc = ""
    self.turnCount = 0
    self.resultMessage = ""
    self.resultTimer = 0
    self.projectCooldown = 0
    self.lastAttackLog = ""

    self.ram = 5
    self.maxRAM = 5
    self.ramRegen = 1

    self.heat = 0
    self.maxHeat = 60
    self.coolPerTurn = 3
    self.heatMultiplier = 1.0

    self.actionsPerTurn = 1
    self.actionsRemaining = 0
    self.turnActive = false

    self.critChance = 0.05
    self.gpuPower = 8
    self.gpuHeat = 5
    self.gpuTier = 0
    self.gpuMaxTier = 0

    self.showTutorial = true
    self.tutorialPage = 0

    self.floatingNumbers = {}
    self.barShake = 0
    self.barShakeIntensity = 0
    self.lastDamageTime = 0
    self.critFlash = 0
    self.attackAnimTimer = 0
    self.attackAnimActive = false

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

function Trabajo:recalcStats()
    local upgMap = self:getUpgrades()

    local cpuTier = 0
    if upgMap.cpu then cpuTier = 1 end
    local cpuData = hardwareComponents.cpu.base
    if cpuTier == 1 then cpuData = hardwareComponents.cpu.cpu100 end
    self.critChance = cpuData.critChance
    self.actionsPerTurn = cpuData.actionsPerTurn
    self.gpuMaxTier = cpuData.gpuLock

    local gpuTier = 0
    if upgMap.display then gpuTier = 1 end
    if gpuTier > self.gpuMaxTier then gpuTier = self.gpuMaxTier end
    self.gpuTier = gpuTier
    local gpuData = hardwareComponents.gpu.base
    if gpuTier == 1 then gpuData = hardwareComponents.gpu.s3trio
    elseif gpuTier == 2 then gpuData = hardwareComponents.gpu.virge
    elseif gpuTier == 3 then gpuData = hardwareComponents.gpu.banshee end
    self.gpuPower = gpuData.power
    self.gpuHeat = gpuData.heatPerAttack

    local coolTier = 0
    if upgMap.cooling then coolTier = 1 end
    local coolData = hardwareComponents.cooling.base
    if coolTier == 1 then coolData = hardwareComponents.cooling.cool1
    elseif coolTier == 2 then coolData = hardwareComponents.cooling.cool2
    elseif coolTier == 3 then coolData = hardwareComponents.cooling.cool3 end
    self.coolPerTurn = coolData.coolPerTurn
    self.maxHeat = coolData.maxHeatTolerance

    self.maxRAM = 5
    if self.ram > self.maxRAM then self.ram = self.maxRAM end
end

function Trabajo:startProject(projectData)
    self.activeProject = projectData.name
    self.projectDesc = projectData.desc
    self.projectHP = projectData.hp
    self.projectMaxHP = projectData.hp
    self.projectDays = 0
    self.projectMaxDays = projectData.days or 14
    self.projectReward = projectData.reward
    self.turnCount = 0
    self.resultMessage = ""
    self.resultTimer = 0
    self.selectedTab = 2
    self.lastAttackLog = ""

    self:recalcStats()
    self.ram = self.maxRAM
    self.heat = 0
    self.actionsRemaining = 0
    self.turnActive = false
    self.showTutorial = true
    self.tutorialPage = 0
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

    if self.critFlash > 0 then
        self.critFlash = self.critFlash - dt
    end

    if self.attackAnimTimer > 0 then
        self.attackAnimTimer = self.attackAnimTimer - dt
        if self.attackAnimTimer <= 0 then
            self.attackAnimActive = false
        end
    end

    for i = #self.floatingNumbers, 1, -1 do
        local num = self.floatingNumbers[i]
        num.timer = num.timer - dt
        num.y = num.y + num.vy * dt
        if num.timer <= 0 then
            table.remove(self.floatingNumbers, i)
        end
    end
end

function Trabajo:startTurn()
    if not self.activeProject then return end
    if self.turnActive then return end
    self:recalcStats()
    self.turnActive = true
    self.actionsRemaining = self.actionsPerTurn
end

function Trabajo:endTurn()
    if not self.activeProject then return end
    if not self.turnActive then return end

    self.turnActive = false
    self.actionsRemaining = 0
    self.turnCount = self.turnCount + 1
    self.projectDays = self.projectDays + 1

    self.ram = math.min(self.maxRAM, self.ram + self.ramRegen)

    local coolAmount = self.coolPerTurn
    if self.heat > self.maxHeat then
        coolAmount = math.floor(coolAmount * 0.5)
    end
    self.heat = math.max(0, self.heat - coolAmount)

    if self.heat >= self.maxHeat then
        local progressLoss = math.floor(self.projectMaxHP * 0.05)
        self.projectHP = math.min(self.projectMaxHP, self.projectHP + progressLoss)
        self.lastAttackLog = "Sobrecalentamiento! +" .. progressLoss .. " HP al proyecto"
        if self.achievementsRef then
            self.achievementsRef:onOverheat()
        end
    end

    if self.projectDays >= self.projectMaxDays then
        self:failProject()
    end
end

function Trabajo:attackProject(attackIndex)
    if not self.activeProject then return end
    if not self.turnActive then return end
    if self.actionsRemaining <= 0 then
        self.resultMessage = "Sin acciones restantes! Termina el dia."
        self.resultTimer = 1.5
        return
    end

    local ramCost = 2
    if self.ram < ramCost then
        self.resultMessage = "RAM insuficiente! Necesitas " .. ramCost .. " RAM."
        self.resultTimer = 1.5
        return
    end

    self.ram = self.ram - ramCost
    self.actionsRemaining = self.actionsRemaining - 1

    local damage = self.gpuPower
    local heatGain = self.gpuHeat
    local isCrit = math.random() < self.critChance

    if isCrit then
        damage = math.floor(damage * 1.5)
        heatGain = math.floor(heatGain * 1.3)
        self.lastAttackLog = "CRITICO! " .. damage .. " de daño"
        self.critFlash = 0.3
        if self.achievementsRef then
            self.achievementsRef:onCrit()
        end
    else
        self.lastAttackLog = "Ataque: " .. damage .. " de daño"
    end

    if self.heat >= self.maxHeat then
        damage = math.floor(damage * 1.3)
        heatGain = math.floor(heatGain * 1.2)
        self.lastAttackLog = self.lastAttackLog .. " (Sobrecalentado!)"
    end

    self.heat = math.min(100, self.heat + heatGain)
    self.projectHP = self.projectHP - damage

    self.barShake = 0.3
    self.barShakeIntensity = isCrit and 6 or 3
    self.attackAnimTimer = 0.2
    self.attackAnimActive = true

    table.insert(self.floatingNumbers, {
        text = "-" .. damage,
        x = 0,
        y = 0,
        timer = 1.0,
        maxTimer = 1.0,
        isCrit = isCrit,
        vy = -60,
    })

    if self.projectHP <= 0 then
        self.projectHP = 0
        self:winProject()
    end

    if self.achievementsRef then
        self.achievementsRef:triggerRandomEvent(self)
    end
end

function Trabajo:waitAction()
    if not self.activeProject then return end
    if not self.turnActive then return end

    self.ram = math.min(self.maxRAM, self.ram + 2)
    self.actionsRemaining = self.actionsRemaining - 1
    self.lastAttackLog = "Descansando... +2 RAM"
end

function Trabajo:winProject()
    local reward = self.projectReward
    self.money = self.money + reward
    self.totalEarned = self.totalEarned + reward
    self.completedProjects = (self.completedProjects or 0) + 1
    self.resultMessage = "Proyecto completado! +$" .. reward
    self.resultTimer = 3.0

    local wasOverheated = self.heat >= self.maxHeat
    if self.achievementsRef then
        self.achievementsRef:onProjectComplete(reward, wasOverheated)
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
    self.projectHP = 0
    self.projectMaxHP = 0
    self.projectDays = 0
    self.projectMaxDays = 14
    self.projectReward = 0
    self.projectDesc = ""
    self.turnCount = 0
    self.resultMessage = ""
    self.projectCooldown = 3.0
    self.selectedTab = 1
    self.lastAttackLog = ""
    self.heat = 0
    self.ram = self.maxRAM
    self.turnActive = false
    self.actionsRemaining = 0
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

    if self.showTutorial then
        self:drawTutorial(x, y, w, h)
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
    local hpRatio = self.projectHP / self.projectMaxHP
    local barColor = hpRatio > 0.5 and W95.green or (hpRatio > 0.25 and W95.yellow or W95.red)
    love.graphics.setColor(barColor)
    love.graphics.rectangle("fill", barX + 2 + shakeOffsetX, barY + 2, (barW - 4) * hpRatio, barH - 4)

    if self.critFlash > 0 then
        love.graphics.setColor(1, 1, 1, self.critFlash * 3)
        love.graphics.rectangle("fill", barX + 2 + shakeOffsetX, barY + 2, (barW - 4) * hpRatio, barH - 4)
    end

    love.graphics.setColor(W95.white)
    love.graphics.printf(self.projectHP .. "/" .. self.projectMaxHP, barX + shakeOffsetX, barY + 1, barW, "center")

    for _, num in ipairs(self.floatingNumbers) do
        local alpha = num.timer / num.maxTimer
        if num.isCrit then
            love.graphics.setColor(1, 0.2, 0.2, alpha)
        else
            love.graphics.setColor(1, 1, 0.2, alpha)
        end
        local numX = barX + barW / 2 + num.x
        local numY = barY + num.y
        love.graphics.printf(num.text, numX - 30, numY, 60, "center")
    end

    local infoY = barY + barH + 4
    love.graphics.setColor(W95.text)
    love.graphics.print("Dia: " .. self.projectDays .. "/" .. self.projectMaxDays, x + 16, infoY)
    love.graphics.setColor(W95.green)
    love.graphics.print("$" .. self.projectReward, x + w - 60, infoY)

    local ramY = infoY + 16
    love.graphics.setColor(W95.text)
    love.graphics.print("RAM:", x + 16, ramY)
    local ramBarX = x + 50
    local ramBarW = w - 66
    local ramBarH = 10
    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", ramBarX, ramY, ramBarW, ramBarH)
    self:drawInset(ramBarX, ramY, ramBarW, ramBarH)
    local ramRatio = self.ram / self.maxRAM
    love.graphics.setColor(W95.blue)
    love.graphics.rectangle("fill", ramBarX + 1, ramY + 1, (ramBarW - 2) * ramRatio, ramBarH - 2)
    love.graphics.setColor(W95.white)
    love.graphics.printf(self.ram .. "/" .. self.maxRAM, ramBarX, ramY - 1, ramBarW, "center")

    local heatY = ramY + 14
    love.graphics.setColor(W95.text)
    love.graphics.print("Calor:", x + 16, heatY)
    local heatBarX = x + 56
    local heatBarW = w - 72
    local heatBarH = 10
    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", heatBarX, heatY, heatBarW, heatBarH)
    self:drawInset(heatBarX, heatY, heatBarW, heatBarH)
    local heatRatio = math.min(self.heat / self.maxHeat, 1)
    local heatColor = heatRatio < 0.5 and W95.green or (heatRatio < 0.8 and W95.yellow or W95.red)
    love.graphics.setColor(heatColor)
    love.graphics.rectangle("fill", heatBarX + 1, heatY + 1, (heatBarW - 2) * heatRatio, heatBarH - 2)
    love.graphics.setColor(W95.white)
    local heatPct = math.floor(self.heat) .. "/" .. self.maxHeat
    love.graphics.printf(heatPct, heatBarX, heatY - 1, heatBarW, "center")

    if self.heat >= self.maxHeat then
        love.graphics.setColor(W95.red)
        love.graphics.print("SOBRECALENTADO!", x + 16, heatY + 12)
    end

    local actY = heatY + (self.heat >= self.maxHeat and 24 or 14)
    if self.turnActive then
        love.graphics.setColor(W95.text)
        love.graphics.print("Acciones: " .. self.actionsRemaining .. "/" .. self.actionsPerTurn, x + 16, actY)
    else
        love.graphics.setColor(W95.textDim)
        love.graphics.print("Esperando dia siguiente...", x + 16, actY)
    end

    if self.lastAttackLog ~= "" then
        local logY = actY + 14
        love.graphics.setColor(W95.text)
        love.graphics.print(self.lastAttackLog, x + 16, logY)
    end

    local btnY = y + h - 50
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 8, btnY - 6, x + w - 8, btnY - 6)

    if self.turnActive then
        local atkW = (w - 32) / 2
        local atkH = 22
        local gap = 4

        local gpuBtnX = x + 12
        local gpuBtnY = btnY
        local mx, my = love.mouse.getPosition()
        local gpuHov = mx >= gpuBtnX and mx <= gpuBtnX + atkW and my >= gpuBtnY and my <= gpuBtnY + atkH
        local gpuCanUse = self.ram >= 2 and self.actionsRemaining > 0
        love.graphics.setColor(gpuCanUse and (gpuHov and {0.85, 0.85, 0.85} or W95.bg) or {0.6, 0.6, 0.6})
        love.graphics.rectangle("fill", gpuBtnX, gpuBtnY, atkW, atkH)
        self:drawBevel(gpuBtnX, gpuBtnY, atkW, atkH)
        love.graphics.setColor(gpuCanUse and W95.text or W95.textDim)
        love.graphics.printf("GPU [" .. self.gpuPower .. "dmg]", gpuBtnX, gpuBtnY + 3, atkW, "center")
        if gpuCanUse then
            table.insert(self.buttons, {x = gpuBtnX, y = gpuBtnY, w = atkW, h = atkH, action = "attack", index = 1})
        end

        local waitBtnX = x + 12 + atkW + gap
        local waitHov = mx >= waitBtnX and mx <= waitBtnX + atkW and my >= gpuBtnY and my <= gpuBtnY + atkH
        local waitCanUse = self.actionsRemaining > 0
        love.graphics.setColor(waitCanUse and (waitHov and {0.85, 0.85, 0.85} or W95.bg) or {0.6, 0.6, 0.6})
        love.graphics.rectangle("fill", waitBtnX, gpuBtnY, atkW, atkH)
        self:drawBevel(waitBtnX, gpuBtnY, atkW, atkH)
        love.graphics.setColor(waitCanUse and W95.text or W95.textDim)
        love.graphics.printf("Descansar +2RAM", waitBtnX, gpuBtnY + 3, atkW, "center")
        if waitCanUse then
            table.insert(self.buttons, {x = waitBtnX, y = gpuBtnY, w = atkW, h = atkH, action = "wait"})
        end

        local endDayW = w - 24
        local endDayY = gpuBtnY + atkH + gap
        local endDayHov = mx >= x + 12 and mx <= x + 12 + endDayW and my >= endDayY and my <= endDayY + 20
        love.graphics.setColor(endDayHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", x + 12, endDayY, endDayW, 20)
        self:drawBevel(x + 12, endDayY, endDayW, 20)
        love.graphics.setColor(W95.orange)
        love.graphics.printf("Terminar Dia", x + 12, endDayY + 3, endDayW, "center")
        table.insert(self.buttons, {x = x + 12, y = endDayY, w = endDayW, h = 20, action = "endTurn"})
    else
        local startDayW = w - 24
        local startDayH = 24
        local startDayX = x + 12
        local startDayY = btnY
        local mx, my = love.mouse.getPosition()
        local startHov = mx >= startDayX and mx <= startDayX + startDayW and my >= startDayY and my <= startDayY + startDayH
        love.graphics.setColor(startHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", startDayX, startDayY, startDayW, startDayH)
        self:drawBevel(startDayX, startDayY, startDayW, startDayH)
        love.graphics.setColor(W95.green)
        love.graphics.printf("Iniciar Dia", startDayX, startDayY + 5, startDayW, "center")
        table.insert(self.buttons, {x = startDayX, y = startDayY, w = startDayW, h = startDayH, action = "startTurn"})
    end

    if self.resultMessage ~= "" then
        love.graphics.setColor(W95.yellow)
        love.graphics.printf(self.resultMessage, x + 8, y + h - 14, w - 16, "center")
    end
end

function Trabajo:drawTutorial(x, y, w, h)
    love.graphics.setColor(W95.highlight)
    love.graphics.printf("=== TUTORIAL: Combate ===", x + 8, y + 8, w - 16, "center")

    local pages = {
        {
            "GPU (Placa de video)",
            "Fuente principal de daño.",
            "Cada ataque llena la barra",
            "del proyecto. Cuanto mas",
            "poderosa la GPU, mas daño.",
        },
        {
            "CPU (Procesador)",
            "Determina:",
            "- Acciones por turno (1 basico)",
            "- Chance de critico (5% basico)",
            "- GPU maxima disponible",
        },
        {
            "RAM (Memoria)",
            "Tu maná. Empieza en 5.",
            "Cada accion cuesta 2 RAM.",
            "Se regenera 1 al terminar",
            "el dia.",
        },
        {
            "Refrigeracion",
            "Cada ataque genera calor.",
            "Si el calor supera el maximo,",
            "pierdes progreso del proyecto.",
            "Mejora la refrigeracion!",
        },
    }

    local page = pages[self.tutorialPage + 1]
    if page then
        for i, line in ipairs(page) do
            love.graphics.setColor(W95.text)
            love.graphics.print(line, x + 16, y + 30 + (i - 1) * 14)
        end
    end

    local btnY = y + h - 36
    local btnW = 80
    local btnH = 22
    local mx, my = love.mouse.getPosition()

    if self.tutorialPage > 0 then
        local prevX = x + 12
        local prevHov = mx >= prevX and mx <= prevX + btnW and my >= btnY and my <= btnY + btnH
        love.graphics.setColor(prevHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", prevX, btnY, btnW, btnH)
        self:drawBevel(prevX, btnY, btnW, btnH)
        love.graphics.setColor(W95.text)
        love.graphics.printf("< Anterior", prevX, btnY + 3, btnW, "center")
        table.insert(self.buttons, {x = prevX, y = btnY, w = btnW, h = btnH, action = "tutPrev"})
    end

    if self.tutorialPage < #pages - 1 then
        local nextX = x + w - btnW - 12
        local nextHov = mx >= nextX and mx <= nextX + btnW and my >= btnY and my <= btnY + btnH
        love.graphics.setColor(nextHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", nextX, btnY, btnW, btnH)
        self:drawBevel(nextX, btnY, btnW, btnH)
        love.graphics.setColor(W95.text)
        love.graphics.printf("Siguiente >", nextX, btnY + 3, btnW, "center")
        table.insert(self.buttons, {x = nextX, y = btnY, w = btnW, h = btnH, action = "tutNext"})
    else
        local closeX = x + (w - btnW) / 2
        local closeHov = mx >= closeX and mx <= closeX + btnW and my >= btnY and my <= btnY + btnH
        love.graphics.setColor(closeHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", closeX, btnY, btnW, btnH)
        self:drawBevel(closeX, btnY, btnW, btnH)
        love.graphics.setColor(W95.green)
        love.graphics.printf("Entendido!", closeX, btnY + 3, btnW, "center")
        table.insert(self.buttons, {x = closeX, y = btnY, w = btnW, h = btnH, action = "tutClose"})
    end

    love.graphics.setColor(W95.textDim)
    love.graphics.printf((self.tutorialPage + 1) .. "/" .. #pages, x + 8, y + h - 14, w - 16, "center")
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
            elseif btn.action == "attack" and self.activeProject then
                self:attackProject(btn.index)
            elseif btn.action == "wait" and self.activeProject then
                self:waitAction()
            elseif btn.action == "endTurn" and self.activeProject then
                self:endTurn()
            elseif btn.action == "startTurn" and self.activeProject then
                self:startTurn()
            elseif btn.action == "tutNext" then
                self.tutorialPage = self.tutorialPage + 1
            elseif btn.action == "tutPrev" then
                self.tutorialPage = self.tutorialPage - 1
            elseif btn.action == "tutClose" then
                self.showTutorial = false
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
