local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UITheme = require(script.Parent.UITheme)
local ExperienceConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("game"):WaitForChild("ExperienceConfig")
)

local HomePanel = {}
HomePanel.__index = HomePanel

local HUB_SIZE = Vector2.new(390, 238)
local SOFT_TWEEN = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

-- Public interface: Show, Hide, SetVisible, UpdatePlayerSummary, UpdateCurrencies,
-- UpdateProgression, UpdateDailyStatus, SetBattleEnabled, SetLoading, SetGamepadFocus,
-- RefreshResponsiveLayout, ApplyTheme, UpdateSettings, UpdateCosmeticPreviews,
-- UpdateHubState, Destroy.

local function connect(self, signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self.connections, connection)
	return connection
end

local function styleButton(button, variant, isReducedMotion)
	UITheme.button(button, variant)
	UITheme.attachButtonFeedback(button, isReducedMotion)
	return button
end

function HomePanel.new(gui, options)
	options = options or {}

	local self = setmetatable({}, HomePanel)
	self.gui = gui
	self.callbacks = options.callbacks or {}
	self.playSound = options.playSound or function() end
	self.showBanner = options.showBanner or function() end
	self.isReducedMotion = options.isReducedMotion or function()
		return false
	end
	self.connections = {}
	self.tweens = {}
	self.pieceSwatches = {}
	self.boardPreviewCells = {}
	self.queued = false
	self.lastQueued = false
	self.loading = false
	self.battleEnabled = true
	self.destroyed = false
	self.accentColor = UITheme.Color.primary

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0, 0)
	panel.Position = UDim2.fromOffset(18, 86)
	panel.Size = UDim2.fromOffset(HUB_SIZE.X, HUB_SIZE.Y)
	panel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	panel.BackgroundTransparency = 0.04
	panel.BorderSizePixel = 0
	panel.Parent = gui
	UITheme.card(panel, {
		color = Color3.fromRGB(255, 255, 255),
		strokeColor = Color3.fromRGB(125, 203, 255),
		strokeTransparency = 0.18,
	})
	self.panel = panel

	local panelScale = Instance.new("UIScale")
	panelScale.Scale = 1
	panelScale.Parent = panel
	self.panelScale = panelScale

	local logoButton = Instance.new("TextButton")
	logoButton.AnchorPoint = Vector2.new(0, 0.5)
	logoButton.Position = UDim2.fromScale(0, 0.5)
	logoButton.Size = UDim2.fromOffset(52, 52)
	logoButton.BackgroundColor3 = Color3.fromRGB(30, 187, 255)
	logoButton.BorderSizePixel = 0
	logoButton.Font = Enum.Font.GothamBlack
	logoButton.Text = "BB"
	logoButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	logoButton.TextSize = 20
	logoButton.Visible = false
	logoButton.Parent = gui
	styleButton(logoButton, "primary", self.isReducedMotion)
	self.logoButton = logoButton

	local logoHint = Instance.new("TextLabel")
	logoHint.AnchorPoint = Vector2.new(0, 0.5)
	logoHint.Position = UDim2.fromOffset(66, 0)
	logoHint.Size = UDim2.fromOffset(92, 26)
	logoHint.BackgroundColor3 = Color3.fromRGB(14, 18, 27)
	logoHint.BackgroundTransparency = 0.12
	logoHint.BorderSizePixel = 0
	logoHint.Font = Enum.Font.GothamBold
	logoHint.Text = "Hub"
	logoHint.TextColor3 = Color3.fromRGB(245, 247, 251)
	logoHint.TextSize = 14
	logoHint.Visible = false
	logoHint.Parent = logoButton
	UITheme.card(logoHint, { color = UITheme.Color.panelRaised, strokeTransparency = 0.32 })
	self.logoHint = logoHint

	local closeButton = Instance.new("TextButton")
	closeButton.AnchorPoint = Vector2.new(1, 0)
	closeButton.Position = UDim2.new(1, -12, 0, 12)
	closeButton.Size = UDim2.fromOffset(30, 30)
	closeButton.BackgroundColor3 = Color3.fromRGB(42, 57, 96)
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBlack
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(245, 247, 251)
	closeButton.TextSize = 16
	closeButton.Parent = panel
	UITheme.closeButton(closeButton)
	UITheme.attachButtonFeedback(closeButton, self.isReducedMotion)
	self.closeButton = closeButton

	local guideButton = Instance.new("TextButton")
	guideButton.AnchorPoint = Vector2.new(1, 0)
	guideButton.Position = UDim2.new(1, -50, 0, 12)
	guideButton.Size = UDim2.fromOffset(72, 30)
	guideButton.BackgroundColor3 = Color3.fromRGB(232, 246, 255)
	guideButton.BorderSizePixel = 0
	guideButton.Font = Enum.Font.GothamBold
	guideButton.Text = "Guide"
	guideButton.TextColor3 = Color3.fromRGB(35, 45, 55)
	guideButton.TextSize = 13
	guideButton.Parent = panel
	styleButton(guideButton, "secondary", self.isReducedMotion)
	self.guideButton = guideButton

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(16, 12)
	title.Size = UDim2.fromOffset(190, 30)
	title.Font = Enum.Font.GothamBlack
	title.Text = "Hub"
	title.TextColor3 = Color3.fromRGB(35, 45, 55)
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = panel
	UITheme.text(title, "title")
	self.title = title

	local statusLabel = Instance.new("TextLabel")
	statusLabel.BackgroundTransparency = 1
	statusLabel.Position = UDim2.fromOffset(16, 48)
	statusLabel.Size = UDim2.fromOffset(358, 40)
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.Text = "Walk to a queue pad or use the buttons below."
	statusLabel.TextColor3 = Color3.fromRGB(66, 82, 94)
	statusLabel.TextSize = 14
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.TextWrapped = true
	statusLabel.Parent = panel
	self.statusLabel = statusLabel

	local matchmakingLabel = Instance.new("TextLabel")
	matchmakingLabel.BackgroundTransparency = 1
	matchmakingLabel.Position = UDim2.fromOffset(16, 92)
	matchmakingLabel.Size = UDim2.fromOffset(358, 20)
	matchmakingLabel.Font = Enum.Font.GothamBold
	matchmakingLabel.Text = "Arenas: 3 open | Queue: 0"
	matchmakingLabel.TextColor3 = Color3.fromRGB(87, 104, 117)
	matchmakingLabel.TextSize = 13
	matchmakingLabel.TextXAlignment = Enum.TextXAlignment.Left
	matchmakingLabel.Parent = panel
	self.matchmakingLabel = matchmakingLabel

	local battleButton = Instance.new("TextButton")
	battleButton.Position = UDim2.fromOffset(16, 124)
	battleButton.Size = UDim2.fromOffset(172, 50)
	battleButton.BackgroundColor3 = Color3.fromRGB(30, 187, 255)
	battleButton.BorderSizePixel = 0
	battleButton.Font = Enum.Font.GothamBold
	battleButton.Text = ExperienceConfig.isModeEnabled("Battle") and "Join Battle Queue"
		or "Play Solo"
	battleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	battleButton.TextSize = 16
	battleButton.Parent = panel
	styleButton(battleButton, "primary", self.isReducedMotion)
	self.battleButton = battleButton

	local storyButton = Instance.new("TextButton")
	storyButton.Position = UDim2.fromOffset(204, 124)
	storyButton.Size = UDim2.fromOffset(170, 50)
	storyButton.BackgroundColor3 = Color3.fromRGB(123, 237, 75)
	storyButton.BorderSizePixel = 0
	storyButton.Font = Enum.Font.GothamBold
	storyButton.Text = "Story Mode"
	storyButton.TextColor3 = Color3.fromRGB(13, 32, 24)
	storyButton.TextSize = 15
	storyButton.TextWrapped = true
	storyButton.Visible = ExperienceConfig.isModeEnabled("Story")
	storyButton.Parent = panel
	styleButton(storyButton, "success", self.isReducedMotion)
	self.storyButton = storyButton

	local storyPreviewLabel = Instance.new("TextLabel")
	storyPreviewLabel.BackgroundTransparency = 1
	storyPreviewLabel.Position = UDim2.fromOffset(204, 176)
	storyPreviewLabel.Size = UDim2.fromOffset(170, 18)
	storyPreviewLabel.Font = Enum.Font.GothamBold
	storyPreviewLabel.Text = "Next chapter loading..."
	storyPreviewLabel.TextColor3 = Color3.fromRGB(153, 163, 179)
	storyPreviewLabel.TextSize = 10
	storyPreviewLabel.TextWrapped = true
	storyPreviewLabel.TextXAlignment = Enum.TextXAlignment.Left
	storyPreviewLabel.TextYAlignment = Enum.TextYAlignment.Center
	storyPreviewLabel.Visible = ExperienceConfig.isModeEnabled("Story")
	storyPreviewLabel.Parent = panel
	UITheme.text(storyPreviewLabel, "soft")
	self.storyPreviewLabel = storyPreviewLabel

	local motionButton = Instance.new("TextButton")
	motionButton.Position = UDim2.fromOffset(22, 224)
	motionButton.Size = UDim2.fromOffset(276, 42)
	motionButton.BackgroundColor3 = Color3.fromRGB(42, 57, 96)
	motionButton.BorderSizePixel = 0
	motionButton.Font = Enum.Font.GothamBold
	motionButton.Text = "Motion: Full"
	motionButton.TextColor3 = Color3.fromRGB(245, 247, 251)
	motionButton.TextSize = 15
	motionButton.Parent = panel
	motionButton.Visible = false
	styleButton(motionButton, "secondary", self.isReducedMotion)
	self.motionButton = motionButton

	local uiSizeButton = Instance.new("TextButton")
	uiSizeButton.Position = UDim2.fromOffset(322, 224)
	uiSizeButton.Size = UDim2.fromOffset(276, 42)
	uiSizeButton.BackgroundColor3 = Color3.fromRGB(42, 57, 96)
	uiSizeButton.BorderSizePixel = 0
	uiSizeButton.Font = Enum.Font.GothamBold
	uiSizeButton.Text = "UI Size: Auto"
	uiSizeButton.TextColor3 = Color3.fromRGB(245, 247, 251)
	uiSizeButton.TextSize = 15
	uiSizeButton.Parent = panel
	uiSizeButton.Visible = false
	styleButton(uiSizeButton, "secondary", self.isReducedMotion)
	self.uiSizeButton = uiSizeButton

	local pieceSkinButton = Instance.new("TextButton")
	pieceSkinButton.Position = UDim2.fromOffset(22, 278)
	pieceSkinButton.Size = UDim2.fromOffset(276, 42)
	pieceSkinButton.BackgroundColor3 = Color3.fromRGB(42, 57, 96)
	pieceSkinButton.BorderSizePixel = 0
	pieceSkinButton.Font = Enum.Font.GothamBold
	pieceSkinButton.Text = "  Pieces: Rainbow"
	pieceSkinButton.TextColor3 = Color3.fromRGB(245, 247, 251)
	pieceSkinButton.TextSize = 15
	pieceSkinButton.TextXAlignment = Enum.TextXAlignment.Left
	pieceSkinButton.Parent = panel
	pieceSkinButton.Visible = false
	styleButton(pieceSkinButton, "secondary", self.isReducedMotion)
	self.pieceSkinButton = pieceSkinButton

	local pieceSwatchFrame = Instance.new("Frame")
	pieceSwatchFrame.BackgroundTransparency = 1
	pieceSwatchFrame.Position = UDim2.new(1, -78, 0.5, -6)
	pieceSwatchFrame.Size = UDim2.fromOffset(58, 12)
	pieceSwatchFrame.ZIndex = 3
	pieceSwatchFrame.Parent = pieceSkinButton

	for index = 1, 4 do
		local swatch = Instance.new("Frame")
		swatch.Position = UDim2.fromOffset((index - 1) * 15, 0)
		swatch.Size = UDim2.fromOffset(12, 12)
		swatch.BorderSizePixel = 0
		swatch.ZIndex = 4
		swatch.Parent = pieceSwatchFrame
		self.pieceSwatches[index] = swatch
	end

	local soundButton = Instance.new("TextButton")
	soundButton.Position = UDim2.fromOffset(322, 278)
	soundButton.Size = UDim2.fromOffset(276, 42)
	soundButton.BackgroundColor3 = Color3.fromRGB(42, 57, 96)
	soundButton.BorderSizePixel = 0
	soundButton.Font = Enum.Font.GothamBold
	soundButton.Text = "Sound: 65%"
	soundButton.TextColor3 = Color3.fromRGB(245, 247, 251)
	soundButton.TextSize = 15
	soundButton.Parent = panel
	soundButton.Visible = false
	styleButton(soundButton, "secondary", self.isReducedMotion)
	self.soundButton = soundButton

	local boardSkinButton = Instance.new("TextButton")
	boardSkinButton.Position = UDim2.fromOffset(22, 332)
	boardSkinButton.Size = UDim2.fromOffset(276, 42)
	boardSkinButton.BackgroundColor3 = Color3.fromRGB(42, 57, 96)
	boardSkinButton.BorderSizePixel = 0
	boardSkinButton.Font = Enum.Font.GothamBold
	boardSkinButton.Text = "  Board: Auto"
	boardSkinButton.TextColor3 = Color3.fromRGB(245, 247, 251)
	boardSkinButton.TextSize = 15
	boardSkinButton.TextXAlignment = Enum.TextXAlignment.Left
	boardSkinButton.Parent = panel
	boardSkinButton.Visible = false
	styleButton(boardSkinButton, "secondary", self.isReducedMotion)
	self.boardSkinButton = boardSkinButton

	local boardPreviewFrame = Instance.new("Frame")
	boardPreviewFrame.BackgroundTransparency = 1
	boardPreviewFrame.Position = UDim2.new(1, -72, 0.5, -14)
	boardPreviewFrame.Size = UDim2.fromOffset(48, 28)
	boardPreviewFrame.ZIndex = 3
	boardPreviewFrame.Parent = boardSkinButton

	for row = 1, 2 do
		for column = 1, 3 do
			local index = (row - 1) * 3 + column
			local cell = Instance.new("Frame")
			cell.Position = UDim2.fromOffset((column - 1) * 15, (row - 1) * 15)
			cell.Size = UDim2.fromOffset(12, 12)
			cell.BorderSizePixel = 0
			cell.ZIndex = 4
			cell.Parent = boardPreviewFrame
			self.boardPreviewCells[index] = cell
		end
	end

	local shopButton = Instance.new("TextButton")
	shopButton.BackgroundColor3 = Color3.fromRGB(30, 187, 255)
	shopButton.BackgroundTransparency = 0
	shopButton.Position = UDim2.fromOffset(16, 190)
	shopButton.Size = UDim2.fromOffset(358, 34)
	shopButton.Font = Enum.Font.GothamBold
	shopButton.Text = "Shop & Closet"
	shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	shopButton.TextSize = 14
	shopButton.TextWrapped = true
	shopButton.TextXAlignment = Enum.TextXAlignment.Center
	shopButton.TextYAlignment = Enum.TextYAlignment.Center
	shopButton.BorderSizePixel = 0
	shopButton.Parent = panel
	styleButton(shopButton, "primary", self.isReducedMotion)
	self.shopButton = shopButton

	self:ConfigureFocus()

	connect(self, closeButton.Activated, function()
		self:Hide()
		if self.callbacks.close then
			self.callbacks.close()
		end
	end)
	connect(self, logoButton.Activated, function()
		if self.callbacks.reopen then
			self.callbacks.reopen()
		else
			self:Show()
		end
	end)
	connect(self, guideButton.Activated, function()
		self.playSound("Button")
		if self.callbacks.guide then
			self.callbacks.guide()
		end
	end)
	connect(self, battleButton.Activated, function()
		self.playSound(self.queued and "Button" or "Queue")
		if self.callbacks.battle then
			self.callbacks.battle(self.queued)
		end
	end)
	connect(self, storyButton.Activated, function()
		self.playSound("Button")
		if self.callbacks.story then
			self.callbacks.story()
		end
	end)
	connect(self, motionButton.Activated, function()
		if self.callbacks.motion then
			self.callbacks.motion()
		end
	end)
	connect(self, uiSizeButton.Activated, function()
		if self.callbacks.uiSize then
			self.callbacks.uiSize()
		end
	end)
	connect(self, pieceSkinButton.Activated, function()
		if self.callbacks.pieceSkin then
			self.callbacks.pieceSkin()
		end
	end)
	connect(self, boardSkinButton.Activated, function()
		if self.callbacks.boardSkin then
			self.callbacks.boardSkin()
		end
	end)
	connect(self, shopButton.Activated, function()
		self.playSound("Button")
		if self.callbacks.shop then
			self.callbacks.shop()
		end
	end)
	connect(self, soundButton.Activated, function()
		if self.callbacks.sound then
			self.callbacks.sound()
		end
	end)

	return self
