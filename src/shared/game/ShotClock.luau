-- The Spicy shot clock: place a piece before it runs out, or the run ends.
--
-- Pure, and deliberately separate from GameServer. Two reasons.
--
-- First, this decides when a player's run ends, which makes it exactly the
-- kind of rule that needs tests -- and GameServer, a 3600-line script holding
-- remotes and DataStores, is not testable from the Lune harness.
--
-- Second, GameServer sits two top-level locals from Luau's 200-register
-- ceiling (see scripts/check-local-registers.luau). Growing the timer inline
-- there would spend budget the project does not have.
--
-- Authority note: every function here takes `now` rather than reading the
-- clock itself, so the caller decides the time source. The server passes
-- os.clock(); tests pass whatever they need. The client is never the source --
-- a shot clock the client owns is a shot clock the client can pause.

local Config = require(script.Parent.Config)

local ShotClock = {}

local function profileFor(difficultyId)
	if typeof(difficultyId) ~= "string" then
		return nil
	end
	return Config.Difficulties.Profiles[difficultyId]
end

local function isFiniteNumber(value)
	return typeof(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

-- How long a placement gets on this difficulty, or nil when it is untimed.
-- Untimed is the honest answer for Chill and Classic: returning 0 would make
-- every consumer that treats a number as "there is a clock" show one, which is
-- the bug that had Solo rendering a frozen "Time: 0s" for a whole run.
function ShotClock.secondsFor(difficultyId)
	local profile = profileFor(difficultyId)
	if not profile then
		return nil
	end

	local seconds = profile.placementSeconds
	if not isFiniteNumber(seconds) or seconds <= 0 then
		return nil
	end

	return seconds
end

function ShotClock.isTimed(difficultyId)
	return ShotClock.secondsFor(difficultyId) ~= nil
end

-- The deadline for the placement starting now, or nil on an untimed profile.
function ShotClock.deadlineFrom(now, difficultyId)
	local seconds = ShotClock.secondsFor(difficultyId)
	if not seconds or not isFiniteNumber(now) then
		return nil
	end

	return now + seconds
end

function ShotClock.secondsLeft(deadline, now)
	if not isFiniteNumber(deadline) or not isFiniteNumber(now) then
		return nil
	end

	return math.max(0, deadline - now)
end

-- Expiry is strictly "now is past the deadline". A run must never end on the
-- exact tick the clock reaches zero from rounding alone -- the player who
-- placed on the last instant placed in time.
function ShotClock.hasExpired(deadline, now)
	if not isFiniteNumber(deadline) or not isFiniteNumber(now) then
		return false
	end

	return now > deadline
end

-- What the HUD should show. Returns nil on untimed runs so the client can hide
-- the readout entirely rather than render a placeholder.
function ShotClock.displaySecondsLeft(deadline, now)
	local left = ShotClock.secondsLeft(deadline, now)
	if left == nil then
		return nil
	end

	return math.max(0, math.ceil(left))
end

return ShotClock
