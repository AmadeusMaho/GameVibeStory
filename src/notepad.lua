local Screen = require("src.screen")
local Notepad = {}
Notepad.__index = Notepad

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
}

function Notepad.new(x, y)
    local self = setmetatable({}, Notepad)
    self.window = WindowManager.new("Objetivos", x or 150, y or 100, 420, 320)

    self.smallFont = love.graphics.newFont(11)
    self.notifFont = love.graphics.newFont(12)

    self.trabajoRef = nil
    self.explorerRef = nil
    self.emailRef = nil
    self.personalUnlocked = false
    self.onGoalComplete = nil

    self.objectives = {
        {id = "work5", text = "Trabaja 5 veces", done = false, shown = true},
        {id = "money20", text = "Gana $20 en total", done = false, shown = false},
        {id = "work15", text = "Trabaja 15 veces", done = false, shown = false},
        {id = "firstProject", text = "Termina un proyecto exitosamente", done = false, shown = false},
        {id = "money300", text = "Gana $300 en total", done = false, shown = false},
        {id = "work30", text = "Trabaja 30 veces", done = false, shown = false},
        {id = "money750", text = "Gana $750 en total", done = false, shown = false},
    }

    self.pendingNotifications = {}

    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, x, y, button)
        return self:handleClick(x, y, button)
    end

    return self
end

function Notepad:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function Notepad:update(dt)
    if not self.trabajoRef then return end

    local money = self.trabajoRef.totalEarned or 0
    local tasksDone = self.trabajoRef.tasksCompleted or 0
    local hasCompletedProject = self.trabajoRef.completedProjects and self.trabajoRef.completedProjects > 0

    for i, obj in ipairs(self.objectives) do
        if not obj.done then
            if obj.id == "work5" and tasksDone >= 5 then
                obj.done = true
                self:unlockNext(i)
                self:addNotification("Objetivo Completado!", obj.text)
                if self.onGoalComplete then self.onGoalComplete(obj.id, i) end
            elseif obj.id == "money20" and money >= 20 then
                obj.done = true
                self:unlockNext(i)
                self:addNotification("Objetivo Completado!", obj.text)
                if self.onGoalComplete then self.onGoalComplete(obj.id, i) end
            elseif obj.id == "work15" and tasksDone >= 15 then
                obj.done = true
                self:unlockNext(i)
                self:addNotification("Objetivo Completado!", obj.text)
                if self.onGoalComplete then self.onGoalComplete(obj.id, i) end
            elseif obj.id == "firstProject" and hasCompletedProject then
                obj.done = true
                self:unlockNext(i)
                self:addNotification("Objetivo Completado!", obj.text)
                if self.onGoalComplete then self.onGoalComplete(obj.id, i) end
            elseif obj.id == "money300" and money >= 300 then
                obj.done = true
                self:unlockNext(i)
                self:addNotification("Objetivo Completado!", obj.text)
                if self.onGoalComplete then self.onGoalComplete(obj.id, i) end
            elseif obj.id == "work30" and tasksDone >= 30 then
                obj.done = true
                self:unlockNext(i)
                self:addNotification("Objetivo Completado!", obj.text)
                if self.onGoalComplete then self.onGoalComplete(obj.id, i) end
            elseif obj.id == "money750" and money >= 750 then
                obj.done = true
                self:unlockNext(i)
                self:addNotification("Objetivo Completado!", obj.text)
                if self.onGoalComplete then self.onGoalComplete(obj.id, i) end
            end
        end
    end

    for i = #self.pendingNotifications, 1, -1 do
        self.pendingNotifications[i].timer = self.pendingNotifications[i].timer - dt
        if self.pendingNotifications[i].timer <= 0 then
            table.remove(self.pendingNotifications, i)
        end
    end
end

function Notepad:addNotification(title, text)
    table.insert(self.pendingNotifications, {
        title = title,
        text = text,
        timer = 4.0,
    })
end

function Notepad:unlockNext(currentIndex)
    local nextObj = self.objectives[currentIndex + 1]
    if nextObj then
        nextObj.shown = true
    end
end

function Notepad:drawContent(cx, cy, cw, ch)
    self.buttons = {}

    local prevFont = love.graphics.getFont()
    love.graphics.setFont(self.smallFont)

    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", cx, cy, cw, ch)
    self:drawInset(cx, cy, cw, ch)

    Screen.setScissor(cx + 2, cy + 2, cw - 4, ch - 4)

    local money = 0
    if self.trabajoRef then
        money = self.trabajoRef.totalEarned or 0
    end

    local y = cy + 16
    local lineH = 22

    love.graphics.setColor(W95.highlight)
    love.graphics.printf("=== OBJETIVOS ===", cx, y, cw, "center")
    y = y + lineH + 6

    for _, obj in ipairs(self.objectives) do
        if obj.shown then
            local check = obj.done and "[X]" or "[ ]"
            if obj.done then
                love.graphics.setColor(W95.green)
            else
                love.graphics.setColor(W95.text)
            end
            love.graphics.print("  " .. check .. "  " .. obj.text, cx + 16, y)
            y = y + lineH
        end
    end

    y = y + 12
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(cx + 16, y, cx + cw - 16, y)
    y = y + 10

    love.graphics.setColor(W95.textDim)
    love.graphics.print("  Dinero total: $" .. money, cx + 16, y)

    Screen.setScissor()
    love.graphics.setFont(prevFont)
end

function Notepad:drawInset(x, y, w, h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Notepad:handleClick(x, y, button)
    return true
end

function Notepad:drawNotifications()
    local prevFont = love.graphics.getFont()
    love.graphics.setFont(self.notifFont)

    local screenW, screenH = Screen.getWidth(), Screen.getHeight()

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
            local notifY = 130 + (i - 1) * (notifH + 10)

            love.graphics.setColor(0, 0, 0, alpha * 0.5)
            love.graphics.rectangle("fill", notifX + 2, notifY + 2, notifW, notifH, 4, 4)

            love.graphics.setColor(0.1, 0.1, 0.1, alpha)
            love.graphics.rectangle("fill", notifX, notifY, notifW, notifH, 4, 4)

            love.graphics.setColor(W95.highlight[1], W95.highlight[2], W95.highlight[3], alpha)
            love.graphics.rectangle("line", notifX, notifY, notifW, notifH, 4, 4)

            love.graphics.setColor(W95.highlight[1], W95.highlight[2], W95.highlight[3], alpha)
            love.graphics.printf(notif.title, notifX, notifY + 6, notifW, "center")

            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.printf(notif.text, notifX, notifY + 24, notifW, "center")
        else
            table.remove(self.pendingNotifications, i)
        end
    end

    love.graphics.setFont(prevFont)
end

function Notepad:draw(mx, my)
    self.window:drawFrame()
end

function Notepad:hitTest(mx, my)
    return self.window:hitTest(mx, my)
end

function Notepad:mousepressed(x, y, button)
    return self.window:mousepressed(x, y, button)
end

function Notepad:mousereleased(x, y, button)
    self.window:mousereleased(x, y, button)
end

function Notepad:mousemoved(x, y)
    self.window:mousemoved(x, y)
end

return Notepad
