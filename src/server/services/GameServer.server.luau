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
local lastPlaceRequestAt = {}
local queueStartedAt = nil
local nextSessionId = 0
local profileStore = nil

pcall(function()
	profileStore = DataStoreService:GetDataStore("BlockBlastProfilesV1")
end)

local BATTLE_MIN_PLAYERS = 2
local SOLO_TEST_SECONDS = 8
local OUT_OF_MOVES_RETURN_SECONDS = 4
local POST_BATTLE_RETURN_SECONDS = 6
local PLACE_COOLDOWN_SECONDS = 0.08
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

local function sanitizeSettings(settings)
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

	if typeof(settings.pieceSkin) == "string" and Blocks.isValidPieceSkin(settings.pieceSkin) then
		clean.pieceSkin = settings.pieceSkin
	end

	if typeof(settings.boardSkin) == "string" and Config.isValidBoardSkin(settings.boardSkin) then
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
	settingsEvent:FireClient(player, playerSettings[player] or DEFAULT_SETTINGS)
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

local function sessionSummaries()
	local summaries = {}

	for _, session in activeSessions do
		table.insert(summaries, {
			id = session.id,
			mode = session.mode,
			arenaIndex = session.arena and session.arena.index or nil,
			playerCount = #session.players,
			startedWith = session.startedWith,
			timeLeft = math.max(0, math.ceil(session.endsAt - os.clock())),
			finishScheduled = session.finishScheduled,
		})
	end

	table.sort(summaries, function(a, b)
		return a.id < b.id
	end)

	return summaries
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

	task.spawn(function()
		if not profileStore then
			return
		end

		local ok, profile = pcall(function()
			return profileStore:GetAsync(`Player_{player.UserId}`)
		end)

		if not ok or typeof(profile) ~= "table" or player.Parent ~= Players then
			return
		end

		if typeof(profile.bestScore) == "number" then
			bestScore.Value = math.max(0, math.floor(profile.bestScore))
		end

		if typeof(profile.wins) == "number" then
			wins.Value = math.max(0, math.floor(profile.wins))
		end

		if typeof(profile.coins) == "number" then
			coins.Value = math.max(0, math.floor(profile.coins))
		end

		if typeof(profile.xp) == "number" then
			xp.Value = math.max(0, math.floor(profile.xp))
		end

		if typeof(profile.level) == "number" then
			level.Value = math.max(1, math.floor(profile.level))
		end

		playerSettings[player] = sanitizeSettings(profile.settings)
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

local function saveProfile(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local bestScore = leaderstats and leaderstats:FindFirstChild("BestScore")
	local wins = leaderstats and leaderstats:FindFirstChild("Wins")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local xp = leaderstats and leaderstats:FindFirstChild("XP")
	local level = leaderstats and leaderstats:FindFirstChild("Level")
	if not bestScore or not wins or not coins or not xp or not level or not profileStore then
		return
	end

	pcall(function()
		profileStore:SetAsync(`Player_{player.UserId}`, {
			version = 1,
			bestScore = bestScore.Value,
			wins = wins.Value,
			coins = coins.Value,
			xp = xp.Value,
			level = level.Value,
			settings = sanitizeSettings(playerSettings[player]),
			updatedAt = os.time(),
		})
	end)
end

local function levelFromXp(xp)
	return math.max(1, math.floor(math.sqrt(xp / Config.LevelXpBase)) + 1)
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
	if not coins or not xp or not level or not wins then
		return
	end

	local hundredScore = math.floor(state.score / 100)
	local earnedCoins = math.max(5, hundredScore * Config.CoinsPerHundredScore)
	local earnedXp = math.max(10, hundredScore * Config.XpPerHundredScore)

	if winner and state.mode == "Battle" then
		earnedCoins += Config.WinnerBonusCoins
		earnedXp += Config.WinnerBonusXp
		wins.Value += 1
	end

	coins.Value += earnedCoins
	xp.Value += earnedXp
	level.Value = levelFromXp(xp.Value)
	state.message = winner
			and state.mode == "Battle"
			and `Victory! +{earnedCoins} coins +{earnedXp} XP`
		or `Rewards: +{earnedCoins} coins +{earnedXp} XP`
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
		return false
	end

	local now = os.clock()
	local lastRequestAt = lastPlaceRequestAt[player] or 0
	if now - lastRequestAt < PLACE_COOLDOWN_SECONDS then
		return false
	end

	lastPlaceRequestAt[player] = now
	return true
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
		sessionId = session and session.id or nil,
		arenaIndex = session and session.arena and session.arena.index or nil,
		timeLeft = session and math.max(0, math.ceil(session.endsAt - os.clock())) or nil,
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

	hubEvent:FireClient(player, {
		mode = playerModes[player] or "Hub",
		queued = queuedPlayers[player] == true,
		queueCount = queueCount(),
		minPlayers = BATTLE_MIN_PLAYERS,
		activeSessions = activeSessionCount(),
		openArenas = openArenas,
		totalArenas = totalArenas,
		sessions = sessionSummaries(),
		secondsToSoloStart = secondsToSoloStart,
		message = message,
	})
end

local function broadcastHub(message)
	for _, player in Players:GetPlayers() do
		sendHubState(player, message)
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

local function createPlayerState(player, mode)
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
		linesCleared = 0,
		rewardsGranted = false,
		alive = true,
		message = nil,
	}

	giveNewHand(state)
	playerStates[player] = state
	updateLeaderstats(player, 0)
end

local function startBattle(players, mode)
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
		arena = arena,
	}
	activeSessions[session.id] = session

	for slot, player in players do
		queuedPlayers[player] = nil
		playerModes[player] = mode
		playerSessions[player] = session
		table.insert(session.players, player)
		createPlayerState(player, mode)
		teleportToArenaSlot(player, slot, session)
		effectsEvent:FireClient(player, {
			kind = "BattleStart",
			message = mode == "Story" and "Story training started!"
				or #players >= BATTLE_MIN_PLAYERS and "Battle started!"
				or "Solo test started!",
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
	if queueCount() == 0 then
		queueStartedAt = nil
	end

	broadcastHub(`{player.DisplayName} left the battle queue`)
end

startStoryMode = function(player)
	if playerModes[player] == "Battle" or playerModes[player] == "Story" then
		sendHubState(player, "Finish your current run first")
		return
	end

	if not findFreeArena() then
		sendHubState(player, "Arena is busy - try story again after this match")
		return
	end

	startBattle({ player }, "Story")
end

local function finishBattle(session, winner)
	if session.finishScheduled then
		return
	end

	session.finishScheduled = true

	for _, player in session.players do
		local state = playerStates[player]
		if not state then
			continue
		end

		grantBattleRewards(player, state, player == winner)
		saveProfile(player)
		state.alive = false
		effectsEvent:FireClient(player, {
			kind = "BattleResult",
			message = state.message,
			won = player == winner,
		})
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
	if state then
		grantBattleRewards(player, state, false)
	end
	saveProfile(player)
	playerStates[player] = nil
	playerSessions[player] = nil
	queuedPlayers[player] = nil
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
	broadcastHub("Returned to hub")
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
	if not canAcceptPlaceRequest(player, slot, x, y) then
		return
	end

	local state = playerStates[player]
	if not state or not state.alive then
		return
	end
	local session = playerSessions[player]
	if not session then
		return
	end

	local shape = state.hand[slot]
	if not shape then
		return
	end

	local placed, cellsPlaced = Grid.place(state.board, shape, x, y)
	if not placed then
		effectsEvent:FireClient(player, {
			kind = "InvalidPlace",
			message = "That spot is blocked",
		})
		return
	end

	state.hand[slot] = nil
	local linesCleared = Grid.clearLines(state.board)
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

queueEvent.OnServerEvent:Connect(function(player, mode)
	if mode == "Battle" then
		joinBattleQueue(player)
	elseif mode == "LeaveQueue" then
		leaveBattleQueue(player)
	elseif mode == "LeaveBattle" then
		leaveBattle(player)
	else
		startStoryMode(player)
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

	playerSettings[player] = sanitizeSettings(nextSettings)
	sendSettings(player)
	task.defer(function()
		saveProfile(player)
	end)
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
	playerModes[player] = nil
	playerSettings[player] = nil
	lastPlaceRequestAt[player] = nil
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
				broadcast(session)
			end
		end
		if queueCount() > 0 then
			broadcastHub("Waiting for players")
		end
	end
end)
