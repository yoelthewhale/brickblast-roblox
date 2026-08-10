local Players = game:GetService("Players")
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
local coinChipLabel = nil
local timerLabel = nil
local progressionLabel = nil
local matchInfoLabel = nil
local statusLabel = nil
local leaderboardLabel = nil
local customizeButton = nil
local returnHubButton = nil
local playAgainButton = nil
local rotatePieceButton = nil
local rerollPieceButton = nil
local minimizeButton = nil
local resetLayoutButton = nil
local resizeHandle = nil
local battleDock = nil
local dockStatusLabel = nil
local openBoardButton = nil
local dockReturnButton = nil
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
local dockScale = nil
local bannerScale = nil
local clampWindowToScreen = nil
local applyWindowLayout = nil
local applyBoardSkin = nil
local renderBoard = nil
local renderHand = nil
local renderDiagnostics = nil
local pulseHandSlot = nil

local DEFAULT_WINDOW_POSITION = UDim2.new(0.5, -500, 0.5, 0)
local DEFAULT_WINDOW_SIZE = Vector2.new(1000, 650)
local MIN_WINDOW_SIZE = Vector2.new(380, 540)
local MAX_WINDOW_SIZE = Vector2.new(1240, 820)
local COMPACT_WINDOW_WIDTH = 700
local QUICK_TWEEN = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local SOFT_TWEEN = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local function isUiReducedMotion()
	return reducedMotion
end

local function styleButton(button, variant)
	UITheme.button(button, variant)
	UITheme.attachButtonFeedback(button, isUiReducedMotion)
	return button
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
	if root and screenSize.X < 620 and root.Size.X.Offset > COMPACT_WINDOW_WIDTH then
		local compactWidth =
			math.clamp(screenSize.X - 24, MIN_WINDOW_SIZE.X, COMPACT_WINDOW_WIDTH - 1)
		local compactHeight = math.clamp(screenSize.Y - 64, MIN_WINDOW_SIZE.Y, MAX_WINDOW_SIZE.Y)
		root.Size = UDim2.fromOffset(compactWidth, compactHeight)
		if applyWindowLayout then
			applyWindowLayout()
		end
	end

	local automaticScale = 1
	if screenSize.X < 720 or screenSize.Y < 560 then
		automaticScale = 0.86
	elseif screenSize.X < 980 then
		automaticScale = 0.88
	end

	local rootFitScale = math.min(1, (screenSize.X - 16) / math.max(1, root.Size.X.Offset))
	local dockFitScale = math.min(1, (screenSize.X - 16) / 260)
	local nextScale = automaticScale * uiScale
	if rootScale then
		rootScale.Scale = math.clamp(math.min(nextScale, rootFitScale), 0.72, 1.12)
	end
	if homePanelController then
		homePanelController:RefreshResponsiveLayout(screenSize, nextScale)
	end
	if dockScale then
		dockScale.Scale = math.clamp(math.min(nextScale, dockFitScale), 0.78, 1.12)
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
				battleDock.Visible = false
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
root.AnchorPoint = Vector2.new(0, 0.5)
root.Position = DEFAULT_WINDOW_POSITION
root.Size = UDim2.fromOffset(DEFAULT_WINDOW_SIZE.X, DEFAULT_WINDOW_SIZE.Y)
root.BackgroundColor3 = Color3.fromRGB(10, 17, 34)
root.BackgroundTransparency = 0.12
root.BorderSizePixel = 0
root.Visible = false
root.Parent = gui
UITheme.panel(root, {
	color = Color3.fromRGB(8, 18, 35),
	bottomColor = Color3.fromRGB(5, 10, 20),
	strokeColor = Color3.fromRGB(47, 199, 255),
	strokeTransparency = 0.16,
	radius = 34,
})
root.BackgroundTransparency = 0.28
local rootStroke = root:FindFirstChildOfClass("UIStroke")
if rootStroke then
	rootStroke.Thickness = 6
end

rootScale = Instance.new("UIScale")
rootScale.Scale = 1
rootScale.Parent = root

