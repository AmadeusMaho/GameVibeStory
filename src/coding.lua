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

local monokai = {
    bg = {0.15, 0.16, 0.18},
    text = {0.97, 0.97, 0.94},
    keyword = {0.98, 0.45, 0.36},
    string = {0.90, 0.78, 0.35},
    comment = {0.50, 0.52, 0.54},
    func = {0.70, 0.90, 0.30},
    number = {0.68, 0.45, 0.97},
    variable = {0.30, 0.85, 0.85},
    operator = {0.97, 0.97, 0.94},
    lineNum = {0.40, 0.42, 0.44},
}

local appTypes = {
    {
        id = "desktop",
        name = "Aplicacion de escritorio",
        difficulty = "normal",
        baseCost = 500,
        baseQuality = 1.0,
        desc = "Programa de productividad\npara Windows 95",
        difficultyLabel = "Normal",
        difficultyColor = {0.9, 0.9, 0.2},
    },
    {
        id = "utility",
        name = "Utilidad del sistema",
        difficulty = "facil",
        baseCost = 300,
        baseQuality = 1.2,
        desc = "Herramienta para optimizar\no mantener el sistema",
        difficultyLabel = "Facil",
        difficultyColor = {0.2, 0.8, 0.2},
    },
    {
        id = "game",
        name = "Videojuego",
        difficulty = "dificil",
        baseCost = 1000,
        baseQuality = 0.8,
        desc = "Juego para PC\nRequiere graficos y sonido",
        difficultyLabel = "Dificil",
        difficultyColor = {0.9, 0.6, 0.2},
    },
    {
        id = "database",
        name = "Base de datos",
        difficulty = "normal",
        baseCost = 800,
        baseQuality = 1.0,
        desc = "Sistema de gestion\nde datos empresariales",
        difficultyLabel = "Normal",
        difficultyColor = {0.9, 0.9, 0.2},
    },
    {
        id = "web",
        name = "Pagina web",
        difficulty = "dificil",
        baseCost = 1200,
        baseQuality = 0.7,
        desc = "Sitio web interactivo\ncon HTML y JavaScript",
        difficultyLabel = "Dificil",
        difficultyColor = {0.9, 0.6, 0.2},
    },
    {
        id = "os",
        name = "Sistema operativo",
        difficulty = "pesadilla",
        baseCost = 5000,
        baseQuality = 0.5,
        desc = "Sistema operativo completo\nRequiere equipo avanzado",
        difficultyLabel = "Pesadilla",
        difficultyColor = {0.6, 0.0, 0.6},
    },
}

