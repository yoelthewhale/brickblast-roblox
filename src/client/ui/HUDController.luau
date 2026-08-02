local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local MenuController = require(script.Parent.MenuController)
local UITheme = require(script.Parent.UITheme)

local HUDController = {}
HUDController.__index = HUDController

local RIGHT_BUTTONS = {
	{
		key = "play",
		icon = "PLAY",
		label = "Play",
		primary = true,
		color = Color3.fromRGB(64, 156, 255),
	},
	{ key = "modes", icon = "MODE", label = "Modes", color = Color3.fromRGB(167, 109, 255) },
	{ key = "inventory", icon = "BAG", label = "Inventory", color = Color3.fromRGB(255, 112, 189) },
	{ key = "shop", icon = "SHOP", label = "Shop", color = Color3.fromRGB(255, 205, 82) },
	{ key = "rewards", icon = "GIFT", label = "Rewards", color = Color3.fromRGB(74, 222, 128) },
	{ key = "settings", icon = "SET", label = "Settings", color = Color3.fromRGB(232, 246, 255) },
}

local function connect(self, signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self.connections, connection)
	return connection
end

local function makeLabel(parent, name, text, size, role)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Size = size
	label.Text = text
	label.TextColor3 = role == "muted" and Color3.fromRGB(87, 104, 117)
		or Color3.fromRGB(35, 45, 55)
	label.Font = role == "title" and UITheme.Font.title
		or role == "heading" and UITheme.Font.heading
		or UITheme.Font.body
	label.TextSize = role == "title" and 19 or role == "heading" and 15 or 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextWrapped = true
	label.Parent = parent
	return label
end

local function makeCard(parent, name, size)
	local card = Instance.new("Frame")
	card.Name = name
	card.Size = size
	card.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	card.BackgroundTransparency = 0.07
	card.BorderSizePixel = 0
	card.Parent = parent
	UITheme.card(card, {
		color = Color3.fromRGB(255, 255, 255),
		strokeColor = Color3.fromRGB(125, 203, 255),
		strokeTransparency = 0.22,
	})
	UITheme.padding(card, 12)
	return card
end

local function addList(parent, padding)
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, padding or 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = parent
	return layout
end

function HUDController.new(gui, options)
	options = options or {}

	local self = setmetatable({}, HUDController)
	self.gui = gui
	self.player = options.player or Players.LocalPlayer
	self.callbacks = options.callbacks or {}
	self.playSound = options.playSound or function() end
	self.notify = options.notify or function() end
	self.isReducedMotion = options.isReducedMotion or function()
		return false
	end
	self.connections = {}
	self.buttons = {}
	self.collapsed = false
	self.gameplayFocus = false
	self.currentHubState = nil
	self.currentState = nil

	self.menu = MenuController.new(gui, {
		isReducedMotion = self.isReducedMotion,
		playSound = self.playSound,
	})

	self:BuildLeftHud()
	self:BuildRightMenu()
	self:BuildTopHud()

	connect(self, gui:GetPropertyChangedSignal("AbsoluteSize"), function()
		self:RefreshResponsiveLayout()
	end)
	self:RefreshResponsiveLayout()

	return self
end

