local Achievements = require(script.Parent.Achievements)

local AchievementsTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local tests = {}

tests.isUnlockedRespectsThreshold = function()
	local definition = Achievements.getDefinition("COMBO_BRONZE")
	assertCondition(definition ~= nil, "COMBO_BRONZE should exist")
	assertCondition(
		not Achievements.isUnlocked(definition, { highestCombo = definition.threshold - 1 }),
		"below threshold should not unlock"
	)
	assertCondition(
		Achievements.isUnlocked(definition, { highestCombo = definition.threshold }),
		"meeting threshold exactly should unlock"
	)
end

tests.isUnlockedRejectsMissingOrNonNumericStats = function()
	local definition = Achievements.getDefinition("RUNS_BRONZE")
	assertCondition(not Achievements.isUnlocked(definition, {}), "missing stat should not unlock")
	assertCondition(
		not Achievements.isUnlocked(definition, { totalRuns = "5" }),
		"non-numeric stat should not unlock"
	)
end

tests.newlyUnlockedMatchesEveryDefinitionWhenMaxed = function()
	local lifetimeStats = {
		bestScore = 999999,
		highestCombo = 999,
		highestStage = 999,
		totalPerfectClears = 999,
		totalLinesCleared = 999999,
		totalBlocksPlaced = 999999,
		totalRuns = 999999,
	}
	local newly = Achievements.newlyUnlocked(lifetimeStats, {})
	assertCondition(
		#newly == #Achievements.Definitions,
		"maxed stats should unlock every achievement the first time"
	)
end

tests.newlyUnlockedExcludesAlreadySeenAchievements = function()
	local lifetimeStats = { totalRuns = Achievements.getDefinition("RUNS_GOLD").threshold }
	local firstPass = Achievements.newlyUnlocked(lifetimeStats, {})

	local alreadyUnlocked = {}
	for _, definition in firstPass do
		alreadyUnlocked[definition.id] = true
	end

	local secondPass = Achievements.newlyUnlocked(lifetimeStats, alreadyUnlocked)
	assertCondition(#secondPass == 0, "already-unlocked achievements should not repeat")
end

tests.tiersUnlockIndependentlyAtTheirOwnThreshold = function()
	local lifetimeStats = { totalRuns = Achievements.getDefinition("RUNS_BRONZE").threshold }
	local newly = Achievements.newlyUnlocked(lifetimeStats, {})

	local unlockedIds = {}
	for _, definition in newly do
		unlockedIds[definition.id] = true
	end

	assertCondition(unlockedIds.RUNS_BRONZE == true, "bronze tier should unlock at its threshold")
	assertCondition(unlockedIds.RUNS_SILVER == nil, "silver tier should not unlock early")
	assertCondition(unlockedIds.RUNS_GOLD == nil, "gold tier should not unlock early")
end

function AchievementsTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return AchievementsTests
