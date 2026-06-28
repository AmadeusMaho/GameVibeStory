local MyPC = {}
MyPC.__index = MyPC

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
    fieldBorder = {0.5, 0.5, 0.5},
    tabActive = {0.75, 0.75, 0.75},
    tabInactive = {0.65, 0.65, 0.65},
    highlight = {0, 0, 0.5},
    highlightText = {1, 1, 1},
    groupBg = {0.75, 0.75, 0.75},
}

function MyPC.new(x, y)
    local self = setmetatable({}, MyPC)
    self.window = WindowManager.new("Propiedades de sistema", x or 120, y or 80, 420, 380)

    self.selectedTab = 1
    self.tabs = {
        {label = "General", id = "general"},
        {label = "Administrador de dispositivos", id = "devices"},
        {label = "Perf. del sistema", id = "performance"},
    }

    self.smallFont = love.graphics.newFont(11)

    self.pcStats = nil
    self.upgradesRef = nil
    self.explorerRef = nil

    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, x, y, button)
        return self:handleClick(x, y, button)
    end

    return self
end

function MyPC:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function MyPC:update(dt)
end

function MyPC:drawBevel(x, y, w, h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function MyPC:drawInset(x, y, w, h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function MyPC:drawContent(cx, cy, cw, ch)
    self.buttons = {}

    local prevFont = love.graphics.getFont()

    love.graphics.setFont(self.smallFont)

    local tabY = cy + 8
    local tabH = 22
    local tabStartX = cx + 10
    local tabW = 105

    for i, tab in ipairs(self.tabs) do
        local tx = tabStartX + (i - 1) * (tabW + 2)
        local isActive = (i == self.selectedTab)

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
            love.graphics.line(tx, tabY + 4, tx, tabY + tabH)
            love.graphics.setColor(W95.borderDark)
            love.graphics.line(tx + tabW, tabY + 4, tx + tabW, tabY + tabH)
        end

        love.graphics.setColor(W95.text)
        love.graphics.printf(tab.label, tx, tabY + (isActive and 4 or 6), tabW, "center")

        table.insert(self.buttons, {x = tx, y = tabY, w = tabW, h = tabH, action = "tab", index = i})
    end

    local panelY = tabY + tabH + 2
    local panelH = ch - tabH - 40

    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx + 8, panelY, cw - 16, panelH)
    self:drawBevel(cx + 8, panelY, cw - 16, panelH)

    if self.selectedTab == 1 then
        self:drawGeneralTab(cx + 14, panelY + 8, cw - 28, panelH - 16)
    elseif self.selectedTab == 2 then
        self:drawDevicesTab(cx + 14, panelY + 8, cw - 28, panelH - 16)
    elseif self.selectedTab == 3 then
        self:drawPerformanceTab(cx + 14, panelY + 8, cw - 28, panelH - 16)
    end

    local btnW = 75
    local btnH = 23
    local btnY = cy + ch - 30
    local btnX = cx + cw - btnW - 14

    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
    self:drawBevel(btnX, btnY, btnW, btnH)
    love.graphics.setColor(W95.text)
    love.graphics.printf("Aceptar", btnX, btnY + 5, btnW, "center")
    table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "ok"})

    love.graphics.setFont(prevFont)
end

function MyPC:drawGeneralTab(x, y, w, h)
    local prevFont = love.graphics.getFont()
    love.graphics.setFont(self.smallFont)

    local iconSize = 48
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("fill", x + 8, y + 8, iconSize, iconSize)
    love.graphics.setColor(0, 0, 0.5)
    love.graphics.rectangle("line", x + 8, y + 8, iconSize, iconSize)

    love.graphics.setColor(W95.text)
    love.graphics.print("Microsoft Windows 95", x + 68, y + 10)
    love.graphics.setColor(W95.textDim)
    love.graphics.print("Copyright (c) 1981-1995 Microsoft Corp.", x + 68, y + 28)

    local ps = self.pcStats or {
        os = "Microsoft Windows 95  4.00.950",
        cpu = "Intel Pentium 75MHz",
        ram = "16 MB",
        disk = "850 MB HDD",
        display = "Standard PCI Graphics Adapter (VGA)",
        bios = "American Megatrends  12/01/94",
    }

    local stats = {
        {label = "Version:", value = ps.os},
        {label = "Procesador:", value = ps.cpu},
        {label = "Memoria:", value = ps.ram},
        {label = "Disco:", value = ps.disk},
        {label = "Pantalla:", value = ps.display},
        {label = "Refrigeracion:", value = ps.sound or "Disipador basico"},
        {label = "BIOS:", value = ps.bios},
    }

    local sysInfoY = y + 70
    for i, pair in ipairs(stats) do
        local ly = sysInfoY + (i - 1) * 20
        love.graphics.setColor(W95.text)
        love.graphics.print(pair.label, x + 8, ly)

        love.graphics.setColor(W95.fieldBg)
        love.graphics.rectangle("fill", x + 100, ly - 2, w - 108, 18)
        self:drawInset(x + 100, ly - 2, w - 108, 18)
        love.graphics.setColor(W95.text)
        love.graphics.print(pair.value, x + 106, ly)
    end

    love.graphics.setFont(prevFont)
end

