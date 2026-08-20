-- Stage-driven presentation for a Solo run.
--
-- This module used to hold four hand-tuned palettes that shared nothing with
-- each other: a teal one, a pink one, a brown one, and a red one, cycled by
-- stage. That produced variety without identity -- the board changed which
-- *game* it looked like every stage, while the surrounding HUD chrome stayed
-- a dark neon arcade cabinet that matched none of them.
--
-- Presets are now derived from VisualTokens, the single source of truth for
-- the Bubblegum Toybox direction (docs/VISUAL_DIRECTION.md, GitHub #98).
-- Stage still changes the look, but it now moves through flavors *inside* one
-- identity, and run intensity moves a separate energy axis.
--
-- The public API here is deliberately unchanged -- presetForStage,
-- validatePreset, blockColorForIndex, blockColorForCell, transitionForStage,
-- presetCount, requiredFields -- so existing consumers need no edits. Callers
-- that want the richer token set should require VisualTokens directly rather
-- than growing this shim.

local VisualTokens = require(script.Parent.VisualTokens)

local StageVisuals = {}

local REQUIRED_FIELDS = {
	"background",
	"backgroundAccent",
	"panel",
	"panelMuted",
	"panelText",
	"panelSubtleText",
	"panelBorder",
	"boardFrame",
	"boardRim",
	"boardEmpty",
	"boardOutline",
	"blockPalette",
	"score",
	"combo",
	"stage",
	"accent",
	"leaderboard",
	"notice",
	"wash",
}

local function isFiniteNumber(value)
	return typeof(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function cleanStage(stage)
	if not isFiniteNumber(stage) then
		return 1
	end

	return math.max(1, math.floor(stage))
end

-- Presets are rendered at rest (energy 0). Live gameplay should drive energy
-- from real run state via VisualTokens.energyFor; that wiring is phase 5 of
-- #98 and deliberately not done here.
local function presetFromTokens(tokens)
	return {
		id = tokens.flavorId,
		name = tokens.flavorName,

		background = tokens.atmosphere,
		backgroundAccent = tokens.atmosphereAccent,

		panel = tokens.surface,
		panelMuted = tokens.surfaceSunken,
		panelText = tokens.ink,
		panelSubtleText = tokens.inkSoft,
		panelBorder = tokens.boardRim,

		boardFrame = tokens.surfaceTinted,
		boardRim = tokens.boardRim,
		boardEmpty = tokens.boardCell,
		boardOutline = tokens.boardCellEdge,

		blockPalette = tokens.piecePalette,

		score = tokens.ink,
		combo = tokens.hot,
		stage = tokens.inkSoft,
		accent = tokens.accent,
		leaderboard = tokens.primary,
		notice = tokens.ink,
		wash = tokens.wash,
	}
end

function StageVisuals.presetCount()
	return VisualTokens.flavorCount()
end

function StageVisuals.requiredFields()
	return table.clone(REQUIRED_FIELDS)
end

function StageVisuals.presetForStage(stage)
	local tokens = VisualTokens.resolve(stage, 0)
	local preset = presetFromTokens(tokens)
	preset.stageNumber = tokens.stageNumber
	preset.cycle = tokens.cycle
	preset.presetIndex = tokens.flavorIndex
	return preset
end

function StageVisuals.validatePreset(preset)
	if typeof(preset) ~= "table" then
		return false
	end

	for _, field in REQUIRED_FIELDS do
		if preset[field] == nil then
			return false
		end
	end

	return typeof(preset.blockPalette) == "table" and #preset.blockPalette >= 3
end

function StageVisuals.blockColorForIndex(preset, index)
	local colors = preset and preset.blockPalette
	if typeof(colors) ~= "table" or #colors == 0 then
		colors = VisualTokens.resolve(1, 0).piecePalette
	end

	local cleanIndex = cleanStage(index)
	return colors[((cleanIndex - 1) % #colors) + 1]
end

function StageVisuals.blockColorForCell(preset, x, y)
	local seed = cleanStage(x) * 3 + cleanStage(y) * 5
	return StageVisuals.blockColorForIndex(preset, seed)
end

function StageVisuals.transitionForStage(stage, reducedMotion)
	local preset = StageVisuals.presetForStage(stage)
	if reducedMotion then
		return {
			kind = "fade",
			duration = 0.18,
			messageDuration = 1.2,
			wash = preset.wash,
		}
	end

	return {
		kind = "pulseWash",
		duration = 0.42,
		messageDuration = 1.55,
		wash = preset.wash,
	}
end

return StageVisuals
