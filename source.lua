local field = {}
local covers = {}
local images = {}

-- tile height/width: 16
-- digit height: 23 width: 13
-- wall width: 10

local scores = {}

local rows = nil
local cols = nil
local mines = 10
local difficultysetting = 1

local gamestate = "playing"
local firstclick = false

local menuopen = false
local menuselection = 1
local numselection = 1

local flagsdown = nil
local unopened = nil

local time = nil
local starttimer = false -- used to determine if timer is running. set to true upon first click.

local cursorx = nil
local cursory = nil
local quickflag = false


local yoffset = 0
local xoffset = 0
local menuy = 350

local targetyoff = 0
local targetxoff = 0
local targetmenuy = 350

local dampcoeff = 0.3

local fieldstartx = 0 -- temporarily added a 0 since ocasionally after setting the code, there would be an error
local fieldendx = 0   -- where something attempted to use the nil value.
local boardstartx = 0

local mousedown = false

local willrestart = false -- used to determine whether to restart when mouse clicks the smiley face.
-- pressing any key should set this to false, cancelling the resetgame.

local tileids = { -- sus
    [0] = "tnothing",
    [1] = "tnum1",
    [2] = "tnum2",
    [3] = "tnum3",
    [4] = "tnum4",
    [5] = "tnum5",
    [6] = "tnum6",
    [7] = "tnum7",
    [8] = "tnum8",
    [9] = "tbomb",
    [10] = "tbombclicked",
    [11] = "tbombmisflag"
}

local coverids = {
    [1] = "t_normal",
    [2] = "t_flag",
    [3] = "t_marked"
}

-- dimensions for each difficulty.
-- 0 is beginner, 1 is intermediate, etc
local sv = {
    { 9,  9,  10 },
    { 16, 16, 40 },
    { 30, 16, 99 },
    { 9,  9,  10 }
}


function open(x, y)
    if gamestate == "playing" then -- note: gamestate check is done like twice lmao
        if covers[y][x] == 1 then
            if field[y][x] == 9 then
                field[y][x] = 10
                endgame("lost")
            else
                covers[y][x] = 0
                if field[y][x] == 0 then
                    for a = y - 1, y + 1 do
                        for b = x - 1, x + 1 do
                            if iSVALID(b, a) then
                                open(b, a)
                            end
                        end
                    end
                end
            end
        end
    end
end

function flag(x, y)
    if gamestate == "playing" then
        if covers[y][x] == 1 then
            covers[y][x] = 2
        elseif covers[y][x] == 2 then
            covers[y][x] = 1
        end
    end
end

function chord(x, y)
    if gamestate == "playing" and covers[y][x] == 0 and countadjflags(x, y) == field[y][x] then
        for a = y - 1, y + 1 do
            for b = x - 1, x + 1 do
                if iSVALID(b, a) then
                    open(b, a)
                end
            end
        end
    end
end

function countstuff()
    flagsdown = 0
    unopened = 0
    for a = 1, rows do
        for b = 1, cols do
            if covers[a][b] ~= 0 then
                unopened = unopened + 1
                if covers[a][b] == 2 then
                    flagsdown = flagsdown + 1
                end
            end
        end
    end
end

function summarize()
    for a = 1, rows do
        for b = 1, cols do
            if gamestate == "win" then -- win/lost
                if covers[a][b] == 1 then
                    covers[a][b] = 2
                end
            else
                if covers[a][b] == 2 and field[a][b] ~= 9 then
                    field[a][b] = 11
                    covers[a][b] = 0
                end
                if covers[a][b] == 1 and (field[a][b] == 9 or field[a][b] == 10) then
                    covers[a][b] = 0
                end
            end
        end
    end
end

function endgame(state)
    gamestate = state
    if gamestate == "win" then
        if difficultysetting < 4 then
            -- since precision is only 0.05, i subtract the value so string.format always rounds down. (lol)
            updaterecord(math.min(9999.9, time - 0.03), difficultysetting)
        end
    end
    summarize()
