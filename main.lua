
function love.load()
    -- Initial view (full Mandelbrot)
    width, height = 800, 600
    love.window.setMode(width, height)

    max_iter = 100
    
    -- Zoom parameters
    zoom_factor = 0.1  -- How much to zoom per click
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
                local r, g, b = getColor(iter, max_iter)
                love.graphics.setColor(r, g, b)
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
    if button == 1 then  -- Left click: Zoom in
        center_re = xmin + (xmax - xmin) * x / width
        center_im = ymin + (ymax - ymin) * y / height
        xspan = xspan * 0.5
        yspan = yspan * 0.5
        max_iter = max_iter * 1.1  -- Increase iterations to reveal deeper colors
    elseif button == 2 then  -- Right click: Zoom out
        xspan = xspan / 0.5
        yspan = yspan / 0.5
        max_iter = math.max(100, max_iter / 1.5)  -- Prevent max_iter < 100
    end
    update_bounds()
    redraw_fractal()
end

--https://stackoverflow.com/questions/68317097/how-to-properly-convert-hsl-colors-to-rgb-colors-in-lua
function hslToRgb(h, s, l)
    h = h / 360
    s = s / 100
    l = l / 100

    local r, g, b;

    if s == 0 then
        r, g, b = l, l, l; -- achromatic
    else
        local function hue2rgb(p, q, t)
            if t < 0 then t = t + 1 end
            if t > 1 then t = t - 1 end
            if t < 1 / 6 then return p + (q - p) * 6 * t end
            if t < 1 / 2 then return q end
            if t < 2 / 3 then return p + (q - p) * (2 / 3 - t) * 6 end
            return p;
        end

        local q = l < 0.5 and l * (1 + s) or l + s - l * s;
        local p = 2 * l - q;
        r = hue2rgb(p, q, h + 1 / 3);
        g = hue2rgb(p, q, h);
        b = hue2rgb(p, q, h - 1 / 3);
    end

    if not a then a = 1 end
    return r * 255, g * 255, b * 255, a * 255
end

function getColor(iter, max_iter)
    -- Normalize iteration count to [0, 1]
    local normalized = iter / max_iter

    -- Map to HSL (hue ranges from 0° to 360°)
    local hue = normalized * 360  -- 0°=red, 120°=green, 240°=blue, etc.
    local saturation = 100        -- Full saturation
    local lightness = 50         -- Medium lightness

    -- Convert HSL to RGB
    local r, g, b = hslToRgb(hue, saturation, lightness)
    return r / 255, g / 255, b / 255  -- Scale to [0, 1] for LÖVE
end