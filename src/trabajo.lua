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

local projectDifficulties = {
    {id = "facil", label = "Facil", color = {0.2, 0.8, 0.2}, hpMult = 1.0, rewardMult = 1.0},
    {id = "normal", label = "Normal", color = {0.9, 0.9, 0.2}, hpMult = 1.0, rewardMult = 1.0},
    {id = "dificil", label = "Dificil", color = {0.9, 0.6, 0.2}, hpMult = 1.0, rewardMult = 1.0},
    {id = "muy_dificil", label = "Muy Dificil", color = {0.9, 0.3, 0.3}, hpMult = 1.0, rewardMult = 1.0},
    {id = "extremo", label = "Extremo", color = {1.0, 0.2, 0.0}, hpMult = 1.0, rewardMult = 1.0},
    {id = "pesadilla", label = "Pesadilla", color = {0.6, 0.0, 0.6}, hpMult = 1.0, rewardMult = 1.0},
    {id = "inframundo", label = "Inframundo", color = {0.8, 0.0, 1.0}, hpMult = 1.0, rewardMult = 1.0},
    {id = "infierno", label = "Infierno", color = {1.0, 0.0, 0.3}, hpMult = 1.0, rewardMult = 1.0},
}

local freelanceTasks = {
    {name = "Entrada de datos", reward = 1, time = 1.1, difficulty = "muy_facil"},
    {name = "Clasificacion de archivos", reward = 1, time = 0.9, difficulty = "muy_facil"},
    {name = "Archivo de correspondencia", reward = 1, time = 0.7, difficulty = "muy_facil"},
    {name = "Inventario de equipo", reward = 1, time = 1.1, difficulty = "muy_facil"},
    {name = "Correccion de documentos", reward = 2, time = 1.65, difficulty = "facil"},
    {name = "Revision de facturas", reward = 1, time = 1.3, difficulty = "facil"},
    {name = "Digitacion de formularios", reward = 2, time = 1.45, difficulty = "facil"},
    {name = "Procesamiento de nominas", reward = 2, time = 2.2, difficulty = "normal"},
    {name = "Redaccion de cartas", reward = 3, time = 2.0, difficulty = "normal"},
    {name = "Traduccion simple", reward = 3, time = 1.8, difficulty = "normal"},
    {name = "Base de datos Access", reward = 4, time = 2.5, difficulty = "dificil"},
    {name = "Configuracion de red", reward = 5, time = 2.8, difficulty = "dificil"},
    {name = "Pagina web HTML", reward = 5, time = 3.0, difficulty = "dificil"},
    {name = "App Visual Basic", reward = 7, time = 3.5, difficulty = "muy_dificil"},
    {name = "Sistema de facturacion", reward = 8, time = 4.0, difficulty = "muy_dificil"},
    {name = "Red corporativa", reward = 10, time = 4.5, difficulty = "pesadilla"},
    {name = "Sistema ERP", reward = 12, time = 5.0, difficulty = "pesadilla"},
}

local difficultyUnlockMilestone = {
    normal = {type = "tasks", value = 50},
    dificil = {type = "tasks", value = 100},
    muy_dificil = {type = "tasks", value = 200},
    pesadilla = {type = "tasks", value = 350},
}

local componentDefs = {
    gpu = {
        label = "GPU",
        color = {0.2, 0.8, 0.3},
        baseInterval = 2.0,
        basePower = 3,
        tiers = {
            {interval = 2.0, power = 3},
            {interval = 1.6, power = 5},
            {interval = 1.2, power = 8},
            {interval = 0.8, power = 12},
        },
        passive = "Mayor daño por circulo",
    },
    cpu = {
        label = "CPU",
        color = {0.6, 0.2, 0.9},
        baseInterval = 3.0,
        basePower = 2,
        tiers = {
            {interval = 3.0, power = 2},
            {interval = 2.4, power = 3},
            {interval = 1.8, power = 5},
            {interval = 1.2, power = 7},
        },
        passive = "Genera circulos mas rapido",
    },
    ram = {
        label = "RAM",
        color = {0.9, 0.5, 0.1},
        baseInterval = 4.0,
        basePower = 0,
        tiers = {
            {interval = 4.0, power = 0},
            {interval = 3.2, power = 2},
            {interval = 2.4, power = 4},
            {interval = 1.6, power = 7},
        },
        passive = "Multiplicador de puntos al llegar",
    },
    cooling = {
        label = "Refrigeracion",
        color = {0.2, 0.8, 0.8},
        baseInterval = 5.0,
        basePower = 0,
        tiers = {
            {interval = 5.0, power = 0},
            {interval = 4.0, power = 2},
            {interval = 3.0, power = 4},
            {interval = 2.0, power = 6},
        },
        passive = "Reduce fallos (bugs) en circulos",
    },
}

