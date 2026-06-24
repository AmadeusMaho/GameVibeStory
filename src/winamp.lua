local Winamp = {}
Winamp.__index = Winamp

local WindowManager = require("src.window")

local WA = {
    bg = {0.05, 0.05, 0.1},
    panelBg = {0.1, 0.1, 0.15},
    borderLight = {0.3, 0.3, 0.35},
    borderDark = {0.02, 0.02, 0.05},
    text = {0, 1, 0},
    textDim = {0, 0.5, 0},
    textBright = {0.2, 1, 0.2},
    buttonBg = {0.15, 0.15, 0.2},
    buttonHover = {0.25, 0.25, 0.3},
    sliderBg = {0.05, 0.05, 0.1},
    sliderFill = {0, 0.8, 0},
}

function Winamp.new(x, y)
    local self = setmetatable({}, Winamp)
    self.window = WindowManager.new("Winamp", x or 100, y or 100, 275, 165)

    self.playing = false
    self.currentTime = 0
    self.totalTime = 0
    self.seekPos = 0
    self.volume = 0.7
    self.shuffle = false
    self.music = nil

    self.playlist = {
        {title = "The man who sold the world - Nirvana", duration = 0, file = "songw95_1.wav"},
    }
    self.selectedTrack = 1
    self.buttons = {}

    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, x, y, button)
        return self:handleClick(x, y, button)
    end

    return self
end

function Winamp:setMusic(source)
    self.music = source
    if source then
        self.totalTime = source:getDuration()
        self.playlist[1].duration = self.totalTime
    end
end

function Winamp:formatTime(seconds)
    if seconds < 0 then seconds = 0 end
    local mins = math.floor(seconds / 60)
    local secs = math.floor(seconds % 60)
    return string.format("%d:%02d", mins, secs)
end

function Winamp:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function Winamp:update(dt)
    if not self.window.visible then return end
    if self.playing and self.music then
        self.currentTime = self.music:tell()
        if self.totalTime > 0 then
            self.seekPos = self.currentTime / self.totalTime
        end
    end
end

function Winamp:nextTrack()
    if self.selectedTrack < #self.playlist then
        self.selectedTrack = self.selectedTrack + 1
    else
        self.selectedTrack = 1
    end
    self.currentTime = 0
    self.seekPos = 0
    if self.music then
        self.totalTime = self.music:getDuration()
        self.playlist[self.selectedTrack].duration = self.totalTime
    end
end

function Winamp:prevTrack()
    if self.currentTime > 3 then
        if self.music then
            self.music:seek(0)
        end
        self.currentTime = 0
    elseif self.selectedTrack > 1 then
        self.selectedTrack = self.selectedTrack - 1
        self.currentTime = 0
        self.seekPos = 0
        if self.music then
            self.totalTime = self.music:getDuration()
            self.playlist[self.selectedTrack].duration = self.totalTime
        end
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

function Winamp:drawTransportIcon(x, y, w, h, icon)
    local cx = x + w / 2
    local cy = y + h / 2

    if icon == "prev" then
        love.graphics.setColor(WA.text)
        love.graphics.polygon("fill", cx - 8, cy - 6, cx - 8, cy + 6, cx - 14, cy)
        love.graphics.rectangle("fill", cx - 4, cy - 6, 3, 12)
        love.graphics.polygon("fill", cx + 2, cy - 6, cx + 2, cy + 6, cx + 10, cy)
    elseif icon == "play" then
        love.graphics.setColor(WA.text)
        love.graphics.polygon("fill", cx - 4, cy - 7, cx - 4, cy + 7, cx + 7, cy)
    elseif icon == "stop" then
        love.graphics.setColor(WA.text)
        love.graphics.rectangle("fill", cx - 5, cy - 5, 10, 10)
    elseif icon == "next" then
        love.graphics.setColor(WA.text)
        love.graphics.polygon("fill", cx + 8, cy - 6, cx + 8, cy + 6, cx + 14, cy)
        love.graphics.rectangle("fill", cx + 1, cy - 6, 3, 12)
        love.graphics.polygon("fill", cx - 2, cy - 6, cx - 2, cy + 6, cx - 10, cy)
    end
end

