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
    yellow = {0.8, 0.6, 0},
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
    self.onHardwarePurchase = nil

    self.musicSongs = {
        {name = "Nirvana - Smells Like Teen Spirit", price = 35, file = "songw95_1.wav", purchased = false, category = "tendencias"},
        {name = "RHCP - Aeroplane", price = 45, file = "songw95_2.wav", purchased = false, category = "tendencias"},
        {name = "Backstreet Boys - I Want It That Way", price = 60, file = "songw95_3.wav", purchased = false, category = "tendencias"},
        {name = "Las Ketchup - Asereje", price = 75, file = "songw95_4.wav", purchased = false, category = "tendencias"},
        {name = "Nobuo Uematsu - Corridors of Time", price = 50, file = "songGame_w95.wav", purchased = false, category = "videojuegos"},
    }

    self.favorites = {
        {label = "Tienda", page = "upgrades"},
        {label = "Apps", page = "apps"},
        {label = "Windows Update", page = "update"},
        {label = "Musica", page = "music", unlocked = false},
        {label = "Fondo de escritorio", page = "wallpaper", unlocked = false},
        {label = "MSN", page = "msn", unlocked = false},
    }
    self.unlockedPages = {upgrades = true, update = true, apps = true}

    self.appStore = {
        {
            id = "winbatch",
            name = "Winbatch",
            desc = "Automatiza tareas freelance.\nHace clic automaticamente\nen el boton Trabajar cada\n3 segundos.",
            price = 500,
            icon = "winbatch",
            purchased = false,
            milestone = nil,
        },
        {
            id = "app2",
            name = "Proximamente...",
            desc = "Nueva app disponible pronto.",
            price = 0,
            icon = nil,
            purchased = false,
            milestone = "locked",
        },
        {
            id = "app3",
            name = "Proximamente...",
            desc = "Nueva app disponible pronto.",
            price = 0,
            icon = nil,
            purchased = false,
            milestone = "locked",
        },
        {
            id = "app4",
            name = "Proximamente...",
            desc = "Nueva app disponible pronto.",
            price = 0,
            icon = nil,
            purchased = false,
            milestone = "locked",
        },
    }
    self.appStoreScrollY = 0
    self.selectedApp = nil

    self.upgradeTiers = {
        cpu = {
            {from = "Pentium 75MHz", to = "Pentium 100MHz", price = 80, watts = 30},
            {from = "Pentium 100MHz", to = "Pentium 133MHz", price = 160, watts = 40},
            {from = "Pentium 133MHz", to = "Pentium 200MHz", price = 352, watts = 55},
            {from = "Pentium 200MHz", to = "Pentium MMX 233", price = 800, watts = 70},
        },
        ram = {
            {from = "16 MB", to = "32 MB", price = 200, watts = 3},
            {from = "32 MB", to = "64 MB", price = 500, watts = 5},
            {from = "64 MB", to = "128 MB", price = 1200, watts = 8},
            {from = "128 MB", to = "256 MB", price = 3000, watts = 12},
        },
        disk = {
            {from = "850 MB", to = "1.2 GB", price = 90, watts = 8},
            {from = "1.2 GB", to = "2.1 GB", price = 189, watts = 10},
            {from = "2.1 GB", to = "4.3 GB", price = 397, watts = 12},
            {from = "4.3 GB", to = "8.4 GB", price = 834, watts = 15},
        },
        display = {
            {from = "Standard VGA", to = "S3 Trio64", price = 100, watts = 10},
            {from = "S3 Trio64", to = "S3 ViRGE", price = 220, watts = 15},
            {from = "S3 ViRGE", to = "3dfx Banshee", price = 484, watts = 25},
            {from = "3dfx Banshee", to = "Voodoo 3 3000", price = 1065, watts = 40},
        },
        cooling = {
            {from = "Disipador basico", to = "Ventilador activo", price = 75, watts = 2},
            {from = "Ventilador activo", to = "Cooler Turbo", price = 143, watts = 4},
            {from = "Cooler Turbo", to = "Refrigeracion liquida", price = 271, watts = 8},
            {from = "Refrigeracion liquida", to = "Sistema custom", price = 515, watts = 12},
        },
        psu = {
            {from = "Fuente 150W", to = "Fuente 200W", price = 60, capacity = 200},
            {from = "Fuente 200W", to = "Fuente 250W", price = 120, capacity = 250},
            {from = "Fuente 250W", to = "Fuente 300W", price = 240, capacity = 300},
            {from = "Fuente 300W", to = "Fuente 350W", price = 480, capacity = 350},
        },
    }

    self.upgradeLevels = {
        cpu = 0, ram = 0, disk = 0, display = 0, cooling = 0, psu = 0,
    }

    self.componentWatts = {
        cpu = {30, 40, 55, 70},
        ram = {3, 5, 8, 12},
        disk = {8, 10, 12, 15},
        display = {10, 15, 25, 40},
        cooling = {2, 4, 8, 12},
    }

    self.psuCapacity = {150, 200, 250, 300, 350}

    self.upgrades = self:getVisibleUpgrades()

    self.shopView = "grid"
    self.selectedComponent = nil
    self.shopScrollY = 0
    self.navHistory = {}
    self.navIndex = 0

    self.componentIcons = {
        cpu = {label = "Procesador", icon = "CPU"},
        ram = {label = "Memoria RAM", icon = "RAM"},
        disk = {label = "Disco Duro", icon = "HDD"},
        display = {label = "Placa de Video", icon = "GPU"},
        cooling = {label = "Refrigeracion", icon = "FAN"},
        psu = {label = "Fuente de Poder", icon = "PSU"},
    }

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

