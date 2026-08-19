-- Server-side telemetry: the in-memory counters, the failure reports, and the
-- DataStore flush that makes both survive a restart.
--
-- This lives in its own ModuleScript rather than inside GameServer.server.luau
-- for a concrete reason: that file is a single top-level Luau chunk, and Luau
-- allows only 200 top-level locals per chunk. Adding this feature's ten locals
-- inline pushed it to 206, at which point the entire server script failed to
-- compile and the game did not run at all (see #96). A ModuleScript gets its
-- own register budget.
--
-- The pure arithmetic still lives in shared/game/Telemetry.luau, which is unit
-- tested. This module is the stateful server half: DataStore handles, buffers,
-- and the flush loop.

local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Telemetry =
	require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("game"):WaitForChild("Telemetry"))

local TelemetryReporter = {}

-- Counters live here so callers can keep doing `reporter.counters.placements += 1`
-- without every counter costing a top-level local in the server script.
TelemetryReporter.counters = {
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
	profilesMigrated = 0,
	profilesAheadOfServer = 0,
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
}

-- Failure tallies surfaced in the diagnostics snapshot.
TelemetryReporter.failures = {
	profileLoad = 0,
	profileSave = 0,
	analyticsFlush = 0,
}

local analyticsStore = nil
local lastFlushedCounters = {}
-- High-severity failures waiting to be written. Kept until a flush succeeds,
-- so a failed write retries rather than losing the report.
local pendingErrorReports = {}

-- Separate store from profiles so a problem with one cannot affect the other,
-- and so analytics writes never share a key with player data.
pcall(function()
	analyticsStore = DataStoreService:GetDataStore("BlockBlastAnalyticsV1")
end)

-- Record a high-severity failure somewhere it can be read after the session
-- ends. Callers still warn() for live Studio work; this adds the durable copy.
--
-- Deliberately not used for analytics-flush failures: reporting a storage
-- failure into storage is circular, and those have their own counter.
function TelemetryReporter.reportError(category, message, userId)
	local entry = Telemetry.sanitizeErrorEntry({
		category = category,
		message = message,
		userId = userId,
		at = os.time(),
	})

	if not entry then
		return
	end

	-- Bounded here as well as at the merge: a server that cannot reach the
	-- DataStore at all would otherwise accumulate reports forever.
	table.insert(pendingErrorReports, entry)
	while #pendingErrorReports > Telemetry.ErrorLogLimit do
		table.remove(pendingErrorReports, 1)
	end
end

-- Fold this server's counters into the shared cross-server totals. Writes
-- deltas rather than totals so several servers accumulate into one key
-- instead of overwriting each other.
function TelemetryReporter.flushAnalytics()
	if not analyticsStore then
		return false
	end

	local deltas, hasAny = Telemetry.counterDeltas(TelemetryReporter.counters, lastFlushedCounters)
	if not hasAny then
		return true
	end

	-- Snapshot before the write, not after: a counter that ticks while the
	-- request is in flight belongs to the next flush.
	local snapshot = Telemetry.flushedSnapshot(TelemetryReporter.counters)
	local updatedAt = os.time()

	local ok, err = pcall(function()
		analyticsStore:UpdateAsync("Totals", function(stored)
			return Telemetry.mergeTotals(stored, deltas, updatedAt)
		end)
	end)

	if not ok then
		-- lastFlushedCounters is deliberately left alone, so these deltas are
		-- retried on the next flush instead of being lost.
		TelemetryReporter.failures.analyticsFlush += 1
		warn(`[BlockBlast] Failed to flush analytics: {tostring(err)}`)
		return false
	end

	lastFlushedCounters = snapshot
	return true
end

-- Write the pending failure reports. Separate key from the counters: most
-- flushes have no errors at all, so this write usually does not happen.
function TelemetryReporter.flushErrorReports()
	if not analyticsStore or #pendingErrorReports == 0 then
		return true
	end

	local outgoing = pendingErrorReports
	pendingErrorReports = {}

	local ok, err = pcall(function()
		analyticsStore:UpdateAsync("Errors", function(stored)
			return Telemetry.mergeErrorLog(stored, outgoing, Telemetry.ErrorLogLimit)
		end)
	end)

	if not ok then
		-- Put them back in front of anything reported during the write, so
		-- order is preserved and nothing is dropped by a transient failure.
		for index = #outgoing, 1, -1 do
			table.insert(pendingErrorReports, 1, outgoing[index])
		end
		while #pendingErrorReports > Telemetry.ErrorLogLimit do
			table.remove(pendingErrorReports, 1)
		end

		TelemetryReporter.failures.analyticsFlush += 1
		warn(`[BlockBlast] Failed to flush error reports: {tostring(err)}`)
		return false
	end

	return true
end

function TelemetryReporter.flushAll()
	TelemetryReporter.flushAnalytics()
	TelemetryReporter.flushErrorReports()
end

-- Starts the periodic flush. Called once by the server.
function TelemetryReporter.startFlushLoop()
	task.spawn(function()
		while true do
			task.wait(Telemetry.FlushIntervalSeconds)
			TelemetryReporter.flushAll()
		end
	end)
end

return TelemetryReporter
