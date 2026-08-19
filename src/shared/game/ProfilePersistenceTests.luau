local ProfilePersistence = require(script.Parent.ProfilePersistence)

local ProfilePersistenceTests = {}

local LoadStatus = ProfilePersistence.LoadStatus

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local tests = {}

tests.aProfileAtTheCurrentVersionNeedsNoMigration = function()
	local profile = { version = ProfilePersistence.Version, coins = 100 }
	local status, migrated, fromVersion = ProfilePersistence.migrate(profile)

	assertCondition(status == "current", `Expected "current", got "{status}"`)
	assertCondition(migrated.coins == 100, "The profile passes through untouched")
	assertCondition(fromVersion == ProfilePersistence.Version, "Reports the version it was at")
end

tests.anUnversionedProfileIsTreatedAsTheFirstVersion = function()
	-- Saves written before versioning existed carry no version field. They are
	-- old, not corrupt, and must migrate rather than being refused.
	local status, migrated, fromVersion = ProfilePersistence.migrate({ coins = 50 })

	assertCondition(status == "migrated", `Expected "migrated", got "{status}"`)
	assertCondition(fromVersion == 1, "An absent version means version 1")
	assertCondition(migrated.coins == 50, "Existing fields survive the migration")
	assertCondition(
		migrated.version == ProfilePersistence.Version,
		"A migrated profile is stamped with the current version"
	)
end

tests.aGarbledVersionIsTreatedAsTheFirstVersion = function()
	for _, version in { "2", {}, 0 / 0, -5, 0 } do
		local profile = { version = version, coins = 7 }
		local status, migrated = ProfilePersistence.migrate(profile)

		assertCondition(
			status == "migrated",
			`An unusable version should migrate rather than be trusted (got "{status}")`
		)
		assertCondition(migrated.coins == 7, "Existing fields survive")
	end
end

tests.aProfileFromANewerBuildIsRefused = function()
	-- The rollback case. This server cannot know what a newer build's fields
	-- mean, so it must not load them and must not save over them.
	local profile = { version = ProfilePersistence.Version + 1, coins = 999 }
	local status, returned, fromVersion = ProfilePersistence.migrate(profile)

	assertCondition(status == "future", `Expected "future", got "{status}"`)
	assertCondition(fromVersion == ProfilePersistence.Version + 1, "Reports the version it found")
	assertCondition(returned.coins == 999, "The stored profile is handed back unmodified")
	assertCondition(
		returned.version == ProfilePersistence.Version + 1,
		"A refused profile is never restamped with this server's version"
	)
end

tests.aRefusedProfileCannotBeSaved = function()
	-- The whole point of refusing: the caller marks the load Failed, and a
	-- Failed load is not allowed to write.
	assertCondition(
		not ProfilePersistence.canSave(LoadStatus.Failed),
		"A refused profile's session must stay read-only"
	)
end

tests.anAbsentProfileIsNotAMigration = function()
	local status = ProfilePersistence.migrate(nil)
	assertCondition(status == "empty", `A new player has nothing to migrate (got "{status}")`)

	status = ProfilePersistence.migrate("not a table")
	assertCondition(status == "empty", "A non-table stored value is treated as empty")
end

tests.profileVersionReadsWhatWasStamped = function()
	assertCondition(ProfilePersistence.profileVersion(nil) == nil, "No profile has no version")
	assertCondition(ProfilePersistence.profileVersion({}) == 1, "An unstamped profile is version 1")
	assertCondition(
		ProfilePersistence.profileVersion({ version = 2 }) == 2,
		"A stamped version is read back"
	)
	assertCondition(
		ProfilePersistence.profileVersion({ version = 2.9 }) == 2,
		"A fractional version floors rather than being rejected"
	)
end

tests.loadedProfilesMaySave = function()
	assertCondition(ProfilePersistence.canSave(LoadStatus.Loaded), "Loaded profiles may save")
	assertCondition(
		ProfilePersistence.saveDecision(LoadStatus.Loaded, 0, 5) == "save",
		"Loaded profiles save immediately"
	)
