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
local ArcadeUI = require(script.Parent.ArcadeUI)
local CosmeticPanel = require(script.Parent.CosmeticPanel)
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
	accentColor = Color3.fromRGB(64, 156, 255),
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
local trayStage = nil
local actionsPanel = nil
local boardGridContainer = nil
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
local loadingDismissed = false
local tutorialPanel = nil
local hubManuallyClosed = true
local tutorialComplete = true
local tutorialManuallyOpened = false
local cosmeticPreviewSnapshot = nil
local root = nil
local rootScale = nil
local bannerScale = nil
local clampWindowToScreen = nil
local applyWindowLayout = nil
local applyBoardSkin = nil
local renderBoard = nil
local renderHand = nil
local renderDiagnostics = nil
local pulseHandSlot = nil

local DEFAULT_WINDOW_POSITION = UDim2.new(0.5, 0, 0.5, 18)
local DEFAULT_WINDOW_SIZE = Vector2.new(1120, 650)
local DEFAULT_WORKSPACE_SCALE = 1
local MIN_WORKSPACE_SCALE = 0.78
local MAX_WORKSPACE_SCALE = 1.22
local WINDOW_LAYOUT = {
	width = 1120,
	height = 650,
	outerPadding = 22,
	headerHeight = 60,
	headerGap = 16,
	columnGap = 18,
	leftWidth = 222,
	centerWidth = 408,
	rightWidth = 410,
	statGap = 14,
	boardPadding = 18,
	boardGap = 5,
	boardSize = 408,
	boardStageHeight = 408,
	trayGap = 14,
	trayHeight = 104,
	actionGap = 12,
}
local QUICK_TWEEN = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SOFT_TWEEN = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local workspaceScale = DEFAULT_WORKSPACE_SCALE

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
		accent = Color3.fromRGB(64, 156, 255),
	},
	{
		name = "Candy",
		panel = Color3.fromRGB(35, 19, 36),
		board = Color3.fromRGB(45, 27, 49),
		accent = Color3.fromRGB(244, 114, 182),
	},
	{
		name = "Arcade",
		panel = Color3.fromRGB(12, 30, 24),
		board = Color3.fromRGB(18, 42, 35),
		accent = Color3.fromRGB(74, 222, 128),
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
loadingTitle.Text = "Block Blast Battle"
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
loadingAccent.BackgroundColor3 = Color3.fromRGB(64, 156, 255)
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

	local _, bottomRightInset = GuiService:GetGuiInset()
	local usableWidth = math.max(1, screenSize.X - 32)
	local usableHeight = math.max(1, screenSize.Y - bottomRightInset.Y - 32)
	local rootFitScale = math.min(
		1,
		usableWidth / math.max(1, root.Size.X.Offset),
		usableHeight / math.max(1, root.Size.Y.Offset)
	)
	local nextScale = automaticScale * uiScale
	if rootScale then
		local lowerBound = math.min(MIN_WORKSPACE_SCALE, rootFitScale)
		rootScale.Scale = math.clamp(
			math.min(nextScale * workspaceScale, rootFitScale),
			lowerBound,
			MAX_WORKSPACE_SCALE
		)
	end
	if homePanelController then
		homePanelController:RefreshResponsiveLayout(screenSize, nextScale)
	end
	if clampWindowToScreen then
		clampWindowToScreen()
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
			Color3.fromRGB(255, 44, 209),
			Color3.fromRGB(255, 244, 42),
			Color3.fromRGB(69, 255, 86),
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
		Color3.fromRGB(255, 76, 76),
		Color3.fromRGB(255, 204, 54),
		Color3.fromRGB(76, 217, 100),
		Color3.fromRGB(64, 156, 255),
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
		if color == Color3.fromRGB(224, 74, 74) or color == Color3.fromRGB(255, 110, 110) then
			kind = "error"
		elseif color == Color3.fromRGB(251, 146, 60) or color == Color3.fromRGB(255, 207, 102) then
			kind = "warning"
		elseif color == Color3.fromRGB(74, 222, 128) then
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
		renderBoard()
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
		renderBoard()
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
			renderBoard()
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
		queueEvent:FireServer("Story", chapter)
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
			if currentState then
				root.Visible = true
				clampWindowToScreen()
				return
			end
			if
				ExperienceConfig.isModeEnabled("Solo")
				and not ExperienceConfig.isModeEnabled("Battle")
			then
				queueEvent:FireServer("Solo")
			elseif currentHubState and currentHubState.queued then
				queueEvent:FireServer("LeaveQueue")
			else
				queueEvent:FireServer("Battle")
			end
		end,
		modes = function()
			if currentState then
				showBanner("Finish your current run first", Color3.fromRGB(251, 146, 60))
				return
			end
			cosmeticPanelController:Hide()
			shopPanelController:Hide()
			storyPanelController:Hide()
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

				makeModeButton(
					1,
					"Battle Queue",
					"Classic race to outscore rivals.",
					Color3.fromRGB(64, 156, 255),
					function()
						queueEvent:FireServer("Battle")
					end
				)
				makeModeButton(
					2,
					"Story Missions",
					"Solo objectives and replayable guide practice.",
					Color3.fromRGB(167, 109, 255),
					function()
						storyPanelController:Show()
					end
				)
				makeModeButton(
					3,
					"Custom Lab",
					"Test block rotations and reroll your hand.",
					Color3.fromRGB(255, 112, 189),
					function()
						queueEvent:FireServer("CustomLab")
					end
				)
			end)
		end,
		inventory = function()
			shopPanelController:Hide()
			storyPanelController:Hide()
			cosmeticPanelController:Show()
		end,
		shop = function()
			cosmeticPanelController:Hide()
			storyPanelController:Hide()
			shopPanelController:Show()
		end,
		rewards = function()
			hudController:OpenInfoPanel("Quests", {
				"Solo scores, coins, XP, and personal bests are tracked by the server.",
				"Daily quests are coming after the solo loop is tightened.",
				"Leaderboards are the next major progression priority.",
			})
		end,
		settings = function()
			hudController:OpenInfoPanel("Settings", {
				reducedMotion and "Motion: Reduced" or "Motion: Full",
				soundEnabled and `Sound: {math.floor(soundVolume * 100)}%` or "Sound: Off",
				"Full controls remain in the Home panel for now.",
			})
		end,
	},
})

