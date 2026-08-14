local Config = require(script.Parent.Config)
local Grid = require(script.Parent.Grid)
local StageProgression = require(script.Parent.StageProgression)

local StageProgressionTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
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

local tests = {}

tests.newRunStartsAtStageOne = function()
	local state = StageProgression.newRun()

	assertCondition(state.currentStage == 1, "New run should start at stage 1")
	assertCondition(state.stageProgress == 0, "New run should start with zero progress")
	assertCondition(
		state.stageProgressRequired == Config.StageProgression.BaseRequirement,
		"Stage 1 requirement should use configured base"
	)
	assertCondition(state.totalPerfectClears == 0, "New run should start with zero perfect clears")
end

tests.normalLineClearProgress = function()
	local nextState, result =
		StageProgression.applyPlacement(StageProgression.newRun(), filledBoard(), {
			linesCleared = 1,
			comboStreak = 1,
		})

	assertCondition(
		result.progressGained == Config.StageProgression.LineProgress,
		"Single line clear should award line progress only"
	)
	assertCondition(nextState.stageProgress == result.progressGained, "Progress should be stored")
end

tests.multiLineProgress = function()
	local _, result = StageProgression.applyPlacement(StageProgression.newRun(), filledBoard(), {
		linesCleared = 3,
		comboStreak = 1,
	})
	local expected = Config.StageProgression.LineProgress * 3
		+ Config.StageProgression.MultiLineBonus * 2

	assertCondition(result.progressGained == expected, "Multi-line clear should add bonuses")
end

tests.comboProgressCap = function()
	local _, capped = StageProgression.applyPlacement(StageProgression.newRun(), filledBoard(), {
		linesCleared = 1,
		comboStreak = 99,
	})
	local _, atCap = StageProgression.applyPlacement(StageProgression.newRun(), filledBoard(), {
		linesCleared = 1,
		comboStreak = Config.StageProgression.ComboProgressCap + 1,
	})

	assertCondition(
		capped.progressGained == atCap.progressGained,
		"Combo progress should stop at configured cap"
	)
end

tests.perfectClearDetection = function()
	local nextState, result =
		StageProgression.applyPlacement(StageProgression.newRun(), Grid.create(), {
			linesCleared = 1,
			comboStreak = 1,
		})

	assertCondition(
		result.perfectClear == true,
		"Empty board after line clear should be perfect clear"
	)
	assertCondition(nextState.totalPerfectClears == 1, "Perfect clear should increment run count")
end

tests.perfectClearProgressBonus = function()
	local _, result = StageProgression.applyPlacement(StageProgression.newRun(), Grid.create(), {
		linesCleared = 1,
		comboStreak = 1,
	})
	local expected = Config.StageProgression.LineProgress
		+ Config.StageProgression.PerfectClearBonus

	assertCondition(result.progressGained == expected, "Perfect clear should add configured bonus")
end

tests.increasingRequirements = function()
	local first = StageProgression.requirementForStage(1)
	local third = StageProgression.requirementForStage(3)
	local sixth = StageProgression.requirementForStage(6)

	assertCondition(first < third, "Stage 3 should require more than stage 1")
	assertCondition(third < sixth, "Stage 6 should require more than stage 3")
end

tests.overflowCanAdvanceMultipleStages = function()
	local state = StageProgression.newRun()
	state.stageProgress = 200
	local nextState = StageProgression.sanitize(state)

	assertCondition(nextState.currentStage > 2, "Overflow should support multiple stage advances")
	assertCondition(
		nextState.stageProgress < nextState.stageProgressRequired,
		"Overflow progress should be reduced below the current requirement"
	)
end

tests.stageResetOnNewSoloRun = function()
	local progressed = StageProgression.newRun()
	progressed.currentStage = 4
	progressed.stageProgress = 12

	local reset = StageProgression.newRun()

	assertCondition(reset.currentStage == 1, "New run should reset stage")
	assertCondition(reset.stageProgress == 0, "New run should reset progress")
end

tests.noFalsePerfectClear = function()
	local board = Grid.create()
	board[1][1] = "filled"
	local nextState, result = StageProgression.applyPlacement(StageProgression.newRun(), board, {
		linesCleared = 1,
		comboStreak = 1,
	})

	assertCondition(
		result.perfectClear == false,
		"Occupied board should not count as perfect clear"
	)
	assertCondition(
		nextState.totalPerfectClears == 0,
		"False perfect clear should not increment count"
	)
end

tests.invalidValuesCannotCorruptState = function()
	local clean = StageProgression.sanitize({
		currentStage = -10,
		stageProgress = 0 / 0,
		stageProgressRequired = math.huge,
		totalPerfectClears = -4,
	})

	assertCondition(clean.currentStage == 1, "Invalid stage should sanitize to stage 1")
	assertCondition(clean.stageProgress == 0, "Invalid progress should sanitize to zero")
	assertCondition(clean.totalPerfectClears == 0, "Invalid perfect clears should sanitize to zero")
	assertCondition(
		clean.stageProgressRequired == StageProgression.requirementForStage(1),
		"Requirement should be recomputed from sanitized stage"
	)
end

function StageProgressionTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return StageProgressionTests
