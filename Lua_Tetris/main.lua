local WINDOW_WIDTH = 420
local WINDOW_HEIGHT = 600
local BLOCK_SIZE = 30
local ROWS = 20
local COLS = 14
local EMPTY = 0
local INITIAL_TICK_TIME = 0.5
local TICK_DECREMENT = 0.05
local MIN_TICK_TIME = 0.1
local FAST_FALL_TICK_MULTIPLIER = 0.00000001

local shapes = {
    {
        {1, 1, 1, 1}
    },
    {
        {1, 1, 0},
        {0, 1, 1}
    },
    {
        {0, 1, 1},
        {1, 1, 0}
    },
    {
        {1, 1},
        {1, 1}
    }
}

local grid = {}


local currentPiece = {}
local currentRow = 1
local currentCol = 1
local currentShapeIndex = 1

local tickTime = INITIAL_TICK_TIME
local timeSinceTick = 0

local score = 0
local gameIsOver = false;

local function initGrid()
    for i = 1, ROWS do
        grid[i] = {}
        for j = 1, COLS do
            grid[i][j] = EMPTY
        end
    end
end
initGrid()

local function drawBlock(x, y)
    love.graphics.rectangle("fill", (x - 1) * BLOCK_SIZE, (y - 1) * BLOCK_SIZE, BLOCK_SIZE, BLOCK_SIZE)
end

local function drawScore()
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("Score: " .. score, 10, 10)
end

local function drawGrid()
    for i = 1, ROWS do
        for j = 1, COLS do
            if grid[i][j] ~= EMPTY then
                drawBlock(j, i)
            end
        end
    end
end

local function drawCurrentPiece()
    for i = 1, #currentPiece do
        for j = 1, #currentPiece[i] do
            if currentPiece[i][j] == 1 then
                drawBlock(currentCol + j - 1, currentRow + i - 1)
            end
        end
    end
end

local function canMoveDown()
    for i = 1, #currentPiece do
        for j = 1, #currentPiece[i] do
            if currentPiece[i][j] == 1 then
                local row = currentRow + i
                if row > ROWS or grid[row][currentCol + j - 1] ~= EMPTY then
                    return false
                end
            end
        end
    end
    return true
end

local function mergePiece()
    for i = 1, #currentPiece do
        for j = 1, #currentPiece[i] do
            if currentPiece[i][j] == 1 then
                grid[currentRow + i - 1][currentCol + j - 1] = currentPiece[i][j]
            end
        end
    end
end

local function removeFullRow()
    local fullRows = {}
    for i = ROWS, 1, -1 do
        local full = true
        for j = 1, COLS do
            if grid[i][j] == EMPTY then
                full = false
                break
            end
        end
        if full then
            table.insert(fullRows, i)
        end
    end

    if #fullRows == 0 then
        return
    end
 
    for _, rowIndex in ipairs(fullRows) do
        for i = rowIndex, 2, -1 do
            for j = 1, COLS do
                grid[i][j] = grid[i - 1][j]
            end
        end
        for j = 1, COLS do
            grid[1][j] = EMPTY
        end
        score = score + 200
    end
    removeFullRow()
end

local function isGameOver()
    for j = 1, COLS do
        if grid[1][j] ~= EMPTY then
            return true
        end
    end
    return false
end

local function gameOver()
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Game Over\nScore: " .. score .. "\nPress 'R' to restart", 0, WINDOW_HEIGHT / 2 - 30, WINDOW_WIDTH, "center")
end

local function spawnNewPiece()
    currentShapeIndex = love.math.random(1, #shapes)
    currentPiece = shapes[currentShapeIndex]
    currentRow = 1
    currentCol = math.floor(COLS / 2)
    if not canMoveDown() or isGameOver() then
        gameIsOver = true
        gameOver()
        return
    end
end

local function rotatePieceClockwise()
    local newPiece = {}
    for j = 1, #currentPiece[1] do
        newPiece[j] = {}
        for i = #currentPiece, 1, -1 do
            newPiece[j][#currentPiece - i + 1] = currentPiece[i][j]
        end
    end
    currentPiece = newPiece
end

function love.load()
    love.window.setTitle("Tetris")
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2)

    spawnNewPiece()
end

function love.update(dt)
    timeSinceTick = timeSinceTick + dt
    local tickSpeed = tickTime
    if love.keyboard.isDown("down") then
        tickSpeed = tickTime * FAST_FALL_TICK_MULTIPLIER
    end
    if timeSinceTick >= tickSpeed then
        timeSinceTick = timeSinceTick - tickSpeed
        if canMoveDown() then
            currentRow = currentRow + 1
        else
            mergePiece()
            spawnNewPiece()
            removeFullRow()
        end
    end
end

function love.draw()
    drawGrid()
    drawCurrentPiece()
    drawScore()
    if gameIsOver then
        gameOver()
    end
end

function love.keypressed(key)
    if key == "left" then
        currentCol = currentCol - 1
        if currentCol < 1 then
            currentCol = 1
        end
    elseif key == "right" then
        currentCol = currentCol + 1
        if currentCol + #currentPiece[1] - 1 > COLS then
            currentCol = COLS - #currentPiece[1] + 1
        end
    elseif key == "space" then
        rotatePieceClockwise()
    elseif key == "r" then
        resetGame()
    end
end

function resetGame()
    score = 0
    grid = {}
    initGrid()
    tickTime = INITIAL_TICK_TIME
    timeSinceTick = 0
    gameIsOver = false
    spawnNewPiece()
end