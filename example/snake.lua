-- Snake Game Example for Soluna
-- To run: bin/soluna.exe entry=example/snake.lua
-- Or: bin/soluna.exe example/snake.game

local soluna = require "soluna"
local matquad = require "soluna.material.quad"

soluna.set_window_title "Snake Game - Soluna Example"

local args = ...
local batch = args.batch

-- Game configuration
local GRID_SIZE = 20        -- Size of each grid cell in pixels
local GRID_WIDTH = 30       -- Number of cells horizontally
local GRID_HEIGHT = 20      -- Number of cells vertically
local INITIAL_SPEED = 10    -- Frames per move (lower = faster)

-- Colors (RGBA format: 0xRRGGBBAA)
local COLOR_BACKGROUND = 0x1a1a2eff
local COLOR_SNAKE_HEAD = 0x4ade80ff
local COLOR_SNAKE_BODY = 0x22c55eff
local COLOR_FOOD = 0xef4444ff
local COLOR_BORDER = 0x374151ff
local COLOR_SCORE_BG = 0x111827ff

-- Direction constants
local DIR_UP = 1
local DIR_DOWN = 2
local DIR_LEFT = 3
local DIR_RIGHT = 4

-- Key codes (based on GLFW key codes)
local KEY_UP = 265
local KEY_DOWN = 264
local KEY_LEFT = 263
local KEY_RIGHT = 262
local KEY_W = 87
local KEY_S = 83
local KEY_A = 65
local KEY_D = 68
local KEY_SPACE = 32
local KEY_R = 82

-- Game state
local snake = {}
local direction = DIR_RIGHT
local next_direction = DIR_RIGHT
local food = {x = 0, y = 0}
local score = 0
local game_over = false
local paused = false
local frame_count = 0
local speed = INITIAL_SPEED

-- Screen dimensions
local screen_w = args.width
local screen_h = args.height

-- Calculate game area position (centered)
local function get_game_offset()
    local game_w = GRID_WIDTH * GRID_SIZE
    local game_h = GRID_HEIGHT * GRID_SIZE
    local offset_x = (screen_w - game_w) / 2
    local offset_y = (screen_h - game_h) / 2 + 20  -- Extra space for score display
    return offset_x, offset_y
end

-- Initialize the snake at the center
local function init_snake()
    snake = {}
    local start_x = math.floor(GRID_WIDTH / 2)
    local start_y = math.floor(GRID_HEIGHT / 2)
    for i = 0, 3 do
        table.insert(snake, {x = start_x - i, y = start_y})
    end
end

-- Check if a position is occupied by the snake
local function is_snake_position(x, y)
    for _, segment in ipairs(snake) do
        if segment.x == x and segment.y == y then
            return true
        end
    end
    return false
end

-- Spawn food at a random position not occupied by the snake
local function spawn_food()
    local attempts = 0
    repeat
        food.x = math.random(0, GRID_WIDTH - 1)
        food.y = math.random(0, GRID_HEIGHT - 1)
        attempts = attempts + 1
    until not is_snake_position(food.x, food.y) or attempts > 1000
end

-- Initialize the game
local function init_game()
    math.randomseed(os.time())
    init_snake()
    spawn_food()
    direction = DIR_RIGHT
    next_direction = DIR_RIGHT
    score = 0
    game_over = false
    paused = false
    speed = INITIAL_SPEED
    frame_count = 0
end

-- Get the opposite direction
local function opposite_direction(dir)
    if dir == DIR_UP then return DIR_DOWN
    elseif dir == DIR_DOWN then return DIR_UP
    elseif dir == DIR_LEFT then return DIR_RIGHT
    elseif dir == DIR_RIGHT then return DIR_LEFT
    end
end

-- Move the snake
local function move_snake()
    direction = next_direction
    
    -- Calculate new head position
    local head = snake[1]
    local new_head = {x = head.x, y = head.y}
    
    if direction == DIR_UP then
        new_head.y = new_head.y - 1
    elseif direction == DIR_DOWN then
        new_head.y = new_head.y + 1
    elseif direction == DIR_LEFT then
        new_head.x = new_head.x - 1
    elseif direction == DIR_RIGHT then
        new_head.x = new_head.x + 1
    end
    
    -- Check wall collision
    if new_head.x < 0 or new_head.x >= GRID_WIDTH or
       new_head.y < 0 or new_head.y >= GRID_HEIGHT then
        game_over = true
        return
    end
    
    -- Check self collision (exclude tail since it will move)
    for i = 1, #snake - 1 do
        if snake[i].x == new_head.x and snake[i].y == new_head.y then
            game_over = true
            return
        end
    end
    
    -- Insert new head
    table.insert(snake, 1, new_head)
    
    -- Check food collision
    if new_head.x == food.x and new_head.y == food.y then
        score = score + 10
        spawn_food()
        -- Increase speed every 50 points
        if score % 50 == 0 and speed > 3 then
            speed = speed - 1
        end
    else
        -- Remove tail
        table.remove(snake)
    end
end

-- Draw a single grid cell
local function draw_cell(x, y, color)
    local offset_x, offset_y = get_game_offset()
    local px = offset_x + x * GRID_SIZE + 1
    local py = offset_y + y * GRID_SIZE + 1
    batch:add(matquad.quad(GRID_SIZE - 2, GRID_SIZE - 2, color), px, py)
