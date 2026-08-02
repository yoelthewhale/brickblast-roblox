local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local UITheme = require(script.Parent.UITheme)

local ShopPanel = {}
ShopPanel.__index = ShopPanel

local CATEGORIES = { "Featured", "Passes", "Cosmetics", "Currency" }

local THEME = UITheme.Color
local SHOP_BLUE = Color3.fromRGB(34, 186, 255)
local SHOP_BLUE_DARK = Color3.fromRGB(10, 19, 42)
local SHOP_GREEN = Color3.fromRGB(106, 236, 67)
local SHOP_PURPLE = Color3.fromRGB(205, 95, 255)
local SHOP_GOLD = Color3.fromRGB(255, 215, 72)
local SHOP_RED = Color3.fromRGB(255, 69, 83)
local SHOP_TEXT = Color3.fromRGB(244, 248, 255)
local CARD_COLORS = {
	Color3.fromRGB(35, 185, 255),
	Color3.fromRGB(116, 236, 70),
	Color3.fromRGB(205, 95, 255),
	Color3.fromRGB(255, 211, 71),
}

local function safeArray(value)
	return typeof(value) == "table" and value or {}
end

local function categoryMatches(item, category)
	if category == "Featured" then
		return item.featured == true or item.category == "Featured"
	end

	return item.category == category
end

local function statusColor(state)
	if state == "Owned" or state == "Equipped" then
		return THEME.success
	elseif state == "Locked" or state == "Unavailable" then
		return THEME.warn
	elseif state == "Error" then
		return THEME.error
	end

	return THEME.button
end

local function buttonText(item)
	if item.pending then
		return "Loading..."
	elseif item.equipped then
		return "Equipped"
	elseif item.owned then
		return item.itemType == "Cosmetic" and "Equip" or "Owned"
	elseif item.state == "Locked" then
		return "Locked"
	elseif item.state == "PassRequired" then
		return "View Pass"
	elseif item.state == "Unavailable" or item.available == false then
		return "Unavailable"
	elseif item.itemType == "Cosmetic" and item.costCoins then
		return `Buy - {item.costCoins} coins`
	end

	return item.priceRobux and `Buy - R${item.priceRobux}` or "Buy"
end