function HUDController:BuildLeftHud()
	local stack = Instance.new("Frame")
	stack.Name = "LeftPlayerHud"
	stack.AnchorPoint = Vector2.new(0, 0)
	stack.Position = UDim2.fromOffset(18, 86)
	stack.Size = UDim2.fromOffset(270, 190)
	stack.BackgroundTransparency = 1
	stack.ZIndex = UITheme.Z.hud
	stack.Parent = self.gui
	self.leftStack = stack
	addList(stack, 10)

	local profile = makeCard(stack, "ProfileCard", UDim2.new(1, 0, 0, 58))
	self.profileCard = profile
	profile.BackgroundColor3 = Color3.fromRGB(36, 185, 255)
	UITheme.gradient(profile, Color3.fromRGB(58, 209, 255), Color3.fromRGB(18, 119, 219), 0)
	local profileStroke = profile:FindFirstChildOfClass("UIStroke")
	if profileStroke then
		profileStroke.Color = Color3.fromRGB(9, 64, 139)
		profileStroke.Thickness = 3
		profileStroke.Transparency = 0.08
	end

	local avatar = Instance.new("ImageLabel")
	avatar.Name = "Avatar"
	avatar.Position = UDim2.fromOffset(0, 0)
	avatar.Size = UDim2.fromOffset(38, 38)
	avatar.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	avatar.BorderSizePixel = 0
	avatar.Image = `rbxthumb://type=AvatarHeadShot&id={self.player.UserId}&w=100&h=100`
	avatar.Parent = profile
	UITheme.corner(avatar, UITheme.Radius.pill)
	UITheme.stroke(avatar, Color3.fromRGB(72, 178, 255), 1, 0.22)

	self.nameLabel = makeLabel(
		profile,
		"DisplayName",
		self.player.DisplayName,
		UDim2.new(1, -52, 0, 22),
		"title"
	)
	self.nameLabel.Position = UDim2.fromOffset(50, 0)
	self.nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	self.nameLabel.TextStrokeColor3 = Color3.fromRGB(8, 66, 128)
	self.nameLabel.TextStrokeTransparency = 0.35
	self.nameLabel.TextSize = 17
	self.levelLabel = makeLabel(profile, "Level", "LV. 1", UDim2.new(1, -52, 0, 18), "heading")
	self.levelLabel.Position = UDim2.fromOffset(50, 23)
	self.levelLabel.TextColor3 = Color3.fromRGB(255, 247, 130)
	self.levelLabel.TextStrokeColor3 = Color3.fromRGB(8, 66, 128)
	self.levelLabel.TextStrokeTransparency = 0.45

	local xpBack = Instance.new("Frame")
	xpBack.Name = "XPBack"
	xpBack.Position = UDim2.fromOffset(50, 43)
	xpBack.Size = UDim2.new(1, -58, 0, 7)
	xpBack.BackgroundColor3 = Color3.fromRGB(7, 70, 139)
	xpBack.BorderSizePixel = 0
	xpBack.Parent = profile
	UITheme.corner(xpBack, UITheme.Radius.pill)

	local xpFill = Instance.new("Frame")
	xpFill.Name = "XPFill"
	xpFill.Size = UDim2.fromScale(0, 1)
	xpFill.BackgroundColor3 = Color3.fromRGB(255, 238, 77)
	xpFill.BorderSizePixel = 0
	xpFill.Parent = xpBack
	UITheme.corner(xpFill, UITheme.Radius.pill)
	self.xpFill = xpFill

	local stats = makeCard(stack, "StatsCard", UDim2.new(1, 0, 0, 92))
	self.statsCard = stats
	stats.BackgroundTransparency = 1
	local statsStroke = stats:FindFirstChildOfClass("UIStroke")
	if statsStroke then
		statsStroke.Enabled = false
	end
	self.coinsLabel = makeLabel(stats, "Coins", "COINS 0", UDim2.new(1, 0, 0, 28), "heading")
	self.coinsLabel.Position = UDim2.fromOffset(0, 0)
	self.winsLabel = makeLabel(stats, "Wins", "WINS 0", UDim2.new(1, 0, 0, 28), "heading")
	self.winsLabel.Position = UDim2.fromOffset(0, 32)
	self.starsLabel = makeLabel(stats, "Stars", "STARS 0", UDim2.new(1, 0, 0, 28), "heading")
	self.starsLabel.Position = UDim2.fromOffset(0, 64)
	for index, label in { self.coinsLabel, self.winsLabel, self.starsLabel } do
		label.BackgroundTransparency = 0
		label.BackgroundColor3 = index == 1 and Color3.fromRGB(255, 194, 47)
			or index == 2 and Color3.fromRGB(59, 226, 116)
			or Color3.fromRGB(177, 101, 255)
		label.TextColor3 = Color3.fromRGB(255, 255, 255)
		label.TextStrokeColor3 = Color3.fromRGB(45, 76, 115)
		label.TextStrokeTransparency = 0.35
		label.TextSize = 17
		label.TextXAlignment = Enum.TextXAlignment.Center
		UITheme.corner(label, UITheme.Radius.pill)
		UITheme.stroke(label, Color3.fromRGB(8, 76, 151), 2, 0.08)
	end

	local objective = makeCard(stack, "ObjectiveCard", UDim2.new(1, 0, 0, 32))
	self.objectiveCard = objective
	objective.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	self.modeLabel = makeLabel(objective, "Mode", "Hub", UDim2.new(1, 0, 0, 18), "heading")
	self.modeLabel.Position = UDim2.fromOffset(0, 0)
	self.objectiveLabel = makeLabel(
		objective,
		"Objective",
		"Walk to a portal or open Play.",
		UDim2.new(1, 0, 0, 0),
		"muted"
	)
	self.objectiveLabel.Visible = false
end

