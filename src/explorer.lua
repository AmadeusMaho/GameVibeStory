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
    green = {0, 0.5, 0},
}

function Explorer.new(x, y)
    local self = setmetatable({}, Explorer)
    self.window = WindowManager.new("Microsoft Internet Explorer", x or 80, y or 60, 640, 460)

    self.currentPage = "home"
    self.loading = false
    self.loadTimer = 0
    self.loadDuration = 1.2
    self.selectedFav = 1
    self.trabajoRef = nil
    self.pcStatsRef = nil
    self.winampRef = nil

    self.musicSongs = {
        {name = "Nirvana - Smells Like Teen Spirit", price = 5, file = "songw95_1.wav", purchased = true},
        {name = "RHCP - Aeroplane", price = 5, file = "songw95_2.wav", purchased = true},
        {name = "Backstreet Boys - I Want It That Way", price = 100, file = "songw95_3.wav", purchased = false},
        {name = "Las Ketchup - Asereje", price = 100, file = "songw95_4.wav", purchased = false},
    }

    self.favorites = {
        {label = "Tienda", page = "upgrades"},
        {label = "Musica", page = "music"},
        {label = "Fondo de escritorio", page = "wallpaper"},
        {label = "Windows Update", page = "update"},
        {label = "MSN", page = "msn"},
    }

    self.upgradeTiers = {
        cpu = {
            {from = "Pentium 75MHz", to = "Pentium 100MHz", price = 49},
            {from = "Pentium 100MHz", to = "Pentium 133MHz", price = 99},
            {from = "Pentium 133MHz", to = "Pentium 200MHz", price = 189},
            {from = "Pentium 200MHz", to = "Pentium MMX 233", price = 349},
        },
        ram = {
            {from = "16 MB", to = "32 MB", price = 29},
            {from = "32 MB", to = "64 MB", price = 59},
            {from = "64 MB", to = "128 MB", price = 109},
            {from = "128 MB", to = "256 MB", price = 199},
        },
        disk = {
            {from = "850 MB", to = "1.2 GB", price = 35},
            {from = "1.2 GB", to = "2.1 GB", price = 69},
            {from = "2.1 GB", to = "4.3 GB", price = 119},
            {from = "4.3 GB", to = "8.4 GB", price = 199},
        },
        display = {
            {from = "Standard VGA", to = "S3 Trio64", price = 79},
            {from = "S3 Trio64", to = "S3 ViRGE", price = 149},
            {from = "S3 ViRGE", to = "3dfx Banshee", price = 249},
            {from = "3dfx Banshee", to = "Voodoo 3 3000", price = 399},
        },
        cooling = {
            {from = "Disipador basico", to = "Ventilador activo", price = 25},
            {from = "Ventilador activo", to = "Cooler Turbo", price = 59},
            {from = "Cooler Turbo", to = "Refrigeracion liquida", price = 99},
            {from = "Refrigeracion liquida", to = "Sistema custom", price = 179},
        },
        monitor = {
            {from = '14" CRT', to = '15" SVGA', price = 59},
            {from = '15" SVGA', to = '17" CRT', price = 119},
            {from = '17" CRT', to = '19" Trinitron', price = 219},
            {from = '19" Trinitron', to = '21" TFT', price = 379},
        },
    }

    self.upgradeLevels = {
        cpu = 0, ram = 0, disk = 0, display = 0, cooling = 0, monitor = 0,
    }

    self.upgrades = self:getVisibleUpgrades()

    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, x, y, button)
        return self:handleClick(x, y, button)
    end

    return self
end

