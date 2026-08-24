-- Which celebration a line clear earns, and what it says.
--
-- Split out from the client on purpose. The *rendering* of a praise burst is
-- presentation and lives in ArcadeUI; the *decision* -- how impressive was
-- that clear, and therefore how loud should the game be about it -- is game
-- rules, and rules that nobody can see are rules nobody notices breaking.
-- Putting it here makes it testable, and it is: a tier that silently stops
-- escalating turns the whole feature into noise.
--
-- Reference behaviour (docs/VISUAL_DIRECTION.md): the game shouts louder as
-- the clear gets harder, topping out at a full-width multi-colour burst. The
-- ceiling has to be rare or it stops meaning anything, so only the genuinely
-- hard clears reach it.

local ClearPraise = {}

-- Ordered weakest to strongest. `tier` is what ArcadeUI renders against;
-- `rank` exists so callers (and tests) can compare two results without
-- knowing the tier names.
ClearPraise.Tiers = {
	quiet = { rank = 0 },
	good = { rank = 1 },
	great = { rank = 2 },
	amazing = { rank = 3 },
}

local function isPositiveNumber(value)
	return typeof(value) == "number" and value == value and value > 0
end

local function cleanCount(value)
	if not isPositiveNumber(value) then
		return 0
	end
	return math.floor(value)
end

-- The single entry point. Takes the effect payload the server already sends
-- on a placement, returns nil when the clear does not deserve a burst.
--
-- Deliberately tolerant of missing fields: this reads a network payload, and
-- a praise burst is never worth a client error.
function ClearPraise.forEffect(effect)
	if typeof(effect) ~= "table" then
		return nil
	end

	local lines = cleanCount(effect.linesCleared)
	if lines <= 0 then
		return nil
	end

	local combo = cleanCount(effect.comboStreak)
	local perfect = effect.perfectClear == true

	-- A perfect clear is the rarest thing in the game and always tops out,
	-- regardless of how it was reached.
	if perfect then
		return { text = "PERFECT!", tier = "amazing", rank = 3, lines = lines, combo = combo }
	end

	-- Four lines at once, or a deep combo streak. Both are hard enough to be
	-- worth the loudest treatment the game has short of a perfect clear.
	if lines >= 4 or combo >= 5 then
		return { text = "UNBELIEVABLE!", tier = "amazing", rank = 3, lines = lines, combo = combo }
	end

	if lines >= 3 or combo >= 3 then
		return { text = "FANTASTIC!", tier = "great", rank = 2, lines = lines, combo = combo }
	end

	if lines >= 2 or combo >= 2 then
		return { text = "GREAT!", tier = "good", rank = 1, lines = lines, combo = combo }
	end

	-- A single line with no streak. Still acknowledged, but quietly -- this is
	-- the most common event in the game and shouting about it would drown out
	-- everything above.
	return { text = "NICE!", tier = "quiet", rank = 0, lines = lines, combo = combo }
end

return ClearPraise