end

tests.pendingProfilesWaitThenSkip = function()
	assertCondition(
		not ProfilePersistence.canSave(LoadStatus.Pending),
		"Pending profiles must not save"
	)
	assertCondition(
		ProfilePersistence.saveDecision(LoadStatus.Pending, 0, 5) == "wait",
		"Pending profiles wait while budget remains"
	)
	assertCondition(
		ProfilePersistence.saveDecision(LoadStatus.Pending, 4.9, 5) == "wait",
		"Pending profiles keep waiting just under the timeout"
	)
	assertCondition(
		ProfilePersistence.saveDecision(LoadStatus.Pending, 5, 5) == "skip",
		"Pending profiles skip once the wait budget is spent"
	)
	assertCondition(
		ProfilePersistence.saveDecision(LoadStatus.Pending, 0, 0) == "skip",
		"A zero wait budget skips instead of saving"
	)
end

tests.failedLoadsNeverSave = function()
	assertCondition(not ProfilePersistence.canSave(LoadStatus.Failed), "Failed loads must not save")
	assertCondition(
		ProfilePersistence.saveDecision(LoadStatus.Failed, 0, 30) == "skip",
		"Failed loads skip regardless of the wait budget"
	)
end

tests.untrackedPlayersNeverSave = function()
	assertCondition(not ProfilePersistence.canSave(nil), "An untracked player must not save")
	assertCondition(
		ProfilePersistence.saveDecision(nil, 0, 30) == "skip",
		"An untracked player skips instead of waiting"
	)
	assertCondition(
		ProfilePersistence.saveDecision("Bogus", 0, 30) == "skip",
		"An unknown status skips instead of saving"
	)
end

tests.appendOnlySetsUnionBothSides = function()
	local merged = ProfilePersistence.mergeAppendOnlySet({ a = true }, { b = true })
	assertCondition(merged.a == true, "In-memory entries survive the merge")
	assertCondition(merged.b == true, "Stored entries survive the merge")
end

tests.appendOnlySetsKeepStoredEntriesWhenMemoryIsBlank = function()
	-- The exact save/load race this guards: in-memory receipt ledger is
	-- empty because the load never resolved, stored ledger is real.
	local merged = ProfilePersistence.mergeAppendOnlySet({}, { receipt1 = true })
	assertCondition(merged.receipt1 == true, "A blank in-memory ledger must not drop receipts")

	merged = ProfilePersistence.mergeAppendOnlySet(nil, { receipt1 = true })
	assertCondition(merged.receipt1 == true, "A missing in-memory ledger must not drop receipts")
end

tests.appendOnlySetsIgnoreNonTrueValues = function()
	local merged = ProfilePersistence.mergeAppendOnlySet(
		{ falsey = false, texty = "yes" },
		{ nested = {}, real = true }
	)
	assertCondition(merged.falsey == nil, "False entries are not carried over")
	assertCondition(merged.texty == nil, "Non-boolean entries are not carried over")
	assertCondition(merged.nested == nil, "Table entries are not carried over")
	assertCondition(merged.real == true, "True entries are carried over")
end

tests.mergeReturnsAFreshTable = function()
	local inMemory = { a = true }
	local existing = { b = true }
	local merged = ProfilePersistence.mergeAppendOnlySet(inMemory, existing)
	merged.c = true

	assertCondition(inMemory.c == nil, "Merging must not mutate the in-memory set")
	assertCondition(existing.c == nil, "Merging must not mutate the stored set")
	assertCondition(inMemory.b == nil, "Merging must not write back into the in-memory set")
end

tests.loadFailureNoticeWaitsForTheClient = function()
	assertCondition(
		not ProfilePersistence.shouldNotifyLoadFailure(
			LoadStatus.Failed,
			{ clientReady = false, sent = false }
		),
		"The notice must not fire before the client is listening"
	)
	assertCondition(
		ProfilePersistence.shouldNotifyLoadFailure(
			LoadStatus.Failed,
			{ clientReady = true, sent = false }
		),
		"The notice fires once the client is ready"
	)
