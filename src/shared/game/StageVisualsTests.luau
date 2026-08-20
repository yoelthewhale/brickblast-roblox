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
		StageVisuals.presetForStage(1).name == "Bubblegum",
		"Stage 1 should use the Bubblegum flavor"
	)
	assertCondition(
		StageVisuals.presetForStage(2).name == "Spearmint",
		"Stage 2 should use the Spearmint flavor"
	)
	assertCondition(
		StageVisuals.presetForStage(3).name == "Lemon Drop",
		"Stage 3 should use the Lemon Drop flavor"
	)
	assertCondition(
		StageVisuals.presetForStage(4).name == "Grape Soda",
		"Stage 4 should use the Grape Soda flavor"
	)
end

tests.beyondInitialPresetsCycle = function()
	local first = StageVisuals.presetForStage(1)
	local fifth = StageVisuals.presetForStage(5)

	assertCondition(fifth.name == first.name, "Stage 5 should cycle back to Bubblegum")
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
		StageVisuals.presetForStage(nil).name == "Bubblegum",
		"Nil stage should fall back"
	)
	assertCondition(
		StageVisuals.presetForStage(-20).name == "Bubblegum",
		"Negative stage should fall back"
	)
	assertCondition(
		StageVisuals.presetForStage(0 / 0).name == "Bubblegum",
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

tests.presetShapeIsUnchangedForExistingConsumers = function()
	-- StageVisuals is now a shim over VisualTokens. Existing client code was
	-- deliberately not touched, so every field it reads must still be present
	-- and still be a Color3 (or, for blockPalette, a list of them).
	for stage = 1, 9 do
		local preset = StageVisuals.presetForStage(stage)
		for _, field in StageVisuals.requiredFields() do
			assertCondition(preset[field] ~= nil, `Stage {stage} preset lost field {field}`)
			if field ~= "blockPalette" then
				assertCondition(
					typeof(preset[field]) == "Color3",
					`Stage {stage} field {field} should be a Color3`
				)
			end
		end
		assertCondition(preset.stageNumber == stage, `Stage {stage} lost its stageNumber`)
		assertCondition(preset.presetIndex ~= nil, `Stage {stage} lost its presetIndex`)
		assertCondition(preset.id ~= nil, `Stage {stage} lost its id`)
	end
end

tests.blockColorHelpersStayInBounds = function()
	local preset = StageVisuals.presetForStage(1)
	for index = -5, 20 do
		assertCondition(
			typeof(StageVisuals.blockColorForIndex(preset, index)) == "Color3",
			`blockColorForIndex returned a non-color for index {index}`
		)
	end
	for x = 1, 8 do
		for y = 1, 8 do
			assertCondition(
				typeof(StageVisuals.blockColorForCell(preset, x, y)) == "Color3",
				`blockColorForCell returned a non-color for ({x}, {y})`
			)
		end
	end
	assertCondition(
		typeof(StageVisuals.blockColorForIndex({}, 1)) == "Color3",
		"blockColorForIndex should fall back safely for a preset with no palette"
	)
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
