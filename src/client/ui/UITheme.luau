local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UITheme = {}

-- Derived from VisualTokens rather than hand-picked.
--
-- This was the "B2 Polished Arcade" palette: a near-black cabinet with neon
-- cyan and pink accents, tuned before the game had a visual direction. It
-- survived the Bubblegum era untouched, which is how the project ended up
-- running two unrelated palettes at once -- ArcadeUI on tokens, everything
-- built on UITheme on the old cabinet -- and why panels never quite matched
-- the board they sat next to.
--
-- Every key below is kept, spelling included, because these are read across
-- the menu, shop, story, cosmetic and developer panels and a missing key is a
-- runtime nil rather than a compile error. What changed is where the values
-- come from: the chassis roles now resolve against the same navy identity the
-- board does, and the accent roles are the reference's own block colors, so
-- an accent on a panel is literally a color the player already sees on a
-- piece.
local VisualTokens = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("game"):WaitForChild("VisualTokens")
)

local identity = VisualTokens.identity()
local chrome = VisualTokens.chrome()
local base = VisualTokens.resolve(1, 0)

UITheme.Color = {
	background = identity.well,
	panel = identity.surface,
	panelRaised = identity.surfaceRaised,
	panelSoft = base.surfaceTinted,
	stroke = base.boardRim,
	strokeSoft = identity.cellEdge,
	primary = base.primary,
	primaryDark = base.tertiary,
	cyan = Color3.fromRGB(84, 192, 232),
	lime = Color3.fromRGB(123, 209, 108),
	pink = base.hot,
	success = Color3.fromRGB(123, 209, 108),
	danger = Color3.fromRGB(198, 64, 58),
	warning = Color3.fromRGB(224, 138, 52),
	reward = Color3.fromRGB(229, 185, 60),
	text = identity.ink,
	textMuted = identity.inkSoft,
	textSoft = chrome.muted,
}

UITheme.Color.button = UITheme.Color.primary
UITheme.Color.buttonMuted = UITheme.Color.panelSoft
UITheme.Color.card = UITheme.Color.panelRaised
UITheme.Color.cardMuted = base.surfaceSunken
UITheme.Color.muted = UITheme.Color.textMuted
UITheme.Color.soft = UITheme.Color.textSoft
UITheme.Color.warn = UITheme.Color.warning
UITheme.Color.error = UITheme.Color.danger
-- The HUD reads directly on the room in the reference -- no white cards -- so
-- these are now dark surfaces with light type rather than the inverse pair
-- they used to be.
UITheme.Color.hudPanel = identity.surface
UITheme.Color.hudPanelBlue = identity.surfaceRaised
UITheme.Color.hudText = identity.ink
UITheme.Color.hudTextMuted = identity.inkSoft
UITheme.Color.hubGrass = Color3.fromRGB(123, 209, 108)
UITheme.Color.hubWater = Color3.fromRGB(84, 192, 232)
UITheme.Color.hubGold = Color3.fromRGB(229, 185, 60)
UITheme.Color.hubPurple = Color3.fromRGB(140, 108, 224)

UITheme.Font = {
	title = Enum.Font.GothamBlack,
	heading = Enum.Font.GothamBold,
	body = Enum.Font.Gotham,
	code = Enum.Font.Code,
}

UITheme.TextSize = {
	hero = 32,
	title = 26,
	heading = 19,
	body = 15,
	caption = 12,
}

UITheme.Space = {
	xs = 10,
	sm = 14,
	md = 18,
	lg = 28,
	xl = 36,
}

UITheme.Radius = {
	sm = 10,
	md = 16,
	lg = 20,
	pill = 999,
}

UITheme.Z = {
	hud = 10,
	modal = 40,
	toast = 60,
}

UITheme.Motion = {
	fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	soft = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	pop = TweenInfo.new(0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
}

function UITheme.corner(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or UITheme.Radius.md)
	corner.Parent = parent
	return corner
end

function UITheme.stroke(parent, color, thickness, transparency)
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or UITheme.Color.strokeSoft
	stroke.Thickness = thickness or 1
	stroke.Transparency = transparency or 0.18
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = parent
	return stroke
end

function UITheme.gradient(parent, topColor, bottomColor, rotation)
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, topColor),
		ColorSequenceKeypoint.new(1, bottomColor),
	})
	gradient.Rotation = rotation or 90
	gradient.Parent = parent
	return gradient
