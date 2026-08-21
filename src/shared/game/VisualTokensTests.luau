local VisualTokens = require(script.Parent.VisualTokens)

local VisualTokensTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local function assertNear(actual, expected, tolerance, message)
	assertCondition(
		math.abs(actual - expected) <= tolerance,
		`{message} (got {actual}, expected ~{expected})`
	)
end

local function luminance(color)
	return 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
end

-- WCAG-style contrast ratio. Used here as a regression guard, not as a
-- certification: the point is that a later palette tweak cannot silently make
-- board text or empty cells unreadable.
local function contrastRatio(a, b)
	local lighter = math.max(luminance(a), luminance(b))
	local darker = math.min(luminance(a), luminance(b))
	return (lighter + 0.05) / (darker + 0.05)
end

local tests = {}

-- --- Identity ------------------------------------------------------------

tests.identityIsStableAcrossEveryStageAndEnergy = function()
	local base = VisualTokens.identity()

	for stage = 1, 24 do
		for step = 0, 4 do
			local tokens = VisualTokens.resolve(stage, step / 4)
			assertCondition(
				tokens.ink == base.ink,
				`Ink must not vary (stage {stage}, energy {step / 4})`
			)
			assertCondition(
				tokens.surface == base.cream,
				`Surface must not vary (stage {stage}, energy {step / 4})`
			)
			assertCondition(
				tokens.gloss == base.gloss,
				`Gloss must not vary (stage {stage}, energy {step / 4})`
			)
		end
	end
end

tests.identityReturnsACopy = function()
	local first = VisualTokens.identity()
	first.ink = Color3.fromRGB(0, 0, 0)
	assertCondition(
		VisualTokens.identity().ink ~= Color3.fromRGB(0, 0, 0),
		"identity() must hand back a copy, not the shared table"
	)
end

-- --- Flavor --------------------------------------------------------------

tests.flavorsCycleByStage = function()
	local count = VisualTokens.flavorCount()
	assertCondition(count == 4, "Flavor count should stay at 4 so stage-cycle math is unchanged")

	local first = VisualTokens.flavorForStage(1)
	local wrapped = VisualTokens.flavorForStage(1 + count)

	assertCondition(wrapped.id == first.id, "Stage 1 + flavorCount should return the same flavor")
	assertCondition(wrapped.cycle == 1, "Wrapping once should report cycle 1")
	assertCondition(first.cycle == 0, "The first pass should report cycle 0")
end

tests.everyFlavorIsDistinct = function()
	local seen = {}
	for stage = 1, VisualTokens.flavorCount() do
		local flavor = VisualTokens.flavorForStage(stage)
		assertCondition(not seen[flavor.id], `Flavor {flavor.id} appeared twice inside one cycle`)
		seen[flavor.id] = true
	end
end

tests.invalidStageFallsBackToStageOne = function()
	for _, bad in { nil, "seven", 0, -12, 0 / 0, math.huge, {} } do
		local flavor = VisualTokens.flavorForStage(bad)
		assertCondition(flavor.stageNumber == 1, "Invalid stage should clamp to stage 1")
		assertCondition(flavor.id ~= nil, "Invalid stage should still return a usable flavor")
	end
end

-- --- Energy --------------------------------------------------------------

tests.energyIsZeroAtRest = function()
	local resting = VisualTokens.energyFor({ comboStreak = 0, stage = 1, perfectClears = 0 })
	assertNear(resting, 0, 0.0001, "A fresh stage-1 run should sit at zero energy")
end

tests.energyReachesFullWhenEverySignalIsMaxed = function()
	local maxed = VisualTokens.energyFor({ comboStreak = 99, stage = 99, perfectClears = 99 })
	assertNear(maxed, 1, 0.0001, "All signals maxed should reach exactly full energy")
end

tests.energyIsMonotonicInCombo = function()
	local previous = -1
	for combo = 0, 20 do
		local value = VisualTokens.energyFor({ comboStreak = combo, stage = 1, perfectClears = 0 })
		assertCondition(value >= previous, `Energy dropped as combo rose to {combo}`)
		previous = value
	end
end

tests.energyIsMonotonicInStage = function()
	local previous = -1
	for stage = 1, 30 do
		local value = VisualTokens.energyFor({ comboStreak = 0, stage = stage, perfectClears = 0 })
		assertCondition(value >= previous, `Energy dropped as stage rose to {stage}`)
		previous = value
	end
end