root = Instance.new("Frame")
root.Name = "PCPuzzleWorkspace"
root.AnchorPoint = Vector2.new(0.5, 0.5)
root.Position = DEFAULT_WINDOW_POSITION
root.Size = UDim2.fromOffset(DEFAULT_WINDOW_SIZE.X, DEFAULT_WINDOW_SIZE.Y)
root.BackgroundColor3 = Color3.fromRGB(10, 17, 34)
root.BackgroundTransparency = 0.06
root.BorderSizePixel = 0
root.Visible = false
root.Parent = gui
ArcadeUI.Panel(root, {
	radius = 34,
	rimColor = ArcadeUI.Color.rimBright,
	strokeThickness = 5,
})
root.BackgroundTransparency = 0.06
root.BackgroundTransparency = 0.42
root.BackgroundTransparency = 0.72
local rootStroke = root:FindFirstChildOfClass("UIStroke")
if rootStroke then
	rootStroke.Thickness = 5
	rootStroke.Transparency = 0.42
end
removeDirectGradients(root)
local rootHighlight = root:FindFirstChild("ArcadeTopHighlight")
if rootHighlight and rootHighlight:IsA("GuiObject") then
	rootHighlight.Visible = false
end

rootScale = Instance.new("UIScale")
rootScale.Scale = 1
rootScale.Parent = root

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
			if
				ExperienceConfig.isModeEnabled("Solo")
				and not ExperienceConfig.isModeEnabled("Battle")
			then
				queueEvent:FireServer("Solo")
			else
				queueEvent:FireServer(queued and "LeaveQueue" or "Battle")
			end
		end,
		story = function()
			cosmeticPanelController:Hide()
			shopPanelController:Hide()
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
				showBanner(nextLockedCosmeticText(), Color3.fromRGB(251, 146, 60))
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
				showBanner(nextLockedCosmeticText(), Color3.fromRGB(251, 146, 60))
				playSound("Blocked")
				return
			end

			boardSkinIndex = nextIndex
			updateSettingsButtonText()
			applyBoardSkin()
			if currentState then
				renderBoard()
			end
			playSound("Button")
			saveSettings()
			local boardSkin = Config.BoardSkins[boardSkinIndex]
			showBanner(`Board: {boardSkin and boardSkin.name or "Auto"}`, customization.accentColor)
		end,
		shop = function()
			cosmeticPanelController:Hide()
			storyPanelController:Hide()
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
tutorialButton.BackgroundColor3 = Color3.fromRGB(64, 156, 255)
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
tutorialStoryButton.BackgroundColor3 = Color3.fromRGB(45, 58, 82)
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
	queueEvent:FireServer("Story")
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
resetLayoutButton.BackgroundColor3 = Color3.fromRGB(45, 58, 82)
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
closeWorkspaceButton.AnchorPoint = Vector2.new(1, 0)
closeWorkspaceButton.Position = UDim2.new(1, -26, 0, 18)
closeWorkspaceButton.Size = UDim2.fromOffset(44, 38)
closeWorkspaceButton.BackgroundColor3 = Color3.fromRGB(215, 43, 54)
closeWorkspaceButton.BorderSizePixel = 0
closeWorkspaceButton.Font = Enum.Font.GothamBlack
closeWorkspaceButton.Text = "X"
closeWorkspaceButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeWorkspaceButton.TextSize = 20
closeWorkspaceButton.Parent = workspaceHeader
ArcadeUI.Button(closeWorkspaceButton, Color3.fromRGB(215, 43, 54))
UITheme.attachButtonFeedback(closeWorkspaceButton, isUiReducedMotion)
markInteractive(closeWorkspaceButton)

closeWorkspaceButton.Activated:Connect(function()
	playSound("Button")
	queueEvent:FireServer("LeaveBattle")
end)

settingsButton = makeTopControl("WorkspaceSettingsButton", "SET", Color3.fromRGB(24, 49, 86))
settingsButton.TextSize = 13
settingsButton.Activated:Connect(function()
	playSound("Button")
	hudController:OpenInfoPanel("Settings", {
		reducedMotion and "Motion: Reduced" or "Motion: Full",
		soundEnabled and `Sound: {math.floor(soundVolume * 100)}%` or "Sound: Off",
		"Use Reset to restore the puzzle workspace layout.",
	})
end)

helpButton = makeTopControl("WorkspaceHelpButton", "?", Color3.fromRGB(24, 49, 86))
helpButton.TextSize = 22
helpButton.Activated:Connect(function()
	tutorialManuallyOpened = true
	updateTutorialVisibility()
	playSound("Button")
end)

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
end

