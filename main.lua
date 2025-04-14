if arg[2] == "debug" then
    require("lldebugger").start()
end

function love.draw()
    love.graphics.print("Hello, World!", 100, 100)
end