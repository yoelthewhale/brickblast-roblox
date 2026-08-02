local UIAssets = {}

-- Replace these placeholders only after a complete HUD direction and final
-- project-owned PNG set are approved. The existing generated icon folders are
-- rejected references and must not be uploaded or wired into this table.
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