end

function countadjflags(x, y)
    local adjnumflags = 0
    for a = y - 1, y + 1 do
        for b = x - 1, x + 1 do
            if iSVALID(b, a) and covers[a][b] == 2 then
                adjnumflags = adjnumflags + 1
            end
        end
    end
    return adjnumflags
end

function setmines(x, y)
    local placed = 0
    local emergencyf = 0 -- oops
    while placed < mines and emergencyf < 10000 do
        tx = math.random(1, cols)
        ty = math.random(1, rows)

        if field[ty][tx] >= 0 then
            if (math.abs(tx - x) > 1 or math.abs(ty - y) > 1) or (rows * cols - (rows - 1) * (cols - 1) < 9 and (tx ~= x or ty ~= y)) then -- extra logic added for stupid games
                placed = placed + 1
                field[ty][tx] = -100
                for a = ty - 1, ty + 1 do
                    for b = tx - 1, tx + 1 do
                        if iSVALID(b, a) then
                            field[a][b] = field[a][b] + 1
                        end
                    end
                end
            end
        end
        emergencyf = emergencyf + 1
    end
    for a = 1, rows do
        for b = 1, cols do
            if field[a][b] < 0 then
                field[a][b] = 9
            end
        end
    end
    mines = placed
end

function iSVALID(x, y)
    return x >= 1 and x <= cols and y >= 1 and y <= rows
end

function wITHINBOX(inputx, inputy, x, y, width, height)
    return inputx > x and inputx < x + width and inputy > y and inputy < y + height
end

function resetgame(difficulty)
    difficultysetting = difficulty
    rows = sv[difficulty][1]
    cols = sv[difficulty][2]
    mines = sv[difficulty][3]
    for y = 1, rows do
        field[y] = {}
        covers[y] = {}
        for x = 1, cols do
            field[y][x] = 0
            covers[y][x] = 1
        end
    end

    cursorx = math.ceil(cols / 2)
    cursory = math.min(math.ceil(rows / 2), 7)

    menuopen = false

    targetxoff = 0
    targetyoff = 0
    targetmenuy = 350

    time = 0
    firstclick = true
    starttimer = false

    update() -- in case board is autowin
    gamestate = "playing"
end

function on.timer()
    -- sketchy
    if gamestate == "playing" and starttimer == true then
        time = time + 0.05
        if (time % 1) < 0.1 then
            platform.window:invalidate()
        end
    end

    if math.abs(yoffset - targetyoff) > 1 then
        yoffset = yoffset + (targetyoff - yoffset) * dampcoeff
        if math.abs(yoffset - targetyoff) <= 1 then yoffset = targetyoff end
        platform.window:invalidate()
    end

    if math.abs(xoffset - targetxoff) > 1 then
        xoffset = xoffset + (targetxoff - xoffset) * (dampcoeff * 1.6)
        if math.abs(xoffset - targetxoff) <= 1 then xoffset = targetxoff end
        platform.window:invalidate()
    end
    if math.abs(menuy - targetmenuy) > 1 then
        menuy = menuy + (targetmenuy - menuy) * (dampcoeff * 1.6)
        if math.abs(menuy - targetmenuy) <= 1 then menuy = targetmenuy end
        platform.window:invalidate()
    end
end

function update()
    countstuff()
    if mines == unopened and gamestate == "playing" then
        endgame("win")
    end
    platform.window:invalidate()
end

function on.construction()
    processimages()

    for i = 1, 3 do
        scores[i] = {}
        for j = 1, 3 do
            scores[i][j] = "-"
        end
    end
    getrecords()



    timer.start(0.05)

    resetgame(1)
    update()
end

function on.backspaceKey()
    if menuopen then --
        if menuselection == 4 then
            sv[4][numselection] = 0
        end
    else
        resetgame(difficultysetting)
    end
