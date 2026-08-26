local ClearPraise = require(script.Parent.ClearPraise)

local ClearPraiseTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local tests = {}

tests.noClearEarnsNoPraise = function()
	assertCondition(ClearPraise.forEffect({ linesCleared = 0 }) == nil, "0 lines must not praise")
	assertCondition(ClearPraise.forEffect({}) == nil, "A placement with no clear must not praise")
end

-- This reads a network payload, and a praise burst is never worth a client
-- error. Every one of these used to be a live crash path in the handler that
-- consumed `effect` directly.
tests.garbageInputNeverErrors = function()
	local junk = { nil, 5, "clear", true, {}, { linesCleared = "two" }, { linesCleared = 0 / 0 } }
	for index = 1, 7 do
		local ok = pcall(function()
			ClearPraise.forEffect(junk[index])
		end)
		assertCondition(ok, `forEffect errored on garbage input #{index}`)
	end
	assertCondition(ClearPraise.forEffect(nil) == nil, "nil must be silent, not an error")
	assertCondition(ClearPraise.forEffect(5) == nil, "A number must be silent")
	assertCondition(
		ClearPraise.forEffect({ linesCleared = "two" }) == nil,
		"A non-numeric line count must be silent"
	)
	assertCondition(
		ClearPraise.forEffect({ linesCleared = 0 / 0 }) == nil,
		"NaN lines must be silent rather than praising"
	)
end

tests.oneLineIsAcknowledgedQuietly = function()
	local praise = ClearPraise.forEffect({ linesCleared = 1 })
	assertCondition(praise ~= nil, "A single line should still say something")
	assertCondition(praise.tier == "quiet", `A single line should be quiet, got {praise.tier}`)
end

tests.moreLinesEarnLouderPraise = function()
	local previous = -1
	for lines = 1, 4 do
		local praise = ClearPraise.forEffect({ linesCleared = lines })
		assertCondition(praise ~= nil, `{lines} lines should praise`)
		assertCondition(
			praise.rank > previous,
			`Praise must escalate with line count: {lines} lines ranked {praise.rank}, `
				.. `not above the previous {previous}`
		)
		previous = praise.rank
	end
end

-- The failure this guards is subtle and total: if the ceiling is reachable by
-- an ordinary clear, every clear looks like the best clear and the whole
-- system stops carrying information.
tests.theTopTierStaysRare = function()
	local ordinary = {
		{ linesCleared = 1 },
		{ linesCleared = 1, comboStreak = 2 },
		{ linesCleared = 2 },
		{ linesCleared = 2, comboStreak = 2 },
	}
	for index, effect in ordinary do
		local praise = ClearPraise.forEffect(effect)
		assertCondition(
			praise.tier ~= "amazing",
			`Ordinary clear #{index} reached the top tier; it must stay rare`
		)
	end
end

tests.comboStreakAloneCanEscalate = function()
	local flat = ClearPraise.forEffect({ linesCleared = 1, comboStreak = 1 })
	local streaking = ClearPraise.forEffect({ linesCleared = 1, comboStreak = 5 })
	assertCondition(
		streaking.rank > flat.rank,
		"A deep streak on one line should out-rank the same clear with no streak"
	)
end

tests.perfectClearAlwaysTopsOut = function()
	-- Even the smallest possible perfect clear outranks everything else,
	-- because the rarity is in the board state, not the line count.
	local praise = ClearPraise.forEffect({ linesCleared = 1, perfectClear = true })
	assertCondition(praise.tier == "amazing", "A perfect clear must reach the top tier")
	assertCondition(praise.text == "PERFECT!", "A perfect clear should name itself")
end

tests.everyResultIsRenderable = function()
	local cases = {
		{ linesCleared = 1 },
		{ linesCleared = 2 },
		{ linesCleared = 3 },
		{ linesCleared = 4 },
		{ linesCleared = 1, comboStreak = 9 },
		{ linesCleared = 2, perfectClear = true },
	}
	for index, effect in cases do
		local praise = ClearPraise.forEffect(effect)
		assertCondition(
			typeof(praise.text) == "string" and #praise.text > 0,
			`#{index} has no text`
		)
		assertCondition(ClearPraise.Tiers[praise.tier] ~= nil, `#{index} has an unknown tier`)
		assertCondition(
			ClearPraise.Tiers[praise.tier].rank == praise.rank,
			`#{index} rank disagrees with its tier`
		)
	end
end

function ClearPraiseTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return ClearPraiseTests
