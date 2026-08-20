local Config = require(script.Parent.Config)

local StageProgression = {}

local Rules = Config.StageProgression

local function isFiniteNumber(value)
	return typeof(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function cleanInteger(value, minimum, fallback)
	if not isFiniteNumber(value) then
		return fallback
	end

	return math.max(minimum, math.floor(value))
end

function StageProgression.requirementForStage(stage)
	stage = cleanInteger(stage, 1, 1)
	return Rules.BaseRequirement + (stage - 1) * Rules.RequirementGrowth
end

function StageProgression.newRun()
	return {
		currentStage = 1,
		stageProgress = 0,
		stageProgressRequired = StageProgression.requirementForStage(1),
		totalPerfectClears = 0,
	}
end

function StageProgression.sanitize(state)
	if typeof(state) ~= "table" then
		return StageProgression.newRun()
	end

	local currentStage = cleanInteger(state.currentStage, 1, 1)
	local required = StageProgression.requirementForStage(currentStage)
	local progress = cleanInteger(state.stageProgress, 0, 0)
	local perfectClears = cleanInteger(state.totalPerfectClears, 0, 0)

	while progress >= required do
		progress -= required
		currentStage += 1
		required = StageProgression.requirementForStage(currentStage)
	end

	return {
		currentStage = currentStage,
		stageProgress = math.min(progress, required - 1),
		stageProgressRequired = required,
		totalPerfectClears = perfectClears,
	}
end

function StageProgression.isBoardEmpty(board)
	if typeof(board) ~= "table" then
		return false
	end

	for y = 1, Config.BoardSize do
		if typeof(board[y]) ~= "table" then
			return false
		end
		for x = 1, Config.BoardSize do
			if board[y][x] ~= false then
				return false
			end
		end
	end

	return true
end

local function progressForEvent(linesCleared, comboStreak, perfectClear)
	local progress = 0
	progress += linesCleared * Rules.LineProgress
	progress += math.max(0, linesCleared - 1) * Rules.MultiLineBonus

	if comboStreak > 1 then
		progress += math.min(comboStreak - 1, Rules.ComboProgressCap) * Rules.ComboProgressBonus
	end

	if perfectClear then
		progress += Rules.PerfectClearBonus
	end

	return progress
end

function StageProgression.applyPlacement(state, board, event)
	local nextState = StageProgression.sanitize(state)
	event = event or {}

	local linesCleared = cleanInteger(event.linesCleared, 0, 0)
	local comboStreak = cleanInteger(event.comboStreak, 0, 0)
	local perfectClear = linesCleared > 0 and StageProgression.isBoardEmpty(board)
	local progressGained = progressForEvent(linesCleared, comboStreak, perfectClear)
	local startingStage = nextState.currentStage

	nextState.stageProgress += progressGained
	while nextState.stageProgress >= nextState.stageProgressRequired do
		nextState.stageProgress -= nextState.stageProgressRequired
		nextState.currentStage += 1
		nextState.stageProgressRequired =
			StageProgression.requirementForStage(nextState.currentStage)
	end

	if perfectClear then
		nextState.totalPerfectClears += 1
	end

	return nextState,
		{
			progressGained = progressGained,
			perfectClear = perfectClear,
			stagesAdvanced = nextState.currentStage - startingStage,
			currentStage = nextState.currentStage,
			stageProgress = nextState.stageProgress,
			stageProgressRequired = nextState.stageProgressRequired,
			totalPerfectClears = nextState.totalPerfectClears,
		}
end

function StageProgression.publicState(state)
	return StageProgression.sanitize(state)
end

return StageProgression