function ShopPanel.new(gui, options)
	options = options or {}

	local self = setmetatable({}, ShopPanel)
	self.shopEvent = options.shopEvent
	self.playSound = options.playSound or function() end
	self.showMessage = options.showMessage or function() end
	self.openCloset = options.openCloset or function() end
	self.previewCosmetic = options.previewCosmetic or function() end
	self.stopPreview = options.stopPreview or function() end
	self.getCosmetics = options.getCosmetics or function()
		return {}
	end
	self.category = "Featured"
	self.shopState = {
		loading = true,
		gamePasses = {},
		developerProducts = {},
		message = "Loading shop...",
	}
	self.pendingPrompt = nil
	self.cardButtons = {}

	local dim = Instance.new("TextButton")
	dim.Name = "ShopDim"
	dim.BackgroundColor3 = Color3.fromRGB(6, 10, 22)
	dim.BackgroundTransparency = 0.48
	dim.BorderSizePixel = 0
	dim.Text = ""
	dim.AutoButtonColor = false
	dim.Visible = false
	dim.Size = UDim2.fromScale(1, 1)
	dim.ZIndex = 42
	dim.Parent = gui
	self.dim = dim

	local rays = Instance.new("Frame")
	rays.Name = "ShopRays"
	rays.AnchorPoint = Vector2.new(0.5, 0.5)
	rays.Position = UDim2.fromScale(0.5, 0.5)
	rays.Size = UDim2.fromOffset(760, 620)
	rays.BackgroundTransparency = 1
	rays.Visible = false
	rays.ZIndex = 43
	rays.Parent = gui
	self.rays = rays
	for index = 1, 16 do
		local ray = Instance.new("Frame")
		ray.Name = `Ray{index}`
		ray.AnchorPoint = Vector2.new(0.5, 1)
		ray.Position = UDim2.fromScale(0.5, 0.5)
		ray.Size = UDim2.fromOffset(index % 2 == 0 and 26 or 16, 360)
		ray.BackgroundColor3 = index % 2 == 0 and Color3.fromRGB(232, 190, 255)
			or Color3.fromRGB(101, 224, 255)
		ray.BackgroundTransparency = 0.82
		ray.BorderSizePixel = 0
		ray.Rotation = (index - 1) * (360 / 16)
		ray.ZIndex = 43
		ray.Parent = rays
	end

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(760, 540)
	panel.BackgroundColor3 = Color3.fromRGB(25, 18, 54)
	panel.BackgroundTransparency = 0
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.ZIndex = 45
	panel.Parent = gui
	UITheme.card(panel, {
		color = Color3.fromRGB(25, 18, 54),
		strokeColor = Color3.fromRGB(84, 222, 255),
		strokeTransparency = 0,
	})
	local panelStroke = panel:FindFirstChildOfClass("UIStroke")
	if panelStroke then
		panelStroke.Thickness = 5
	end
	self.panel = panel

	local panelScale = Instance.new("UIScale")
	panelScale.Parent = panel
	self.panelScale = panelScale

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Position = UDim2.fromOffset(0, 0)
	header.Size = UDim2.new(1, 0, 0, 70)
	header.BackgroundColor3 = Color3.fromRGB(119, 60, 214)
	header.BorderSizePixel = 0
	header.ZIndex = 46
	header.Parent = panel
	UITheme.corner(header, UITheme.Radius.md)
	UITheme.gradient(header, Color3.fromRGB(190, 91, 255), Color3.fromRGB(72, 45, 180), 90)

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(38, -18)
	title.Size = UDim2.fromOffset(320, 84)
	title.Font = Enum.Font.GothamBlack
	title.Text = "SHOP"
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.TextStrokeColor3 = Color3.fromRGB(17, 10, 44)
	title.TextStrokeTransparency = 0
	title.TextSize = 48
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 48
	title.Parent = panel

	local closeButton = Instance.new("TextButton")
	closeButton.Position = UDim2.new(1, -64, 0, -16)
	closeButton.Size = UDim2.fromOffset(60, 60)
	closeButton.BackgroundColor3 = SHOP_RED
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBlack
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextStrokeColor3 = Color3.fromRGB(124, 18, 36)
	closeButton.TextStrokeTransparency = 0.25
	closeButton.TextSize = 32
	closeButton.ZIndex = 49
	closeButton.Parent = panel
	UITheme.button(closeButton, "danger")
	closeButton.BackgroundColor3 = SHOP_RED
	local closeCorner = closeButton:FindFirstChildOfClass("UICorner")
	if closeCorner then
		closeCorner.CornerRadius = UDim.new(0, 12)
	end
	UITheme.attachButtonFeedback(closeButton)
	self.closeButton = closeButton

	local subtitle = Instance.new("TextLabel")
	subtitle.BackgroundTransparency = 1
	subtitle.Position = UDim2.fromOffset(350, 22)
	subtitle.Size = UDim2.fromOffset(330, 26)
	subtitle.Font = Enum.Font.GothamBlack
	subtitle.Text = "Server-safe upgrades"
	subtitle.TextColor3 = Color3.fromRGB(230, 249, 255)
	subtitle.TextSize = 17
	subtitle.TextWrapped = true
	subtitle.TextXAlignment = Enum.TextXAlignment.Right
	subtitle.ZIndex = 48
	subtitle.Parent = panel

	local tabFrame = Instance.new("Frame")
	tabFrame.BackgroundTransparency = 1
	tabFrame.Position = UDim2.fromOffset(18, 96)
	tabFrame.Size = UDim2.fromOffset(112, 386)
	tabFrame.ZIndex = 46
	tabFrame.Parent = panel
	self.tabFrame = tabFrame
	self.tabs = {}

	for index, category in CATEGORIES do
		local tab = Instance.new("TextButton")
		tab.Position = UDim2.fromOffset(0, (index - 1) * 84)
		tab.Size = UDim2.fromOffset(108, 72)
		tab.BackgroundColor3 = category == self.category and SHOP_PURPLE or SHOP_BLUE
		tab.BorderSizePixel = 0
		tab.Font = Enum.Font.GothamBlack
		tab.Text = category
		tab.TextColor3 = Color3.fromRGB(255, 255, 255)
		tab.TextStrokeColor3 = SHOP_BLUE_DARK
		tab.TextStrokeTransparency = 0.45
		tab.TextSize = 13
		tab.TextWrapped = true
		tab.ZIndex = 47
		tab.Parent = tabFrame
		UITheme.button(tab, category == self.category and "primary" or "secondary")
		tab.BackgroundColor3 = category == self.category and SHOP_PURPLE or SHOP_BLUE
		UITheme.attachButtonFeedback(tab)
		tab.Activated:Connect(function()
			self.playSound("Button")
			self.category = category
			self:Track("ShopTabSelected")
			self:Refresh()
		end)
		self.tabs[category] = tab
	end

	local status = Instance.new("TextLabel")
	status.BackgroundTransparency = 1
	status.Position = UDim2.fromOffset(150, 82)
	status.Size = UDim2.fromOffset(580, 24)
	status.Font = Enum.Font.GothamBold
	status.Text = "Loading shop..."
	status.TextColor3 = Color3.fromRGB(223, 238, 255)
	status.TextSize = 14
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.ZIndex = 46
	status.Parent = panel
	self.status = status

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(150, 112)
	list.Size = UDim2.fromOffset(584, 398)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.ScrollBarThickness = 6
	list.ZIndex = 46
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Parent = panel
	self.list = list

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(280, 166)
	grid.CellPadding = UDim2.fromOffset(16, 16)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = list
	self.grid = grid
	grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.fromOffset(0, grid.AbsoluteContentSize.Y + 8)
	end)

	self.updateScale = function()
		local screenSize = gui.AbsoluteSize
		local scale =
			math.clamp(math.min((screenSize.X - 44) / 760, (screenSize.Y - 64) / 540), 0.58, 1)
		panelScale.Scale = scale
		rays.Size = UDim2.fromOffset(760 * scale, 620 * scale)
		local compact = screenSize.X < 720
		if compact then
			grid.CellSize = UDim2.fromOffset(560, 150)
			list.Position = UDim2.fromOffset(104, 112)
			list.Size = UDim2.fromOffset(620, 398)
			tabFrame.Position = UDim2.fromOffset(14, 112)
			tabFrame.Size = UDim2.fromOffset(76, 360)
		else
			grid.CellSize = UDim2.fromOffset(280, 166)
			list.Position = UDim2.fromOffset(150, 112)
			list.Size = UDim2.fromOffset(584, 398)
			tabFrame.Position = UDim2.fromOffset(18, 96)
			tabFrame.Size = UDim2.fromOffset(112, 386)
		end
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(self.updateScale)
	self.updateScale()

	closeButton.Activated:Connect(function()
		self.playSound("Button")
		self:Hide()
	end)

	return self
