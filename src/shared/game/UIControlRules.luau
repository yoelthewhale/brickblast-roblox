local Config = require(script.Parent.Config)

local UIControlRules = {}

UIControlRules.ServerActionCooldownSeconds = 0.45

UIControlRules.HubControls = {
	{
		name = "playButton",
		label = "PLAY",
		action = "Queue.Solo",
		enabledWhen = "Solo",
	},
	{
		name = "shopButton",
		label = "SHOP",
		action = "ShopPanel.Show",
		enabledWhen = "Hub",
	},
	{
		name = "inventoryButton",
		label = "INVENTORY",
		action = "CosmeticPanel.Show",
		enabledWhen = "Hub",
	},
	{
		name = "settingsButton",
		label = "SETTINGS",
		action = "Menu.Settings",
		enabledWhen = "Hub",
	},
	{
		name = "rewardsButton",
		label = "QUESTS SOON",
		action = "Menu.ComingSoon",
		comingSoon = true,
		enabledWhen = "Hub",
	},
}

UIControlRules.SoloControls = {
	{
		name = "WorkspaceSettingsButton",
		label = "SET",
		action = "Menu.Settings",
	},
	{
		name = "WorkspaceHelpButton",
		label = "?",
		action = "Tutorial.Show",
	},
	{
		name = "WorkspaceCloseButton",
		label = "X",
		action = "Queue.LeaveBattle",
	},
	{
		name = "ReturnHubButton",
		label = "Return Hub",
		action = "Queue.LeaveBattle",
	},
	{
		name = "PlayAgainButton",
		label = "Play Again",
		action = "Queue.PlayAgain",
	},
	{
		name = "WorkspaceResizeHandle",
		label = "Resize",
		hidden = true,
		action = "HiddenObsolete",
	},
}

function UIControlRules.controlHasAction(control)
	if typeof(control) ~= "table" then
		return false
	end

	return typeof(control.action) == "string"
		or control.comingSoon == true
		or control.hidden == true
end

function UIControlRules.disabledModeControlsAreHidden(experienceConfig)
	experienceConfig = experienceConfig or {}
	local modes = experienceConfig.Modes or {}
	return modes.Battle ~= true and modes.Story ~= true and modes.CustomLab ~= true
end

function UIControlRules.onlyOneMajorPanelOpen(panelStates)
	local count = 0
	for _, isOpen in panelStates or {} do
		if isOpen == true then
			count += 1
		end
	end

	return count <= 1
end

function UIControlRules.canFireServerAction(lastRequestAt, now, cooldownSeconds)
	cooldownSeconds = cooldownSeconds or UIControlRules.ServerActionCooldownSeconds
	if typeof(lastRequestAt) ~= "number" or typeof(now) ~= "number" then
		return false
	end

	return now - lastRequestAt >= cooldownSeconds
end

function UIControlRules.boardGridChildrenAreValid(childClassNames)
	local buttonCount = 0

	for _, className in childClassNames or {} do
		if className == "TextButton" then
			buttonCount += 1
		elseif className ~= "UIPadding" and className ~= "UIGridLayout" then
			return false, buttonCount
		end
	end

	return buttonCount == Config.BoardSize * Config.BoardSize, buttonCount
end

return UIControlRules
