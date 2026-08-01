local GuiService = game:GetService("GuiService")
local UserInputService = game:GetService("UserInputService")

local UITheme = require(script.Parent.UITheme)

local CosmeticPanel = {}
CosmeticPanel.__index = CosmeticPanel

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

local function requirementText(requirement)
	return requirement and requirement.label or "Free"
end

local function setCardState(card, unlocked, equipped)
	if equipped then
		card.BackgroundColor3 = UITheme.Color.primary
	elseif unlocked then
		card.BackgroundColor3 = UITheme.Color.panelSoft
	else
		card.BackgroundColor3 = UITheme.Color.cardMuted
	end

	local stroke = card:FindFirstChildOfClass("UIStroke")
	if stroke then
		stroke.Color = equipped and Color3.fromRGB(156, 211, 255)
			or unlocked and UITheme.Color.strokeSoft
			or UITheme.Color.warning
		stroke.Transparency = equipped and 0.08 or unlocked and 0.38 or 0.52
	end
end

function CosmeticPanel.new(gui, blocks, config, options)
	options = options or {}

	local self = setmetatable({}, CosmeticPanel)
	self.blocks = blocks
	self.config = config
	self.getProgress = options.getProgress or function()
		return {}
	end
	self.getPieceSkin = options.getPieceSkin or function()
		return "Rainbow"
	end
	self.getBoardSkin = options.getBoardSkin or function()
		return "Auto"
	end
	self.selectPieceSkin = options.selectPieceSkin or function() end
	self.selectBoardSkin = options.selectBoardSkin or function() end
	self.playSound = options.playSound or function() end
	self.showMessage = options.showMessage or function() end
	self.pieceCards = {}
	self.boardCards = {}

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(520, 340)
	panel.BackgroundColor3 = Color3.fromRGB(14, 18, 27)
	panel.BackgroundTransparency = 0.03
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.ZIndex = 38
	panel.Parent = gui
	UITheme.panel(panel, { color = UITheme.Color.panel, bottomColor = UITheme.Color.background })
	self.panel = panel

	local panelScale = Instance.new("UIScale")
	panelScale.Scale = 1
	panelScale.Parent = panel
	self.panelScale = panelScale
	self.updateScale = function()
		local screenSize = gui.AbsoluteSize
		panelScale.Scale =
			math.clamp(math.min((screenSize.X - 24) / 520, (screenSize.Y - 48) / 340), 0.72, 1)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(self.updateScale)
	self.updateScale()

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(18, 14)
	title.Size = UDim2.fromOffset(420, 30)
	title.Font = Enum.Font.GothamBlack
	title.Text = "Cosmetic Closet"
	title.TextColor3 = Color3.fromRGB(245, 247, 251)
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 39
	title.Parent = panel
	UITheme.text(title, "title")

	local closeButton = Instance.new("TextButton")
	closeButton.Position = UDim2.new(1, -48, 0, 14)
	closeButton.Size = UDim2.fromOffset(32, 32)
	closeButton.BackgroundColor3 = Color3.fromRGB(45, 58, 82)
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBlack
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(245, 247, 251)
	closeButton.TextSize = 16
	closeButton.ZIndex = 39
	closeButton.Parent = panel
	UITheme.closeButton(closeButton)
	UITheme.attachButtonFeedback(closeButton)
	self.closeButton = closeButton

	local piecesHeader = Instance.new("TextLabel")
	piecesHeader.BackgroundTransparency = 1
	piecesHeader.Position = UDim2.fromOffset(18, 54)
	piecesHeader.Size = UDim2.fromOffset(240, 20)
	piecesHeader.Font = Enum.Font.GothamBold
	piecesHeader.Text = "Piece Styles"
	piecesHeader.TextColor3 = Color3.fromRGB(193, 201, 215)
	piecesHeader.TextSize = 15
	piecesHeader.TextXAlignment = Enum.TextXAlignment.Left
	piecesHeader.ZIndex = 39
	piecesHeader.Parent = panel
	UITheme.text(piecesHeader, "muted")

	local boardsHeader = Instance.new("TextLabel")
	boardsHeader.BackgroundTransparency = 1
	boardsHeader.Position = UDim2.fromOffset(18, 176)
	boardsHeader.Size = UDim2.fromOffset(240, 20)
	boardsHeader.Font = Enum.Font.GothamBold
	boardsHeader.Text = "Board Skins"
	boardsHeader.TextColor3 = Color3.fromRGB(193, 201, 215)
	boardsHeader.TextSize = 15
	boardsHeader.TextXAlignment = Enum.TextXAlignment.Left
	boardsHeader.ZIndex = 39
	boardsHeader.Parent = panel
	UITheme.text(boardsHeader, "muted")

	for index, skinName in blocks.PieceSkins do
		local card = self:createPieceCard(index, skinName)
		card.Parent = panel
		self.pieceCards[index] = card
	end

	for index, skin in config.BoardSkins do
		local card = self:createBoardCard(index, skin)
		card.Parent = panel
		self.boardCards[index] = card
	end
	self:ConfigureFocus()

	closeButton.Activated:Connect(function()
		self.playSound("Button")
		self:Hide()
	end)

	return self
