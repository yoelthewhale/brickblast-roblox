local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local MenuController = require(script.Parent.MenuController)
local UITheme = require(script.Parent.UITheme)
local ExperienceConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("game"):WaitForChild("ExperienceConfig")
)

local HUDController = {}
HUDController.__index = HUDController

local LEFT_BUTTONS = {
	{
		key = "rewards",
		label = "Quests Soon",
		icon = "Quest",
		accent = Color3.fromRGB(255, 210, 71),
	},
	{
		key = "codes",
		label = "Codes",
		icon = "Gift",
		accent = Color3.fromRGB(255, 93, 200),
	},
	{
		key = "achievements",
		label = "Achievements",
		icon = "Trophy",
		accent = Color3.fromRGB(255, 210, 71),
	},
}

if ExperienceConfig.UI.ShowModesButton then
	table.insert(LEFT_BUTTONS, {
		key = "modes",
		label = "Modes",
		icon = "Blocks",
		accent = Color3.fromRGB(48, 215, 255),
	})
end

local RIGHT_BUTTONS = {
	{
		key = "play",
		label = "Play",
		icon = "Play",
		primary = true,
		accent = Color3.fromRGB(112, 237, 71),
	},
	{
		key = "shop",
		label = "Shop",
		icon = "Bag",
		accent = Color3.fromRGB(190, 118, 255),
	},
	{
		key = "inventory",
		label = "Inventory",
		icon = "Grid",
		accent = Color3.fromRGB(30, 187, 255),
	},
	{
		key = "settings",
		label = "Settings",
		icon = "Gear",
		accent = Color3.fromRGB(255, 210, 71),
	},
}

local RESOURCE_ITEMS = {
	{
		key = "level",
		label = "LV",
		accent = Color3.fromRGB(52, 215, 255),
	},
	{
		key = "xp",
		label = "XP",
		accent = Color3.fromRGB(112, 237, 71),
	},
	{
		key = "coins",
		label = "Coins",
		accent = Color3.fromRGB(255, 210, 71),
	},
	{
		key = "bestScore",
		label = "Best",
		accent = Color3.fromRGB(255, 255, 255),
	},
}

if ExperienceConfig.UI.ShowWins then
	table.insert(RESOURCE_ITEMS, {
		key = "wins",
		label = "Wins",
		accent = Color3.fromRGB(255, 255, 255),
	})
end

if ExperienceConfig.UI.ShowStoryStars then
	table.insert(RESOURCE_ITEMS, {
		key = "stars",
		label = "Stars",
		accent = Color3.fromRGB(190, 118, 255),
	})
end

local function connect(self, signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self.connections, connection)
	return connection
end

local function addCorner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
	return corner
end

local function addStroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color
	stroke.Thickness = thickness
	stroke.Transparency = transparency or 0
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

local function addGradient(parent, topColor, bottomColor)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor),
		ColorSequenceKeypoint.new(1, bottomColor),
	})
	gradient.Rotation = 90
	gradient.Parent = parent
	return gradient
end

local function addPadding(parent, left, right, top, bottom)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, left)
	padding.PaddingRight = UDim.new(0, right or left)
	padding.PaddingTop = UDim.new(0, top or left)
	padding.PaddingBottom = UDim.new(0, bottom or top or left)
	padding.Parent = parent
	return padding
end

local function addList(parent, direction, padding, horizontalAlignment, verticalAlignment)
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = direction or Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, padding or 10)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.HorizontalAlignment = horizontalAlignment or Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = verticalAlignment or Enum.VerticalAlignment.Center
	layout.Parent = parent
	return layout
end