battleDock = Instance.new("Frame")
battleDock.Position = UDim2.fromOffset(18, 88)
battleDock.Size = UDim2.fromOffset(260, 116)
battleDock.BackgroundColor3 = Color3.fromRGB(13, 22, 43)
battleDock.BackgroundTransparency = 0.02
battleDock.BorderSizePixel = 0
battleDock.Visible = false
battleDock.Parent = gui
UITheme.panel(battleDock, {
	color = Color3.fromRGB(13, 22, 43),
	bottomColor = Color3.fromRGB(7, 12, 25),
	strokeColor = Color3.fromRGB(48, 190, 255),
	strokeTransparency = 0.04,
})

dockScale = Instance.new("UIScale")
dockScale.Scale = 1
dockScale.Parent = battleDock

dockStatusLabel = Instance.new("TextLabel")
dockStatusLabel.BackgroundTransparency = 1
dockStatusLabel.Position = UDim2.fromOffset(14, 10)
dockStatusLabel.Size = UDim2.fromOffset(232, 36)
dockStatusLabel.Font = Enum.Font.GothamBold
dockStatusLabel.Text = "Solo run active"
dockStatusLabel.TextColor3 = Color3.fromRGB(245, 247, 251)
dockStatusLabel.TextSize = 16
dockStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
dockStatusLabel.TextWrapped = true
dockStatusLabel.Parent = battleDock

openBoardButton = Instance.new("TextButton")
openBoardButton.Position = UDim2.fromOffset(14, 58)
openBoardButton.Size = UDim2.fromOffset(110, 38)
openBoardButton.BackgroundColor3 = Color3.fromRGB(64, 156, 255)
openBoardButton.BorderSizePixel = 0
openBoardButton.Font = Enum.Font.GothamBold
openBoardButton.Text = "Open Board"
openBoardButton.TextColor3 = Color3.fromRGB(255, 255, 255)
openBoardButton.TextSize = 14
openBoardButton.Parent = battleDock
styleButton(openBoardButton, "primary")

dockReturnButton = Instance.new("TextButton")
dockReturnButton.Position = UDim2.fromOffset(136, 58)
dockReturnButton.Size = UDim2.fromOffset(110, 38)
dockReturnButton.BackgroundColor3 = Color3.fromRGB(45, 58, 82)
dockReturnButton.BorderSizePixel = 0
dockReturnButton.Font = Enum.Font.GothamBold
dockReturnButton.Text = "Return Hub"
dockReturnButton.TextColor3 = Color3.fromRGB(245, 247, 251)
dockReturnButton.TextSize = 14
dockReturnButton.Parent = battleDock
styleButton(dockReturnButton, "secondary")

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
customizeButton.Parent = root
styleButton(customizeButton, "primary")

minimizeButton = Instance.new("TextButton")
minimizeButton.AnchorPoint = Vector2.new(1, 0)
minimizeButton.Position = UDim2.new(1, -172, 0, 16)
minimizeButton.Size = UDim2.fromOffset(86, 34)
minimizeButton.BackgroundColor3 = Color3.fromRGB(45, 58, 82)
minimizeButton.BorderSizePixel = 0
minimizeButton.Font = Enum.Font.GothamBold
minimizeButton.Text = "Hide"
minimizeButton.TextColor3 = Color3.fromRGB(245, 247, 251)
minimizeButton.TextSize = 14
minimizeButton.Parent = root
styleButton(minimizeButton, "secondary")

resetLayoutButton = Instance.new("TextButton")
resetLayoutButton.AnchorPoint = Vector2.new(1, 0)
resetLayoutButton.Position = UDim2.new(1, -266, 0, 16)
resetLayoutButton.Size = UDim2.fromOffset(86, 34)
resetLayoutButton.BackgroundColor3 = Color3.fromRGB(45, 58, 82)
resetLayoutButton.BorderSizePixel = 0
resetLayoutButton.Font = Enum.Font.GothamBold
resetLayoutButton.Text = "Reset"
resetLayoutButton.TextColor3 = Color3.fromRGB(245, 247, 251)
resetLayoutButton.TextSize = 14
resetLayoutButton.Parent = root
styleButton(resetLayoutButton, "secondary")

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
	battleDock.BackgroundColor3 = theme.panel
	openBoardButton.BackgroundColor3 = theme.accent
	customizeButton.BackgroundColor3 = theme.accent
	if homePanelController then
		homePanelController:ApplyTheme(theme)
	end
	resetLayoutButton.BackgroundColor3 = Color3.fromRGB(45, 58, 82)
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

