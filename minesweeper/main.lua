fieldWidth = 10
fieldHeight = 10
margin = 100
marginX = 300
textSize = 10
mineCount = 10 
bigCellWidth = 3
bigCellHeight = 3
moduleNames = {
	"basic"
}
visibleModule = moduleNames[1]
modules = {}
for i=1,#moduleNames do
	local moduleName = moduleNames[i]
	require(moduleName)
	modules[moduleName] = {module = getModuleObject()}
end
minesweeper = {
	global = {
		isFlagged = function (x, y)
			return field[x][y].flagged
		end,
		isOpened = function(x,y)
			return field[x][y].opened
		end
	}
}
local function init()
	field = {}
	for i=1,fieldWidth do
		local line = {}
		for j=1,fieldHeight do table.insert(line, {flagged = false, opened = false, mine = false}) end
		table.insert(field, line)
	end
	gameResult = 0
	flagCount = 0
	firstPress = true
	textFont = love.graphics.newFont(textSize)
	cellSelected = nil
end
function runModulesInit()
	local firstPress = {firstPressX, firstPressY}
	for i,j in pairs(modules) do
		j.field, dangerous = j.module.init(fieldWidth, fieldHeight, firstPress, {["Mine count"] = mineCount}, {})
		dumpField(i)
		for k=1,#dangerous do
			local pos = dangerous[k]
			field[pos[1]][pos[2]].mine = true
		end
	end
	constructBigCell()
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
function lose() gameResult = -1 end
function open(x, y)
	local cell = field[x][y]
	cell.opened = true
	if cell.mine then 
		lose()
		return
	end
	for i,j in pairs(modules) do
		local nextCells = j.module.emptyCheck(x,y, j.field)
		print("next size " .. #nextCells)
		while #nextCells ~= 0 do
			local replacement = {}
			for k=1,#nextCells do
				local nextCell = nextCells[k]
				local nextCellX = nextCell[1]
				local nextCellY = nextCell[2]
				local checkedCell = field[nextCellX][nextCellY]
				if not checkedCell.opened and not checkedCell.flagged then 
					field[nextCellX][nextCellY].opened = true
					if field[nextCellX][nextCellY].mine then 
						lose()
						return
					end
					local nextNextCells = j.module.emptyCheck(nextCellX, nextCellY, j.field)
					for o=1,#nextNextCells do
						table.insert(replacement, nextNextCells[o]) 
					end
					
				end
			end
			nextCells = replacement
		end
		break
	end
end
function calculateScreenValues()
	local cellWidth = (width - margin * 3 - marginX) / fieldWidth 
	local cellHeight = (height - margin * 2) / fieldHeight
	cellSize = math.min(cellWidth, cellHeight)
	cellBorder = cellSize / 10
	doubleCellBorder = cellBorder * 2
	cellFont = love.graphics.newFont(cellSize - cellBorder)
	halfCellSize = cellSize / 2
	fieldViewWidth = cellSize*fieldWidth
	fieldViewHeight = cellSize*fieldHeight
	widthOffset = ((width - margin - marginX - fieldViewWidth) / 2) + margin + marginX
	heightOffset = (height - fieldViewHeight) / 2

	local largerBigCellSize = math.max(bigCellWidth, bigCellHeight)
	bigCellMargin = marginX / (10 * largerBigCellSize) 
	bigCellSize = (marginX - bigCellMargin) / largerBigCellSize 
end
function love.load()
	width = 1600 
	height = 900 
	love.window.setMode(width,height,{})
	calculateScreenValues()
	love.keyboard.setKeyRepeat(true)
	init()
end
function color(r,g,b)
	love.graphics.setColor(r,g,b,1)
end
function colorV(v)
	color(v[1],v[2],v[3])
end
function drawCell(cellX,cellY, thisCell, fieldX, fieldY)
	local rect = function (x,y,w,h) love.graphics.rectangle("fill", widthOffset+x, heightOffset+y, w, h) end
	local line = function (x1,y1,x2,y2) love.graphics.line(widthOffset+x1, heightOffset+y1, widthOffset+x2, heightOffset+y2) end
	color(0.5,0.5,0.5)
	rect(cellX, cellY, cellSize, cellSize) --cell border 
	if thisCell.opened then color(1,1,1) else color(0,0,0) end 
	local cellInnerX = cellX + cellBorder
	local cellInnerY = cellY + cellBorder
	rect(cellInnerX, cellInnerY, cellSize - doubleCellBorder, cellSize - doubleCellBorder) --cell inner square 
	if thisCell.opened then 
		local visible = modules[visibleModule]
		local moduleCell = visible.field[fieldX][fieldY]
		visible.module.drawSmall(moduleCell, widthOffset + cellInnerX, heightOffset + cellInnerY, cellSize - doubleCellBorder)
	else
		if thisCell.flagged then
			local cellInnerSize = cellSize - doubleCellBorder 
			local cellInnerUpperX = cellInnerX + cellBorder
			local cellInnerUpperY = cellInnerY + cellBorder
			local cellInnerLowerX = cellX + cellInnerSize 
			local cellInnerLowerY = cellY + cellInnerSize 
			color(1,0,0)
			line(cellInnerUpperX, cellInnerUpperY, cellInnerLowerX, cellInnerLowerY)
			line(cellInnerUpperX, cellInnerLowerY, cellInnerLowerX, cellInnerUpperY)
		end
	end
end
function drawBigCell(cellX, cellY)
	local rect = function(offset) love.graphics.rectangle("fill",offset+margin, offset+margin, marginX-offset*2, marginX-offset*2, cellBorder) end
	color(0.5,0.5,0.5)
	rect(0)
	color(1,1,1)
	rect(cellBorder)
	for i=1,#bigCellComposition do
		local bigCell = bigCellComposition[i]
		local position = bigCell.position
		local bigCellS = bigCellSize + bigCellMargin
		local x = margin + (position[1] - 1) * bigCellS + bigCellMargin
		local y = margin + (position[2] - 1) * bigCellS + bigCellMargin
		local size = bigCell.size
		local w = bigCellS * (size[1] - 1) + bigCellSize
		local h = bigCellS * (size[2] - 1) + bigCellSize
		colorV(bigCell.borderColor)
		love.graphics.rectangle("fill", x, y, w, h, bigCellMargin)
		local innerX = x + bigCellMargin
		local innerY = y + bigCellMargin
		local doubleMargin = bigCellMargin * 2
		local innerW = w - doubleMargin
		local innerH = h - doubleMargin
		colorV(bigCell.backgroundColor)
		love.graphics.rectangle("fill", innerX, innerY, innerW, innerH, bigCellMargin)
		local module = modules[bigCell.module]
		module.module.drawBig(module.field[cellX][cellY], innerX, innerY, innerW, innerH)
	end
end
function constructBigCell()
	local fittingArray = {}
	for i=1,bigCellWidth do
		local line = {}
		for j=1,bigCellHeight do
			table.insert(line, false)
		end
		table.insert(fittingArray, line)
	end
	local moduleCells = {}
	for i,j in pairs(modules) do
		table.insert(moduleCells, {size = j.module.params.draw.size, module = i})
	end
	table.sort(moduleCells, function(a,b) return a.size[1] * a.size[2] > b.size[1] * b.size[2] end)
	local result = {}
	for i=1,#moduleCells do
		local cell = moduleCells[i]
		local found = false
		for j=1,#fittingArray do
			if found then break end
			for k=1,#fittingArray[j] do
				local fits = checkFitting(fittingArray, cell, j, k)
				if fits then
					for o=1,cell.size[1] do
						for p=1,cell.size[2] do
							fittingArray[j+o-1][k+p-1] = true
						end
					end
					local module = cell.module
					local moduleParams = modules[module].module.params.draw
					table.insert(result, {position = {j,k}, size = cell.size, module = module, backgroundColor = moduleParams.backgroundColor, borderColor = moduleParams.borderColor}) 
					found = true
					break
				end
			end
		end
	end
	bigCellComposition = result
end
function checkFitting(array, element, x, y)	
	local elementW = element.size[1]
	local elementH = element.size[2]
	local w = #array
	local h = #array[1]
	if x+elementW > w or y+elementH > h then return false end
	for i=1,elementW do
		local newX = x + i - 1
		for j=1,elementH do
			local newY = y + j - 1
			if array[newX][newY] then return false end
		end
	end
	return true
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
			drawCell(cellX, cellY, field[i][j], i, j)
		end
	end
	if cellSelected ~= nil then
		drawBigCell(cellSelected[1],cellSelected[2])	
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
						runModulesInit()
					end
					open(fieldX,fieldY)
					checkAllOpened()
				else
					if not cell.opened then
						cell.flagged = not cell.flagged
						flagCount = flagCount + (cell.flagged and 1 or -1)
					else
						cellSelected = {fieldX, fieldY}
					end
				end
			end
		else
			init()
		end
	end	
end
function dumpField(moduleName)
	local moduleField = modules[moduleName].field
	for i=1,#moduleField do
		for j=1,#moduleField[i] do
			for k,o in pairs(moduleField[i][j]) do
				print("element" .. i .. "," .. j .. ": " .. tostring(k) .. "=" .. tostring(o))
			end
		end
	end
end
function maxMineCount() return fieldWidth * fieldHeight - ((fieldWidth < 3 and fieldWidth or 3) * (fieldHeight < 3 and fieldHeight or 3)) end
function limitMineCount()
	local max = maxMineCount()
	if mineCount > max then mineCount = max end
end
function possibleSize(decreaseWidth) return fieldWidth + (decreaseWidth and -1 or 0) > 3 or fieldHeight + (decreaseWidth and 0 or -1) > 3 end
function love.keypressed(key, scancode, isrepeat)
	if key == "c" then
		for i=1,fieldWidth do
			for j=1,fieldHeight do
				local thisCell = field[i][j]
				thisCell.opened = not thisCell.opened  
				field[i][j] = thisCell
			end
		end
	elseif key == "r" then
		init()
	elseif firstPress then
		if key == "m" and mineCount < maxMineCount() then mineCount = mineCount + 1 
		elseif key == "l" and mineCount > 1 then mineCount = mineCount - 1 
		else
			if key == "s" then fieldHeight = fieldHeight + 1
			elseif key == "d" then fieldWidth = fieldWidth + 1
			else
				if key == "w" and possibleSize(false) and fieldHeight > 1 then fieldHeight = fieldHeight - 1 
				elseif key == "a" and possibleSize(true) and fieldWidth > 1 then fieldWidth = fieldWidth - 1 end
				limitMineCount()
			end
			init()
			calculateScreenValues()
		end
	end
end
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end
