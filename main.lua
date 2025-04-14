
function love.load()
    -- Initial view (full Mandelbrot)
    width, height = 800, 600
    love.window.setMode(width, height)

    max_iter = 100
    
    -- Zoom parameters
    zoom_factor = 0.25  -- How much to zoom per click (e.g., 0.5 = 2x zoom)
    center_re = -0.5   -- Target center (real part)
    center_im = 0      -- Target center (imaginary part)
    xspan, yspan = 3.0, 2.5  -- Initial axis spans (xmax - xmin)

    update_bounds()  -- Sets xmin/xmax/ymin/ymax based on center and span
    redraw_fractal() -- Regenerates the fractal with new bounds
end

function love.draw()
    love.graphics.draw(canvas)
    love.graphics.setColor(1, 1, 1)
end

function redraw_fractal()
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

function update_bounds()
    xmin = center_re - xspan / 2
    xmax = center_re + xspan / 2
    ymin = center_im - yspan / 2
    ymax = center_im + yspan / 2
end

function love.mousepressed(x, y, button)
    if button == 1 then  -- Left click to Zoom in
        -- Update center to mouse position
        center_re = xmin + (xmax - xmin) * x / width
        center_im = ymin + (ymax - ymin) * y / height
        
        -- Reduce span to zoom in
        xspan = xspan * zoom_factor
        yspan = yspan * zoom_factor
        
        update_bounds()
        redraw_fractal()
    elseif button == 2 then  -- Right click to Zoom out
        xspan = xspan / zoom_factor
        yspan = yspan / zoom_factor
        update_bounds()
        redraw_fractal()
    end
end
