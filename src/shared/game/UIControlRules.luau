local Config = require(script.Parent.Config)

local UIControlRules = {}

UIControlRules.ServerActionCooldownSeconds = 0.45

-- How long a panel waits for a server reply before giving up and showing an
-- actionable state. Several panels show a "loading"/"checking" placeholder
-- while a remote is in flight; without a deadline, a dropped reply or a
-- server-side error with no response leaves them there forever.
UIControlRules.PanelResponseTimeoutSeconds = 6

local function cleanNumber(value, fallback)
	if typeof(value) ~= "number" or value ~= value then
		return fallback
	end

	return value
end

-- Turn a raw achievements payload into entries that are safe to sort and draw.
--
-- The panel destroys its "Loading" label before rendering, so anything that
-- errors partway through -- a missing threshold making the sort comparator
-- throw, a nil progress reaching math.min -- used to leave a silently blank
-- panel with nothing to tell the player. Entries that cannot be repaired are
-- dropped rather than rendered half-formed.
function UIControlRules.sanitizeAchievementsPayload(list)
	local entries = {}

	if typeof(list) ~= "table" then
		return entries
	end

	for _, entry in list do
		if
			typeof(entry) == "table"
			and typeof(entry.stat) == "string"
			and typeof(entry.name) == "string"
			and cleanNumber(entry.threshold, nil) ~= nil
		then
			table.insert(entries, {
				id = entry.id,
				stat = entry.stat,
				name = entry.name,
				tier = typeof(entry.tier) == "string" and entry.tier or "Bronze",
				threshold = entry.threshold,
				progress = math.max(0, cleanNumber(entry.progress, 0)),
				rewardCoins = math.max(0, cleanNumber(entry.rewardCoins, 0)),
				unlocked = entry.unlocked == true,
			})
		end
	end

	table.sort(entries, function(left, right)
		if left.unlocked ~= right.unlocked then
			return left.unlocked
		end
		if left.stat ~= right.stat then
			return left.stat < right.stat
		end
		return left.threshold < right.threshold
	end)

	return entries
end

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
