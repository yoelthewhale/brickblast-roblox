local Telemetry = require(script.Parent.Telemetry)

local TelemetryTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local tests = {}

tests.deltasAreWhatChangedSinceTheLastFlush = function()
	local deltas, hasAny = Telemetry.counterDeltas(
		{ placements = 120, linesCleared = 30, forfeits = 0 },
		{ placements = 100, linesCleared = 30 }
	)

	assertCondition(hasAny, "A changed counter should report something to flush")
	assertCondition(deltas.placements == 20, "Only the increase is flushed, not the total")
	assertCondition(deltas.linesCleared == nil, "An unchanged counter contributes nothing")
	assertCondition(deltas.forfeits == nil, "A counter still at zero contributes nothing")
end

tests.aFirstFlushSendsEverything = function()
	local deltas, hasAny = Telemetry.counterDeltas({ placements = 5 }, nil)

	assertCondition(hasAny, "The first flush has something to send")
	assertCondition(deltas.placements == 5, "With nothing flushed yet, the delta is the total")
end

tests.aQuietServerHasNothingToFlush = function()
	local _, hasAny = Telemetry.counterDeltas({ placements = 7 }, { placements = 7 })
	assertCondition(not hasAny, "Unchanged counters should skip the write entirely")

	local _, emptyHasAny = Telemetry.counterDeltas({}, {})
	assertCondition(not emptyHasAny, "No counters means nothing to flush")
end

tests.deltasIgnoreValuesThatAreNotCounters = function()
	local deltas = Telemetry.counterDeltas({
		placements = 3,
		name = "server",
		nested = {},
		broken = 0 / 0,
		infinite = math.huge,
	}, {})

	assertCondition(deltas.placements == 3, "Real counters are included")
	assertCondition(deltas.name == nil, "Strings are not counters")
	assertCondition(deltas.nested == nil, "Tables are not counters")
	assertCondition(deltas.broken == nil, "NaN is not a counter")
	assertCondition(deltas.infinite == nil, "Infinity is not a counter")
end

tests.totalsAccumulateAcrossServers = function()
	local first = Telemetry.mergeTotals({ placements = 1000 }, { placements = 20 })
	assertCondition(first.placements == 1020, "Deltas add to the stored total")

	local second = Telemetry.mergeTotals(first, { placements = 5, linesCleared = 2 })
	assertCondition(second.placements == 1025, "A second server adds on top")
	assertCondition(second.linesCleared == 2, "A counter absent from storage starts from its delta")
end

tests.mergingToleratesAnEmptyStore = function()
	local merged = Telemetry.mergeTotals(nil, { placements = 4 })
	assertCondition(merged.placements == 4, "The very first write starts from nothing")

	merged = Telemetry.mergeTotals("corrupt", { placements = 4 })
	assertCondition(merged.placements == 4, "A corrupt stored value does not block the write")
end

tests.mergingIsSafeToRepeatOnTheSameStoredValue = function()
	-- UpdateAsync can re-run a transform when another server wins the race, so
	-- the same stored value and deltas must always produce the same result.
	local stored = { placements = 100 }
	local deltas = { placements = 7 }

	local first = Telemetry.mergeTotals(stored, deltas)
	local second = Telemetry.mergeTotals(stored, deltas)

	assertCondition(first.placements == 107, "First run adds the delta once")
	assertCondition(second.placements == 107, "A repeated run does not double-count")
	assertCondition(stored.placements == 100, "The stored table is not mutated")
	assertCondition(deltas.placements == 7, "The deltas table is not mutated")
end

tests.mergingRecordsWhenItHappened = function()
	local merged = Telemetry.mergeTotals({}, { placements = 1 }, 1755000000)
	assertCondition(merged.updatedAt == 1755000000, "The write records its timestamp")

	merged = Telemetry.mergeTotals({}, { placements = 1 }, nil)
	assertCondition(merged.updatedAt == nil, "A missing timestamp is simply not recorded")
end

tests.theFlushedSnapshotIsTakenAtDeltaTime = function()
	-- A counter that ticks during the write belongs to the next flush. The
	-- snapshot must come from the values the deltas were computed against, or
	-- those events are silently dropped.
	local counters = { placements = 10 }
	local snapshot = Telemetry.flushedSnapshot(counters)

	counters.placements = 14

	assertCondition(snapshot.placements == 10, "The snapshot is a copy, not a live reference")
	assertCondition(
		Telemetry.counterDeltas(counters, snapshot).placements == 4,
		"Events counted during the write are carried into the next flush"
	)
