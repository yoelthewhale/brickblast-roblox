local Blocks = require(script.Parent.Blocks)
local Config = require(script.Parent.Config)
local VisualTokens = require(script.Parent.VisualTokens)

local BlocksTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local tests = {}

-- The invariant that actually matters, and the reason the diagonal shapes were
-- removed rather than merely renamed.
--
-- A piece whose cells touch only at their corners reads on the board as
-- several separate pieces, which fights a game about filling rows with solids.
-- Checking connectivity structurally means a future shape cannot reintroduce
-- the defect under a different id -- which a hardcoded list of banned names
-- would not have caught.
tests.everyShapeIsEdgeConnected = function()
	for _, shape in Blocks.Shapes do
		local occupied = {}
		for _, cell in shape.cells do
			occupied[`{cell.X}:{cell.Y}`] = cell
		end

		-- Flood fill from the first cell through shared edges only.
		local first = shape.cells[1]
		assertCondition(first ~= nil, `Shape {shape.id} has no cells`)

		local seen = {}
		local queue = { first }
		seen[`{first.X}:{first.Y}`] = true
		local head = 1
		while head <= #queue do
			local current = queue[head]
			head += 1
			local neighbours = {
				{ current.X + 1, current.Y },
				{ current.X - 1, current.Y },
				{ current.X, current.Y + 1 },
				{ current.X, current.Y - 1 },
			}
			for _, offset in neighbours do
				local key = `{offset[1]}:{offset[2]}`
				if occupied[key] and not seen[key] then
					seen[key] = true
					table.insert(queue, occupied[key])
				end
			end
		end

		local reached = 0
		for _ in seen do
			reached += 1
		end
		assertCondition(
			reached == #shape.cells,
			`Shape {shape.id} is not edge-connected: reached {reached} of {#shape.cells} cells. `
				.. "Cells touching only at corners read as separate pieces on the board."
		)
	end
end

tests.noShapeIsEmptyOrDuplicated = function()
	local seenIds = {}
	for _, shape in Blocks.Shapes do
		assertCondition(typeof(shape.id) == "string" and #shape.id > 0, "A shape has no id")
		assertCondition(seenIds[shape.id] == nil, `Duplicate shape id: {shape.id}`)
		seenIds[shape.id] = true
		assertCondition(#shape.cells > 0, `Shape {shape.id} has no cells`)

		local seenCells = {}
		for _, cell in shape.cells do
			local key = `{cell.X}:{cell.Y}`
			assertCondition(seenCells[key] == nil, `Shape {shape.id} lists cell {key} twice`)
			seenCells[key] = true
		end
	end
end

-- A shape that cannot fit an empty board is unplaceable the moment it is
-- dealt, which reads to the player as the game freezing rather than as a hard
-- piece.
tests.everyShapeFitsAnEmptyBoard = function()
	for _, shape in Blocks.Shapes do
		local maxX, maxY = 0, 0
		for _, cell in shape.cells do
			maxX = math.max(maxX, cell.X)
			maxY = math.max(maxY, cell.Y)
		end
		assertCondition(
			maxX < Config.BoardSize and maxY < Config.BoardSize,
			`Shape {shape.id} spans {maxX + 1}x{maxY + 1} and cannot fit a {Config.BoardSize} board`
		)
	end
end

-- Hand generation reads these tables by shape id. An entry naming a shape that
-- no longer exists is dead weight that silently stops doing anything, which is
-- exactly how `plus` survived its own removal until this test existed.
tests.handGenerationOnlyNamesRealShapes = function()
	local known = {}
	for _, shape in Blocks.Shapes do
		known[shape.id] = true
	end

	for _, listName in { "FlexibleShapeIds", "RestrictiveShapeIds" } do
		local list = Config.HandGeneration[listName]
		assertCondition(typeof(list) == "table", `Config.HandGeneration.{listName} is missing`)
		for shapeId in list do
			assertCondition(
				known[shapeId] == true,
				`Config.HandGeneration.{listName} names "{shapeId}", which is not a real shape`
			)
		end
	end
end

tests.theApprovedFamiliesAreAllPresent = function()
	local known = {}
	for _, shape in Blocks.Shapes do
		known[shape.id] = true
	end

	-- One representative per family Yoel approved. This is not the full set --
	-- rotations are generated -- but losing any of these means losing a family.
	local required = {
		"single",
		"line2",
		"line3",
		"line4",
		"square2",
		"corner",
		"tShape",
		"sShape",
		"zShape",
		"jShape",
		"lShape",
		"rect2x3",
	}
	for _, shapeId in required do
		assertCondition(known[shapeId] == true, `The approved piece set is missing "{shapeId}"`)
	end
end

-- A piece is dealt ONE colour, and it comes from the identity palette.
--
-- Both halves of this were broken and neither was visible to any test.
-- `randomPieceColor` generated a random hue across the whole wheel, so pieces
-- could arrive lime or magenta -- colours that exist nowhere else in the game.
-- It went unnoticed because the Solo renderer discarded the piece's colour and
-- computed one from the cell's x/y instead, so the real value never reached
-- the screen in the only mode anyone plays.
tests.everyPieceIsDealtOneColourFromThePalette = function()
	local palette = VisualTokens.blockPalette()

	local function isPaletteColour(color)
		for _, entry in palette do
			if entry == color then
				return true
			end
		end
		return false
	end

	for seed = 1, 120 do
		local randomizer = Random.new(seed)
		local shape = Blocks.createShape(Blocks.Shapes[1].id, randomizer)
		assertCondition(
			typeof(shape.color) == "Color3",
			`Piece at seed {seed} was dealt no colour at all`
		)
		assertCondition(
			isPaletteColour(shape.color),
			`Piece at seed {seed} was dealt a colour outside the identity palette. `
				.. "Pieces must be one of the five block colours, not an arbitrary hue."
		)
	end
end

-- Over enough deals the palette should actually get used, not collapse onto
-- one entry. A generator that always returned palette[1] would satisfy the
-- test above while making every piece on the board the same colour.
tests.pieceColoursActuallyVary = function()
	local seen = {}
	local distinct = 0
	for seed = 1, 300 do
		local shape = Blocks.createShape(Blocks.Shapes[1].id, Random.new(seed))
		local key = tostring(shape.color)
		if not seen[key] then
			seen[key] = true
			distinct += 1
		end
	end

	assertCondition(
		distinct >= 4,
		`Only {distinct} distinct piece colours appeared across 300 deals; the palette `
			.. "is collapsing rather than being used"
	)
end

function BlocksTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return BlocksTests