local componentOrder = {"gpu", "cpu", "ram", "cooling"}

function Trabajo.new(x, y)
    local self = setmetatable({}, Trabajo)
    self.window = WindowManager.new("Trabajo Freelance", x or 250, y or 120, 460, 320)

    self.money = 0
    self.smallFont = love.graphics.newFont(11)
    self.circleFont = love.graphics.newFont(13)
    self.totalEarned = 0
    self.tasksCompleted = 0
    self.currentTask = nil
    self.taskProgress = 0
    self.cooldown = 0
    self.cooldownMax = 0.3
    self.onWorkDone = nil
    self.onOpenParticular = nil
    self.emailRef = nil
    self.explorerRef = nil
    self.achievementsRef = nil
    self.completedProjects = 0

    self.activeJobs = {}
    self.maxJobs = 1
    self.unlockedDifficulties = {facil = true, normal = true}
    self.difficultyProgression = {"facil", "normal", "dificil", "muy_dificil", "extremo", "pesadilla", "inframundo", "infierno"}
    self.newDifficultyUnlocked = nil

    self.particularWindow = WindowManager.new("Trabajo Particular", (x or 250) + 50, (y or 120) + 50, 460, 400)
    self.particularWindow.minimizeOnly = true

    self.activeProject = nil
    self.projectProgress = 0
    self.projectMaxProgress = 100
    self.projectDaysLeft = 14
    self.projectMaxDays = 14
    self.projectReward = 0
    self.projectDesc = ""
    self.resultMessage = ""
    self.resultTimer = 0
    self.malwareLossMessage = ""
    self.malwareLossTimer = 0
    self.projectCooldown = 0
    self.successMessage = ""
    self.successTimer = 0

    self.winbatchActive = false
    self.winbatchTimer = 0
    self.winbatchInterval = 3.0

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

    self.particularWindow.onDraw = function(_, cx, cy, cw, ch)
        self:drawParticularContent(cx, cy, cw, ch)
    end
    self.particularWindow.onMousePressed = function(_, x, y, button)
        if button ~= 1 then return false end
        for _, btn in ipairs(self.buttons) do
            if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
                if btn.action == "dismiss_success" then
                    self.successMessage = ""
                    self.successTimer = 0
                    self.newDifficultyUnlocked = nil
                    self.particularWindow.visible = false
                end
                return true
            end
        end
        return true
    end

    self.moneySounds = {}
    for i = 1, 3 do
        local ok, snd = pcall(love.audio.newSource, "assets/sounds/money" .. i .. ".wav", "static")
        if ok then
            snd:setVolume(0.6)
            table.insert(self.moneySounds, snd)
        end
    end

    self.circleSounds = {}
    local okCs, sndCs = pcall(love.audio.newSource, "assets/sounds/circlesound.wav", "static")
    if okCs then
        sndCs:setVolume(0.5)
        table.insert(self.circleSounds, sndCs)
    end
    local okCs2, sndCs2 = pcall(love.audio.newSource, "assets/sounds/circlesound2.wav", "static")
    if okCs2 then
        sndCs2:setVolume(0.5)
        table.insert(self.circleSounds, sndCs2)
    end

    self.floatingFont = love.graphics.newFont(18)

    return self
end

