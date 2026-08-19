local ExperienceConfig = require(script.Parent.ExperienceConfig)
local UIControlRules = require(script.Parent.UIControlRules)

local UIControlRulesTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local tests = {}

tests.visibleControlsHaveActions = function()
	for _, control in UIControlRules.HubControls do
		assertCondition(
			UIControlRules.controlHasAction(control),
			`Hub control {control.name} should be actionable or explicitly disabled`
		)
	end
	for _, control in UIControlRules.SoloControls do
		assertCondition(
			UIControlRules.controlHasAction(control),
			`Solo control {control.name} should be actionable or explicitly disabled`
		)
	end
end

tests.disabledModesRemainHidden = function()
	assertCondition(
		UIControlRules.disabledModeControlsAreHidden(ExperienceConfig),
		"Disabled Battle, Story, and Custom Lab controls should remain hidden"
	)
end

tests.majorPanelsAreMutuallyExclusive = function()
	assertCondition(
		UIControlRules.onlyOneMajorPanelOpen({
			shop = true,
			cosmetics = false,
			story = false,
			menu = false,
		}),
		"One open panel should be valid"
	)
	assertCondition(not UIControlRules.onlyOneMajorPanelOpen({
		shop = true,
		cosmetics = true,
		story = false,
		menu = false,
	}), "Two open major panels should be invalid")
end

tests.resetAndReturnDebounce = function()
	-- 1.5 rather than the cooldown's exact boundary (1.45): floating-point
	-- subtraction (1.45 - 1) lands at 0.44999999999999996, just under the
	-- 0.45 cooldown, so an exact-boundary input is flaky by construction.
	assertCondition(
		UIControlRules.canFireServerAction(1, 1.5),
		"Request should be allowed after cooldown"
	)
	assertCondition(
		not UIControlRules.canFireServerAction(1, 1.1),
		"Request should be blocked inside cooldown"
	)
end

local function boardGridChildren()
	local children = { { className = "UIPadding" }, { className = "UIGridLayout" } }

	for y = 1, 8 do
		for x = 1, 8 do
			table.insert(children, {
				className = "TextButton",
				name = `{x}_{y}`,
				isBoardCell = true,
				boardX = x,
				boardY = y,
			})
		end
	end

	return children
end

tests.boardGridInvariant = function()
	local valid, problems, cellCount = UIControlRules.validateBoardGridChildren(boardGridChildren())

	assertCondition(
		valid,
		`A correct 8x8 grid should validate, got: {table.concat(problems, "; ")}`
	)
	assertCondition(cellCount == 64, "Board grid should count exactly 64 cells")
end

