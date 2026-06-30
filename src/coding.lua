local Coding = {}
Coding.__index = Coding

local Screen = require("src.screen")
local WindowManager = require("src.window")

local W95 = {
    bg = {0.75, 0.75, 0.75},
    borderLight = {1, 1, 1},
    borderDark = {0.5, 0.5, 0.5},
    text = {0, 0, 0},
    textDim = {0.4, 0.4, 0.4},
    white = {1, 1, 1},
    highlight = {0, 0, 0.5},
    highlightText = {1, 1, 1},
    green = {0, 0.5, 0},
    red = {0.8, 0, 0},
    yellow = {0.8, 0.6, 0},
}

Coding.projectTypes = {
    {id="calculator",name="Calculadora",difficulty="normal",baseCost=800,baseHp=1000,reward=2000,monthly=80},
    {id="notepad_pro",name="Notepad Pro",difficulty="normal",baseCost=600,baseHp=800,reward=1500,monthly=60},
    {id="file_manager",name="File Manager",difficulty="normal",baseCost=900,baseHp=1200,reward=2200,monthly=90},
    {id="browser",name="Web Browser",difficulty="dificil",baseCost=2000,baseHp=2000,reward=5000,monthly=200},
    {id="email_client",name="Cliente de Email",difficulty="dificil",baseCost=1500,baseHp=1600,reward=4000,monthly=150},
    {id="media_player",name="Reproductor",difficulty="dificil",baseCost=2500,baseHp=2400,reward=6000,monthly=250},
    {id="database",name="Base de Datos",difficulty="pesadilla",baseCost=5000,baseHp=4000,reward=12000,monthly=500},
    {id="office_suite",name="Suite de Oficina",difficulty="pesadilla",baseCost=8000,baseHp=5000,reward=18000,monthly=800},
    {id="game_engine",name="Motor de Juegos",difficulty="pesadilla",baseCost=12000,baseHp=6000,reward=25000,monthly=1200},
}

local componentDefs = {
    gpu = {label="GPU",color={0.2,0.8,0.3},baseInterval=2.0,basePower=3,tiers={{interval=2.0,power=3},{interval=1.6,power=5},{interval=1.2,power=8},{interval=0.8,power=12}}},
    cpu = {label="CPU",color={0.6,0.2,0.9},baseInterval=3.0,basePower=2,tiers={{interval=3.0,power=2},{interval=2.4,power=3},{interval=1.8,power=5},{interval=1.2,power=7}}},
    ram = {label="RAM",color={0.9,0.5,0.1},baseInterval=4.0,basePower=0,tiers={{interval=4.0,power=0},{interval=3.2,power=2},{interval=2.4,power=4},{interval=1.6,power=7}}},
    cooling = {label="Refrig",color={0.2,0.8,0.8},baseInterval=5.0,basePower=0,tiers={{interval=5.0,power=0},{interval=4.0,power=2},{interval=3.0,power=4},{interval=2.0,power=6}}},
}
local componentOrder = {"gpu","cpu","ram","cooling"}

local codeSnippets = {
    {
        {text='def calculate_total(items):', typing=true},
        {text='    total = 0', typing=false},
        {text='    for item in items:', typing=false},
        {text='        total += item.price', typing=true},
        {text='    return total', typing=false},
    },
    {
        {text='class Database:', typing=true},
        {text='    def __init__(self, name):', typing=false},
        {text='        self.name = name', typing=false},
        {text='        self.tables = {}', typing=true},
        {text='    def create_table(self, name, cols):', typing=false},
        {text='        table = {"name": name}', typing=true},
    },
    {
        {text='function processData(input) {', typing=true},
        {text='    const result = [];', typing=false},
        {text='    for (let i = 0; i < input.length; i++) {', typing=false},
        {text='        if (input[i].valid) {', typing=true},
        {text='            result.push(transform(input[i]));', typing=false},
        {text='        }', typing=false},
        {text='    }', typing=false},
        {text='    return result;', typing=true},
        {text='}', typing=false},
    },
    {
        {text='#include <stdlib.h>', typing=true},
        {text='#include <string.h>', typing=false},
        {text='typedef struct {', typing=false},
        {text='    char *name;', typing=true},
        {text='    int id;', typing=false},
        {text='    float value;', typing=false},
        {text='} Record;', typing=true},
        {text='Record* create_record(const char *n) {', typing=false},
        {text='    Record *r = malloc(sizeof(Record));', typing=true},
        {text='    return r;', typing=false},
        {text='}', typing=false},
    },
    {
        {text='def save_report(data, filename):', typing=true},
        {text='    with open(filename, "w") as f:', typing=false},
        {text='        for line in data:', typing=false},
        {text='            f.write(str(line) + "\\n")', typing=true},
        {text='    print("Report saved!")', typing=false},
    },
    {
        {text='class FileManager:', typing=true},
        {text='    def __init__(self, path):', typing=false},
        {text='        self.path = path', typing=false},
        {text='        self.files = []', typing=true},
        {text='    def list_files(self):', typing=false},
        {text='        return os.listdir(self.path)', typing=true},
    },
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
    self.activeProject = nil
    self.projectProgress = 0
    self.projectMaxProgress = 100
    self.moneySpent = 0
    self.costPerSecond = 0
    self.projectDaysLeft = 0
    self.projectMaxDays = 0
    self.circles = {}
    self.floatingNumbers = {}
    self.barShake = 0
    self.components = {}
    self.publishedApps = {}
    self.refreshAttempts = 3
    self.maxRefreshAttempts = 3
    self.refreshCooldown = 0
    self.refreshCooldownMax = 30
    self.milestoneActive = false
    self.milestoneTargets = {0.25, 0.50, 0.75}
    self.nextMilestone = 1
    self.codeLines = {}
    self.codeLineIndex = 1
    self.codeCharIndex = 0
    self.codeScrollY = 0
    self.codeH = 300
    self.cursorBlink = 0
    self.snippetLines = {}
    self.snippetIndex = 1
    self.typingMode = false
    self.currentTypingLine = ""
    self.typedChars = ""
    self.typingError = false
    self.typingErrorTimer = 0
    self.combo = 0
    self.maxCombo = 0
    self.linesCompleted = 0
    self.autoTypingSpeed = 0.03
    self.autoTypingTimer = 0
    self.autoTypingCharIndex = 0
    self.snippetComplete = false
    self.snippetBonus = 0
    self.codeFont = love.graphics.newFont(12)
    self.smallFont = love.graphics.newFont(11)
    self.circleFont = love.graphics.newFont(13)
    self.circleSounds = {}
    local okCs, sndCs = pcall(love.audio.newSource, "assets/sounds/circlesound.wav", "static")
    if okCs then sndCs:setVolume(0.5); table.insert(self.circleSounds, sndCs) end
    local okCs2, sndCs2 = pcall(love.audio.newSource, "assets/sounds/circlesound2.wav", "static")
    if okCs2 then sndCs2:setVolume(0.5); table.insert(self.circleSounds, sndCs2) end
    self.buttons = {}
    self.lastMX = 0
    self.lastMY = 0
    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, mx, my, btn)
        if btn ~= 1 then return false end
        for _, b in ipairs(self.buttons) do
            if mx >= b.x and mx <= b.x + b.w and my >= b.y and my <= b.y + b.h then
                self:handleButton(b.action, b)
                return true
            end
        end
        return true
    end
    return self
