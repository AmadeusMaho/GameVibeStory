local Coding = {}
Coding.__index = Coding

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
}

local codeSnippets = {
    {
        lang = "Python",
        reward = 150,
        lines = {
            'def fibonacci(n):',
            '    if n <= 1:',
            '        return n',
            '    return fibonacci(n-1) + fibonacci(n-2)',
            '',
            'for i in range(10):',
            '    print(f"F({i}) = {fibonacci(i)}")',
        },
    },
    {
        lang = "JavaScript",
        reward = 200,
        lines = {
            'function fetchUsers() {',
            '    return fetch("/api/users")',
            '        .then(res => res.json())',
            '        .then(data => {',
            '            console.log(data);',
            '            return data;',
            '        });',
            '}',
        },
    },
    {
        lang = "HTML",
        reward = 120,
        lines = {
            '<!DOCTYPE html>',
            '<html>',
            '<head>',
            '    <title>Mi Pagina</title>',
            '</head>',
            '<body>',
            '    <h1>Hola Mundo</h1>',
            '</body>',
            '</html>',
        },
    },
    {
        lang = "SQL",
        reward = 180,
        lines = {
            'SELECT u.nombre, u.email',
            'FROM usuarios u',
            'INNER JOIN pedidos p',
            '    ON u.id = p.usuario_id',
            'WHERE p.fecha > "2024-01-01"',
            'ORDER BY p.total DESC',
            'LIMIT 10;',
        },
    },
    {
        lang = "C",
        reward = 250,
        lines = {
            '#include <stdio.h>',
            '',
            'int main() {',
            '    int arr[] = {5, 2, 8, 1, 9};',
            '    int n = sizeof(arr)/sizeof(arr[0]);',
            '    ',
            '    for(int i = 0; i < n; i++) {',
            '        printf("%d ", arr[i]);',
            '    }',
            '    return 0;',
            '}',
        },
    },
    {
        lang = "Java",
        reward = 220,
        lines = {
            'public class Main {',
            '    public static void main(String[] args) {',
            '        String[] names = {"Ana", "Luis"};',
            '        for (String name : names) {',
            '            System.out.println("Hola " + name);',
            '        }',
            '    }',
            '}',
        },
    },
}

function Coding.new(x, y)
    local self = setmetatable({}, Coding)
    self.window = WindowManager.new("Code Editor", x or 200, y or 100, 500, 400)
    self.window.minimizeOnly = true

    self.trabajoRef = nil
    self.explorerRef = nil
    self.activeProject = nil
    self.snippet = nil
    self.typedText = ""
    self.targetText = ""
    self.charIndex = 0
    self.progress = 0
    self.reward = 0
    self.linesTyped = {}
    self.isComplete = false
    self.completeMessage = ""
    self.completeTimer = 0
    self.cursorBlink = 0

    self.codeFont = love.graphics.newFont(12)
    self.smallFont = love.graphics.newFont(11)

    self.window.onDraw = function(_, cx, cy, cw, ch)
        self:drawContent(cx, cy, cw, ch)
    end
    self.window.onMousePressed = function(_, x, y, button)
        return self:handleClick(x, y, button)
    end

    return self
end

function Coding:toggleVisible()
    self.window.visible = not self.window.visible
    self.window.minimized = false
end

function Coding:getCharsPerKey()
    local base = 1
    if self.explorerRef then
        local cpuLevel = self.explorerRef.upgradeLevels.cpu or 0
        base = base + cpuLevel * 2
    end
    return base
end

function Coding:getRewardMultiplier()
    local mult = 1.0
    if self.explorerRef then
        local gpuLevel = self.explorerRef.upgradeLevels.display or 0
        mult = mult + gpuLevel * 0.25
    end
    return mult
end

