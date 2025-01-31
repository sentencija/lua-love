local mineCountParamName = "Mine count"
local basicModule = {
	params = {
		mine = {
			[mineCountParamName] = function (w, h, params)
				return {min = 1, max = w * h - (w<3 and w or 3) * (h<3 and h or 3)}
			end
		},
		empty = {},
		draw = {
			size = {1,1},
			backgroundColor = {1,1,1},
			borderColor = {0.5,0.5,0.5}
		}
	}
}
function getModuleObject() return basicModule end		
function basicModule.init(w, h, firstClickPosition, mineParams, emptyParams)
	local firstClickX = firstClickPosition[1]
	local firstClickY = firstClickPosition[2]
	local cells = basicModule.getCellSet(w, h, firstClickX, firstClickY) 
	local field = basicModule.createField(w, h)
	local dangerous = {}
	for i=1,mineParams[mineCountParamName] do
		local chosenCell = table.remove(cells, math.random(#cells))
		field[chosenCell[1]][chosenCell[2]].mine = true
		table.insert(dangerous, chosenCell)
	end
	local startAdjacent = basicModule.getAdjacentCells(firstClickX, firstClickY, w, h)
	table.insert(startAdjacent, firstClickPosition)
	for i=1,#startAdjacent do table.insert(cells, startAdjacent[i]) end
	for i=1,#cells do
		local thisCell = cells[i]
		local counter = 0
		local thisCellX = thisCell[1]
		local thisCellY = thisCell[2]
		local adjacent = basicModule.getAdjacentCells(thisCellX, thisCellY, w, h)
		for j=1,#adjacent do
			local thisAdjacent = adjacent[j]
			if field[thisAdjacent[1]][thisAdjacent[2]].mine then counter = counter + 1 end
		end
		field[thisCellX][thisCellY].number = counter
	end
	return field, dangerous 
end
function basicModule.emptyCheck(x, y, field)
	local c = field[x][y]
	if c.number == nil then return {} end
	local adjacent = basicModule.getAdjacentCells(x, y, #field, #field[1])
	local result = {}
	local counter = c.number 
	print("counter " .. counter)
	if counter == 0 then 
		for i=1,#adjacent do
			table.insert(result, adjacent[i])
		end
		return result
	end
	for i=1,#adjacent do
		local cell = adjacent[i]
		local cellX = cell[1]
		local cellY = cell[2]
		if cell.mine then break end
		if minesweeper.global.isFlagged(cellX, cellY) then 
			counter = counter - 1
		elseif not minesweeper.global.isOpened(cellX, cellY) then
			table.insert(result, cell)
		end
	end
	print("counter after " .. counter)
	if counter ~= 0 then return {} end
	return result
end
function basicModule.createField(w, h)
	local field = {}
	for i=1,w do
		local line = {}
		for j=1,h do table.insert(line, {}) end
		table.insert(field, line)
	end
	return field
end
function basicModule.getCellSet(w, h, firstClickX, firstClickY)
	local firstClickAdjacentCells = basicModule.getAdjacentCells(firstClickX, firstClickY, w, h)
	table.insert(firstClickAdjacentCells, {firstClickX, firstClickY})
	local possibleCells = {}
	for i=1,w do
		for j=1,h do
			local skip = false
			for k=1,#firstClickAdjacentCells do
				local cell = firstClickAdjacentCells[k]
				if cell[1] == i and cell[2] == j then
					skip = true
					break
				end
			end
			if not skip then 
				table.insert(possibleCells, {i,j})
			end
		end
	end
	return possibleCells
end
function basicModule.getAdjacentCells(x,y,w,h)
	local possibleXDirections = {}
	if x ~= 1 then table.insert(possibleXDirections, -1) end
	if x ~= w then table.insert(possibleXDirections, 1) end
	local possibleYDirections = {}
	if y ~= 1 then table.insert(possibleYDirections, -1) end
	if y ~= h then table.insert(possibleYDirections, 1) end
	local result = {}
	for i=1,#possibleYDirections do table.insert(result, {0,possibleYDirections[i]}) end
	for i=1,#possibleXDirections do
		local xDirection = possibleXDirections[i]
		table.insert(result, {xDirection, 0})
		for j=1,#possibleYDirections do table.insert(result, {xDirection, possibleYDirections[j]}) end
	end
	for i=1,#result do
		local direction = result[i]
		direction[1] = direction[1] + x
		direction[2] = direction[2] + y
	end
	return result
end

function basicModule.drawSmall(cell, x, y, w)
	local cellNumber = cell.number
	if cell.mine then drawMine(x, y, w)
	elseif cellNumber ~= 0 then drawNumber(x, y, w, cellNumber)
	end
end
local sqrt2 = math.sqrt(2)
function drawMine(x, y, w)
	love.graphics.setColor(0,0,0)
	local halfW = w / 2 
	local centerX = x + halfW
	local centerY = y + halfW
	local sqrt2W = halfW / sqrt2
	love.graphics.circle("fill", centerX, centerY, halfW * 9 / 10)
	local leftX = centerX - sqrt2W
	local topY = centerY - sqrt2W
	local rightX = centerX + sqrt2W
	local botY = centerY + sqrt2W
	love.graphics.line(leftX, topY, rightX, botY)
	love.graphics.line(leftX, botY, rightX, topY)
	love.graphics.line(x, centerY, x+w, centerY)
	love.graphics.line(centerX, y, centerX, y+w)
end
local fonts = {}
function drawNumber(x, y, w, number)
	setFont(w)
	love.graphics.setColor(0,0,0)
	love.graphics.print(number, x + w/3, y)
end
function setFont(size)
	if fonts[size] == nil then fonts[size] = love.graphics.newFont(size) end
	love.graphics.setFont(fonts[size])
end
function basicModule.drawBig(cell, x, y, w, h)
	love.graphics.setColor(0,0,0)
	setFont(math.min(w,h))
	love.graphics.print(cell.number, x, y)
end

