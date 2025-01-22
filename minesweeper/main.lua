fieldWidth = 10
fieldHeight = 10
margin = 100
textSize = 10
mineCount = 10 
function createCell()
	return {
		mine = false,
		number = 0,
		opened = false,
		flagged = false,
	}
end
function init()
	field = {}
	for i=1,fieldWidth do
		local array = {}
		for j=1,fieldHeight do
			array[j] = createCell()	
		end
		field[i] = array
	end
	gameResult = 0
	flagCount = 0
	firstPress = true
	textFont = love.graphics.newFont(textSize)
end
function spawnMines(count)
	local possibleSquares = {}
	local startDirections = getPossibleDirections(firstPressX, firstPressY)
	for i=1,fieldWidth do
		for j=1,fieldHeight do
			if i ~= firstPressX or j ~= firstPressY then
				local found = false
				for k=1,#startDirections do
					local thisDirection = startDirections[k]
					if i == firstPressX + thisDirection[1] and j == firstPressY + thisDirection[2] then 
						found = true
						break 
					end
				end	
				if not found then
					table.insert(possibleSquares, {i,j})
				end
			end
		end
	end
	minePositions = {}
	for i=1,mineCount do
		local randomIndex = math.random(table.getn(possibleSquares))
		local element = table.remove(possibleSquares, randomIndex)
		table.insert(minePositions, element)
		field[element[1]][element[2]].mine = true
	end
end
function setNumbers()
	for i=1,fieldWidth do
		for j=1,fieldHeight do
			if not field[i][j].mine then
				local directions = getPossibleDirections(i,j)	
				local counter = 0
				for k=1,#directions do
					local direction = directions[k]
					if field[i+direction[1]][j+direction[2]].mine then counter = counter + 1 end
				end
				field[i][j].number = counter
			end
		end
	end
end
function checkAllFlagged()
	for i=1,#minePositions do
		local thisPosition = minePositions[i]
		if not field[thisPosition[1]][thisPosition[2]].flagged then return end
	end
	win()
end
function checkAllOpened()
	for i=1,fieldWidth do
		for j=1,fieldHeight do
			local thisCell = field[i][j]		
			if not thisCell.mine and not thisCell.opened then return end
		end 
	end
	win()
end
function win() gameResult = 1 end
function getPossibleDirections(x,y)
	local availableXDirections = {}
	if x~=1 then availableXDirections[1] = -1 end
	if x~=fieldWidth then table.insert(availableXDirections, 1) end
	local availableYDirections = {}
	if y~=1 then availableYDirections[1] = -1 end
	if y~=fieldHeight then table.insert(availableYDirections, 1) end
	local directions = {}
	for k=1,#availableYDirections do
		table.insert(directions, {0, availableYDirections[k]})
	end
	for k=1,#availableXDirections do
		local xDirection = availableXDirections[k]
		table.insert(directions, {xDirection, 0})
		for o=1,#availableYDirections do
			table.insert(directions, {xDirection, availableYDirections[o]})
		end
	end
	return directions
end
function open(x,y, singleOpen)
	local thisCell = field[x][y]
	thisCell.opened = true
	field[x][y] = thisCell
	if thisCell.mine then 
		gameResult = -1
		return
	end
	local count = thisCell.number
	local directions = getPossibleDirections(x,y)
	local unflagged = {}
	for i=1,#directions do
		local thisDirection = directions[i]
		local newX = x+thisDirection[1]
		local newY = y+thisDirection[2]
		local thisDirectionCell = field[newX][newY] 
		if thisDirectionCell.flagged then count = count - 1
		elseif not thisDirectionCell.opened then table.insert(unflagged, {newX, newY})  
		end
	end
	if count == 0 then
		for i=1,#unflagged do
			local nextCell = unflagged[i]	
			local cell = field[nextCell[1]][nextCell[2]]
			if not singleOpen or cell.number == 0 then 
				open(nextCell[1],nextCell[2])
			else 
				cell.opened = true
				field[nextCell[1]][nextCell[2]] = cell
			end
		end
	end
end
function calculateScreenValues()
	local cellWidth = (width - margin * 2) / fieldWidth 
	local cellHeight = (height - margin * 2) / fieldHeight
	cellSize = math.min(cellWidth, cellHeight)
	cellBorder = cellSize / 10
	doubleCellBorder = cellBorder * 2
	cellFont = love.graphics.newFont(cellSize - cellBorder)
	halfCellSize = cellSize / 2
	fieldViewWidth = cellSize*fieldWidth
	fieldViewHeight = cellSize*fieldHeight
	widthOffset = (width - fieldViewWidth) / 2
	heightOffset = (height - fieldViewHeight) / 2
end
function love.load()
	width = 960
	height = 540
	love.window.setMode(960,540,{})
	calculateScreenValues()
	love.keyboard.setKeyRepeat(true)
	init()
