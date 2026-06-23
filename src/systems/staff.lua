local Staff = {}
Staff.__index = Staff

local STAFF_NAMES = {
    "Alex", "Jordan", "Casey", "Morgan", "Riley",
    "Quinn", "Avery", "Cameron", "Dakota", "Emery",
    "Finley", "Harper", "Kendall", "Logan", "Parker",
    "Reese", "Sage", "Taylor", "Val", "Wren"
}

local STAFF_CAREERS = {
    {name = "Programmer", base = {programming = 10, design = 2, art = 0, sound = 0, marketing = 0}},
    {name = "Designer", base = {programming = 2, design = 10, art = 2, sound = 0, marketing = 2}},
    {name = "Artist", base = {programming = 0, design = 2, art = 10, sound = 0, marketing = 0}},
    {name = "Sound Designer", base = {programming = 0, design = 0, art = 0, sound = 10, marketing = 0}},
    {name = "Marketer", base = {programming = 0, design = 0, art = 0, sound = 0, marketing = 10}}
}

local CAREER_LEVELS = {
    {name = "Junior", multiplier = 1.0},
    {name = "Senior", multiplier = 1.5},
    {name = "Lead", multiplier = 2.0},
    {name = "Director", multiplier = 3.0},
    {name = "Legend", multiplier = 5.0}
}

function Staff.new(game)
    local self = setmetatable({}, Staff)
    
    self.game = game
    self.members = {}
    self.maxMembers = 3
    self.hireCost = 100
    self.hireCostMultiplier = 1.15
    
    return self
end

function Staff:update(dt)
    for _, member in ipairs(self.members) do
        member.experience = member.experience + dt * 0.1
        local expNeeded = self:getExperienceNeeded(member.level)
        if member.experience >= expNeeded then
            member.level = member.level + 1
            member.experience = 0
            self.game:addNotification(member.name .. " subió a nivel " .. member.level, "success")
        end
    end
end

function Staff:hire(forcedCareer)
    if #self.members >= self.maxMembers then
        self.game:addNotification("Estudio lleno! Mejora la oficina.", "warning")
        return false
    end
    
    if not self.game:spendMoney(self.hireCost) then
        self.game:addNotification("Dinero insuficiente!", "error")
        return false
    end
    
    local name = STAFF_NAMES[math.random(#STAFF_NAMES)]
    local career = forcedCareer or STAFF_CAREERS[math.random(#STAFF_CAREERS)]
    local level = 1
    
    local member = {
        name = name,
        career = career.name,
        level = level,
        experience = 0,
        stats = {}
    }
    
    for stat, base in pairs(career.base) do
        member.stats[stat] = base + math.random(0, 5)
    end
    
    table.insert(self.members, member)
    self.hireCost = math.floor(self.hireCost * self.hireCostMultiplier)
    
    self.game:addNotification("Contratado: " .. name .. " (" .. career.name .. ")", "success")
    self.game.stats:addReputation(1)
    
    return true
end

function Staff:fire(index)
    if index > 0 and index <= #self.members then
        local member = self.members[index]
        table.remove(self.members, index)
        self.game:addNotification(member.name .. " fue despedido.", "info")
        return true
    end
    return false
end

function Staff:train(index)
    if index > 0 and index <= #self.members then
        local member = self.members[index]
        local cost = member.level * 50
        
        if self.game:spendMoney(cost) then
            member.experience = member.experience + self:getExperienceNeeded(member.level) * 0.5
            self.game:addNotification(member.name .. " recibió entrenamiento.", "info")
            return true
        end
    end
    return false
end

function Staff:getTotalStats()
    local totals = {programming = 0, design = 0, art = 0, sound = 0, marketing = 0}
    
    for _, member in ipairs(self.members) do
        local mult = CAREER_LEVELS[math.min(member.level, #CAREER_LEVELS)].multiplier
        for stat, value in pairs(member.stats) do
            totals[stat] = totals[stat] + value * mult
        end
    end
    
    return totals
end

function Staff:getAverageStats()
    local totals = self:getTotalStats()
    local count = math.max(1, #self.members)
    
    local averages = {}
    for stat, value in pairs(totals) do
        averages[stat] = value / count
    end
    
    return averages
end

function Staff:getExperienceNeeded(level)
    return math.floor(100 * math.pow(1.5, level - 1))
end

function Staff:getCareerLevelName(level)
    return CAREER_LEVELS[math.min(level, #CAREER_LEVELS)].name
end

function Staff:save()
    local data = {
        members = {},
        maxMembers = self.maxMembers,
        hireCost = self.hireCost
    }
    
    for _, member in ipairs(self.members) do
        table.insert(data.members, {
            name = member.name,
            career = member.career,
            level = member.level,
            experience = member.experience,
            stats = member.stats
        })
    end
    
    return data
end

function Staff:load(data)
    self.maxMembers = data.maxMembers or 3
    self.hireCost = data.hireCost or 100
    self.members = {}
    
    for _, memberData in ipairs(data.members or {}) do
        table.insert(self.members, {
            name = memberData.name,
            career = memberData.career,
            level = memberData.level or 1,
            experience = memberData.experience or 0,
            stats = memberData.stats or {}
        })
    end
end

return Staff
