-- enemy.lua
-- Enemy entity derived from base Entity

local Entity = require("entity")

local Enemy = {}
Enemy.__index = Enemy
setmetatable(Enemy, {__index = Entity})

function Enemy:new(x, y, name, health)
    local instance = Entity:new(x, y)
    setmetatable(instance, self)
    
    -- Enemy-specific properties
    instance.type = "enemy"
    instance.name = name or "Monster"
    instance.health = health or 30
    instance.maxHealth = instance.health
    instance.color = {1, 0.3, 0.3}  -- Red
    instance.width = 38
    instance.height = 38
    instance.targetX = x
    instance.targetY = y
    instance.lastTargetChange = 0
    
    return instance
end

function Enemy:update(dt)
    -- Simple enemy AI: move toward player occasionally
    self.lastTargetChange = self.lastTargetChange + dt
    
    if self.lastTargetChange > 1.5 then
        -- Find player
        for _, entity in ipairs(love.entities or {}) do
            if entity.type == "player" then
                -- Set new target position toward player
                local angle = math.atan2(entity.y - self.y, entity.x - self.x)
                local distance = math.random(50, 150)
                self.targetX = self.x + math.cos(angle) * distance
                self.targetY = self.y + math.sin(angle) * distance
                self.lastTargetChange = 0
                break
            end
        end
    end
    
    -- Move toward target
    local dx = self.targetX - self.x
    local dy = self.targetY - self.y
    local dist = math.sqrt(dx*dx + dy*dy)
    
    if dist > 5 then
        local moveX = dx / dist * self.speed * dt
        local moveY = dy / dist * self.speed * dt
        self:move(moveX, moveY)
    end
end

function Enemy:draw()
    -- Draw the base entity
    Entity.draw(self)
    
    -- Draw enemy name
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.name, self.x - self.width/2, self.y - self.height/2 - 20)
    
    -- Draw health bar
    local barWidth = self.width
    local barHeight = 5
    
    -- Background (red)
    love.graphics.setColor(0.5, 0, 0)
    love.graphics.rectangle("fill", self.x - barWidth/2, self.y + self.height/2 + 5, 
                            barWidth, barHeight)
    
    -- Foreground (green) - make sure health isn't negative
    local healthPercent = math.max(0, math.min(1, self.health / self.maxHealth))
    love.graphics.setColor(0, 0.8, 0)
    love.graphics.rectangle("fill", self.x - barWidth/2, self.y + self.height/2 + 5, 
                            barWidth * healthPercent, barHeight)
end

function Enemy:onCollision(other)
    -- Enemy-specific collision behavior
    if other.type == "player" then
        -- Enemies take damage when colliding with players
        self.health = self.health - 5
        if self.health <= 0 then
            self.active = false
        end
    end
end

return Enemy