end

-- Draw the game border
local function draw_border()
    local offset_x, offset_y = get_game_offset()
    local game_w = GRID_WIDTH * GRID_SIZE
    local game_h = GRID_HEIGHT * GRID_SIZE
    local border = 4
    
    -- Top border
    batch:add(matquad.quad(game_w + border * 2, border, COLOR_BORDER), offset_x - border, offset_y - border)
    -- Bottom border
    batch:add(matquad.quad(game_w + border * 2, border, COLOR_BORDER), offset_x - border, offset_y + game_h)
    -- Left border
    batch:add(matquad.quad(border, game_h, COLOR_BORDER), offset_x - border, offset_y)
    -- Right border
    batch:add(matquad.quad(border, game_h, COLOR_BORDER), offset_x + game_w, offset_y)
end

-- Draw the game background
local function draw_background()
    local offset_x, offset_y = get_game_offset()
    local game_w = GRID_WIDTH * GRID_SIZE
    local game_h = GRID_HEIGHT * GRID_SIZE
    batch:add(matquad.quad(game_w, game_h, COLOR_BACKGROUND), offset_x, offset_y)
end

-- Draw the snake
local function draw_snake()
    for i, segment in ipairs(snake) do
        local color = (i == 1) and COLOR_SNAKE_HEAD or COLOR_SNAKE_BODY
        draw_cell(segment.x, segment.y, color)
    end
end

-- Draw the food
local function draw_food()
    draw_cell(food.x, food.y, COLOR_FOOD)
end

-- Draw score display
local function draw_score()
    local offset_x, offset_y = get_game_offset()
    -- Score background
    batch:add(matquad.quad(120, 30, COLOR_SCORE_BG), offset_x, offset_y - 40)
    
    -- Draw score as small rectangles (simple digit representation)
    local score_str = tostring(score)
    for i = 1, #score_str do
        local digit = tonumber(score_str:sub(i, i))
        -- Simple representation: filled rectangle whose height represents the digit
        local bar_h = 4 + digit * 2
        batch:add(matquad.quad(8, bar_h, 0xfbbf24ff), offset_x + 10 + (i - 1) * 12, offset_y - 35 + (20 - bar_h) / 2)
    end
end

-- Draw game over overlay
local function draw_game_over()
    -- Semi-transparent overlay
    batch:add(matquad.quad(screen_w, screen_h, 0x00000080), 0, 0)
    
    -- Game over indicator (red rectangle in center)
    local indicator_w = 200
    local indicator_h = 60
    batch:add(matquad.quad(indicator_w, indicator_h, 0xdc2626ff), 
              (screen_w - indicator_w) / 2, 
              (screen_h - indicator_h) / 2)
    
    -- "Restart" hint (small white rectangle)
    batch:add(matquad.quad(150, 20, 0xffffffcc), 
              (screen_w - 150) / 2, 
              (screen_h + indicator_h) / 2 + 20)
end

-- Draw pause indicator
local function draw_paused()
    -- Pause indicator (two vertical bars)
    local bar_w = 20
    local bar_h = 60
    local gap = 15
    local center_x = screen_w / 2
    local center_y = screen_h / 2
    
    batch:add(matquad.quad(bar_w, bar_h, 0xffffffcc), center_x - gap - bar_w, center_y - bar_h / 2)
    batch:add(matquad.quad(bar_w, bar_h, 0xffffffcc), center_x + gap, center_y - bar_h / 2)
end

-- Initialize game on load
init_game()

-- Callback functions
local callback = {}

function callback.frame(count)
    frame_count = frame_count + 1
    
    -- Update game state
    if not game_over and not paused then
        if frame_count % speed == 0 then
            move_snake()
        end
    end
    
    -- Draw everything
    draw_background()
    draw_border()
    draw_snake()
    draw_food()
    draw_score()
    
    if game_over then
        draw_game_over()
    elseif paused then
        draw_paused()
    end
end

function callback.key(keycode, state)
    if state ~= 1 then return end  -- Only handle key press
    
    -- Restart game
    if game_over and (keycode == KEY_SPACE or keycode == KEY_R) then
        init_game()
        return
    end
    
    -- Pause/unpause
    if keycode == KEY_SPACE then
        paused = not paused
        return
    end
    
    -- Direction controls (prevent 180-degree turns)
    if not paused and not game_over then
        if (keycode == KEY_UP or keycode == KEY_W) and direction ~= DIR_DOWN then
            next_direction = DIR_UP
        elseif (keycode == KEY_DOWN or keycode == KEY_S) and direction ~= DIR_UP then
            next_direction = DIR_DOWN
        elseif (keycode == KEY_LEFT or keycode == KEY_A) and direction ~= DIR_RIGHT then
            next_direction = DIR_LEFT
        elseif (keycode == KEY_RIGHT or keycode == KEY_D) and direction ~= DIR_LEFT then
            next_direction = DIR_RIGHT
        end
    end
end

function callback.window_resize(w, h)
    screen_w = w
    screen_h = h
end

return callback
