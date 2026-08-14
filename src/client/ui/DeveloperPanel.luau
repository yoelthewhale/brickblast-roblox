local DeveloperPanel = {}
DeveloperPanel.__index = DeveloperPanel

local PALETTE = {
	panel = Color3.fromRGB(244, 248, 255),
	card = Color3.fromRGB(255, 255, 255),
	text = Color3.fromRGB(15, 27, 48),
	muted = Color3.fromRGB(77, 91, 116),
	rim = Color3.fromRGB(44, 133, 201),
	warningFill = Color3.fromRGB(255, 229, 99),
	warningText = Color3.fromRGB(61, 36, 0),
	close = Color3.fromRGB(195, 47, 69),
}

local BUTTON_STYLES = {
	diagnostic = {
		base = Color3.fromRGB(226, 243, 255),
		hover = Color3.fromRGB(207, 233, 252),
		pressed = Color3.fromRGB(181, 218, 247),
		stroke = Color3.fromRGB(44, 133, 201),
		text = Color3.fromRGB(13, 67, 111),
	},
	setup = {
		base = Color3.fromRGB(230, 248, 237),
		hover = Color3.fromRGB(209, 238, 221),
		pressed = Color3.fromRGB(183, 225, 201),
		stroke = Color3.fromRGB(50, 145, 91),
		text = Color3.fromRGB(19, 86, 48),
	},
	destructive = {
		base = Color3.fromRGB(255, 232, 232),
		hover = Color3.fromRGB(255, 214, 214),
		pressed = Color3.fromRGB(248, 191, 191),
		stroke = Color3.fromRGB(190, 66, 77),
		text = Color3.fromRGB(113, 31, 36),
	},
	primary = {
		base = Color3.fromRGB(56, 115, 206),
		hover = Color3.fromRGB(69, 133, 224),
		pressed = Color3.fromRGB(40, 91, 172),
		stroke = Color3.fromRGB(18, 68, 151),
		text = Color3.fromRGB(255, 255, 255),
	},
	close = {
		base = PALETTE.close,
		hover = Color3.fromRGB(219, 64, 85),
		pressed = Color3.fromRGB(154, 36, 52),
		stroke = Color3.fromRGB(112, 27, 40),
		text = Color3.fromRGB(255, 255, 255),
	},
}

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
	stroke.Parent = parent
	return stroke
end

local function addPadding(parent, left, right, top, bottom)
	local padding = Instance.new("UIPadding")
	padding.PaddingLeft = UDim.new(0, left)
	padding.PaddingRight = UDim.new(0, right)
	padding.PaddingTop = UDim.new(0, top)
	padding.PaddingBottom = UDim.new(0, bottom)
	padding.Parent = parent
	return padding
end

local function makeLabel(parent, text, size, position, options)
	options = options or {}
	local label = Instance.new("TextLabel")
	label.Name = options.name or "TextLabel"
	label.BackgroundTransparency = options.backgroundTransparency or 1
	label.Font = options.font or Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = options.color or PALETTE.text
	label.TextSize = options.textSize or 14
	label.TextWrapped = true
	label.TextXAlignment = options.xAlignment or Enum.TextXAlignment.Left
	label.TextYAlignment = options.yAlignment or Enum.TextYAlignment.Center
	label.Position = position or UDim2.fromOffset(0, 0)
	label.Size = size
	label.ZIndex = options.zIndex or 39
	label.Parent = parent
	if options.backgroundColor then
		label.BackgroundColor3 = options.backgroundColor
	end
	return label
end

local function styleButton(button, styleName)
	local style = BUTTON_STYLES[styleName] or BUTTON_STYLES.setup
	button.AutoButtonColor = false
	button.BackgroundColor3 = style.base
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.TextColor3 = style.text
	button.TextSize = 13
	button.TextWrapped = true
	button.ZIndex = 41
	addCorner(button, 8)
	local stroke = addStroke(button, style.stroke, 1.5, 0)

	button.MouseEnter:Connect(function()
		button.BackgroundColor3 = style.hover
		stroke.Thickness = 2
	end)
	button.MouseLeave:Connect(function()
		button.BackgroundColor3 = style.base
		stroke.Thickness = 1.5
	end)
	button.MouseButton1Down:Connect(function()
		button.BackgroundColor3 = style.pressed
		stroke.Thickness = 2.5
	end)
	button.MouseButton1Up:Connect(function()
		button.BackgroundColor3 = style.hover
		stroke.Thickness = 2
	end)
