local WindowManager = {}
WindowManager.__index = WindowManager

local W95 = {
    bg = {0.75, 0.75, 0.75},
    titleActive = {0.0, 0.0, 0.5},
    titleInactive = {0.5, 0.5, 0.5},
    titleText = {1, 1, 1},
    borderLight = {1, 1, 1},
    borderDark = {0.5, 0.5, 0.5},
    borderUltra = {0.25, 0.25, 0.25},
    buttonText = {0, 0, 0},
    buttonBg = {0.75, 0.75, 0.75},
    buttonHover = {0.85, 0.85, 0.85},
}

function WindowManager.new(title, x, y, w, h)
    local self = setmetatable({}, WindowManager)
    self.title = title or "Window"
    self.x = x or 100
    self.y = y or 100
    self.w = w or 400
    self.h = h or 300
    self.titleH = 20
    self.visible = false
    self.active = true
    self.dragging = false
    self.dragOffsetX = 0
    self.dragOffsetY = 0
    self.minimized = false
    self.fullscreen = false
    self.prevX = x
    self.prevY = y
    self.prevW = w
    self.prevH = h
    self.buttons = {}
    self.onClose = nil
    self.onMinimize = nil
    self.onFullscreen = nil
    self.onDraw = nil
    self.onMousePressed = nil
    self.onMouseReleased = nil
    self.onMouseMoved = nil
    return self
end

function WindowManager:getContentArea()
    return self.x, self.y + self.titleH, self.w, self.h - self.titleH
end

function WindowManager:drawTitleBar()
    local btnSize = self.titleH - 4
    local btnY = self.y + 2

    love.graphics.setColor(self.active and W95.titleActive or W95.titleInactive)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.titleH)

    love.graphics.setColor(W95.titleText)
    love.graphics.printf(self.title, self.x + 4, self.y + 3, self.w - 4 - (btnSize + 2) * 3, "left")

    local closeX = self.x + self.w - btnSize - 2
    local maxX = closeX - btnSize - 2
    local minX = maxX - btnSize - 2

    local mx, my = love.mouse.getPosition()

    local function drawBtn(bx, by, label)
        love.graphics.setColor(W95.buttonBg)
        love.graphics.rectangle("fill", bx, by, btnSize, btnSize)
        love.graphics.setColor(W95.borderLight)
        love.graphics.line(bx, by, bx + btnSize, by)
        love.graphics.line(bx, by, bx, by + btnSize)
        love.graphics.setColor(W95.borderDark)
        love.graphics.line(bx + btnSize, by, bx + btnSize, by + btnSize)
        love.graphics.line(bx, by + btnSize, bx + btnSize, by + btnSize)
        love.graphics.setColor(W95.buttonText)
        love.graphics.printf(label, bx, by, btnSize, "center")
    end

    drawBtn(minX, btnY, "_")
    drawBtn(maxX, btnY, "□")
    drawBtn(closeX, btnY, "x")

    self.buttons = {
        {x = minX, y = btnY, w = btnSize, h = btnSize, action = "minimize"},
        {x = maxX, y = btnY, w = btnSize, h = btnSize, action = "fullscreen"},
        {x = closeX, y = btnY, w = btnSize, h = btnSize, action = "close"},
    }
end

function WindowManager:drawFrame()
    if not self.visible then return end
    if self.minimized then return end

    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", self.x, self.y + self.titleH, self.w, self.h - self.titleH)

    love.graphics.setColor(W95.borderLight)
    love.graphics.line(self.x, self.y, self.x + self.w, self.y)
    love.graphics.line(self.x, self.y, self.x, self.y + self.h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(self.x + self.w, self.y, self.x + self.w, self.y + self.h)
    love.graphics.line(self.x, self.y + self.h, self.x + self.w, self.y + self.h)
    love.graphics.setColor(W95.borderUltra)
    love.graphics.line(self.x + 1, self.y + self.h - 1, self.x + self.w - 1, self.y + self.h - 1)
    love.graphics.line(self.x + self.w - 1, self.y + 1, self.x + self.w - 1, self.y + self.h - 1)

    self:drawTitleBar()

    if self.onDraw then
        local cx, cy, cw, ch = self:getContentArea()
        love.graphics.setScissor(cx, cy, cw, ch)
        self:onDraw(cx, cy, cw, ch)
        love.graphics.setScissor()
    end
end

function WindowManager:isTitleBar(mx, my)
    return mx >= self.x and mx <= self.x + self.w
        and my >= self.y and my <= self.y + self.titleH
end

function WindowManager:hitTest(mx, my)
    if not self.visible or self.minimized then return false end
    return mx >= self.x and mx <= self.x + self.w
        and my >= self.y and my <= self.y + self.h
end

function WindowManager:mousepressed(x, y, button)
    if button ~= 1 then return false end
    if not self.visible or self.minimized then return false end

    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "close" then
                self.visible = false
                if self.onClose then self:onClose() end
            elseif btn.action == "minimize" then
                self.minimized = true
                if self.onMinimize then self:onMinimize() end
            elseif btn.action == "fullscreen" then
                self.fullscreen = not self.fullscreen
                if self.fullscreen then
                    self.prevX, self.prevY = self.x, self.y
                    self.prevW, self.prevH = self.w, self.h
                    local ww, wh = love.graphics.getDimensions()
                    self.x, self.y = 0, 0
                    self.w, self.h = ww, wh
                else
                    self.x, self.y = self.prevX, self.prevY
                    self.w, self.h = self.prevW, self.prevH
                end
                if self.onFullscreen then self:onFullscreen(self.fullscreen) end
            end
            return true
        end
    end

    if self:isTitleBar(x, y) then
        self.dragging = true
        self.dragOffsetX = x - self.x
        self.dragOffsetY = y - self.y
        return true
    end

    if self.onMousePressed then
        local cx, cy, cw, ch = self:getContentArea()
        if x >= cx and x <= cx + cw and y >= cy and y <= cy + ch then
            return self:onMousePressed(x, y, button)
        end
    end

    return true
end

function WindowManager:mousereleased(x, y, button)
    if button == 1 then
        self.dragging = false
    end
    if self.onMouseReleased then
        self:onMouseReleased(x, y, button)
    end
end

function WindowManager:mousemoved(x, y)
    if self.dragging then
        self.x = x - self.dragOffsetX
        self.y = y - self.dragOffsetY
    end
    if self.onMouseMoved then
        self:onMouseMoved(x, y)
    end
end

return WindowManager