
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
    instance.color = {1, 0.3, 0.3} -- Red
    instance.width = 38
    instance.height = 38
    
    -- Complex coordinates for fractal space
    instance.complex_x = x
    instance.complex_y = y
    instance.complex_size = 0.05  -- Size in fractal space
    
    -- Movement properties
    instance.targetX = x
    instance.targetY = y
    instance.lastTargetChange = 0
    instance.changeInterval = math.random(1.2, 2.5)  -- Randomize movement timing
    instance.speed = 80 + math.random(-20, 20)  -- Randomize speed
    
    -- Behavior properties
    instance.aggressiveness = math.random(3, 10) / 10  -- How strongly it follows player (0.3-1.0)
    instance.wanderRadius = math.random(50, 200)  -- How far it wanders
    
    return instance
end

function Enemy:update(dt)
    -- Update enemy AI behavior
    self.lastTargetChange = self.lastTargetChange + dt
    
    -- Change target periodically
    if self.lastTargetChange > self.changeInterval then
        -- Find player
        local player = nil
        for _, entity in ipairs(love.entities or {}) do
            if entity.type == "player" then
                player = entity
                break
            end
        end
        
        if player then
            -- Chance to move toward player (based on aggressiveness)
            if math.random() < self.aggressiveness then
                -- Move toward player with some randomness
                local angle = math.atan2(player.y - self.y, player.x - self.x)
                -- Add some randomness to angle
                angle = angle + math.random(-0.5, 0.5)
                local distance = math.random(30, self.wanderRadius)
                self.targetX = self.x + math.cos(angle) * distance
                self.targetY = self.y + math.sin(angle) * distance
            else
                -- Random wandering
                local angle = math.random() * math.pi * 2
                local distance = math.random(30, self.wanderRadius)
                self.targetX = self.x + math.cos(angle) * distance
                self.targetY = self.y + math.sin(angle) * distance
            end
            
            -- Reset timer with slight randomness
            self.lastTargetChange = math.random(-0.3, 0.3)
            -- Update change interval for variety
            self.changeInterval = math.random(1.2, 2.5)
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
        
        -- Update complex coordinates
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
end

function Enemy:draw()
    -- Draw the enemy with pulsing effect
    local pulseAmount = (math.sin(love.timer.getTime() * 3) + 1) * 0.1
    local r = self.color[1] - pulseAmount
    local g = self.color[2]
    local b = self.color[3] + pulseAmount
    
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", self.x - self.width/2, self.y - self.height/2,
                           self.width, self.height)
    
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
        
        -- Damage the player too
        other.health = other.health - 2
        
        if self.health <= 0 then
            self.active = false
        end
    end
end

return Enemy