tests.energyIsMonotonicInPerfectClears = function()
	local previous = -1
	for perfect = 0, 10 do
		local value =
			VisualTokens.energyFor({ comboStreak = 0, stage = 1, perfectClears = perfect })
		assertCondition(value >= previous, `Energy dropped as perfect clears rose to {perfect}`)
		previous = value
	end
end

tests.comboOutweighsStage = function()
	-- Combo is the signal the player is actively driving, so it must dominate
	-- the slow stage floor. If this inverts, a good streak stops feeling like
	-- it is doing anything.
	local hotCombo = VisualTokens.energyFor({ comboStreak = 8, stage = 1, perfectClears = 0 })
	local deepStage = VisualTokens.energyFor({ comboStreak = 0, stage = 99, perfectClears = 0 })
	assertCondition(hotCombo > deepStage, "A maxed combo should outrank a maxed stage floor")
end

tests.energyClampsOnGarbageInput = function()
	for _, bad in { nil, "hot", 42, {}, { comboStreak = "x", stage = {}, perfectClears = 0 / 0 } } do
		local value = VisualTokens.energyFor(bad)
		assertCondition(
			value >= 0 and value <= 1,
			`Energy escaped 0..1 on garbage input (got {value})`
		)
	end
end

tests.negativeSignalsCannotDriveEnergyBelowZero = function()
	local value = VisualTokens.energyFor({ comboStreak = -50, stage = -50, perfectClears = -50 })
	assertCondition(value >= 0, "Negative signals must not produce negative energy")
end

-- --- Resolve -------------------------------------------------------------

tests.resolveClampsEnergyIntoRange = function()
	for _, bad in { -5, 12, 0 / 0, math.huge, "warm", nil } do
		local tokens = VisualTokens.resolve(1, bad)
		assertCondition(
			tokens.energy >= 0 and tokens.energy <= 1,
			`resolve() leaked an out-of-range energy ({tokens.energy})`
		)
	end
end

tests.energyIntensifiesTheRim = function()
	-- The single most visible expression of energy: the board rim gets hotter
	-- and more saturated as a run heats up. This is the guard against the
	-- palette quietly going static.
	local calm = VisualTokens.resolve(1, 0)
	local hot = VisualTokens.resolve(1, 1)

	local _, calmSaturation = calm.boardRim:ToHSV()
	local _, hotSaturation = hot.boardRim:ToHSV()

	assertCondition(
		hotSaturation > calmSaturation,
		"Board rim should gain saturation as energy rises"
	)
	assertCondition(calm.boardRim ~= hot.boardRim, "Board rim must actually change with energy")
end

tests.everyStageLooksDifferentAtRest = function()
	local seen = {}
	for stage = 1, VisualTokens.flavorCount() do
		local key = tostring(VisualTokens.resolve(stage, 0).primary)
		assertCondition(not seen[key], `Stage {stage} produced a duplicate primary color`)
		seen[key] = true
	end
end

tests.boardWellNeverApproachesInk = function()
	-- An empty cell must never read as a filled one, however hot the run gets.
	for stage = 1, 12 do
		for step = 0, 4 do
			local tokens = VisualTokens.resolve(stage, step / 4)
			assertCondition(
				contrastRatio(tokens.boardWell, tokens.ink) > 2.5,
				`Board well collapsed toward ink at stage {stage}, energy {step / 4}`
			)
		end
	end
end

tests.panelTextStaysReadableOnSurface = function()
	for stage = 1, 12 do
		for step = 0, 4 do
			local tokens = VisualTokens.resolve(stage, step / 4)
			local ratio = contrastRatio(tokens.ink, tokens.surface)
			assertCondition(
				ratio >= 4.5,
				`Ink on surface fell below 4.5:1 at stage {stage}, energy {step / 4} (got {ratio})`
			)
		end
	end
end

tests.piecePaletteIsUsableAtEveryStage = function()
	for stage = 1, 12 do
		local tokens = VisualTokens.resolve(stage, 0)
		assertCondition(
			#tokens.piecePalette >= 3,
			`Stage {stage} piece palette must hold at least 3 colors`
		)
		for index, color in tokens.piecePalette do
			assertCondition(
				typeof(color) == "Color3",
				`Stage {stage} piece palette entry {index} is not a Color3`
			)
		end
	end
end

tests.scalesAreOrdered = function()
	local space = VisualTokens.Space
	assertCondition(
		space.hair < space.tight
			and space.tight < space.snug
			and space.snug < space.base
			and space.base < space.roomy
			and space.roomy < space.loose,
		"Spacing scale must increase monotonically"
	)

	local radius = VisualTokens.Radius
	assertCondition(
		radius.cell < radius.chip and radius.chip < radius.card and radius.card < radius.panel,
		"Radius scale must increase from cell to panel"
	)
