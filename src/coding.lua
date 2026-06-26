local Coding = {}
Coding.__index = Coding

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
}

local projectTypes = {
    {id = "calculator", name = "Calculadora", difficulty = "normal", baseCost = 800, baseHp = 300, reward = 2000, monthly = 80},
    {id = "notepad_pro", name = "Notepad Pro", difficulty = "normal", baseCost = 600, baseHp = 250, reward = 1500, monthly = 60},
    {id = "file_manager", name = "File Manager", difficulty = "normal", baseCost = 900, baseHp = 350, reward = 2200, monthly = 90},
    {id = "browser", name = "Web Browser", difficulty = "dificil", baseCost = 2000, baseHp = 500, reward = 5000, monthly = 200},
    {id = "email_client", name = "Cliente de Email", difficulty = "dificil", baseCost = 1500, baseHp = 400, reward = 4000, monthly = 150},
    {id = "media_player", name = "Reproductor", difficulty = "dificil", baseCost = 2500, baseHp = 600, reward = 6000, monthly = 250},
    {id = "database", name = "Base de Datos", difficulty = "pesadilla", baseCost = 5000, baseHp = 900, reward = 12000, monthly = 500},
    {id = "office_suite", name = "Suite de Oficina", difficulty = "pesadilla", baseCost = 8000, baseHp = 1200, reward = 18000, monthly = 800},
    {id = "game_engine", name = "Motor de Juegos", difficulty = "pesadilla", baseCost = 12000, baseHp = 1500, reward = 25000, monthly = 1200},
}

function Coding.new(x, y)
    local self = setmetatable({}, Coding)
    self.window = WindowManager.new("Code Editor", x or 200, y or 100, 600, 450)

    self.trabajoRef = nil
    self.explorerRef = nil

    self.codingLevel = 1
    self.codingXP = 0
    self.xpPerLevel = {100, 250, 500, 1000, 2000}

    self.state = "browse"
    self.availableProjects = {}
    self.selectedProject = nil
    self.projectName = ""

    self.activeProject = nil
    self.projectProgress = 0
    self.projectMaxProgress = 100
    self.moneySpent = 0
    self.costPerSecond = 0
    self.projectDaysLeft = 0
    self.projectMaxDays = 0

    self.milestoneTargets = {0.25, 0.50, 0.75}
    self.nextMilestone = 1
    self.milestoneActive = false
    self.codeLines = {}
    self.codeLineIndex = 1
    self.codeCharIndex = 0
    self.codeProgress = 0
    self.codeScrollY = 0
    self.codeTargetScrollY = 0
    self.codeFont = love.graphics.newFont(12)
    self.codeComplete = false
    self.cursorBlink = 0

    local codeSnippets = {
        {'def calculate_total(items):', '    total = 0', '    for item in items:', '        total += item.price', '    return total', '', 'def save_report(data):', '    with open("report.txt", "w") as f:', '        f.write(str(data))'},
        {'class Database:', '    def __init__(self, name):', '        self.name = name', '        self.tables = {}', '', '    def create_table(self, name, cols):', '        table = {"name": name, "columns": cols}', '        self.tables[name] = table'},
        {'function processData(input) {', '    const result = [];', '    for (let i = 0; i < input.length; i++) {', '        if (input[i].valid) {', '            result.push(transform(input[i]));', '        }', '    }', '    return result;', '}'},
        {'#include <stdlib.h>', '#include <string.h>', '', 'typedef struct {', '    char *name;', '    int id;', '    float value;', '} Record;', '', 'Record* create_record(const char *n) {', '    Record *r = malloc(sizeof(Record));', '    r->name = strdup(n);', '    return r;', '}'},
    }
    self.codeSnippets = codeSnippets

    self.circles = {}
    self.floatingNumbers = {}
    self.barShake = 0
    self.components = {}

    self.publishedApps = {}
    self.selectedApp = nil

    self.refreshAttempts = 3
    self.maxRefreshAttempts = 3
    self.refreshCooldown = 0
    self.refreshCooldownMax = 30

    self.buttons = {}
    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, x, y, button)
        return self:handleClick(x, y, button)
    end

    return self
end

function Coding:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function Coding:getCodingLevel()
    return self.codingLevel
end

function Coding:getNextXP()
    return self.xpPerLevel[self.codingLevel] or 99999
end

function Coding:checkLevelUp()
    while self.codingLevel < #self.xpPerLevel and self.codingXP >= self.xpPerLevel[self.codingLevel] do
        self.codingXP = self.codingXP - self.xpPerLevel[self.codingLevel]
        self.codingLevel = self.codingLevel + 1
    end
end