function Explorer:unlockPage(page)
    self.unlockedPages[page] = true
    for _, fav in ipairs(self.favorites) do
        if fav.page == page then
            fav.unlocked = true
        end
    end
end

function Explorer:getTotalWatts()
    local total = 0
    local componentOrder = {"cpu", "ram", "disk", "display", "cooling"}
    for _, stat in ipairs(componentOrder) do
        local level = self.upgradeLevels[stat] or 0
        if self.componentWatts[stat] and self.componentWatts[stat][level + 1] then
            total = total + self.componentWatts[stat][level + 1]
        elseif self.componentWatts[stat] and self.componentWatts[stat][1] then
            total = total + self.componentWatts[stat][1]
        end
    end
    return total
end

function Explorer:getPsuCapacity()
    local level = self.upgradeLevels.psu or 0
    return self.psuCapacity[level + 1] or 150
end

function Explorer:canAffordWatts(watts)
    return self:getTotalWatts() + watts <= self:getPsuCapacity()
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
    if page == "upgrades" then
        self.shopView = "grid"
        self.selectedComponent = nil
        self.shopScrollY = 0
        self.navHistory = {}
        self.navIndex = 0
    end
end

function Explorer:navigateToComponent(stat)
    self.shopView = "detail"
    self.selectedComponent = stat
    table.insert(self.navHistory, {view = "grid"})
    self.navIndex = #self.navHistory
end

function Explorer:navigateBack()
    if self.navIndex > 0 then
        local hist = self.navHistory[self.navIndex]
        self.shopView = hist.view
        self.selectedComponent = hist.component
        self.navIndex = self.navIndex - 1
    else
        self.shopView = "grid"
        self.selectedComponent = nil
        self.shopScrollY = 0
    end
end

