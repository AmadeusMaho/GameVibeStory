local RecycleBin = {}
RecycleBin.__index = RecycleBin

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
    fieldBg = {1, 1, 1},
}

function RecycleBin.new(x, y)
    local self = setmetatable({}, RecycleBin)
    self.window = WindowManager.new("Papelera de reciclaje", x or 300, y or 150, 380, 280)

    self.smallFont = love.graphics.newFont(11)

    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, x, y, button)
        return self:handleClick(x, y, button)
    end

    return self
end

function RecycleBin:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function RecycleBin:update(dt)
end

function RecycleBin:drawBevel(x, y, w, h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function RecycleBin:drawInset(x, y, w, h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function RecycleBin:drawContent(cx, cy, cw, ch)
    self.buttons = {}

    local prevFont = love.graphics.getFont()
    love.graphics.setFont(self.smallFont)

    local menuH = 18
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx, cy, cw, menuH)
    local menuItems = {"Archivo", "Editar", "Ver", "Ayuda"}
    local mx_off = cx + 4
    for _, item in ipairs(menuItems) do
        local iw = self.smallFont:getWidth(item) + 12
        love.graphics.setColor(W95.text)
        love.graphics.print(item, mx_off, cy + 3)
        mx_off = mx_off + iw
    end

    local contentY = cy + menuH
    local contentH = ch - menuH - 20

    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", cx, contentY, cw, contentH)
    self:drawInset(cx, contentY, cw, contentH)

    love.graphics.setColor(W95.textDim)
    love.graphics.printf("La papelera esta vacia", cx, contentY + contentH / 2 - 20, cw, "center")

    local statusH = 20
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx, cy + ch - statusH, cw, statusH)
    self:drawBevel(cx, cy + ch - statusH, cw, statusH)
    love.graphics.setColor(W95.text)
    love.graphics.print("  0 elementos", cx + 4, cy + ch - statusH + 4)

    love.graphics.setFont(prevFont)
end

function RecycleBin:handleClick(x, y, button)
    return true
end

function RecycleBin:draw(mx, my)
    self.window:drawFrame()
end

function RecycleBin:hitTest(mx, my)
    return self.window:hitTest(mx, my)
end

function RecycleBin:mousepressed(x, y, button)
    return self.window:mousepressed(x, y, button)
end

function RecycleBin:mousereleased(x, y, button)
    self.window:mousereleased(x, y, button)
end

function RecycleBin:mousemoved(x, y)
    self.window:mousemoved(x, y)
end

return RecycleBin
