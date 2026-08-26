local Blocks = require(script.Parent.Blocks)
local Config = require(script.Parent.Config)
local Grid = require(script.Parent.Grid)

local GridTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local function countCells(cells)
	local count = 0
	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			if cells[y] and cells[y][x] then
				count += 1
			end
		end
	end
	return count
end

local function assertCell(cells, x, y, expected, message)
	assertCondition((cells[y] and cells[y][x] == true) == expected, message)
end

local function assertBoardEquals(left, right, message)
	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			assertCondition(left[y][x] == right[y][x], `{message} at {x},{y}`)
		end
	end
end

local function fillRowExcept(board, y, openX)
	for x = 1, Config.BoardSize do
		board[y][x] = if x == openX then false else "filled"
	end
end

local function fillColumnExcept(board, x, openY)
	for y = 1, Config.BoardSize do
		board[y][x] = if y == openY then false else "filled"
	end
end

local function shape(shapeId)
	local generated = Blocks.createShape(shapeId, Random.new(42), "Rainbow")
	assertCondition(generated ~= nil, `Expected {shapeId} to be generated`)
	return generated
end

local tests = {}

tests.validPlacementCanClearNothing = function()
	local board = Grid.create()
	local cells, rows, columns = Grid.clearPreviewCells(board, shape("single"), 4, 4)

	assertCondition(cells ~= nil, "Valid placement should return a preview set")
	assertCondition(#rows == 0, "Empty board single placement should clear no rows")
	assertCondition(#columns == 0, "Empty board single placement should clear no columns")
	assertCondition(countCells(cells) == 0, "No-clear placement should highlight no cells")
end

tests.previewCompletesOneRow = function()
	local board = Grid.create()
	fillRowExcept(board, 3, 4)

	local cells, rows, columns = Grid.clearPreviewCells(board, shape("single"), 4, 3)

	assertCondition(#rows == 1 and rows[1] == 3, "Expected row 3 to preview clear")
	assertCondition(#columns == 0, "Expected no column clear")
	assertCondition(
		countCells(cells) == Config.BoardSize,
		"One row should highlight exactly 8 cells"
	)
	for x = 1, Config.BoardSize do
		assertCell(cells, x, 3, true, `Expected row preview cell {x},3`)
	end
end

tests.previewCompletesOneColumn = function()
	local board = Grid.create()
	fillColumnExcept(board, 5, 6)

	local cells, rows, columns = Grid.clearPreviewCells(board, shape("single"), 5, 6)

	assertCondition(#rows == 0, "Expected no row clear")
	assertCondition(#columns == 1 and columns[1] == 5, "Expected column 5 to preview clear")
	assertCondition(
		countCells(cells) == Config.BoardSize,
		"One column should highlight exactly 8 cells"
	)
	for y = 1, Config.BoardSize do
		assertCell(cells, 5, y, true, `Expected column preview cell 5,{y}`)
	end
end

tests.previewCompletesMultipleRows = function()
	local board = Grid.create()
	fillRowExcept(board, 2, 8)
	fillRowExcept(board, 3, 8)

	local cells, rows, columns = Grid.clearPreviewCells(board, shape("vertical2"), 8, 2)

	assertCondition(#rows == 2 and rows[1] == 2 and rows[2] == 3, "Expected rows 2 and 3")
	assertCondition(#columns == 0, "Expected no column clear")
	assertCondition(countCells(cells) == Config.BoardSize * 2, "Two rows should highlight 16 cells")
end

tests.previewCompletesMultipleColumns = function()
	local board = Grid.create()
	fillColumnExcept(board, 2, 8)
	fillColumnExcept(board, 3, 8)

	local cells, rows, columns = Grid.clearPreviewCells(board, shape("line2"), 2, 8)

	assertCondition(#rows == 0, "Expected no row clear")
	assertCondition(
		#columns == 2 and columns[1] == 2 and columns[2] == 3,
		"Expected columns 2 and 3"
	)
	assertCondition(
		countCells(cells) == Config.BoardSize * 2,
		"Two columns should highlight 16 cells"
	)
end

tests.previewCompletesRowAndColumnWithoutDuplicateIntersection = function()
	local board = Grid.create()
	fillRowExcept(board, 4, 4)
	fillColumnExcept(board, 4, 4)

	local cells, rows, columns = Grid.clearPreviewCells(board, shape("single"), 4, 4)

	assertCondition(#rows == 1 and rows[1] == 4, "Expected row 4")
	assertCondition(#columns == 1 and columns[1] == 4, "Expected column 4")
	assertCondition(
		countCells(cells) == Config.BoardSize * 2 - 1,
		"Row and column intersection should be one highlighted cell, not a duplicate"
	)
	assertCell(cells, 4, 4, true, "Expected the intersection cell to be highlighted")
end

tests.invalidPlacementProducesNoPreview = function()
	local board = Grid.create()
	board[1][1] = "filled"

	local cells, rows, columns = Grid.clearPreviewCells(board, shape("single"), 1, 1)

	assertCondition(cells == nil, "Invalid placement should not return preview cells")
	assertCondition(rows == nil, "Invalid placement should not return rows")
	assertCondition(columns == nil, "Invalid placement should not return columns")
end

tests.previewDoesNotMutateTheRealBoard = function()
	local board = Grid.create()
	fillRowExcept(board, 6, 2)
	local before = Grid.clone(board)

	Grid.clearPreviewCells(board, shape("single"), 2, 6)

	assertBoardEquals(board, before, "Clear preview must not mutate the real board")
end

tests.movingHoverChangesThePredictedClear = function()
	local board = Grid.create()
	fillRowExcept(board, 7, 8)

	local noClearCells, noClearRows = Grid.clearPreviewCells(board, shape("single"), 8, 6)
	local clearCells, clearRows = Grid.clearPreviewCells(board, shape("single"), 8, 7)

	assertCondition(#noClearRows == 0, "Hovering a non-clearing cell should remove row prediction")
	assertCondition(countCells(noClearCells) == 0, "Non-clearing hover should highlight no cells")
	assertCondition(
		#clearRows == 1 and clearRows[1] == 7,
		"Moving hover onto the gap should predict row 7"
	)
	assertCondition(
		countCells(clearCells) == Config.BoardSize,
		"Clearing hover should highlight row 7"
	)
end

tests.previewMatchesActualPlacementAndClear = function()
	local board = Grid.create()
	fillRowExcept(board, 8, 6)
	fillColumnExcept(board, 6, 8)
	local previewCells = Grid.clearPreviewCells(board, shape("single"), 6, 8)

	local placed = Grid.place(board, shape("single"), 6, 8)
	assertCondition(placed == true, "Expected actual placement to be valid")
	local linesCleared = Grid.clearLines(board)

	assertCondition(
		countCells(previewCells) == Config.BoardSize * 2 - 1,
		"Expected row plus column preview"
	)
	assertCondition(linesCleared == 2, "Actual clear should match the predicted row plus column")
end

function GridTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return GridTests
