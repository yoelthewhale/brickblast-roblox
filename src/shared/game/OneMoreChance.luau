local Grid = require(script.Parent.Grid)
local HandGenerator = require(script.Parent.HandGenerator)
local StageProgression = require(script.Parent.StageProgression)

local OneMoreChance = {}

OneMoreChance.CapPerRun = 1

local function cloneArray(array)
	return table.clone(array or {})
end

local function finiteNumber(value, fallback)
	if typeof(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
		return fallback
	end
	return value
end

function OneMoreChance.initializeRun(state)
	state.continueUses = 0
	state.continueCap = OneMoreChance.CapPerRun
	state.continuePending = false
	state.continueSnapshot = nil
	state.usedContinue = false
end

function OneMoreChance.captureSnapshot(state)
	if typeof(state) ~= "table" or state.mode ~= "Solo" then
		return nil
	end

	state.continueSnapshot = {
		board = Grid.clone(state.board),
		hand = cloneArray(state.hand),
		recentHands = cloneArray(state.recentHands),
		assistance = HandGenerator.sanitizeAssistance(state.assistance, state.difficulty),
		stage = StageProgression.sanitize(state.stage),
		score = finiteNumber(state.score, 0),
		bestScore = finiteNumber(state.bestScore, 0),
		linesCleared = finiteNumber(state.linesCleared, 0),
		comboStreak = finiteNumber(state.comboStreak, 0),
		highestCombo = finiteNumber(state.highestCombo, 0),
	}
	return state.continueSnapshot
end

function OneMoreChance.canOffer(state)
	return typeof(state) == "table"
		and state.mode == "Solo"
		and state.continueSnapshot ~= nil
		and (state.continueUses or 0) < (state.continueCap or OneMoreChance.CapPerRun)
end

function OneMoreChance.beginOffer(state)
	if typeof(state) ~= "table" or state.mode ~= "Solo" then
		return false
	end

	local available = OneMoreChance.canOffer(state)
	state.continuePending = available
	if available then
		state.message = "No moves left"
	end
	return available
end

function OneMoreChance.publicOffer(state)
	local used = typeof(state) == "table" and state.continueUses or 0
	local cap = typeof(state) == "table" and state.continueCap or OneMoreChance.CapPerRun
	local pending = typeof(state) == "table" and state.continuePending == true

	return {
		available = pending and OneMoreChance.canOffer(state),
		source = pending and OneMoreChance.canOffer(state) and "free" or "none",
		usedThisRun = used,
		capThisRun = cap,
		priceText = nil,
		stage = typeof(state) == "table" and state.stage and state.stage.currentStage or 1,
		score = typeof(state) == "table" and finiteNumber(state.score, 0) or 0,
	}
end

function OneMoreChance.restore(state)
	if not OneMoreChance.canOffer(state) then
		return false
	end

	local snapshot = state.continueSnapshot
	state.board = Grid.clone(snapshot.board)
	state.hand = cloneArray(snapshot.hand)
	state.recentHands = cloneArray(snapshot.recentHands)
	state.assistance = HandGenerator.sanitizeAssistance(snapshot.assistance, state.difficulty)
	state.stage = StageProgression.sanitize(snapshot.stage)
	state.score = snapshot.score
	state.bestScore = math.max(snapshot.bestScore, state.bestScore or 0)
	state.linesCleared = snapshot.linesCleared
	state.comboStreak = snapshot.comboStreak
	state.highestCombo = snapshot.highestCombo
	state.continueUses += 1
	state.continuePending = false
	state.usedContinue = true
	state.alive = true
	state.message = "One More Chance"
	state.returnScheduled = false
	state.resultSummary = nil
	return true
end

function OneMoreChance.decline(state)
	if typeof(state) ~= "table" then
		return
	end

	state.continuePending = false
	state.message = "Run ended"
end

return OneMoreChance
