local Email = {}
Email.__index = Email

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
    link = {0, 0, 0.8},
}

local projectDifficulties = {
    {id = "facil", label = "Fácil", color = {0.2, 0.8, 0.2}, hpMult = 1.0, rewardMult = 1.0},
    {id = "normal", label = "Normal", color = {0.9, 0.9, 0.2}, hpMult = 2.67, rewardMult = 1.4},
    {id = "dificil", label = "Difícil", color = {0.9, 0.6, 0.2}, hpMult = 4.67, rewardMult = 1.8},
    {id = "muy_dificil", label = "Muy Difícil", color = {0.9, 0.3, 0.3}, hpMult = 7.33, rewardMult = 2.3},
    {id = "pesadilla", label = "Pesadilla", color = {0.6, 0.0, 0.6}, hpMult = 10.67, rewardMult = 3.0},
}

local function getDifficultyForProject(index)
    if index <= 4 then return projectDifficulties[1]
    elseif index <= 8 then return projectDifficulties[2]
    elseif index <= 13 then return projectDifficulties[3]
    elseif index <= 17 then return projectDifficulties[4]
    else return projectDifficulties[5]
    end
end

local function generateProjectBody(baseBody, diff, reward)
    return baseBody .. "\n\nDificultad: " .. diff.label .. "\nRecompensa: $" .. reward
end

local allEmails = {
}

function Email.new(x, y)
    local self = setmetatable({}, Email)
    self.window = WindowManager.new("Correo Electronico", x or 180, y or 90, 620, 500)

    self.inbox = {}
    self.selectedEmail = nil
    self.selectedIndex = 0
    self.lastMX = 0
    self.lastMY = 0
    self.trabajoRef = nil
    self.notepadRef = nil
    self.onProjectPopup = nil
    self.emailIndex = 1
    self.pendingApplications = 0
    self.workSinceLastEmail = 0
    self.emailChance = 0.015
    self.emailBonus = 0
    self.emailCooldown = 0
    self.emailCooldownTime = 10
    self.chimeSound = nil
    self.initialized = false
    self.smallFont = love.graphics.newFont(11)
    self.buttons = {}
    self.scrollY = 0
    self.inboxScrollY = 0
    self.maxInboxScroll = 0
    self.malwareSent = false
    self.downloadIconActive = false
    self.totalTasksDone = 0

    local ok, snd = pcall(love.audio.newSource, "assets/sounds/CHIMES.WAV", "static")
    if ok then
        self.chimeSound = snd
        self.chimeSound:setVolume(0.6)
    end

    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, x, y, button)
        return self:handleClick(x, y, button)
    end

    self.initialized = true

    local welcomeEmail = {
        subject = "Bienvenido a su nuevo puesto",
        sender = "admin@empresa.com",
        type = "news",
        body = "Estimado empleado:\n\nBienvenido a su nuevo puesto.\nLe explicaremos como funciona:\n\n1. GANAR DINERO:\nHaga click en el icono \"Trabajo\"\ny presione \"Trabajar\". Cada tarea\nle paga $1-2. Trabaje mas para\nganar mas y mejorar su PC.\n\n2. OBJETIVOS:\nComplete objetivos para\ndesbloquear nuevas aplicaciones.\n\n3. CORREO:\nRevise su correo regularmente.\nAlgunos correos son ofertas de\nproyectos con mejor recompensa.\nPero cuidado: hay correos\npeligrosos que le roban dinero.\n\n4. PROYECTOS:\nSus componentes generan circulos\nde progreso automaticamente.\nMejores componentes = mas rapido.\nComplete la barra antes de que\nse acabe el tiempo.\n\nSu gerente.",
        handled = true,
        read = true,
    }
    table.insert(self.inbox, welcomeEmail)
    self.selectedIndex = 1
    self.selectedEmail = welcomeEmail

    return self
end

function Email:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function Email:playChime()
    if self.chimeSound and self.initialized and self.canPlayChime then
        if self.canPlayChime() then
            self.chimeSound:stop()
            self.chimeSound:play()
        end
    end
end

function Email:addNextEmail()
    if self.emailIndex <= #allEmails then
        local email = allEmails[self.emailIndex]
        email.read = false
        email.handled = false
        if email.type == "project" then
            email.daysLeft = 10
        end
        table.insert(self.inbox, email)
        self.emailIndex = self.emailIndex + 1
        self:playChime()
    end
end

function Email:addEmailToInbox(email)
    email.read = false
    email.handled = false
    if email.type == "project" then
        email.daysLeft = 10
    end
    table.insert(self.inbox, email)
    self.selectedIndex = #self.inbox
    self.selectedEmail = email
    self.scrollY = 0
    self:playChime()
