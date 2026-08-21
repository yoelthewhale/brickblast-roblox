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

	local hand, diagnostics = HandGenerator.generate(board, {
		randomizer = Random.new(202),
		candidateLimit = 12,
		assistance = HandGenerator.newAssistance(),
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
	-- This test previously asserted that assistance was spent here, which was
	-- the bug rather than the behaviour: a hand missing every fitting shape is
	-- already penalised by 1000 points, so the base scorer produces the single
	-- on its own. The player was being charged for a rescue nothing performed.
	assertCondition(
		diagnostics.assistanceConsumed == false,
		"A rescue the base scorer would have made anyway must not spend assistance"
	)
	assertCondition(
		diagnostics.assistance.remaining == Config.HandGeneration.AssistanceStart,
		"An unspent rescue should leave the budget untouched"
	)
	assertCondition(
		diagnostics.assistanceReason == "none",
		"An unspent rescue should not claim a reason"
	)
end

tests.assistanceIsSpentWhenItForcesAFittingPiece = function()
	-- With a single candidate to choose from, the winning hand can genuinely
	-- lack any playable piece, and only then does the generator step in and
	-- replace a slot. That is assistance doing real work, so it is charged.
	local board = filledBoard()
	board[Config.BoardSize][Config.BoardSize] = false

	local hand, diagnostics = HandGenerator.generate(board, {
		randomizer = Random.new(3454),
		candidateLimit = 1,
		assistance = HandGenerator.newAssistance(),
	})

	assertCondition(
		diagnostics.assistanceConsumed == true,
		"Forcing a fitting piece should spend assistance"
	)
	assertCondition(
		diagnostics.assistanceReason == "forced fitting piece",
		"A forced rescue should say so"
	)
	assertCondition(
		diagnostics.assistance.remaining
			== Config.HandGeneration.AssistanceStart - Config.HandGeneration.RescueCost,
		"A forced rescue should reduce assistance by the configured cost"
	)
	assertCondition(handHasAnyMove(board, hand), "A forced rescue should leave a playable hand")
end

tests.anExhaustedBudgetStillProducesAPlayableHand = function()
	-- The struggling-player case: the budget is gone, the board is nearly
	-- full, and the generator must still not hand out an unplayable hand. The
	-- fitting-shape penalty does that work independently of assistance.
	local board = filledBoard()
	board[Config.BoardSize][Config.BoardSize] = false

	local emptyBudget = HandGenerator.newAssistance()
	emptyBudget.remaining = 0

	local hand, diagnostics = HandGenerator.generate(board, {
		randomizer = Random.new(404),
		candidateLimit = 12,
		assistance = emptyBudget,
	})

	assertCondition(
		diagnostics.assistanceConsumed == false,
		"An empty budget cannot be spent further"
	)
	assertCondition(diagnostics.assistance.remaining == 0, "An empty budget stays at zero")
	assertCondition(
		handHasAnyMove(board, hand),
		"A player with no assistance left still gets a playable hand"
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
	assertCondition(
		diagnostics.assistanceConsumed == false,
		"No-fit boards should not spend assistance"
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

tests.assistanceIsCapped = function()
	local assistance = HandGenerator.restoreAssistance({
		remaining = Config.HandGeneration.AssistanceMax,
		cap = Config.HandGeneration.AssistanceMax,
	}, 99, "test")

	assertCondition(
		assistance.remaining == Config.HandGeneration.AssistanceMax,
		"Restored assistance should stay capped"
	)
end

tests.stagePressureIncreases = function()
	local early = HandGenerator.difficultyForStage(1)
	local cappedBase = HandGenerator.difficultyForStage(8)
	local extended = HandGenerator.difficultyForStage(15)
	local longRun = HandGenerator.difficultyForStage(30)

	assertCondition(early.pressure <= cappedBase.pressure, "Later stages should add pressure")
	assertCondition(
		math.abs(cappedBase.pressure - Config.HandGeneration.MaxPressure) < 0.0001,
		"Stage 8 should preserve the original pressure cap"
	)
	assertCondition(
		extended.pressure > cappedBase.pressure,
		"Stage 15 should continue escalating beyond the original cap"
	)
	assertCondition(
		longRun.pressure <= Config.HandGeneration.LateMaxPressure,
		"Long-run pressure should stay capped"
	)
	assertCondition(
		longRun.assistanceMultiplier == 1 - longRun.pressure,
		"Assistance multiplier should remain tied to pressure"
	)
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

tests.difficultySanitizesUnknownInput = function()
	for _, bad in { nil, "", "impossible", 42, {}, true } do
		assertCondition(
			HandGenerator.sanitizeDifficulty(bad) == Config.Difficulties.Default,
			"Unknown difficulty should fall back to the default"
		)
	end

	for _, id in Config.Difficulties.Order do
		assertCondition(
			HandGenerator.sanitizeDifficulty(id) == id,
			`Known difficulty {id} should survive sanitizing`
		)
	end
end

tests.classicDifficultyIsUnchangedBehaviour = function()
	-- The whole safety argument for this feature is that the default profile is
	-- a no-op, so existing runs behave exactly as before. If this breaks, the
	-- feature has silently rebalanced the game.
	local profile = HandGenerator.difficultyProfile("classic")
	assertCondition(profile.assistanceBonus == 0, "Classic must not change the rescue budget")
	assertCondition(profile.pressureScale == 1, "Classic must not scale pressure")
	assertCondition(profile.pressureStartOffset == 0, "Classic must not shift pressure start")

	local assistance = HandGenerator.newAssistance("classic")
	assertCondition(
		assistance.remaining == Config.HandGeneration.AssistanceStart,
		"Classic should start with the configured assistance"
	)
	assertCondition(
		assistance.cap == Config.HandGeneration.AssistanceMax,
		"Classic should cap at the configured assistance"
	)

	for stage = 1, 20 do
		local withId = HandGenerator.difficultyForStage(stage, "classic")
		local withoutId = HandGenerator.difficultyForStage(stage)
		assertCondition(
			math.abs(withId.pressure - withoutId.pressure) < 1e-9,
			`Classic pressure diverged from the default at stage {stage}`
		)
	end
end

tests.difficultyOrdersAssistanceBudgets = function()
	local chill = HandGenerator.newAssistance("chill")
	local classic = HandGenerator.newAssistance("classic")
	local spicy = HandGenerator.newAssistance("spicy")

	assertCondition(
		chill.remaining > classic.remaining and classic.remaining > spicy.remaining,
		"Rescue budgets should decrease from chill to spicy"
	)
	assertCondition(chill.cap > spicy.cap, "Rescue caps should decrease from chill to spicy")
end

tests.everyDifficultyKeepsAtLeastOneRescue = function()
	for _, id in Config.Difficulties.Order do
		local assistance = HandGenerator.newAssistance(id)
		assertCondition(
			assistance.remaining >= 1 and assistance.cap >= 1,
			`Difficulty {id} left the player with no rescues at all`
		)
		assertCondition(
			assistance.remaining <= assistance.cap,
			`Difficulty {id} starts above its own cap`
		)
	end
end

tests.difficultyOrdersPressure = function()
	-- Compared at a mid-run stage, where all three profiles are active.
	local chill = HandGenerator.difficultyForStage(10, "chill")
	local classic = HandGenerator.difficultyForStage(10, "classic")
	local spicy = HandGenerator.difficultyForStage(10, "spicy")

	assertCondition(
		chill.pressure < classic.pressure and classic.pressure < spicy.pressure,
		"Pressure at stage 10 should increase from chill to spicy"
	)
end

tests.chillDelaysPressureOnset = function()
	-- Classic starts biting at stage 3; chill offsets that by two stages.
	assertCondition(
		HandGenerator.difficultyForStage(3, "chill").pressure == 0,
		"Chill should still be pressure-free at stage 3"
	)
	assertCondition(
		HandGenerator.difficultyForStage(3, "classic").pressure > 0,
		"Classic should already apply pressure at stage 3"
	)
end

tests.pressureStaysWithinBoundsForEveryDifficulty = function()
	for _, id in Config.Difficulties.Order do
		for stage = 1, 60 do
			local difficulty = HandGenerator.difficultyForStage(stage, id)
			assertCondition(
				difficulty.pressure >= 0
					and difficulty.pressure <= Config.HandGeneration.LateMaxPressure,
				`Difficulty {id} escaped the pressure bounds at stage {stage}`
			)
			assertCondition(
				difficulty.assistanceMultiplier >= 0,
				`Difficulty {id} produced a negative assistance multiplier at stage {stage}`
			)
		end
	end
end

tests.difficultyIsMonotonicInStageForEveryProfile = function()
	for _, id in Config.Difficulties.Order do
		local previous = -1
		for stage = 1, 40 do
			local pressure = HandGenerator.difficultyForStage(stage, id).pressure
			assertCondition(
				pressure >= previous - 1e-9,
				`Difficulty {id} pressure dropped as stage rose to {stage}`
			)
			previous = pressure
		end
	end
end

tests.assistanceRemembersItsDifficultyAcrossSanitize = function()
	-- A run carries its difficulty on the assistance table. If a sanitize call
	-- that is not told the difficulty resets the cap to the default, a chill
	-- run silently loses rescues mid-game.
	local chill = HandGenerator.newAssistance("chill")
	local roundTripped = HandGenerator.sanitizeAssistance(chill)

	assertCondition(roundTripped.difficulty == "chill", "Sanitize dropped the run's difficulty")
	assertCondition(
		roundTripped.cap == chill.cap,
		"Sanitize reset a chill run's rescue cap to the default"
	)
	assertCondition(
		roundTripped.remaining == chill.remaining,
		"Sanitize changed a chill run's remaining rescues"
	)
end

tests.generateHonoursTheRunDifficulty = function()
	local board = Grid.create()
	local hand = HandGenerator.generate(board, {
		randomizer = Random.new(99),
		count = Config.InventorySize,
		assistance = HandGenerator.newAssistance("chill"),
		stage = 6,
	})

	assertCondition(#hand == Config.InventorySize, "Generation should still return a full hand")
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