local function makeLabel(parent, name, text, font, size, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.BackgroundTransparency = 1
	label.Font = font
	label.Text = text
	label.TextColor3 = color
	label.TextSize = size
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = parent
	return label
end

local function makeShadow(parent, radius)
	local shadow = Instance.new("Frame")
	shadow.Name = "Shadow"
	shadow.AnchorPoint = Vector2.new(0.5, 0.5)
	shadow.Position = UDim2.new(0.5, 0, 0.5, 6)
	shadow.Size = UDim2.new(1, 4, 1, 4)
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = 0.72
	shadow.BorderSizePixel = 0
	shadow.ZIndex = parent.ZIndex - 1
	shadow.Parent = parent
	addCorner(shadow, radius)
	return shadow
end

local function makeIcon(parent, iconType, chipColor, glyphColor)
	glyphColor = glyphColor or Color3.fromRGB(255, 255, 255)

	local iconFrame = Instance.new("Frame")
	iconFrame.Name = "Icon"
	iconFrame.Size = UDim2.fromOffset(36, 36)
	iconFrame.BackgroundColor3 = chipColor
	iconFrame.BorderSizePixel = 0
	iconFrame.Parent = parent
	addCorner(iconFrame, 10)
	addStroke(iconFrame, glyphColor, 2, 0.55)

	local function block(name, position, size, colorOverride)
		local frame = Instance.new("Frame")
		frame.Name = name
		frame.Position = position
		frame.Size = size
		frame.BackgroundColor3 = colorOverride or glyphColor
		frame.BorderSizePixel = 0
		frame.Parent = iconFrame
		addCorner(frame, 3)
		return frame
	end

	if iconType == "Play" then
		block("A", UDim2.fromOffset(11, 9), UDim2.fromOffset(14, 18))
		block("B", UDim2.fromOffset(21, 14), UDim2.fromOffset(6, 8))
	elseif iconType == "Bag" then
		block("Body", UDim2.fromOffset(8, 14), UDim2.fromOffset(20, 14))
		block("HandleLeft", UDim2.fromOffset(11, 9), UDim2.fromOffset(4, 8))
		block("HandleRight", UDim2.fromOffset(21, 9), UDim2.fromOffset(4, 8))
	elseif iconType == "Grid" then
		for row = 0, 1 do
			for column = 0, 1 do
				block(
					`Cell{row}{column}`,
					UDim2.fromOffset(9 + column * 10, 9 + row * 10),
					UDim2.fromOffset(8, 8)
				)
			end
		end
	elseif iconType == "Gear" then
		block("Core", UDim2.fromOffset(13, 13), UDim2.fromOffset(10, 10))
		block("Top", UDim2.fromOffset(15, 7), UDim2.fromOffset(6, 7))
		block("Bottom", UDim2.fromOffset(15, 22), UDim2.fromOffset(6, 7))
		block("Left", UDim2.fromOffset(7, 15), UDim2.fromOffset(7, 6))
		block("Right", UDim2.fromOffset(22, 15), UDim2.fromOffset(7, 6))
	elseif iconType == "Quest" then
		block("Box", UDim2.fromOffset(9, 9), UDim2.fromOffset(18, 18))
		block("CheckA", UDim2.fromOffset(13, 18), UDim2.fromOffset(6, 5), chipColor)
		block("CheckB", UDim2.fromOffset(18, 13), UDim2.fromOffset(5, 10), chipColor)
	elseif iconType == "Gift" then
		block("Box", UDim2.fromOffset(8, 16), UDim2.fromOffset(20, 12))
		block("Lid", UDim2.fromOffset(7, 12), UDim2.fromOffset(22, 5))
		block("Ribbon", UDim2.fromOffset(16, 12), UDim2.fromOffset(4, 16), chipColor)
	elseif iconType == "Trophy" then
		block("Cup", UDim2.fromOffset(11, 8), UDim2.fromOffset(14, 12))
		block("HandleLeft", UDim2.fromOffset(7, 9), UDim2.fromOffset(4, 8))
		block("HandleRight", UDim2.fromOffset(25, 9), UDim2.fromOffset(4, 8))
		block("Stem", UDim2.fromOffset(15, 20), UDim2.fromOffset(6, 5))
		block("Base", UDim2.fromOffset(11, 25), UDim2.fromOffset(14, 4))
	else
		block("A", UDim2.fromOffset(9, 10), UDim2.fromOffset(9, 9))
		block("B", UDim2.fromOffset(19, 17), UDim2.fromOffset(9, 9))
	end

	return iconFrame
end

local function makeNavButton(parent, data, compact)
	local button = Instance.new("TextButton")
	button.Name = `{data.key}Button`
	button.AutoButtonColor = false
	button.BackgroundColor3 = data.primary and Color3.fromRGB(123, 237, 75)
		or Color3.fromRGB(22, 33, 58)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.Text = ""
	button.Selectable = true
	button.ZIndex = parent.ZIndex + 1
	button.Parent = parent
	addCorner(button, data.primary and 18 or 14)
	addStroke(
		button,
		data.primary and Color3.fromRGB(21, 116, 44) or data.accent,
		data.primary and 4 or 2,
		0
	)
	addGradient(
		button,
		data.primary and Color3.fromRGB(143, 255, 102)
			or data.accent:Lerp(Color3.fromRGB(255, 255, 255), 0.08),
		data.primary and Color3.fromRGB(73, 206, 54) or Color3.fromRGB(17, 27, 48)
	)
	makeShadow(button, data.primary and 18 or 14)

	local iconFrame = makeIcon(
		button,
		data.icon,
		data.primary and Color3.fromRGB(255, 255, 255) or data.accent,
		data.primary and Color3.fromRGB(38, 132, 62) or Color3.fromRGB(255, 255, 255)
	)
	iconFrame.Position =
		UDim2.fromOffset(data.primary and 16 or compact and 12 or 10, data.primary and 12 or 10)
	iconFrame.ZIndex = button.ZIndex + 1

	local label = makeLabel(
		button,
		"Label",
		string.upper(data.label),
		Enum.Font.GothamBlack,
		data.primary and 28 or 16,
		Color3.fromRGB(255, 255, 255)
	)
	label.Position = UDim2.fromOffset(data.primary and 66 or compact and 0 or 52, 0)
	label.Size = compact and UDim2.new(1, 0, 1, 0)
		or UDim2.new(1, data.primary and -82 or -62, 1, 0)
	label.TextXAlignment = compact and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left
	label.TextStrokeColor3 = data.primary and Color3.fromRGB(20, 112, 41)
		or Color3.fromRGB(8, 16, 34)
	label.TextStrokeTransparency = 0.28
	label.ZIndex = button.ZIndex + 1

	local badge = Instance.new("TextLabel")
	badge.Name = "NotificationBadge"
	badge.AnchorPoint = Vector2.new(1, 0)
	badge.Position = UDim2.new(1, -6, 0, -6)
	badge.Size = UDim2.fromOffset(24, 24)
	badge.BackgroundColor3 = Color3.fromRGB(255, 86, 107)
	badge.BorderSizePixel = 0
	badge.Font = Enum.Font.GothamBlack
	badge.Text = "1"
	badge.TextColor3 = Color3.fromRGB(255, 255, 255)
	badge.TextSize = 12
	badge.Visible = false
	badge.ZIndex = button.ZIndex + 3
	badge.Parent = button
	addCorner(badge, 999)
	addStroke(badge, Color3.fromRGB(122, 17, 41), 2, 0)

	return button
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
	self.resourceLabels = {}
	self.currentHubState = nil
	self.currentState = nil
	self.gameplayFocus = false

	self.menu = MenuController.new(gui, {
		isReducedMotion = self.isReducedMotion,
		playSound = self.playSound,
	})

	self:BuildBrand()
	self:BuildResourceBar()
	self:BuildLeftNav()
	self:BuildRightNav()
	self:BuildTopHud()

	connect(self, UserInputService.GamepadConnected, function()
		self:SetDefaultGamepadFocus(false)
	end)
	connect(self, gui:GetPropertyChangedSignal("AbsoluteSize"), function()
		self:RefreshResponsiveLayout()
	end)
	self:RefreshResponsiveLayout()
	self:UpdateProgression()

	return self
end

function HUDController:BuildBrand()
	local brand = Instance.new("Frame")
	brand.Name = "ArcadeBrand"
	brand.Position = UDim2.fromOffset(24, 58)
	brand.Size = UDim2.fromOffset(260, 56)
	brand.BackgroundTransparency = 1
	brand.ZIndex = UITheme.Z.hud
	brand.Parent = self.gui
	self.brand = brand

	local title = makeLabel(
		brand,
		"Title",
		"Solo Puzzle",
		Enum.Font.GothamBlack,
		26,
		Color3.fromRGB(255, 255, 255)
	)
	title.Size = UDim2.new(1, 0, 0, 30)
	title.TextStrokeColor3 = Color3.fromRGB(9, 33, 72)
	title.TextStrokeTransparency = 0.25
	self.brandTitle = title

	local subtitle = makeLabel(
		brand,
		"Subtitle",
		"Beat your best score",
		Enum.Font.GothamBold,
		15,
		Color3.fromRGB(119, 244, 255)
	)
	subtitle.Position = UDim2.fromOffset(1, 31)
	subtitle.Size = UDim2.new(1, 0, 0, 22)
	self.brandSubtitle = subtitle
end

function HUDController:BuildResourceBar()
	local bar = Instance.new("Frame")
	bar.Name = "TopResourceBar"
	bar.AnchorPoint = Vector2.new(1, 0)
	bar.Position = UDim2.new(1, -24, 0, 56)
	bar.AutomaticSize = Enum.AutomaticSize.X
	bar.Size = UDim2.fromOffset(0, 54)
	bar.BackgroundColor3 = Color3.fromRGB(18, 28, 50)
	bar.BorderSizePixel = 0
	bar.ZIndex = UITheme.Z.hud
	bar.Parent = self.gui
	addCorner(bar, 18)
	addStroke(bar, Color3.fromRGB(30, 187, 255), 2, 0.08)
	addGradient(bar, Color3.fromRGB(22, 35, 65), Color3.fromRGB(13, 21, 39))
	self.resourceBar = bar
	addPadding(bar, 12, 12, 8, 8)
	addList(
		bar,
		Enum.FillDirection.Horizontal,
		8,
		Enum.HorizontalAlignment.Center,
		Enum.VerticalAlignment.Center
	)

	for index, item in RESOURCE_ITEMS do
		local chip = Instance.new("Frame")
		chip.Name = `{item.key}Resource`
		chip.LayoutOrder = index
		chip.AutomaticSize = Enum.AutomaticSize.X
		chip.Size = UDim2.fromOffset(0, 38)
		chip.BackgroundColor3 = Color3.fromRGB(14, 23, 43)
		chip.BorderSizePixel = 0
		chip.ZIndex = bar.ZIndex + 1
		chip.Parent = bar
		addCorner(chip, 999)
		addStroke(chip, item.accent, 2, 0.04)
		addPadding(chip, 14, 16, 0, 0)
		addList(
			chip,
			Enum.FillDirection.Horizontal,
			8,
			Enum.HorizontalAlignment.Left,
			Enum.VerticalAlignment.Center
		)

		local iconDot = Instance.new("Frame")
		iconDot.Name = "Accent"
		iconDot.LayoutOrder = 1
		iconDot.Size = UDim2.fromOffset(14, 10)
		iconDot.BackgroundColor3 = item.accent
		iconDot.BorderSizePixel = 0
		iconDot.ZIndex = chip.ZIndex + 1
		iconDot.Parent = chip
		addCorner(iconDot, 3)

		local label = makeLabel(
			chip,
			"Value",
			`{item.label} 0`,
			Enum.Font.GothamBlack,
			15,
			Color3.fromRGB(255, 255, 255)
		)
		label.LayoutOrder = 2
		label.AutomaticSize = Enum.AutomaticSize.X
		label.Size = UDim2.fromOffset(0, 38)
		label.TextWrapped = false
		label.TextXAlignment = Enum.TextXAlignment.Left
		label.ZIndex = chip.ZIndex + 1
		self.resourceLabels[item.key] = label
	end
end

function HUDController:BuildLeftNav()
	local stack = Instance.new("Frame")
	stack.Name = "LeftArcadeNav"
	stack.Position = UDim2.fromOffset(24, 156)
	stack.AutomaticSize = Enum.AutomaticSize.Y
	stack.Size = UDim2.fromOffset(150, 0)
	stack.BackgroundColor3 = Color3.fromRGB(15, 25, 48)
	stack.BorderSizePixel = 0
	stack.ZIndex = UITheme.Z.hud
	stack.Parent = self.gui
	addCorner(stack, 20)
	addStroke(stack, Color3.fromRGB(30, 187, 255), 3, 0)
	makeShadow(stack, 20)
	addPadding(stack, 12, 12, 12, 12)
	addList(
		stack,
		Enum.FillDirection.Vertical,
		12,
		Enum.HorizontalAlignment.Center,
		Enum.VerticalAlignment.Top
	)
	self.leftNav = stack

	for index, data in LEFT_BUTTONS do
		local button = makeNavButton(stack, data, false)
		button.LayoutOrder = index
		button.Size = UDim2.fromOffset(126, 70)
		self.buttons[data.key] = button
		connect(self, button.Activated, function()
			self:ActivateButton(data)
		end)
	end
end

function HUDController:BuildRightNav()
	local stack = Instance.new("Frame")
	stack.Name = "RightArcadeNav"
	stack.AnchorPoint = Vector2.new(1, 0.5)
	stack.Position = UDim2.new(1, -24, 0.5, 24)
	stack.Size = UDim2.fromOffset(210, 344)
	stack.BackgroundTransparency = 1
	stack.ZIndex = UITheme.Z.hud
	stack.Parent = self.gui
	addList(
		stack,
		Enum.FillDirection.Vertical,
		14,
		Enum.HorizontalAlignment.Right,
		Enum.VerticalAlignment.Center
	)
	self.rightNav = stack

	for index, data in RIGHT_BUTTONS do
		local button = makeNavButton(stack, data, false)
		button.LayoutOrder = index
		button.Size = data.primary and UDim2.fromOffset(206, 80) or UDim2.fromOffset(180, 64)
		self.buttons[data.key] = button
		connect(self, button.Activated, function()
			self:ActivateButton(data)
		end)
	end
end

function HUDController:BuildTopHud()
	local top = Instance.new("Frame")
	top.Name = "TopQueueBanner"
	top.AnchorPoint = Vector2.new(0.5, 0)
	top.Position = UDim2.new(0.5, 0, 0, 126)
	top.Size = UDim2.fromOffset(520, 48)
	top.BackgroundColor3 = Color3.fromRGB(18, 28, 50)
	top.BackgroundTransparency = 0.04
	top.BorderSizePixel = 0
	top.Visible = false
	top.ZIndex = UITheme.Z.hud
	top.Parent = self.gui
	addCorner(top, 16)
	addStroke(top, Color3.fromRGB(30, 187, 255), 2, 0.08)
	addGradient(top, Color3.fromRGB(23, 42, 78), Color3.fromRGB(14, 23, 43))
	makeShadow(top, 16)
	self.topBar = top

	local zone = makeLabel(
		top,
		"Status",
		"Floating Hub",
		Enum.Font.GothamBlack,
		18,
		Color3.fromRGB(255, 255, 255)
	)
	zone.Position = UDim2.fromOffset(18, 0)
	zone.Size = UDim2.new(1, -136, 1, 0)
	zone.TextXAlignment = Enum.TextXAlignment.Left
	zone.ZIndex = top.ZIndex + 1
	self.zoneLabel = zone

	local cancel = Instance.new("TextButton")
	cancel.Name = "CancelQueue"
	cancel.AnchorPoint = Vector2.new(1, 0.5)
	cancel.Position = UDim2.new(1, -10, 0.5, 0)
	cancel.Size = UDim2.fromOffset(108, 32)
	cancel.AutoButtonColor = false
	cancel.BackgroundColor3 = Color3.fromRGB(255, 86, 107)
	cancel.BorderSizePixel = 0
	cancel.Font = Enum.Font.GothamBlack
	cancel.Text = "LEAVE"
	cancel.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancel.TextSize = 13
	cancel.Visible = false
	cancel.ZIndex = top.ZIndex + 1
	cancel.Parent = top
	addCorner(cancel, 10)
	addStroke(cancel, Color3.fromRGB(126, 19, 40), 2, 0)
	UITheme.attachButtonFeedback(cancel, self.isReducedMotion)
	self.cancelQueueButton = cancel
	connect(self, cancel.Activated, function()
		self.playSound("Button")
		local callback = self.callbacks.play
		if callback then
			callback()
		end
	end)
end

function HUDController:ActivateButton(data)
	self.playSound(data.comingSoon and "Blocked" or "Button")
	if self.menu then
		self.menu:Close()
	end
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
			Enum.Font.GothamBold,
			18,
			Color3.fromRGB(255, 255, 255)
		)
		label.Size = UDim2.new(1, 0, 0, 74)
		label.TextXAlignment = Enum.TextXAlignment.Center
	end)
