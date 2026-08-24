-- Visual tokens: the single source of truth for the game's look. See
-- docs/VISUAL_DIRECTION.md for the approved direction and GitHub #98 for the
-- phased rollout.
--
-- The direction changed on 2026-08-23 from the light "Bubblegum Toybox" look to
-- a dark board with saturated beveled blocks, matching a reference Yoel
-- approved. The two-axis architecture below survived that pivot unchanged --
-- only the values moved -- which is the whole reason it was built this way.
--
-- The model has two independent axes over one fixed identity:
--
--   IDENTITY  never varies. A deep indigo room, a darker board well, light
--             ink, and one fixed set of saturated block colors. This is what
--             makes the game recognizable at any moment of any run.
--
--   FLAVOR    varies by stage. Tints the *room and the well* -- never the
--             blocks. The reference shows one fixed multi-colored block set,
--             so piece color is part of the identity now and progression lives
--             behind the board rather than on it.
--
--   ENERGY    varies by run intensity, 0..1, derived from combo streak, stage
--             depth, and perfect clears. Drives rim heat, backdrop lift, and
--             wash strength.
--
-- ENERGY is the load-bearing idea and the one most easily lost: it is what
-- keeps the game from collapsing into a single static palette while still
-- having one coherent identity. The reference is itself a static palette; the
-- deliberate decision was to match its *look* and keep progression alive
-- behind the board. A calm stage 1 room and a stage 12 room mid-hot-streak
-- must read as the same game at different temperatures. Do not "simplify"
-- this away.
--
-- This module is pure: it creates no Instances and reads no game state, so it
-- runs under the headless Lune suite. Keep it that way.

local VisualTokens = {}

-- The fixed half of the identity. Every flavor is built on these, which is
-- what stops stage changes from reading as a different product.
local IDENTITY = {
	-- Light ink on a dark room, the inverse of the previous direction. Not pure
	-- white: a faint blue cast keeps text sitting *in* the scene rather than
	-- punched through it.
	ink = Color3.fromRGB(240, 244, 255),
	inkSoft = Color3.fromRGB(168, 179, 214),
	-- The room the board sits in.
	backdrop = Color3.fromRGB(78, 95, 168),
	-- Panels and cards float slightly above the room.
	surface = Color3.fromRGB(42, 51, 88),
	surfaceRaised = Color3.fromRGB(56, 67, 112),
	-- The board well is markedly darker than the room, which is what makes the
	-- blocks read as lit objects sitting in a recess.
	well = Color3.fromRGB(30, 37, 71),
	cell = Color3.fromRGB(37, 45, 82),
	cellEdge = Color3.fromRGB(50, 59, 102),
	gloss = Color3.fromRGB(255, 255, 255),
	shadow = Color3.fromRGB(16, 20, 40),
}

-- The block colors are fixed identity, not flavor. The reference shows orange,
-- blue, red, gold and cyan coexisting on one board, so tying piece color to
-- stage would fight the look it is meant to match. Progression moved to the
-- room and the well instead -- see FLAVORS.
local BLOCK_PALETTE = {
	Color3.fromRGB(224, 138, 52),
	Color3.fromRGB(58, 86, 200),
	Color3.fromRGB(198, 64, 58),
	Color3.fromRGB(229, 185, 60),
	Color3.fromRGB(84, 192, 232),
}

-- Four flavors keeps `presetCount()` at 4, so the existing stage-cycle math and
-- every current consumer of StageVisuals behave exactly as before.
--
-- These are deliberately close together. They tint the room a player is looking
-- past, not the pieces they are looking at, so the difference between stages
-- should register as "the light changed" rather than "the game changed".
local FLAVORS = {
	{
		id = "indigo",
		name = "Indigo",
		primary = Color3.fromRGB(78, 95, 168),
		secondary = Color3.fromRGB(96, 114, 190),
		tertiary = Color3.fromRGB(30, 37, 71),
		hot = Color3.fromRGB(120, 150, 255),
	},
	{
		id = "teal",
		name = "Deep Teal",
		primary = Color3.fromRGB(52, 110, 148),
		secondary = Color3.fromRGB(68, 132, 170),
		tertiary = Color3.fromRGB(22, 45, 66),
		hot = Color3.fromRGB(86, 200, 224),
	},
	{
		id = "plum",
		name = "Plum",
		primary = Color3.fromRGB(104, 72, 158),
		secondary = Color3.fromRGB(126, 92, 182),
		tertiary = Color3.fromRGB(40, 26, 66),
		hot = Color3.fromRGB(176, 122, 255),
	},
	{
		id = "ember",
		name = "Ember",
		primary = Color3.fromRGB(140, 74, 96),
		secondary = Color3.fromRGB(166, 92, 112),
		tertiary = Color3.fromRGB(54, 24, 38),
		hot = Color3.fromRGB(255, 122, 138),
	},
}

