-- entityfactory.lua

local EntityFactory = {}

function EntityFactory:createPlayer(x, y)
    return Player:new(x, y)
end

function EntityFactory:createRandomEnemy(x, y)
    local enemyTypes = {"Slime", "Goblin", "Skeleton", "Bat"}
    local enemyType = enemyTypes[math.random(1, #enemyTypes)]
    local health = math.random(20, 50)
    return Enemy:new(x, y, enemyType, health)
end

return EntityFactory