local codeTemplates = {
    python = {
        '#!/usr/bin/env python',
        '# -*- coding: utf-8 -*-',
        '',
        'import os',
        'import sys',
        'from datetime import datetime',
        '',
        'class Application:',
        '    """Clase principal de la aplicacion"""',
        '    ',
        '    def __init__(self, name, version):',
        '        self.name = name',
        '        self.version = version',
        '        self.running = False',
        '        self.data = {}',
        '    ',
        '    def initialize(self):',
        '        """Inicializar componentes"""',
        '        print(f"Iniciando {self.name} v{self.version}")',
        '        self.running = True',
        '        self.load_config()',
        '        return True',
        '    ',
        '    def load_config(self):',
        '        """Cargar configuracion"""',
        '        config_path = os.path.join(os.getcwd(), "config.ini")',
        '        if os.path.exists(config_path):',
        '            with open(config_path, "r") as f:',
        '                for line in f:',
        '                    key, value = line.strip().split("=")',
        '                    self.data[key] = value',
        '    ',
        '    def process_data(self, items):',
        '        """Procesar lista de elementos"""',
        '        results = []',
        '        for item in items:',
        '            if item.is_valid():',
        '                processed = self.transform(item)',
        '                results.append(processed)',
        '        return sorted(results, key=lambda x: x.date)',
        '    ',
        '    def save_results(self, results):',
        '        """Guardar resultados en disco"""',
        '        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")',
        '        filename = f"output_{timestamp}.dat"',
        '        with open(filename, "wb") as f:',
        '            for result in results:',
        '                f.write(result.serialize())',
        '        return filename',
        '',
        'if __name__ == "__main__":',
        '    app = Application("MiApp", "1.0.0")',
        '    if app.initialize():',
        '        print("Aplicacion iniciada correctamente")',
        '        data = app.process_data(load_input())',
        '        app.save_results(data)',
    },
    javascript = {
        '// Aplicacion JavaScript',
        'const express = require("express");',
        'const path = require("path");',
        '',
        'class Server {',
        '    constructor(port) {',
        '        this.port = port;',
        '        this.app = express();',
        '        this.routes = new Map();',
        '        this.middleware = [];',
        '    }',
        '',
        '    use(fn) {',
        '        this.middleware.push(fn);',
        '        this.app.use(fn);',
        '    }',
        '',
        '    get(path, handler) {',
        '        this.routes.set(`GET:${path}`, handler);',
        '        this.app.get(path, handler);',
        '    }',
        '',
        '    post(path, handler) {',
        '        this.routes.set(`POST:${path}`, handler);',
        '        this.app.post(path, handler);',
        '    }',
        '',
        '    start() {',
        '        return new Promise((resolve) => {',
        '            this.server = this.app.listen(this.port, () => {',
        '                console.log(`Server running on port ${this.port}`);',
        '                resolve();',
        '            });',
        '        });',
        '    }',
        '',
        '    stop() {',
        '        if (this.server) {',
        '            this.server.close();',
        '        }',
        '    }',
        '}',
        '',
        'const server = new Server(3000);',
        'server.use(express.json());',
        'server.use(express.static("public"));',
        '',
        'server.get("/api/data", (req, res) => {',
        '    const data = fetchDataFromDB();',
        '    res.json({ success: true, data });',
        '});',
        '',
        'server.post("/api/submit", async (req, res) => {',
        '    const { name, email, message } = req.body;',
        '    const result = await saveToDatabase({ name, email, message });',
        '    res.json({ success: true, id: result.insertId });',
        '});',
        '',
        'server.start().then(() => {',
        '    console.log("Servidor iniciado");',
        '});',
    },
    c = {
        '#include <stdio.h>',
        '#include <stdlib.h>',
        '#include <string.h>',
        '#include <ctype.h>',
        '',
        '#define MAX_BUFFER 1024',
        '#define MAX_ENTRIES 100',
        '',
        'typedef struct {',
        '    char name[64];',
        '    int id;',
        '    double value;',
        '    struct tm created;',
        '} Entry;',
        '',
        'typedef struct {',
        '    Entry entries[MAX_ENTRIES];',
        '    int count;',
        '    char filename[256];',
        '} Database;',
        '',
        'Database* db_create(const char* filename) {',
        '    Database* db = malloc(sizeof(Database));',
        '    if (!db) return NULL;',
        '    db->count = 0;',
        '    strncpy(db->filename, filename, 255);',
        '    return db;',
        '}',
        '',
        'int db_add(Database* db, const char* name, double value) {',
        '    if (db->count >= MAX_ENTRIES) return -1;',
        '    Entry* e = &db->entries[db->count];',
        '    strncpy(e->name, name, 63);',
        '    e->id = db->count + 1;',
        '    e->value = value;',
        '    db->count++;',
        '    return e->id;',
        '}',
        '',
        'int db_save(Database* db) {',
        '    FILE* f = fopen(db->filename, "wb");',
        '    if (!f) return -1;',
        '    fwrite(&db->count, sizeof(int), 1, f);',
        '    fwrite(db->entries, sizeof(Entry), db->count, f);',
        '    fclose(f);',
        '    return 0;',
        '}',
        '',
        'Database* db_load(const char* filename) {',
        '    Database* db = db_create(filename);',
        '    if (!db) return NULL;',
        '    FILE* f = fopen(filename, "rb");',
        '    if (!f) { free(db); return NULL; }',
        '    fread(&db->count, sizeof(int), 1, f);',
        '    fread(db->entries, sizeof(Entry), db->count, f);',
        '    fclose(f);',
        '    return db;',
        '}',
        '',
        'void db_print(Database* db) {',
        '    printf("Database: %s (%d entries)\\n", db->filename, db->count);',
        '    for (int i = 0; i < db->count; i++) {',
        '        printf("  [%d] %s: %.2f\\n", db->entries[i].id,',
        '               db->entries[i].name, db->entries[i].value);',
        '    }',
        '}',
        '',
        'int main(int argc, char* argv[]) {',
        '    Database* db = db_create("data.db");',
        '    db_add(db, "Item 1", 100.50);',
        '    db_add(db, "Item 2", 200.75);',
        '    db_save(db);',
        '    db_print(db);',
        '    free(db);',
        '    return 0;',
        '}',
    },
}

