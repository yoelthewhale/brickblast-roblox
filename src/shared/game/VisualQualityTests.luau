local VisualQuality = require(script.Parent.VisualQuality)

local VisualQualityTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local DESKTOP = {
	touchEnabled = false,
	keyboardEnabled = true,
	screenSize = Vector2.new(1920, 1080),
}

local PHONE = {
	touchEnabled = true,
	keyboardEnabled = false,
	screenSize = Vector2.new(390, 844),
}

local TABLET = {
	touchEnabled = true,
	keyboardEnabled = false,
	screenSize = Vector2.new(1024, 768),
}

local TOUCHSCREEN_LAPTOP = {
	touchEnabled = true,
	keyboardEnabled = true,
	screenSize = Vector2.new(1920, 1080),
}

local tests = {}

tests.desktopKeepsTheFullEffectsStack = function()
	assertCondition(not VisualQuality.isLowTierDevice(DESKTOP), "A desktop is not low-tier")
	assertCondition(
		VisualQuality.tierFor(DESKTOP, false) == VisualQuality.Tier.Full,
		"A desktop keeps the full effects stack"
	)
end

tests.touchOnlyDevicesAreLowTier = function()
	-- The bug this fixes: these devices ran the full desktop post-processing
	-- stack unless the player found the Reduced Motion setting themselves.
	assertCondition(VisualQuality.isLowTierDevice(PHONE), "A phone is low-tier")
	assertCondition(
		VisualQuality.isLowTierDevice(TABLET),
		"A tablet is low-tier even though its screen is large"
	)
	assertCondition(
		VisualQuality.usesReducedEffects(PHONE, false),
		"A phone gets reduced effects without opting in"
	)
end

tests.aTouchscreenLaptopKeepsTheFullStack = function()
	assertCondition(
		not VisualQuality.isLowTierDevice(TOUCHSCREEN_LAPTOP),
		"Touch plus a keyboard is a laptop, not a phone"
	)
end

tests.smallScreensAreLowTierEvenWithoutTouch = function()
	assertCondition(
		VisualQuality.isLowTierDevice({
			touchEnabled = false,
			keyboardEnabled = true,
			screenSize = Vector2.new(640, 480),
		}),
		"A small window is treated as low-tier"
	)
end

tests.reducedMotionStillForcesReducedEffects = function()
	assertCondition(
		VisualQuality.usesReducedEffects(DESKTOP, true),
		"Reduced Motion still scales effects down on a desktop"
	)
	assertCondition(
		VisualQuality.tierFor(DESKTOP, true) == VisualQuality.Tier.Reduced,
		"Reduced Motion maps to the reduced tier"
	)
end

tests.missingDeviceInformationFallsBackToFull = function()
	-- Never guess low-tier from absent data: that would silently downgrade
	-- visuals for a desktop player whose camera was not ready yet.
	assertCondition(not VisualQuality.isLowTierDevice(nil), "No device info is not low-tier")
	assertCondition(not VisualQuality.isLowTierDevice({}), "An empty device table is not low-tier")
	assertCondition(
		VisualQuality.tierFor(nil, false) == VisualQuality.Tier.Full,
		"No device info keeps the full stack"
	)
	assertCondition(not VisualQuality.isLowTierDevice({
		touchEnabled = false,
		keyboardEnabled = true,
		screenSize = "not a size",
	}), "An unusable screen size is ignored rather than assumed small")
end

function VisualQualityTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return VisualQualityTests
