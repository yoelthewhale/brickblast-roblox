local Players = game:GetService("Players")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameShared = Shared:WaitForChild("game")
local Blocks = require(GameShared.Blocks)
local Config = require(GameShared.Config)
local ExperienceConfig = require(GameShared.ExperienceConfig)
local Grid = require(GameShared.Grid)
local SoloLayout = require(GameShared.SoloLayout)
local StageProgression = require(GameShared.StageProgression)
local StageVisuals = require(GameShared.StageVisuals)
local ArcadeUI = require(script.Parent.ArcadeUI)
local CosmeticPanel = require(script.Parent.CosmeticPanel)
local DeveloperPanel = require(script.Parent.DeveloperPanel)
local HUDController = require(script.Parent.HUDController)
local HomePanel = require(script.Parent.HomePanel)
local NotificationController = require(script.Parent.NotificationController)
local ResultPanel = require(script.Parent.ResultPanel)
local ShopPanel = require(script.Parent.ShopPanel)
local SoundController = require(script.Parent.SoundController)
local StoryPanel = require(script.Parent.StoryPanel)
local UITheme = require(script.Parent.UITheme)

local remotes = ReplicatedStorage:WaitForChild("BlockBlastRemotes")
local stateEvent = remotes:WaitForChild("State")
local placeEvent = remotes:WaitForChild("Place")
local handEvent = remotes:WaitForChild("Hand")
local queueEvent = remotes:WaitForChild("Queue")
local hubEvent = remotes:WaitForChild("Hub")
local effectsEvent = remotes:WaitForChild("Effects")
local settingsEvent = remotes:WaitForChild("Settings")
local shopEvent = remotes:WaitForChild("Shop")
local devCommandFunction = remotes:WaitForChild("DevCommand")

local selectedSlot = nil
local hoverX = nil
local hoverY = nil
local currentState = nil
local currentHubState = nil
local cells = {}
local cellScales = {}
local handButtons = {}
local handPreviews = {}
local previousBoard = nil
local lastRenderedBoard = nil
local boardGhostLayer = nil
local reducedMotion = false
local uiScale = 1
local pieceSkinIndex = 1
local boardSkinIndex = 1
local soundEnabled = true
local soundVolume = 0.65
local soundController = SoundController.new()
local customization = {
	boardEmptyColor = Config.Colors.Empty,
	panelColor = Color3.fromRGB(14, 18, 27),
	accentColor = Color3.fromRGB(30, 187, 255),
}
local scoreLabel = nil
local bestScoreLabel = nil
local comboBadgeLabel = nil
local coinStatLabel = nil
local coinChipLabel = nil
local rankStatLabel = nil
local timerLabel = nil
local progressionLabel = nil
local matchInfoLabel = nil
local statusLabel = nil
local workspaceHeader = nil
local workspaceContent = nil
local leftColumn = nil
local centerColumn = nil
local rightColumn = nil
local boardStage = nil
local boardFrame = nil
local trayStage = nil
local actionsPanel = nil
local boardGridContainer = nil
local stageUi = {}
local leaderboardLabel = nil
local leaderboardRows = {}
local thumbnailCache = {}
local thumbnailRequestToken = 0
local customizeButton = nil
local closeWorkspaceButton = nil
local resetLayoutButton = nil
local settingsButton = nil
local helpButton = nil
local returnHubButton = nil
local playAgainButton = nil
local rotatePieceButton = nil
local rerollPieceButton = nil
local resizeHandle = nil
local banner = nil
local diagnosticsPanel = nil
local diagnosticsLabel = nil
local diagnosticsVisible = false
local loadingScreen = nil
local cosmeticPanelController = nil
local resultPanelController = nil
local shopPanelController = nil
local storyPanelController = nil
local homePanelController = nil
local hudController = nil
local notificationController = nil
local developerPanelController = nil
local loadingDismissed = false
local tutorialPanel = nil
local hubManuallyClosed = true
local tutorialComplete = true
local tutorialManuallyOpened = false
local cosmeticPreviewSnapshot = nil
local root = nil
local rootScale = nil
local bannerScale = nil
local workspaceInteraction = nil
local clampWindowToScreen = nil
local applyWindowLayout = nil
local applyBoardSkin = nil
local renderBoard = nil
local renderGhostPreview = nil
local renderHand = nil
local renderDiagnostics = nil
local pulseHandSlot = nil

local WINDOW_LAYOUT = SoloLayout.calculate(Vector2.new(1280, 720), 36, 0, 1)
local QUICK_TWEEN = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SOFT_TWEEN = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local day43Ui = {
	serverActionCooldownSeconds = 0.45,
	placeActionCooldownSeconds = 0.08,
	lastServerActionAt = 0,
	lastPlaceActionAt = 0,
	-- Attached here instead of top-level locals: this script is a single
	-- top-level chunk already close to Luau's 200-local register limit.
	codesEvent = remotes:WaitForChild("Codes"),
	achievementsEvent = remotes:WaitForChild("Achievements"),
	previousHandOccupied = {},
}

local function isUiReducedMotion()
	return reducedMotion
end

local function styleButton(button, variant)
	UITheme.button(button, variant)
	UITheme.attachButtonFeedback(button, isUiReducedMotion)
	return button
end

local function markInteractive(guiObject)
	guiObject:SetAttribute("BlocksWorkspaceDrag", true)
	return guiObject
end

local function makeWorkspaceContainer(
	name,
	parent,
	backgroundColor,
	radius,
	rimColor,
	strokeThickness
)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.BackgroundColor3 = backgroundColor or ArcadeUI.Color.inner
	frame.BackgroundTransparency = 0.02
	frame.BorderSizePixel = 0
	frame.ClipsDescendants = true
	frame.Parent = parent
	ArcadeUI.InnerPanel(frame, {
		radius = radius or 22,
		rimColor = rimColor or Color3.fromRGB(28, 92, 161),
		strokeThickness = strokeThickness or 2,
	})
	return frame
end

local function suppressExternalPuzzleHud(isPuzzleVisible)
	if not hudController then
		return
	end

	hudController:SetGameplayFocus(isPuzzleVisible)
	if hudController.topBar then
		hudController.topBar.Visible = false
	end
	if hudController.cancelQueueButton then
		hudController.cancelQueueButton.Visible = false
	end
	local screenGui = player:FindFirstChild("PlayerGui")
		and player.PlayerGui:FindFirstChild("BlockBlastBattleGui")
	for _, name in
		{ "ArcadeBrand", "TopResourceBar", "LeftArcadeNav", "RightArcadeNav", "TopQueueBanner" }
	do
		local item = screenGui and screenGui:FindFirstChild(name)
		if item and item:IsA("GuiObject") then
			item.Visible = not isPuzzleVisible
		end
	end
end

local function removeDirectGradients(guiObject)
	for _, child in guiObject:GetChildren() do
		if child:IsA("UIGradient") then
			child:Destroy()
		end
	end
end

local function statRichText(heading, value, valueColorHex)
	return `<font color="#FFFFFF">{heading}</font>\n<font color="{valueColorHex}">{value}</font>`
end

local function enforceStatTextContrast()
	if comboBadgeLabel then
		removeDirectGradients(comboBadgeLabel)
		comboBadgeLabel.RichText = true
		comboBadgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		comboBadgeLabel.TextTransparency = 0
		comboBadgeLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		comboBadgeLabel.TextStrokeTransparency = 0.05
	end
	if coinStatLabel then
		removeDirectGradients(coinStatLabel)
		coinStatLabel.RichText = true
		coinStatLabel.TextColor3 = Color3.fromRGB(255, 236, 160)
		coinStatLabel.TextTransparency = 0
		coinStatLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		coinStatLabel.TextStrokeTransparency = 0.08
	end
	if rankStatLabel then
		removeDirectGradients(rankStatLabel)
		rankStatLabel.RichText = true
		rankStatLabel.TextColor3 = ArcadeUI.Color.gold
		rankStatLabel.TextTransparency = 0
		rankStatLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		rankStatLabel.TextStrokeTransparency = 0.08
	end
end

local function makeTopControl(name, text, color)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = Vector2.new(1, 0)
	button.BackgroundColor3 = color or Color3.fromRGB(12, 32, 61)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.Text = text
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 22
	button.Parent = workspaceHeader
	ArcadeUI.Button(button, button.BackgroundColor3)
	UITheme.attachButtonFeedback(button, isUiReducedMotion)
	markInteractive(button)
	return button
end

local function requestLeaderboardThumbnail(userId, imageLabel, token)
	if typeof(userId) ~= "number" or userId <= 0 then
		return
	end

	local cached = thumbnailCache[userId]
	if cached then
		imageLabel.Image = cached
		imageLabel.Visible = true
		return
	end

	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(
				userId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size100x100
			)
		end)
		if not ok or typeof(content) ~= "string" or token ~= thumbnailRequestToken then
			return
		end

		thumbnailCache[userId] = content
		if imageLabel.Parent then
			imageLabel.Image = content
			imageLabel.Visible = true
		end
	end)
end

local themePresets = {
	{
		name = "Ocean",
		panel = Color3.fromRGB(14, 18, 27),
		board = Color3.fromRGB(24, 28, 36),
		accent = Color3.fromRGB(30, 187, 255),
	},
	{
		name = "Candy",
		panel = Color3.fromRGB(35, 19, 36),
		board = Color3.fromRGB(45, 27, 49),
		accent = Color3.fromRGB(255, 93, 200),
	},
	{
		name = "Arcade",
		panel = Color3.fromRGB(12, 30, 24),
		board = Color3.fromRGB(18, 42, 35),
		accent = Color3.fromRGB(123, 237, 75),
	},
}
local themeIndex = 1

local function isFiniteNumber(value)
	return typeof(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function applyWorldVisualQuality()
	local hub = Workspace:FindFirstChild("BlockBlastHub")
	if hub then
		for _, descendant in hub:GetDescendants() do
			if descendant:IsA("ParticleEmitter") then
				local defaultRate = descendant:GetAttribute("DefaultRate")
				if not isFiniteNumber(defaultRate) then
					defaultRate = descendant.Rate
					descendant:SetAttribute("DefaultRate", defaultRate)
				end
				descendant.Rate = reducedMotion and math.min(defaultRate, 0.35) or defaultRate
			elseif descendant:IsA("PointLight") then
				local defaultBrightness = descendant:GetAttribute("DefaultBrightness")
				if not isFiniteNumber(defaultBrightness) then
					defaultBrightness = descendant.Brightness
					descendant:SetAttribute("DefaultBrightness", defaultBrightness)
				end
				descendant.Brightness = reducedMotion and defaultBrightness * 0.45
					or defaultBrightness
			end
		end
	end

	for _, effect in Lighting:GetChildren() do
		if effect.Name:match("^BlockBlast") then
			if effect:IsA("BloomEffect") then
				local defaultIntensity = effect:GetAttribute("DefaultIntensity")
				if not isFiniteNumber(defaultIntensity) then
					defaultIntensity = effect.Intensity
					effect:SetAttribute("DefaultIntensity", defaultIntensity)
				end
				effect.Intensity = reducedMotion and defaultIntensity * 0.45 or defaultIntensity
			elseif effect:IsA("SunRaysEffect") then
				local defaultIntensity = effect:GetAttribute("DefaultIntensity")
				if not isFiniteNumber(defaultIntensity) then
					defaultIntensity = effect.Intensity
					effect:SetAttribute("DefaultIntensity", defaultIntensity)
				end
				effect.Intensity = reducedMotion and defaultIntensity * 0.35 or defaultIntensity
			elseif effect:IsA("DepthOfFieldEffect") then
				local defaultFar = effect:GetAttribute("DefaultFarIntensity")
				if not isFiniteNumber(defaultFar) then
					defaultFar = effect.FarIntensity
					effect:SetAttribute("DefaultFarIntensity", defaultFar)
				end
				effect.FarIntensity = reducedMotion and 0 or defaultFar
			end
		end
	end
end

local gui = Instance.new("ScreenGui")
gui.Name = "BlockBlastBattleGui"
gui.ResetOnSpawn = false
-- Layout code throughout this file and HUDController manually reserves
-- safe-area space via GuiService:GetGuiInset(), so Roblox must not also
-- shrink AbsoluteSize/AbsolutePosition for the same inset or that space
-- gets reserved twice (visible as an extra gap, worst along the top edge).
gui.IgnoreGuiInset = true
gui.Parent = player:WaitForChild("PlayerGui")

if RunService:IsStudio() then
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.KeyCode == Enum.KeyCode.F8 then
			gui.Enabled = not gui.Enabled
		end
	end)
end

pcall(function()
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
end)

Workspace.ChildAdded:Connect(function(child)
	if child.Name == "BlockBlastHub" then
		task.defer(applyWorldVisualQuality)
	end
end)

loadingScreen = Instance.new("Frame")
loadingScreen.Size = UDim2.fromScale(1, 1)
loadingScreen.BackgroundColor3 = Color3.fromRGB(8, 11, 18)
loadingScreen.BorderSizePixel = 0
loadingScreen.ZIndex = 50
loadingScreen.Parent = gui

local loadingTitle = Instance.new("TextLabel")
loadingTitle.AnchorPoint = Vector2.new(0.5, 0.5)
loadingTitle.BackgroundTransparency = 1
loadingTitle.Position = UDim2.fromScale(0.5, 0.44)
loadingTitle.Size = UDim2.fromOffset(520, 54)
loadingTitle.Font = Enum.Font.GothamBlack
loadingTitle.Text = "BrickBlast"
loadingTitle.TextColor3 = Color3.fromRGB(245, 247, 251)
loadingTitle.TextSize = 34
loadingTitle.TextWrapped = true
loadingTitle.ZIndex = 51
loadingTitle.Parent = loadingScreen

local loadingStatus = Instance.new("TextLabel")
loadingStatus.AnchorPoint = Vector2.new(0.5, 0.5)
loadingStatus.BackgroundTransparency = 1
loadingStatus.Position = UDim2.fromScale(0.5, 0.5)
loadingStatus.Size = UDim2.fromOffset(420, 28)
loadingStatus.Font = Enum.Font.GothamBold
loadingStatus.Text = "Preparing your board..."
loadingStatus.TextColor3 = Color3.fromRGB(153, 163, 179)
loadingStatus.TextSize = 17
loadingStatus.ZIndex = 51
loadingStatus.Parent = loadingScreen

local loadingAccent = Instance.new("Frame")
loadingAccent.AnchorPoint = Vector2.new(0.5, 0.5)
loadingAccent.Position = UDim2.fromScale(0.5, 0.56)
loadingAccent.Size = UDim2.fromOffset(220, 4)
loadingAccent.BackgroundColor3 = Color3.fromRGB(30, 187, 255)
loadingAccent.BorderSizePixel = 0
loadingAccent.ZIndex = 51
loadingAccent.Parent = loadingScreen

local function dismissLoading()
	if loadingDismissed then
		return
	end

	loadingDismissed = true
	if reducedMotion then
		loadingScreen.Visible = false
		return
	end

	local tween = TweenService:Create(loadingScreen, TweenInfo.new(0.28), {
		BackgroundTransparency = 1,
	})
	TweenService:Create(loadingTitle, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
	TweenService:Create(loadingStatus, TweenInfo.new(0.2), { TextTransparency = 1 }):Play()
	TweenService:Create(loadingAccent, TweenInfo.new(0.2), { BackgroundTransparency = 1 }):Play()
	tween:Play()
	tween.Completed:Once(function()
		loadingScreen.Visible = false
	end)
end

banner = Instance.new("TextLabel")
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.Position = UDim2.fromScale(0.5, -0.08)
banner.Size = UDim2.fromOffset(520, 58)
banner.BackgroundColor3 = Color3.fromRGB(14, 18, 27)
banner.BackgroundTransparency = 0.08
banner.BorderSizePixel = 0
banner.Font = Enum.Font.GothamBlack
banner.Text = ""
banner.TextColor3 = Color3.fromRGB(245, 247, 251)
banner.TextSize = 24
banner.TextWrapped = true
banner.Visible = false
banner.Parent = gui
UITheme.card(banner, {
	color = UITheme.Color.panelRaised,
	strokeColor = UITheme.Color.primary,
	strokeTransparency = 0.2,
})

bannerScale = Instance.new("UIScale")
bannerScale.Scale = 1
bannerScale.Parent = banner

notificationController = NotificationController.new(gui, {
	isReducedMotion = function()
		return reducedMotion
	end,
})

if RunService:IsStudio() then
	diagnosticsPanel = Instance.new("Frame")
	diagnosticsPanel.AnchorPoint = Vector2.new(1, 1)
	diagnosticsPanel.Position = UDim2.new(1, -18, 1, -18)
	diagnosticsPanel.Size = UDim2.fromOffset(390, 190)
	diagnosticsPanel.BackgroundColor3 = Color3.fromRGB(8, 11, 18)
	diagnosticsPanel.BackgroundTransparency = 0.08
	diagnosticsPanel.BorderSizePixel = 0
	diagnosticsPanel.ZIndex = 40
	diagnosticsPanel.Visible = diagnosticsVisible
	diagnosticsPanel.Parent = gui

	diagnosticsLabel = Instance.new("TextLabel")
	diagnosticsLabel.BackgroundTransparency = 1
	diagnosticsLabel.Position = UDim2.fromOffset(12, 10)
	diagnosticsLabel.Size = UDim2.fromOffset(366, 170)
	diagnosticsLabel.Font = Enum.Font.Code
	diagnosticsLabel.Text = "Studio diagnostics loading..."
	diagnosticsLabel.TextColor3 = Color3.fromRGB(210, 224, 255)
	diagnosticsLabel.TextSize = 13
	diagnosticsLabel.TextXAlignment = Enum.TextXAlignment.Left
	diagnosticsLabel.TextYAlignment = Enum.TextYAlignment.Top
	diagnosticsLabel.TextWrapped = true
	diagnosticsLabel.ZIndex = 41
	diagnosticsLabel.Parent = diagnosticsPanel

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or input.KeyCode ~= Enum.KeyCode.F8 then
			return
		end

		diagnosticsVisible = not diagnosticsVisible
		diagnosticsPanel.Visible = diagnosticsVisible
	end)
end

local function applyUiScale()
	local screenSize = gui.AbsoluteSize
	local automaticScale = 1
	if screenSize.X < 1180 or screenSize.Y < 720 then
		automaticScale = 0.92
	elseif screenSize.X < 1366 then
		automaticScale = 0.96
	end

	local nextScale = automaticScale * uiScale
	local topLeftInset, bottomRightInset = GuiService:GetGuiInset()
	WINDOW_LAYOUT = SoloLayout.calculate(screenSize, topLeftInset.Y, bottomRightInset.Y, nextScale)
	if rootScale then
		rootScale.Scale = 1
	end
	if homePanelController then
		homePanelController:RefreshResponsiveLayout(screenSize, nextScale)
	end
	if applyWindowLayout then
		applyWindowLayout()
	end
	if bannerScale then
		bannerScale.Scale = math.max(0.82, nextScale)
	end
	if notificationController then
		notificationController:RefreshResponsiveLayout()
	end
	if hudController then
		hudController:RefreshResponsiveLayout()
	end
