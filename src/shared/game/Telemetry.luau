-- Pure shaping rules for persisted server analytics.
--
-- The server keeps ~40 in-memory counters (sessions, placements, line clears,
-- shop funnel steps, receipt retries). They were readable only through the
-- Studio-only diagnostics overlay, so every one of them reset to zero on each
-- server restart and was never aggregated across servers.
--
-- Persisting them is a read-modify-write against a shared DataStore key, which
-- means the merge runs inside an UpdateAsync transform. Transforms must not
-- yield and may be re-run when another server wins a race, so the arithmetic
-- lives here: pure, allocation-only, and unit-testable outside Studio.

local Telemetry = {}

-- How often a server folds its counters into the shared totals. Counters are
-- cheap to accumulate and expensive to write, so this is deliberately slow --
-- one write per server per interval, not one per event.
Telemetry.FlushIntervalSeconds = 60

local function isCountable(value)
	return typeof(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

-- What this server has counted since its last successful flush.
--
-- Session counters only ever climb, so the delta is current minus
-- last-flushed. Returns the deltas and whether any are non-zero, so a quiet
-- server can skip the write entirely rather than burning DataStore budget
-- writing zeroes.
function Telemetry.counterDeltas(current, lastFlushed)
	local deltas = {}
	local hasAny = false

	if typeof(current) ~= "table" then
		return deltas, false
	end

	lastFlushed = if typeof(lastFlushed) == "table" then lastFlushed else {}

	for key, value in current do
		if isCountable(value) then
			local previous = if isCountable(lastFlushed[key]) then lastFlushed[key] else 0
			local delta = value - previous
			if delta ~= 0 then
				deltas[key] = delta
				hasAny = true
			end
		end
	end

	return deltas, hasAny
end

-- Fold one server's deltas into the stored cross-server totals.
--
-- Runs inside an UpdateAsync transform: pure, never yields, and safe to run
-- more than once against the same stored value because it always starts from
-- the stored table it was handed rather than from anything accumulated.
function Telemetry.mergeTotals(stored, deltas, updatedAt)
	local merged = {}

	if typeof(stored) == "table" then
		for key, value in stored do
			if isCountable(value) then
				merged[key] = value
			end
		end
	end

	if typeof(deltas) == "table" then
		for key, delta in deltas do
			if isCountable(delta) then
				merged[key] = (merged[key] or 0) + delta
			end
		end
	end

	if isCountable(updatedAt) then
		merged.updatedAt = updatedAt
	end

	return merged
end

-- The snapshot to remember as "already flushed" once a write succeeds.
--
-- Taken from the counters as they were when the deltas were computed, not
-- from the live table: a counter that ticked during the write belongs to the
-- next flush, not this one. Anything else would silently drop events.
function Telemetry.flushedSnapshot(current)
	local snapshot = {}

	if typeof(current) ~= "table" then
		return snapshot
	end

	for key, value in current do
		if isCountable(value) then
			snapshot[key] = value
		end
	end

	return snapshot
end

return Telemetry
