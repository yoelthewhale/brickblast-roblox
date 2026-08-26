local Blocks = require(script.Parent.Blocks)
local Config = require(script.Parent.Config)
local Grid = require(script.Parent.Grid)
local VisualTokens = require(script.Parent.VisualTokens)

local BlocksTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local tests = {}

local function colorKey(color)
	return `{math.floor(color.R * 255 + 0.5)}:{math.floor(color.G * 255 + 0.5)}:{math.floor(
		color.B * 255 + 0.5
	)}`
end

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

tests.placedPiecesKeepOneSolidColor = function()
	local shape = Blocks.createShape("tShape", Random.new(1234), "Rainbow")
	assertCondition(shape ~= nil, "Expected tShape to be created")
	assertCondition(typeof(shape.color) == "Color3", "Generated shape should own one Color3 color")

	local board = Grid.create()
	local placed = Grid.place(board, shape, 3, 3)
	assertCondition(placed == true, "Expected generated shape to place on an empty board")

	for _, cell in shape.cells do
		local x = 3 + cell.X
		local y = 3 + cell.Y
		assertCondition(
			board[y][x] == shape.color,
			`Placed cell {x},{y} should keep the piece color instead of deriving a board-position color`
		)
	end
end

tests.dealtPiecesUseIdentityPalette = function()
	local paletteKeys = {}
	for _, color in VisualTokens.blockPalette() do
		paletteKeys[colorKey(color)] = true
	end

	for _, skin in Blocks.PieceSkins do
		for seed = 1, 20 do
			local shape = Blocks.createShape("line4", Random.new(seed), skin)
			assertCondition(shape ~= nil, "Expected line4 to be created")
			assertCondition(
				paletteKeys[colorKey(shape.color)] == true,
				`Piece skin {skin} generated a color outside the fixed Deep Board block palette`
			)
		end
	end
end

tests.randomDealsUseThePaletteRange = function()
	local seen = {}
	for seed = 1, 300 do
		local shape = Blocks.createShape("single", Random.new(seed), "Rainbow")
		seen[colorKey(shape.color)] = true
	end

	local seenCount = 0
	for _ in seen do
		seenCount += 1
	end

	assertCondition(
		seenCount >= 4,
		"Piece generation should use the palette range, not collapse to one color"
	)
end

-- Both block styles must survive a round trip through a saved profile. A
-- cosmetic id that resolves to nil would render no block at all, which is a
-- blank board rather than an ugly one.
tests.blockStylesResolveSafely = function()
	assertCondition(#Config.BlockStyles >= 2, "There should be at least two block styles")

	local ids = {}
	for _, style in Config.BlockStyles do
		assertCondition(typeof(style.id) == "string" and #style.id > 0, "A style has no id")
		assertCondition(typeof(style.name) == "string" and #style.name > 0, "A style has no name")
		assertCondition(ids[style.id] == nil, `Duplicate block style id: {style.id}`)
		ids[style.id] = true
		assertCondition(
			Config.sanitizeBlockStyle(style.id) == style.id,
			`A real style id should survive sanitizing: {style.id}`
		)
	end

	assertCondition(ids[Config.BlockStyleDefault] == true, "The default style must be a real style")

	for _, bad in { nil, "", "nonsense", 5, true, {} } do
		assertCondition(
			ids[Config.sanitizeBlockStyle(bad)] == true,
			"Garbage input must resolve to a real style, never nil"
		)
	end
end

-- Both styles are kept because Yoel wanted both, not because one supersedes
-- the other. This fails if a future change quietly drops one.
tests.bothClassicAndGemAreAvailable = function()
	local found = {}
	for _, style in Config.BlockStyles do
		found[style.id] = true
	end
	assertCondition(found.gem == true, "The gem style must stay available")
	assertCondition(found.classic == true, "The classic bevel must stay available")
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