end

tests.loadFailureNoticeFiresOnlyOnce = function()
	assertCondition(
		not ProfilePersistence.shouldNotifyLoadFailure(
			LoadStatus.Failed,
			{ clientReady = true, sent = true }
		),
		"The notice must not repeat once sent"
	)
end

tests.loadFailureNoticeOnlyAppliesToFailedLoads = function()
	local ready = { clientReady = true, sent = false }
	assertCondition(
		not ProfilePersistence.shouldNotifyLoadFailure(LoadStatus.Loaded, ready),
		"A successful load produces no notice"
	)
	assertCondition(
		not ProfilePersistence.shouldNotifyLoadFailure(LoadStatus.Pending, ready),
		"A load still in flight produces no notice"
	)
	assertCondition(
		not ProfilePersistence.shouldNotifyLoadFailure(LoadStatus.Failed, nil),
		"An untracked player produces no notice"
	)
end

tests.reconcileKeepsStoredReceiptsAndCodes = function()
	local payload = {
		coins = 500,
		fulfilledPurchaseIds = {},
		redeemedCodes = {},
	}
	local stored = {
		coins = 900,
		fulfilledPurchaseIds = { receipt1 = true },
		redeemedCodes = { launch = true },
	}

	local reconciled = ProfilePersistence.reconcileWithStored(payload, stored)
	assertCondition(reconciled.fulfilledPurchaseIds.receipt1 == true, "Stored receipts survive")
	assertCondition(reconciled.redeemedCodes.launch == true, "Stored redeemed codes survive")
	assertCondition(reconciled.coins == 500, "Session stats still come from the payload")
end

tests.reconcileHandlesAMissingStoredProfile = function()
	local payload = {
		coins = 10,
		fulfilledPurchaseIds = { receipt1 = true },
		redeemedCodes = { launch = true },
	}

	local reconciled = ProfilePersistence.reconcileWithStored(payload, nil)
	assertCondition(reconciled.coins == 10, "A new player keeps their payload values")
	assertCondition(reconciled.fulfilledPurchaseIds.receipt1 == true, "Receipts are carried over")
	assertCondition(reconciled.redeemedCodes.launch == true, "Redeemed codes are carried over")
end

tests.reconcileNeverMutatesItsInputs = function()
	-- UpdateAsync can call the transform more than once with the same payload,
	-- so a second run must see exactly the same input as the first.
	local payload = {
		coins = 10,
		fulfilledPurchaseIds = { receipt1 = true },
		redeemedCodes = {},
	}
	local stored = { fulfilledPurchaseIds = { receipt2 = true }, redeemedCodes = {} }

	local first = ProfilePersistence.reconcileWithStored(payload, stored)
	first.coins = 99
	first.fulfilledPurchaseIds.receipt3 = true

	assertCondition(payload.coins == 10, "The payload is not mutated")
	assertCondition(
		payload.fulfilledPurchaseIds.receipt2 == nil,
		"The payload ledger is not mutated"
	)
	assertCondition(
		payload.fulfilledPurchaseIds.receipt3 == nil,
		"The payload ledger stays isolated"
	)
	assertCondition(stored.fulfilledPurchaseIds.receipt3 == nil, "The stored ledger is not mutated")

	local second = ProfilePersistence.reconcileWithStored(payload, stored)
	assertCondition(second.coins == 10, "A repeated transform produces the same result")
	assertCondition(
		second.fulfilledPurchaseIds.receipt3 == nil,
		"A repeated transform is not tainted"
	)
	assertCondition(
		second.fulfilledPurchaseIds.receipt1 == true,
		"A repeated transform keeps payload ids"
	)
	assertCondition(
		second.fulfilledPurchaseIds.receipt2 == true,
		"A repeated transform keeps stored ids"
	)
end

function ProfilePersistenceTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return ProfilePersistenceTests