local reviewCompanies = {
    {name = "PC Magazine", harshness = 0.3},
    {name = "Computer World", harshness = 0.5},
    {name = "Tech Review", harshness = 0.7},
    {name = "Software Weekly", harshness = 0.4},
    {name = "Digital Trends", harshness = 0.6},
}

function Coding.new(x, y)
    local self = setmetatable({}, Coding)
    self.window = WindowManager.new("Code Editor", x or 200, y or 100, 560, 440)

    self.trabajoRef = nil
    self.explorerRef = nil

    self.codingLevel = 1
    self.codingXP = 0
    self.xpPerLevel = {100, 250, 500, 1000, 2000}

    self.state = "menu"
    self.selectedType = 1
    self.appName = "Mi Aplicacion"
    self.inputActive = false

    self.currentCode = {}
    self.codeIndex = 0
    self.charIndex = 0
    self.scrollY = 0
    self.targetScrollY = 0
    self.progress = 0
    self.quality = 0

    self.reviews = {}
    self.reviewIndex = 0
    self.reviewTimer = 0

    self.salesData = {}
    self.currentMonth = 0
    self.totalRevenue = 0
    self.salesTimer = 0
    self.salesSpeed = 0.5

    self.completeMessage = ""
    self.completeTimer = 0

    self.cursorBlink = 0
    self.buttons = {}

    self.codeFont = love.graphics.newFont(13)
    self.smallFont = love.graphics.newFont(11)
    self.titleFont = love.graphics.newFont(14)

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

function Coding:getCodingLevel()
    return self.codingLevel
end

function Coding:getCharsPerKey()
    return 3 + self.codingLevel * 2
end

function Coding:getQualityMultiplier()
    local base = 0.5 + self.codingLevel * 0.15
    if self.explorerRef then
        local cpuLevel = self.explorerRef.upgradeLevels.cpu or 0
        base = base + cpuLevel * 0.05
        local gpuLevel = self.explorerRef.upgradeLevels.display or 0
        base = base + gpuLevel * 0.03
    end
    return base
end

function Coding:calculateReviewScores()
    local quality = self.quality
    local scores = {}
    for _, company in ipairs(reviewCompanies) do
        local base = quality * 10
        local variation = (math.random() - 0.5) * 3
        local harsh = company.harshness * (1 - self.codingLevel * 0.05)
        local score = math.max(1, math.min(10, base + variation - harsh * 2))
        table.insert(scores, {
            company = company.name,
            score = math.floor(score * 10) / 10,
            text = self:getReviewText(score),
        })
    end
    return scores
end

function Coding:getReviewText(score)
    if score >= 8 then return "Excelente! Altamente recomendado." end
    if score >= 6 then return "Buen trabajo. Solido y confiable." end
    if score >= 4 then return "Regular. Necesita mejoras." end
    if score >= 2 then return "Decepcionante. Muchos bugs." end
    return "Terrible. No lo compren."
end

