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

tests.sanitizeLifetimeStatsFillsEveryDefinedStat = function()
	local clean, corrected = Achievements.sanitizeLifetimeStats(nil)

	for key, defaultValue in Achievements.DefaultLifetimeStats do
		assertCondition(clean[key] == defaultValue, `Missing {key} should fall back to its default`)
	end
	assertCondition(corrected == 0, "An absent table is not a correction, just a new player")
end

tests.sanitizeLifetimeStatsClampsToTheConfiguredCeilings = function()
	local clean, corrected = Achievements.sanitizeLifetimeStats({
		highestCombo = 99999,
		totalRuns = math.huge,
		totalLinesCleared = -50,
	})

	assertCondition(
		clean.highestCombo == Achievements.LifetimeStatLimits.highestCombo,
		"An impossible combo should clamp to the ceiling"
	)
	assertCondition(clean.totalRuns == 0, "A non-finite run count should fall back to the default")
	assertCondition(clean.totalLinesCleared == 0, "A negative line count should clamp to zero")
	assertCondition(corrected == 3, `Three fields were corrected, counted {corrected}`)
end

tests.sanitizeLifetimeStatsRespectsPerStatFloors = function()
	local clean = Achievements.sanitizeLifetimeStats({ highestStage = 0, highestCombo = 0 })

	assertCondition(clean.highestStage == 1, "Stage counts from one, not zero")
	assertCondition(clean.highestCombo == 0, "Combo legitimately starts at zero")
end

tests.sanitizeLifetimeStatsRejectsNonNumbers = function()
	local clean, corrected = Achievements.sanitizeLifetimeStats({
		highestCombo = "999",
		totalRuns = {},
		totalBlocksPlaced = true,
	})

	assertCondition(clean.highestCombo == 0, "A numeric string is not a number")
	assertCondition(clean.totalRuns == 0, "A table is not a number")
	assertCondition(clean.totalBlocksPlaced == 0, "A boolean is not a number")
	assertCondition(corrected == 3, "Each rejected field counts as a correction")
end

tests.sanitizeLifetimeStatsDropsUnknownKeys = function()
	-- A saved profile could carry fields from an older schema, or ones an
	-- exploiter invented. Only the defined stats survive.
	local clean = Achievements.sanitizeLifetimeStats({ totalRuns = 5, coins = 999999 })

	assertCondition(clean.totalRuns == 5, "A legitimate value passes through")
	assertCondition(clean.coins == nil, "An undefined stat should not be carried over")
end

tests.sanitizeLifetimeStatsTruncatesFractions = function()
	local clean = Achievements.sanitizeLifetimeStats({ totalRuns = 7.9 })

	assertCondition(clean.totalRuns == 7, "Fractional counts should floor to whole numbers")
end

tests.sanitizedStatsFeedTheUnlockCheck = function()
	-- The reason this sanitizer matters: a clamped stat must not hand out an
	-- achievement the player never earned.
	local clean = Achievements.sanitizeLifetimeStats({ totalRuns = "75" })
	local newly = Achievements.newlyUnlocked(clean, {})

	for _, definition in newly do
		assertCondition(
			definition.stat ~= "totalRuns",
			"A rejected run count must not unlock a run achievement"
		)
	end
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