function Coding:refreshProjects()
    self.availableProjects = {}
    local count = math.min(4, 2 + math.floor(self.codingLevel / 2))
    local available = {}
    for _, p in ipairs(projectTypes) do
        table.insert(available, p)
    end
    for i = 1, count do
        if #available > 0 then
            local idx = math.random(#available)
            table.insert(self.availableProjects, available[idx])
            table.remove(available, idx)
        end
    end
end

function Coding:startProject(index)
    local projectType = self.availableProjects[index]
    if not projectType then return end
    if self.trabajoRef.money < projectType.baseCost then return end

    self.trabajoRef.money = self.trabajoRef.money - projectType.baseCost
    self.activeProject = projectType
    self.projectName = projectType.name
    self.projectProgress = 0
    self.projectMaxProgress = projectType.baseHp
    self.moneySpent = projectType.baseCost
    self.costPerSecond = projectType.baseCost / 60
    self.projectDaysLeft = 14
    self.projectMaxDays = 14

    self.nextMilestone = 1
    self.milestoneActive = false
    self.codeProgress = 0

    self.circles = {}
    self.floatingNumbers = {}
    self.barShake = 0
    self:recalcComponents()

    self.state = "coding"
end

function Coding:recalcComponents()
    self.components = {}
    if not self.explorerRef then return end

    local gpuLevel = self.explorerRef.upgradeLevels.display or 0
    local cpuLevel = self.explorerRef.upgradeLevels.cpu or 0
    local ramLevel = self.explorerRef.upgradeLevels.ram or 0
    local coolLevel = self.explorerRef.upgradeLevels.cooling or 0

    local gpuPower = 3 + gpuLevel * 3
    local gpuInterval = math.max(0.8, 2.0 - gpuLevel * 0.3)

    local cpuPower = 2 + cpuLevel * 2
    local cpuInterval = math.max(1.0, 3.0 - cpuLevel * 0.5)

    table.insert(self.components, {
        id = "gpu", label = "GPU", color = {0.2, 0.8, 0.3},
        power = gpuPower, interval = gpuInterval, timer = 0, screenX = 0, screenY = 0, barX = 0, barY = 0, vibration = 0,
    })
    table.insert(self.components, {
        id = "cpu", label = "CPU", color = {0.6, 0.2, 0.9},
        power = cpuPower, interval = cpuInterval, timer = 0, screenX = 0, screenY = 0, barX = 0, barY = 0, vibration = 0,
    })

    if ramLevel > 0 then
        local ramPower = 1 + ramLevel
        local ramInterval = math.max(1.5, 4.0 - ramLevel * 0.6)
        table.insert(self.components, {
            id = "ram", label = "RAM", color = {0.9, 0.5, 0.1},
            power = ramPower, interval = ramInterval, timer = 0, screenX = 0, screenY = 0, barX = 0, barY = 0, vibration = 0,
        })
    end
    if coolLevel > 0 then
        local coolPower = 1 + coolLevel
        local coolInterval = math.max(2.0, 5.0 - coolLevel * 0.7)
        table.insert(self.components, {
            id = "cooling", label = "Cool", color = {0.2, 0.8, 0.8},
            power = coolPower, interval = coolInterval, timer = 0, screenX = 0, screenY = 0, barX = 0, barY = 0, vibration = 0,
        })
    end
end

function Coding:sellApp()
    if not self.activeProject then return end

    local projectType = self.activeProject
    table.insert(self.publishedApps, {
        name = self.projectName,
        type = projectType,
        revenuePerMonth = projectType.monthly,
        monthsLeft = 12,
        totalRevenue = 0,
        selling = true,
        updated = false,
        updateCooldown = 0,
        successScore = math.random(5, 9) / 10,
    })

    self.codingXP = self.codingXP + math.floor(projectType.reward / 5)
    self:checkLevelUp()
    self:resetProject()
end

function Coding:resetProject()
    self.activeProject = nil
    self.projectProgress = 0
    self.projectMaxProgress = 100
    self.moneySpent = 0
    self.moneyPerSecond = 0
    self.projectDaysLeft = 0
    self.projectMaxDays = 0
    self.circles = {}
    self.floatingNumbers = {}
    self.state = "browse"
end

function Coding:cancelProject()
    if not self.activeProject then return end
    self.trabajoRef.money = self.trabajoRef.money + math.floor(self.moneySpent * 0.3)
    self:resetProject()
end

function Coding:update(dt)
    self:refreshCooldownUpdate(dt)
    self:activeProjectUpdate(dt)
    self:publishedAppsUpdate(dt)
    self:updateMinigame(dt)

    for i = #self.floatingNumbers, 1, -1 do
        local num = self.floatingNumbers[i]
        num.y = num.y + num.vy * dt
        num.timer = num.timer - dt
        if num.timer <= 0 then
            table.remove(self.floatingNumbers, i)
        end
    end
end

function Coding:refreshCooldownUpdate(dt)
    if self.refreshCooldown > 0 then
        self.refreshCooldown = self.refreshCooldown - dt
        if self.refreshCooldown <= 0 then
            self.refreshAttempts = self.maxRefreshAttempts
        end
    end
end

function Coding:activeProjectUpdate(dt)
    if self.state ~= "coding" then return end
    if not self.activeProject then return end
    if self.milestoneActive then return end

    local costPerFrame = self.costPerSecond * dt
    if self.trabajoRef.money >= costPerFrame then
        self.trabajoRef.money = self.trabajoRef.money - costPerFrame
        self.moneySpent = self.moneySpent + costPerFrame
    end

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
                text = "+" .. circ.power, x = circ.targetX, y = circ.targetY,
                timer = 1.0, maxTimer = 1.0, vy = -40, isBug = circ.isBug,
            })
            self.barShake = 0.15
            table.remove(self.circles, i)

            if self.projectProgress >= self.projectMaxProgress then
                self.state = "sell"
                return
            end
        end
    end

    if self.nextMilestone <= #self.milestoneTargets then
        local target = self.milestoneTargets[self.nextMilestone]
        if self.projectProgress / self.projectMaxProgress >= target then
            self:triggerMilestone()
        end
    end

    self.projectDaysLeft = self.projectDaysLeft - dt * 0.05
    if self.projectDaysLeft <= 0 then
        self:cancelProject()
    end

    if self.barShake > 0 then
        self.barShake = self.barShake - dt
    end