end

function Email:onWorkCompleted()
    self.workSinceLastEmail = self.workSinceLastEmail + 1
    self.totalTasksDone = self.totalTasksDone + 1

    if self.emailCooldown > 0 then
        return
    end

    if not self.malwareSent and self.totalTasksDone >= 15 then
        self.malwareSent = true
        self:addEmailToInbox({
            subject = "Descarga disponible: WinOptimizer Pro",
            sender = "downloads@freeware.com",
            type = "malware",
            body = "Hola!\n\nHemos detectado que su PC\npodria funcionar mejor.\n\nDescargue WinOptimizer Pro\npara optimizar su sistema.\n\nGratis por tiempo limitado!",
            moneyLoss = 0,
            isDesktopMalware = true,
        })
        self.emailCooldown = self.emailCooldownTime
        return
    end

    if self.workSinceLastEmail >= 12 then
        self.emailBonus = 0.20
    end

    local chance = math.min(1.0, self.emailChance + self.emailBonus)
    if math.random() < chance then
        self.workSinceLastEmail = 0
        self.emailChance = 0.015
        self.emailBonus = 0
        self.emailCooldown = self.emailCooldownTime

        if self.pendingApplications > 0 then
            self.pendingApplications = self.pendingApplications - 1
            local accepted = math.random() < 0.5
            if accepted then
                self:addEmailToInbox({
                    subject = "CV ACEPTADO - Felicidades!",
                    sender = "rrhh@empresa.com",
                    type = "news",
                    body = "Estimado candidato:\n\nSu CV ha sido aceptado.\nSe le contactara pronto para\nuna entrevista.\n\nSaludos cordiales.",
                    moneyReward = 50,
                })
                if self.trabajoRef then
                    self.trabajoRef.tabUnlocked = true
                end
            else
                self:addEmailToInbox({
                    subject = "CV Rechazado",
                    sender = "rrhh@empresa.com",
                    type = "news",
                    body = "Estimado candidato:\n\nLamentamos informarle que\nsu perfil no coincide con\nnuestras necesidades.\n\nLe deseamos exito.",
                })
            end
        else
            if self.emailIndex <= #allEmails then
                self:addNextEmail()
            end
        end
    else
        self.emailChance = math.min(1.0, self.emailChance + 0.02)
    end
end

function Email:update(dt)
    if self.emailCooldown > 0 then
        self.emailCooldown = self.emailCooldown - dt
    end
    
    if not self.dayTimer then self.dayTimer = 0 end
    self.dayTimer = self.dayTimer + dt
    if self.dayTimer >= 60 then
        self.dayTimer = self.dayTimer - 60
        for i = #self.inbox, 1, -1 do
            local e = self.inbox[i]
            if e.type == "project" and e.daysLeft and not e.handled then
                e.daysLeft = e.daysLeft - 1
                if e.daysLeft <= 0 then
                    table.remove(self.inbox, i)
                    if self.selectedEmail == e then
                        self.selectedEmail = nil
                        self.selectedIndex = 0
                    end
                end
            end
        end
    end
end

