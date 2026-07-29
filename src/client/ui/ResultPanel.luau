local TweenService = game:GetService("TweenService")

local ResultPanel = {}
ResultPanel.__index = ResultPanel

local SOFT_TWEEN = TweenInfo.new(0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function ResultPanel.new(gui, queueEvent, options)
	options = options or {}

	local self = setmetatable({}, ResultPanel)
	self.queueEvent = queueEvent
	self.playSound = options.playSound or function() end
	self.isReducedMotion = options.isReducedMotion or function()
		return false
	end
	self.hasCurrentRun = options.hasCurrentRun or function()
		return false
	end

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(0.5, 0)
	panel.Position = UDim2.fromScale(0.5, 0.18)
	panel.Size = UDim2.fromOffset(420, 208)
	panel.BackgroundColor3 = Color3.fromRGB(31, 38, 52)
	panel.BackgroundTransparency = 0.04
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.ZIndex = 35
	panel.Parent = gui
	self.panel = panel

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.fromOffset(18, 14)
	titleLabel.Size = UDim2.fromOffset(326, 30)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Text = "Run Complete"
	titleLabel.TextColor3 = Color3.fromRGB(245, 247, 251)
	titleLabel.TextSize = 24
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextWrapped = true
	titleLabel.ZIndex = 36
	titleLabel.Parent = panel
	self.titleLabel = titleLabel

	local closeButton = Instance.new("TextButton")
	closeButton.Position = UDim2.new(1, -46, 0, 12)
	closeButton.Size = UDim2.fromOffset(32, 32)
	closeButton.BackgroundColor3 = Color3.fromRGB(45, 58, 82)
	closeButton.BorderSizePixel = 0
	closeButton.Font = Enum.Font.GothamBlack
	closeButton.Text = "X"
	closeButton.TextColor3 = Color3.fromRGB(245, 247, 251)
	closeButton.TextSize = 16
	closeButton.ZIndex = 36
	closeButton.Parent = panel

	local summaryLabel = Instance.new("TextLabel")
	summaryLabel.BackgroundTransparency = 1
	summaryLabel.Position = UDim2.fromOffset(18, 52)
	summaryLabel.Size = UDim2.fromOffset(384, 40)
	summaryLabel.Font = Enum.Font.GothamBold
	summaryLabel.Text = "Score 0 | 0 lines"
	summaryLabel.TextColor3 = Color3.fromRGB(245, 247, 251)
	summaryLabel.TextSize = 16
	summaryLabel.TextWrapped = true
	summaryLabel.TextXAlignment = Enum.TextXAlignment.Left
	summaryLabel.TextYAlignment = Enum.TextYAlignment.Top
	summaryLabel.ZIndex = 36
	summaryLabel.Parent = panel
	self.summaryLabel = summaryLabel

	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Position = UDim2.fromOffset(18, 92)
	rewardLabel.Size = UDim2.fromOffset(384, 28)
	rewardLabel.Font = Enum.Font.GothamBlack
	rewardLabel.Text = "+0 coins   +0 XP"
	rewardLabel.TextColor3 = Color3.fromRGB(255, 233, 148)
	rewardLabel.TextSize = 18
	rewardLabel.TextWrapped = true
	rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
	rewardLabel.ZIndex = 36
	rewardLabel.Parent = panel
	self.rewardLabel = rewardLabel

	local progressLabel = Instance.new("TextLabel")
	progressLabel.BackgroundTransparency = 1
	progressLabel.Position = UDim2.fromOffset(18, 122)
	progressLabel.Size = UDim2.fromOffset(384, 24)
	progressLabel.Font = Enum.Font.Gotham
	progressLabel.Text = "Best score: 0"
	progressLabel.TextColor3 = Color3.fromRGB(210, 224, 255)
	progressLabel.TextSize = 14
	progressLabel.TextWrapped = true
	progressLabel.TextXAlignment = Enum.TextXAlignment.Left
	progressLabel.ZIndex = 36
	progressLabel.Parent = panel
	self.progressLabel = progressLabel

	local unlockLabel = Instance.new("TextLabel")
	unlockLabel.BackgroundTransparency = 1
	unlockLabel.Position = UDim2.fromOffset(18, 146)
	unlockLabel.Size = UDim2.fromOffset(210, 42)
	unlockLabel.Font = Enum.Font.GothamBold
	unlockLabel.Text = "Next unlock: keep playing"
	unlockLabel.TextColor3 = Color3.fromRGB(193, 201, 215)
	unlockLabel.TextSize = 13
	unlockLabel.TextWrapped = true
	unlockLabel.TextXAlignment = Enum.TextXAlignment.Left
	unlockLabel.TextYAlignment = Enum.TextYAlignment.Top
	unlockLabel.ZIndex = 36
	unlockLabel.Parent = panel
	self.unlockLabel = unlockLabel

	local replayButton = Instance.new("TextButton")
	replayButton.Position = UDim2.fromOffset(248, 164)
	replayButton.Size = UDim2.fromOffset(154, 30)
	replayButton.BackgroundColor3 = Color3.fromRGB(64, 156, 255)
	replayButton.BorderSizePixel = 0
	replayButton.Font = Enum.Font.GothamBold
	replayButton.Text = "Queue Battle"
	replayButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	replayButton.TextSize = 14
	replayButton.ZIndex = 36
	replayButton.Parent = panel

	closeButton.MouseButton1Click:Connect(function()
		self.playSound("Button")
		self:Hide()
	end)

	replayButton.MouseButton1Click:Connect(function()
		self.playSound("Queue")
		self:Hide()
		if self.hasCurrentRun() then
			self.queueEvent:FireServer("LeaveBattle")
			task.delay(0.2, function()
				self.queueEvent:FireServer("Battle")
			end)
		else
			self.queueEvent:FireServer("Battle")
		end
	end)

	return self
end

function ResultPanel:Hide()
	self.panel.Visible = false
end

function ResultPanel:Show(result, message, won)
	result = typeof(result) == "table" and result or {}
	local outcome = result.outcome or (won and "Victory" or "Run Complete")
	local score = result.score or 0
	local linesCleared = result.linesCleared or 0
	local coins = result.coins or 0
	local xp = result.xp or 0
	local storyStars = result.storyStars or 0
	local bestScore = result.bestScore or score
	local previousBestScore = result.previousBestScore or bestScore
	local nextUnlockText = result.nextUnlockText or "Next unlock: keep playing"
	local bestDelta = math.max(0, bestScore - previousBestScore)
	local rewardText = `+{coins} coins   +{xp} XP`

	if storyStars > 0 then
		rewardText ..= `   +{storyStars} star`
	end

	self.titleLabel.Text = outcome
	self.summaryLabel.Text = message or `Score {score} | {linesCleared} lines`
	self.rewardLabel.Text = rewardText
	self.progressLabel.Text = bestDelta > 0 and `New best score: {bestScore} (+{bestDelta})`
		or `Best score: {bestScore} | Lines cleared: {linesCleared}`
	self.unlockLabel.Text = nextUnlockText
	self.panel.BackgroundColor3 = won and Color3.fromRGB(13, 55, 39) or Color3.fromRGB(31, 38, 52)
	self.panel.Visible = true

	if self.isReducedMotion() then
		self.panel.Position = UDim2.fromScale(0.5, 0.18)
		return
	end

	self.panel.Position = UDim2.fromScale(0.5, 0.14)
	TweenService:Create(self.panel, SOFT_TWEEN, {
		Position = UDim2.fromScale(0.5, 0.18),
	}):Play()
end

return ResultPanel
