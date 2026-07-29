local Config = {}

Config.BoardSize = 8
Config.InventorySize = 3
Config.RoundSeconds = 180
Config.PointsPerCell = 10
Config.PointsPerLine = 100
Config.GarbagePerLineCleared = 1

Config.Colors = {
	Empty = Color3.fromRGB(24, 28, 36),
	Filled = Color3.fromRGB(64, 156, 255),
	Garbage = Color3.fromRGB(224, 74, 74),
	PreviewValid = Color3.fromRGB(82, 210, 132),
	PreviewInvalid = Color3.fromRGB(255, 110, 110),
}

return Config
