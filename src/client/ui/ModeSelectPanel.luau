-- Mode and difficulty selection, shown when the player presses Play.
--
-- Built as its own ModuleScript for two reasons. It gets its own Luau register
-- budget, which BlockBlastClient.client.luau does not have to spare (198/200);
-- and mode selection is a concern that should be able to grow without the
-- monolith growing with it.
--
-- The mode list is deliberately data-driven even though only Solo is enabled
-- today. Adding a mode later should mean adding a table entry, not restructuring
-- this panel. Modes disabled in ExperienceConfig are simply not offered -- they
-- are never rendered as locked "coming soon" teasers, because advertising a
-- mode with no committed date is the pattern already flagged on #28 and #52.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameShared = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("game")
local ExperienceConfig = require(GameShared:WaitForChild("ExperienceConfig"))
local HandGenerator = require(GameShared:WaitForChild("HandGenerator"))
local VisualTokens = require(GameShared:WaitForChild("VisualTokens"))

local ModeSelectPanel = {}
ModeSelectPanel.__index = ModeSelectPanel

local OPEN_TWEEN = TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local CLOSE_TWEEN = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local MODES = {
	{
		id = "Solo",
		name = "Solo Puzzle",
		blurb = "Clear rows and columns. Chase stages and combos.",
		offersDifficulty = true,
	},
}

local function corner(parent, radius)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius)
	item.Parent = parent
	return item
end

local function stroke(parent, color, thickness, transparency)
	local item = Instance.new("UIStroke")
	item.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	item.Color = color
	item.Thickness = thickness
	item.Transparency = transparency or 0
	item.Parent = parent
	return item
end

local function enabledModes()
	local list = {}
	for _, mode in MODES do
		if ExperienceConfig.isModeEnabled(mode.id) then
			table.insert(list, mode)
		end
	end
	return list
end

function ModeSelectPanel.new(gui, options)
	options = options or {}

	local self = setmetatable({}, ModeSelectPanel)
	self.onConfirm = options.onConfirm or function() end
	self.playSound = options.playSound or function() end
	self.isReducedMotion = options.isReducedMotion or function()
		return false
	end
	self.difficultyButtons = {}
	self.selectedDifficulty = HandGenerator.sanitizeDifficulty(options.defaultDifficulty)
	self.selectedMode = "Solo"

	local tokens = VisualTokens.resolve(1, 0)

	local shade = Instance.new("TextButton")
	shade.Name = "ModeSelectShade"
	shade.AutoButtonColor = false
	shade.Text = ""
	shade.BackgroundColor3 = tokens.ink
	shade.BackgroundTransparency = 0.45
	shade.BorderSizePixel = 0
	shade.Size = UDim2.fromScale(1, 1)
	shade.Visible = false
	shade.ZIndex = 60
	shade.Parent = gui
	self.shade = shade

	local panel = Instance.new("Frame")
	panel.Name = "ModeSelectPanel"
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(460, 470)
	panel.BackgroundColor3 = tokens.surface
	panel.BorderSizePixel = 0
	panel.ZIndex = 61
	panel.Parent = shade
	corner(panel, VisualTokens.Radius.panel)
	stroke(panel, tokens.boardRim, 4, 0.1)
	self.panel = panel

	local title = Instance.new("TextLabel")
	title.Name = "ModeSelectTitle"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(24, 20)
	title.Size = UDim2.new(1, -100, 0, 34)
	title.Font = Enum.Font.GothamBlack
	title.Text = "Choose your run"
	title.TextColor3 = tokens.ink
	title.TextSize = 26
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 62
	title.Parent = panel

	local close = Instance.new("TextButton")
	close.Name = "ModeSelectClose"
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -20, 0, 18)
	close.Size = UDim2.fromOffset(38, 38)
	close.Font = Enum.Font.GothamBlack
	close.Text = "X"
	close.TextColor3 = tokens.ink
	close.TextSize = 18
	close.BackgroundColor3 = tokens.surfaceSunken
	close.AutoButtonColor = false
	close.BorderSizePixel = 0
	close.ZIndex = 62
	close.Parent = panel
	corner(close, VisualTokens.Radius.chip)
	stroke(close, tokens.boardCellEdge, 2, 0.35)
	close.Activated:Connect(function()
		self.playSound("Button")
		self:Close()
	end)
	shade.Activated:Connect(function()
		self:Close()
	end)

	self:BuildModes(panel, tokens)
	self:BuildDifficulties(panel, tokens)
	self:BuildConfirm(panel, tokens)
	self:SetDifficulty(self.selectedDifficulty)

	return self
