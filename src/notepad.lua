local Notepad = {}
Notepad.__index = Notepad

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
    menuBg = {0.75, 0.75, 0.75},
}

function Notepad.new(x, y)
    local self = setmetatable({}, Notepad)
    self.window = WindowManager.new("Sin titulo - Bloc de notas", x or 150, y or 100, 500, 380)

    self.text = "=== OBJETIVOS ===\n\n[ ] Genera $100\n\n\n\n(Selecciona los objetivos completados)"
    self.scrollY = 0
    self.cursorPos = #self.text

    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, x, y, button)
        return self:handleClick(x, y, button)
    end

    return self
end

function Notepad:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function Notepad:update(dt)
end

function Notepad:drawContent(cx, cy, cw, ch)
    self.buttons = {}

    local prevFont = love.graphics.getFont()
    local smallFont = love.graphics.newFont(11)
    love.graphics.setFont(smallFont)

    local menuH = 18
    love.graphics.setColor(W95.menuBg)
    love.graphics.rectangle("fill", cx, cy, cw, menuH)

    local menuItems = {"Archivo", "Edicion", "Formato", "Ayuda"}
    local mx_off = cx + 4
    for _, item in ipairs(menuItems) do
        local iw = smallFont:getWidth(item) + 12
        love.graphics.setColor(W95.text)
        love.graphics.print(item, mx_off, cy + 3)
        mx_off = mx_off + iw
    end

    local contentY = cy + menuH
    local contentH = ch - menuH

    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", cx, contentY, cw, contentH)
    self:drawInset(cx, contentY, cw, contentH)

    love.graphics.setScissor(cx + 2, contentY + 2, cw - 4, contentH - 4)

    local lines = {}
    for line in self.text:gmatch("[^\n]*") do
        table.insert(lines, line)
    end

    local lineH = 14
    local padX = 6
    local padY = 4

    for i, line in ipairs(lines) do
        local ly = contentY + padY + (i - 1) * lineH - self.scrollY
        if ly + lineH > contentY and ly < contentY + contentH then
            love.graphics.setColor(W95.text)
            love.graphics.print(line, cx + padX, ly)
        end
    end

    local cursorLine = 1
    local cursorCol = self.cursorPos
    for i = 1, #lines do
        if cursorCol > #lines[i] + 1 then
            cursorCol = cursorCol - #lines[i] - 1
            cursorLine = i + 1
        else
            cursorLine = i
            break
        end
    end

    local cursorX = cx + padX + smallFont:getWidth(string.sub(lines[cursorLine] or "", 1, cursorCol - 1))
    local cursorY = contentY + padY + (cursorLine - 1) * lineH - self.scrollY

    if math.floor(love.timer.getTime() * 2) % 2 == 0 then
        love.graphics.setColor(W95.text)
        love.graphics.rectangle("fill", cursorX, cursorY, 2, lineH)
    end

    love.graphics.setScissor()

    love.graphics.setFont(prevFont)
end

function Notepad:drawInset(x, y, w, h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Notepad:handleClick(x, y, button)
    if button == 1 then
        local cx, cy, cw, ch = self.window:getContentArea()
        local prevFont = love.graphics.getFont()
        local smallFont = love.graphics.newFont(11)

        if y >= cy + 18 and y <= cy + ch then
            local lines = {}
            for line in self.text:gmatch("[^\n]*") do
                table.insert(lines, line)
            end

            local lineH = 14
            local padY = 4
            local clickLine = math.floor((y - cy - 18 + self.scrollY - padY) / lineH) + 1

            if clickLine >= 1 and clickLine <= #lines then
                local lineText = lines[clickLine] or ""
                local clickX = x - cx - 6

                local col = 0
                for c = 1, #lineText do
                    local charW = smallFont:getWidth(lineText:sub(c, c))
                    if clickX < charW / 2 then
                        col = c - 1
                        break
                    end
                    clickX = clickX - charW
                    col = c
                end

                self.cursorPos = 0
                for i = 1, clickLine - 1 do
                    self.cursorPos = self.cursorPos + #lines[i] + 1
                end
                self.cursorPos = self.cursorPos + col
            end
        end
    end
    return true
end

function Notepad:draw(mx, my)
    self.window:drawFrame()
end

function Notepad:hitTest(mx, my)
    return self.window:hitTest(mx, my)
end

function Notepad:mousepressed(x, y, button)
    return self.window:mousepressed(x, y, button)
end

function Notepad:mousereleased(x, y, button)
    self.window:mousereleased(x, y, button)
end

function Notepad:mousemoved(x, y)
    self.window:mousemoved(x, y)
end

return Notepad
