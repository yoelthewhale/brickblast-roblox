local Config = {}

Config.BoardSize = 8
Config.InventorySize = 3
Config.RoundSeconds = 180
Config.StoryRoundSeconds = 120
Config.PointsPerCell = 10
Config.PointsPerLine = 100
Config.GarbagePerLineCleared = 1
Config.CoinsPerHundredScore = 4
Config.WinnerBonusCoins = 40
Config.XpPerHundredScore = 8
Config.WinnerBonusXp = 60
Config.LevelXpBase = 120

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

function Config.isValidBoardSkin(boardSkin)
	for _, skin in Config.BoardSkins do
		if skin.name == boardSkin then
			return true
		end
	end

	return false
end

return Config