end

function ShopPanel:itemsForCurrentCategory()
	local items = {}
	for _, pass in safeArray(self.shopState.gamePasses) do
		if categoryMatches(pass, self.category) then
			table.insert(items, pass)
		end
	end
	for _, product in safeArray(self.shopState.developerProducts) do
		if categoryMatches(product, self.category) then
			table.insert(items, product)
		end
	end
	for _, cosmetic in safeArray(self.shopState.cosmetics) do
		if categoryMatches(cosmetic, self.category) then
			table.insert(items, cosmetic)
		end
	end

	return items
end

function ShopPanel:createCard(item, index)
	local cardColor = CARD_COLORS[((index - 1) % #CARD_COLORS) + 1]
	local locked = item.state == "Locked" or item.state == "Unavailable"
	local card = Instance.new("Frame")
	card.BackgroundColor3 = locked and Color3.fromRGB(182, 197, 210) or cardColor
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.ZIndex = 47
	UITheme.card(card, {
		color = locked and Color3.fromRGB(182, 197, 210) or cardColor,
		strokeColor = statusColor(item.state),
		strokeTransparency = 0.08,
	})
	local cardStroke = card:FindFirstChildOfClass("UIStroke")
	if cardStroke then
		cardStroke.Color = locked and Color3.fromRGB(95, 114, 130) or SHOP_BLUE_DARK
		cardStroke.Thickness = 2
	end
	UITheme.gradient(
		card,
		cardColor,
		locked and Color3.fromRGB(145, 158, 173) or Color3.fromRGB(205, 250, 255),
		90
	)

	local iconBubble = Instance.new("Frame")
	iconBubble.Name = "IconBubble"
	iconBubble.Position = UDim2.fromOffset(12, 18)
	iconBubble.Size = UDim2.fromOffset(86, 86)
	iconBubble.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	iconBubble.BackgroundTransparency = 0.05
	iconBubble.BorderSizePixel = 0
	iconBubble.ZIndex = 48
	iconBubble.Parent = card
	UITheme.corner(iconBubble, UITheme.Radius.pill)
	UITheme.stroke(iconBubble, SHOP_BLUE_DARK, 2, 0.18)

	local icon = Instance.new("TextLabel")
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.fromScale(1, 1)
	icon.Font = Enum.Font.GothamBlack
	icon.Text = item.itemType == "GamePass" and "PASS"
		or item.itemType == "DeveloperProduct" and "COIN"
		or "SKIN"
	icon.TextColor3 = statusColor(item.state)
	icon.TextSize = 20
	icon.TextWrapped = true
	icon.ZIndex = 49
	icon.Parent = iconBubble

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(110, 14)
	name.Size = UDim2.new(1, -126, 0, 30)
	name.Font = Enum.Font.GothamBlack
	name.Text = item.name or "Shop Item"
	name.TextColor3 = Color3.fromRGB(255, 255, 255)
	name.TextStrokeColor3 = SHOP_BLUE_DARK
	name.TextStrokeTransparency = 0.2
	name.TextSize = 20
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.ZIndex = 48
	name.Parent = card

	local description = Instance.new("TextLabel")
	description.BackgroundTransparency = 1
	description.Position = UDim2.fromOffset(110, 44)
	description.Size = UDim2.new(1, -126, 0, 42)
	description.Font = Enum.Font.GothamBold
	description.Text = item.description or ""
	description.TextColor3 = SHOP_TEXT
	description.TextSize = 13
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.ZIndex = 48
	description.Parent = card

	local stateLabel = Instance.new("TextLabel")
	stateLabel.BackgroundTransparency = 1
	stateLabel.Position = UDim2.fromOffset(14, 114)
	stateLabel.Size = UDim2.new(1, -170, 0, 26)
	stateLabel.Font = Enum.Font.GothamBlack
	stateLabel.Text = item.unavailableReason or item.state or "Available"
	stateLabel.TextColor3 = statusColor(item.state)
	stateLabel.TextSize = 13
	stateLabel.TextTruncate = Enum.TextTruncate.AtEnd
	stateLabel.TextXAlignment = Enum.TextXAlignment.Left
	stateLabel.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
	stateLabel.TextStrokeTransparency = 0.45
	stateLabel.ZIndex = 48
	stateLabel.Parent = card

	local gift = Instance.new("TextButton")
	gift.AnchorPoint = Vector2.new(1, 1)
	gift.Position = UDim2.new(1, -126, 1, -14)
	gift.Size = UDim2.fromOffset(74, 38)
	gift.BackgroundColor3 = SHOP_BLUE
	gift.BorderSizePixel = 0
	gift.Font = Enum.Font.GothamBlack
	gift.Text = "Gift"
	gift.TextColor3 = Color3.fromRGB(255, 255, 255)
	gift.TextSize = 14
	gift.Selectable = true
	gift.ZIndex = 48
	gift.Parent = card
	UITheme.button(gift, "primary")
	gift.BackgroundColor3 = SHOP_BLUE
	UITheme.attachButtonFeedback(gift)
	table.insert(self.cardButtons, gift)
	gift.Activated:Connect(function()
		self.playSound("Blocked")
		self.showMessage("Gifting is planned for a later shop update.", THEME.warn)
	end)

	local action = Instance.new("TextButton")
	action.AnchorPoint = Vector2.new(1, 1)
	action.Position = UDim2.new(1, -14, 1, -14)
	action.Size = UDim2.fromOffset(104, 38)
	action.BackgroundColor3 = SHOP_GREEN
	action.BorderSizePixel = 0
	action.Font = Enum.Font.GothamBlack
	action.Text = buttonText(item)
	action.TextColor3 = Color3.fromRGB(255, 255, 255)
	action.TextStrokeColor3 = Color3.fromRGB(19, 110, 28)
	action.TextStrokeTransparency = 0.28
	action.TextSize = 14
	action.TextWrapped = true
	action.Selectable = true
	action.ZIndex = 48
	action.Parent = card
	UITheme.button(action, (item.owned or item.equipped) and "success" or "primary")
	UITheme.attachButtonFeedback(action)
	table.insert(self.cardButtons, action)

	if item.owned or item.equipped then
		action.BackgroundColor3 = THEME.success
	elseif item.available == false or item.state == "Locked" or item.pending then
		action.BackgroundColor3 = THEME.buttonMuted
	else
		action.BackgroundColor3 = SHOP_GREEN
	end

	action.Activated:Connect(function()
		self:activateItem(item)
	end)

	if item.itemType == "Cosmetic" then
		local preview = Instance.new("TextButton")
		preview.Position = UDim2.fromOffset(110, 92)
		preview.Size = UDim2.fromOffset(86, 30)
		preview.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		preview.BorderSizePixel = 0
		preview.Font = Enum.Font.GothamBold
		preview.Text = "Preview"
		preview.TextColor3 = SHOP_TEXT
		preview.TextSize = 12
		preview.Selectable = true
		preview.ZIndex = 48
		preview.Parent = card
		UITheme.button(preview, "secondary")
		UITheme.attachButtonFeedback(preview)
		table.insert(self.cardButtons, preview)
		preview.Activated:Connect(function()
			self.playSound("Button")
			self:Track("CosmeticPreviewed")
			self.previewCosmetic(item)
		end)
	end

	return card
end

function ShopPanel:activateItem(item)
	if item.itemType == "Cosmetic" then
		if item.equipped then
			self.playSound("Button")
			self.showMessage(`${item.name} is equipped.`, THEME.success)
			return
		elseif item.owned then
			self.pendingPrompt = item.id
			self.playSound("Button")
			self.shopEvent:FireServer("EquipCosmetic", {
				id = item.id,
			})
			self:Refresh()
			return
		elseif item.state == "Available" and item.costCoins then
			self.pendingPrompt = item.id
			self.playSound("Button")
			self:Track("CosmeticPurchaseAttempted")
			self.shopEvent:FireServer("PurchaseCosmetic", {
				id = item.id,
			})
			self:Refresh()
			return
		elseif item.state == "PassRequired" and item.requiredGamePass then
			self.pendingPrompt = item.requiredGamePass
			self.playSound("Button")
			self:Track("GamePassPromptOpened")
			self.shopEvent:FireServer("RequestPrompt", {
				itemType = "GamePass",
				id = item.requiredGamePass,
			})
			self:Refresh()
			return
		elseif item.state == "Locked" then
			self.playSound("Blocked")
			self.showMessage(item.unavailableReason or "Cosmetic locked.", THEME.warn)
			return
		end

		self.playSound("Blocked")
		self.showMessage(item.unavailableReason or "Cosmetic unavailable.", THEME.warn)
		return
	end

	if item.owned then
		self.playSound("Button")
		self.showMessage(`${item.name} already owned.`, THEME.success)
		return
	end

	if item.available == false then
		self.playSound("Blocked")
		self.showMessage(item.unavailableReason or "This item is unavailable.", THEME.warn)
		return
	end

	if self.pendingPrompt then
		self.playSound("Blocked")
		self.showMessage("Finish the current purchase prompt first.", THEME.warn)
		return
	end

	self.pendingPrompt = item.id
	self.playSound("Button")
	if item.itemType == "GamePass" then
		self:Track("GamePassPromptOpened")
	end
	self.shopEvent:FireServer("RequestPrompt", {
		itemType = item.itemType,
		id = item.id,
	})
	self:Refresh()
end

function ShopPanel:Refresh()
	for _, child in self.list:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
	self.cardButtons = {}

	for category, tab in self.tabs do
		tab.BackgroundColor3 = category == self.category and SHOP_PURPLE or SHOP_BLUE
		local stroke = tab:FindFirstChildOfClass("UIStroke")
		if stroke then
			stroke.Transparency = category == self.category and 0.04 or 0.34
			stroke.Color = category == self.category and SHOP_GOLD or SHOP_BLUE_DARK
		end
	end

	self.status.Text = self.shopState.message or "Choose an item."
	local items = self:itemsForCurrentCategory()
	if self.shopState.loading then
		items = {
			{
				name = "Loading shop...",
				description = "Checking server-authoritative ownership and product availability.",
				state = "Loading",
				available = false,
			},
		}
	elseif #items == 0 then
		items = {
			{
				name = "Nothing here yet",
				description = "This category is ready for future inventory and shop rotations.",
				state = "Unavailable",
				available = false,
			},
		}
	end

	for index, item in items do
		item.pending = self.pendingPrompt == item.id
		self:createCard(item, index).Parent = self.list
	end
end

function ShopPanel:HandleServerMessage(message)
	if typeof(message) ~= "table" then
		return
	end

	if message.kind == "Snapshot" and typeof(message.shop) == "table" then
		self.shopState = message.shop
		self.shopState.loading = false
		self.pendingPrompt = message.shop.pendingId
		self:Refresh()
	elseif message.kind == "PromptApproved" then
		if message.itemType == "GamePass" then
			MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, message.marketplaceId)
		elseif message.itemType == "DeveloperProduct" then
			MarketplaceService:PromptProductPurchase(Players.LocalPlayer, message.marketplaceId)
		end
	elseif message.kind == "Error" then
		self.pendingPrompt = nil
		self.showMessage(message.message or "Shop error.", THEME.error)
		self:Refresh()
	end
end

function ShopPanel:Track(eventName)
	self.shopEvent:FireServer("Track", {
		event = eventName,
	})
end

function ShopPanel:Hide()
	self.stopPreview()
	self.panel.Visible = false
	self.dim.Visible = false
	self.rays.Visible = false
end

function ShopPanel:Show(category)
	self.category = category or self.category
	self.shopState.loading = #safeArray(self.shopState.gamePasses) == 0
	self:Refresh()
	self.updateScale()
	self.dim.Visible = true
	self.rays.Visible = true
	self.panel.Visible = true
	self:Track("ShopOpened")
	self.shopEvent:FireServer("RequestSnapshot")

	if UserInputService.GamepadEnabled and self.closeButton then
		GuiService.SelectedObject = self.closeButton
	end
end

return ShopPanel
