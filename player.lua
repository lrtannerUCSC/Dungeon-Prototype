-- player.lua
-- Player entity derived from base Entity

local Entity = require("entity")

local Player = {}
Player.__index = Player
setmetatable(Player, {__index = Entity})

function Player:new(x, y)
    local instance = Entity:new(x, y)
    setmetatable(instance, self)
    
    instance.type = "player"
    instance.color = {1, 1, 1}
    instance.size = 20
    instance.speed = 0.01
    instance.health = 100
    instance.maxHealth = 100
    
    instance.complex_x = center_re
    instance.complex_y = center_im
    instance.complex_size = 0.05
    
    return instance
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