end

function Coding:triggerMilestone()
    self.milestoneActive = true
    self.codeLines = self.codeSnippets[math.random(#self.codeSnippets)]
    self.codeLineIndex = 1
    self.codeCharIndex = 0
    self.codeProgress = 0
    self.codeScrollY = 0
    self.codeTargetScrollY = 0
    self.codeComplete = false
    self.nextMilestone = self.nextMilestone + 1
end

function Coding:updateMinigame(dt)
    self.cursorBlink = self.cursorBlink + dt
    self.codeScrollY = self.codeScrollY + (self.codeTargetScrollY - self.codeScrollY) * dt * 10
end

function Coding:publishedAppsUpdate(dt)
    for i = #self.publishedApps, 1, -1 do
        local app = self.publishedApps[i]
        if app.selling then
            app.monthlyTimer = (app.monthlyTimer or 0) + dt
            if app.monthlyTimer >= 30 then
                app.monthlyTimer = app.monthlyTimer - 30
                local revenue = math.floor(app.revenuePerMonth * app.successScore * app.monthsLeft / 12)
                app.totalRevenue = app.totalRevenue + revenue
                if self.trabajoRef then
                    self.trabajoRef.money = self.trabajoRef.money + revenue
                end
                app.monthsLeft = app.monthsLeft - 1
                app.updateCooldown = app.updateCooldown + 1
                if app.monthsLeft <= 0 then
                    app.selling = false
                end
            end
        end
    end
end

function Coding:generateCircle(comp)
    local compBox = comp

    local bugChance = 0.03
    local isBug = math.random() < bugChance
    local power = isBug and 0 or comp.power
    local circColor = isBug and {0.9, 0.15, 0.15} or comp.color

    table.insert(self.circles, {
        x = compBox.screenX, y = compBox.screenY,
        vx = (compBox.barX - compBox.screenX) * 0.5,
        vy = (compBox.barY - compBox.screenY) * 0.5,
        targetX = compBox.barX, targetY = compBox.barY,
        color = circColor, power = power,
        life = 1.5, radius = 10, isBug = isBug,
    })
    compBox.vibration = 0.2
end

function Coding:drawContent(cx, cy, cw, ch)
    self.buttons = {}
    local prevFont = love.graphics.getFont()

    if self.state == "browse" then
        self:drawBrowse(cx, cy, cw, ch)
    elseif self.state == "coding" then
        if self.milestoneActive then
            self:drawMinigame(cx, cy, cw, ch)
        else
            self:drawCoding(cx, cy, cw, ch)
        end
    elseif self.state == "sell" then
        self:drawSell(cx, cy, cw, ch)
    elseif self.state == "manage" then
        self:drawManage(cx, cy, cw, ch)
    end

    love.graphics.setFont(prevFont)
end

function Coding:drawBrowse(x, y, w, h)
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", x + 6, y + 4, w - 12, h - 8)
    self:drawBevel(x + 6, y + 4, w - 12, h - 8)

    love.graphics.setColor(W95.text)
    love.graphics.printf("Proyectos de Coding", x + 8, y + 8, w - 16, "center")
    love.graphics.setColor(W95.yellow)
    love.graphics.printf("Nivel: " .. self.codingLevel .. "  XP: " .. self.codingXP .. "/" .. self:getNextXP(), x + 8, y + 22, w - 16, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 8, y + 38, x + w - 8, y + 38)

    if #self.availableProjects == 0 then
        self:refreshProjects()
    end

    local itemH = 65
    local startY = y + 44
    for i, project in ipairs(self.availableProjects) do
        local iy = startY + (i - 1) * (itemH + 6)
        if iy + itemH < y + h then
            local canAfford = self.trabajoRef and self.trabajoRef.money >= project.baseCost
            love.graphics.setColor(canAfford and W95.bg or {0.9, 0.9, 0.9})
            love.graphics.rectangle("fill", x + 12, iy, w - 24, itemH)
            self:drawBevel(x + 12, iy, w - 24, itemH)

            love.graphics.setColor(W95.text)
            love.graphics.printf(project.name, x + 20, iy + 4, w - 40, "center")

            local diffColor = W95.green
            if project.difficulty == "dificil" then diffColor = W95.yellow end
            if project.difficulty == "pesadilla" then diffColor = W95.red end
            love.graphics.setColor(diffColor)
            love.graphics.printf("[" .. project.difficulty:upper() .. "]", x + 20, iy + 20, w - 40, "center")

            love.graphics.setColor(W95.textDim)
            love.graphics.printf("Inversion: $" .. project.baseCost .. "  |  Ingreso: $" .. project.monthly .. "/mes", x + 20, iy + 36, w - 40, "center")

            local btnW = 90
            local btnH = 18
            local btnX = x + (w - btnW) / 2
            local btnY = iy + itemH - 22
            local btnHov = self.lastMX >= btnX and self.lastMX <= btnX + btnW and self.lastMY >= btnY and self.lastMY <= btnY + btnH

            if canAfford then
                love.graphics.setColor(btnHov and {0.85, 0.85, 0.85} or W95.bg)
                love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
                self:drawBevel(btnX, btnY, btnW, btnH)
                love.graphics.setColor(W95.green)
                love.graphics.printf("Iniciar", btnX, btnY + 2, btnW, "center")
                table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "start_project", index = i})
            else
                love.graphics.setColor(W95.textDim)
                love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
                self:drawBevel(btnX, btnY, btnW, btnH)
                love.graphics.setColor(W95.red)
                love.graphics.printf("Sin fondos", btnX, btnY + 2, btnW, "center")
            end
        end
    end

    if #self.publishedApps > 0 then
        local manageBtnX = x + 12
        local manageBtnY = y + h - 32
        local manageBtnW = 120
        local manageBtnH = 22
        local mHov = self.lastMX >= manageBtnX and self.lastMX <= manageBtnX + manageBtnW and self.lastMY >= manageBtnY and self.lastMY <= manageBtnY + manageBtnH

        love.graphics.setColor(mHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", manageBtnX, manageBtnY, manageBtnW, manageBtnH)
        self:drawBevel(manageBtnX, manageBtnY, manageBtnW, manageBtnH)
        love.graphics.setColor(W95.yellow)
        love.graphics.printf("Mis Apps (" .. #self.publishedApps .. ")", manageBtnX, manageBtnY + 3, manageBtnW, "center")
        table.insert(self.buttons, {x = manageBtnX, y = manageBtnY, w = manageBtnW, h = manageBtnH, action = "open_manage"})
    end

    local refreshBtnX = x + w - 110 - 12
    local refreshBtnY = y + h - 32
    local refreshBtnW = 110
    local refreshBtnH = 22
    local rHov = self.lastMX >= refreshBtnX and self.lastMX <= refreshBtnX + refreshBtnW and self.lastMY >= refreshBtnY and self.lastMY <= refreshBtnY + refreshBtnH

    if self.refreshAttempts > 0 then
        love.graphics.setColor(rHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", refreshBtnX, refreshBtnY, refreshBtnW, refreshBtnH)
        self:drawBevel(refreshBtnX, refreshBtnY, refreshBtnW, refreshBtnH)
        love.graphics.setColor(W95.text)
        love.graphics.printf("Refresh (" .. self.refreshAttempts .. ")", refreshBtnX, refreshBtnY + 3, refreshBtnW, "center")
        table.insert(self.buttons, {x = refreshBtnX, y = refreshBtnY, w = refreshBtnW, h = refreshBtnH, action = "refresh"})
    else
        love.graphics.setColor(W95.textDim)
        love.graphics.rectangle("fill", refreshBtnX, refreshBtnY, refreshBtnW, refreshBtnH)
        self:drawBevel(refreshBtnX, refreshBtnY, refreshBtnW, refreshBtnH)
        love.graphics.setColor(W95.red)
        love.graphics.printf(math.ceil(self.refreshCooldown) .. "s", refreshBtnX, refreshBtnY + 3, refreshBtnW, "center")
    end
end

function Coding:drawCoding(x, y, w, h)
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", x + 6, y + 4, w - 12, h - 8)
    self:drawBevel(x + 6, y + 4, w - 12, h - 8)

    love.graphics.setColor(W95.text)
    love.graphics.printf("Codificando: " .. self.projectName, x + 8, y + 8, w - 16, "center")

    local hpRatio = math.min(self.projectProgress / self.projectMaxProgress, 1)
    local barX = x + 20
    local barY = y + 28
    local barW = w - 40
    local barH = 22

    local shakeOff = 0
    if self.barShake > 0 then shakeOff = (math.random() - 0.5) * 4 end

    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", barX + shakeOff, barY, barW, barH)
    self:drawInset(barX + shakeOff, barY, barW, barH)
    local barColor = hpRatio > 0.5 and W95.green or (hpRatio > 0.25 and W95.yellow or W95.red)
    love.graphics.setColor(barColor)
    love.graphics.rectangle("fill", barX + 2 + shakeOff, barY + 2, (barW - 4) * hpRatio, barH - 4)
    love.graphics.setColor(W95.white)
    love.graphics.printf(math.floor(self.projectProgress) .. "/" .. self.projectMaxProgress, barX + shakeOff, barY + 3, barW, "center")

    local infoY = barY + barH + 4
    love.graphics.setColor(W95.text)
    love.graphics.print("Dias: " .. math.ceil(self.projectDaysLeft) .. "/" .. self.projectMaxDays, x + 16, infoY)
    love.graphics.setColor(W95.green)
    love.graphics.print("Ingresos: $" .. math.floor(self.moneySpent), x + w - 100, infoY)

    local compY = infoY + 18
    local compW = (w - 40) / math.max(1, #self.components)
    for i, comp in ipairs(self.components) do
        local cx = x + 16 + (i - 1) * compW
        local vibOff = 0
        if comp.vibration > 0 then vibOff = (math.random() - 0.5) * 4 end

        love.graphics.setColor(W95.fieldBg)
        love.graphics.rectangle("fill", cx + vibOff, compY, compW - 6, 50)
        self:drawBevel(cx + vibOff, compY, compW - 6, 50)

        love.graphics.setColor(comp.color)
        love.graphics.rectangle("fill", cx + vibOff, compY, compW - 6, 3)
        love.graphics.rectangle("fill", cx + vibOff, compY + 47, compW - 6, 3)

        love.graphics.setColor(W95.text)
        love.graphics.printf(comp.label, cx + vibOff, compY + 5, compW - 6, "center")
        love.graphics.setColor(W95.textDim)
        love.graphics.printf(comp.power .. " pts", cx + vibOff, compY + 18, compW - 6, "center")
        love.graphics.printf(string.format("%.1fs", comp.interval), cx + vibOff, compY + 30, compW - 6, "center")

        comp.screenX = cx + compW / 2
        comp.screenY = compY + 50
        comp.barX = barX + barW * hpRatio
        comp.barY = barY + barH / 2
    end

    for _, circ in ipairs(self.circles) do
        love.graphics.setColor(circ.color)
        love.graphics.circle("fill", circ.x, circ.y, circ.radius)
        love.graphics.setColor(0, 0, 0)
        love.graphics.circle("line", circ.x, circ.y, circ.radius)
    end

    for _, num in ipairs(self.floatingNumbers) do
        local alpha = num.timer / num.maxTimer
        love.graphics.setColor(num.isBug and {1, 0.2, 0.2, alpha} or {0.2, 1, 0.2, alpha})
        love.graphics.printf(num.text, num.x - 30, num.y, 60, "center")
    end

    local cancelBtnW = 100
    local cancelBtnH = 24
    local cancelBtnX = x + w - cancelBtnW - 16
    local cancelBtnY = y + h - 36
    local cHov = self.lastMX >= cancelBtnX and self.lastMX <= cancelBtnX + cancelBtnW and self.lastMY >= cancelBtnY and self.lastMY <= cancelBtnY + cancelBtnH

    love.graphics.setColor(cHov and {0.85, 0.85, 0.85} or W95.bg)
    love.graphics.rectangle("fill", cancelBtnX, cancelBtnY, cancelBtnW, cancelBtnH)
    self:drawBevel(cancelBtnX, cancelBtnY, cancelBtnW, cancelBtnH)
    love.graphics.setColor(W95.red)
    love.graphics.printf("Cancelar", cancelBtnX, cancelBtnY + 5, cancelBtnW, "center")
    table.insert(self.buttons, {x = cancelBtnX, y = cancelBtnY, w = cancelBtnW, h = cancelBtnH, action = "cancel_project"})

    love.graphics.setColor(W95.textDim)
    love.graphics.printf("Cancelas y recuperas 30%", x + 16, y + h - 28, w / 2 - 20, "left")
end

function Coding:drawMinigame(x, y, w, h)
    love.graphics.setColor({0.15, 0.16, 0.18})
    love.graphics.rectangle("fill", x + 6, y + 4, w - 12, h - 8)
    self:drawBevel(x + 6, y + 4, w - 12, h - 8)

    love.graphics.setColor(W95.yellow)
    love.graphics.setFont(self.smallFont or love.graphics.newFont(11))
    love.graphics.printf("Escribe el codigo para completar el milestone", x + 8, y + 8, w - 16, "center")

    local codeX = x + 12
    local codeY = y + 24
    local codeW = w - 24
    local codeH = h - 50

    love.graphics.setColor({0.1, 0.1, 0.1})
    love.graphics.rectangle("fill", codeX, codeY, codeW, codeH)
    self:drawBevel(codeX, codeY, codeW, codeH)

    love.graphics.setScissor(codeX + 1, codeY + 1, codeW - 2, codeH - 2)
    love.graphics.setFont(self.codeFont)
    local lineH = 16
    local maxLines = math.floor((codeH - 4) / lineH)

    local startLine = math.max(1, math.floor(self.codeScrollY / lineH) + 1)
    local endLine = math.min(#self.codeLines, startLine + maxLines)

    for i = startLine, endLine do
        local lineY = codeY + 2 + (i - startLine) * lineH
        love.graphics.setColor({0.4, 0.4, 0.4})
        love.graphics.printf(i, codeX + 4, lineY, 30, "right")

        local lineText = ""
        if i < self.codeLineIndex then
            lineText = self.codeLines[i]
        elseif i == self.codeLineIndex then
            lineText = self.codeLines[i]:sub(1, self.codeCharIndex)
        end

        if #lineText > 0 then
            local tokens = {}
            local current = ""
            for c in lineText:gmatch(".") do
                if c:match("[%s%(%)%[%]{};,:%.]") then
                    if #current > 0 then
                        table.insert(tokens, current)
                        current = ""
                    end
                    table.insert(tokens, c)
                else
                    current = current .. c
                end
            end
            if #current > 0 then table.insert(tokens, current) end

            local keywords = {"if", "else", "for", "while", "return", "function", "class", "def", "import", "from", "const", "let", "var", "int", "char", "void", "struct", "typedef", "include", "define", "malloc", "free"}
            local drawX = codeX + 38
            for _, token in ipairs(tokens) do
                local color = {0.97, 0.97, 0.94}
                if token:match("^%d+$") then color = {0.68, 0.45, 0.97}
                elseif token:match('".*"') or token:match("'.*'") then color = {0.90, 0.78, 0.35}
                elseif token:match("^//") or token:match("^#") then color = {0.50, 0.52, 0.54}
                else
                    for _, kw in ipairs(keywords) do
                        if token == kw then color = {0.98, 0.45, 0.36}; break end
                    end
                end
                love.graphics.setColor(color)
                love.graphics.print(token, drawX, lineY)
                drawX = drawX + self.codeFont:getWidth(token)
            end
        end

        if i == self.codeLineIndex and not self.codeComplete and math.floor(self.cursorBlink * 2) % 2 == 0 then
            local cursorX = codeX + 38 + self.codeFont:getWidth(self.codeLines[i]:sub(1, self.codeCharIndex))
            love.graphics.setColor({0.97, 0.97, 0.94})
            love.graphics.rectangle("fill", cursorX, lineY, 8, 14)
        end
    end
    love.graphics.setScissor()

    love.graphics.setColor(W95.textDim)
    love.graphics.setFont(self.smallFont or love.graphics.newFont(11))
    love.graphics.printf("Presiona cualquier tecla para escribir codigo", x + 12, y + h - 14, w - 24, "center")
end

function Coding:drawSell(x, y, w, h)
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", x + 6, y + 4, w - 12, h - 8)
    self:drawBevel(x + 6, y + 4, w - 12, h - 8)

    love.graphics.setColor(W95.green)
    love.graphics.printf("Proyecto Completado!", x + 8, y + 20, w - 16, "center")

    love.graphics.setColor(W95.text)
    love.graphics.printf(self.projectName, x + 8, y + 45, w - 16, "center")

    love.graphics.setColor(W95.yellow)
    love.graphics.printf("XP ganado: +" .. math.floor(self.activeProject.reward / 5), x + 8, y + 65, w - 16, "center")

    local btnW = 160
    local btnH = 32
    local btnX = x + (w - btnW) / 2
    local btnY = y + 100
    local btnHov = self.lastMX >= btnX and self.lastMX <= btnX + btnW and self.lastMY >= btnY and self.lastMY <= btnY + btnH

    love.graphics.setColor(btnHov and {0.85, 0.85, 0.85} or W95.bg)
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
    self:drawBevel(btnX, btnY, btnW, btnH)
    love.graphics.setColor(W95.green)
    love.graphics.printf("Vender App", btnX, btnY + 8, btnW, "center")
    table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "sell_app"})
end

function Coding:drawManage(x, y, w, h)
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", x + 6, y + 4, w - 12, h - 8)
    self:drawBevel(x + 6, y + 4, w - 12, h - 8)

    love.graphics.setColor(W95.text)
    love.graphics.printf("Mis Aplicaciones", x + 8, y + 8, w - 16, "center")

    if #self.publishedApps == 0 then
        love.graphics.setColor(W95.textDim)
        love.graphics.printf("No tienes apps publicadas.", x + 8, y + 50, w - 16, "center")

        local backBtnW = 80
        local backBtnH = 22
        local backBtnX = x + (w - backBtnW) / 2
        local backBtnY = y + h - 34
        local bHov = self.lastMX >= backBtnX and self.lastMX <= backBtnX + backBtnW and self.lastMY >= backBtnY and self.lastMY <= backBtnY + backBtnH

        love.graphics.setColor(bHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", backBtnX, backBtnY, backBtnW, backBtnH)
        self:drawBevel(backBtnX, backBtnY, backBtnW, backBtnH)
        love.graphics.setColor(W95.text)
        love.graphics.printf("Volver", backBtnX, backBtnY + 3, backBtnW, "center")
        table.insert(self.buttons, {x = backBtnX, y = backBtnY, w = backBtnW, h = backBtnH, action = "back_browse"})
        return
    end

    local itemH = 50
    local startY = y + 28
    for i, app in ipairs(self.publishedApps) do
        local iy = startY + (i - 1) * (itemH + 4)
        if iy + itemH < y + h - 40 then
            love.graphics.setColor(W95.bg)
            love.graphics.rectangle("fill", x + 12, iy, w - 24, itemH)
            self:drawBevel(x + 12, iy, w - 24, itemH)

            love.graphics.setColor(W95.text)
            love.graphics.print(app.name, x + 20, iy + 4)

            local status = app.selling and ("Vendiendo (" .. app.monthsLeft .. " meses)") or "Retirada"
            love.graphics.setColor(app.selling and W95.green or W95.textDim)
            love.graphics.print(status, x + 20, iy + 18)

            love.graphics.setColor(W95.yellow)
            love.graphics.print("Total: $" .. app.totalRevenue, x + 20, iy + 32)

            if app.selling then
                local updateBtnW = 60
                local updateBtnH = 16
                local updateBtnX = x + w - updateBtnW - 20
                local updateBtnY = iy + 4
                local uHov = self.lastMX >= updateBtnX and self.lastMX <= updateBtnX + updateBtnW and self.lastMY >= updateBtnY and self.lastMY <= updateBtnY + updateBtnH

                if app.updateCooldown >= 4 then
                    love.graphics.setColor(uHov and {0.85, 0.85, 0.85} or W95.bg)
                    love.graphics.rectangle("fill", updateBtnX, updateBtnY, updateBtnW, updateBtnH)
                    self:drawBevel(updateBtnX, updateBtnY, updateBtnW, updateBtnH)
                    love.graphics.setColor(W95.green)
                    love.graphics.printf("Update", updateBtnX, updateBtnY + 1, updateBtnW, "center")
                    table.insert(self.buttons, {x = updateBtnX, y = updateBtnY, w = updateBtnW, h = updateBtnH, action = "do_update", index = i})
                else
                    love.graphics.setColor(W95.textDim)
                    love.graphics.print("Update: " .. (4 - app.updateCooldown) .. " meses", x + w - 110, iy + 18)
                end

                local cancelAppW = 60
                local cancelAppH = 16
                local cancelAppX = x + w - cancelAppW - 20
                local cancelAppY = iy + 24
                local caHov = self.lastMX >= cancelAppX and self.lastMX <= cancelAppX + cancelAppW and self.lastMY >= cancelAppY and self.lastMY <= cancelAppY + cancelAppH

                love.graphics.setColor(caHov and {0.85, 0.85, 0.85} or W95.bg)
                love.graphics.rectangle("fill", cancelAppX, cancelAppY, cancelAppW, cancelAppH)
                self:drawBevel(cancelAppX, cancelAppY, cancelAppW, cancelAppH)
                love.graphics.setColor(W95.red)
                love.graphics.printf("Quitar", cancelAppX, cancelAppY + 1, cancelAppW, "center")
                table.insert(self.buttons, {x = cancelAppX, y = cancelAppY, w = cancelAppW, h = cancelAppH, action = "cancel_sale", index = i})
            end
        end
    end

    local backBtnW = 80
    local backBtnH = 22
    local backBtnX = x + 12
    local backBtnY = y + h - 34
    local bHov = self.lastMX >= backBtnX and self.lastMX <= backBtnX + backBtnW and self.lastMY >= backBtnY and self.lastMY <= backBtnY + backBtnH

    love.graphics.setColor(bHov and {0.85, 0.85, 0.85} or W95.bg)
    love.graphics.rectangle("fill", backBtnX, backBtnY, backBtnW, backBtnH)
    self:drawBevel(backBtnX, backBtnY, backBtnW, backBtnH)
    love.graphics.setColor(W95.text)
    love.graphics.printf("Volver", backBtnX, backBtnY + 3, backBtnW, "center")
    table.insert(self.buttons, {x = backBtnX, y = backBtnY, w = backBtnW, h = backBtnH, action = "back_browse"})
end

function Coding:handleClick(x, y, button)
    if button ~= 1 then return false end

    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "start_project" then
                self:startProject(btn.index)
            elseif btn.action == "refresh" and self.refreshAttempts > 0 then
                self:refreshProjects()
                self.refreshAttempts = self.refreshAttempts - 1
                if self.refreshAttempts == 0 then
                    self.refreshCooldown = self.refreshCooldownMax
                end
            elseif btn.action == "sell_app" then
                self:sellApp()
            elseif btn.action == "open_manage" then
                self.state = "manage"
            elseif btn.action == "back_browse" then
                self.state = "browse"
            elseif btn.action == "cancel_project" then
                self:cancelProject()
            elseif btn.action == "do_update" and btn.index then
                local app = self.publishedApps[btn.index]
                if app and app.updateCooldown >= 4 then
                    app.revenuePerMonth = math.floor(app.revenuePerMonth * 1.3)
                    app.monthsLeft = app.monthsLeft + 8
                    app.updateCooldown = 0
                end
            elseif btn.action == "cancel_sale" and btn.index then
                table.remove(self.publishedApps, btn.index)
            end
            return true
        end
    end
    return true
end

function Coding:drawBevel(x, y, w, h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Coding:drawInset(x, y, w, h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Coding:mousemoved(x, y)
    self.lastMX = x
    self.lastMY = y
    self.window:mousemoved(x, y)
end

function Coding:mousereleased(x, y, button)
    self.window:mousereleased(x, y, button)
end

function Coding:draw(mx, my)
    self.window:drawFrame()
end

function Coding:hitTest(mx, my)
    return self.window:hitTest(mx, my)
end

function Coding:mousepressed(x, y, button)
    return self.window:mousepressed(x, y, button)
end

function Coding:keypressed(key)
    if self.state ~= "coding" or not self.milestoneActive then return end
    if key == "lshift" or key == "rshift" or key == "lctrl" or key == "rctrl" or
       key == "lalt" or key == "ralt" or key == "escape" or key == "tab" or
       key == "capslock" or key == "return" or key == "up" or key == "down" or
       key == "left" or key == "right" or key == "home" or key == "end" then
        return
    end

    local charsPerKey = 1 + self.codingLevel
    for i = 1, charsPerKey do
        if self.codeLineIndex <= #self.codeLines then
            local currentLine = self.codeLines[self.codeLineIndex]
            if self.codeCharIndex < #currentLine then
                self.codeCharIndex = self.codeCharIndex + 1
            else
                self.codeLineIndex = self.codeLineIndex + 1
                self.codeCharIndex = 0
                self.codeTargetScrollY = self.codeTargetScrollY + 16
            end
        end
    end

    local totalChars = 0
    for _, line in ipairs(self.codeLines) do
        totalChars = totalChars + #line + 1
    end
    local typedChars = 0
    for i = 1, self.codeLineIndex - 1 do
        typedChars = typedChars + #self.codeLines[i] + 1
    end
    typedChars = typedChars + self.codeCharIndex
    self.codeProgress = math.min(1, typedChars / totalChars)

    if self.codeLineIndex > #self.codeLines then
        self.milestoneActive = false
        self.codeComplete = false
        local bonus = math.floor(self.activeProject.baseHp * 0.1)
        self.projectProgress = self.projectProgress + bonus
        self.codingXP = self.codingXP + 10
        self:checkLevelUp()
    end
end

function Coding:textinput(text)
end

return Coding
