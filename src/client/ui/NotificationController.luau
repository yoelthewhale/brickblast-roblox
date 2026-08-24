local TweenService = game:GetService("TweenService")

local UITheme = require(script.Parent.UITheme)

local NotificationController = {}
NotificationController.__index = NotificationController

local MAX_NOTIFICATIONS = 4
local DEFAULT_DURATION = 3.2

-- Accent stripe per notification kind, taken from the block palette rather
-- than the old neon set, so a toast is built from colours already on screen.
local TYPE_COLORS = {
	info = Color3.fromRGB(84, 192, 232),
	success = Color3.fromRGB(108, 196, 124),
	warning = Color3.fromRGB(224, 138, 52),
	error = Color3.fromRGB(198, 64, 58),
	reward = Color3.fromRGB(229, 185, 60),
}

local function connect(self, signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self.connections, connection)
	return connection
end

function NotificationController.new(gui, options)
	options = options or {}

	local self = setmetatable({}, NotificationController)
	self.gui = gui
	self.isReducedMotion = options.isReducedMotion or function()
		return false
	end
	self.connections = {}
	self.items = {}
	self.keyedItems = {}
	self.lastShownAt = {}

	local container = Instance.new("Frame")
	container.Name = "NotificationStack"
	container.AnchorPoint = Vector2.new(0.5, 0)
	container.Position = UDim2.fromScale(0.5, 0.035)
	container.Size = UDim2.fromOffset(460, 220)
	container.BackgroundTransparency = 1
	container.ZIndex = UITheme.Z.toast
	container.Parent = gui
	self.container = container

	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = container
	self.scale = scale

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	connect(self, gui:GetPropertyChangedSignal("AbsoluteSize"), function()
		self:RefreshResponsiveLayout()
	end)
	self:RefreshResponsiveLayout()

	return self
end

function NotificationController:RefreshResponsiveLayout()
	local screenSize = self.gui.AbsoluteSize
	local width = math.clamp(screenSize.X - 32, 280, 460)
	self.container.Size = UDim2.fromOffset(width, 220)
	self.scale.Scale = screenSize.X < 620 and 0.88 or 1
end

function NotificationController:Show(message, kind, options)
	options = options or {}
	if typeof(message) ~= "string" or message == "" then
		return
	end

	kind = kind or "info"
	if options.key then
		self:Dismiss(options.key)
	end
	local key = `{kind}:{message}`
	local now = os.clock()
	if self.lastShownAt[key] and now - self.lastShownAt[key] < 0.75 then
		return
	end
	self.lastShownAt[key] = now

	while #self.items >= MAX_NOTIFICATIONS do
		local oldest = table.remove(self.items, 1)
		if oldest then
			oldest:Destroy()
		end
	end

	-- This was a white card with near-black text: correct when the chassis was
	-- cream, and a bright foreign rectangle once the game went dark. "That spot
	-- is blocked" is the most frequently seen toast in the game, so it was also
	-- the most visible thing still wearing the old palette. It is a raised
	-- surface from the shared theme now, and the type is light.
	local card = Instance.new("Frame")
	card.Name = "Notification"
	card.Size = UDim2.new(1, 0, 0, 54)
	card.BackgroundColor3 = UITheme.Color.panelRaised
	card.BackgroundTransparency = 0.04
	card.BorderSizePixel = 0
	card.ZIndex = UITheme.Z.toast
	card.Parent = self.container
	UITheme.card(card, {
		color = UITheme.Color.panelRaised,
		strokeColor = TYPE_COLORS[kind] or TYPE_COLORS.info,
		strokeTransparency = 0.12,
	})

	local accent = Instance.new("Frame")
	accent.Name = "Accent"
	accent.Size = UDim2.new(0, 7, 1, 0)
	accent.BackgroundColor3 = TYPE_COLORS[kind] or TYPE_COLORS.info
	accent.BorderSizePixel = 0
	accent.ZIndex = card.ZIndex + 1
	accent.Parent = card
	UITheme.corner(accent, UITheme.Radius.md)

	local label = Instance.new("TextLabel")
	label.Name = "Message"
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(18, 7)
	label.Size = UDim2.new(1, -30, 1, -14)
	label.Font = UITheme.Font.heading
	label.Text = message
	label.TextColor3 = UITheme.Color.text
	label.TextSize = 15
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.ZIndex = card.ZIndex + 1
	label.Parent = card

	table.insert(self.items, card)
	if options.key then
		self.keyedItems[options.key] = card
	end

	if not self.isReducedMotion() then
		card.Position = UDim2.fromOffset(0, -10)
		card.BackgroundTransparency = 1
		label.TextTransparency = 1
		TweenService:Create(card, UITheme.Motion.soft, {
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 0.08,
		}):Play()
		TweenService:Create(label, UITheme.Motion.soft, { TextTransparency = 0 }):Play()
	end

	task.delay(options.duration or DEFAULT_DURATION, function()
		if not card.Parent then
			return
		end

		local function removeCard()
			for index, item in self.items do
				if item == card then
					table.remove(self.items, index)
					break
				end
			end
			if options.key and self.keyedItems[options.key] == card then
				self.keyedItems[options.key] = nil
			end
			card:Destroy()
		end

		if self.isReducedMotion() then
			removeCard()
			return
		end

		local tween = TweenService:Create(card, TweenInfo.new(0.18), {
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(0, -8),
		})
		TweenService:Create(label, TweenInfo.new(0.16), { TextTransparency = 1 }):Play()
		tween:Play()
		tween.Completed:Once(removeCard)
	end)
end

function NotificationController:Dismiss(key)
	local card = self.keyedItems[key]
	if not card then
		return
	end

	for index, item in self.items do
		if item == card then
			table.remove(self.items, index)
			break
		end
	end
	self.keyedItems[key] = nil
	card:Destroy()
end

function NotificationController:Destroy()
	for _, connection in self.connections do
		connection:Disconnect()
	end
	table.clear(self.connections)
	if self.container then
		self.container:Destroy()
	end
end

return NotificationController