function Explorer:getVisibleUpgrades()
    local visible = {}
    local names = {cpu = "Procesador", ram = "Memoria RAM", disk = "Disco Duro", display = "Placa de Video", cooling = "Refrigeracion", monitor = "Monitor"}
    for stat, tiers in pairs(self.upgradeTiers) do
        local level = self.upgradeLevels[stat] or 0
        if level < #tiers then
            local tier = tiers[level + 1]
            table.insert(visible, {
                name = names[stat],
                current = tier.from,
                upgrade = tier.to,
                price = tier.price,
                stat = stat,
                purchased = false,
                tier = level + 1,
            })
        end
    end
    table.sort(visible, function(a, b) return a.price < b.price end)
    return visible
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
    if self.purchaseMsgTimer and self.purchaseMsgTimer > 0 then
        self.purchaseMsgTimer = self.purchaseMsgTimer - dt
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
        elseif self.currentPage == "music" then
            self:drawMusicPage(pageX + 10, contentY + 10, pageW - 20, contentH - 20)
        elseif self.currentPage == "wallpaper" then
            self:drawWallpaperPage(pageX + 10, contentY + 10, pageW - 20, contentH - 20)
        elseif self.currentPage == "update" then
            self:drawPlaceholderPage(pageX + 10, contentY + 10, pageW - 20, contentH - 20, "Windows Update", "Su sistema esta actualizado.")
        elseif self.currentPage == "msn" then
            self:drawPlaceholderPage(pageX + 10, contentY + 10, pageW - 20, contentH - 20, "MSN", "Bienvenido a MSN.com")
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
    love.graphics.printf("Tienda de Hardware - PC Shop", x, y, w, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 10, y + 20, x + w - 10, y + 20)

    local moneyStr = "$0"
    if self.trabajoRef then
        moneyStr = "$" .. self.trabajoRef.money
    end
    love.graphics.setColor(W95.green)
    love.graphics.printf("Su dinero: " .. moneyStr, x, y + 24, w, "center")

    if #self.upgrades == 0 then
        love.graphics.setColor(W95.text)
        love.graphics.printf("¡Todos los componentes al maximo!", x, y + 60, w, "center")
        love.graphics.setColor(W95.green)
        love.graphics.printf("Su PC esta completamente upgrades.", x, y + 80, w, "center")
    else
        love.graphics.setColor(W95.text)
        love.graphics.printf("Mejore su PC - Componentes disponibles:", x, y + 40, w, "center")

        local tableX = x + 10
        local tableY = y + 56
        local colW = {100, 100, 100, 65, 80}
        local rowH = 24

        love.graphics.setColor(W95.highlight)
        love.graphics.rectangle("fill", tableX, tableY, w - 20, rowH)

        love.graphics.setColor(W95.highlightText)
        local headers = {"Componente", "Actual", "Upgrade", "Precio", "Comprar"}
        local hx = tableX + 4
        for i, header in ipairs(headers) do
            love.graphics.print(header, hx, tableY + 6)
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
            love.graphics.print(upg.name, rx, ry + 6)
            rx = rx + colW[1]
            love.graphics.setColor(W95.textDim)
            love.graphics.print(upg.current, rx, ry + 6)
            rx = rx + colW[2]
            love.graphics.setColor({0, 0.5, 0})
            love.graphics.print(upg.upgrade, rx, ry + 6)
            rx = rx + colW[3]
            love.graphics.setColor({0.8, 0, 0})
            love.graphics.print("$" .. upg.price, rx, ry + 6)
            rx = rx + colW[4]

            local btnW = 56
            local btnH = 18
            local btnX = rx
            local btnY = ry + 3

            local btnHovered = self.lastMX >= btnX and self.lastMX <= btnX + btnW and self.lastMY >= btnY and self.lastMY <= btnY + btnH
            local canBuy = self.trabajoRef and self.trabajoRef.money >= upg.price
            love.graphics.setColor(btnHovered and {0.85, 0.85, 0.85} or W95.bg)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
            self:drawBevel(btnX, btnY, btnW, btnH)
            love.graphics.setColor(canBuy and W95.text or W95.textDim)
            love.graphics.printf("Comprar", btnX, btnY + 3, btnW, "center")
            table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "buy", index = i})
        end

        love.graphics.setColor(W95.borderDark)
        love.graphics.line(x + 10, tableY + rowH + #self.upgrades * rowH + 4, x + w - 10, tableY + rowH + #self.upgrades * rowH + 4)
    end

    if self.purchaseMsgTimer and self.purchaseMsgTimer > 0 and self.purchaseMessage then
        love.graphics.setColor(W95.highlight)
        love.graphics.printf(self.purchaseMessage, x, y + h - 38, w, "center")
    end

    love.graphics.setColor(W95.textDim)
    love.graphics.printf("Precios en dolares. Impuestos no incluidos.", x, y + h - 20, w, "center")
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
                local upg = self.upgrades[btn.index]
                if upg and self.trabajoRef then
                    if self.trabajoRef.money >= upg.price and not upg.purchased then
                        self.trabajoRef.money = self.trabajoRef.money - upg.price
                        upg.purchased = true
                        self.upgradeLevels[upg.stat] = (self.upgradeLevels[upg.stat] or 0) + 1
                        self.purchaseMessage = upg.name .. " mejorado a " .. upg.upgrade .. "!"
                        self.purchaseMsgTimer = 2.0
                        if self.pcStatsRef then
                            if upg.stat == "cpu" then self.pcStatsRef.cpu = upg.upgrade end
                            if upg.stat == "ram" then
                                self.pcStatsRef.ram = upg.upgrade
                                local num = upg.upgrade:match("(%d+)")
                                if num then self.pcStatsRef.ramNum = tonumber(num) end
                            end
                            if upg.stat == "disk" then self.pcStatsRef.disk = upg.upgrade .. " HDD" end
                            if upg.stat == "display" then self.pcStatsRef.display = upg.upgrade end
                            if upg.stat == "cooling" then self.pcStatsRef.cooling = upg.upgrade end
                            if upg.stat == "monitor" then self.pcStatsRef.monitor = upg.upgrade end
                        end
                        self.upgrades = self:getVisibleUpgrades()
                    elseif upg.purchased then
                        self.purchaseMessage = "Ya tienes este upgrade."
                        self.purchaseMsgTimer = 2.0
                    else
                        self.purchaseMessage = "Dinero insuficiente. Necesitas $" .. upg.price
                        self.purchaseMsgTimer = 2.0
                    end
                end
            elseif btn.action == "tb" then
                if btn.label == "Inicio" then
                    self:navigateTo("home")
                elseif btn.label == "Detener" then
                    self.loading = false
                    self.loadTimer = 0
                elseif btn.label == "Actualizar" then
                    self:navigateTo(self.currentPage)
                end
            elseif btn.action == "buymusic" then
                local song = self.musicSongs[btn.index]
                if song and self.trabajoRef and not song.purchased then
                    if self.trabajoRef.money >= song.price then
                        self.trabajoRef.money = self.trabajoRef.money - song.price
                        song.purchased = true
                        self.purchaseMessage = song.name .. " comprado!"
                        self.purchaseMsgTimer = 2.0
                        if self.winampRef and song.file then
                            self.winampRef:addSong(song.name, song.file)
                        end
                    else
                        self.purchaseMessage = "Dinero insuficiente."
                        self.purchaseMsgTimer = 2.0
                    end
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

function Explorer:drawMusicPage(x, y, w, h)
    love.graphics.setColor(W95.text)
    love.graphics.printf("Tienda de Musica - Microsoft", x, y, w, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 10, y + 20, x + w - 10, y + 20)

    local moneyStr = "$0"
    if self.trabajoRef then
        moneyStr = "$" .. self.trabajoRef.money
    end
    love.graphics.setColor(W95.green)
    love.graphics.printf("Su dinero: " .. moneyStr, x, y + 24, w, "center")

    love.graphics.setColor(W95.text)
    love.graphics.printf("Descargue la mejor musica para su PC", x, y + 40, w, "center")

    local tableX = x + 20
    local tableY = y + 58
    local colW = {200, 70, 80}
    local rowH = 22

    love.graphics.setColor(W95.highlight)
    love.graphics.rectangle("fill", tableX, tableY, w - 40, rowH)
    love.graphics.setColor(W95.highlightText)
    local headers = {"Cancion", "Precio", "Comprar"}
    local hx = tableX + 4
    for i, header in ipairs(headers) do
        love.graphics.print(header, hx, tableY + 5)
        hx = hx + colW[i]
    end

    for i, song in ipairs(self.musicSongs) do
        local ry = tableY + rowH + (i - 1) * rowH
        local isEven = i % 2 == 0

        if isEven then
            love.graphics.setColor({0.92, 0.92, 0.92})
            love.graphics.rectangle("fill", tableX, ry, w - 40, rowH)
        end

        love.graphics.setColor(W95.text)
        love.graphics.print(song.name, tableX + 4, ry + 5)

        local rx = tableX + colW[1]
        if song.purchased then
            love.graphics.setColor(W95.green)
            love.graphics.print("Comprado", rx, ry + 5)
        else
            love.graphics.setColor({0.8, 0, 0})
            love.graphics.print("$" .. song.price, rx, ry + 5)
        end

        rx = rx + colW[2]
        local btnW = 56
        local btnH = 18
        local btnX = rx
        local btnY = ry + 2

        if song.purchased then
            love.graphics.setColor(W95.green)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
            love.graphics.setColor(W95.white)
            love.graphics.printf("OK", btnX, btnY + 3, btnW, "center")
        else
            local btnHovered = self.lastMX >= btnX and self.lastMX <= btnX + btnW and self.lastMY >= btnY and self.lastMY <= btnY + btnH
            love.graphics.setColor(btnHovered and {0.85, 0.85, 0.85} or W95.bg)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
            self:drawBevel(btnX, btnY, btnW, btnH)
            love.graphics.setColor(W95.text)
            love.graphics.printf("Comprar", btnX, btnY + 3, btnW, "center")
            table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "buymusic", index = i})
        end
    end

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 20, tableY + rowH + #self.musicSongs * rowH + 4, x + w - 20, tableY + rowH + #self.musicSongs * rowH + 4)

    if self.purchaseMsgTimer and self.purchaseMsgTimer > 0 and self.purchaseMessage then
        love.graphics.setColor(W95.highlight)
        love.graphics.printf(self.purchaseMessage, x, y + h - 38, w, "center")
    end

    love.graphics.setColor(W95.textDim)
    love.graphics.printf("Las canciones se agregan a Winamp despues de comprarlas.", x, y + h - 20, w, "center")
