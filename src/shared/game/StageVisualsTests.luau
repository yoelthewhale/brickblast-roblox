local StageVisuals = require(script.Parent.StageVisuals)

local StageVisualsTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local tests = {}

tests.initialStageMappings = function()
	assertCondition(
		StageVisuals.presetForStage(1).name == "Aqua Candy",
		"Stage 1 should use Aqua Candy"
	)
	assertCondition(
		StageVisuals.presetForStage(2).name == "Berry Pop",
		"Stage 2 should use Berry Pop"
	)
	assertCondition(
		StageVisuals.presetForStage(3).name == "Golden Cheese",
		"Stage 3 should use Golden Cheese"
	)
	assertCondition(
		StageVisuals.presetForStage(4).name == "Lava Rush",
		"Stage 4 should use Lava Rush"
	)
end

tests.beyondInitialPresetsCycle = function()
	local first = StageVisuals.presetForStage(1)
	local fifth = StageVisuals.presetForStage(5)

	assertCondition(fifth.name == first.name, "Stage 5 should cycle back to Aqua Candy")
	assertCondition(fifth.cycle == 1, "Stage 5 should record the first completed preset cycle")
end

tests.requiredFieldsAreComplete = function()
	for stage = 1, StageVisuals.presetCount() do
		local preset = StageVisuals.presetForStage(stage)
		assertCondition(
			StageVisuals.validatePreset(preset),
			`{preset.name} should include every required field`
		)
	end
end

tests.invalidStageFallsBackSafely = function()
	assertCondition(
		StageVisuals.presetForStage(nil).name == "Aqua Candy",
		"Nil stage should fall back"
	)
	assertCondition(
		StageVisuals.presetForStage(-20).name == "Aqua Candy",
		"Negative stage should fall back"
	)
	assertCondition(
		StageVisuals.presetForStage(0 / 0).name == "Aqua Candy",
		"NaN stage should fall back"
	)
end

tests.reducedMotionTransition = function()
	local normal = StageVisuals.transitionForStage(2, false)
	local reduced = StageVisuals.transitionForStage(2, true)

	assertCondition(normal.kind == "pulseWash", "Normal motion should use pulse wash")
	assertCondition(reduced.kind == "fade", "Reduced Motion should use a simple fade")
	assertCondition(reduced.duration < normal.duration, "Reduced Motion should be shorter")
end

function StageVisualsTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return StageVisualsTests
