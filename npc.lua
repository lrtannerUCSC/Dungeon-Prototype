-- npc.lua
-- NPC entity derived from base Entity

local Entity = require("entity")

local NPC = {}
NPC.__index = NPC
setmetatable(NPC, {__index = Entity})

function NPC:new(x, y, name, message)
    local instance = Entity:new(x, y)
    setmetatable(instance, self)
    
    -- NPC-specific properties
    instance.type = "npc"
    instance.name = name or "Unknown"
    instance.message = message or "Hello!"
    instance.color = {0, 0.7, 1}  -- Light blue
    instance.width = 35
    instance.height = 35
    instance.showMessage = false
    instance.messageTimer = 0
    
    return instance
end

function NPC:update(dt)
    -- Simple NPC AI: move randomly occasionally
    if math.random() < 0.01 then
        local dx = math.random(-1, 1) * 10
        local dy = math.random(-1, 1) * 10
        self:move(dx, dy)
    end
    
    -- Message timer
    if self.showMessage then
        self.messageTimer = self.messageTimer - dt
        if self.messageTimer <= 0 then
            self.showMessage = false
        end
    end
end

function NPC:draw()
    -- Draw the base entity
    Entity.draw(self)
    
    -- Draw the NPC name
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.name, self.x - self.width/2, self.y - self.height/2 - 20)
    
    -- Draw the message if showing
    if self.showMessage then
        love.graphics.setColor(1, 1, 1, 0.8)
        love.graphics.rectangle("fill", self.x - 100, self.y - 70, 200, 30)
        love.graphics.setColor(0, 0, 0)
        love.graphics.print(self.message, self.x - 95, self.y - 65)
    end
end

function NPC:onCollision(other)
    -- NPC specific collision: show message when player collides
    if other.type == "player" and not self.showMessage then
        self.showMessage = true
        self.messageTimer = 3  -- Show message for 3 seconds
    end
end

return NPC