end

function UITheme.padding(parent, all)
	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, all)
	padding.PaddingBottom = UDim.new(0, all)
	padding.PaddingLeft = UDim.new(0, all)
	padding.PaddingRight = UDim.new(0, all)
	padding.Parent = parent
	return padding
end

function UITheme.panel(frame, options)
	options = options or {}
	frame.BackgroundColor3 = options.color or UITheme.Color.panel
	frame.BorderSizePixel = 0
	UITheme.corner(frame, options.radius or UITheme.Radius.lg)
	UITheme.stroke(
		frame,
		options.strokeColor or UITheme.Color.strokeSoft,
		options.strokeThickness or 1,
		options.strokeTransparency or 0.2
	)
	if options.gradient ~= false then
		UITheme.gradient(
			frame,
			options.color or UITheme.Color.panel,
			options.bottomColor or UITheme.Color.background,
			90
		)
	end
	return frame
end

function UITheme.card(frame, options)
	options = options or {}
	frame.BackgroundColor3 = options.color or UITheme.Color.panelRaised
	frame.BorderSizePixel = 0
	UITheme.corner(frame, options.radius or UITheme.Radius.md)
	UITheme.stroke(
		frame,
		options.strokeColor or UITheme.Color.strokeSoft,
		1,
		options.strokeTransparency or 0.28
	)
	return frame
end

function UITheme.button(button, variant)
	variant = variant or "secondary"
	button.BorderSizePixel = 0
	button.Font = UITheme.Font.heading
	button.TextSize = button.TextSize > 0 and button.TextSize or UITheme.TextSize.body
	button.TextColor3 = (variant == "success" or variant == "reward") and Color3.fromRGB(11, 35, 24)
		or UITheme.Color.text
	button.BackgroundColor3 = variant == "primary" and UITheme.Color.primary
		or variant == "success" and UITheme.Color.success
		or variant == "danger" and UITheme.Color.danger
		or variant == "reward" and UITheme.Color.reward
		or UITheme.Color.panelSoft
	button.Selectable = true
	UITheme.corner(button, UITheme.Radius.md)

	local outline = Instance.new("UIStroke")
	outline.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	outline.Color = Color3.fromRGB(6, 10, 20)
	outline.Thickness = 3
	outline.Transparency = 0
	outline.Parent = button

	local highlight = Instance.new("UIStroke")
	highlight.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	highlight.Color = button.BackgroundColor3:Lerp(Color3.fromRGB(255, 255, 255), 0.55)
	highlight.Thickness = 2
	highlight.Transparency = 0.15
	highlight.Parent = button

	UITheme.gradient(
		button,
		button.BackgroundColor3:Lerp(Color3.fromRGB(255, 255, 255), 0.16),
		button.BackgroundColor3:Lerp(Color3.fromRGB(0, 0, 0), 0.2),
		90
	)

	return button
end

function UITheme.closeButton(button)
	UITheme.button(button, "danger")
	button.Text = "X"
	button.TextSize = 16
	return button
end

function UITheme.text(label, role)
	label.BackgroundTransparency = 1
	label.TextColor3 = role == "muted" and UITheme.Color.textMuted
		or role == "soft" and UITheme.Color.textSoft
		or role == "reward" and UITheme.Color.reward
		or UITheme.Color.text
	label.Font = role == "title" and UITheme.Font.title
		or role == "heading" and UITheme.Font.heading
		or UITheme.Font.body
	return label
end

function UITheme.attachButtonFeedback(button, isReducedMotion)
	local scale = button:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = button

	local activeTween = nil
	local function tweenTo(nextScale)
		if isReducedMotion and isReducedMotion() then
			scale.Scale = 1
			return
		end
		if activeTween then
			activeTween:Cancel()
		end
		activeTween = TweenService:Create(scale, UITheme.Motion.fast, { Scale = nextScale })
		activeTween:Play()
	end

	button.MouseEnter:Connect(function()
		tweenTo(1.025)
	end)
	button.MouseLeave:Connect(function()
		tweenTo(1)
	end)
	button.MouseButton1Down:Connect(function()
		tweenTo(0.975)
	end)
	button.MouseButton1Up:Connect(function()
		tweenTo(1.025)
	end)

	return scale
end

return UITheme
