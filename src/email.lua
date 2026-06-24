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

local allEmails = {
    {
        subject = "Oferta de trabajo - digitador",
        sender = "empleos@trabajo.com",
        type = "job",
        body = "Se requiere digitador con experiencia.\nSalario: $15/hora.\nEnvie su CV a este correo.",
        moneyReward = 15,
    },
    {
        subject = "NOTICIAS: Nuevo Pentium Pro",
        sender = "noticias@tech.com",
        type = "news",
        body = "Intel anuncia el nuevo Pentium Pro\na 200MHz. Disponible en tiendas\na partir del proximo mes.",
    },
    {
        subject = "Ganaste un premio!",
        sender = "premio@loteria.com",
        type = "malware",
        body = "Felicidades! Ha ganado $10,000!\nDescargue el archivo adjunto\npara reclamar su premio.",
        moneyLoss = 25,
    },
    {
        subject = "Descarga Winamp gratis",
        sender = "downloads@winamp.com",
        type = "ad",
        body = "Obtenga Winamp GRATIS!\nLa mejor reproductor de musica\npara su PC con Windows 95.",
    },
    {
        subject = "Trabajo nocturno - datos",
        sender = "nightjob@freelance.net",
        type = "job",
        body = "Se busca persona para entrada\nde datos nocturna. $20/hora.\nHorario: 10pm - 6am.",
        moneyReward = 20,
    },
    {
        subject = "Alerta de seguridad",
        sender = "security@microsoft.com",
        type = "news",
        body = "Microsoft recomienda instalar\nel parche de seguridad MS95-001.\nDisponible en Windows Update.",
    },
    {
        subject = "Software pirata - gratis",
        sender = "free@warez.com",
        type = "malware",
        body = "Obtenga Office 95 gratis!\nSin licencia requerida.\nDescargue el archivo adjunto.",
        moneyLoss = 30,
    },
    {
        subject = "Oferta especial - Disco duro",
        sender = "ofertas@compumail.com",
        type = "ad",
        body = "Disco duro IDE 1.2GB por solo $99!\nOferta por tiempo limitado.\nLlame al 555-0123.",
    },
    {
        subject = "Freelance - traduccion",
        sender = "traduccion@work.com",
        type = "job",
        body = "Se necesita traductor ingles-espanol.\nPago por palabra. Trabajo remoto.\nResponda para mas informacion.",
        moneyReward = 25,
    },
    {
        subject = "Actualizacion de BIOS",
        sender = "bios@ami.com",
        type = "news",
        body = "AMI BIOS ofrece nueva actualizacion\npara mejorar el rendimiento.\nDescargue desde nuestro sitio.",
    },
    {
        subject = "Club de inversionistas",
        sender = "inversiones@vip.com",
        type = "malware",
        body = "Unase al club de inversionistas\nmas exclusivo del mundo.\nGanancias garantizadas al 300%.",
        moneyLoss = 50,
    },
    {
        subject = "Anuncio: Impresoras baratas",
        sender = "ventas@printers.com",
        type = "ad",
        body = "Impresoras Matriciales desde $49!\nEnvio gratis a todo el pais.\nVisite nuestra tienda en linea.",
    },
}

function Email.new(x, y)
    local self = setmetatable({}, Email)
    self.window = WindowManager.new("Correo Electronico", x or 180, y or 90, 500, 380)

    self.inbox = {}
    self.selectedEmail = nil
    self.selectedIndex = 0
    self.lastMX = 0
    self.lastMY = 0
    self.trabajoRef = nil
    self.notepadRef = nil
    self.emailIndex = 1
    self.emailsPerBatch = 3
    self.pendingApplications = 0
    self.workSinceApplication = 0
    self.chimeSound = nil

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

    self:loadNextBatch()

    return self
end

function Email:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function Email:playChime()
    if self.chimeSound then
        self.chimeSound:stop()
        self.chimeSound:play()
    end
end

function Email:loadNextBatch()
    self.inbox = {}
    for i = 1, self.emailsPerBatch do
        if self.emailIndex <= #allEmails then
            local email = allEmails[self.emailIndex]
            email.read = false
            email.handled = false
            table.insert(self.inbox, email)
            self.emailIndex = self.emailIndex + 1
        end
    end
    if #self.inbox > 0 then
        self.selectedIndex = 1
        self.selectedEmail = self.inbox[1]
    end
    self:playChime()