function Trabajo:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function Trabajo:getUpgrades()
    local upgMap = {}
    if self.explorerRef then
        for stat, level in pairs(self.explorerRef.upgradeLevels) do
            if level > 0 then
                upgMap[stat] = level
            end
        end
    end
    return upgMap
end

function Trabajo:getComponentTier(componentId)
    local statMap = {
        gpu = "display",
        cpu = "cpu",
        ram = "ram",
        cooling = "cooling",
    }
    local stat = statMap[componentId]
    if not stat then return 0 end
    if self.explorerRef then
        return self.explorerRef.upgradeLevels[stat] or 0
    end
    return 0
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

    local isFirstProject = (self.completedProjects or 0) == 0
    local diffId = projectData.difficulty or "facil"
    local diffInfo = nil
    for _, d in ipairs(projectDifficulties) do
        if d.id == diffId then diffInfo = d break end
    end

    if isFirstProject then
        self.projectMaxProgress = projectData.baseHp or 150
    else
        local baseHp = projectData.baseHp or 150
        local hpMult = diffInfo and diffInfo.hpMult or 1.0
        self.projectMaxProgress = math.floor(baseHp * hpMult)
    end

    self.projectDifficulty = diffInfo
    local baseDays = projectData.days or 14
    local completed = self.completedProjects or 0
    local scaleFactor = math.max(0.3, 1.0 - completed * 0.1)
    local scaledDays = math.max(4, math.floor(baseDays * scaleFactor))
    self.projectDaysLeft = scaledDays
    self.projectMaxDays = scaledDays

    if isFirstProject then
        self.projectReward = projectData.reward
    else
        local rewardMult = diffInfo and diffInfo.rewardMult or 1.0
        self.projectReward = math.floor(projectData.reward * rewardMult)
    end

    self.resultMessage = ""
    self.resultTimer = 0
    self.successMessage = ""
    self.successTimer = 0
    self.malwareLossMessage = ""
    self.malwareLossTimer = 0
    self.circles = {}
    self.floatingNumbers = {}
    self.barShake = 0

    self:recalcComponents()

    self.particularWindow.visible = true
    self.particularWindow.minimized = false
    if self.onOpenParticular then self.onOpenParticular() end
end