end

function ModeSelectPanel:BuildModes(panel, tokens)
	local modes = enabledModes()

	local heading = Instance.new("TextLabel")
	heading.Name = "ModeHeading"
	heading.BackgroundTransparency = 1
	heading.Position = UDim2.fromOffset(24, 64)
	heading.Size = UDim2.new(1, -48, 0, 18)
	heading.Font = Enum.Font.GothamBold
	heading.Text = "MODE"
	heading.TextColor3 = tokens.inkSoft
	heading.TextSize = 13
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.ZIndex = 62
	heading.Parent = panel

	local y = 86
	for _, mode in modes do
		local card = Instance.new("Frame")
		card.Name = `ModeCard{mode.id}`
		card.Position = UDim2.fromOffset(24, y)
		card.Size = UDim2.new(1, -48, 0, 68)
		card.BackgroundColor3 = tokens.surfaceTinted
		card.BorderSizePixel = 0
		card.ZIndex = 62
		card.Parent = panel
		corner(card, VisualTokens.Radius.card)
		stroke(card, tokens.boardRim, 3, 0.15)

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Position = UDim2.fromOffset(16, 10)
		name.Size = UDim2.new(1, -32, 0, 24)
		name.Font = Enum.Font.GothamBlack
		name.Text = mode.name
		name.TextColor3 = tokens.ink
		name.TextSize = 19
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.ZIndex = 63
		name.Parent = card

		local blurb = Instance.new("TextLabel")
		blurb.BackgroundTransparency = 1
		blurb.Position = UDim2.fromOffset(16, 34)
		blurb.Size = UDim2.new(1, -32, 0, 22)
		blurb.Font = Enum.Font.GothamMedium
		blurb.Text = mode.blurb
		blurb.TextColor3 = tokens.inkSoft
		blurb.TextSize = 13
		blurb.TextXAlignment = Enum.TextXAlignment.Left
		blurb.TextTruncate = Enum.TextTruncate.AtEnd
		blurb.ZIndex = 63
		blurb.Parent = card

		y += 78
	end

	self.modesBottom = y
end

function ModeSelectPanel:BuildDifficulties(panel, tokens)
	local top = self.modesBottom + 8

	local heading = Instance.new("TextLabel")
	heading.Name = "DifficultyHeading"
	heading.BackgroundTransparency = 1
	heading.Position = UDim2.fromOffset(24, top)
	heading.Size = UDim2.new(1, -48, 0, 18)
	heading.Font = Enum.Font.GothamBold
	heading.Text = "DIFFICULTY"
	heading.TextColor3 = tokens.inkSoft
	heading.TextSize = 13
	heading.TextXAlignment = Enum.TextXAlignment.Left
	heading.ZIndex = 62
	heading.Parent = panel

	local y = top + 24
	for _, profile in HandGenerator.difficultyOptions() do
		local button = Instance.new("TextButton")
		button.Name = `Difficulty{profile.id}`
		button.AutoButtonColor = false
		button.Text = ""
		button.Position = UDim2.fromOffset(24, y)
		button.Size = UDim2.new(1, -48, 0, 60)
		button.BackgroundColor3 = tokens.surfaceSunken
		button.BorderSizePixel = 0
		button.ZIndex = 62
		button.Parent = panel
		corner(button, VisualTokens.Radius.card)

		local outline = stroke(button, tokens.boardCellEdge, 2, 0.4)

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Position = UDim2.fromOffset(16, 9)
		name.Size = UDim2.new(1, -32, 0, 22)
		name.Font = Enum.Font.GothamBlack
		name.Text = profile.name
		name.TextColor3 = tokens.ink
		name.TextSize = 18
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.ZIndex = 63
		name.Parent = button

		local blurb = Instance.new("TextLabel")
		blurb.BackgroundTransparency = 1
		blurb.Position = UDim2.fromOffset(16, 31)
		blurb.Size = UDim2.new(1, -32, 0, 20)
		blurb.Font = Enum.Font.GothamMedium
		blurb.Text = profile.blurb
		blurb.TextColor3 = tokens.inkSoft
		blurb.TextSize = 12
		blurb.TextXAlignment = Enum.TextXAlignment.Left
		blurb.TextTruncate = Enum.TextTruncate.AtEnd
		blurb.ZIndex = 63
		blurb.Parent = button

		self.difficultyButtons[profile.id] = {
			button = button,
			outline = outline,
			name = name,
		}

		button.Activated:Connect(function()
			self.playSound("Button")
			self:SetDifficulty(profile.id)
		end)

		y += 68
	end

	self.difficultiesBottom = y
