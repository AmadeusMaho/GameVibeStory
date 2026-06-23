local Game = {}
Game.__index = Game

local Staff = require("src.systems.staff")
local Development = require("src.systems.development")
local Office = require("src.systems.office")
local Prestige = require("src.systems.prestige")
local Stats = require("src.systems.stats")

function Game.new()
    local self = setmetatable({}, Game)
    
    self.stats = Stats.new()
    self.staff = Staff.new(self)
    self.office = Office.new(self)
    self.development = Development.new(self)
    self.prestige = Prestige.new(self)
    
    self.currentScreen = "main"
    self.notifications = {}
    self.floatingNumbers = {}
    
    self:load()
    
    return self
end

function Game:update(dt)
    self.stats:update(dt)
    self.staff:update(dt)
    self.office:update(dt)
    self.development:update(dt)
    
    self:updateFloatingNumbers(dt)
    self:updateNotifications(dt)
end

function Game:addMoney(amount)
    self.stats:addMoney(amount)
    self:addFloatingNumber("+" .. self:formatNumber(amount), 1, 0.8, 0.2)
end

function Game:addResearch(amount)
    self.stats:addResearch(amount)
end

function Game:addFame(amount)
    self.stats:addFame(amount)
end

function Game:addReputation(amount)
    self.stats:addReputation(amount)
end

function Game:spendMoney(amount)
    if self.stats.money >= amount then
        self.stats.money = self.stats.money - amount
        return true
    end
    return false
end

function Game:addFloatingNumber(text, r, g, b)
    table.insert(self.floatingNumbers, {
        text = text,
        x = 480 + math.random(-50, 50),
        y = 300,
        r = r or 1,
        g = g or 1,
        b = b or 1,
        life = 1.0,
        vy = -50
    })
end

function Game:addNotification(text, type)
    table.insert(self.notifications, {
        text = text,
        type = type or "info",
        life = 3.0
    })
end

function Game:updateFloatingNumbers(dt)
    for i = #self.floatingNumbers, 1, -1 do
        local num = self.floatingNumbers[i]
        num.y = num.y + num.vy * dt
        num.life = num.life - dt
        if num.life <= 0 then
            table.remove(self.floatingNumbers, i)
        end
    end
end

function Game:updateNotifications(dt)
    for i = #self.notifications, 1, -1 do
        self.notifications[i].life = self.notifications[i].life - dt
        if self.notifications[i].life <= 0 then
            table.remove(self.notifications, i)
        end
    end
end

function Game:formatNumber(num)
    if num >= 1e12 then
        return string.format("%.1fT", num / 1e12)
    elseif num >= 1e9 then
        return string.format("%.1fB", num / 1e9)
    elseif num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(math.floor(num))
    end
end

function Game:save()
    local data = {
        stats = self.stats:save(),
        staff = self.staff:save(),
        office = self.office:save(),
        development = self.development:save(),
        prestige = self.prestige:save()
    }
    
    local json = require("dkjson") or nil
    if json then
        local file = io.open("save.json", "w")
        if file then
            file:write(json.encode(data))
            file:close()
        end
    end
end

function Game:load()
    local file = io.open("save.json", "r")
    if file then
        local content = file:read("*a")
        file:close()
        
        local json = require("dkjson") or nil
        if json then
            local data = json.decode(content)
            if data then
                self.stats:load(data.stats or {})
                self.staff:load(data.staff or {})
                self.office:load(data.office or {})
                self.development:load(data.development or {})
                self.prestige:load(data.prestige or {})
            end
        end
    end
end

return Game
