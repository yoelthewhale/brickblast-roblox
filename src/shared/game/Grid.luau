local Config = require(script.Parent.Config)

local Grid = {}

function Grid.create()
	local board = {}

	for y = 1, Config.BoardSize do
		board[y] = {}
		for x = 1, Config.BoardSize do
			board[y][x] = false
		end
	end

	return board
end

function Grid.clone(board)
	local nextBoard = {}

	for y = 1, Config.BoardSize do
		nextBoard[y] = {}
		for x = 1, Config.BoardSize do
			nextBoard[y][x] = board[y][x]
		end
	end

	return nextBoard
end

function Grid.canPlace(board, shape, originX, originY)
	for _, cell in shape.cells do
		local x = originX + cell.X
		local y = originY + cell.Y

		if x < 1 or x > Config.BoardSize or y < 1 or y > Config.BoardSize then
			return false
		end

		if board[y][x] ~= false then
			return false
		end
	end

	return true
end

function Grid.place(board, shape, originX, originY)
	if not Grid.canPlace(board, shape, originX, originY) then
		return false, 0
	end

	for _, cell in shape.cells do
		local x = originX + cell.X
		local y = originY + cell.Y
		board[y][x] = shape.color
	end

	return true, #shape.cells
end

local function findCompletedLines(board, isOccupied)
	local rows = {}
	local columns = {}

	for y = 1, Config.BoardSize do
		local filled = true
		for x = 1, Config.BoardSize do
			if not isOccupied(board, x, y) then
				filled = false
				break
			end
		end
		if filled then
			table.insert(rows, y)
		end
	end

	for x = 1, Config.BoardSize do
		local filled = true
		for y = 1, Config.BoardSize do
			if not isOccupied(board, x, y) then
				filled = false
				break
			end
		end
		if filled then
			table.insert(columns, x)
		end
	end

	return rows, columns
end

local function boardOccupancy(board, x, y)
	return board[y][x] ~= false
end

local function placedCellLookup(shape, originX, originY)
	local cells = {}
	for _, cell in shape.cells do
		local x = originX + cell.X
		local y = originY + cell.Y
		cells[y] = cells[y] or {}
		cells[y][x] = true
	end
	return cells
end

function Grid.completedLines(board)
	return findCompletedLines(board, boardOccupancy)
end

function Grid.linesCompletedByPlacement(board, shape, originX, originY)
	if not Grid.canPlace(board, shape, originX, originY) then
		return nil
	end

	local placedCells = placedCellLookup(shape, originX, originY)
	return findCompletedLines(board, function(sourceBoard, x, y)
		return sourceBoard[y][x] ~= false or (placedCells[y] and placedCells[y][x] == true)
	end)
end

function Grid.clearPreviewCells(board, shape, originX, originY)
	local rows, columns = Grid.linesCompletedByPlacement(board, shape, originX, originY)
	if not rows then
		return nil
	end

	local cells = {}
	for _, y in rows do
		cells[y] = cells[y] or {}
		for x = 1, Config.BoardSize do
			cells[y][x] = true
		end
	end

	for _, x in columns do
		for y = 1, Config.BoardSize do
			cells[y] = cells[y] or {}
			cells[y][x] = true
		end
	end

	return cells, rows, columns
end

function Grid.clearLines(board)
	local rows, columns = Grid.completedLines(board)

	for _, y in rows do
		for x = 1, Config.BoardSize do
			board[y][x] = false
		end
	end

	for _, x in columns do
		for y = 1, Config.BoardSize do
			board[y][x] = false
		end
	end

	return #rows + #columns
end

function Grid.hasAnyMove(board, hand)
	for _, shape in hand do
		if shape ~= nil then
			for y = 1, Config.BoardSize do
				for x = 1, Config.BoardSize do
					if Grid.canPlace(board, shape, x, y) then
						return true
					end
				end
			end
		end
	end

	return false
end

function Grid.addGarbage(board, amount)
	for _ = 1, amount do
		for y = 1, Config.BoardSize - 1 do
			for x = 1, Config.BoardSize do
				board[y][x] = board[y + 1][x]
			end
		end

		local gap = math.random(1, Config.BoardSize)
		for x = 1, Config.BoardSize do
			board[Config.BoardSize][x] = x == gap and false or "garbage"
		end
	end
end

return Grid
