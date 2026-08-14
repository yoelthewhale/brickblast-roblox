local Blocks = require(script.Parent.Blocks)
local Config = require(script.Parent.Config)
local Grid = require(script.Parent.Grid)
local HandGenerator = require(script.Parent.HandGenerator)
local StageProgression = require(script.Parent.StageProgression)

local DeveloperTools = {}

local Settings = Config.DeveloperTools

local function isFiniteNumber(value)
	return typeof(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function cleanInteger(value, minimum, maximum, fallback)
	if not isFiniteNumber(value) then
		return fallback
	end

	return math.clamp(math.floor(value), minimum, maximum)
end

local function fillBoard(value)
	local board = Grid.create()

	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			board[y][x] = value
		end
	end

	return board
end

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

local function handShapeNames(hand)
	local names = {}

	for slot = 1, Config.InventorySize do
		local shape = hand and hand[slot]
		names[slot] = shape and shape.id or "empty"
	end

	return names
end

local function validShapeIds()
	local ids = {}

	for _, shape in Blocks.Shapes do
		table.insert(ids, shape.id)
	end

	return ids
end

function DeveloperTools.isEnabled()
	return Settings.Enabled == true
end

function DeveloperTools.isAuthorizedUserId(userId)
	if not DeveloperTools.isEnabled() or not isFiniteNumber(userId) then
		return false
	end

	for _, allowedUserId in Settings.AuthorizedUserIds do
		if allowedUserId == userId then
			return true
		end
	end

	return false
end

function DeveloperTools.publicAccessForPlayer(player)
	local authorized = player ~= nil and DeveloperTools.isAuthorizedUserId(player.UserId)
	return {
		enabled = DeveloperTools.isEnabled(),
		authorized = authorized,
	}
end

local function setStageState(state, stage, progress)
	local nextStage = cleanInteger(stage, 1, Settings.MaxStage, 1)
	local nextProgress = cleanInteger(progress, 0, Settings.MaxStageProgress, 0)

	state.stage = StageProgression.sanitize({
		currentStage = nextStage,
		stageProgress = nextProgress,
		totalPerfectClears = state.stage and state.stage.totalPerfectClears or 0,
	})
end

function DeveloperTools.boardPattern(patternName)
	local board = Grid.create()

	if patternName == "empty" then
		return board
	elseif patternName == "nearlyCompletedLine" then
		for x = 1, Config.BoardSize - 1 do
			board[Config.BoardSize][x] = "dev"
		end
	elseif patternName == "perfectClearSetup" then
		board[1][1] = "dev"
		board[1][2] = "dev"
		board[1][3] = "dev"
	elseif patternName == "crowded" then
		for y = 1, Config.BoardSize do
			for x = 1, Config.BoardSize do
				if (x + y) % 3 ~= 0 then
					board[y][x] = "dev"
				end
			end
		end
	elseif patternName == "singleOnly" then
		board = fillBoard("dev")
		board[Config.BoardSize][Config.BoardSize] = false
	elseif patternName == "noMove" then
		board = fillBoard("dev")
	else
		return nil
	end

	return board
end

function DeveloperTools.validateBoard(board)
	if typeof(board) ~= "table" then
		return false
	end

	for y = 1, Config.BoardSize do
		if typeof(board[y]) ~= "table" then
			return false
		end
		for x = 1, Config.BoardSize do
			local value = board[y][x]
			if value ~= false and value ~= "dev" then
				return false
			end
		end
	end

	return true
end

function DeveloperTools.diagnostics(state, visibleCellCount)
	local stage = StageProgression.publicState(state and state.stage)
	return {
		currentStage = stage.currentStage,
		stageProgress = stage.stageProgress,
		stageProgressRequired = stage.stageProgressRequired,
		score = state and state.score or 0,
		comboStreak = state and state.comboStreak or 0,
		totalPerfectClears = stage.totalPerfectClears,
		occupiedCells = state and countOccupied(state.board) or 0,
		handShapeNames = state and handShapeNames(state.hand) or {},
		recordEligible = state and state.developerTestRun ~= true or false,
		visibleBoardCells = cleanInteger(
			visibleCellCount,
			0,
			Config.BoardSize * Config.BoardSize,
			0
		),
	}
end

local function markDeveloperRun(state)
	state.developerTestRun = true
	state.recordEligible = false
	state.message = "Developer test run - records disabled"
end

function DeveloperTools.applyCommand(state, command)
	if typeof(state) ~= "table" or state.mode ~= "Solo" then
		return false, "Solo run required"
	end
	if typeof(command) ~= "table" or typeof(command.action) ~= "string" then
		return false, "Malformed developer command"
	end

	local action = command.action

	if action == "Diagnostics" then
		return true, "Diagnostics refreshed", false
	elseif action == "SetStage" then
		markDeveloperRun(state)
		setStageState(state, command.stage, command.progress or 0)
	elseif action == "AddStageProgress" then
		markDeveloperRun(state)
		local current = StageProgression.publicState(state.stage)
		local amount = cleanInteger(command.amount, 0, Settings.MaxStageProgress, 0)
		setStageState(state, current.currentStage, current.stageProgress + amount)
	elseif action == "AdvanceStage" then
		markDeveloperRun(state)
		local current = StageProgression.publicState(state.stage)
		setStageState(state, current.currentStage + 1, 0)
	elseif action == "SetCombo" then
		markDeveloperRun(state)
		state.comboStreak = cleanInteger(command.combo, 0, Settings.MaxCombo, 0)
		state.highestCombo = math.max(state.highestCombo or 0, state.comboStreak)
	elseif action == "ClearBoard" then
		markDeveloperRun(state)
		state.board = Grid.create()
	elseif action == "ResetRun" then
		markDeveloperRun(state)
		state.board = Grid.create()
		state.score = 0
		state.linesCleared = 0
		state.comboStreak = 0
		state.highestCombo = 0
		state.stage = StageProgression.newRun()
		state.recentHands = {}
		state.hand = HandGenerator.generate(state.board, {
			randomizer = state.randomizer,
			count = Config.InventorySize,
			pieceSkin = state.pieceSkin,
		})
	elseif action == "GenerateHand" then
		markDeveloperRun(state)
		state.hand = HandGenerator.generate(state.board, {
			randomizer = state.randomizer,
			count = Config.InventorySize,
			pieceSkin = state.pieceSkin,
			comboStreak = state.comboStreak,
			recentHands = state.recentHands,
		})
		state.recentHands = HandGenerator.rememberHand(state.recentHands, state.hand)
	elseif action == "ChooseHand" then
		if typeof(command.shapes) ~= "table" then
			return false, "ChooseHand requires shape names"
		end
		local hand = {}
		for slot = 1, Config.InventorySize do
			local shapeId = command.shapes[slot]
			if typeof(shapeId) ~= "string" or not Blocks.getShapeDefinition(shapeId) then
				return false, "Unknown shape name"
			end
			hand[slot] = Blocks.createShape(shapeId, state.randomizer, state.pieceSkin)
		end
		markDeveloperRun(state)
		state.hand = hand
	elseif action == "LoadPattern" then
		local board = DeveloperTools.boardPattern(command.pattern)
		if not DeveloperTools.validateBoard(board) then
			return false, "Unknown or invalid board pattern"
		end
		markDeveloperRun(state)
		state.board = board
	elseif action == "ForceNoMove" then
		local board = DeveloperTools.boardPattern("noMove")
		if not board then
			return false, "No-move pattern unavailable"
		end
		markDeveloperRun(state)
		state.board = board
	else
		return false, "Unknown developer command"
	end

	state.alive = Grid.hasAnyMove(state.board, state.hand)
	return true, "Developer command applied", true
end

function DeveloperTools.commandList()
	return {
		"SetStage",
		"AddStageProgress",
		"AdvanceStage",
		"SetCombo",
		"ClearBoard",
		"ResetRun",
		"GenerateHand",
		"ChooseHand",
		"LoadPattern",
		"Diagnostics",
	}
end

function DeveloperTools.shapeIds()
	return validShapeIds()
end

return DeveloperTools
