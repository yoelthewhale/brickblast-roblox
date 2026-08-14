local StageVisuals = {}

local PRESETS = {
	{
		id = "aquaCandy",
		name = "Aqua Candy",
		background = Color3.fromRGB(111, 220, 233),
		backgroundAccent = Color3.fromRGB(189, 248, 250),
		panel = Color3.fromRGB(236, 253, 255),
		panelMuted = Color3.fromRGB(205, 242, 247),
		panelText = Color3.fromRGB(20, 69, 86),
		panelSubtleText = Color3.fromRGB(54, 114, 129),
		panelBorder = Color3.fromRGB(80, 189, 209),
		boardFrame = Color3.fromRGB(156, 238, 241),
		boardRim = Color3.fromRGB(58, 184, 210),
		boardEmpty = Color3.fromRGB(196, 247, 249),
		boardOutline = Color3.fromRGB(115, 212, 224),
		blockPalette = {
			Color3.fromRGB(64, 195, 217),
			Color3.fromRGB(238, 103, 119),
			Color3.fromRGB(250, 187, 48),
			Color3.fromRGB(255, 128, 146),
		},
		score = Color3.fromRGB(255, 255, 255),
		combo = Color3.fromRGB(255, 108, 129),
		stage = Color3.fromRGB(15, 126, 159),
		accent = Color3.fromRGB(255, 201, 54),
		leaderboard = Color3.fromRGB(24, 138, 172),
		notice = Color3.fromRGB(255, 255, 255),
		wash = Color3.fromRGB(126, 235, 244),
	},
	{
		id = "berryPop",
		name = "Berry Pop",
		background = Color3.fromRGB(224, 128, 165),
		backgroundAccent = Color3.fromRGB(255, 182, 211),
		panel = Color3.fromRGB(255, 230, 241),
		panelMuted = Color3.fromRGB(242, 189, 213),
		panelText = Color3.fromRGB(91, 30, 59),
		panelSubtleText = Color3.fromRGB(126, 62, 91),
		panelBorder = Color3.fromRGB(183, 63, 119),
		boardFrame = Color3.fromRGB(137, 87, 105),
		boardRim = Color3.fromRGB(244, 102, 160),
		boardEmpty = Color3.fromRGB(158, 101, 120),
		boardOutline = Color3.fromRGB(137, 73, 99),
		blockPalette = {
			Color3.fromRGB(205, 26, 103),
			Color3.fromRGB(238, 57, 135),
			Color3.fromRGB(255, 110, 169),
			Color3.fromRGB(255, 139, 189),
		},
		score = Color3.fromRGB(255, 247, 252),
		combo = Color3.fromRGB(255, 70, 157),
		stage = Color3.fromRGB(191, 29, 108),
		accent = Color3.fromRGB(255, 218, 80),
		leaderboard = Color3.fromRGB(178, 48, 112),
		notice = Color3.fromRGB(255, 248, 252),
		wash = Color3.fromRGB(255, 153, 201),
	},
	{
		id = "goldenCheese",
		name = "Golden Cheese",
		background = Color3.fromRGB(173, 119, 59),
		backgroundAccent = Color3.fromRGB(226, 174, 85),
		panel = Color3.fromRGB(255, 237, 186),
		panelMuted = Color3.fromRGB(229, 190, 118),
		panelText = Color3.fromRGB(70, 43, 20),
		panelSubtleText = Color3.fromRGB(112, 78, 37),
		panelBorder = Color3.fromRGB(169, 113, 43),
		boardFrame = Color3.fromRGB(82, 43, 29),
		boardRim = Color3.fromRGB(248, 193, 62),
		boardEmpty = Color3.fromRGB(58, 30, 22),
		boardOutline = Color3.fromRGB(76, 40, 28),
		blockPalette = {
			Color3.fromRGB(255, 223, 71),
			Color3.fromRGB(255, 195, 52),
			Color3.fromRGB(245, 166, 38),
			Color3.fromRGB(255, 235, 122),
		},
		score = Color3.fromRGB(255, 246, 188),
		combo = Color3.fromRGB(255, 212, 69),
		stage = Color3.fromRGB(140, 78, 18),
		accent = Color3.fromRGB(255, 223, 82),
		leaderboard = Color3.fromRGB(126, 75, 34),
		notice = Color3.fromRGB(255, 247, 186),
		wash = Color3.fromRGB(255, 207, 89),
	},
	{
		id = "lavaRush",
		name = "Lava Rush",
		background = Color3.fromRGB(186, 35, 37),
		backgroundAccent = Color3.fromRGB(231, 72, 42),
		panel = Color3.fromRGB(255, 224, 197),
		panelMuted = Color3.fromRGB(244, 166, 105),
		panelText = Color3.fromRGB(86, 28, 18),
		panelSubtleText = Color3.fromRGB(129, 54, 31),
		panelBorder = Color3.fromRGB(217, 86, 35),
		boardFrame = Color3.fromRGB(116, 24, 31),
		boardRim = Color3.fromRGB(247, 110, 31),
		boardEmpty = Color3.fromRGB(103, 22, 30),
		boardOutline = Color3.fromRGB(139, 36, 37),
		blockPalette = {
			Color3.fromRGB(255, 137, 38),
			Color3.fromRGB(230, 95, 24),
			Color3.fromRGB(255, 176, 61),
			Color3.fromRGB(203, 67, 24),
		},
		score = Color3.fromRGB(149, 255, 87),
		combo = Color3.fromRGB(255, 206, 67),
		stage = Color3.fromRGB(255, 118, 39),
		accent = Color3.fromRGB(255, 219, 67),
		leaderboard = Color3.fromRGB(151, 36, 32),
		notice = Color3.fromRGB(255, 241, 188),
		wash = Color3.fromRGB(255, 119, 45),
	},
}

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

function StageVisuals.presetCount()
	return #PRESETS
end

function StageVisuals.requiredFields()
	return table.clone(REQUIRED_FIELDS)
end

function StageVisuals.presetForStage(stage)
	local clean = cleanStage(stage)
	local index = ((clean - 1) % #PRESETS) + 1
	local cycle = math.floor((clean - 1) / #PRESETS)
	local preset = table.clone(PRESETS[index])
	preset.stageNumber = clean
	preset.cycle = cycle
	preset.presetIndex = index
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
		colors = PRESETS[1].blockPalette
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
