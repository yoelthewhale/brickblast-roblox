local DeveloperPanel = {}
DeveloperPanel.__index = DeveloperPanel

local function makeLabel(parent, text, size, position)
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = Color3.fromRGB(232, 240, 255)
	label.TextSize = 13
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Position = position
	label.Size = size
	label.Parent = parent
	return label
end

local function styleButton(button, color)
	button.BackgroundColor3 = color or Color3.fromRGB(24, 49, 86)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextSize = 12
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = button
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(85, 205, 255)
	stroke.Transparency = 0.18
	stroke.Thickness = 1
	stroke.Parent = button
	return button
end

local function makeButton(parent, text, position, commandFactory)
	local button = Instance.new("TextButton")
	button.Text = text
	button.Position = position
	button.Size = UDim2.fromOffset(124, 28)
	button.Parent = parent
	styleButton(button)
	button.Activated:Connect(function()
		commandFactory()
	end)
	return button
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
	styleButton(self.button, Color3.fromRGB(142, 68, 173))

	self.indicator = Instance.new("TextLabel")
	self.indicator.Name = "DeveloperTestIndicator"
	self.indicator.BackgroundColor3 = Color3.fromRGB(89, 28, 28)
	self.indicator.BackgroundTransparency = 0.05
	self.indicator.BorderSizePixel = 0
	self.indicator.Font = Enum.Font.GothamBlack
	self.indicator.Text = "DEV TEST - RECORDS DISABLED"
	self.indicator.TextColor3 = Color3.fromRGB(255, 255, 255)
	self.indicator.TextSize = 15
	self.indicator.TextWrapped = true
	self.indicator.Position = UDim2.fromOffset(84, 252)
	self.indicator.Size = UDim2.fromOffset(260, 34)
	self.indicator.Visible = false
	self.indicator.ZIndex = 38
	self.indicator.Parent = self.parent
	styleButton(self.indicator, Color3.fromRGB(89, 28, 28))

	self.panel = Instance.new("Frame")
	self.panel.Name = "DeveloperToolsPanel"
	self.panel.BackgroundColor3 = Color3.fromRGB(8, 14, 28)
	self.panel.BackgroundTransparency = 0.03
	self.panel.BorderSizePixel = 0
	self.panel.Position = UDim2.fromOffset(14, 294)
	self.panel.Size = UDim2.fromOffset(420, 330)
	self.panel.Visible = false
	self.panel.ZIndex = 38
	self.panel.Parent = self.parent
	local panelCorner = Instance.new("UICorner")
	panelCorner.CornerRadius = UDim.new(0, 10)
	panelCorner.Parent = self.panel
	local panelStroke = Instance.new("UIStroke")
	panelStroke.Color = Color3.fromRGB(85, 205, 255)
	panelStroke.Thickness = 2
	panelStroke.Parent = self.panel

	makeLabel(self.panel, "Developer Tools", UDim2.fromOffset(210, 24), UDim2.fromOffset(14, 10))
	local close = Instance.new("TextButton")
	close.Text = "X"
	close.Position = UDim2.fromOffset(374, 10)
	close.Size = UDim2.fromOffset(32, 26)
	close.Parent = self.panel
	styleButton(close, Color3.fromRGB(170, 52, 68))
	close.Activated:Connect(function()
		self.panel.Visible = false
	end)

	self.diagnostics = makeLabel(
		self.panel,
		"Diagnostics unavailable",
		UDim2.fromOffset(166, 276),
		UDim2.fromOffset(240, 44)
	)
	self.diagnostics.Font = Enum.Font.Code
	self.diagnostics.TextSize = 11
	self.diagnostics.TextYAlignment = Enum.TextYAlignment.Top

	local commands = {
		{ "Set Stage 3", { action = "SetStage", stage = 3, progress = 0 } },
		{ "+20 Stage", { action = "AddStageProgress", amount = 20 } },
		{ "Advance Stage", { action = "AdvanceStage" } },
		{ "Combo 5", { action = "SetCombo", combo = 5 } },
		{ "Clear Board", { action = "ClearBoard" } },
		{ "Reset Run", { action = "ResetRun" } },
		{ "Smart Hand", { action = "GenerateHand" } },
		{ "Hand: small", { action = "ChooseHand", shapes = { "single", "line2", "line3" } } },
		{ "Empty", { action = "LoadPattern", pattern = "empty" } },
		{ "Near Line", { action = "LoadPattern", pattern = "nearlyCompletedLine" } },
		{ "Perfect Setup", { action = "LoadPattern", pattern = "perfectClearSetup" } },
		{ "Crowded", { action = "LoadPattern", pattern = "crowded" } },
		{ "Single Only", { action = "LoadPattern", pattern = "singleOnly" } },
		{ "No Move", { action = "LoadPattern", pattern = "noMove" } },
		{ "Diagnostics", { action = "Diagnostics" } },
	}

	for index, entry in commands do
		local column = (index - 1) % 2
		local row = math.floor((index - 1) / 2)
		makeButton(
			self.panel,
			entry[1],
			UDim2.fromOffset(14 + column * 110, 44 + row * 34),
			function()
				self:Invoke(entry[2])
			end
		).Size =
			UDim2.fromOffset(102, 28)
	end

	self.button.Activated:Connect(function()
		self.panel.Visible = not self.panel.Visible
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
	if self.showMessage then
		self.showMessage(
			response.message or "Developer command complete",
			response.ok and Color3.fromRGB(74, 222, 128) or Color3.fromRGB(224, 74, 74)
		)
	end
end

function DeveloperPanel:UpdateState(state)
	self.currentState = state
	local developer = state and state.developer
	local authorized = developer and developer.authorized == true
	self.button.Visible = authorized
	if not authorized then
		self.panel.Visible = false
	end

	local testRun = developer and developer.testRun == true
	self.indicator.Visible = testRun
	if developer and developer.diagnostics then
		local diagnostics = table.clone(developer.diagnostics)
		diagnostics.visibleBoardCells = self:VisibleCellCount()
		self:SetDiagnostics(diagnostics)
	end
end

return DeveloperPanel
