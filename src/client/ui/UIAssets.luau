local UIAssets = {}

-- Replace these placeholders after uploading project-owned PNGs through
-- Creator Dashboard. Keep IDs centralized so visual asset swaps are safe.
UIAssets.Images = {
	-- assets/ui/icons-blocky-bedwars/play.png
	Play = "",
	-- assets/ui/icons-blocky-bedwars/shop.png
	Shop = "",
	-- assets/ui/icons-blocky-bedwars/quests.png
	Quests = "",
	-- assets/ui/icons-blocky-bedwars/settings.png
	Settings = "",
	-- assets/ui/icons-blocky-bedwars/coins.png
	Coins = "",
	-- assets/ui/icons-blocky-bedwars/wins.png
	Wins = "",
	-- assets/ui/icons-blocky-bedwars/story-stars.png
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
