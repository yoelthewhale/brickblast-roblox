local Blocks = require(script.Parent.Blocks)
local Config = require(script.Parent.Config)
local DeveloperTools = require(script.Parent.DeveloperTools)
local Grid = require(script.Parent.Grid)
local HandGenerator = require(script.Parent.HandGenerator)
local StageProgression = require(script.Parent.StageProgression)

local DeveloperToolsTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local function makeState()
	return {
		board = Grid.create(),
		hand = {
			Blocks.createShape("single", Random.new(1), "Rainbow"),
			Blocks.createShape("line2", Random.new(2), "Rainbow"),
			Blocks.createShape("line3", Random.new(3), "Rainbow"),
		},
		recentHands = {},
		randomizer = Random.new(10),
		mode = "Solo",
		pieceSkin = "Rainbow",
		score = 100,
		bestScore = 100,
		linesCleared = 0,
		comboStreak = 0,
		highestCombo = 0,
		stage = StageProgression.newRun(),
		assistance = HandGenerator.newAssistance(),
		lastHandGeneration = nil,
		alive = true,
	}
end

local tests = {}

tests.authorizationUsesUserId = function()
	local wasEnabled = Config.DeveloperTools.Enabled
	local originalAllowlist = Config.DeveloperTools.AuthorizedUserIds
	Config.DeveloperTools.Enabled = true
	Config.DeveloperTools.AuthorizedUserIds = { 12345 }

	assertCondition(DeveloperTools.isAuthorizedUserId(12345), "Allowlisted UserId should authorize")
	assertCondition(
		not DeveloperTools.isAuthorizedUserId(54321),
		"Unknown UserId should not authorize"
	)
	assertCondition(
		not DeveloperTools.isAuthorizedUserId("12345"),
		"String IDs should not authorize"
	)

	Config.DeveloperTools.Enabled = wasEnabled
	Config.DeveloperTools.AuthorizedUserIds = originalAllowlist
end

tests.masterSwitchDisablesAuthorization = function()
	local wasEnabled = Config.DeveloperTools.Enabled
	local originalAllowlist = Config.DeveloperTools.AuthorizedUserIds
	Config.DeveloperTools.Enabled = false
	Config.DeveloperTools.AuthorizedUserIds = { 12345 }

	assertCondition(
		not DeveloperTools.isAuthorizedUserId(12345),
		"Master switch should disable tools"
	)

	Config.DeveloperTools.Enabled = wasEnabled
	Config.DeveloperTools.AuthorizedUserIds = originalAllowlist
end

tests.rejectsMalformedCommands = function()
	local state = makeState()
	local ok = DeveloperTools.applyCommand(state, { action = "MissingCommand" })

	assertCondition(ok == false, "Unknown commands should be rejected")
	assertCondition(state.developerTestRun ~= true, "Rejected commands should not mark dev run")
end

tests.numericInputsAreClamped = function()
	local state = makeState()
	local ok = DeveloperTools.applyCommand(state, {
		action = "SetStage",
		stage = 999,
		progress = math.huge,
	})

	assertCondition(ok == true, "Valid command should apply")
	assertCondition(
		state.stage.currentStage <= Config.DeveloperTools.MaxStage,
		"Stage should clamp to max"
	)
	assertCondition(state.stage.stageProgress == 0, "Invalid progress should sanitize")
end

tests.boardPatternsAreValid = function()
	for _, pattern in
		{ "empty", "nearlyCompletedLine", "perfectClearSetup", "crowded", "singleOnly", "noMove" }
	do
		local board = DeveloperTools.boardPattern(pattern)
		assertCondition(DeveloperTools.validateBoard(board), `{pattern} board should validate`)
	end
end

tests.chooseHandRejectsUnknownShapes = function()
	local state = makeState()
	local ok = DeveloperTools.applyCommand(state, {
		action = "ChooseHand",
		shapes = { "single", "not-a-shape", "line3" },
	})

	assertCondition(ok == false, "Unknown shape names should be rejected")
end

tests.gameplayCommandsMarkDeveloperRun = function()
	local state = makeState()
	local ok = DeveloperTools.applyCommand(state, {
		action = "ClearBoard",
	})

	assertCondition(ok == true, "Clear board command should apply")
	assertCondition(state.developerTestRun == true, "Gameplay command should mark dev run")
	assertCondition(state.recordEligible == false, "Developer run should disable records")
end

tests.diagnosticsDoesNotMarkDeveloperRun = function()
	local state = makeState()
	local ok = DeveloperTools.applyCommand(state, {
		action = "Diagnostics",
	})

	assertCondition(ok == true, "Diagnostics should be accepted")
	assertCondition(state.developerTestRun ~= true, "Diagnostics should not alter eligibility")
end

tests.diagnosticsReportRecordSuppression = function()
	local state = makeState()
	DeveloperTools.applyCommand(state, { action = "SetCombo", combo = 4 })
	local diagnostics = DeveloperTools.diagnostics(state, 64)

	assertCondition(diagnostics.recordEligible == false, "Diagnostics should report ineligible run")
	assertCondition(diagnostics.comboStreak == 4, "Diagnostics should include combo")
	assertCondition(diagnostics.visibleBoardCells == 64, "Diagnostics should include cell count")
	assertCondition(
		diagnostics.assistanceRemaining == Config.HandGeneration.AssistanceStart,
		"Diagnostics should include assistance"
	)
	assertCondition(
		#diagnostics.legalPlacementCounts == Config.InventorySize,
		"Diagnostics should include legal placement counts"
	)
end

tests.generateHandTracksGeneratorDiagnostics = function()
	local state = makeState()
	local ok = DeveloperTools.applyCommand(state, { action = "GenerateHand" })

	assertCondition(ok == true, "Generate hand command should apply")
	assertCondition(
		typeof(state.lastHandGeneration) == "table",
		"Generate hand should store diagnostics"
	)
	assertCondition(
		state.lastHandGeneration.candidatesScored <= state.lastHandGeneration.candidateLimit,
		"Generate hand should stay within candidate limit"
	)
end

function DeveloperToolsTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return DeveloperToolsTests
