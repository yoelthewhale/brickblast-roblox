local GameplayRules = require(script.Parent.GameplayRules)

local GameplayRulesTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local tests = {}

tests.comboBonusForStreakMatchesFormula = function()
	assertCondition(GameplayRules.comboBonusForStreak(0) == 0, "streak 0 should have no bonus")
	assertCondition(GameplayRules.comboBonusForStreak(1) == 0, "streak 1 should have no bonus")
	assertCondition(
		GameplayRules.comboBonusForStreak(2) == 25,
		"streak 2 should give one bonus unit"
	)
	assertCondition(
		GameplayRules.comboBonusForStreak(5) == 100,
		"streak 5 should give four bonus units"
	)
end

tests.scoreForPlacementMatchesFormula = function()
	local scoreDelta, comboBonus = GameplayRules.scoreForPlacement(4, 0, 1)
	assertCondition(scoreDelta == 40, "four placed cells with no clear should score 40")
	assertCondition(comboBonus == 0, "no combo bonus without a streak above 1")

	scoreDelta, comboBonus = GameplayRules.scoreForPlacement(4, 2, 3)
	assertCondition(comboBonus == 50, "streak 3 should give two bonus units")
	assertCondition(scoreDelta == 290, "cells + lines + combo bonus should sum to 290")
end

tests.assistanceRestoreAmountTracksIndividualTriggers = function()
	local amount, triggers =
		GameplayRules.assistanceRestoreAmount(0, { stagesAdvanced = 2, perfectClear = false })
	assertCondition(amount == 2, "two stages advanced should restore two units")
	assertCondition(triggers.stageAdvanced == true, "stage advance trigger should be flagged")
	assertCondition(
		triggers.comboMilestone == false,
		"combo milestone should not fire without a streak"
	)
	assertCondition(triggers.perfectClear == false, "perfect clear should not fire when false")

	amount, triggers =
		GameplayRules.assistanceRestoreAmount(3, { stagesAdvanced = 0, perfectClear = false })
	assertCondition(amount == 1, "hitting the combo milestone should restore one unit")
	assertCondition(triggers.comboMilestone == true, "combo milestone trigger should be flagged")

	amount, triggers =
		GameplayRules.assistanceRestoreAmount(0, { stagesAdvanced = 0, perfectClear = true })
	assertCondition(amount == 2, "a perfect clear should restore two units")
	assertCondition(triggers.perfectClear == true, "perfect clear trigger should be flagged")

	amount, triggers =
		GameplayRules.assistanceRestoreAmount(3, { stagesAdvanced = 1, perfectClear = true })
	assertCondition(amount == 4, "all three triggers together should sum to four")
	assertCondition(
		triggers.stageAdvanced and triggers.comboMilestone and triggers.perfectClear,
		"all three triggers should be flagged together"
	)

	amount, triggers = GameplayRules.assistanceRestoreAmount(1, nil)
	assertCondition(amount == 0, "no triggers should restore nothing")
	assertCondition(
		not triggers.stageAdvanced and not triggers.comboMilestone and not triggers.perfectClear,
		"no triggers should be flagged"
	)
end

tests.describeAssistanceTriggersJoinsReasons = function()
	local description = GameplayRules.describeAssistanceTriggers({
		stageAdvanced = true,
		comboMilestone = true,
		perfectClear = true,
	})
	assertCondition(
		description == "stage advanced, combo milestone, perfect clear",
		"description should join all active triggers in order"
	)

	description = GameplayRules.describeAssistanceTriggers({
		stageAdvanced = false,
		comboMilestone = false,
		perfectClear = false,
	})
	assertCondition(description == "none", "description should report none when nothing triggered")
end

function GameplayRulesTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return GameplayRulesTests