end

function HUDController:OpenInfoPanel(title, lines)
	self.menu:Open(title, title, function(content)
		addList(
			content,
			Enum.FillDirection.Vertical,
			12,
			Enum.HorizontalAlignment.Center,
			Enum.VerticalAlignment.Top
		)
		for index, line in lines do
			local card = Instance.new("Frame")
			card.Name = `Line{index}`
			card.LayoutOrder = index
			card.Size = UDim2.new(1, 0, 0, 62)
			card.BackgroundColor3 = Color3.fromRGB(28, 44, 78)
			card.BorderSizePixel = 0
			card.Parent = content
			addCorner(card, 14)
			addStroke(card, Color3.fromRGB(72, 195, 255), 2, 0.22)
			addPadding(card, 14, 14, 8, 8)
			local label = makeLabel(
				card,
				"Text",
				line,
				Enum.Font.GothamBold,
				16,
				Color3.fromRGB(235, 246, 255)
			)
			label.Size = UDim2.fromScale(1, 1)
		end
	end)
end

function HUDController:RefreshResponsiveLayout()
	local screenSize = self.gui.AbsoluteSize
	local inset = GuiService:GetGuiInset()
	local phone = screenSize.X < 720 or screenSize.Y < 520

	if self.brand then
		self.brand.Position =
			UDim2.new(0, phone and 16 or 24, 0, math.max(inset.Y + 18, phone and 32 or 54))
		self.brand.Size = UDim2.fromOffset(phone and 210 or 280, phone and 46 or 58)
		self.brandTitle.TextSize = phone and 20 or 26
		self.brandSubtitle.TextSize = phone and 12 or 15
	end

	if self.resourceBar then
		self.resourceBar.Position = phone and UDim2.new(0, 16, 0, math.max(inset.Y + 82, 92))
			or UDim2.new(1, -24, 0, math.max(inset.Y + 18, 56))
		self.resourceBar.AnchorPoint = phone and Vector2.new(0, 0) or Vector2.new(1, 0)
		self.resourceBar.AutomaticSize = phone and Enum.AutomaticSize.None or Enum.AutomaticSize.X
		self.resourceBar.Size = phone and UDim2.new(1, -32, 0, 46) or UDim2.fromOffset(0, 54)
		for _, item in RESOURCE_ITEMS do
			local label = self.resourceLabels[item.key]
			local chip = label and label.Parent
			if chip and chip:IsA("Frame") then
				chip.Size = UDim2.fromOffset(0, phone and 32 or 38)
				label.TextSize = phone and 12 or 15
			end
		end
	end

	if self.leftNav then
		self.leftNav.Position = phone and UDim2.new(0, 16, 1, -110)
			or UDim2.new(0, 24, 0, math.max(inset.Y + 118, 156))
		self.leftNav.AutomaticSize = phone and Enum.AutomaticSize.X or Enum.AutomaticSize.Y
		self.leftNav.Size = phone and UDim2.fromOffset(0, 82) or UDim2.fromOffset(150, 0)
		local layout = self.leftNav:FindFirstChildOfClass("UIListLayout")
		if layout then
			layout.FillDirection = phone and Enum.FillDirection.Horizontal
				or Enum.FillDirection.Vertical
			layout.Padding = UDim.new(0, phone and 10 or 12)
		end
		for _, data in LEFT_BUTTONS do
			local button = self.buttons[data.key]
			if button then
				button.Size = phone and UDim2.fromOffset(100, 56) or UDim2.fromOffset(126, 70)
				local label = button:FindFirstChild("Label")
				local iconFrame = button:FindFirstChild("Icon")
				if label and label:IsA("TextLabel") then
					label.TextSize = phone and 11 or 16
					label.Position = phone and UDim2.fromOffset(0, 28) or UDim2.fromOffset(52, 0)
					label.Size = phone and UDim2.new(1, 0, 0, 24) or UDim2.new(1, -62, 1, 0)
					label.TextXAlignment = phone and Enum.TextXAlignment.Center
						or Enum.TextXAlignment.Left
				end
				if iconFrame and iconFrame:IsA("Frame") then
					iconFrame.Position = phone and UDim2.fromOffset(32, 8)
						or UDim2.fromOffset(10, 10)
					iconFrame.Size = phone and UDim2.fromOffset(28, 28) or UDim2.fromOffset(36, 36)
				end
			end
		end
	end

	if self.rightNav then
		self.rightNav.AnchorPoint = phone and Vector2.new(1, 1) or Vector2.new(1, 0.5)
		self.rightNav.Position = phone and UDim2.new(1, -16, 1, -110) or UDim2.new(1, -24, 0.5, 24)
		self.rightNav.Size = phone and UDim2.fromOffset(520, 82) or UDim2.fromOffset(210, 344)
		local layout = self.rightNav:FindFirstChildOfClass("UIListLayout")
		if layout then
			layout.FillDirection = phone and Enum.FillDirection.Horizontal
				or Enum.FillDirection.Vertical
			layout.Padding = UDim.new(0, phone and 10 or 14)
			layout.HorizontalAlignment = phone and Enum.HorizontalAlignment.Right
				or Enum.HorizontalAlignment.Right
		end
		for _, data in RIGHT_BUTTONS do
			local button = self.buttons[data.key]
			if button then
				button.Size = phone and UDim2.fromOffset(data.primary and 132 or 108, 56)
					or data.primary and UDim2.fromOffset(206, 80)
					or UDim2.fromOffset(180, 64)
				local label = button:FindFirstChild("Label")
				local iconFrame = button:FindFirstChild("Icon")
				if label and label:IsA("TextLabel") then
					label.TextSize = phone and 11 or data.primary and 28 or 16
					label.Position = phone and UDim2.fromOffset(0, 28)
						or UDim2.fromOffset(data.primary and 66 or 52, 0)
					label.Size = phone and UDim2.new(1, 0, 0, 24)
						or UDim2.new(1, data.primary and -82 or -62, 1, 0)
					label.TextXAlignment = phone and Enum.TextXAlignment.Center
						or Enum.TextXAlignment.Left
				end
				if iconFrame and iconFrame:IsA("Frame") then
					iconFrame.Position = phone
							and UDim2.fromOffset((button.Size.X.Offset - 28) / 2, 8)
						or UDim2.fromOffset(data.primary and 16 or 10, data.primary and 12 or 10)
					iconFrame.Size = phone and UDim2.fromOffset(28, 28) or UDim2.fromOffset(36, 36)
				end
			end
		end
	end

	if self.topBar then
		self.topBar.Position = UDim2.new(
			0.5,
			0,
			0,
			phone and math.max(inset.Y + 138, 148) or math.max(inset.Y + 86, 126)
		)
		self.topBar.Size =
			UDim2.fromOffset(math.clamp(screenSize.X - 36, 320, 560), phone and 44 or 48)
	end

	self:RefreshGamepadNavigation(phone)