end

function HomePanel:ConfigureFocus()
	self.closeButton.NextSelectionLeft = self.guideButton
	self.closeButton.NextSelectionDown = if self.storyButton.Visible
		then self.storyButton
		else self.battleButton
	self.guideButton.NextSelectionRight = self.closeButton
	self.guideButton.NextSelectionDown = self.battleButton

	self.battleButton.NextSelectionRight = if self.storyButton.Visible
		then self.storyButton
		else nil
	self.battleButton.NextSelectionUp = self.guideButton
	self.battleButton.NextSelectionDown = self.shopButton

	self.storyButton.NextSelectionLeft = self.battleButton
	self.storyButton.NextSelectionUp = self.closeButton
	self.storyButton.NextSelectionDown = self.shopButton

	self.shopButton.NextSelectionUp = self.battleButton
end

function HomePanel:SetGamepadFocus(target)
	if not UserInputService.GamepadEnabled then
		return
	end
	if target == "close" then
		GuiService.SelectedObject = self.closeButton
	elseif target == "story" then
		GuiService.SelectedObject = self.storyButton
	elseif target == "shop" then
		GuiService.SelectedObject = self.shopButton
	else
		GuiService.SelectedObject = self.battleButton
	end
end

function HomePanel:Show()
	self:SetVisible(true)
