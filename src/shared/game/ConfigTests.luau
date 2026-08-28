local Config = require(script.Parent.Config)

local ConfigTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local function isFiniteNumber(value)
	return typeof(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local tests = {}

tests.boardAndInventoryDimensionsStayLocked = function()
	assertCondition(Config.BoardSize == 8, "BrickBlast gameplay is locked to an 8x8 board")
	assertCondition(Config.InventorySize == 3, "The Solo hand should keep exactly three slots")
end

tests.difficultyProfilesAreCompleteAndOrdered = function()
	local seen = {}
	for _, difficultyId in Config.Difficulties.Order do
		local profile = Config.Difficulties.Profiles[difficultyId]
		assertCondition(profile ~= nil, `Difficulty {difficultyId} is listed but has no profile`)
		assertCondition(profile.id == difficultyId, `Difficulty {difficultyId} has a mismatched id`)
		assertCondition(typeof(profile.name) == "string" and #profile.name > 0, "Missing name")
		assertCondition(typeof(profile.blurb) == "string" and #profile.blurb > 0, "Missing blurb")
		assertCondition(
			typeof(profile.detail) == "string" and #profile.detail > 0,
			"Missing detail"
		)
		assertCondition(isFiniteNumber(profile.assistanceBonus), "Missing assistance bonus")
		assertCondition(isFiniteNumber(profile.pressureScale), "Missing pressure scale")
		assertCondition(isFiniteNumber(profile.pressureStartOffset), "Missing pressure offset")
		assertCondition(seen[difficultyId] == nil, `Duplicate difficulty id {difficultyId}`)
		seen[difficultyId] = true
	end

	assertCondition(seen[Config.Difficulties.Default] == true, "Default difficulty must be listed")
	assertCondition(
		Config.Difficulties.Profiles.chill.placementSeconds == nil,
		"Chill must stay untimed"
	)
	assertCondition(
		Config.Difficulties.Profiles.classic.placementSeconds == nil,
		"Classic must stay untimed"
	)
	assertCondition(
		isFiniteNumber(Config.Difficulties.Profiles.spicy.placementSeconds)
			and Config.Difficulties.Profiles.spicy.placementSeconds > 0,
		"Spicy should be the only timed profile"
	)
end

tests.boardSkinUnlocksOnlyReferenceRealSkins = function()
	local skins = {}
	for _, skin in Config.BoardSkins do
		assertCondition(
			typeof(skin.name) == "string" and #skin.name > 0,
			"A board skin has no name"
		)
		assertCondition(skins[skin.name] == nil, `Duplicate board skin {skin.name}`)
		skins[skin.name] = true
		assertCondition(
			Config.isValidBoardSkin(skin.name),
			`Board skin {skin.name} should validate`
		)
	end

	assertCondition(skins.Auto == true, "Auto board skin is the required default")
	for skinName, requirement in Config.BoardSkinUnlocks do
		assertCondition(
			skins[skinName] == true,
			`Unlock rule names an unknown board skin {skinName}`
		)
		assertCondition(
			typeof(requirement.label) == "string",
			`{skinName} unlock should have a label`
		)
	end
	assertCondition(not Config.isValidBoardSkin("MissingSkin"), "Unknown board skins must reject")
end

tests.blockStyleUnlocksOnlyReferenceRealStyles = function()
	local stylesById = {}
	local stylesByName = {}
	for _, style in Config.BlockStyles do
		assertCondition(typeof(style.id) == "string" and #style.id > 0, "A block style has no id")
		assertCondition(
			typeof(style.name) == "string" and #style.name > 0,
			"A block style has no name"
		)
		assertCondition(stylesById[style.id] == nil, `Duplicate block style id {style.id}`)
		assertCondition(stylesByName[style.name] == nil, `Duplicate block style name {style.name}`)
		stylesById[style.id] = true
		stylesByName[style.name] = true
	end

	assertCondition(
		stylesById[Config.BlockStyleDefault] == true,
		"Default block style should be a real style"
	)
	for styleName, requirement in Config.BlockStyleUnlocks do
		assertCondition(
			stylesByName[styleName] == true,
			`Unlock rule names an unknown block style {styleName}`
		)
		assertCondition(
			typeof(requirement.label) == "string",
			`{styleName} unlock should have a label`
		)
	end
end

tests.cosmeticDefaultsResolveToOwnedCosmetics = function()
	for category, cosmeticId in Config.DefaultEquippedCosmetics do
		local definition = Config.getCosmeticDefinition(cosmeticId)
		assertCondition(definition ~= nil, `Default cosmetic {cosmeticId} is missing`)
		assertCondition(
			definition.cosmeticCategory == category,
			`Default cosmetic {cosmeticId} is assigned to the wrong category`
		)
		assertCondition(
			definition.defaultOwned == true,
			`Default cosmetic {cosmeticId} is not owned`
		)
	end
end

tests.monetizationPlaceholdersNeverResolveAsPurchasableIds = function()
	local placeholder = Config.Monetization.PlaceholderId
	assertCondition(placeholder == 0, "Placeholder marketplace id should stay explicit and obvious")
	assertCondition(
		Config.getGamePassByMarketplaceId(placeholder) == nil,
		"Placeholder game pass ids must not resolve as real purchases"
	)
	assertCondition(
		Config.getDeveloperProductByMarketplaceId(placeholder) == nil,
		"Placeholder developer product ids must not resolve as real purchases"
	)
end

tests.monetizationDefinitionsHaveStableUniqueIds = function()
	local configIds = {}
	local marketIds = {}

	for _, pass in Config.Monetization.GamePasses do
		assertCondition(typeof(pass.id) == "string" and #pass.id > 0, "Game pass missing id")
		assertCondition(configIds[pass.id] == nil, `Duplicate monetization id {pass.id}`)
		configIds[pass.id] = true
		assertCondition(
			Config.getGamePassDefinition(pass.id) == pass,
			`Game pass {pass.id} lost lookup`
		)
		if pass.gamePassId ~= Config.Monetization.PlaceholderId then
			assertCondition(
				isFiniteNumber(pass.gamePassId),
				`Game pass {pass.id} has an invalid id`
			)
			assertCondition(
				marketIds[pass.gamePassId] == nil,
				`Duplicate marketplace id {pass.gamePassId}`
			)
			marketIds[pass.gamePassId] = pass.id
		end
	end

	for _, product in Config.Monetization.DeveloperProducts do
		assertCondition(typeof(product.id) == "string" and #product.id > 0, "Product missing id")
		assertCondition(configIds[product.id] == nil, `Duplicate monetization id {product.id}`)
		configIds[product.id] = true
		assertCondition(
			Config.getDeveloperProductDefinition(product.id) == product,
			`Product {product.id} lost lookup`
		)
		if product.productId ~= Config.Monetization.PlaceholderId then
			assertCondition(
				isFiniteNumber(product.productId),
				`Product {product.id} has an invalid id`
			)
			assertCondition(
				marketIds[product.productId] == nil,
				`Duplicate marketplace id {product.productId}`
			)
			marketIds[product.productId] = product.id
		end
	end
end

function ConfigTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return ConfigTests
