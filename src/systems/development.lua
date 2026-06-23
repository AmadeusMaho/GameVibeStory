local Development = {}
Development.__index = Development

local GENRES = {
    {name = "RPG", unlockCost = 0, bonus = {programming = 1.2, design = 1.0}},
    {name = "Action", unlockCost = 0, bonus = {programming = 1.0, art = 1.2}},
    {name = "Sports", unlockCost = 500, bonus = {marketing = 1.3}},
    {name = "Strategy", unlockCost = 2000, bonus = {design = 1.3}},
    {name = "Simulation", unlockCost = 5000, bonus = {design = 1.2, programming = 1.1}},
    {name = "Adventure", unlockCost = 10000, bonus = {art = 1.3, sound = 1.1}},
    {name = "Puzzle", unlockCost = 25000, bonus = {programming = 1.3}},
    {name = "Horror", unlockCost = 50000, bonus = {art = 1.2, sound = 1.2}}
}

local PLATFORMS = {
    {name = "PC", unlockCost = 0, multiplier = 1.0},
    {name = "Console", unlockCost = 5000, multiplier = 1.5},
    {name = "Mobile", unlockCost = 2000, multiplier = 0.8},
    {name = "Handheld", unlockCost = 10000, multiplier = 1.2}
}

local HIDDEN_COMBOS = {
    {genre = "RPG", platform = "PC", bonus = 1.5, name = "Classic RPG"},
    {genre = "Action", platform = "Console", bonus = 1.4, name = "Console Action"},
    {genre = "Simulation", platform = "Mobile", bonus = 1.3, name = "Mobile Sim"},
    {genre = "Horror", platform = "Console", bonus = 1.6, name = "Console Horror"},
    {genre = "Strategy", platform = "PC", bonus = 1.4, name = "PC Strategy"}
}

function Development.new(game)
    local self = setmetatable({}, Development)
    
    self.game = game
    self.currentProject = nil
    self.completedGames = {}
    self.unlockedGenres = {"RPG", "Action"}
    self.unlockedPlatforms = {"PC"}
    self.discoveredCombos = {}
    
    self.developmentSpeed = 1.0
    self.qualityBonus = 0
    
    return self
end

function Development:update(dt)
    if self.currentProject then
        self.currentProject.progress = self.currentProject.progress + 
            self.developmentSpeed * self:getStaffSpeed() * dt
        
        if self.currentProject.progress >= self.currentProject.required then
            self:completeProject()
        end
    end
end

function Development:startProject(genreName, platformName)
    if self.currentProject then
        self.game:addNotification("Ya hay un proyecto en desarrollo!", "warning")
        return false
    end
    
    local genre = self:getGenre(genreName)
    local platform = self:getPlatform(platformName)
    
    if not genre or not platform then
        self.game:addNotification("Género o plataforma no disponible!", "error")
        return false
    end
    
    local baseCost = 100
    local cost = baseCost * math.pow(1.1, self.game.stats.totalGamesMade)
    
    if not self.game:spendMoney(cost) then
        self.game:addNotification("Dinero insuficiente!", "error")
        return false
    end
    
    self.currentProject = {
        genre = genreName,
        platform = platformName,
        progress = 0,
        required = 10 + self.game.stats.totalGamesMade * 2,
        quality = 0,
        startDate = os.time()
    }
    
    self.game:addNotification("Inicio: " .. genreName .. " para " .. platformName, "info")
    return true
end

