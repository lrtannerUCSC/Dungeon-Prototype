
local Entity = require("entity")
local Item = {}
Item.__index = Item
setmetatable(Item, {__index = Entity}) -- Proper inheritance

function Item:new(re, im, name, itemType)
    local instance = Entity:new(0, 0) -- Start with base entity
    setmetatable(instance, self)
    
    -- Complex space properties
    instance.complex_x = re
    instance.complex_y = im
    instance.complex_size = 0.05
    
    -- Visual properties
    instance.name = name or "Item"
    instance.itemType = itemType or "misc"
    instance.width = 20
    instance.height = 20
    
    -- Color based on type
    if itemType == "healing" then
        instance.base_color = {0, 0.8, 0.2}  -- Green for health
        instance.current_color = {0, 0.8, 0.2}
    elseif itemType == "power" then
        instance.base_color = {0.9, 0.6, 0.1}  -- Orange for power
        instance.current_color = {0.9, 0.6, 0.1}
    else
        instance.base_color = {0.4, 0.4, 1.0}  -- Blue for misc
        instance.current_color = {0.4, 0.4, 1.0}
    end
    
    -- Movement properties
    instance.moveSpeed = math.random(10, 30)  -- Random slow movement
    instance.moveAngle = math.random() * math.pi * 2  -- Random direction
    instance.moveTick = 0
    instance.moveInterval = math.random(3, 6)  -- Change direction every 3-6 seconds
    
    -- Animation properties
    instance.bobHeight = 0
    instance.bobDirection = 1
    instance.pulseAmount = 0
    instance.collected = false
    instance.active = true
    
    return instance
end

function Item:update(dt)
    -- Animation: bobbing effect
    self.bobHeight = self.bobHeight + dt * self.bobDirection * 30
    if math.abs(self.bobHeight) > 5 then
        self.bobDirection = -self.bobDirection
    end
    
    -- Pulsing color effect
    self.pulseAmount = (math.sin(love.timer.getTime() * 2) + 1) * 0.2
    self.current_color = {
        self.base_color[1] * (1 + self.pulseAmount * 0.2),
        self.base_color[2] * (1 + self.pulseAmount * 0.2),
        self.base_color[3] * (1 + self.pulseAmount * 0.2)
    }
    
    -- Random slow movement
    self.moveTick = self.moveTick + dt
    if self.moveTick > self.moveInterval then
        -- Change direction randomly
        self.moveAngle = math.random() * math.pi * 2
        self.moveTick = 0
        self.moveInterval = math.random(3, 6)
    end
    
    -- Apply movement
    local moveX = math.cos(self.moveAngle) * self.moveSpeed * dt
    local moveY = math.sin(self.moveAngle) * self.moveSpeed * dt
    self:move(moveX, moveY)
    
    -- Update complex coordinates if needed
    if love.entities then
        for _, entity in ipairs(love.entities) do
            if entity.type == "player" then
                -- Get the current viewport bounds
                local xmin, xmax = entity.viewport.xmin, entity.viewport.xmax
                local ymin, ymax = entity.viewport.ymin, entity.viewport.ymax
                local width, height = love.graphics.getDimensions()
                
                -- Convert screen coordinates to complex coordinates
                self.complex_x = xmin + (xmax - xmin) * self.x / width
                self.complex_y = ymin + (ymax - ymin) * self.y / height
                break
            end
        end
    end
end

function Item:draw()
    -- Use computed screen coordinates with bob effect
    local draw_y = self.y + self.bobHeight
    
    -- Draw glowing effect
    local glowSize = 5 + self.pulseAmount * 2
    love.graphics.setColor(self.current_color[1], self.current_color[2], self.current_color[3], 0.3)
    love.graphics.rectangle('fill',
                          self.x - self.width/2 - glowSize/2,
                          draw_y - self.height/2 - glowSize/2,
                          self.width + glowSize, self.height + glowSize)
    
    -- Draw main item
    love.graphics.setColor(self.current_color)
    love.graphics.rectangle('fill',
                          self.x - self.width/2,
                          draw_y - self.height/2,
                          self.width, self.height)
    
    -- Draw item name
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.name,
                      self.x - self.width/2,
                      draw_y - self.height/2 - 15)
end

function Item:onCollision(other)
    if other.type == "player" and not self.collected then
        -- Apply effect based on type
        if self.itemType == "healing" then
            other.health = math.min(other.health + 10, other.maxHealth)
            -- Visual feedback
            other.healEffect = 1.0  -- Start heal visual effect
        elseif self.itemType == "power" then
            other.power = other.power + 5
        end
        
        self.collected = true
        self.active = false
    end
end

return Item