local Explorer = {}
Explorer.__index = Explorer

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
    highlight = {0, 0, 0.5},
    highlightText = {1, 1, 1},
    link = {0, 0, 0.8},
    linkVisited = {0.5, 0, 0.5},
    menuBg = {0.75, 0.75, 0.75},
    contentBg = {1, 1, 1},
    statusBar = {0.75, 0.75, 0.75},
    favBg = {0.75, 0.75, 0.75},
    favHover = {0, 0, 0.8},
}

function Explorer.new(x, y)
    local self = setmetatable({}, Explorer)
    self.window = WindowManager.new("Microsoft Internet Explorer", x or 80, y or 60, 640, 460)

    self.currentPage = "home"
    self.loading = false
    self.loadTimer = 0
    self.loadDuration = 1.2
    self.selectedFav = 1

    self.favorites = {
        {label = "Pagina de Upgrades", page = "upgrades"},
        {label = "Windows Update", page = "update"},
        {label = "MSN", page = "msn"},
        {label = "Mi PC", page = "mypc"},
    }

    self.upgrades = {
        {name = "Procesador", current = "Pentium 75MHz", upgrade = "Pentium 100MHz", price = 150, stat = "cpu"},
        {name = "Memoria RAM", current = "16 MB", upgrade = "32 MB", price = 80, stat = "ram"},
        {name = "Disco Duro", current = "850 MB", upgrade = "1.2 GB", price = 120, stat = "disk"},
        {name = "Tarjeta de Video", current = "Standard VGA", upgrade = "S3 Trio64", price = 200, stat = "display"},
        {name = "Tarjeta de Sonido", current = "Sound Blaster 16", upgrade = "Sound Blaster AWE32", price = 180, stat = "sound"},
        {name = "Monitor", current = "14\" CRT", upgrade = "15\" CRT", price = 250, stat = "monitor"},
    }

    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, x, y, button)
        return self:handleClick(x, y, button)
    end

    return self
end

function Explorer:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function Explorer:update(dt)
    if self.loading then
        self.loadTimer = self.loadTimer + dt
        if self.loadTimer >= self.loadDuration then
            self.loading = false
            self.loadTimer = 0
        end
    end
end

function Explorer:navigateTo(page)
    self.loading = true
    self.loadTimer = 0
    self.pendingPage = page
    for i, fav in ipairs(self.favorites) do
        if fav.page == page then
            self.selectedFav = i
            break
        end
    end
end

function Explorer:finishLoad()
    if self.pendingPage then
        self.currentPage = self.pendingPage
        self.pendingPage = nil
    end
end

