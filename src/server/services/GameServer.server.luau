local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Players.CharacterAutoLoads = false

local HUB_SPAWN_OFFSET = Vector3.new(0, 7, 0)
local emergencySpawn = Instance.new("SpawnLocation")
emergencySpawn.Name = "BlockBlastEmergencySpawn"
emergencySpawn.Anchored = true
emergencySpawn.Size = Vector3.new(36, 1, 36)
emergencySpawn.CFrame = CFrame.new(0, 6, 22)
emergencySpawn.Neutral = true
emergencySpawn.Duration = 0
emergencySpawn.Enabled = true
emergencySpawn.CanCollide = true
emergencySpawn.CanTouch = false
emergencySpawn.CanQuery = true
emergencySpawn.Transparency = 0.35
emergencySpawn.Parent = workspace

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GameShared = Shared:WaitForChild("game")
local Achievements = require(GameShared.Achievements)
local Blocks = require(GameShared.Blocks)
local Config = require(GameShared.Config)
local DeveloperTools = require(GameShared.DeveloperTools)
local ExperienceConfig = require(GameShared.ExperienceConfig)
local GameplayRules = require(GameShared.GameplayRules)
local Grid = require(GameShared.Grid)
local HandGenerator = require(GameShared.HandGenerator)
local ProfilePersistence = require(GameShared.ProfilePersistence)
local StageProgression = require(GameShared.StageProgression)
local Telemetry = require(GameShared.Telemetry)
local UIControlRules = require(GameShared.UIControlRules)
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

local handEvent = Instance.new("RemoteEvent")
handEvent.Name = "Hand"
handEvent.Parent = remotes

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

local shopEvent = Instance.new("RemoteEvent")
shopEvent.Name = "Shop"
shopEvent.Parent = remotes

local codesEvent = Instance.new("RemoteEvent")
codesEvent.Name = "Codes"
codesEvent.Parent = remotes

local achievementsEvent = Instance.new("RemoteEvent")
achievementsEvent.Name = "Achievements"
achievementsEvent.Parent = remotes

local devCommandFunction = Instance.new("RemoteFunction")
devCommandFunction.Name = "DevCommand"
devCommandFunction.Parent = remotes

