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
}

local tasks = {
    {name = "Entrada de datos", reward = 5, time = 1.0},
    {name = "Correccion de documentos", reward = 8, time = 1.5},
    {name = "Clasificacion de archivos", reward = 4, time = 0.8},
    {name = "Revision de facturas", reward = 6, time = 1.2},
    {name = "Digitacion de formularios", reward = 7, time = 1.3},
    {name = "Procesamiento de nominas", reward = 10, time = 2.0},
    {name = "Inventario de equipo", reward = 5, time = 1.0},
    {name = "Archivo de correspondencia", reward = 3, time = 0.6},
}

function Trabajo.new(x, y)
    local self = setmetatable({}, Trabajo)
    self.window = WindowManager.new("Trabajo Freelance", x or 250, y or 120, 360, 240)

    self.money = 0
    self.totalEarned = 0
    self.tasksCompleted = 0
    self.currentTask = nil
    self.taskProgress = 0
    self.cooldown = 0
    self.cooldownMax = 0.3
    self.level = 1
    self.baseReward = 5
    self.onWorkDone = nil

    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, x, y, button)
        return self:handleClick(x, y, button)
    end

    return self
end

function Trabajo:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function Trabajo:update(dt)
    if self.cooldown > 0 then
        self.cooldown = self.cooldown - dt
    end

    if self.currentTask then
        self.taskProgress = self.taskProgress + dt
        if self.taskProgress >= self.currentTask.time then
            local reward = self.currentTask.reward + (self.level - 1) * 2
            self.money = self.money + reward
            self.totalEarned = self.totalEarned + reward
            self.tasksCompleted = self.tasksCompleted + 1
            self.currentTask = nil
            self.taskProgress = 0
            self.cooldown = self.cooldownMax
            if self.onWorkDone then self.onWorkDone() end
        end
    end
end

function Trabajo:getEarningsPerClick()
    return self.baseReward + (self.level - 1) * 2
end

function Trabajo:drawContent(cx, cy, cw, ch)
    self.buttons = {}

    local prevFont = love.graphics.getFont()
    local smallFont = love.graphics.newFont(11)
    love.graphics.setFont(smallFont)

    love.graphics.setColor(W95.text)
    love.graphics.printf("Trabajo Freelance", cx + 8, cy + 12, cw - 16, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(cx + 8, cy + 32, cx + cw - 8, cy + 32)

    love.graphics.setColor(W95.text)
    love.graphics.print("Tareas completadas: " .. self.tasksCompleted, cx + 16, cy + 42)
    love.graphics.setColor(W95.green)
    love.graphics.print("Dinero: $" .. self.money, cx + 16, cy + 60)

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(cx + 8, cy + 80, cx + cw - 8, cy + 80)

    if self.currentTask then
        love.graphics.setColor(W95.text)
        love.graphics.printf("Trabajando en:", cx + 8, cy + 92, cw - 16, "center")
        love.graphics.setColor(W95.highlight)
        love.graphics.printf(self.currentTask.name, cx + 8, cy + 108, cw - 16, "center")

        local barX = cx + 30
        local barY = cy + 130
        local barW = cw - 60
        local barH = 22

        love.graphics.setColor(W95.fieldBg)
        love.graphics.rectangle("fill", barX, barY, barW, barH)
        self:drawInset(barX, barY, barW, barH)

        local progress = math.min(self.taskProgress / self.currentTask.time, 1)
        love.graphics.setColor(W95.highlight)
        love.graphics.rectangle("fill", barX + 2, barY + 2, (barW - 4) * progress, barH - 4)

        love.graphics.setColor(W95.white)
        love.graphics.printf(math.floor(progress * 100) .. "%", barX, barY + 4, barW, "center")

        local cancelW = 80
        local cancelX = cx + (cw - cancelW) / 2
        local cancelY = cy + 160
        local mx, my = love.mouse.getPosition()
        local cancelHov = mx >= cancelX and mx <= cancelX + cancelW and my >= cancelY and my <= cancelY + 22

        love.graphics.setColor(cancelHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", cancelX, cancelY, cancelW, 22)
        self:drawBevel(cancelX, cancelY, cancelW, 22)
        love.graphics.setColor(W95.red)
        love.graphics.printf("Cancelar", cancelX, cancelY + 4, cancelW, "center")
        table.insert(self.buttons, {x = cancelX, y = cancelY, w = cancelW, h = 22, action = "cancel"})
    else
        local earnings = self:getEarningsPerClick()

        love.graphics.setColor(W95.text)
        love.graphics.printf("Ganancia por tarea: $" .. earnings, cx + 8, cy + 92, cw - 16, "center")

        local btnW = 160
        local btnH = 36
        local btnX = cx + (cw - btnW) / 2
        local btnY = cy + 116
        local mx, my = love.mouse.getPosition()
        local btnHov = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH

        if self.cooldown > 0 then
            love.graphics.setColor(W95.textDim)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
            self:drawBevel(btnX, btnY, btnW, btnH)
            love.graphics.setColor(W95.textDim)
            love.graphics.printf("Esperar...", btnX, btnY + 11, btnW, "center")
        else
            love.graphics.setColor(btnHov and {0.85, 0.85, 0.85} or W95.bg)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
            self:drawBevel(btnX, btnY, btnW, btnH)
            love.graphics.setColor(W95.green)
            love.graphics.printf("Trabajar", btnX, btnY + 11, btnW, "center")
            table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "work"})
        end

        love.graphics.setColor(W95.borderDark)
        love.graphics.line(cx + 8, cy + 166, cx + cw - 8, cy + 166)

        love.graphics.setColor(W95.textDim)
        love.graphics.print("Nivel: " .. self.level, cx + 16, cy + 176)
        love.graphics.print("Mejore su CPU para ganar mas", cx + 16, cy + 192)
    end

    love.graphics.setFont(prevFont)
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

function Trabajo:handleClick(x, y, button)
    if button ~= 1 then return false end

    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "work" and self.cooldown <= 0 and not self.currentTask then
                self.currentTask = tasks[math.random(#tasks)]
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