local function applyTheme()
	local theme = themePresets[themeIndex]
	customization.panelColor = theme.panel
	customization.accentColor = theme.accent
	root.BackgroundColor3 = theme.panel
	customizeButton.BackgroundColor3 = theme.accent
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
	workspaceScale = DEFAULT_WORKSPACE_SCALE
	root.Position = DEFAULT_WINDOW_POSITION
	applyUiScale()
	clampWindowToScreen()
end)

local title = Instance.new("TextButton")
title.Name = "WorkspaceDragHandle"
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(24, 18)
title.Size = UDim2.fromOffset(530, 42)
title.AutoButtonColor = false
title.Font = Enum.Font.GothamBlack
title.Text = "SOLO PUZZLE WORKSPACE"
title.TextColor3 = Color3.fromRGB(245, 247, 251)
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = workspaceHeader
UITheme.text(title, "title")

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

local scoreCard = Instance.new("Frame")
scoreCard.Name = "ScoreCard"
scoreCard.Position = UDim2.fromOffset(22, 72)
scoreCard.Size = UDim2.fromOffset(210, 170)
scoreCard.Parent = leftColumn
ArcadeUI.StatCard(scoreCard)

local scoreHeading = Instance.new("TextLabel")
scoreHeading.BackgroundTransparency = 1
scoreHeading.Position = UDim2.fromOffset(16, 12)
scoreHeading.Size = UDim2.new(1, -32, 0, 26)
scoreHeading.Font = Enum.Font.GothamBlack
scoreHeading.Text = "SCORE"
scoreHeading.TextColor3 = Color3.fromRGB(255, 255, 255)
scoreHeading.TextSize = 22
scoreHeading.TextXAlignment = Enum.TextXAlignment.Center
scoreHeading.Parent = scoreCard
ArcadeUI.Text(scoreHeading)

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
scoreLabel.Parent = scoreCard
ArcadeUI.Text(scoreLabel, "score")

local scoreDivider = Instance.new("Frame")
scoreDivider.BackgroundColor3 = ArcadeUI.Color.rim
scoreDivider.BackgroundTransparency = 0.28
scoreDivider.BorderSizePixel = 0
scoreDivider.Position = UDim2.new(0, 24, 0, 92)
scoreDivider.Size = UDim2.new(1, -48, 0, 3)
scoreDivider.Parent = scoreCard
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
bestScoreLabel.Parent = scoreCard
ArcadeUI.Text(bestScoreLabel, "best")

comboBadgeLabel = Instance.new("TextLabel")
comboBadgeLabel.BackgroundTransparency = 0.08
comboBadgeLabel.BackgroundColor3 = ArcadeUI.Color.inner
comboBadgeLabel.Position = UDim2.fromOffset(22, 232)
comboBadgeLabel.Size = UDim2.fromOffset(210, 108)
comboBadgeLabel.Font = Enum.Font.GothamBlack
comboBadgeLabel.Text = statRichText("COMBO", "x1", "#DA49FF")
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
rankStatLabel.Text = statRichText("TROPHY", "RANK --", "#FFC629")
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