function Trabajo:update(dt)
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - dt
    end

    if self.winbatchActive then
        self.winbatchTimer = self.winbatchTimer + dt
        if self.winbatchTimer >= self.winbatchInterval then
            self.winbatchTimer = self.winbatchTimer - self.winbatchInterval
            for slot = 1, self.maxJobs do
                if not self.activeJobs[slot] then
                    local available = self:getAvailableTasks()
                    if #available > 0 then
                        local task = available[math.random(#available)]
                        self.activeJobs[slot] = {task = task, progress = 0, auto = true}
                    end
                    break
                end
            end
        end
    end

    local oldMaxJobs = self.maxJobs
    self.maxJobs = self:getJobCapacity()
    
    if self.maxJobs ~= oldMaxJobs then
        local baseH = 200
        local slotH = 60
        self.window.h = baseH + self.maxJobs * slotH
    end
    
    self:checkDifficultyUnlocks()

    for slot = 1, self.maxJobs do
        local job = self.activeJobs[slot]
        if job then
            job.progress = job.progress + dt
            local adjustedTime = job.task.time * self:getTaskTimeMultiplier()
            if job.progress >= adjustedTime then
                local baseReward = self:getBaseRewardPerTask()
                local comboMult = 1.0
                if self.achievementsRef then
                    comboMult = self.achievementsRef.comboMultiplier or 1.0
                end
                local hwMult = self:getTaskRewardMultiplier()
                local reward = math.floor(baseReward * comboMult * hwMult)
                self.money = self.money + reward
                self.totalEarned = self.totalEarned + reward
                self.tasksCompleted = self.tasksCompleted + 1
                if not job.auto and self.moneySounds and #self.moneySounds > 0 then
                    local snd = self.moneySounds[math.random(#self.moneySounds)]
                    snd:stop()
                    snd:play()
                end
                if self.achievementsRef then
                    self.achievementsRef:onTaskComplete(reward)
                end
                if self.onWorkDone then self.onWorkDone() end
                self.activeJobs[slot] = nil
            end
        end
    end

    if self.resultTimer > 0 then
        self.resultTimer = self.resultTimer - dt
        if self.resultTimer <= 0 then
            self.resultMessage = ""
        end
    end

    if self.successTimer > 0 then
        self.successTimer = self.successTimer - dt
        if self.successTimer <= 0 then
            self.successMessage = ""
            self.particularWindow.visible = false
        end
    end

    if self.malwareLossTimer and self.malwareLossTimer > 0 then
        self.malwareLossTimer = self.malwareLossTimer - dt
        if self.malwareLossTimer <= 0 then
            self.malwareLossMessage = ""
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
            comp.timer = comp.timer + dt * self:getCircleGenMultiplier()
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
                if circ.isBug then
                    self.projectProgress = math.max(0, self.projectProgress - circ.power)
                    table.insert(self.floatingNumbers, {
                        text = "-" .. circ.power,
                        x = circ.targetX,
                        y = circ.targetY,
                        timer = 1.5,
                        maxTimer = 1.5,
                        vy = -40,
                        isBug = true,
                    })
                else
                    self.projectProgress = self.projectProgress + circ.power
                    table.insert(self.floatingNumbers, {
                        text = "+" .. circ.power,
                        x = circ.targetX,
                        y = circ.targetY,
                        timer = 1.0,
                        maxTimer = 1.0,
                        vy = -40,
                    })
                end
                self.barShake = 0.15
                self.barShakeIntensity = circ.isBug and 4 or 2
                table.remove(self.circles, i)

                if self.projectProgress >= self.projectMaxProgress then
                    self:winProject()
                    return
                end
            end
        end

        self.projectDaysLeft = self.projectDaysLeft - dt * 0.3
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
    local baseSpeed = 200
    local speed = baseSpeed

    local bugChance = math.max(0, 0.08 - self:getBugChanceReduction())
    local isBug = math.random() < bugChance
    local circColor = isBug and {0.9, 0.15, 0.15} or comp.color
    local basePower = isBug and math.floor(comp.power * 0.6) or comp.power
    local circPower = math.floor(basePower * self:getCirclePowerMultiplier() * self:getRamMultiplier())

    table.insert(self.circles, {
        x = startX,
        y = startY,
        vx = (dx / dist) * speed,
        vy = (dy / dist) * speed,
        targetX = targetX,
        targetY = targetY,
        color = circColor,
        power = circPower,
        life = dist / speed + 0.1,
        radius = 12,
        componentLabel = comp.label,
        isBug = isBug,
    })

    comp.vibration = 0.2

    if #self.circleSounds > 0 then
        local snd = self.circleSounds[math.random(#self.circleSounds)]
        snd:stop()
        snd:play()
    end
end

function Trabajo:winProject()
    local reward = self.projectReward
    self.money = self.money + reward
    self.totalEarned = self.totalEarned + reward
    self.completedProjects = (self.completedProjects or 0) + 1

    local completedDiff = self.projectDifficulty and self.projectDifficulty.id
    if completedDiff then
        for i, diffId in ipairs(self.difficultyProgression) do
            if diffId == completedDiff and i < #self.difficultyProgression then
                local nextDiff = self.difficultyProgression[i + 1]
                if not self.unlockedDifficulties[nextDiff] then
                    self.unlockedDifficulties[nextDiff] = true
                    self.newDifficultyUnlocked = nextDiff
                end
                break
            end
        end
    end

    self.successMessage = "Proyecto exitoso! +$" .. reward
    self.successTimer = 5.0

    if self.achievementsRef then
        self.achievementsRef:onProjectComplete(reward, false)
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
    self.circles = {}
    self.floatingNumbers = {}
    self.components = {}
    self.barShake = 0

    if self.successTimer <= 0 then
        self.particularWindow.visible = false
    end
end

function Trabajo:getAvailableTasks()
    local available = {}
    for _, task in ipairs(freelanceTasks) do
        if self.unlockedDifficulties[task.difficulty] then
            table.insert(available, task)
        end
    end
    return available
end

function Trabajo:checkDifficultyUnlocks()
    for diff, milestone in pairs(difficultyUnlockMilestone) do
        if not self.unlockedDifficulties[diff] then
            if milestone.type == "tasks" and self.tasksCompleted >= milestone.value then
                self.unlockedDifficulties[diff] = true
            end
        end
    end
end

function Trabajo:getEarningsPerClick()
    local baseReward = self:getBaseRewardPerTask()
    return math.floor(baseReward * self:getTaskRewardMultiplier())
end

function Trabajo:getTaskTimeMultiplier()
    local mult = 1.75
    local upgMap = self:getUpgrades()
    if upgMap.cpu then mult = mult * math.pow(0.70, upgMap.cpu) end
    if upgMap.cooling then
        local coolingBoost = 0.10 + (upgMap.cooling - 1) * 0.20
        mult = mult * (1.0 - coolingBoost)
    end
    if mult < 0.5 then mult = 0.5 end
    return mult
end

function Trabajo:getBaseRewardPerTask()
    local gpuRewards = {1, 2, 4, 8, 16}
    local upgMap = self:getUpgrades()
    local gpuLevel = upgMap.display or 0
    return gpuRewards[gpuLevel + 1] or 1
end

function Trabajo:getTaskRewardMultiplier()
    local mult = 1.0
    local upgMap = self:getUpgrades()
    if upgMap.cooling then
        local coolingBoost = 0.10 + (upgMap.cooling - 1) * 0.20
        mult = mult * (1.0 + coolingBoost)
    end
    return mult
end

function Trabajo:getJobCapacity()
    local capacity = 1
    local upgMap = self:getUpgrades()
    if upgMap.ram then capacity = capacity + upgMap.ram end
    return capacity
end

function Trabajo:getCirclePowerMultiplier()
    local mult = 1.0
    local upgMap = self:getUpgrades()
    if upgMap.display then mult = mult + 0.30 * upgMap.display end
    return mult
end

function Trabajo:getCircleGenMultiplier()
    local mult = 1.0
    local upgMap = self:getUpgrades()
    if upgMap.cpu then mult = mult * math.pow(0.85, upgMap.cpu) end
    return mult
end

function Trabajo:getBugChanceReduction()
    local reduction = 0
    local upgMap = self:getUpgrades()
    if upgMap.cooling then reduction = reduction + 0.02 * upgMap.cooling end
    return reduction
end

function Trabajo:getRamMultiplier()
    local mult = 1.0
    local upgMap = self:getUpgrades()
    if upgMap.ram then mult = mult + 0.25 * upgMap.ram end
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
    love.graphics.setFont(self.smallFont)

    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx + 6, cy + 4, cw - 12, ch - 8)
    self:drawBevel(cx + 6, cy + 4, cw - 12, ch - 8)

    self:drawFreelanceTab(cx + 12, cy + 10, cw - 24, ch - 20)

    love.graphics.setFont(prevFont)
end

function Trabajo:drawFreelanceTab(x, y, w, h)
    self.buttons = {}
    
    love.graphics.setColor(W95.text)
    love.graphics.printf("Trabajo Freelance", x + 8, y + 8, w - 16, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 8, y + 26, x + w - 8, y + 26)

    love.graphics.setColor(W95.text)
    love.graphics.print("Tareas completadas: " .. self.tasksCompleted, x + 8, y + 30)
    love.graphics.setColor(W95.green)
    love.graphics.print("Dinero: $" .. self.money, x + 8, y + 44)

    if self.winbatchActive then
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.print("Winbatch: ACTIVO", x + w - 120, y + 30)
    end

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 8, y + 60, x + w - 8, y + 60)

    local emptySlots = 0
    for slot = 1, self.maxJobs do
        if not self.activeJobs[slot] then emptySlots = emptySlots + 1 end
    end
    local hasEmptySlots = emptySlots > 0

    local earnings = self:getEarningsPerClick()
    love.graphics.setColor(W95.text)
    love.graphics.printf("Ganancia: $" .. earnings .. "/tarea | Slots: " .. self.maxJobs, x + 8, y + 64, w - 16, "center")

    local btnW = 140
    local btnH = 28
    local btnX = x + (w - btnW) / 2
    local btnY = y + 82
    local mx, my = love.mouse.getPosition()
    local btnHov = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH

    if hasEmptySlots then
        love.graphics.setColor(btnHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
        self:drawBevel(btnX, btnY, btnW, btnH)
        love.graphics.setColor(W95.green)
        love.graphics.printf("Trabajar (" .. emptySlots .. ")", btnX, btnY + 6, btnW, "center")
        table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "work_all"})
    else
        love.graphics.setColor(W95.textDim)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
        self:drawBevel(btnX, btnY, btnW, btnH)
        love.graphics.setColor(W95.textDim)
        love.graphics.printf("Todos ocupados", btnX, btnY + 6, btnW, "center")
    end

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 8, y + 116, x + w - 8, y + 116)

    local slotH = 36
    local slotStartY = y + 120
    
    for slot = 1, self.maxJobs do
        local slotY = slotStartY + (slot - 1) * slotH
        local job = self.activeJobs[slot]
        
        love.graphics.setColor(W95.textDim)
        love.graphics.print("Slot " .. slot .. ":", x + 8, slotY + 2)
        
        if job then
            love.graphics.setColor(W95.text)
            love.graphics.print(job.task.name, x + 55, slotY + 2)
            
            local barX = x + 55
            local barY = slotY + 16
            local barW = w - 75
            local barH = 14

            love.graphics.setColor(W95.fieldBg)
            love.graphics.rectangle("fill", barX, barY, barW, barH)
            self:drawInset(barX, barY, barW, barH)

            local progress = math.min(job.progress / (job.task.time * self:getTaskTimeMultiplier()), 1)
            love.graphics.setColor(W95.highlight)
            love.graphics.rectangle("fill", barX + 2, barY + 2, (barW - 4) * progress, barH - 4)

            love.graphics.setColor(W95.white)
            love.graphics.printf(math.floor(progress * 100) .. "%", barX, barY, barW, "center")
        else
            love.graphics.setColor(W95.textDim)
            love.graphics.print("[Vacio]", x + 55, slotY + 2)
        end
    end

    local bottomY = slotStartY + self.maxJobs * slotH + 4
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 8, bottomY, x + w - 8, bottomY)

    local compInfoY = bottomY + 4
    local compLabels = {
        {id = "cpu", label = "CPU", color = {0.6, 0.2, 0.9}},
        {id = "gpu", label = "GPU", color = {0.2, 0.8, 0.3}},
        {id = "ram", label = "RAM", color = {0.9, 0.5, 0.1}},
        {id = "cooling", label = "FAN", color = {0.2, 0.8, 0.8}},
    }
    local colW = (w - 16) / 4
    for i, comp in ipairs(compLabels) do
        local tier = self:getComponentTier(comp.id)
        local cx = x + 8 + (i - 1) * colW
        love.graphics.setColor(comp.color)
        love.graphics.printf(comp.label .. " Lv." .. tier, cx, compInfoY, colW, "center")
    end
end

function Trabajo:drawParticularContent(cx, cy, cw, ch)
    self.buttons = {}
    local prevFont = love.graphics.getFont()
    love.graphics.setFont(self.smallFont)

    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx + 6, cy + 4, cw - 12, ch - 8)
    self:drawBevel(cx + 6, cy + 4, cw - 12, ch - 8)

    self:drawParticularTab(cx + 12, cy + 10, cw - 24, ch - 20)

    love.graphics.setFont(prevFont)
