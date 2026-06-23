local Stats = {}
Stats.__index = Stats

function Stats.new()
    local self = setmetatable({}, Stats)
    
    self.money = 0
    self.research = 0
    self.fame = 0
    self.reputation = 0
    
    self.totalMoneyEarned = 0
    self.totalGamesMade = 0
    self.totalFans = 0
    
    self.moneyPerSecond = 0
    self.researchPerSecond = 0
    
    self.lastUpdate = 0
    
    return self
end

function Stats:update(dt)
    self.moneyPerSecond = self:calculateMoneyPerSecond()
    self.researchPerSecond = self:calculateResearchPerSecond()
    
    self.money = self.money + self.moneyPerSecond * dt
    self.totalMoneyEarned = self.totalMoneyEarned + self.moneyPerSecond * dt
    self.research = self.research + self.researchPerSecond * dt
end

function Stats:addMoney(amount)
    self.money = self.money + amount
    self.totalMoneyEarned = self.totalMoneyEarned + amount
end

function Stats:addResearch(amount)
    self.research = self.research + amount
end

function Stats:addFame(amount)
    self.fame = self.fame + amount
    self.totalFans = self.totalFans + amount
end

function Stats:addReputation(amount)
    self.reputation = math.max(0, math.min(100, self.reputation + amount))
end

function Stats:calculateMoneyPerSecond()
    return self.moneyPerSecond
end

function Stats:calculateResearchPerSecond()
    return self.researchPerSecond
end

function Stats:save()
    return {
        money = self.money,
        research = self.research,
        fame = self.fame,
        reputation = self.reputation,
        totalMoneyEarned = self.totalMoneyEarned,
        totalGamesMade = self.totalGamesMade,
        totalFans = self.totalFans
    }
end

function Stats:load(data)
    self.money = data.money or 0
    self.research = data.research or 0
    self.fame = data.fame or 0
    self.reputation = data.reputation or 0
    self.totalMoneyEarned = data.totalMoneyEarned or 0
    self.totalGamesMade = data.totalGamesMade or 0
    self.totalFans = data.totalFans or 0
end

return Stats
