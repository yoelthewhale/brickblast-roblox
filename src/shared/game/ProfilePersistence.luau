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
