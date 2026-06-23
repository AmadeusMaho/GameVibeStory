local Office = {}
Office.__index = Office

local OFFICE_LEVELS = {
    {name = "Garaje", capacity = 3, cost = 0, speedBonus = 0, qualityBonus = 0},
    {name = "Oficina Pequeña", capacity = 5, cost = 5000, speedBonus = 0.1, qualityBonus = 0},
    {name = "Oficina Mediana", capacity = 8, cost = 25000, speedBonus = 0.2, qualityBonus = 0.1},
    {name = "Oficina Grande", capacity = 12, cost = 100000, speedBonus = 0.3, qualityBonus = 0.2},
    {name = "Torre Corporativa", capacity = 20, cost = 500000, speedBonus = 0.5, qualityBonus = 0.3},
    {name = "Sede Global", capacity = 30, cost = 2000000, speedBonus = 0.7, qualityBonus = 0.5}
}

local EQUIPMENT = {
    {name = "Computadoras Básicas", cost = 500, speedBonus = 0.05, qualityBonus = 0},
    {name = "Computadoras Gaming", cost = 2000, speedBonus = 0.1, qualityBonus = 0.05},
    {name = "Estudio de Grabación", cost = 5000, speedBonus = 0, qualityBonus = 0.15},
    {name = "Consolas de Prueba", cost = 3000, speedBonus = 0, qualityBonus = 0.1},
    {name = "Sala de Descanso", cost = 8000, speedBonus = 0.05, qualityBonus = 0.05},
    {name = "Servidores Potentes", cost = 15000, speedBonus = 0.2, qualityBonus = 0.1}
}

function Office.new(game)
    local self = setmetatable({}, Office)
    
    self.game = game
    self.level = 1
    self.purchasedEquipment = {}
    
    return self
end

function Office:update(dt)
    local levelData = self:getCurrentLevel()
    self.game.staff.maxMembers = levelData.capacity
    self.game.development.developmentSpeed = 1.0 + levelData.speedBonus + self:getTotalSpeedBonus()
    self.game.development.qualityBonus = levelData.qualityBonus + self:getTotalQualityBonus()
end

function Office:getCurrentLevel()
    return OFFICE_LEVELS[self.level]
end

function Office:getNextLevel()
    if self.level < #OFFICE_LEVELS then
        return OFFICE_LEVELS[self.level + 1]
    end
    return nil
end

function Office:upgradeOffice()
    local nextLevel = self:getNextLevel()
    if not nextLevel then
        self.game:addNotification("Nivel máximo alcanzado!", "info")
        return false
    end
    
    if not self.game:spendMoney(nextLevel.cost) then
        self.game:addNotification("Dinero insuficiente! Necesitas $" .. self.game:formatNumber(nextLevel.cost), "error")
        return false
    end
    
    self.level = self.level + 1
    self.game:addNotification("¡Oficina mejorada a " .. nextLevel.name .. "!", "success")
    self.game.stats:addReputation(5)
    return true
end

function Office:buyEquipment(equipIndex)
    local equip = EQUIPMENT[equipIndex]
    if not equip then return false end
    
    if self:hasEquipment(equipIndex) then
        self.game:addNotification("Ya tienes este equipo!", "warning")
        return false
    end
    
    if not self.game:spendMoney(equip.cost) then
        self.game:addNotification("Dinero insuficiente!", "error")
        return false
    end
    
    table.insert(self.purchasedEquipment, equipIndex)
    self.game:addNotification("Equipo comprado: " .. equip.name, "success")
    return true
end

function Office:hasEquipment(equipIndex)
    for _, idx in ipairs(self.purchasedEquipment) do
        if idx == equipIndex then
            return true
        end
    end
    return false
end

function Office:getTotalSpeedBonus()
    local bonus = 0
    for _, idx in ipairs(self.purchasedEquipment) do
        bonus = bonus + EQUIPMENT[idx].speedBonus
    end
    return bonus
end

function Office:getTotalQualityBonus()
    local bonus = 0
    for _, idx in ipairs(self.purchasedEquipment) do
        bonus = bonus + EQUIPMENT[idx].qualityBonus
    end
    return bonus
end

function Office:getAllEquipment()
    return EQUIPMENT
end

function Office:getAllLevels()
    return OFFICE_LEVELS
end

function Office:save()
    return {
        level = self.level,
        purchasedEquipment = self.purchasedEquipment
    }
end

function Office:load(data)
    self.level = data.level or 1
    self.purchasedEquipment = data.purchasedEquipment or {}
end

return Office
