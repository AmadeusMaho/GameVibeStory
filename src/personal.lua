local Personal = {}
Personal.__index = Personal

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
}

local employeeTypes = {
    {
        id = "pasante",
        name = "Pasante",
        desc = "Estudiante universitario.\nLento pero barato.",
        baseCost = 75,
        baseIncome = 1,
        costMult = 1.18,
        icon = "Pas",
    },
    {
        id = "tecnico",
        name = "Tecnico",
        desc = "Tecnico en computacion.\nRendimiento medio.",
        baseCost = 350,
        baseIncome = 4,
        costMult = 1.22,
        icon = "Tec",
    },
    {
        id = "programador",
        name = "Programador",
        desc = "Programador experiente.\nBuen rendimiento.",
        baseCost = 2000,
        baseIncome = 15,
        costMult = 1.25,
        icon = "Prog",
    },
    {
        id = "gerente",
        name = "Gerente",
        desc = "Gerente de proyecto.\nGenera mucho dinero.",
        baseCost = 12000,
        baseIncome = 60,
        costMult = 1.28,
        icon = "Ger",
    },
    {
        id = "director",
        name = "Director",
        desc = "Director ejecutivo.\nLa elite del negocio.",
        baseCost = 80000,
        baseIncome = 250,
        costMult = 1.30,
        icon = "Dir",
    },
}

function Personal.new(x, y)
    local self = setmetatable({}, Personal)
    self.window = WindowManager.new("Personal - Empleados", x or 200, y or 100, 440, 380)

    self.trabajoRef = nil
    self.employees = {}
    self.totalIncome = 0
    self.incomeTimer = 0
    self.incomeInterval = 1.0

    for _, empType in ipairs(employeeTypes) do
        self.employees[empType.id] = {
            count = 0,
            cost = empType.baseCost,
        }
    end

    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, x, y, button)
        return self:handleClick(x, y, button)
    end

    return self
end

function Personal:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function Personal:update(dt)
    if not self.trabajoRef then return end

    self.incomeTimer = self.incomeTimer + dt
    if self.incomeTimer >= self.incomeInterval then
        self.incomeTimer = self.incomeTimer - self.incomeInterval
        local income = self:getTotalIncome()
        if income > 0 then
            self.trabajoRef.money = self.trabajoRef.money + income
            self.trabajoRef.totalEarned = self.trabajoRef.totalEarned + income
        end
    end
end

function Personal:getTotalIncome()
    local total = 0
    for _, empType in ipairs(employeeTypes) do
        local emp = self.employees[empType.id]
        if emp and emp.count > 0 then
            total = total + emp.count * empType.baseIncome
        end
    end
    return total
end

function Personal:getNextCost(empType)
    local emp = self.employees[empType.id]
    local count = emp and emp.count or 0
    return math.floor(empType.baseCost * math.pow(empType.costMult, count))
end

function Personal:hireEmployee(empTypeId)
    if not self.trabajoRef then return end

    local empType = nil
    for _, et in ipairs(employeeTypes) do
        if et.id == empTypeId then
            empType = et
            break
        end
    end
    if not empType then return end

    local cost = self:getNextCost(empType)
    if self.trabajoRef.money < cost then
        return false, "Dinero insuficiente"
    end

    self.trabajoRef.money = self.trabajoRef.money - cost
    local emp = self.employees[empTypeId]
    emp.count = emp.count + 1
    emp.cost = self:getNextCost(empType)

    return true, empType.name .. " contratado!"
end

