local GuiService = game:GetService("GuiService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local ArcadeUI = require(script.Parent.ArcadeUI)
local UITheme = require(script.Parent.UITheme)

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
	self.requestCooldownSeconds = options.requestCooldownSeconds or 0.45
	self.lastRequestAt = 0

	local panel = Instance.new("Frame")
	panel.AnchorPoint = Vector2.new(1, 0.5)
	panel.Position = UDim2.new(1, -112, 0.5, 88)
	panel.Size = UDim2.fromOffset(344, 214)
	panel.BackgroundColor3 = ArcadeUI.Color.inner
	panel.BackgroundTransparency = 0.04
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.ZIndex = 35
	panel.Parent = gui
	ArcadeUI.Panel(panel, {
		radius = 26,
		rimColor = ArcadeUI.Color.rimBright,
		strokeThickness = 4,
	})
	self.panel = panel

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Position = UDim2.fromOffset(18, 14)
	titleLabel.Size = UDim2.fromOffset(268, 30)
	titleLabel.Text = "Run Complete"
	titleLabel.TextSize = 22
	titleLabel.TextXAlignment = Enum.TextXAlignment.Left
	titleLabel.TextWrapped = true
	titleLabel.ZIndex = 36
	titleLabel.Parent = panel
	UITheme.text(titleLabel, "title")
	self.titleLabel = titleLabel

	local closeButton = Instance.new("TextButton")
	closeButton.Position = UDim2.new(1, -48, 0, 12)
	closeButton.Size = UDim2.fromOffset(34, 34)
	closeButton.ZIndex = 36
	closeButton.Parent = panel
	UITheme.closeButton(closeButton)
	UITheme.attachButtonFeedback(closeButton, self.isReducedMotion)

	local summaryCard = Instance.new("Frame")
	summaryCard.Position = UDim2.fromOffset(18, 54)
	summaryCard.Size = UDim2.fromOffset(308, 58)
	summaryCard.ZIndex = 36
	summaryCard.Parent = panel
	UITheme.card(summaryCard, { color = UITheme.Color.panelSoft, strokeTransparency = 0.38 })

	local summaryLabel = Instance.new("TextLabel")
	summaryLabel.BackgroundTransparency = 1
	summaryLabel.Position = UDim2.fromOffset(14, 10)
	summaryLabel.Size = UDim2.new(1, -28, 1, -20)
	summaryLabel.Text = "Score 0 | 0 lines"
	summaryLabel.TextSize = 16
	summaryLabel.TextWrapped = true
	summaryLabel.TextXAlignment = Enum.TextXAlignment.Left
	summaryLabel.TextYAlignment = Enum.TextYAlignment.Top
	summaryLabel.ZIndex = 36
	summaryLabel.Parent = summaryCard
	UITheme.text(summaryLabel, "heading")
	self.summaryLabel = summaryLabel

	local rewardCard = Instance.new("Frame")
	rewardCard.Position = UDim2.fromOffset(18, 122)
	rewardCard.Size = UDim2.fromOffset(308, 38)
	rewardCard.ZIndex = 36
	rewardCard.Parent = panel
	UITheme.card(rewardCard, {
		color = Color3.fromRGB(43, 35, 23),
		strokeColor = UITheme.Color.reward,
		strokeTransparency = 0.18,
	})

	local rewardLabel = Instance.new("TextLabel")
	rewardLabel.BackgroundTransparency = 1
	rewardLabel.Position = UDim2.fromOffset(14, 8)
	rewardLabel.Size = UDim2.new(1, -28, 1, -16)
	rewardLabel.Text = "+0 coins   +0 XP"
	rewardLabel.TextSize = 18
	rewardLabel.TextWrapped = true
	rewardLabel.TextXAlignment = Enum.TextXAlignment.Left
	rewardLabel.ZIndex = 36
	rewardLabel.Parent = rewardCard
	UITheme.text(rewardLabel, "reward")
	self.rewardLabel = rewardLabel

	local progressLabel = Instance.new("TextLabel")
	progressLabel.BackgroundTransparency = 1
	progressLabel.Position = UDim2.fromOffset(18, 166)
	progressLabel.Size = UDim2.fromOffset(142, 20)
	progressLabel.Text = "Best score: 0"
	progressLabel.TextSize = 12
	progressLabel.TextWrapped = true
	progressLabel.TextXAlignment = Enum.TextXAlignment.Left
	progressLabel.ZIndex = 36
	progressLabel.Parent = panel
	UITheme.text(progressLabel, "muted")
	self.progressLabel = progressLabel

	local unlockLabel = Instance.new("TextLabel")
	unlockLabel.BackgroundTransparency = 1
	unlockLabel.Position = UDim2.fromOffset(18, 186)
	unlockLabel.Size = UDim2.fromOffset(142, 18)
	unlockLabel.Text = "Next unlock: keep playing"
	unlockLabel.TextSize = 10
	unlockLabel.TextWrapped = true
	unlockLabel.TextXAlignment = Enum.TextXAlignment.Left
	unlockLabel.TextYAlignment = Enum.TextYAlignment.Top
	unlockLabel.ZIndex = 36
	unlockLabel.Parent = panel
	UITheme.text(unlockLabel, "soft")
	self.unlockLabel = unlockLabel

	local replayButton = Instance.new("TextButton")
	replayButton.Position = UDim2.fromOffset(174, 168)
	replayButton.Size = UDim2.fromOffset(152, 36)
	replayButton.Text = "Play Again"
	replayButton.TextSize = 13
	replayButton.ZIndex = 36
	replayButton.Parent = panel
	UITheme.button(replayButton, "primary")
	UITheme.attachButtonFeedback(replayButton, self.isReducedMotion)
	self.closeButton = closeButton
	self.replayButton = replayButton
	closeButton.NextSelectionDown = replayButton
	replayButton.NextSelectionUp = closeButton

	closeButton.Activated:Connect(function()
		self.playSound("Button")
		self:Hide()
	end)

	replayButton.Activated:Connect(function()
		local now = os.clock()
		if now - self.lastRequestAt < self.requestCooldownSeconds then
			return
		end
		self.lastRequestAt = now
		self.playSound("Queue")
		self:Hide()
		if self.hasCurrentRun() then
			self.queueEvent:FireServer("PlayAgain")
		else
			self.queueEvent:FireServer("Solo")
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
	local highestCombo = result.highestCombo or 0
	local duration = result.duration
	local coins = result.coins or 0
	local xp = result.xp or 0
	local dailyBonusCoins = result.dailyBonusCoins or 0
	local dailyBonusXp = result.dailyBonusXp or 0
	local storyStars = result.storyStars or 0
	local bestScore = result.bestScore or score
	local previousBestScore = result.previousBestScore or bestScore
	local nextUnlockText = result.nextUnlockText or "Next unlock: keep playing"
	local storyText = result.storyText
	local bestDelta = math.max(0, bestScore - previousBestScore)
	local rewardText = `+{coins} coins   +{xp} XP`

	if storyStars > 0 then
		rewardText ..= `   +{storyStars} star`
	end
	if dailyBonusCoins > 0 or dailyBonusXp > 0 then
		rewardText ..= "   Daily bonus!"
	end

	self.titleLabel.Text = outcome
	self.summaryLabel.Text = storyText
		or message
		or `Score {score} | {linesCleared} lines | Best combo x{math.max(1, highestCombo)}`
	self.rewardLabel.Text = rewardText
	self.progressLabel.Text = bestDelta > 0 and `New best score: {bestScore} (+{bestDelta})`
		or duration and `Best score: {bestScore} | Combo x{math.max(1, highestCombo)} | {duration}s`
		or `Best score: {bestScore} | Combo x{math.max(1, highestCombo)}`
	self.unlockLabel.Text = nextUnlockText
	self.panel.BackgroundColor3 = won and Color3.fromRGB(12, 45, 42) or ArcadeUI.Color.inner
	self.panel.Visible = true
	if UserInputService.GamepadEnabled then
		GuiService.SelectedObject = self.replayButton
	end

	if self.isReducedMotion() then
		self.panel.Position = UDim2.new(1, -112, 0.5, 88)
		return
	end

	self.panel.Position = UDim2.new(1, -112, 0.5, 62)
	TweenService:Create(self.panel, SOFT_TWEEN, {
		Position = UDim2.new(1, -112, 0.5, 88),
	}):Play()
end

return ResultPanel
