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
	assertCondition(
		UIControlRules.canFireServerAction(1, 1.45),
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
