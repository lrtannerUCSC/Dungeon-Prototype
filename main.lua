function love.load()
    -- Initial view (full Mandelbrot)
    width, height = 800, 600
    love.window.setMode(width, height)
    love.window.setTitle("Mandelbrot's Maze")

    max_iter = 50
    
    -- Zoom parameters
    zoom_factor = 0.1  -- How much to zoom per click
    center_re = -0.5   -- Target center (real part)
    center_im = 0      -- Target center (imaginary part)
    xspan, yspan = 3.0, 2.5  -- Initial axis spans (xmax - xmin)

    update_bounds()  -- Sets xmin/xmax/ymin/ymax based on center and span
    redraw_fractal() -- Regenerates the fractal with new bounds
    
    -- Player as a simple square
    player = {
        x = width / 2,
        y = height / 2,
        size = 20,          -- Size in pixels
        color = {1, 1, 1} -- White
    }
end

function love.draw()
    -- Draw fractal
    love.graphics.draw(canvas)
    
    -- Draw player square
    love.graphics.setColor(player.color)
    love.graphics.rectangle('fill', 
        player.x - player.size/2, 
        player.y - player.size/2, 
        player.size, player.size)
end

function calculateMandelbrot(c_re, c_im, max_iter)
    local x, y = 0, 0  -- Z0 = 0
    local iter = 0
    
    while x*x + y*y <= 4 and iter < max_iter do
        local x_new = x*x - y*y + c_re
        y = 2*x*y + c_im
        x = x_new
        iter = iter + 1
    end
    
    return iter
end

function redraw_fractal()
    canvas = love.graphics.newCanvas(width, height)
    love.graphics.setCanvas(canvas)
    
    for px = 0, width - 1 do
        for py = 0, height - 1 do
            -- Convert pixel to complex coordinates
            local c_re = xmin + (xmax - xmin) * px / width
            local c_im = ymin + (ymax - ymin) * py / height
            
            -- Calculate iterations
            local iter = calculateMandelbrot(c_re, c_im, max_iter)
            
            -- Color and draw
            if iter < max_iter then
                local r, g, b = getColor(iter, max_iter)
                love.graphics.setColor(r, g, b)
                love.graphics.points(px, py)
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
        xspan = xspan * zoom_factor
        yspan = yspan * zoom_factor
        max_iter = max_iter * 1.1  -- Increase iterations to reveal deeper colors
    elseif button == 2 then  -- Right click: Zoom out
        xspan = xspan / zoom_factor
        yspan = yspan / zoom_factor
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
    -- Normalize iteration count
    local normalized = iter / max_iter

    -- Map to HSL (hue ranges from 0° to 360°)
    local hue = normalized * 360 
    local saturation = 100
    local lightness = 50

    -- Convert HSL to RGB
    local r, g, b = hslToRgb(hue, saturation, lightness)
    return r / 255, g / 255, b / 255  -- Scale to [0, 1] cus thats how LOVE does it
end

-- Checking if move is valid, and adjusting zoom accordingly
function love.keypressed(key)
    -- Store original values
    local original_re = center_re
    local original_im = center_im
    local original_xspan = xspan
    local original_yspan = yspan
    local original_max_iter = max_iter
    
    -- Calculate movement direction
    local moveX, moveY = 0, 0
    if key == 'a' or key == 'left' then moveX = -1 end
    if key == 'd' or key == 'right' then moveX = 1 end
    if key == 'w' or key == 'up' then moveY = -1 end
    if key == 's' or key == 'down' then moveY = 1 end
    
    -- Normalize diagonal movement
    if moveX ~= 0 and moveY ~= 0 then
        moveX, moveY = moveX * 0.7071, moveY * 0.7071
    end
    
    -- Movement amount (world units)
    local moveAmount = 0.1 * xspan  -- Scales with zoom level
    
    local player_sizeX, player_sizeY = convertPlayerSize()
    local player_worldX, player_worldY = convertPlayerCoordinates()
    
    -- Check if movement would go outside fractal
    local function isValidPosition(x, y)
        local points = {
            -- Check all sides and corners
            {x - player_sizeX/2, y},                -- left
            {x + player_sizeX/2, y},                -- right
            {x, y - player_sizeY/2},                -- top
            {x, y + player_sizeY/2},                -- bottom
            {x - player_sizeX/2, y - player_sizeY/2}, -- top-left
            {x + player_sizeX/2, y - player_sizeY/2}, -- top-right
            {x - player_sizeX/2, y + player_sizeY/2}, -- bottom-left
            {x + player_sizeX/2, y + player_sizeY/2}  -- bottom-right
        }
        
        for _, point in ipairs(points) do
            if calculateMandelbrot(point[1], point[2], max_iter) < max_iter then
                return false  -- At least one point is outside
            end
        end
        return true  -- All points inside fractal
    end
    
    -- Try to move (with automatic zoom)
    local proposed_re = center_re + moveX * moveAmount
    local proposed_im = center_im + moveY * moveAmount
    local zoomSteps = 0
    local maxZoomSteps = 20
    
    -- Keep zooming in until the player fits, adjust the distance stepped to account for zoom
    while not isValidPosition(proposed_re, proposed_im) and zoomSteps < maxZoomSteps do
        -- Zoom in
        xspan = xspan * 0.9
        yspan = yspan * 0.9
        moveAmount = 0.1 * xspan  -- Update move amount for new zoom
        proposed_re = center_re + moveX * moveAmount
        proposed_im = center_im + moveY * moveAmount
        zoomSteps = zoomSteps + 1
        max_iter = max_iter * 1.05  -- Increase detail when zooming
    end
    
    -- Apply movement if possible
    if isValidPosition(proposed_re, proposed_im) then
        center_re = proposed_re
        center_im = proposed_im
    else
        center_re = original_re
        center_im = original_im
        xspan = original_xspan
        yspan = original_yspan
        max_iter = original_max_iter
    end
    
    update_bounds()
    redraw_fractal()
end

-- Basic helper functions cus these were being used often
function convertPlayerSize()
    local player_sizeX = (xmax - xmin) * player.size / width
    local player_sizeY = (ymax - ymin) * player.size / height
    return player_sizeX, player_sizeY
end

function convertPlayerCoordinates()
    local player_worldX = xmin + (xmax - xmin) * player.x / width
    local player_worldY = ymin + (ymax - ymin) * player.y / height
    return player_worldX, player_worldY
end