function Explorer:navigateForward()
    if self.navIndex < #self.navHistory then
        self.navIndex = self.navIndex + 1
        local hist = self.navHistory[self.navIndex]
        self.shopView = hist.view
        self.selectedComponent = hist.component
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

    local favIndex = 0
    for i, fav in ipairs(self.favorites) do
        if fav.unlocked ~= false then
            favIndex = favIndex + 1
            local fy = contentY + 22 + (favIndex - 1) * 20
            local favHovered = self.lastMX >= cx and self.lastMX <= cx + favW and self.lastMY >= fy and self.lastMY <= fy + 18

            if fav.page == self.currentPage and not self.loading then
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
        elseif self.currentPage == "apps" then
            self:drawAppsPage(pageX + 10, contentY + 10, pageW - 20, contentH - 20)
        elseif self.currentPage == "music" and self.unlockedPages.music then
            self:drawMusicPage(pageX + 10, contentY + 10, pageW - 20, contentH - 20)
        elseif self.currentPage == "wallpaper" and self.unlockedPages.wallpaper then
            self:drawWallpaperPage(pageX + 10, contentY + 10, pageW - 20, contentH - 20)
        elseif self.currentPage == "update" then
            self:drawPlaceholderPage(pageX + 10, contentY + 10, pageW - 20, contentH - 20, "Windows Update", "Su sistema esta actualizado.")
        elseif self.currentPage == "msn" and self.unlockedPages.msn then
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

function Explorer:drawAppsPage(x, y, w, h)
    love.graphics.setColor(W95.text)
    love.graphics.printf("Tienda de Aplicaciones", x, y, w, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 10, y + 20, x + w - 10, y + 20)

    local moneyStr = "$0"
    if self.trabajoRef then
        moneyStr = "$" .. self.trabajoRef.money
    end
    love.graphics.setColor(W95.green)
    love.graphics.printf("Su dinero: " .. moneyStr, x, y + 24, w, "center")

    local cols = 3
    local cellW = 120
    local cellH = 130
    local padding = 16
    local startX = x + (w - cols * (cellW + padding) + padding) / 2

    love.graphics.setScissor(x, y + 44, w, h - 44)

    local scrollOffset = -self.appStoreScrollY

    for i, app in ipairs(self.appStore) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local cx = startX + col * (cellW + padding)
        local cy = y + 52 + row * (cellH + padding) + scrollOffset

        if cy + cellH > y + 44 and cy < y + h then
            local isLocked = app.milestone == "locked"
            local isSelected = self.selectedApp and self.selectedApp.id == app.id
            local hovered = self.lastMX >= cx and self.lastMX <= cx + cellW and self.lastMY >= cy and self.lastMY <= cy + cellH

            love.graphics.setColor(isSelected and {0.9, 0.9, 1.0} or (hovered and {0.85, 0.85, 0.85} or W95.bg))
            love.graphics.rectangle("fill", cx, cy, cellW, cellH)
            self:drawBevel(cx, cy, cellW, cellH)

            love.graphics.setColor(W95.highlight)
            love.graphics.rectangle("fill", cx + 4, cy + 4, cellW - 8, 40)

            if app.icon and iconImages[app.icon] then
                local img = iconImages[app.icon]
                local imgW, imgH = img:getDimensions()
                local iconScale = math.min(36 / imgW, 36 / imgH)
                love.graphics.setColor(1, 1, 1)
                love.graphics.draw(img, cx + (cellW - 36) / 2, cy + 6, 0, iconScale, iconScale)
            else
                love.graphics.setColor(W95.textDim)
                love.graphics.printf("?", cx, cy + 16, cellW, "center")
            end

            love.graphics.setColor(W95.text)
            love.graphics.printf(app.name, cx, cy + 48, cellW, "center")

            if isLocked then
                love.graphics.setColor(W95.textDim)
                love.graphics.printf("Proximamente...", cx, cy + 64, cellW, "center")
                table.insert(self.buttons, {x = cx, y = cy, w = cellW, h = cellH, action = "selectapp", index = i})
            elseif app.purchased then
                love.graphics.setColor(W95.green)
                love.graphics.printf("Instalado", cx, cy + 64, cellW, "center")
                table.insert(self.buttons, {x = cx, y = cy, w = cellW, h = cellH, action = "selectapp", index = i})
            else
                love.graphics.setColor({0.8, 0, 0})
                love.graphics.printf("$" .. app.price, cx, cy + 64, cellW, "center")

                local btnW = 56
                local btnH = 18
                local btnX = cx + (cellW - btnW) / 2
                local btnY = cy + 82
                local btnHov = self.lastMX >= btnX and self.lastMX <= btnX + btnW and self.lastMY >= btnY and self.lastMY <= btnY + btnH
                local canAfford = self.trabajoRef and self.trabajoRef.money >= app.price

                if canAfford then
                    love.graphics.setColor(btnHov and {0.85, 0.85, 0.85} or W95.bg)
                    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
                    self:drawBevel(btnX, btnY, btnW, btnH)
                    love.graphics.setColor(W95.green)
                    love.graphics.printf("Comprar", btnX, btnY + 3, btnW, "center")
                    table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "buyapp", index = i})
                else
                    love.graphics.setColor(W95.textDim)
                    love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
                    self:drawBevel(btnX, btnY, btnW, btnH)
                    love.graphics.setColor(W95.textDim)
                    love.graphics.printf("Comprar", btnX, btnY + 3, btnW, "center")
                end
                table.insert(self.buttons, {x = cx, y = cy, w = cellW, h = cellH - 30, action = "selectapp", index = i})
            end
        end
    end

    love.graphics.setScissor()

    if self.selectedApp then
        local app = self.selectedApp
        love.graphics.setColor(W95.borderDark)
        love.graphics.line(x + 10, y + h - 60, x + w - 10, y + h - 60)
        love.graphics.setColor(W95.text)
        love.graphics.printf(app.name, x, y + h - 55, w, "center")
        love.graphics.setColor(W95.textDim)
        love.graphics.printf(app.desc, x, y + h - 40, w, "center")
    end

    if self.purchaseMsgTimer and self.purchaseMsgTimer > 0 and self.purchaseMessage then
        love.graphics.setColor(W95.highlight)
        love.graphics.printf(self.purchaseMessage, x, y + h - 20, w, "center")
    end
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

    if self.shopView == "grid" then
        self:drawShopGrid(x, y + 44, w, h - 64)
    else
        self:drawShopDetail(x, y + 44, w, h - 64)
    end

    if self.purchaseMsgTimer and self.purchaseMsgTimer > 0 and self.purchaseMessage then
        love.graphics.setColor(W95.highlight)
        love.graphics.printf(self.purchaseMessage, x, y + h - 38, w, "center")
    end
