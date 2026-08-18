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

tests.boardGridInvariant = function()
	local childClassNames = { "UIPadding", "UIGridLayout" }
	for _ = 1, 64 do
		table.insert(childClassNames, "TextButton")
	end

	local valid, buttonCount = UIControlRules.boardGridChildrenAreValid(childClassNames)
	assertCondition(valid, "Board grid should allow only layout helpers and 64 cell buttons")
	assertCondition(buttonCount == 64, "Board grid should count exactly 64 cells")

	table.insert(childClassNames, "Frame")
	assertCondition(
		not UIControlRules.boardGridChildrenAreValid(childClassNames),
		"Decorative direct children should be rejected"
	)
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