local boardFrame = Instance.new("Frame")
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
boardGridContainer = Instance.new("Frame")
boardGridContainer.Name = "BoardGridContainer"
boardGridContainer.BackgroundTransparency = 1
boardGridContainer.BorderSizePixel = 0
boardGridContainer.ClipsDescendants = true
boardGridContainer.Parent = boardFrame

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
				local shape = currentState.hand[selectedSlot]
				if
					shape
					and typeof(boardX) == "number"
					and typeof(boardY) == "number"
					and Grid.canPlace(currentState.board, shape, boardX, boardY)
				then
					playSound("Place")
					placeEvent:FireServer(selectedSlot, boardX, boardY)
				elseif shape then
					statusLabel.Text = "That spot is blocked"
					playSound("Blocked")
					showBanner("That spot is blocked", Color3.fromRGB(224, 74, 74))
				end
			end
		end)

		button.MouseEnter:Connect(function()
			hoverX = button:GetAttribute("BoardX")
			hoverY = button:GetAttribute("BoardY")
			if currentState then
				renderBoard()
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
					renderBoard()
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

local side = Instance.new("Frame")
side.Position = UDim2.fromOffset(360, 104)
side.Size = UDim2.fromOffset(256, 304)
side.BackgroundColor3 = Color3.fromRGB(8, 23, 45)
side.BackgroundTransparency = 0.02
side.Parent = trayStage
ArcadeUI.Panel(side, {
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
statusLabel.Parent = side
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

for slot = 1, Config.InventorySize do
	local button = Instance.new("TextButton")
	button.Position = UDim2.fromOffset(0, 38 + (slot - 1) * 66)
	button.Size = UDim2.fromOffset(256, 58)
	button.BackgroundColor3 = Color3.fromRGB(31, 38, 52)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(245, 247, 251)
	button.TextSize = 18
	button.Text = ""
	button.Parent = side
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
			renderBoard()
			renderHand()
		end
	end)
end

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
returnHubButton.Position = UDim2.fromOffset(360, 390)
returnHubButton.Size = UDim2.fromOffset(124, 32)
returnHubButton.BackgroundColor3 = Color3.fromRGB(45, 58, 82)
returnHubButton.BorderSizePixel = 0
returnHubButton.Font = Enum.Font.GothamBold
returnHubButton.Text = "Return Hub"
returnHubButton.TextColor3 = Color3.fromRGB(245, 247, 251)
returnHubButton.TextSize = 14
returnHubButton.Parent = actionsPanel
styleButton(returnHubButton, "secondary")
markInteractive(returnHubButton)

playAgainButton = Instance.new("TextButton")
playAgainButton.Position = UDim2.fromOffset(492, 390)
playAgainButton.Size = UDim2.fromOffset(124, 32)
playAgainButton.BackgroundColor3 = Color3.fromRGB(64, 156, 255)
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
rotatePieceButton.Position = UDim2.fromOffset(360, 352)
rotatePieceButton.Size = UDim2.fromOffset(124, 32)
rotatePieceButton.BackgroundColor3 = Color3.fromRGB(167, 109, 255)
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
rerollPieceButton.Position = UDim2.fromOffset(492, 352)
rerollPieceButton.Size = UDim2.fromOffset(124, 32)
rerollPieceButton.BackgroundColor3 = Color3.fromRGB(255, 112, 189)
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
resizeHandle.Parent = root
styleButton(resizeHandle, "secondary")
UITheme.stroke(resizeHandle, Color3.fromRGB(47, 199, 255), 3, 0.06)
markInteractive(resizeHandle)

local function clampNumber(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

clampWindowToScreen = function()
	local screenSize = gui.AbsoluteSize
	local topLeftInset, bottomRightInset = GuiService:GetGuiInset()
	local scale = rootScale and rootScale.Scale or 1
	local scaledSize = Vector2.new(root.Size.X.Offset * scale, root.Size.Y.Offset * scale)
	local halfWidth = scaledSize.X / 2
	local halfHeight = scaledSize.Y / 2
	local rawX = (screenSize.X * root.Position.X.Scale) + root.Position.X.Offset
	local rawY = (screenSize.Y * root.Position.Y.Scale) + root.Position.Y.Offset
	local minX = math.min(screenSize.X - 24, halfWidth + 16)
	local maxX = math.max(minX, screenSize.X - halfWidth - 16)
	local minY = math.min(screenSize.Y - 24, topLeftInset.Y + halfHeight + 16)
	local maxY = math.max(minY, screenSize.Y - bottomRightInset.Y - halfHeight - 16)

	root.Position = UDim2.fromOffset(clampNumber(rawX, minX, maxX), clampNumber(rawY, minY, maxY))
end

applyWindowLayout = function()
	local layout = WINDOW_LAYOUT
	local contentY = layout.outerPadding + layout.headerHeight + layout.headerGap
	local contentHeight = layout.height - contentY - layout.outerPadding
	local gridSize = layout.boardSize
	local boardPaddingPixels = layout.boardPadding
	local boardCellPadding = layout.boardGap
	local cellPixels = math.floor(
		(gridSize - (2 * boardPaddingPixels) - ((Config.BoardSize - 1) * boardCellPadding))
			/ Config.BoardSize
	)
	local usedBoardPixels = (cellPixels * Config.BoardSize)
		+ ((Config.BoardSize - 1) * boardCellPadding)
		+ (2 * boardPaddingPixels)
	local boardInset = math.floor((gridSize - usedBoardPixels) / 2)

	title.Visible = true
	title.Position = UDim2.fromOffset(20, 8)
	title.Size = UDim2.fromOffset(260, 30)
	title.TextSize = 22
	progressionLabel.Visible = true

	workspaceHeader.Position = UDim2.fromOffset(layout.outerPadding, layout.outerPadding)
	workspaceHeader.Size =
		UDim2.fromOffset(layout.width - (layout.outerPadding * 2), layout.headerHeight)
	workspaceContent.Position = UDim2.fromOffset(layout.outerPadding, contentY)
	workspaceContent.Size =
		UDim2.fromOffset(layout.width - (layout.outerPadding * 2), contentHeight)
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
	progressionLabel.Size = UDim2.fromOffset(440, 18)
	progressionLabel.TextSize = 12
	timerLabel.Visible = true
	timerLabel.AnchorPoint = Vector2.new(0, 0)
	timerLabel.Position = UDim2.fromOffset(376, 17)
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
	end
	if closeWorkspaceButton then
		closeWorkspaceButton.Position = UDim2.new(1, -22, 0, 12)
		closeWorkspaceButton.Size = UDim2.fromOffset(44, 36)
		closeWorkspaceButton.TextSize = 20
	end
	if resizeHandle then
		resizeHandle.Position = UDim2.new(1, -18, 1, -18)
		resizeHandle.Size = UDim2.fromOffset(50, 34)
	end

	scoreCard.Position = UDim2.fromOffset(0, 0)
	scoreCard.Size = UDim2.fromOffset(layout.leftWidth, 150)
	scoreLabel.Position = UDim2.fromOffset(14, 18)
	scoreLabel.Size = UDim2.new(1, -28, 0, 60)
	scoreLabel.TextSize = 48
	bestScoreLabel.Position = UDim2.fromOffset(18, 94)
	bestScoreLabel.Size = UDim2.new(1, -36, 0, 34)
	bestScoreLabel.TextSize = 20

	comboBadgeLabel.Position = UDim2.fromOffset(0, 150 + layout.statGap)
	comboBadgeLabel.Size = UDim2.fromOffset(layout.leftWidth, 104)
	comboBadgeLabel.TextSize = 28
	comboBadgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	comboBadgeLabel.TextTransparency = 0
	comboBadgeLabel.BackgroundTransparency = 0.02
	comboBadgeLabel.TextStrokeTransparency = 0.05
	coinStatLabel.Position = UDim2.fromOffset(0, 150 + layout.statGap + 104 + layout.statGap)
	coinStatLabel.Size = UDim2.fromOffset(layout.leftWidth, 86)
	coinStatLabel.TextSize = 26
	coinStatLabel.TextColor3 = Color3.fromRGB(255, 236, 160)
	coinStatLabel.TextTransparency = 0
	coinStatLabel.BackgroundTransparency = 0.02
	coinStatLabel.TextStrokeTransparency = 0.08
	rankStatLabel.Position =
		UDim2.fromOffset(0, 150 + layout.statGap + 104 + layout.statGap + 86 + layout.statGap)
	rankStatLabel.Size = UDim2.fromOffset(layout.leftWidth, 86)
	rankStatLabel.TextSize = 22
	rankStatLabel.TextColor3 = ArcadeUI.Color.gold
	rankStatLabel.TextTransparency = 0
	rankStatLabel.BackgroundTransparency = 0.02
	rankStatLabel.TextStrokeTransparency = 0.08

	boardFrame.Position = UDim2.fromOffset(boardInset, boardInset)
	boardFrame.Size = UDim2.fromOffset(usedBoardPixels, usedBoardPixels)
	boardGridContainer.Position = UDim2.fromScale(0, 0)
	boardGridContainer.Size = UDim2.fromScale(1, 1)
	boardLayout.CellSize = UDim2.fromOffset(cellPixels, cellPixels)
	boardLayout.CellPadding = UDim2.fromOffset(boardCellPadding, boardCellPadding)
	boardPadding.PaddingTop = UDim.new(0, boardPaddingPixels)
	boardPadding.PaddingBottom = UDim.new(0, boardPaddingPixels)
	boardPadding.PaddingLeft = UDim.new(0, boardPaddingPixels)
	boardPadding.PaddingRight = UDim.new(0, boardPaddingPixels)

	local sideWidth = layout.centerWidth
	side.Position = UDim2.fromOffset(0, 0)
	side.Size = UDim2.fromOffset(sideWidth, layout.trayHeight)
	statusLabel.Position = UDim2.fromOffset(18, 12)
	statusLabel.Size = UDim2.fromOffset(sideWidth - 36, 22)
	statusLabel.TextSize = 17
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left

	local slotHeight = 62
	for slot, button in handButtons do
		local buttonWidth =
			math.floor((sideWidth - 36 - ((Config.InventorySize - 1) * 14)) / Config.InventorySize)
		button.Position = UDim2.fromOffset(18 + (slot - 1) * (buttonWidth + 14), 38)
		button.Size = UDim2.fromOffset(buttonWidth, slotHeight)

		local preview = handPreviews[slot]
		preview.Size = UDim2.fromOffset(60, 60)
		preview.Position =
			UDim2.fromOffset(math.max(8, math.floor((buttonWidth - preview.Size.X.Offset) / 2)), 1)

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
		leaderboardLabel.Size = UDim2.fromOffset(layout.rightWidth, 378)
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

	actionsPanel.Position = UDim2.fromOffset(0, 378 + layout.actionGap)
	actionsPanel.Size = UDim2.fromOffset(layout.rightWidth, 112)

	local actionWidth = math.floor((layout.rightWidth - layout.actionGap) / 2)
	returnHubButton.Position = UDim2.fromOffset(0, 0)
	returnHubButton.Size = UDim2.fromOffset(actionWidth, 44)
	playAgainButton.Position = UDim2.fromOffset(actionWidth + layout.actionGap, 0)
	playAgainButton.Size = UDim2.fromOffset(actionWidth, 44)

	rotatePieceButton.Position = UDim2.fromOffset(0, 56)
	rotatePieceButton.Size = UDim2.fromOffset(actionWidth, 42)
	rerollPieceButton.Position = UDim2.fromOffset(actionWidth + layout.actionGap, 56)
	rerollPieceButton.Size = UDim2.fromOffset(actionWidth, 42)

	root.Size = UDim2.fromOffset(layout.width, layout.height)
end

returnHubButton.Activated:Connect(function()
	playSound("Button")
	queueEvent:FireServer("LeaveBattle")
end)

playAgainButton.Activated:Connect(function()
	playSound("Queue")
	queueEvent:FireServer("PlayAgain")
end)

local function requestSelectedHandAction(action)
	if not currentState or currentState.mode ~= "Custom" then
		showBanner("Custom Lab only", Color3.fromRGB(251, 146, 60))
		playSound("Blocked")
		return
	end

	if not selectedSlot or not currentState.hand or not currentState.hand[selectedSlot] then
		showBanner("Choose an active piece first", Color3.fromRGB(251, 146, 60))
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

local draggingWindow = false
local resizingWindow = false
local inputStartPosition = nil
local windowStartPosition = nil
local resizeStartScale = nil

local function stopWorkspaceInteraction()
	draggingWindow = false
	resizingWindow = false
	inputStartPosition = nil
	windowStartPosition = nil
	resizeStartScale = nil
end

local function startWorkspaceDrag(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not root.Visible then
		return
	end

	draggingWindow = true
	resizingWindow = false
	inputStartPosition = input.Position
	windowStartPosition = root.Position
end

local function startWorkspaceResize(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not root.Visible then
		return
	end

	resizingWindow = true
	draggingWindow = false
	inputStartPosition = input.Position
	windowStartPosition = root.Position
	resizeStartScale = workspaceScale
end

root.InputBegan:Connect(startWorkspaceDrag)
workspaceHeader.InputBegan:Connect(startWorkspaceDrag)
workspaceContent.InputBegan:Connect(startWorkspaceDrag)
leftColumn.InputBegan:Connect(startWorkspaceDrag)
centerColumn.InputBegan:Connect(startWorkspaceDrag)
rightColumn.InputBegan:Connect(startWorkspaceDrag)
boardStage.InputBegan:Connect(startWorkspaceDrag)
trayStage.InputBegan:Connect(startWorkspaceDrag)
actionsPanel.InputBegan:Connect(startWorkspaceDrag)
title.InputBegan:Connect(startWorkspaceDrag)
scoreCard.InputBegan:Connect(startWorkspaceDrag)
comboBadgeLabel.InputBegan:Connect(startWorkspaceDrag)
coinStatLabel.InputBegan:Connect(startWorkspaceDrag)
rankStatLabel.InputBegan:Connect(startWorkspaceDrag)
side.InputBegan:Connect(startWorkspaceDrag)
resizeHandle.InputBegan:Connect(startWorkspaceResize)

UserInputService.InputChanged:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseMovement then
		return
	end

	if draggingWindow and inputStartPosition and windowStartPosition then
		local delta = input.Position - inputStartPosition
		root.Position = UDim2.new(
			windowStartPosition.X.Scale,
			windowStartPosition.X.Offset + delta.X,
			windowStartPosition.Y.Scale,
			windowStartPosition.Y.Offset + delta.Y
		)
		clampWindowToScreen()
	elseif resizingWindow and inputStartPosition and resizeStartScale then
		local delta = input.Position - inputStartPosition
		local averageDelta = (delta.X + delta.Y) / 2
		local nextScale = resizeStartScale + (averageDelta / 520)
		workspaceScale = clampNumber(nextScale, MIN_WORKSPACE_SCALE, MAX_WORKSPACE_SCALE)
		applyUiScale()
		clampWindowToScreen()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		stopWorkspaceInteraction()
	end
end)

local function cloneBoard(board)
	local copy = {}

	for y = 1, Config.BoardSize do
		copy[y] = {}
		for x = 1, Config.BoardSize do
			copy[y][x] = board[y][x]
		end
	end

	return copy
end

local function playCellPop(x, y)
	if reducedMotion then
		return
	end

	local scale = cellScales[y] and cellScales[y][x]
	if not scale then
		return
	end

	scale.Scale = 0.72
	TweenService:Create(scale, QUICK_TWEEN, { Scale = 1 }):Play()
end

local function playClearFlash(x, y)
	if reducedMotion then
		return
	end

	local cell = cells[y] and cells[y][x]
	local scale = cellScales[y] and cellScales[y][x]
	if not cell or not scale then
		return
	end

	local originalColor = cell.BackgroundColor3
	cell.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	scale.Scale = 1.18
	TweenService
		:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = 1,
		})
		:Play()
	task.delay(0.12, function()
		if currentState and currentState.board[y][x] == false then
			cell.BackgroundColor3 = customization.boardEmptyColor
		else
			cell.BackgroundColor3 = originalColor
		end
	end)
end

local function shakeWindow()
	if reducedMotion then
		showBanner("That spot is blocked", Color3.fromRGB(224, 74, 74))
		return
	end

	local startPosition = root.Position
	TweenService:Create(root, TweenInfo.new(0.05), {
		Position = startPosition + UDim2.fromOffset(8, 0),
	}):Play()
	task.delay(0.06, function()
		TweenService:Create(root, TweenInfo.new(0.05), {
			Position = startPosition + UDim2.fromOffset(-8, 0),
		}):Play()
	end)
	task.delay(0.12, function()
		TweenService:Create(root, TweenInfo.new(0.06), {
			Position = startPosition,
		}):Play()
	end)
end

local function playBoardDiff(previous, nextBoard)
	if not previous then
		return
	end

	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			local oldValue = previous[y][x]
			local newValue = nextBoard[y][x]
			if oldValue == false and newValue ~= false then
				playCellPop(x, y)
			elseif oldValue ~= false and newValue == false then
				playClearFlash(x, y)
			end
		end
	end
end

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

renderBoard = function()
	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			local value = currentState.board[y][x]
			local cell = cells[y][x]
			if value == false then
				setCellGloss(cell, customization.boardEmptyColor, "empty")
			elseif value == "garbage" then
				setCellGloss(cell, Config.Colors.Garbage, "filled")
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
				stroke.Color = value == false and Color3.fromRGB(38, 61, 97)
					or Color3.fromRGB(255, 255, 255)
				stroke.Transparency = value == false and 0.2 or 0.55
			end
		end
	end

	updateStatusText()

	local shape = getSelectedShape()
	if not shape or not hoverX or not hoverY or not currentState.alive then
		return
	end

	local canPlace = Grid.canPlace(currentState.board, shape, hoverX, hoverY)
	statusLabel.Text = canPlace and `Place {shape.id}` or "That spot is blocked"

	for _, cell in shape.cells do
		local x = hoverX + cell.X
		local y = hoverY + cell.Y
		if x >= 1 and x <= Config.BoardSize and y >= 1 and y <= Config.BoardSize then
			local previewCell = cells[y][x]
			setCellGloss(
				previewCell,
				canPlace and shape.color or Config.Colors.PreviewInvalid,
				canPlace and "preview" or "invalid"
			)
			local stroke = previewCell:FindFirstChildOfClass("UIStroke")
			if stroke then
				stroke.Color = canPlace and Color3.fromRGB(255, 255, 255)
					or Color3.fromRGB(255, 105, 105)
				stroke.Transparency = 0.12
			end
		end
	end
end

local function clearPreview(preview)
	for _, child in preview:GetChildren() do
		child:Destroy()
	end
end

local function renderShapePreview(preview, shape)
	clearPreview(preview)

	if not shape then
		return
	end

	local minX = math.huge
	local maxX = -math.huge
	local minY = math.huge
	local maxY = -math.huge

	for _, cell in shape.cells do
		minX = math.min(minX, cell.X)
		maxX = math.max(maxX, cell.X)
		minY = math.min(minY, cell.Y)
		maxY = math.max(maxY, cell.Y)
	end

	local width = maxX - minX + 1
	local height = maxY - minY + 1
	local previewSize = math.max(44, math.min(preview.AbsoluteSize.X, preview.AbsoluteSize.Y))
	local tileSize = math.floor(math.min((previewSize - 6) / width, (previewSize - 6) / height))
	local offsetX = math.floor((previewSize - width * tileSize) / 2)
	local offsetY = math.floor((previewSize - height * tileSize) / 2)

	for _, cell in shape.cells do
		ArcadeUI.GlossyBlock(
			preview,
			shape.color,
			UDim2.fromOffset(tileSize - 3, tileSize - 3),
			UDim2.fromOffset(
				offsetX + (cell.X - minX) * tileSize,
				offsetY + (cell.Y - minY) * tileSize
			),
			"GlossyBlock"
		)
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

local function shapeText(shape)
	if not shape then
		return "Used"
	end

	return "Ready"
end

local function storyGoalText(state)
	local mission = state and state.storyMission
	if not mission then
		return nil
	end

	local targetLines = mission.targetLines or 0
	local targetScore = mission.targetScore or 0
	local currentLines = math.min(state.linesCleared or 0, targetLines)
	local currentScore = math.min(state.score or 0, targetScore)
	local chapterName = `Chapter {mission.chapter or 1}: {mission.name}`

	if targetLines > 0 and targetScore > 0 then
		return `{chapterName}: {currentLines}/{targetLines} lines, {currentScore}/{targetScore} score`
	elseif targetLines > 0 then
		return `{chapterName}: {currentLines}/{targetLines} lines`
	end

	return `{chapterName}: {currentScore}/{targetScore} score`
end

local function storyPreviewText(mission, storyStars)
	if typeof(mission) ~= "table" then
		return "Complete missions to unlock chapters"
	end

	local chapter = mission.chapter or 1
	local stars = storyStars or 0
	return `Chapter {chapter} | {mission.description or "Clear blocks and score"} | Stars {stars}`
end

renderHand = function()
	for slot, button in handButtons do
		local shape = currentState.hand[slot]
		local label = button:FindFirstChild("Label")
		if label then
			label.Text = shapeText(shape)
		end
		renderShapePreview(handPreviews[slot], shape)
		button.BackgroundColor3 = selectedSlot == slot and Color3.fromRGB(18, 71, 126)
			or shape and ArcadeUI.Color.inner
			or Color3.fromRGB(28, 34, 46)
		button.BackgroundTransparency = shape and 0 or 0.32
		local stroke = button:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = selectedSlot == slot and ArcadeUI.Color.rimBright
				or shape and Color3.fromRGB(33, 103, 177)
				or Color3.fromRGB(78, 84, 96)
			stroke.Thickness = selectedSlot == slot and 4 or 2
			stroke.Transparency = shape and 0.08 or 0.45
		end
	end
end

local function renderLeaderboard(leaderboard)
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
			rowStroke.Color = isLocalPlayer and ArcadeUI.Color.rimBright
				or index == 1 and ArcadeUI.Color.gold
				or index == 2 and ArcadeUI.Color.silver
				or index == 3 and ArcadeUI.Color.bronze
				or Color3.fromRGB(31, 90, 151)
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
			avatar.BackgroundColor3 = isLocalPlayer and Color3.fromRGB(254, 230, 122)
				or Color3.fromRGB(32, 73, 118)
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
			nameLabel.TextColor3 = isLocalPlayer and ArcadeUI.Color.gold or ArcadeUI.Color.text
		end

		local score = row:FindFirstChild("Score")
		if score and score:IsA("TextLabel") then
			score.Text = tostring(entry.score or 0)
			score.TextColor3 = index <= 3 and ArcadeUI.Color.gold or ArcadeUI.Color.best
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
			statRichText("TROPHY", currentRank and `RANK #{currentRank}` or "RANK --", "#FFC629")
		enforceStatTextContrast()
	end

	leaderboardLabel.Text = ""
end

local function renderProgression()
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local xp = leaderstats and leaderstats:FindFirstChild("XP")
	local level = leaderstats and leaderstats:FindFirstChild("Level")
	local storyStars = leaderstats and leaderstats:FindFirstChild("StoryStars")
	local cleared = currentState and currentState.linesCleared or 0
	local titleName = currentState
			and typeof(currentState.equippedCosmetics) == "table"
			and currentState.equippedCosmetics.title
		or "Rookie"

	progressionLabel.Text =
		`{titleName} | Level {level and level.Value or 1} | {coins and coins.Value or 0} coins | {xp and xp.Value or 0} XP | {storyStars and storyStars.Value or 0} stars | {cleared} cleared`
	if coinChipLabel then
		coinChipLabel.Text = `{coins and coins.Value or 0} Coins  +`
	end
	if coinStatLabel then
		coinStatLabel.Text = statRichText("COINS", tostring(coins and coins.Value or 0), "#FFECA0")
		enforceStatTextContrast()
	end
	if hudController then
		hudController:UpdateProgression()
	end
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
		stopWorkspaceInteraction()
		root.Visible = false
		rotatePieceButton.Visible = false
		rerollPieceButton.Visible = false
		if hudController then
			suppressExternalPuzzleHud(false)
			hudController:UpdateGameState(nil)
		end
		setHubPanelVisible(not hubManuallyClosed)
		updateTutorialVisibility()
		previousBoard = nil
		renderDiagnostics()
		return
	end

	if not root.Visible then
		root.Position = DEFAULT_WINDOW_POSITION
		root.Visible = true
		applyUiScale()
		clampWindowToScreen()
	end
	if hudController then
		hudController:UpdateGameState(currentState)
		suppressExternalPuzzleHud(true)
	end
	if currentState.alive then
		resultPanelController:Hide()
	end
	cosmeticPanelController:Hide()
	shopPanelController:Hide()
	storyPanelController:Hide()
	setHubPanelVisible(false)
	updateTutorialVisibility()
	title.Text = currentState.mode == "Story" and "STORY TRAINING"
		or currentState.mode == "Custom" and "CUSTOM LAB"
		or currentState.mode == "Solo" and "SOLO PUZZLE"
		or "BLOCK BLAST BATTLE"
	scoreLabel.Text = tostring(currentState.score)
	if bestScoreLabel then
		bestScoreLabel.Text = `BEST {currentState.bestScore or 0}`
	end
	if comboBadgeLabel then
		local combo = math.max(1, currentState.comboStreak or 1)
		comboBadgeLabel.Text = statRichText("COMBO", `x{combo}`, "#DA49FF")
		enforceStatTextContrast()
		comboBadgeLabel.Visible = combo > 1 or currentState.mode == "Solo"
	end
	matchInfoLabel.Text = currentState.mode == "Story"
			and (storyGoalText(currentState) or "Story Mission")
		or currentState.mode == "Custom" and "Rotate or reroll pieces before placement"
		or currentState.mode == "Solo" and `Best score: {currentState.bestScore or 0}`
		or `Arena {currentState.arenaIndex or "--"} | Match {currentState.sessionId or "--"}`
	timerLabel.Text = currentState.timeLeft
			and currentState.suddenDeath
			and `Sudden: {currentState.timeLeft}s`
		or currentState.timeLeft and `Time: {currentState.timeLeft}s`
		or "Time: --"
	timerLabel.TextColor3 = currentState.suddenDeath and Color3.fromRGB(255, 110, 110)
		or currentState.timeLeft and currentState.timeLeft <= 15 and Color3.fromRGB(255, 207, 102)
		or Color3.fromRGB(193, 201, 215)
	playAgainButton.Text = currentState.mode == "Story" and "Replay" or "Play Again"
	playAgainButton.Visible = not currentState.alive and currentState.mode ~= "Custom"
	rotatePieceButton.Visible = currentState.mode == "Custom" and currentState.alive
	rerollPieceButton.Visible = currentState.mode == "Custom" and currentState.alive

	selectFirstAvailablePiece()

	renderBoard()
	playBoardDiff(oldBoard, currentState.board)
	renderHand()
	renderLeaderboard(leaderboard)
	renderProgression()
	renderDiagnostics()
	previousBoard = cloneBoard(currentState.board)
end)

task.spawn(function()
	local leaderstats = player:WaitForChild("leaderstats", 10)
	if leaderstats then
		for _, stat in leaderstats:GetChildren() do
			if stat:IsA("IntValue") then
				stat.Changed:Connect(function()
					renderProgression()
					updateSettingsButtonText()
				end)
			end
		end
		leaderstats.ChildAdded:Connect(function(child)
			if child:IsA("IntValue") then
				child.Changed:Connect(function()
					renderProgression()
					updateSettingsButtonText()
				end)
				renderProgression()
				updateSettingsButtonText()
			end
		end)
		renderProgression()
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
			storyPreviewText(hubState.storyMission, hubState.storyStars),
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

effectsEvent.OnClientEvent:Connect(function(effect)
	if not effect then
		return
	end

	if effect.kind == "InvalidPlace" then
		playSound("Blocked")
		shakeWindow()
		showBanner(effect.message or "That spot is blocked", Color3.fromRGB(224, 74, 74))
	elseif effect.kind == "Place" then
		playSound("Place")
		if effect.shape then
			for _, cell in effect.shape.cells do
				playCellPop(effect.originX + cell.X, effect.originY + cell.Y)
			end
		end
		if effect.linesCleared and effect.linesCleared > 0 then
			playSound("Clear")
			if effect.comboStreak and effect.comboStreak > 1 then
				showBanner(
					`Combo x{effect.comboStreak}! +{effect.comboBonus or 0}`,
					Color3.fromRGB(255, 207, 102)
				)
			elseif effect.lineClearEffect == "Ripple" then
				showBanner(
					`Ripple clear: {effect.linesCleared} line(s)!`,
					Color3.fromRGB(64, 156, 255)
				)
			else
				showBanner(`Cleared {effect.linesCleared} line(s)!`, Color3.fromRGB(74, 222, 128))
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
		showBanner(effect.message or "Piece updated", Color3.fromRGB(255, 112, 189))
	elseif effect.kind == "SuddenDeath" then
		playSound("Blocked")
		showBanner(
			effect.detail or effect.message or "Sudden death!",
			Color3.fromRGB(255, 110, 110)
		)
	elseif effect.kind == "SuddenDeathPressure" then
		playSound("Blocked")
		showBanner(effect.message or "Pressure row rising", Color3.fromRGB(251, 146, 60))
	elseif effect.kind == "BattleResult" then
		playSound("Result")
		resultPanelController:Show(effect.result, effect.message, effect.won)
		showBanner(
			effect.message or "Run complete",
			effect.won and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(251, 146, 60)
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