end
function line(x1,y1,x2,y2)
	love.graphics.line(widthOffset+x1, heightOffset+y1, widthOffset+x2, heightOffset+y2)
end
function rect(mode, x, y, w, h)
	love.graphics.rectangle(mode, widthOffset+x, heightOffset+y, w, h)
end
function circle(mode, x, y, r)
	love.graphics.circle(mode, widthOffset+x, heightOffset+y, r)
end
function text(text, x, y)
	love.graphics.print(text, widthOffset+x, heightOffset+y)
end
function color(r,g,b)
	love.graphics.setColor(r,g,b,1)
end
gameContinueText = "Game is still in progress"
gameWonText = "You have won!"
gameLostText = "You have exploded"
minesText = "Mines:"
function love.draw()
	love.graphics.setFont(textFont)
	love.graphics.setColor(1,1,1)
	love.graphics.print(gameResult == 0 and gameContinueText or (gameResult == 1 and gameWonText or gameLostText),0,0)
	love.graphics.print(minesText .. flagCount .. "/" .. mineCount, 0, height - textSize * 4)
	love.graphics.setFont(cellFont)
	for i=1,fieldWidth do
		for j=1,fieldHeight do
			local cellX = (i-1) * cellSize
			local cellY = (j-1) * cellSize
			love.graphics.setColor(0.5,0.5,0.5)
			rect("fill", cellX, cellY, cellSize, cellSize) --cell border 
			local thisCell = field[i][j]
			if thisCell.opened then love.graphics.setColor(1,1,1) else love.graphics.setColor(0,0,0) end 
			local cellInnerX = cellX + cellBorder
			local cellInnerY = cellY + cellBorder
			rect("fill", cellInnerX, cellInnerY, cellSize - doubleCellBorder, cellSize - doubleCellBorder) --cell inner square 
			if thisCell.opened then 
				if thisCell.mine then
					color(0,0,0)
					circle("fill", cellX+halfCellSize, cellY+halfCellSize, cellSize/2-cellBorder)
				else
					color(0,0,0)	
					local thisCellNumber = thisCell.number
					if thisCellNumber ~= 0 then text(thisCellNumber, cellX + halfCellSize / 2, cellY) end
				end
			else
				if thisCell.flagged then
					local cellInnerSize = cellSize - cellBorder
					local cellInnerLowerX = cellX + cellInnerSize 
					local cellInnerLowerY = cellY + cellInnerSize 
					color(1,0,0)
					line(cellInnerX, cellInnerY, cellInnerLowerX, cellInnerLowerY)
					line(cellInnerX, cellInnerLowerY, cellInnerLowerX, cellInnerY)
				end
			end
		end
	end
end
function love.mousepressed(x,y,button,istouch)
	if button == 1 or button == 2 then
		if gameResult == 0 then 
			if ( x > widthOffset and x < widthOffset + fieldViewWidth ) and ( y > heightOffset and y < heightOffset + fieldViewHeight ) then
				local fieldX = math.floor((x - widthOffset) / cellSize) + 1
				local fieldY = math.floor((y - heightOffset) / cellSize) + 1
				local cell = field[fieldX][fieldY]
				if button == 1 then
					if firstPress then
						firstPress = false
						firstPressX = fieldX
						firstPressY = fieldY
						spawnMines(mineCount)
						setNumbers()
					end
					open(fieldX,fieldY,cell.opened)
					checkAllOpened()
				elseif not cell.opened then
					cell.flagged = not cell.flagged
					flagCount = flagCount + (cell.flagged and 1 or -1)
					checkAllFlagged()
				end
			end
		else
			init()
		end
	end	
end
function maxMineCount() return fieldWidth * fieldHeight - ((fieldWidth < 3 and fieldWidth or 3) * (fieldHeight < 3 and fieldHeight or 3)) end
function limitMineCount()
	local max = maxMineCount()
	if mineCount > max then mineCount = max end
end
function love.keypressed(key, scancode, isrepeat)
	if key == "c" then
		for i=1,fieldWidth do
			for j=1,fieldHeight do
				local thisCell = field[i][j]
				thisCell.opened = not thisCell.opened  
				field[i][j] = thisCell
			end
		end
	elseif firstPress then
		if key == "m" and mineCount < maxMineCount() then mineCount = mineCount + 1 
		elseif key == "l" and mineCount > 1 then mineCount = mineCount - 1 
		else
			if key == "s" then fieldHeight = fieldHeight + 1
			elseif key == "d" then fieldWidth = fieldWidth + 1
			else
				if key == "w" and fieldHeight > 1 then fieldHeight = fieldHeight - 1 
				elseif key == "a" and fieldWidth > 1 then fieldWidth = fieldWidth - 1 end
				limitMineCount()
			end
			init()
			calculateScreenValues()
		end
	end
end