end

function on.enterKey()
    if menuopen then
        sv[4][1] = math.max(2, math.min(100, sv[4][1]))
        sv[4][2] = math.max(2, math.min(20, sv[4][2]))
        sv[4][3] = math.max(0, math.min((sv[4][1] - 1) * (sv[4][2] - 1), sv[4][3]))
        resetgame(menuselection)
    elseif gamestate == "playing" then
        if firstclick then
            setmines(cursorx, cursory)
            countstuff()
            firstclick = false
            starttimer = true
        end
        open(cursorx, cursory)
    end
    update()
end

function enternumber(new, old, digits)
    if old >= 10 ^ (digits - 1) then
        return new
    else
        return old * 10 + new
    end
end

function on.charIn(key)
    willrestart = false
    if key == 'm' then
        if menuopen == false then
            menuopen = true
            targetxoff = -8 * math.max(cols, 7) + 12
            targetmenuy = 0
        else
            menuopen = false
            targetxoff = 0
            targetmenuy = 350
        end
    end

    if (key == '+' or key == '-') and gamestate == "playing" then
        starttimer = true
        flag(cursorx, cursory)
        chord(cursorx, cursory)
        if gamestate == "playing" then
            update()
        end
    end

    if menuopen and tonumber(key) then
        if menuselection == 4 then
            if numselection == 3 then
                sv[4][3] = enternumber(tonumber(key), sv[4][3], 4)
            else
                sv[4][numselection] = enternumber(tonumber(key), sv[4][numselection], 2)
            end
        end
    else
        if gamestate == "playing" then
            if key == '2' or key == '1' or key == '3' then cursory = math.min(rows, cursory + 1) end
            if key == '8' or key == '7' or key == '9' then cursory = math.max(1, cursory - 1) end
            if key == '6' or key == '3' or key == '9' then cursorx = math.min(cols, cursorx + 1) end
            if key == '4' or key == '1' or key == '7' then cursorx = math.max(1, cursorx - 1) end

            if key == '.' then quickflag = not quickflag end

            if key == '5' then
                if quickflag then
                    starttimer = true
                    flag(cursorx, cursory)
                    chord(cursorx, cursory)
                    if gamestate == "playing" then
                        update()
                    end
                else
                    if firstclick then
                        setmines(cursorx, cursory)
                        countstuff()
                        firstclick = false
                        starttimer = true
                    end
                    open(cursorx, cursory)
                    update() -- ??????????? idk where this should rly go
                end
            end
        end

        if (key == '^' or key == "^2") and targetyoff > 0 then
            targetyoff = targetyoff - 48
        elseif (key == "exp(" or key == "10^(") and targetyoff < ((45 + 16 * rows) - platform.window:height()) then
            targetyoff = targetyoff + 48
        end
    end
    print(key)
    platform.window:invalidate()
end

function on.arrowUp()
    willrestart = false
    if menuopen then
        menuselection = math.max(1, menuselection - 1)
    end
    platform.window:invalidate()
end

function on.arrowDown()
    willrestart = false
    if menuopen then
        menuselection = math.min(4, menuselection + 1)
        numselection = 1
    end
    platform.window:invalidate()
end

function on.arrowLeft()
    willrestart = false
    if menuopen then
        if menuselection == 4 then
            numselection = math.max(1, numselection - 1)
        end
    end
    platform.window:invalidate()
end

function on.arrowRight()
    willrestart = false
    if menuopen then
        if menuselection == 4 then
            numselection = math.min(3, numselection + 1)
        end
    end
    platform.window:invalidate()
end

