-- The One More Chance offer, shown when a Solo run reaches a true no-move
-- state. Spec: docs/ONE_MORE_CHANCE_SPEC.md.
--
-- Its own ModuleScript for the same two reasons as ModeSelectPanel: it gets an
-- independent Luau register budget, which BlockBlastClient.client.luau does not
-- have to spare at 198/200, and it keeps a growing concern out of the monolith.
--
-- Presentation follows the reference Yoel approved: a bright gradient card, a
-- sunken preview panel showing what the offer actually gives you, one chunky
-- primary action, and a quieter decline beneath it. Two deliberate departures
-- from that reference, both explained where they happen:
--
--   * Body text is ink, not white. The reference puts white text on a light
--     gradient, which is poor contrast; ink on the same gradient is far more
--     readable and costs nothing.
--   * The decline stays a real, full-width button rather than a small
--     underlined text link. The reference is a rewarded ad, where nudging
--     costs the player nothing. Ours becomes a Robux purchase, and a
--     hard-to-hit decline next to a big spend button is the line between a
--     lifeline and a shakedown. It is quieter than the primary; it is not
--     hidden.
--
-- Also, and non-negotiably:
--
--   * No countdown timer, anywhere, ever.
--   * The decline holds default keyboard/gamepad focus. A player mashing A or
--     Enter at the moment they lose must never be able to spend by reflex.
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

local OPEN_TWEEN = TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local MAX_CARD_WIDTH = 440

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

local function label(parent, name, text, font, size, color, order, align)
	local item = Instance.new("TextLabel")
	item.Name = name
	item.BackgroundTransparency = 1
	item.Font = font
	item.Text = text
	item.TextColor3 = color
	item.TextSize = size
	item.TextWrapped = true
	item.TextXAlignment = align or Enum.TextXAlignment.Center
	item.AutomaticSize = Enum.AutomaticSize.Y
	item.Size = UDim2.new(1, 0, 0, 0)
	item.LayoutOrder = order
	item.ZIndex = parent.ZIndex + 1
	item.Parent = parent
	return item
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
	-- Darker than a normal modal scrim. The reference dims the board hard so the
	-- card is unmistakably the only live thing on screen, and the dead board
	-- stops competing for attention.
	overlay.BackgroundTransparency = 0.25
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
	-- Scale width with a cap: fills a phone with a gutter, stops at a
	-- comfortable reading width on desktop.
	card.Size = UDim2.new(1, -48, 0, 0)
	card.AutomaticSize = Enum.AutomaticSize.Y
	card.BackgroundColor3 = tokens.secondary
	card.BorderSizePixel = 0
	card.ZIndex = 81
	card:SetAttribute("BlocksWorkspaceDrag", true)
	card.Parent = overlay
	corner(card, VisualTokens.Radius.panel)
	stroke(card, tokens.gloss, 3, 0.55)
	self.card = card

	-- The reference's signature: a bright diagonal gradient across the whole
	-- card. Built from flavor tokens rather than fixed hues, so the card is
	-- mint on a Spearmint stage and bubblegum on a Bubblegum one.
	local gradient = Instance.new("UIGradient")
	gradient.Rotation = 35
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, tokens.tertiary),
		ColorSequenceKeypoint.new(0.5, tokens.secondary),
		ColorSequenceKeypoint.new(1, tokens.accent),
	})
	gradient.Parent = card
	self.gradient = gradient

	local sizeCap = Instance.new("UISizeConstraint")
	sizeCap.MaxSize = Vector2.new(MAX_CARD_WIDTH, math.huge)
	sizeCap.Parent = card

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, VisualTokens.Space.loose)
	padding.PaddingBottom = UDim.new(0, VisualTokens.Space.loose)
	padding.PaddingLeft = UDim.new(0, VisualTokens.Space.loose)
	padding.PaddingRight = UDim.new(0, VisualTokens.Space.loose)
	padding.Parent = card

	-- No shadow child on a list-laid-out frame. A shadow sized larger than its
	-- parent with no LayoutOrder sorts first and pushes real content off-screen
	-- -- the bug that hid the hub's left nav (#125, #126).
	local list = Instance.new("UIListLayout")
	list.FillDirection = Enum.FillDirection.Vertical
	list.SortOrder = Enum.SortOrder.LayoutOrder
	list.HorizontalAlignment = Enum.HorizontalAlignment.Center
	list.Padding = UDim.new(0, VisualTokens.Space.base)
	list.Parent = card

	self.title = label(card, "Title", "No moves left", Enum.Font.GothamBlack, 25, tokens.ink, 1)
	self.summary = label(card, "Summary", "", Enum.Font.GothamMedium, 15, tokens.ink, 2)

	self:BuildPreview(card, tokens)

	self.accept = self:BuildAccept(card, tokens)
	self.decline = self:BuildDecline(card, tokens)

	return self
end