end

function Coding:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
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

function Coding:getMaxAppsForSale()
    if self.codingLevel >= 5 then return 3 end
    if self.codingLevel >= 3 then return 2 end
    return 1
end

function Coding:refreshProjects()
    self.availableProjects = {}
    local count = math.min(4, 2 + math.floor(self.codingLevel / 2))
    local available = {}
    for _, p in ipairs(Coding.projectTypes) do table.insert(available, p) end
    for i = 1, count do
        if #available > 0 then
            local idx = math.random(#available)
            table.insert(self.availableProjects, available[idx])
            table.remove(available, idx)
        end
    end
end

function Coding:recalcComponents()
    self.components = {}
    if not self.explorerRef then return end
    local statMap = {gpu="display", cpu="cpu", ram="ram", cooling="cooling"}
    for _, id in ipairs(componentOrder) do
        local def = componentDefs[id]
        local stat = statMap[id]
        local level = self.explorerRef.upgradeLevels[stat] or 0
        local power = level > 0 and def.tiers[level].power or def.basePower
        local interval = level > 0 and def.tiers[level].interval or def.baseInterval
        if power > 0 then
            local mult = (stat == "ram" or stat == "cooling") and 0.5 or 1.0
            table.insert(self.components, {
                id=id, label=def.label, color=def.color,
                power=math.floor(power*mult), interval=interval,
                timer=0, screenX=0, screenY=0, barX=0, barY=0, vibration=0,
            })
        end
    end
end

function Coding:startProject(index)
    local pt = self.availableProjects[index]
    if not pt then return end
    if not self.trabajoRef or self.trabajoRef.money < pt.baseCost then return end
    local selling = 0
    for _, app in ipairs(self.publishedApps) do
        if app.selling then selling = selling + 1 end
    end
    if selling >= self:getMaxAppsForSale() then return end
    self.trabajoRef.money = self.trabajoRef.money - pt.baseCost
    self.activeProject = pt
    self.projectProgress = 0
    self.projectMaxProgress = pt.baseHp
    self.moneySpent = pt.baseCost
    self.projectDaysLeft = 14
    self.projectMaxDays = 14
    self.state = "coding"
    self:startNextSnippet()
end

function Coding:startNextSnippet()
    self.milestoneActive = true
    local snippet = codeSnippets[math.random(#codeSnippets)]
    self.snippetLines = snippet
    self.snippetIndex = 1
    self.codeLines = {}
    self.codeLineIndex = 1
    self.codeCharIndex = 0
    self.codeScrollY = 0
    self.combo = 0
    self.linesCompleted = 0
    self.snippetComplete = false
    self.snippetBonus = 0
    self.typedChars = ""
    self.typingError = false
    self.typingErrorTimer = 0
    self:advanceSnippet()
end

function Coding:sellApp()
    if not self.activeProject then return end
    local pt = self.activeProject
    table.insert(self.publishedApps, {
        name=pt.name, type=pt, revenuePerMonth=pt.monthly,
        monthsLeft=12, totalRevenue=0, selling=true,
        updateCooldown=0, successScore=math.random(5,9)/10,
    })
    self.codingXP = self.codingXP + math.floor(pt.reward / 5)
    self:checkLevelUp()
    self:resetProject()
end

function Coding:resetProject()
    self.activeProject = nil
    self.projectProgress = 0
    self.projectMaxProgress = 100
    self.moneySpent = 0
    self.projectDaysLeft = 0
    self.milestoneActive = false
    self.snippetComplete = false
    self.state = "browse"
end

function Coding:cancelProject()
    if not self.activeProject then return end
    if self.trabajoRef then
        self.trabajoRef.money = self.trabajoRef.money + math.floor(self.moneySpent * 0.3)
    end
    self:resetProject()
end

function Coding:handleButton(action, btn)
    if action == "start_project" then
        self:startProject(btn.index)
    elseif action == "refresh" and self.refreshAttempts > 0 then
        self:refreshProjects()
        self.refreshAttempts = self.refreshAttempts - 1
        if self.refreshAttempts == 0 then self.refreshCooldown = self.refreshCooldownMax end
    elseif action == "sell_app" then
        self:sellApp()
    elseif action == "open_manage" then
        self.state = "manage"
    elseif action == "back_browse" then
        self.state = "browse"
    elseif action == "cancel_project" then
        self:cancelProject()
    elseif action == "do_update" and btn.index then
        local app = self.publishedApps[btn.index]
        if app and (app.updateCooldown or 0) >= 4 then
            app.revenuePerMonth = math.floor(app.revenuePerMonth * 1.3)
            app.monthsLeft = app.monthsLeft + 8
            app.updateCooldown = 0
        end
    elseif action == "cancel_sale" and btn.index then
        table.remove(self.publishedApps, btn.index)
    end
end

function Coding:striggerMilestone()
    self.milestoneActive = true
    local snippet = codeSnippets[math.random(#codeSnippets)]
    self.snippetLines = snippet
    self.snippetIndex = 1
    self.codeLines = {}
    self.codeLineIndex = 1
    self.codeCharIndex = 0
    self.codeScrollY = 0
    self.nextMilestone = self.nextMilestone + 1
    self.combo = 0
    self.linesCompleted = 0
    self.snippetComplete = false
    self.snippetBonus = 0
    self.typedChars = ""
    self.typingError = false
    self.typingErrorTimer = 0
    self:advanceSnippet()
end

function Coding:advanceSnippet()
    if self.snippetIndex > #self.snippetLines then
        self.snippetComplete = true
        self.snippetBonus = math.floor(self.activeProject.baseHp * 0.15)
        self.projectProgress = self.projectProgress + self.snippetBonus
        self.codingXP = self.codingXP + 15
        self:checkLevelUp()
        return
    end
    local current = self.snippetLines[self.snippetIndex]
    if current.typing then
        self.typingMode = true
        self.currentTypingLine = current.text
        self.typedChars = ""
        self.typingError = false
        self.typingErrorTimer = 0
        table.insert(self.codeLines, current.text)
        self.codeLineIndex = #self.codeLines
        self.codeCharIndex = 0
    else
        self.typingMode = false
        self.codeLines = {}
        self.codeLineIndex = 1
        self.codeCharIndex = 0
        self.autoTypingTimer = 0
        self.autoTypingCharIndex = 0
        local autoStart = self.snippetIndex
        local autoEnd = autoStart
        while autoEnd <= #self.snippetLines and not self.snippetLines[autoEnd].typing do
            autoEnd = autoEnd + 1
        end
        self.autoLines = {}
        for i = autoStart, autoEnd - 1 do
            table.insert(self.autoLines, self.snippetLines[i].text)
        end
        self.autoLineIndex = 1
        self.autoCharIndex = 0
    end
end

function Coding:update(dt)
    if self.refreshCooldown > 0 then
        self.refreshCooldown = self.refreshCooldown - dt
        if self.refreshCooldown <= 0 then self.refreshAttempts = self.maxRefreshAttempts end
    end
    if self.state == "coding" and self.activeProject then
        self.projectDaysLeft = self.projectDaysLeft - dt * 0.05
        if self.projectDaysLeft <= 0 then self:cancelProject() end
    end
    for i = #self.floatingNumbers, 1, -1 do
        local n = self.floatingNumbers[i]
        n.y = n.y + n.vy * dt
        n.timer = n.timer - dt
        if n.timer <= 0 then table.remove(self.floatingNumbers, i) end
    end
    for i = #self.publishedApps, 1, -1 do
        local app = self.publishedApps[i]
        if app.selling then
            app.monthlyTimer = (app.monthlyTimer or 0) + dt
            if app.monthlyTimer >= 30 then
                app.monthlyTimer = app.monthlyTimer - 30
                local revenue = math.floor(app.revenuePerMonth * app.successScore * app.monthsLeft / 12)
                app.totalRevenue = app.totalRevenue + revenue
                if self.trabajoRef then self.trabajoRef.money = self.trabajoRef.money + revenue end
                app.monthsLeft = app.monthsLeft - 1
                app.updateCooldown = (app.updateCooldown or 0) + 1
                if app.monthsLeft <= 0 then app.selling = false end
            end
        end
    end
    self.cursorBlink = self.cursorBlink + dt
    if self.typingErrorTimer > 0 then
        self.typingErrorTimer = self.typingErrorTimer - dt
        if self.typingErrorTimer <= 0 then
            self.typingError = false
        end
    end
    if self.milestoneActive and not self.typingMode and not self.snippetComplete and self.autoLines then
        self.autoTypingTimer = self.autoTypingTimer + dt
        if self.autoTypingTimer >= self.autoTypingSpeed then
            self.autoTypingTimer = self.autoTypingTimer - self.autoTypingSpeed
            if self.autoLineIndex <= #self.autoLines then
                local currentLine = self.autoLines[self.autoLineIndex]
                if self.autoCharIndex < #currentLine then
                    self.autoCharIndex = self.autoCharIndex + 1
                    if #self.codeLines < self.autoLineIndex then
                        table.insert(self.codeLines, "")
                    end
                    self.codeLines[self.autoLineIndex] = currentLine:sub(1, self.autoCharIndex)
                    self.codeLineIndex = self.autoLineIndex
                    self.codeCharIndex = self.autoCharIndex
                else
                    self.autoLineIndex = self.autoLineIndex + 1
                    self.autoCharIndex = 0
                end
            end
        end
    end
    if self.milestoneActive then
        local lineH = 16
        local currentLineY = (self.codeLineIndex - 1) * lineH
        local maxVisibleY = self.codeScrollY + self.codeH - lineH * 3
        if currentLineY > maxVisibleY then
            self.codeScrollY = currentLineY - self.codeH + lineH * 3
        end
    end
end

function Coding:genCircle(comp)
    local tx, ty = comp.barX, comp.barY
    local dx, dy = tx - comp.screenX, ty - comp.screenY
    local dist = math.max(1, math.sqrt(dx*dx + dy*dy))
    local speed = 200
    local isBug = math.random() < 0.03
    local power = isBug and math.floor(comp.power * 0.6) or comp.power
    table.insert(self.circles, {
        x=comp.screenX, y=comp.screenY, vx=(dx/dist)*speed, vy=(dy/dist)*speed,
        targetX=tx, targetY=ty, color=isBug and {0.9,0.15,0.15} or comp.color,
        power=power, life=dist/speed+0.1, radius=12, isBug=isBug,
    })
    comp.vibration = 0.2
end

function Coding:keypressed(key)
    if self.state ~= "coding" or not self.milestoneActive then return end
    if self.snippetComplete then
        if self.projectProgress >= self.projectMaxProgress then
            self.state = "sell"
        else
            self:startNextSnippet()
        end
        return
    end
    if key == "lshift" or key == "rshift" or key == "lctrl" or key == "rctrl" or
       key == "lalt" or key == "ralt" or key == "escape" or key == "tab" or
       key == "capslock" or key == "up" or key == "down" or
       key == "left" or key == "right" or key == "home" or key == "end" then return end
    if not self.typingMode then
        if key == "return" or key == "space" then
            self:finishAutoSection()
        end
        return
    end
    if key == "return" then return end
    if key == "backspace" then
        if #self.typedChars > 0 then
            self.typedChars = self.typedChars:sub(1, -2)
            self.codeCharIndex = #self.typedChars
        end
        return
    end
end

function Coding:completeTypingLine()
    local damage = math.floor(self.activeProject.baseHp * 0.03)
    local comboMult = 1.0 + self.combo * 0.1
    damage = math.floor(damage * comboMult)
    self.projectProgress = self.projectProgress + damage
    self.combo = self.combo + 1
    if self.combo > self.maxCombo then self.maxCombo = self.combo end
    self.linesCompleted = self.linesCompleted + 1
    self.codingXP = self.codingXP + 5
    self:checkLevelUp()
    table.insert(self.floatingNumbers, {
        text = "+" .. damage .. (self.combo > 1 and (" x" .. self.combo) or ""),
        x = self.window.x + self.window.w / 2,
        y = self.window.y + 100,
        timer = 1.5, maxTimer = 1.5, vy = -50, isBug = false,
    })
    self.barShake = 0.2
    self.snippetIndex = self.snippetIndex + 1
    self:advanceSnippet()
    if self.projectProgress >= self.projectMaxProgress then
        self.state = "sell"
    end
end

function Coding:finishAutoSection()
    for _, line in ipairs(self.autoLines) do
        table.insert(self.codeLines, line)
    end
    self.codeLineIndex = #self.codeLines
    self.codeCharIndex = #self.codeLines[#self.codeLines]
    self.snippetIndex = self.snippetIndex + #self.autoLines
    self.typingMode = false
    self.autoLines = {}
    self.autoLineIndex = 1
    self.autoCharIndex = 0
    self:advanceSnippet()
end

function Coding:drawContent(cx, cy, cw, ch)
    self.buttons = {}
    local prevFont = love.graphics.getFont()
    love.graphics.setFont(self.smallFont)
    if self.state == "browse" then
        self:drawBrowse(cx, cy, cw, ch)
    elseif self.state == "coding" then
        self:drawMinigame(cx, cy, cw, ch)
    elseif self.state == "sell" then
        self:drawSell(cx, cy, cw, ch)
    elseif self.state == "manage" then
        self:drawManage(cx, cy, cw, ch)
    end
    love.graphics.setFont(prevFont)
end

function Coding:drawBevel(x, y, w, h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x, y, x+w, y); love.graphics.line(x, y, x, y+h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x+w, y, x+w, y+h); love.graphics.line(x, y+h, x+w, y+h)
end

function Coding:drawInset(x, y, w, h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x, y, x+w, y); love.graphics.line(x, y, x, y+h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x+w, y, x+w, y+h); love.graphics.line(x, y+h, x+w, y+h)
end

function Coding:drawBrowse(x, y, w, h)
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", x+6, y+4, w-12, h-8)
    self:drawBevel(x+6, y+4, w-12, h-8)
    love.graphics.setColor(W95.text)
    love.graphics.printf("Proyectos de Coding", x+8, y+8, w-16, "center")
    love.graphics.setColor(W95.yellow)
    love.graphics.printf("Nivel: "..self.codingLevel.."  XP: "..self.codingXP.."/"..self:getNextXP(), x+8, y+22, w-16, "center")
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x+8, y+38, x+w-8, y+38)
    if #self.availableProjects == 0 then self:refreshProjects() end
    local itemH = 72
    for i, pt in ipairs(self.availableProjects) do
        local iy = y + 44 + (i-1) * (itemH + 8)
        if iy + itemH < y + h - 40 then
            local canAfford = self.trabajoRef and self.trabajoRef.money >= pt.baseCost
            love.graphics.setColor(canAfford and W95.bg or {0.9,0.9,0.9})
            love.graphics.rectangle("fill", x+12, iy, w-24, itemH)
            self:drawBevel(x+12, iy, w-24, itemH)
            love.graphics.setColor(W95.highlight)
            love.graphics.rectangle("fill", x+14, iy+2, 24, 24)
            love.graphics.setColor(W95.text)
            love.graphics.printf(pt.difficulty:sub(1,1):upper(), x+14, iy+6, 24, "center")
            love.graphics.setColor(W95.text)
            love.graphics.printf(pt.name, x+44, iy+6, w-60, "left")
            local dc = W95.green
            if pt.difficulty == "dificil" then dc = W95.yellow end
            if pt.difficulty == "pesadilla" then dc = W95.red end
            love.graphics.setColor(dc)
            love.graphics.printf(pt.difficulty:upper(), x+44, iy+22, 80, "left")
            love.graphics.setColor(W95.textDim)
            love.graphics.printf("$"..pt.baseCost.."  |  $"..pt.monthly.."/mes", x+44, iy+36, w-60, "left")
            local btnW, btnH = 80, 20
            local btnX, btnY = x+w-btnW-20, iy+itemH-28
            local hov = self.lastMX >= btnX and self.lastMX <= btnX+btnW and self.lastMY >= btnY and self.lastMY <= btnY+btnH
            if canAfford then
                love.graphics.setColor(hov and {0.85,0.85,0.85} or W95.bg)
                love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
                self:drawBevel(btnX, btnY, btnW, btnH)
                love.graphics.setColor(W95.green)
                love.graphics.printf("Iniciar", btnX, btnY+4, btnW, "center")
                self.buttons[#self.buttons+1] = {x=btnX, y=btnY, w=btnW, h=btnH, action="start_project", index=i}
            else
                love.graphics.setColor(W95.textDim)
                love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
                self:drawBevel(btnX, btnY, btnW, btnH)
                love.graphics.setColor(W95.red)
                love.graphics.printf("Sin fondos", btnX, btnY+4, btnW, "center")
            end
        end
    end
    if #self.publishedApps > 0 then
        local mx, my, mw, mh = x+12, y+h-32, 120, 22
        local hov = self.lastMX >= mx and self.lastMX <= mx+mw and self.lastMY >= my and self.lastMY <= my+mh
        love.graphics.setColor(hov and {0.85,0.85,0.85} or W95.bg)
        love.graphics.rectangle("fill", mx, my, mw, mh)
        self:drawBevel(mx, my, mw, mh)
        love.graphics.setColor(W95.yellow)
        love.graphics.printf("Mis Apps ("..#self.publishedApps..")", mx, my+3, mw, "center")
        self.buttons[#self.buttons+1] = {x=mx, y=my, w=mw, h=mh, action="open_manage"}
    end
    local rx, ry, rw, rh = x+w-122, y+h-32, 110, 22
    local rhov = self.lastMX >= rx and self.lastMX <= rx+rw and self.lastMY >= ry and self.lastMY <= ry+rh
    if self.refreshAttempts > 0 then
        love.graphics.setColor(rhov and {0.85,0.85,0.85} or W95.bg)
        love.graphics.rectangle("fill", rx, ry, rw, rh)
        self:drawBevel(rx, ry, rw, rh)
        love.graphics.setColor(W95.text)
        love.graphics.printf("Refresh ("..self.refreshAttempts..")", rx, ry+3, rw, "center")
        self.buttons[#self.buttons+1] = {x=rx, y=ry, w=rw, h=rh, action="refresh"}
    else
        love.graphics.setColor(W95.textDim)
        love.graphics.rectangle("fill", rx, ry, rw, rh)
        self:drawBevel(rx, ry, rw, rh)
        love.graphics.setColor(W95.red)
        love.graphics.printf(math.ceil(self.refreshCooldown).."s", rx, ry+3, rw, "center")
    end
end

function Coding:drawCoding(x, y, w, h)
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", x+6, y+4, w-12, h-8)
    self:drawBevel(x+6, y+4, w-12, h-8)
    love.graphics.setColor(W95.text)
    love.graphics.printf("Codificando: "..(self.activeProject and self.activeProject.name or ""), x+8, y+8, w-16, "center")
    local hpR = math.min(self.projectProgress / self.projectMaxProgress, 1)
    local bx, by, bw, bh = x+20, y+28, w-40, 22
    local shake = self.barShake > 0 and (math.random()-0.5)*4 or 0
    love.graphics.setColor(W95.white)
    love.graphics.rectangle("fill", bx+shake, by, bw, bh)
    self:drawInset(bx+shake, by, bw, bh)
    local bc = hpR > 0.5 and W95.green or (hpR > 0.25 and W95.yellow or W95.red)
    love.graphics.setColor(bc)
    love.graphics.rectangle("fill", bx+2+shake, by+2, (bw-4)*hpR, bh-4)
    love.graphics.setColor(W95.white)
    love.graphics.printf(math.floor(self.projectProgress).."/"..self.projectMaxProgress, bx+shake, by+3, bw, "center")
    for _, target in ipairs(self.milestoneTargets) do
        local mx = bx + (bw-4) * target
        local passed = hpR >= target
        love.graphics.setColor(passed and {0.5,1,0.5} or {1,0.5,0.5})
        love.graphics.line(mx+shake, by-3, mx+shake, by+bh+3)
        love.graphics.setColor(passed and W95.green or W95.yellow)
        love.graphics.printf("V", mx+shake-12, by-14, 24, "center")
    end
    local infoY = by + bh + 4
    love.graphics.setColor(W95.text)
    love.graphics.print("Dias: "..math.ceil(self.projectDaysLeft).."/"..self.projectMaxDays, x+16, infoY)
    love.graphics.setColor(W95.green)
    love.graphics.print("Ingresos: $"..math.floor(self.moneySpent), x+w-100, infoY)
    local compY = infoY + 18
    local compW = (w-40) / math.max(1, #self.components)
    for i, comp in ipairs(self.components) do
        local cx = x + 16 + (i-1) * compW
        local vib = comp.vibration > 0 and (math.random()-0.5)*4 or 0
        love.graphics.setColor(W95.white)
        love.graphics.rectangle("fill", cx+vib, compY, compW-6, 50)
        self:drawBevel(cx+vib, compY, compW-6, 50)
        love.graphics.setColor(comp.color)
        love.graphics.rectangle("fill", cx+vib, compY, compW-6, 3)
        love.graphics.rectangle("fill", cx+vib, compY+47, compW-6, 3)
        love.graphics.setColor(W95.text)
        love.graphics.printf(comp.label, cx+vib, compY+5, compW-6, "center")
        love.graphics.setColor(W95.textDim)
        love.graphics.printf(comp.power.." pts", cx+vib, compY+18, compW-6, "center")
        love.graphics.printf(string.format("%.1fs", comp.interval), cx+vib, compY+30, compW-6, "center")
        comp.screenX = cx + compW/2
        comp.screenY = compY + 50
        comp.barX = bx + bw * hpR
        comp.barY = by + bh/2
    end
    for _, c in ipairs(self.circles) do
        love.graphics.setColor(0,0,0,0.3)
        love.graphics.circle("fill", c.x+2, c.y+2, c.radius)
        love.graphics.setColor(c.color)
        love.graphics.circle("fill", c.x, c.y, c.radius)
        love.graphics.setColor(0,0,0)
        love.graphics.circle("line", c.x, c.y, c.radius)
        love.graphics.setFont(self.circleFont)
        love.graphics.setColor(1,1,1)
        love.graphics.printf(c.power, c.x-16, c.y-8, 32, "center")
        love.graphics.setFont(self.smallFont)
    end
    for _, n in ipairs(self.floatingNumbers) do
        local alpha = n.timer / n.maxTimer
        love.graphics.setColor(n.isBug and {1,0.2,0.2,alpha} or {0.2,1,0.2,alpha})
        love.graphics.printf(n.text, n.x-30, n.y, 60, "center")
    end
    local btnW, btnH = 100, 24
    local cxBtnX, cxBtnY = x+w-btnW-16, y+h-36
    local cxHov = self.lastMX >= cxBtnX and self.lastMX <= cxBtnX+btnW and self.lastMY >= cxBtnY and self.lastMY <= cxBtnY+btnH
    love.graphics.setColor(cxHov and {0.85,0.85,0.85} or W95.bg)
    love.graphics.rectangle("fill", cxBtnX, cxBtnY, btnW, btnH)
    self:drawBevel(cxBtnX, cxBtnY, btnW, btnH)
    love.graphics.setColor(W95.red)
    love.graphics.printf("Cancelar", cxBtnX, cxBtnY+5, btnW, "center")
    self.buttons[#self.buttons+1] = {x=cxBtnX, y=cxBtnY, w=btnW, h=btnH, action="cancel_project"}
    love.graphics.setColor(W95.textDim)
    love.graphics.printf("Recuperas 30%", x+16, y+h-28, w/2-20, "left")
end

function Coding:drawMinigame(x, y, w, h)
    love.graphics.setColor({0.15, 0.16, 0.18})
    love.graphics.rectangle("fill", x+6, y+4, w-12, h-8)
    self:drawBevel(x+6, y+4, w-12, h-8)

    love.graphics.setColor(W95.text)
    love.graphics.printf("Codificando: "..(self.activeProject and self.activeProject.name or ""), x+8, y+8, w-16, "center")

    local hpR = math.min(self.projectProgress / self.projectMaxProgress, 1)
    local bx, by, bw, bh = x+16, y+24, w-32, 16
    love.graphics.setColor(W95.white)
    love.graphics.rectangle("fill", bx, by, bw, bh)
    self:drawInset(bx, by, bw, bh)
    local bc = hpR > 0.5 and W95.green or (hpR > 0.25 and W95.yellow or W95.red)
    love.graphics.setColor(bc)
    love.graphics.rectangle("fill", bx+2, by+2, (bw-4)*hpR, bh-4)
    love.graphics.setColor(W95.white)
    love.graphics.printf(math.floor(self.projectProgress).."/"..self.projectMaxProgress, bx, by+1, bw, "center")

    local infoY = by + bh + 4
    love.graphics.setColor(W95.textDim)
    love.graphics.print("Dias: "..math.ceil(self.projectDaysLeft).."/"..self.projectMaxDays, x+16, infoY)

    if self.snippetComplete then
        love.graphics.setColor(W95.green)
        love.graphics.printf("Snippet completado!", x+8, y+60, w-16, "center")
        love.graphics.setColor(W95.yellow)
        love.graphics.printf("+" .. self.snippetBonus .. " HP", x+8, y+80, w-16, "center")
        love.graphics.setColor(W95.text)
        love.graphics.printf("Combo maximo: x" .. self.maxCombo, x+8, y+100, w-16, "center")
        love.graphics.printf("Lineas completadas: " .. self.linesCompleted, x+8, y+120, w-16, "center")
        love.graphics.setColor(W95.textDim)
        love.graphics.printf("Presiona cualquier tecla para continuar", x+8, y+150, w-16, "center")
        return
    end

    local statusY = infoY + 16
    love.graphics.setColor(W95.yellow)
    if self.typingMode then
        love.graphics.printf("Escribe esta linea:", x+8, statusY, w-16, "center")
    else
        love.graphics.setColor({0.5, 1, 0.5})
        love.graphics.printf("Continua escribiendo...", x+8, statusY, w-16, "center")
    end

    local comboText = "Combo: x" .. self.combo
    local comboColor = W95.textDim
    if self.combo >= 10 then comboColor = {1, 0.5, 0}
    elseif self.combo >= 5 then comboColor = W95.yellow
    elseif self.combo >= 1 then comboColor = W95.green end
    love.graphics.setColor(comboColor)
    love.graphics.printf(comboText, x+8, statusY, w-16, "right")

    local codeX, codeY, codeW, codeH = x+12, statusY+16, w-24, h-statusY-36
    self.codeH = codeH
    love.graphics.setColor({0.1,0.1,0.1})
    love.graphics.rectangle("fill", codeX, codeY, codeW, codeH)
    self:drawBevel(codeX, codeY, codeW, codeH)
    Screen.setScissor(codeX+1, codeY+1, codeW-2, codeH-2)

    love.graphics.setFont(self.codeFont)
    local lineH = 16
    local maxLines = math.floor((codeH-4) / lineH)
    local totalLines = #self.codeLines
    local startLine = math.max(1, totalLines - maxLines + 1)
    local endLine = totalLines

    local kw = {"if","else","for","while","return","function","class","def","import","from","const","let","var","int","char","void","struct","typedef","include","define","printf","malloc","free"}

    for i = startLine, endLine do
        local ly = codeY + 2 + (i - startLine) * lineH
        love.graphics.setColor({0.4,0.4,0.4})
        love.graphics.printf(i, codeX+4, ly, 30, "right")

        local txt = self.codeLines[i] or ""
        local isCurrentTyping = self.typingMode and i == #self.codeLines

        if isCurrentTyping then
            love.graphics.setColor({0.2, 0.3, 0.2})
            love.graphics.rectangle("fill", codeX+34, ly-1, codeW-38, lineH)
        end

        if #txt > 0 then
            local toks, cur = {}, ""
            for c in txt:gmatch(".") do
                if c:match("[%s%(%)%[%]{};,:%.]") then
                    if #cur > 0 then toks[#toks+1]=cur; cur="" end
                    toks[#toks+1]=c
                else cur = cur..c end
            end
            if #cur > 0 then toks[#toks+1]=cur end
            local dx = codeX + 38
            for _, tk in ipairs(toks) do
                local col = {0.97,0.97,0.94}
                if tk:match("^%d+$") then col = {0.68,0.45,0.97}
                elseif tk:match('".*"') or tk:match("'.*'") then col = {0.90,0.78,0.35}
                elseif tk:match("^//") or tk:match("^#") then col = {0.50,0.52,0.54}
                else for _, k in ipairs(kw) do if tk == k then col = {0.98,0.45,0.36}; break end end end
                love.graphics.setColor(col)
                love.graphics.print(tk, dx, ly)
                dx = dx + self.codeFont:getWidth(tk)
            end
        end

        if isCurrentTyping and self.typingMode then
            local typedPart = self.typedChars
            local remainingPart = self.currentTypingLine:sub(#typedPart + 1)
            local typedW = self.codeFont:getWidth(typedPart)
            local baseX = codeX + 38

            if #typedPart > 0 then
                love.graphics.setColor(self.typingError and {1, 0.3, 0.3} or {0.3, 1, 0.3})
                love.graphics.print(typedPart, baseX, ly)
            end

            if #remainingPart > 0 then
                love.graphics.setColor({0.6, 0.6, 0.6})
                love.graphics.print(remainingPart, baseX + typedW, ly)
            end

            if math.floor(self.cursorBlink*2)%2 == 0 then
                love.graphics.setColor({0.97,0.97,0.94})
                love.graphics.rectangle("fill", baseX + typedW, ly, 8, 14)
            end
        end
    end

    Screen.setScissor()

    love.graphics.setColor(W95.textDim)
    love.graphics.setFont(self.smallFont)
    if self.typingMode then
        love.graphics.printf("Escribe cada caracter correctamente", x+12, y+h-28, w-24, "center")
    else
        love.graphics.printf("Presiona ENTER para continuar", x+12, y+h-28, w-24, "center")
    end

    local btnW, btnH = 80, 18
    local btnX, btnY = x+w-btnW-12, y+h-20
    local hov = self.lastMX >= btnX and self.lastMX <= btnX+btnW and self.lastMY >= btnY and self.lastMY <= btnY+btnH
    love.graphics.setColor(hov and {0.85,0.85,0.85} or W95.bg)
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
    self:drawBevel(btnX, btnY, btnW, btnH)
    love.graphics.setColor(W95.red)
    love.graphics.printf("Cancelar", btnX, btnY+2, btnW, "center")
    self.buttons[#self.buttons+1] = {x=btnX, y=btnY, w=btnW, h=btnH, action="cancel_project"}
end

function Coding:drawSell(x, y, w, h)
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", x+6, y+4, w-12, h-8)
    self:drawBevel(x+6, y+4, w-12, h-8)
    love.graphics.setColor(W95.green)
    love.graphics.printf("Proyecto Completado!", x+8, y+20, w-16, "center")
    love.graphics.setColor(W95.text)
    love.graphics.printf(self.activeProject and self.activeProject.name or "", x+8, y+45, w-16, "center")
    love.graphics.setColor(W95.yellow)
    love.graphics.printf("XP ganado: +"..(self.activeProject and math.floor(self.activeProject.reward/5) or 0), x+8, y+65, w-16, "center")
    local btnW, btnH = 160, 32
    local btnX, btnY = x+(w-btnW)/2, y+100
    local hov = self.lastMX >= btnX and self.lastMX <= btnX+btnW and self.lastMY >= btnY and self.lastMY <= btnY+btnH
    love.graphics.setColor(hov and {0.85,0.85,0.85} or W95.bg)
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
    self:drawBevel(btnX, btnY, btnW, btnH)
    love.graphics.setColor(W95.green)
    love.graphics.printf("Vender App", btnX, btnY+8, btnW, "center")
    self.buttons[#self.buttons+1] = {x=btnX, y=btnY, w=btnW, h=btnH, action="sell_app"}
end

function Coding:drawManage(x, y, w, h)
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", x+6, y+4, w-12, h-8)
    self:drawBevel(x+6, y+4, w-12, h-8)
    love.graphics.setColor(W95.text)
    love.graphics.printf("Mis Aplicaciones", x+8, y+8, w-16, "center")
    if #self.publishedApps == 0 then
        love.graphics.setColor(W95.textDim)
        love.graphics.printf("No tienes apps publicadas.", x+8, y+50, w-16, "center")
        local bw, bh = 80, 22
        local bx, by = x+(w-bw)/2, y+h-34
        local hov = self.lastMX >= bx and self.lastMX <= bx+bw and self.lastMY >= by and self.lastMY <= by+bh
        love.graphics.setColor(hov and {0.85,0.85,0.85} or W95.bg)
        love.graphics.rectangle("fill", bx, by, bw, bh)
        self:drawBevel(bx, by, bw, bh)
        love.graphics.setColor(W95.text)
        love.graphics.printf("Volver", bx, by+3, bw, "center")
        self.buttons[#self.buttons+1] = {x=bx, y=by, w=bw, h=bh, action="back_browse"}
        return
    end
    local itemH = 60
    for i, app in ipairs(self.publishedApps) do
        local iy = y + 28 + (i-1) * (itemH + 8)
        if iy + itemH < y + h - 40 then
            love.graphics.setColor(W95.bg)
            love.graphics.rectangle("fill", x+12, iy, w-24, itemH)
            self:drawBevel(x+12, iy, w-24, itemH)
            love.graphics.setColor(W95.text)
            love.graphics.print(app.name, x+20, iy+4)
            local status = app.selling and ("Vendiendo ("..app.monthsLeft.." meses)") or "Retirada"
            love.graphics.setColor(app.selling and W95.green or W95.textDim)
            love.graphics.print(status, x+20, iy+18)
            love.graphics.setColor(W95.yellow)
            love.graphics.print("Total: $"..app.totalRevenue, x+20, iy+32)
            if app.selling then
                local uw, uh = 60, 16
                local ux, uy = x+w-uw-20, iy+4
                local uhov = self.lastMX >= ux and self.lastMX <= ux+uw and self.lastMY >= uy and self.lastMY <= uy+uh
                if (app.updateCooldown or 0) >= 4 then
                    love.graphics.setColor(uhov and {0.85,0.85,0.85} or W95.bg)
                    love.graphics.rectangle("fill", ux, uy, uw, uh)
                    self:drawBevel(ux, uy, uw, uh)
                    love.graphics.setColor(W95.green)
                    love.graphics.printf("Update", ux, uy+1, uw, "center")
                    self.buttons[#self.buttons+1] = {x=ux, y=uy, w=uw, h=uh, action="do_update", index=i}
                else
                    love.graphics.setColor(W95.textDim)
                    love.graphics.print("Update: "..(4-(app.updateCooldown or 0)).." meses", x+w-110, iy+18)
                end
                local cw, ch = 60, 16
                local cxBtnX, cxBtnY = x+w-cw-20, iy+24
                local chov = self.lastMX >= cxBtnX and self.lastMX <= cxBtnX+cw and self.lastMY >= cxBtnY and self.lastMY <= cxBtnY+ch
                love.graphics.setColor(chov and {0.85,0.85,0.85} or W95.bg)
                love.graphics.rectangle("fill", cxBtnX, cxBtnY, cw, ch)
                self:drawBevel(cxBtnX, cxBtnY, cw, ch)
                love.graphics.setColor(W95.red)
                love.graphics.printf("Quitar", cxBtnX, cxBtnY+1, cw, "center")
                self.buttons[#self.buttons+1] = {x=cxBtnX, y=cxBtnY, w=cw, h=ch, action="cancel_sale", index=i}
            end
        end
    end
    local bw, bh = 80, 22
    local bx, by = x+12, y+h-34
    local hov = self.lastMX >= bx and self.lastMX <= bx+bw and self.lastMY >= by and self.lastMY <= by+bh
    love.graphics.setColor(hov and {0.85,0.85,0.85} or W95.bg)
    love.graphics.rectangle("fill", bx, by, bw, bh)
    self:drawBevel(bx, by, bw, bh)
    love.graphics.setColor(W95.text)
    love.graphics.printf("Volver", bx, by+3, bw, "center")
    self.buttons[#self.buttons+1] = {x=bx, y=by, w=bw, h=bh, action="back_browse"}
end

function Coding:mousemoved(mx, my)
    self.lastMX = mx
    self.lastMY = my
    self.window:mousemoved(mx, my)
end

function Coding:mousereleased(x, y, button)
    self.window:mousereleased(x, y, button)
end

function Coding:draw()
    self.lastMX, self.lastMY = love.mouse.getPosition()
    self.window:drawFrame()
end

function Coding:hitTest(mx, my)
    return self.window:hitTest(mx, my)
end

function Coding:mousepressed(x, y, button)
    return self.window:mousepressed(x, y, button)
end

function Coding:textinput(text)
    if self.state ~= "coding" or not self.milestoneActive or self.snippetComplete then return end
    if not self.typingMode then return end
    if self.typingErrorTimer > 0 then return end
    local expectedChar = self.currentTypingLine:sub(#self.typedChars + 1, #self.typedChars + 1)
    if text == expectedChar then
        self.typedChars = self.typedChars .. text
        self.codeCharIndex = #self.typedChars
        self.typingError = false
        if #self.typedChars >= #self.currentTypingLine then
            self:completeTypingLine()
        end
    else
        self.typingError = true
        self.typingErrorTimer = 0.3
        self.combo = 0
    end
end

return Coding