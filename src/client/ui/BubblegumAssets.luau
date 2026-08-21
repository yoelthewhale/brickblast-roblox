local BubblegumAssets = {}

-- Real Roblox image asset ids from the approved Bubblegum production package.
-- Keep all UI callers routed through this table; do not scatter ids elsewhere.
BubblegumAssets.Images = {
	Coin = "rbxassetid://71385619350306",
	XP = "rbxassetid://110597096643027",
	BestScore = "rbxassetid://111998552125153",
	Trophy = "rbxassetid://104591227123281",
	Stage = "rbxassetid://119977561034295",
	MedalFirst = "rbxassetid://97093206983103",
	MedalSecond = "rbxassetid://75444676121332",
	MedalThird = "rbxassetid://118622519676127",
	RewardCrateClosed = "rbxassetid://128643456863208",
	RewardCrateOpen = "rbxassetid://131335880682800",
	SparkleParticle = "rbxassetid://128357824254870",
	ConfettiRect = "rbxassetid://138448664648507",
	ConfettiDot = "rbxassetid://130014295275059",
	ConfettiStar = "rbxassetid://122223931821086",
	ConfettiSquiggle = "rbxassetid://105496120597000",
	ShadowSoft = "rbxassetid://129679451767397",
	CandyFlourishCorner = "rbxassetid://134743329714974",
	LollipopMark = "rbxassetid://88045772402344",
}

BubblegumAssets.Metadata = {
	Coin = {
		file = "icons/icon_coin.png",
		usage = "Coins/currency icon",
		runtimeTint = false,
		scaleType = Enum.ScaleType.Fit,
	},
	XP = {
		file = "icons/icon_xp.png",
		usage = "XP icon",
		runtimeTint = false,
		scaleType = Enum.ScaleType.Fit,
	},
	BestScore = {
		file = "icons/icon_best.png",
		usage = "Best-score badge",
		runtimeTint = false,
		scaleType = Enum.ScaleType.Fit,
	},
	Trophy = {
		file = "icons/icon_trophy.png",
		usage = "Trophy/rank stat",
		runtimeTint = false,
		scaleType = Enum.ScaleType.Fit,
	},
	Stage = {
		file = "icons/icon_stage.png",
		usage = "Stage/progression icon",
		runtimeTint = false,
		scaleType = Enum.ScaleType.Fit,
	},
	MedalFirst = {
		file = "medals/medal_first.png",
		usage = "1st place medal",
		runtimeTint = false,
		scaleType = Enum.ScaleType.Fit,
	},
	MedalSecond = {
		file = "medals/medal_second.png",
		usage = "2nd place medal",
		runtimeTint = false,
		scaleType = Enum.ScaleType.Fit,
	},
	MedalThird = {
		file = "medals/medal_third.png",
		usage = "3rd place medal",
		runtimeTint = false,
		scaleType = Enum.ScaleType.Fit,
	},
	RewardCrateClosed = {
		file = "rewards/crate_reward_closed.png",
		usage = "Closed reward crate",
		runtimeTint = false,
		scaleType = Enum.ScaleType.Fit,
	},
	RewardCrateOpen = {
		file = "rewards/crate_reward_open.png",
		usage = "Opened reward crate",
		runtimeTint = false,
		scaleType = Enum.ScaleType.Fit,
	},
	SparkleParticle = {
		file = "particles/sparkle_particle.png",
		usage = "Sparkle/burst particle",
		runtimeTint = true,
		scaleType = Enum.ScaleType.Fit,
	},
	ConfettiRect = {
		file = "particles/confetti_rect.png",
		usage = "Confetti particle",
		runtimeTint = true,
		scaleType = Enum.ScaleType.Fit,
	},
	ConfettiDot = {
		file = "particles/confetti_dot.png",
		usage = "Confetti particle",
		runtimeTint = true,
		scaleType = Enum.ScaleType.Fit,
	},
	ConfettiStar = {
		file = "particles/confetti_star.png",
		usage = "Confetti particle",
		runtimeTint = true,
		scaleType = Enum.ScaleType.Fit,
	},
	ConfettiSquiggle = {
		file = "particles/confetti_squiggle.png",
		usage = "Confetti particle",
		runtimeTint = true,
		scaleType = Enum.ScaleType.Fit,
	},
	ShadowSoft = {
		file = "ui/shadow_soft_9slice.png",
		usage = "Reusable soft card/panel shadow",
		runtimeTint = true,
		scaleType = Enum.ScaleType.Slice,
		sliceCenter = Rect.new(64, 64, 192, 192),
		sliceScale = 1,
	},
	CandyFlourishCorner = {
		file = "decor/candy_flourish_corner.png",
		usage = "Decorative corner flourish",
		runtimeTint = false,
		scaleType = Enum.ScaleType.Fit,
	},
	LollipopMark = {
		file = "decor/lollipop_mark.png",
		usage = "Decorative lollipop mark",
		runtimeTint = false,
		scaleType = Enum.ScaleType.Fit,
	},
}

function BubblegumAssets.imageFor(key)
	local image = BubblegumAssets.Images[key]
	if typeof(image) ~= "string" or image == "" then
		return nil
	end

	return image
end

function BubblegumAssets.metadataFor(key)
	return BubblegumAssets.Metadata[key]
end

function BubblegumAssets.medalKeyForRank(rank)
	if rank == 1 then
		return "MedalFirst"
	elseif rank == 2 then
		return "MedalSecond"
	elseif rank == 3 then
		return "MedalThird"
	end

	return nil
end

function BubblegumAssets.applyTo(imageObject, key, options)
	local image = BubblegumAssets.imageFor(key)
	local metadata = BubblegumAssets.metadataFor(key)
	if not image or not metadata then
		imageObject.Image = ""
		imageObject.Visible = false
		return false
	end

	options = options or {}
	imageObject.BackgroundTransparency = 1
	imageObject.Image = image
	imageObject.ScaleType = metadata.scaleType or Enum.ScaleType.Fit
	imageObject.Visible = options.visible ~= false

	if metadata.scaleType == Enum.ScaleType.Slice then
		imageObject.SliceCenter = metadata.sliceCenter or Rect.new(0, 0, 0, 0)
		imageObject.SliceScale = metadata.sliceScale or 1
	end
	if options.imageColor and (metadata.runtimeTint or options.allowSemanticTint) then
		imageObject.ImageColor3 = options.imageColor
	else
		imageObject.ImageColor3 = Color3.fromRGB(255, 255, 255)
	end

	return true
end

return BubblegumAssets
