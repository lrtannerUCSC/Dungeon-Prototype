-- player.lua
-- Player entity derived from base Entity

local Entity = require("entity")

local Player = {}
Player.__index = Player
setmetatable(Player, {__index = Entity})

function Player:new(x, y)
    local instance = Entity:new(x, y)
    setmetatable(instance, self)
    
    -- Player-specific properties
    instance.type = "player"
    instance.color = {0, 1, 0}  -- Green
    instance.width = 40
    instance.height = 40
    instance.speed = 200
    instance.health = 100
    instance.maxHealth = 100
    
    return instance
end

function Player:update(dt)
    -- Handle player movement with WASD
    if love.keyboard.isDown("w") then
        self:move(0, -self.speed * dt)
    end
    if love.keyboard.isDown("s") then
        self:move(0, self.speed * dt)
    end
    if love.keyboard.isDown("a") then
        self:move(-self.speed * dt, 0)
    end
    if love.keyboard.isDown("d") then
        self:move(self.speed * dt, 0)
    end
    
    -- Keep player on screen
    self.x = math.max(self.width/2, math.min(self.x, love.graphics.getWidth() - self.width/2))
    self.y = math.max(self.height/2, math.min(self.y, love.graphics.getHeight() - self.height/2))
end

function Player:onCollision(other)
    -- Player-specific collision behavior
    if other.type == "item" then
        if other.itemType == "healing" then
            self.health = math.min(self.health + 10, self.maxHealth)
        end
    elseif other.type == "enemy" then
        self.health = math.max(self.health - 1, 0)
    end
end

return Player
