-- Bubblegum Toybox visual tokens: the single source of truth for the game's
-- look. See docs/VISUAL_DIRECTION.md for the approved direction and
-- GitHub #98 for the phased rollout.
--
-- The model has two independent axes over one fixed identity:
--
--   IDENTITY  never varies. Cream surfaces, deep-grape ink, glossy chunky
--             forms. This is what makes the game recognizable as BrickBlast
--             at any moment of any run.
--
--   FLAVOR    varies by stage. A hue family *inside* the identity, so stage 2
--             looks like a different candy rather than a different game. This
--             replaces four unrelated themes (teal / pink / brown / red) that
--             shared nothing.
--
--   ENERGY    varies by run intensity, 0..1, derived from combo streak, stage
--             depth, and perfect clears. Drives saturation, contrast, rim
--             heat, and wash strength.
--
-- ENERGY is the load-bearing idea and the one most easily lost: it is what
-- keeps the game from collapsing into a single static palette while still
-- having one coherent identity. A calm stage 1 board and a stage 12 board
-- mid-hot-streak must read as the same game at different temperatures, not as
-- two different games. Do not "simplify" this away.
--
-- This module is pure: it creates no Instances and reads no game state, so it
-- runs under the headless Lune suite. Keep it that way.

local VisualTokens = {}

-- The fixed half of the identity. Every flavor is built on these, which is
-- what stops stage changes from reading as a different product.
local IDENTITY = {
	-- Deep grape rather than black. Toy plastic has no true black, and ink
	-- this warm keeps candy colors from looking dirty next to it.
	ink = Color3.fromRGB(58, 30, 66),
	inkSoft = Color3.fromRGB(116, 82, 128),
	-- Surfaces are warm off-white, not grey.
	cream = Color3.fromRGB(255, 250, 246),
	creamShade = Color3.fromRGB(240, 228, 238),
	gloss = Color3.fromRGB(255, 255, 255),
	shadow = Color3.fromRGB(126, 80, 138),
}

-- Four flavors keeps `presetCount()` at 4, so the existing stage-cycle math
-- and every current consumer of StageVisuals behave exactly as before.
local FLAVORS = {
	{
		id = "bubblegum",
		name = "Bubblegum",
		primary = Color3.fromRGB(255, 138, 193),
		secondary = Color3.fromRGB(255, 198, 224),
		tertiary = Color3.fromRGB(150, 235, 215),
		hot = Color3.fromRGB(255, 64, 140),
	},
	{
		id = "spearmint",
		name = "Spearmint",
		primary = Color3.fromRGB(126, 226, 196),
		secondary = Color3.fromRGB(192, 244, 226),
		tertiary = Color3.fromRGB(255, 170, 205),
		hot = Color3.fromRGB(34, 206, 160),
	},
	{
		id = "lemonDrop",
		name = "Lemon Drop",
		primary = Color3.fromRGB(255, 214, 102),
		secondary = Color3.fromRGB(255, 238, 182),
		tertiary = Color3.fromRGB(255, 160, 190),
		hot = Color3.fromRGB(255, 166, 38),
	},
	{
		id = "grapeSoda",
		name = "Grape Soda",
		primary = Color3.fromRGB(186, 150, 255),
		secondary = Color3.fromRGB(220, 202, 255),
		tertiary = Color3.fromRGB(150, 232, 238),
		hot = Color3.fromRGB(138, 86, 255),
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

-- Non-color tokens. Chunky toy forms want large radii and generous spacing;
-- these are the vocabulary phases 3 and 4 build the board and HUD from.
VisualTokens.Radius = {
	cell = 10,
	piece = 9,
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

	-- The board well deepens slightly with energy so bright pieces gain
	-- contrast exactly when the screen gets busiest. Capped well short of
	-- ink, because an empty cell must never read as a filled one.
	local well = mix(IDENTITY.creamShade, IDENTITY.shadow, 0.10 + heat * 0.16)

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

		surface = IDENTITY.cream,
		surfaceSunken = IDENTITY.creamShade,
		surfaceTinted = mix(IDENTITY.cream, secondary, 0.35),

		atmosphere = mix(secondary, primary, 0.25 + heat * 0.35),
		atmosphereAccent = mix(IDENTITY.cream, secondary, 0.55),
		wash = mix(secondary, hot, heat * 0.7),

		boardWell = well,
		boardRim = rim,
		boardCell = mix(IDENTITY.cream, secondary, 0.28),
		boardCellEdge = mix(IDENTITY.creamShade, IDENTITY.shadow, 0.22),

		primary = primary,
		secondary = secondary,
		tertiary = tertiary,
		hot = hot,
		accent = accent,

		piecePalette = {
			primary,
			hot,
			tertiary,
			energize(flavor.secondary, heat * 0.4),
			mix(primary, tertiary, 0.5),
		},

		glossStrength = VisualTokens.Gloss.standard - heat * 0.16,
	}
end

return VisualTokens