end

-- --- Chrome (the chassis palette ArcadeUI consumes) ----------------------

tests.contrastRatioMatchesKnownValues = function()
	local white = Color3.fromRGB(255, 255, 255)
	local black = Color3.fromRGB(0, 0, 0)
	assertNear(
		VisualTokens.contrastRatio(white, black),
		21,
		0.05,
		"Black on white should be the 21:1 maximum"
	)
	assertNear(
		VisualTokens.contrastRatio(white, white),
		1,
		0.001,
		"A color against itself should be 1:1"
	)
end

tests.readableOnDarkensUntilItClearsTheTarget = function()
	local cream = VisualTokens.identity().cream
	-- Pale candy yellow on cream is roughly 1.3:1 -- the exact case that made
	-- the old `score` role unreadable once the chassis went light.
	local pale = Color3.fromRGB(255, 210, 71)
	assertCondition(
		VisualTokens.contrastRatio(pale, cream) < 4.5,
		"Precondition: pale yellow should start unreadable on cream"
	)

	local fixed = VisualTokens.readableOn(pale, cream, 4.5)
	assertCondition(
		VisualTokens.contrastRatio(fixed, cream) >= 4.5,
		"readableOn should darken until the target is met"
	)

	local hue = select(1, pale:ToHSV())
	local fixedHue = select(1, fixed:ToHSV())
	assertNear(fixedHue, hue, 0.02, "readableOn must preserve hue, not wash the color out")
end

tests.readableOnLeavesAlreadyReadableColorsAlone = function()
	local cream = VisualTokens.identity().cream
	local ink = VisualTokens.identity().ink
	assertCondition(
		VisualTokens.readableOn(ink, cream, 4.5) == ink,
		"A color that already clears the target should be returned untouched"
	)
end

tests.everyChromeTextRoleIsReadableOnBothGrounds = function()
	local chrome = VisualTokens.chrome()
	local identity = VisualTokens.identity()
	local textRoles = { "text", "muted", "score", "best", "combo", "gold", "silver", "bronze" }

	for _, role in textRoles do
		for groundName, ground in { surface = identity.cream, sunken = identity.creamShade } do
			local ratio = VisualTokens.contrastRatio(chrome[role], ground)
			assertCondition(
				ratio >= 4.5,
				`Chrome role {role} is unreadable on {groundName} ({ratio}:1)`
			)
		end
	end
end

tests.chromeKeepsEveryKeyArcadeUiConsumes = function()
	-- ArcadeUI.Color is consumed at ~59 call sites that were deliberately left
	-- untouched, so dropping a key here breaks the client at runtime with no
	-- compile-time signal.
	local chrome = VisualTokens.chrome()
	local required = {
		"shell",
		"shellTop",
		"shellBottom",
		"inner",
		"innerBottom",
		"edge",
		"rim",
		"rimBright",
		"text",
		"muted",
		"score",
		"best",
		"combo",
		"gold",
		"silver",
		"bronze",
	}

	for _, key in required do
		assertCondition(chrome[key] ~= nil, `Chrome palette lost the {key} key`)
		assertCondition(typeof(chrome[key]) == "Color3", `Chrome key {key} is not a Color3`)
	end
end

tests.chromeIsStableAcrossRuns = function()
	-- Chrome is the chassis: it must NOT vary with stage or energy, or the
	-- energy axis stops reading as "the board is heating up" and becomes "the
	-- whole screen is flickering".
	local first = VisualTokens.chrome()
	local second = VisualTokens.chrome()
	for key, value in first do
		assertCondition(second[key] == value, `Chrome key {key} is not deterministic`)
	end
end

tests.chromeRolesStayDistinguishable = function()
	local chrome = VisualTokens.chrome()
	-- score/combo/best carry different meanings in the HUD; if contrast
	-- derivation collapses them onto the same value the HUD loses information.
	assertCondition(chrome.score ~= chrome.combo, "score and combo must stay distinct")
	assertCondition(chrome.best ~= chrome.combo, "best and combo must stay distinct")
	assertCondition(chrome.gold ~= chrome.silver, "gold and silver must stay distinct")
	assertCondition(chrome.silver ~= chrome.bronze, "silver and bronze must stay distinct")
end

function VisualTokensTests.run()
	local names = {}
	for name, body in tests do
		body()
		table.insert(names, name)
	end
	return names
end

return VisualTokensTests