-- How much each signal contributes to energy. Combo dominates because it is
-- the one the player is actively driving; stage is a slow floor that rises
-- across a run; perfect clears are a punctuation bump. The three weights sum
-- to 1.0 so a maxed-out run reaches exactly full energy.
local ENERGY = {
	ComboWeight = 0.55,
	ComboFull = 8,
	StageWeight = 0.30,
	StageFull = 12,
	PerfectWeight = 0.15,
	PerfectFull = 3,
}

-- Non-color tokens. Panels stay chunky, but the board itself does not: the
-- reference's blocks are hard-edged molded tiles with only the corners taken
-- off, so cell and piece radii are small enough to keep a filled row reading
-- as a continuous bar rather than a string of lozenges.
VisualTokens.Radius = {
	cell = 8,
	piece = 6,
	chip = 14,
	card = 20,
	panel = 26,
	pill = 999,
}

VisualTokens.Space = {
	hair = 2,
	tight = 4,
	snug = 6,
	base = 10,
	roomy = 16,
	loose = 24,
}

VisualTokens.Elevation = {
	flat = { offset = 0, blur = 0, transparency = 1 },
	raised = { offset = 3, blur = 6, transparency = 0.72 },
	floating = { offset = 6, blur = 12, transparency = 0.62 },
	lifted = { offset = 10, blur = 20, transparency = 0.55 },
}

-- Gloss is the signature of the plastic-toy look: a bright highlight across
-- the top third of a form. Strength rises slightly with energy.
VisualTokens.Gloss = {
	subtle = 0.82,
	standard = 0.68,
	strong = 0.52,
	heightScale = 0.34,
}

