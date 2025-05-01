-- entity_manager.lua
local EntityManager = {}
EntityManager.__index = EntityManager

function EntityManager:new()
    return setmetatable({
        entities = {},       -- All active entities
        registry = {},       -- Entities that need position updates
        next_id = 1          -- For unique IDs
    }, self)
end

function EntityManager:register(entity)
    if not entity.id then
        entity.id = "e"..self.next_id
        self.next_id = self.next_id + 1
    end
    
    table.insert(self.entities, entity)
    
    -- Only add to registry if it has complex coordinates
    if entity.complex_x then
        table.insert(self.registry, entity)
    end
    return entity
end

function EntityManager:updateAll(dt)
    -- Update in reverse order for safe removal
    for i = #self.entities, 1, -1 do
        local e = self.entities[i]
        if e.update then e:update(dt) end
        if e.active == false then
            table.remove(self.entities, i)
        end
    end
end

function EntityManager:drawAll()
    for _, e in ipairs(self.entities) do
        if e.draw then e:draw() end
    end
end

function EntityManager:updatePositions(xmin, xmax, ymin, ymax, width, height)
    for _, e in ipairs(self.registry) do
        -- Convert complex to screen coordinates
        e.x = width * (e.complex_x - xmin) / (xmax - xmin)
        e.y = height * (e.complex_y - ymin) / (ymax - ymin)
        
        -- Calculate size scaling
        local viewport_width = xmax - xmin
        e.display_size = (e.complex_size / viewport_width) * width
    end
end

return EntityManager