function Coding:startJob()
    local snippet = codeSnippets[math.random(#codeSnippets)]
    self.snippet = snippet
    self.targetText = table.concat(snippet.lines, "\n")
    self.typedText = ""
    self.charIndex = 0
    self.progress = 0
    self.reward = math.floor(snippet.reward * self:getRewardMultiplier())
    self.linesTyped = {}
    self.isComplete = false
    self.completeMessage = ""
    self.completeTimer = 0
    self.activeProject = true
    self.window.visible = true
    self.window.minimized = false
end

function Coding:handleClick(x, y, button)
    if button ~= 1 then return false end

    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "start_coding" then
                self:startJob()
            elseif btn.action == "dismiss_coding" then
                self.activeProject = false
                self.completeMessage = ""
                self.completeTimer = 0
            end
            return true
        end
    end
    return true
end

function Coding:keypressed(key)
    if not self.activeProject or self.isComplete then return end
    if key == "lshift" or key == "rshift" or key == "lctrl" or key == "rctrl" or 
       key == "lalt" or key == "ralt" or key == "escape" or key == "tab" then
        return
    end

    local charsToAdd = self:getCharsPerKey()
    for i = 1, charsToAdd do
        if self.charIndex < #self.targetText then
            self.charIndex = self.charIndex + 1
            self.typedText = self.targetText:sub(1, self.charIndex)
        end
    end

    self.progress = self.charIndex / #self.targetText

    if self.charIndex >= #self.targetText then
        self.isComplete = true
        self.completeMessage = "Trabajo completado! +$" .. self.reward
        self.completeTimer = 5.0
        if self.trabajoRef then
            self.trabajoRef.money = self.trabajoRef.money + self.reward
            self.trabajoRef.totalEarned = self.trabajoRef.totalEarned + self.reward
            self.trabajoRef.tasksCompleted = self.trabajoRef.tasksCompleted + 1
        end
    end
end

function Coding:update(dt)
    if self.completeTimer > 0 then
        self.completeTimer = self.completeTimer - dt
        if self.completeTimer <= 0 then
            self.activeProject = false
            self.completeMessage = ""
        end
    end
    self.cursorBlink = self.cursorBlink + dt
end

function Coding:drawBevel(x, y, w, h)
    love.graphics.setColor(W95.borderLight)
    love.graphics.line(x, y, x + w, y)
    love.graphics.line(x, y, x, y + h)
    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + w, y, x + w, y + h)
    love.graphics.line(x, y + h, x + w, y + h)
end

function Coding:drawContent(cx, cy, cw, ch)
    self.buttons = {}
    local prevFont = love.graphics.getFont()

    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", cx + 6, cy + 4, cw - 12, ch - 8)
    self:drawBevel(cx + 6, cy + 4, cw - 12, ch - 8)

    if not self.activeProject then
        love.graphics.setColor(W95.text)
        love.graphics.setFont(self.smallFont)
        love.graphics.printf("Code Editor", cx + 12, cy + 20, cw - 24, "center")
        love.graphics.setColor(W95.textDim)
        love.graphics.printf("Acepta trabajos de programacion\npara ganar dinero escribiendo codigo.", cx + 12, cy + 50, cw - 24, "center")

        local btnW = 120
        local btnH = 28
        local btnX = cx + (cw - btnW) / 2
        local btnY = cy + 100
        local mx, my = love.mouse.getPosition()
        local btnHov = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH

        love.graphics.setColor(btnHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
        self:drawBevel(btnX, btnY, btnW, btnH)
        love.graphics.setColor(W95.green)
        love.graphics.printf("Nuevo trabajo", btnX, btnY + 7, btnW, "center")
        table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "start_coding"})

        love.graphics.setFont(prevFont)
        return
    end

    if self.completeMessage ~= "" then
        love.graphics.setColor(W95.green)
        love.graphics.setFont(self.smallFont)
        love.graphics.printf(self.completeMessage, cx + 12, cy + ch / 2 - 30, cw - 24, "center")
        love.graphics.setColor(W95.text)
        love.graphics.printf("Felicidades por completar el trabajo!", cx + 12, cy + ch / 2 - 10, cw - 24, "center")

        local btnW = 80
        local btnH = 24
        local btnX = cx + (cw - btnW) / 2
        local btnY = cy + ch / 2 + 20
        local mx, my = love.mouse.getPosition()
        local btnHov = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH
        love.graphics.setColor(btnHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
        self:drawBevel(btnX, btnY, btnW, btnH)
        love.graphics.setColor(W95.text)
        love.graphics.printf("Aceptar", btnX, btnY + 5, btnW, "center")
        table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "dismiss_coding"})
        love.graphics.setFont(prevFont)
        return
    end

    love.graphics.setColor(W95.text)
    love.graphics.setFont(self.smallFont)
    love.graphics.printf("Lenguaje: " .. self.snippet.lang .. " | Recompensa: $" .. self.reward, cx + 12, cy + 8, cw - 24, "center")

    local barX = cx + 12
    local barY = cy + 26
    local barW = cw - 24
    local barH = 16

    love.graphics.setColor(W95.fieldBg)
    love.graphics.rectangle("fill", barX, barY, barW, barH)
    self:drawBevel(barX, barY, barW, barH)

    love.graphics.setColor(W95.highlight)
    love.graphics.rectangle("fill", barX + 2, barY + 2, (barW - 4) * self.progress, barH - 4)

    love.graphics.setColor(W95.white)
    love.graphics.printf(math.floor(self.progress * 100) .. "%", barX, barY + 1, barW, "center")

    local codeX = cx + 12
    local codeY = cy + 48
    local codeW = cw - 24
    local codeH = ch - 60

    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.rectangle("fill", codeX, codeY, codeW, codeH)
    self:drawBevel(codeX, codeY, codeW, codeH)

    love.graphics.setScissor(codeX + 2, codeY + 2, codeW - 4, codeH - 4)

    love.graphics.setFont(self.codeFont)

    local lines = {}
    for line in self.typedText:gmatch("[^\n]*") do
        table.insert(lines, line)
    end

    local lineH = 16
    local maxLines = math.floor((codeH - 4) / lineH)
    local startLine = math.max(1, #lines - maxLines + 1)

    for i = startLine, #lines do
        local lineY = codeY + 2 + (i - startLine) * lineH
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.print(lines[i], codeX + 6, lineY)
    end

    if not self.isComplete and math.floor(self.cursorBlink * 2) % 2 == 0 then
        local lastLine = lines[#lines] or ""
        local cursorX = codeX + 6 + self.codeFont:getWidth(lastLine)
        local cursorY = codeY + 2 + (#lines - startLine) * lineH
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.rectangle("fill", cursorX, cursorY, 8, 14)
    end

    love.graphics.setScissor()

    love.graphics.setColor(W95.textDim)
    love.graphics.setFont(self.smallFont)
    love.graphics.printf("Presiona cualquier tecla para escribir codigo", cx + 12, cy + ch - 14, cw - 24, "center")

    love.graphics.setFont(prevFont)
end

return Coding