function Explorer:drawBevel(x, y, w, h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Explorer:drawInset(x, y, w, h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Explorer:drawContent(cx, cy, cw, ch)
    self.buttons = {}

    local prevFont = love.graphics.getFont()
    local smallFont = love.graphics.newFont(11)
    love.graphics.setFont(smallFont)

    local menuH = 18
    local toolbarH = 28
    local addressH = 24
    local statusH = 20
    local favW = 150

    love.graphics.setColor(W95.menuBg)
    love.graphics.rectangle("fill", cx, cy, cw, menuH)
    local menuItems = {"Archivo", "Editar", "Ver", "Favoritos", "Ayuda"}
    local mx_off = cx + 4
    for _, item in ipairs(menuItems) do
        local iw = smallFont:getWidth(item) + 12
        love.graphics.setColor(W95.text)
        love.graphics.print(item, mx_off, cy + 3)
        mx_off = mx_off + iw
    end

    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx, cy + menuH, cw, toolbarH)
    self:drawBevel(cx, cy + menuH, cw, toolbarH)

    local tbButtons = {"Atras", "Adelante", "Detener", "Actualizar", "Inicio"}
    local tbX = cx + 4
    local tbY = cy + menuH + 3
    local tbW = 56
    local tbH = 22
    for i, label in ipairs(tbButtons) do
        local bx = tbX + (i - 1) * (tbW + 2)
        love.graphics.setColor(W95.bg)
        love.graphics.rectangle("fill", bx, tbY, tbW, tbH)
        self:drawBevel(bx, tbY, tbW, tbH)
        love.graphics.setColor(W95.text)
        love.graphics.printf(label, bx, tbY + 5, tbW, "center")
        table.insert(self.buttons, {x = bx, y = tbY, w = tbW, h = tbH, action = "tb", label = label})
    end

    local addrY = cy + menuH + toolbarH
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx, addrY, cw, addressH)

    love.graphics.setColor(W95.text)
    love.graphics.print("Direccion:", cx + 4, addrY + 5)

    local addrX = cx + 62
    local addrW = cw - 70
    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", addrX, addrY + 2, addrW, addressH - 4)
    self:drawInset(addrX, addrY + 2, addrW, addressH - 4)

    local addrText = "http://www.microsoft.com/" .. self.currentPage
    if self.loading and self.pendingPage then
        addrText = "http://www.microsoft.com/" .. self.pendingPage
    end
    love.graphics.setColor(W95.text)
    love.graphics.print(addrText, addrX + 4, addrY + 5)

    local contentY = addrY + addressH
    local contentH = ch - menuH - toolbarH - addressH - statusH

    love.graphics.setColor(W95.favBg)
    love.graphics.rectangle("fill", cx, contentY, favW, contentH)
    self:drawBevel(cx, contentY, favW, contentH)

    love.graphics.setColor(W95.text)
    love.graphics.print("Favoritos", cx + 4, contentY + 4)

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(cx + 4, contentY + 18, cx + favW - 4, contentY + 18)

    for i, fav in ipairs(self.favorites) do
        local fy = contentY + 22 + (i - 1) * 20
        local favHovered = self.lastMX >= cx and self.lastMX <= cx + favW and self.lastMY >= fy and self.lastMY <= fy + 18

        if i == self.selectedFav and not self.loading then
            love.graphics.setColor(W95.favHover)
            love.graphics.rectangle("fill", cx + 2, fy, favW - 4, 18)
            love.graphics.setColor(W95.highlightText)
        elseif favHovered then
            love.graphics.setColor({0.85, 0.85, 0.85})
            love.graphics.rectangle("fill", cx + 2, fy, favW - 4, 18)
            love.graphics.setColor(W95.link)
        else
            love.graphics.setColor(W95.text)
        end

        love.graphics.print("  " .. fav.label, cx + 6, fy + 3)
        table.insert(self.buttons, {x = cx, y = fy, w = favW, h = 18, action = "fav", page = fav.page, index = i})
    end

    local pageX = cx + favW
    local pageW = cw - favW

    love.graphics.setColor(W95.contentBg)
    love.graphics.rectangle("fill", pageX, contentY, pageW, contentH)
    self:drawInset(pageX, contentY, pageW, contentH)

    if self.loading then
        self:drawLoading(pageX + 10, contentY + 10, pageW - 20, contentH - 20)
    else
        self:finishLoad()
        if self.currentPage == "upgrades" then
            self:drawUpgradesPage(pageX + 10, contentY + 10, pageW - 20, contentH - 20)
        elseif self.currentPage == "update" then
            self:drawPlaceholderPage(pageX + 10, contentY + 10, pageW - 20, contentH - 20, "Windows Update", "Su sistema esta actualizado.")
        elseif self.currentPage == "msn" then
            self:drawPlaceholderPage(pageX + 10, contentY + 10, pageW - 20, contentH - 20, "MSN", "Bienvenido a MSN.com")
        elseif self.currentPage == "mypc" then
            self:drawPlaceholderPage(pageX + 10, contentY + 10, pageW - 20, contentH - 20, "Mi PC", "Acceda a las propiedades de su PC.")
        else
            self:drawHomePage(pageX + 10, contentY + 10, pageW - 20, contentH - 20)
        end
    end

    love.graphics.setColor(W95.statusBar)
    love.graphics.rectangle("fill", cx, cy + ch - statusH, cw, statusH)
    self:drawBevel(cx, cy + ch - statusH, cw, statusH)
    love.graphics.setColor(W95.text)
    local statusText = "Listo"
    if self.loading then
        statusText = "Cargando " .. (self.pendingPage or "") .. "..."
    end
    love.graphics.print("  " .. statusText, cx + 4, cy + ch - statusH + 4)

    love.graphics.setFont(prevFont)
end

function Explorer:drawLoading(x, y, w, h)
    love.graphics.setColor(W95.text)
    love.graphics.printf("Conectando...", x, y + h / 2 - 30, w, "center")

    local barW = 200
    local barH = 16
    local barX = x + (w - barW) / 2
    local barY = y + h / 2

    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", barX, barY, barW, barH)
    self:drawInset(barX, barY, barW, barH)

    local progress = math.min(self.loadTimer / self.loadDuration, 1)
    local filledW = (barW - 4) * progress

    love.graphics.setColor({0, 0, 0.5})
    love.graphics.rectangle("fill", barX + 2, barY + 2, filledW, barH - 4)

    local blocks = math.floor(progress * 20)
    local blockStr = string.rep("=", blocks) .. string.rep(" ", 20 - blocks)
    love.graphics.setColor(W95.text)
    love.graphics.printf("[" .. blockStr .. "]", x, barY + barH + 8, w, "center")
end