end

function Email:addEmailToInbox(email)
    email.read = false
    email.handled = false
    table.insert(self.inbox, email)
    if #self.inbox == 1 then
        self.selectedIndex = 1
        self.selectedEmail = self.inbox[1]
    end
    self:playChime()
end

function Email:onWorkCompleted()
    if self.pendingApplications > 0 then
        self.workSinceApplication = self.workSinceApplication + 1
        local threshold = 5 + math.random(11)
        if self.workSinceApplication >= threshold then
            self.workSinceApplication = 0
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
            else
                self:addEmailToInbox({
                    subject = "CV Rechazado",
                    sender = "rrhh@empresa.com",
                    type = "news",
                    body = "Estimado candidato:\n\nLamentamos informarle que\nsu perfil no coincide con\nnuestras necesidades.\n\nLe deseamos exito.",
                })
            end
        end
    end
end

function Email:update(dt)
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

function Email:drawContent(cx, cy, cw, ch)
    self.buttons = {}

    local prevFont = love.graphics.getFont()
    local smallFont = love.graphics.newFont(11)
    love.graphics.setFont(smallFont)

    local menuH = 18
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx, cy, cw, menuH)
    local menuItems = {"Archivo", "Editar", "Ver", "Correo", "Ayuda"}
    local mx_off = cx + 4
    for _, item in ipairs(menuItems) do
        local iw = smallFont:getWidth(item) + 12
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
    local listH = 120
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

    for i, email in ipairs(self.inbox) do
        local ey = headerY + 18 + (i - 1) * 18
        if ey + 18 > listY + listH then break end

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

        table.insert(self.buttons, {x = cx + 2, y = ey, w = listW - 4, h = 17, action = "select", index = i})
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

        love.graphics.setColor(W95.borderDark)
        love.graphics.line(cx + 8, contentY + 36, cx + cw - 10, contentY + 36)

        local lines = {}
        for line in email.body:gmatch("[^\n]*") do
            table.insert(lines, line)
        end

        local lineH = 14
        for j, line in ipairs(lines) do
            local ly = contentY + 40 + (j - 1) * lineH
            if ly + lineH < contentY + contentH then
                love.graphics.setColor(W95.text)
                love.graphics.print(line, cx + 10, ly)
            end
        end

        if not email.handled then
            local btnY = contentY + contentH - 28
            local btnW = 90
            local btnH = 22

            local actionX = cx + cw - btnW * 2 - 16
            local mx, my = love.mouse.getPosition()
            local actionHov = mx >= actionX and mx <= actionX + btnW and my >= btnY and my <= btnY + btnH
            love.graphics.setColor(actionHov and {0.85, 0.85, 0.85} or W95.bg)
            love.graphics.rectangle("fill", actionX, btnY, btnW, btnH)
            self:drawBevel(actionX, btnY, btnW, btnH)
            love.graphics.setColor(W95.text)
            love.graphics.printf("Descargar", actionX, btnY + 4, btnW, "center")
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

    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "select" then
                self.selectedIndex = btn.index
                self.selectedEmail = self.inbox[btn.index]
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
                    if self.notepadRef then
                        self.notepadRef.emailJobsAccepted = (self.notepadRef.emailJobsAccepted or 0) + 1
                    end
                elseif self.selectedEmail.type == "malware" and self.selectedEmail.moneyLoss and self.trabajoRef then
                    self.trabajoRef.money = math.max(0, self.trabajoRef.money - self.selectedEmail.moneyLoss)
                    if self.notepadRef then
                        self.notepadRef.malwareDownloaded = (self.notepadRef.malwareDownloaded or 0) + 1
                    end
                end
            elseif btn.action == "delete" and self.selectedEmail and not self.selectedEmail.handled then
                self.selectedEmail.handled = true
                if self.notepadRef then
                    self.notepadRef.emailsDeleted = (self.notepadRef.emailsDeleted or 0) + 1
                    if self.selectedEmail.type == "malware" then
                        self.notepadRef.malwareDeleted = (self.notepadRef.malwareDeleted or 0) + 1
                    end
                end
            end
            return true
        end
    end
    return true
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

return Email
