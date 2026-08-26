local Config = require(script.Parent.Config)
local ShotClock = require(script.Parent.ShotClock)

local ShotClockTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local tests = {}

tests.onlySpicyIsTimed = function()
	assertCondition(ShotClock.isTimed("spicy"), "Spicy should be timed")
	assertCondition(not ShotClock.isTimed("chill"), "Chill must never be timed")
	assertCondition(not ShotClock.isTimed("classic"), "Classic must never be timed")
end

-- Untimed has to be nil, not 0. A consumer that treats any number as "there is
-- a clock" will render one, which is exactly how Solo ended up showing a
-- frozen "Time: 0s" for entire runs before this distinction was enforced.
tests.untimedMeansNilNotZero = function()
	assertCondition(ShotClock.secondsFor("chill") == nil, "Chill must report nil, not 0")
	assertCondition(ShotClock.deadlineFrom(100, "chill") == nil, "An untimed run has no deadline")
	assertCondition(
		ShotClock.displaySecondsLeft(nil, 100) == nil,
		"With no deadline there is nothing to display"
	)
end

tests.garbageInputNeverErrorsOrInventsAClock = function()
	local junk = { nil, 5, "spicy!", true, {}, 0 / 0, math.huge }
	for index = 1, 7 do
		local ok = pcall(function()
			ShotClock.secondsFor(junk[index])
			ShotClock.deadlineFrom(junk[index], junk[index])
			ShotClock.hasExpired(junk[index], junk[index])
			ShotClock.secondsLeft(junk[index], junk[index])
		end)
		assertCondition(ok, `ShotClock errored on garbage input #{index}`)
	end

	assertCondition(ShotClock.secondsFor("nonsense") == nil, "An unknown difficulty has no clock")
	assertCondition(
		ShotClock.deadlineFrom(0 / 0, "spicy") == nil,
		"A NaN clock reading must not produce a deadline"
	)
	-- The dangerous direction: a garbage deadline that reads as expired would
	-- end a run the player was still playing.
	assertCondition(
		ShotClock.hasExpired(0 / 0, 100) == false,
		"A NaN deadline must never end a run"
	)
	assertCondition(ShotClock.hasExpired(nil, 100) == false, "No deadline must never end a run")
end

tests.aDeadlineIsTheProfileLengthAway = function()
	local seconds = ShotClock.secondsFor("spicy")
	local deadline = ShotClock.deadlineFrom(1000, "spicy")
	assertCondition(deadline == 1000 + seconds, "The deadline should be `now` plus the allowance")
end

-- The boundary that decides runs. Placing on the exact instant the clock shows
-- zero is placing in time; only passing it is not.
tests.expiryIsStrictlyPastTheDeadline = function()
	local deadline = ShotClock.deadlineFrom(0, "spicy")
	assertCondition(not ShotClock.hasExpired(deadline, 0), "A fresh clock has not expired")
	assertCondition(
		not ShotClock.hasExpired(deadline, deadline),
		"Landing exactly on the deadline must count as in time, not as a loss"
	)
	assertCondition(
		ShotClock.hasExpired(deadline, deadline + 0.001),
		"A moment past the deadline must expire"
	)
end

tests.remainingTimeCountsDownAndFloorsAtZero = function()
	local deadline = ShotClock.deadlineFrom(0, "spicy")
	local previous = math.huge
	for now = 0, 12 do
		local left = ShotClock.secondsLeft(deadline, now)
		assertCondition(left <= previous, `Remaining time went up between {now - 1} and {now}`)
		assertCondition(left >= 0, "Remaining time must never go negative")
		previous = left
	end
	assertCondition(
		ShotClock.secondsLeft(deadline, 9999) == 0,
		"Long past the deadline should read 0, not a negative number"
	)
end

tests.theDisplayNeverShowsZeroWhileTimeRemains = function()
	-- Ceil rather than floor: a readout that shows 0 while the player still has
	-- most of a second left tells them they have already lost when they have
	-- not.
	local deadline = ShotClock.deadlineFrom(0, "spicy")
	assertCondition(
		ShotClock.displaySecondsLeft(deadline, deadline - 0.4) >= 1,
		"With time still on the clock the display must not read 0"
	)
	assertCondition(
		ShotClock.displaySecondsLeft(deadline, deadline) == 0,
		"At the deadline the display should read 0"
	)
end

tests.everyDifficultyProfileIsHandled = function()
	for _, difficultyId in Config.Difficulties.Order do
		local ok = pcall(function()
			ShotClock.secondsFor(difficultyId)
		end)
		assertCondition(ok, `ShotClock could not handle the "{difficultyId}" profile`)
	end
end

function ShotClockTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return ShotClockTests