function on.mouseDown(x, y)
    if wITHINBOX(x, y, platform.window:width() / 2 - 11 - xoffset, 10, 23, 23) then
        willrestart = true
    elseif menuopen and x < 124 then                     -- approx value
        if wITHINBOX(x, y, 5, 159, 117, 45) then         -- custom
            menuselection = 4
            if wITHINBOX(x, y, 10, 177, 18, 13) then     --custom 1
                numselection = 1
            elseif wITHINBOX(x, y, 35, 177, 18, 13) then --custom 2
                numselection = 2
            elseif wITHINBOX(x, y, 63, 177, 22, 13) then --custom 3
                numselection = 3
            else
                resetgame(4) -- play custom
            end
        end
        for a = 1, 3 do
            if wITHINBOX(x, y, 5, -41 + 50 * a, 117, 45) then
                menuselection = a
                resetgame(a)
                break
            end
        end
    elseif gamestate == "playing" and not menuopen and wITHINBOX(x, y, fieldstartx, 43, fieldendx - fieldstartx, math.min(platform.window:height() - 43, 16 * rows)) then
        -- edgy-ass calculation
        cursory = math.floor((y + yoffset - 43) / 16) + 1
        cursorx = math.floor((x - boardstartx + xoffset) / 16) + 1
    end
    platform.window:invalidate()
end

function on.mouseUp(x, y)
    if willrestart then
        resetgame(difficultysetting)
        willrestart = false
    end
end

------------------------------------------------------------------------------------------------------------------------

function updaterecord(time, d)
    getrecords()
    if scores[d][1] == "-" or time < scores[d][1] then
        scores[d][3] = scores[d][2]
        scores[d][2] = scores[d][1]
        scores[d][1] = time
    elseif scores[d][2] == "-" or time < scores[d][2] then
        scores[d][3] = scores[d][2]
        scores[d][2] = time
    elseif scores[d][3] == "-" or time < scores[d][3] then
        scores[d][3] = time
    end

    -- submit record
    for i = 1, 3 do
        for j = 1, 3 do
            var.store("msr" .. i .. j, scores[i][j])
        end
    end
end

function getrecords()
    for i = 1, 3 do
        for j = 1, 3 do
            temp = var.recall("msr" .. i .. j)
            if temp == nil then
                temp = "-"
                var.store("msr" .. i .. j, "-")
            end
            scores[i][j] = temp
        end
    end
end

function clearrecords()
    for i = 1, 3 do
        for j = 1, 3 do
            var.store("msr" .. i .. j, "-")
        end
    end
    getrecords()
end

------------------------------------------------------------------------------------------------------------------------

function on.paint(gc)
    gc:clipRect("set", 0, 0, platform.window:width(), platform.window:height())

    fieldstartx = platform.window:width() / 2 - (math.max(cols, 7)) * 8;
    fieldendx = platform.window:width() / 2 + (math.max(cols, 7)) * 8;

    boardstartx = platform.window:width() / 2 - cols * 8; -- used to center board in 2 col games.

    -- Gray Background --
    gc:setColorRGB(192, 192, 192)
    gc:fillRect(0, 0, platform.window:width(), platform.window:height())

    if menuy < 320 then
        drawmenu(gc)
    end

    -- field --
    drawfield(gc, boardstartx, 43)

    -- Cursor --
    drawcursor(gc, boardstartx)

    -- Display --
    drawdisplay(gc, fieldstartx, fieldendx)

    -- Borders --
    drawborders(gc, fieldstartx, fieldendx)

    -- Scrollbar --
    if rows > 10 then
        drawscrollbar(gc)
    end
end

function drawcursor(gc, startx)
    gc:setPen("medium")
    if menuopen then
        gc:setColorRGB(96, 96, 96)
    else
        gc:setColorRGB(0, 0, 0)
    end
    gc:drawRect(startx + 16 * (cursorx - 1) - 1 - xoffset, 42 + 16 * (cursory - 1) - yoffset, 17, 17)
end

