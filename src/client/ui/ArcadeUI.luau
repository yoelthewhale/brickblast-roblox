local ArcadeUI = {}

-- B2 "Polished Arcade" palette
ArcadeUI.Color = {
	shell = Color3.fromRGB(9, 13, 25),
	shellTop = Color3.fromRGB(23, 44, 82),
	shellBottom = Color3.fromRGB(5, 8, 18),
	inner = Color3.fromRGB(17, 32, 60),
	innerBottom = Color3.fromRGB(7, 13, 27),
	edge = Color3.fromRGB(5, 9, 20),
	rim = Color3.fromRGB(30, 187, 255),
	rimBright = Color3.fromRGB(110, 244, 255),
	text = Color3.fromRGB(255, 255, 255),
	muted = Color3.fromRGB(190, 210, 233),
	score = Color3.fromRGB(255, 210, 71),
	best = Color3.fromRGB(110, 244, 255),
	combo = Color3.fromRGB(255, 93, 200),
	gold = Color3.fromRGB(255, 210, 71),
	silver = Color3.fromRGB(213, 225, 241),
	bronze = Color3.fromRGB(255, 139, 61),
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
	shadow.BackgroundTransparency = 0.42
	shadow.BorderSizePixel = 0
	shadow.Position = position + UDim2.fromOffset(3, 5)
	shadow.Size = size
	shadow.Active = false
	shadow.Parent = parent
	corner(shadow, 9)

	local block = Instance.new("Frame")
	block.Name = name or "GlossyBlock"
	block.BackgroundColor3 = color
	block.BorderSizePixel = 0
	block.Position = position
	block.Size = size
	block.Active = false
	block.Parent = parent
	corner(block, 9)
	stroke(block, Color3.fromRGB(0, 0, 0), 2, 0.45)
	stroke(block, color:Lerp(Color3.fromRGB(255, 255, 255), 0.38), 1, 0.1)
	gradient(
		block,
		color:Lerp(Color3.fromRGB(255, 255, 255), 0.38),
		color:Lerp(Color3.fromRGB(0, 0, 0), 0.16),
		90
	)

	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	shine.BackgroundTransparency = 0.42
	shine.BorderSizePixel = 0
	shine.Position = UDim2.new(0, 6, 0, 5)
	shine.Size = UDim2.new(0.5, -5, 0, 6)
	shine.Active = false
	shine.Parent = block
	corner(shine, 5)

	local emboss = Instance.new("TextLabel")
	emboss.Name = "Emboss"
	emboss.BackgroundTransparency = 1
	emboss.Position = UDim2.fromScale(0.22, 0.18)
	emboss.Size = UDim2.fromScale(0.56, 0.58)
	emboss.Font = Enum.Font.GothamBlack
	emboss.Text = "+"
	emboss.TextColor3 = color:Lerp(Color3.fromRGB(0, 0, 0), 0.28)
	emboss.TextTransparency = 0.65
	emboss.TextScaled = true
	emboss.Active = false
	emboss.Parent = block

	return block
end

function ArcadeUI.RenderShapePreview(preview, shape, options)
	for _, child in preview:GetChildren() do
		child:Destroy()
	end

	if not shape then
		return
	end

	local minX = math.huge
	local maxX = -math.huge
	local minY = math.huge
	local maxY = -math.huge

	for _, cell in shape.cells do
		minX = math.min(minX, cell.X)
		maxX = math.max(maxX, cell.X)
		minY = math.min(minY, cell.Y)
		maxY = math.max(maxY, cell.Y)
	end

	local width = maxX - minX + 1
	local height = maxY - minY + 1
	local previewSize = math.max(44, math.min(preview.AbsoluteSize.X, preview.AbsoluteSize.Y))
	local tileSize = math.floor(math.min((previewSize - 6) / width, (previewSize - 6) / height))
	local offsetX = math.floor((previewSize - width * tileSize) / 2)
	local offsetY = math.floor((previewSize - height * tileSize) / 2)

	for index, cell in shape.cells do
		local blockColor = shape.color
		if options and options.blockColor then
			blockColor = options.blockColor
		elseif options and options.blockColors then
			blockColor = options.blockColors[((index - 1) % #options.blockColors) + 1]
		end

		ArcadeUI.GlossyBlock(
			preview,
			blockColor,
			UDim2.fromOffset(tileSize - 3, tileSize - 3),
			UDim2.fromOffset(
				offsetX + (cell.X - minX) * tileSize,
				offsetY + (cell.Y - minY) * tileSize
			),
			"GlossyBlock"
		)
	end
end

function ArcadeUI.StoryGoalText(state)
	local mission = state and state.storyMission
	if not mission then
		return nil
	end

	local targetLines = mission.targetLines or 0
	local targetScore = mission.targetScore or 0
	local currentLines = math.min(state.linesCleared or 0, targetLines)
	local currentScore = math.min(state.score or 0, targetScore)
	local chapterName = `Chapter {mission.chapter or 1}: {mission.name}`

	if targetLines > 0 and targetScore > 0 then
		return `{chapterName}: {currentLines}/{targetLines} lines, {currentScore}/{targetScore} score`
	elseif targetLines > 0 then
		return `{chapterName}: {currentLines}/{targetLines} lines`
	end

	return `{chapterName}: {currentScore}/{targetScore} score`
end

function ArcadeUI.StoryPreviewText(mission, storyStars)
	if typeof(mission) ~= "table" then
		return "Complete missions to unlock chapters"
	end

	local chapter = mission.chapter or 1
	local stars = storyStars or 0
	return `Chapter {chapter} | {mission.description or "Clear blocks and score"} | Stars {stars}`
end

function ArcadeUI.RenderProgression(context)
	local player = context.player
	local currentState = context.currentState
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local xp = leaderstats and leaderstats:FindFirstChild("XP")
	local level = leaderstats and leaderstats:FindFirstChild("Level")
	local storyStars = leaderstats and leaderstats:FindFirstChild("StoryStars")
	local cleared = currentState and currentState.linesCleared or 0
	local titleName = currentState
			and typeof(currentState.equippedCosmetics) == "table"
			and currentState.equippedCosmetics.title
		or "Rookie"

	context.progressionLabel.Text =
		`{titleName} | Level {level and level.Value or 1} | {coins and coins.Value or 0} coins | {xp and xp.Value or 0} XP | {storyStars and storyStars.Value or 0} stars | {cleared} cleared`
	if context.coinChipLabel then
		context.coinChipLabel.Text = `{coins and coins.Value or 0} Coins  +`
	end
	if context.coinStatLabel then
		context.coinStatLabel.Text =
			context.statRichText("COINS", tostring(coins and coins.Value or 0), "#FFECA0")
		context.enforceStatTextContrast()
	end
	if context.hudController then
		context.hudController:UpdateProgression()
	end
end

function ArcadeUI.CloneBoard(board, boardSize)
	local copy = {}

	for y = 1, boardSize do
		copy[y] = {}
		for x = 1, boardSize do
			copy[y][x] = board[y][x]
		end
	end

	return copy
end

function ArcadeUI.PlayCellPop(context, x, y)
	if context.reducedMotion then
		return
	end

	local scale = context.cellScales[y] and context.cellScales[y][x]
	if not scale then
		return
	end

	scale.Scale = 0.72
	context.TweenService:Create(scale, context.quickTween, { Scale = 1 }):Play()
end

function ArcadeUI.PlayClearFlash(context, x, y)
	if context.reducedMotion then
		return
	end

	local cell = context.cells[y] and context.cells[y][x]
	local scale = context.cellScales[y] and context.cellScales[y][x]
	if not cell or not scale then
		return
	end

	local originalColor = cell.BackgroundColor3
	cell.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	scale.Scale = 1.18
	context.TweenService
		:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Scale = 1,
		})
		:Play()
	task.delay(0.12, function()
		-- getCurrentState (not a captured snapshot) so this reads the live
		-- board even if it fires after a later placement/clear already
		-- replaced the state object this animation was originally queued for.
		local liveState = context.getCurrentState and context.getCurrentState()
		if liveState and liveState.board[y][x] == false then
			cell.BackgroundColor3 = context.boardEmptyColor
		else
			cell.BackgroundColor3 = originalColor
		end
	end)
end

function ArcadeUI.PlayBoardDiff(context, previous, nextBoard)
	if not previous then
		return
	end

	-- Placement pops are fired once by the explicit "Place" effect
	-- (see BlockBlastClient's effectsEvent handler); only clear feedback
	-- belongs here, or clears would pop twice for the same placement.
	local clearedCells = {}
	for y = 1, context.boardSize do
		for x = 1, context.boardSize do
			if previous[y][x] ~= false and nextBoard[y][x] == false then
				table.insert(clearedCells, { x = x, y = y })
			end
		end
	end

	if #clearedCells == 0 then
		return
	end

	-- Grid.clearLines only ever clears whole rows/columns, so a "line" here
	-- is any row/column where every cell in it just transitioned to empty.
	-- Staggering by line (and then across each line) gives the classic
	-- left-to-right/top-to-bottom sweep instead of every cell popping at once.
	local function lineFullyCleared(getCell)
		for i = 1, context.boardSize do
			local x, y = getCell(i)
			if not (previous[y][x] ~= false and nextBoard[y][x] == false) then
				return false
			end
		end
		return true
	end

	local clearedRows, clearedColumns = {}, {}
	for y = 1, context.boardSize do
		if lineFullyCleared(function(i)
			return i, y
		end) then
			table.insert(clearedRows, y)
		end
	end
	for x = 1, context.boardSize do
		if lineFullyCleared(function(i)
			return x, i
		end) then
			table.insert(clearedColumns, x)
		end
	end

	local STAGGER_STEP = 0.025
	local LINE_GAP = 0.08
	local handled = {}
	local lineIndex = 0

	for _, y in clearedRows do
		local base = lineIndex * LINE_GAP
		lineIndex += 1
		for x = 1, context.boardSize do
			handled[`{x}:{y}`] = true
			task.delay(base + (x - 1) * STAGGER_STEP, function()
				ArcadeUI.PlayClearFlash(context, x, y)
			end)
		end
	end

	for _, x in clearedColumns do
		local base = lineIndex * LINE_GAP
		lineIndex += 1
		for y = 1, context.boardSize do
			local key = `{x}:{y}`
			if not handled[key] then
				handled[key] = true
				task.delay(base + (y - 1) * STAGGER_STEP, function()
					ArcadeUI.PlayClearFlash(context, x, y)
				end)
			end
		end
	end

	-- Fallback for any diffed cell that isn't part of a full row/column
	-- (e.g. a board reset outside normal line-clear flow).
	for _, cell in clearedCells do
		local key = `{cell.x}:{cell.y}`
		if not handled[key] then
			ArcadeUI.PlayClearFlash(context, cell.x, cell.y)
		end
	end
end

function ArcadeUI.ScorePopup(context, amount)
	if not context.parent or not amount or amount <= 0 then
		return
	end

	local label = Instance.new("TextLabel")
	label.Name = "ScorePopup"
	label.BackgroundTransparency = 1
	label.AnchorPoint = Vector2.new(0.5, 0)
	label.Position = UDim2.new(0.5, 0, 0, 18)
	label.Size = UDim2.fromOffset(160, 32)
	label.Font = Enum.Font.GothamBlack
	label.Text = `+{amount}`
	label.TextColor3 = Color3.fromRGB(123, 237, 75)
	label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	label.TextStrokeTransparency = 0.2
	label.TextSize = 24
	label.ZIndex = 20
	label.Parent = context.parent

	if context.reducedMotion then
		task.delay(0.35, function()
			label:Destroy()
		end)
		return
	end

	context.TweenService
		:Create(label, TweenInfo.new(0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = label.Position - UDim2.fromOffset(0, 46),
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		:Play()
	task.delay(0.7, function()
		label:Destroy()
	end)
end

function ArcadeUI.PulseCombo(context)
	if not context.comboBadge then
		return
	end

	if context.reducedMotion then
		local original = context.comboBadge.BackgroundColor3
		context.comboBadge.BackgroundColor3 = Color3.fromRGB(255, 210, 71)
		task.delay(0.15, function()
			if context.comboBadge then
				context.comboBadge.BackgroundColor3 = original
			end
		end)
		return
	end

	local scale = context.comboBadge:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Parent = context.comboBadge
	scale.Scale = 1
	context.TweenService:Create(scale, context.quickTween, { Scale = 1.18 }):Play()
	task.delay(0.14, function()
		if scale.Parent then
			context.TweenService
				:Create(
					scale,
					TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ Scale = 1 }
				)
				:Play()
		end
	end)

	for _, sparkle in context.comboBadge:GetChildren() do
		if sparkle:IsA("Frame") and sparkle.Name:match("^ComboSparkle") then
			sparkle.BackgroundTransparency = 0
			context.TweenService
				:Create(
					sparkle,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ BackgroundTransparency = 1 }
				)
				:Play()
		end
	end
end

function ArcadeUI.PerfectClearFlash(context)
	if context.reducedMotion or not context.boardFrame then
		return
	end

	local flash = Instance.new("Frame")
	flash.Name = "PerfectClearFlash"
	flash.BackgroundColor3 = Color3.fromRGB(255, 210, 71)
	flash.BackgroundTransparency = 0.35
	flash.BorderSizePixel = 0
	flash.Size = UDim2.fromScale(1, 1)
	flash.ZIndex = 30
	flash.Parent = context.boardFrame

	context.TweenService
		:Create(
			flash,
			TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ BackgroundTransparency = 1 }
		)
		:Play()
	task.delay(0.5, function()
		flash:Destroy()
	end)
end

function ArcadeUI.ShakeWindow(context)
	if context.reducedMotion or not context.root then
		return
	end

	local startPosition = context.root.Position
	context.TweenService
		:Create(context.root, TweenInfo.new(0.05), {
			Position = startPosition + UDim2.fromOffset(8, 0),
		})
		:Play()
	task.delay(0.06, function()
		if context.root then
			context.TweenService
				:Create(context.root, TweenInfo.new(0.05), {
					Position = startPosition + UDim2.fromOffset(-8, 0),
				})
				:Play()
		end
	end)
	task.delay(0.12, function()
		if context.root then
			context.TweenService
				:Create(context.root, TweenInfo.new(0.06), {
					Position = startPosition,
				})
				:Play()
		end
	end)
end

function ArcadeUI.AttachWorkspaceInteraction(context)
	local state = {
		draggingWindow = false,
		resizingWindow = false,
		inputStartPosition = nil,
		windowStartPosition = nil,
		resizeStartScale = nil,
	}

	local function stop()
		state.draggingWindow = false
		state.resizingWindow = false
		state.inputStartPosition = nil
		state.windowStartPosition = nil
		state.resizeStartScale = nil
	end

	local function startDrag(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not context.root.Visible then
			return
		end

		state.draggingWindow = true
		state.resizingWindow = false
		state.inputStartPosition = input.Position
		state.windowStartPosition = context.root.Position
	end

	local function startResize(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 or not context.root.Visible then
			return
		end

		state.resizingWindow = true
		state.draggingWindow = false
		state.inputStartPosition = input.Position
		state.windowStartPosition = context.root.Position
		state.resizeStartScale = context.getWorkspaceScale()
	end

	for _, target in context.dragTargets do
		target.InputBegan:Connect(startDrag)
	end
	context.resizeHandle.InputBegan:Connect(startResize)

	context.UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		if state.draggingWindow and state.inputStartPosition and state.windowStartPosition then
			local delta = input.Position - state.inputStartPosition
			context.root.Position = UDim2.new(
				state.windowStartPosition.X.Scale,
				state.windowStartPosition.X.Offset + delta.X,
				state.windowStartPosition.Y.Scale,
				state.windowStartPosition.Y.Offset + delta.Y
			)
			context.clampWindowToScreen()
		elseif state.resizingWindow and state.inputStartPosition and state.resizeStartScale then
			local delta = input.Position - state.inputStartPosition
			local averageDelta = (delta.X + delta.Y) / 2
			local nextScale = state.resizeStartScale + averageDelta / 520
			context.setWorkspaceScale(nextScale)
			context.applyUiScale()
			context.clampWindowToScreen()
		end
	end)

	context.UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			stop()
		end
	end)

	return {
		stop = stop,
	}
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