end

function HUDController:RefreshGamepadNavigation(phone)
	local ordered = {}
	for _, data in LEFT_BUTTONS do
		local button = self.buttons[data.key]
		if button then
			table.insert(ordered, button)
		end
	end
	for _, data in RIGHT_BUTTONS do
		local button = self.buttons[data.key]
		if button then
			table.insert(ordered, button)
		end
	end

	for index, button in ordered do
		button.NextSelectionLeft = phone and ordered[index - 1] or self.buttons.play
		button.NextSelectionRight = phone and ordered[index + 1] or self.buttons.play
		button.NextSelectionUp = phone and nil or ordered[index - 1]
		button.NextSelectionDown = phone and nil or ordered[index + 1]
	end

	if phone then
		return
	end

	local leftTarget = self.buttons.modes
		or self.buttons.rewards
		or self.buttons.codes
		or self.buttons.achievements
	for index, data in RIGHT_BUTTONS do
		local button = self.buttons[data.key]
		if button then
			button.NextSelectionLeft = leftTarget
			button.NextSelectionUp = index > 1 and self.buttons[RIGHT_BUTTONS[index - 1].key] or nil
			button.NextSelectionDown = index < #RIGHT_BUTTONS
					and self.buttons[RIGHT_BUTTONS[index + 1].key]
				or nil
		end
	end
	for index, data in LEFT_BUTTONS do
		local button = self.buttons[data.key]
		if button then
			button.NextSelectionRight = self.buttons.play
			button.NextSelectionUp = index > 1 and self.buttons[LEFT_BUTTONS[index - 1].key] or nil
			button.NextSelectionDown = index < #LEFT_BUTTONS
					and self.buttons[LEFT_BUTTONS[index + 1].key]
				or nil
		end
	end
