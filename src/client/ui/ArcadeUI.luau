local ReplicatedStorage = game:GetService("ReplicatedStorage")

local VisualTokens = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("game"):WaitForChild("VisualTokens")
)
local BubblegumAssets = require(script.Parent.BubblegumAssets)

local ArcadeUI = {}
local CONFETTI_ASSET_KEYS = {
	"ConfettiRect",
	"ConfettiDot",
	"ConfettiStar",
	"ConfettiSquiggle",
}

-- The chassis palette. This was the "B2 Polished Arcade" set -- a near-black
-- navy cabinet with a neon cyan rim -- which fought the Bubblegum Toybox board
-- it was framing. It is now derived from the shared identity
-- (docs/VISUAL_DIRECTION.md, #98) but keeps every key name, so all existing
-- call sites are untouched.
--
-- Text roles are contrast-derived rather than hand-picked: see
-- VisualTokens.readableOn. Do not replace one with a literal Color3 -- several
-- of these sit on cream now, where a hand-picked candy color is unreadable.
ArcadeUI.Color = VisualTokens.chrome()

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
	highlight.BackgroundColor3 = VisualTokens.identity().gloss
	highlight.BackgroundTransparency = 0.45
	highlight.BorderSizePixel = 0
	highlight.Position = UDim2.new(0, 18, 0, 8)
	highlight.Size = UDim2.new(1, -36, 0, 5)
	highlight.Active = false
	highlight.Parent = frame
	corner(highlight, radius)

	if BubblegumAssets.imageFor("ShadowSoft") then
		local shadow = Instance.new("ImageLabel")
		shadow.Name = "BubblegumSoftShadow"
		shadow.AnchorPoint = Vector2.new(0.5, 0.5)
		shadow.Position = UDim2.new(0.5, 0, 0.5, 10)
		shadow.Size = UDim2.new(1, 28, 1, 28)
		shadow.BackgroundTransparency = 1
		shadow.ImageTransparency = 0.2
		shadow.ZIndex = math.max(frame.ZIndex - 1, 0)
		shadow.Active = false
		shadow.Parent = frame
		BubblegumAssets.applyTo(shadow, "ShadowSoft", {
			imageColor = VisualTokens.identity().shadow,
		})
	end

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
	stroke(frame, options.rimColor or ArcadeUI.Color.edge, options.strokeThickness or 2, 0.2)
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
	-- Ink rather than black, and much lighter: a hard black outline was right
	-- for neon-on-black and reads as grime on cream.
	label.TextStrokeColor3 = VisualTokens.identity().ink
	label.TextStrokeTransparency = role == "muted" and 0.92 or 0.82
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

	-- Pieces are the most-looked-at object in the game, so their shading is
	-- worth being fussy about. This used to be a candy: big radius, a floating
	-- highlight bar, and an embossed "+" glyph. The approved reference is not
	-- candy -- it is a molded plastic tile, and what sells that is a hard
	-- three-tone bevel rather than a gloss.
	--
	-- Three faces, all derived from the piece's own hue so every color in the
	-- palette bevels consistently: a lit top face, the body, and a shaded
	-- bottom face. Deriving them rather than shipping three palettes means a
	-- new block color needs no extra tuning to look molded.
	local identity = VisualTokens.identity()
	local lit = color:Lerp(identity.gloss, 0.34)
	local shade = color:Lerp(identity.shadow, 0.42)
	local outline = color:Lerp(identity.shadow, 0.62)

	local shadow = Instance.new("Frame")
	shadow.Name = `{name or "Block"}Shadow`
	shadow.BackgroundColor3 = identity.shadow
	shadow.BackgroundTransparency = 0.45
	shadow.BorderSizePixel = 0
	shadow.Position = position + UDim2.fromOffset(2, 3)
	shadow.Size = size
	shadow.Active = false
	shadow.Parent = parent
	corner(shadow, VisualTokens.Radius.piece)

	local block = Instance.new("Frame")
	block.Name = name or "GlossyBlock"
	block.BackgroundColor3 = color
	block.BorderSizePixel = 0
	block.Position = position
	block.Size = size
	block.Active = false
	block.ClipsDescendants = true
	block.Parent = parent
	corner(block, VisualTokens.Radius.piece)
	-- One outline, in a deepened version of the piece's own hue rather than
	-- black, so tiles read as separate objects against each other and against
	-- the dark well without any of them picking up a grey rim.
	stroke(block, outline, 2, 0)

	-- The faces are clipped by the block's own corner radius, so they need no
	-- radius of their own; giving them one would round the inner edge and turn
	-- the bevel back into a highlight bar.
	local topFace = Instance.new("Frame")
	topFace.Name = "BevelTop"
	topFace.BackgroundColor3 = lit
	topFace.BorderSizePixel = 0
	topFace.Position = UDim2.fromScale(0, 0)
	topFace.Size = UDim2.new(1, 0, 0.24, 0)
	topFace.Active = false
	topFace.ZIndex = block.ZIndex
	topFace.Parent = block

	local bottomFace = Instance.new("Frame")
	bottomFace.Name = "BevelBottom"
	bottomFace.BackgroundColor3 = shade
	bottomFace.BorderSizePixel = 0
	bottomFace.Position = UDim2.fromScale(0, 0.78)
	bottomFace.Size = UDim2.new(1, 0, 0.22, 0)
	bottomFace.Active = false
	bottomFace.ZIndex = block.ZIndex
	bottomFace.Parent = block

	-- A very slight vertical fall across the body ties the two faces together
	-- so the bevel reads as one lit solid rather than three stacked stripes.
	gradient(block, color:Lerp(identity.gloss, 0.08), color:Lerp(identity.shadow, 0.1), 90)

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
	label.TextStrokeColor3 = VisualTokens.identity().ink
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
		if sparkle:IsA("GuiObject") and sparkle.Name:match("^ComboSparkle") then
			if sparkle:IsA("ImageLabel") then
				sparkle.ImageTransparency = 0
			elseif sparkle:IsA("Frame") then
				sparkle.BackgroundTransparency = 0
			end
			context.TweenService
				:Create(
					sparkle,
					TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					sparkle:IsA("ImageLabel") and { ImageTransparency = 1 }
						or { BackgroundTransparency = 1 }
				)
				:Play()
		end
	end
end

function ArcadeUI.DecorativeImage(parent, key, options)
	options = options or {}
	local image = Instance.new("ImageLabel")
	image.Name = options.name or key
	image.BackgroundTransparency = 1
	image.Position = options.position or UDim2.fromOffset(0, 0)
	image.Size = options.size or UDim2.fromOffset(48, 48)
	image.AnchorPoint = options.anchorPoint or Vector2.new(0, 0)
	image.Rotation = options.rotation or 0
	image.ImageTransparency = options.transparency or 0
	image.ZIndex = options.zIndex or parent.ZIndex + 1
	image.Active = false
	image.Parent = parent
	if
		not BubblegumAssets.applyTo(image, key, {
			imageColor = options.imageColor,
			allowSemanticTint = options.allowSemanticTint,
		})
	then
		image:Destroy()
		return nil
	end

	return image
end

function ArcadeUI.SetLeaderboardMedal(row, rank)
	local medalKey = BubblegumAssets.medalKeyForRank(rank)
	local medal = row:FindFirstChild("RankMedal")
	if not medal then
		medal = Instance.new("ImageLabel")
		medal.Name = "RankMedal"
		medal.BackgroundTransparency = 1
		medal.Position = UDim2.fromOffset(5, 4)
		medal.Size = UDim2.fromOffset(32, 32)
		medal.ZIndex = row.ZIndex + 2
		medal.Active = false
		medal.Parent = row
	end

	if not medalKey then
		medal.Image = ""
		medal.Visible = false
		return false
	end

	return BubblegumAssets.applyTo(medal, medalKey)
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

	for index, key in CONFETTI_ASSET_KEYS do
		local confetti = ArcadeUI.DecorativeImage(context.boardFrame, key, {
			name = `PerfectClearConfetti{index}`,
			position = UDim2.new(0.18 + index * 0.14, 0, 0.08, 0),
			size = UDim2.fromOffset(index % 2 == 0 and 18 or 14, index % 2 == 0 and 18 or 14),
			anchorPoint = Vector2.new(0.5, 0.5),
			rotation = -20 + index * 18,
			imageColor = index == 1 and ArcadeUI.Color.gold
				or index == 2 and ArcadeUI.Color.rimBright
				or index == 3 and ArcadeUI.Color.combo
				or ArcadeUI.Color.best,
			zIndex = 31,
		})
		if confetti then
			context.TweenService
				:Create(
					confetti,
					TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{
						Position = confetti.Position + UDim2.fromOffset(0, 34 + index * 4),
						ImageTransparency = 1,
						Rotation = confetti.Rotation + 38,
					}
				)
				:Play()
			task.delay(0.7, function()
				if confetti.Parent then
					confetti:Destroy()
				end
			end)
		end
	end
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
	local tokens = VisualTokens.resolve(1, 0)
	button.BorderSizePixel = 0
	button.BackgroundColor3 = tokens.boardCell
	button.ClipsDescendants = true
	corner(button, VisualTokens.Radius.cell)
	-- An empty cell is a recess in a dark well, not a tile. It gets a thin
	-- edge a shade lighter than itself -- enough to draw the grid, not enough
	-- to compete with a placed block -- and no gloss at all. The gloss
	-- gradient that used to sit here was laid over every stage color and read
	-- as a haze across the whole board once the chassis went dark.
	stroke(button, tokens.boardCellEdge, 1, 0.45)
	gradient(button, tokens.boardCell, tokens.boardWell, 90)
	return button
end

function ArcadeUI.PieceSlot(button)
	ArcadeUI.InnerPanel(button, {
		radius = 18,
		rimColor = ArcadeUI.Color.rim,
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
	stroke(row, ArcadeUI.Color.edge, 1, 0.28)
	gradient(row, ArcadeUI.Color.inner, ArcadeUI.Color.innerBottom, 90)
	ArcadeUI.SetLeaderboardMedal(row, index)
	return row
end

return ArcadeUI