function drawtext(gc, x, y, num, precision)
    if num == "-" then return end
    str = string.format("%." .. precision .. "f", num)
    length = 1
    for i = 1, #str do
        c = str:sub(i, i)
        if c == '1' then
            length = length + 5 -- 4 + 1
        elseif c == '.' then
            length = length + 2 -- 4 + 1
        else
            length = length + 6 -- 5 + 1
        end
    end

    xpos = math.floor(x - (length / 2))
    for i = 1, #str do
        c = str:sub(i, i)
        if c == '1' then
            gc:drawImage(images.txt1, xpos, y)
            xpos = xpos + 5 -- 4 + 1
        elseif c == '.' then
            gc:drawImage(images.txtdot, xpos, y)
            xpos = xpos + 2 -- 4 + 1
        else
            gc:drawImage(images["txt" .. c], xpos, y)
            xpos = xpos + 6 -- 5 + 1
        end
    end
end

function drawmenu(gc)
    gc:drawImage(images.mbbeginner, 6, 10 - menuy)
    drawtext(gc, 27, 38 - menuy, scores[1][1], 1)
    drawtext(gc, 65, 38 - menuy, scores[1][2], 1)
    drawtext(gc, 103, 38 - menuy, scores[1][3], 1)

    gc:drawImage(images.mbintermediate, 6, 60 - menuy)
    drawtext(gc, 27, 88 - menuy, scores[2][1], 1)
    drawtext(gc, 65, 88 - menuy, scores[2][2], 1)
    drawtext(gc, 103, 88 - menuy, scores[2][3], 1)

    gc:drawImage(images.mbadvanced, 6, 110 - menuy)
    drawtext(gc, 27, 138 - menuy, scores[3][1], 1)
    drawtext(gc, 65, 138 - menuy, scores[3][2], 1)
    drawtext(gc, 103, 138 - menuy, scores[3][3], 1)

    gc:drawImage(images.mbcustom, 6, 160 - menuy)
    drawtext(gc, 20, 179 - menuy, sv[4][1], 0)
    drawtext(gc, 45, 179 - menuy, sv[4][2], 0)
    drawtext(gc, 76, 179 - menuy, sv[4][3], 0)

    gc:setColorRGB(0, 0, 0)
    gc:setPen("medium")

    gc:drawRect(5, -41 + 50 * math.min(menuselection, 4) - menuy, 117, 45)
    if menuselection == 4 then
        if numselection == 1 then
            gc:drawRect(10, 177 - menuy, 17, 13)
        elseif numselection == 2 then
            gc:drawRect(35, 177 - menuy, 17, 13)
        else
            gc:drawRect(60, 177 - menuy, 28, 13)
        end
    end
end

function drawdisplay(gc, startx, endx)
    gc:setColorRGB(192, 192, 192)
    gc:fillRect(startx - xoffset, 0, endx - startx, 35)

    if willrestart then
        gc:drawImage(images.ssmiledown, platform.window:width() / 2 - 11 - xoffset, 10)
    else
        if gamestate == "lost" then
            gc:drawImage(images.sdead, platform.window:width() / 2 - 11 - xoffset, 10)
        elseif gamestate == "win" then
            gc:drawImage(images.scool, platform.window:width() / 2 - 11 - xoffset, 10)
        else
            gc:drawImage(images.ssmile, platform.window:width() / 2 - 11 - xoffset, 10)
        end
    end

    local tminesleft = math.max(-99, math.min(999, mines - flagsdown))
    drawnums(gc, startx - xoffset, 10, tminesleft)

    local ttime = math.min(999, math.floor(time))
    drawnums(gc, endx - 39 - xoffset, 10, ttime)
end

function drawnums(gc, x, y, value)
    local trueval = math.min(math.max(x, 64 - xoffset), platform.window:width() - 39 - 64 - xoffset)

    local text
    if value < 0 then
        text = 'm' .. string.format("%02d", math.abs(value))
    else
        text = string.format("%03d", value)
    end

    for i = 1, 3 do
        gc:drawImage(images['d' .. text:sub(i, i)], trueval + 13 * (i - 1), y)
    end

    gc:setColorRGB(128, 128, 128)
    gc:fillRect(trueval - 2, 10, 2, 23)
    gc:setColorRGB(255, 255, 255)
    gc:fillRect(trueval + 39, 10, 2, 23)