function Personal:drawBevel(x, y, w, h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Personal:drawInset(x, y, w, h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Personal:drawContent(cx, cy, cw, ch)
    self.buttons = {}
    local prevFont = love.graphics.getFont()
    local smallFont = love.graphics.newFont(11)
    love.graphics.setFont(smallFont)

    love.graphics.setColor(W95.text)
    love.graphics.printf("Departamento de Personal", cx + 8, cy + 6, cw - 16, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(cx + 8, cy + 22, cx + cw - 8, cy + 22)

    local income = self:getTotalIncome()
    love.graphics.setColor(W95.green)
    love.graphics.print("Ingreso por segundo: $" .. income, cx + 12, cy + 28)

    local money = self.trabajoRef and self.trabajoRef.money or 0
    love.graphics.setColor(W95.text)
    love.graphics.print("Dinero: $" .. money, cx + 12, cy + 44)

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(cx + 8, cy + 62, cx + cw - 8, cy + 62)

    local tableX = cx + 8
    local tableY = cy + 68
    local colW = {80, 50, 90, 70, 80}
    local rowH = 22

    love.graphics.setColor(W95.highlight)
    love.graphics.rectangle("fill", tableX, tableY, cw - 16, rowH)
    love.graphics.setColor(W95.highlightText)
    local headers = {"Empleado", "Cantidad", "Genera/uno", "Costo", "Contratar"}
    local hx = tableX + 4
    for i, header in ipairs(headers) do
        love.graphics.print(header, hx, tableY + 5)
        hx = hx + colW[i]
    end

    for i, empType in ipairs(employeeTypes) do
        local ry = tableY + rowH + (i - 1) * (rowH + 4)
        local isEven = i % 2 == 0

        if isEven then
            love.graphics.setColor({0.92, 0.92, 0.92})
            love.graphics.rectangle("fill", tableX, ry, cw - 16, rowH + 4)
        end

        local emp = self.employees[empType.id]
        local cost = self:getNextCost(empType)
        local canAfford = self.trabajoRef and self.trabajoRef.money >= cost

        love.graphics.setColor(W95.text)
        love.graphics.print(empType.name, tableX + 4, ry + 4)

        love.graphics.setColor(emp.count > 0 and W95.green or W95.textDim)
        love.graphics.print(tostring(emp.count), tableX + 4 + colW[1], ry + 4)

        love.graphics.setColor(W95.green)
        love.graphics.print("$" .. empType.baseIncome .. "/s", tableX + 4 + colW[1] + colW[2], ry + 4)

        love.graphics.setColor(canAfford and {0.8, 0, 0} or W95.textDim)
        love.graphics.print("$" .. cost, tableX + 4 + colW[1] + colW[2] + colW[3], ry + 4)

        local btnW = 60
        local btnH = 18
        local btnX = tableX + 4 + colW[1] + colW[2] + colW[3] + colW[4]
        local btnY = ry + 3

        local btnHovered = self.lastMX >= btnX and self.lastMX <= btnX + btnW and self.lastMY >= btnY and self.lastMY <= btnY + btnH
        love.graphics.setColor(canAfford and (btnHovered and {0.85, 0.85, 0.85} or W95.bg) or {0.7, 0.7, 0.7})
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
        self:drawBevel(btnX, btnY, btnW, btnH)
        love.graphics.setColor(canAfford and W95.text or W95.textDim)
        love.graphics.printf("Contratar", btnX, btnY + 3, btnW, "center")

        if canAfford then
            table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "hire", empId = empType.id})
        end
    end

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(cx + 8, tableY + rowH + #employeeTypes * (rowH + 4) + 4, cx + cw - 8, tableY + rowH + #employeeTypes * (rowH + 4) + 4)

    love.graphics.setColor(W95.textDim)
    love.graphics.printf("Los empleados generan dinero automaticamente.", cx + 8, cy + ch - 20, cw - 16, "center")

    love.graphics.setFont(prevFont)
end

function Personal:handleClick(x, y, button)
    if button ~= 1 then return false end

    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "hire" then
                local ok, msg = self:hireEmployee(btn.empId)
                if msg then
                    self.resultMessage = msg
                    self.resultTimer = 2.0
                end
            end
            return true
        end
    end
    return true
end

function Personal:draw(mx, my)
    self.lastMX = mx
    self.lastMY = my
    self.window:drawFrame()
end

function Personal:hitTest(mx, my)
    return self.window:hitTest(mx, my)
end

function Personal:mousepressed(x, y, button)
    return self.window:mousepressed(x, y, button)
end

function Personal:mousereleased(x, y, button)
    self.window:mousereleased(x, y, button)
end

function Personal:mousemoved(x, y)
    self.window:mousemoved(x, y)
end

return Personal
