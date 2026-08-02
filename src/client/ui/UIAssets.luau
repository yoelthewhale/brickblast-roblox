local UIAssets = {}

-- Replace these placeholders after uploading project-owned PNGs through
-- Creator Dashboard. Keep IDs centralized so visual asset swaps are safe.
UIAssets.Images = {
	-- assets/ui/icons/play.png
	Play = "",
	-- assets/ui/icons/shop.png
	Shop = "",
	-- assets/ui/icons/quests.png
	Quests = "",
	-- assets/ui/icons/settings.png
	Settings = "",
	-- assets/ui/icons/coins.png
	Coins = "",
	-- assets/ui/icons/wins.png
	Wins = "",
	-- assets/ui/icons/story-stars.png
	StoryStars = "",
}

function UIAssets.imageFor(key)
	local image = UIAssets.Images[key]
	if typeof(image) ~= "string" or image == "" then
		return nil
	end

	return image
end

return UIAssets