function HUDController:BuildRightMenu()
	local stack = Instance.new("Frame")
	stack.Name = "RightActionHud"
	stack.AnchorPoint = Vector2.new(1, 0.5)
	stack.Position = UDim2.new(1, -18, 0.5, 0)
	stack.Size = UDim2.fromOffset(58, 364)
	stack.BackgroundTransparency = 1
	stack.ZIndex = UITheme.Z.hud
	stack.Parent = self.gui
	self.rightStack = stack
	addList(stack, 8)

	for index, data in RIGHT_BUTTONS do
		local button = Instance.new("TextButton")
		button.Name = `{data.key}Button`
		button.LayoutOrder = index
		button.Size = UDim2.fromOffset(data.primary and 58 or 52, data.primary and 58 or 52)
		button.BackgroundColor3 = data.color or Color3.fromRGB(255, 255, 255)
		button.Text = self:ButtonText(data)
		button.TextColor3 = data.key == "settings" and Color3.fromRGB(35, 45, 55)
			or Color3.fromRGB(255, 255, 255)
		button.TextSize = data.primary and 22 or 19
		button.TextWrapped = true
		button.Font = UITheme.Font.heading
		button.BorderSizePixel = 0
		button.Selectable = true
		button.Parent = stack
		UITheme.button(button, data.primary and "primary" or "secondary")
		button.BackgroundColor3 = data.color or Color3.fromRGB(255, 255, 255)
		button.TextColor3 = data.key == "settings" and Color3.fromRGB(35, 45, 55)
			or Color3.fromRGB(255, 255, 255)
		local corner = button:FindFirstChildOfClass("UICorner")
		if corner then
			corner.CornerRadius = UDim.new(0, 14)
		end
		UITheme.attachButtonFeedback(button, self.isReducedMotion)
		self.buttons[data.key] = button

		connect(self, button.Activated, function()
			self:ActivateButton(data)
		end)
	end
end

function HUDController:BuildTopHud()
	local top = Instance.new("Frame")
	top.Name = "TopContextHud"
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.fromScale(0.5, 0.02)
	top.Size = UDim2.fromOffset(360, 42)
	top.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	top.BackgroundTransparency = 0.12
	top.BorderSizePixel = 0
	top.Visible = false
	top.ZIndex = UITheme.Z.hud
	top.Parent = self.gui
	UITheme.card(top, {
		color = Color3.fromRGB(255, 255, 255),
		strokeColor = Color3.fromRGB(125, 203, 255),
		strokeTransparency = 0.3,
	})
	self.topBar = top

	self.zoneLabel = makeLabel(top, "Zone", "Floating Hub", UDim2.new(1, -24, 1, 0), "heading")
	self.zoneLabel.Position = UDim2.fromOffset(12, 0)
	self.zoneLabel.TextXAlignment = Enum.TextXAlignment.Center
end

function HUDController:ButtonText(data)
	return data.icon
end

function HUDController:ActivateButton(data)
	self.playSound(data.comingSoon and "Blocked" or "Button")
	self.menu:Close()
	self:SetMenuButtonSelected(data.key)
	if data.comingSoon then
		self:OpenComingSoon(data.label)
		self.notify(`{data.label} is coming soon`, "info")
		return
	end

	local callback = self.callbacks[data.key]
	if callback then
		callback()
		return
	end

	self:OpenComingSoon(data.label)
end

function HUDController:OpenComingSoon(title)
	self.menu:Open(`soon-{title}`, title, function(content)
		local label = makeLabel(
			content,
			"ComingSoon",
			`{title} is planned but not fully connected yet.`,
			UDim2.new(1, 0, 0, 74),
			"heading"
		)
		label.TextXAlignment = Enum.TextXAlignment.Center
	end)
end

function HUDController:OpenInfoPanel(title, lines)
	self.menu:Open(title, title, function(content)
		addList(content, 10)
		for index, line in lines do
			local card = makeCard(content, `Line{index}`, UDim2.new(1, 0, 0, 56))
			local label = makeLabel(card, "Text", line, UDim2.new(1, 0, 1, 0), "muted")
			label.TextXAlignment = Enum.TextXAlignment.Left
		end
	end)
end

function HUDController:RefreshResponsiveLayout()
	local screenSize = self.gui.AbsoluteSize
	local inset = GuiService:GetGuiInset()
	local compact = screenSize.X < 860
	local phone = screenSize.X < 620 or screenSize.Y < 520
	self.collapsed = compact

	self.leftStack.AnchorPoint = Vector2.new(0, 1)
	self.leftStack.Position = UDim2.new(0, 16, 1, phone and -78 or -28)
	self.leftStack.Size =
		UDim2.fromOffset(phone and 210 or compact and 236 or 270, phone and 128 or 190)
	self.statsCard.Visible = true
	self.objectiveCard.Visible = not phone

	self.rightStack.AnchorPoint = Vector2.new(1, 0.5)
	self.rightStack.Position = UDim2.new(1, -18, 0.5, phone and -10 or 0)
	self.rightStack.Size = UDim2.fromOffset(phone and 60 or 66, phone and 372 or 420)
	for _, data in RIGHT_BUTTONS do
		local button = self.buttons[data.key]
		if button then
			button.Text = self:ButtonText(data)
			local size = phone and 52 or data.primary and 66 or 60
			button.Size = UDim2.fromOffset(size, size)
			button.TextSize = phone and 13 or data.primary and 15 or 13
		end
	end

	self.topBar.Position = UDim2.new(0.5, 0, 0, math.max(12, inset.Y + 8))
	self.topBar.Size = UDim2.fromOffset(math.clamp(screenSize.X - 360, 260, 420), 42)
