local UIAssets = {}

-- Replace these placeholders after uploading project-owned PNGs through
-- Creator Dashboard. Keep IDs centralized so visual asset swaps are safe.
UIAssets.Images = {
	Play = "",
	Shop = "",
	Quests = "",
	Settings = "",
	Coins = "",
	Wins = "",
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