end

function Explorer:drawShopGrid(x, y, w, h)
    local componentOrder = {"cpu", "ram", "disk", "display", "cooling", "psu"}
    local cols = 3
    local cellW = 120
    local cellH = 110
    local padding = 16
    local startX = x + (w - cols * (cellW + padding) + padding) / 2

    local totalWatts = self:getTotalWatts()
    local psuCap = self:getPsuCapacity()

    love.graphics.setColor(W95.text)
    love.graphics.printf("Consumo: " .. totalWatts .. "W / " .. psuCap .. "W", x, y - 16, w, "center")

    love.graphics.setScissor(x, y, w, h)

    local scrollOffset = -self.shopScrollY

    for i, stat in ipairs(componentOrder) do
        local col = (i - 1) % cols
        local row = math.floor((i - 1) / cols)
        local cx = startX + col * (cellW + padding)
        local cy = y + 8 + row * (cellH + padding) + scrollOffset

        if cy + cellH > y and cy < y + h then
            local comp = self.componentIcons[stat]
            local level = self.upgradeLevels[stat] or 0
            local tiers = self.upgradeTiers[stat]
            local isMaxed = level >= #tiers

            local currentWatts = 0
            if self.componentWatts[stat] and self.componentWatts[stat][level + 1] then
                currentWatts = self.componentWatts[stat][level + 1]
            elseif self.componentWatts[stat] and self.componentWatts[stat][1] then
                currentWatts = self.componentWatts[stat][1]
            end

            local hovered = self.lastMX >= cx and self.lastMX <= cx + cellW and self.lastMY >= cy and self.lastMY <= cy + cellH

            love.graphics.setColor(hovered and {0.85, 0.85, 0.85} or W95.bg)
            love.graphics.rectangle("fill", cx, cy, cellW, cellH)
            self:drawBevel(cx, cy, cellW, cellH)

            love.graphics.setColor(W95.highlight)
            love.graphics.rectangle("fill", cx + 4, cy + 4, cellW - 8, 28)
            love.graphics.setColor(W95.highlightText)
            love.graphics.printf(comp.icon, cx + 4, cy + 10, cellW - 8, "center")

            love.graphics.setColor(W95.text)
            love.graphics.printf(comp.label, cx, cy + 36, cellW, "center")

            love.graphics.setColor(W95.textDim)
            love.graphics.printf("Lv." .. level, cx, cy + 50, cellW, "center")

            if isMaxed then
                love.graphics.setColor(W95.green)
                love.graphics.printf("MAX", cx, cy + 54, cellW, "center")
            else
                local nextTier = tiers[level + 1]
                local canBuyMoney = self.trabajoRef and self.trabajoRef.money >= nextTier.price
                local canBuyWatts = stat == "psu" or self:canAffordWatts(nextTier.watts or 0)
                if canBuyMoney and canBuyWatts then
                    love.graphics.setColor(W95.green)
                else
                    love.graphics.setColor({0.8, 0, 0})
                end
                love.graphics.printf("$" .. nextTier.price, cx, cy + 54, cellW, "center")
            end

            if stat == "psu" then
                local psuLevel = self.upgradeLevels.psu or 0
                local nextCap = self.psuCapacity[psuLevel + 2] or self.psuCapacity[#self.psuCapacity]
                love.graphics.setColor(W95.textDim)
                love.graphics.printf("-> " .. nextCap .. "W", cx, cy + 70, cellW, "center")
            else
            love.graphics.setColor(W95.textDim)
            love.graphics.printf(currentWatts .. "W", cx, cy + 70, cellW, "center")
            end

            local bonusText = ""
            if stat == "cpu" then
                local bonus = level * 20
                bonusText = "Tiempo: -" .. bonus .. "%"
            elseif stat == "display" then
                local bonus = level * 40
                bonusText = "Dinero: +" .. bonus .. "%"
            elseif stat == "ram" then
                bonusText = "Trabajos: " .. (1 + level)
            elseif stat == "cooling" then
                local bonus = 10 + (level - 1) * 20
                if level == 0 then bonus = 0 end
                bonusText = "Boost: +" .. bonus .. "%"
            elseif stat == "disk" then
                bonusText = "Apps: " .. (1 + level)
            elseif stat == "psu" then
                bonusText = "Capacidad"
            end

            love.graphics.setColor(W95.yellow)
            love.graphics.printf(bonusText, cx, cy + 86, cellW, "center")

            table.insert(self.buttons, {x = cx, y = cy, w = cellW, h = cellH, action = "component", stat = stat})
        end
    end

    love.graphics.setScissor()
end

function Explorer:drawShopDetail(x, y, w, h)
    local stat = self.selectedComponent
    if not stat then return end

    local comp = self.componentIcons[stat]
    local tiers = self.upgradeTiers[stat]
    local level = self.upgradeLevels[stat] or 0

    local totalWatts = self:getTotalWatts()
    local psuCap = self:getPsuCapacity()

    love.graphics.setColor(W95.text)
    love.graphics.printf(comp.label, x, y, w, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 10, y + 18, x + w - 10, y + 18)

    love.graphics.setColor(W95.text)
    love.graphics.printf("Nivel actual: " .. level .. "/" .. #tiers .. "  |  Consumo: " .. totalWatts .. "W / " .. psuCap .. "W", x, y + 24, w, "center")

    local tableX = x + 10
    local tableY = y + 50
    local rowH = 28

    local isPsu = stat == "psu"
    local headers = isPsu and {"Upgrade", "Capacidad", "Precio", "Estado"} or {"Upgrade", "Watts", "Precio", "Estado"}
    local colW2 = {(w - 120) / 2, 50, 70, 80}

    love.graphics.setColor(W95.highlight)
    love.graphics.rectangle("fill", tableX, tableY, w - 20, rowH)
    love.graphics.setColor(W95.highlightText)
    local hx = tableX + 4
    for i, header in ipairs(headers) do
        love.graphics.print(header, hx, tableY + 8)
        hx = hx + colW2[i]
    end

    for i, tier in ipairs(tiers) do
        local ry = tableY + rowH + (i - 1) * rowH
        local isEven = i % 2 == 0
        local isCurrent = i == level + 1
        local isOwned = i <= level

        if isEven then
            love.graphics.setColor({0.92, 0.92, 0.92})
            love.graphics.rectangle("fill", tableX, ry, w - 20, rowH)
        end

        love.graphics.setColor(W95.text)
        local rx = tableX + 4
        love.graphics.print(tier.from .. " -> " .. tier.to, rx, ry + 8)
        rx = rx + colW2[1]

        love.graphics.setColor(W95.textDim)
        if isPsu then
            love.graphics.print(tier.capacity .. "W", rx, ry + 8)
        else
            love.graphics.print((tier.watts or 0) .. "W", rx, ry + 8)
        end
        rx = rx + colW2[2]

        local canBuyMoney = self.trabajoRef and self.trabajoRef.money >= tier.price
        local canBuyWatts = isPsu or self:canAffordWatts(tier.watts or 0)
        if canBuyMoney and canBuyWatts then
            love.graphics.setColor(W95.green)
        else
            love.graphics.setColor({0.8, 0, 0})
        end
        love.graphics.print("$" .. tier.price, rx, ry + 8)
        rx = rx + colW2[3]

        if isOwned then
            love.graphics.setColor(W95.green)
            love.graphics.print("Comprado", rx, ry + 8)
        elseif isCurrent then
            local btnW = 70
            local btnH = 20
            local btnX = rx
            local btnY = ry + 4
            local canBuy = canBuyMoney and canBuyWatts
            local btnHovered = self.lastMX >= btnX and self.lastMX <= btnX + btnW and self.lastMY >= btnY and self.lastMY <= btnY + btnH
            love.graphics.setColor(btnHovered and {0.85, 0.85, 0.85} or W95.bg)
            love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
            self:drawBevel(btnX, btnY, btnW, btnH)
            love.graphics.setColor(canBuy and W95.text or W95.textDim)
            love.graphics.printf("Comprar", btnX, btnY + 4, btnW, "center")
            table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "buy", stat = stat, tierIndex = i})
        else
            love.graphics.setColor(W95.textDim)
            love.graphics.print("Bloqueado", rx, ry + 8)
        end
    end

    local descY = y + h - 60
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 10, descY, x + w - 10, descY)

    local descriptions = {
        cpu = "Freelance: -20% tiempo de tarea por upgrade\nProyecto: Genera circulos mas rapido\n\nBase: 35% mas lento sin upgrades.\nCada nivel de CPU reduce el tiempo\nentre tareas y acelera la generacion\nde circulos en proyectos.",
        ram = "Freelance: +1 trabajo simultaneo por upgrade\nProyecto: +25% puntos por circulo\n\nCada nivel de RAM permite hacer\nmas trabajos a la vez y aumenta\nlos puntos que dan los circulos.",
        disk = "Almacenamiento del sistema\nDetermina cuantas apps puedes tener\n\nCada nivel de HDD desbloquea\nnuevas aplicaciones y funciones.",
        display = "Freelance: +40% dinero por tarea por upgrade\nProyecto: Mayor daño por circulo\n\nCada nivel de GPU aumenta el dinero\npor tarea y el daño de los circulos\nen proyectos.",
        cooling = "Freelance: +10% GPU y CPU, +20% por upgrade\nProyecto: Reduce bugs en circulos\n\nCada nivel de cooling potencia\nla GPU y CPU, y reduce la\nprobabilidad de bugs.",
        psu = "Fuente de alimentacion\nDetermina la capacidad maxima de watts\n\nPermite instalar componentes mas\npotentes sin exceder el limite.",
    }

    love.graphics.setColor(W95.text)
    love.graphics.printf("Que hace este componente:", x + 10, descY + 6, w - 20, "left")

    local desc = descriptions[stat] or ""
    love.graphics.setColor(W95.textDim)
    local descLines = desc:gmatch("[^\n]+")
    local lineY = descY + 22
    for line in descLines do
        love.graphics.print("  " .. line, x + 14, lineY)
        lineY = lineY + 14
    end
