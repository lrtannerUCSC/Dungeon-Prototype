local Entity = require("entity")

local Item = {}
Item.__index = Item
setmetatable(Item, {__index = Entity})  -- Proper inheritance

function Item:new(re, im, name, itemType)
    local instance = Entity:new(0, 0)  -- Start with base entity
    setmetatable(instance, self)
    
    -- Complex space properties
    instance.complex_x = re
    instance.complex_y = im
    instance.complex_size = 5
    
    -- Visual properties
    instance.name = name or "Item"
    instance.itemType = itemType or "misc"
    instance.base_color = {0, 1, 0}
    instance.current_color = {0, 1, 0}
    instance.bob_height = 0
    instance.bob_direction = 1
    instance.collected = false
    instance.active = true
    
    -- Initialize animation properties
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
    -- Use computed screen coordinates
    local draw_y = self.y + self.bobHeight
    
    love.graphics.setColor(self.current_color)
    love.graphics.rectangle('fill',
        self.x - self.complex_size/2,
        draw_y - self.complex_size/2,
        self.complex_size, self.complex_size)
    
    -- Text scales with view
    local text_scale = math.max(0.5, self.complex_size/20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.name,
        self.x - self.complex_size/2,
        draw_y - self.complex_size/2 - 15,
        0, text_scale, text_scale)
end

function Item:onCollision(other)
    if other.type == "player" and not self.collected then
        if self.itemType == "healing" then
            other.health = math.min(other.health + 10, other.maxHealth)
        end
        self.collected = true
        self.active = false
    end
end

return Item