end

local function settingsPayload()
	return {
		themeIndex = themeIndex,
		reducedMotion = reducedMotion,
		uiScale = uiScale,
		tutorialComplete = tutorialComplete,
		pieceSkin = Blocks.PieceSkins[pieceSkinIndex] or "Rainbow",
		boardSkin = Config.BoardSkins[boardSkinIndex] and Config.BoardSkins[boardSkinIndex].name
			or "Auto",
		soundEnabled = soundEnabled,
		soundVolume = soundVolume,
	}
end

local function applySoundSettings()
	soundController:SetSettings(soundEnabled, soundVolume)
end

local function playSound(cueName)
	soundController:Play(cueName)
end

local function saveSettings()
	settingsEvent:FireServer("Update", settingsPayload())
end

function day43Ui.fireQueueRequest(action, payload)
	local now = os.clock()
	if now - day43Ui.lastServerActionAt < day43Ui.serverActionCooldownSeconds then
		return false
	end

	day43Ui.lastServerActionAt = now
	if payload ~= nil then
		queueEvent:FireServer(action, payload)
	else
		queueEvent:FireServer(action)
	end
	return true
end

local function localCosmeticProgress()
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local level = leaderstats and leaderstats:FindFirstChild("Level")
	local storyStars = leaderstats and leaderstats:FindFirstChild("StoryStars")

	return {
		coins = coins and coins.Value or 0,
		level = level and level.Value or 1,
		storyStars = storyStars and storyStars.Value or 0,
	}
end

local function isPieceSkinUnlocked(index)
	local skinName = Blocks.PieceSkins[index]
	return Config.meetsCosmeticRequirement(
		Config.PieceSkinUnlocks[skinName],
		localCosmeticProgress()
	)
end

local function isBoardSkinUnlocked(index)
	local skin = Config.BoardSkins[index]
	return Config.meetsCosmeticRequirement(
		skin and Config.BoardSkinUnlocks[skin.name],
		localCosmeticProgress()
	)
end

local function lockedText(requirement)
	return requirement and requirement.label or "Keep playing"
end

local function nextLockedCosmeticText()
	for _, skinName in Blocks.PieceSkins do
		local requirement = Config.PieceSkinUnlocks[skinName]
		if not Config.meetsCosmeticRequirement(requirement, localCosmeticProgress()) then
			return `Next pieces: {skinName} at {lockedText(requirement)}`
		end
	end

	for _, skin in Config.BoardSkins do
		local requirement = Config.BoardSkinUnlocks[skin.name]
		if not Config.meetsCosmeticRequirement(requirement, localCosmeticProgress()) then
			return `Next board: {skin.name} at {lockedText(requirement)}`
		end
	end

	return "All current cosmetics unlocked"
end

local function shopCosmeticItems()
	local progress = localCosmeticProgress()
	local items = {}

	for _, skinName in Blocks.PieceSkins do
		local requirement = Config.PieceSkinUnlocks[skinName]
		local unlocked = Config.meetsCosmeticRequirement(requirement, progress)
		table.insert(items, {
			id = `PIECE_{skinName}`,
			itemType = "Cosmetic",
			name = `{skinName} Pieces`,
			category = "Cosmetics",
			description = unlocked and "Owned progression piece style."
				or `Unlock through play: {lockedText(requirement)}`,
			state = Blocks.PieceSkins[pieceSkinIndex] == skinName and "Equipped"
				or unlocked and "Owned"
				or "Locked",
			owned = unlocked,
			equipped = Blocks.PieceSkins[pieceSkinIndex] == skinName,
			available = unlocked,
			lockedText = lockedText(requirement),
		})
	end

	for _, skin in Config.BoardSkins do
		local requirement = Config.BoardSkinUnlocks[skin.name]
		local unlocked = Config.meetsCosmeticRequirement(requirement, progress)
		table.insert(items, {
			id = `BOARD_{skin.name}`,
			itemType = "Cosmetic",
			name = `{skin.name} Board`,
			category = "Cosmetics",
			description = unlocked and "Owned progression board style."
				or `Unlock through play: {lockedText(requirement)}`,
			state = Config.BoardSkins[boardSkinIndex] == skin and "Equipped"
				or unlocked and "Owned"
				or "Locked",
			owned = unlocked,
			equipped = Config.BoardSkins[boardSkinIndex] == skin,
			available = unlocked,
			lockedText = lockedText(requirement),
		})
	end

	return items
end

local function previewColorsForPieceSkin(skinName)
	if skinName == "Neon" then
		return {
			Color3.fromRGB(0, 255, 234),
			Color3.fromRGB(255, 93, 200),
			Color3.fromRGB(255, 210, 71),
			Color3.fromRGB(123, 237, 75),
		}
	elseif skinName == "Pastel" then
		return {
			Color3.fromRGB(255, 183, 213),
			Color3.fromRGB(184, 219, 255),
			Color3.fromRGB(197, 245, 190),
			Color3.fromRGB(244, 221, 158),
		}
	elseif skinName == "Ice" then
		return {
			Color3.fromRGB(154, 224, 255),
			Color3.fromRGB(185, 238, 255),
			Color3.fromRGB(217, 248, 255),
			Color3.fromRGB(128, 201, 242),
		}
	end

	return {
		Color3.fromRGB(255, 86, 107),
		Color3.fromRGB(255, 210, 71),
		Color3.fromRGB(123, 237, 75),
		Color3.fromRGB(30, 187, 255),
	}
end

local function updateCosmeticPreviews()
	local skinName = Blocks.PieceSkins[pieceSkinIndex] or "Rainbow"
	local colors = previewColorsForPieceSkin(skinName)

	local boardSkin = Config.BoardSkins[boardSkinIndex]
	local emptyColor = boardSkin and boardSkin.empty or customization.boardEmptyColor
	local borderColor = boardSkin and boardSkin.border or customization.accentColor
	if homePanelController then
		homePanelController:UpdateCosmeticPreviews(colors, {
			empty = emptyColor,
			border = borderColor,
		})
	end
end

local function updateSettingsButtonText()
	if homePanelController then
		local boardSkin = Config.BoardSkins[boardSkinIndex]
		homePanelController:UpdateSettings({
			reducedMotion = reducedMotion,
			uiScale = uiScale,
			pieceSkin = Blocks.PieceSkins[pieceSkinIndex] or "Rainbow",
			boardSkin = boardSkin and boardSkin.name or "Auto",
			soundEnabled = soundEnabled,
			soundVolume = soundVolume,
		})
	end

	updateCosmeticPreviews()
	if cosmeticPanelController then
		cosmeticPanelController:Refresh()
	end
	if shopPanelController then
		shopPanelController:Refresh()
	end
	if hudController then
		hudController:UpdateProgression()
	end
end

local function updateTutorialVisibility()
	if not tutorialPanel then
		return
	end

	tutorialPanel.Visible = currentState == nil and tutorialManuallyOpened
end

local function showBanner(message, color)
	if message == "Welcome to the hub" or message == ExperienceConfig.Solo.WelcomeMessage then
		return
	end

	if notificationController then
		local kind = "info"
		if color == Color3.fromRGB(255, 86, 107) then
			kind = "error"
		elseif color == Color3.fromRGB(255, 139, 61) or color == Color3.fromRGB(255, 210, 71) then
			kind = "warning"
		elseif color == Color3.fromRGB(123, 237, 75) then
			kind = "success"
		end
		notificationController:Show(message, kind)
		return
	end

	banner.Text = message
	banner.BackgroundColor3 = color or Color3.fromRGB(14, 18, 27)
	banner.TextTransparency = 1
	banner.BackgroundTransparency = 1
	banner.Position = UDim2.fromScale(0.5, -0.08)
	banner.Visible = true

	if reducedMotion then
		banner.Position = UDim2.fromScale(0.5, 0.035)
		banner.TextTransparency = 0
		banner.BackgroundTransparency = 0.08
		return
	end

	TweenService:Create(banner, SOFT_TWEEN, {
		Position = UDim2.fromScale(0.5, 0.035),
		TextTransparency = 0,
		BackgroundTransparency = 0.08,
	}):Play()

	task.delay(2.3, function()
		if banner.Text ~= message then
			return
		end

		local tween = TweenService:Create(banner, TweenInfo.new(0.22), {
			Position = UDim2.fromScale(0.5, -0.08),
			TextTransparency = 1,
			BackgroundTransparency = 1,
		})
		tween:Play()
		tween.Completed:Once(function()
			if banner.Text == message then
				banner.Visible = false
			end
		end)
	end)
end

local function restoreCosmeticPreview()
	if not cosmeticPreviewSnapshot then
		return
	end

	pieceSkinIndex = cosmeticPreviewSnapshot.pieceSkinIndex
	boardSkinIndex = cosmeticPreviewSnapshot.boardSkinIndex
	cosmeticPreviewSnapshot = nil
	updateSettingsButtonText()
	if applyBoardSkin then
		applyBoardSkin()
	end
	if currentState and renderBoard then
		renderBoard(true)
	end
end

function day43Ui.closeMajorPanels(except)
	if except ~= "shop" and shopPanelController then
		shopPanelController:Hide()
	end
	if except ~= "cosmetics" and cosmeticPanelController then
		cosmeticPanelController:Hide()
	end
	if except ~= "story" and storyPanelController then
		storyPanelController:Hide()
	end
	if except ~= "menu" and hudController and hudController.menu then
		hudController.menu:Close()
	end
	if except ~= "tutorial" then
		tutorialManuallyOpened = false
		updateTutorialVisibility()
	end
end

local function previewShopCosmetic(item)
	if typeof(item) ~= "table" or typeof(item.preview) ~= "table" then
		return
	end

	if not cosmeticPreviewSnapshot then
		cosmeticPreviewSnapshot = {
			pieceSkinIndex = pieceSkinIndex,
			boardSkinIndex = boardSkinIndex,
		}
	end

	if typeof(item.preview.pieceSkin) == "string" then
		for index, skinName in Blocks.PieceSkins do
			if skinName == item.preview.pieceSkin then
				pieceSkinIndex = index
				break
			end
		end
	end

	if typeof(item.preview.boardSkin) == "string" then
		for index, skin in Config.BoardSkins do
			if skin.name == item.preview.boardSkin then
				boardSkinIndex = index
				break
			end
		end
	end

	updateSettingsButtonText()
	if applyBoardSkin then
		applyBoardSkin()
	end
	if currentState and renderBoard then
		renderBoard(true)
	end
	showBanner(`Previewing {item.name or "cosmetic"}`, customization.accentColor)
end

resultPanelController = ResultPanel.new(gui, queueEvent, {
	playSound = playSound,
	isReducedMotion = function()
		return reducedMotion
	end,
	hasCurrentRun = function()
		return currentState ~= nil
	end,
})

cosmeticPanelController = CosmeticPanel.new(gui, Blocks, Config, {
	playSound = playSound,
	showMessage = showBanner,
	getProgress = localCosmeticProgress,
	getPieceSkin = function()
		return Blocks.PieceSkins[pieceSkinIndex] or "Rainbow"
	end,
	getBoardSkin = function()
		local boardSkin = Config.BoardSkins[boardSkinIndex]
		return boardSkin and boardSkin.name or "Auto"
	end,
	selectPieceSkin = function(index)
		pieceSkinIndex = index
		updateSettingsButtonText()
		saveSettings()
		showBanner(
			`Pieces: {Blocks.PieceSkins[pieceSkinIndex] or "Rainbow"}`,
			customization.accentColor
		)
	end,
	selectBoardSkin = function(index)
		boardSkinIndex = index
		updateSettingsButtonText()
		if applyBoardSkin then
			applyBoardSkin()
		end
		if currentState and renderBoard then
			renderBoard(true)
		end
		saveSettings()
		local boardSkin = Config.BoardSkins[boardSkinIndex]
		showBanner(`Board: {boardSkin and boardSkin.name or "Auto"}`, customization.accentColor)
	end,
})

shopPanelController = ShopPanel.new(gui, {
	shopEvent = shopEvent,
	playSound = playSound,
	showMessage = showBanner,
	getCosmetics = shopCosmeticItems,
	previewCosmetic = previewShopCosmetic,
	stopPreview = restoreCosmeticPreview,
	openCloset = function()
		day43Ui.closeMajorPanels("cosmetics")
		cosmeticPanelController:Show()
	end,
})

storyPanelController = StoryPanel.new(gui, {
	playSound = playSound,
	showMessage = showBanner,
	getMissions = function()
		return currentHubState and currentHubState.storyMissions or {}
	end,
	startMission = function(chapter)
		day43Ui.fireQueueRequest("Story", chapter)
	end,
})

hudController = HUDController.new(gui, {
	player = player,
	playSound = playSound,
	notify = function(message, kind)
		if notificationController then
			notificationController:Show(message, kind)
		else
			showBanner(message, customization.accentColor)
		end
	end,
	isReducedMotion = function()
		return reducedMotion
	end,
	callbacks = {
		play = function()
			day43Ui.closeMajorPanels()
			if currentState then
				root.Visible = true
				clampWindowToScreen()
				return
			end
			if
				ExperienceConfig.isModeEnabled("Solo")
				and not ExperienceConfig.isModeEnabled("Battle")
			then
				day43Ui.fireQueueRequest("Solo")
			elseif currentHubState and currentHubState.queued then
				day43Ui.fireQueueRequest("LeaveQueue")
			else
				day43Ui.fireQueueRequest("Battle")
			end
		end,
		modes = function()
			if currentState then
				showBanner("Finish your current run first", Color3.fromRGB(255, 139, 61))
				return
			end
			day43Ui.closeMajorPanels("menu")
			hudController.menu:Open("modes", "Choose Mode", function(content)
				local layout = Instance.new("UIListLayout")
				layout.Padding = UDim.new(0, 10)
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.Parent = content

				local function makeModeButton(order, titleText, detailText, color, callback)
					local button = Instance.new("TextButton")
					button.LayoutOrder = order
					button.Size = UDim2.new(1, 0, 0, 72)
					button.BackgroundColor3 = color
					button.BorderSizePixel = 0
					button.Text = ""
					button.Selectable = true
					button.Parent = content
					UITheme.button(button, order == 1 and "primary" or "secondary")
					button.BackgroundColor3 = color
					UITheme.attachButtonFeedback(button, isUiReducedMotion)

					local titleLabel = Instance.new("TextLabel")
					titleLabel.BackgroundTransparency = 1
					titleLabel.Position = UDim2.fromOffset(14, 8)
					titleLabel.Size = UDim2.new(1, -28, 0, 24)
					titleLabel.Font = Enum.Font.GothamBlack
					titleLabel.Text = titleText
					titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
					titleLabel.TextSize = 17
					titleLabel.TextXAlignment = Enum.TextXAlignment.Left
					titleLabel.Parent = button

					local detailLabel = Instance.new("TextLabel")
					detailLabel.BackgroundTransparency = 1
					detailLabel.Position = UDim2.fromOffset(14, 34)
					detailLabel.Size = UDim2.new(1, -28, 0, 28)
					detailLabel.Font = Enum.Font.Gotham
					detailLabel.Text = detailText
					detailLabel.TextColor3 = Color3.fromRGB(240, 248, 255)
					detailLabel.TextSize = 13
					detailLabel.TextWrapped = true
					detailLabel.TextXAlignment = Enum.TextXAlignment.Left
					detailLabel.Parent = button

					button.Activated:Connect(function()
						playSound("Button")
						hudController.menu:Close()
						callback()
					end)
				end

				local order = 1
				if ExperienceConfig.isModeEnabled("Battle") then
					makeModeButton(
						order,
						"Battle Queue",
						"Classic race to outscore rivals.",
						Color3.fromRGB(30, 187, 255),
						function()
							day43Ui.fireQueueRequest("Battle")
						end
					)
					order += 1
				end
				if ExperienceConfig.isModeEnabled("Story") then
					makeModeButton(
						order,
						"Story Missions",
						"Solo objectives and replayable guide practice.",
						Color3.fromRGB(190, 118, 255),
						function()
							day43Ui.closeMajorPanels("story")
							storyPanelController:Show()
						end
					)
					order += 1
				end
				if ExperienceConfig.isModeEnabled("CustomLab") then
					makeModeButton(
						order,
						"Custom Lab",
						"Test block rotations and reroll your hand.",
						Color3.fromRGB(255, 93, 200),
						function()
							day43Ui.fireQueueRequest("CustomLab")
						end
					)
					order += 1
				end
				if order == 1 then
					makeModeButton(
						order,
						"Solo Puzzle",
						"Battle, Story, and Custom Lab are disabled in this build.",
						Color3.fromRGB(30, 187, 255),
						function()
							day43Ui.fireQueueRequest("Solo")
						end
					)
				end
			end)
		end,
		inventory = function()
			day43Ui.closeMajorPanels("cosmetics")
			cosmeticPanelController:Show()
		end,
		shop = function()
			day43Ui.closeMajorPanels("shop")
			shopPanelController:Show()
		end,
		rewards = function()
			day43Ui.closeMajorPanels("menu")
			hudController:OpenInfoPanel("Quests", {
				"COMING SOON",
				"Solo scores, coins, XP, and personal bests are already tracked.",
				"Daily quests are intentionally disabled in this solo-first build.",
			})
		end,
		codes = function()
			day43Ui.closeMajorPanels("menu")
			hudController.menu:Open("codes", "Redeem Code", function(content)
				local layout = Instance.new("UIListLayout")
				layout.Padding = UDim.new(0, 12)
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.Parent = content

				local hint = Instance.new("TextLabel")
				hint.LayoutOrder = 1
				hint.BackgroundTransparency = 1
				hint.Size = UDim2.new(1, 0, 0, 40)
				hint.Font = Enum.Font.GothamBold
				hint.Text = "Enter a code to redeem a reward."
				hint.TextColor3 = Color3.fromRGB(190, 210, 233)
				hint.TextSize = 15
				hint.TextWrapped = true
				hint.TextXAlignment = Enum.TextXAlignment.Left
				hint.Parent = content

				local input = Instance.new("TextBox")
				input.LayoutOrder = 2
				input.Size = UDim2.new(1, 0, 0, 52)
				input.BackgroundColor3 = Color3.fromRGB(14, 23, 43)
				input.BorderSizePixel = 0
				input.ClearTextOnFocus = false
				input.Font = Enum.Font.GothamBlack
				input.PlaceholderText = "Enter code"
				input.PlaceholderColor3 = Color3.fromRGB(120, 136, 168)
				input.Text = ""
				input.TextColor3 = Color3.fromRGB(255, 255, 255)
				input.TextSize = 18
				input.Parent = content
				UITheme.corner(input, 12)
				UITheme.stroke(input, Color3.fromRGB(30, 187, 255), 2, 0.2)

				local status = Instance.new("TextLabel")
				status.LayoutOrder = 3
				status.BackgroundTransparency = 1
				status.Size = UDim2.new(1, 0, 0, 30)
				status.Font = Enum.Font.GothamBold
				status.Text = ""
				status.TextColor3 = Color3.fromRGB(190, 210, 233)
				status.TextSize = 14
				status.TextWrapped = true
				status.TextXAlignment = Enum.TextXAlignment.Left
				status.Parent = content
				day43Ui.codeStatusLabel = status

				local redeem = Instance.new("TextButton")
				redeem.LayoutOrder = 4
				redeem.Size = UDim2.new(1, 0, 0, 54)
				redeem.BorderSizePixel = 0
				redeem.Font = Enum.Font.GothamBlack
				redeem.Text = "REDEEM"
				redeem.TextSize = 18
				redeem.Parent = content
				UITheme.button(redeem, "success")
				UITheme.attachButtonFeedback(redeem, isUiReducedMotion)

				local function submit()
					local code = input.Text
					if not code or code:gsub("%s", "") == "" then
						status.Text = "Type a code first."
						status.TextColor3 = Color3.fromRGB(255, 139, 61)
						return
					end
					playSound("Button")
					status.Text = "Checking..."
					status.TextColor3 = Color3.fromRGB(190, 210, 233)
					day43Ui.codesEvent:FireServer(code)
				end

				redeem.Activated:Connect(submit)
				input.FocusLost:Connect(function(enterPressed)
					if enterPressed then
						submit()
					end
				end)
			end)
		end,
		achievements = function()
			day43Ui.closeMajorPanels("menu")
			hudController.menu:Open("achievements", "Achievements", function(content)
				local scroll = Instance.new("ScrollingFrame")
				scroll.Size = UDim2.fromScale(1, 1)
				scroll.BackgroundTransparency = 1
				scroll.BorderSizePixel = 0
				scroll.ScrollBarThickness = 6
				scroll.ScrollBarImageColor3 = Color3.fromRGB(30, 187, 255)
				scroll.CanvasSize = UDim2.fromOffset(0, 0)
				scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
				scroll.Parent = content

				local layout = Instance.new("UIListLayout")
				layout.Padding = UDim.new(0, 8)
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.Parent = scroll

				local loading = Instance.new("TextLabel")
				loading.Name = "Loading"
				loading.BackgroundTransparency = 1
				loading.Size = UDim2.new(1, 0, 0, 40)
				loading.Font = Enum.Font.GothamBold
				loading.Text = "Loading achievements..."
				loading.TextColor3 = Color3.fromRGB(190, 210, 233)
				loading.TextSize = 15
				loading.Parent = scroll

				day43Ui.achievementsScroll = scroll
				day43Ui.achievementsEvent:FireServer("RequestSnapshot")
			end)
		end,
		settings = function()
			day43Ui.closeMajorPanels("menu")
			hudController.menu:Open("settings", "Settings", function(content)
				local layout = Instance.new("UIListLayout")
				layout.Padding = UDim.new(0, 10)
				layout.SortOrder = Enum.SortOrder.LayoutOrder
				layout.Parent = content

				local function makeSettingButton(order, text, callback)
					local button = Instance.new("TextButton")
					button.LayoutOrder = order
					button.Size = UDim2.new(1, 0, 0, 58)
					button.BackgroundColor3 = Color3.fromRGB(42, 57, 96)
					button.BorderSizePixel = 0
					button.Font = Enum.Font.GothamBold
					button.Text = text
					button.TextColor3 = Color3.fromRGB(245, 247, 251)
					button.TextSize = 16
					button.TextWrapped = true
					button.Parent = content
					styleButton(button, "secondary")
					button.Activated:Connect(function()
						callback()
						hudController:SetMenuButtonSelected("settings")
					end)
				end

				makeSettingButton(
					1,
					reducedMotion and "Motion: Reduced" or "Motion: Full",
					function()
						reducedMotion = not reducedMotion
						updateSettingsButtonText()
						playSound("Button")
						saveSettings()
						hudController.callbacks.settings()
					end
				)
				makeSettingButton(
					2,
					soundEnabled and `Sound: {math.floor(soundVolume * 100)}%` or "Sound: Off",
					function()
						if soundVolume > 0.36 then
							soundVolume = 0.35
							soundEnabled = true
						elseif soundVolume > 0 then
							soundVolume = 0
							soundEnabled = false
						else
							soundVolume = 0.65
							soundEnabled = true
						end
						updateSettingsButtonText()
						applySoundSettings()
						playSound("Button")
						saveSettings()
						hudController.callbacks.settings()
					end
				)
				makeSettingButton(
					3,
					uiScale == 1 and "UI Size: Auto"
						or uiScale > 1 and "UI Size: Large"
						or "UI Size: Compact",
					function()
						if uiScale == 1 then
							uiScale = 1.12
						elseif uiScale > 1 then
							uiScale = 0.92
						else
							uiScale = 1
						end
						updateSettingsButtonText()
						applyUiScale()
						clampWindowToScreen()
						playSound("Button")
						saveSettings()
						hudController.callbacks.settings()
					end
				)
			end)
		end,
	},
})

