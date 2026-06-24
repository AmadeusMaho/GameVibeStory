local Winamp = {}
Winamp.__index = Winamp

local CursorManager = require("src.cursor")

local WA = {
    bg = {0.05, 0.05, 0.1},
    panelBg = {0.1, 0.1, 0.15},
    borderLight = {0.3, 0.3, 0.35},
    borderDark = {0.02, 0.02, 0.05},
    text = {0, 1, 0},
    textDim = {0, 0.5, 0},
    textBright = {0.2, 1, 0.2},
    titleBg = {0.0, 0.0, 0.3},
    titleText = {1, 1, 1},
    buttonBg = {0.15, 0.15, 0.2},
    buttonHover = {0.25, 0.25, 0.3},
    sliderBg = {0.05, 0.05, 0.1},
    sliderFill = {0, 0.8, 0},
    playlistBg = {0, 0, 0.15},
    playlistText = {0, 1, 0},
    playlistSelected = {0, 0, 0.5},
    playlistHighlight = {0.2, 1, 0.2},
    eqGreen = {0, 0.9, 0},
    eqYellow = {0.9, 0.9, 0},
    eqRed = {0.9, 0, 0},
}

function Winamp.new(x, y)
    local self = setmetatable({}, Winamp)
    self.x = x or 100
    self.y = y or 100
    self.visible = false
    self.dragging = false
    self.dragOffsetX = 0
    self.dragOffsetY = 0

    self.playerW = 275
    self.playerH = 116
    self.eqW = 275
    self.eqH = 116
    self.playlistW = 275
    self.playlistH = 150

    self.totalW = self.playerW
    self.totalH = self.playerH + self.eqH + self.playlistH

    self.playing = false
    self.paused = false
    self.currentTime = 0
    self.totalTime = 0
    self.seekPos = 0
    self.volume = 0.7
    self.balance = 0
    self.shuffle = false
    self.repeatOn = false

    self.eqOn = true
    self.eqAuto = false
    self.eqSliders = {}
    for i = 1, 10 do
        self.eqSliders[i] = 0.5
    end
    self.preamp = 0.5

    self.playlist = {
        {title = "Mori Calliope - Go-Getters", duration = 195},
        {title = "CircusP - Goodbye", duration = 204},
        {title = "AmaLee - Siren", duration = 242},
        {title = "Crusher-P - Echo", duration = 230},
        {title = "MB3 - Silent City", duration = 243},
        {title = "Sumex0 - Please Wait", duration = 169},
        {title = "Omaru Polka - Persona", duration = 296},
    }
    self.selectedTrack = 1
    self.scrollOffset = 0

    self.hoveredButton = nil
    self.hoveredSlider = nil
    self.buttons = {}

    return self
end

function Winamp:formatTime(seconds)
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

function Winamp:toggleVisible()
    self.visible = not self.visible
end

function Winamp:update(dt)
    if not self.visible then return end

    if self.playing and not self.paused then
        self.currentTime = self.currentTime + dt
        if self.currentTime >= self.totalTime then
            self:nextTrack()
        end
        self.seekPos = self.currentTime / self.totalTime
    end
end

function Winamp:nextTrack()
    if self.selectedTrack < #self.playlist then
        self.selectedTrack = self.selectedTrack + 1
    elseif self.repeatOn then
        self.selectedTrack = 1
    else
        self.playing = false
    end
    self.currentTime = 0
    self.totalTime = self.playlist[self.selectedTrack].duration
end

function Winamp:prevTrack()
    if self.currentTime > 3 then
        self.currentTime = 0
    elseif self.selectedTrack > 1 then
        self.selectedTrack = self.selectedTrack - 1
        self.currentTime = 0
        self.totalTime = self.playlist[self.selectedTrack].duration
    end
end

function Winamp:drawBorder(x, y, w, h, inset)
    if inset then
        love.graphics.setColor(WA.borderDark)
        love.graphics.line(x, y, x + w, y)
        love.graphics.line(x, y, x, y + h)
        love.graphics.setColor(WA.borderLight)
        love.graphics.line(x + w, y, x + w, y + h)
        love.graphics.line(x, y + h, x + w, y + h)
    else
        love.graphics.setColor(WA.borderLight)
        love.graphics.line(x, y, x + w, y)
        love.graphics.line(x, y, x, y + h)
        love.graphics.setColor(WA.borderDark)
        love.graphics.line(x + w, y, x + w, y + h)
        love.graphics.line(x, y + h, x + w, y + h)
    end
