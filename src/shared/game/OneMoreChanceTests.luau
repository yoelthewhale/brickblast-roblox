local Blocks = require(script.Parent.Blocks)
local Config = require(script.Parent.Config)
local Grid = require(script.Parent.Grid)
local OneMoreChance = require(script.Parent.OneMoreChance)
local StageProgression = require(script.Parent.StageProgression)

local tests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message or "Assertion failed", 2)
	end
end

local function makeState()
	return {
		board = Grid.create(),
		hand = {
			Blocks.createShape("single", Random.new(1), "Rainbow"),
			nil,
			nil,
		},
		recentHands = {},
		mode = "Solo",
		score = 120,
		bestScore = 200,
		linesCleared = 3,
		comboStreak = 2,
		highestCombo = 4,
		stage = StageProgression.newRun(),
		difficulty = Config.Difficulties.Default,
		assistance = nil,
		alive = true,
		message = nil,
	}
end

tests.offerIsHiddenBeforePendingDeath = function()
	local state = makeState()
	OneMoreChance.initializeRun(state)
	OneMoreChance.captureSnapshot(state)

	local offer = OneMoreChance.publicOffer(state)
	assertCondition(offer.available == false, "Offer should not appear before a pending run end")
	assertCondition(offer.source == "none", "Non-pending offer should not expose a reward source")
	assertCondition(offer.usedThisRun == 0, "Fresh run should have zero uses")
	assertCondition(offer.capThisRun == 1, "Prototype cap should be one continue")
end

tests.restoreRewindsBoardAndRunStats = function()
	local state = makeState()
	OneMoreChance.initializeRun(state)
	Grid.place(state.board, state.hand[1], 1, 1)
	OneMoreChance.captureSnapshot(state)

	state.score = 450
	state.linesCleared = 8
	state.comboStreak = 5
	state.highestCombo = 5
	Grid.place(state.board, state.hand[1], 2, 1)
	state.alive = false

	assertCondition(OneMoreChance.beginOffer(state) == true, "Snapshot should make offer available")
	assertCondition(OneMoreChance.restore(state) == true, "Restore should succeed once")
	assertCondition(state.board[1][1] ~= false, "Original placement should remain")
	assertCondition(state.board[1][2] == false, "Post-snapshot placement should be rewound")
	assertCondition(state.score == 120, "Score should rewind to the snapshot")
	assertCondition(state.linesCleared == 3, "Line count should rewind")
	assertCondition(state.comboStreak == 2, "Combo should rewind")
	assertCondition(state.highestCombo == 4, "Highest combo should rewind")
	assertCondition(state.alive == true, "Continue should revive the run")
	assertCondition(state.continueUses == 0, "Restore alone should not consume a continue")
	assertCondition(
		OneMoreChance.confirmPlayableUse(state) == true,
		"Playable restore should consume"
	)
	assertCondition(state.usedContinue == true, "Run should record confirmed continue usage")
end

tests.capPreventsSecondFreeContinue = function()
	local state = makeState()
	OneMoreChance.initializeRun(state)
	OneMoreChance.captureSnapshot(state)
	OneMoreChance.beginOffer(state)
	assertCondition(OneMoreChance.restore(state) == true, "First continue should work")
	assertCondition(
		OneMoreChance.confirmPlayableUse(state) == true,
		"First continue should consume"
	)

	state.alive = false
	OneMoreChance.beginOffer(state)
	local offer = OneMoreChance.publicOffer(state)
	assertCondition(offer.available == false, "Second continue should be capped")
	assertCondition(offer.usedThisRun == offer.capThisRun, "Capped offer should report usage")
	assertCondition(OneMoreChance.restore(state) == false, "Second restore should be rejected")
end

tests.initializeRunClearsEveryContinueFlagFromThePreviousRun = function()
	local state = makeState()
	state.continueUses = 1
	state.continueCap = 99
	state.continuePending = true
	state.continueSnapshot = { board = Grid.create() }
	state.usedContinue = true

	OneMoreChance.initializeRun(state)

	assertCondition(state.continueUses == 0, "New run should reset continue uses")
	assertCondition(state.continueCap == OneMoreChance.CapPerRun, "New run should reset the cap")
	assertCondition(state.continuePending == false, "New run should not inherit a pending offer")
	assertCondition(state.continueSnapshot == nil, "New run should drop the old snapshot")
	assertCondition(state.usedContinue == false, "New run should clear the used-continue marker")
end

tests.declineEndsThePendingOfferWithoutConsumingAContinue = function()
	local state = makeState()
	OneMoreChance.initializeRun(state)
	OneMoreChance.captureSnapshot(state)

	assertCondition(OneMoreChance.beginOffer(state) == true, "Offer should begin from a snapshot")
	OneMoreChance.decline(state)

	local offer = OneMoreChance.publicOffer(state)
	assertCondition(offer.available == false, "Declined offer should not remain available")
	assertCondition(offer.source == "none", "Declined offer should expose no entitlement source")
	assertCondition(state.continueUses == 0, "Declining should not consume a continue")
	assertCondition(state.usedContinue == false, "Declining should not mark the run as continued")
	assertCondition(state.continueSnapshot ~= nil, "Declining should not destroy audit history")
end

tests.unplayableRestoreCanReopenWithoutSpendingTheRunCap = function()
	local state = makeState()
	OneMoreChance.initializeRun(state)

	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			state.board[y][x] = "filled"
		end
	end
	state.hand = {
		Blocks.createShape("single", Random.new(44), "Rainbow"),
		nil,
		nil,
	}
	OneMoreChance.captureSnapshot(state)
	assertCondition(OneMoreChance.beginOffer(state) == true, "Snapshot should still open the offer")
	assertCondition(OneMoreChance.restore(state) == true, "Restore itself should rewind state")

	assertCondition(
		OneMoreChance.confirmPlayableUse(state) == false,
		"An unplayable restore should not consume the continue"
	)
	assertCondition(state.continueUses == 0, "Failed confirmation should preserve the run cap")
	assertCondition(state.usedContinue == false, "Failed confirmation should not mark continuation")
	assertCondition(OneMoreChance.reopenOffer(state) == true, "The offer can be reopened for retry")
	assertCondition(state.continuePending == true, "Retry should restore pending state")
	assertCondition(state.alive == false, "Retry waits at the run-end state")
end

function tests.run()
	local names = {}
	for name, test in tests do
		if name ~= "run" then
			test()
			table.insert(names, name)
		end
	end
	table.sort(names)
	return names
end

return tests
