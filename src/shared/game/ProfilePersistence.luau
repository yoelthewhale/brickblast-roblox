-- Pure sequencing rules for DataStore profile persistence.
--
-- The server loads a player's profile asynchronously and does not block
-- their join on it. Everything in-memory (coins, cosmetics, the receipt
-- ledger) starts blank and is only filled in once that load resolves, so a
-- save that runs before it would overwrite the real saved profile with
-- defaults. These helpers decide when a save is allowed and how
-- append-only ledgers merge, kept here so the rules are testable outside
-- Studio (GameServer.server.luau cannot be loaded by the Lune runner).

local ProfilePersistence = {}

-- Lifecycle of a player's profile load.
--   Pending: GetAsync is still in flight, in-memory state is not real yet.
--   Loaded:  the load resolved (including "no saved profile" for a new
--            player), so in-memory state is authoritative and safe to write.
--   Failed:  the load could not be read. In-memory state is blank but the
--            DataStore may hold real data, so this session must never write.
ProfilePersistence.LoadStatus = {
	Pending = "Pending",
	Loaded = "Loaded",
	Failed = "Failed",
}

-- The schema version stamped onto every saved profile.
ProfilePersistence.Version = 2

-- Transforms keyed by the version they upgrade *from*: MIGRATIONS[n] takes a
-- profile at version n and returns it at n + 1.
--
-- Empty today, and that is the point. Version 2 only added fields, which the
-- per-field sanitizers already tolerate, so nothing needs transforming yet.
-- What was missing was anywhere for the first migration to live: the version
-- was written on every save and read nowhere, so a future change to what a
-- field *means* would have silently misread old profiles instead of upgrading
-- them.
local MIGRATIONS = {}

-- Profiles saved before versioning existed carry no version field. They are
-- version 1 by definition, not corrupt.
local FIRST_VERSION = 1

function ProfilePersistence.profileVersion(profile)
	if typeof(profile) ~= "table" then
		return nil
	end

	local version = profile.version
	if typeof(version) ~= "number" or version ~= version or version < FIRST_VERSION then
		return FIRST_VERSION
	end

	return math.floor(version)
end

-- Bring a loaded profile up to the current schema.
--
-- Returns status, profile, fromVersion:
--   "empty"    nothing stored yet; a new player, nothing to migrate
--   "current"  already at ProfilePersistence.Version
--   "migrated" upgraded; the returned table is the one to use
--   "future"   written by a NEWER build than this server
--
-- "future" is the case worth being careful about. It happens when a server is
-- rolled back and meets a profile saved by the newer build. This server cannot
-- know what those fields mean, so the only safe answer is to refuse: the
-- caller should treat it exactly like a failed load, leaving the session
-- read-only rather than overwriting data it does not understand.
function ProfilePersistence.migrate(profile)
	if typeof(profile) ~= "table" then
		return "empty", profile, nil
	end

	local fromVersion = ProfilePersistence.profileVersion(profile)

	if fromVersion > ProfilePersistence.Version then
		return "future", profile, fromVersion
	end

	if fromVersion == ProfilePersistence.Version then
		return "current", profile, fromVersion
	end

	local migrated = profile
	for version = fromVersion, ProfilePersistence.Version - 1 do
		local transform = MIGRATIONS[version]
		if transform then
			migrated = transform(migrated)
		end
	end

	migrated.version = ProfilePersistence.Version
	return "migrated", migrated, fromVersion
end

-- What a save attempt should do right now.
--   "save": in-memory state is trustworthy, write it.
--   "wait": the load is still in flight and there is time budget left.
--   "skip": writing would risk clobbering real saved data.
function ProfilePersistence.saveDecision(status, elapsedSeconds, timeoutSeconds)
	if status == ProfilePersistence.LoadStatus.Loaded then
		return "save"
	end

	if status ~= ProfilePersistence.LoadStatus.Pending then
		-- Failed, or a player with no tracked load at all.
		return "skip"
	end

	local elapsed = typeof(elapsedSeconds) == "number" and elapsedSeconds or 0
	local timeout = typeof(timeoutSeconds) == "number" and timeoutSeconds or 0
	if elapsed < timeout then
		return "wait"
	end

	return "skip"
end

function ProfilePersistence.canSave(status)
	return status == ProfilePersistence.LoadStatus.Loaded
end

-- Union of two append-only boolean sets (fulfilled receipt ids, redeemed
-- codes). These only ever gain entries, so taking the union means a save
-- can never drop an entry that exists in the stored profile -- even if the
-- in-memory copy is incomplete.
function ProfilePersistence.mergeAppendOnlySet(inMemory, existing)
	local merged = {}

	if typeof(existing) == "table" then
		for key, value in existing do
			if value == true then
				merged[key] = true
			end
		end
	end

	if typeof(inMemory) == "table" then
		for key, value in inMemory do
			if value == true then
				merged[key] = true
			end
		end
	end

	return merged
end

-- Whether the "we could not read your save" notice should be sent right now.
--
-- `notice` is the player's notice bookkeeping: `clientReady` becomes true once
-- the client has asked the server for its initial state, and `sent` records
-- that the notice already went out. Both matter -- the notice fires at most
-- once per session, and never before the client is listening, because a
-- FireClient that lands before the client connects its handlers is silently
-- dropped and the player would never hear about it.
function ProfilePersistence.shouldNotifyLoadFailure(status, notice)
	if status ~= ProfilePersistence.LoadStatus.Failed then
		return false
	end

	if typeof(notice) ~= "table" then
		return false
	end

	return notice.clientReady == true and notice.sent ~= true
end

-- Reconcile an already-built save payload against whatever is currently
-- stored, producing the value to write.
--
-- This is deliberately pure and allocation-only: it runs inside a DataStore
-- UpdateAsync transform, which must never yield, and which the DataStore may
-- call more than once if another writer wins a race. Building the payload
-- itself (cosmetics, entitlements, settings) can yield, so that happens
-- before the transform and only this reconcile runs inside it.
function ProfilePersistence.reconcileWithStored(payload, existingProfile)
	local reconciled = table.clone(payload)

	if typeof(existingProfile) ~= "table" then
		reconciled.fulfilledPurchaseIds =
			ProfilePersistence.mergeAppendOnlySet(payload.fulfilledPurchaseIds, nil)
		reconciled.redeemedCodes = ProfilePersistence.mergeAppendOnlySet(payload.redeemedCodes, nil)
		return reconciled
	end

	reconciled.fulfilledPurchaseIds = ProfilePersistence.mergeAppendOnlySet(
		payload.fulfilledPurchaseIds,
		existingProfile.fulfilledPurchaseIds
	)
	reconciled.redeemedCodes =
		ProfilePersistence.mergeAppendOnlySet(payload.redeemedCodes, existingProfile.redeemedCodes)

	return reconciled
end

return ProfilePersistence
