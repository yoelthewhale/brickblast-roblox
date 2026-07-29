local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameShared = Shared:WaitForChild("game")
local Blocks = require(GameShared.Blocks)
local Config = require(GameShared.Config)
local Grid = require(GameShared.Grid)
local HubBuilder = require(script.Parent.Parent.world.HubBuilder)

local remotes = Instance.new("Folder")
remotes.Name = "BlockBlastRemotes"
remotes.Parent = ReplicatedStorage

local stateEvent = Instance.new("RemoteEvent")
stateEvent.Name = "State"
stateEvent.Parent = remotes

local placeEvent = Instance.new("RemoteEvent")
placeEvent.Name = "Place"
placeEvent.Parent = remotes

local queueEvent = Instance.new("RemoteEvent")
queueEvent.Name = "Queue"
queueEvent.Parent = remotes

local hubEvent = Instance.new("RemoteEvent")
hubEvent.Name = "Hub"
hubEvent.Parent = remotes

local effectsEvent = Instance.new("RemoteEvent")
effectsEvent.Name = "Effects"
effectsEvent.Parent = remotes

local settingsEvent = Instance.new("RemoteEvent")
settingsEvent.Name = "Settings"
settingsEvent.Parent = remotes

local hubParts = HubBuilder.build()
local playerStates = {}
local playerSessions = {}
local activeSessions = {}
local queuedPlayers = {}
local playerModes = {}
local playerSettings = {}
local selectedStoryChapters = {}
local lastPlaceRequestAt = {}
local lastQueueRequestAt = {}
local settingsSaveScheduled = {}
local queueStartedAt = nil
local nextSessionId = 0
local profileStore = nil
local profileLoadFailures = 0
local profileSaveFailures = 0
local analytics = {
	battleSessionsStarted = 0,
	storySessionsStarted = 0,
	battleSessionsFinished = 0,
	storyMissionsCompleted = 0,
	queueJoins = 0,
	queueLeaves = 0,
	placements = 0,
	linesCleared = 0,
	invalidPlacements = 0,
	rejectedPlaceRequests = 0,
	throttledPlaceRequests = 0,
	suddenDeathPressureRows = 0,
	profileFieldsSanitized = 0,
	forfeits = 0,
}

pcall(function()
	profileStore = DataStoreService:GetDataStore("BlockBlastProfilesV1")
end)

local BATTLE_MIN_PLAYERS = 2
local SOLO_TEST_SECONDS = 8
local OUT_OF_MOVES_RETURN_SECONDS = 4
local POST_BATTLE_RETURN_SECONDS = 6
local PLACE_COOLDOWN_SECONDS = 0.08
local QUEUE_ACTION_COOLDOWN_SECONDS = 0.35
local SETTINGS_SAVE_DEBOUNCE_SECONDS = 1
local PROFILE_SAVE_RETRY_COUNT = 3
local PROFILE_LIMITS = {
	bestScore = 1000000000,
	wins = 1000000,
	coins = 100000000,
	xp = 100000000,
	level = 1000,
	storyStars = 100000,
}
local leaveBattle = nil
local scheduleReturnIfEliminated = nil
local resolveBattleIfFinished = nil
local startStoryMode = nil

local DEFAULT_SETTINGS = {
	themeIndex = 1,
	reducedMotion = false,
	uiScale = 1,
	tutorialComplete = false,
	pieceSkin = "Rainbow",
	boardSkin = "Auto",
	soundEnabled = true,
	soundVolume = 0.65,
}

local function cosmeticProgress(player)
	local leaderstats = player and player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local level = leaderstats and leaderstats:FindFirstChild("Level")
	local storyStars = leaderstats and leaderstats:FindFirstChild("StoryStars")

	return {
		coins = coins and coins.Value or 0,
		level = level and level.Value or 1,
		storyStars = storyStars and storyStars.Value or 0,
	}
end

local function nextCosmeticUnlockText(progress)
	for _, skinName in Blocks.PieceSkins do
		local requirement = Config.PieceSkinUnlocks[skinName]
		if not Config.meetsCosmeticRequirement(requirement, progress) then
			return `Next pieces: {skinName} at {requirement and requirement.label or "keep playing"}`
		end
	end

	for _, skin in Config.BoardSkins do
		local requirement = Config.BoardSkinUnlocks[skin.name]
		if not Config.meetsCosmeticRequirement(requirement, progress) then
			return `Next board: {skin.name} at {requirement and requirement.label or "keep playing"}`
		end
	end

	return "All current cosmetics unlocked"
end