end

function Explorer:handleClick(x, y, button)
    if button ~= 1 then return false end

    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "fav" then
                if not self.loading then
                    self:navigateTo(btn.page)
                end
            elseif btn.action == "component" then
                self:navigateToComponent(btn.stat)
            elseif btn.action == "selectapp" then
                local app = self.appStore[btn.index]
                if app then
                    self.selectedApp = app
                end
            elseif btn.action == "buy" then
                if btn.stat and btn.tierIndex then
                    local stat = btn.stat
                    local tierIndex = btn.tierIndex
                    local tiers = self.upgradeTiers[stat]
                    local level = self.upgradeLevels[stat] or 0
                    if tierIndex == level + 1 and tiers[tierIndex] then
                        local tier = tiers[tierIndex]
                        local canBuyMoney = self.trabajoRef and self.trabajoRef.money >= tier.price
                        local canBuyWatts = self:canAffordWatts(tier.watts or 0)
                        if canBuyMoney and canBuyWatts then
                            self.trabajoRef.money = self.trabajoRef.money - tier.price
                            self.upgradeLevels[stat] = level + 1
                            local names = {cpu = "Procesador", ram = "Memoria RAM", disk = "Disco Duro", display = "Placa de Video", cooling = "Refrigeracion", psu = "Fuente de Poder"}
                            self.purchaseMessage = names[stat] .. " mejorado a " .. tier.to .. "!"
                            self.purchaseMsgTimer = 2.0
                            if self.onHardwarePurchase then self.onHardwarePurchase() end
                            if self.onUpgradePurchased then self.onUpgradePurchased(stat, level + 1) end
                            if self.pcStatsRef then
                                if stat == "cpu" then self.pcStatsRef.cpu = tier.to end
                                if stat == "ram" then
                                    self.pcStatsRef.ram = tier.to
                                    local num = tier.to:match("(%d+)")
                                    if num then self.pcStatsRef.ramNum = tonumber(num) end
                                end
                                if stat == "disk" then self.pcStatsRef.disk = tier.to .. " HDD" end
                                if stat == "display" then self.pcStatsRef.display = tier.to end
                                if stat == "cooling" then self.pcStatsRef.cooling = tier.to end
                                if stat == "psu" then self.pcStatsRef.psu = tier.to end
                            end
                            self.upgrades = self:getVisibleUpgrades()
                        elseif not canBuyMoney then
                            self.purchaseMessage = "Dinero insuficiente. Necesitas $" .. tier.price
                            self.purchaseMsgTimer = 2.0
                        elseif not canBuyWatts then
                            self.purchaseMessage = "Fuente de poder insuficiente. Necesita mas watts."
                            self.purchaseMsgTimer = 2.0
                        end
                    end
                else
                    local upg = self.upgrades[btn.index]
                    if upg and self.trabajoRef then
                        if self.trabajoRef.money >= upg.price and not upg.purchased then
                            self.trabajoRef.money = self.trabajoRef.money - upg.price
                            upg.purchased = true
                            self.upgradeLevels[upg.stat] = (self.upgradeLevels[upg.stat] or 0) + 1
                            self.purchaseMessage = upg.name .. " mejorado a " .. upg.upgrade .. "!"
                            self.purchaseMsgTimer = 2.0
                            if self.onUpgradePurchased then self.onUpgradePurchased(upg.stat, self.upgradeLevels[upg.stat]) end
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
                end
            elseif btn.action == "buyapp" then
                local app = self.appStore[btn.index]
                if app and self.trabajoRef and not app.purchased and app.milestone ~= "locked" then
                    if self.trabajoRef.money >= app.price then
                        self.trabajoRef.money = self.trabajoRef.money - app.price
                        app.purchased = true
                        self.purchaseMessage = app.name .. " instalado!"
                        self.purchaseMsgTimer = 2.0
                        if self.onAppPurchased then self.onAppPurchased(app.id) end
                    else
                        self.purchaseMessage = "Dinero insuficiente."
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
                elseif btn.label == "Atras" then
                    self:navigateBack()
                elseif btn.label == "Adelante" then
                    self:navigateForward()
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