end

function ModeSelectPanel:BuildConfirm(panel, tokens)
	local confirm = Instance.new("TextButton")
	confirm.Name = "ModeSelectConfirm"
	confirm.AnchorPoint = Vector2.new(0.5, 1)
	confirm.Position = UDim2.new(0.5, 0, 1, -22)
	confirm.Size = UDim2.new(1, -48, 0, 58)
	confirm.Font = Enum.Font.GothamBlack
	confirm.Text = "START RUN"
	confirm.TextColor3 = tokens.ink
	confirm.TextSize = 21
	confirm.BackgroundColor3 = tokens.accent
	confirm.AutoButtonColor = false
	confirm.BorderSizePixel = 0
	confirm.ZIndex = 62
	confirm.Parent = panel
	corner(confirm, VisualTokens.Radius.card)
	stroke(confirm, tokens.hot, 3, 0.1)
	self.confirmButton = confirm

	confirm.Activated:Connect(function()
		self.playSound("Button")
		local mode, difficulty = self.selectedMode, self.selectedDifficulty
		self:Close()
		self.onConfirm(mode, difficulty)
	end)
end

function ModeSelectPanel:SetDifficulty(difficultyId)
	local resolved = HandGenerator.sanitizeDifficulty(difficultyId)
	self.selectedDifficulty = resolved
	local tokens = VisualTokens.resolve(1, 0)

	for id, parts in self.difficultyButtons do
		local selected = id == resolved
		parts.button.BackgroundColor3 = selected and tokens.boardCell or tokens.surfaceSunken
		parts.outline.Color = selected and tokens.boardRim or tokens.boardCellEdge
		parts.outline.Thickness = selected and 4 or 2
		parts.outline.Transparency = selected and 0 or 0.4
	end
end

function ModeSelectPanel:IsOpen()
	return self.shade.Visible
end

function ModeSelectPanel:Open()
	if self.shade.Visible then
		return
	end

	self.shade.Visible = true

	if self.isReducedMotion() then
		self.panel.Size = UDim2.fromOffset(460, 470)
		return
	end

	self.panel.Size = UDim2.fromOffset(414, 423)
	TweenService:Create(self.panel, OPEN_TWEEN, {
		Size = UDim2.fromOffset(460, 470),
	}):Play()
end

function ModeSelectPanel:Close()
	if not self.shade.Visible then
		return
	end

	if self.isReducedMotion() then
		self.shade.Visible = false
		return
	end

	local tween = TweenService:Create(self.panel, CLOSE_TWEEN, {
		Size = UDim2.fromOffset(414, 423),
	})
	tween.Completed:Once(function()
		self.shade.Visible = false
	end)
	tween:Play()
end

function ModeSelectPanel:Destroy()
	if self.shade then
		self.shade:Destroy()
	end
end

return ModeSelectPanel