-- The best idea in the reference: a sunken panel showing what the offer
-- actually gives you, so the player is not agreeing to an abstraction. Ours
-- states the two concrete effects rather than illustrating pieces, because the
-- replacement hand is generated server-side after the choice and cannot be
-- previewed honestly before it exists.
function ContinuePanel:BuildPreview(card, tokens)
	local well = Instance.new("Frame")
	well.Name = "OfferPreview"
	well.BackgroundColor3 = tokens.ink
	well.BackgroundTransparency = 0.82
	well.BorderSizePixel = 0
	well.Size = UDim2.new(1, 0, 0, 0)
	well.AutomaticSize = Enum.AutomaticSize.Y
	well.LayoutOrder = 3
	well.ZIndex = card.ZIndex + 1
	well.Parent = card
	corner(well, VisualTokens.Radius.card)
	stroke(well, tokens.gloss, 2, 0.65)

	local wellPadding = Instance.new("UIPadding")
	wellPadding.PaddingTop = UDim.new(0, VisualTokens.Space.base)
	wellPadding.PaddingBottom = UDim.new(0, VisualTokens.Space.base)
	wellPadding.PaddingLeft = UDim.new(0, VisualTokens.Space.roomy)
	wellPadding.PaddingRight = UDim.new(0, VisualTokens.Space.roomy)
	wellPadding.Parent = well

	local wellList = Instance.new("UIListLayout")
	wellList.FillDirection = Enum.FillDirection.Vertical
	wellList.SortOrder = Enum.SortOrder.LayoutOrder
	wellList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	wellList.Padding = UDim.new(0, VisualTokens.Space.snug)
	wellList.Parent = well

	label(
		well,
		"PreviewRewind",
		"Your last move is undone",
		Enum.Font.GothamBold,
		16,
		tokens.ink,
		1
	)
	label(
		well,
		"PreviewHand",
		"You get a fresh hand that fits",
		Enum.Font.GothamBold,
		16,
		tokens.ink,
		2
	)

	self.preview = well
end

function ContinuePanel:BuildAccept(card, tokens)
	local button = Instance.new("TextButton")
	button.Name = "UseContinue"
	button.AutoButtonColor = false
	button.BackgroundColor3 = tokens.hot
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBlack
	button.Text = "ONE MORE CHANCE"
	button.TextColor3 = tokens.gloss
	button.TextSize = 20
	button.Size = UDim2.new(1, 0, 0, 62)
	button.LayoutOrder = 5
	button.ZIndex = card.ZIndex + 1
	button.Selectable = true
	button:SetAttribute("BlocksWorkspaceDrag", true)
	button.Parent = card
	corner(button, VisualTokens.Radius.card)
	stroke(button, tokens.gloss, 3, 0.4)

	-- Chunky toy-plastic sheen, same treatment as the pieces.
	local sheen = Instance.new("UIGradient")
	sheen.Rotation = 90
	sheen.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, tokens.hot:Lerp(tokens.gloss, 0.3)),
		ColorSequenceKeypoint.new(1, tokens.hot),
	})
	sheen.Parent = button
	self.acceptSheen = sheen

	button.Activated:Connect(function()
		if button:GetAttribute("Busy") then
			return
		end
		self.playSound("Queue")
		button:SetAttribute("Busy", true)
		button.Text = "WORKING..."
		self.onAccept()
	end)

	return button
end

-- Quieter than the primary, but a real full-width button. See the header for
-- why this departs from the reference's text link.
function ContinuePanel:BuildDecline(card, tokens)
	local button = Instance.new("TextButton")
	button.Name = "EndRun"
	button.AutoButtonColor = false
	button.BackgroundColor3 = tokens.ink
	button.BackgroundTransparency = 0.78
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.Text = "End Run"
	button.TextColor3 = tokens.ink
	button.TextSize = 17
	button.Size = UDim2.new(1, 0, 0, 46)
	button.LayoutOrder = 6
	button.ZIndex = card.ZIndex + 1
	button.Selectable = true
	button:SetAttribute("BlocksWorkspaceDrag", true)
	button.Parent = card
	corner(button, VisualTokens.Radius.card)

	button.Activated:Connect(function()
		self.playSound("Blocked")
		self.onDecline()
	end)

	return button
end

-- Renders entirely from the server payload. `offer` is the `continueOffer`
-- table described in the spec's data contract.
function ContinuePanel:Update(offer)
	if typeof(offer) ~= "table" or offer.available ~= true then
		self:Hide()
		return
	end

	-- Repaint on every show so the card carries the run's flavor rather than a
	-- palette captured at construction. Resolved at rest: the payload carries no
	-- energy, and a card shown at the fail state should not claim run intensity.
	local tokens = VisualTokens.resolve(offer.stage or 1, 0)
	self:Repaint(tokens)

	local stage = offer.stage or 1
	local score = offer.score or 0
	local cap = offer.capThisRun or 1
	local used = offer.usedThisRun or 0
	local remaining = math.max(0, cap - used)

	if offer.source == "token" then
		self.accept.Text = "USE SAVED CHANCE"
	elseif offer.source == "purchase" and offer.priceText then
		self.accept.Text = `ONE MORE CHANCE · {offer.priceText}`
	else
		self.accept.Text = "ONE MORE CHANCE"
	end

	self.summary.Text = `Stage {stage} · {score} points  ·  {remaining} of {cap} left`

	self:Show()
end

function ContinuePanel:Repaint(tokens)
	self.card.BackgroundColor3 = tokens.secondary
	self.gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, tokens.tertiary),
		ColorSequenceKeypoint.new(0.5, tokens.secondary),
		ColorSequenceKeypoint.new(1, tokens.accent),
	})
	self.accept.BackgroundColor3 = tokens.hot
	self.acceptSheen.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, tokens.hot:Lerp(tokens.gloss, 0.3)),
		ColorSequenceKeypoint.new(1, tokens.hot),
	})
	self.title.TextColor3 = tokens.ink
	self.summary.TextColor3 = tokens.ink
end

function ContinuePanel:Show()
	self.accept:SetAttribute("Busy", nil)

	if self.visible then
		return
	end

	self.visible = true
	self.overlay.Visible = true

	-- Decline takes focus, never the accept button. See the header.
	GuiService.SelectedObject = self.decline

	if self.isReducedMotion() then
		return
	end

	self.card.Size = UDim2.new(0.9, -48, 0, 0)
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
