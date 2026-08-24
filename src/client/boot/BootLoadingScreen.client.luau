-- The first thing a player sees. Runs from ReplicatedFirst, which is the only
-- place early enough to replace Roblox's default loading screen.
--
-- Two constraints shape everything below, and both are easy to break by
-- "improving" this file later:
--
-- 1. IT CANNOT REQUIRE ANYTHING FROM ReplicatedStorage.
--    ReplicatedFirst runs before ReplicatedStorage has replicated, so a
--    `WaitForChild("Shared")` here would block for seconds on exactly the
--    screen whose whole job is to appear instantly. That is why the palette
--    below is written out rather than pulled from VisualTokens. Those values
--    mirror `VisualTokens.identity()` and the Bubblegum flavor anchor; if the
--    identity is ever retuned, these need the same edit by hand. There is no
--    way around that without reintroducing the blocking require.
--
-- 2. IT MUST NEVER TRAP THE PLAYER.
--    A loading screen that fails to dismiss is worse than no loading screen at
--    all -- the game looks broken and the player leaves. Every wait here is
--    bounded, and a hard deadline dismisses the screen regardless of what else
--    has or has not happened.
--
-- This screen covers asset loading only. The client's own loading overlay
-- takes over for the server handshake, so the two are styled to match.

local ContentProvider = game:GetService("ContentProvider")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Mirrors VisualTokens.identity() plus the Bubblegum flavor anchor. See note 1.
local PALETTE = {
	atmosphere = Color3.fromRGB(255, 183, 216),
	surface = Color3.fromRGB(255, 250, 246),
	ink = Color3.fromRGB(58, 30, 66),
	inkSoft = Color3.fromRGB(116, 82, 128),
	primary = Color3.fromRGB(255, 138, 193),
	hot = Color3.fromRGB(255, 64, 140),
	gloss = Color3.fromRGB(255, 255, 255),
}

-- The tetromino drawn as { x, y } cells on a 3x2 grid, matching the reference:
-- a three-long bar with one cell raised at the left.
local PIECE_CELLS = { { 0, 1 }, { 1, 1 }, { 2, 1 }, { 2, 0 } }
local PIECE_CELL_SIZE = 26
local PIECE_CELL_GAP = 4

local SPIN_SECONDS = 1.6
local MINIMUM_VISIBLE_SECONDS = 0.6
local HARD_DEADLINE_SECONDS = 20

local player = Players.LocalPlayer

-- Roblox's own screen has to go before ours is parented, or they overlap.
pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

-- Respect the platform accessibility setting where it exists. Wrapped because
-- ReducedMotionEnabled is not present on every client version, and this screen
-- must never fail to build over a missing property.
local function prefersReducedMotion()
	local ok, value = pcall(function()
		return GuiService.ReducedMotionEnabled
	end)
	return ok and value == true
end

local function corner(instance, radius)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius)
	item.Parent = instance
	return item
end

local screen = Instance.new("ScreenGui")
screen.Name = "BrickBlastBootLoading"
screen.IgnoreGuiInset = true
screen.ResetOnSpawn = false
screen.DisplayOrder = 1000
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

local backdrop = Instance.new("Frame")
backdrop.Name = "Backdrop"
backdrop.BackgroundColor3 = PALETTE.atmosphere
backdrop.BorderSizePixel = 0
backdrop.Size = UDim2.fromScale(1, 1)
backdrop.ZIndex = 1
backdrop.Parent = screen

local wash = Instance.new("UIGradient")
wash.Rotation = 90
wash.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, PALETTE.surface),
	ColorSequenceKeypoint.new(1, PALETTE.atmosphere),
})
wash.Parent = backdrop

local title = Instance.new("TextLabel")
title.Name = "Wordmark"
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.BackgroundTransparency = 1
title.Position = UDim2.fromScale(0.5, 0.36)
title.Size = UDim2.new(1, -48, 0, 60)
title.Font = Enum.Font.GothamBlack
title.Text = "BRICKBLAST"
title.TextColor3 = PALETTE.ink
title.TextSize = 46
title.TextScaled = false
title.ZIndex = 2
title.Parent = backdrop

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.AnchorPoint = Vector2.new(0.5, 0.5)
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromScale(0.5, 0.43)
subtitle.Size = UDim2.new(1, -48, 0, 24)
subtitle.Font = Enum.Font.GothamBold
subtitle.Text = "BUBBLEGUM TOYBOX"
subtitle.TextColor3 = PALETTE.inkSoft
subtitle.TextSize = 15
subtitle.ZIndex = 2
subtitle.Parent = backdrop