local function setBattleBoardVisible(visible)
	root.Visible = visible
	battleDock.Visible = currentState ~= nil and not visible
	setHubPanelVisible(currentState == nil and not hubManuallyClosed)
end

minimizeButton.Activated:Connect(function()
	playSound("Button")
	setBattleBoardVisible(false)
end)

openBoardButton.Activated:Connect(function()
	playSound("Button")
	setBattleBoardVisible(true)
end)

dockReturnButton.Activated:Connect(function()
	playSound("Button")
	queueEvent:FireServer("LeaveBattle")
end)

local title = Instance.new("TextButton")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(24, 18)
title.Size = UDim2.fromOffset(210, 36)
title.AutoButtonColor = false
title.Font = Enum.Font.GothamBold
title.Text = "Solo Puzzle"
title.TextColor3 = Color3.fromRGB(245, 247, 251)
title.TextSize = 22
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = root
UITheme.text(title, "title")

local scoreCard = Instance.new("Frame")
scoreCard.Name = "ScoreCard"
scoreCard.Position = UDim2.fromOffset(22, 72)
scoreCard.Size = UDim2.fromOffset(210, 170)
scoreCard.Parent = root
UITheme.panel(scoreCard, {
	color = Color3.fromRGB(12, 28, 52),
	bottomColor = Color3.fromRGB(5, 14, 30),
	strokeColor = Color3.fromRGB(35, 173, 244),
	strokeTransparency = 0.04,
	strokeThickness = 4,
	radius = 20,
})

scoreLabel = Instance.new("TextLabel")
scoreLabel.BackgroundTransparency = 1
scoreLabel.Position = UDim2.fromOffset(14, 16)
scoreLabel.Size = UDim2.new(1, -28, 0, 58)
scoreLabel.Font = Enum.Font.GothamBlack
scoreLabel.Text = "0"
scoreLabel.TextColor3 = Color3.fromRGB(255, 222, 72)
scoreLabel.TextSize = 50
scoreLabel.TextXAlignment = Enum.TextXAlignment.Center
scoreLabel.TextStrokeColor3 = Color3.fromRGB(42, 28, 10)
scoreLabel.TextStrokeTransparency = 0.35
scoreLabel.Parent = scoreCard

bestScoreLabel = Instance.new("TextLabel")
bestScoreLabel.BackgroundTransparency = 1
bestScoreLabel.Position = UDim2.fromOffset(18, 82)
bestScoreLabel.Size = UDim2.new(1, -36, 0, 34)
bestScoreLabel.Font = Enum.Font.GothamBlack
bestScoreLabel.Text = "BEST 0"
bestScoreLabel.TextColor3 = Color3.fromRGB(63, 205, 255)
bestScoreLabel.TextSize = 20
bestScoreLabel.TextXAlignment = Enum.TextXAlignment.Center
bestScoreLabel.Parent = scoreCard