root = Instance.new("Frame")
root.Name = "PCPuzzleWorkspace"
root.AnchorPoint = Vector2.new(0, 0)
root.Position = UDim2.fromOffset(0, 0)
root.Size = UDim2.fromScale(1, 1)
root.BackgroundColor3 = Color3.fromRGB(10, 17, 34)
root.BackgroundTransparency = 0
root.BorderSizePixel = 0
root.Visible = false
root.ZIndex = 1
root.Parent = gui
-- radius = 0: root is stretched to the literal screen edges, so any corner
-- rounding here shows as a background sliver at the four screen corners
-- instead of a floating-card look. Inner panels keep their own rounding.
ArcadeUI.Panel(root, {
	radius = 0,
	rimColor = ArcadeUI.Color.rimBright,
	strokeThickness = 5,
})
root.BackgroundTransparency = 0
local rootStroke = root:FindFirstChildOfClass("UIStroke")
if rootStroke then
	rootStroke.Thickness = 5
	rootStroke.Transparency = 1
end
removeDirectGradients(root)
local rootHighlight = root:FindFirstChild("ArcadeTopHighlight")
if rootHighlight and rootHighlight:IsA("GuiObject") then
	rootHighlight.Visible = false
end

rootScale = Instance.new("UIScale")
rootScale.Scale = 1
rootScale.Parent = root

stageUi.decorations = {}
for decorIndex = 1, 6 do
	local decor = Instance.new("Frame")
	decor.Name = `StageBackdropAccent{decorIndex}`
	decor.Active = false
	decor.BackgroundTransparency = 0.72
	decor.BorderSizePixel = 0
	decor.ZIndex = 1
	decor.Parent = root
	UITheme.corner(decor, 28)
	stageUi.decorations[decorIndex] = decor
end

stageUi.wash = Instance.new("Frame")
stageUi.wash.Name = "StageTransitionWash"
stageUi.wash.Active = false
stageUi.wash.BackgroundTransparency = 1
stageUi.wash.BorderSizePixel = 0
stageUi.wash.Position = UDim2.fromScale(0, 0)
stageUi.wash.Size = UDim2.fromScale(1, 1)
stageUi.wash.ZIndex = 75
stageUi.wash.Parent = root

stageUi.notice = Instance.new("TextLabel")
stageUi.notice.Name = "StageUpNotice"
stageUi.notice.Active = false
stageUi.notice.BackgroundTransparency = 1
stageUi.notice.Font = Enum.Font.GothamBlack
stageUi.notice.Text = ""
stageUi.notice.TextColor3 = Color3.fromRGB(255, 255, 255)
stageUi.notice.TextScaled = true
stageUi.notice.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
stageUi.notice.TextStrokeTransparency = 0.45
stageUi.notice.Visible = false
stageUi.notice.ZIndex = 76
stageUi.notice.Parent = root

workspaceHeader = makeWorkspaceContainer(
	"WorkspaceHeader",
	root,
	Color3.fromRGB(9, 28, 56),
	22,
	ArcadeUI.Color.rimBright,
	2
)
workspaceContent = Instance.new("Frame")
workspaceContent.Name = "WorkspaceContent"
workspaceContent.BackgroundTransparency = 1
workspaceContent.BorderSizePixel = 0
workspaceContent.Parent = root

leftColumn = Instance.new("Frame")
leftColumn.Name = "StatsColumn"
leftColumn.BackgroundTransparency = 1
leftColumn.BorderSizePixel = 0
leftColumn.Parent = workspaceContent

centerColumn = Instance.new("Frame")
centerColumn.Name = "GameplayColumn"
centerColumn.BackgroundTransparency = 1
centerColumn.BorderSizePixel = 0
centerColumn.Parent = workspaceContent

rightColumn = Instance.new("Frame")
rightColumn.Name = "LeaderboardColumn"
rightColumn.BackgroundTransparency = 1
rightColumn.BorderSizePixel = 0
rightColumn.Parent = workspaceContent

boardStage = Instance.new("Frame")
boardStage.Name = "BoardStage"
boardStage.BackgroundTransparency = 1
boardStage.BorderSizePixel = 0
boardStage.Parent = centerColumn

trayStage = Instance.new("Frame")
trayStage.Name = "PieceTrayStage"
trayStage.BackgroundTransparency = 1
trayStage.BorderSizePixel = 0
trayStage.Parent = centerColumn

actionsPanel = Instance.new("Frame")
actionsPanel.Name = "WorkspaceActions"
actionsPanel.BackgroundTransparency = 1
actionsPanel.BorderSizePixel = 0
actionsPanel.Parent = rightColumn

local function nextUnlockedIndex(currentIndex, itemCount, isUnlocked)
	for offset = 1, itemCount do
		local nextIndex = ((currentIndex + offset - 1) % itemCount) + 1
		if isUnlocked(nextIndex) then
			return nextIndex
		end
	end

	return currentIndex
end

