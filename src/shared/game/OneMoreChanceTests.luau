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