end

local function makeButton(parent, text, commandFactory, styleName, name)
	local button = Instance.new("TextButton")
	button.Name = name or "DeveloperCommandButton"
	button.Text = text
	button.Size = UDim2.new(1, 0, 0, 32)
	button.Parent = parent
	styleButton(button, styleName)
	button.Activated:Connect(function()
		commandFactory()
	end)
	return button
end

local function makeSection(parent, title, detail)
	local section = Instance.new("Frame")
	section.Name = title:gsub("%s+", "") .. "Section"
	section.AutomaticSize = Enum.AutomaticSize.Y
	section.BackgroundColor3 = PALETTE.card
	section.BorderSizePixel = 0
	section.Size = UDim2.new(1, -8, 0, 0)
	section.ZIndex = 40
	section.Parent = parent
	addCorner(section, 8)
	addStroke(section, Color3.fromRGB(189, 207, 230), 1, 0)
	addPadding(section, 10, 10, 8, 10)

	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 6)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = section

	local heading = makeLabel(section, title, UDim2.new(1, 0, 0, 19), nil, {
		name = "SectionHeading",
		color = PALETTE.text,
		textSize = 15,
		zIndex = 41,
	})
	heading.LayoutOrder = 1

	if detail and detail ~= "" then
		local purpose = makeLabel(section, detail, UDim2.new(1, 0, 0, 34), nil, {
			name = "SectionDetail",
			color = PALETTE.muted,
			font = Enum.Font.GothamMedium,
			textSize = 12,
			yAlignment = Enum.TextYAlignment.Top,
			zIndex = 41,
		})
		purpose.LayoutOrder = 2
	end

	return section
end

local function commandButtonName(text)
	return "DevCommand" .. text:gsub("[^%w]", "")
end