homePanelController = HomePanel.new(gui, {
	playSound = playSound,
	showBanner = showBanner,
	isReducedMotion = isUiReducedMotion,
	callbacks = {
		close = function()
			hubManuallyClosed = true
		end,
		reopen = function()
			hubManuallyClosed = false
			homePanelController:SetVisible(true, currentState == nil)
		end,
		guide = function()
			tutorialManuallyOpened = true
			updateTutorialVisibility()
		end,
		battle = function(queued)
			day43Ui.closeMajorPanels()
			if
				ExperienceConfig.isModeEnabled("Solo")
				and not ExperienceConfig.isModeEnabled("Battle")
			then
				day43Ui.fireQueueRequest("Solo")
			else
				day43Ui.fireQueueRequest(queued and "LeaveQueue" or "Battle")
			end
		end,
		story = function()
			day43Ui.closeMajorPanels("story")
			storyPanelController:Show()
		end,
		motion = function()
			reducedMotion = not reducedMotion
			updateSettingsButtonText()
			playSound("Button")
			saveSettings()
			showBanner(
				reducedMotion and "Motion: Reduced" or "Motion: Full",
				customization.accentColor
			)
		end,
		uiSize = function()
			if uiScale == 1 then
				uiScale = 1.12
			elseif uiScale > 1 then
				uiScale = 0.92
			else
				uiScale = 1
			end
			updateSettingsButtonText()
			applyUiScale()
			clampWindowToScreen()
			playSound("Button")
			saveSettings()
		end,
		pieceSkin = function()
			local nextIndex =
				nextUnlockedIndex(pieceSkinIndex, #Blocks.PieceSkins, isPieceSkinUnlocked)
			if nextIndex == pieceSkinIndex then
				showBanner(nextLockedCosmeticText(), Color3.fromRGB(255, 139, 61))
				playSound("Blocked")
				return
			end

			pieceSkinIndex = nextIndex
			updateSettingsButtonText()
			playSound("Button")
			saveSettings()
			showBanner(
				`Pieces: {Blocks.PieceSkins[pieceSkinIndex] or "Rainbow"}`,
				customization.accentColor
			)
		end,
		boardSkin = function()
			local nextIndex =
				nextUnlockedIndex(boardSkinIndex, #Config.BoardSkins, isBoardSkinUnlocked)
			if nextIndex == boardSkinIndex then
				showBanner(nextLockedCosmeticText(), Color3.fromRGB(255, 139, 61))
				playSound("Blocked")
				return
			end

			boardSkinIndex = nextIndex
			updateSettingsButtonText()
			applyBoardSkin()
			if currentState then
				renderBoard(true)
			end
			playSound("Button")
			saveSettings()
			local boardSkin = Config.BoardSkins[boardSkinIndex]
			showBanner(`Board: {boardSkin and boardSkin.name or "Auto"}`, customization.accentColor)
		end,
		shop = function()
			day43Ui.closeMajorPanels("shop")
			shopPanelController:Show()
		end,
		sound = function()
			if soundVolume > 0.36 then
				soundVolume = 0.35
				soundEnabled = true
			elseif soundVolume > 0 then
				soundVolume = 0
				soundEnabled = false
			else
				soundVolume = 0.65
				soundEnabled = true
			end

			updateSettingsButtonText()
			applySoundSettings()
			playSound("Button")
			saveSettings()
		end,
	},
})
homePanelController:SetVisible(false, false)

local function setHubPanelVisible(_visible)
	homePanelController:SetVisible(false, false)
end

tutorialPanel = Instance.new("Frame")
tutorialPanel.AnchorPoint = Vector2.new(1, 0)
tutorialPanel.Position = UDim2.new(1, -28, 0, 88)
tutorialPanel.Size = UDim2.fromOffset(320, 206)
tutorialPanel.BackgroundColor3 = Color3.fromRGB(14, 18, 27)
tutorialPanel.BackgroundTransparency = 0.08
tutorialPanel.BorderSizePixel = 0
tutorialPanel.Visible = false
tutorialPanel.Parent = gui
UITheme.panel(
	tutorialPanel,
	{ color = UITheme.Color.panel, bottomColor = UITheme.Color.background }
)

local tutorialTitle = Instance.new("TextLabel")
tutorialTitle.BackgroundTransparency = 1
tutorialTitle.Position = UDim2.fromOffset(18, 14)
tutorialTitle.Size = UDim2.fromOffset(284, 28)
tutorialTitle.Font = Enum.Font.GothamBlack
tutorialTitle.Text = "Start Strong"
tutorialTitle.TextColor3 = Color3.fromRGB(245, 247, 251)
tutorialTitle.TextSize = 22
tutorialTitle.TextXAlignment = Enum.TextXAlignment.Left
tutorialTitle.Parent = tutorialPanel
UITheme.text(tutorialTitle, "title")

local tutorialBody = Instance.new("TextLabel")
tutorialBody.BackgroundTransparency = 1
tutorialBody.Position = UDim2.fromOffset(18, 50)
tutorialBody.Size = UDim2.fromOffset(284, 96)
tutorialBody.Font = Enum.Font.Gotham
tutorialBody.Text =
	"1. Press Play to start a solo run.\n2. Pick a piece on the right.\n3. Clear full rows or columns and beat your best score."
tutorialBody.TextColor3 = Color3.fromRGB(193, 201, 215)
tutorialBody.TextSize = 15
tutorialBody.TextWrapped = true
tutorialBody.TextXAlignment = Enum.TextXAlignment.Left
tutorialBody.TextYAlignment = Enum.TextYAlignment.Top
tutorialBody.Parent = tutorialPanel
UITheme.text(tutorialBody, "muted")

local tutorialButton = Instance.new("TextButton")
tutorialButton.Position = UDim2.fromOffset(18, 158)
tutorialButton.Size = UDim2.fromOffset(132, 34)
tutorialButton.BackgroundColor3 = Color3.fromRGB(30, 187, 255)
tutorialButton.BorderSizePixel = 0
tutorialButton.Font = Enum.Font.GothamBold
tutorialButton.Text = "Got It"
tutorialButton.TextColor3 = Color3.fromRGB(255, 255, 255)
tutorialButton.TextSize = 15
tutorialButton.Parent = tutorialPanel
styleButton(tutorialButton, "primary")

local tutorialStoryButton = Instance.new("TextButton")
tutorialStoryButton.Position = UDim2.fromOffset(162, 158)
tutorialStoryButton.Size = UDim2.fromOffset(140, 34)
tutorialStoryButton.BackgroundColor3 = Color3.fromRGB(42, 57, 96)
tutorialStoryButton.BorderSizePixel = 0
tutorialStoryButton.Font = Enum.Font.GothamBold
tutorialStoryButton.Text = "Try Story"
tutorialStoryButton.Visible = ExperienceConfig.isModeEnabled("Story")
tutorialStoryButton.TextColor3 = Color3.fromRGB(245, 247, 251)
tutorialStoryButton.TextSize = 15
tutorialStoryButton.Parent = tutorialPanel
styleButton(tutorialStoryButton, "secondary")

tutorialButton.Activated:Connect(function()
	tutorialComplete = true
	tutorialManuallyOpened = false
	updateTutorialVisibility()
	playSound("Button")
	saveSettings()
end)

tutorialStoryButton.Activated:Connect(function()
	tutorialComplete = true
	tutorialManuallyOpened = false
	updateTutorialVisibility()
	playSound("Button")
	saveSettings()
	day43Ui.fireQueueRequest("Story")
end)

customizeButton = Instance.new("TextButton")
customizeButton.AnchorPoint = Vector2.new(1, 0)
customizeButton.Position = UDim2.new(1, -22, 0, 16)
customizeButton.Size = UDim2.fromOffset(142, 34)
customizeButton.BackgroundColor3 = Color3.fromRGB(31, 38, 52)
customizeButton.BorderSizePixel = 0
customizeButton.Font = Enum.Font.GothamBold
customizeButton.Text = "Theme: Ocean"
customizeButton.TextColor3 = Color3.fromRGB(245, 247, 251)
customizeButton.TextSize = 14
customizeButton.Parent = workspaceHeader
ArcadeUI.Button(customizeButton, Color3.fromRGB(37, 107, 188))
UITheme.attachButtonFeedback(customizeButton, isUiReducedMotion)
markInteractive(customizeButton)

resetLayoutButton = Instance.new("TextButton")
resetLayoutButton.AnchorPoint = Vector2.new(1, 0)
resetLayoutButton.Position = UDim2.new(1, -174, 0, 18)
resetLayoutButton.Size = UDim2.fromOffset(126, 38)
resetLayoutButton.BackgroundColor3 = Color3.fromRGB(42, 57, 96)
resetLayoutButton.BorderSizePixel = 0
resetLayoutButton.Font = Enum.Font.GothamBold
resetLayoutButton.Text = "Reset Layout"
resetLayoutButton.TextColor3 = Color3.fromRGB(245, 247, 251)
resetLayoutButton.TextSize = 13
resetLayoutButton.Parent = workspaceHeader
ArcadeUI.Button(resetLayoutButton, Color3.fromRGB(32, 55, 91))
UITheme.attachButtonFeedback(resetLayoutButton, isUiReducedMotion)
markInteractive(resetLayoutButton)

closeWorkspaceButton = Instance.new("TextButton")
closeWorkspaceButton.Name = "WorkspaceCloseButton"
closeWorkspaceButton.AnchorPoint = Vector2.new(1, 0)
closeWorkspaceButton.Position = UDim2.new(1, -26, 0, 18)
closeWorkspaceButton.Size = UDim2.fromOffset(44, 38)
closeWorkspaceButton.BackgroundColor3 = Color3.fromRGB(255, 86, 107)
closeWorkspaceButton.BorderSizePixel = 0
closeWorkspaceButton.Font = Enum.Font.GothamBlack
closeWorkspaceButton.Text = "X"
closeWorkspaceButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeWorkspaceButton.TextSize = 20
closeWorkspaceButton.Parent = workspaceHeader
ArcadeUI.Button(closeWorkspaceButton, Color3.fromRGB(255, 86, 107))
UITheme.attachButtonFeedback(closeWorkspaceButton, isUiReducedMotion)
markInteractive(closeWorkspaceButton)

closeWorkspaceButton.Activated:Connect(function()
	playSound("Button")
	day43Ui.fireQueueRequest("LeaveBattle")
end)

settingsButton = makeTopControl("WorkspaceSettingsButton", "SET", Color3.fromRGB(24, 49, 86))
settingsButton.TextSize = 13
settingsButton.Activated:Connect(function()
	playSound("Button")
	if hudController and hudController.callbacks and hudController.callbacks.settings then
		hudController.callbacks.settings()
	end
end)

helpButton = makeTopControl("WorkspaceHelpButton", "?", Color3.fromRGB(24, 49, 86))
helpButton.TextSize = 22
helpButton.Activated:Connect(function()
	tutorialManuallyOpened = true
	updateTutorialVisibility()
	playSound("Button")
end)

local function activeStageVisual()
	local stageState = currentState and currentState.stage
	local hasSoloStage = currentState
		and currentState.mode == "Solo"
		and typeof(stageState) == "table"
	return StageVisuals.presetForStage(hasSoloStage and stageState.currentStage or 1), hasSoloStage
end

local function applyStrokeColor(parent, color, transparency)
	if not parent then
		return
	end

	for _, child in parent:GetChildren() do
		if child:IsA("UIStroke") then
			child.Color = color
			if transparency then
				child.Transparency = transparency
			end
		end
	end
end

local function styleSoloPanel(frame, preset, muted)
	if not frame then
		return
	end

	frame.BackgroundColor3 = muted and preset.panelMuted or preset.panel
	frame.BackgroundTransparency = muted and 0.03 or 0
	applyStrokeColor(frame, preset.panelBorder, 0.08)
end

-- Stage visuals own the active Solo world: background, panels, board, pieces, tray,
-- leaderboard, and stage-transition colors. Cosmetic themes remain player-owned
-- preferences outside Solo or where they do not conflict with the active stage.
local function applyStagePalette()
	local stageState = currentState and currentState.stage
	local hasSoloStage = currentState
		and currentState.mode == "Solo"
		and typeof(stageState) == "table"
	local preset = StageVisuals.presetForStage(hasSoloStage and stageState.currentStage or 1)
	local boardSkin = Config.BoardSkins[boardSkinIndex] or Config.BoardSkins[1]
	local theme = themePresets[themeIndex]
	local emptyColor = if hasSoloStage then preset.boardEmpty else boardSkin.empty or theme.board
	local outlineColor = if hasSoloStage
		then preset.boardOutline
		else boardSkin.border or Color3.fromRGB(45, 55, 72)
	local rimColor = if hasSoloStage then preset.boardRim else ArcadeUI.Color.rimBright

	customization.boardEmptyColor = emptyColor
	if hasSoloStage then
		root.BackgroundColor3 = preset.background
		workspaceHeader.BackgroundColor3 = preset.panel
		workspaceContent.BackgroundTransparency = 1
		styleSoloPanel(stageUi.scoreCard, preset, false)
		styleSoloPanel(comboBadgeLabel, preset, true)
		styleSoloPanel(coinStatLabel, preset, false)
		styleSoloPanel(rankStatLabel, preset, false)
		styleSoloPanel(stageUi.side, preset, false)
		styleSoloPanel(leaderboardLabel, preset, false)
		stageUi.scoreHeading.TextColor3 = preset.panelText
		scoreLabel.TextColor3 = preset.score
		bestScoreLabel.TextColor3 = preset.stage
		comboBadgeLabel.TextColor3 = preset.combo
		coinStatLabel.TextColor3 = preset.accent
		rankStatLabel.TextColor3 = preset.accent
		statusLabel.TextColor3 = preset.panelText
		progressionLabel.TextColor3 = preset.panelSubtleText
		matchInfoLabel.TextColor3 = preset.panelSubtleText
		timerLabel.TextColor3 = preset.panelSubtleText
		stageUi.titleButton.TextColor3 = preset.panelText
		customizeButton.BackgroundColor3 = preset.leaderboard
		coinChipLabel.BackgroundColor3 = preset.panelMuted
		coinChipLabel.TextColor3 = preset.panelText
		returnHubButton.BackgroundColor3 = preset.leaderboard
		playAgainButton.BackgroundColor3 = preset.stage
		rotatePieceButton.BackgroundColor3 = preset.leaderboard
		rerollPieceButton.BackgroundColor3 = preset.combo
		for index, decor in stageUi.decorations do
			decor.BackgroundColor3 = index % 2 == 0 and preset.backgroundAccent or preset.wash
		end
	end

	if boardFrame then
		boardFrame.BackgroundColor3 = hasSoloStage and preset.boardFrame
			or Color3.fromRGB(8, 23, 45)
		applyStrokeColor(boardFrame, rimColor, 0.04)
	end

	if stageUi.card then
		stageUi.card.Visible = hasSoloStage
		stageUi.card.BackgroundColor3 = preset.panel
		applyStrokeColor(stageUi.card, preset.stage, 0)
	end
	if stageUi.fill then
		stageUi.fill.BackgroundColor3 = preset.accent
	end
	if stageUi.track then
		stageUi.track.BackgroundColor3 = preset.panelMuted
	end
	if stageUi.title then
		stageUi.title.TextColor3 = preset.stage
	end
	if stageUi.progress then
		stageUi.progress.TextColor3 = preset.panelText
	end

	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			local cell = cells[y] and cells[y][x]
			if not cell then
				continue
			end

			cell.BorderSizePixel = 1
			cell.BorderColor3 = outlineColor
			local stroke = cell:FindFirstChildOfClass("UIStroke")
			if stroke and (not currentState or currentState.board[y][x] == false) then
				stroke.Color = outlineColor
				stroke.Transparency = hasSoloStage and 0.12 or 0.2
			end
			if not currentState or currentState.board[y][x] == false then
				cell.BackgroundColor3 = emptyColor
			end
		end
	end

	if hasSoloStage and renderBoard then
		renderBoard(true)
	end
end

local function playStageTransition(stage)
	local preset = StageVisuals.presetForStage(stage)
	local transition = StageVisuals.transitionForStage(stage, reducedMotion)
	stageUi.noticeToken = (stageUi.noticeToken or 0) + 1
	local token = stageUi.noticeToken

	if stageUi.wash then
		stageUi.wash.BackgroundColor3 = transition.wash
		stageUi.wash.BackgroundTransparency = reducedMotion and 0.78 or 0.45
		if not reducedMotion then
			TweenService:Create(stageUi.wash, TweenInfo.new(transition.duration), {
				BackgroundTransparency = 1,
			}):Play()
		else
			task.delay(transition.duration, function()
				if stageUi.wash then
					stageUi.wash.BackgroundTransparency = 1
				end
			end)
		end
	end

	if stageUi.notice then
		stageUi.notice.Text = `STAGE {stage}`
		stageUi.notice.TextColor3 = preset.notice
		stageUi.notice.Visible = true
		stageUi.notice.TextTransparency = 0
		if not reducedMotion then
			stageUi.notice.Size = UDim2.fromOffset(340, 96)
			stageUi.notice.Position = UDim2.new(0.5, -170, 0, WINDOW_LAYOUT.top + 78)
			TweenService:Create(stageUi.notice, TweenInfo.new(transition.duration), {
				Position = UDim2.new(0.5, -170, 0, WINDOW_LAYOUT.top + 58),
			}):Play()
		end
		task.delay(transition.messageDuration, function()
			if stageUi.noticeToken == token and stageUi.notice then
				stageUi.notice.Visible = false
			end
		end)
	end
end

local function renderStageDisplay()
	local stageState = currentState and currentState.stage
	local hasSoloStage = currentState
		and currentState.mode == "Solo"
		and typeof(stageState) == "table"
	if stageUi.card then
		stageUi.card.Visible = hasSoloStage
	end
	if not hasSoloStage then
		stageUi.lastStage = nil
		return
	end

	local cleanStage = StageProgression.publicState(stageState)
	local progress = math.clamp(cleanStage.stageProgress, 0, cleanStage.stageProgressRequired)
	local ratio = progress / math.max(1, cleanStage.stageProgressRequired)
	local preset = StageVisuals.presetForStage(cleanStage.currentStage)
	-- Stage-advance visuals (wash tween, title flash, banner) are owned solely
	-- by the explicit "StageUp" effect handler, not derived here from a diff,
	-- so they only fire once per advance instead of twice.
	stageUi.lastStage = cleanStage.currentStage
	stageUi.title.Text = `STAGE {cleanStage.currentStage}`
	stageUi.progress.Text = `{progress} / {cleanStage.stageProgressRequired}`
	stageUi.fill.Size = UDim2.fromScale(ratio, 1)
	stageUi.fill.BackgroundColor3 = preset.accent
	applyStagePalette()
end

local function pulseStageUpDisplay()
	if not stageUi.card then
		return
	end

	if reducedMotion then
		stageUi.card.BackgroundTransparency = 0
		task.delay(0.35, function()
			if stageUi.card then
				stageUi.card.BackgroundTransparency = 0.04
			end
		end)
		return
	end

	local scale = stageUi.card:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = stageUi.card
	TweenService:Create(scale, QUICK_TWEEN, { Scale = 1.08 }):Play()
	task.delay(0.16, function()
		if scale.Parent then
			TweenService:Create(scale, SOFT_TWEEN, { Scale = 1 }):Play()
		end
	end)
end

applyBoardSkin = function()
	local theme = themePresets[themeIndex]
	local boardSkin = Config.BoardSkins[boardSkinIndex] or Config.BoardSkins[1]
	local emptyColor = boardSkin.empty or theme.board
	local borderColor = boardSkin.border or Color3.fromRGB(45, 55, 72)

	customization.boardEmptyColor = emptyColor

	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			local cell = cells[y] and cells[y][x]
			if not cell then
				continue
			end

			cell.BorderSizePixel = 1
			cell.BorderColor3 = borderColor
			if not currentState or currentState.board[y][x] == false then
				cell.BackgroundColor3 = emptyColor
			end
		end
	end

	applyStagePalette()
end

local function applyTheme()
	local theme = themePresets[themeIndex]
	customization.panelColor = theme.panel
	customization.accentColor = theme.accent
	if not (currentState and currentState.mode == "Solo") then
		root.BackgroundColor3 = theme.panel
		customizeButton.BackgroundColor3 = theme.accent
	end
	if homePanelController then
		homePanelController:ApplyTheme(theme)
	end
	customizeButton.Text = `Theme: {theme.name}`
	applyBoardSkin()
end

customizeButton.Activated:Connect(function()
	themeIndex += 1
	if themeIndex > #themePresets then
		themeIndex = 1
	end
	applyTheme()
	playSound("Button")
	saveSettings()
end)

resetLayoutButton.Activated:Connect(function()
	playSound("Button")
	applyUiScale()
end)

stageUi.titleButton = Instance.new("TextButton")
stageUi.titleButton.Name = "WorkspaceDragHandle"
stageUi.titleButton.BackgroundTransparency = 1
stageUi.titleButton.Position = UDim2.fromOffset(24, 18)
stageUi.titleButton.Size = UDim2.fromOffset(530, 42)
stageUi.titleButton.AutoButtonColor = false
stageUi.titleButton.Font = Enum.Font.GothamBlack
stageUi.titleButton.Text = "SOLO PUZZLE"
stageUi.titleButton.TextColor3 = Color3.fromRGB(245, 247, 251)
stageUi.titleButton.TextSize = 22
stageUi.titleButton.TextXAlignment = Enum.TextXAlignment.Left
stageUi.titleButton.Parent = workspaceHeader
UITheme.text(stageUi.titleButton, "title")

for dotIndex = 1, 5 do
	local gripDot = Instance.new("Frame")
	gripDot.Name = `TitleGripDot{dotIndex}`
	gripDot.BackgroundColor3 = Color3.fromRGB(67, 123, 194)
	gripDot.BorderSizePixel = 0
	gripDot.Position = UDim2.new(0.5, -34 + (dotIndex - 1) * 17, 0, 32)
	gripDot.Size = UDim2.fromOffset(9, 9)
	gripDot.Active = false
	gripDot.Parent = workspaceHeader
	UITheme.corner(gripDot, 9)
	UITheme.stroke(gripDot, Color3.fromRGB(5, 12, 24), 1, 0.25)
end

stageUi.scoreCard = Instance.new("Frame")
stageUi.scoreCard.Name = "ScoreCard"
stageUi.scoreCard.Position = UDim2.fromOffset(22, 72)
stageUi.scoreCard.Size = UDim2.fromOffset(210, 170)
stageUi.scoreCard.Parent = leftColumn
ArcadeUI.StatCard(stageUi.scoreCard)

stageUi.scoreHeading = Instance.new("TextLabel")
stageUi.scoreHeading.BackgroundTransparency = 1
stageUi.scoreHeading.Position = UDim2.fromOffset(16, 12)
stageUi.scoreHeading.Size = UDim2.new(1, -32, 0, 26)
stageUi.scoreHeading.Font = Enum.Font.GothamBlack
stageUi.scoreHeading.Text = "SCORE"
stageUi.scoreHeading.TextColor3 = Color3.fromRGB(255, 255, 255)
stageUi.scoreHeading.TextSize = 22
stageUi.scoreHeading.TextXAlignment = Enum.TextXAlignment.Center
stageUi.scoreHeading.Parent = stageUi.scoreCard
ArcadeUI.Text(stageUi.scoreHeading)

scoreLabel = Instance.new("TextLabel")
scoreLabel.BackgroundTransparency = 1
scoreLabel.Position = UDim2.fromOffset(14, 16)
scoreLabel.Size = UDim2.new(1, -28, 0, 58)
scoreLabel.Font = Enum.Font.GothamBlack
scoreLabel.Text = "0"
scoreLabel.TextColor3 = ArcadeUI.Color.score
scoreLabel.TextSize = 50
scoreLabel.TextXAlignment = Enum.TextXAlignment.Center
scoreLabel.TextStrokeColor3 = Color3.fromRGB(42, 28, 10)
scoreLabel.TextStrokeTransparency = 0.35
scoreLabel.Parent = stageUi.scoreCard
ArcadeUI.Text(scoreLabel, "score")

local scoreDivider = Instance.new("Frame")
scoreDivider.BackgroundColor3 = ArcadeUI.Color.rim
scoreDivider.BackgroundTransparency = 0.28
scoreDivider.BorderSizePixel = 0
scoreDivider.Position = UDim2.new(0, 24, 0, 92)
scoreDivider.Size = UDim2.new(1, -48, 0, 3)
scoreDivider.Parent = stageUi.scoreCard
UITheme.corner(scoreDivider, 3)

bestScoreLabel = Instance.new("TextLabel")
bestScoreLabel.BackgroundTransparency = 1
bestScoreLabel.Position = UDim2.fromOffset(18, 82)
bestScoreLabel.Size = UDim2.new(1, -36, 0, 34)
bestScoreLabel.Font = Enum.Font.GothamBlack
bestScoreLabel.Text = "BEST 0"
bestScoreLabel.TextColor3 = ArcadeUI.Color.best
bestScoreLabel.TextSize = 20
bestScoreLabel.TextXAlignment = Enum.TextXAlignment.Center
bestScoreLabel.Parent = stageUi.scoreCard
ArcadeUI.Text(bestScoreLabel, "best")

comboBadgeLabel = Instance.new("TextLabel")
comboBadgeLabel.BackgroundTransparency = 0.08
comboBadgeLabel.BackgroundColor3 = ArcadeUI.Color.inner
comboBadgeLabel.Position = UDim2.fromOffset(22, 232)
comboBadgeLabel.Size = UDim2.fromOffset(210, 108)
comboBadgeLabel.Font = Enum.Font.GothamBlack
comboBadgeLabel.Text = statRichText("COMBO", "x1", "#FF5DC8")
comboBadgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
comboBadgeLabel.TextSize = 28
comboBadgeLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
comboBadgeLabel.TextStrokeTransparency = 0.05
comboBadgeLabel.Parent = leftColumn
ArcadeUI.StatCard(comboBadgeLabel)
ArcadeUI.Text(comboBadgeLabel, "combo")

for sparkleIndex = 1, 4 do
	local sparkle = Instance.new("Frame")
	sparkle.Name = `ComboSparkle{sparkleIndex}`
	sparkle.BackgroundColor3 = sparkleIndex % 2 == 0 and ArcadeUI.Color.gold
		or ArcadeUI.Color.rimBright
	sparkle.BorderSizePixel = 0
	sparkle.Position = UDim2.fromOffset(26 + sparkleIndex * 36, sparkleIndex % 2 == 0 and 24 or 76)
	sparkle.Size = UDim2.fromOffset(7, 7)
	sparkle.BackgroundTransparency = 1
	sparkle.Active = false
	sparkle.Parent = comboBadgeLabel
	UITheme.corner(sparkle, 7)
end

coinStatLabel = Instance.new("TextLabel")
coinStatLabel.BackgroundTransparency = 0.04
coinStatLabel.BackgroundColor3 = Color3.fromRGB(11, 27, 51)
coinStatLabel.Position = UDim2.fromOffset(22, 356)
coinStatLabel.Size = UDim2.fromOffset(210, 76)
coinStatLabel.Font = Enum.Font.GothamBlack
coinStatLabel.Text = statRichText("COINS", "0", "#FFECA0")
coinStatLabel.TextColor3 = Color3.fromRGB(255, 236, 160)
coinStatLabel.TextSize = 26
coinStatLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
coinStatLabel.TextStrokeTransparency = 0.08
coinStatLabel.Parent = leftColumn
ArcadeUI.StatCard(coinStatLabel)
ArcadeUI.Text(coinStatLabel, "gold")

rankStatLabel = Instance.new("TextLabel")
rankStatLabel.BackgroundTransparency = 0.04
rankStatLabel.BackgroundColor3 = Color3.fromRGB(11, 27, 51)
rankStatLabel.Position = UDim2.fromOffset(22, 482)
rankStatLabel.Size = UDim2.fromOffset(210, 76)
rankStatLabel.Font = Enum.Font.GothamBlack
rankStatLabel.Text = statRichText("TROPHY", "RANK --", "#FFD247")
rankStatLabel.TextColor3 = ArcadeUI.Color.gold
rankStatLabel.TextSize = 22
rankStatLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
rankStatLabel.TextStrokeTransparency = 0.08
rankStatLabel.Parent = leftColumn
ArcadeUI.StatCard(rankStatLabel)
ArcadeUI.Text(rankStatLabel, "gold")
enforceStatTextContrast()

coinChipLabel = Instance.new("TextLabel")
coinChipLabel.AnchorPoint = Vector2.new(1, 0)
coinChipLabel.BackgroundTransparency = 0.02
coinChipLabel.BackgroundColor3 = Color3.fromRGB(11, 27, 51)
coinChipLabel.Position = UDim2.new(1, -170, 0, 20)
coinChipLabel.Size = UDim2.fromOffset(170, 50)
coinChipLabel.Font = Enum.Font.GothamBlack
coinChipLabel.Text = "0 Coins  +"
coinChipLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
coinChipLabel.TextSize = 20
coinChipLabel.Parent = workspaceHeader
ArcadeUI.Button(coinChipLabel, Color3.fromRGB(13, 37, 69))

timerLabel = Instance.new("TextLabel")
timerLabel.AnchorPoint = Vector2.new(1, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.Position = UDim2.new(1, -22, 0, 56)
timerLabel.Size = UDim2.fromOffset(180, 26)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.Text = "Time: --"
timerLabel.TextColor3 = Color3.fromRGB(193, 201, 215)
timerLabel.TextSize = 18
timerLabel.TextXAlignment = Enum.TextXAlignment.Right
timerLabel.Parent = workspaceHeader
UITheme.text(timerLabel, "muted")

progressionLabel = Instance.new("TextLabel")
progressionLabel.BackgroundTransparency = 1
progressionLabel.Position = UDim2.fromOffset(24, 42)
progressionLabel.Size = UDim2.fromOffset(420, 20)
progressionLabel.Font = Enum.Font.Gotham
progressionLabel.Text = "Level 1 | 0 coins | 0 XP"
progressionLabel.TextColor3 = Color3.fromRGB(153, 163, 179)
progressionLabel.TextSize = 14
progressionLabel.TextXAlignment = Enum.TextXAlignment.Left
progressionLabel.Parent = workspaceHeader
UITheme.text(progressionLabel, "soft")

stageUi.card = Instance.new("Frame")
stageUi.card.Name = "StageProgressCard"
stageUi.card.BackgroundColor3 = Color3.fromRGB(9, 26, 51)
stageUi.card.BackgroundTransparency = 0.04
stageUi.card.BorderSizePixel = 0
stageUi.card.Parent = workspaceHeader
ArcadeUI.Panel(stageUi.card, {
	radius = 14,
	rimColor = Color3.fromRGB(110, 244, 255),
	strokeThickness = 2,
})

stageUi.title = Instance.new("TextLabel")
stageUi.title.BackgroundTransparency = 1
stageUi.title.Position = UDim2.fromOffset(10, 4)
stageUi.title.Size = UDim2.new(1, -20, 0, 15)
stageUi.title.Font = Enum.Font.GothamBlack
stageUi.title.Text = "STAGE 1"
stageUi.title.TextColor3 = Color3.fromRGB(255, 255, 255)
stageUi.title.TextSize = 12
stageUi.title.TextXAlignment = Enum.TextXAlignment.Left
stageUi.title.Parent = stageUi.card

stageUi.progress = Instance.new("TextLabel")
stageUi.progress.BackgroundTransparency = 1
stageUi.progress.Position = UDim2.fromOffset(10, 18)
stageUi.progress.Size = UDim2.new(1, -20, 0, 14)
stageUi.progress.Font = Enum.Font.GothamBold
stageUi.progress.Text = "0 / 28"
stageUi.progress.TextColor3 = Color3.fromRGB(202, 213, 230)
stageUi.progress.TextSize = 10
stageUi.progress.TextXAlignment = Enum.TextXAlignment.Left
stageUi.progress.Parent = stageUi.card

stageUi.track = Instance.new("Frame")
stageUi.track.Name = "StageProgressTrack"
stageUi.track.BackgroundColor3 = Color3.fromRGB(5, 15, 31)
stageUi.track.BackgroundTransparency = 0.05
stageUi.track.BorderSizePixel = 0
stageUi.track.Position = UDim2.new(0, 10, 1, -9)
stageUi.track.Size = UDim2.new(1, -20, 0, 4)
stageUi.track.Parent = stageUi.card
UITheme.corner(stageUi.track, 4)

stageUi.fill = Instance.new("Frame")
stageUi.fill.Name = "StageProgressFill"
stageUi.fill.BackgroundColor3 = Color3.fromRGB(110, 244, 255)
stageUi.fill.BorderSizePixel = 0
stageUi.fill.Size = UDim2.fromScale(0, 1)
stageUi.fill.Parent = stageUi.track
UITheme.corner(stageUi.fill, 4)

matchInfoLabel = Instance.new("TextLabel")
matchInfoLabel.AnchorPoint = Vector2.new(1, 0)
matchInfoLabel.BackgroundTransparency = 1
matchInfoLabel.Position = UDim2.new(1, -22, 0, 80)
matchInfoLabel.Size = UDim2.fromOffset(180, 20)
matchInfoLabel.Font = Enum.Font.Gotham
matchInfoLabel.Text = "Beat your best score"
matchInfoLabel.TextColor3 = Color3.fromRGB(153, 163, 179)
matchInfoLabel.TextSize = 14
matchInfoLabel.TextXAlignment = Enum.TextXAlignment.Right
matchInfoLabel.Parent = workspaceHeader
UITheme.text(matchInfoLabel, "soft")

local function getSelectedShape()
	if not currentState or not selectedSlot then
		return nil
	end

	return currentState.hand[selectedSlot]
end

local function selectFirstAvailablePiece()
	if not currentState then
		selectedSlot = nil
		return
	end

	if selectedSlot and currentState.hand[selectedSlot] ~= nil then
		return
	end

	selectedSlot = nil
	for slot, shape in currentState.hand do
		if shape ~= nil then
			selectedSlot = slot
			return
		end
	end
end

boardFrame = Instance.new("Frame")
boardFrame:SetAttribute("BlocksWorkspaceDrag", true)
boardFrame.Position = UDim2.fromOffset(24, 104)
boardFrame.Size = UDim2.fromOffset(304, 304)
boardFrame.BackgroundColor3 = Color3.fromRGB(8, 23, 45)
boardFrame.BackgroundTransparency = 0
boardFrame.ClipsDescendants = true
boardFrame.Parent = boardStage
ArcadeUI.Panel(boardFrame, {
	radius = 28,
	rimColor = ArcadeUI.Color.rimBright,
	strokeThickness = 6,
})
-- Assigned onto day43Ui (not a new top-level local) because this script is a
-- single top-level chunk already close to Luau's 200-local register limit.
day43Ui.attemptPlacement = function(slot, boardX, boardY)
	local UIControlRules = require(GameShared.UIControlRules)
	if not currentState or not slot then
		return false
	end

	local now = os.clock()
	if
		not UIControlRules.canFireServerAction(
			day43Ui.lastPlaceActionAt,
			now,
			day43Ui.placeActionCooldownSeconds
		)
	then
		return false
	end

	local shape = currentState.hand[slot]
	if
		shape
		and typeof(boardX) == "number"
		and typeof(boardY) == "number"
		and Grid.canPlace(currentState.board, shape, boardX, boardY)
	then
		day43Ui.lastPlaceActionAt = now
		playSound("Place")
		placeEvent:FireServer(slot, boardX, boardY)
		return true
	elseif shape then
		statusLabel.Text = "That spot is blocked"
		playSound("Blocked")
		showBanner("That spot is blocked", Color3.fromRGB(255, 86, 107))
	end

	return false
end

boardGridContainer = Instance.new("Frame")
boardGridContainer.Name = "BoardGridContainer"
boardGridContainer.BackgroundTransparency = 1
boardGridContainer.BorderSizePixel = 0
boardGridContainer.ClipsDescendants = true
boardGridContainer.Parent = boardFrame

boardGhostLayer = Instance.new("Frame")
boardGhostLayer.Name = "BoardGhostLayer"
boardGhostLayer.BackgroundTransparency = 1
boardGhostLayer.BorderSizePixel = 0
boardGhostLayer.ClipsDescendants = true
boardGhostLayer.Position = UDim2.fromScale(0, 0)
boardGhostLayer.Size = UDim2.fromScale(1, 1)
boardGhostLayer.ZIndex = 2
boardGhostLayer.Parent = boardFrame

local boardPadding = Instance.new("UIPadding")
boardPadding.PaddingTop = UDim.new(0, 16)
boardPadding.PaddingBottom = UDim.new(0, 16)
boardPadding.PaddingLeft = UDim.new(0, 16)
boardPadding.PaddingRight = UDim.new(0, 16)
boardPadding.Parent = boardGridContainer

local boardLayout = Instance.new("UIGridLayout")
boardLayout.CellSize = UDim2.fromOffset(35, 35)
boardLayout.CellPadding = UDim2.fromOffset(3, 3)
boardLayout.SortOrder = Enum.SortOrder.LayoutOrder
boardLayout.Parent = boardGridContainer

for y = 1, Config.BoardSize do
	for x = 1, Config.BoardSize do
		local button = Instance.new("TextButton")
		button.Name = `{x}_{y}`
		button:SetAttribute("BoardX", x)
		button:SetAttribute("BoardY", y)
		button:SetAttribute("IsBoardCell", true)
		button.LayoutOrder = (y - 1) * Config.BoardSize + x
		button.BackgroundColor3 = Config.Colors.Empty
		button.BorderSizePixel = 0
		button.Text = ""
		button.AutoButtonColor = false
		button.Parent = boardGridContainer
		markInteractive(button)
		ArcadeUI.BoardCell(button)

		local scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = button

		cells[y] = cells[y] or {}
		cells[y][x] = button
		cellScales[y] = cellScales[y] or {}
		cellScales[y][x] = scale

		button.Activated:Connect(function()
			local boardX = button:GetAttribute("BoardX")
			local boardY = button:GetAttribute("BoardY")
			if currentState and selectedSlot then
				day43Ui.attemptPlacement(selectedSlot, boardX, boardY)
			end
		end)

		button.MouseEnter:Connect(function()
			hoverX = button:GetAttribute("BoardX")
			hoverY = button:GetAttribute("BoardY")
			if currentState then
				renderGhostPreview()
			end
		end)

		button.MouseLeave:Connect(function()
			if
				hoverX == button:GetAttribute("BoardX")
				and hoverY == button:GetAttribute("BoardY")
			then
				hoverX = nil
				hoverY = nil
				if currentState then
					renderGhostPreview()
				end
			end
		end)
	end
end

local function validateBoardGridHierarchy()
	local directGuiObjects = 0
	local seenCoordinates = {}

	for _, child in boardGridContainer:GetChildren() do
		if child:IsA("GuiObject") then
			directGuiObjects += 1
			local isCell = child:IsA("TextButton") and child:GetAttribute("IsBoardCell") == true
			local x = child:GetAttribute("BoardX")
			local y = child:GetAttribute("BoardY")
			local coordinateKey = `{tostring(x)}:{tostring(y)}`

			if
				not isCell
				or typeof(x) ~= "number"
				or typeof(y) ~= "number"
				or x < 1
				or x > Config.BoardSize
				or y < 1
				or y > Config.BoardSize
				or seenCoordinates[coordinateKey]
			then
				warn(
					`Invalid board grid child: {child.Name} ({child.ClassName}) at {coordinateKey}`
				)
			end

			seenCoordinates[coordinateKey] = true
		end
	end

	if directGuiObjects ~= Config.BoardSize * Config.BoardSize then
		warn(
			`BoardGridContainer expected {Config.BoardSize * Config.BoardSize} direct GuiObjects, found {directGuiObjects}`
		)
	end
end

validateBoardGridHierarchy()

local function visibleBoardCellCount()
	local count = 0

	for _, child in boardGridContainer:GetChildren() do
		if child:IsA("GuiButton") and child.Visible then
			count += 1
		end
	end

	return count
end

developerPanelController = DeveloperPanel.new({
	parent = gui,
	remote = devCommandFunction,
	showMessage = showBanner,
	isReducedMotion = isUiReducedMotion,
	getVisibleBoardCellCount = visibleBoardCellCount,
})

stageUi.side = Instance.new("Frame")
stageUi.side.Position = UDim2.fromOffset(360, 104)
stageUi.side.Size = UDim2.fromOffset(256, 304)
stageUi.side.BackgroundColor3 = Color3.fromRGB(8, 23, 45)
stageUi.side.BackgroundTransparency = 0.02
stageUi.side.Parent = trayStage
ArcadeUI.Panel(stageUi.side, {
	radius = 26,
	rimColor = ArcadeUI.Color.rimBright,
	strokeThickness = 5,
})

statusLabel = Instance.new("TextLabel")
statusLabel.BackgroundTransparency = 1
statusLabel.Size = UDim2.fromOffset(296, 28)
statusLabel.Font = Enum.Font.GothamBold
statusLabel.Text = "Choose a piece"
statusLabel.TextColor3 = Color3.fromRGB(245, 247, 251)
statusLabel.TextSize = 20
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = stageUi.side
UITheme.text(statusLabel, "heading")

local function updateStatusText()
	if currentState and currentState.message then
		statusLabel.Text = currentState.message
	elseif currentState and not currentState.alive then
		statusLabel.Text = "Out of moves"
	elseif getSelectedShape() then
		statusLabel.Text = `Selected piece {selectedSlot}`
	else
		statusLabel.Text = "Choose a piece"
	end
end

-- Assigned onto day43Ui (not a new top-level local) because this script is a
-- single top-level chunk already close to Luau's 200-local register limit.
day43Ui.drag = {
	MOVE_THRESHOLD = 6,
	state = {
		active = false,
		dragging = false,
		slot = nil,
		shape = nil,
		startPosition = nil,
		icon = nil,
	},
}

function day43Ui.drag.boardCellFromScreenPosition(screenX, screenY)
	local innerPadding = WINDOW_LAYOUT.boardPadding
	local cellGap = WINDOW_LAYOUT.boardGap
	local cellPixels = WINDOW_LAYOUT.boardCell
	local step = cellPixels + cellGap

	local localX = screenX - boardFrame.AbsolutePosition.X
	local localY = screenY - boardFrame.AbsolutePosition.Y
	local boardX = math.floor((localX - innerPadding) / step) + 1
	local boardY = math.floor((localY - innerPadding) / step) + 1

	return boardX, boardY
end

function day43Ui.drag.destroyIcon()
	if day43Ui.drag.state.icon then
		day43Ui.drag.state.icon:Destroy()
		day43Ui.drag.state.icon = nil
	end
end

function day43Ui.drag.createIcon(shape)
	local preset, hasSoloStage = activeStageVisual()
	local cellPixels = WINDOW_LAYOUT.boardCell
	local minX, maxX, minY, maxY = math.huge, -math.huge, math.huge, -math.huge
	for _, cell in shape.cells do
		minX = math.min(minX, cell.X)
		maxX = math.max(maxX, cell.X)
		minY = math.min(minY, cell.Y)
		maxY = math.max(maxY, cell.Y)
	end

	local icon = Instance.new("Frame")
	icon.Name = "DragPieceIcon"
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromOffset((maxX - minX + 1) * cellPixels, (maxY - minY + 1) * cellPixels)
	icon.ZIndex = 50
	icon.Active = false
	icon.Parent = root
	ArcadeUI.RenderShapePreview(icon, shape, {
		blockColors = hasSoloStage and preset.blockPalette or nil,
	})

	return icon
end

function day43Ui.drag.updateIconPosition(screenX, screenY)
	if not day43Ui.drag.state.icon then
		return
	end
	day43Ui.drag.state.icon.Position = UDim2.fromOffset(
		screenX - day43Ui.drag.state.icon.AbsoluteSize.X / 2,
		screenY - day43Ui.drag.state.icon.AbsoluteSize.Y / 2
	)
end

function day43Ui.drag.finish(screenX, screenY)
	if day43Ui.drag.state.dragging then
		local boardX, boardY = day43Ui.drag.boardCellFromScreenPosition(screenX, screenY)
		local isOverBoard = boardX >= 1
			and boardX <= Config.BoardSize
			and boardY >= 1
			and boardY <= Config.BoardSize
		if isOverBoard then
			day43Ui.attemptPlacement(day43Ui.drag.state.slot, boardX, boardY)
		end
		local trayPreview = handPreviews[day43Ui.drag.state.slot]
		if trayPreview then
			trayPreview.Visible = true
		end
	end

	day43Ui.drag.destroyIcon()
	day43Ui.drag.state.active = false
	day43Ui.drag.state.dragging = false
	day43Ui.drag.state.slot = nil
	day43Ui.drag.state.shape = nil
	day43Ui.drag.state.startPosition = nil
end

for slot = 1, Config.InventorySize do
	local button = Instance.new("TextButton")
	button.Name = `HandSlot{slot}`
	button.Position = UDim2.fromOffset(0, 38 + (slot - 1) * 66)
	button.Size = UDim2.fromOffset(256, 58)
	button.BackgroundColor3 = Color3.fromRGB(31, 38, 52)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(245, 247, 251)
	button.TextSize = 18
	button.Text = ""
	button.Parent = stageUi.side
	ArcadeUI.PieceSlot(button)
	UITheme.attachButtonFeedback(button, isUiReducedMotion)
	markInteractive(button)
	local buttonStroke = button:FindFirstChildOfClass("UIStroke")
	if buttonStroke then
		buttonStroke.Thickness = 3
		buttonStroke.Color = Color3.fromRGB(34, 173, 244)
		buttonStroke.Transparency = 0.1
	end
	handButtons[slot] = button

	local preview = Instance.new("Frame")
	preview.Name = "Preview"
	preview.Position = UDim2.fromOffset(12, 8)
	preview.Size = UDim2.fromOffset(44, 44)
	preview.BackgroundTransparency = 1
	preview.Parent = button
	handPreviews[slot] = preview

	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(70, 0)
	label.Size = UDim2.fromOffset(174, 58)
	label.Font = Enum.Font.GothamBold
	label.Text = `Piece {slot}`
	label.TextColor3 = Color3.fromRGB(245, 247, 251)
	label.TextSize = 17
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = button
	UITheme.text(label, "heading")

	button.Activated:Connect(function()
		selectedSlot = slot
		playSound("Button")
		if pulseHandSlot then
			pulseHandSlot(slot)
		end
		updateStatusText()
		if currentState then
			renderGhostPreview()
			renderHand()
		end
	end)

	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if not currentState then
			return
		end
		local shape = currentState.hand[slot]
		if not shape then
			return
		end

		day43Ui.drag.state.active = true
		day43Ui.drag.state.dragging = false
		day43Ui.drag.state.slot = slot
		day43Ui.drag.state.shape = shape
		day43Ui.drag.state.startPosition = input.Position
	end)
end

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end
	if not day43Ui.drag.state.active or not day43Ui.drag.state.startPosition then
		return
	end

	if not day43Ui.drag.state.dragging then
		local delta = input.Position - day43Ui.drag.state.startPosition
		if delta.Magnitude < day43Ui.drag.MOVE_THRESHOLD then
			return
		end
		day43Ui.drag.state.dragging = true
		selectedSlot = day43Ui.drag.state.slot
		day43Ui.drag.state.icon = day43Ui.drag.createIcon(day43Ui.drag.state.shape)
		local trayPreview = handPreviews[day43Ui.drag.state.slot]
		if trayPreview then
			trayPreview.Visible = false
		end
	end

	day43Ui.drag.updateIconPosition(input.Position.X, input.Position.Y)

	local boardX, boardY =
		day43Ui.drag.boardCellFromScreenPosition(input.Position.X, input.Position.Y)
	if currentState and (boardX ~= hoverX or boardY ~= hoverY) then
		hoverX = boardX
		hoverY = boardY
		renderGhostPreview()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end
	if day43Ui.drag.state.active then
		day43Ui.drag.finish(input.Position.X, input.Position.Y)
	end
end)

leaderboardLabel = Instance.new("TextLabel")
leaderboardLabel.BackgroundColor3 = ArcadeUI.Color.inner
leaderboardLabel.BackgroundTransparency = 0.02
leaderboardLabel.Position = UDim2.fromOffset(0, 242)
leaderboardLabel.Size = UDim2.fromOffset(256, 56)
leaderboardLabel.Font = Enum.Font.GothamBlack
leaderboardLabel.TextColor3 = Color3.fromRGB(245, 247, 251)
leaderboardLabel.TextSize = 16
leaderboardLabel.TextXAlignment = Enum.TextXAlignment.Left
leaderboardLabel.TextYAlignment = Enum.TextYAlignment.Top
leaderboardLabel.Parent = rightColumn
markInteractive(leaderboardLabel)
ArcadeUI.Panel(leaderboardLabel, {
	radius = 24,
	rimColor = ArcadeUI.Color.rim,
	strokeThickness = 4,
})

local leaderboardHeading = Instance.new("TextLabel")
leaderboardHeading.Name = "Heading"
leaderboardHeading.BackgroundTransparency = 1
leaderboardHeading.Position = UDim2.fromOffset(48, 16)
leaderboardHeading.Size = UDim2.new(1, -64, 0, 32)
leaderboardHeading.Font = Enum.Font.GothamBlack
leaderboardHeading.Text = "SERVER TOP"
leaderboardHeading.TextColor3 = Color3.fromRGB(255, 255, 255)
leaderboardHeading.TextSize = 24
leaderboardHeading.TextXAlignment = Enum.TextXAlignment.Left
leaderboardHeading.Parent = leaderboardLabel
ArcadeUI.Text(leaderboardHeading)

for barIndex = 1, 3 do
	local signalBar = Instance.new("Frame")
	signalBar.Name = `SignalBar{barIndex}`
	signalBar.BackgroundColor3 = ArcadeUI.Color.best
	signalBar.BorderSizePixel = 0
	signalBar.Position = UDim2.fromOffset(22 + (barIndex - 1) * 9, 34 - barIndex * 5)
	signalBar.Size = UDim2.fromOffset(6, 8 + barIndex * 5)
	signalBar.Active = false
	signalBar.Parent = leaderboardLabel
	UITheme.corner(signalBar, 3)
end

for rowIndex = 1, 7 do
	local row = ArcadeUI.LeaderboardRow(leaderboardLabel, rowIndex)
	row.Position = UDim2.fromOffset(18, 58 + (rowIndex - 1) * 39)

	local rank = Instance.new("TextLabel")
	rank.Name = "Rank"
	rank.BackgroundTransparency = 1
	rank.Position = UDim2.fromOffset(8, 0)
	rank.Size = UDim2.fromOffset(38, 38)
	rank.Font = Enum.Font.GothamBlack
	rank.Text = tostring(rowIndex)
	rank.TextSize = 20
	rank.TextXAlignment = Enum.TextXAlignment.Center
	rank.Parent = row
	ArcadeUI.Text(rank, rowIndex == 1 and "gold" or rowIndex == 2 and "muted" or "best")

	local avatar = Instance.new("Frame")
	avatar.Name = "Avatar"
	avatar.BackgroundColor3 = Color3.fromRGB(32, 73, 118)
	avatar.BorderSizePixel = 0
	avatar.Position = UDim2.fromOffset(48, 5)
	avatar.Size = UDim2.fromOffset(28, 28)
	avatar.Active = false
	avatar.Parent = row
	UITheme.corner(avatar, 8)

	local avatarImage = Instance.new("ImageLabel")
	avatarImage.Name = "AvatarImage"
	avatarImage.BackgroundTransparency = 1
	avatarImage.Position = UDim2.fromOffset(2, 2)
	avatarImage.Size = UDim2.new(1, -4, 1, -4)
	avatarImage.Image = ""
	avatarImage.Visible = false
	avatarImage.Active = false
	avatarImage.Parent = avatar
	UITheme.corner(avatarImage, 7)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(84, 0)
	nameLabel.Size = UDim2.fromOffset(130, 38)
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.Text = "--"
	nameLabel.TextSize = 14
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
	nameLabel.Parent = row
	ArcadeUI.Text(nameLabel)

	local score = Instance.new("TextLabel")
	score.Name = "Score"
	score.BackgroundTransparency = 1
	score.Position = UDim2.fromOffset(206, 0)
	score.Size = UDim2.fromOffset(86, 38)
	score.Font = Enum.Font.GothamBlack
	score.Text = "--"
	score.TextSize = 15
	score.TextXAlignment = Enum.TextXAlignment.Right
	score.Parent = row
	ArcadeUI.Text(score, rowIndex <= 3 and "gold" or "best")

	leaderboardRows[rowIndex] = row
end

returnHubButton = Instance.new("TextButton")
returnHubButton.Name = "ReturnHubButton"
returnHubButton.Position = UDim2.fromOffset(360, 390)
returnHubButton.Size = UDim2.fromOffset(124, 32)
returnHubButton.BackgroundColor3 = Color3.fromRGB(42, 57, 96)
returnHubButton.BorderSizePixel = 0
returnHubButton.Font = Enum.Font.GothamBold
returnHubButton.Text = "Return Hub"
returnHubButton.TextColor3 = Color3.fromRGB(245, 247, 251)
returnHubButton.TextSize = 14
returnHubButton.Parent = actionsPanel
styleButton(returnHubButton, "secondary")
markInteractive(returnHubButton)

playAgainButton = Instance.new("TextButton")
playAgainButton.Name = "PlayAgainButton"
playAgainButton.Position = UDim2.fromOffset(492, 390)
playAgainButton.Size = UDim2.fromOffset(124, 32)
playAgainButton.BackgroundColor3 = Color3.fromRGB(30, 187, 255)
playAgainButton.BorderSizePixel = 0
playAgainButton.Font = Enum.Font.GothamBold
playAgainButton.Text = "Play Again"
playAgainButton.TextColor3 = Color3.fromRGB(255, 255, 255)
playAgainButton.TextSize = 14
playAgainButton.Visible = false
playAgainButton.Parent = actionsPanel
styleButton(playAgainButton, "primary")
markInteractive(playAgainButton)

rotatePieceButton = Instance.new("TextButton")
rotatePieceButton.Name = "RotatePieceButton"
rotatePieceButton.Position = UDim2.fromOffset(360, 352)
rotatePieceButton.Size = UDim2.fromOffset(124, 32)
rotatePieceButton.BackgroundColor3 = Color3.fromRGB(190, 118, 255)
rotatePieceButton.BorderSizePixel = 0
rotatePieceButton.Font = Enum.Font.GothamBold
rotatePieceButton.Text = "Rotate"
rotatePieceButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rotatePieceButton.TextSize = 14
rotatePieceButton.Visible = false
rotatePieceButton.Parent = actionsPanel
styleButton(rotatePieceButton, "primary")
markInteractive(rotatePieceButton)

rerollPieceButton = Instance.new("TextButton")
rerollPieceButton.Name = "RerollPieceButton"
rerollPieceButton.Position = UDim2.fromOffset(492, 352)
rerollPieceButton.Size = UDim2.fromOffset(124, 32)
rerollPieceButton.BackgroundColor3 = Color3.fromRGB(255, 93, 200)
rerollPieceButton.BorderSizePixel = 0
rerollPieceButton.Font = Enum.Font.GothamBold
rerollPieceButton.Text = "Reroll"
rerollPieceButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rerollPieceButton.TextSize = 14
rerollPieceButton.Visible = false
rerollPieceButton.Parent = actionsPanel
styleButton(rerollPieceButton, "primary")
markInteractive(rerollPieceButton)

resizeHandle = Instance.new("TextButton")
resizeHandle.Name = "WorkspaceResizeHandle"
resizeHandle.AnchorPoint = Vector2.new(1, 1)
resizeHandle.Position = UDim2.new(1, -18, 1, -18)
resizeHandle.Size = UDim2.fromOffset(38, 38)
resizeHandle.BackgroundColor3 = Color3.fromRGB(12, 32, 61)
resizeHandle.BorderSizePixel = 0
resizeHandle.Font = Enum.Font.GothamBlack
resizeHandle.Text = "Resize"
resizeHandle.TextColor3 = Color3.fromRGB(245, 247, 251)
resizeHandle.TextSize = 11
resizeHandle.Visible = false
resizeHandle.Active = false
resizeHandle.Selectable = false
resizeHandle.Parent = root
styleButton(resizeHandle, "secondary")
UITheme.stroke(resizeHandle, Color3.fromRGB(47, 199, 255), 3, 0.06)
markInteractive(resizeHandle)

local function clampNumber(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

clampWindowToScreen = function()
	root.Position = UDim2.fromOffset(0, 0)
	root.Size = UDim2.fromOffset(gui.AbsoluteSize.X, gui.AbsoluteSize.Y)
end

applyWindowLayout = function()
	local layout = WINDOW_LAYOUT
	local contentY = layout.top + layout.headerHeight + layout.headerGap
	local contentHeight = layout.contentHeight
	local gridSize = layout.boardSize
	local boardPaddingPixels = layout.boardPadding
	local boardCellPadding = layout.boardGap
	local cellPixels = layout.boardCell
	local boardInset = math.floor((layout.centerWidth - gridSize) / 2)

	stageUi.titleButton.Visible = true
	stageUi.titleButton.Position = UDim2.fromOffset(20, 6)
	stageUi.titleButton.Size = UDim2.fromOffset(300, 30)
	stageUi.titleButton.TextSize = 24
	progressionLabel.Visible = true

	root.Position = UDim2.fromOffset(0, 0)
	root.Size = UDim2.fromOffset(layout.width, layout.height)
	workspaceHeader.Position = UDim2.fromOffset(layout.outerPadding, layout.top)
	workspaceHeader.Size = UDim2.fromOffset(layout.contentWidth, layout.headerHeight)
	workspaceContent.Position = UDim2.fromOffset(layout.outerPadding, contentY)
	workspaceContent.Size = UDim2.fromOffset(layout.contentWidth, contentHeight)
	leftColumn.Position = UDim2.fromOffset(0, 0)
	leftColumn.Size = UDim2.fromOffset(layout.leftWidth, contentHeight)
	centerColumn.Position = UDim2.fromOffset(layout.leftWidth + layout.columnGap, 0)
	centerColumn.Size = UDim2.fromOffset(layout.centerWidth, contentHeight)
	rightColumn.Position = UDim2.fromOffset(
		layout.leftWidth + layout.columnGap + layout.centerWidth + layout.columnGap,
		0
	)
	rightColumn.Size = UDim2.fromOffset(layout.rightWidth, contentHeight)
	boardStage.Position = UDim2.fromOffset(0, 0)
	boardStage.Size = UDim2.fromOffset(layout.centerWidth, layout.boardStageHeight)
	trayStage.Position = UDim2.fromOffset(0, layout.boardStageHeight + layout.trayGap)
	trayStage.Size = UDim2.fromOffset(layout.centerWidth, layout.trayHeight)

	progressionLabel.Position = UDim2.fromOffset(20, 34)
	progressionLabel.Size = UDim2.fromOffset(math.max(260, layout.contentWidth - 820), 18)
	progressionLabel.TextSize = 12
	if stageUi.card then
		stageUi.card.Position = UDim2.fromOffset(math.floor(layout.contentWidth * 0.43), 9)
		stageUi.card.Size = UDim2.fromOffset(132, 40)
	end
	timerLabel.Visible = true
	timerLabel.AnchorPoint = Vector2.new(0, 0)
	timerLabel.Position = UDim2.fromOffset(math.floor(layout.contentWidth * 0.34), 17)
	timerLabel.Size = UDim2.fromOffset(92, 26)
	timerLabel.TextSize = 13
	timerLabel.TextXAlignment = Enum.TextXAlignment.Center
	matchInfoLabel.Visible = true
	matchInfoLabel.AnchorPoint = Vector2.new(1, 0)
	matchInfoLabel.Position = UDim2.new(1, -500, 0, 17)
	matchInfoLabel.Size = UDim2.fromOffset(162, 26)
	matchInfoLabel.TextSize = 11

	if customizeButton then
		customizeButton.Position = UDim2.new(1, -318, 0, 12)
		customizeButton.Size = UDim2.fromOffset(128, 36)
		customizeButton.TextSize = 12
	end
	if coinChipLabel then
		coinChipLabel.AnchorPoint = Vector2.new(1, 0)
		coinChipLabel.Position = UDim2.new(1, -456, 0, 12)
		coinChipLabel.Size = UDim2.fromOffset(128, 36)
		coinChipLabel.TextSize = 15
	end
	if settingsButton then
		settingsButton.Position = UDim2.new(1, -178, 0, 12)
		settingsButton.Size = UDim2.fromOffset(44, 36)
	end
	if helpButton then
		helpButton.Position = UDim2.new(1, -126, 0, 12)
		helpButton.Size = UDim2.fromOffset(44, 36)
	end
	if resetLayoutButton then
		resetLayoutButton.Position = UDim2.new(1, -230, 0, 12)
		resetLayoutButton.Size = UDim2.fromOffset(44, 36)
		resetLayoutButton.Text = "Reset"
		resetLayoutButton.TextSize = 10
		resetLayoutButton.Visible = false
	end
	if closeWorkspaceButton then
		closeWorkspaceButton.Position = UDim2.new(1, -22, 0, 12)
		closeWorkspaceButton.Size = UDim2.fromOffset(44, 36)
		closeWorkspaceButton.TextSize = 20
	end
	if resizeHandle then
		resizeHandle.Position = UDim2.new(1, -18, 1, -18)
		resizeHandle.Size = UDim2.fromOffset(50, 34)
		resizeHandle.Visible = false
		resizeHandle.Active = false
		resizeHandle.Selectable = false
	end

	stageUi.scoreCard.Position = UDim2.fromOffset(0, 0)
	stageUi.scoreCard.Size = UDim2.fromOffset(layout.leftWidth, math.floor(contentHeight * 0.23))
	scoreLabel.Position = UDim2.fromOffset(14, 18)
	scoreLabel.Size = UDim2.new(1, -28, 0, 60)
	scoreLabel.TextSize = clampNumber(math.floor(layout.leftWidth * 0.2), 34, 54)
	bestScoreLabel.Position = UDim2.fromOffset(18, math.floor(contentHeight * 0.15))
	bestScoreLabel.Size = UDim2.new(1, -36, 0, 34)
	bestScoreLabel.TextSize = clampNumber(math.floor(layout.leftWidth * 0.085), 16, 22)

	local scoreHeight = stageUi.scoreCard.Size.Y.Offset
	local statHeight = math.floor((contentHeight - scoreHeight - layout.statGap * 3) / 3)
	comboBadgeLabel.Position = UDim2.fromOffset(0, scoreHeight + layout.statGap)
	comboBadgeLabel.Size = UDim2.fromOffset(layout.leftWidth, statHeight)
	comboBadgeLabel.TextSize = clampNumber(math.floor(layout.leftWidth * 0.12), 22, 32)
	comboBadgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	comboBadgeLabel.TextTransparency = 0
	comboBadgeLabel.BackgroundTransparency = 0.02
	comboBadgeLabel.TextStrokeTransparency = 0.05
	coinStatLabel.Position =
		UDim2.fromOffset(0, scoreHeight + layout.statGap + statHeight + layout.statGap)
	coinStatLabel.Size = UDim2.fromOffset(layout.leftWidth, statHeight)
	coinStatLabel.TextSize = clampNumber(math.floor(layout.leftWidth * 0.11), 20, 28)
	coinStatLabel.TextColor3 = Color3.fromRGB(255, 236, 160)
	coinStatLabel.TextTransparency = 0
	coinStatLabel.BackgroundTransparency = 0.02
	coinStatLabel.TextStrokeTransparency = 0.08
	rankStatLabel.Position = UDim2.fromOffset(
		0,
		scoreHeight + layout.statGap + statHeight + layout.statGap + statHeight + layout.statGap
	)
	rankStatLabel.Size = UDim2.fromOffset(layout.leftWidth, statHeight)
	rankStatLabel.TextSize = clampNumber(math.floor(layout.leftWidth * 0.095), 18, 24)
	rankStatLabel.TextColor3 = ArcadeUI.Color.gold
	rankStatLabel.TextTransparency = 0
	rankStatLabel.BackgroundTransparency = 0.02
	rankStatLabel.TextStrokeTransparency = 0.08

	boardFrame.Position = UDim2.fromOffset(boardInset, 0)
	boardFrame.Size = UDim2.fromOffset(gridSize, gridSize)
	boardGridContainer.Position = UDim2.fromScale(0, 0)
	boardGridContainer.Size = UDim2.fromScale(1, 1)
	boardLayout.CellSize = UDim2.fromOffset(cellPixels, cellPixels)
	boardLayout.CellPadding = UDim2.fromOffset(boardCellPadding, boardCellPadding)
	boardPadding.PaddingTop = UDim.new(0, boardPaddingPixels)
	boardPadding.PaddingBottom = UDim.new(0, boardPaddingPixels)
	boardPadding.PaddingLeft = UDim.new(0, boardPaddingPixels)
	boardPadding.PaddingRight = UDim.new(0, boardPaddingPixels)

	local sideWidth = layout.centerWidth
	stageUi.side.Position = UDim2.fromOffset(0, 0)
	stageUi.side.Size = UDim2.fromOffset(sideWidth, layout.trayHeight)
	statusLabel.Position = UDim2.fromOffset(18, 12)
	statusLabel.Size = UDim2.fromOffset(sideWidth - 36, 22)
	statusLabel.TextSize = 17
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left

	local slotHeight = math.max(74, layout.trayHeight - 42)
	for slot, button in handButtons do
		local buttonWidth =
			math.floor((sideWidth - 36 - ((Config.InventorySize - 1) * 14)) / Config.InventorySize)
		button.Position = UDim2.fromOffset(18 + (slot - 1) * (buttonWidth + 14), 38)
		button.Size = UDim2.fromOffset(buttonWidth, slotHeight)

		local preview = handPreviews[slot]
		local previewSize = math.max(60, math.min(94, slotHeight - 10))
		preview.Size = UDim2.fromOffset(previewSize, previewSize)
		preview.Position =
			UDim2.fromOffset(math.max(8, math.floor((buttonWidth - preview.Size.X.Offset) / 2)), 3)

		local label = button:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			label.Position = UDim2.fromOffset(6, 46)
			label.Size = UDim2.fromOffset(math.max(60, buttonWidth - 8), 14)
			label.TextSize = 10
			label.TextXAlignment = Enum.TextXAlignment.Center
		end
	end

	if leaderboardLabel then
		leaderboardLabel.Visible = true
		leaderboardLabel.Position = UDim2.fromOffset(0, 0)
		leaderboardLabel.Size = UDim2.fromOffset(layout.rightWidth, layout.leaderboardHeight)
		leaderboardLabel.TextSize = 18
	end
	local activeLeaderboardHeading = leaderboardLabel and leaderboardLabel:FindFirstChild("Heading")
	if activeLeaderboardHeading and activeLeaderboardHeading:IsA("TextLabel") then
		activeLeaderboardHeading.Position = UDim2.fromOffset(52, 16)
		activeLeaderboardHeading.Size = UDim2.new(1, -76, 0, 30)
		activeLeaderboardHeading.TextSize = 22
	end
	for rowIndex, row in leaderboardRows do
		row.Position = UDim2.fromOffset(16, 58 + (rowIndex - 1) * 42)
		row.Size = UDim2.fromOffset(layout.rightWidth - 32, 38)
		local nameLabel = row:FindFirstChild("Name")
		if nameLabel and nameLabel:IsA("TextLabel") then
			nameLabel.Position = UDim2.fromOffset(84, 0)
			nameLabel.Size = UDim2.fromOffset(144, 38)
			nameLabel.TextSize = 14
		end
		local score = row:FindFirstChild("Score")
		if score and score:IsA("TextLabel") then
			score.Position = UDim2.fromOffset(232, 0)
			score.Size = UDim2.fromOffset(82, 38)
			score.TextSize = 14
		end
	end
	local emptyLabel = leaderboardLabel and leaderboardLabel:FindFirstChild("Empty")
	if emptyLabel and emptyLabel:IsA("TextLabel") then
		emptyLabel.Position = UDim2.fromOffset(24, 112)
		emptyLabel.Size = UDim2.new(1, -48, 0, 72)
		emptyLabel.TextSize = 15
	end

	actionsPanel.Position = UDim2.fromOffset(0, layout.leaderboardHeight + layout.actionGap)
	actionsPanel.Size = UDim2.fromOffset(layout.rightWidth, layout.actionsHeight)

	local actionWidth = math.floor((layout.rightWidth - layout.actionGap) / 2)
	returnHubButton.Position = UDim2.fromOffset(0, 0)
	returnHubButton.Size = UDim2.fromOffset(actionWidth, 44)
	playAgainButton.Position = UDim2.fromOffset(actionWidth + layout.actionGap, 0)
	playAgainButton.Size = UDim2.fromOffset(actionWidth, 44)

	rotatePieceButton.Position = UDim2.fromOffset(0, 56)
	rotatePieceButton.Size = UDim2.fromOffset(actionWidth, 42)
	rerollPieceButton.Position = UDim2.fromOffset(actionWidth + layout.actionGap, 56)
	rerollPieceButton.Size = UDim2.fromOffset(actionWidth, 42)

	for index, decor in stageUi.decorations do
		local width = math.floor(layout.width * (0.14 + index * 0.018))
		local height = math.floor(layout.height * (0.08 + index * 0.01))
		decor.Size = UDim2.fromOffset(width, height)
		decor.Position = UDim2.fromOffset(
			(index % 2 == 0) and (layout.width - width - layout.outerPadding * index)
				or layout.outerPadding * index,
			layout.top + 48 + index * math.floor(layout.height * 0.105)
		)
	end
	if stageUi.notice then
		stageUi.notice.Size = UDim2.fromOffset(340, 96)
		stageUi.notice.Position = UDim2.new(0.5, -170, 0, layout.top + 58)
	end
	if stageUi.wash then
		stageUi.wash.Size = UDim2.fromScale(1, 1)
	end
end

returnHubButton.Activated:Connect(function()
	playSound("Button")
	day43Ui.fireQueueRequest("LeaveBattle")
end)

playAgainButton.Activated:Connect(function()
	playSound("Queue")
	day43Ui.fireQueueRequest("PlayAgain")
end)

local function requestSelectedHandAction(action)
	if not currentState or currentState.mode ~= "Custom" then
		showBanner("Custom Lab only", Color3.fromRGB(255, 139, 61))
		playSound("Blocked")
		return
	end

	if not selectedSlot or not currentState.hand or not currentState.hand[selectedSlot] then
		showBanner("Choose an active piece first", Color3.fromRGB(255, 139, 61))
		playSound("Blocked")
		return
	end

	playSound("Button")
	handEvent:FireServer(action, selectedSlot)
end

rotatePieceButton.Activated:Connect(function()
	requestSelectedHandAction("Rotate")
end)

rerollPieceButton.Activated:Connect(function()
	requestSelectedHandAction("Reroll")
end)

workspaceInteraction = {
	stop = function() end,
}

local function clearGlossyBlocks(parent)
	for _, child in parent:GetChildren() do
		if child.Name == "GlossyBlock" or child.Name == "GlossyBlockShadow" then
			child:Destroy()
		end
	end
end

local function setCellGloss(cell, color, state)
	clearGlossyBlocks(cell)

	if state == "empty" then
		cell.BackgroundColor3 = customization.boardEmptyColor
		return
	end

	cell.BackgroundColor3 = state == "invalid" and Color3.fromRGB(82, 25, 37)
		or Color3.fromRGB(10, 24, 47)
	ArcadeUI.GlossyBlock(
		cell,
		color,
		UDim2.new(1, -6, 1, -6),
		UDim2.fromOffset(3, 3),
		"GlossyBlock"
	)
end

renderBoard = function(forceFull)
	local preset, hasSoloStage = activeStageVisual()
	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			local value = currentState.board[y][x]
			local unchanged = not forceFull
				and lastRenderedBoard
				and lastRenderedBoard[y]
				and lastRenderedBoard[y][x] == value
			if not unchanged then
				local cell = cells[y][x]
				if value == false then
					setCellGloss(cell, customization.boardEmptyColor, "empty")
				elseif value == "garbage" then
					setCellGloss(
						cell,
						hasSoloStage and preset.boardOutline or Config.Colors.Garbage,
						"filled"
					)
				elseif hasSoloStage then
					setCellGloss(cell, StageVisuals.blockColorForCell(preset, x, y), "filled")
				elseif typeof(value) == "Color3" then
					setCellGloss(cell, value, "filled")
				else
					setCellGloss(cell, Config.Colors.Filled, "filled")
				end
				local gradient = cell:FindFirstChildOfClass("UIGradient")
				if gradient then
					local baseColor = cell.BackgroundColor3
					gradient.Color = ColorSequence.new({
						ColorSequenceKeypoint.new(
							0,
							baseColor:Lerp(
								Color3.fromRGB(255, 255, 255),
								value == false and 0.06 or 0.22
							)
						),
						ColorSequenceKeypoint.new(
							1,
							baseColor:Lerp(Color3.fromRGB(0, 0, 0), value == false and 0.1 or 0.18)
						),
					})
				end
				local stroke = cell:FindFirstChildOfClass("UIStroke")
				if stroke then
					stroke.Color = value == false
							and (hasSoloStage and preset.boardOutline or Color3.fromRGB(38, 61, 97))
						or Color3.fromRGB(255, 255, 255)
					stroke.Transparency = value == false and 0.2 or 0.55
				end
			end

			lastRenderedBoard = lastRenderedBoard or {}
			lastRenderedBoard[y] = lastRenderedBoard[y] or {}
			lastRenderedBoard[y][x] = value
		end
	end

	updateStatusText()
end

local ghostCells = {}

renderGhostPreview = function()
	for _, ghostCell in ghostCells do
		ghostCell:Destroy()
	end
	table.clear(ghostCells)

	local shape = getSelectedShape()
	if not shape or not hoverX or not hoverY or not currentState or not currentState.alive then
		return
	end

	local preset, hasSoloStage = activeStageVisual()
	local canPlace = Grid.canPlace(currentState.board, shape, hoverX, hoverY)
	statusLabel.Text = canPlace and `Place {shape.id}` or "That spot is blocked"

	local innerPadding = WINDOW_LAYOUT.boardPadding
	local cellGap = WINDOW_LAYOUT.boardGap
	local cellPixels = WINDOW_LAYOUT.boardCell

	for _, cell in shape.cells do
		local x = hoverX + cell.X
		local y = hoverY + cell.Y
		if x >= 1 and x <= Config.BoardSize and y >= 1 and y <= Config.BoardSize then
			local ghostCell = Instance.new("Frame")
			ghostCell.Name = `Ghost_{x}_{y}`
			ghostCell.Active = false
			ghostCell.Position = UDim2.fromOffset(
				innerPadding + (x - 1) * (cellPixels + cellGap),
				innerPadding + (y - 1) * (cellPixels + cellGap)
			)
			ghostCell.Size = UDim2.fromOffset(cellPixels, cellPixels)
			ghostCell.Parent = boardGhostLayer
			ArcadeUI.BoardCell(ghostCell)

			local color = canPlace
					and (hasSoloStage and StageVisuals.blockColorForCell(preset, x, y) or shape.color)
				or Config.Colors.PreviewInvalid
			setCellGloss(ghostCell, color, canPlace and "preview" or "invalid")

			local stroke = ghostCell:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = canPlace and Color3.fromRGB(255, 255, 255)
					or Color3.fromRGB(255, 86, 107)
				stroke.Transparency = 0.12
			end

			table.insert(ghostCells, ghostCell)
		end
	end
end

pulseHandSlot = function(slot)
	local button = handButtons[slot]
	if not button or reducedMotion then
		return
	end

	local scale = button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = button
	TweenService:Create(scale, QUICK_TWEEN, { Scale = 1.06 }):Play()
	task.delay(0.12, function()
		if scale.Parent then
			TweenService:Create(scale, SOFT_TWEEN, { Scale = 1 }):Play()
		end
	end)
end

day43Ui.playTrayEntrance = function(button, slot)
	if reducedMotion then
		return
	end

	local scale = button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = button
	scale.Scale = 0.4
	task.delay((slot - 1) * 0.05, function()
		if scale.Parent then
			playSound("TrayRefill")
			TweenService:Create(
				scale,
				TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Scale = 1 }
			):Play()
		end
	end)
end

renderHand = function()
	local preset, hasSoloStage = activeStageVisual()
	for slot, button in handButtons do
		local shape = currentState.hand[slot]
		local isOccupied = shape ~= nil
		if isOccupied and not day43Ui.previousHandOccupied[slot] then
			day43Ui.playTrayEntrance(button, slot)
		end
		day43Ui.previousHandOccupied[slot] = isOccupied
		local label = button:FindFirstChild("Label")
		if label then
			label.Text = ArcadeUI.HandSlotText(shape)
			label.TextColor3 = hasSoloStage and preset.panelText or Color3.fromRGB(245, 247, 251)
		end
		ArcadeUI.RenderShapePreview(handPreviews[slot], shape, {
			blockColors = hasSoloStage and preset.blockPalette or nil,
		})
		button.BackgroundColor3 = selectedSlot == slot
				and (hasSoloStage and preset.panelMuted or Color3.fromRGB(18, 71, 126))
			or shape and (hasSoloStage and preset.panel or ArcadeUI.Color.inner)
			or Color3.fromRGB(28, 34, 46)
		button.BackgroundTransparency = shape and 0 or 0.32
		local stroke = button:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = selectedSlot == slot
					and (hasSoloStage and preset.accent or ArcadeUI.Color.rimBright)
				or shape and (hasSoloStage and preset.panelBorder or Color3.fromRGB(33, 103, 177))
				or Color3.fromRGB(78, 84, 96)
			stroke.Thickness = selectedSlot == slot and 4 or 2
			stroke.Transparency = shape and 0.08 or 0.45
		end
	end
end

local function renderLeaderboard(leaderboard)
	local preset, hasSoloStage = activeStageVisual()
	local currentRank = nil
	thumbnailRequestToken += 1
	local leaderboardToken = thumbnailRequestToken
	local visibleCount = 0

	for index, row in leaderboardRows do
		local entry = leaderboard and leaderboard[index]
		row.Visible = entry ~= nil
		if not entry then
			continue
		end
		visibleCount += 1

		local isLocalPlayer = entry.userId == player.UserId or entry.name == player.Name
		if isLocalPlayer then
			currentRank = index
		end

		local rowStroke = row:FindFirstChildOfClass("UIStroke")
		if rowStroke then
			rowStroke.Color = isLocalPlayer
					and (hasSoloStage and preset.accent or ArcadeUI.Color.rimBright)
				or index == 1 and ArcadeUI.Color.gold
				or index == 2 and ArcadeUI.Color.silver
				or index == 3 and ArcadeUI.Color.bronze
				or (hasSoloStage and preset.leaderboard or Color3.fromRGB(31, 90, 151))
			rowStroke.Thickness = isLocalPlayer and 3 or 1
			rowStroke.Transparency = isLocalPlayer and 0 or 0.28
		end

		local rank = row:FindFirstChild("Rank")
		if rank and rank:IsA("TextLabel") then
			rank.Text = index <= 3 and tostring(index) or tostring(index)
			rank.TextColor3 = index == 1 and ArcadeUI.Color.gold
				or index == 2 and ArcadeUI.Color.silver
				or index == 3 and ArcadeUI.Color.bronze
				or ArcadeUI.Color.text
		end

		local avatar = row:FindFirstChild("Avatar")
		if avatar and avatar:IsA("Frame") then
			avatar.BackgroundColor3 = isLocalPlayer
					and (hasSoloStage and preset.accent or Color3.fromRGB(254, 230, 122))
				or (hasSoloStage and preset.panelMuted or Color3.fromRGB(32, 73, 118))
			local avatarImage = avatar:FindFirstChild("AvatarImage")
			if avatarImage and avatarImage:IsA("ImageLabel") then
				avatarImage.Image = ""
				avatarImage.Visible = false
				requestLeaderboardThumbnail(entry.userId, avatarImage, leaderboardToken)
			end
		end

		local nameLabel = row:FindFirstChild("Name")
		if nameLabel and nameLabel:IsA("TextLabel") then
			nameLabel.Text = isLocalPlayer and "You" or entry.name or "Player"
			nameLabel.TextColor3 = isLocalPlayer
					and (hasSoloStage and preset.stage or ArcadeUI.Color.gold)
				or (hasSoloStage and preset.panelText or ArcadeUI.Color.text)
		end

		local score = row:FindFirstChild("Score")
		if score and score:IsA("TextLabel") then
			score.Text = tostring(entry.score or 0)
			score.TextColor3 = index <= 3
					and (hasSoloStage and preset.accent or ArcadeUI.Color.gold)
				or (hasSoloStage and preset.stage or ArcadeUI.Color.best)
		end
	end

	if leaderboardLabel then
		local emptyLabel = leaderboardLabel:FindFirstChild("Empty")
		if not emptyLabel then
			emptyLabel = Instance.new("TextLabel")
			emptyLabel.Name = "Empty"
			emptyLabel.BackgroundTransparency = 1
			emptyLabel.Position = UDim2.fromOffset(24, 108)
			emptyLabel.Size = UDim2.new(1, -48, 0, 64)
			emptyLabel.Font = Enum.Font.GothamBold
			emptyLabel.Text = "More players will appear here."
			emptyLabel.TextColor3 = ArcadeUI.Color.muted
			emptyLabel.TextSize = 16
			emptyLabel.TextWrapped = true
			emptyLabel.Parent = leaderboardLabel
		end
		emptyLabel.Visible = visibleCount <= 1
	end

	if rankStatLabel then
		rankStatLabel.Text =
			statRichText("TROPHY", currentRank and `RANK #{currentRank}` or "RANK --", "#FFD247")
		enforceStatTextContrast()
	end

	leaderboardLabel.Text = ""
end

renderDiagnostics = function()
	if not diagnosticsLabel then
		return
	end

	local lines = {
		"STUDIO MATCH DIAGNOSTICS",
		`Player: {player.Name}`,
	}

	if currentState then
		table.insert(
			lines,
			`Mode: {currentState.mode or "?"} | Arena: {currentState.arenaIndex or "--"} | Match: {currentState.sessionId or "--"}`
		)
		table.insert(
			lines,
			`Score: {currentState.score or 0} | Alive: {tostring(currentState.alive)}`
		)
	elseif currentHubState then
		table.insert(lines, "Mode: Hub")
		table.insert(
			lines,
			`Arenas: {currentHubState.openArenas or 0}/{currentHubState.totalArenas or 0} | Matches: {currentHubState.activeSessions or 0}`
		)
		table.insert(
			lines,
			`Queue: {currentHubState.queueCount or 0}/{currentHubState.minPlayers or 2} | Queued: {tostring(
				currentHubState.queued
			)}`
		)
		local stats = typeof(currentHubState.analytics) == "table" and currentHubState.analytics
			or {}
		table.insert(
			lines,
			`Profile L/S/Sanitized: {currentHubState.profileLoadFailures or 0}/{currentHubState.profileSaveFailures or 0}/{stats.profileFieldsSanitized or 0}`
		)
		if typeof(currentHubState.analytics) == "table" then
			table.insert(
				lines,
				`Analytics Solo/Battle/Story/P/C/K/I/F/R/T/D: {stats.soloSessionsStarted or 0}/{stats.battleSessionsStarted or 0}/{stats.storySessionsStarted or 0}/{stats.placements or 0}/{stats.linesCleared or 0}/{stats.combosTriggered or 0}/{stats.invalidPlacements or 0}/{stats.forfeits or 0}/{stats.rejectedPlaceRequests or 0}/{stats.throttledPlaceRequests or 0}/{stats.suddenDeathPressureRows or 0}`
			)
		end
	else
		table.insert(lines, "Waiting for state...")
	end

	if currentHubState and typeof(currentHubState.sessions) == "table" then
		for _, session in currentHubState.sessions do
			table.insert(
				lines,
				`#{session.id} {session.mode} A{session.arenaIndex or "?"} P{session.playerCount}/{session.startedWith} T{session.timeLeft}s{session.suddenDeath and " SD" or ""}`
			)
		end
	end

	diagnosticsLabel.Text = table.concat(lines, "\n")
end

stateEvent.OnClientEvent:Connect(function(nextState, leaderboard)
	dismissLoading()
	local oldBoard = previousBoard
	currentState = nextState

	if not currentState then
		if workspaceInteraction then
			workspaceInteraction.stop()
		end
		root.Visible = false
		if stageUi.card then
			stageUi.card.Visible = false
		end
		stageUi.lastStage = nil
		rotatePieceButton.Visible = false
		rerollPieceButton.Visible = false
		if hudController then
			suppressExternalPuzzleHud(false)
			hudController:UpdateGameState(nil)
		end
		if developerPanelController then
			developerPanelController:UpdateState(nil)
		end
		setHubPanelVisible(not hubManuallyClosed)
		updateTutorialVisibility()
		previousBoard = nil
		lastRenderedBoard = nil
		renderGhostPreview()
		renderDiagnostics()
		return
	end

	if not root.Visible then
		root.Visible = true
		applyUiScale()
	end
	if hudController then
		hudController:UpdateGameState(currentState)
		suppressExternalPuzzleHud(true)
	end
	if developerPanelController then
		developerPanelController:UpdateState(currentState)
	end
	if currentState.alive then
		resultPanelController:Hide()
	end
	cosmeticPanelController:Hide()
	shopPanelController:Hide()
	storyPanelController:Hide()
	setHubPanelVisible(false)
	updateTutorialVisibility()
	stageUi.titleButton.Text = currentState.mode == "Story" and "STORY TRAINING"
		or currentState.mode == "Custom" and "CUSTOM LAB"
		or currentState.mode == "Solo" and "SOLO PUZZLE"
		or "BRICKBLAST BATTLE"
	scoreLabel.Text = tostring(currentState.score)
	if bestScoreLabel then
		bestScoreLabel.Text = `BEST {currentState.bestScore or 0}`
	end
	if comboBadgeLabel then
		local combo = math.max(1, currentState.comboStreak or 1)
		comboBadgeLabel.Text = statRichText("COMBO", `x{combo}`, "#FF5DC8")
		enforceStatTextContrast()
		comboBadgeLabel.Visible = combo > 1 or currentState.mode == "Solo"
	end
	renderStageDisplay()
	matchInfoLabel.Text = currentState.mode == "Story"
			and (ArcadeUI.StoryGoalText(currentState) or "Story Mission")
		or currentState.mode == "Custom" and "Rotate or reroll pieces before placement"
		or currentState.mode == "Solo" and `Best score: {currentState.bestScore or 0}`
		or `Arena {currentState.arenaIndex or "--"} | Match {currentState.sessionId or "--"}`
	timerLabel.Text = currentState.timeLeft
			and currentState.suddenDeath
			and `Sudden: {currentState.timeLeft}s`
		or currentState.timeLeft and `Time: {currentState.timeLeft}s`
		or "Time: --"
	timerLabel.TextColor3 = currentState.suddenDeath and Color3.fromRGB(255, 86, 107)
		or currentState.timeLeft and currentState.timeLeft <= 15 and Color3.fromRGB(255, 210, 71)
		or Color3.fromRGB(193, 201, 215)
	playAgainButton.Text = currentState.mode == "Story" and "Replay" or "Play Again"
	playAgainButton.Visible = not currentState.alive and currentState.mode ~= "Custom"
	rotatePieceButton.Visible = currentState.mode == "Custom" and currentState.alive
	rerollPieceButton.Visible = currentState.mode == "Custom" and currentState.alive

	selectFirstAvailablePiece()

	renderBoard()
	renderGhostPreview()
	ArcadeUI.PlayBoardDiff({
		boardSize = Config.BoardSize,
		cells = cells,
		cellScales = cellScales,
		getCurrentState = function()
			return currentState
		end,
		boardEmptyColor = customization.boardEmptyColor,
		reducedMotion = reducedMotion,
		TweenService = TweenService,
		quickTween = QUICK_TWEEN,
	}, oldBoard, currentState.board)
	renderHand()
	renderLeaderboard(leaderboard)
	ArcadeUI.RenderProgression({
		player = player,
		currentState = currentState,
		progressionLabel = progressionLabel,
		coinChipLabel = coinChipLabel,
		coinStatLabel = coinStatLabel,
		hudController = hudController,
		statRichText = statRichText,
		enforceStatTextContrast = enforceStatTextContrast,
	})
	renderDiagnostics()
	previousBoard = ArcadeUI.CloneBoard(currentState.board, Config.BoardSize)
end)

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		for _, stat in leaderstats:GetChildren() do
			if stat:IsA("IntValue") then
				stat.Changed:Connect(function()
					ArcadeUI.RenderProgression({
						player = player,
						currentState = currentState,
						progressionLabel = progressionLabel,
						coinChipLabel = coinChipLabel,
						coinStatLabel = coinStatLabel,
						hudController = hudController,
						statRichText = statRichText,
						enforceStatTextContrast = enforceStatTextContrast,
					})
					updateSettingsButtonText()
				end)
			end
		end
		leaderstats.ChildAdded:Connect(function(child)
			if child:IsA("IntValue") then
				child.Changed:Connect(function()
					ArcadeUI.RenderProgression({
						player = player,
						currentState = currentState,
						progressionLabel = progressionLabel,
						coinChipLabel = coinChipLabel,
						coinStatLabel = coinStatLabel,
						hudController = hudController,
						statRichText = statRichText,
						enforceStatTextContrast = enforceStatTextContrast,
					})
					updateSettingsButtonText()
				end)
				ArcadeUI.RenderProgression({
					player = player,
					currentState = currentState,
					progressionLabel = progressionLabel,
					coinChipLabel = coinChipLabel,
					coinStatLabel = coinStatLabel,
					hudController = hudController,
					statRichText = statRichText,
					enforceStatTextContrast = enforceStatTextContrast,
				})
				updateSettingsButtonText()
			end
		end)
		ArcadeUI.RenderProgression({
			player = player,
			currentState = currentState,
			progressionLabel = progressionLabel,
			coinChipLabel = coinChipLabel,
			coinStatLabel = coinStatLabel,
			hudController = hudController,
			statRichText = statRichText,
			enforceStatTextContrast = enforceStatTextContrast,
		})
		updateSettingsButtonText()
	end
end)

