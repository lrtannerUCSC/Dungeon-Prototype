local Entity = require("entity")

local Wall = {}
Wall.__index = Wall
setmetatable(Wall, {__index = Entity})

function Wall:new(x, y, width, height, color)
    local instance = Entity:new(x, y)  -- Now treating x,y as top-left corner
    setmetatable(instance, self)

    instance.type = "wall"
    instance.color = color or {1, 0, 1}
    instance.width = width or 40
    instance.height = height or 40

    return instance
end

function Wall:onCollision(other)
    if other.type == "player" or other.type == "enemy" then
        local dx = (other.x - self.x)
        local dy = (other.y - self.y)
        local px = (other.width + self.width)/2 - math.abs(dx)
        local py = (other.height + self.height)/2 - math.abs(dy)

        if px < py then
            if dx > 0 then
                other.x = other.x + px
            else
                other.x = other.x - px
            end
        else
            if dy > 0 then
                other.y = other.y + py
            else
                other.y = other.y - py
            end
        end
    end
end



return Wall