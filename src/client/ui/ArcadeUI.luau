local ArcadeUI = {}

ArcadeUI.Color = {
	shell = Color3.fromRGB(8, 18, 36),
	shellTop = Color3.fromRGB(18, 50, 96),
	shellBottom = Color3.fromRGB(3, 9, 22),
	inner = Color3.fromRGB(10, 29, 56),
	innerBottom = Color3.fromRGB(4, 13, 31),
	edge = Color3.fromRGB(2, 7, 18),
	rim = Color3.fromRGB(41, 162, 255),
	rimBright = Color3.fromRGB(87, 217, 255),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(177, 205, 232),
	score = Color3.fromRGB(255, 209, 45),
	best = Color3.fromRGB(42, 215, 255),
	combo = Color3.fromRGB(218, 73, 255),
	gold = Color3.fromRGB(255, 198, 41),
	silver = Color3.fromRGB(213, 225, 241),
	bronze = Color3.fromRGB(235, 132, 44),
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

local function gradient(parent, topColor, bottomColor, rotation)
	local item = Instance.new("UIGradient")
	item.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor),
		ColorSequenceKeypoint.new(1, bottomColor),
	})
	item.Rotation = rotation or 90
	item.Parent = parent
	return item
end

local function decorateShell(frame, radius, rimColor, strokeThickness)
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = ArcadeUI.Color.shell
	corner(frame, radius)
	stroke(frame, ArcadeUI.Color.edge, strokeThickness + 3, 0)
	stroke(frame, rimColor or ArcadeUI.Color.rim, strokeThickness, 0.08)
	gradient(frame, ArcadeUI.Color.shellTop, ArcadeUI.Color.shellBottom, 90)

	local highlight = Instance.new("Frame")
	highlight.Name = "ArcadeTopHighlight"
	highlight.BackgroundColor3 = Color3.fromRGB(140, 222, 255)
	highlight.BackgroundTransparency = 0.7
	highlight.BorderSizePixel = 0
	highlight.Position = UDim2.new(0, 18, 0, 8)
	highlight.Size = UDim2.new(1, -36, 0, 5)
	highlight.Active = false
	highlight.Parent = frame
	corner(highlight, radius)

	return frame
end

function ArcadeUI.Panel(frame, options)
	options = options or {}
	return decorateShell(
		frame,
		options.radius or 26,
		options.rimColor or ArcadeUI.Color.rim,
		options.strokeThickness or 4
	)
end

function ArcadeUI.InnerPanel(frame, options)
	options = options or {}
	frame.BorderSizePixel = 0
	frame.BackgroundColor3 = ArcadeUI.Color.inner
	corner(frame, options.radius or 18)
	stroke(
		frame,
		options.rimColor or Color3.fromRGB(28, 92, 161),
		options.strokeThickness or 2,
		0.2
	)
	gradient(frame, ArcadeUI.Color.inner, ArcadeUI.Color.innerBottom, 90)
	return frame
end

function ArcadeUI.Text(label, role)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBlack
	label.TextColor3 = role == "score" and ArcadeUI.Color.score
		or role == "best" and ArcadeUI.Color.best
		or role == "combo" and ArcadeUI.Color.combo
		or role == "gold" and ArcadeUI.Color.gold
		or role == "muted" and ArcadeUI.Color.muted
		or ArcadeUI.Color.text
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = role == "muted" and 0.75 or 0.45
	return label
end

function ArcadeUI.Button(button, color)
	button.BorderSizePixel = 0
	button.BackgroundColor3 = color or ArcadeUI.Color.inner
	button.Font = Enum.Font.GothamBlack
	button.TextColor3 = ArcadeUI.Color.text
	corner(button, 16)
	stroke(button, ArcadeUI.Color.edge, 3, 0)
	stroke(button, ArcadeUI.Color.rimBright, 2, 0.12)
	gradient(
		button,
		button.BackgroundColor3:Lerp(Color3.fromRGB(255, 255, 255), 0.18),
		button.BackgroundColor3:Lerp(Color3.fromRGB(0, 0, 0), 0.18),
		90
	)
	return button
end

function ArcadeUI.StatCard(frame)
	ArcadeUI.Panel(frame, {
		radius = 24,
		strokeThickness = 4,
	})
	return frame
end

function ArcadeUI.GlossyBlock(parent, color, size, position, name)
	parent.ClipsDescendants = true

	local shadow = Instance.new("Frame")
	shadow.Name = `{name or "Block"}Shadow`
	shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	shadow.BackgroundTransparency = 0.48
	shadow.BorderSizePixel = 0
	shadow.Position = position + UDim2.fromOffset(3, 4)
	shadow.Size = size
	shadow.Active = false
	shadow.Parent = parent
	corner(shadow, 7)

	local block = Instance.new("Frame")
	block.Name = name or "GlossyBlock"
	block.BackgroundColor3 = color
	block.BorderSizePixel = 0
	block.Position = position
	block.Size = size
	block.Active = false
	block.Parent = parent
	corner(block, 7)
	stroke(block, color:Lerp(Color3.fromRGB(255, 255, 255), 0.25), 1, 0.2)
	gradient(
		block,
		color:Lerp(Color3.fromRGB(255, 255, 255), 0.32),
		color:Lerp(Color3.fromRGB(0, 0, 0), 0.18),
		90
	)

	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shine.BackgroundTransparency = 0.56
	shine.BorderSizePixel = 0
	shine.Position = UDim2.new(0, 5, 0, 4)
	shine.Size = UDim2.new(0.55, -5, 0, 5)
	shine.Active = false
	shine.Parent = block
	corner(shine, 5)

	return block
end

function ArcadeUI.BoardCell(button)
	button.BorderSizePixel = 0
	button.BackgroundColor3 = Color3.fromRGB(12, 29, 56)
	button.ClipsDescendants = true
	corner(button, 9)
	stroke(button, Color3.fromRGB(47, 72, 112), 2, 0.18)
	gradient(button, Color3.fromRGB(18, 39, 73), Color3.fromRGB(7, 17, 37), 90)
	return button
end

function ArcadeUI.PieceSlot(button)
	ArcadeUI.InnerPanel(button, {
		radius = 18,
		rimColor = Color3.fromRGB(33, 103, 177),
		strokeThickness = 2,
	})
	return button
end

function ArcadeUI.LeaderboardRow(parent, index)
	local row = Instance.new("Frame")
	row.Name = `LeaderboardRow{index}`
	row.BackgroundColor3 = ArcadeUI.Color.inner
	row.BorderSizePixel = 0
	row.Size = UDim2.fromOffset(300, 38)
	row.Active = false
	row.Parent = parent
	corner(row, 12)
	stroke(row, Color3.fromRGB(31, 90, 151), 1, 0.28)
	gradient(row, Color3.fromRGB(13, 36, 70), Color3.fromRGB(5, 17, 40), 90)
	return row
end

return ArcadeUI