function Coding:calculateSales()
    local avgScore = 0
    for _, r in ipairs(self.reviews) do
        avgScore = avgScore + r.score
    end
    avgScore = avgScore / #self.reviews

    local baseSales = avgScore * 10
    local levelBonus = self.codingLevel * 5
    local peakSales = baseSales + levelBonus

    local months = {}
    local revenue = 0
    for m = 1, 12 do
        local decay = math.max(0.1, 1 - (m - 1) * 0.08)
        local sales = math.floor(peakSales * decay)
        local monthRevenue = sales * (10 + self.codingLevel * 2)
        revenue = revenue + monthRevenue
        table.insert(months, {
            month = m,
            sales = sales,
            revenue = monthRevenue,
        })
    end
    return months, revenue
end

function Coding:startCoding()
    local appType = appTypes[self.selectedType]
    local templates = {"python", "javascript", "c"}
    local lang = templates[math.random(#templates)]
    self.currentCode = codeTemplates[lang]
    self.codeIndex = 0
    self.charIndex = 0
    self.scrollY = 0
    self.targetScrollY = 0
    self.progress = 0
    self.quality = 0
    self.reviews = {}
    self.reviewIndex = 0
    self.reviewTimer = 0
    self.salesData = {}
    self.currentMonth = 0
    self.totalRevenue = 0
    self.salesTimer = 0
    self.state = "coding"
end

function Coding:handleClick(x, y, button)
    if button ~= 1 then return false end

    for _, btn in ipairs(self.buttons) do
        if x >= btn.x and x <= btn.x + btn.w and y >= btn.y and y <= btn.y + btn.h then
            if btn.action == "select_type" then
                self.selectedType = btn.index
            elseif btn.action == "start_project" then
                local appType = appTypes[self.selectedType]
                if self.trabajoRef and self.trabajoRef.money >= appType.baseCost then
                    self.trabajoRef.money = self.trabajoRef.money - appType.baseCost
                    self:startCoding()
                end
            elseif btn.action == "input_name" then
                self.inputActive = true
            elseif btn.action == "dismiss_reviews" then
                self.state = "sales"
                self.currentMonth = 1
                self.salesTimer = 0
            elseif btn.action == "finish_sales" then
                if self.trabajoRef then
                    self.trabajoRef.money = self.trabajoRef.money + self.totalRevenue
                    self.trabajoRef.totalEarned = self.trabajoRef.totalEarned + self.totalRevenue
                end
                self.codingXP = self.codingXP + math.floor(self.totalRevenue / 10)
                self:checkLevelUp()
                self.state = "menu"
            elseif btn.action == "back_menu" then
                self.state = "menu"
            end
            return true
        end
    end
    return true
end

function Coding:checkLevelUp()
    local maxLevel = #self.xpPerLevel
    if self.codingLevel >= maxLevel then return end
    local needed = self.xpPerLevel[self.codingLevel]
    if self.codingXP >= needed then
        self.codingLevel = self.codingLevel + 1
        self.codingXP = self.codingXP - needed
    end
end

function Coding:keypressed(key)
    if self.state == "menu" and self.inputActive then
        if key == "backspace" then
            self.appName = self.appName:sub(1, -2)
        elseif key == "return" or key == "escape" then
            self.inputActive = false
        elseif #key == 1 and #self.appName < 30 then
            self.appName = self.appName .. key
        end
        return
    end

    if self.state ~= "coding" then return end
    if key == "lshift" or key == "rshift" or key == "lctrl" or key == "rctrl" or
       key == "lalt" or key == "ralt" or key == "escape" or key == "tab" or
       key == "capslock" then
        return
    end

    local charsToAdd = self:getCharsPerKey()
    for i = 1, charsToAdd do
        if self.codeIndex < #self.currentCode then
            local currentLine = self.currentCode[self.codeIndex]
            if self.charIndex < #currentLine then
                self.charIndex = self.charIndex + 1
            else
                self.codeIndex = self.codeIndex + 1
                self.charIndex = 0
                if self.codeIndex <= #self.currentCode then
                    self.targetScrollY = self.targetScrollY + 16
                end
            end
        end
    end

    local totalChars = 0
    for _, line in ipairs(self.currentCode) do
        totalChars = totalChars + #line + 1
    end
    local typedChars = 0
    for i = 1, self.codeIndex do
        typedChars = typedChars + #self.currentCode[i] + 1
    end
    typedChars = typedChars + self.charIndex
    self.progress = math.min(1, typedChars / totalChars)
    self.quality = self.progress * self:getQualityMultiplier()

    if self.codeIndex >= #self.currentCode and self.charIndex >= #self.currentCode[#self.currentCode] then
        self.state = "reviews"
        self.reviews = self:calculateReviewScores()
        self.reviewIndex = 0
        self.reviewTimer = 0
        self.salesData, self.totalRevenue = self:calculateSales()
    end
end

function Coding:update(dt)
    self.cursorBlink = self.cursorBlink + dt

    if self.state == "coding" then
        self.scrollY = self.scrollY + (self.targetScrollY - self.scrollY) * dt * 10
    end

    if self.state == "reviews" then
        self.reviewTimer = self.reviewTimer + dt
        if self.reviewTimer > 0.8 then
            self.reviewTimer = 0
            if self.reviewIndex < #self.reviews then
                self.reviewIndex = self.reviewIndex + 1
            end
        end
    end

    if self.state == "sales" then
        self.salesTimer = self.salesTimer + dt
        if self.salesTimer >= self.salesSpeed then
            self.salesTimer = 0
            if self.currentMonth <= #self.salesData then
                self.currentMonth = self.currentMonth + 1
            end
        end
    end
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

    if self.state == "menu" then
        self:drawMenu(cx, cy, cw, ch)
    elseif self.state == "coding" then
        self:drawCoding(cx, cy, cw, ch)
    elseif self.state == "reviews" then
        self:drawReviews(cx, cy, cw, ch)
    elseif self.state == "sales" then
        self:drawSales(cx, cy, cw, ch)
    end

    love.graphics.setFont(prevFont)
end

function Coding:drawMenu(x, y, w, h)
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", x + 6, y + 4, w - 12, h - 8)
    self:drawBevel(x + 6, y + 4, w - 12, h - 8)

    love.graphics.setColor(W95.text)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("Desarrollo de Software", x + 12, y + 10, w - 24, "center")

    love.graphics.setFont(self.smallFont)
    love.graphics.setColor(W95.yellow)
    love.graphics.printf("Nivel de Coding: " .. self.codingLevel, x + 12, y + 30, w - 24, "center")

    local nextXP = self.xpPerLevel[self.codingLevel] or "MAX"
    love.graphics.setColor(W95.textDim)
    love.graphics.printf("XP: " .. self.codingXP .. "/" .. nextXP, x + 12, y + 44, w - 24, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 12, y + 60, x + w - 12, y + 60)

    love.graphics.setColor(W95.text)
    love.graphics.printf("Nombre de la app:", x + 12, y + 66, w - 24, "left")

    local nameBoxX = x + 12
    local nameBoxY = y + 80
    local nameBoxW = w - 24
    local nameBoxH = 20

    love.graphics.setColor(self.inputActive and W95.white or W95.fieldBg)
    love.graphics.rectangle("fill", nameBoxX, nameBoxY, nameBoxW, nameBoxH)
    self:drawBevel(nameBoxX, nameBoxY, nameBoxW, nameBoxH)

    love.graphics.setColor(W95.text)
    love.graphics.print(self.appName, nameBoxX + 4, nameBoxY + 3)
    table.insert(self.buttons, {x = nameBoxX, y = nameBoxY, w = nameBoxW, h = nameBoxH, action = "input_name"})

    love.graphics.setColor(W95.text)
    love.graphics.printf("Tipo de aplicacion:", x + 12, y + 108, w - 24, "left")

    local gridX = x + 12
    local gridY = y + 124
    local cellW = (w - 30) / 2
    local cellH = 42

    for i, appType in ipairs(appTypes) do
        local col = (i - 1) % 2
        local row = math.floor((i - 1) / 2)
        local cx = gridX + col * (cellW + 4)
        local cy = gridY + row * (cellH + 4)

        local isSelected = i == self.selectedType
        local hovered = self.lastMX >= cx and self.lastMX <= cx + cellW and self.lastMY >= cy and self.lastMY <= cy + cellH

        love.graphics.setColor(isSelected and {0.9, 0.9, 1.0} or (hovered and {0.85, 0.85, 0.85} or W95.bg))
        love.graphics.rectangle("fill", cx, cy, cellW, cellH)
        self:drawBevel(cx, cy, cellW, cellH)

        love.graphics.setColor(W95.text)
        love.graphics.setFont(self.smallFont)
        love.graphics.printf(appType.name, cx + 4, cy + 4, cellW - 8, "center")

        love.graphics.setColor(appType.difficultyColor)
        love.graphics.printf(appType.difficultyLabel, cx + 4, cy + 17, cellW - 8, "center")

        love.graphics.setColor(W95.textDim)
        love.graphics.printf("$" .. appType.baseCost, cx + 4, cy + 29, cellW - 8, "center")

        table.insert(self.buttons, {x = cx, y = cy, w = cellW, h = cellH, action = "select_type", index = i})
    end

    local selectedType = appTypes[self.selectedType]
    love.graphics.setColor(W95.textDim)
    love.graphics.setFont(self.smallFont)
    love.graphics.printf(selectedType.desc, x + 12, y + h - 80, w - 24, "center")

    local btnW = 140
    local btnH = 28
    local btnX = x + (w - btnW) / 2
    local btnY = y + h - 42
    local mx, my = love.mouse.getPosition()
    local btnHov = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH
    local canAfford = self.trabajoRef and self.trabajoRef.money >= selectedType.baseCost

    if canAfford then
        love.graphics.setColor(btnHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
        self:drawBevel(btnX, btnY, btnW, btnH)
        love.graphics.setColor(W95.green)
        love.graphics.printf("Desarrollar ($" .. selectedType.baseCost .. ")", btnX, btnY + 7, btnW, "center")
    else
        love.graphics.setColor(W95.textDim)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
        self:drawBevel(btnX, btnY, btnW, btnH)
        love.graphics.setColor(W95.red)
        love.graphics.printf("Sin fondos", btnX, btnY + 7, btnW, "center")
    end
    table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "start_project"})
end

function Coding:drawCoding(x, y, w, h)
    love.graphics.setColor(monokai.bg)
    love.graphics.rectangle("fill", x + 6, y + 4, w - 12, h - 8)

    love.graphics.setColor(W95.text)
    love.graphics.setFont(self.smallFont)
    love.graphics.printf("Desarrollando: " .. self.appName, x + 12, y + 8, w - 24, "center")

    local barX = x + 12
    local barY = y + 24
    local barW = w - 24
    local barH = 14

    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", barX, barY, barW, barH)
    self:drawBevel(barX, barY, barW, barH)

    love.graphics.setColor(monokai.func)
    love.graphics.rectangle("fill", barX + 2, barY + 2, (barW - 4) * self.progress, barH - 4)

    love.graphics.setColor(monokai.text)
    love.graphics.printf(math.floor(self.progress * 100) .. "%", barX, barY, barW, "center")

    local codeX = x + 12
    local codeY = y + 44
    local codeW = w - 24
    local codeH = h - 56

    love.graphics.setColor(monokai.bg)
    love.graphics.rectangle("fill", codeX, codeY, codeW, codeH)
    love.graphics.setColor(W95.borderDark)
    love.graphics.rectangle("line", codeX, codeY, codeW, codeH)

    love.graphics.setScissor(codeX + 1, codeY + 1, codeW - 2, codeH - 2)

    love.graphics.setFont(self.codeFont)
    local lineH = 16
    local maxLines = math.floor((codeH - 4) / lineH)
    local startLine = math.max(1, math.floor(self.scrollY / lineH) + 1)
    local endLine = math.min(#self.currentCode, startLine + maxLines - 1)

    for i = startLine, endLine do
        local lineY = codeY + 2 + (i - startLine) * lineH - (self.scrollY % lineH)

        love.graphics.setColor(monokai.lineNum)
        love.graphics.printf(i, codeX + 4, lineY, 30, "right")

        local lineText = ""
        if i < self.codeIndex then
            lineText = self.currentCode[i]
        elseif i == self.codeIndex then
            lineText = self.currentCode[i]:sub(1, self.charIndex)
        end

        if #lineText > 0 then
            local textX = codeX + 38
            local keywords = {"if", "else", "for", "while", "return", "function", "class", "def", "import", "from", "const", "let", "var", "int", "char", "void", "struct", "typedef", "include", "define", "printf"}
            local funcs = {"print", "len", "range", "sorted", "append", "malloc", "free", "fopen", "fclose", "fread", "fwrite", "require", "listen", "json", "then"}

            local tokens = {}
            local current = ""
            for c in lineText:gmatch(".") do
                if c:match("[%s%(%)%[%]{};,:]") then
                    if #current > 0 then
                        table.insert(tokens, current)
                        current = ""
                    end
                    table.insert(tokens, c)
                else
                    current = current .. c
                end
            end
            if #current > 0 then table.insert(tokens, current) end

            local drawX = textX
            for _, token in ipairs(tokens) do
                local color = monokai.text
                if token:match("^%d+$") then
                    color = monokai.number
                elseif token:match('".*"') or token:match("'.*'") then
                    color = monokai.string
                elseif token:match("^//") or token:match("^#") then
                    color = monokai.comment
                else
                    for _, kw in ipairs(keywords) do
                        if token == kw then
                            color = monokai.keyword
                            break
                        end
                    end
                    for _, fn in ipairs(funcs) do
                        if token == fn then
                            color = monokai.func
                            break
                        end
                    end
                end
                love.graphics.setColor(color)
                love.graphics.print(token, drawX, lineY)
                drawX = drawX + self.codeFont:getWidth(token)
            end
        end

        if i == self.codeIndex and math.floor(self.cursorBlink * 2) % 2 == 0 then
            local cursorX = codeX + 38 + self.codeFont:getWidth(self.currentCode[i]:sub(1, self.charIndex))
            love.graphics.setColor(monokai.text)
            love.graphics.rectangle("fill", cursorX, lineY, 8, 14)
        end
    end

    love.graphics.setScissor()

    love.graphics.setColor(W95.textDim)
    love.graphics.setFont(self.smallFont)
    love.graphics.printf("Presiona cualquier tecla para escribir codigo", x + 12, y + h - 14, w - 24, "center")
end

function Coding:drawReviews(x, y, w, h)
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", x + 6, y + 4, w - 12, h - 8)
    self:drawBevel(x + 6, y + 4, w - 12, h - 8)

    love.graphics.setColor(W95.text)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("Reviews: " .. self.appName, x + 12, y + 10, w - 24, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 12, y + 30, x + w - 12, y + 30)

    love.graphics.setFont(self.smallFont)
    for i = 1, self.reviewIndex do
        local review = self.reviews[i]
        if review then
            local ry = y + 36 + (i - 1) * 50

            love.graphics.setColor(W95.text)
            love.graphics.setFont(self.titleFont)
            love.graphics.print(review.company, x + 16, ry)

            local scoreColor = W95.green
            if review.score < 5 then scoreColor = W95.red
            elseif review.score < 7 then scoreColor = W95.yellow end
            love.graphics.setColor(scoreColor)
            love.graphics.printf(review.score .. "/10", x + w - 80, ry, 60, "right")

            love.graphics.setColor(W95.textDim)
            love.graphics.setFont(self.smallFont)
            love.graphics.print(review.text, x + 16, ry + 18)
        end
    end

    if self.reviewIndex >= #self.reviews then
        local btnW = 100
        local btnH = 24
        local btnX = x + (w - btnW) / 2
        local btnY = y + h - 40
        local mx, my = love.mouse.getPosition()
        local btnHov = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH

        love.graphics.setColor(btnHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
        self:drawBevel(btnX, btnY, btnW, btnH)
        love.graphics.setColor(W95.text)
        love.graphics.printf("Ver ventas", btnX, btnY + 5, btnW, "center")
        table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "dismiss_reviews"})
    end
end

function Coding:drawSales(x, y, w, h)
    love.graphics.setColor(W95.bg)
    love.graphics.rectangle("fill", x + 6, y + 4, w - 12, h - 8)
    self:drawBevel(x + 6, y + 4, w - 12, h - 8)

    love.graphics.setColor(W95.text)
    love.graphics.setFont(self.titleFont)
    love.graphics.printf("Ventas: " .. self.appName, x + 12, y + 10, w - 24, "center")

    love.graphics.setColor(W95.green)
    love.graphics.setFont(self.smallFont)
    local revenueSoFar = 0
    for i = 1, math.min(self.currentMonth - 1, #self.salesData) do
        revenueSoFar = revenueSoFar + self.salesData[i].revenue
    end
    love.graphics.printf("Total: $" .. revenueSoFar, x + 12, y + 28, w - 24, "center")

    love.graphics.setColor(W95.borderDark)
    love.graphics.line(x + 12, y + 44, x + w - 12, y + 44)

    local tableX = x + 16
    local tableY = y + 50
    local colW = {(w - 40) / 3, (w - 40) / 3, (w - 40) / 3}
    local rowH = 18

    love.graphics.setColor(W95.highlight)
    love.graphics.rectangle("fill", tableX, tableY, w - 32, rowH)
    love.graphics.setColor(W95.highlightText)
    love.graphics.setFont(self.smallFont)
    love.graphics.print("Mes", tableX + 4, tableY + 2)
    love.graphics.print("Ventas", tableX + colW[1] + 4, tableY + 2)
    love.graphics.print("Ingresos", tableX + colW[1] + colW[2] + 4, tableY + 2)

    for i = 1, math.min(self.currentMonth - 1, #self.salesData) do
        local data = self.salesData[i]
        local ry = tableY + rowH + (i - 1) * rowH
        local isEven = i % 2 == 0

        if isEven then
            love.graphics.setColor({0.92, 0.92, 0.92})
            love.graphics.rectangle("fill", tableX, ry, w - 32, rowH)
        end

        love.graphics.setColor(W95.text)
        love.graphics.print("Mes " .. data.month, tableX + 4, ry + 2)
        love.graphics.print(data.sales .. " uds", tableX + colW[1] + 4, ry + 2)
        love.graphics.setColor(W95.green)
        love.graphics.print("$" .. data.revenue, tableX + colW[1] + colW[2] + 4, ry + 2)
    end

    if self.currentMonth > #self.salesData then
        love.graphics.setColor(W95.text)
        love.graphics.setFont(self.titleFont)
        love.graphics.printf("Producto retirado del mercado", x + 12, y + h - 60, w - 24, "center")

        local btnW = 120
        local btnH = 28
        local btnX = x + (w - btnW) / 2
        local btnY = y + h - 38
        local mx, my = love.mouse.getPosition()
        local btnHov = mx >= btnX and mx <= btnX + btnW and my >= btnY and my <= btnY + btnH

        love.graphics.setColor(btnHov and {0.85, 0.85, 0.85} or W95.bg)
        love.graphics.rectangle("fill", btnX, btnY, btnW, btnH)
        self:drawBevel(btnX, btnY, btnW, btnH)
        love.graphics.setColor(W95.green)
        love.graphics.printf("Cobrar $" .. self.totalRevenue, btnX, btnY + 6, btnW, "center")
        table.insert(self.buttons, {x = btnX, y = btnY, w = btnW, h = btnH, action = "finish_sales"})
    end
end

function Coding:mousemoved(x, y)
    self.lastMX = x
    self.lastMY = y
end

function Coding:mousereleased(x, y, button)
end

function Coding:draw(mx, my)
    self.window:drawFrame()
end

function Coding:hitTest(mx, my)
    return self.window:hitTest(mx, my)
end

function Coding:mousepressed(x, y, button)
    return self.window:mousepressed(x, y, button)
end

function Coding:textinput(text)
    if self.state == "menu" and self.inputActive then
        if #self.appName < 30 then
            self.appName = self.appName .. text
        end
    end
end

return Coding