-- The spinner. A real piece rather than a generic ring, so the very first
-- thing on screen is the object the whole game is about.
local spinner = Instance.new("Frame")
spinner.Name = "PieceSpinner"
spinner.AnchorPoint = Vector2.new(0.5, 0.5)
spinner.BackgroundTransparency = 1
spinner.Position = UDim2.fromScale(0.5, 0.58)
spinner.Size =
	UDim2.fromOffset(PIECE_CELL_SIZE * 3 + PIECE_CELL_GAP * 2, PIECE_CELL_SIZE * 2 + PIECE_CELL_GAP)
spinner.ZIndex = 2
spinner.Parent = backdrop

for index, cell in PIECE_CELLS do
	local block = Instance.new("Frame")
	block.Name = `Cell{index}`
	block.BackgroundColor3 = if index % 2 == 0 then PALETTE.primary else PALETTE.hot
	block.BorderSizePixel = 0
	block.Position = UDim2.fromOffset(
		cell[1] * (PIECE_CELL_SIZE + PIECE_CELL_GAP),
		cell[2] * (PIECE_CELL_SIZE + PIECE_CELL_GAP)
	)
	block.Size = UDim2.fromOffset(PIECE_CELL_SIZE, PIECE_CELL_SIZE)
	block.ZIndex = 3
	block.Parent = spinner
	corner(block, 7)

	-- Same gloss-over-shadow treatment the real pieces use, so the spinner is
	-- recognisably made of BrickBlast blocks rather than flat squares.
	local sheen = Instance.new("UIGradient")
	sheen.Rotation = 90
	sheen.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, block.BackgroundColor3:Lerp(PALETTE.gloss, 0.42)),
		ColorSequenceKeypoint.new(1, block.BackgroundColor3),
	})
	sheen.Parent = block
end

local status = Instance.new("TextLabel")
status.Name = "Status"
status.AnchorPoint = Vector2.new(0.5, 0.5)
status.BackgroundTransparency = 1
status.Position = UDim2.fromScale(0.5, 0.72)
status.Size = UDim2.new(1, -48, 0, 24)
status.Font = Enum.Font.GothamBold
status.Text = "Loading..."
status.TextColor3 = PALETTE.inkSoft
status.TextSize = 16
status.ZIndex = 2
status.Parent = backdrop

screen.Parent = player:WaitForChild("PlayerGui")

local reducedMotion = prefersReducedMotion()
local spinConnection = nil

if reducedMotion then
	-- Reduced motion means instant, not absent: the piece still reads as the
	-- loading indicator, it just holds a fixed friendly angle instead of
	-- rotating.
	spinner.Rotation = 12
else
	local elapsed = 0
	spinConnection = RunService.RenderStepped:Connect(function(delta)
		elapsed += delta
		spinner.Rotation = (elapsed / SPIN_SECONDS) * 360 % 360
	end)
end

local startedAt = os.clock()
local dismissed = false

local function dismiss()
	if dismissed then
		return
	end
	dismissed = true

	if spinConnection then
		spinConnection:Disconnect()
		spinConnection = nil
	end

	if reducedMotion then
		screen:Destroy()
		return
	end

	local fade = TweenService:Create(backdrop, TweenInfo.new(0.35), {
		BackgroundTransparency = 1,
	})
	for _, item in backdrop:GetDescendants() do
		if item:IsA("TextLabel") then
			TweenService:Create(item, TweenInfo.new(0.25), { TextTransparency = 1 }):Play()
		elseif item:IsA("Frame") then
			TweenService:Create(item, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
		end
	end
	fade:Play()
	fade.Completed:Once(function()
		screen:Destroy()
	end)
end

-- Bounded wait. Nothing below may block indefinitely: see note 2.
task.spawn(function()
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	-- Preloading the pieces we just built is cheap and means the handoff to the
	-- client's own overlay does not flash unstyled content.
	pcall(function()
		ContentProvider:PreloadAsync({ backdrop })
	end)

	local held = os.clock() - startedAt
	if held < MINIMUM_VISIBLE_SECONDS then
		task.wait(MINIMUM_VISIBLE_SECONDS - held)
	end

	dismiss()
end)

-- The safety net. If anything above stalls -- a hung Loaded signal, a preload
-- that never returns -- the screen still goes away.
task.delay(HARD_DEADLINE_SECONDS, dismiss)