function DeveloperPanel.new(options)
	local self = setmetatable({}, DeveloperPanel)

	self.remote = options.remote
	self.parent = options.parent
	self.showMessage = options.showMessage
	self.isReducedMotion = options.isReducedMotion
	self.getVisibleBoardCellCount = options.getVisibleBoardCellCount
	self.currentState = nil

	self.button = Instance.new("TextButton")
	self.button.Name = "DeveloperToolsButton"
	self.button.Text = "DEV"
	self.button.Position = UDim2.fromOffset(14, 252)
	self.button.Size = UDim2.fromOffset(60, 34)
	self.button.Visible = false
	self.button.ZIndex = 38
	self.button.Parent = self.parent
	styleButton(self.button, "primary")

	self.indicator = Instance.new("TextLabel")
	self.indicator.Name = "DeveloperTestIndicator"
	self.indicator.BackgroundColor3 = PALETTE.warningFill
	self.indicator.BackgroundTransparency = 0
	self.indicator.BorderSizePixel = 0
	self.indicator.Font = Enum.Font.GothamBlack
	self.indicator.Text = "DEV TEST - RECORDS DISABLED"
	self.indicator.TextColor3 = PALETTE.warningText
	self.indicator.TextSize = 15
	self.indicator.TextWrapped = true
	self.indicator.Position = UDim2.fromOffset(84, 252)
	self.indicator.Size = UDim2.fromOffset(286, 34)
	self.indicator.Visible = false
	self.indicator.ZIndex = 38
	self.indicator.Parent = self.parent
	addCorner(self.indicator, 8)
	addStroke(self.indicator, Color3.fromRGB(126, 76, 0), 2, 0)

	self.panel = Instance.new("Frame")
	self.panel.Name = "DeveloperToolsPanel"
	self.panel.BackgroundColor3 = PALETTE.panel
	self.panel.BackgroundTransparency = 0
	self.panel.BorderSizePixel = 0
	self.panel.Position = UDim2.fromOffset(14, 294)
	self.panel.Size = UDim2.fromOffset(548, 424)
	self.panel.Visible = false
	self.panel.ZIndex = 38
	self.panel.Parent = self.parent
	addCorner(self.panel, 10)
	addStroke(self.panel, PALETTE.rim, 2, 0)

	local header = Instance.new("Frame")
	header.Name = "Header"
	header.BackgroundColor3 = Color3.fromRGB(219, 234, 252)
	header.BorderSizePixel = 0
	header.Position = UDim2.fromOffset(12, 12)
	header.Size = UDim2.new(1, -24, 0, 42)
	header.ZIndex = 39
	header.Parent = self.panel
	addCorner(header, 8)
	addStroke(header, Color3.fromRGB(167, 194, 225), 1, 0)

	makeLabel(header, "Developer Tools", UDim2.new(1, -170, 1, 0), UDim2.fromOffset(12, 0), {
		name = "DeveloperToolsTitle",
		color = PALETTE.text,
		textSize = 17,
		zIndex = 40,
	})
	makeLabel(header, "authorized test run", UDim2.fromOffset(124, 20), UDim2.new(1, -164, 0, 11), {
		name = "DeveloperToolsSubtitle",
		color = PALETTE.muted,
		font = Enum.Font.GothamMedium,
		textSize = 12,
		zIndex = 40,
	})

	local close = Instance.new("TextButton")
	close.Name = "DeveloperPanelCloseButton"
	close.Text = "X"
	close.Position = UDim2.new(1, -42, 0, 8)
	close.Size = UDim2.fromOffset(30, 26)
	close.Parent = header
	styleButton(close, "close")
	close.Activated:Connect(function()
		self.panel.Visible = false
		self:RefreshIndicatorVisibility()
	end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name = "DeveloperCommandScroll"
	scroll.Active = true
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.CanvasSize = UDim2.fromOffset(0, 0)
	scroll.Position = UDim2.fromOffset(12, 66)
	scroll.ScrollBarImageColor3 = PALETTE.rim
	scroll.ScrollBarThickness = 8
	scroll.ScrollingDirection = Enum.ScrollingDirection.Y
	scroll.Size = UDim2.fromOffset(292, 344)
	scroll.ZIndex = 39
	scroll.Parent = self.panel

	local scrollLayout = Instance.new("UIListLayout")
	scrollLayout.FillDirection = Enum.FillDirection.Vertical
	scrollLayout.Padding = UDim.new(0, 10)
	scrollLayout.SortOrder = Enum.SortOrder.LayoutOrder
	scrollLayout.Parent = scroll

	local sections = {
		{
			title = "Stage",
			detail = "Set stage values or progress: Stage 3, +20 progress, one-stage advance, or combo value 5.",
			buttons = {
				{ "Set Stage 3", { action = "SetStage", stage = 3, progress = 0 }, "setup" },
				{ "+20 Stage", { action = "AddStageProgress", amount = 20 }, "setup" },
				{ "Advance Stage", { action = "AdvanceStage" }, "setup" },
				{ "Combo 5", { action = "SetCombo", combo = 5 }, "setup" },
			},
		},
		{
			title = "Board Setup",
			detail = "Load known board patterns for flow, line-clear, crowded, and game-over checks.",
			buttons = {
				{ "Empty", { action = "LoadPattern", pattern = "empty" }, "setup" },
				{
					"Near Line",
					{ action = "LoadPattern", pattern = "nearlyCompletedLine" },
					"setup",
				},
				{
					"Perfect Setup",
					{ action = "LoadPattern", pattern = "perfectClearSetup" },
					"setup",
				},
				{ "Crowded", { action = "LoadPattern", pattern = "crowded" }, "setup" },
				{ "Single Only", { action = "LoadPattern", pattern = "singleOnly" }, "setup" },
				{ "No Move", { action = "LoadPattern", pattern = "noMove" }, "destructive" },
			},
		},
		{
			title = "Hand Setup",
			detail = "Generate the smart hand or force the small-piece hand set.",
			buttons = {
				{ "Smart Hand", { action = "GenerateHand" }, "setup" },
				{
					"Hand: small",
					{ action = "ChooseHand", shapes = { "single", "line2", "line3" } },
					"setup",
				},
			},
		},
		{
			title = "Run Controls",
			detail = "Clears or resets the current developer run. Records stay disabled.",
			buttons = {
				{ "Clear Board", { action = "ClearBoard" }, "destructive" },
				{ "Reset Run", { action = "ResetRun" }, "destructive" },
			},
		},
		{
			title = "Diagnostics",
			detail = "Refreshes server diagnostics and visible board-cell verification.",
			buttons = {
				{ "Diagnostics", { action = "Diagnostics" }, "diagnostic" },
			},
		},
	}

	for sectionIndex, sectionInfo in sections do
		local section = makeSection(scroll, sectionInfo.title, sectionInfo.detail)
		section.LayoutOrder = sectionIndex
		for buttonIndex, entry in sectionInfo.buttons do
			local button = makeButton(section, entry[1], function()
				self:Invoke(entry[2])
			end, entry[3], commandButtonName(entry[1]))
			button.LayoutOrder = buttonIndex + 2
		end
	end

	local diagnosticsCard = Instance.new("Frame")
	diagnosticsCard.Name = "DiagnosticsCard"
	diagnosticsCard.BackgroundColor3 = PALETTE.card
	diagnosticsCard.BorderSizePixel = 0
	diagnosticsCard.Position = UDim2.fromOffset(318, 66)
	diagnosticsCard.Size = UDim2.fromOffset(216, 344)
	diagnosticsCard.ZIndex = 39
	diagnosticsCard.Parent = self.panel
	addCorner(diagnosticsCard, 8)
	addStroke(diagnosticsCard, Color3.fromRGB(167, 194, 225), 1, 0)
	addPadding(diagnosticsCard, 12, 12, 10, 10)

	makeLabel(diagnosticsCard, "Diagnostics", UDim2.new(1, 0, 0, 22), UDim2.fromOffset(0, 0), {
		name = "DiagnosticsHeading",
		color = PALETTE.text,
		textSize = 15,
		zIndex = 40,
	})
	self.diagnostics = makeLabel(
		diagnosticsCard,
		"Diagnostics unavailable",
		UDim2.new(1, 0, 1, -34),
		UDim2.fromOffset(0, 30),
		{
			name = "DiagnosticsReadout",
			color = PALETTE.text,
			font = Enum.Font.Code,
			textSize = 12,
			yAlignment = Enum.TextYAlignment.Top,
			zIndex = 40,
		}
	)

	self.button.Activated:Connect(function()
		self.panel.Visible = not self.panel.Visible
		self:RefreshIndicatorVisibility()
		if self.panel.Visible then
			self:Invoke({ action = "Diagnostics" })
		end
	end)

	return self
end

function DeveloperPanel:VisibleCellCount()
	if self.getVisibleBoardCellCount then
		return self.getVisibleBoardCellCount()
	end
	return 0
end

function DeveloperPanel:SetDiagnostics(diagnostics)
	if typeof(diagnostics) ~= "table" then
		return
	end

	self.diagnostics.Text = table.concat({
		`Stage {diagnostics.currentStage}: {diagnostics.stageProgress}/{diagnostics.stageProgressRequired}`,
		`Score {diagnostics.score} | Combo {diagnostics.comboStreak}`,
		`Perfect clears {diagnostics.totalPerfectClears}`,
		`Occupied {diagnostics.occupiedCells}`,
		`Hand {table.concat(diagnostics.handShapeNames or {}, ", ")}`,
		`Record eligible {tostring(diagnostics.recordEligible)}`,
		`Visible cells {diagnostics.visibleBoardCells}`,
	}, "\n")
end

function DeveloperPanel:Invoke(command)
	if not self.remote then
		return
	end

	local payload = table.clone(command)
	payload.visibleBoardCells = self:VisibleCellCount()

	local ok, response = pcall(function()
		return self.remote:InvokeServer(payload)
	end)

	if not ok or typeof(response) ~= "table" then
		if self.showMessage then
			self.showMessage("Developer command failed", Color3.fromRGB(224, 74, 74))
		end
		return
	end

	if response.diagnostics then
		self:SetDiagnostics(response.diagnostics)
	end
	if response.developer then
		local state = self.currentState or {}
		state.developer = response.developer
		self.currentState = state
		self:RefreshIndicatorVisibility()
	end
	if self.showMessage then
		self.showMessage(
			response.message or "Developer command complete",
			response.ok and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(224, 74, 74)
		)
	end
end

function DeveloperPanel:RefreshIndicatorVisibility()
	local developer = self.currentState and self.currentState.developer
	local authorized = developer and developer.authorized == true
	local testRun = developer and developer.testRun == true
	self.indicator.Visible = authorized and (testRun or self.panel.Visible)
end

function DeveloperPanel:UpdateState(state)
	self.currentState = state
	local developer = state and state.developer
	local authorized = developer and developer.authorized == true
	self.button.Visible = authorized
	if not authorized then
		self.panel.Visible = false
	end

	self:RefreshIndicatorVisibility()
	if developer and developer.diagnostics then
		local diagnostics = table.clone(developer.diagnostics)
		diagnostics.visibleBoardCells = self:VisibleCellCount()
		self:SetDiagnostics(diagnostics)
	end
end

return DeveloperPanel