local function sanitizeSettings(settings, progress)
	local clean = table.clone(DEFAULT_SETTINGS)
	if typeof(settings) ~= "table" then
		return clean
	end

	if typeof(settings.themeIndex) == "number" then
		clean.themeIndex = math.clamp(math.floor(settings.themeIndex), 1, 3)
	end

	if typeof(settings.reducedMotion) == "boolean" then
		clean.reducedMotion = settings.reducedMotion
	end

	if typeof(settings.uiScale) == "number" then
		clean.uiScale = math.clamp(settings.uiScale, 0.92, 1.12)
	end

	if typeof(settings.tutorialComplete) == "boolean" then
		clean.tutorialComplete = settings.tutorialComplete
	end

	if
		typeof(settings.pieceSkin) == "string"
		and Blocks.isValidPieceSkin(settings.pieceSkin)
		and Config.meetsCosmeticRequirement(Config.PieceSkinUnlocks[settings.pieceSkin], progress)
	then
		clean.pieceSkin = settings.pieceSkin
	end

	if
		typeof(settings.boardSkin) == "string"
		and Config.isValidBoardSkin(settings.boardSkin)
		and Config.meetsCosmeticRequirement(Config.BoardSkinUnlocks[settings.boardSkin], progress)
	then
		clean.boardSkin = settings.boardSkin
	end

	if typeof(settings.soundEnabled) == "boolean" then
		clean.soundEnabled = settings.soundEnabled
	end

	if typeof(settings.soundVolume) == "number" then
		clean.soundVolume = math.clamp(settings.soundVolume, 0, 1)
	end

	return clean
end

local function sendSettings(player)
	settingsEvent:FireClient(
		player,
		sanitizeSettings(playerSettings[player], cosmeticProgress(player))
	)
end

local function findFreeArena()
	local arenas = hubParts.arenas or {}
	if #arenas == 0 then
		return nil
	end

	local usedArenaIndexes = {}
	for _, session in activeSessions do
		if session.arena then
			usedArenaIndexes[session.arena.index] = true
		end
	end

	for _, arena in arenas do
		if not usedArenaIndexes[arena.index] then
			return arena
		end
	end

	return nil
end

local function activeSessionCount()
	local count = 0
	for _ in activeSessions do
		count += 1
	end

	return count
end

local function arenaCounts()
	local totalArenas = #(hubParts.arenas or {})
	local activeCount = activeSessionCount()

	return totalArenas, math.max(0, totalArenas - activeCount)
end

local function sessionSecondsLeft(session)
	return session and session.endsAt and math.max(0, session.endsAt - os.clock()) or 0
end

local function isSuddenDeathActive(session)
	return session
		and session.mode == "Battle"
		and sessionSecondsLeft(session) <= Config.SuddenDeathStartsAt
end

local function sessionSummaries()
	local summaries = {}

	for _, session in activeSessions do
		table.insert(summaries, {
			id = session.id,
			mode = session.mode,
			arenaIndex = session.arena and session.arena.index or nil,
			playerCount = #session.players,
			startedWith = session.startedWith,
			timeLeft = math.ceil(sessionSecondsLeft(session)),
			suddenDeath = isSuddenDeathActive(session),
			finishScheduled = session.finishScheduled,
		})
	end

	table.sort(summaries, function(a, b)
		return a.id < b.id
	end)

	return summaries
end

