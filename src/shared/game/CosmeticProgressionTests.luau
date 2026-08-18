-- Guards one invariant: every cosmetic must be reachable by a player of the
-- modes that are actually switched on. Four cosmetics shipped requiring story
-- stars while Story mode was disabled, which made them permanent dead ends
-- with a visible requirement label the player could never satisfy.

local Config = require(script.Parent.Config)
local ExperienceConfig = require(script.Parent.ExperienceConfig)

local CosmeticProgressionTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

-- The best progress a Solo player can reach. Levels and coins both grow from
-- Solo runs without limit, so a requirement on either is satisfiable; story
-- stars only come from Story-mission completion.
local function maximumReachableProgress()
	return {
		level = math.huge,
		coins = math.huge,
		storyStars = ExperienceConfig.isModeEnabled("Story") and math.huge or 0,
	}
end

local tests = {}

tests.everyCosmeticIsReachableWithTheEnabledModes = function()
	local reachable = maximumReachableProgress()

	for _, cosmetic in Config.Cosmetics do
		if cosmetic.requiredGamePass == nil then
			assertCondition(
				Config.meetsCosmeticRequirement(cosmetic.requirement, reachable),
				`{cosmetic.id} cannot be unlocked by any player of the currently enabled modes`
			)
		end
	end
end

tests.skinUnlockTablesAreReachableToo = function()
	local reachable = maximumReachableProgress()

	for skinName, requirement in Config.PieceSkinUnlocks do
		assertCondition(
			Config.meetsCosmeticRequirement(requirement, reachable),
			`Piece skin {skinName} is gated behind progress no enabled mode grants`
		)
	end

	for skinName, requirement in Config.BoardSkinUnlocks do
		assertCondition(
			Config.meetsCosmeticRequirement(requirement, reachable),
			`Board skin {skinName} is gated behind progress no enabled mode grants`
		)
	end
end

tests.everyCosmeticRequirementHasAPlayerFacingLabel = function()
	-- The shop shows requirement.label verbatim, so a retargeted requirement
	-- left with a stale label would tell the player to do the wrong thing.
	local storyEnabled = ExperienceConfig.isModeEnabled("Story")

	local function checkLabel(kind, skinName, requirement)
		assertCondition(
			typeof(requirement.label) == "string" and requirement.label ~= "",
			`{kind} {skinName} has no unlock label to show`
		)
		assertCondition(
			storyEnabled or not string.find(requirement.label, "Story"),
			`{kind} {skinName} still advertises a Story requirement while Story is off`
		)
	end

	for skinName, requirement in Config.PieceSkinUnlocks do
		checkLabel("Piece skin", skinName, requirement)
	end

	for skinName, requirement in Config.BoardSkinUnlocks do
		checkLabel("Board skin", skinName, requirement)
	end
end

function CosmeticProgressionTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return CosmeticProgressionTests
