-- The One More Chance offer, shown when a Solo run reaches a true no-move
-- state. Spec: docs/ONE_MORE_CHANCE_SPEC.md.
--
-- Its own ModuleScript for the same two reasons as ModeSelectPanel: it gets an
-- independent Luau register budget, which BlockBlastClient.client.luau does not
-- have to spare at 198/200, and it keeps a growing concern out of the monolith
-- rather than adding another 160 lines to it.
--
-- Three things here are requirements from the spec rather than styling, and
-- each is easy to erode without noticing:
--
--   * No countdown timer, anywhere, ever. A ticking clock on this panel is the
--     clearest dark pattern in the genre, and it is the single change most
--     likely to make a paid version read as predatory.
--   * End Run carries equal visual weight -- same height, same text size, same
--     contrast. It may be quieter in colour; it must never be greyed, shrunk,
--     or hidden.
--   * End Run holds default keyboard/gamepad focus. A player mashing A or
--     Enter at the moment they lose must never be able to spend by reflex.
--     Harmless while the continue is free; the habit has to exist before the
--     Robux path lands.
--
-- The panel renders purely from the server's `continueOffer` payload. It never
-- decides entitlement, never computes price, and never assumes a source, so
-- adding the paid path later populates two fields rather than rewriting this.

local GuiService = game:GetService("GuiService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local GameShared = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("game")
local VisualTokens = require(GameShared:WaitForChild("VisualTokens"))

local ContinuePanel = {}
ContinuePanel.__index = ContinuePanel

local OPEN_TWEEN = TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

-- Wide enough to read comfortably, capped so it never exceeds a phone's width.
-- The card itself is scale-sized against the overlay, so the cap is the only
-- number that needs to exist.
local MAX_CARD_WIDTH = 420

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

local function label(parent, name, text, font, size, color, order)
	local item = Instance.new("TextLabel")
	item.Name = name
	item.BackgroundTransparency = 1
	item.Font = font
	item.Text = text
	item.TextColor3 = color
	item.TextSize = size
	item.TextWrapped = true
	item.TextXAlignment = Enum.TextXAlignment.Left
	item.AutomaticSize = Enum.AutomaticSize.Y
	item.Size = UDim2.new(1, 0, 0, 0)
	item.LayoutOrder = order
	item.ZIndex = parent.ZIndex + 1
	item.Parent = parent
	return item
end

-- Both buttons are built by the same function with the same geometry, so
-- "equal visual weight" is structural rather than something to remember.
local function actionButton(parent, name, text, fill, ink, order)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AutoButtonColor = false
	button.BackgroundColor3 = fill
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.Text = text
	button.TextColor3 = ink
	button.TextSize = 18
	button.Size = UDim2.new(1, 0, 0, 54)
	button.LayoutOrder = order
	button.ZIndex = parent.ZIndex + 1
	button.Selectable = true
	button:SetAttribute("BlocksWorkspaceDrag", true)
	button.Parent = parent
	corner(button, VisualTokens.Radius.card)
	return button
end

function ContinuePanel.new(parent, options)
	options = options or {}

	local self = setmetatable({}, ContinuePanel)
	self.onAccept = options.onAccept or function() end
	self.onDecline = options.onDecline or function() end
	self.playSound = options.playSound or function() end
	self.isReducedMotion = options.isReducedMotion or function()
		return false
	end
	self.visible = false

	local tokens = VisualTokens.resolve(1, 0)

	local overlay = Instance.new("Frame")
	overlay.Name = "OneMoreChanceOverlay"
	overlay.BackgroundColor3 = tokens.ink
	overlay.BackgroundTransparency = 0.42
	overlay.BorderSizePixel = 0
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.Visible = false
	overlay.Active = true
	overlay.ZIndex = 80
	overlay:SetAttribute("BlocksWorkspaceDrag", true)
	overlay.Parent = parent
	self.overlay = overlay

	local card = Instance.new("Frame")
	card.Name = "OneMoreChanceCard"
	card.AnchorPoint = Vector2.new(0.5, 0.5)
	card.Position = UDim2.fromScale(0.5, 0.5)
	-- Scale width minus a margin, capped by the constraint below: fills a phone
	-- with a gutter, stops at a comfortable reading width on desktop. The old
	-- panel used a fixed 420px offset, which overflowed a 375pt phone entirely.
	card.Size = UDim2.new(1, -48, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = tokens.surface
	card.BorderSizePixel = 0
	card.ZIndex = 81
	card:SetAttribute("BlocksWorkspaceDrag", true)
	card.Parent = overlay
	corner(card, VisualTokens.Radius.panel)
	stroke(card, tokens.boardRim, 4, 0.1)
	self.card = card

	local sizeCap = Instance.new("UISizeConstraint")
	sizeCap.MaxSize = Vector2.new(MAX_CARD_WIDTH, math.huge)
	sizeCap.Parent = card

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, VisualTokens.Space.loose)
	padding.PaddingBottom = UDim.new(0, VisualTokens.Space.loose)
	padding.PaddingLeft = UDim.new(0, VisualTokens.Space.loose)
	padding.PaddingRight = UDim.new(0, VisualTokens.Space.loose)
	padding.Parent = card

	-- No shadow child here, deliberately. UIListLayout lays out every child, and
	-- a shadow sized larger than its parent with no LayoutOrder sorts first and
	-- pushes real content off-screen -- the bug that hid the hub's left nav.
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.Padding = UDim.new(0, VisualTokens.Space.base)
	list.Parent = card

	self.title = label(card, "Title", "No moves left", Enum.Font.GothamBlack, 26, tokens.ink, 1)
	self.summary = label(card, "Summary", "", Enum.Font.GothamMedium, 15, tokens.inkSoft, 2)
	self.body = label(
		card,
		"Body",
		"Rewind one move and get a fresh hand that fits",
		Enum.Font.GothamMedium,
		15,
		tokens.inkSoft,
		3
	)
	self.meta = label(card, "Meta", "", Enum.Font.GothamBold, 14, tokens.inkSoft, 4)

	-- Buttons stack full-width rather than sitting side by side. Side-by-side
	-- at a fail state invites a mis-tap on the option that will eventually cost
	-- money, and it is what forced the old panel to shrink its primary label to
	-- fit.
	self.accept = actionButton(card, "UseContinue", "ONE MORE CHANCE", tokens.accent, tokens.ink, 5)
	stroke(self.accept, tokens.hot, 3, 0.1)

	self.decline = actionButton(card, "EndRun", "END RUN", tokens.surfaceSunken, tokens.ink, 6)
	stroke(self.decline, tokens.boardCellEdge, 2, 0.3)

	self.accept.Activated:Connect(function()
		if self.accept:GetAttribute("Busy") then
			return
		end
		self.playSound("Queue")
		self.accept:SetAttribute("Busy", true)
		self.accept.Text = "WORKING..."
		self.onAccept()
	end)

	self.decline.Activated:Connect(function()
		self.playSound("Blocked")
		self.onDecline()
	end)

	return self
end

-- Renders entirely from the server payload. `offer` is the `continueOffer`
-- table described in the spec's data contract.
function ContinuePanel:Update(offer)
	local shouldShow = typeof(offer) == "table" and offer.available == true

	if not shouldShow then
		self:Hide()
		return
	end

	local stage = offer.stage or 1
	local score = offer.score or 0
	self.summary.Text = `Stage {stage} · {score} points`

	local cap = offer.capThisRun or 1
	local used = offer.usedThisRun or 0
	local remaining = math.max(0, cap - used)

	-- The entitlement line is the only part that differs between a free
	-- prototype, a redeemed token, and a purchase.
	if offer.source == "token" then
		self.meta.Text = "Using your saved One More Chance"
	elseif offer.source == "purchase" and offer.priceText then
		self.meta.Text = `{offer.priceText} · {remaining} of {cap} this run`
	else
		self.meta.Text = `Free · {remaining} of {cap} this run`
	end

	self:Show()
end

function ContinuePanel:Show()
	self.accept:SetAttribute("Busy", nil)
	self.accept.Text = "ONE MORE CHANCE"

	if self.visible then
		return
	end

	self.visible = true
	self.overlay.Visible = true

	-- End Run takes focus, never the accept button. See the header.
	GuiService.SelectedObject = self.decline

	if self.isReducedMotion() then
		return
	end

	self.card.Size = UDim2.new(0.92, -48, 0, 0)
	TweenService:Create(self.card, OPEN_TWEEN, {
		Size = UDim2.new(1, -48, 0, 0),
	}):Play()
end

function ContinuePanel:Hide()
	if not self.visible then
		return
	end

	self.visible = false
	self.overlay.Visible = false

	if GuiService.SelectedObject == self.decline or GuiService.SelectedObject == self.accept then
		GuiService.SelectedObject = nil
	end
end

function ContinuePanel:Destroy()
	if self.overlay then
		self.overlay:Destroy()
	end
end

return ContinuePanel