end

function Trabajo:drawParticularTab(x, y, w, h)
    if self.successMessage ~= "" then
        love.graphics.setColor(W95.green)
        love.graphics.printf(self.successMessage, x + 8, y + h / 2 - 30, w - 16, "center")
        love.graphics.setColor(W95.text)
        love.graphics.printf("Felicidades por completar el proyecto!", x + 8, y + h / 2 - 10, w - 16, "center")

        if self.newDifficultyUnlocked then
            local diffInfo = nil
            for _, d in ipairs(projectDifficulties) do
                if d.id == self.newDifficultyUnlocked then diffInfo = d break end
            end
            if diffInfo then
                love.graphics.setColor(diffInfo.color)
                love.graphics.printf("Nueva dificultad desbloqueada:", x + 8, y + h / 2 + 40, w - 16, "center")
                love.graphics.setColor(W95.highlight)
                love.graphics.printf("[" .. diffInfo.label .. "]", x + 8, y + h / 2 + 55, w - 16, "center")
            end
        end

        local btnW = 80
        local btnH = 24
        local btnX = x + (w - btnW) / 2
        local btnY = y + h / 2 + 20
        local mx, my = love.mouse.getPosition()
        local btnHov = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH
        love.graphics.setColor(btnHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
        self:drawBevel(btnX, btnY, btnW, btnH)
        love.graphics.setColor(W95.text)
        love.graphics.printf("Aceptar", btnX, btnY + 5, btnW, "center")
        table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "dismiss_success"})
        return
    end

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

    if self.projectDifficulty then
        love.graphics.setColor(self.projectDifficulty.color)
        love.graphics.printf("[" .. self.projectDifficulty.label .. "]", x + 8, y + 32, w - 16, "center")
    end

    love.graphics.setColor(W95.textDim)
    local descLines = {}
    for line in self.projectDesc:gmatch("[^\n]*") do
        table.insert(descLines, line)
    end
    for i, line in ipairs(descLines) do
        love.graphics.printf(line, x + 8, y + 46 + (i - 1) * 12, w - 16, "center")
    end

    local barX = x + 16
    local barY = y + 74
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
        if num.isBug then
            love.graphics.setColor(1, 0.2, 0.2, alpha)
        else
            love.graphics.setColor(0.2, 1, 0.2, alpha)
        end
        local prevFont = love.graphics.getFont()
        love.graphics.setFont(self.floatingFont)
        love.graphics.printf(num.text, num.x - 40, num.y, 80, "center")
        love.graphics.setFont(prevFont)
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
        {1.0, 1.0, 1.0},
        {0.2, 0.8, 0.2},
        {0.2, 0.4, 0.9},
        {0.6, 0.2, 0.9},
        {0.9, 0.6, 0.1},
    }

    local tierNames = {"Basico", "Avanzado", "Elite", "Legendario", "Maximo"}

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
        love.graphics.printf("Potencia: " .. comp.power, bx + vibOff, by + 41, boxW, "center")

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

        love.graphics.setColor(circ.color)
        love.graphics.circle("fill", cx, cy, r)

        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("line", cx, cy, r)

        local prevFont = love.graphics.getFont()
        love.graphics.setFont(self.circleFont)
        love.graphics.setColor(1, 1, 1)
        love.graphics.printf(circ.power, cx - 16, cy - 8, 32, "center")
        love.graphics.setFont(prevFont)
    end

    if self.resultMessage ~= "" then
        love.graphics.setColor(W95.yellow)
        love.graphics.printf(self.resultMessage, x + 8, y + h - 14, w - 16, "center")
    end

    if self.malwareLossMessage and self.malwareLossMessage ~= "" then
        love.graphics.setColor({0.8, 0, 0})
        love.graphics.printf(self.malwareLossMessage, x + 8, y + h - 30, w - 16, "center")
    end
end

function Trabajo:handleClick(x, y, button)
    if button ~= 1 then return false end

    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "work_all" then
                local available = self:getAvailableTasks()
                if #available > 0 then
                    for slot = 1, self.maxJobs do
                        if not self.activeJobs[slot] then
                            local task = available[math.random(#available)]
                            self.activeJobs[slot] = {task = task, progress = 0}
                        end
                    end
                end
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