local function isFiniteNumber(value)
	return typeof(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function clampNumber(value, minimum, maximum)
	if not isFiniteNumber(value) then
		return minimum
	end

	return math.max(minimum, math.min(maximum, value))
end

local function cleanStage(stage)
	if not isFiniteNumber(stage) then
		return 1
	end

	return math.max(1, math.floor(stage))
end

local function cleanCount(value)
	if not isFiniteNumber(value) then
		return 0
	end

	return math.max(0, math.floor(value))
end

local function mix(from, to, alpha)
	return from:Lerp(to, clampNumber(alpha, 0, 1))
end

-- Pushes saturation and value up without moving hue, so a color gets hotter
-- rather than becoming a different color. This is how energy intensifies the
-- palette while leaving the flavor recognizable.
local function energize(color, amount)
	local strength = clampNumber(amount, 0, 1)
	local hue, saturation, value = color:ToHSV()
	local nextSaturation = clampNumber(saturation + (1 - saturation) * strength * 0.55, 0, 1)
	local nextValue = clampNumber(value + (1 - value) * strength * 0.25, 0, 1)
	return Color3.fromHSV(hue, nextSaturation, nextValue)
end

-- Proper sRGB relative luminance (WCAG 2.x), gamma-linearized. The naive
-- weighted-average version is wrong by enough to matter when deciding whether
-- a text role clears 4.5:1, and it is wrong in the dangerous direction on a
-- dark chassis: it scores light-on-navy far lower than it really is.
local function relativeLuminance(color)
	local function channel(value)
		if value <= 0.03928 then
			return value / 12.92
		end
		return ((value + 0.055) / 1.055) ^ 2.4
	end

	return 0.2126 * channel(color.R) + 0.7152 * channel(color.G) + 0.0722 * channel(color.B)
end

function VisualTokens.contrastRatio(a, b)
	local first = relativeLuminance(a)
	local second = relativeLuminance(b)
	local lighter = math.max(first, second)
	local darker = math.min(first, second)
	return (lighter + 0.05) / (darker + 0.05)
end

-- Darkens a color, preserving hue and saturation, until it clears `target`
-- contrast against `background`.
--
-- This exists because the chrome palette has now been retuned twice -- once
-- from a near-black arcade cabinet to cream, then from cream to navy.
-- Retuning eight text roles by eye each time is how a redesign ships an
-- accessibility regression; deriving them keeps every role readable
-- automatically, including after someone retunes the flavor anchors.
function VisualTokens.readableOn(color, background, target)
	local goal = clampNumber(target, 1, 21)
	if VisualTokens.contrastRatio(color, background) >= goal then
		return color
	end

	local hue, saturation, value = color:ToHSV()
	local candidate = color

	-- Which way to walk depends on the ground. Against a dark background,
	-- darkening a color makes it *less* readable, so the walk has to go up.
	-- This mattered the moment the direction flipped from a cream game to a
	-- navy one: the darken-only version quietly made every text role worse.
	local towardLight = relativeLuminance(background) < 0.18

	-- Fixed steps rather than a binary search: the space is tiny, and a
	-- deterministic walk keeps results stable across runs, which matters
	-- because these land in tests.
	--
	-- Both walks preserve hue exactly. Scaling every channel toward black
	-- leaves hue and saturation untouched; lerping toward white scales the
	-- channel *differences* uniformly, which also leaves hue untouched while
	-- shedding saturation. That last part is what makes the light walk able
	-- to finish: a saturated blue held at full saturation tops out around
	-- 4.4:1 on the navy chassis no matter how high its value goes, so value
	-- alone cannot clear 4.5:1 and the walk has to be allowed to pale out.
	for step = 1, 100 do
		if towardLight then
			candidate = mix(color, IDENTITY.gloss, step / 100)
		else
			candidate = Color3.fromHSV(hue, saturation, math.max(0, value * (1 - step / 100)))
		end
		if VisualTokens.contrastRatio(candidate, background) >= goal then
			return candidate
		end
	end

	return candidate
end

-- The chassis palette: shaped key-for-key like the old ArcadeUI.Color so all
-- 59 call sites keep working, but derived from the shared identity instead of
-- the "B2 Polished Arcade" near-black cabinet it started as.
--
-- Chrome is deliberately STABLE -- it does not take stage or energy. The
-- chassis is the identity; progression-driven variation belongs on the board
-- and its accents, where StageVisuals.presetForRun already puts it. Making
-- chrome dynamic too would smear the effect across the whole screen and make
-- the energy axis harder to read, not easier.
local TEXT_CONTRAST_TARGET = 4.5

function VisualTokens.chrome()
	local signature = FLAVORS[1]
	local surface = IDENTITY.surface
	local sunken = IDENTITY.well

	-- A text role can land on either ground, so it has to clear the target on
	-- both. Solving against the harder one alone is not enough: which ground
	-- is harder depends on the direction readableOn walks, and that flipped
	-- when the chassis went from cream to navy. Alternating passes converge
	-- because both walks move the same way on a single-polarity chassis.
	local function readable(color)
		local candidate = color
		for _ = 1, 4 do
			candidate = VisualTokens.readableOn(candidate, surface, TEXT_CONTRAST_TARGET)
			candidate = VisualTokens.readableOn(candidate, sunken, TEXT_CONTRAST_TARGET)
			if
				VisualTokens.contrastRatio(candidate, surface) >= TEXT_CONTRAST_TARGET
				and VisualTokens.contrastRatio(candidate, sunken) >= TEXT_CONTRAST_TARGET
			then
				break
			end
		end
		return candidate
	end

	return {
		shell = surface,
		shellTop = IDENTITY.surfaceRaised,
		shellBottom = mix(surface, IDENTITY.shadow, 0.35),
		inner = mix(surface, sunken, 0.55),
		innerBottom = mix(sunken, IDENTITY.shadow, 0.4),
		-- On a dark chassis the edge is the darkest thing present, not the
		-- lightest: panels are cut *out* of the room rather than laid on it.
		edge = IDENTITY.shadow,

		-- Rims are strokes, not text, so they stay saturated.
		rim = signature.primary,
		rimBright = mix(signature.primary, IDENTITY.gloss, 0.35),

		text = IDENTITY.ink,
		muted = readable(IDENTITY.inkSoft),
		score = readable(Color3.fromRGB(229, 185, 60)),
		best = readable(Color3.fromRGB(84, 192, 232)),
		combo = readable(signature.hot),
		gold = readable(Color3.fromRGB(229, 185, 60)),
		silver = readable(Color3.fromRGB(196, 206, 226)),
		bronze = readable(Color3.fromRGB(224, 138, 52)),
	}
end

function VisualTokens.identity()
	return table.clone(IDENTITY)
end

function VisualTokens.flavorCount()
	return #FLAVORS
end

function VisualTokens.flavorForStage(stage)
	local clean = cleanStage(stage)
	local index = ((clean - 1) % #FLAVORS) + 1
	local flavor = table.clone(FLAVORS[index])
	flavor.index = index
	flavor.cycle = math.floor((clean - 1) / #FLAVORS)
	flavor.stageNumber = clean
	return flavor
end

-- Pure mapping from run state to 0..1 intensity. Monotonic in every input and
-- clamped, including for garbage input, so no caller can drive the visuals
-- out of range.
function VisualTokens.energyFor(state)
	if typeof(state) ~= "table" then
		return 0
	end

	local combo = cleanCount(state.comboStreak)
	local stage = cleanStage(state.stage)
	local perfect = cleanCount(state.perfectClears)

	local comboPart = math.min(combo / ENERGY.ComboFull, 1) * ENERGY.ComboWeight
	local stagePart = math.min((stage - 1) / ENERGY.StageFull, 1) * ENERGY.StageWeight
	local perfectPart = math.min(perfect / ENERGY.PerfectFull, 1) * ENERGY.PerfectWeight

	return clampNumber(comboPart + stagePart + perfectPart, 0, 1)
end

-- The full token set for a given stage and energy. Everything downstream --
-- board, pieces, HUD accents, effects, atmosphere -- should read from here
-- rather than hardcoding a color.
function VisualTokens.resolve(stage, energy)
	local flavor = VisualTokens.flavorForStage(stage)
	local heat = clampNumber(energy, 0, 1)

	local primary = energize(flavor.primary, heat)
	local secondary = energize(flavor.secondary, heat * 0.6)
	local tertiary = energize(flavor.tertiary, heat * 0.8)
	local hot = energize(flavor.hot, heat)

	-- Rim and accent travel from the calm primary toward the hot anchor as
	-- the run heats up. This is the most visible expression of energy.
	local rim = mix(primary, hot, heat * 0.75)
	local accent = mix(flavor.secondary, hot, 0.35 + heat * 0.45)

	-- The well deepens slightly with energy so the saturated blocks gain
	-- contrast exactly when the board gets busiest. Capped short of the room
	-- colour so the recess never swallows an empty cell.
	local well = mix(IDENTITY.well, IDENTITY.shadow, 0.12 + heat * 0.2)

	return {
		flavorId = flavor.id,
		flavorName = flavor.name,
		flavorIndex = flavor.index,
		stageNumber = flavor.stageNumber,
		cycle = flavor.cycle,
		energy = heat,

		ink = IDENTITY.ink,
		inkSoft = IDENTITY.inkSoft,
		gloss = IDENTITY.gloss,
		shadow = IDENTITY.shadow,

		surface = IDENTITY.surface,
		surfaceSunken = mix(IDENTITY.surface, IDENTITY.shadow, 0.3),
		surfaceTinted = mix(IDENTITY.surface, primary, 0.25),

		-- The room. This is where progression lives, and it has to stay *deep*.
		--
		-- The first version mixed primary into secondary at ~0.3, which handed
		-- back the flavor at near-full saturation: stage 3 (Plum) rendered as
		-- a bright violet that washed out the board it surrounded and looked
		-- nothing like the game's own logo. The logo is the target here -- a
		-- near-black navy ground with saturated blocks on top -- so the room is
		-- now built the other way round: start from the well and admit only a
		-- fifth of the flavor.
		--
		-- Progression is not weakened by this, it is made legible. Four rooms
		-- separated by hue at the same low luminance read as four rooms; four
		-- rooms separated by brightness read as the game getting louder until
		-- the blocks stop being the brightest thing on screen. Energy still
		-- lifts the room, just within the deep range.
		atmosphere = mix(IDENTITY.well, primary, 0.22 + heat * 0.18),
		atmosphereAccent = mix(IDENTITY.well, primary, 0.34 + heat * 0.2),
		wash = mix(IDENTITY.well, hot, 0.3 + heat * 0.35),

		boardWell = well,
		boardRim = rim,
		boardCell = mix(IDENTITY.cell, primary, 0.18),
		boardCellEdge = mix(IDENTITY.cellEdge, primary, 0.22),

		primary = primary,
		secondary = secondary,
		tertiary = tertiary,
		hot = hot,
		accent = accent,

		-- Fixed, never flavor-derived. See BLOCK_PALETTE: the reference shows
		-- five colours coexisting on one board, so tying piece colour to stage
		-- would fight the look this is meant to match.
		piecePalette = table.clone(BLOCK_PALETTE),

		glossStrength = VisualTokens.Gloss.standard - heat * 0.16,
	}
end

return VisualTokens
