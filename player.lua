
local Entity = require("entity")
local Player = {}
Player.__index = Player
setmetatable(Player, {__index = Entity})

function Player:new(x, y)
    local instance = Entity:new(x, y)
    setmetatable(instance, self)
    
    -- Player-specific properties
    instance.type = "player"
    instance.name = "Explorer"
    instance.health = 100
    instance.maxHealth = 100
    instance.power = 10
    instance.color = {0.2, 0.6, 1.0} -- Blue
    instance.width = 40
    instance.height = 40
    instance.size = 20 -- Used for collision
    instance.speed = 0.01
    
    -- Complex coordinates for fractal space
    instance.complex_x = 0
    instance.complex_y = 0
    instance.complex_size = 0.05 -- Add default complex_size
    
    -- Store current zoom for gameplay scaling
    instance.current_zoom = 1.0
    
    -- Visual feedback effects
    instance.damageEffect = 0
    instance.healEffect = 0
    
    -- Store viewport info
    instance.viewport = {
        xmin = -2.5,
        xmax = 1.0,
        ymin = -1.5,
        ymax = 1.5
    }
    
    return instance
end

function Player:update(dt)
    -- Update visual effects
    if self.damageEffect > 0 then
        self.damageEffect = self.damageEffect - dt * 2
    end
    if self.healEffect > 0 then
        self.healEffect = self.healEffect - dt * 1.5
    end
    
    -- Update player logic
    -- Add any other player-specific update logic here
end

function Player:draw()
    -- Draw the player with any active effects
    local r, g, b = self.color[1], self.color[2], self.color[3]
    
    -- Apply damage effect (red tint)
    if self.damageEffect > 0 then
        r = r + self.damageEffect * 0.8
        g = g - self.damageEffect * 0.4
        b = b - self.damageEffect * 0.4
    end
    
    -- Apply heal effect (green tint)
    if self.healEffect > 0 then
        r = r - self.healEffect * 0.3
        g = g + self.healEffect * 0.3
        b = b - self.healEffect * 0.3
    end
    
    -- Clamp colors
    r = math.max(0, math.min(1, r))
    g = math.max(0, math.min(1, g))
    b = math.max(0, math.min(1, b))
    
    -- Draw player
    love.graphics.setColor(r, g, b)
    love.graphics.rectangle("fill", self.x - self.width/2, self.y - self.height/2, self.width, self.height)
    
    -- Draw player name
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.name, self.x - self.width/2, self.y - self.height/2 - 20)
    
    -- Draw health bar
    local barWidth = self.width
    local barHeight = 5
    
    -- Background (red)
    love.graphics.setColor(0.5, 0, 0)
    love.graphics.rectangle("fill", self.x - barWidth/2, self.y + self.height/2 + 5, barWidth, barHeight)
    
    -- Foreground (green)
    local healthPercent = math.max(0, math.min(1, self.health / self.maxHealth))
    love.graphics.setColor(0, 0.8, 0)
    love.graphics.rectangle("fill", self.x - barWidth/2, self.y + self.height/2 + 5, barWidth * healthPercent, barHeight)
end

function Player:onCollision(other)
    -- Player-specific collision behavior
    if other.type == "enemy" then
        -- Player takes damage from enemies
        self.health = self.health - 5
        self.damageEffect = 1.0 -- Start damage visual effect
        
        -- Game over check
        if self.health <= 0 then
            -- Game over logic
            self.health = 0
        end
    elseif other.type == "item" then
        -- Handle item collection
        self.healEffect = 1.0
    end
end

function Player:updateViewport(xmin, xmax, ymin, ymax)
    self.viewport = {
        xmin = xmin,
        xmax = xmax,
        ymin = ymin,
        ymax = ymax
    }
    
    -- Update player's complex coordinates
    local width, height = love.graphics.getDimensions()
    self.complex_x = xmin + (xmax - xmin) * self.x / width
    self.complex_y = ymin + (ymax - ymin) * self.y / height
end

return Player