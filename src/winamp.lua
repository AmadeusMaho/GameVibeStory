local Winamp = {}
Winamp.__index = Winamp

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
}

function Winamp.new(x, y)
    local self = setmetatable({}, Winamp)
    self.x = x or 100
    self.y = y or 100
    self.visible = false
    self.dragging = false
    self.dragOffsetX = 0
    self.dragOffsetY = 0

    self.w = 275
    self.h = 140

    self.playing = false
    self.currentTime = 0
    self.totalTime = 0
    self.seekPos = 0
    self.volume = 0.7
    self.shuffle = false

    self.playlist = {
        {title = "Mori Calliope - Go-Getters", duration = 195},
        {title = "CircusP - Goodbye", duration = 204},
        {title = "AmaLee - Siren", duration = 242},
        {title = "Crusher-P - Echo", duration = 230},
        {title = "MB3 - Silent City", duration = 243},
    }
    self.selectedTrack = 1
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
    if self.playing then
        self.currentTime = self.currentTime + dt
        if self.currentTime >= self.totalTime then
            self:nextTrack()
        end
        if self.totalTime > 0 then
            self.seekPos = self.currentTime / self.totalTime
        end
    end
end

function Winamp:nextTrack()
    if self.shuffle then
        self.selectedTrack = love.math.random(1, #self.playlist)
    elseif self.selectedTrack < #self.playlist then
        self.selectedTrack = self.selectedTrack + 1
    else
        self.playing = false
        self.currentTime = 0
        self.seekPos = 0
        return
    end
    self.currentTime = 0
    self.totalTime = self.playlist[self.selectedTrack].duration
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

function Winamp:draw(mx, my)
    if not self.visible then return end
    self.buttons = {}

    local px, py = self.x, self.y

    love.graphics.setColor(WA.panelBg)
    love.graphics.rectangle("fill", px, py, self.w, self.h)
    self:drawBorder(px, py, self.w, self.h, false)

    love.graphics.setColor(WA.titleBg)
    love.graphics.rectangle("fill", px + 2, py + 2, self.w - 4, 14)
    love.graphics.setColor(WA.titleText)
    love.graphics.printf("WINAMP", px + 2, py + 2, self.w - 4, "center")

    love.graphics.setColor(WA.bg)
    love.graphics.rectangle("fill", px + 5, py + 20, self.w - 10, 24)
    self:drawBorder(px + 5, py + 20, self.w - 10, 24, true)

    local track = self.playlist[self.selectedTrack]
    local title = track and track.title or "No track"
    love.graphics.setColor(WA.textBright)
    love.graphics.printf(title, px + 10, py + 27, self.w - 20, "center")

    love.graphics.setColor(WA.sliderBg)
    love.graphics.rectangle("fill", px + 5, py + 50, self.w - 10, 8)
    love.graphics.setColor(WA.sliderFill)
    love.graphics.rectangle("fill", px + 5, py + 50, (self.w - 10) * self.seekPos, 8)
    self:drawBorder(px + 5, py + 50, self.w - 10, 8, true)

    local timeStr = self:formatTime(self.currentTime) .. " / " .. self:formatTime(self.totalTime)
    love.graphics.setColor(WA.text)
    love.graphics.printf(timeStr, px + 5, py + 62, self.w - 10, "right")

    local btnY = py + 80
    local btnH = 20
    local btnW = 40
    local btnGap = 5
    local btns = {">", "[]", ">|"}
    local startX = px + (self.w - (#btns * (btnW + btnGap) - btnGap)) / 2

    for i, label in ipairs(btns) do
        local bx = startX + (i - 1) * (btnW + btnGap)
        local hov = mx >= bx and mx <= bx + btnW and my >= btnY and my <= btnY + btnH
        self:drawButton(bx, btnY, btnW, btnH, label, hov)
        table.insert(self.buttons, {x = bx, y = btnY, w = btnW, h = btnH, action = label})
    end

    local shufX = px + 5
    local shufY = py + 108
    local shufHov = mx >= shufX and mx <= shufX + 50 and my >= shufY and my <= shufY + 14
    love.graphics.setColor(self.shuffle and WA.textBright or WA.textDim)
    love.graphics.rectangle("fill", shufX, shufY, 50, 14)
    love.graphics.setColor(self.shuffle and WA.text or WA.textDim)
    love.graphics.printf("SHUFFLE", shufX, shufY, 50, "center")
    table.insert(self.buttons, {x = shufX, y = shufY, w = 50, h = 14, action = "shuffle"})

    local volX = px + self.w - 100
    love.graphics.setColor(WA.textDim)
    love.graphics.print("VOL", volX, shufY + 1)
    love.graphics.setColor(WA.sliderBg)
    love.graphics.rectangle("fill", volX + 28, shufY + 2, 65, 10)
    love.graphics.setColor(WA.sliderFill)
    love.graphics.rectangle("fill", volX + 28, shufY + 2, 65 * self.volume, 10)
    table.insert(self.buttons, {x = volX + 28, y = shufY, w = 65, h = 14, action = "volume"})

    local trackInfo = string.format("%d/%d", self.selectedTrack, #self.playlist)
    love.graphics.setColor(WA.textDim)
    love.graphics.printf(trackInfo, px + 60, shufY + 1, 80, "center")
end

function Winamp:isTitleBar(mx, my)
    return mx >= self.x and mx <= self.x + self.w
        and my >= self.y and my <= self.y + 16
end

function Winamp:hitTest(mx, my)
    if not self.visible then return false end
    return mx >= self.x and mx <= self.x + self.w
        and my >= self.y and my <= self.y + self.h
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
                if self.totalTime == 0 and self.playlist[self.selectedTrack] then
                    self.totalTime = self.playlist[self.selectedTrack].duration
                end
            elseif btn.action == "[]" then
                self.playing = false
                self.currentTime = 0
                self.seekPos = 0
            elseif btn.action == ">|" then
                self:nextTrack()
            elseif btn.action == "shuffle" then
                self.shuffle = not self.shuffle
            elseif btn.action == "volume" then
                local relX = x - btn.x
                self.volume = math.max(0, math.min(1, relX / btn.w))
            end
            return true
        end
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

return Winamp