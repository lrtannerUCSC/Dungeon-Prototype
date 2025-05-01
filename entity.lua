
local Entity = {}
Entity.__index = Entity

-- Constructor
function Entity:new(x, y)
    local instance = {}
    setmetatable(instance, self)
    
    -- Common properties for all entities
    instance.x = x or 0
    instance.y = y or 0
    instance.width = 32
    instance.height = 32
    instance.speed = 100
    instance.color = {1, 1, 1}
    instance.type = "entity"
    instance.active = true
    instance.id = tostring(math.random(1000000))
    
    return instance
end

-- Common methods for all entities
function Entity:update(dt)
    -- Base update logic
end

function Entity:draw()
    -- Set color and draw rectangle
    love.graphics.setColor(self.color)
    love.graphics.rectangle("fill", self.x - self.width/2, self.y - self.height/2, 
                            self.width, self.height)
    
    -- Draw entity type
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(self.type, self.x - self.width/2 + 5, self.y - 5)
    
    -- Reset color
    love.graphics.setColor(1, 1, 1)
end

function Entity:move(dx, dy)
    self.x = self.x + dx
    self.y = self.y + dy
end

function Entity:checkScreenCollision(other)
    -- Traditional screen-space collision
    return math.abs(self.x - other.x) < (self.width/2 + other.width/2) and
           math.abs(self.y - other.y) < (self.height/2 + other.height/2)
end

function Entity:checkComplexCollision(other)
    -- Only works if both entities have complex coordinates
    if not (self.complex_x and other.complex_x) then return false end
    
    local dx = self.complex_x - other.complex_x
    local dy = self.complex_y - other.complex_y
    local combined_radius = (self.complex_size + other.complex_size)/2
    return (dx*dx + dy*dy) < (combined_radius*combined_radius)
end

-- Default to screen collision
function Entity:checkCollision(other)
    if self.complex_x and other.complex_x then
        return self:checkComplexCollision(other)
    else
        return self:checkScreenCollision(other)
    end
end


function Entity:onCollision(other)
    -- Base collision behavior
end

function Entity:getInfo()
    return {
        type = self.type,
        position = {x = self.x, y = self.y},
        size = {width = self.width, height = self.height},
        id = self.id
    }
end

return Entity
