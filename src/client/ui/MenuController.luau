local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local UITheme = require(script.Parent.UITheme)

local MenuController = {}
MenuController.__index = MenuController

local function connect(self, signal, callback)
	local connection = signal:Connect(callback)
	table.insert(self.connections, connection)
	return connection
end

function MenuController.new(gui, options)
	options = options or {}

	local self = setmetatable({}, MenuController)
	self.gui = gui
	self.isReducedMotion = options.isReducedMotion or function()
		return false
	end
	self.playSound = options.playSound or function() end
	self.connections = {}
	self.activeKey = nil

	local dim = Instance.new("TextButton")
	dim.Name = "MenuDim"
	dim.BackgroundColor3 = Color3.fromRGB(15, 24, 32)
	dim.BackgroundTransparency = 0.68
	dim.BorderSizePixel = 0
	dim.Text = ""
	dim.Visible = false
	dim.AutoButtonColor = false
	dim.Size = UDim2.fromScale(1, 1)
	dim.ZIndex = UITheme.Z.modal - 2
	dim.Parent = gui
	self.dim = dim

	local panel = Instance.new("Frame")
	panel.Name = "SideMenuPanel"
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -108, 0.5, 0)
	panel.Size = UDim2.fromOffset(380, 420)
	panel.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.ZIndex = UITheme.Z.modal
	panel.Parent = gui
	UITheme.panel(panel, {
		color = Color3.fromRGB(255, 255, 255),
		bottomColor = Color3.fromRGB(225, 246, 255),
		strokeColor = Color3.fromRGB(135, 201, 255),
		strokeTransparency = 0.12,
	})
	self.panel = panel

	local scale = Instance.new("UIScale")
	scale.Scale = 1
	scale.Parent = panel
	self.scale = scale

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(20, 14)
	title.Size = UDim2.new(1, -68, 0, 34)
	title.Font = UITheme.Font.title
	title.Text = "Menu"
	title.TextColor3 = Color3.fromRGB(35, 45, 55)
	title.TextSize = 22
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = panel.ZIndex + 1
	title.Parent = panel
	self.title = title

	local close = Instance.new("TextButton")
	close.Name = "Close"
	close.AnchorPoint = Vector2.new(1, 0)
	close.Position = UDim2.new(1, -16, 0, 14)
	close.Size = UDim2.fromOffset(36, 36)
	close.Text = "X"
	close.TextSize = 16
	close.ZIndex = panel.ZIndex + 1
	close.Parent = panel
	UITheme.closeButton(close)
	UITheme.attachButtonFeedback(close, self.isReducedMotion)
	self.closeButton = close

	local content = Instance.new("Frame")
	content.Name = "Content"
	content.BackgroundTransparency = 1
	content.Position = UDim2.fromOffset(18, 62)
	content.Size = UDim2.new(1, -36, 1, -80)
	content.ZIndex = panel.ZIndex + 1
	content.Parent = panel
	self.content = content

	connect(self, close.Activated, function()
		self.playSound("Button")
		self:Close()
	end)
	connect(self, dim.Activated, function()
		self:Close()
	end)
	connect(self, UserInputService.InputBegan, function(input, processed)
		if processed or not self.panel.Visible then
			return
		end
		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.ButtonB then
			self.playSound("Button")
			self:Close()
		end
	end)
	connect(self, gui:GetPropertyChangedSignal("AbsoluteSize"), function()
		self:RefreshResponsiveLayout()
	end)
	self:RefreshResponsiveLayout()

	return self
end

function MenuController:RefreshResponsiveLayout()
	local screenSize = self.gui.AbsoluteSize
	local narrow = screenSize.X < 760
	local width = narrow and math.clamp(screenSize.X - 28, 300, 360) or 380
	local height = math.clamp(screenSize.Y - 96, 320, narrow and 380 or 430)
	self.panel.Size = UDim2.fromOffset(width, height)
	self.panel.Position = narrow and UDim2.new(0.5, 0, 0.5, 0) or UDim2.new(1, -108, 0.5, 0)
	self.panel.AnchorPoint = narrow and Vector2.new(0.5, 0.5) or Vector2.new(1, 0.5)
	self.scale.Scale = screenSize.X < 520 and 0.92 or 1
end

function MenuController:Clear()
	for _, child in self.content:GetChildren() do
		child:Destroy()
	end
end

function MenuController:Open(key, title, render)
	self.activeKey = key
	self.title.Text = title or "Menu"
	self:Clear()
	if render then
		render(self.content)
	end
	self.dim.Visible = true
	self.panel.Visible = true
	self:RefreshResponsiveLayout()

	if self.isReducedMotion() then
		self.panel.BackgroundTransparency = 0.05
	else
		self.panel.BackgroundTransparency = 1
		local start = self.panel.Position + UDim2.fromOffset(16, 0)
		local finish = self.panel.Position
		self.panel.Position = start
		TweenService:Create(self.panel, UITheme.Motion.soft, {
			Position = finish,
			BackgroundTransparency = 0.05,
		}):Play()
	end

	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = self.closeButton
	end
end

function MenuController:Close()
	if not self.panel.Visible then
		return
	end
	self.activeKey = nil
	self.dim.Visible = false
	self.panel.Visible = false
	self:Clear()
	if GuiService.SelectedObject and GuiService.SelectedObject:IsDescendantOf(self.panel) then
		GuiService.SelectedObject = nil
	end
end

function MenuController:Destroy()
	for _, connection in self.connections do
		connection:Disconnect()
	end
	table.clear(self.connections)
	if self.dim then
		self.dim:Destroy()
	end
	if self.panel then
		self.panel:Destroy()
	end
end

return MenuController