end

function HUDController:SetDefaultGamepadFocus(force)
	if self.gameplayFocus or not UserInputService.GamepadEnabled then
		return
	end
	if self.menu and self.menu.panel and self.menu.panel.Visible then
		return
	end
	if
		not force
		and GuiService.SelectedObject
		and GuiService.SelectedObject:IsDescendantOf(self.gui)
	then
		return
	end

	local target = self.buttons.play or self.buttons.modes or self.buttons.rewards
	if target and target.Visible and target.Selectable then
		GuiService.SelectedObject = target
	end
end

function HUDController:SetGameplayFocus(enabled)
	self.gameplayFocus = enabled == true
	local visible = not self.gameplayFocus
	if self.brand then
		self.brand.Visible = visible
	end
	if self.resourceBar then
		self.resourceBar.Visible = visible
	end
	if self.leftNav then
		self.leftNav.Visible = visible
	end
	if self.rightNav then
		self.rightNav.Visible = visible
	end
	if self.gameplayFocus and self.menu then
		self.menu:Close()
	elseif not self.gameplayFocus then
		self:SetDefaultGamepadFocus(false)
	end
end

function HUDController:SetMenuButtonSelected(key)
	for buttonKey, button in self.buttons do
		local selected = buttonKey == key
		local dataAccent = Color3.fromRGB(30, 187, 255)
		for _, data in LEFT_BUTTONS do
			if data.key == buttonKey then
				dataAccent = data.accent
			end
		end
		for _, data in RIGHT_BUTTONS do
			if data.key == buttonKey then
				dataAccent = data.accent
			end
		end
		local stroke = button:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Color = selected and Color3.fromRGB(255, 210, 71) or dataAccent
			stroke.Thickness = selected and 4 or buttonKey == "play" and 4 or 2
		end
		button.BackgroundTransparency = selected and 0 or 0.02
	end