hubEvent.OnClientEvent:Connect(function(hubState)
	dismissLoading()
	if not hubState then
		return
	end

	currentHubState = hubState
	applyWorldVisualQuality()
	if hudController then
		hudController:UpdateHubState(hubState)
	end
	renderDiagnostics()

	if
		hubState.mode == "Battle"
		or hubState.mode == "Story"
		or hubState.mode == "Custom"
		or hubState.mode == "Solo"
	then
		if hudController then
			hudController:UpdateGameState({
				mode = hubState.mode,
				message = hubState.message,
			})
		end
		updateTutorialVisibility()
		return
	end

	setHubPanelVisible(not hubManuallyClosed)
	updateTutorialVisibility()
	if storyPanelController then
		storyPanelController:Refresh()
	end
	if homePanelController then
		homePanelController:UpdateHubState(
			hubState,
			ArcadeUI.StoryPreviewText(hubState.storyMission, hubState.storyStars),
			customization.accentColor
		)
	end
	renderDiagnostics()
end)

shopEvent.OnClientEvent:Connect(function(message)
	if shopPanelController then
		shopPanelController:HandleServerMessage(message)
	end
end)

day43Ui.renderAchievements = function(list)
	local scroll = day43Ui.achievementsScroll
	if not scroll or not scroll.Parent then
		return
	end

	for _, child in scroll:GetChildren() do
		if child:IsA("Frame") or (child:IsA("TextLabel") and child.Name == "Loading") then
			child:Destroy()
		end
	end

	table.sort(list, function(left, right)
		if left.unlocked ~= right.unlocked then
			return left.unlocked
		end
		if left.stat ~= right.stat then
			return left.stat < right.stat
		end
		return left.threshold < right.threshold
	end)

	for order, entry in list do
		local tierColor = entry.tier == "Gold" and ArcadeUI.Color.gold
			or entry.tier == "Silver" and ArcadeUI.Color.silver
			or ArcadeUI.Color.bronze

		local row = Instance.new("Frame")
		row.LayoutOrder = order
		row.Size = UDim2.new(1, 0, 0, 60)
		row.BackgroundColor3 = entry.unlocked and Color3.fromRGB(20, 46, 30)
			or Color3.fromRGB(14, 23, 43)
		row.BorderSizePixel = 0
		row.Parent = scroll
		UITheme.corner(row, 12)
		UITheme.stroke(row, tierColor, 2, entry.unlocked and 0.1 or 0.4)

		local tierBar = Instance.new("Frame")
		tierBar.Position = UDim2.fromOffset(12, 12)
		tierBar.Size = UDim2.fromOffset(10, 36)
		tierBar.BackgroundColor3 = tierColor
		tierBar.BorderSizePixel = 0
		tierBar.Parent = row
		UITheme.corner(tierBar, 4)

		local title = Instance.new("TextLabel")
		title.BackgroundTransparency = 1
		title.Position = UDim2.fromOffset(34, 8)
		title.Size = UDim2.new(1, -46, 0, 22)
		title.Font = Enum.Font.GothamBlack
		title.Text = `{entry.name} ({entry.tier})`
		title.TextColor3 = entry.unlocked and Color3.fromRGB(123, 237, 75)
			or Color3.fromRGB(255, 255, 255)
		title.TextSize = 15
		title.TextXAlignment = Enum.TextXAlignment.Left
		title.TextTruncate = Enum.TextTruncate.AtEnd
		title.Parent = row

		local progressText = entry.unlocked and "Unlocked!"
			or `{math.min(entry.progress, entry.threshold)} / {entry.threshold}`
		local detail = Instance.new("TextLabel")
		detail.BackgroundTransparency = 1
		detail.Position = UDim2.fromOffset(34, 30)
		detail.Size = UDim2.new(1, -46, 0, 20)
		detail.Font = Enum.Font.GothamBold
		detail.Text = `{progressText} - +{entry.rewardCoins} coins`
		detail.TextColor3 = Color3.fromRGB(190, 210, 233)
		detail.TextSize = 13
		detail.TextXAlignment = Enum.TextXAlignment.Left
		detail.Parent = row
	end