function Email:drawBevel(x, y, w, h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Email:drawInset(x, y, w, h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Email:getActionButtonText(email)
    if email.type == "job" then return "Enviar CV"
    elseif email.type == "malware" then return "Descargar"
    elseif email.type == "beneficial" then return "Descargar"
    elseif email.type == "project" then return "Aceptar"
    elseif email.type == "personal_unlock" then return "Descargar"
    else return nil
    end
end

function Email:drawContent(cx, cy, cw, ch)
    self.buttons = {}
    local prevFont = love.graphics.getFont()
    love.graphics.setFont(self.smallFont)

    local menuH = 18
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx, cy, cw, menuH)
    local menuItems = {"Archivo", "Editar", "Ver", "Correo", "Ayuda"}
    local mx_off = cx + 4
    for _, item in ipairs(menuItems) do
        local iw = self.smallFont:getWidth(item) + 12
        love.graphics.setColor(W95.text)
        love.graphics.print(item, mx_off, cy + 3)
        mx_off = mx_off + iw
    end

    local toolbarH = 28
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx, cy + menuH, cw, toolbarH)
    self:drawBevel(cx, cy + menuH, cw, toolbarH)

    local tbButtons = {"Nuevo", "Responder", "Reenviar", "Eliminar"}
    local tbX = cx + 4
    local tbY = cy + menuH + 3
    local tbW = 60
    local tbH = 22
    for i, label in ipairs(tbButtons) do
        local bx = tbX + (i - 1) * (tbW + 2)
        love.graphics.setColor(W95.bg)
        love.graphics.rectangle("fill", bx, tbY, tbW, tbH)
        self:drawBevel(bx, tbY, tbW, tbH)
        love.graphics.setColor(W95.text)
        love.graphics.printf(label, bx, tbY + 5, tbW, "center")
    end

    local listY = cy + menuH + toolbarH
    local listH = 140
    local listW = cw

    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", cx, listY, listW, listH)
    self:drawInset(cx, listY, listW, listH)

    local colW = {20, cw - 100, 80}
    local headers = {"", "Asunto", "De"}
    local headerY = listY + 2

    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx + 2, headerY, listW - 4, 16)

    local hx = cx + 6
    for i, header in ipairs(headers) do
        love.graphics.setColor(W95.text)
        love.graphics.print(header, hx, headerY + 2)
        hx = hx + colW[i]
    end

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(cx + 4, headerY + 16, cx + listW - 4, headerY + 16)

    local inboxContentY = headerY + 18
    local inboxContentH = listH - 20
    local totalInboxH = #self.inbox * 18
    self.maxInboxScroll = math.max(0, totalInboxH - inboxContentH)

    love.graphics.setScissor(cx + 2, inboxContentY, listW - 4, inboxContentH)
    for i, email in ipairs(self.inbox) do
        local ey = inboxContentY + (i - 1) * 18 + self.inboxScrollY
        if ey + 18 < inboxContentY or ey > inboxContentY + inboxContentH then

        else
        local isSelected = (i == self.selectedIndex)
        local mx, my = love.mouse.getPosition()
        local isHovered = mx >= cx + 2 and mx <= cx + listW - 2 and my >= ey and my <= ey + 17

        if isSelected then
            love.graphics.setColor(W95.highlight)
            love.graphics.rectangle("fill", cx + 2, ey, listW - 4, 17)
            love.graphics.setColor(W95.highlightText)
        elseif isHovered then
            love.graphics.setColor({0.85, 0.85, 0.85})
            love.graphics.rectangle("fill", cx + 2, ey, listW - 4, 17)
            love.graphics.setColor(W95.text)
        else
            love.graphics.setColor(email.read and W95.textDim or W95.text)
        end

        local ex = cx + 6
        love.graphics.print(email.handled and "  " or " * ", ex, ey + 1)
        ex = ex + colW[1]
        love.graphics.print(email.subject, ex, ey + 1)
        ex = ex + colW[2]
        love.graphics.print(email.sender, ex, ey + 1)

        if email.type == "project" and email.daysLeft and not email.handled then
            if email.daysLeft <= 3 then
                love.graphics.setColor({0.8, 0, 0})
            else
                love.graphics.setColor({0.6, 0.4, 0})
            end
            love.graphics.print(email.daysLeft .. "d", cx + listW - 24, ey + 1)
        end

        table.insert(self.buttons, {x = cx + 2, y = ey, w = listW - 4, h = 17, action = "select", index = i})
        end
    end
    love.graphics.setScissor()

    if self.maxInboxScroll > 0 then
        local scrollBarX = cx + listW - 14
        local scrollBarY = inboxContentY
        local scrollBarH = inboxContentH
        local thumbH = math.max(20, scrollBarH * (inboxContentH / totalInboxH))
        local thumbY = scrollBarY + (-self.inboxScrollY / self.maxInboxScroll) * (scrollBarH - thumbH)

        love.graphics.setColor({0.7, 0.7, 0.7})
        love.graphics.rectangle("fill", scrollBarX, scrollBarY, 10, scrollBarH)
        love.graphics.setColor({0.5, 0.5, 0.5})
        love.graphics.rectangle("fill", scrollBarX, thumbY, 10, thumbH)
    end

    local contentY = listY + listH + 4
    local contentH = ch - menuH - toolbarH - listH - 50

    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", cx + 2, contentY, cw - 4, contentH)
    self:drawInset(cx + 2, contentY, cw - 4, contentH)

    if self.selectedEmail then
        local email = self.selectedEmail

        love.graphics.setColor(W95.text)
        love.graphics.print("De: " .. email.sender, cx + 8, contentY + 6)
        love.graphics.print("Asunto: " .. email.subject, cx + 8, contentY + 20)

        if email.type == "project" and email.daysLeft and not email.handled then
            if email.daysLeft <= 3 then
                love.graphics.setColor({0.8, 0, 0})
            else
                love.graphics.setColor({0.6, 0.4, 0})
            end
            love.graphics.print("Dias restantes: " .. email.daysLeft, cx + cw - 120, contentY + 6)
        end

        love.graphics.setColor(W95.borderDark)
        love.graphics.line(cx + 8, contentY + 36, cx + cw - 10, contentY + 36)

        local lines = {}
        for line in email.body:gmatch("[^\n]*") do
            table.insert(lines, line)
        end

        local lineH = 14
        local bodyY = contentY + 40
        local bodyH = contentH - 44
        local totalTextH = #lines * lineH
        self.maxScroll = math.max(0, totalTextH - bodyH)

        love.graphics.setScissor(cx + 2, bodyY, cw - 4, bodyH)
        for j, line in ipairs(lines) do
            local ly = bodyY + (j - 1) * lineH + self.scrollY
            love.graphics.setColor(W95.text)
            love.graphics.print(line, cx + 10, ly)
        end
        love.graphics.setScissor()

        if not email.handled then
            local btnY = contentY + contentH - 28
            local btnW = 90
            local btnH = 22
            local actionText = self:getActionButtonText(email)

            if actionText then
                local actionX = cx + cw - btnW * 2 - 16
                local mx, my = love.mouse.getPosition()
                local actionHov = mx >= actionX and mx <= actionX + btnW and my >= btnY and my <= btnY + btnH
                love.graphics.setColor(actionHov and {0.85, 0.85, 0.85} or W95.bg)
                love.graphics.rectangle("fill", actionX, btnY, btnW, btnH)
                self:drawBevel(actionX, btnY, btnW, btnH)
                love.graphics.setColor(W95.text)
                love.graphics.printf(actionText, actionX, btnY + 4, btnW, "center")
                table.insert(self.buttons, {x = actionX, y = btnY, w = btnW, h = btnH, action = "download"})

                local deleteX = cx + cw - btnW - 8
                local delHov = mx >= deleteX and mx <= deleteX + btnW and my >= btnY and my <= btnY + btnH
                love.graphics.setColor(delHov and {0.85, 0.85, 0.85} or W95.bg)
                love.graphics.rectangle("fill", deleteX, btnY, btnW, btnH)
                self:drawBevel(deleteX, btnY, btnW, btnH)
                love.graphics.setColor(W95.text)
                love.graphics.printf("Eliminar", deleteX, btnY + 4, btnW, "center")
                table.insert(self.buttons, {x = deleteX, y = btnY, w = btnW, h = btnH, action = "delete"})
            else
                local deleteX = cx + cw - btnW - 8
                local mx, my = love.mouse.getPosition()
                local delHov = mx >= deleteX and mx <= deleteX + btnW and my >= btnY and my <= btnY + btnH
                love.graphics.setColor(delHov and {0.85, 0.85, 0.85} or W95.bg)
                love.graphics.rectangle("fill", deleteX, btnY, btnW, btnH)
                self:drawBevel(deleteX, btnY, btnW, btnH)
                love.graphics.setColor(W95.text)
                love.graphics.printf("Eliminar", deleteX, btnY + 4, btnW, "center")
                table.insert(self.buttons, {x = deleteX, y = btnY, w = btnW, h = btnH, action = "delete"})
            end
        else
            love.graphics.setColor(W95.textDim)
            love.graphics.printf("Correo procesado", cx + 8, contentY + contentH - 20, cw - 16, "center")
        end
    else
        love.graphics.setColor(W95.textDim)
        love.graphics.printf("Seleccione un correo para leer", cx + 8, contentY + contentH / 2 - 6, cw - 16, "center")
    end

    local statusH = 20
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx, cy + ch - statusH, cw, statusH)
    self:drawBevel(cx, cy + ch - statusH, cw, statusH)
    love.graphics.setColor(W95.text)
    local unread = 0
    for _, e in ipairs(self.inbox) do
        if not e.read then unread = unread + 1 end
    end
    love.graphics.print("  Correos: " .. #self.inbox .. "  |  No leidos: " .. unread, cx + 4, cy + ch - statusH + 4)

    love.graphics.setFont(prevFont)
end

function Email:handleClick(x, y, button)
    if button ~= 1 then return false end
    if not self.window.visible then return false end

    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "select" then
                self.selectedIndex = btn.index
                self.selectedEmail = self.inbox[btn.index]
                self.scrollY = 0
                if self.selectedEmail then
                    self.selectedEmail.read = true
                end
            elseif btn.action == "download" and self.selectedEmail and not self.selectedEmail.handled then
                self.selectedEmail.handled = true
                if self.selectedEmail.type == "job" and self.selectedEmail.moneyReward and self.trabajoRef then
                    self.trabajoRef.money = self.trabajoRef.money + self.selectedEmail.moneyReward
                    self.trabajoRef.totalEarned = self.trabajoRef.totalEarned + self.selectedEmail.moneyReward
                    self.pendingApplications = self.pendingApplications + 1
                    self.workSinceApplication = 0
    self.workThreshold = 1 + math.random(10)
                    if self.notepadRef then
                        self.notepadRef.emailJobsAccepted = (self.notepadRef.emailJobsAccepted or 0) + 1
                    end
                elseif self.selectedEmail.type == "malware" and self.selectedEmail.isDesktopMalware then
                    self.downloadIconActive = true
                    if self.notepadRef then
                        self.notepadRef.malwareDownloaded = (self.notepadRef.malwareDownloaded or 0) + 1
                    end
                elseif self.selectedEmail.type == "malware" and self.selectedEmail.moneyLoss and self.selectedEmail.moneyLoss > 0 and self.trabajoRef then
                    self.trabajoRef.money = math.max(0, self.trabajoRef.money - self.selectedEmail.moneyLoss)
                    if self.notepadRef then
                        self.notepadRef.malwareDownloaded = (self.notepadRef.malwareDownloaded or 0) + 1
                    end
                elseif self.selectedEmail.type == "project" and self.selectedEmail.projectData and self.trabajoRef then
                    if self.selectedEmail.daysLeft and self.selectedEmail.daysLeft <= 0 then
                        return true
                    end
                    if not self.trabajoRef.activeProject then
                        self.trabajoRef.tabUnlocked = true
                        self.trabajoRef:startProject(self.selectedEmail.projectData)
                        self.selectedEmail.handled = true
                    else
                        if self.onProjectPopup then
                            self.onProjectPopup()
                        end
                    end
                elseif self.selectedEmail.type == "personal_unlock" then
                    self.selectedEmail.handled = true
                    if self.notepadRef then
                        self.notepadRef.personalReady = true
                    end
                elseif self.selectedEmail.type == "beneficial" and not self.selectedEmail.handled then
                    self.selectedEmail.handled = true
                    local bonus = 10 + math.random(20)
                    if self.trabajoRef then
                        self.trabajoRef.money = self.trabajoRef.money + bonus
                        self.trabajoRef.totalEarned = self.trabajoRef.totalEarned + bonus
                    end
                end
            elseif btn.action == "delete" and self.selectedEmail and not self.selectedEmail.handled then
                if self.notepadRef then
                    self.notepadRef.emailsDeleted = (self.notepadRef.emailsDeleted or 0) + 1
                    if self.selectedEmail.type == "malware" then
                        self.notepadRef.malwareDeleted = (self.notepadRef.malwareDeleted or 0) + 1
                    end
                end
                local idx = nil
                for i, e in ipairs(self.inbox) do
                    if e == self.selectedEmail then
                        idx = i
                        break
                    end
                end
                if idx then
                    table.remove(self.inbox, idx)
                end
                self.selectedEmail = nil
                self.selectedIndex = 0
            end
            return true
        end
    end
    return false
end

function Email:draw(mx, my)
    self.lastMX = mx
    self.lastMY = my
    self.window:drawFrame()
end

function Email:hitTest(mx, my)
    return self.window:hitTest(mx, my)
end

function Email:mousepressed(x, y, button)
    return self.window:mousepressed(x, y, button)
end

function Email:mousereleased(x, y, button)
    self.window:mousereleased(x, y, button)
end

function Email:mousemoved(x, y)
    self.window:mousemoved(x, y)
end

function Email:wheelmoved(x, y)
    if not self.window.visible or self.window.minimized then return end
    local mx, my = love.mouse.getPosition()
    local cx, cy, cw, ch = self.window:getContentArea()
    if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
        local menuH = 18
        local toolbarH = 28
        local inboxY = cy + menuH + toolbarH
        local inboxH = 140

        if my >= inboxY and my <= inboxY + inboxH then
            self.inboxScrollY = self.inboxScrollY + y * 18
            if self.inboxScrollY > 0 then self.inboxScrollY = 0 end
            if self.maxInboxScroll and self.inboxScrollY < -self.maxInboxScroll then
                self.inboxScrollY = -self.maxInboxScroll
            end
        else
            self.scrollY = self.scrollY + y * 20
            if self.scrollY > 0 then self.scrollY = 0 end
            if self.maxScroll and self.scrollY < -self.maxScroll then
                self.scrollY = -self.maxScroll
            end
        end
    end
end

return Email