function Development:completeProject()
    if not self.currentProject then return end
    
    local stats = self.game.staff:getAverageStats()
    local genre = self:getGenre(self.currentProject.genre)
    local platform = self:getPlatform(self.currentProject.platform)
    
    local quality = 0
    for stat, value in pairs(stats) do
        quality = quality + value * (genre.bonus[stat] or 1.0)
    end
    quality = quality / 5
    quality = quality * (1 + self.qualityBonus)
    quality = quality * (0.8 + math.random() * 0.4)
    quality = math.floor(quality)
    
    local income = self:calculateIncome(quality, self.currentProject.genre, self.currentProject.platform)
    local fameGain = math.floor(quality * 0.5)
    local repGain = math.floor(quality * 0.1)
    
    local combo = self:checkCombo(self.currentProject.genre, self.currentProject.platform)
    if combo then
        income = math.floor(income * combo.bonus)
        self.game:addNotification("COMBO: " .. combo.name .. " (+" .. math.floor((combo.bonus - 1) * 100) .. "%)", "success")
    end
    
    local gameEntry = {
        genre = self.currentProject.genre,
        platform = self.currentProject.platform,
        quality = quality,
        income = income,
        date = os.time()
    }
    
    table.insert(self.completedGames, gameEntry)
    self.game.stats.totalGamesMade = self.game.stats.totalGamesMade + 1
    
    self.game:addMoney(income)
    self.game:addFame(fameGain)
    self.game:addReputation(repGain)
    
    self.game:addNotification(
        string.format("¡Juego lanzado! Calidad: %d | Ingreso: $%s", 
            quality, self.game:formatNumber(income)),
        "success"
    )
    
    self.currentProject = nil
end

function Development:calculateIncome(quality, genreName, platformName)
    local base = 100
    local qualityMult = math.pow(quality / 10, 1.5)
    local fameMult = 1 + (self.game.stats.fame / 1000)
    local repMult = 1 + (self.game.stats.reputation / 100)
    
    return math.floor(base * qualityMult * fameMult * repMult)
end

function Development:checkCombo(genreName, platformName)
    for _, combo in ipairs(HIDDEN_COMBOS) do
        if combo.genre == genreName and combo.platform == platformName then
            if not self:isComboDiscovered(genreName, platformName) then
                table.insert(self.discoveredCombos, {genre = genreName, platform = platformName})
                self.game:addNotification("¡Nuevo combo descubierto!", "success")
            end
            return combo
        end
    end
    return nil
end

function Development:isComboDiscovered(genreName, platformName)
    for _, combo in ipairs(self.discoveredCombos) do
        if combo.genre == genreName and combo.platform == platformName then
            return true
        end
    end
    return false
end

function Development:getStaffSpeed()
    local stats = self.game.staff:getAverageStats()
    return (stats.programming + stats.design) / 20
end

function Development:getGenre(name)
    for _, genre in ipairs(GENRES) do
        if genre.name == name then
            return genre
        end
    end
    return nil
end

function Development:getPlatform(name)
    for _, platform in ipairs(PLATFORMS) do
        if platform.name == name then
            return platform
        end
    end
    return nil
end

function Development:unlockGenre(genreName)
    local genre = self:getGenre(genreName)
    if not genre then return false end
    
    for _, g in ipairs(self.unlockedGenres) do
        if g == genreName then return false end
    end
    
    if not self.game:spendMoney(genre.unlockCost) then
        self.game:addNotification("Dinero insuficiente!", "error")
        return false
    end
    
    table.insert(self.unlockedGenres, genreName)
    self.game:addNotification("Género desbloqueado: " .. genreName, "success")
    return true
end

function Development:unlockPlatform(platformName)
    local platform = self:getPlatform(platformName)
    if not platform then return false end
    
    for _, p in ipairs(self.unlockedPlatforms) do
        if p == platformName then return false end
    end
    
    if not self.game:spendMoney(platform.unlockCost) then
        self.game:addNotification("Dinero insuficiente!", "error")
        return false
    end
    
    table.insert(self.unlockedPlatforms, platformName)
    self.game:addNotification("Plataforma desbloqueada: " .. platformName, "success")
    return true
end

function Development:save()
    return {
        unlockedGenres = self.unlockedGenres,
        unlockedPlatforms = self.unlockedPlatforms,
        discoveredCombos = self.discoveredCombos,
        completedGames = self.completedGames
    }
end

function Development:load(data)
    self.unlockedGenres = data.unlockedGenres or {"RPG", "Action"}
    self.unlockedPlatforms = data.unlockedPlatforms or {"PC"}
    self.discoveredCombos = data.discoveredCombos or {}
    self.completedGames = data.completedGames or {}
end

return Development