local function sanitizeProfileInteger(value, minimum, maximum, fallback)
	if typeof(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return fallback, value ~= nil
	end

	local clean = math.clamp(math.floor(value), minimum, maximum)
	return clean, clean ~= value
end

local function applyLoadedProfileStat(profile, stat, key, minimum, maximum, fallback)
	local clean, sanitized = sanitizeProfileInteger(profile[key], minimum, maximum, fallback)
	stat.Value = clean
	return sanitized and 1 or 0
end

local function sanitizedStatValue(stat, minimum, maximum, fallback)
	local clean, sanitized = sanitizeProfileInteger(stat and stat.Value, minimum, maximum, fallback)
	if sanitized and stat then
		stat.Value = clean
	end

	if sanitized then
		analytics.profileFieldsSanitized += 1
	end

	return clean
end

local function createLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local battleScore = Instance.new("IntValue")
	battleScore.Name = "BattleScore"
	battleScore.Value = 0
	battleScore.Parent = leaderstats

	local bestScore = Instance.new("IntValue")
	bestScore.Name = "BestScore"
	bestScore.Value = 0
	bestScore.Parent = leaderstats

	local wins = Instance.new("IntValue")
	wins.Name = "Wins"
	wins.Value = 0
	wins.Parent = leaderstats

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 0
	coins.Parent = leaderstats

	local xp = Instance.new("IntValue")
	xp.Name = "XP"
	xp.Value = 0
	xp.Parent = leaderstats

	local level = Instance.new("IntValue")
	level.Name = "Level"
	level.Value = 1
	level.Parent = leaderstats

	local storyStars = Instance.new("IntValue")
	storyStars.Name = "StoryStars"
	storyStars.Value = 0
	storyStars.Parent = leaderstats

	task.spawn(function()
		if not profileStore then
			return
		end

		local ok, profile = pcall(function()
			return profileStore:GetAsync(`Player_{player.UserId}`)
		end)

		if not ok then
			profileLoadFailures += 1
			warn(`[BlockBlast] Failed to load profile for {player.UserId}: {tostring(profile)}`)
			return
		end

		if typeof(profile) ~= "table" or player.Parent ~= Players then
			return
		end

		local sanitizedFields = 0
		sanitizedFields += applyLoadedProfileStat(
			profile,
			bestScore,
			"bestScore",
			0,
			PROFILE_LIMITS.bestScore,
			0
		)
		sanitizedFields += applyLoadedProfileStat(profile, wins, "wins", 0, PROFILE_LIMITS.wins, 0)
		sanitizedFields += applyLoadedProfileStat(
			profile,
			coins,
			"coins",
			0,
			PROFILE_LIMITS.coins,
			0
		)
		sanitizedFields += applyLoadedProfileStat(profile, xp, "xp", 0, PROFILE_LIMITS.xp, 0)
		sanitizedFields += applyLoadedProfileStat(
			profile,
			level,
			"level",
			1,
			PROFILE_LIMITS.level,
			1
		)
		sanitizedFields += applyLoadedProfileStat(
			profile,
			storyStars,
			"storyStars",
			0,
			PROFILE_LIMITS.storyStars,
			0
		)
		analytics.profileFieldsSanitized += sanitizedFields

		playerSettings[player] = sanitizeSettings(profile.settings, cosmeticProgress(player))
		sendSettings(player)
	end)
end

local function updateLeaderstats(player, score)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local battleScore = leaderstats:FindFirstChild("BattleScore")
	local bestScore = leaderstats:FindFirstChild("BestScore")

	if battleScore then
		battleScore.Value = score
	end

	if bestScore and score > bestScore.Value then
		bestScore.Value = score
	end
end

local function setProfileWithRetry(player, payload)
	for attempt = 1, PROFILE_SAVE_RETRY_COUNT do
		local ok, err = pcall(function()
			profileStore:SetAsync(`Player_{player.UserId}`, payload)
		end)

		if ok then
			return true
		end

		if attempt == PROFILE_SAVE_RETRY_COUNT then
			profileSaveFailures += 1
			warn(`[BlockBlast] Failed to save profile for {player.UserId}: {tostring(err)}`)
			return false
		end

		task.wait(0.35 * attempt)
	end

	return false
end

local function saveProfile(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local bestScore = leaderstats and leaderstats:FindFirstChild("BestScore")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local xp = leaderstats and leaderstats:FindFirstChild("XP")
	local level = leaderstats and leaderstats:FindFirstChild("Level")
	local storyStars = leaderstats and leaderstats:FindFirstChild("StoryStars")
	if
		not bestScore
		or not wins
		or not coins
		or not xp
		or not level
		or not storyStars
		or not profileStore
	then
		return
	end

	setProfileWithRetry(player, {
		version = 1,
		bestScore = sanitizedStatValue(bestScore, 0, PROFILE_LIMITS.bestScore, 0),
		wins = sanitizedStatValue(wins, 0, PROFILE_LIMITS.wins, 0),
		coins = sanitizedStatValue(coins, 0, PROFILE_LIMITS.coins, 0),
		xp = sanitizedStatValue(xp, 0, PROFILE_LIMITS.xp, 0),
		level = sanitizedStatValue(level, 1, PROFILE_LIMITS.level, 1),
		storyStars = sanitizedStatValue(storyStars, 0, PROFILE_LIMITS.storyStars, 0),
		settings = sanitizeSettings(playerSettings[player], cosmeticProgress(player)),
		updatedAt = os.time(),
	})
end

local function levelFromXp(xp)
	return math.max(1, math.floor(math.sqrt(xp / Config.LevelXpBase)) + 1)
end

local function completedStoryChapters(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local storyStars = leaderstats and leaderstats:FindFirstChild("StoryStars")
	return storyStars and storyStars.Value or 0
end

local function storyMissionForChapter(chapter)
	local missionCount = #Config.StoryMissions
	if missionCount == 0 then
		return nil
	end

	local mission = table.clone(Config.StoryMissions[((chapter - 1) % missionCount) + 1])
	mission.chapter = chapter
	return mission
end

local function validatedStoryChapter(player, requestedChapter)
	local completed = completedStoryChapters(player)
	local maxUnlockedChapter = completed + 1
	if typeof(requestedChapter) ~= "number" or requestedChapter ~= math.floor(requestedChapter) then
		return maxUnlockedChapter
	end

	return math.clamp(requestedChapter, 1, maxUnlockedChapter)
end

local function storyMissionForPlayer(player, requestedChapter)
	return storyMissionForChapter(validatedStoryChapter(player, requestedChapter))
end

local function storyMissionListForPlayer(player)
	local completed = completedStoryChapters(player)
	local firstChapter = math.max(1, completed - 1)
	local lastChapter = completed + 2
	local missions = {}

	for chapter = firstChapter, lastChapter do
		local mission = storyMissionForChapter(chapter)
		if mission then
			mission.unlocked = chapter <= completed + 1
			mission.completed = chapter <= completed
			mission.next = chapter == completed + 1
			table.insert(missions, mission)
		end
	end

	return missions
end

local function isStoryMissionComplete(state)
	local mission = state.storyMission
	if not mission then
		return false
	end

	return state.score >= (mission.targetScore or 0)
		and state.linesCleared >= (mission.targetLines or 0)
end

local function storyChapterTitle(mission)
	if not mission then
		return "Story Training"
	end

	return `Chapter {mission.chapter or 1}: {mission.name or "Training"}`
end

local function storyFlavorText(mission, completed)
	if not mission then
		return nil
	end

	if completed then
		return mission.success or "Mission complete."
	end

	return mission.failure or "Mission incomplete. Try the objective again."
end

local function grantBattleRewards(player, state, winner)
	if state.rewardsGranted then
		return
	end

	state.rewardsGranted = true
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local coins = leaderstats:FindFirstChild("Coins")
	local xp = leaderstats:FindFirstChild("XP")
	local level = leaderstats:FindFirstChild("Level")
	local wins = leaderstats:FindFirstChild("Wins")
	local storyStars = leaderstats:FindFirstChild("StoryStars")
	if not coins or not xp or not level or not wins or not storyStars then
		return
	end

	local hundredScore = math.floor(state.score / 100)
	local earnedCoins = math.max(5, hundredScore * Config.CoinsPerHundredScore)
	local earnedXp = math.max(10, hundredScore * Config.XpPerHundredScore)
	local storyObjectiveMet = state.mode == "Story" and isStoryMissionComplete(state)
	local storyProgressionCompleted = storyObjectiveMet
		and state.storyMission
		and state.storyMission.chapter == storyStars.Value + 1
	local oldBestScore = state.startingBestScore or state.bestScore or 0

	if winner and state.mode == "Battle" then
		earnedCoins += Config.WinnerBonusCoins
		earnedXp += Config.WinnerBonusXp
		wins.Value += 1
	elseif storyProgressionCompleted then
		earnedCoins += Config.StoryCompletionCoins
		earnedXp += Config.StoryCompletionXp
		storyStars.Value += 1
		selectedStoryChapters[player] = storyStars.Value + 1
		analytics.storyMissionsCompleted += 1
	end

	coins.Value += earnedCoins
	xp.Value += earnedXp
	level.Value = levelFromXp(xp.Value)
	local nextUnlockText = nextCosmeticUnlockText({
		coins = coins.Value,
		level = level.Value,
		storyStars = storyStars.Value,
	})
	state.resultSummary = {
		mode = state.mode,
		score = state.score,
		linesCleared = state.linesCleared,
		coins = earnedCoins,
		xp = earnedXp,
		storyStars = storyProgressionCompleted and 1 or 0,
		bestScore = state.bestScore,
		previousBestScore = oldBestScore,
		storyCompleted = storyObjectiveMet,
		won = winner == true and state.mode == "Battle",
		nextUnlockText = nextUnlockText,
	}
	if state.mode == "Story" then
		state.resultSummary.storyText = storyFlavorText(state.storyMission, storyObjectiveMet)
	end
	if winner and state.mode == "Battle" then
		state.message = `Victory! +{earnedCoins} coins +{earnedXp} XP`
		state.resultSummary.outcome = "Victory"
	elseif storyProgressionCompleted then
		state.message = `Mission complete! +{earnedCoins} coins +{earnedXp} XP`
		state.resultSummary.outcome = "Mission Complete"
	elseif storyObjectiveMet then
		state.message = `Replay complete! +{earnedCoins} coins +{earnedXp} XP`
		state.resultSummary.outcome = "Replay Complete"
	elseif state.mode == "Story" then
		state.message = `Mission incomplete - rewards: +{earnedCoins} coins +{earnedXp} XP`
		state.resultSummary.outcome = "Mission Incomplete"
	else
		state.message = `Rewards: +{earnedCoins} coins +{earnedXp} XP`
		state.resultSummary.outcome = "Run Complete"
	end
end

local function fireResult(player, state, won)
	state.resultShown = true
	effectsEvent:FireClient(player, {
		kind = "BattleResult",
		message = state.message,
		won = won == true,
		result = state.resultSummary,
	})
end

local function isWholeNumber(value)
	return typeof(value) == "number" and value == math.floor(value)
end

local function canAcceptPlaceRequest(player, slot, x, y)
	if
		not isWholeNumber(slot)
		or not isWholeNumber(x)
		or not isWholeNumber(y)
		or slot < 1
		or slot > Config.InventorySize
		or x < 1
		or x > Config.BoardSize
		or y < 1
		or y > Config.BoardSize
	then
		return false, "InvalidPayload"
	end

	local now = os.clock()
	local lastRequestAt = lastPlaceRequestAt[player] or 0
	if now - lastRequestAt < PLACE_COOLDOWN_SECONDS then
		return false, "Cooldown"
	end

	lastPlaceRequestAt[player] = now
	return true, nil
end

local function canAcceptQueueAction(player)
	local now = os.clock()
	local lastRequestAt = lastQueueRequestAt[player] or 0
	if now - lastRequestAt < QUEUE_ACTION_COOLDOWN_SECONDS then
		return false
	end

	lastQueueRequestAt[player] = now
	return true
end

local function scheduleSettingsSave(player)
	if settingsSaveScheduled[player] then
		return
	end

	settingsSaveScheduled[player] = true
	task.delay(SETTINGS_SAVE_DEBOUNCE_SECONDS, function()
		settingsSaveScheduled[player] = nil
		if player.Parent == Players then
			saveProfile(player)
		end
	end)
end

local function publicState(player)
	local state = playerStates[player]
	if not state then
		return nil
	end
	local session = playerSessions[player]

	return {
		board = state.board,
		hand = state.hand,
		score = state.score,
		bestScore = state.bestScore,
		alive = state.alive,
		message = state.message,
		linesCleared = state.linesCleared,
		mode = state.mode,
		storyMission = state.storyMission,
		storyComplete = state.mode == "Story" and isStoryMissionComplete(state) or false,
		resultSummary = state.resultSummary,
		sessionId = session and session.id or nil,
		arenaIndex = session and session.arena and session.arena.index or nil,
		timeLeft = session and math.ceil(sessionSecondsLeft(session)) or nil,
		suddenDeath = isSuddenDeathActive(session),
	}
end

local function queueCount()
	local count = 0

	for _ in queuedPlayers do
		count += 1
	end

	return count
end

local function sendHubState(player, message)
	local secondsToSoloStart = nil
	if queueStartedAt and queuedPlayers[player] then
		secondsToSoloStart =
			math.max(0, math.ceil(SOLO_TEST_SECONDS - (os.clock() - queueStartedAt)))
	end
	local totalArenas, openArenas = arenaCounts()
	local selectedChapter = selectedStoryChapters[player]
	local storyMission = storyMissionForPlayer(player, selectedChapter)
	local progress = cosmeticProgress(player)

	hubEvent:FireClient(player, {
		mode = playerModes[player] or "Hub",
		queued = queuedPlayers[player] == true,
		queueCount = queueCount(),
		minPlayers = BATTLE_MIN_PLAYERS,
		activeSessions = activeSessionCount(),
		openArenas = openArenas,
		totalArenas = totalArenas,
		sessions = sessionSummaries(),
		storyMission = storyMission,
		storyMissions = storyMissionListForPlayer(player),
		storyStars = progress.storyStars,
		profileLoadFailures = profileLoadFailures,
		profileSaveFailures = profileSaveFailures,
		analytics = table.clone(analytics),
		secondsToSoloStart = secondsToSoloStart,
		message = message,
	})
end

local function broadcastHub(message, exceptPlayer)
	for _, player in Players:GetPlayers() do
		if player ~= exceptPlayer then
			sendHubState(player, message)
		end
	end
end

local function broadcast(session)
	if not session then
		for _, activeSession in activeSessions do
			broadcast(activeSession)
		end
		return
	end

	local leaderboard = {}

	for _, player in session.players do
		local state = playerStates[player]
		if not state then
			continue
		end

		table.insert(leaderboard, {
			userId = player.UserId,
			name = player.DisplayName,
			score = state.score,
			bestScore = state.bestScore,
			alive = state.alive,
			message = state.message,
		})
	end

	table.sort(leaderboard, function(a, b)
		return a.score > b.score
	end)

	for _, player in session.players do
		if player.Parent == Players and playerStates[player] then
			stateEvent:FireClient(player, publicState(player), leaderboard)
		end
	end
end

local function giveNewHand(state)
	state.hand = Blocks.createHand(state.randomizer, Config.InventorySize, state.pieceSkin)
end

local function teleportTo(part, player)
	local character = player.Character
	if character and character.PrimaryPart then
		character:PivotTo(part.CFrame + Vector3.new(0, 5, 0))
	end
end

local function teleportToArenaSlot(player, slot, session)
	local arenaSpawns = session and session.arena and session.arena.spawns
		or hubParts.arenaSpawns
		or {}
	local spawnPart = arenaSpawns[((slot - 1) % math.max(1, #arenaSpawns)) + 1]
		or hubParts.battleSpawn
	teleportTo(spawnPart, player)
end

local function pressureOpponents(attacker, linesCleared, session)
	if linesCleared <= 0 then
		return
	end

	local garbageAmount = linesCleared * Config.GarbagePerLineCleared

	for _, player in session.players do
		local state = playerStates[player]
		if player ~= attacker and state and state.alive then
			Grid.addGarbage(state.board, garbageAmount)
			state.alive = Grid.hasAnyMove(state.board, state.hand)
			if scheduleReturnIfEliminated then
				scheduleReturnIfEliminated(player, state)
			end
		end
	end
end

local function applySuddenDeathPressure(session)
	if
		not session
		or session.mode ~= "Battle"
		or session.finishScheduled
		or sessionSecondsLeft(session) > Config.SuddenDeathStartsAt
	then
		return
	end

	local now = os.clock()
	if not session.suddenDeathAnnounced then
		session.suddenDeathAnnounced = true
		session.nextSuddenDeathPressureAt = now
		for _, player in session.players do
			if player.Parent == Players then
				effectsEvent:FireClient(player, {
					kind = "SuddenDeath",
					message = "Sudden death!",
					detail = "Pressure rows are rising. Clear space fast.",
				})
			end
		end
	end

	if session.nextSuddenDeathPressureAt and now < session.nextSuddenDeathPressureAt then
		return
	end
	session.nextSuddenDeathPressureAt = now + Config.SuddenDeathPressureInterval

	local rowsAdded = 0
	for _, player in session.players do
		local state = playerStates[player]
		if state and state.alive then
			Grid.addGarbage(state.board, Config.SuddenDeathGarbageRows)
			rowsAdded += Config.SuddenDeathGarbageRows
			state.message = "Sudden death pressure"
			state.alive = Grid.hasAnyMove(state.board, state.hand)
			if not state.alive then
				state.message = "Sudden death locked your board"
			end
			if player.Parent == Players then
				effectsEvent:FireClient(player, {
					kind = "SuddenDeathPressure",
					message = "Pressure row rising",
				})
			end
			if scheduleReturnIfEliminated then
				scheduleReturnIfEliminated(player, state)
			end
		end
	end

	analytics.suddenDeathPressureRows += rowsAdded
	if resolveBattleIfFinished then
		resolveBattleIfFinished(session)
	end
end

local function createPlayerState(player, mode, storyChapter)
	local randomizer = Random.new(os.clock() * 100000 + player.UserId)
	local state = {
		board = Grid.create(),
		hand = {},
		randomizer = randomizer,
		mode = mode,
		pieceSkin = (playerSettings[player] or DEFAULT_SETTINGS).pieceSkin,
		score = 0,
		bestScore = player:FindFirstChild("leaderstats") and player.leaderstats.BestScore.Value
			or 0,
		startingBestScore = player:FindFirstChild("leaderstats")
				and player.leaderstats.BestScore.Value
			or 0,
		linesCleared = 0,
		rewardsGranted = false,
		storyMission = mode == "Story" and storyMissionForPlayer(player, storyChapter) or nil,
		alive = true,
		message = nil,
	}

	giveNewHand(state)
	playerStates[player] = state
	updateLeaderstats(player, 0)
end

local function startBattle(players, mode, storyChapter)
	mode = mode or "Battle"
	local arena = findFreeArena()
	if not arena then
		return nil
	end

	nextSessionId += 1
	local session = {
		id = nextSessionId,
		mode = mode,
		players = {},
		startedWith = #players,
		finishScheduled = false,
		endsAt = os.clock() + (mode == "Story" and Config.StoryRoundSeconds or Config.RoundSeconds),
		suddenDeathAnnounced = false,
		nextSuddenDeathPressureAt = nil,
		arena = arena,
	}
	activeSessions[session.id] = session
	if mode == "Story" then
		analytics.storySessionsStarted += 1
	else
		analytics.battleSessionsStarted += 1
	end

	for slot, player in players do
		queuedPlayers[player] = nil
		playerModes[player] = mode
		playerSessions[player] = session
		table.insert(session.players, player)
		createPlayerState(player, mode, storyChapter)
		local state = playerStates[player]
		local storyMission = state and state.storyMission
		teleportToArenaSlot(player, slot, session)
		effectsEvent:FireClient(player, {
			kind = "BattleStart",
			message = mode == "Story" and storyChapterTitle(storyMission)
				or #players >= BATTLE_MIN_PLAYERS and "Battle started!"
				or "Solo test started!",
			detail = mode == "Story" and storyMission and storyMission.intro or nil,
		})
	end

	if queueCount() == 0 then
		queueStartedAt = nil
	else
		queueStartedAt = os.clock()
	end

	broadcastHub(mode == "Story" and "Story training started" or "Battle started")
	broadcast(session)
	return session
end

local function getHighestScoringAlivePlayer(session)
	local winner = nil
	local bestScore = -1

	for _, player in session.players do
		local state = playerStates[player]
		if state and state.alive and state.score > bestScore then
			winner = player
			bestScore = state.score
		end
	end

	return winner
end

local function tryStartBattle()
	if not findFreeArena() then
		if queueCount() > 0 then
			broadcastHub("All arenas are busy")
		end
		return
	end

	local players = {}
	for player in queuedPlayers do
		if player.Parent == Players then
			table.insert(players, player)
		end
	end

	while #players >= BATTLE_MIN_PLAYERS and findFreeArena() do
		local matchPlayers = {}
		for _ = 1, BATTLE_MIN_PLAYERS do
			table.insert(matchPlayers, table.remove(players, 1))
		end
		startBattle(matchPlayers, "Battle")
	end

	if #players >= BATTLE_MIN_PLAYERS then
		return
	end

	if #players == 1 and queueStartedAt and os.clock() - queueStartedAt >= SOLO_TEST_SECONDS then
		startBattle({ players[1] }, "Battle")
	end
end

local function joinBattleQueue(player)
	if playerModes[player] == "Battle" or playerModes[player] == "Story" then
		sendHubState(player, "Finish your current run first")
		return
	end

	if queuedPlayers[player] then
		sendHubState(player, "Already queued")
		return
	end

	if not findFreeArena() then
		sendHubState(player, "All arenas are busy")
		return
	end

	queuedPlayers[player] = true
	analytics.queueJoins += 1
	queueStartedAt = queueStartedAt or os.clock()
	broadcastHub(`{player.DisplayName} joined the battle queue`)
	tryStartBattle()
end

local function leaveBattleQueue(player)
	if not queuedPlayers[player] then
		sendHubState(player, "You are not queued")
		return
	end

	queuedPlayers[player] = nil
	analytics.queueLeaves += 1
	if queueCount() == 0 then
		queueStartedAt = nil
	end

	broadcastHub(`{player.DisplayName} left the battle queue`)
end

startStoryMode = function(player, requestedChapter)
	if playerModes[player] == "Battle" or playerModes[player] == "Story" then
		sendHubState(player, "Finish your current run first")
		return
	end

	if not findFreeArena() then
		sendHubState(player, "Arena is busy - try story again after this match")
		return
	end

	local chapter = validatedStoryChapter(player, requestedChapter)
	selectedStoryChapters[player] = chapter
	startBattle({ player }, "Story", chapter)
end

local function playAgainBattle(player)
	local state = playerStates[player]
	local session = playerSessions[player]

	if state and state.alive and not (session and session.finishScheduled) then
		sendHubState(player, "Finish your current run first")
		return
	end

	if state or session then
		leaveBattle(player)
	end

	joinBattleQueue(player)
end

local function finishBattle(session, winner)
	if session.finishScheduled then
		return
	end

	session.finishScheduled = true
	if session.mode == "Battle" then
		analytics.battleSessionsFinished += 1
	end

	for _, player in session.players do
		local state = playerStates[player]
		if not state then
			continue
		end

		grantBattleRewards(player, state, player == winner)
		saveProfile(player)
		state.alive = false
		fireResult(player, state, player == winner)
	end

	broadcastHub(winner and `{winner.DisplayName} won the battle` or "Battle complete")
	broadcast(session)

	task.delay(POST_BATTLE_RETURN_SECONDS, function()
		local playersToReturn = {}
		for _, player in session.players do
			table.insert(playersToReturn, player)
		end

		for _, player in playersToReturn do
			if player.Parent == Players and playerStates[player] then
				leaveBattle(player)
			end
		end
	end)
end

resolveBattleIfFinished = function(session)
	if session.finishScheduled or session.startedWith < BATTLE_MIN_PLAYERS then
		return
	end

	local alivePlayers = {}
	for _, player in session.players do
		local state = playerStates[player]
		if state and state.alive then
			table.insert(alivePlayers, player)
		end
	end

	if #alivePlayers <= 1 then
		finishBattle(session, alivePlayers[1])
	end
end

leaveBattle = function(player)
	local state = playerStates[player]
	local session = playerSessions[player]
	local returnMessage = "Returned to hub"
	if state then
		if not state.alive or (session and session.finishScheduled) then
			grantBattleRewards(player, state, false)
			if not state.resultShown then
				fireResult(player, state, false)
			end
		else
			state.rewardsGranted = true
			state.message = "Run forfeited - no rewards"
			state.resultSummary = {
				mode = state.mode,
				outcome = "Forfeit",
				score = state.score,
				linesCleared = state.linesCleared,
				coins = 0,
				xp = 0,
				storyStars = 0,
				bestScore = state.bestScore,
				previousBestScore = state.startingBestScore or state.bestScore,
				storyCompleted = false,
				won = false,
				nextUnlockText = nextCosmeticUnlockText(cosmeticProgress(player)),
				storyText = state.mode == "Story"
						and "Training abandoned. Restart when you are ready."
					or nil,
			}
			analytics.forfeits += 1
			fireResult(player, state, false)
		end
		returnMessage = state.message or returnMessage
	end
	saveProfile(player)
	playerStates[player] = nil
	playerSessions[player] = nil
	queuedPlayers[player] = nil
	selectedStoryChapters[player] = nil
	playerModes[player] = "Hub"

	if session then
		for index, sessionPlayer in session.players do
			if sessionPlayer == player then
				table.remove(session.players, index)
				break
			end
		end
		if #session.players == 0 then
			activeSessions[session.id] = nil
		end
	end

	teleportTo(hubParts.spawn, player)
	stateEvent:FireClient(player, nil, {})
	sendHubState(player, returnMessage)
	broadcastHub("Returned to hub", player)
	if session and activeSessions[session.id] then
		broadcast(session)
	end
	if session and resolveBattleIfFinished then
		resolveBattleIfFinished(session)
	end
end

scheduleReturnIfEliminated = function(player, state)
	if state.alive or state.returnScheduled then
		return
	end

	local session = playerSessions[player]
	if session and session.startedWith >= BATTLE_MIN_PLAYERS then
		if resolveBattleIfFinished then
			resolveBattleIfFinished(session)
		end
		return
	end

	state.returnScheduled = true
	task.delay(OUT_OF_MOVES_RETURN_SECONDS, function()
		if playerStates[player] == state and not state.alive then
			leaveBattle(player)
		end
	end)
end

placeEvent.OnServerEvent:Connect(function(player, slot, x, y)
	local canPlaceRequest, rejectReason = canAcceptPlaceRequest(player, slot, x, y)
	if not canPlaceRequest then
		if rejectReason == "Cooldown" then
			analytics.throttledPlaceRequests += 1
		else
			analytics.rejectedPlaceRequests += 1
		end
		return
	end

	local state = playerStates[player]
	if not state or not state.alive then
		analytics.rejectedPlaceRequests += 1
		return
	end
	local session = playerSessions[player]
	if not session then
		analytics.rejectedPlaceRequests += 1
		return
	end

	local shape = state.hand[slot]
	if not shape then
		analytics.rejectedPlaceRequests += 1
		return
	end

	local placed, cellsPlaced = Grid.place(state.board, shape, x, y)
	if not placed then
		analytics.invalidPlacements += 1
		effectsEvent:FireClient(player, {
			kind = "InvalidPlace",
			message = "That spot is blocked",
		})
		return
	end

	state.hand[slot] = nil
	local linesCleared = Grid.clearLines(state.board)
	analytics.placements += 1
	analytics.linesCleared += linesCleared
	effectsEvent:FireClient(player, {
		kind = "Place",
		originX = x,
		originY = y,
		shape = shape,
		linesCleared = linesCleared,
	})
	state.score += cellsPlaced * Config.PointsPerCell + linesCleared * Config.PointsPerLine
	state.linesCleared += linesCleared
	if state.score > state.bestScore then
		state.bestScore = state.score
	end
	updateLeaderstats(player, state.score)

	local hasPieces = false
	for _, remaining in state.hand do
		if remaining ~= nil then
			hasPieces = true
			break
		end
	end

	if not hasPieces then
		giveNewHand(state)
	end

	pressureOpponents(player, linesCleared, session)
	state.alive = Grid.hasAnyMove(state.board, state.hand)
	scheduleReturnIfEliminated(player, state)
	broadcast(session)
	if resolveBattleIfFinished then
		resolveBattleIfFinished(session)
	end
end)

queueEvent.OnServerEvent:Connect(function(player, mode, requestedChapter)
	if not canAcceptQueueAction(player) then
		return
	end

	if mode == "Battle" then
		joinBattleQueue(player)
	elseif mode == "LeaveQueue" then
		leaveBattleQueue(player)
	elseif mode == "LeaveBattle" then
		leaveBattle(player)
	elseif mode == "PlayAgain" then
		playAgainBattle(player)
	elseif mode == "Story" then
		startStoryMode(player, requestedChapter)
	end
end)

settingsEvent.OnServerEvent:Connect(function(player, action, nextSettings)
	if action == "Request" then
		sendSettings(player)
		return
	end

	if action ~= "Update" then
		return
	end

	playerSettings[player] = sanitizeSettings(nextSettings, cosmeticProgress(player))
	sendSettings(player)
	scheduleSettingsSave(player)
end)

hubParts.battlePrompt.Triggered:Connect(joinBattleQueue)

hubParts.storyPrompt.Triggered:Connect(function(player)
	startStoryMode(player)
end)

for _, arena in (hubParts.arenas or {}) do
	local returnPrompt = Instance.new("ProximityPrompt")
	returnPrompt.ActionText = "Return"
	returnPrompt.ObjectText = "Hub"
	returnPrompt.HoldDuration = 0.2
	returnPrompt.MaxActivationDistance = 12
	returnPrompt.RequiresLineOfSight = false
	returnPrompt.Parent = arena.returnPad
	returnPrompt.Triggered:Connect(leaveBattle)
end

Players.PlayerAdded:Connect(function(player)
	playerSettings[player] = table.clone(DEFAULT_SETTINGS)
	createLeaderstats(player)
	playerModes[player] = "Hub"
	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		if playerModes[player] ~= "Battle" and playerModes[player] ~= "Story" then
			teleportTo(hubParts.spawn, player)
		end
	end)
	stateEvent:FireClient(player, nil, {})
	sendHubState(player, "Welcome to the hub")
	sendSettings(player)
end)

Players.PlayerRemoving:Connect(function(player)
	saveProfile(player)
	local session = playerSessions[player]
	playerStates[player] = nil
	playerSessions[player] = nil
	queuedPlayers[player] = nil
	selectedStoryChapters[player] = nil
	playerModes[player] = nil
	playerSettings[player] = nil
	lastPlaceRequestAt[player] = nil
	lastQueueRequestAt[player] = nil
	settingsSaveScheduled[player] = nil
	if session then
		for index, sessionPlayer in session.players do
			if sessionPlayer == player then
				table.remove(session.players, index)
				break
			end
		end
		if #session.players == 0 then
			activeSessions[session.id] = nil
		elseif resolveBattleIfFinished then
			resolveBattleIfFinished(session)
		end
	end
	broadcastHub()
end)

game:BindToClose(function()
	for _, player in Players:GetPlayers() do
		saveProfile(player)
	end
end)

for _, player in Players:GetPlayers() do
	if not player:FindFirstChild("leaderstats") then
		playerSettings[player] = playerSettings[player] or table.clone(DEFAULT_SETTINGS)
		createLeaderstats(player)
	end
	playerModes[player] = playerModes[player] or "Hub"
	stateEvent:FireClient(player, nil, {})
	sendHubState(player, "Welcome to the hub")
	sendSettings(player)
end

task.spawn(function()
	while true do
		task.wait(1)
		tryStartBattle()
		for _, session in activeSessions do
			if session.endsAt and os.clock() >= session.endsAt then
				finishBattle(session, getHighestScoringAlivePlayer(session))
			else
				applySuddenDeathPressure(session)
				if not session.finishScheduled then
					broadcast(session)
				end
			end
		end
		if queueCount() > 0 then
			broadcastHub("Waiting for players")
		end
	end
end)
