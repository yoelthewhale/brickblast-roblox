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
-- Awarded per "step" of a simultaneous multi-line clear, deliberately the same
-- rate as the combo bonus: clearing n lines at once should be worth what those
-- n clears would have earned as consecutive combo placements. See
-- GameplayRules.multiLineBonusForClear.
Config.MultiLineClearBonusPoints = Config.ComboBonusPoints
Config.GarbagePerLineCleared = 1
Config.CoinsPerHundredScore = 4
Config.WinnerBonusCoins = 40
Config.XpPerHundredScore = 8
Config.WinnerBonusXp = 60
Config.LevelXpBase = 120

Config.StageProgression = {
	BaseRequirement = 28,
	RequirementGrowth = 8,
	LineProgress = 8,
	MultiLineBonus = 5,
	PerfectClearBonus = 40,
	ComboProgressBonus = 3,
	ComboProgressCap = 9,
}

Config.HandGeneration = {
	CandidateLimit = 40,
	RecentHistoryLimit = 5,
	AssistanceStart = 3,
	AssistanceMax = 4,
	CrowdedRescueThreshold = 0.58,
	TightBoardFitThreshold = 3,
	RescueCost = 1,
	StagePressureStart = 3,
	PressurePerStage = 0.07,
	MaxPressure = 0.42,
	FlexibleShapeIds = {
		single = true,
		line2 = true,
	},
	RestrictiveShapeIds = {
		plus = true,
		corner = true,
		square2 = true,
		line3 = true,
		vertical3 = true,
		line4 = true,
		vertical4 = true,
		tShape = true,
		sShape = true,
		zShape = true,
		jShape = true,
		lShape = true,
		rect2x3 = true,
		tShape2 = true,
		tShape3 = true,
		tShape4 = true,
		sShape2 = true,
		zShape2 = true,
		jShape2 = true,
		jShape3 = true,
		jShape4 = true,
		lShape2 = true,
		lShape3 = true,
		lShape4 = true,
		corner2 = true,
		corner3 = true,
		corner4 = true,
	},
	StageAdvanceRestore = 1,
	ComboRestoreMilestone = 3,
	ComboRestore = 1,
	PerfectClearRestore = 2,
}

Config.DeveloperTools = {
	Enabled = true,
	CommandCooldownSeconds = 0.12,
	MaxStage = 25,
	MaxStageProgress = 5000,
	MaxCombo = 25,
	AuthorizedUserIds = {
		564972790,
	},
}

Config.StoryCompletionCoins = 30
Config.StoryCompletionXp = 50
Config.DailyBonusCoins = 25
Config.DailyBonusXp = 40

Config.Monetization = {
	PlaceholderId = 0,
	GamePasses = {
		{
			id = "VIP_PASS",
			name = "VIP Pass",
			category = "Passes",
			featured = true,
			gamePassId = 0,
			suggestedPriceRobux = 299,
			description = "A prestige pass with modest reward boosts and VIP identity hooks.",
			benefits = {
				"VIP title foundation",
				"+5% coins from runs",
				"+5% XP from runs",
			},
			rewardMultipliers = {
				coins = 1.05,
				xp = 1.05,
			},
		},
		{
			id = "DELUXE_COSMETICS_PASS",
			name = "Deluxe Cosmetics Pass",
			category = "Cosmetics",
			featured = true,
			gamePassId = 0,
			suggestedPriceRobux = 399,
			description = "Unlocks the future deluxe visual collection without affecting match power.",
			benefits = {
				"Deluxe cosmetic entitlement",
				"Future premium board and piece styles",
				"No gameplay advantage",
			},
		},
		{
			id = "EXTRA_PRESET_SLOTS_PASS",
			name = "Extra Preset Slots Pass",
			category = "Passes",
			featured = false,
			gamePassId = 0,
			suggestedPriceRobux = 199,
			description = "Adds room for future saved style and layout presets.",
			benefits = {
				"Extra cosmetic preset slots",
				"Future layout preset support",
				"Account-level entitlement",
			},
		},
		{
			id = "SUPPORTER_PASS",
			name = "Supporter Pass",
			category = "Featured",
			featured = true,
			gamePassId = 0,
			suggestedPriceRobux = 99,
			description = "A low-cost support option with a small daily bonus hook.",
			benefits = {
				"Supporter identity foundation",
				"+5 daily bonus coins when eligible",
				"Thank-you cosmetic hook",
			},
			dailyBonusCoins = 5,
		},
	},
	DeveloperProducts = {
		{
			id = "COINS_SMALL",
			name = "Small Coin Pack",
			category = "Currency",
			productId = 0,
			suggestedPriceRobux = 49,
			coins = 150,
			description = "A starter coin pack for future cosmetic purchases.",
		},
		{
			id = "COINS_MEDIUM",
			name = "Medium Coin Pack",
			category = "Currency",
			productId = 0,
			suggestedPriceRobux = 149,
			coins = 525,
			description = "A better-value coin pack for future shop rotations.",
		},
		{
			id = "COINS_LARGE",
			name = "Large Coin Pack",
			category = "Currency",
			productId = 0,
			suggestedPriceRobux = 399,
			coins = 1650,
			description = "A large coin pack for future collectors.",
		},
	},
}

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

