local Blocks = require(script.Parent.Blocks)
local Config = require(script.Parent.Config)
local Grid = require(script.Parent.Grid)
local HandGenerator = require(script.Parent.HandGenerator)

local HandGeneratorTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local function shapeIds(hand)
	local ids = {}

	for index, shape in hand do
		ids[index] = shape.id
	end

	return ids
end

local function handHasAnyMove(board, hand)
	for _, shape in hand do
		for y = 1, Config.BoardSize do
			for x = 1, Config.BoardSize do
				if Grid.canPlace(board, shape, x, y) then
					return true
				end
			end
		end
	end

	return false
end

local function filledBoard()
	local board = Grid.create()

	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			board[y][x] = "filled"
		end
	end

	return board
end

local function allGeneratedCellsAreInBounds(hand)
	for _, shape in hand do
		assertCondition(
			Blocks.getShapeDefinition(shape.id) ~= nil,
			`Generated invalid shape id {shape.id}`
		)
		for _, cell in shape.cells do
			assertCondition(cell.X >= 0, `Shape {shape.id} has negative X`)
			assertCondition(cell.Y >= 0, `Shape {shape.id} has negative Y`)
			assertCondition(cell.X < Config.BoardSize, `Shape {shape.id} has out-of-bounds X`)
			assertCondition(cell.Y < Config.BoardSize, `Shape {shape.id} has out-of-bounds Y`)
		end
	end
end

local tests = {}

tests.emptyBoard = function()
	local board = Grid.create()
	local hand, diagnostics = HandGenerator.generate(board, {
		randomizer = Random.new(101),
		candidateLimit = 12,
	})

	assertCondition(diagnostics.anyKnownShapeFits == true, "Empty board should have fitting shapes")
	assertCondition(#hand == Config.InventorySize, "Generated hand should use inventory size")
	assertCondition(handHasAnyMove(board, hand), "Empty board hand should be playable")
end

tests.crowdedBoardOnlySingleFits = function()
	local board = filledBoard()
	board[Config.BoardSize][Config.BoardSize] = false

	local hand = HandGenerator.generate(board, {
		randomizer = Random.new(202),
		candidateLimit = 12,
	})
	local containsSingle = false

	for _, shape in hand do
		if shape.id == "single" then
			containsSingle = true
			break
		end
	end

	assertCondition(containsSingle, "Crowded board with one gap should include a single")
	assertCondition(
		handHasAnyMove(board, hand),
		"Crowded board hand should include the one fitting move"
	)
end

tests.noKnownPieceFits = function()
	local board = filledBoard()
	local hand, diagnostics = HandGenerator.generate(board, {
		randomizer = Random.new(303),
		candidateLimit = 12,
	})

	assertCondition(
		diagnostics.anyKnownShapeFits == false,
		"Full board should have no fitting shape"
	)
	assertCondition(
		handHasAnyMove(board, hand) == false,
		"Full board hand should preserve game over"
	)
end

tests.identicalSeedsMatch = function()
	local board = Grid.create()
	local first = HandGenerator.generate(board, {
		randomizer = Random.new(404),
		candidateLimit = 18,
	})
	local second = HandGenerator.generate(board, {
		randomizer = Random.new(404),
		candidateLimit = 18,
	})

	assertCondition(
		table.concat(shapeIds(first), ",") == table.concat(shapeIds(second), ","),
		"Identical seeds should produce identical shape ids"
	)
end

tests.validPiecesAndCells = function()
	local board = Grid.create()
	local hand = HandGenerator.generate(board, {
		randomizer = Random.new(505),
		candidateLimit = 18,
	})

	allGeneratedCellsAreInBounds(hand)
end

tests.repeatPenalty = function()
	local board = Grid.create()
	local repeated = { "single", "line2", "line3" }
	local cleanScore = HandGenerator.scoreShapeIds(board, repeated, {
		recentHands = {},
	})
	local penalizedScore = HandGenerator.scoreShapeIds(board, repeated, {
		recentHands = { HandGenerator.handSignature(repeated) },
	})

	assertCondition(penalizedScore < cleanScore, "Recent hand signature should reduce score")
end

tests.fixedCandidateLimit = function()
	local board = Grid.create()
	local _, diagnostics = HandGenerator.generate(board, {
		randomizer = Random.new(606),
		candidateLimit = 7,
	})

	assertCondition(
		diagnostics.candidatesScored == 7,
		"Generator should stop at the configured candidate limit"
	)
	assertCondition(
		diagnostics.candidatesScored <= diagnostics.candidateLimit,
		"Generator exceeded candidate limit"
	)
end

function HandGeneratorTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return HandGeneratorTests