end

function HUDController:SetPlayButtonState(hubState)
	local button = self.buttons.play
	if not button then
		return
	end

	local queued = hubState and hubState.queued == true
	local openArenas = hubState and hubState.openArenas or 0
	local label = button:FindFirstChild("Label")
	if label and label:IsA("TextLabel") then
		if queued and ExperienceConfig.isModeEnabled("Battle") then
			label.Text = "LEAVE"
		elseif openArenas <= 0 and ExperienceConfig.isModeEnabled("Battle") then
			label.Text = "FULL"
		else
			label.Text = "PLAY"
		end
	end
	button.BackgroundColor3 = ExperienceConfig.isModeEnabled("Solo")
			and not ExperienceConfig.isModeEnabled("Battle")
			and Color3.fromRGB(123, 237, 75)
		or queued and Color3.fromRGB(255, 89, 178)
		or openArenas <= 0 and Color3.fromRGB(88, 96, 112)
		or Color3.fromRGB(123, 237, 75)
end

function HUDController:UpdateProgression()
	local leaderstats = self.player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local xp = leaderstats and leaderstats:FindFirstChild("XP")
	local level = leaderstats and leaderstats:FindFirstChild("Level")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	local storyStars = leaderstats and leaderstats:FindFirstChild("StoryStars")
	local bestScore = leaderstats and leaderstats:FindFirstChild("BestScore")

	local levelValue = level and level.Value or 1
	local xpValue = xp and xp.Value or 0
	local coinsValue = coins and coins.Value or 0
	local winsValue = wins and wins.Value or 0
	local starsValue = storyStars and storyStars.Value or 0
	local bestValue = bestScore and bestScore.Value or 0

	if self.resourceLabels.level then
		self.resourceLabels.level.Text = `LV {levelValue}`
	end
	if self.resourceLabels.xp then
		self.resourceLabels.xp.Text = `XP {xpValue % 100}%`
	end
	if self.resourceLabels.coins then
		self.resourceLabels.coins.Text = `{coinsValue} Coins`
	end
	if self.resourceLabels.bestScore then
		self.resourceLabels.bestScore.Text = `{bestValue} Best`
	end
	if self.resourceLabels.wins then
		self.resourceLabels.wins.Text = `{winsValue} Wins`
	end
	if self.resourceLabels.stars then
		self.resourceLabels.stars.Text = `{starsValue} Stars`
	end
