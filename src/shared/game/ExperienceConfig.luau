local ExperienceConfig = {}

ExperienceConfig.Modes = {
	Solo = true,
	Battle = false,
	Story = false,
	CustomLab = false,
}

ExperienceConfig.World = {
	BuildBattleRoutes = false,
	BuildStoryRoutes = false,
	BuildBattleArenas = false,
}

ExperienceConfig.UI = {
	ShowModesButton = false,
	ShowStoryStars = false,
	ShowWins = false,
}

ExperienceConfig.Solo = {
	PrimaryRemoteMode = "Solo",
	HubPromptEnabled = true,
	WelcomeMessage = "Press Play to start a solo puzzle run",
}

local MODE_ALIASES = {
	Custom = "CustomLab",
}

function ExperienceConfig.isModeEnabled(mode)
	local key = MODE_ALIASES[mode] or mode
	return ExperienceConfig.Modes[key] == true
end

function ExperienceConfig.isBattleVisible()
	return ExperienceConfig.World.BuildBattleRoutes == true
		or ExperienceConfig.World.BuildBattleArenas == true
		or ExperienceConfig.Modes.Battle == true
end

function ExperienceConfig.isStoryVisible()
	return ExperienceConfig.World.BuildStoryRoutes == true or ExperienceConfig.Modes.Story == true
end

return ExperienceConfig