local function makeFallbackPart(parent, name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = true
	part.CastShadow = false
	part.Parent = parent
	return part
end

local function makeFallbackPrompt(part, actionText, objectText)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

local function buildFallbackHub(buildError)
	local existing = workspace:FindFirstChild("BlockBlastHub")
	if existing then
		existing:Destroy()
	end

	local hub = Instance.new("Folder")
	hub.Name = "BlockBlastHub"
	hub.Parent = workspace

	local floor = workspace:FindFirstChild("BootstrapHubSafetyFloor")
	if floor and floor:IsA("BasePart") then
		floor.Color = Color3.fromRGB(72, 210, 119)
		floor.Material = Enum.Material.Grass
		floor.Size = Vector3.new(110, 1, 110)
		floor.Transparency = 0
	end

	local spawn = workspace:FindFirstChild("BootstrapHubSpawn")
	if not (spawn and spawn:IsA("SpawnLocation")) then
		spawn = emergencySpawn
		spawn.Parent = hub
	end
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.CanCollide = true
	spawn.Enabled = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.CFrame = CFrame.new(0, 7.2, 22) * CFrame.Angles(0, math.rad(180), 0)

	local soloPad = makeFallbackPart(
		hub,
		"SoloPlayPad",
		Vector3.new(24, 1, 18),
		Vector3.new(0, 2, -28),
		Color3.fromRGB(64, 156, 255),
		Enum.Material.Neon
	)
	soloPad:SetAttribute("QueueMode", "Solo")
	local soloPrompt = makeFallbackPrompt(soloPad, "Play", "Solo Puzzle")

	local fallbackColors = {
		Color3.fromRGB(255, 82, 82),
		Color3.fromRGB(255, 210, 62),
		Color3.fromRGB(63, 219, 118),
		Color3.fromRGB(48, 158, 255),
		Color3.fromRGB(167, 109, 255),
		Color3.fromRGB(255, 112, 189),
	}
	for index, color in fallbackColors do
		local angle = (math.pi * 2) * index / #fallbackColors
		makeFallbackPart(
			hub,
			`FallbackRainbowBlock{index}`,
			Vector3.new(6, 3, 6),
			Vector3.new(math.cos(angle) * 32, 4, math.sin(angle) * 32),
			color,
			Enum.Material.SmoothPlastic
		).CanCollide =
			false
	end
	for index = 1, 8 do
		local x = -42 + index * 10
		makeFallbackPart(
			hub,
			`FallbackFlower{index}`,
			Vector3.new(3, 0.8, 3),
			Vector3.new(x, 2.8, 36 + (index % 2) * 5),
			fallbackColors[((index - 1) % #fallbackColors) + 1],
			Enum.Material.Neon
		).CanCollide =
			false
	end

	local warning = makeFallbackPart(
		hub,
		"HubBuildWarning",
		Vector3.new(48, 10, 1),
		Vector3.new(0, 9, -48),
		Color3.fromRGB(255, 255, 255),
		Enum.Material.SmoothPlastic
	)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 36
	surfaceGui.Parent = warning
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = "Fallback Hub Loaded\nCheck Studio Output"
	label.TextColor3 = Color3.fromRGB(35, 45, 55)
	label.TextScaled = true
	label.Parent = surfaceGui

	warn(`Block Blast generated hub failed; fallback hub loaded: {buildError}`)
	return {
		hub = hub,
		spawn = spawn,
		soloPrompt = soloPrompt,
		battlePrompt = nil,
		storyPrompt = nil,
		battleSpawn = nil,
		arenaSpawns = {},
		arenaReturnPad = nil,
		arenas = {},
	}
end

local hubBuildSucceeded, hubPartsOrError = pcall(HubBuilder.build)
local hubParts = if hubBuildSucceeded then hubPartsOrError else buildFallbackHub(hubPartsOrError)
if not hubBuildSucceeded then
	warn(`Block Blast hub failed to build; using fallback hub: {hubPartsOrError}`)
end
if hubParts.spawn then
	hubParts.spawn.Anchored = true
	hubParts.spawn.CanCollide = true
	hubParts.spawn.Enabled = true
end
if hubBuildSucceeded and emergencySpawn.Parent then
	emergencySpawn:Destroy()
end
Players.CharacterAutoLoads = true

local playerStates = {}
local playerSpawnConnections = {}
local playerCharacterConnections = {}
local playerSessions = {}
local activeSessions = {}
local queuedPlayers = {}
local playerModes = {}
local playerSettings = {}
local playerDailyRewardDates = {}
local playerEntitlements = {}
local playerFulfilledPurchaseIds = {}
local playerRedeemedCodes = {}
local playerLifetimeStats = {}
local playerUnlockedAchievements = {}
local playerCosmeticInventories = {}
local playerProfileLoadStatus = {}
local playerProfileNoticeState = {}
local selectedStoryChapters = {}
local lastPlaceRequestAt = {}
local lastHandRequestAt = {}
local lastQueueRequestAt = {}
local lastDeveloperCommandAt = {}
local lastShopRequestAt = {}
local lastCodeRequestAt = {}
local lastAchievementsRequestAt = {}
local purchasePromptLocks = {}
local processedReceipts = {}
local settingsSaveScheduled = {}
local queueStartedAt = nil
local nextSessionId = 0
local serverHighScores = {}
local profileStore = nil
local profileLoadFailures = 0
local profileSaveFailures = 0
local analytics = {
	soloSessionsStarted = 0,
	soloSessionsFinished = 0,
	battleSessionsStarted = 0,
	storySessionsStarted = 0,
	battleSessionsFinished = 0,
	storyMissionsCompleted = 0,
	queueJoins = 0,
	queueLeaves = 0,
	placements = 0,
	linesCleared = 0,
	invalidPlacements = 0,
	combosTriggered = 0,
	rejectedPlaceRequests = 0,
	throttledPlaceRequests = 0,
	suddenDeathPressureRows = 0,
	profileFieldsSanitized = 0,
	profileSavesSkippedBeforeLoad = 0,
	forfeits = 0,
	shopSnapshotsRequested = 0,
	shopPromptRequests = 0,
	shopPromptRejected = 0,
	shopPromptCompleted = 0,
	shopPromptCancelled = 0,
	shopOwnershipRefreshes = 0,
	developerProductReceiptsGranted = 0,
	developerProductReceiptsRetried = 0,
	shopOpened = 0,
	shopTabsSelected = 0,
	cosmeticsPreviewed = 0,
	cosmeticPurchaseAttempts = 0,
	cosmeticPurchaseSucceeded = 0,
	cosmeticPurchaseFailed = 0,
	cosmeticEquips = 0,
	gamePassPromptOpened = 0,
	customLabSessionsStarted = 0,
	customLabHandRotations = 0,
	customLabHandRerolls = 0,
	rejectedHandRequests = 0,
	throttledHandRequests = 0,
	throttledCodeRedemptions = 0,
	throttledAchievementsRequests = 0,
}

pcall(function()
	profileStore = DataStoreService:GetDataStore("BlockBlastProfilesV1")
end)

-- Cross-server analytics totals. Separate store from profiles so a problem
-- with one cannot affect the other, and so analytics writes never share a
-- key with player data.
local analyticsStore = nil
local analyticsFlushFailures = 0
local lastFlushedCounters = {}

pcall(function()
	analyticsStore = DataStoreService:GetDataStore("BlockBlastAnalyticsV1")
end)

-- Fold this server's counters into the shared totals.
--
-- Every counter used to live only in memory, so a restart discarded the lot
-- and nothing was ever aggregated across servers. This writes deltas rather
-- than totals, so several servers can accumulate into one key without
-- overwriting each other.
--
-- Returns true when the counters are safely stored (including when there is
-- nothing to store).
local function flushAnalytics()
	if not analyticsStore then
		return false
	end

	local deltas, hasAny = Telemetry.counterDeltas(analytics, lastFlushedCounters)
	if not hasAny then
		return true
	end

	-- Snapshot before the write, not after: a counter that ticks while the
	-- request is in flight belongs to the next flush.
	local snapshot = Telemetry.flushedSnapshot(analytics)
	local updatedAt = os.time()

	local ok, err = pcall(function()
		analyticsStore:UpdateAsync("Totals", function(stored)
			return Telemetry.mergeTotals(stored, deltas, updatedAt)
		end)
	end)

	if not ok then
		-- lastFlushedCounters is deliberately left alone, so these deltas are
		-- retried on the next flush instead of being lost.
		analyticsFlushFailures += 1
		warn(`[BlockBlast] Failed to flush analytics: {tostring(err)}`)
		return false
	end

	lastFlushedCounters = snapshot
	return true
end

local BATTLE_MIN_PLAYERS = 2
local SOLO_TEST_SECONDS = 8
local OUT_OF_MOVES_RETURN_SECONDS = 4
local POST_BATTLE_RETURN_SECONDS = 6
local PLACE_COOLDOWN_SECONDS = 0.08
local HAND_ACTION_COOLDOWN_SECONDS = 0.18
local QUEUE_ACTION_COOLDOWN_SECONDS = 0.35
local SHOP_ACTION_COOLDOWN_SECONDS = 0.35
-- Deliberately the slowest of the action cooldowns. Redeeming is a typed,
-- one-at-a-time action, and this remote is the one an attacker would use to
-- guess codes.
local CODE_REDEEM_COOLDOWN_SECONDS = 1
local ACHIEVEMENTS_ACTION_COOLDOWN_SECONDS = 0.35
local ENTITLEMENT_CACHE_SECONDS = 120
local SETTINGS_SAVE_DEBOUNCE_SECONDS = 1
local PROFILE_SAVE_RETRY_COUNT = 3
local PROFILE_LOAD_RETRY_COUNT = 3
-- How long a save may block waiting for an in-flight profile load before
-- giving up. PlayerRemoving and BindToClose both run on a limited budget,
-- so this stays well under Roblox's 30s BindToClose allowance.
local PROFILE_LOAD_WAIT_SECONDS = 6
local PROFILE_LIMITS = {
	bestScore = 1000000000,
	wins = 1000000,
	coins = 100000000,
	xp = 100000000,
	level = 1000,
	storyStars = 100000,
}
local PROFILE_VERSION = 2
local leaveBattle = nil
local scheduleReturnIfEliminated = nil
local resolveBattleIfFinished = nil
local sendHubState = nil
local sendShopSnapshot = nil
local startStoryMode = nil
local leaveBattleQueue = nil
local ownsLegacyCosmetic = nil
local sanitizeCosmeticInventory = nil
local cosmeticInventory = nil
local applyEquippedCosmeticsToSettings = nil

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

local function isFiniteNumber(value)
	return typeof(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function dailyDateKey()
	local date = os.date("!*t")
	return string.format("%04d-%02d-%02d", date.year, date.month, date.day)
end

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

local function sanitizeSettings(settings, progress, player)
	local clean = table.clone(DEFAULT_SETTINGS)
	if typeof(settings) ~= "table" then
		return clean
	end

	if isFiniteNumber(settings.themeIndex) then
		clean.themeIndex = math.clamp(math.floor(settings.themeIndex), 1, 3)
	end

	if typeof(settings.reducedMotion) == "boolean" then
		clean.reducedMotion = settings.reducedMotion
	end

	if isFiniteNumber(settings.uiScale) then
		clean.uiScale = math.clamp(settings.uiScale, 0.92, 1.12)
	end

	if typeof(settings.tutorialComplete) == "boolean" then
		clean.tutorialComplete = settings.tutorialComplete
	end

	if
		typeof(settings.pieceSkin) == "string"
		and Blocks.isValidPieceSkin(settings.pieceSkin)
		and (
			ownsLegacyCosmetic
				and ownsLegacyCosmetic(
					player,
					settings.pieceSkin,
					Config.CosmeticCategories.PieceSkin
				)
			or not ownsLegacyCosmetic
				and Config.meetsCosmeticRequirement(
					Config.PieceSkinUnlocks[settings.pieceSkin],
					progress
				)
		)
	then
		clean.pieceSkin = settings.pieceSkin
	end

	if
		typeof(settings.boardSkin) == "string"
		and Config.isValidBoardSkin(settings.boardSkin)
		and (
			ownsLegacyCosmetic
				and ownsLegacyCosmetic(
					player,
					settings.boardSkin,
					Config.CosmeticCategories.BoardSkin
				)
			or not ownsLegacyCosmetic
				and Config.meetsCosmeticRequirement(
					Config.BoardSkinUnlocks[settings.boardSkin],
					progress
				)
		)
	then
		clean.boardSkin = settings.boardSkin
	end

	if typeof(settings.soundEnabled) == "boolean" then
		clean.soundEnabled = settings.soundEnabled
	end

	if isFiniteNumber(settings.soundVolume) then
		clean.soundVolume = math.clamp(settings.soundVolume, 0, 1)
	end

	return clean
end

local function sendSettings(player)
	settingsEvent:FireClient(
		player,
		sanitizeSettings(playerSettings[player], cosmeticProgress(player), player)
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
	if not isFiniteNumber(value) then
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

-- The timestamp half of every rate-limit gate on this server.
--
-- Seven remotes had their own copy of "read the last timestamp, compare it
-- to a cooldown, record the new one". Two of those copies were added the
-- same day this was written, because following the existing pattern meant
-- pasting it again. The decision itself now comes from
-- UIControlRules.canFireServerAction, which is unit-tested; callers keep
-- their own timestamps, cooldowns, and preconditions.
--
-- Records the new timestamp only when the request is accepted, so a
-- rejected burst cannot keep pushing the window forward.
local function consumeActionCooldown(timestamps, player, cooldownSeconds)
	local now = os.clock()
	if not UIControlRules.canFireServerAction(timestamps[player] or 0, now, cooldownSeconds) then
		return false
	end

	timestamps[player] = now
	return true
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

-- Thin wrapper so the clamping rules live in shared/game with the other
-- sanitizers and stay unit-testable; the server keeps only the analytics
-- bookkeeping.
local function sanitizeLifetimeStats(raw)
	local clean, corrected = Achievements.sanitizeLifetimeStats(raw)
	analytics.profileFieldsSanitized += corrected
	return clean
end

local function sanitizeUnlockedAchievements(raw)
	local clean = {}
	if typeof(raw) ~= "table" then
		return clean
	end

	for achievementId, value in raw do
		if value == true and Achievements.getDefinition(achievementId) then
			clean[achievementId] = true
		end
	end

	return clean
end

-- Tells the player their save could not be read, so they do not mistake a
-- DataStore outage for having genuinely lost their progress. Since the
-- load failed, this session is also read-only, which the message says.
local function notifyProfileLoadFailure(player)
	local notice = playerProfileNoticeState[player]
	if not ProfilePersistence.shouldNotifyLoadFailure(playerProfileLoadStatus[player], notice) then
		return
	end

	notice.sent = true
	effectsEvent:FireClient(player, {
		kind = "ProfileLoadFailed",
		message = "Couldn't load your save. Nothing was lost, but this session won't save progress - rejoin to try again.",
	})
end

-- Records the outcome of a player's profile load. Ignores players who are
-- no longer tracked, so a load that resolves after PlayerRemoving cleaned
-- up does not leak an entry back into the table.
local function markProfileLoadStatus(player, status)
	if playerProfileLoadStatus[player] == nil then
		return
	end

	playerProfileLoadStatus[player] = status

	if status == ProfilePersistence.LoadStatus.Failed then
		notifyProfileLoadFailure(player)
	end
end

local function createLeaderstats(player)
	-- Everything below starts blank and only becomes real once the async
	-- load at the bottom of this function resolves. Until then no save is
	-- allowed -- see saveProfile.
	playerProfileLoadStatus[player] = ProfilePersistence.LoadStatus.Pending
	playerProfileNoticeState[player] = { clientReady = false, sent = false }

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
			-- No DataStore access at all. Nothing can be read, so nothing may
			-- be written either.
			markProfileLoadStatus(player, ProfilePersistence.LoadStatus.Failed)
			return
		end

		local ok, profile
		for attempt = 1, PROFILE_LOAD_RETRY_COUNT do
			ok, profile = pcall(function()
				return profileStore:GetAsync(`Player_{player.UserId}`)
			end)

			if ok or attempt == PROFILE_LOAD_RETRY_COUNT or player.Parent ~= Players then
				break
			end

			task.wait(0.35 * attempt)
		end

		if not ok then
			profileLoadFailures += 1
			-- Staying Failed keeps this session read-only: the stored profile
			-- is real data we could not read, and writing blank in-memory
			-- defaults over it would wipe the player.
			markProfileLoadStatus(player, ProfilePersistence.LoadStatus.Failed)
			warn(`[BlockBlast] Failed to load profile for {player.UserId}: {tostring(profile)}`)
			return
		end

		-- The read succeeded. A nil result simply means a new player with no
		-- saved profile yet, which is safe to write over.
		markProfileLoadStatus(player, ProfilePersistence.LoadStatus.Loaded)

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

		if typeof(profile.dailyRewardDate) == "string" then
			playerDailyRewardDates[player] = profile.dailyRewardDate
		end
		playerFulfilledPurchaseIds[player] = typeof(profile.fulfilledPurchaseIds) == "table"
				and table.clone(profile.fulfilledPurchaseIds)
			or {}
		playerRedeemedCodes[player] = typeof(profile.redeemedCodes) == "table"
				and table.clone(profile.redeemedCodes)
			or {}
		playerLifetimeStats[player] = sanitizeLifetimeStats(profile.lifetimeStats)
		playerUnlockedAchievements[player] =
			sanitizeUnlockedAchievements(profile.unlockedAchievements)
		playerCosmeticInventories[player] = sanitizeCosmeticInventory(
			player,
			profile.cosmetics,
			cosmeticProgress(player),
			profile.settings
		)
		playerSettings[player] =
			sanitizeSettings(profile.settings, cosmeticProgress(player), player)
		applyEquippedCosmeticsToSettings(player)
		if sendHubState and playerModes[player] == "Hub" then
			sendHubState(player, "Welcome to the hub")
		end
		sendSettings(player)
		if sendShopSnapshot then
			sendShopSnapshot(player)
		end
	end)
end

local function updateLeaderstats(player, score, recordEligible)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local battleScore = leaderstats:FindFirstChild("BattleScore")
	local bestScore = leaderstats:FindFirstChild("BestScore")

	if battleScore then
		battleScore.Value = score
	end

	if recordEligible == false then
		return
	end

	if bestScore and score > bestScore.Value then
		bestScore.Value = score
	end

	serverHighScores[player.UserId] = {
		userId = player.UserId,
		name = player.DisplayName,
		score = math.max(score, bestScore and bestScore.Value or 0),
		bestScore = bestScore and bestScore.Value or score,
	}
end

local function serverHighScoreList()
	local list = {}
	for _, entry in serverHighScores do
		table.insert(list, table.clone(entry))
	end

	table.sort(list, function(a, b)
		if a.score == b.score then
			return a.name < b.name
		end
		return a.score > b.score
	end)

	while #list > 10 do
		table.remove(list)
	end

	return list
end

local function profileStats(player)
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
		return nil
	end

	return {
		bestScore = bestScore,
		wins = wins,
		coins = coins,
		xp = xp,
		level = level,
		storyStars = storyStars,
	}
end

local function mergedProfilePayload(player, existingProfile, stats)
	existingProfile = typeof(existingProfile) == "table" and existingProfile or {}
	-- Receipt ids and redeemed codes only ever gain entries, so union them
	-- rather than letting the in-memory copy replace the stored one. A save
	-- can then never drop a receipt it did not happen to know about.
	local fulfilledPurchaseIds = ProfilePersistence.mergeAppendOnlySet(
		playerFulfilledPurchaseIds[player],
		existingProfile.fulfilledPurchaseIds
	)
	local redeemedCodes = ProfilePersistence.mergeAppendOnlySet(
		playerRedeemedCodes[player],
		existingProfile.redeemedCodes
	)
	local lifetimeStats =
		sanitizeLifetimeStats(playerLifetimeStats[player] or existingProfile.lifetimeStats)
	local unlockedAchievements = typeof(playerUnlockedAchievements[player]) == "table"
			and table.clone(playerUnlockedAchievements[player])
		or sanitizeUnlockedAchievements(existingProfile.unlockedAchievements)

	return {
		version = PROFILE_VERSION,
		bestScore = sanitizedStatValue(stats.bestScore, 0, PROFILE_LIMITS.bestScore, 0),
		wins = sanitizedStatValue(stats.wins, 0, PROFILE_LIMITS.wins, 0),
		coins = sanitizedStatValue(stats.coins, 0, PROFILE_LIMITS.coins, 0),
		xp = sanitizedStatValue(stats.xp, 0, PROFILE_LIMITS.xp, 0),
		level = sanitizedStatValue(stats.level, 1, PROFILE_LIMITS.level, 1),
		storyStars = sanitizedStatValue(stats.storyStars, 0, PROFILE_LIMITS.storyStars, 0),
		settings = sanitizeSettings(playerSettings[player], cosmeticProgress(player), player),
		dailyRewardDate = playerDailyRewardDates[player],
		cosmetics = cosmeticInventory(player),
		fulfilledPurchaseIds = fulfilledPurchaseIds,
		redeemedCodes = redeemedCodes,
		lifetimeStats = lifetimeStats,
		unlockedAchievements = unlockedAchievements,
		updatedAt = os.time(),
	}
end

-- Writes through UpdateAsync rather than SetAsync so the payload is built
-- against whatever is actually stored, instead of assuming the in-memory
-- session is the only writer.
local function updateProfileWithRetry(player, stats)
	-- Built up front, outside the transform: an UpdateAsync callback must
	-- not yield, and assembling the payload touches cosmetic/entitlement
	-- lookups that can. The transform itself stays a pure reconcile.
	local payload = mergedProfilePayload(player, nil, stats)

	for attempt = 1, PROFILE_SAVE_RETRY_COUNT do
		local ok, err = pcall(function()
			profileStore:UpdateAsync(`Player_{player.UserId}`, function(existingProfile)
				return ProfilePersistence.reconcileWithStored(payload, existingProfile)
			end)
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
	if not ProfilePersistence.canSave(playerProfileLoadStatus[player]) then
		-- The profile has not been read back yet (or could not be), so the
		-- in-memory session is still blank defaults. Writing it would wipe
		-- the player's real saved data.
		analytics.profileSavesSkippedBeforeLoad += 1
		return false
	end

	local stats = profileStats(player)
	if not stats then
		return false
	end

	return updateProfileWithRetry(player, stats)
end

-- Save for a player who is going away (leaving, or the server shutting
-- down). If their load is still in flight, briefly wait for it instead of
-- skipping, so a short session's progress is still written.
local function saveProfileBeforeExit(player)
	local startedAt = os.clock()

	while
		ProfilePersistence.saveDecision(
			playerProfileLoadStatus[player],
			os.clock() - startedAt,
			PROFILE_LOAD_WAIT_SECONDS
		) == "wait"
	do
		task.wait(0.1)
	end

	return saveProfile(player)
end

local function productInfoForMarketplaceId(marketplaceId, infoType)
	if marketplaceId == Config.Monetization.PlaceholderId then
		return nil
	end

	local ok, info = pcall(function()
		return MarketplaceService:GetProductInfo(marketplaceId, infoType)
	end)
	if ok and typeof(info) == "table" then
		return info
	end

	return nil
end

local function entitlementState(player)
	playerEntitlements[player] = playerEntitlements[player]
		or {
			gamePasses = {},
			lastCheckedAt = {},
			errors = {},
		}

	return playerEntitlements[player]
end

local function refreshGamePassOwnership(player, pass, force)
	local entitlements = entitlementState(player)
	if pass.gamePassId == Config.Monetization.PlaceholderId then
		entitlements.gamePasses[pass.id] = false
		entitlements.errors[pass.id] = "Creator Dashboard ID required"
		return false, "Creator Dashboard ID required"
	end

	local lastCheckedAt = entitlements.lastCheckedAt[pass.id] or 0
	if not force and os.clock() - lastCheckedAt < ENTITLEMENT_CACHE_SECONDS then
		return entitlements.gamePasses[pass.id] == true, entitlements.errors[pass.id]
	end

	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.gamePassId)
	end)

	entitlements.lastCheckedAt[pass.id] = os.clock()
	analytics.shopOwnershipRefreshes += 1
	if not ok then
		entitlements.errors[pass.id] = "Ownership check failed"
		return entitlements.gamePasses[pass.id] == true, entitlements.errors[pass.id]
	end

	entitlements.gamePasses[pass.id] = owns == true
	entitlements.errors[pass.id] = nil
	return entitlements.gamePasses[pass.id], nil
end

local function playerOwnsGamePass(player, passId)
	local pass = Config.getGamePassDefinition(passId)
	if not pass then
		return false
	end

	local owned = refreshGamePassOwnership(player, pass, false)
	return owned == true
end

local function entitlementRewardMultipliers(player)
	local coinMultiplier = 1
	local xpMultiplier = 1
	for _, pass in Config.Monetization.GamePasses do
		if playerOwnsGamePass(player, pass.id) and typeof(pass.rewardMultipliers) == "table" then
			coinMultiplier *= pass.rewardMultipliers.coins or 1
			xpMultiplier *= pass.rewardMultipliers.xp or 1
		end
	end

	return coinMultiplier, xpMultiplier
end

local function entitlementDailyBonusCoins(player)
	local bonus = 0
	for _, pass in Config.Monetization.GamePasses do
		if pass.dailyBonusCoins and playerOwnsGamePass(player, pass.id) then
			bonus += pass.dailyBonusCoins
		end
	end

	return bonus
end

local function cosmeticIdForLegacyValue(category, legacyValue)
	for _, cosmetic in Config.Cosmetics do
		local preview = cosmetic.preview or {}
		if
			cosmetic.cosmeticCategory == category
			and (
				preview.pieceSkin == legacyValue
				or preview.boardSkin == legacyValue
				or preview.lineClearEffect == legacyValue
				or preview.title == legacyValue
			)
		then
			return cosmetic.id
		end
	end

	return nil
end

local function defaultOwnedCosmetics(progress)
	local owned = {}
	for _, cosmetic in Config.Cosmetics do
		if
			cosmetic.defaultOwned
			or (
				cosmetic.requirement
				and Config.meetsCosmeticRequirement(cosmetic.requirement, progress)
			)
		then
			owned[cosmetic.id] = true
		end
	end

	return owned
end

local function canOwnCosmetic(player, cosmetic, progress, owned)
	if not cosmetic then
		return false
	end
	if owned and owned[cosmetic.id] == true then
		return true
	end
	if cosmetic.defaultOwned then
		return true
	end
	if cosmetic.requiredGamePass then
		return playerOwnsGamePass(player, cosmetic.requiredGamePass)
	end
	if cosmetic.requirement then
		return Config.meetsCosmeticRequirement(cosmetic.requirement, progress)
	end

	return false
end

sanitizeCosmeticInventory = function(player, rawInventory, progress, legacySettings)
	local owned = defaultOwnedCosmetics(progress)
	rawInventory = typeof(rawInventory) == "table" and rawInventory or {}

	if typeof(rawInventory.owned) == "table" then
		for cosmeticId, value in rawInventory.owned do
			if value == true and Config.getCosmeticDefinition(cosmeticId) then
				owned[cosmeticId] = true
			end
		end
	end

	local equipped = {}
	local rawEquipped = typeof(rawInventory.equipped) == "table" and rawInventory.equipped or {}
	for category, defaultCosmeticId in Config.DefaultEquippedCosmetics do
		local requestedId = rawEquipped[category]
		if not requestedId and typeof(legacySettings) == "table" then
			if category == Config.CosmeticCategories.PieceSkin then
				requestedId = cosmeticIdForLegacyValue(category, legacySettings.pieceSkin)
			elseif category == Config.CosmeticCategories.BoardSkin then
				requestedId = cosmeticIdForLegacyValue(category, legacySettings.boardSkin)
			end
		end

		local cosmetic = Config.getCosmeticDefinition(requestedId)
		if
			cosmetic
			and cosmetic.cosmeticCategory == category
			and canOwnCosmetic(player, cosmetic, progress, owned)
		then
			owned[cosmetic.id] = true
			equipped[category] = cosmetic.id
		else
			owned[defaultCosmeticId] = true
			equipped[category] = defaultCosmeticId
		end
	end

	return {
		owned = owned,
		equipped = equipped,
		presets = {},
		activePreset = 1,
	}
end

cosmeticInventory = function(player)
	if not playerCosmeticInventories[player] then
		playerCosmeticInventories[player] =
			sanitizeCosmeticInventory(player, nil, cosmeticProgress(player), playerSettings[player])
	end

	return playerCosmeticInventories[player]
end

ownsLegacyCosmetic = function(player, legacyValue, category)
	local cosmeticId = cosmeticIdForLegacyValue(category, legacyValue)
	if not cosmeticId then
		return false
	end

	local inventory = cosmeticInventory(player)
	local cosmetic = Config.getCosmeticDefinition(cosmeticId)
	return canOwnCosmetic(player, cosmetic, cosmeticProgress(player), inventory.owned)
end

applyEquippedCosmeticsToSettings = function(player)
	local inventory = cosmeticInventory(player)
	local settings = playerSettings[player] or table.clone(DEFAULT_SETTINGS)
	local pieceCosmetic =
		Config.getCosmeticDefinition(inventory.equipped[Config.CosmeticCategories.PieceSkin])
	local boardCosmetic =
		Config.getCosmeticDefinition(inventory.equipped[Config.CosmeticCategories.BoardSkin])
	if pieceCosmetic and pieceCosmetic.preview and pieceCosmetic.preview.pieceSkin then
		settings.pieceSkin = pieceCosmetic.preview.pieceSkin
	end
	if boardCosmetic and boardCosmetic.preview and boardCosmetic.preview.boardSkin then
		settings.boardSkin = boardCosmetic.preview.boardSkin
	end
	playerSettings[player] = sanitizeSettings(settings, cosmeticProgress(player), player)
end

local function publicCosmeticCatalog(player)
	local progress = cosmeticProgress(player)
	local inventory = cosmeticInventory(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local coinBalance = coins and coins.Value or 0
	local items = {}

	for _, cosmetic in Config.Cosmetics do
		local owned = canOwnCosmetic(player, cosmetic, progress, inventory.owned)
		if owned then
			inventory.owned[cosmetic.id] = true
		end

		local requiredPass = cosmetic.requiredGamePass
		local passDefinition = requiredPass and Config.getGamePassDefinition(requiredPass) or nil
		local passUnavailable = passDefinition
			and passDefinition.gamePassId == Config.Monetization.PlaceholderId
		local equipped = inventory.equipped[cosmetic.cosmeticCategory] == cosmetic.id
		local hasCost = (cosmetic.costCoins or 0) > 0
		local canAfford = not hasCost or coinBalance >= cosmetic.costCoins
		local lockedReason = nil
		local state = "Available"

		if equipped then
			state = "Equipped"
		elseif owned then
			state = "Owned"
		elseif passUnavailable then
			state = "Unavailable"
			lockedReason = "Creator Dashboard ID required"
		elseif requiredPass then
			state = "PassRequired"
			lockedReason = "Requires game pass"
		elseif hasCost and not canAfford then
			state = "Locked"
			lockedReason = `Need {cosmetic.costCoins} coins`
		elseif
			cosmetic.requirement
			and not Config.meetsCosmeticRequirement(cosmetic.requirement, progress)
		then
			state = "Locked"
			lockedReason = cosmetic.requirement.label or "Keep playing"
		elseif not hasCost then
			state = "Locked"
			lockedReason = "Locked"
		end

		table.insert(items, {
			id = cosmetic.id,
			itemType = "Cosmetic",
			name = cosmetic.name,
			description = cosmetic.description,
			category = "Cosmetics",
			cosmeticCategory = cosmetic.cosmeticCategory,
			rarity = cosmetic.rarity,
			unlockSource = cosmetic.unlockSource,
			costCoins = cosmetic.costCoins,
			requiredGamePass = cosmetic.requiredGamePass,
			preview = cosmetic.preview,
			owned = owned,
			equipped = equipped,
			available = state == "Available" or state == "Owned" or state == "Equipped",
			state = state,
			unavailableReason = lockedReason,
		})
	end

	return items
end

local function equippedCosmeticPreview(player, category)
	local inventory = cosmeticInventory(player)
	local cosmetic = Config.getCosmeticDefinition(inventory.equipped[category])
	return cosmetic and cosmetic.preview or {}
end

local function publicEquippedCosmetics(player)
	return {
		pieceSkin = equippedCosmeticPreview(player, Config.CosmeticCategories.PieceSkin).pieceSkin
			or "Rainbow",
		boardSkin = equippedCosmeticPreview(player, Config.CosmeticCategories.BoardSkin).boardSkin
			or "Auto",
		lineClearEffect = equippedCosmeticPreview(
			player,
			Config.CosmeticCategories.LineClearEffect
		).lineClearEffect or "Spark",
		title = equippedCosmeticPreview(player, Config.CosmeticCategories.PlayerTitle).title
			or "Rookie",
	}
end

local function publicShopSnapshot(player, message, pendingId)
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	local ownsExtraPresetSlots = playerOwnsGamePass(player, "EXTRA_PRESET_SLOTS_PASS")
	local gamePasses = {}
	for _, pass in Config.Monetization.GamePasses do
		local owned, ownershipError = refreshGamePassOwnership(player, pass, false)
		local info = productInfoForMarketplaceId(pass.gamePassId, Enum.InfoType.GamePass)
		local price = info and info.PriceInRobux or pass.suggestedPriceRobux
		local unavailableReason = ownershipError
		if
			pass.id == "EXTRA_PRESET_SLOTS_PASS"
			and pass.gamePassId ~= Config.Monetization.PlaceholderId
		then
			unavailableReason = "Preset UI not implemented yet"
		end
		table.insert(gamePasses, {
			id = pass.id,
			itemType = "GamePass",
			name = (info and info.Name) or pass.name,
			description = (info and info.Description) or pass.description,
			category = pass.category,
			featured = pass.featured == true,
			benefits = pass.benefits,
			owned = owned == true,
			equipped = owned == true and pass.id == "VIP_PASS",
			available = pass.gamePassId ~= Config.Monetization.PlaceholderId
				and ownershipError == nil
				and unavailableReason == nil,
			marketplaceId = pass.gamePassId,
			priceRobux = price,
			state = owned and "Owned"
				or unavailableReason and "Unavailable"
				or pendingId == pass.id and "Loading"
				or "Available",
			unavailableReason = unavailableReason,
		})
	end

	local developerProducts = {}
	for _, product in Config.Monetization.DeveloperProducts do
		local info = productInfoForMarketplaceId(product.productId, Enum.InfoType.Product)
		local unavailable = product.productId == Config.Monetization.PlaceholderId
		table.insert(developerProducts, {
			id = product.id,
			itemType = "DeveloperProduct",
			name = (info and info.Name) or product.name,
			description = (info and info.Description) or product.description,
			category = product.category,
			featured = product.featured == true,
			coins = product.coins,
			available = not unavailable,
			marketplaceId = product.productId,
			priceRobux = (info and info.PriceInRobux) or product.suggestedPriceRobux,
			state = unavailable and "Unavailable"
				or pendingId == product.id and "Loading"
				or "Available",
			unavailableReason = unavailable and "Creator Dashboard ID required" or nil,
		})
	end

	return {
		gamePasses = gamePasses,
		developerProducts = developerProducts,
		cosmetics = publicCosmeticCatalog(player),
		coinBalance = coins and coins.Value or 0,
		presetSlots = Config.FreePresetSlots
			+ (ownsExtraPresetSlots and Config.ExtraPresetSlots or 0),
		extraPresetSlotsAvailable = ownsExtraPresetSlots,
		message = message,
		pendingId = pendingId,
		analytics = {
			snapshots = analytics.shopSnapshotsRequested,
			prompts = analytics.shopPromptRequests,
			rejected = analytics.shopPromptRejected,
			completed = analytics.shopPromptCompleted,
			cancelled = analytics.shopPromptCancelled,
		},
	}
end

sendShopSnapshot = function(player, message, pendingId)
	shopEvent:FireClient(player, {
		kind = "Snapshot",
		shop = publicShopSnapshot(player, message, pendingId),
	})
end

local function canAcceptShopAction(player)
	return consumeActionCooldown(lastShopRequestAt, player, SHOP_ACTION_COOLDOWN_SECONDS)
end

local function findPurchasableDefinition(itemType, itemId)
	if typeof(itemId) ~= "string" then
		return nil
	end

	if itemType == "GamePass" then
		return Config.getGamePassDefinition(itemId)
	elseif itemType == "DeveloperProduct" then
		return Config.getDeveloperProductDefinition(itemId)
	end

	return nil
end

local function sendShopError(player, message)
	shopEvent:FireClient(player, {
		kind = "Error",
		message = message,
	})
end

local SHOP_ANALYTICS_EVENTS = {
	ShopOpened = "shopOpened",
	ShopTabSelected = "shopTabsSelected",
	CosmeticPreviewed = "cosmeticsPreviewed",
	CosmeticPurchaseAttempted = "cosmeticPurchaseAttempts",
	GamePassPromptOpened = "gamePassPromptOpened",
}

local function trackShopAnalytics(eventName)
	local counter = SHOP_ANALYTICS_EVENTS[eventName]
	if not counter then
		return false
	end

	analytics[counter] += 1
	return true
end

local function purchaseCosmetic(player, cosmeticId)
	local cosmetic = Config.getCosmeticDefinition(cosmeticId)
	if not cosmetic then
		analytics.shopPromptRejected += 1
		analytics.cosmeticPurchaseFailed += 1
		sendShopError(player, "That cosmetic is unavailable.")
		return
	end

	local inventory = cosmeticInventory(player)
	if canOwnCosmetic(player, cosmetic, cosmeticProgress(player), inventory.owned) then
		sendShopSnapshot(player, "Already owned.")
		return
	end

	if cosmetic.requiredGamePass then
		analytics.cosmeticPurchaseFailed += 1
		sendShopError(player, "This cosmetic requires a game pass.")
		return
	end

	if (cosmetic.costCoins or 0) <= 0 then
		analytics.cosmeticPurchaseFailed += 1
		sendShopError(player, "This cosmetic cannot be bought with coins.")
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if not coins or coins.Value < cosmetic.costCoins then
		analytics.shopPromptRejected += 1
		analytics.cosmeticPurchaseFailed += 1
		sendShopSnapshot(player, `Need {cosmetic.costCoins} coins.`)
		return
	end

	coins.Value -= cosmetic.costCoins
	inventory.owned[cosmetic.id] = true
	if not saveProfile(player) then
		inventory.owned[cosmetic.id] = nil
		coins.Value += cosmetic.costCoins
		analytics.cosmeticPurchaseFailed += 1
		sendShopError(player, "Purchase could not be saved. Try again.")
		return
	end

	analytics.shopPromptCompleted += 1
	analytics.cosmeticPurchaseSucceeded += 1
	sendSettings(player)
	sendShopSnapshot(player, `{cosmetic.name} purchased.`)
end

local function equipCosmetic(player, cosmeticId)
	local cosmetic = Config.getCosmeticDefinition(cosmeticId)
	if not cosmetic then
		analytics.shopPromptRejected += 1
		sendShopError(player, "That cosmetic is unavailable.")
		return
	end

	local inventory = cosmeticInventory(player)
	if not canOwnCosmetic(player, cosmetic, cosmeticProgress(player), inventory.owned) then
		analytics.shopPromptRejected += 1
		sendShopSnapshot(player, "Unlock this cosmetic before equipping it.")
		return
	end

	inventory.owned[cosmetic.id] = true
	local previousEquipped = inventory.equipped[cosmetic.cosmeticCategory]
	local previousSettings = table.clone(playerSettings[player] or DEFAULT_SETTINGS)
	inventory.equipped[cosmetic.cosmeticCategory] = cosmetic.id
	applyEquippedCosmeticsToSettings(player)
	if not saveProfile(player) then
		inventory.equipped[cosmetic.cosmeticCategory] = previousEquipped
		playerSettings[player] = previousSettings
		sendShopError(player, "Equip could not be saved. Try again.")
		return
	end

	analytics.shopPromptCompleted += 1
	analytics.cosmeticEquips += 1
	sendSettings(player)
	sendShopSnapshot(player, `{cosmetic.name} equipped.`)
end

-- Kept server-side on purpose: this table is never replicated, so the code
-- strings are not readable from a client.
local CODES = {
	-- Developer/testing code. Restricted to Config.DeveloperTools
	-- .AuthorizedUserIds -- it maxes out every stat and unlocks all
	-- cosmetics including gamepass-locked ones, and the string itself is
	-- readable by anyone browsing the public repository.
	yoel = { kind = "DevUnlock", requiresDeveloperAuthorization = true },
}

-- The single reply for "this code is not redeemable by you". Unknown codes
-- and codes the player is not authorized for deliberately share it, so an
-- unauthorized player cannot discover that a restricted code exists.
local function sendUnknownCodeError(player)
	codesEvent:FireClient(player, { kind = "Error", message = "That code doesn't exist." })
end

local function redeemCode(player, rawCode)
	local normalizedCode = typeof(rawCode) == "string" and rawCode:gsub("%s", ""):lower() or ""
	local definition = normalizedCode ~= "" and CODES[normalizedCode] or nil
	if not definition then
		sendUnknownCodeError(player)
		return
	end

	if
		definition.requiresDeveloperAuthorization
		and not DeveloperTools.isAuthorizedUserId(player.UserId)
	then
		sendUnknownCodeError(player)
		return
	end

	local redeemed = playerRedeemedCodes[player] or {}
	playerRedeemedCodes[player] = redeemed
	if redeemed[normalizedCode] then
		codesEvent:FireClient(
			player,
			{ kind = "Error", message = "You already redeemed that code." }
		)
		return
	end

	if definition.kind == "DevUnlock" then
		local leaderstats = player:FindFirstChild("leaderstats")
		local coins = leaderstats and leaderstats:FindFirstChild("Coins")
		local xp = leaderstats and leaderstats:FindFirstChild("XP")
		local level = leaderstats and leaderstats:FindFirstChild("Level")
		local storyStars = leaderstats and leaderstats:FindFirstChild("StoryStars")
		if not coins or not xp or not level or not storyStars then
			codesEvent:FireClient(player, {
				kind = "Error",
				message = "Stats aren't loaded yet, try again in a moment.",
			})
			return
		end

		coins.Value = PROFILE_LIMITS.coins
		xp.Value = PROFILE_LIMITS.xp
		level.Value = PROFILE_LIMITS.level
		storyStars.Value = PROFILE_LIMITS.storyStars

		local inventory = cosmeticInventory(player)
		for _, cosmetic in Config.Cosmetics do
			inventory.owned[cosmetic.id] = true
		end

		redeemed[normalizedCode] = true
		if not saveProfile(player) then
			redeemed[normalizedCode] = nil
			codesEvent:FireClient(
				player,
				{ kind = "Error", message = "Couldn't save that. Try again." }
			)
			return
		end

		sendSettings(player)
		if sendShopSnapshot then
			sendShopSnapshot(player, "Everything unlocked.")
		end
		codesEvent:FireClient(player, {
			kind = "Success",
			message = "Dev code redeemed: everything unlocked and stats maxed out.",
		})
		return
	end

	codesEvent:FireClient(
		player,
		{ kind = "Error", message = "That code can't be redeemed right now." }
	)
end

local function canAcceptCodeRedemption(player)
	return consumeActionCooldown(lastCodeRequestAt, player, CODE_REDEEM_COOLDOWN_SECONDS)
end

codesEvent.OnServerEvent:Connect(function(player, rawCode)
	if not canAcceptCodeRedemption(player) then
		analytics.throttledCodeRedemptions += 1
		-- Answer rather than dropping it, so the panel's "Checking..." state
		-- still resolves for a player who double-tapped the button.
		codesEvent:FireClient(
			player,
			{ kind = "Error", message = "Slow down for a second, then try again." }
		)
		return
	end

	redeemCode(player, rawCode)
end)

local function currentLifetimeView(player)
	local stats = playerLifetimeStats[player]
	if not stats then
		return nil
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local bestScore = leaderstats and leaderstats:FindFirstChild("BestScore")
	local view = table.clone(stats)
	view.bestScore = bestScore and bestScore.Value or 0
	return view
end

local function publicAchievementsSnapshot(player)
	local lifetimeView = currentLifetimeView(player)
		or table.clone(Achievements.DefaultLifetimeStats)
	local unlocked = playerUnlockedAchievements[player] or {}

	local list = {}
	for _, definition in Achievements.Definitions do
		table.insert(list, {
			id = definition.id,
			stat = definition.stat,
			tier = definition.tier,
			threshold = definition.threshold,
			name = definition.name,
			rewardCoins = definition.rewardCoins,
			unlocked = unlocked[definition.id] == true,
			progress = lifetimeView[definition.stat] or 0,
		})
	end

	return list
end

local function checkAchievements(player)
	local lifetimeView = currentLifetimeView(player)
	if not lifetimeView then
		return
	end

	local unlocked = playerUnlockedAchievements[player] or {}
	playerUnlockedAchievements[player] = unlocked

	local newly = Achievements.newlyUnlocked(lifetimeView, unlocked)
	if #newly == 0 then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	for _, definition in newly do
		unlocked[definition.id] = true
		if coins then
			coins.Value = math.clamp(coins.Value + definition.rewardCoins, 0, PROFILE_LIMITS.coins)
		end
	end

	saveProfile(player)

	for _, definition in newly do
		effectsEvent:FireClient(player, {
			kind = "AchievementUnlocked",
			id = definition.id,
			name = definition.name,
			tier = definition.tier,
			rewardCoins = definition.rewardCoins,
		})
	end
end

local function canAcceptAchievementsAction(player)
	return consumeActionCooldown(
		lastAchievementsRequestAt,
		player,
		ACHIEVEMENTS_ACTION_COOLDOWN_SECONDS
	)
end

achievementsEvent.OnServerEvent:Connect(function(player, action)
	if action ~= "RequestSnapshot" then
		return
	end

	if not canAcceptAchievementsAction(player) then
		-- Dropped rather than answered: a throttled request means one was
		-- already accepted within the cooldown, so a snapshot is on its way.
		analytics.throttledAchievementsRequests += 1
		return
	end

	achievementsEvent:FireClient(player, {
		kind = "Snapshot",
		achievements = publicAchievementsSnapshot(player),
	})
end)

local function grantDeveloperProductReceipt(player, product, receiptKey)
	-- Fulfilling against a pre-load session would write blank coins over the
	-- stored balance. Returning false leaves the receipt unprocessed, so
	-- Roblox retries it once the profile is loaded.
	if not ProfilePersistence.canSave(playerProfileLoadStatus[player]) then
		return false
	end

	local stats = profileStats(player)
	if not stats or not profileStore then
		return false
	end

	-- Same rule as updateProfileWithRetry: assemble outside, reconcile
	-- inside, so nothing in the UpdateAsync transform can yield. The
	-- transform may also run more than once on a write conflict, so the
	-- coin grant is recomputed from the payload each time rather than
	-- accumulated.
	local basePayload = mergedProfilePayload(player, nil, stats)
	local alreadyFulfilled = false
	local nextCoins = nil
	local ok, err = pcall(function()
		profileStore:UpdateAsync(`Player_{player.UserId}`, function(existingProfile)
			local payload = ProfilePersistence.reconcileWithStored(basePayload, existingProfile)
			if payload.fulfilledPurchaseIds[receiptKey] == true then
				alreadyFulfilled = true
				nextCoins = payload.coins
				return payload
			end

			payload.coins =
				math.clamp(payload.coins + (product.coins or 0), 0, PROFILE_LIMITS.coins)
			payload.fulfilledPurchaseIds[receiptKey] = true
			nextCoins = payload.coins
			return payload
		end)
	end)

	if not ok then
		profileSaveFailures += 1
		warn(`[BlockBlast] Failed to fulfill receipt for {player.UserId}: {tostring(err)}`)
		return false
	end

	playerFulfilledPurchaseIds[player] = playerFulfilledPurchaseIds[player] or {}
	playerFulfilledPurchaseIds[player][receiptKey] = true
	processedReceipts[receiptKey] = true
	if nextCoins then
		stats.coins.Value = nextCoins
	end

	return true, alreadyFulfilled
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
	if state.developerTestRun then
		state.finishedAt = state.finishedAt or os.clock()
		state.resultSummary = {
			mode = state.mode,
			outcome = "Developer Test",
			score = state.score,
			linesCleared = state.linesCleared,
			highestCombo = state.highestCombo,
			duration = state.startedAt
					and math.max(0, math.floor(state.finishedAt - state.startedAt))
				or nil,
			coins = 0,
			xp = 0,
			storyStars = 0,
			bestScore = state.startingBestScore or state.bestScore,
			previousBestScore = state.startingBestScore or state.bestScore,
			storyCompleted = false,
			won = false,
			nextUnlockText = "Developer test run - records and rewards disabled.",
		}
		state.message = "Developer test run - no records or rewards"
		return
	end

	if state.mode == "Custom" then
		state.finishedAt = state.finishedAt or os.clock()
		state.resultSummary = {
			mode = state.mode,
			outcome = "Custom Lab",
			score = state.score,
			linesCleared = state.linesCleared,
			highestCombo = state.highestCombo,
			duration = state.startedAt
					and math.max(0, math.floor(state.finishedAt - state.startedAt))
				or nil,
			coins = 0,
			xp = 0,
			storyStars = 0,
			bestScore = state.bestScore,
			previousBestScore = state.startingBestScore or state.bestScore,
			storyCompleted = false,
			won = false,
			nextUnlockText = "Custom Lab does not award progression yet.",
		}
		state.message = "Custom Lab complete - no rewards"
		return
	end

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

	local lifetimeStats = playerLifetimeStats[player]
	if lifetimeStats then
		lifetimeStats.totalRuns += 1
	end
	checkAchievements(player)

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

	local dailyEligible = (winner and state.mode == "Battle") or storyProgressionCompleted
	local today = dailyDateKey()
	local dailyBonusCoins = 0
	local dailyBonusXp = 0
	if dailyEligible and playerDailyRewardDates[player] ~= today then
		dailyBonusCoins = Config.DailyBonusCoins + entitlementDailyBonusCoins(player)
		dailyBonusXp = Config.DailyBonusXp
		earnedCoins += dailyBonusCoins
		earnedXp += dailyBonusXp
		playerDailyRewardDates[player] = today
	end

	local coinMultiplier, xpMultiplier = entitlementRewardMultipliers(player)
	earnedCoins = math.max(0, math.floor(earnedCoins * coinMultiplier))
	earnedXp = math.max(0, math.floor(earnedXp * xpMultiplier))

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
		highestCombo = state.highestCombo,
		duration = state.finishedAt and state.startedAt and math.max(
			0,
			math.floor(state.finishedAt - state.startedAt)
		) or nil,
		coins = earnedCoins,
		xp = earnedXp,
		dailyBonusCoins = dailyBonusCoins,
		dailyBonusXp = dailyBonusXp,
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
	elseif state.mode == "Solo" then
		state.message = `Solo complete: +{earnedCoins} coins +{earnedXp} XP`
		state.resultSummary.outcome = "Solo Complete"
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

	if not consumeActionCooldown(lastPlaceRequestAt, player, PLACE_COOLDOWN_SECONDS) then
		return false, "Cooldown"
	end

	return true, nil
end

local function canAcceptHandAction(player, action, slot)
	if
		(action ~= "Rotate" and action ~= "Reroll")
		or not isWholeNumber(slot)
		or slot < 1
		or slot > Config.InventorySize
	then
		return false, "InvalidPayload"
	end

	if not consumeActionCooldown(lastHandRequestAt, player, HAND_ACTION_COOLDOWN_SECONDS) then
		return false, "Cooldown"
	end

	return true, nil
end

local function canAcceptQueueAction(player)
	return consumeActionCooldown(lastQueueRequestAt, player, QUEUE_ACTION_COOLDOWN_SECONDS)
end

local function canAcceptDeveloperCommand(player)
	if not DeveloperTools.isAuthorizedUserId(player.UserId) then
		return false, "Unauthorized"
	end

	if
		not consumeActionCooldown(
			lastDeveloperCommandAt,
			player,
			Config.DeveloperTools.CommandCooldownSeconds
		)
	then
		return false, "Cooldown"
	end

	return true, nil
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
		comboStreak = state.comboStreak,
		highestCombo = state.highestCombo,
		mode = state.mode,
		customMode = state.mode == "Custom",
		storyMission = state.storyMission,
		storyComplete = state.mode == "Story" and isStoryMissionComplete(state) or false,
		stage = state.mode == "Solo" and StageProgression.publicState(state.stage) or nil,
		developer = {
			enabled = DeveloperTools.isEnabled(),
			authorized = DeveloperTools.isAuthorizedUserId(player.UserId),
			testRun = state.developerTestRun == true,
			recordEligible = state.developerTestRun ~= true,
			diagnostics = DeveloperTools.isAuthorizedUserId(player.UserId)
					and DeveloperTools.diagnostics(state, nil)
				or nil,
			commands = DeveloperTools.isAuthorizedUserId(player.UserId)
					and DeveloperTools.commandList()
				or {},
			shapes = DeveloperTools.isAuthorizedUserId(player.UserId) and DeveloperTools.shapeIds()
				or {},
		},
		resultSummary = state.resultSummary,
		equippedCosmetics = publicEquippedCosmetics(player),
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

local function pruneQueue()
	local removed = false
	for player in queuedPlayers do
		if player.Parent ~= Players or playerModes[player] ~= "Hub" then
			queuedPlayers[player] = nil
			removed = true
		end
	end

	if queueCount() == 0 then
		queueStartedAt = nil
	end

	return removed
end

local function updateHubWorldVisuals()
	if not ExperienceConfig.isModeEnabled("Battle") then
		if HubBuilder.setQueueVisuals then
			HubBuilder.setQueueVisuals(0, BATTLE_MIN_PLAYERS, nil, 0)
		end
		return
	end

	local _, openArenas = arenaCounts()
	local secondsToSoloStart = nil
	if queueStartedAt and queueCount() > 0 then
		secondsToSoloStart =
			math.max(0, math.ceil(SOLO_TEST_SECONDS - (os.clock() - queueStartedAt)))
	end

	if HubBuilder.setQueueVisuals then
		HubBuilder.setQueueVisuals(queueCount(), BATTLE_MIN_PLAYERS, secondsToSoloStart, openArenas)
	end
end

sendHubState = function(player, message)
	pruneQueue()
	updateHubWorldVisuals()
	local secondsToSoloStart = nil
	if queueStartedAt and queuedPlayers[player] then
		secondsToSoloStart =
			math.max(0, math.ceil(SOLO_TEST_SECONDS - (os.clock() - queueStartedAt)))
	end
	local totalArenas, openArenas = arenaCounts()
	local selectedChapter = selectedStoryChapters[player]
	local storyMission = if ExperienceConfig.isModeEnabled("Story")
		then storyMissionForPlayer(player, selectedChapter)
		else nil
	local progress = cosmeticProgress(player)
	local dailyBonusAvailable = false

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
		storyMissions = if ExperienceConfig.isModeEnabled("Story")
			then storyMissionListForPlayer(player)
			else {},
		storyStars = progress.storyStars,
		dailyBonusAvailable = dailyBonusAvailable,
		dailyBonusText = "Solo rewards are based on score and personal bests.",
		profileLoadFailures = profileLoadFailures,
		profileSaveFailures = profileSaveFailures,
		analyticsFlushFailures = analyticsFlushFailures,
		analytics = table.clone(analytics),
		developer = DeveloperTools.publicAccessForPlayer(player),
		serverHighScores = serverHighScoreList(),
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

	local leaderboard = session.mode == "Solo" and serverHighScoreList() or {}

	if session.mode ~= "Solo" then
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
	end

	for _, player in session.players do
		if player.Parent == Players and playerStates[player] then
			stateEvent:FireClient(player, publicState(player), leaderboard)
		end
	end
end

local function giveNewHand(state)
	if state.mode == "Solo" then
		local hand, generation = HandGenerator.generate(state.board, {
			randomizer = state.randomizer,
			count = Config.InventorySize,
			pieceSkin = state.pieceSkin,
			comboStreak = state.comboStreak,
			recentHands = state.recentHands,
			assistance = state.assistance,
			stage = state.stage and state.stage.currentStage or 1,
		})
		state.hand = hand
		state.assistance = generation.assistance
		state.lastHandGeneration = generation
		state.recentHands = HandGenerator.rememberHand(state.recentHands, state.hand)
	else
		state.hand = Blocks.createHand(state.randomizer, Config.InventorySize, state.pieceSkin)
	end
end

local function restoreSoloAssistance(state, stageResult)
	if state.mode ~= "Solo" then
		return
	end

	local restoreAmount, triggers =
		GameplayRules.assistanceRestoreAmount(state.comboStreak, stageResult)
	if restoreAmount > 0 then
		state.assistance = HandGenerator.restoreAssistance(
			state.assistance,
			restoreAmount,
			GameplayRules.describeAssistanceTriggers(triggers)
		)
	end
end

local function teleportTo(part, player)
	if not part or not part.Parent then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
		or character:WaitForChild("HumanoidRootPart", 4)
	if rootPart then
		character:PivotTo(part.CFrame + HUB_SPAWN_OFFSET)
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
	if linesCleared <= 0 or not session or session.mode ~= "Battle" then
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
		recentHands = {},
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
		comboStreak = 0,
		highestCombo = 0,
		stage = mode == "Solo" and StageProgression.newRun() or nil,
		assistance = mode == "Solo" and HandGenerator.newAssistance() or nil,
		lastHandGeneration = nil,
		developerTestRun = false,
		rewardsGranted = false,
		storyMission = mode == "Story" and storyMissionForPlayer(player, storyChapter) or nil,
		alive = true,
		message = nil,
	}

	giveNewHand(state)
	playerStates[player] = state
	updateLeaderstats(player, 0, true)
end

local function startBattle(players, mode, storyChapter)
	mode = mode or "Battle"
	if not ExperienceConfig.isModeEnabled(mode) then
		for _, player in players do
			if player.Parent == Players then
				sendHubState(player, `{mode} is disabled in the current solo-first build`)
			end
		end
		return nil
	end

	local eligiblePlayers = {}
	for _, player in players do
		if
			player.Parent == Players
			and playerModes[player] == "Hub"
			and (
				mode == "Solo"
				or mode == "Story"
				or mode == "Custom"
				or queuedPlayers[player] == true
			)
		then
			table.insert(eligiblePlayers, player)
		end
	end

	if #eligiblePlayers == 0 then
		pruneQueue()
		broadcastHub()
		return nil
	end

	local arena = if mode == "Solo" then nil else findFreeArena()
	if mode ~= "Solo" and not arena then
		return nil
	end

	nextSessionId += 1
	local session = {
		id = nextSessionId,
		mode = mode,
		players = {},
		startedWith = #eligiblePlayers,
		finishScheduled = false,
		startedAt = os.clock(),
		endsAt = if mode == "Solo"
			then nil
			else os.clock() + (mode == "Story" and Config.StoryRoundSeconds or Config.RoundSeconds),
		suddenDeathAnnounced = false,
		nextSuddenDeathPressureAt = nil,
		arena = arena,
	}
	activeSessions[session.id] = session
	if mode == "Solo" then
		analytics.soloSessionsStarted += 1
	elseif mode == "Story" then
		analytics.storySessionsStarted += 1
	elseif mode == "Custom" then
		analytics.customLabSessionsStarted += 1
	else
		analytics.battleSessionsStarted += 1
	end

	for slot, player in eligiblePlayers do
		queuedPlayers[player] = nil
		playerModes[player] = mode
		playerSessions[player] = session
		table.insert(session.players, player)
		createPlayerState(player, mode, storyChapter)
		local state = playerStates[player]
		if state then
			state.startedAt = session.startedAt
		end
		local storyMission = state and state.storyMission
		if mode == "Solo" then
			teleportTo(hubParts.spawn, player)
		else
			teleportToArenaSlot(player, slot, session)
		end
		effectsEvent:FireClient(player, {
			kind = "BattleStart",
			message = mode == "Solo" and "Solo puzzle started!"
				or mode == "Story" and storyChapterTitle(storyMission)
				or mode == "Custom" and "Custom Lab started!"
				or #eligiblePlayers >= BATTLE_MIN_PLAYERS and "Battle started!"
				or "Solo test started!",
			detail = mode == "Solo" and "Place pieces, clear lines, and beat your best score."
				or mode == "Story" and storyMission and storyMission.intro
				or mode == "Custom" and "Rotate or reroll pieces before placing them."
				or nil,
		})
	end

	if queueCount() == 0 then
		queueStartedAt = nil
	else
		queueStartedAt = os.clock()
	end

	broadcastHub(
		mode == "Solo" and "Solo puzzle started"
			or mode == "Story" and "Story training started"
			or mode == "Custom" and "Custom Lab started"
			or "Battle started"
	)
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
	if not ExperienceConfig.isModeEnabled("Battle") then
		return
	end

	pruneQueue()
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
	if not ExperienceConfig.isModeEnabled("Battle") then
		sendHubState(player, "Battle is disabled while the game focuses on solo puzzle play")
		return
	end

	if
		playerModes[player] == "Battle"
		or playerModes[player] == "Story"
		or playerModes[player] == "Custom"
		or playerModes[player] == "Solo"
	then
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

leaveBattleQueue = function(player)
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
	if not ExperienceConfig.isModeEnabled("Story") then
		sendHubState(player, "Story is disabled while the game focuses on solo puzzle play")
		return
	end

	if
		playerModes[player] == "Battle"
		or playerModes[player] == "Story"
		or playerModes[player] == "Custom"
		or playerModes[player] == "Solo"
	then
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

local function startCustomLab(player)
	if not ExperienceConfig.isModeEnabled("Custom") then
		sendHubState(player, "Custom Lab is disabled in the current solo-first build")
		return
	end

	if
		playerModes[player] == "Battle"
		or playerModes[player] == "Story"
		or playerModes[player] == "Custom"
		or playerModes[player] == "Solo"
	then
		sendHubState(player, "Finish your current run first")
		return
	end

	if not findFreeArena() then
		sendHubState(player, "Arena is busy - try Custom Lab again after this match")
		return
	end

	startBattle({ player }, "Custom")
end

local function startSoloRun(player)
	if
		playerModes[player] == "Battle"
		or playerModes[player] == "Story"
		or playerModes[player] == "Custom"
		or playerModes[player] == "Solo"
	then
		sendHubState(player, "Finish your current run first")
		return
	end

	startBattle({ player }, "Solo")
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

	startSoloRun(player)
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

		state.finishedAt = os.clock()
		grantBattleRewards(player, state, player == winner)
		if not state.developerTestRun then
			saveProfile(player)
		end
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
			state.finishedAt = state.finishedAt or os.clock()
			grantBattleRewards(player, state, false)
			if not state.resultShown then
				fireResult(player, state, false)
			end
		else
			state.rewardsGranted = true
			state.message = "Run forfeited - no rewards"
			state.finishedAt = os.clock()
			state.resultSummary = {
				mode = state.mode,
				outcome = "Forfeit",
				score = state.score,
				linesCleared = state.linesCleared,
				highestCombo = state.highestCombo,
				duration = state.startedAt
						and math.max(0, math.floor(state.finishedAt - state.startedAt))
					or nil,
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
	if not (state and state.developerTestRun) then
		saveProfile(player)
	end
	playerStates[player] = nil
	playerSessions[player] = nil
	queuedPlayers[player] = nil
	selectedStoryChapters[player] = nil
	playerModes[player] = "Hub"

	if session then
		local stateScore = state and state.score or nil
		if stateScore and not (state and state.developerTestRun) then
			updateLeaderstats(player, stateScore, true)
		end
		if session.mode == "Solo" then
			analytics.soloSessionsFinished += 1
		end
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
	if linesCleared > 0 then
		state.comboStreak += 1
		state.highestCombo = math.max(state.highestCombo, state.comboStreak)
		if state.comboStreak > 1 then
			analytics.combosTriggered += 1
		end
	else
		state.comboStreak = 0
	end
	local scoreDelta, comboBonus, multiLineBonus =
		GameplayRules.scoreForPlacement(cellsPlaced, linesCleared, state.comboStreak)
	local stageResult = nil
	if state.mode == "Solo" then
		state.stage, stageResult = StageProgression.applyPlacement(state.stage, state.board, {
			linesCleared = linesCleared,
			comboStreak = state.comboStreak,
		})
		restoreSoloAssistance(state, stageResult)
	end
	analytics.placements += 1
	analytics.linesCleared += linesCleared
	effectsEvent:FireClient(player, {
		kind = "Place",
		originX = x,
		originY = y,
		shape = shape,
		linesCleared = linesCleared,
		lineClearEffect = publicEquippedCosmetics(player).lineClearEffect,
		comboStreak = state.comboStreak,
		comboBonus = comboBonus,
		multiLineBonus = multiLineBonus,
		scoreDelta = scoreDelta,
		stageProgressGained = stageResult and stageResult.progressGained or nil,
		perfectClear = stageResult and stageResult.perfectClear or nil,
	})
	if stageResult and stageResult.stagesAdvanced > 0 then
		effectsEvent:FireClient(player, {
			kind = "StageUp",
			currentStage = stageResult.currentStage,
			stagesAdvanced = stageResult.stagesAdvanced,
			stageProgress = stageResult.stageProgress,
			stageProgressRequired = stageResult.stageProgressRequired,
			perfectClear = stageResult.perfectClear,
		})
	end
	state.score += scoreDelta
	state.linesCleared += linesCleared
	if not state.developerTestRun and state.score > state.bestScore then
		state.bestScore = state.score
	end
	if not state.developerTestRun then
		updateLeaderstats(player, state.score, true)

		local lifetimeStats = playerLifetimeStats[player]
		if lifetimeStats then
			lifetimeStats.highestCombo = math.max(lifetimeStats.highestCombo, state.comboStreak)
			lifetimeStats.totalLinesCleared += linesCleared
			lifetimeStats.totalBlocksPlaced += cellsPlaced
			if stageResult and stageResult.perfectClear then
				lifetimeStats.totalPerfectClears += 1
			end
			if stageResult and stageResult.currentStage then
				lifetimeStats.highestStage =
					math.max(lifetimeStats.highestStage, stageResult.currentStage)
			end
		end
		checkAchievements(player)
	end

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

handEvent.OnServerEvent:Connect(function(player, action, slot)
	local canRequest, rejectReason = canAcceptHandAction(player, action, slot)
	if not canRequest then
		if rejectReason == "Cooldown" then
			analytics.throttledHandRequests += 1
		else
			analytics.rejectedHandRequests += 1
		end
		return
	end

	local state = playerStates[player]
	local session = playerSessions[player]
	if not state or not session or not state.alive or state.mode ~= "Custom" then
		analytics.rejectedHandRequests += 1
		return
	end

	local shape = state.hand[slot]
	if not shape then
		analytics.rejectedHandRequests += 1
		return
	end

	if action == "Rotate" then
		local rotated = Blocks.rotateShape(shape)
		if not rotated then
			analytics.rejectedHandRequests += 1
			return
		end
		state.hand[slot] = rotated
		analytics.customLabHandRotations += 1
	else
		state.hand[slot] = Blocks.getRandomShape(state.randomizer, state.pieceSkin)
		analytics.customLabHandRerolls += 1
	end

	state.alive = Grid.hasAnyMove(state.board, state.hand)
	effectsEvent:FireClient(player, {
		kind = "HandUpdated",
		action = action,
		slot = slot,
		message = action == "Rotate" and `Piece {slot} rotated` or `Piece {slot} rerolled`,
	})
	broadcast(session)
end)

devCommandFunction.OnServerInvoke = function(player, command)
	local canRequest, rejectReason = canAcceptDeveloperCommand(player)
	if not canRequest then
		return {
			ok = false,
			message = rejectReason or "Developer tools unavailable",
			access = DeveloperTools.publicAccessForPlayer(player),
		}
	end

	local state = playerStates[player]
	local session = playerSessions[player]
	if not state or not session or state.mode ~= "Solo" then
		return {
			ok = false,
			message = "Start a Solo run first",
			access = DeveloperTools.publicAccessForPlayer(player),
		}
	end

	local ok, message, alteredGameplay = DeveloperTools.applyCommand(state, command)
	if ok and alteredGameplay then
		effectsEvent:FireClient(player, {
			kind = "DeveloperCommand",
			message = message,
		})
		scheduleReturnIfEliminated(player, state)
		broadcast(session)
	end

	return {
		ok = ok,
		message = message,
		access = DeveloperTools.publicAccessForPlayer(player),
		developer = publicState(player).developer,
		diagnostics = DeveloperTools.diagnostics(
			state,
			typeof(command) == "table" and command.visibleBoardCells or nil
		),
	}
end

queueEvent.OnServerEvent:Connect(function(player, mode, requestedChapter)
	if not canAcceptQueueAction(player) then
		return
	end

	if mode == "Solo" then
		startSoloRun(player)
	elseif mode == "Battle" then
		joinBattleQueue(player)
	elseif mode == "LeaveQueue" then
		leaveBattleQueue(player)
	elseif mode == "LeaveBattle" then
		leaveBattle(player)
	elseif mode == "PlayAgain" then
		playAgainBattle(player)
	elseif mode == "Story" then
		startStoryMode(player, requestedChapter)
	elseif mode == "CustomLab" then
		startCustomLab(player)
	end
end)

shopEvent.OnServerEvent:Connect(function(player, action, payload)
	if action == "Track" and typeof(payload) == "table" then
		trackShopAnalytics(payload.event)
		return
	end

	if not canAcceptShopAction(player) then
		analytics.shopPromptRejected += 1
		return
	end

	if action == "RequestSnapshot" then
		analytics.shopSnapshotsRequested += 1
		sendShopSnapshot(player)
		return
	end

	if action == "PurchaseCosmetic" and typeof(payload) == "table" then
		analytics.cosmeticPurchaseAttempts += 1
		purchaseCosmetic(player, payload.id)
		return
	end

	if action == "EquipCosmetic" and typeof(payload) == "table" then
		equipCosmetic(player, payload.id)
		return
	end

	if action ~= "RequestPrompt" or typeof(payload) ~= "table" then
		analytics.shopPromptRejected += 1
		return
	end

	local itemType = payload.itemType
	local itemId = payload.id
	local definition = findPurchasableDefinition(itemType, itemId)
	if not definition then
		analytics.shopPromptRejected += 1
		shopEvent:FireClient(player, {
			kind = "Error",
			message = "That shop item is unavailable.",
		})
		return
	end

	local marketplaceId = itemType == "GamePass" and definition.gamePassId or definition.productId
	if marketplaceId == Config.Monetization.PlaceholderId then
		analytics.shopPromptRejected += 1
		sendShopSnapshot(player, "Creator Dashboard ID required before this can be purchased.")
		return
	end

	if purchasePromptLocks[player] then
		analytics.shopPromptRejected += 1
		shopEvent:FireClient(player, {
			kind = "Error",
			message = "Finish the current purchase prompt first.",
		})
		return
	end

	if itemType == "GamePass" then
		local owned = refreshGamePassOwnership(player, definition, true)
		if owned then
			sendShopSnapshot(player, "Already owned.")
			return
		end
	end

	analytics.shopPromptRequests += 1
	if itemType == "GamePass" then
		analytics.gamePassPromptOpened += 1
	end
	purchasePromptLocks[player] = {
		itemType = itemType,
		id = itemId,
		marketplaceId = marketplaceId,
	}
	shopEvent:FireClient(player, {
		kind = "PromptApproved",
		itemType = itemType,
		id = itemId,
		marketplaceId = marketplaceId,
	})
	sendShopSnapshot(player, "Opening purchase prompt...", itemId)
end)

MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, wasPurchased)
	local lock = purchasePromptLocks[player]
	if lock and lock.itemType == "GamePass" and lock.marketplaceId == gamePassId then
		purchasePromptLocks[player] = nil
	end

	local pass = Config.getGamePassByMarketplaceId(gamePassId)
	if not pass then
		return
	end

	if wasPurchased then
		analytics.shopPromptCompleted += 1
		refreshGamePassOwnership(player, pass, true)
		sendShopSnapshot(player, `{pass.name} unlocked.`)
	else
		analytics.shopPromptCancelled += 1
		sendShopSnapshot(player, "Purchase cancelled.")
	end
end)

MarketplaceService.PromptProductPurchaseFinished:Connect(function(userId, productId, wasPurchased)
	local player = Players:GetPlayerByUserId(userId)
	if not player then
		return
	end

	local lock = purchasePromptLocks[player]
	if lock and lock.itemType == "DeveloperProduct" and lock.marketplaceId == productId then
		purchasePromptLocks[player] = nil
	end

	if not wasPurchased then
		analytics.shopPromptCancelled += 1
		sendShopSnapshot(player, "Purchase cancelled.")
	end
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local product = Config.getDeveloperProductByMarketplaceId(receiptInfo.ProductId)
	if not product then
		analytics.developerProductReceiptsRetried += 1
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local receiptKey = `Receipt_{receiptInfo.PurchaseId}`
	if processedReceipts[receiptKey] then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local granted, alreadyFulfilled = grantDeveloperProductReceipt(player, product, receiptKey)
	if not granted then
		analytics.developerProductReceiptsRetried += 1
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	analytics.shopPromptCompleted += 1
	if not alreadyFulfilled then
		analytics.developerProductReceiptsGranted += 1
		sendShopSnapshot(player, `{product.name} added.`)
	else
		sendShopSnapshot(player, `{product.name} already fulfilled.`)
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

settingsEvent.OnServerEvent:Connect(function(player, action, nextSettings)
	if action == "Request" then
		-- The client's own startup handshake, so its remote handlers are
		-- connected by now. A load failure detected before this point was
		-- held back rather than fired into the void.
		local notice = playerProfileNoticeState[player]
		if notice then
			notice.clientReady = true
		end
		sendSettings(player)
		notifyProfileLoadFailure(player)
		return
	end

	if action ~= "Update" then
		return
	end

	playerSettings[player] = sanitizeSettings(nextSettings, cosmeticProgress(player), player)
	sendSettings(player)
	scheduleSettingsSave(player)
end)

if hubParts.soloPrompt then
	hubParts.soloPrompt.Triggered:Connect(startSoloRun)
end

if hubParts.battlePrompt and ExperienceConfig.isModeEnabled("Battle") then
	hubParts.battlePrompt.Triggered:Connect(joinBattleQueue)
end

if hubParts.storyPrompt and ExperienceConfig.isModeEnabled("Story") then
	hubParts.storyPrompt.Triggered:Connect(function(player)
		startStoryMode(player)
	end)
end

for _, arena in (hubParts.arenas or {}) do
	if not arena.returnPad then
		continue
	end
	local returnPrompt = Instance.new("ProximityPrompt")
	returnPrompt.ActionText = "Return"
	returnPrompt.ObjectText = "Hub"
	returnPrompt.HoldDuration = 0.2
	returnPrompt.MaxActivationDistance = 12
	returnPrompt.RequiresLineOfSight = false
	returnPrompt.Parent = arena.returnPad
	returnPrompt.Triggered:Connect(leaveBattle)
end

local function attachHubSpawnSafety(player)
	if playerSpawnConnections[player] then
		return
	end

	playerSpawnConnections[player] = player.CharacterAdded:Connect(function(character)
		if playerCharacterConnections[player] then
			playerCharacterConnections[player]:Disconnect()
			playerCharacterConnections[player] = nil
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
			or character:WaitForChild("Humanoid", 4)
		if humanoid then
			playerCharacterConnections[player] = humanoid.Died:Connect(function()
				if queuedPlayers[player] and leaveBattleQueue then
					leaveBattleQueue(player)
					return
				end

				if
					playerModes[player] == "Battle"
					or playerModes[player] == "Story"
					or playerModes[player] == "Custom"
					or playerModes[player] == "Solo"
				then
					task.delay(0.25, function()
						if player.Parent == Players and playerStates[player] then
							leaveBattle(player)
						end
					end)
				end
			end)
		end

		if
			playerModes[player] == "Battle"
			or playerModes[player] == "Story"
			or playerModes[player] == "Custom"
			or playerModes[player] == "Solo"
		then
			return
		end

		teleportTo(hubParts.spawn, player)
	end)
end

local function initializePlayer(player)
	attachHubSpawnSafety(player)
	playerSettings[player] = table.clone(DEFAULT_SETTINGS)
	playerDailyRewardDates[player] = nil
	playerFulfilledPurchaseIds[player] = {}
	createLeaderstats(player)
	playerCosmeticInventories[player] =
		sanitizeCosmeticInventory(player, nil, cosmeticProgress(player), playerSettings[player])
	applyEquippedCosmeticsToSettings(player)
	playerModes[player] = "Hub"
	stateEvent:FireClient(player, nil, {})
	sendHubState(player, ExperienceConfig.Solo.WelcomeMessage)
	sendSettings(player)
	sendShopSnapshot(player)

	if player.Character then
		teleportTo(hubParts.spawn, player)
	else
		player:LoadCharacter()
	end
end

Players.PlayerAdded:Connect(initializePlayer)

Players.PlayerRemoving:Connect(function(player)
	local removingState = playerStates[player]
	if not (removingState and removingState.developerTestRun) then
		saveProfileBeforeExit(player)
	end
	local session = playerSessions[player]
	if queuedPlayers[player] then
		analytics.queueLeaves += 1
	end
	playerStates[player] = nil
	if playerSpawnConnections[player] then
		playerSpawnConnections[player]:Disconnect()
		playerSpawnConnections[player] = nil
	end
	if playerCharacterConnections[player] then
		playerCharacterConnections[player]:Disconnect()
		playerCharacterConnections[player] = nil
	end
	playerSessions[player] = nil
	queuedPlayers[player] = nil
	if queueCount() == 0 then
		queueStartedAt = nil
	end
	selectedStoryChapters[player] = nil
	playerModes[player] = nil
	serverHighScores[player.UserId] = nil
	playerSettings[player] = nil
	playerDailyRewardDates[player] = nil
	playerEntitlements[player] = nil
	playerFulfilledPurchaseIds[player] = nil
	playerRedeemedCodes[player] = nil
	playerLifetimeStats[player] = nil
	playerUnlockedAchievements[player] = nil
	playerCosmeticInventories[player] = nil
	playerProfileLoadStatus[player] = nil
	playerProfileNoticeState[player] = nil
	lastPlaceRequestAt[player] = nil
	lastHandRequestAt[player] = nil
	lastQueueRequestAt[player] = nil
	lastDeveloperCommandAt[player] = nil
	lastShopRequestAt[player] = nil
	lastCodeRequestAt[player] = nil
	lastAchievementsRequestAt[player] = nil
	purchasePromptLocks[player] = nil
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
	-- Run the saves concurrently: each one may wait on an in-flight profile
	-- load, and doing that serially could exhaust the shutdown budget with
	-- a full server.
	local pendingSaves = 0

	-- Whatever this server counted since the last interval would otherwise be
	-- discarded, which is the exact loss this persistence exists to stop.
	pendingSaves += 1
	task.spawn(function()
		flushAnalytics()
		pendingSaves -= 1
	end)

	for _, player in Players:GetPlayers() do
		local state = playerStates[player]
		if not (state and state.developerTestRun) then
			pendingSaves += 1
			task.spawn(function()
				saveProfileBeforeExit(player)
				pendingSaves -= 1
			end)
		end
	end

	-- Bounded so a stuck DataStore cannot hold the shutdown open past the
	-- 30 seconds Roblox allows.
	local deadline = os.clock() + PROFILE_LOAD_WAIT_SECONDS + 12
	while pendingSaves > 0 and os.clock() < deadline do
		task.wait(0.1)
	end
end)

for _, player in Players:GetPlayers() do
	if not playerModes[player] then
		initializePlayer(player)
	end
end

task.spawn(function()
	while true do
		task.wait(Telemetry.FlushIntervalSeconds)
		flushAnalytics()
	end
end)

task.spawn(function()
	while true do
		task.wait(1)
		if ExperienceConfig.isModeEnabled("Battle") then
			tryStartBattle()
		end
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