end

function HomePanel:Hide()
	self:SetVisible(false)
end

function HomePanel:SetVisible(visible, canShow)
	if self.destroyed then
		return
	end
	local shouldShow = visible and canShow ~= false
	self.panel.Visible = shouldShow
	self.logoButton.Visible = canShow ~= false and not shouldShow
	self.logoHint.Visible = self.logoButton.Visible

	if shouldShow then
		local inset = GuiService:GetGuiInset()
		local openY = math.max(76, inset.Y + 58)
		local openPosition = UDim2.fromOffset(18, openY)
		self.panel.Position = UDim2.fromOffset(18, openY - 8)
		if not self.isReducedMotion() then
			if self.showTween then
				self.showTween:Cancel()
			end
			self.showTween = TweenService:Create(self.panel, SOFT_TWEEN, {
				Position = openPosition,
			})
			self.showTween:Play()
		else
			self.panel.Position = openPosition
		end
		self:SetGamepadFocus("battle")
	elseif GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(self.panel) then
		GuiService.SelectedObject = nil
	end
end

function HomePanel:RefreshResponsiveLayout(screenSize, nextScale)
	local automaticScale = nextScale or 1
	local inset = GuiService:GetGuiInset()
	local hubFitScale =
		math.min(1, (screenSize.X - 24) / HUB_SIZE.X, (screenSize.Y - 24) / HUB_SIZE.Y)
	self.panelScale.Scale = math.clamp(math.min(automaticScale, hubFitScale), 0.72, 1.12)
	self.panel.Position = UDim2.fromOffset(18, math.max(76, inset.Y + 58))
