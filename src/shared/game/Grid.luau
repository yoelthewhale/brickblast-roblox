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

-- Which rows and columns are complete, given an occupancy test.
--
-- The occupancy test is a parameter rather than a hard read of `board` so that
-- the drag preview can ask "what would be complete if this piece were here"
-- without ever building a modified board. That is the whole reason this is
-- shaped this way: the preview and the real clear must never be able to
-- disagree about what counts as a completed line, and the only way to
-- guarantee that is for both to run this exact loop.
--
-- Pure. Reads nothing it is not given, writes nothing at all.
local function findCompletedLines(isOccupied)
	local rows = {}
	local columns = {}

	for y = 1, Config.BoardSize do
		local filled = true
		for x = 1, Config.BoardSize do
			if not isOccupied(x, y) then
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
			if not isOccupied(x, y) then
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

-- The completed lines on the board as it stands. Public because the preview
-- path and anything else that needs to reason about lines should go through
-- the same detection the clear uses.
function Grid.completedLines(board)
	local rows, columns = findCompletedLines(function(x, y)
		return board[y][x] ~= false
	end)
	return rows, columns
end

-- Which lines WOULD complete if `shape` were placed at this origin.
--
-- Never mutates the board and never clones it. A clone would work and would
-- also be the easy way to introduce the exact bug this feature must not have:
-- a copy that drifts from the original, or a "temporary" write that escapes.
-- Instead the piece's cells are held in a lookup and treated as occupied by
-- the shared detection above, so the real board is only ever read.
--
-- Returns nothing when the placement is illegal. An invalid hover must not
-- produce a clear preview, and answering that here means no caller has to
-- remember to check.
function Grid.linesCompletedByPlacement(board, shape, originX, originY)
	if not Grid.canPlace(board, shape, originX, originY) then
		return nil, nil
	end

	local covered = {}
	for _, cell in shape.cells do
		covered[`{originX + cell.X}:{originY + cell.Y}`] = true
	end

	local rows, columns = findCompletedLines(function(x, y)
		return board[y][x] ~= false or covered[`{x}:{y}`] == true
	end)

	return rows, columns
end

-- The set of board coordinates that would light up for this placement.
--
-- A set rather than a list, keyed [y][x], so a cell sitting on both a
-- completed row and a completed column appears once. Deduplicating after the
-- fact would mean the renderer could double-draw an intersection, which on a
-- translucent highlight reads as a brighter square at every crossing.
--
-- Returns nil when nothing would clear, so callers can distinguish "no clear"
-- from "an empty set I should still render".
function Grid.clearPreviewCells(board, shape, originX, originY)
	local rows, columns = Grid.linesCompletedByPlacement(board, shape, originX, originY)
	if not rows or (#rows == 0 and #columns == 0) then
		return nil
	end

	local cells = {}
	local function mark(x, y)
		local row = cells[y]
		if not row then
			row = {}
			cells[y] = row
		end
		row[x] = true
	end

	for _, y in rows do
		for x = 1, Config.BoardSize do
			mark(x, y)
		end
	end
	for _, x in columns do
		for y = 1, Config.BoardSize do
			mark(x, y)
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