end

function Explorer:drawWallpaperPage(x, y, w, h)
    love.graphics.setColor(W95.text)
    love.graphics.printf("Fondo de Escritorio - Personalizacion", x, y, w, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 10, y + 20, x + w - 10, y + 20)

    love.graphics.setColor(W95.text)
    love.graphics.printf("Personalice el fondo de su escritorio", x, y + 28, w, "center")

    local wallpapers = {
        {name = "Azul clasico", price = 0, color = {0, 0, 0.5}},
        {name = "Verde bosque", price = 10, color = {0, 0.3, 0}},
        {name = "Rojo pasion", price = 10, color = {0.5, 0, 0}},
        {name = "Purpura royal", price = 15, color = {0.3, 0, 0.5}},
        {name = "Naranja atardecer", price = 15, color = {0.8, 0.4, 0}},
    }

    local tableX = x + 20
    local tableY = y + 50
    local rowH = 30

    love.graphics.setColor(W95.highlight)
    love.graphics.rectangle("fill", tableX, tableY, w - 40, rowH)
    love.graphics.setColor(W95.highlightText)
    love.graphics.print("Fondo", tableX + 8, tableY + 8)
    love.graphics.print("Precio", tableX + 160, tableY + 8)

    for i, wp in ipairs(wallpapers) do
        local ry = tableY + rowH + (i - 1) * rowH
        local isEven = i % 2 == 0

        if isEven then
            love.graphics.setColor({0.92, 0.92, 0.92})
            love.graphics.rectangle("fill", tableX, ry, w - 40, rowH)
        end

        love.graphics.setColor(wp.color)
        love.graphics.rectangle("fill", tableX + 8, ry + 5, 20, 16)
        love.graphics.setColor(0, 0, 0.5)
        love.graphics.rectangle("line", tableX + 8, ry + 5, 20, 16)

        love.graphics.setColor(W95.text)
        love.graphics.print(wp.name, tableX + 36, ry + 8)

        if wp.price == 0 then
            love.graphics.setColor(W95.green)
            love.graphics.print("Gratis", tableX + 160, ry + 8)
        else
            love.graphics.setColor({0.8, 0, 0})
            love.graphics.print("$" .. wp.price, tableX + 160, ry + 8)
        end

        local btnW = 56
        local btnH = 20
        local btnX = tableX + w - 80
        local btnY = ry + 5
        local btnHovered = self.lastMX >= btnX and self.lastMX <= btnX + btnW and self.lastMY >= btnY and self.lastMY <= btnY + btnH
        love.graphics.setColor(btnHovered and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
        self:drawBevel(btnX, btnY, btnW, btnH)
        love.graphics.setColor(W95.text)
        love.graphics.printf("Aplicar", btnX, btnY + 3, btnW, "center")
    end

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 20, tableY + rowH + #wallpapers * rowH + 4, x + w - 20, tableY + rowH + #wallpapers * rowH + 4)

    love.graphics.setColor(W95.textDim)
    love.graphics.printf("Los fondos se aplican inmediatamente al escritorio.", x, y + h - 20, w, "center")
end

return Explorer