comboBadgeLabel = Instance.new("TextLabel")
comboBadgeLabel.BackgroundTransparency = 0.08
comboBadgeLabel.BackgroundColor3 = Color3.fromRGB(118, 45, 220)
comboBadgeLabel.Position = UDim2.fromOffset(22, 232)
comboBadgeLabel.Size = UDim2.fromOffset(210, 108)
comboBadgeLabel.Font = Enum.Font.GothamBlack
comboBadgeLabel.Text = "COMBO\nx1"
comboBadgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
comboBadgeLabel.TextSize = 28
comboBadgeLabel.TextStrokeColor3 = Color3.fromRGB(31, 9, 69)
comboBadgeLabel.TextStrokeTransparency = 0.2
comboBadgeLabel.Parent = root
UITheme.corner(comboBadgeLabel, 22)
UITheme.stroke(comboBadgeLabel, Color3.fromRGB(244, 212, 255), 4, 0.03)

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
coinChipLabel.Parent = root
UITheme.corner(coinChipLabel, 18)
UITheme.stroke(coinChipLabel, Color3.fromRGB(34, 173, 244), 3, 0.08)

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
timerLabel.Parent = root
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
progressionLabel.Parent = root
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
matchInfoLabel.Parent = root
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
boardFrame.Position = UDim2.fromOffset(24, 104)
boardFrame.Size = UDim2.fromOffset(304, 304)
boardFrame.BackgroundColor3 = Color3.fromRGB(8, 23, 45)
boardFrame.BackgroundTransparency = 0
boardFrame.Parent = root
UITheme.corner(boardFrame, 24)
UITheme.stroke(boardFrame, Color3.fromRGB(39, 178, 255), 7, 0.02)
UITheme.gradient(boardFrame, Color3.fromRGB(14, 35, 68), Color3.fromRGB(4, 13, 28), 90)
local boardPadding = Instance.new("UIPadding")
boardPadding.PaddingTop = UDim.new(0, 16)
boardPadding.PaddingBottom = UDim.new(0, 16)
boardPadding.PaddingLeft = UDim.new(0, 16)
boardPadding.PaddingRight = UDim.new(0, 16)
boardPadding.Parent = boardFrame

local boardLayout = Instance.new("UIGridLayout")
boardLayout.CellSize = UDim2.fromOffset(35, 35)
boardLayout.CellPadding = UDim2.fromOffset(3, 3)
boardLayout.SortOrder = Enum.SortOrder.LayoutOrder
boardLayout.Parent = boardFrame

for y = 1, Config.BoardSize do
	for x = 1, Config.BoardSize do
		local button = Instance.new("TextButton")
		button.Name = `{x}_{y}`
		button.LayoutOrder = (y - 1) * Config.BoardSize + x
		button.BackgroundColor3 = Config.Colors.Empty
		button.BorderSizePixel = 0
		button.Text = ""
		button.AutoButtonColor = false
		button.Parent = boardFrame
		UITheme.corner(button, 8)
		UITheme.stroke(button, Color3.fromRGB(36, 59, 94), 2, 0.12)
		UITheme.gradient(button, Color3.fromRGB(31, 43, 66), Color3.fromRGB(13, 24, 45), 90)

		local scale = Instance.new("UIScale")
		scale.Scale = 1
		scale.Parent = button

		cells[y] = cells[y] or {}
		cells[y][x] = button
		cellScales[y] = cellScales[y] or {}
		cellScales[y][x] = scale

		button.Activated:Connect(function()
			if currentState and selectedSlot then
				local shape = currentState.hand[selectedSlot]
				if shape and Grid.canPlace(currentState.board, shape, x, y) then
					playSound("Place")
					placeEvent:FireServer(selectedSlot, x, y)
				elseif shape then
					statusLabel.Text = "That spot is blocked"
					playSound("Blocked")
					showBanner("That spot is blocked", Color3.fromRGB(224, 74, 74))
				end
			end
		end)

		button.MouseEnter:Connect(function()
			hoverX = x
			hoverY = y
			if currentState then
				renderBoard()
			end
		end)

		button.MouseLeave:Connect(function()
			if hoverX == x and hoverY == y then
				hoverX = nil
				hoverY = nil
				if currentState then
					renderBoard()
				end
			end
		end)
	end
end

