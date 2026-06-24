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

    self.trabajoRef = nil
    self.explorerRef = nil
    self.emailRef = nil
    self.personalUnlocked = false

    self.objectives = {
        {id = "money20", text = "Genera $20", done = false, shown = true},
        {id = "firstUpgrade", text = "Compra tu primer upgrade", done = false, shown = false},
        {id = "firstProject", text = "Termina un proyecto exitosamente", done = false, shown = false},
        {id = "work20", text = "Trabaja 20 veces", done = false, shown = false},
        {id = "money200", text = "Genera $200 en total", done = false, shown = false},
    }

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
    local hasUpgrade = false
    if self.explorerRef then
        for stat, level in pairs(self.explorerRef.upgradeLevels) do
            if level > 0 then
                hasUpgrade = true
                break
            end
        end
    end
    local tasksDone = self.trabajoRef.tasksCompleted or 0
    local hasCompletedProject = self.trabajoRef.completedProjects and self.trabajoRef.completedProjects > 0

    for i, obj in ipairs(self.objectives) do
        if not obj.done then
            if obj.id == "money20" and money >= 20 then
                obj.done = true
                self:unlockNext(i)
            elseif obj.id == "firstUpgrade" and hasUpgrade then
                obj.done = true
                self:unlockNext(i)
            elseif obj.id == "firstProject" and hasCompletedProject then
                obj.done = true
                self:unlockNext(i)
                if self.emailRef and not self.personalEmailSent then
                    self.personalEmailSent = true
                    self.emailRef:addEmailToInbox({
                        subject = "Nuevo: Departamento de Personal",
                        sender = "admin@empresa.com",
                        type = "news",
                        body = "Estimado freelancer:\n\nFelicidades por completar\nsu primer proyecto!\n\nAhora puede contratar personal\npara que trabajen por usted.\n\nNuevo icono disponible:\n'Personal' en el escritorio.\n\nSus empleados generaran\ndinero automaticamente.\n\nSaludos cordiales.",
                    })
                end
            elseif obj.id == "work20" and tasksDone >= 20 then
                obj.done = true
                self:unlockNext(i)
                if self.emailRef and not self.personalUnlocked then
                    self.personalUnlocked = true
                    self.emailRef:addEmailToInbox({
                        subject = "Nuevo: Departamento de Personal",
                        sender = "admin@empresa.com",
                        type = "personal_unlock",
                        body = "Estimado freelancer:\n\nHa completado 20 tareas!\nAhora puede contratar personal\npara que trabajen por usted.\n\nDescargue la aplicacion\n'Personal' desde este correo.\n\nSus empleados generaran\ndinero automaticamente.\n\nSaludos cordiales.",
                    })
                end
            elseif obj.id == "money200" and money >= 200 then
                obj.done = true
                self:unlockNext(i)
            end
        end
    end
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
    local smallFont = love.graphics.newFont(11)
    love.graphics.setFont(smallFont)

    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", cx, cy, cw, ch)
    self:drawInset(cx, cy, cw, ch)

    love.graphics.setScissor(cx + 2, cy + 2, cw - 4, ch - 4)

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

    love.graphics.setScissor()
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
