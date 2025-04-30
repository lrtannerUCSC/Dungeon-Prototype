-- item.lua
-- Item entity derived from base Entity

local Entity = require("entity")

local Item = {}
Item.__index = Item
setmetatable(Item, {__index = Entity})

function Item:new(x, y, name, itemType)
    local instance = Entity:new(x, y)
    setmetatable(instance, self)
    
    -- Item-specific properties
    instance.type = "item"
    instance.name = name or "Unknown Item"
    instance.itemType = itemType or "misc"  -- healing, weapon, misc
    instance.color = {1, 1, 0}  -- Yellow
    instance.width = 25
    instance.height = 25
    instance.collected = false
    instance.bobHeight = 0
    instance.bobDirection = 1
    
    return instance
end

function Item:update(dt)
    -- Make items bob up and down
    self.bobHeight = self.bobHeight + dt * self.bobDirection * 30
    if math.abs(self.bobHeight) > 5 then
        self.bobDirection = -self.bobDirection
    end
end

function Item:draw()
    -- Draw at bob height
    local originalY = self.y
    self.y = self.y + self.bobHeight
    
    -- Draw the base entity
    Entity.draw(self)
    
    -- Draw item name
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.name, self.x - self.width/2, self.y - self.height/2 - 20)
    
    -- Reset y position
    self.y = originalY
end

function Item:onCollision(other)
    -- Item-specific collision behavior
    if other.type == "player" and not self.collected then
        -- Items disappear when collected by player
        if self.itemType == "healing" then
            other.health = math.min(other.health + 10, other.maxHealth)
        end
        self.collected = true
        self.active = false  -- This will cause it to be removed in the next update
    end
end

return Item