end

function HomePanel:GetSize()
	return HUB_SIZE
end

function HomePanel:ApplyTheme(theme)
	self.accentColor = theme.accent or self.accentColor
	self.panel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.logoButton.BackgroundColor3 = self.accentColor
	self.battleButton.BackgroundColor3 = self.queued and Color3.fromRGB(255, 93, 200)
		or self.accentColor
	self.shopButton.BackgroundColor3 = self.accentColor
end

function HomePanel:UpdateSettings(settings)
	settings = settings or {}
	self.motionButton.Text = settings.reducedMotion and "Motion: Reduced" or "Motion: Full"
	if settings.uiScale == 1 then
		self.uiSizeButton.Text = "UI Size: Auto"
	elseif (settings.uiScale or 1) > 1 then
		self.uiSizeButton.Text = "UI Size: Large"
	else
		self.uiSizeButton.Text = "UI Size: Compact"
	end
	self.pieceSkinButton.Text = `  Pieces: {settings.pieceSkin or "Rainbow"}`
	self.boardSkinButton.Text = `  Board: {settings.boardSkin or "Auto"}`
	self.shopButton.Text = "Shop & Closet"
	if settings.soundEnabled == false or (settings.soundVolume or 0) <= 0 then
		self.soundButton.Text = "Sound: Off"
	else
		self.soundButton.Text = `Sound: {math.floor((settings.soundVolume or 0.65) * 100)}%`
	end
