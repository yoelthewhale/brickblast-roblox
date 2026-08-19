local Achievements = {}

Achievements.Definitions = {
	{
		id = "SCORE_BRONZE",
		stat = "bestScore",
		tier = "Bronze",
		threshold = 500,
		name = "Rising Star",
		rewardCoins = 25,
	},
	{
		id = "SCORE_SILVER",
		stat = "bestScore",
		tier = "Silver",
		threshold = 2000,
		name = "High Scorer",
		rewardCoins = 60,
	},
	{
		id = "SCORE_GOLD",
		stat = "bestScore",
		tier = "Gold",
		threshold = 5000,
		name = "Puzzle Master",
		rewardCoins = 150,
	},
	{
		id = "COMBO_BRONZE",
		stat = "highestCombo",
		tier = "Bronze",
		threshold = 3,
		name = "Combo Starter",
		rewardCoins = 20,
	},
	{
		id = "COMBO_SILVER",
		stat = "highestCombo",
		tier = "Silver",
		threshold = 6,
		name = "Combo Chainer",
		rewardCoins = 50,
	},
	{
		id = "COMBO_GOLD",
		stat = "highestCombo",
		tier = "Gold",
		threshold = 10,
		name = "Combo Legend",
		rewardCoins = 120,
	},
	{
		id = "STAGE_BRONZE",
		stat = "highestStage",
		tier = "Bronze",
		threshold = 3,
		name = "Stage Climber",
		rewardCoins = 25,
	},
	{
		id = "STAGE_SILVER",
		stat = "highestStage",
		tier = "Silver",
		threshold = 6,
		name = "Stage Veteran",
		rewardCoins = 60,
	},
	{
		id = "STAGE_GOLD",
		stat = "highestStage",
		tier = "Gold",
		threshold = 10,
		name = "Stage Champion",
		rewardCoins = 150,
	},
	{
		id = "PERFECT_BRONZE",
		stat = "totalPerfectClears",
		tier = "Bronze",
		threshold = 1,
		name = "Clean Sweep",
		rewardCoins = 30,
	},
	{
		id = "PERFECT_SILVER",
		stat = "totalPerfectClears",
		tier = "Silver",
		threshold = 10,
		name = "Immaculate",
		rewardCoins = 75,
	},
	{
		id = "PERFECT_GOLD",
		stat = "totalPerfectClears",
		tier = "Gold",
		threshold = 30,
		name = "Perfectionist",
		rewardCoins = 175,
	},
	{
		id = "LINES_BRONZE",
		stat = "totalLinesCleared",
		tier = "Bronze",
		threshold = 50,
		name = "Line Clearer",
		rewardCoins = 20,
	},
	{
		id = "LINES_SILVER",
		stat = "totalLinesCleared",
		tier = "Silver",
		threshold = 250,
		name = "Line Crusher",
		rewardCoins = 55,
	},
	{
		id = "LINES_GOLD",
		stat = "totalLinesCleared",
		tier = "Gold",
		threshold = 750,
		name = "Line Annihilator",
		rewardCoins = 140,
	},
	{
		id = "BLOCKS_BRONZE",
		stat = "totalBlocksPlaced",
		tier = "Bronze",
		threshold = 200,
		name = "Builder",
		rewardCoins = 20,
	},
	{
		id = "BLOCKS_SILVER",
		stat = "totalBlocksPlaced",
		tier = "Silver",
		threshold = 1000,
		name = "Architect",
		rewardCoins = 55,
	},
	{
		id = "BLOCKS_GOLD",
		stat = "totalBlocksPlaced",
		tier = "Gold",
		threshold = 3000,
		name = "Master Builder",
		rewardCoins = 140,
	},
	{
		id = "RUNS_BRONZE",
		stat = "totalRuns",
		tier = "Bronze",
		threshold = 5,
		name = "Regular",
		rewardCoins = 20,
	},
	{
		id = "RUNS_SILVER",
		stat = "totalRuns",
		tier = "Silver",
		threshold = 25,
		name = "Dedicated",
		rewardCoins = 55,
	},
	{
		id = "RUNS_GOLD",
		stat = "totalRuns",
		tier = "Gold",
		threshold = 75,
		name = "Devoted",
		rewardCoins = 140,
	},
}

-- bestScore is intentionally absent: it already exists as leaderstats.BestScore,
-- callers merge that in alongside these when building a lifetimeStats table.
Achievements.DefaultLifetimeStats = {
	highestCombo = 0,
	highestStage = 1,
	totalPerfectClears = 0,
	totalLinesCleared = 0,
	totalBlocksPlaced = 0,
	totalRuns = 0,
}

-- Upper bounds for saved lifetime stats. A profile is player-influenced data
-- read back from a DataStore, so every field is clamped on load rather than
-- trusted -- these are the ceilings a legitimate player can never reach.
Achievements.LifetimeStatLimits = {
	highestCombo = 999,
	highestStage = 1000,
	totalPerfectClears = 1000000,
	totalLinesCleared = 100000000,
	totalBlocksPlaced = 100000000,
	totalRuns = 10000000,
}

-- The floor for each stat. Stage counts from 1; everything else from 0.
local function minimumForStat(key)
	return if key == "highestStage" then 1 else 0
end

local function isFiniteNumber(value)
	return typeof(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

-- Clamp a saved lifetime-stat table into something safe to use, matching
-- StageProgression.sanitize and HandGenerator.sanitizeAssistance.
--
-- Returns the clean table and the number of fields that had to be corrected,
-- which the server folds into its analytics counter.
function Achievements.sanitizeLifetimeStats(raw)
	local source = if typeof(raw) == "table" then raw else {}
	local clean = {}
	local corrected = 0

	for key, defaultValue in Achievements.DefaultLifetimeStats do
		local value = source[key]
		if isFiniteNumber(value) then
			local clamped = math.clamp(
				math.floor(value),
				minimumForStat(key),
				Achievements.LifetimeStatLimits[key]
			)
			clean[key] = clamped
			if clamped ~= value then
				corrected += 1
			end
		else
			clean[key] = defaultValue
			if value ~= nil then
				corrected += 1
			end
		end
	end

	return clean, corrected
end

function Achievements.getDefinition(id)
	for _, definition in Achievements.Definitions do
		if definition.id == id then
			return definition
		end
	end

	return nil
end

function Achievements.isUnlocked(definition, lifetimeStats)
	if not definition or not lifetimeStats then
		return false
	end

	local value = lifetimeStats[definition.stat]
	return typeof(value) == "number" and value >= definition.threshold
end

-- Returns the definitions that just crossed their threshold: unlocked by
-- lifetimeStats but not yet present (== true) in alreadyUnlocked.
function Achievements.newlyUnlocked(lifetimeStats, alreadyUnlocked)
	alreadyUnlocked = alreadyUnlocked or {}
	local newly = {}

	for _, definition in Achievements.Definitions do
		if
			alreadyUnlocked[definition.id] ~= true
			and Achievements.isUnlocked(definition, lifetimeStats)
		then
			table.insert(newly, definition)
		end
	end

	return newly
end

return Achievements
