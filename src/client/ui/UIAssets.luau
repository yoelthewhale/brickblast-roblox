local UIAssets = {}

local BubblegumAssets = require(script.Parent.BubblegumAssets)

-- Legacy HUD keys are preserved so older UI code can move onto the approved
-- production package without scattering Roblox asset ids through call sites.
UIAssets.Images = {
	Play = "",
	Shop = "",
	Quests = "",
	Settings = "",
	Coins = BubblegumAssets.Images.Coin,
	XP = BubblegumAssets.Images.XP,
	BestScore = BubblegumAssets.Images.BestScore,
	Trophy = BubblegumAssets.Images.Trophy,
	Stage = BubblegumAssets.Images.Stage,
	Wins = "",
	StoryStars = "",
}

UIAssets.Bubblegum = BubblegumAssets

local LEGACY_TO_BUBBLEGUM = {
	Coins = "Coin",
	XP = "XP",
	BestScore = "BestScore",
	Trophy = "Trophy",
	Stage = "Stage",
}

function UIAssets.imageFor(key)
	local bubblegumKey = LEGACY_TO_BUBBLEGUM[key] or key
	local productionImage = BubblegumAssets.imageFor(bubblegumKey)
	if productionImage then
		return productionImage
	end

	local image = UIAssets.Images[key]
	if typeof(image) ~= "string" or image == "" then
		return nil
	end

	return image
end

function UIAssets.applyTo(imageObject, key, options)
	local bubblegumKey = LEGACY_TO_BUBBLEGUM[key] or key
	return BubblegumAssets.applyTo(imageObject, bubblegumKey, options)
end

return UIAssets
