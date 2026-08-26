local Blocks = require(script.Parent.Blocks)
local Config = require(script.Parent.Config)
local Grid = require(script.Parent.Grid)

local GridTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local FILL = Color3.fromRGB(200, 100, 100)

local function shapeFrom(cells)
	local made = {}
	for _, cell in cells do
		table.insert(made, Vector2.new(cell[1], cell[2]))
	end
	return { id = "test", cells = made, color = FILL }
end

local SINGLE = shapeFrom({ { 0, 0 } })

-- Fills the whole board, then empties the listed coordinates. Used only where
-- a densely packed board is the point; note that a board this full completes
-- *every* line at once, so it is the wrong tool for isolating one.
local function boardWithHoles(holes)
	local board = Grid.create()
	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			board[y][x] = FILL
		end
	end
	for _, hole in holes do
		board[hole[2]][hole[1]] = false
	end
	return board
end

-- Fills one row, leaving a single gap. Everything else stays empty, so the
-- only line that can complete is this one. Isolating lines this way is what
-- makes "two rows completed" a real assertion rather than a side effect of
-- having filled the entire board.
local function fillRowExcept(board, y, gapX)
	for x = 1, Config.BoardSize do
		board[y][x] = if x == gapX then false else FILL
	end
	return board
end

local function fillColumnExcept(board, x, gapY)
	for y = 1, Config.BoardSize do
		board[y][x] = if y == gapY then false else FILL
	end
	return board
end

local function countCells(cells)
	local total = 0
	for _, row in cells do
		for _ in row do
			total += 1
		end
	end
	return total
end

local function snapshot(board)
	local rows = {}
	for y = 1, Config.BoardSize do
		local row = {}
		for x = 1, Config.BoardSize do
			row[x] = tostring(board[y][x])
		end
		rows[y] = table.concat(row, ",")
	end
	return table.concat(rows, "|")
end

local tests = {}

-- 1. A legal placement that completes nothing must preview nothing.
tests.aPlacementThatClearsNothingPreviewsNothing = function()
	local board = Grid.create()
	assertCondition(
		Grid.clearPreviewCells(board, SINGLE, 3, 3) == nil,
		"An empty board cannot complete a line, so there is nothing to preview"
	)
end

