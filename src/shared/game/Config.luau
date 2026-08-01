local Config = {}

Config.BoardSize = 8
Config.InventorySize = 3
Config.RoundSeconds = 180
Config.StoryRoundSeconds = 120
Config.SuddenDeathStartsAt = 30
Config.SuddenDeathPressureInterval = 10
Config.SuddenDeathGarbageRows = 1
Config.PointsPerCell = 10
Config.PointsPerLine = 100
Config.ComboBonusPoints = 25
Config.GarbagePerLineCleared = 1
Config.CoinsPerHundredScore = 4
Config.WinnerBonusCoins = 40
Config.XpPerHundredScore = 8
Config.WinnerBonusXp = 60
Config.LevelXpBase = 120

Config.StoryCompletionCoins = 30
Config.StoryCompletionXp = 50
Config.DailyBonusCoins = 25
Config.DailyBonusXp = 40

Config.StoryMissions = {
	{
		name = "First Clear",
		description = "Clear 2 lines before time runs out.",
		intro = "The hub grid is unstable. Clear the first sparks and prove you can control the board.",
		success = "Clean work. The first lane is stable, and the hub crew is watching now.",
		failure = "The sparks are still jumping. Reset your rhythm and clear those first lanes.",
		targetScore = 250,
		targetLines = 2,
	},
	{
		name = "Score Sprint",
		description = "Score 700 points before time runs out.",
		intro = "The battle boards need speed data. Stack points fast before the timer drains.",
		success = "That pace will hold in a fight. Your sprint data is locked in.",
		failure = "Good start, but the clock won this one. Chase higher-value placements next run.",
		targetScore = 700,
		targetLines = 0,
	},
	{
		name = "Combo Builder",
		description = "Clear 5 lines and score 900 points.",
		intro = "Now chain clears under pressure. Build space, then cash it in with combos.",
		success = "That combo pattern is battle ready. The next arena tier is getting closer.",
		failure = "The combo window slipped away. Open the board before chasing the big clear.",
		targetScore = 900,
		targetLines = 5,
	},
}

Config.PieceSkinUnlocks = {
	Rainbow = {
		label = "Free",
	},
	Neon = {
		level = 2,
		label = "Level 2",
	},
	Pastel = {
		storyStars = 1,
		label = "1 Story Star",
	},
	Ice = {
		level = 3,
		storyStars = 2,
		label = "Level 3 + 2 Story Stars",
	},
}

Config.Colors = {
	Empty = Color3.fromRGB(24, 28, 36),
	Filled = Color3.fromRGB(64, 156, 255),
	Garbage = Color3.fromRGB(224, 74, 74),
	PreviewValid = Color3.fromRGB(82, 210, 132),
	PreviewInvalid = Color3.fromRGB(255, 110, 110),
}

Config.BoardSkins = {
	{
		name = "Auto",
		empty = nil,
		border = Color3.fromRGB(45, 55, 72),
	},
	{
		name = "Midnight",
		empty = Color3.fromRGB(12, 16, 24),
		border = Color3.fromRGB(56, 67, 89),
	},
	{
		name = "Sugar",
		empty = Color3.fromRGB(43, 30, 49),
		border = Color3.fromRGB(244, 114, 182),
	},
	{
		name = "Garden",
		empty = Color3.fromRGB(16, 38, 31),
		border = Color3.fromRGB(74, 222, 128),
	},
	{
		name = "Contrast",
		empty = Color3.fromRGB(7, 9, 13),
		border = Color3.fromRGB(245, 247, 251),
	},
}

Config.BoardSkinUnlocks = {
	Auto = {
		label = "Free",
	},
	Midnight = {
		level = 2,
		label = "Level 2",
	},
	Sugar = {
		coins = 150,
		label = "150 coins",
	},
	Garden = {
		storyStars = 1,
		label = "1 Story Star",
	},
	Contrast = {
		level = 4,
		storyStars = 3,
		label = "Level 4 + 3 Story Stars",
	},
}

function Config.meetsCosmeticRequirement(requirement, progress)
	if not requirement then
		return true
	end

	progress = progress or {}
	return (progress.level or 1) >= (requirement.level or 1)
		and (progress.coins or 0) >= (requirement.coins or 0)
		and (progress.storyStars or 0) >= (requirement.storyStars or 0)
end

function Config.isValidBoardSkin(boardSkin)
	for _, skin in Config.BoardSkins do
		if skin.name == boardSkin then
			return true
		end
	end

	return false
end

return Config
