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
		color = Color3.fromRGB(67, 224, 86),
	},
	{ key = "shop", icon = "SHOP", label = "Shop", color = Color3.fromRGB(255, 205, 82) },
	{ key = "rewards", icon = "QUEST", label = "Quests", color = Color3.fromRGB(64, 156, 255) },
	{ key = "settings", icon = "SET", label = "Settings", color = Color3.fromRGB(116, 124, 139) },
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

local function addHorizontalList(parent, padding)
	local layout = addList(parent, padding)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	return layout
end

local function addTextConstraint(label, minSize, maxSize)
	local constraint = Instance.new("UITextSizeConstraint")
	constraint.MinTextSize = minSize
	constraint.MaxTextSize = maxSize
	constraint.Parent = label
	return constraint
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
	addTextConstraint(self.nameLabel, 12, 17)
	self.levelLabel = makeLabel(profile, "Level", "LV. 1", UDim2.new(1, -52, 0, 18), "heading")
	self.levelLabel.Position = UDim2.fromOffset(50, 23)
	self.levelLabel.TextColor3 = Color3.fromRGB(255, 247, 130)
	self.levelLabel.TextStrokeColor3 = Color3.fromRGB(8, 66, 128)
	self.levelLabel.TextStrokeTransparency = 0.45
	addTextConstraint(self.levelLabel, 10, 15)

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
		local iconText = index == 1 and "$" or index == 2 and "W" or "*"
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
		addTextConstraint(label, 12, 17)

		local iconBadge = Instance.new("TextLabel")
		iconBadge.Name = "IconBadge"
		iconBadge.Position = UDim2.fromOffset(5, 4)
		iconBadge.Size = UDim2.fromOffset(20, 20)
		iconBadge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		iconBadge.BackgroundTransparency = 0.08
		iconBadge.BorderSizePixel = 0
		iconBadge.Font = UITheme.Font.heading
		iconBadge.Text = iconText
		iconBadge.TextColor3 = label.BackgroundColor3
		iconBadge.TextSize = 13
		iconBadge.ZIndex = label.ZIndex + 1
		iconBadge.Parent = label
		UITheme.corner(iconBadge, UITheme.Radius.pill)

		local plusBadge = Instance.new("TextLabel")
		plusBadge.Name = "PlusBadge"
		plusBadge.AnchorPoint = Vector2.new(1, 0)
		plusBadge.Position = UDim2.new(1, -5, 0, 4)
		plusBadge.Size = UDim2.fromOffset(20, 20)
		plusBadge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		plusBadge.BackgroundTransparency = index == 1 and 0.08 or 1
		plusBadge.BorderSizePixel = 0
		plusBadge.Font = UITheme.Font.heading
		plusBadge.Text = index == 1 and "+" or ""
		plusBadge.TextColor3 = label.BackgroundColor3
		plusBadge.TextSize = 14
		plusBadge.ZIndex = label.ZIndex + 1
		plusBadge.Parent = label
		UITheme.corner(plusBadge, UITheme.Radius.pill)
	end

	local objective = makeCard(stack, "ObjectiveCard", UDim2.new(1, 0, 0, 32))
	self.objectiveCard = objective
	objective.Visible = false
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
	stack.Name = "PrimaryActionHud"
	stack.AnchorPoint = Vector2.new(0.5, 1)
	stack.Position = UDim2.new(0.5, 0, 1, -28)
	stack.Size = UDim2.fromOffset(430, 104)
	stack.BackgroundTransparency = 1
	stack.ZIndex = UITheme.Z.hud
	stack.Parent = self.gui
	self.rightStack = stack

	local playButton = nil
	local secondaryRow = Instance.new("Frame")
	secondaryRow.Name = "SecondaryActions"
	secondaryRow.AnchorPoint = Vector2.new(0.5, 1)
	secondaryRow.Position = UDim2.new(0.5, 0, 1, 0)
	secondaryRow.Size = UDim2.fromOffset(360, 38)
	secondaryRow.BackgroundTransparency = 1
	secondaryRow.Parent = stack
	addHorizontalList(secondaryRow, 10)

	for index, data in RIGHT_BUTTONS do
		local button = Instance.new("TextButton")
		button.Name = `{data.key}Button`
		button.LayoutOrder = index
		button.Size = data.primary and UDim2.fromOffset(238, 58) or UDim2.fromOffset(110, 38)
		button.BackgroundColor3 = data.color or Color3.fromRGB(255, 255, 255)
		button.Text = ""
		button.TextColor3 = Color3.fromRGB(255, 255, 255)
		button.TextStrokeColor3 = data.key == "settings" and Color3.fromRGB(45, 54, 68)
			or Color3.fromRGB(19, 87, 127)
		button.TextStrokeTransparency = 0.28
		button.TextSize = data.primary and 27 or 14
		button.TextWrapped = true
		button.Font = UITheme.Font.heading
		button.BorderSizePixel = 0
		button.Selectable = true
		button.Parent = data.primary and stack or secondaryRow
		UITheme.button(button, data.primary and "success" or "secondary")
		button.BackgroundColor3 = data.color or Color3.fromRGB(255, 255, 255)
		if data.primary then
			button.AnchorPoint = Vector2.new(0.5, 0)
			button.Position = UDim2.new(0.5, 0, 0, 0)
			UITheme.gradient(button, Color3.fromRGB(116, 255, 119), Color3.fromRGB(29, 190, 66), 90)
			playButton = button
		elseif data.key == "settings" then
			button.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			UITheme.gradient(
				button,
				data.color,
				data.color:Lerp(Color3.fromRGB(35, 110, 196), 0.24),
				90
			)
		end
		local corner = button:FindFirstChildOfClass("UICorner")
		if corner then
			corner.CornerRadius = UDim.new(0, data.primary and 14 or 10)
		end
		local stroke = button:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = data.primary and Color3.fromRGB(18, 129, 48)
				or Color3.fromRGB(11, 87, 159)
			stroke.Thickness = data.primary and 3 or 2
			stroke.Transparency = 0.05
		end
		UITheme.attachButtonFeedback(button, self.isReducedMotion)
		self.buttons[data.key] = button

		if data.primary then
			local iconBadge = Instance.new("TextLabel")
			iconBadge.Name = "IconBadge"
			iconBadge.Position = UDim2.fromOffset(16, 10)
			iconBadge.Size = UDim2.fromOffset(38, 38)
			iconBadge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			iconBadge.BackgroundTransparency = 0.05
			iconBadge.BorderSizePixel = 0
			iconBadge.Font = UITheme.Font.title
			iconBadge.Text = ">"
			iconBadge.TextColor3 = Color3.fromRGB(34, 184, 65)
			iconBadge.TextSize = 28
			iconBadge.ZIndex = button.ZIndex + 1
			iconBadge.Parent = button
			UITheme.corner(iconBadge, UITheme.Radius.pill)
			UITheme.stroke(iconBadge, Color3.fromRGB(18, 129, 48), 2, 0.12)

			local playText = Instance.new("TextLabel")
			playText.Name = "ButtonText"
			playText.BackgroundTransparency = 1
			playText.Position = UDim2.fromOffset(62, 0)
			playText.Size = UDim2.new(1, -78, 1, 0)
			playText.Font = UITheme.Font.title
			playText.Text = "PLAY"
			playText.TextColor3 = Color3.fromRGB(255, 255, 255)
			playText.TextStrokeColor3 = Color3.fromRGB(19, 112, 39)
			playText.TextStrokeTransparency = 0.2
			playText.TextSize = 30
			playText.TextXAlignment = Enum.TextXAlignment.Center
			playText.ZIndex = button.ZIndex + 1
			playText.Parent = button
			addTextConstraint(playText, 18, 30)
			self.playButtonText = playText
			self.playButtonIcon = iconBadge
		else
			local iconBadge = Instance.new("TextLabel")
			iconBadge.Name = "IconBadge"
			iconBadge.Position = UDim2.fromOffset(7, 7)
			iconBadge.Size = UDim2.fromOffset(24, 24)
			iconBadge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			iconBadge.BackgroundTransparency = 0.08
			iconBadge.BorderSizePixel = 0
			iconBadge.Font = UITheme.Font.heading
			iconBadge.Text = data.icon
			iconBadge.TextColor3 = data.color
			iconBadge.TextSize = 9
			iconBadge.TextWrapped = true
			iconBadge.ZIndex = button.ZIndex + 1
			iconBadge.Parent = button
			UITheme.corner(iconBadge, 7)

			local label = Instance.new("TextLabel")
			label.Name = "ButtonText"
			label.BackgroundTransparency = 1
			label.Position = UDim2.fromOffset(34, 0)
			label.Size = UDim2.new(1, -38, 1, 0)
			label.Font = UITheme.Font.heading
			label.Text = string.upper(data.label)
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.TextStrokeColor3 = Color3.fromRGB(18, 78, 132)
			label.TextStrokeTransparency = 0.32
			label.TextSize = 14
			label.TextWrapped = true
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.ZIndex = button.ZIndex + 1
			label.Parent = button
			addTextConstraint(label, 10, 14)
		end

		connect(self, button.Activated, function()
			self:ActivateButton(data)
		end)
	end

	self.primaryPlayButton = playButton
	self.secondaryActionRow = secondaryRow
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
	if data.primary then
		return `{data.icon} {string.upper(data.label)}`
	end

	return `{data.icon} {string.upper(data.label)}`
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

	self.leftStack.AnchorPoint = Vector2.new(0, 0)
	self.leftStack.Position = UDim2.new(0, 16, 0, math.max(76, inset.Y + 54))
	self.leftStack.Size =
		UDim2.fromOffset(phone and 198 or compact and 228 or 250, phone and 124 or 164)
	self.statsCard.Visible = true
	self.objectiveCard.Visible = false

	self.rightStack.AnchorPoint = Vector2.new(0.5, 1)
	self.rightStack.Position = UDim2.new(0.5, 0, 1, phone and -72 or -26)
	self.rightStack.Size =
		UDim2.fromOffset(phone and 340 or compact and 386 or 430, phone and 96 or 104)
	if self.secondaryActionRow then
		self.secondaryActionRow.Size = UDim2.fromOffset(phone and 326 or 360, phone and 36 or 38)
	end
	for _, data in RIGHT_BUTTONS do
		local button = self.buttons[data.key]
		if button then
			if data.primary then
				button.Size =
					UDim2.fromOffset(phone and 190 or compact and 220 or 238, phone and 52 or 58)
				local playText = button:FindFirstChild("ButtonText")
				local iconBadge = button:FindFirstChild("IconBadge")
				if playText and playText:IsA("TextLabel") then
					playText.Position = UDim2.fromOffset(phone and 54 or 62, 0)
					playText.Size = UDim2.new(1, phone and -66 or -78, 1, 0)
					playText.TextSize = phone and 24 or 30
				end
				if iconBadge and iconBadge:IsA("TextLabel") then
					iconBadge.Position = UDim2.fromOffset(phone and 12 or 16, phone and 9 or 10)
					iconBadge.Size = UDim2.fromOffset(phone and 34 or 38, phone and 34 or 38)
				end
			else
				button.Size = UDim2.fromOffset(phone and 98 or 110, phone and 36 or 38)
				local label = button:FindFirstChild("ButtonText")
				local iconBadge = button:FindFirstChild("IconBadge")
				if label and label:IsA("TextLabel") then
					label.Position = UDim2.fromOffset(phone and 32 or 34, 0)
					label.Size = UDim2.new(1, phone and -34 or -38, 1, 0)
					label.TextSize = phone and 12 or 14
				end
				if iconBadge and iconBadge:IsA("TextLabel") then
					iconBadge.Size = UDim2.fromOffset(phone and 22 or 24, phone and 22 or 24)
				end
			end
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

function HUDController:SetPlayButtonState(hubState)
	local button = self.buttons.play
	if not button then
		return
	end

	local queued = hubState and hubState.queued == true
	local openArenas = hubState and hubState.openArenas or 0
	local label = self.playButtonText
	local icon = self.playButtonIcon
	if queued then
		if label then
			label.Text = "LEAVE"
		end
		if icon then
			icon.Text = "<"
		end
		button.BackgroundColor3 = Color3.fromRGB(255, 112, 189)
	elseif openArenas <= 0 then
		if label then
			label.Text = "FULL"
		end
		if icon then
			icon.Text = "!"
		end
		button.BackgroundColor3 = Color3.fromRGB(116, 124, 139)
	else
		if label then
			label.Text = "PLAY"
		end
		if icon then
			icon.Text = ">"
		end
		button.BackgroundColor3 = Color3.fromRGB(67, 224, 86)
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
	self:SetPlayButtonState(hubState)
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
		self:SetPlayButtonState(self.currentHubState)
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
