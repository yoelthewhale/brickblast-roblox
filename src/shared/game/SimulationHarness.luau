local Config = require(script.Parent.Config)
local Blocks = require(script.Parent.Blocks)
local GameplayRules = require(script.Parent.GameplayRules)
local Grid = require(script.Parent.Grid)
local HandGenerator = require(script.Parent.HandGenerator)
local StageProgression = require(script.Parent.StageProgression)

local SimulationHarness = {}

local DEFAULT_MAX_PLACEMENTS = 160

local function countOccupied(board)
	local occupied = 0

	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			if board[y][x] ~= false then
				occupied += 1
			end
		end
	end

	return occupied
end

local function countLegalMoves(board, hand)
	local count = 0

	for _, shape in hand do
		if shape == nil then
			continue
		end
		for y = 1, Config.BoardSize do
			for x = 1, Config.BoardSize do
				if Grid.canPlace(board, shape, x, y) then
					count += 1
				end
			end
		end
	end

	return count
end

local function handIsEmpty(hand)
	for _, shape in hand do
		if shape ~= nil then
			return false
		end
	end

	return true
end

local function newFairnessFloorTriggers()
	return {
		stageAdvanced = 0,
		comboMilestone = 0,
		perfectClear = 0,
		totalRestored = 0,
	}
end

local function restoreAssistance(state, stageResult)
	local restoreAmount, triggers =
		GameplayRules.assistanceRestoreAmount(state.comboStreak, stageResult)
	if restoreAmount > 0 then
		state.assistance =
			HandGenerator.restoreAssistance(state.assistance, restoreAmount, "simulation reward")
		local counters = state.fairnessFloorTriggers
		if triggers.stageAdvanced then
			counters.stageAdvanced += 1
		end
		if triggers.comboMilestone then
			counters.comboMilestone += 1
		end
		if triggers.perfectClear then
			counters.perfectClear += 1
		end
		counters.totalRestored += restoreAmount
	end
end

local function generateHand(state)
	local hand, diagnostics = HandGenerator.generate(state.board, {
		randomizer = state.randomizer,
		count = Config.InventorySize,
		comboStreak = state.comboStreak,
		recentHands = state.recentHands,
		assistance = state.assistance,
		stage = state.stage.currentStage,
		candidateLimit = state.candidateLimit,
	})
	state.hand = hand
	state.assistance = diagnostics.assistance
	state.assistanceUsed += diagnostics.assistanceConsumed and 1 or 0
	state.recentHands = HandGenerator.rememberHand(state.recentHands, hand)
end

local function previewMove(board, shape, x, y)
	local preview = Grid.clone(board)
	local placed, cellsPlaced = Grid.place(preview, shape, x, y)
	if not placed then
		return nil
	end

	local linesCleared = Grid.clearLines(preview)
	local legalAfter = 0
	for _, definition in Blocks.Shapes do
		legalAfter += countLegalMoves(preview, {
			{
				id = definition.id,
				cells = Blocks.cloneCells(definition.cells),
			},
		})
	end

	return {
		board = preview,
		cellsPlaced = cellsPlaced,
		linesCleared = linesCleared,
		occupied = countOccupied(preview),
		legalAfter = legalAfter,
	}
end

local function collectMoves(board, hand)
	local moves = {}

	for slot, shape in hand do
		if shape == nil then
			continue
		end
		for y = 1, Config.BoardSize do
			for x = 1, Config.BoardSize do
				local preview = previewMove(board, shape, x, y)
				if preview then
					table.insert(moves, {
						slot = slot,
						x = x,
						y = y,
						shape = shape,
						preview = preview,
					})
				end
			end
		end
	end

	return moves
end

local function chooseMove(strategy, moves, randomizer)
	if #moves == 0 then
		return nil
	end
	if strategy == "random" then
		return moves[randomizer:NextInteger(1, #moves)]
	elseif strategy == "poor" then
		table.sort(moves, function(left, right)
			local leftScore = left.preview.linesCleared * -100
				+ left.preview.occupied * 2
				- left.preview.legalAfter * 0.2
				+ left.slot * 0.01
			local rightScore = right.preview.linesCleared * -100
				+ right.preview.occupied * 2
				- right.preview.legalAfter * 0.2
				+ right.slot * 0.01
			return leftScore > rightScore
		end)
		return moves[1]
	elseif strategy == "smart" then
		table.sort(moves, function(left, right)
			local leftScore = left.preview.linesCleared * 90
				+ left.preview.legalAfter * 1.2
				- left.preview.occupied * 0.35
				+ left.preview.cellsPlaced
			local rightScore = right.preview.linesCleared * 90
				+ right.preview.legalAfter * 1.2
				- right.preview.occupied * 0.35
				+ right.preview.cellsPlaced
			return leftScore > rightScore
		end)
		return moves[1]
	elseif strategy == "spam" then
		return moves[1]
	end

	error(`SimulationHarness: unknown strategy "{tostring(strategy)}"`, 2)
end

function SimulationHarness.run(options)
	options = options or {}
	local state = {
		board = Grid.create(),
		hand = {},
		randomizer = Random.new(options.seed or 1),
		recentHands = {},
		stage = StageProgression.newRun(),
		assistance = HandGenerator.newAssistance(),
		comboStreak = 0,
		highestCombo = 0,
		score = 0,
		linesCleared = 0,
		placements = 0,
		handsSurvived = 0,
		assistanceUsed = 0,
		candidateLimit = options.candidateLimit,
		fairnessFloorTriggers = newFairnessFloorTriggers(),
	}
	local maxPlacements = options.maxPlacements or DEFAULT_MAX_PLACEMENTS
	local strategy = options.strategy or "spam"

	generateHand(state)
	while state.placements < maxPlacements do
		local moves = collectMoves(state.board, state.hand)
		if #moves == 0 then
			return {
				gameOver = true,
				reason = "no legal moves",
				score = state.score,
				placements = state.placements,
				handsSurvived = state.handsSurvived,
				linesCleared = state.linesCleared,
				highestCombo = state.highestCombo,
				highestStage = state.stage.currentStage,
				assistanceUsed = state.assistanceUsed,
				fairnessFloorTriggers = state.fairnessFloorTriggers,
			}
		end

		local move = chooseMove(strategy, moves, state.randomizer)
		Grid.place(state.board, move.shape, move.x, move.y)
		state.hand[move.slot] = nil
		local linesCleared = Grid.clearLines(state.board)
		if linesCleared > 0 then
			state.comboStreak += 1
			state.highestCombo = math.max(state.highestCombo, state.comboStreak)
		else
			state.comboStreak = 0
		end

		local scoreDelta =
			GameplayRules.scoreForPlacement(#move.shape.cells, linesCleared, state.comboStreak)
		state.score += scoreDelta
		state.linesCleared += linesCleared
		local stageResult = nil
		state.stage, stageResult = StageProgression.applyPlacement(state.stage, state.board, {
			linesCleared = linesCleared,
			comboStreak = state.comboStreak,
		})
		restoreAssistance(state, stageResult)
		state.placements += 1

		if handIsEmpty(state.hand) then
			state.handsSurvived += 1
			generateHand(state)
		end
	end

	return {
		gameOver = false,
		reason = "placement cap reached",
		score = state.score,
		placements = state.placements,
		handsSurvived = state.handsSurvived,
		linesCleared = state.linesCleared,
		highestCombo = state.highestCombo,
		highestStage = state.stage.currentStage,
		assistanceUsed = state.assistanceUsed,
		fairnessFloorTriggers = state.fairnessFloorTriggers,
	}
end

return SimulationHarness
