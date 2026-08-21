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

-- Proper sRGB relative luminance (WCAG 2.x), gamma-linearized. The naive
-- weighted-average version is wrong by enough to matter when deciding whether
-- candy text clears 4.5:1 on cream.
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
-- This exists because the chrome palette was tuned for a near-black arcade
-- cabinet and now sits on cream. Retuning eight text roles by eye is how a
-- redesign ships an accessibility regression; deriving them keeps candy hues
-- readable automatically, including after someone retunes the flavor anchors.
function VisualTokens.readableOn(color, background, target)
	local goal = clampNumber(target, 1, 21)
	if VisualTokens.contrastRatio(color, background) >= goal then
		return color
	end

	local hue, saturation, value = color:ToHSV()
	local candidate = color

	-- Walk the value down in fixed steps rather than binary-searching: the
	-- search space is tiny and a deterministic walk keeps results stable
	-- across runs, which matters because these land in tests.
	for step = 1, 100 do
		local nextValue = math.max(0, value * (1 - step / 100))
		candidate = Color3.fromHSV(hue, saturation, nextValue)
		if VisualTokens.contrastRatio(candidate, background) >= goal then
			return candidate
		end
	end

	return candidate
end

-- The chassis palette: shaped key-for-key like the old ArcadeUI.Color so all
-- 59 call sites keep working, but derived from the Bubblegum identity instead
-- of the "B2 Polished Arcade" near-black cabinet.
--
-- Chrome is deliberately STABLE -- it does not take stage or energy. The
-- chassis is the identity; progression-driven variation belongs on the board
-- and its accents, where StageVisuals.presetForRun already puts it. Making
-- chrome dynamic too would smear the effect across the whole screen and make
-- the energy axis harder to read, not easier.
local TEXT_CONTRAST_TARGET = 4.5

function VisualTokens.chrome()
	local signature = FLAVORS[1]
	local surface = IDENTITY.cream
	local sunken = IDENTITY.creamShade
	-- Text roles must clear the target on the darker of the two grounds they
	-- can land on, so a label is readable on a sunken card as well as a panel.
	local ground = if relativeLuminance(sunken) < relativeLuminance(surface)
		then sunken
		else surface

	local function readable(color)
		return VisualTokens.readableOn(color, ground, TEXT_CONTRAST_TARGET)
	end

	return {
		shell = surface,
		shellTop = mix(surface, IDENTITY.gloss, 0.5),
		shellBottom = sunken,
		inner = mix(surface, sunken, 0.55),
		innerBottom = mix(sunken, IDENTITY.shadow, 0.12),
		-- Soft grape rather than black: toy plastic has no true black, and a
		-- black edge on cream reads as a sticker cut-out.
		edge = mix(sunken, IDENTITY.shadow, 0.45),

		-- Rims are strokes, not text, so they stay bright and candy.
		rim = signature.primary,
		rimBright = mix(signature.primary, IDENTITY.gloss, 0.35),

		text = IDENTITY.ink,
		muted = readable(IDENTITY.inkSoft),
		score = readable(Color3.fromRGB(255, 176, 32)),
		best = readable(Color3.fromRGB(38, 200, 168)),
		combo = readable(signature.hot),
		gold = readable(Color3.fromRGB(255, 196, 54)),
		silver = readable(Color3.fromRGB(176, 186, 204)),
		bronze = readable(Color3.fromRGB(226, 138, 74)),
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