tests.boardGridRejectsDecorativeChildren = function()
	local children = boardGridChildren()
	table.insert(children, { className = "Frame", name = "Sparkle" })

	local valid, problems = UIControlRules.validateBoardGridChildren(children)
	assertCondition(not valid, "A decorative direct child should be rejected")
	assertCondition(#problems >= 1, "A rejection should explain itself")
end

tests.boardGridRejectsAWrongCellCount = function()
	local children = boardGridChildren()
	table.remove(children)

	assertCondition(
		not UIControlRules.validateBoardGridChildren(children),
		"63 cells should be rejected"
	)

	children = boardGridChildren()
	table.insert(children, {
		className = "TextButton",
		name = "extra",
		isBoardCell = true,
		boardX = 1,
		boardY = 1,
	})
	assertCondition(
		not UIControlRules.validateBoardGridChildren(children),
		"65 cells should be rejected"
	)
end

tests.boardGridRejectsBadCoordinates = function()
	-- These are the checks the live client had and the shared rule did not, so
	-- adopting the shared rule naively would have quietly weakened the guard on
	-- the locked board invariant.
	local children = boardGridChildren()
	children[3].boardX = 99
	assertCondition(
		not UIControlRules.validateBoardGridChildren(children),
		"Out-of-range coordinates should be rejected"
	)

	children = boardGridChildren()
	children[3].boardX = children[4].boardX
	children[3].boardY = children[4].boardY
	assertCondition(
		not UIControlRules.validateBoardGridChildren(children),
		"Duplicate coordinates should be rejected"
	)

	children = boardGridChildren()
	children[5].isBoardCell = false
	assertCondition(
		not UIControlRules.validateBoardGridChildren(children),
		"A TextButton that is not tagged as a board cell should be rejected"
	)
end

tests.touchDrivesThePlacementPipelineAlongsideTheMouse = function()
	-- The regression this guards: every stage of the drag pipeline was gated
	-- on a mouse input type, so touch never armed a drag, never moved one, and
	-- never got the ghost preview that rides on it.
	assertCondition(UIControlRules.isPointerPressInput("MouseButton1"), "A left click presses")
	assertCondition(UIControlRules.isPointerPressInput("Touch"), "A finger presses")
	assertCondition(
		UIControlRules.isPointerMoveInput("MouseMovement"),
		"Mouse movement moves a drag"
	)
	assertCondition(
		UIControlRules.isPointerMoveInput("Touch"),
		"Touch reports movement under the same type it reports presses under"
	)
end

tests.otherInputTypesDoNotDriveThePlacementPipeline = function()
	for _, inputTypeName in { "MouseButton2", "MouseButton3", "Keyboard", "Gamepad1", "Gyro" } do
		assertCondition(
			not UIControlRules.isPointerPressInput(inputTypeName),
			`{inputTypeName} should not arm or release a drag`
		)
	end

	assertCondition(
		not UIControlRules.isPointerMoveInput("MouseButton1"),
		"A held button is not movement"
	)
	assertCondition(
		not UIControlRules.isPointerMoveInput("Accelerometer"),
		"Device motion is not pointer movement"
	)

	assertCondition(UIControlRules.isTouchInput("Touch"), "Touch is touch")
	assertCondition(not UIControlRules.isTouchInput("MouseMovement"), "A mouse is not touch")
	assertCondition(not UIControlRules.isTouchInput(nil), "Missing input type is not touch")
end

tests.achievementsPayloadSortsUnlockedFirstThenByStatAndThreshold = function()
	local entries = UIControlRules.sanitizeAchievementsPayload({
		{ stat = "totalRuns", name = "Runs 10", threshold = 10, unlocked = false },
		{ stat = "totalRuns", name = "Runs 5", threshold = 5, unlocked = false },
		{ stat = "combo", name = "Combo 3", threshold = 3, unlocked = false },
		{ stat = "totalRuns", name = "Runs 1", threshold = 1, unlocked = true },
	})

	assertCondition(#entries == 4, "Well-formed entries should all survive")
	assertCondition(entries[1].name == "Runs 1", "Unlocked entries sort first")
	assertCondition(entries[2].name == "Combo 3", "Locked entries then sort by stat")
	assertCondition(entries[3].name == "Runs 5", "Then by threshold, ascending")
	assertCondition(entries[4].name == "Runs 10", "Then by threshold, ascending")
end

tests.achievementsPayloadDropsEntriesThatCannotBeRendered = function()
	-- Each of these used to be able to error mid-render, after the panel's
	-- loading label had already been destroyed, leaving a blank panel.
	local entries = UIControlRules.sanitizeAchievementsPayload({
		{ stat = "totalRuns", name = "Missing threshold" },
		{ stat = "totalRuns", name = "Nan threshold", threshold = 0 / 0 },
		{ stat = 5, name = "Numeric stat", threshold = 1 },
		{ stat = "totalRuns", name = 5, threshold = 1 },
		"not a table",
		{ stat = "totalRuns", name = "Good", threshold = 1 },
	})

	assertCondition(#entries == 1, "Only the renderable entry should survive")
	assertCondition(entries[1].name == "Good", "The renderable entry should be kept")
end

tests.achievementsPayloadFillsInSafeDefaults = function()
	local entries = UIControlRules.sanitizeAchievementsPayload({
		{ stat = "totalRuns", name = "Sparse", threshold = 10 },
	})

	assertCondition(entries[1].progress == 0, "Missing progress defaults to zero")
	assertCondition(entries[1].rewardCoins == 0, "Missing reward defaults to zero")
	assertCondition(entries[1].tier == "Bronze", "Missing tier defaults to the lowest")
	assertCondition(entries[1].unlocked == false, "Missing unlocked defaults to false")
end

tests.achievementsPayloadToleratesAMalformedResponse = function()
	assertCondition(
		#UIControlRules.sanitizeAchievementsPayload(nil) == 0,
		"A missing payload yields no entries rather than erroring"
	)
	assertCondition(
		#UIControlRules.sanitizeAchievementsPayload("nonsense") == 0,
		"A non-table payload yields no entries rather than erroring"
	)
	assertCondition(
		#UIControlRules.sanitizeAchievementsPayload({}) == 0,
		"An empty payload yields no entries"
	)
end

tests.panelResponseTimeoutIsUsable = function()
	assertCondition(
		typeof(UIControlRules.PanelResponseTimeoutSeconds) == "number"
			and UIControlRules.PanelResponseTimeoutSeconds > 0,
		"Panels need a positive response deadline to fall back to"
	)
end

function UIControlRulesTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return UIControlRulesTests
