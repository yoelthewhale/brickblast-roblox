local Config = require(script.Parent.Config)
local SimulationHarness = require(script.Parent.SimulationHarness)

local SimulationHarnessTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local function runStrategy(strategy, seed)
	return SimulationHarness.run({
		strategy = strategy,
		seed = seed,
		maxPlacements = 120,
		candidateLimit = Config.HandGeneration.CandidateLimit,
	})
end

local tests = {}

tests.strategiesReturnBoundedResults = function()
	for _, strategy in { "smart", "random", "spam", "poor" } do
		local result = runStrategy(strategy, 4242)
		assertCondition(result.placements <= 120, `{strategy} exceeded placement cap`)
		assertCondition(
			typeof(result.reason) == "string",
			`{strategy} should report a finish reason`
		)
		assertCondition(result.highestStage >= 1, `{strategy} should report stage progress`)
	end
end

tests.identicalSeedsMatch = function()
	local first = runStrategy("smart", 5151)
	local second = runStrategy("smart", 5151)

	assertCondition(first.score == second.score, "Identical seeds should match score")
	assertCondition(
		first.placements == second.placements,
		"Identical seeds should match placements"
	)
	assertCondition(
		first.linesCleared == second.linesCleared,
		"Identical seeds should match line clears"
	)
end

tests.poorStrategiesCanLose = function()
	local losses = 0
	for _, seed in { 11, 12, 13, 14, 15 } do
		local result = runStrategy("poor", seed)
		if result.gameOver then
			losses += 1
		end
	end

	assertCondition(losses >= 3, "Poor strategy should frequently reach game over")
end

tests.spamStrategiesCanLose = function()
	local losses = 0
	for _, seed in { 21, 22, 23, 24, 25 } do
		local result = runStrategy("spam", seed)
		if result.gameOver then
			losses += 1
		end
	end

	assertCondition(losses >= 3, "Spam strategy should frequently reach game over")
end

tests.smartOutperformsPoorOnFixedSeed = function()
	local smart = runStrategy("smart", 6262)
	local poor = runStrategy("poor", 6262)

	assertCondition(
		smart.score >= poor.score,
		"Smart strategy should not score below poor strategy"
	)
	assertCondition(
		smart.linesCleared >= poor.linesCleared,
		"Smart strategy should not clear fewer lines than poor strategy"
	)
end

tests.unknownStrategyErrors = function()
	local ok = pcall(runStrategy, "not-a-real-strategy", 31)
	assertCondition(not ok, "Unknown strategy should error instead of silently succeeding")
end

tests.assistanceDoesNotDrainAcrossRuns = function()
	-- The spiral this guards against: assistance charged on every crowded hand
	-- whether or not it changed the hand, so the budget drained faster than the
	-- positive-outcome triggers could refill it, and the players who most
	-- needed rescue were the least able to earn it back.
	--
	-- This is a cheap property guard, not the regression test for that bug --
	-- it passes on the old generator at this sample size, because whether any
	-- four seeds happen to drain is noisy. The deterministic coverage lives in
	-- HandGeneratorTests, where "a rescue the base scorer would have made
	-- anyway must not spend assistance" fails outright on the old behaviour.
	-- What this adds is a floor: if spending ever starts outrunning
	-- restoration again in aggregate, it trips.
	local totalUsed = 0
	local totalRestored = 0

	for _, seed in { 21, 22, 23, 24 } do
		local result = runStrategy("spam", seed)
		totalUsed += result.assistanceUsed
		totalRestored += result.fairnessFloorTriggers.totalRestored
	end

	assertCondition(
		totalRestored >= totalUsed,
		`Assistance should not drain over a run: used {totalUsed}, restored {totalRestored}`
	)
end

function SimulationHarnessTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return SimulationHarnessTests