end

day43Ui.achievementsEvent.OnClientEvent:Connect(function(response)
	if response and response.kind == "Snapshot" and response.achievements then
		day43Ui.renderAchievements(response.achievements)
	end
end)

day43Ui.codesEvent.OnClientEvent:Connect(function(response)
	if not response then
		return
	end

	local message = response.message or ""
	local isSuccess = response.kind == "Success"
	local color = isSuccess and Color3.fromRGB(123, 237, 75) or Color3.fromRGB(255, 139, 61)

	if day43Ui.codeStatusLabel and day43Ui.codeStatusLabel.Parent then
		day43Ui.codeStatusLabel.Text = message
		day43Ui.codeStatusLabel.TextColor3 = color
	end

	playSound(isSuccess and "Result" or "Blocked")
	showBanner(message, color)
end)

effectsEvent.OnClientEvent:Connect(function(effect)
	if not effect then
		return
	end

	if effect.kind == "InvalidPlace" then
		playSound("Blocked")
		ArcadeUI.ShakeWindow({
			root = root,
			reducedMotion = reducedMotion,
			TweenService = TweenService,
		})
		showBanner(effect.message or "That spot is blocked", Color3.fromRGB(255, 86, 107))
	elseif effect.kind == "Place" then
		playSound("Place")
		if effect.shape then
			for _, cell in effect.shape.cells do
				ArcadeUI.PlayCellPop({
					cellScales = cellScales,
					reducedMotion = reducedMotion,
					TweenService = TweenService,
					quickTween = QUICK_TWEEN,
				}, effect.originX + cell.X, effect.originY + cell.Y)
			end
		end
		if effect.scoreDelta and effect.scoreDelta > 0 then
			ArcadeUI.ScorePopup({
				parent = stageUi.scoreCard,
				reducedMotion = reducedMotion,
				TweenService = TweenService,
			}, effect.scoreDelta)
		end
		if effect.linesCleared and effect.linesCleared > 0 then
			playSound("Clear")
			if effect.comboStreak and effect.comboStreak > 1 then
				playSound("Combo")
				ArcadeUI.PulseCombo({
					comboBadge = comboBadgeLabel,
					reducedMotion = reducedMotion,
					TweenService = TweenService,
					quickTween = QUICK_TWEEN,
				})
			end
			if effect.perfectClear then
				playSound("PerfectClear")
				ArcadeUI.PerfectClearFlash({
					boardFrame = boardFrame,
					reducedMotion = reducedMotion,
					TweenService = TweenService,
				})
				showBanner(`Perfect clear! +{effect.comboBonus or 0}`, Color3.fromRGB(255, 210, 71))
			elseif effect.comboStreak and effect.comboStreak > 1 then
				showBanner(
					`Combo x{effect.comboStreak}! +{effect.comboBonus or 0}`,
					Color3.fromRGB(255, 210, 71)
				)
			elseif effect.lineClearEffect == "Ripple" then
				showBanner(
					`Ripple clear: {effect.linesCleared} line(s)!`,
					Color3.fromRGB(30, 187, 255)
				)
			elseif effect.multiLineBonus and effect.multiLineBonus > 0 then
				-- Say the multi-line bonus out loud, otherwise the points for
				-- the hardest clear in the game arrive invisibly.
				showBanner(
					`{effect.linesCleared} lines at once! +{effect.multiLineBonus}`,
					Color3.fromRGB(255, 210, 71)
				)
			else
				showBanner(`Cleared {effect.linesCleared} line(s)!`, Color3.fromRGB(123, 237, 75))
			end
		end
	elseif effect.kind == "BattleStart" then
		playSound("Queue")
		resultPanelController:Hide()
		showBanner(
			effect.detail or effect.message or "Solo puzzle started!",
			customization.accentColor
		)
	elseif effect.kind == "HandUpdated" then
		playSound("Button")
		if effect.slot and pulseHandSlot then
			pulseHandSlot(effect.slot)
		end
		showBanner(effect.message or "Piece updated", Color3.fromRGB(255, 93, 200))
	elseif effect.kind == "SuddenDeath" then
		playSound("Blocked")
		showBanner(effect.detail or effect.message or "Sudden death!", Color3.fromRGB(255, 86, 107))
	elseif effect.kind == "SuddenDeathPressure" then
		playSound("Blocked")
		showBanner(effect.message or "Pressure row rising", Color3.fromRGB(255, 139, 61))
	elseif effect.kind == "StageUp" then
		pulseStageUpDisplay()
		if effect.currentStage then
			playStageTransition(effect.currentStage)
			if stageUi.title then
				stageUi.title.Text = `STAGE UP {effect.currentStage}`
				local flashedStage = effect.currentStage
				task.delay(reducedMotion and 1.2 or 2, function()
					if stageUi.title and stageUi.lastStage == flashedStage then
						stageUi.title.Text = `STAGE {flashedStage}`
					end
				end)
			end
		end
		local preset = StageVisuals.presetForStage(effect.currentStage or 1)
		showBanner(`Stage {effect.currentStage or "?"}!`, preset.stage)
	elseif effect.kind == "AchievementUnlocked" then
		playSound("PerfectClear")
		showBanner(
			`Achievement unlocked: {effect.name} ({effect.tier}) +{effect.rewardCoins} coins`,
			Color3.fromRGB(255, 210, 71)
		)
	elseif effect.kind == "DeveloperCommand" then
		showBanner(effect.message or "Developer command applied", Color3.fromRGB(123, 237, 75))
	elseif effect.kind == "BattleResult" then
		playSound("Result")
		resultPanelController:Show(effect.result, effect.message, effect.won)
		showBanner(
			effect.message or "Run complete",
			effect.won and Color3.fromRGB(123, 237, 75) or Color3.fromRGB(255, 139, 61)
		)
	end
end)

