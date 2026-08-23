-- Stage-driven presentation for a Solo run.
--
-- This module used to hold four hand-tuned palettes that shared nothing with
-- each other: a teal one, a pink one, a brown one, and a red one, cycled by
-- stage. That produced variety without identity -- the board changed which
-- *game* it looked like every stage, while the surrounding HUD chrome stayed
-- a dark neon arcade cabinet that matched none of them.
--
-- Presets are now derived from VisualTokens, the single source of truth for
-- the Deep Board direction (docs/VISUAL_DIRECTION.md, GitHub #98). Stage still
-- changes the look, but it now moves through flavors *inside* one identity,
-- and run intensity moves a separate energy axis.
--
-- Note what `blockPalette` is wired to: `tokens.piecePalette`, which is fixed
-- and does not move with stage or energy. Under the previous direction it did.
-- If a future change makes piece color stage-derived again, it will silently
-- break the look this shim exists to serve -- see the identity/flavor rule in
-- docs/VISUAL_DIRECTION.md before touching it.
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

-- Presets default to rest (energy 0). Live gameplay drives energy from real
-- run state through StageVisuals.presetForRun below.
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

function StageVisuals.presetForStage(stage, energy)
	local tokens = VisualTokens.resolve(stage, energy or 0)
	local preset = presetFromTokens(tokens)
	preset.stageNumber = tokens.stageNumber
	preset.cycle = tokens.cycle
	preset.presetIndex = tokens.flavorIndex
	return preset
end

-- The live entry point: derives energy from real run state, then resolves the
-- preset at that intensity.
--
-- This is what makes the palette dynamic rather than static. Stage alone
-- picks the flavor; combo streak and perfect clears push intensity within it,
-- so a hot streak visibly heats the board and a fresh run cools it back down.
-- Deleting this and calling presetForStage directly would silently flatten
-- the game to one palette per stage -- exactly the outcome
-- docs/VISUAL_DIRECTION.md warns against.
--
-- The energy math lives in VisualTokens and is computed here rather than in
-- the client so that BlockBlastClient.client.luau does not need a new
-- top-level require; it sits two registers from Luau's ceiling.
function StageVisuals.energyForRun(runState)
	local stageState = typeof(runState) == "table" and runState.stage or nil
	return VisualTokens.energyFor({
		comboStreak = typeof(runState) == "table" and runState.comboStreak or 0,
		stage = typeof(stageState) == "table" and stageState.currentStage or 1,
		perfectClears = typeof(stageState) == "table" and stageState.totalPerfectClears or 0,
	})
end

function StageVisuals.presetForRun(runState)
	local stageState = typeof(runState) == "table" and runState.stage or nil
	local stage = typeof(stageState) == "table" and stageState.currentStage or 1
	local energy = StageVisuals.energyForRun(runState)
	return StageVisuals.presetForStage(stage, energy), energy
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
