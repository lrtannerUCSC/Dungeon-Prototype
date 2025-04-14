if arg[2] == "debug" then
    require("lldebugger").start()
end

function love.load()
    local width, height = 800, 600
    love.window.setMode(width, height)
    love.window.setTitle("Mandelbrot")

    -- Mandelbrot parameters
    --X axis is real numbers
    --Y axis is imaginary numbers
    local xmin, xmax = -2.5, 1.5
    local ymin, ymax = -1.5, 1.5
    local max_iter = 100

    canvas = love.graphics.newCanvas(width, height)
    love.graphics.setCanvas(canvas)

    for px = 0, width - 1 do
        for py = 0, height - 1 do
            --Converting pixel coordinates to complex number grid
                --Each pixel is calculated individually
                --To see if it is in the set or not
            local c_re = xmin + (xmax - xmin) * px / width
            local c_im = ymin + (ymax - ymin) * py / height

            local x, y = 0, 0 --Z_0 = 0
            local iter = 0 --Start at 0 iterations
            while x*x + y*y <= 4 and iter < max_iter do --x*x + y*y = Z_n^2
            --if x*x + y*y <= 4 then Z_n^2 > 2, meaning it diverges
            --Z_n^2 = (x+iy)^2 = x^2 - y^2 + 2ixy
            --Separate real and imageinary parts
                --REAL: x^2-y^2+c_re
                --IMAG: 2xy+c_im
                local x_new = x*x - y*y + c_re
                y = 2*x*y + c_im
                x = x_new
                iter = iter + 1
            end

            -- Color logic (ensure escaping points are visible)
            if iter < max_iter then
                --Measures speed that it takes to escape
                local brightness = iter / max_iter --The fewer iterations, the brighter
                love.graphics.setColor(brightness, brightness * 0.5, 0)
                love.graphics.points(px, py)
            -- else: leave black (part of the set)
            end
        end
    end

    love.graphics.setCanvas()
end

function love.draw()
    love.graphics.draw(canvas)
    love.graphics.setColor(1, 1, 1)
end

-- local love_errorhandler = love.errorhandler

-- function love.errorhandler(msg)
--     if lldebugger then
--         error(msg, 2)
--     else
--         return love_errorhandler(msg)
--     end
-- end