end

tests.errorEntriesAreShapedForStorage = function()
	local clean = Telemetry.sanitizeErrorEntry({
		category = "ProfileSave",
		message = "DataStoreService: 502",
		userId = 564972790,
		at = 1755000000,
	})

	assertCondition(clean.category == "ProfileSave", "The category is kept")
	assertCondition(clean.message == "DataStoreService: 502", "The message is kept")
	assertCondition(clean.userId == 564972790, "The affected player is kept")
	assertCondition(clean.at == 1755000000, "The timestamp is kept")
end

tests.unusableErrorEntriesAreDroppedRatherThanStored = function()
	assertCondition(Telemetry.sanitizeErrorEntry(nil) == nil, "Nothing is not an error report")
	assertCondition(Telemetry.sanitizeErrorEntry("boom") == nil, "A bare string is not a report")
	assertCondition(
		Telemetry.sanitizeErrorEntry({ message = "no category" }) == nil,
		"A report with no category cannot be acted on"
	)
	assertCondition(
		Telemetry.sanitizeErrorEntry({ category = "" }) == nil,
		"An empty category cannot be acted on"
	)
end

tests.errorEntriesToleratePartialInformation = function()
	local clean = Telemetry.sanitizeErrorEntry({ category = "ProfileLoad" })

	assertCondition(clean ~= nil, "A category alone is enough to be worth storing")
	assertCondition(clean.message == "", "A missing message becomes empty rather than nil")
	assertCondition(clean.at == 0, "A missing timestamp becomes zero")
	assertCondition(clean.userId == nil, "A missing player is simply absent")
end

tests.longErrorMessagesAreTruncated = function()
	-- Errors arrive fastest when things are worst, so an unbounded message
	-- would blow the DataStore value size exactly when it matters most.
	local clean = Telemetry.sanitizeErrorEntry({
		category = "ProfileSave",
		message = string.rep("x", Telemetry.ErrorMessageLimit + 500),
	})

	assertCondition(
		#clean.message <= Telemetry.ErrorMessageLimit + 3,
		`Message should be truncated, got {#clean.message} characters`
	)
end

tests.errorLogKeepsTheNewestAndDropsTheOldest = function()
	local stored = {}
	for index = 1, 10 do
		table.insert(stored, { category = "ProfileSave", message = `old {index}`, at = index })
	end

	local merged = Telemetry.mergeErrorLog(stored, {
		{ category = "ProfileLoad", message = "new one", at = 99 },
	}, 5)

	assertCondition(#merged == 5, `Log should be capped at 5, got {#merged}`)
	assertCondition(merged[#merged].message == "new one", "The newest report survives")
	assertCondition(merged[1].message == "old 7", "The oldest reports are dropped first")
end

tests.errorLogSurvivesACorruptStoredValue = function()
	local merged = Telemetry.mergeErrorLog("not a list", {
		{ category = "ProfileSave", message = "still recorded" },
	})

	assertCondition(#merged == 1, "A corrupt stored log does not block new reports")
	assertCondition(merged[1].message == "still recorded", "The new report is stored")

	merged = Telemetry.mergeErrorLog({ "junk", 42, { category = "ProfileLoad" } }, {})
	assertCondition(#merged == 1, "Unusable stored entries are dropped on the next write")
end

tests.errorLogMergeIsSafeToRepeat = function()
	-- Same UpdateAsync contract as the counters: a re-run against the same
	-- stored value must not duplicate or mutate anything.
	local stored = { { category = "ProfileSave", message = "a", at = 1 } }
	local incoming = { { category = "ProfileLoad", message = "b", at = 2 } }

	local first = Telemetry.mergeErrorLog(stored, incoming)
	local second = Telemetry.mergeErrorLog(stored, incoming)

	assertCondition(#first == 2 and #second == 2, "A repeated transform does not accumulate")
	assertCondition(#stored == 1, "The stored log is not mutated")
	assertCondition(#incoming == 1, "The incoming reports are not mutated")
end

tests.flushIntervalIsUsable = function()
	assertCondition(
		typeof(Telemetry.FlushIntervalSeconds) == "number" and Telemetry.FlushIntervalSeconds > 0,
		"A flush loop needs a positive interval"
	)
end

function TelemetryTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return TelemetryTests