end

function drawfield(gc, startx, starty)
    for y = 1, rows do
        if (starty + (y - 1) * 16 - yoffset) > platform.window:height() then break end
        if (starty + (y - 1) * 16 - yoffset) > 20 then
            for x = 1, cols do
                if startx + (x - 1) * 16 - xoffset > platform.window:width() then break end
                if covers[y][x] == 0 then
                    gc:drawImage(images[tileids[field[y][x]]], startx + (x - 1) * 16 - xoffset, starty + (y - 1) * 16 -
                        yoffset)
                elseif quickflag and covers[y][x] == 1 then
                    gc:drawImage(images.t_normalqf, startx + (x - 1) * 16 - xoffset, starty + (y - 1) * 16 - yoffset)
                else
                    gc:drawImage(images[coverids[covers[y][x]]], startx + (x - 1) * 16 - xoffset,
                        starty + (y - 1) * 16 - yoffset)
                end
            end
        end
    end
end

function drawscrollbar(gc)
    gc:setColorRGB(128, 128, 128)
    gc:fillRect(platform.window:width() - 6, (yoffset / 16) / rows * platform.window:height(), 6,
        10 / rows * platform.window:height())
end

function drawborders(gc, startx, endx)
    -- Sides (Vertical)
    for x = 0, rows / 2 do -- draw as much as possible up to end
        if x * 32 + 10 - yoffset >= -20 then
            gc:drawImage(images.bsideV, startx - 10 - xoffset, x * 32 + 10 - yoffset)
            gc:drawImage(images.bsideV, endx - xoffset, x * 32 + 10 - yoffset)
        end
        if x * 32 + 10 - yoffset >= platform.window:height() then break end
    end
    gc:drawImage(images.bsideV, startx - 10 - xoffset, rows * 16 + 11 - yoffset)
    gc:drawImage(images.bsideV, endx - xoffset, rows * 16 + 11 - yoffset)

    -- Sides (Horizontal)
    for x = 0, math.max(6, cols - 1) do -- to accommodate games w/ 2 cols
        gc:drawImage(images.bsideH, startx + x * 16 - xoffset, 0)
        gc:drawImage(images.bsideH, startx + x * 16 - xoffset, 33)
        gc:drawImage(images.bsideH, startx + x * 16 - xoffset, 43 + 16 * rows - yoffset)
    end

    -- Corners --
    gc:drawImage(images.bcornTL, startx - 10 - xoffset, 0)      -- top left
    gc:drawImage(images.bcornTR, endx - xoffset, 0)             -- top right
    if yoffset < 8 then
        gc:drawImage(images.bjuncL, startx - 10 - xoffset, 33)  -- middle left T
        gc:drawImage(images.bjuncR, endx - xoffset, 33)         -- middle right T
    else
        gc:drawImage(images.bcornBL, startx - 10 - xoffset, 33) -- middle left T
        gc:drawImage(images.bcornBR, endx - xoffset, 33)
    end
    gc:drawImage(images.bcornBL, startx - 10 - xoffset, 43 + 16 * rows - yoffset) -- bottom left
    gc:drawImage(images.bcornBR, endx - xoffset, 43 + 16 * rows - yoffset)        -- bottom right
end

function processimages()
    for img_name, img_resource in pairs(_R.IMG) do
        images[img_name] = image.new(img_resource)
    end
    images.scool = images.scool:copy(23, 23)
    images.sdead = images.sdead:copy(23, 23)
    images.ssmile = images.ssmile:copy(23, 23)
    images.ssmiledown = images.ssmiledown:copy(23, 23)
end