end

function CosmeticPanel:ConfigureFocus()
	local pieceCards = self.pieceCards
	local boardCards = self.boardCards
	if self.closeButton and pieceCards[1] then
		self.closeButton.NextSelectionDown = pieceCards[1]
	end

	for index, card in pieceCards do
		card.NextSelectionLeft = pieceCards[index - 1]
		card.NextSelectionRight = pieceCards[index + 1]
		card.NextSelectionUp = self.closeButton
		card.NextSelectionDown = boardCards[math.min(index, #boardCards)]
	end

	for index, card in boardCards do
		card.NextSelectionLeft = boardCards[index - 1]
		card.NextSelectionRight = boardCards[index + 1]
		card.NextSelectionUp = pieceCards[math.min(index, #pieceCards)]
	end
end

function CosmeticPanel:createPieceCard(index, skinName)
	local card = Instance.new("TextButton")
	card.Position = UDim2.fromOffset(18 + ((index - 1) * 122), 80)
	card.Size = UDim2.fromOffset(112, 74)
	card.BorderSizePixel = 0
	card.Font = Enum.Font.GothamBold
	card.Text = ""
	card.ZIndex = 39
	UITheme.button(card, "secondary")
	UITheme.attachButtonFeedback(card)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(8, 7)
	nameLabel.Size = UDim2.fromOffset(96, 18)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = skinName
	nameLabel.TextColor3 = Color3.fromRGB(245, 247, 251)
	nameLabel.TextSize = 13
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 40
	nameLabel.Parent = card
	UITheme.text(nameLabel, "heading")

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.BackgroundTransparency = 1
	statusLabel.Position = UDim2.fromOffset(8, 50)
	statusLabel.Size = UDim2.fromOffset(96, 18)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextColor3 = Color3.fromRGB(210, 224, 255)
	statusLabel.TextSize = 11
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.ZIndex = 40
	statusLabel.Parent = card
	UITheme.text(statusLabel, "soft")

	local colors = previewColorsForPieceSkin(skinName)
	for swatchIndex = 1, 4 do
		local swatch = Instance.new("Frame")
		swatch.Position = UDim2.fromOffset(8 + ((swatchIndex - 1) * 18), 31)
		swatch.Size = UDim2.fromOffset(14, 14)
		swatch.BackgroundColor3 = colors[swatchIndex]
		swatch.BorderSizePixel = 0
		swatch.ZIndex = 40
		swatch.Parent = card
	end

	card.Activated:Connect(function()
		local requirement = self.config.PieceSkinUnlocks[skinName]
		local unlocked = self.config.meetsCosmeticRequirement(requirement, self.getProgress())
		if not unlocked then
			self.playSound("Blocked")
			self.showMessage(`Locked: {requirementText(requirement)}`, Color3.fromRGB(251, 146, 60))
			return
		end

		self.playSound("Button")
		self.selectPieceSkin(index)
		self:Refresh()
	end)

	return card
end

function CosmeticPanel:createBoardCard(index, skin)
	local card = Instance.new("TextButton")
	card.Position = UDim2.fromOffset(18 + ((index - 1) * 98), 202)
	card.Size = UDim2.fromOffset(88, 78)
	card.BorderSizePixel = 0
	card.Font = Enum.Font.GothamBold
	card.Text = ""
	card.ZIndex = 39
	UITheme.button(card, "secondary")
	UITheme.attachButtonFeedback(card)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(7, 7)
	nameLabel.Size = UDim2.fromOffset(74, 18)
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = skin.name
	nameLabel.TextColor3 = Color3.fromRGB(245, 247, 251)
	nameLabel.TextSize = 12
	nameLabel.TextWrapped = true
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 40
	nameLabel.Parent = card
	UITheme.text(nameLabel, "heading")

	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "Status"
	statusLabel.BackgroundTransparency = 1
	statusLabel.Position = UDim2.fromOffset(7, 56)
	statusLabel.Size = UDim2.fromOffset(74, 16)
	statusLabel.Font = Enum.Font.Gotham
	statusLabel.TextColor3 = Color3.fromRGB(210, 224, 255)
	statusLabel.TextSize = 10
	statusLabel.TextWrapped = true
	statusLabel.TextXAlignment = Enum.TextXAlignment.Left
	statusLabel.ZIndex = 40
	statusLabel.Parent = card
	UITheme.text(statusLabel, "soft")

	local emptyColor = skin.empty or Color3.fromRGB(24, 28, 36)
	local borderColor = skin.border or Color3.fromRGB(64, 156, 255)
	for row = 1, 2 do
		for column = 1, 3 do
			local cell = Instance.new("Frame")
			cell.Position = UDim2.fromOffset(8 + ((column - 1) * 15), 30 + ((row - 1) * 15))
			cell.Size = UDim2.fromOffset(12, 12)
			cell.BackgroundColor3 = row == 1 and column == 3 and borderColor or emptyColor
			cell.BorderSizePixel = 0
			cell.ZIndex = 40
			cell.Parent = card
		end
	end

	card.Activated:Connect(function()
		local requirement = self.config.BoardSkinUnlocks[skin.name]
		local unlocked = self.config.meetsCosmeticRequirement(requirement, self.getProgress())
		if not unlocked then
			self.playSound("Blocked")
			self.showMessage(`Locked: {requirementText(requirement)}`, Color3.fromRGB(251, 146, 60))
			return
		end

		self.playSound("Button")
		self.selectBoardSkin(index)
		self:Refresh()
	end)

	return card
end

function CosmeticPanel:Hide()
	self.panel.Visible = false
end

function CosmeticPanel:Show()
	self:Refresh()
	self.updateScale()
	self.panel.Visible = true
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = self.pieceCards[1] or self.closeButton
	end
end

function CosmeticPanel:Refresh()
	local progress = self.getProgress()
	local currentPieceSkin = self.getPieceSkin()
	local currentBoardSkin = self.getBoardSkin()

	for index, skinName in self.blocks.PieceSkins do
		local card = self.pieceCards[index]
		local requirement = self.config.PieceSkinUnlocks[skinName]
		local unlocked = self.config.meetsCosmeticRequirement(requirement, progress)
		local equipped = skinName == currentPieceSkin
		setCardState(card, unlocked, equipped)
		card.Status.Text = equipped and "Equipped"
			or unlocked and "Unlocked"
			or requirementText(requirement)
	end

	for index, skin in self.config.BoardSkins do
		local card = self.boardCards[index]
		local requirement = self.config.BoardSkinUnlocks[skin.name]
		local unlocked = self.config.meetsCosmeticRequirement(requirement, progress)
		local equipped = skin.name == currentBoardSkin
		setCardState(card, unlocked, equipped)
		card.Status.Text = equipped and "Equipped"
			or unlocked and "Unlocked"
			or requirementText(requirement)
	end
end

return CosmeticPanel
