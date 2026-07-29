local StoryPanel = {}
StoryPanel.__index = StoryPanel

local function missionStatusText(mission)
	if mission.completed then
		return "Replay"
	end
	if mission.next then
		return "Next"
	end
	if mission.unlocked then
		return "Unlocked"
	end

	return "Locked"
end

local function missionGoalText(mission)
	local parts = {}
	if (mission.targetScore or 0) > 0 then
		table.insert(parts, `{mission.targetScore} score`)
	end
	if (mission.targetLines or 0) > 0 then
		table.insert(parts, `{mission.targetLines} lines`)
	end

	return #parts > 0 and table.concat(parts, " + ") or "Finish the run"
end

local function setCardState(card, mission)
	if mission.next then
		card.BackgroundColor3 = Color3.fromRGB(64, 156, 255)
	elseif mission.completed then
		card.BackgroundColor3 = Color3.fromRGB(45, 58, 82)
	elseif mission.unlocked then
		card.BackgroundColor3 = Color3.fromRGB(31, 38, 52)
	else
		card.BackgroundColor3 = Color3.fromRGB(23, 27, 36)
	end

	card.Chapter.Text = `Chapter {mission.chapter or "?"}`
	card.Title.Text = mission.name or "Training"
	card.Goal.Text = mission.description or missionGoalText(mission)
	card.Status.Text = missionStatusText(mission)
	card.Status.TextColor3 = mission.unlocked and Color3.fromRGB(210, 224, 255)
		or Color3.fromRGB(153, 163, 179)
end

function StoryPanel.new(gui, options)
	options = options or {}

	local self = setmetatable({}, StoryPanel)
	self.getMissions = options.getMissions or function()
		return {}
	end
	self.playSound = options.playSound or function() end
	self.showMessage = options.showMessage or function() end
	self.startMission = options.startMission or function() end
	self.cards = {}
	self.cardMissions = {}

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0.5)
	panel.Position = UDim2.fromScale(0.5, 0.5)
	panel.Size = UDim2.fromOffset(520, 356)
	panel.BackgroundColor3 = Color3.fromRGB(14, 18, 27)
	panel.BackgroundTransparency = 0.03
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.ZIndex = 42
	panel.Parent = gui
	self.panel = panel

	local panelScale = Instance.new("UIScale")
	panelScale.Scale = 1
	panelScale.Parent = panel
	self.panelScale = panelScale
	self.updateScale = function()
		local screenSize = gui.AbsoluteSize
		panelScale.Scale =
			math.clamp(math.min((screenSize.X - 24) / 520, (screenSize.Y - 48) / 356), 0.72, 1)
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(self.updateScale)
	self.updateScale()

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(18, 14)
	title.Size = UDim2.fromOffset(420, 30)
	title.Font = Enum.Font.GothamBlack
	title.Text = "Story Missions"
	title.TextColor3 = Color3.fromRGB(245, 247, 251)
	title.TextSize = 24
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 43
	title.Parent = panel

	local closeButton = Instance.new("TextButton")
	closeButton.Position = UDim2.new(1, -48, 0, 14)
	closeButton.Size = UDim2.fromOffset(32, 32)
	closeButton.BackgroundColor3 = Color3.fromRGB(45, 58, 82)
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBlack
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(245, 247, 251)
	closeButton.TextSize = 16
	closeButton.ZIndex = 43
	closeButton.Parent = panel

	local subtitle = Instance.new("TextLabel")
	subtitle.BackgroundTransparency = 1
	subtitle.Position = UDim2.fromOffset(18, 48)
	subtitle.Size = UDim2.fromOffset(470, 34)
	subtitle.Font = Enum.Font.Gotham
	subtitle.Text = "Replay cleared chapters or push the next unlocked objective."
	subtitle.TextColor3 = Color3.fromRGB(193, 201, 215)
	subtitle.TextSize = 14
	subtitle.TextWrapped = true
	subtitle.TextXAlignment = Enum.TextXAlignment.Left
	subtitle.ZIndex = 43
	subtitle.Parent = panel

	for index = 1, 4 do
		local card = self:createMissionCard(index)
		card.Parent = panel
		self.cards[index] = card
	end

	closeButton.MouseButton1Click:Connect(function()
		self.playSound("Button")
		self:Hide()
	end)

	return self
end

function StoryPanel:createMissionCard(index)
	local card = Instance.new("TextButton")
	card.Position = UDim2.fromOffset(18, 88 + ((index - 1) * 62))
	card.Size = UDim2.fromOffset(484, 52)
	card.BorderSizePixel = 0
	card.Font = Enum.Font.GothamBold
	card.Text = ""
	card.ZIndex = 43

	local chapter = Instance.new("TextLabel")
	chapter.Name = "Chapter"
	chapter.BackgroundTransparency = 1
	chapter.Position = UDim2.fromOffset(12, 6)
	chapter.Size = UDim2.fromOffset(92, 18)
	chapter.Font = Enum.Font.GothamBold
	chapter.TextColor3 = Color3.fromRGB(210, 224, 255)
	chapter.TextSize = 12
	chapter.TextXAlignment = Enum.TextXAlignment.Left
	chapter.ZIndex = 44
	chapter.Parent = card

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(112, 6)
	title.Size = UDim2.fromOffset(214, 18)
	title.Font = Enum.Font.GothamBold
	title.TextColor3 = Color3.fromRGB(245, 247, 251)
	title.TextSize = 14
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.ZIndex = 44
	title.Parent = card

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.BackgroundTransparency = 1
	status.Position = UDim2.fromOffset(360, 6)
	status.Size = UDim2.fromOffset(104, 18)
	status.Font = Enum.Font.GothamBold
	status.TextColor3 = Color3.fromRGB(210, 224, 255)
	status.TextSize = 12
	status.TextXAlignment = Enum.TextXAlignment.Right
	status.ZIndex = 44
	status.Parent = card

	local goal = Instance.new("TextLabel")
	goal.Name = "Goal"
	goal.BackgroundTransparency = 1
	goal.Position = UDim2.fromOffset(12, 27)
	goal.Size = UDim2.fromOffset(452, 18)
	goal.Font = Enum.Font.Gotham
	goal.TextColor3 = Color3.fromRGB(193, 201, 215)
	goal.TextSize = 12
	goal.TextTruncate = Enum.TextTruncate.AtEnd
	goal.TextXAlignment = Enum.TextXAlignment.Left
	goal.ZIndex = 44
	goal.Parent = card

	card.MouseButton1Click:Connect(function()
		local mission = self.cardMissions[index]
		if typeof(mission) ~= "table" then
			return
		end

		if not mission.unlocked then
			self.playSound("Blocked")
			self.showMessage(
				"Clear your next chapter to unlock this mission.",
				Color3.fromRGB(251, 146, 60)
			)
			return
		end

		self.playSound("Queue")
		self.startMission(mission.chapter)
		self:Hide()
	end)

	return card
end

function StoryPanel:Hide()
	self.panel.Visible = false
end

function StoryPanel:Show()
	self:Refresh()
	self.updateScale()
	self.panel.Visible = true
end

function StoryPanel:Refresh()
	local missions = self.getMissions()

	for index, card in self.cards do
		local mission = missions[index]
		card.Visible = typeof(mission) == "table"
		self.cardMissions[index] = mission
		if mission then
			setCardState(card, mission)
		end
	end
end

return StoryPanel