local side = Instance.new("Frame")
side.Position = UDim2.fromOffset(360, 104)
side.Size = UDim2.fromOffset(256, 304)
side.BackgroundColor3 = Color3.fromRGB(8, 23, 45)
side.BackgroundTransparency = 0.02
side.Parent = root
UITheme.corner(side, 26)
UITheme.stroke(side, Color3.fromRGB(39, 178, 255), 5, 0.04)
UITheme.gradient(side, Color3.fromRGB(11, 31, 59), Color3.fromRGB(4, 13, 28), 90)

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
	styleButton(button, "secondary")
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
leaderboardLabel.BackgroundColor3 = Color3.fromRGB(10, 27, 52)
leaderboardLabel.BackgroundTransparency = 0.05
leaderboardLabel.Position = UDim2.fromOffset(0, 242)
leaderboardLabel.Size = UDim2.fromOffset(256, 56)
leaderboardLabel.Font = Enum.Font.GothamBlack
leaderboardLabel.TextColor3 = Color3.fromRGB(245, 247, 251)
leaderboardLabel.TextSize = 16
leaderboardLabel.TextXAlignment = Enum.TextXAlignment.Left
leaderboardLabel.TextYAlignment = Enum.TextYAlignment.Top
leaderboardLabel.Parent = root
UITheme.text(leaderboardLabel, "muted")
UITheme.corner(leaderboardLabel, 18)
UITheme.stroke(leaderboardLabel, Color3.fromRGB(39, 178, 255), 4, 0.08)
UITheme.gradient(leaderboardLabel, Color3.fromRGB(12, 31, 57), Color3.fromRGB(6, 14, 29), 90)

returnHubButton = Instance.new("TextButton")
returnHubButton.Position = UDim2.fromOffset(360, 390)
returnHubButton.Size = UDim2.fromOffset(124, 32)
returnHubButton.BackgroundColor3 = Color3.fromRGB(45, 58, 82)
returnHubButton.BorderSizePixel = 0
returnHubButton.Font = Enum.Font.GothamBold
returnHubButton.Text = "Return Hub"
returnHubButton.TextColor3 = Color3.fromRGB(245, 247, 251)
returnHubButton.TextSize = 14
returnHubButton.Parent = root
styleButton(returnHubButton, "secondary")

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
playAgainButton.Parent = root
styleButton(playAgainButton, "primary")

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
rotatePieceButton.Parent = root
styleButton(rotatePieceButton, "primary")

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
rerollPieceButton.Parent = root
styleButton(rerollPieceButton, "primary")

resizeHandle = Instance.new("TextButton")
resizeHandle.AnchorPoint = Vector2.new(1, 1)
resizeHandle.Position = UDim2.new(1, -12, 1, -10)
resizeHandle.Size = UDim2.fromOffset(72, 24)
resizeHandle.BackgroundColor3 = Color3.fromRGB(31, 38, 52)
resizeHandle.BorderSizePixel = 0
resizeHandle.Font = Enum.Font.GothamBold
resizeHandle.Text = "Resize"
resizeHandle.TextColor3 = Color3.fromRGB(245, 247, 251)
resizeHandle.TextSize = 12
resizeHandle.Parent = root
styleButton(resizeHandle, "secondary")