function Explorer:wheelmoved(x, y)
    if self.currentPage == "upgrades" and self.shopView == "grid" then
        self.shopScrollY = self.shopScrollY - y * 20
        if self.shopScrollY < 0 then self.shopScrollY = 0 end
    elseif self.currentPage == "apps" then
        self.appStoreScrollY = self.appStoreScrollY - y * 20
        if self.appStoreScrollY < 0 then self.appStoreScrollY = 0 end
    end
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
    local colW = {200, 70, 80}
    local rowH = 22
    local songIndex = 0

    local categories = {
        {id = "tendencias", label = "Tendencias"},
        {id = "videojuegos", label = "Musica de Videojuegos"},
    }

    local curY = y + 58

    for _, cat in ipairs(categories) do
        love.graphics.setColor(W95.highlight)
        love.graphics.rectangle("fill", tableX, curY, w - 40, rowH)
        love.graphics.setColor(W95.highlightText)
        love.graphics.printf(cat.label, tableX, curY + 5, w - 40, "center")
        curY = curY + rowH

        love.graphics.setColor(W95.highlight)
        love.graphics.rectangle("fill", tableX, curY, w - 40, rowH)
        love.graphics.setColor(W95.highlightText)
        local headers = {"Cancion", "Precio", "Comprar"}
        local hx = tableX + 4
        for i, header in ipairs(headers) do
            love.graphics.print(header, hx, curY + 5)
            hx = hx + colW[i]
        end
        curY = curY + rowH

        for i, song in ipairs(self.musicSongs) do
            if song.category == cat.id then
                songIndex = songIndex + 1
                local isEven = songIndex % 2 == 0

                if isEven then
                    love.graphics.setColor({0.92, 0.92, 0.92})
                    love.graphics.rectangle("fill", tableX, curY, w - 40, rowH)
                end

                love.graphics.setColor(W95.text)
                love.graphics.print(song.name, tableX + 4, curY + 5)

                local rx = tableX + colW[1]
                if song.purchased then
                    love.graphics.setColor(W95.green)
                    love.graphics.print("Comprado", rx, curY + 5)
                else
                    love.graphics.setColor({0.8, 0, 0})
                    love.graphics.print("$" .. song.price, rx, curY + 5)
                end

                rx = rx + colW[2]
                local btnW = 56
                local btnH = 18
                local btnX = rx
                local btnY = curY + 2

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
                curY = curY + rowH
            end
        end

        love.graphics.setColor(W95.borderDark)
        love.graphics.line(x + 20, curY, x + w - 20, curY)
        curY = curY + 4
    end

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