end

function HUDController:SetGameplayFocus(enabled)
	self.gameplayFocus = enabled == true
	if self.leftStack then
		self.leftStack.Visible = not self.gameplayFocus
	end
	if self.rightStack then
		self.rightStack.Visible = not self.gameplayFocus
	end
	if self.gameplayFocus and self.menu then
		self.menu:Close()
	end
end

function HUDController:SetMenuButtonSelected(key)
	for buttonKey, button in self.buttons do
		local selected = buttonKey == key
		button.BackgroundTransparency = selected and 0 or 0.04
		local stroke = button:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Thickness = selected and 2 or 1
			stroke.Color = selected and Color3.fromRGB(255, 205, 82) or UITheme.Color.strokeSoft
		end
	end
end

function HUDController:UpdateProgression()
	local leaderstats = self.player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local xp = leaderstats and leaderstats:FindFirstChild("XP")
	local level = leaderstats and leaderstats:FindFirstChild("Level")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	local storyStars = leaderstats and leaderstats:FindFirstChild("StoryStars")

	local levelValue = level and level.Value or 1
	local xpValue = xp and xp.Value or 0
	self.levelLabel.Text = `LV. {levelValue} | {xpValue} XP`
	self.coinsLabel.Text = `$ {coins and coins.Value or 0}`
	self.winsLabel.Text = `WINS {wins and wins.Value or 0}`
	self.starsLabel.Text = `STARS {storyStars and storyStars.Value or 0}`

	local progress = (xpValue % 100) / 100
	if self.isReducedMotion() then
		self.xpFill.Size = UDim2.fromScale(progress, 1)
	else
		TweenService:Create(self.xpFill, UITheme.Motion.soft, {
			Size = UDim2.fromScale(progress, 1),
		}):Play()
	end
end

function HUDController:UpdateHubState(hubState)
	self.currentHubState = hubState
	if not hubState then
		return
	end

	if hubState.mode == "Battle" or hubState.mode == "Story" or hubState.mode == "Custom" then
		return
	end

	self:SetGameplayFocus(false)
	self.topBar.Visible = hubState.queued == true
	local queueCount = hubState.queueCount or 0
	local minPlayers = hubState.minPlayers or 2
	local openArenas = hubState.openArenas or 0
	self.modeLabel.Text = hubState.queued and "Queued" or "Hub"
	if hubState.queued then
		self.objectiveLabel.Text = hubState.secondsToSoloStart
				and hubState.secondsToSoloStart > 0
				and `Waiting for players. Solo test in {hubState.secondsToSoloStart}s.`
			or `Queue: {queueCount}/{minPlayers}. Stay ready.`
	elseif openArenas <= 0 then
		self.objectiveLabel.Text = "Arenas are full. Try Story or wait."
	else
		self.objectiveLabel.Text = "Choose Play, Modes, Shop, or walk to a portal."
	end

	self.zoneLabel.Text = hubState.message or `Floating Hub | {openArenas} arena(s) open`
	self:UpdateProgression()
end

function HUDController:UpdateGameState(state)
	self.currentState = state
	if not state then
		self:SetGameplayFocus(false)
		self.topBar.Visible = false
		self.zoneLabel.Text = "Floating Hub"
		return
	end

	self:SetGameplayFocus(true)
	self.topBar.Visible = true
	self.modeLabel.Text = state.mode == "Story" and "Story Run"
		or state.mode == "Custom" and "Custom Lab"
		or "Battle"
	self.objectiveLabel.Text = state.message
		or state.mode == "Story" and "Complete the mission objective."
		or state.mode == "Custom" and "Rotate or reroll pieces, then test placements."
		or "Place blocks, clear lines, and outscore rivals."
	self.zoneLabel.Text = state.timeLeft and `{self.modeLabel.Text} | {state.timeLeft}s`
		or self.modeLabel.Text
	self:UpdateProgression()
end

function HUDController:Destroy()
	for _, connection in self.connections do
		connection:Disconnect()
	end
	table.clear(self.connections)
	if self.menu then
		self.menu:Destroy()
	end
	if self.leftStack then
		self.leftStack:Destroy()
	end
	if self.rightStack then
		self.rightStack:Destroy()
	end
	if self.topBar then
		self.topBar:Destroy()
	end
end

return HUDController