-- 2. One row.
tests.completingOneRowPreviewsThatRow = function()
	local board = fillRowExcept(Grid.create(), 2, 4)
	local cells, rows, columns = Grid.clearPreviewCells(board, SINGLE, 4, 2)
	assertCondition(cells ~= nil, "Filling the last hole in row 2 should preview a clear")
	assertCondition(#rows == 1 and rows[1] == 2, "Row 2 should be the completed row")
	assertCondition(#columns == 0, "No column should complete")
	assertCondition(
		countCells(cells) == Config.BoardSize,
		`One row should highlight {Config.BoardSize} cells, got {countCells(cells)}`
	)
end

-- 3. One column.
tests.completingOneColumnPreviewsThatColumn = function()
	local board = fillColumnExcept(Grid.create(), 5, 3)
	local cells, rows, columns = Grid.clearPreviewCells(board, SINGLE, 5, 3)
	assertCondition(cells ~= nil, "Filling the last hole in column 5 should preview a clear")
	assertCondition(#columns == 1 and columns[1] == 5, "Column 5 should be the completed column")
	assertCondition(#rows == 0, "No row should complete on an otherwise empty board")
	assertCondition(
		countCells(cells) == Config.BoardSize,
		`One column should highlight {Config.BoardSize} cells, got {countCells(cells)}`
	)
end

-- 4. Multiple rows at once.
tests.completingMultipleRowsPreviewsAllOfThem = function()
	local board = Grid.create()
	fillRowExcept(board, 4, 2)
	fillRowExcept(board, 5, 2)
	local vertical = shapeFrom({ { 0, 0 }, { 0, 1 } })
	local cells, rows, columns = Grid.clearPreviewCells(board, vertical, 2, 4)
	assertCondition(cells ~= nil, "A piece filling both holes should preview a clear")
	assertCondition(#rows == 2, `Two rows should complete, got {#rows}`)
	assertCondition(#columns == 0, "No column should complete here")
	assertCondition(
		countCells(cells) == Config.BoardSize * 2,
		`Two full rows should highlight {Config.BoardSize * 2} cells, got {countCells(cells)}`
	)
end

-- 5. Multiple columns at once.
tests.completingMultipleColumnsPreviewsAllOfThem = function()
	local board = Grid.create()
	fillColumnExcept(board, 3, 7)
	fillColumnExcept(board, 4, 7)
	local horizontal = shapeFrom({ { 0, 0 }, { 1, 0 } })
	local cells, rows, columns = Grid.clearPreviewCells(board, horizontal, 3, 7)
	assertCondition(cells ~= nil, "A piece filling both holes should preview a clear")
	assertCondition(#columns == 2, `Two columns should complete, got {#columns}`)
	assertCondition(#rows == 0, "No row should complete here")
end

-- 6 and 7. A row and a column together, and the cell where they cross counted
-- once. Double-counting an intersection is invisible in a list and obvious on
-- screen: a translucent highlight drawn twice reads as a bright square at
-- every crossing.
tests.aRowAndColumnTogetherShareTheirIntersection = function()
	local board = Grid.create()
	fillRowExcept(board, 6, 6)
	fillColumnExcept(board, 6, 6)
	local cells, rows, columns = Grid.clearPreviewCells(board, SINGLE, 6, 6)
	assertCondition(#rows == 1 and #columns == 1, "Both a row and a column should complete")

	-- 8 + 8 cells minus the one they share.
	local expected = Config.BoardSize * 2 - 1
	assertCondition(
		countCells(cells) == expected,
		`A crossing row and column should highlight {expected} distinct cells, `
			.. `got {countCells(cells)}`
	)
	assertCondition(cells[6][6] == true, "The intersection itself must be highlighted")
end

-- 8. An illegal placement previews nothing, whatever the board looks like.
tests.anIllegalPlacementPreviewsNothing = function()
	local board = fillRowExcept(Grid.create(), 2, 4)
	-- Directly on top of an occupied cell.
	assertCondition(
		Grid.clearPreviewCells(board, SINGLE, 1, 2) == nil,
		"Placing onto an occupied cell is illegal and must preview nothing"
	)
	-- Off the edge of the board.
	assertCondition(
		Grid.clearPreviewCells(board, SINGLE, Config.BoardSize + 1, 2) == nil,
		"Placing off the board is illegal and must preview nothing"
	)
	assertCondition(
		Grid.linesCompletedByPlacement(board, SINGLE, 1, 2) == nil,
		"The line query itself should refuse an illegal placement"
	)
end

-- 9. THE INVARIANT. Preview is a question, never a move.
--
-- This is the failure that would be worst and quietest: a preview that writes
-- to the board would place blocks, clear lines and award score from a hover.
-- Compared against a full snapshot rather than a spot check, because a
-- single stray write anywhere on the board is the whole bug.
tests.previewingNeverMutatesTheBoard = function()
	local board = boardWithHoles({ { 6, 6 }, { 2, 4 }, { 2, 5 } })
	local before = snapshot(board)

	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			Grid.clearPreviewCells(board, SINGLE, x, y)
			Grid.linesCompletedByPlacement(board, SINGLE, x, y)
			Grid.completedLines(board)
		end
	end

	assertCondition(
		snapshot(board) == before,
		"Previewing modified the board. A preview must never be able to place a block, "
			.. "clear a line, or change a single cell."
	)
end

-- 10. Moving the hover recalculates, including back to nothing.
tests.movingTheHoverChangesAndClearsThePrediction = function()
	local board = Grid.create()
	fillRowExcept(board, 2, 4)
	fillRowExcept(board, 5, 7)

	local atFour = Grid.clearPreviewCells(board, SINGLE, 4, 2)
	assertCondition(atFour ~= nil, "Hovering the hole in row 2 should predict a clear")

	local atSeven = Grid.clearPreviewCells(board, SINGLE, 7, 5)
	assertCondition(atSeven ~= nil, "Hovering the hole in row 5 should predict a different clear")
	assertCondition(
		atFour[2] ~= nil and atSeven[2] == nil,
		"Moving the hover must produce a different set, not the previous one"
	)

	-- Somewhere legal that completes nothing: the prediction must go away
	-- rather than linger from the previous position.
	local empty = Grid.create()
	assertCondition(
		Grid.clearPreviewCells(empty, SINGLE, 4, 2) == nil,
		"A hover that completes nothing must clear the prediction, not keep the last one"
	)
end

-- The preview and the real clear must agree. Not "look similar" -- agree
-- exactly, on every board a real piece can produce. If these ever diverge the
-- game lights up lines it then does not clear, which is worse than no preview.
tests.thePreviewMatchesWhatPlacementActuallyClears = function()
	local checked = 0
	local clearing = 0

	for seed = 1, 90 do
		local randomizer = Random.new(seed * 31)
		local board = Grid.create()

		-- Boards are *constructed* near a clear rather than filled at random.
		-- Uniform random fill almost never leaves a line one cell short, so a
		-- purely random sweep spends its whole time agreeing that nothing
		-- clears -- which the `clearing` counter below caught when this was
		-- written the naive way.
		for _ = 1, randomizer:NextInteger(1, 2) do
			fillRowExcept(
				board,
				randomizer:NextInteger(1, Config.BoardSize),
				randomizer:NextInteger(1, Config.BoardSize)
			)
		end
		for _ = 1, randomizer:NextInteger(0, 2) do
			fillColumnExcept(
				board,
				randomizer:NextInteger(1, Config.BoardSize),
				randomizer:NextInteger(1, Config.BoardSize)
			)
		end
		-- Scatter on top so the near-complete lines are not the only thing on
		-- the board and placements have to contend with real clutter.
		for _ = 1, randomizer:NextInteger(0, 14) do
			board[randomizer:NextInteger(1, Config.BoardSize)][randomizer:NextInteger(
				1,
				Config.BoardSize
			)] =
				FILL
		end

		local shape = Blocks.createShape(
			Blocks.Shapes[randomizer:NextInteger(1, #Blocks.Shapes)].id,
			randomizer
		)

		for y = 1, Config.BoardSize do
			for x = 1, Config.BoardSize do
				if Grid.canPlace(board, shape, x, y) then
					local _, rows, columns = Grid.clearPreviewCells(board, shape, x, y)
					local predicted = (rows and #rows or 0) + (columns and #columns or 0)

					-- Play it out for real on a copy and compare.
					local copy = Grid.create()
					for cy = 1, Config.BoardSize do
						for cx = 1, Config.BoardSize do
							copy[cy][cx] = board[cy][cx]
						end
					end
					Grid.place(copy, shape, x, y)
					local actual = Grid.clearLines(copy)

					assertCondition(
						predicted == actual,
						`Preview predicted {predicted} lines at ({x},{y}) but placing actually `
							.. `cleared {actual}. The preview and the clear must never disagree.`
					)
					checked += 1
					if actual > 0 then
						clearing += 1
					end
				end
			end
		end
	end

	assertCondition(checked > 500, `Only {checked} placements were compared; the sweep is too thin`)
	-- Without this the sweep could compare hundreds of placements that clear
	-- nothing and agree perfectly on zero, proving nothing about the case the
	-- whole feature exists for.
	assertCondition(
		clearing > 20,
		`The sweep only exercised {clearing} line-clearing placements. Agreement on `
			.. "boards that never clear is not evidence the preview is right."
	)
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
