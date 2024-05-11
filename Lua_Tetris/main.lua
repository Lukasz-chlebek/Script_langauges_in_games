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
local gameIsOver = false
local inMenu = true
local volume = 0.1

local moveSound = love.audio.newSource("move.mp3", "static")
local rotateSound = love.audio.newSource("rotate.mp3", "static")
local gameOverSound = love.audio.newSource("gameOver.mp3", "static")
local clearRowSound = love.audio.newSource("deleteRow.mp3", "static")
local menuSound = love.audio.newSource("menuSong.mp3", "static")
local ambientSound = love.audio.newSource("ambient.mp3", "static")
local background = love.graphics.newImage("background.jpg")



local function playMoveSound()
    moveSound:stop() 
    moveSound:setVolume(volume)
    moveSound:play()
end

local function playMenuSound()
    menuSound:stop() 
    menuSound:setVolume(volume)
    menuSound:play()
end
local function stopMenuSound()
    menuSound:stop() 
end

local function playAmbientSound()
    ambientSound:stop() 
    ambientSound:setVolume(0.01)
    ambientSound:setLooping(true)
    ambientSound:play()
end
local function stopAmbientSound()
    ambientSound:stop() 
end

local function playRotateSound()
    rotateSound:stop()
    rotateSound:setVolume(volume)
    rotateSound:play()
end


local function playGameOverSound()
    gameOverSound:setVolume(volume)
    gameOverSound:play()
end
local function stopGameOverSound()
    gameOverSound:stop() 
end


local function playClearRowSound()
    clearRowSound:stop()
    clearRowSound:setVolume(volume)
    clearRowSound:play()
end

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
    love.graphics.print("Score: ".. score .. "\nPress 'Q' to save and go back to menu", 10, 10)
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
    playClearRowSound()
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
    stopAmbientSound()
    playGameOverSound()
    love.graphics.clear()
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf("Game Over\nScore: " .. score .. "\nPress 'R' to restart\nPress 'M' to go back to menu ", 0, WINDOW_HEIGHT / 2 - 30, WINDOW_WIDTH, "center")
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

local function spawnPieceFromSave()
    currentPiece = shapes[currentShapeIndex]
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
    playRotateSound()
end

function love.load()
    love.window.setTitle("Tetris")
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2)
    buttonStart = {
        text = "New game",
        x = 100,
        y = 200,
        width = 100,
        height = 50
    }

    buttonLoad = {
        text = "Load game",
        x = 100,
        y = 300,
        width = 150,
        height = 50
    }
    playMenuSound()
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

function drawMenu()
    love.graphics.setBackgroundColor(0.2, 0.2, 0.2)

    love.graphics.setColor(0.4, 0.4, 0.8)
    love.graphics.rectangle("fill", buttonStart.x, buttonStart.y, buttonStart.width, buttonStart.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(buttonStart.text, buttonStart.x, buttonStart.y + buttonStart.height / 3, buttonStart.width, "center")

    love.graphics.setColor(0.4, 0.4, 0.8)
    love.graphics.rectangle("fill", buttonLoad.x, buttonLoad.y, buttonLoad.width, buttonLoad.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(buttonLoad.text, buttonLoad.x, buttonLoad.y + buttonLoad.height / 3, buttonLoad.width, "center")
end

function drawBackground()
    for i = 0, love.graphics.getWidth() / background:getWidth() do
        for j = 0, love.graphics.getHeight() / background:getHeight() do
            love.graphics.draw(background, i * background:getWidth(), j * background:getHeight())
        end
    end
end

function love.draw()
    drawBackground()
    if inMenu then
        drawMenu()
        return
    end
    drawGrid()
    drawCurrentPiece()
    drawScore()
    if gameIsOver then
        gameOver()
    end
    
end

function saveGameStateToFile()
    local filename = "gamestate.txt"
    local file = io.open(filename, "w")

    for i = 1, ROWS do
        for j = 1, COLS do
            file:write(grid[i][j] .. " ")
        end
        file:write("\n")
    end

    file:write("currentShapeIndex=" .. currentShapeIndex .. "\n")
    file:write("score=" .. score .. "\n")
    file:write("currentCol=" .. currentCol .. "\n")
    file:write("currentRow=" .. currentRow .. "\n")
    file:close()
end

function loadGameStateFromFile()
    local filename = "gamestate.txt"
    local file = io.open(filename, "r")

    if file then
        initGrid()
        for i = 1, ROWS do
            local line = file:read() 
            local row = {}
            for value in line:gmatch("%S+") do 
                table.insert(row, tonumber(value)) 
            end
            grid[i] = row 
        end

        for line in file:lines() do
            local key, value = line:match("([^=]+)=(.+)")
            if key == "currentShapeIndex" then
                currentShapeIndex = tonumber(value) 
            elseif key == "score" then
                score = tonumber(value)
            elseif key == "currentCol" then
                currentCol = tonumber(value)
            elseif key == "currentRow" then
                currentRow = tonumber(value)
            end
        end

        file:close()
    else
        print("Cannot find file.")
    end
end

function love.keypressed(key)
    if key == "left" then
        currentCol = currentCol - 1
        if currentCol < 1 then
            currentCol = 1
        else
            playMoveSound()
        end
    elseif key == "right" then
        currentCol = currentCol + 1
        if currentCol + #currentPiece[1] - 1 > COLS then
            currentCol = COLS - #currentPiece[1] + 1
        else
            playMoveSound()
        end
    elseif key == "space" then
        rotatePieceClockwise()
    elseif key == "r" then
        resetGame()
    elseif key== "q" then
        saveGameStateToFile()
        stopAmbientSound()
        playMenuSound()
        inMenu = true
    elseif key== "m" then
        inMenu = true
        stopAmbientSound()
    end
end

function love.mousepressed(x, y, button)
    if button == 1 then
        resetGame()
        if x >= buttonStart.x and x <= buttonStart.x + buttonStart.width and y >= buttonStart.y and y <= buttonStart.y + buttonStart.height then
            spawnNewPiece()
        end
        if x >= buttonLoad.x and x <= buttonLoad.x + buttonLoad.width and y >= buttonLoad.y and y <= buttonLoad.y + buttonLoad.height then
            loadGameStateFromFile()
        end
        stopMenuSound()
        playAmbientSound()
        inMenu = false
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
    stopGameOverSound()
end