end

function HUDController:UpdateHubState(hubState)
	self.currentHubState = hubState
	if not hubState then
		return
	end

	if
		hubState.mode == "Battle"
		or hubState.mode == "Story"
		or hubState.mode == "Custom"
		or hubState.mode == "Solo"
	then
		self:SetGameplayFocus(true)
		self.topBar.Visible = false
		if self.cancelQueueButton then
			self.cancelQueueButton.Visible = false
		end
		return
	end

	self:SetGameplayFocus(false)
	self.topBar.Visible = hubState.queued == true
	local queueCount = hubState.queueCount or 0
	local minPlayers = hubState.minPlayers or 2
	local openArenas = hubState.openArenas or 0
	self:SetPlayButtonState(hubState)
	if self.cancelQueueButton then
		self.cancelQueueButton.Visible = hubState.queued == true
	end
	if ExperienceConfig.isModeEnabled("Solo") and not ExperienceConfig.isModeEnabled("Battle") then
		self.zoneLabel.Text = hubState.message or "Solo Puzzle Lounge"
	elseif hubState.queued then
		self.zoneLabel.Text = hubState.secondsToSoloStart
				and hubState.secondsToSoloStart > 0
				and `Queued {queueCount}/{minPlayers} - solo test in {hubState.secondsToSoloStart}s`
			or `Queued {queueCount}/{minPlayers} - waiting for players`
	elseif openArenas <= 0 then
		self.zoneLabel.Text = "Arenas are full - try Story or wait"
	else
		self.zoneLabel.Text = hubState.message or `Floating Hub - {openArenas} arena(s) open`
	end
	self:UpdateProgression()
	self:SetDefaultGamepadFocus(false)
end

function HUDController:UpdateGameState(state)
	self.currentState = state
	if not state then
		self:SetGameplayFocus(false)
		self.topBar.Visible = false
		self:SetPlayButtonState(self.currentHubState)
		self.zoneLabel.Text = "Solo Puzzle Lounge"
		return
	end

	self:SetGameplayFocus(true)
	self.topBar.Visible = false
	if self.cancelQueueButton then
		self.cancelQueueButton.Visible = false
	end
	local modeName = state.mode == "Story" and "Story Run"
		or state.mode == "Custom" and "Custom Lab"
		or state.mode == "Solo" and "Solo Puzzle"
		or "Battle"
	self.zoneLabel.Text = state.timeLeft and `{modeName} - {state.timeLeft}s`
		or state.message
		or modeName
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
	if self.brand then
		self.brand:Destroy()
	end
	if self.resourceBar then
		self.resourceBar:Destroy()
	end
	if self.leftNav then
		self.leftNav:Destroy()
	end
	if self.rightNav then
		self.rightNav:Destroy()
	end
	if self.topBar then
		self.topBar:Destroy()
	end
end

return HUDController