function Explorer:drawHomePage(x, y, w, h)
    love.graphics.setColor(W95.text)
    love.graphics.printf("Microsoft Internet Explorer", x, y, w, "center")
    love.graphics.setColor(W95.textDim)
    love.graphics.printf("Version 3.0", x, y + 18, w, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 20, y + 40, x + w - 20, y + 40)

    love.graphics.setColor(W95.text)
    love.graphics.printf("Bienvenido a Internet Explorer", x, y + 50, w, "center")
    love.graphics.printf("Seleccione una pagina de Favoritos para comenzar.", x, y + 70, w, "center")

    love.graphics.setColor(W95.link)
    love.graphics.printf("http://www.microsoft.com", x, y + 100, w, "center")
end

function Explorer:drawPlaceholderPage(x, y, w, h, title, desc)
    love.graphics.setColor(W95.text)
    love.graphics.printf(title, x, y, w, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 20, y + 20, x + w - 20, y + 20)

    love.graphics.setColor(W95.text)
    love.graphics.printf(desc, x, y + 30, w, "center")
    love.graphics.setColor(W95.textDim)
    love.graphics.printf("Proximamente...", x, y + 55, w, "center")
end

function Explorer:drawUpgradesPage(x, y, w, h)
    love.graphics.setColor(W95.text)
    love.graphics.printf("Tienda de Upgrades - Microsoft", x, y, w, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 10, y + 20, x + w - 10, y + 20)

    love.graphics.setColor(W95.text)
    love.graphics.printf("Mejore su PC con los mejores componentes", x, y + 28, w, "center")

    local tableX = x + 10
    local tableY = y + 52
    local colW = {120, 110, 110, 70, 80}
    local rowH = 22

    love.graphics.setColor(W95.highlight)
    love.graphics.rectangle("fill", tableX, tableY, w - 20, rowH)

    love.graphics.setColor(W95.highlightText)
    local headers = {"Componente", "Actual", "Upgrade", "Precio", "Comprar"}
    local hx = tableX + 4
    for i, header in ipairs(headers) do
        love.graphics.print(header, hx, tableY + 5)
        hx = hx + colW[i]
    end

    for i, upg in ipairs(self.upgrades) do
        local ry = tableY + rowH + (i - 1) * rowH
        local isEven = i % 2 == 0

        if isEven then
            love.graphics.setColor({0.92, 0.92, 0.92})
            love.graphics.rectangle("fill", tableX, ry, w - 20, rowH)
        end

        love.graphics.setColor(W95.text)
        local rx = tableX + 4
        love.graphics.print(upg.name, rx, ry + 5)
        rx = rx + colW[1]
        love.graphics.setColor(W95.textDim)
        love.graphics.print(upg.current, rx, ry + 5)
        rx = rx + colW[2]
        love.graphics.setColor({0, 0.5, 0})
        love.graphics.print(upg.upgrade, rx, ry + 5)
        rx = rx + colW[3]
        love.graphics.setColor({0.8, 0, 0})
        love.graphics.print("$" .. upg.price, rx, ry + 5)
        rx = rx + colW[4]

        local btnW = 56
        local btnH = 18
        local btnX = rx
        local btnY = ry + 2
        local btnHovered = self.lastMX >= btnX and self.lastMX <= btnX + btnW and self.lastMY >= btnY and self.lastMY <= btnY + btnH

        love.graphics.setColor(btnHovered and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
        self:drawBevel(btnX, btnY, btnW, btnH)
        love.graphics.setColor(W95.text)
        love.graphics.printf("Comprar", btnX, btnY + 3, btnW, "center")

        table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "buy", index = i})
    end

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 10, tableY + rowH + #self.upgrades * rowH + 4, x + w - 10, tableY + rowH + #self.upgrades * rowH + 4)

    love.graphics.setColor(W95.textDim)
    love.graphics.printf("Precios sujetos a cambio sin previo aviso.", x, y + h - 20, w, "center")
end

function Explorer:handleClick(x, y, button)
    if button ~= 1 then return false end

    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "fav" then
                if not self.loading then
                    self:navigateTo(btn.page)
                end
            elseif btn.action == "buy" then
                -- Placeholder for upgrade logic
            elseif btn.action == "tb" then
                if btn.label == "Inicio" then
                    self:navigateTo("home")
                elseif btn.label == "Detener" then
                    self.loading = false
                    self.loadTimer = 0
                elseif btn.label == "Actualizar" then
                    self:navigateTo(self.currentPage)
                end
            end
            return true
        end
    end
    return true
end

function Explorer:draw(mx, my)
    self.lastMX = mx
    self.lastMY = my
    self.window:drawFrame()
end

function Explorer:hitTest(mx, my)
    return self.window:hitTest(mx, my)
end

function Explorer:mousepressed(x, y, button)
    return self.window:mousepressed(x, y, button)
end

function Explorer:mousereleased(x, y, button)
    self.window:mousereleased(x, y, button)
end

function Explorer:mousemoved(x, y)
    self.window:mousemoved(x, y)
end

return Explorer