-- Story mode is disabled (ExperienceConfig.Modes.Story), and nothing outside
-- Story-mission completion grants story stars, so a storyStars requirement is
-- unreachable for a Solo player. These four requirements were retargeted onto
-- the level/coins axes Solo already advances, keeping their original relative
-- difficulty. Their pre-Solo-pivot requirements are noted inline so they can
-- be restored if Story mode comes back.
Config.PieceSkinUnlocks = {
	Rainbow = {
		label = "Free",
	},
	Neon = {
		level = 2,
		label = "Level 2",
	},
	-- Was: storyStars = 1.
	Pastel = {
		level = 3,
		label = "Level 3",
	},
	-- Was: level = 3 + storyStars = 2. Kept as the hardest piece skin.
	Ice = {
		level = 5,
		label = "Level 5",
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
	-- Was: storyStars = 1. Follows Sugar's coin slot rather than adding a
	-- third level-gated board skin.
	Garden = {
		coins = 300,
		label = "300 coins",
	},
	-- Was: level = 4 + storyStars = 3. Kept as the hardest board skin.
	Contrast = {
		level = 6,
		label = "Level 6",
	},
}

Config.CosmeticCategories = {
	PieceSkin = "PieceSkin",
	BoardSkin = "BoardSkin",
	LineClearEffect = "LineClearEffect",
	PlayerTitle = "PlayerTitle",
}

Config.DefaultEquippedCosmetics = {
	PieceSkin = "PIECE_RAINBOW",
	BoardSkin = "BOARD_AUTO",
	LineClearEffect = "CLEAR_SPARK",
	PlayerTitle = "TITLE_ROOKIE",
}

Config.FreePresetSlots = 2
Config.ExtraPresetSlots = 3

Config.Cosmetics = {
	{
		id = "PIECE_RAINBOW",
		name = "Rainbow Pieces",
		description = "Bright randomized block colors.",
		cosmeticCategory = Config.CosmeticCategories.PieceSkin,
		rarity = "Common",
		unlockSource = "Default",
		defaultOwned = true,
		preview = {
			pieceSkin = "Rainbow",
		},
	},
	{
		id = "PIECE_NEON",
		name = "Neon Pieces",
		description = "High-saturation arcade blocks.",
		cosmeticCategory = Config.CosmeticCategories.PieceSkin,
		rarity = "Rare",
		unlockSource = "Progression",
		requirement = Config.PieceSkinUnlocks.Neon,
		preview = {
			pieceSkin = "Neon",
		},
	},
	{
		id = "PIECE_PASTEL",
		name = "Pastel Pieces",
		description = "Soft candy-colored block pieces.",
		cosmeticCategory = Config.CosmeticCategories.PieceSkin,
		rarity = "Uncommon",
		unlockSource = "Progression",
		requirement = Config.PieceSkinUnlocks.Pastel,
		preview = {
			pieceSkin = "Pastel",
		},
	},
	{
		id = "PIECE_ICE",
		name = "Ice Pieces",
		description = "Cool-blue pieces for advanced players.",
		cosmeticCategory = Config.CosmeticCategories.PieceSkin,
		rarity = "Epic",
		unlockSource = "Progression",
		requirement = Config.PieceSkinUnlocks.Ice,
		preview = {
			pieceSkin = "Ice",
		},
	},
	{
		id = "BOARD_AUTO",
		name = "Auto Board",
		description = "Uses your current theme colors.",
		cosmeticCategory = Config.CosmeticCategories.BoardSkin,
		rarity = "Common",
		unlockSource = "Default",
		defaultOwned = true,
		preview = {
			boardSkin = "Auto",
		},
	},
	{
		id = "BOARD_MIDNIGHT",
		name = "Midnight Board",
		description = "A dark, focused board treatment.",
		cosmeticCategory = Config.CosmeticCategories.BoardSkin,
		rarity = "Uncommon",
		unlockSource = "Progression",
		requirement = Config.BoardSkinUnlocks.Midnight,
		preview = {
			boardSkin = "Midnight",
		},
	},
	{
		id = "BOARD_SUGAR",
		name = "Sugar Board",
		description = "A pink board skin purchasable with earned coins.",
		cosmeticCategory = Config.CosmeticCategories.BoardSkin,
		rarity = "Rare",
		unlockSource = "Coins",
		costCoins = 150,
		preview = {
			boardSkin = "Sugar",
		},
	},
	{
		id = "BOARD_GARDEN",
		name = "Garden Board",
		description = "Green board colors earned by saving up coins.",
		cosmeticCategory = Config.CosmeticCategories.BoardSkin,
		rarity = "Uncommon",
		unlockSource = "Coins",
		requirement = Config.BoardSkinUnlocks.Garden,
		preview = {
			boardSkin = "Garden",
		},
	},
	{
		id = "BOARD_CONTRAST",
		name = "Contrast Board",
		description = "High-contrast board colors for readability.",
		cosmeticCategory = Config.CosmeticCategories.BoardSkin,
		rarity = "Epic",
		unlockSource = "Progression",
		requirement = Config.BoardSkinUnlocks.Contrast,
		preview = {
			boardSkin = "Contrast",
		},
	},
	{
		id = "CLEAR_SPARK",
		name = "Spark Clear",
		description = "A clean default line-clear flash.",
		cosmeticCategory = Config.CosmeticCategories.LineClearEffect,
		rarity = "Common",
		unlockSource = "Default",
		defaultOwned = true,
		preview = {
			lineClearEffect = "Spark",
		},
	},
	{
		id = "CLEAR_RIPPLE",
		name = "Ripple Clear",
		description = "A smoother clear pulse bought with earned coins.",
		cosmeticCategory = Config.CosmeticCategories.LineClearEffect,
		rarity = "Rare",
		unlockSource = "Coins",
		costCoins = 100,
		preview = {
			lineClearEffect = "Ripple",
		},
	},
	{
		id = "TITLE_ROOKIE",
		name = "Rookie Title",
		description = "Default player title.",
		cosmeticCategory = Config.CosmeticCategories.PlayerTitle,
		rarity = "Common",
		unlockSource = "Default",
		defaultOwned = true,
		preview = {
			title = "Rookie",
		},
	},
	{
		id = "TITLE_VIP",
		name = "VIP Title",
		description = "Title unlocked by owning the VIP Pass.",
		cosmeticCategory = Config.CosmeticCategories.PlayerTitle,
		rarity = "Premium",
		unlockSource = "GamePass",
		requiredGamePass = "VIP_PASS",
		preview = {
			title = "VIP",
		},
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

function Config.getCosmeticDefinition(cosmeticId)
	for _, cosmetic in Config.Cosmetics do
		if cosmetic.id == cosmeticId then
			return cosmetic
		end
	end

	return nil
end

function Config.getDefaultCosmeticForCategory(category)
	local defaultId = Config.DefaultEquippedCosmetics[category]
	return defaultId and Config.getCosmeticDefinition(defaultId) or nil
end

function Config.getGamePassDefinition(passId)
	for _, pass in Config.Monetization.GamePasses do
		if pass.id == passId then
			return pass
		end
	end

	return nil
end

function Config.getGamePassByMarketplaceId(gamePassId)
	for _, pass in Config.Monetization.GamePasses do
		if pass.gamePassId == gamePassId and gamePassId ~= Config.Monetization.PlaceholderId then
			return pass
		end
	end

	return nil
end

function Config.getDeveloperProductDefinition(productId)
	for _, product in Config.Monetization.DeveloperProducts do
		if product.id == productId then
			return product
		end
	end

	return nil
end

function Config.getDeveloperProductByMarketplaceId(productId)
	for _, product in Config.Monetization.DeveloperProducts do
		if product.productId == productId and productId ~= Config.Monetization.PlaceholderId then
			return product
		end
	end

	return nil
end

return Config