end

function HomePanel:UpdateCosmeticPreviews(pieceColors, boardColors)
	for index, swatch in self.pieceSwatches do
		swatch.BackgroundColor3 = pieceColors[index] or pieceColors[#pieceColors]
	end

	for index, cell in self.boardPreviewCells do
		cell.BackgroundColor3 = index == 3 and boardColors.border or boardColors.empty
	end
end

function HomePanel:UpdatePlayerSummary(summary)
	self:UpdateProgression(summary)
end

function HomePanel:UpdateCurrencies(summary)
	self:UpdateProgression(summary)
end

function HomePanel:UpdateProgression(_summary) end

function HomePanel:UpdateDailyStatus(text, available)
	if available and text then
		self.statusLabel.Text = text
	end
end

function HomePanel:SetBattleEnabled(enabled)
	self.battleEnabled = enabled ~= false
	if not self.battleEnabled and not self.queued then
		self.battleButton.BackgroundColor3 = UITheme.Color.panelSoft
	end
end

function HomePanel:SetLoading(loading)
	self.loading = loading == true
	if self.loading then
		self.statusLabel.Text = "Loading hub..."
	end
end

function HomePanel:UpdateHubState(hubState, storyPreviewText, accentColor)
	hubState = hubState or {}
	if accentColor then
		self.accentColor = accentColor
	end

	local queueCount = hubState.queueCount or 0
	local minPlayers = hubState.minPlayers or 2
	local openArenas = hubState.openArenas or 0
	local totalArenas = hubState.totalArenas or 0
	local activeSessions = hubState.activeSessions or 0
	local queueText = `{queueCount}/{minPlayers} queued`
	if hubState.secondsToSoloStart and hubState.secondsToSoloStart > 0 then
		queueText ..= ` | solo test in {hubState.secondsToSoloStart}s`
	end

	if not ExperienceConfig.isModeEnabled("Story") then
		self.storyButton.Visible = false
		self.storyPreviewLabel.Visible = false
	elseif typeof(hubState.storyMission) == "table" then
		self.storyButton.Visible = true
		self.storyPreviewLabel.Visible = true
		self.storyButton.Text = `Story: {hubState.storyMission.name or "Mission"}`
	else
		self.storyButton.Visible = true
		self.storyPreviewLabel.Visible = true
		self.storyButton.Text = "Story Mode"
	end
	self.storyPreviewLabel.Text = storyPreviewText or "Complete missions to unlock chapters"

	local message = hubState.message or "Welcome to the hub"
	if hubState.dailyBonusAvailable and message == "Welcome to the hub" then
		message = "Daily bonus ready"
	end
	self.statusLabel.Text = message
	self.matchmakingLabel.Text =
		`Arenas: {openArenas}/{totalArenas} open | Matches: {activeSessions} | {queueText}`
	self.matchmakingLabel.TextColor3 = openArenas > 0 and UITheme.Color.textSoft
		or Color3.fromRGB(255, 210, 71)

	self.queued = hubState.queued == true
	self:SetBattleEnabled(openArenas > 0 or self.queued)
	if ExperienceConfig.isModeEnabled("Solo") and not ExperienceConfig.isModeEnabled("Battle") then
		self.battleButton.Text = "Play Solo"
	elseif self.queued then
		self.battleButton.Text = "Queued - Leave Queue"
	elseif openArenas <= 0 then
		self.battleButton.Text = "Arenas Full"
	else
		self.battleButton.Text = "Join Battle Queue"
	end
	self.battleButton.BackgroundColor3 = self.queued and Color3.fromRGB(255, 93, 200)
		or self.battleEnabled and self.accentColor
		or UITheme.Color.panelSoft

	if self.queuedPulseTween then
		self.queuedPulseTween:Cancel()
		self.queuedPulseTween = nil
	end

	if self.queued then
		if not self.lastQueued then
			self.showBanner("Queued for battle", Color3.fromRGB(255, 93, 200))
		end
		if not self.isReducedMotion() then
			self.queuedPulseTween = TweenService:Create(
				self.battleButton,
				TweenInfo.new(0.55, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
				{ BackgroundTransparency = 0.22 }
			)
			self.queuedPulseTween:Play()
		end
	else
		self.battleButton.BackgroundTransparency = 0
	end

	self.lastQueued = self.queued
end

function HomePanel:Destroy()
	if self.destroyed then
		return
	end
	self.destroyed = true
	if self.showTween then
		self.showTween:Cancel()
	end
	if self.queuedPulseTween then
		self.queuedPulseTween:Cancel()
	end
	for _, connection in self.connections do
		connection:Disconnect()
	end
	table.clear(self.connections)
	if self.panel then
		self.panel:Destroy()
	end
	if self.logoButton then
		self.logoButton:Destroy()
	end
end

return HomePanel
