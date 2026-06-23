local Prestige = {}
Prestige.__index = Prestige

local CONSOLE_GENERATIONS = {
    {name = "Retro Boy", era = "8-bit", cost = 100000, qualityBonus = 0.1, speedBonus = 0.1},
    {name = "Super System", era = "16-bit", cost = 500000, qualityBonus = 0.2, speedBonus = 0.15},
    {name = "PlayStation", era = "3D", cost = 2000000, qualityBonus = 0.3, speedBonus = 0.2},
    {name = "NextGen", era = "VR", cost = 10000000, qualityBonus = 0.5, speedBonus = 0.3}
}

local PRESTIGE_UPGRADES = {
    {name = "Experiencia Heredada", cost = 1, effect = "staffXpMult", value = 0.25, description = "+25% XP staff"},
    {name = "Reputación Legendaria", cost = 2, effect = "reputationMult", value = 0.5, description = "+50% reputación"},
    {name = "Red de Contactos", cost = 3, effect = "fameMult", value = 0.3, description = "+30% fama"},
    {name = "Inversión Inteligente", cost = 5, effect = "moneyMult", value = 0.25, description = "+25% ingresos"},
    {name = "Calidad Superior", cost = 8, effect = "qualityMult", value = 0.15, description = "+15% calidad"},
    {name = "Velocidad Extrema", cost = 12, effect = "speedMult", value = 0.2, description = "+20% velocidad"}
}

function Prestige.new(game)
    local self = setmetatable({}, Prestige)
    
    self.game = game
    self.legacy = 0
    self.totalLegacy = 0
    self.prestigeCount = 0
    self.consoleGen = 0
    self.unlockedUpgrades = {}
    self.purchasedUpgrades = {}
    
    return self
end

function Prestige:getLegacyGain()
    local totalMoney = self.game.stats.totalMoneyEarned
    if totalMoney < 1000 then return 0 end
    
    local base = math.log10(totalMoney) - 2
    local multiplier = 1 + (self.prestigeCount * 0.1)
    
    return math.floor(base * multiplier)
end

function Prestige:canPrestige()
    return self:getLegacyGain() > 0
end

function Prestige:prestige()
    if not self:canPrestige() then
        self.game:addNotification("No puedes prestigear aún!", "warning")
        return false
    end
    
    local legacyGain = self:getLegacyGain()
    self.legacy = self.legacy + legacyGain
    self.totalLegacy = self.totalLegacy + legacyGain
    self.prestigeCount = self.prestigeCount + 1
    
    self.game.stats.money = 0
    self.game.stats.research = 0
    self.game.staff.members = {}
    self.game.staff.hireCost = 100
    self.game.office.level = 1
    self.game.office.purchasedEquipment = {}
    self.game.development.currentProject = nil
    self.game.development.unlockedGenres = {"RPG", "Action"}
    self.game.development.unlockedPlatforms = {"PC"}
    
    self.game.stats:addReputation(-self.game.stats.reputation)
    
    self:unlockConsole()
    
    self.game:addNotification(
        string.format("¡PRESTIGE! +%d Legado (Gen %d)", legacyGain, self.prestigeCount),
        "success"
    )
    
    return true
end

function Prestige:unlockConsole()
    if self.consoleGen < #CONSOLE_GENERATIONS then
        local nextGen = CONSOLE_GENERATIONS[self.consoleGen + 1]
        if self.totalLegacy >= nextGen.cost then
            self.consoleGen = self.consoleGen + 1
            self.game:addNotification("¡Consola desbloqueada: " .. nextGen.name .. "!", "success")
        end
    end
end

function Prestige:getConsoleBonus()
    if self.consoleGen == 0 then return {quality = 0, speed = 0} end
    
    local bonus = {quality = 0, speed = 0}
    for i = 1, self.consoleGen do
        bonus.quality = bonus.quality + CONSOLE_GENERATIONS[i].qualityBonus
        bonus.speed = bonus.speed + CONSOLE_GENERATIONS[i].speedBonus
    end
    return bonus
end

function Prestige:buyUpgrade(index)
    local upgrade = PRESTIGE_UPGRADES[index]
    if not upgrade then return false end
    
    if self:hasUpgrade(index) then
        self.game:addNotification("Ya tienes esta mejora!", "warning")
        return false
    end
    
    if self.legacy < upgrade.cost then
        self.game:addNotification("Legado insuficiente!", "error")
        return false
    end
    
    self.legacy = self.legacy - upgrade.cost
    table.insert(self.purchasedUpgrades, index)
    self:applyUpgrade(upgrade)
    
    self.game:addNotification("Mejora desbloqueada: " .. upgrade.name, "success")
    return true
end

function Prestige:applyUpgrade(upgrade)
    local game = self.game
    local effect = upgrade.effect
    local value = upgrade.value
    
    if effect == "staffXpMult" then
        for _, member in ipairs(game.staff.members) do
            member.experience = member.experience * (1 + value)
        end
    elseif effect == "moneyMult" then
        game.stats.moneyPerSecond = game.stats.moneyPerSecond * (1 + value)
    end
end

function Prestige:hasUpgrade(index)
    for _, idx in ipairs(self.purchasedUpgrades) do
        if idx == index then return true end
    end
    return false
end

function Prestige:getMultiplier(effect)
    local mult = 1
    for _, idx in ipairs(self.purchasedUpgrades) do
        local upgrade = PRESTIGE_UPGRADES[idx]
        if upgrade.effect == effect then
            mult = mult + upgrade.value
        end
    end
    return mult
end

function Prestige:getAllUpgrades()
    return PRESTIGE_UPGRADES
end

function Prestige:getConsoles()
    return CONSOLE_GENERATIONS
end

function Prestige:save()
    return {
        legacy = self.legacy,
        totalLegacy = self.totalLegacy,
        prestigeCount = self.prestigeCount,
        consoleGen = self.consoleGen,
        purchasedUpgrades = self.purchasedUpgrades
    }
end

function Prestige:load(data)
    self.legacy = data.legacy or 0
    self.totalLegacy = data.totalLegacy or 0
    self.prestigeCount = data.prestigeCount or 0
    self.consoleGen = data.consoleGen or 0
    self.purchasedUpgrades = data.purchasedUpgrades or {}
end

return Prestige