function MyPC:drawDevicesTab(x, y, w, h)
    local prevFont = love.graphics.getFont()
    love.graphics.setFont(self.smallFont)

    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", x, y, w, h - 8)
    self:drawInset(x, y, w, h - 8)

    local ps = self.pcStats or {}
    local displayDevice = ps.display or "Standard PCI Graphics Adapter (VGA)"
    local soundDevice = ps.sound or "Disipador basico"

    local devices = {
        {name = "Dispositivo de sistema", icon = ">"},
        {name = "  PC compatible con Intel", icon = ""},
        {name = "  Teclado estándar de 101/102 teclas", icon = ""},
        {name = "Dispositivos de disco", icon = ">"},
        {name = "  Controlador de disquete", icon = ""},
        {name = "  IDE DISK DRIVE", icon = ""},
        {name = "Dispositivos de pantalla", icon = ">"},
        {name = "  " .. displayDevice, icon = ""},
        {name = "Sistema de refrigeracion", icon = ">"},
        {name = "  " .. soundDevice, icon = ""},
        {name = "Puertos (COM y LPT)", icon = ">"},
        {name = "  Puerto de comunicaciones (COM1)", icon = ""},
        {name = "  Puerto de impresora (LPT1)", icon = ""},
    }

    love.graphics.setColor(W95.text)
    for i, dev in ipairs(devices) do
        local dy = y + 6 + (i - 1) * 16
        if dy + 16 > y + h - 12 then break end
        love.graphics.setColor(W95.text)
        love.graphics.print(dev.icon .. " " .. dev.name, x + 8, dy)
    end

    love.graphics.setFont(prevFont)
end

function MyPC:drawPerformanceTab(x, y, w, h)
    local prevFont = love.graphics.getFont()
    love.graphics.setFont(self.smallFont)

    local totalMB = 16
    if self.pcStats and self.pcStats.ramNum then
        totalMB = self.pcStats.ramNum
    end

    love.graphics.setColor(W95.text)
    love.graphics.print("Memoria del sistema:", x + 8, y + 8)

    local barX = x + 8
    local barY = y + 26
    local barW = w - 16
    local barH = 20

    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", barX, barY, barW, barH)
    self:drawInset(barX, barY, barW, barH)

    local usedMB = math.floor(totalMB / 2)
    local usedW = (usedMB / totalMB) * (barW - 4)
    love.graphics.setColor(0, 0, 0.5)
    love.graphics.rectangle("fill", barX + 2, barY + 2, usedW, barH - 4)

    love.graphics.setColor(W95.text)
    love.graphics.print(usedMB .. " MB usados de " .. totalMB .. " MB", barX + 8, barY + 3)

    love.graphics.print("Consumo de energia:", x + 8, y + 58)

    local totalWatts = 0
    local psuCap = 150
    if self.explorerRef then
        totalWatts = self.explorerRef:getTotalWatts()
        psuCap = self.explorerRef:getPsuCapacity()
    end

    local pwBarX = x + 8
    local pwBarY = y + 76
    local pwBarW = w - 16
    local pwBarH = 20

    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", pwBarX, pwBarY, pwBarW, pwBarH)
    self:drawInset(pwBarX, pwBarY, pwBarW, pwBarH)

    local usedPW = math.min(totalWatts / psuCap, 1.0) * (pwBarW - 4)
    if totalWatts > psuCap then
        love.graphics.setColor(0.8, 0, 0)
    else
        love.graphics.setColor(0, 0.5, 0)
    end
    love.graphics.rectangle("fill", pwBarX + 2, pwBarY + 2, usedPW, pwBarH - 4)

    love.graphics.setColor(W95.text)
    love.graphics.print(totalWatts .. "W / " .. psuCap .. "W", pwBarX + 8, pwBarY + 3)

    local componentWatts = {}
    if self.explorerRef and self.explorerRef.componentWatts then
        local componentOrder = {"cpu", "ram", "disk", "display", "cooling"}
        local names = {cpu = "CPU", ram = "RAM", disk = "Disco", display = "GPU", cooling = "Cooling"}
        local levels = self.explorerRef.upgradeLevels or {}
        for _, stat in ipairs(componentOrder) do
            local level = levels[stat] or 0
            local watts = 0
            if self.explorerRef.componentWatts[stat] and self.explorerRef.componentWatts[stat][level + 1] then
                watts = self.explorerRef.componentWatts[stat][level + 1]
            end
            table.insert(componentWatts, {name = names[stat], watts = watts})
        end
    end

    love.graphics.print("Desglose por componente:", x + 8, y + 106)
    for i, comp in ipairs(componentWatts) do
        local ry = y + 124 + (i - 1) * 18
        love.graphics.setColor(W95.text)
        love.graphics.print(comp.name, x + 12, ry)
        love.graphics.print(comp.watts .. "W", x + 100, ry)
    end

    love.graphics.setColor(W95.text)
    love.graphics.print("Archivo de intercambio: 24 MB", x + 8, y + 220)

    love.graphics.setFont(prevFont)
end

function MyPC:handleClick(x, y, button)
    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "tab" then
                self.selectedTab = btn.index
            elseif btn.action == "ok" then
                self.window.visible = false
                if self.window.onClose then self.window:onClose() end
            end
            return true
        end
    end
    return true
end

function MyPC:draw(mx, my)
    self.window:drawFrame()
end

function MyPC:hitTest(mx, my)
    return self.window:hitTest(mx, my)
end

function MyPC:mousepressed(x, y, button)
    return self.window:mousepressed(x, y, button)
end

function MyPC:mousereleased(x, y, button)
    self.window:mousereleased(x, y, button)
end

function MyPC:mousemoved(x, y)
    self.window:mousemoved(x, y)
end

return MyPC