function Winamp:drawContent(cx, cy, cw, ch)
    self.buttons = {}

    love.graphics.setColor(WA.panelBg)
    love.graphics.rectangle("fill", cx, cy, cw, ch)

    love.graphics.setColor(WA.bg)
    love.graphics.rectangle("fill", cx + 5, cy + 5, cw - 10, 20)
    self:drawBorder(cx + 5, cy + 5, cw - 10, 20, true)

    local track = self.playlist[self.selectedTrack]
    local title = track and track.title or "No track"
    love.graphics.setColor(WA.textBright)
    love.graphics.printf(title, cx + 10, cy + 10, cw - 20, "center")

    love.graphics.setColor(WA.sliderBg)
    love.graphics.rectangle("fill", cx + 5, cy + 30, cw - 10, 8)
    love.graphics.setColor(WA.sliderFill)
    love.graphics.rectangle("fill", cx + 5, cy + 30, (cw - 10) * self.seekPos, 8)
    self:drawBorder(cx + 5, cy + 30, cw - 10, 8, true)

    local timeStr = self:formatTime(self.currentTime) .. " / " .. self:formatTime(self.totalTime)
    love.graphics.setColor(WA.text)
    love.graphics.printf(timeStr, cx + 5, cy + 42, cw - 10, "right")

    local btnY = cy + 58
    local btnH = 22
    local btnW = 36
    local btnGap = 4
    local icons = {"prev", "play", "stop", "next"}
    local startX = cx + (cw - (#icons * (btnW + btnGap) - btnGap)) / 2

    for i, icon in ipairs(icons) do
        local bx = startX + (i - 1) * (btnW + btnGap)
        local mx, my = love.mouse.getPosition()
        local hov = mx >= bx and mx <= bx + btnW and my >= btnY and my <= btnY + btnH
        love.graphics.setColor(hov and WA.buttonHover or WA.buttonBg)
        love.graphics.rectangle("fill", bx, btnY, btnW, btnH)
        self:drawBorder(bx, btnY, btnW, btnH, true)
        self:drawTransportIcon(bx, btnY, btnW, btnH, icon)
        table.insert(self.buttons, {x = bx, y = btnY, w = btnW, h = btnH, action = icon})
    end

    local shufX = cx + 5
    local shufY = cy + 90
    local mx, my = love.mouse.getPosition()
    local shufHov = mx >= shufX and mx <= shufX + 55 and my >= shufY and my <= shufY + 14
    love.graphics.setColor(self.shuffle and WA.textBright or WA.textDim)
    love.graphics.rectangle("fill", shufX, shufY, 55, 14)
    love.graphics.setColor(self.shuffle and WA.text or WA.textDim)
    love.graphics.printf("SHUFFLE", shufX, shufY, 55, "center")
    table.insert(self.buttons, {x = shufX, y = shufY, w = 55, h = 14, action = "shuffle"})

    local volX = cx + cw - 105
    love.graphics.setColor(WA.textDim)
    love.graphics.print("VOL", volX, shufY + 1)
    love.graphics.setColor(WA.sliderBg)
    love.graphics.rectangle("fill", volX + 28, shufY + 2, 70, 10)
    love.graphics.setColor(WA.sliderFill)
    love.graphics.rectangle("fill", volX + 28, shufY + 2, 70 * self.volume, 10)
    table.insert(self.buttons, {x = volX + 28, y = shufY, w = 70, h = 14, action = "volume"})

    local trackInfo = string.format("%d/%d", self.selectedTrack, #self.playlist)
    love.graphics.setColor(WA.textDim)
    love.graphics.printf(trackInfo, cx + 60, shufY + 1, 80, "center")
end

function Winamp:handleClick(x, y, button)
    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "play" then
                if self.music then
                    if not self.playing then
                        self.music:play()
                        self.playing = true
                    else
                        self.music:pause()
                        self.playing = false
                    end
                end
            elseif btn.action == "stop" then
                if self.music then
                    self.music:stop()
                end
                self.playing = false
                self.currentTime = 0
                self.seekPos = 0
            elseif btn.action == "next" then
                if self.music then
                    self.music:stop()
                end
                self:nextTrack()
                if self.music and self.playing then
                    self.music:play()
                end
            elseif btn.action == "prev" then
                if self.music then
                    self.music:stop()
                end
                self:prevTrack()
                if self.music and self.playing then
                    self.music:play()
                end
            elseif btn.action == "shuffle" then
                self.shuffle = not self.shuffle
            elseif btn.action == "volume" then
                local relX = x - btn.x
                self.volume = math.max(0, math.min(1, relX / btn.w))
                if self.music then
                    self.music:setVolume(self.volume)
                end
            end
            return true
        end
    end
    return true
end

function Winamp:draw(mx, my)
    self.window:drawFrame()
end

function Winamp:hitTest(mx, my)
    return self.window:hitTest(mx, my)
end

function Winamp:mousepressed(x, y, button)
    return self.window:mousepressed(x, y, button)
end

function Winamp:mousereleased(x, y, button)
    self.window:mousereleased(x, y, button)
end

function Winamp:mousemoved(x, y)
    self.window:mousemoved(x, y)
end

return Winamp