settingsEvent.OnClientEvent:Connect(function(settings)
	dismissLoading()
	if typeof(settings) ~= "table" then
		return
	end

	cosmeticPreviewSnapshot = nil

	if isFiniteNumber(settings.themeIndex) then
		themeIndex = math.clamp(math.floor(settings.themeIndex), 1, #themePresets)
	end

	if typeof(settings.reducedMotion) == "boolean" then
		reducedMotion = settings.reducedMotion
		applyWorldVisualQuality()
	end

	if isFiniteNumber(settings.uiScale) then
		uiScale = math.clamp(settings.uiScale, 0.92, 1.12)
	end

	if typeof(settings.tutorialComplete) == "boolean" then
		tutorialComplete = settings.tutorialComplete
	end

	if typeof(settings.pieceSkin) == "string" then
		for index, skin in Blocks.PieceSkins do
			if skin == settings.pieceSkin then
				pieceSkinIndex = index
				break
			end
		end
	end

	if typeof(settings.boardSkin) == "string" then
		for index, skin in Config.BoardSkins do
			if skin.name == settings.boardSkin then
				boardSkinIndex = index
				break
			end
		end
	end

	if typeof(settings.soundEnabled) == "boolean" then
		soundEnabled = settings.soundEnabled
	end

	if isFiniteNumber(settings.soundVolume) then
		soundVolume = math.clamp(settings.soundVolume, 0, 1)
	end

	applySoundSettings()
	updateSettingsButtonText()
	applyTheme()
	applyUiScale()
	if hudController then
		hudController:UpdateProgression()
	end
	clampWindowToScreen()
	updateTutorialVisibility()
end)

gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	applyUiScale()
	clampWindowToScreen()
end)

applyWindowLayout()
applyTheme()
applyUiScale()
applySoundSettings()
settingsEvent:FireServer("Request")
task.delay(6, dismissLoading)