end

function Winamp:drawButton(x, y, w, h, label, hovered)
    love.graphics.setColor(hovered and WA.buttonHover or WA.buttonBg)
    love.graphics.rectangle("fill", x, y, w, h)
    self:drawBorder(x, y, w, h, true)
    love.graphics.setColor(WA.text)
    love.graphics.printf(label, x, y + (h - 12) / 2, w, "center")
end

function Winamp:drawPlayer(mx, my)
    local px, py = self.x, self.y

    love.graphics.setColor(WA.panelBg)
    love.graphics.rectangle("fill", px, py, self.playerW, self.playerH)
    self:drawBorder(px, py, self.playerW, self.playerH, false)

    love.graphics.setColor(WA.titleBg)
    love.graphics.rectangle("fill", px + 2, py + 2, self.playerW - 4, 14)
    love.graphics.setColor(WA.titleText)
    love.graphics.printf("WINAMP", px + 2, py + 2, self.playerW - 4, "center")

    love.graphics.setColor(WA.bg)
    love.graphics.rectangle("fill", px + 5, py + 20, self.playerW - 10, 28)
    self:drawBorder(px + 5, py + 20, self.playerW - 10, 28, true)

    local track = self.playlist[self.selectedTrack]
    local title = track and track.title or "No track"
    love.graphics.setColor(WA.textBright)
    love.graphics.printf(title, px + 10, py + 28, self.playerW - 20, "center")

    love.graphics.setColor(WA.textDim)
    love.graphics.print(string.format("%dkbps  %dkHz  %s", 128, 44, "stereo"), px + 10, py + 52)

    love.graphics.setColor(WA.sliderBg)
    love.graphics.rectangle("fill", px + 5, py + 68, self.playerW - 10, 8)
    love.graphics.setColor(WA.sliderFill)
    love.graphics.rectangle("fill", px + 5, py + 68, (self.playerW - 10) * self.seekPos, 8)
    self:drawBorder(px + 5, py + 68, self.playerW - 10, 8, true)

    local timeStr = self:formatTime(self.currentTime) .. " / " .. self:formatTime(self.totalTime)
    love.graphics.setColor(WA.text)
    love.graphics.printf(timeStr, px + 5, py + 80, self.playerW - 10, "right")

    local btnY = py + 95
    local btnH = 16
    local btnW = 24
    local btnGap = 2
    local btns = {"|<", "||", ">", ">|", "[ ]"}
    local startX = px + (self.playerW - (#btns * (btnW + btnGap) - btnGap)) / 2

    self.buttons = {}
    for i, label in ipairs(btns) do
        local bx = startX + (i - 1) * (btnW + btnGap)
        local hov = mx >= bx and mx <= bx + btnW and my >= btnY and my <= btnY + btnH
        self:drawButton(bx, btnY, btnW, btnH, label, hov)
        table.insert(self.buttons, {x = bx, y = btnY, w = btnW, h = btnH, action = label})
    end

    local shufX = px + 5
    local repX = px + self.playerW - 45
    local toggH = 12

    local shufHov = mx >= shufX and mx <= shufX + 38 and my >= btnY and my <= btnY + toggH
    love.graphics.setColor(self.shuffle and WA.textBright or WA.textDim)
    love.graphics.rectangle("fill", shufX, btnY, 38, toggH)
    love.graphics.setColor(self.shuffle and WA.text or WA.textDim)
    love.graphics.printf("SHUF", shufX, btnY, 38, "center")
    table.insert(self.buttons, {x = shufX, y = btnY, w = 38, h = toggH, action = "shuffle"})

    local repHov = mx >= repX and mx <= repX + 38 and my >= btnY and my <= btnY + toggH
    love.graphics.setColor(self.repeatOn and WA.textBright or WA.textDim)
    love.graphics.rectangle("fill", repX, btnY, 38, toggH)
    love.graphics.setColor(self.repeatOn and WA.text or WA.textDim)
    love.graphics.printf("REP", repX, btnY, 38, "center")
    table.insert(self.buttons, {x = repX, y = btnY, w = 38, h = toggH, action = "repeat"})

    local volX = px + 5
    local volY = py + self.playerH - 14
    love.graphics.setColor(WA.textDim)
    love.graphics.print("VOL", volX, volY)
    love.graphics.setColor(WA.sliderBg)
    love.graphics.rectangle("fill", volX + 25, volY + 2, 60, 8)
    love.graphics.setColor(WA.sliderFill)
    love.graphics.rectangle("fill", volX + 25, volY + 2, 60 * self.volume, 8)
    table.insert(self.buttons, {x = volX + 25, y = volY, w = 60, h = 12, action = "volume"})

    local balX = px + self.playerW - 85
    love.graphics.setColor(WA.textDim)
    love.graphics.print("BAL", balX, volY)
    love.graphics.setColor(WA.sliderBg)
    love.graphics.rectangle("fill", balX + 25, volY + 2, 55, 8)
    love.graphics.setColor(WA.sliderFill)
    local balMid = 27.5
    local balFill = math.abs(self.balance) * balMid
    if self.balance >= 0 then
        love.graphics.rectangle("fill", balX + 25 + balMid, volY + 2, balFill, 8)
    else
        love.graphics.rectangle("fill", balX + 25 + balMid - balFill, volY + 2, balFill, 8)
    end
    table.insert(self.buttons, {x = balX + 25, y = volY, w = 55, h = 12, action = "balance"})
end

function Winamp:drawEQ(mx, my)
    local px, py = self.x, self.y + self.playerH

    love.graphics.setColor(WA.panelBg)
    love.graphics.rectangle("fill", px, py, self.eqW, self.eqH)
    self:drawBorder(px, py, self.eqW, self.eqH, false)

    love.graphics.setColor(WA.titleBg)
    love.graphics.rectangle("fill", px + 2, py + 2, self.eqW - 4, 14)
    love.graphics.setColor(WA.titleText)
    love.graphics.printf("WINAMP EQUALIZER", px + 2, py + 2, self.eqW - 4, "center")

    local togY = py + 20
    local onHov = mx >= px + 5 and mx <= px + 30 and my >= togY and my <= togY + 12
    love.graphics.setColor(self.eqOn and WA.textBright or WA.textDim)
    love.graphics.rectangle("fill", px + 5, togY, 25, 12)
    love.graphics.setColor(WA.text)
    love.graphics.printf("ON", px + 5, togY, 25, "center")
    table.insert(self.buttons, {x = px + 5, y = togY, w = 25, h = 12, action = "eq_on"})

    local autoHov = mx >= px + 35 and mx <= px + 70 and my >= togY and my <= togY + 12
    love.graphics.setColor(self.eqAuto and WA.textBright or WA.textDim)
    love.graphics.rectangle("fill", px + 35, togY, 35, 12)
    love.graphics.setColor(WA.text)
    love.graphics.printf("AUTO", px + 35, togY, 35, "center")
    table.insert(self.buttons, {x = px + 35, y = togY, w = 35, h = 12, action = "eq_auto"})

    local presetHov = mx >= px + self.eqW - 65 and mx <= px + self.eqW - 5 and my >= togY and my <= togY + 12
    love.graphics.setColor(WA.buttonBg)
    love.graphics.rectangle("fill", px + self.eqW - 65, togY, 60, 12)
    self:drawBorder(px + self.eqW - 65, togY, 60, 12, true)
    love.graphics.setColor(WA.text)
    love.graphics.printf("PRESETS", px + self.eqW - 65, togY, 60, "center")
    table.insert(self.buttons, {x = px + self.eqW - 65, y = togY, w = 60, h = 12, action = "eq_preset"})

    local sliderX = px + 15
    local sliderTopY = py + 40
    local sliderH = 55
    local sliderW = 6
    local labels = {"70", "140", "280", "600", "1K", "3K", "6K", "12K", "14K", "16K"}

    love.graphics.setColor(WA.textDim)
    love.graphics.printf("PREAMP", px + 5, sliderTopY - 12, 25, "center")
    love.graphics.setColor(WA.sliderBg)
    love.graphics.rectangle("fill", px + 14, sliderTopY, sliderW, sliderH)
    local preFillY = sliderTopY + sliderH * (1 - self.preamp)
    love.graphics.setColor(WA.eqGreen)
    love.graphics.rectangle("fill", px + 14, preFillY, sliderW, sliderTopY + sliderH - preFillY)
    table.insert(self.buttons, {x = px + 10, y = sliderTopY, w = sliderW + 8, h = sliderH, action = "preamp"})

    local eqStartX = px + 45
    local eqSpacing = (self.eqW - 50) / 10

    for i = 1, 10 do
        local sx = eqStartX + (i - 1) * eqSpacing
        love.graphics.setColor(WA.sliderBg)
        love.graphics.rectangle("fill", sx, sliderTopY, sliderW, sliderH)

        local fillRatio = self.eqSliders[i]
        local fillH = sliderH * fillRatio
        local fillY = sliderTopY + sliderH - fillH

        if fillRatio > 0.7 then
            love.graphics.setColor(WA.eqRed)
        elseif fillRatio > 0.4 then
            love.graphics.setColor(WA.eqYellow)
        else
            love.graphics.setColor(WA.eqGreen)
        end
        love.graphics.rectangle("fill", sx, fillY, sliderW, fillH)

        love.graphics.setColor(WA.textDim)
        love.graphics.printf(labels[i], sx - 8, sliderTopY + sliderH + 2, sliderW + 16, "center")

        table.insert(self.buttons, {x = sx - 4, y = sliderTopY, w = sliderW + 8, h = sliderH, action = "eq_" .. i})
    end
end

function Winamp:drawPlaylist(mx, my)
    local px, py = self.x, self.y + self.playerH + self.eqH

    love.graphics.setColor(WA.playlistBg)
    love.graphics.rectangle("fill", px, py, self.playlistW, self.playlistH)
    self:drawBorder(px, py, self.playlistW, self.playlistH, false)

    love.graphics.setColor(WA.titleBg)
    love.graphics.rectangle("fill", px + 2, py + 2, self.playlistW - 4, 14)
    love.graphics.setColor(WA.titleText)
    love.graphics.printf("WINAMP PLAYLIST", px + 2, py + 2, self.playlistW - 4, "center")

    local listX = px + 5
    local listY = py + 20
    local listW = self.playlistW - 10
    local listH = self.playlistH - 45
    local itemH = 14

    love.graphics.setColor(WA.bg)
    love.graphics.rectangle("fill", listX, listY, listW, listH)
    self:drawBorder(listX, listY, listW, listH, true)

    love.graphics.setScissor(listX, listY, listW, listH)
    for i, track in ipairs(self.playlist) do
        local ty = listY + (i - 1) * itemH - self.scrollOffset
        if ty + itemH > listY and ty < listY + listH then
            local isSelected = i == self.selectedTrack
            local isHovered = mx >= listX and mx <= listX + listW and my >= ty and my <= ty + itemH

            if isSelected then
                love.graphics.setColor(WA.playlistSelected)
                love.graphics.rectangle("fill", listX, ty, listW, itemH)
                love.graphics.setColor(WA.playlistHighlight)
            elseif isHovered then
                love.graphics.setColor({0.05, 0.05, 0.2})
                love.graphics.rectangle("fill", listX, ty, listW, itemH)
                love.graphics.setColor(WA.playlistText)
            else
                love.graphics.setColor(WA.playlistText)
            end

            local num = string.format("%2d. ", i)
            local dur = self:formatTime(track.duration)
            love.graphics.print(num .. track.title, listX + 4, ty + 1)
            love.graphics.printf(dur, listX, ty + 1, listW - 8, "right")
        end
    end
    love.graphics.setScissor()

    local totalTime = 0
    for _, track in ipairs(self.playlist) do
        totalTime = totalTime + track.duration
    end

    love.graphics.setColor(WA.textDim)
    love.graphics.printf(string.format("%d items  [%s]", #self.playlist, self:formatTime(totalTime)),
        listX, listY + listH + 3, listW, "center")

    local btnY = py + self.playlistH - 18
    local btnW = 35
    local addBtnX = px + 5
    local remBtnX = px + 45

    local addHov = mx >= addBtnX and mx <= addBtnX + btnW and my >= btnY and my <= btnY + 14
    self:drawButton(addBtnX, btnY, btnW, 14, "ADD", addHov)
    table.insert(self.buttons, {x = addBtnX, y = btnY, w = btnW, h = 14, action = "add"})

    local remHov = mx >= remBtnX and mx <= remBtnX + btnW and my >= btnY and my <= btnY + 14
    self:drawButton(remBtnX, btnY, btnW, 14, "REM", remHov)
    table.insert(self.buttons, {x = remBtnX, y = btnY, w = btnW, h = 14, action = "rem"})
end

function Winamp:draw(mx, my)
    if not self.visible then return end

    self.buttons = {}

    self:drawPlayer(mx, my)
    self:drawEQ(mx, my)
    self:drawPlaylist(mx, my)
end

function Winamp:isTitleBar(mx, my)
    return mx >= self.x and mx <= self.x + self.playerW
        and my >= self.y and my <= self.y + 16
end

function Winamp:hitTest(mx, my)
    if not self.visible then return false end
    if mx >= self.x and mx <= self.x + self.totalW and my >= self.y and my <= self.y + self.totalH then
        return true
    end
    return false
end

function Winamp:mousepressed(x, y, button)
    if button ~= 1 then return false end
    if not self.visible then return false end

    if self:isTitleBar(x, y) then
        self.dragging = true
        self.dragOffsetX = x - self.x
        self.dragOffsetY = y - self.y
        return true
    end

    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == ">" then
                self.playing = true
                self.paused = false
                if self.totalTime == 0 and self.playlist[self.selectedTrack] then
                    self.totalTime = self.playlist[self.selectedTrack].duration
                end
            elseif btn.action == "||" then
                self.paused = not self.paused
            elseif btn.action == ">|" then
                self:nextTrack()
            elseif btn.action == "|<" then
                self:prevTrack()
            elseif btn.action == "[ ]" then
                self.playing = false
                self.paused = false
                self.currentTime = 0
                self.seekPos = 0
            elseif btn.action == "shuffle" then
                self.shuffle = not self.shuffle
            elseif btn.action == "repeat" then
                self.repeatOn = not self.repeatOn
            elseif btn.action == "volume" then
                local relX = x - btn.x
                self.volume = math.max(0, math.min(1, relX / btn.w))
            elseif btn.action == "balance" then
                local relX = x - btn.x
                self.balance = (relX / btn.w) * 2 - 1
            elseif btn.action == "eq_on" then
                self.eqOn = not self.eqOn
            elseif btn.action == "eq_auto" then
                self.eqAuto = not self.eqAuto
            elseif btn.action == "preamp" then
                local relY = y - btn.y
                self.preamp = 1 - (relY / btn.h)
            elseif btn.action:sub(1, 3) == "eq_" then
                local idx = tonumber(btn.action:sub(4))
                if idx then
                    local relY = y - btn.y
                    self.eqSliders[idx] = 1 - (relY / btn.h)
                end
            elseif btn.action == "add" then
                table.insert(self.playlist, {title = "New Track " .. #self.playlist + 1, duration = 180})
            elseif btn.action == "rem" then
                if #self.playlist > 0 then
                    table.remove(self.playlist, self.selectedTrack)
                    if self.selectedTrack > #self.playlist then
                        self.selectedTrack = math.max(1, #self.playlist)
                    end
                end
            end
            return true
        end
    end

    local px, py = self.x, self.y + self.playerH + self.eqH
    local listX = px + 5
    local listY = py + 20
    local listW = self.playlistW - 10
    local listH = self.playlistH - 45
    local itemH = 14

    if x >= listX and x <= listX + listW and y >= listY and y <= listY + listH then
        local clickIndex = math.floor((y - listY + self.scrollOffset) / itemH) + 1
        if clickIndex >= 1 and clickIndex <= #self.playlist then
            self.selectedTrack = clickIndex
            if self.playing then
                self.currentTime = 0
                self.totalTime = self.playlist[self.selectedTrack].duration
            end
        end
        return true
    end

    local seekX = self.x + 5
    local seekY = self.y + 68
    local seekW = self.playerW - 10
    if x >= seekX and x <= seekX + seekW and y >= seekY and y <= seekY + 8 then
        local relX = x - seekX
        self.seekPos = relX / seekW
        self.currentTime = self.seekPos * self.totalTime
        return true
    end

    return true
end

function Winamp:mousereleased(x, y, button)
    if button == 1 then
        self.dragging = false
    end
end

function Winamp:mousemoved(x, y)
    if self.dragging then
        self.x = x - self.dragOffsetX
        self.y = y - self.dragOffsetY
    end
end

function Winamp:getZOrder()
    return self.visible and 10 or 0
end

return Winamp