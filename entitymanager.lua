-- entitymanager.lua
local EntityManager = {}
EntityManager.__index = EntityManager

function EntityManager:new()
    return setmetatable({
        entities = {}, -- All active entities
        registry = {}, -- Entities that need position updates
        next_id = 1,   -- For unique IDs
        
        -- Spawn control properties
        lastSpawnTime = 0,
        spawnInterval = 5,          -- Time between spawn checks
        enemySpawnChance = 0.3,     -- Base chance to spawn enemy
        itemSpawnChance = 0.4,      -- Base chance to spawn item
        maxEntities = 25,           -- Maximum entities to prevent overload
        zoom_threshold = 10.0       -- Zoom level where entities appear more frequently
    }, self)
end

function EntityManager:register(entity)
    if not entity.id then
        entity.id = "e"..self.next_id
        self.next_id = self.next_id + 1
    end
    
    -- Ensure every entity has complex_size for scaling
    if not entity.complex_size then
        entity.complex_size = 0.05 -- Default size in complex space
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
            
            -- Also remove from registry if needed
            for j = #self.registry, 1, -1 do
                if self.registry[j].id == e.id then
                    table.remove(self.registry, j)
                    break
                end
            end
        end
    end
    
    -- Check for new entity spawning based on time
    self.lastSpawnTime = self.lastSpawnTime + dt
    if self.lastSpawnTime >= self.spawnInterval then
        self:attemptSpawn()
        self.lastSpawnTime = 0
        -- Randomize next spawn interval
        self.spawnInterval = math.random(3, 8)
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
        
        -- Calculate size scaling, ensure complex_size exists
        local viewport_width = xmax - xmin
        local entity_size = e.complex_size or 0.05 -- Default if not set
        e.display_size = (entity_size / viewport_width) * width
        
        -- Scale enemy/item dimensions based on zoom level
        if e.type == "enemy" or e.type == "item" then
            local zoom_scale = 1.0
            
            -- Get player's current zoom level
            local player = self:getPlayer()
            if player then
                zoom_scale = math.max(0.5, math.min(2.0, 1.0 / math.sqrt(player.current_zoom)))
            end
            
            -- Apply zoom scaling to entity dimensions
            if e.width and e.height then
                local base_width = e.width
                local base_height = e.height
                
                -- Scale width and height based on zoom and display_size
                e.width = base_width * zoom_scale
                e.height = base_height * zoom_scale
            end
        end
        
        -- Store viewport info for reference
        e.viewport = {
            xmin = xmin,
            xmax = xmax,
            ymin = ymin,
            ymax = ymax
        }
    end
end

function EntityManager:attemptSpawn()
    -- Don't spawn if we're at maximum entity count
    if #self.entities >= self.maxEntities then return end
    
    -- Find player to get current state
    local player = self:getPlayer()
    if not player then return end
    
    local current_zoom = player.current_zoom or 1.0
    
    -- Adjust spawn chances based on zoom level
    local zoom_factor = math.min(current_zoom / self.zoom_threshold, 5.0)
    local adjusted_enemy_chance = self.enemySpawnChance * (1 + zoom_factor * 0.2)
    local adjusted_item_chance = self.itemSpawnChance * (1 + zoom_factor * 0.1)
    
    -- Attempt to spawn enemies
    if math.random() < adjusted_enemy_chance then
        self:spawnRandomEnemy()
    end
    
    -- Attempt to spawn items
    if math.random() < adjusted_item_chance then
        self:spawnRandomItem()
    end
end

function EntityManager:spawnRandomEnemy()
    local Enemy = require("enemy")
    local valid_pos = self:getRandomValidPosition()
    
    if valid_pos then
        -- Get random enemy type
        local enemyTypes = {"Slime", "Goblin", "Skeleton", "Bat", "Spider"}
        local enemyType = enemyTypes[math.random(1, #enemyTypes)]
        
        -- Random health based on zoom level (harder as you go deeper)
        local player = self:getPlayer()
        local zoom_factor = player and (player.current_zoom or 1.0) or 1.0
        local health = math.floor(20 + math.random(10, 30) * math.min(zoom_factor/10, 2.0))
        
        -- Create and register enemy
        local enemy = Enemy:new(valid_pos.x, valid_pos.y, enemyType, health)
        enemy.complex_x = valid_pos.complex_x
        enemy.complex_y = valid_pos.complex_y
        enemy.complex_size = 0.05
        self:register(enemy)
        return enemy
    end
    return nil
end

function EntityManager:spawnRandomItem()
    local Item = require("item")
    local valid_pos = self:getRandomValidPosition()
    
    if valid_pos then
        -- Randomly choose item type with weights
        local itemType = math.random() < 0.7 and "healing" or "power"
        
        -- Create appropriate item name
        local itemName = itemType == "healing" and "Health" or "Power Boost"
        
        -- Create item with complex coordinates
        local item = Item:new(valid_pos.complex_x, valid_pos.complex_y, itemName, itemType)
        
        -- Set screen coordinates
        item.x = valid_pos.x
        item.y = valid_pos.y
        
        -- Ensure complex_size is set
        item.complex_size = 0.05
        
        self:register(item)
        return item
    end
    return nil
end

function EntityManager:getRandomValidPosition()
    local player = self:getPlayer()
    if not player then return nil end
    
    -- Get screen dimensions
    local width, height = love.graphics.getDimensions()
    
    -- Get current viewport bounds
    local xmin = player.viewport and player.viewport.xmin or -2.5
    local xmax = player.viewport and player.viewport.xmax or 1.0
    local ymin = player.viewport and player.viewport.ymin or -1.5
    local ymax = player.viewport and player.viewport.ymax or 1.0
    
    -- Try to find valid position (not too close to player)
    local attempts = 0
    while attempts < 50 do
        -- Generate random screen position
        local screen_x = math.random(50, width - 50)
        local screen_y = math.random(50, height - 50)
        
        -- Convert to complex coordinates
        local complex_x = xmin + (xmax - xmin) * screen_x / width
        local complex_y = ymin + (ymax - ymin) * screen_y / height
        
        -- Check if point is valid (in the set)
        if self:isValidPosition(complex_x, complex_y) then
            -- Check distance from player (screen space)
            local dx = screen_x - player.x
            local dy = screen_y - player.y
            local dist = math.sqrt(dx*dx + dy*dy)
            
            if dist > 150 then -- Not too close to player
                return {
                    x = screen_x,
                    y = screen_y,
                    complex_x = complex_x,
                    complex_y = complex_y
                }
            end
        end
        attempts = attempts + 1
    end
    
    return nil
end

function EntityManager:isValidPosition(x, y)
    -- Calculate if point is in Mandelbrot set
    local function calculateMandelbrot(c_re, c_im)
        local x, y = 0, 0 -- Z0 = 0
        local iter = 0
        local threshold = 4.0 -- Escape radius squared
        local max_iter = 75  -- Same as base_iter in main
        
        while x*x + y*y <= threshold and iter < max_iter do
            local x_new = x*x - y*y + c_re
            y = 2*x*y + c_im
            x = x_new
            iter = iter + 1
        end
        
        return iter
    end
    
    -- Check if point is NOT in Mandelbrot set (should escape)
    return calculateMandelbrot(x, y) < 75
end

function EntityManager:getPlayer()
    for _, entity in ipairs(self.entities) do
        if entity.type == "player" then
            return entity
        end
    end
    return nil
end

return EntityManager