local function clampNumber(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

clampWindowToScreen = function()
	local screenSize = gui.AbsoluteSize
	local windowSize = root.AbsoluteSize
	local xOffset =
		clampNumber(root.Position.X.Offset, 8, math.max(8, screenSize.X - windowSize.X - 8))
	local yCenter = (screenSize.Y * root.Position.Y.Scale) + root.Position.Y.Offset
	local yOffset =
		clampNumber(yCenter, 24 + (windowSize.Y / 2), screenSize.Y - 24 - (windowSize.Y / 2))
	root.Position = UDim2.new(0, xOffset, 0, yOffset)
end

applyWindowLayout = function()
	local windowSize = root.AbsoluteSize
	local width = windowSize.X
	local height = windowSize.Y
	local compact = width < COMPACT_WINDOW_WIDTH
	local leftPadding = compact and 14 or 24
	local topPadding = compact and 118 or 72
	local gap = compact and 12 or 20
	local scoreColumnWidth = compact and 0 or 220
	local leaderboardWidth = compact and 0 or 230
	local trayHeight = compact and 156 or 128
	local boardLimitByHeight = compact and (height - topPadding - trayHeight - 78)
		or (height - topPadding - trayHeight - 70)
	local boardLimitByWidth = compact and (width - (leftPadding * 2))
		or (width - scoreColumnWidth - leaderboardWidth - (leftPadding * 2) - gap * 2)
	local boardPixels = clampNumber(
		math.min(boardLimitByHeight, boardLimitByWidth),
		compact and 300 or 420,
		compact and 520 or 520
	)
	local innerBoardPixels = boardPixels - 32
	local cellPixels =
		math.floor((innerBoardPixels - ((Config.BoardSize - 1) * 4)) / Config.BoardSize)
	innerBoardPixels = (cellPixels * Config.BoardSize) + ((Config.BoardSize - 1) * 4)
	boardPixels = innerBoardPixels + 32

	local boardX = compact and math.floor((width - boardPixels) / 2)
		or leftPadding + scoreColumnWidth + gap
	local boardY = topPadding
	boardFrame.Position = UDim2.fromOffset(boardX, boardY)
	boardFrame.Size = UDim2.fromOffset(boardPixels, boardPixels)
	boardLayout.CellSize = UDim2.fromOffset(cellPixels, cellPixels)
	boardLayout.CellPadding = UDim2.fromOffset(4, 4)

	title.Visible = not compact
	progressionLabel.Visible = not compact
	timerLabel.Visible = not compact
	matchInfoLabel.Visible = not compact

	if scoreCard then
		scoreCard.Position = compact and UDim2.new(0.5, -160, 0, 22) or UDim2.fromOffset(22, 118)
		scoreCard.Size = compact and UDim2.fromOffset(320, 84) or UDim2.fromOffset(210, 174)
	end
	scoreLabel.Position = compact and UDim2.fromOffset(14, 10) or UDim2.fromOffset(14, 18)
	scoreLabel.Size = compact and UDim2.new(1, -28, 0, 46) or UDim2.new(1, -28, 0, 66)
	scoreLabel.TextSize = compact and 48 or 52
	if bestScoreLabel then
		bestScoreLabel.Position = compact and UDim2.fromOffset(18, 54) or UDim2.fromOffset(18, 94)
		bestScoreLabel.TextSize = compact and 18 or 20
	end
	if coinChipLabel then
		coinChipLabel.Position = compact and UDim2.fromOffset(16, 20) or UDim2.new(1, -190, 0, 20)
		coinChipLabel.AnchorPoint = compact and Vector2.new(0, 0) or Vector2.new(1, 0)
		coinChipLabel.Size = compact and UDim2.fromOffset(104, 42) or UDim2.fromOffset(170, 50)
		coinChipLabel.TextSize = compact and 14 or 20
	end

	local sideX = compact and leftPadding or boardX
	local sideY = compact and boardY + boardPixels + gap or boardY + boardPixels + gap
	local sideWidth = compact and width - (leftPadding * 2) or boardPixels
	local sideHeight = trayHeight
	side.Position = UDim2.fromOffset(sideX, sideY)
	side.Size = UDim2.fromOffset(sideWidth, sideHeight)
	statusLabel.Position = UDim2.fromOffset(compact and 12 or 18, compact and 10 or 12)
	statusLabel.Size = UDim2.fromOffset(sideWidth - (compact and 24 or 36), 28)
	statusLabel.TextSize = compact and 15 or 20
	statusLabel.TextXAlignment = compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left

	if bestScoreLabel then
		bestScoreLabel.Visible = true
	end
	if comboBadgeLabel then
		comboBadgeLabel.Position = compact and UDim2.new(1, -148, 0, 23)
			or UDim2.fromOffset(22, 318)
		comboBadgeLabel.Size = compact and UDim2.fromOffset(130, 76) or UDim2.fromOffset(210, 108)
		comboBadgeLabel.TextSize = compact and 22 or 30
	end

	local slotHeight = compact and 104 or 78
	for slot, button in handButtons do
		local buttonWidth =
			math.floor((sideWidth - 32 - ((Config.InventorySize - 1) * 14)) / Config.InventorySize)
		button.Position =
			UDim2.fromOffset(16 + (slot - 1) * (buttonWidth + 14), compact and 42 or 44)
		button.Size = UDim2.fromOffset(buttonWidth, slotHeight)

		local preview = handPreviews[slot]
		preview.Size = compact and UDim2.fromOffset(74, 74) or UDim2.fromOffset(58, 58)
		preview.Position = UDim2.fromOffset(
			math.max(6, math.floor((buttonWidth - preview.Size.X.Offset) / 2)),
			compact and 8 or 8
		)

		local label = button:FindFirstChild("Label")
		if label and label:IsA("TextLabel") then
			label.Position = UDim2.fromOffset(4, compact and 80 or 64)
			label.Size = UDim2.fromOffset(math.max(60, buttonWidth - 8), compact and 18 or 16)
			label.TextSize = compact and 11 or 12
			label.TextXAlignment = Enum.TextXAlignment.Center
		end
	end

	if leaderboardLabel then
		leaderboardLabel.Visible = true
		if compact then
			leaderboardLabel.Position = UDim2.fromOffset(leftPadding, sideY + sideHeight + 10)
			leaderboardLabel.Size = UDim2.fromOffset(width - (leftPadding * 2), 48)
			leaderboardLabel.TextSize = 13
		else
			leaderboardLabel.Position = UDim2.fromOffset(boardX + boardPixels + gap, 118)
			leaderboardLabel.Size = UDim2.fromOffset(leaderboardWidth, 310)
			leaderboardLabel.TextSize = 16
		end
	end

	local bottomY = compact and height - 42 or 448
	local actionWidth = compact and math.floor((width - (leftPadding * 2) - 8) / 2)
		or math.floor((leaderboardWidth - 8) / 2)
	returnHubButton.Position =
		UDim2.fromOffset(compact and leftPadding or boardX + boardPixels + gap, bottomY)
	returnHubButton.Size = UDim2.fromOffset(actionWidth, 32)
	playAgainButton.Position = UDim2.fromOffset(
		(compact and leftPadding or boardX + boardPixels + gap) + actionWidth + 8,
		bottomY
	)
	playAgainButton.Size = UDim2.fromOffset(actionWidth, 32)

	local customY = bottomY - 38
	rotatePieceButton.Position =
		UDim2.fromOffset(compact and leftPadding or boardX + boardPixels + gap, customY)
	rotatePieceButton.Size = UDim2.fromOffset(actionWidth, 32)
	rerollPieceButton.Position = UDim2.fromOffset(
		(compact and leftPadding or boardX + boardPixels + gap) + actionWidth + 8,
		customY
	)
	rerollPieceButton.Size = UDim2.fromOffset(actionWidth, 32)
	resizeHandle.Position = UDim2.new(1, -12, 1, -10)
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

resetLayoutButton.Activated:Connect(function()
	playSound("Button")
	root.Position = DEFAULT_WINDOW_POSITION
	root.Size = UDim2.fromOffset(DEFAULT_WINDOW_SIZE.X, DEFAULT_WINDOW_SIZE.Y)
	applyUiScale()
	applyWindowLayout()
end)

local draggingWindow = false
local resizingWindow = false
local inputStartPosition = nil
local windowStartPosition = nil
local windowStartSize = nil

title.InputBegan:Connect(function(input)
	if
		input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch
	then
		return
	end

	draggingWindow = true
	inputStartPosition = input.Position
	windowStartPosition = root.Position
end)

resizeHandle.InputBegan:Connect(function(input)
	if
		input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch
	then
		return
	end

	resizingWindow = true
	inputStartPosition = input.Position
	windowStartSize = root.AbsoluteSize
end)

UserInputService.InputChanged:Connect(function(input)
	if
		input.UserInputType ~= Enum.UserInputType.MouseMovement
		and input.UserInputType ~= Enum.UserInputType.Touch
	then
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
	elseif resizingWindow and inputStartPosition and windowStartSize then
		local delta = input.Position - inputStartPosition
		local nextWidth =
			clampNumber(windowStartSize.X + delta.X, MIN_WINDOW_SIZE.X, MAX_WINDOW_SIZE.X)
		local nextHeight =
			clampNumber(windowStartSize.Y + delta.Y, MIN_WINDOW_SIZE.Y, MAX_WINDOW_SIZE.Y)
		root.Size = UDim2.fromOffset(nextWidth, nextHeight)
		applyWindowLayout()
		clampWindowToScreen()
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if
		input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch
	then
		return
	end

	draggingWindow = false
	resizingWindow = false
	inputStartPosition = nil
	windowStartPosition = nil
	windowStartSize = nil
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

renderBoard = function()
	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			local value = currentState.board[y][x]
			local cell = cells[y][x]
			if value == false then
				cell.BackgroundColor3 = customization.boardEmptyColor
			elseif value == "garbage" then
				cell.BackgroundColor3 = Config.Colors.Garbage
			elseif typeof(value) == "Color3" then
				cell.BackgroundColor3 = value
			else
				cell.BackgroundColor3 = Config.Colors.Filled
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
			cells[y][x].BackgroundColor3 = canPlace and shape.color or Config.Colors.PreviewInvalid
			local stroke = cells[y][x]:FindFirstChildOfClass("UIStroke")
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
		local tile = Instance.new("Frame")
		tile.Size = UDim2.fromOffset(tileSize - 3, tileSize - 3)
		tile.Position = UDim2.fromOffset(
			offsetX + (cell.X - minX) * tileSize,
			offsetY + (cell.Y - minY) * tileSize
		)
		tile.BackgroundColor3 = shape.color
		tile.BorderSizePixel = 0
		tile.Parent = preview
		UITheme.corner(tile, 5)
		UITheme.stroke(tile, shape.color:Lerp(Color3.fromRGB(255, 255, 255), 0.4), 1, 0.25)
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

	return `{shape.id} ({#shape.cells} blocks)`
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
		button.BackgroundColor3 = selectedSlot == slot and customization.accentColor
			or Color3.fromRGB(31, 38, 52)
	end
end

local function renderLeaderboard(leaderboard)
	local lines = { "SERVER TOP" }

	for index, entry in leaderboard do
		if index > 7 then
			break
		end
		local name = entry.name or "Player"
		table.insert(lines, `#{index} {name}: {entry.score or 0}`)
	end

	if #lines == 1 then
		table.insert(lines, "Start a run to rank here")
	end

	leaderboardLabel.Text = table.concat(lines, "\n")
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
		root.Visible = false
		battleDock.Visible = false
		rotatePieceButton.Visible = false
		rerollPieceButton.Visible = false
		if hudController then
			hudController:UpdateGameState(nil)
		end
		setHubPanelVisible(not hubManuallyClosed)
		updateTutorialVisibility()
		previousBoard = nil
		renderDiagnostics()
		return
	end

	if not root.Visible and not battleDock.Visible then
		root.Visible = true
	end
	if hudController then
		hudController:UpdateGameState(currentState)
	end
	if currentState.alive then
		resultPanelController:Hide()
	end
	cosmeticPanelController:Hide()
	shopPanelController:Hide()
	storyPanelController:Hide()
	setHubPanelVisible(false)
	updateTutorialVisibility()
	battleDock.Visible = not root.Visible
	title.Text = currentState.mode == "Story" and "Story Training"
		or currentState.mode == "Custom" and "Custom Lab"
		or currentState.mode == "Solo" and "Solo Puzzle"
		or "Block Blast Battle"
	scoreLabel.Text = tostring(currentState.score)
	if bestScoreLabel then
		bestScoreLabel.Text = `BEST {currentState.bestScore or 0}`
	end
	if comboBadgeLabel then
		local combo = math.max(1, currentState.comboStreak or 1)
		comboBadgeLabel.Text = `COMBO\nx{combo}`
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
	dockStatusLabel.Text = currentState.message
		or currentState.mode == "Story" and storyGoalText(currentState)
		or currentState.mode == "Solo" and `Solo score: {currentState.score}`
		or currentState.comboStreak and currentState.comboStreak > 1 and `Combo x{currentState.comboStreak} | Score: {currentState.score}`
		or currentState.suddenDeath and `Sudden death | Score: {currentState.score} | {currentState.timeLeft or "--"}s`
		or currentState.alive and `Arena {currentState.arenaIndex or "--"} | Score: {currentState.score} | {currentState.timeLeft or "--"}s`
		or "Out of moves - returning"
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
