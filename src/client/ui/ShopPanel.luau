local GuiService = game:GetService("GuiService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local ShopPanel = {}
ShopPanel.__index = ShopPanel

local CATEGORIES = { "Featured", "Passes", "Cosmetics", "Currency" }

local THEME = {
	panel = Color3.fromRGB(12, 16, 24),
	card = Color3.fromRGB(26, 32, 43),
	cardMuted = Color3.fromRGB(19, 23, 31),
	button = Color3.fromRGB(64, 156, 255),
	buttonMuted = Color3.fromRGB(45, 58, 82),
	success = Color3.fromRGB(74, 222, 128),
	warn = Color3.fromRGB(251, 146, 60),
	error = Color3.fromRGB(224, 74, 74),
	text = Color3.fromRGB(245, 247, 251),
	muted = Color3.fromRGB(193, 201, 215),
	soft = Color3.fromRGB(153, 163, 179),
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

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(620, 430)
	panel.BackgroundColor3 = THEME.panel
	panel.BackgroundTransparency = 0.02
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.ZIndex = 45
	panel.Parent = gui
	self.panel = panel

	local panelScale = Instance.new("UIScale")
	panelScale.Parent = panel
	self.panelScale = panelScale

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(18, 14)
	title.Size = UDim2.fromOffset(480, 28)
	title.Font = Enum.Font.GothamBlack
	title.Text = "Battle Shop"
	title.TextColor3 = THEME.text
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 46
	title.Parent = panel

	local closeButton = Instance.new("TextButton")
	closeButton.Position = UDim2.new(1, -50, 0, 14)
	closeButton.Size = UDim2.fromOffset(34, 34)
	closeButton.BackgroundColor3 = THEME.buttonMuted
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBlack
	closeButton.Text = "X"
	closeButton.TextColor3 = THEME.text
	closeButton.TextSize = 16
	closeButton.ZIndex = 47
	closeButton.Parent = panel
	self.closeButton = closeButton

	local subtitle = Instance.new("TextLabel")
	subtitle.BackgroundTransparency = 1
	subtitle.Position = UDim2.fromOffset(18, 46)
	subtitle.Size = UDim2.fromOffset(560, 34)
	subtitle.Font = Enum.Font.Gotham
	subtitle.Text = "Passes and currency are server-validated before any purchase prompt opens."
	subtitle.TextColor3 = THEME.muted
	subtitle.TextSize = 14
	subtitle.TextWrapped = true
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.ZIndex = 46
	subtitle.Parent = panel

	local tabFrame = Instance.new("Frame")
	tabFrame.BackgroundTransparency = 1
	tabFrame.Position = UDim2.fromOffset(18, 88)
	tabFrame.Size = UDim2.fromOffset(584, 40)
	tabFrame.ZIndex = 46
	tabFrame.Parent = panel
	self.tabFrame = tabFrame
	self.tabs = {}

	for index, category in CATEGORIES do
		local tab = Instance.new("TextButton")
		tab.Position = UDim2.fromOffset((index - 1) * 146, 0)
		tab.Size = UDim2.fromOffset(136, 38)
		tab.BackgroundColor3 = category == self.category and THEME.button or THEME.buttonMuted
		tab.BorderSizePixel = 0
		tab.Font = Enum.Font.GothamBold
		tab.Text = category
		tab.TextColor3 = THEME.text
		tab.TextSize = 14
		tab.ZIndex = 47
		tab.Parent = tabFrame
		tab.MouseButton1Click:Connect(function()
			self.playSound("Button")
			self.category = category
			self:Track("ShopTabSelected")
			self:Refresh()
		end)
		self.tabs[category] = tab
	end

	local status = Instance.new("TextLabel")
	status.BackgroundTransparency = 1
	status.Position = UDim2.fromOffset(18, 132)
	status.Size = UDim2.fromOffset(584, 22)
	status.Font = Enum.Font.GothamBold
	status.Text = "Loading shop..."
	status.TextColor3 = THEME.soft
	status.TextSize = 13
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.ZIndex = 46
	status.Parent = panel
	self.status = status

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(18, 160)
	list.Size = UDim2.fromOffset(584, 248)
	list.BackgroundTransparency = 1
	list.BorderSizePixel = 0
	list.CanvasSize = UDim2.fromOffset(0, 0)
	list.ScrollBarThickness = 6
	list.ZIndex = 46
	list.Parent = panel
	self.list = list

	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(276, 118)
	grid.CellPadding = UDim2.fromOffset(12, 12)
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = list
	self.grid = grid
	grid:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		list.CanvasSize = UDim2.fromOffset(0, grid.AbsoluteContentSize.Y + 8)
	end)

	self.updateScale = function()
		local screenSize = gui.AbsoluteSize
		local scale =
			math.clamp(math.min((screenSize.X - 24) / 620, (screenSize.Y - 48) / 430), 0.68, 1)
		panelScale.Scale = scale
		local compact = screenSize.X < 720
		if compact then
			grid.CellSize = UDim2.fromOffset(560, 126)
			list.Size = UDim2.fromOffset(584, 248)
		else
			grid.CellSize = UDim2.fromOffset(276, 118)
			list.Size = UDim2.fromOffset(584, 248)
		end
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(self.updateScale)
	self.updateScale()

	closeButton.MouseButton1Click:Connect(function()
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
	local card = Instance.new("Frame")
	card.BackgroundColor3 = (item.state == "Locked" or item.state == "Unavailable")
			and THEME.cardMuted
		or THEME.card
	card.BorderSizePixel = 0
	card.LayoutOrder = index
	card.ZIndex = 47

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(12, 10)
	name.Size = UDim2.new(1, -24, 0, 22)
	name.Font = Enum.Font.GothamBlack
	name.Text = item.name or "Shop Item"
	name.TextColor3 = THEME.text
	name.TextSize = 16
	name.TextTruncate = Enum.TextTruncate.AtEnd
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.ZIndex = 48
	name.Parent = card

	local description = Instance.new("TextLabel")
	description.BackgroundTransparency = 1
	description.Position = UDim2.fromOffset(12, 34)
	description.Size = UDim2.new(1, -24, 0, 34)
	description.Font = Enum.Font.Gotham
	description.Text = item.description or ""
	description.TextColor3 = THEME.muted
	description.TextSize = 12
	description.TextWrapped = true
	description.TextXAlignment = Enum.TextXAlignment.Left
	description.TextYAlignment = Enum.TextYAlignment.Top
	description.ZIndex = 48
	description.Parent = card

	local stateLabel = Instance.new("TextLabel")
	stateLabel.BackgroundTransparency = 1
	stateLabel.Position = UDim2.fromOffset(12, 72)
	stateLabel.Size = UDim2.new(1, -142, 0, 18)
	stateLabel.Font = Enum.Font.GothamBold
	stateLabel.Text = item.unavailableReason or item.state or "Available"
	stateLabel.TextColor3 = statusColor(item.state)
	stateLabel.TextSize = 12
	stateLabel.TextTruncate = Enum.TextTruncate.AtEnd
	stateLabel.TextXAlignment = Enum.TextXAlignment.Left
	stateLabel.ZIndex = 48
	stateLabel.Parent = card

	local action = Instance.new("TextButton")
	action.AnchorPoint = Vector2.new(1, 1)
	action.Position = UDim2.new(1, -12, 1, -12)
	action.Size = UDim2.fromOffset(124, 40)
	action.BackgroundColor3 = statusColor(item.state)
	action.BorderSizePixel = 0
	action.Font = Enum.Font.GothamBold
	action.Text = buttonText(item)
	action.TextColor3 = THEME.text
	action.TextSize = 13
	action.TextWrapped = true
	action.Selectable = true
	action.ZIndex = 48
	action.Parent = card
	table.insert(self.cardButtons, action)

	if item.owned or item.equipped then
		action.BackgroundColor3 = THEME.success
	elseif item.available == false or item.state == "Locked" or item.pending then
		action.BackgroundColor3 = THEME.buttonMuted
	end

	action.MouseButton1Click:Connect(function()
		self:activateItem(item)
	end)

	if item.itemType == "Cosmetic" then
		local preview = Instance.new("TextButton")
		preview.AnchorPoint = Vector2.new(1, 1)
		preview.Position = UDim2.new(1, -146, 1, -12)
		preview.Size = UDim2.fromOffset(86, 40)
		preview.BackgroundColor3 = THEME.buttonMuted
		preview.BorderSizePixel = 0
		preview.Font = Enum.Font.GothamBold
		preview.Text = "Preview"
		preview.TextColor3 = THEME.text
		preview.TextSize = 13
		preview.Selectable = true
		preview.ZIndex = 48
		preview.Parent = card
		table.insert(self.cardButtons, preview)
		preview.MouseButton1Click:Connect(function()
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
		tab.BackgroundColor3 = category == self.category and THEME.button or THEME.buttonMuted
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
end

function ShopPanel:Show(category)
	self.category = category or self.category
	self.shopState.loading = #safeArray(self.shopState.gamePasses) == 0
	self:Refresh()
	self.updateScale()
	self.panel.Visible = true
	self:Track("ShopOpened")
	self.shopEvent:FireServer("RequestSnapshot")

	if UserInputService.GamepadEnabled and self.closeButton then
		GuiService.SelectedObject = self.closeButton
	end
end

return ShopPanel
