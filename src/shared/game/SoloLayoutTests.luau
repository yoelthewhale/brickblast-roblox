local Config = require(script.Parent.Config)
local SoloLayout = require(script.Parent.SoloLayout)

local SoloLayoutTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

-- Invariants every viewport must satisfy, phone or desktop.
local function assertViewport(width, height)
	local label = `{width}x{height}`
	local layout = SoloLayout.calculate(Vector2.new(width, height), 36, 0, 1)

	assertCondition(layout.boardSize == layout.boardStageHeight, `{label}: board stage is square`)
	assertCondition(layout.boardCell > 0, `{label}: board cells have positive size`)
	assertCondition(
		layout.boardCell * Config.BoardSize
				+ layout.boardGap * (Config.BoardSize - 1)
				+ layout.boardPadding * 2
			== layout.boardSize,
		`{label}: board measurements exactly fit the 8x8 grid`
	)
	assertCondition(
		layout.trayHeight > 0 and layout.trayGap > 0,
		`{label}: tray has separated measured space`
	)
	assertCondition(
		layout.leftWidth + layout.centerWidth + layout.rightWidth + layout.columnGap * 2
			<= layout.contentWidth,
		`{label}: columns stay inside the viewport`
	)
	assertCondition(
		layout.boardSize <= layout.contentWidth,
		`{label}: board fits the content width`
	)
	-- Return Hub and Play Again live in the actions panel. If it has no height,
	-- the player cannot leave or restart a run.
	assertCondition(layout.actionsHeight > 0, `{label}: run actions have measured space`)
end

-- Phone viewports stack vertically, so the horizontal invariant is not enough:
-- the whole column has to fit the available height too.
local function assertPhoneViewport(width, height)
	local label = `{width}x{height}`
	local layout = SoloLayout.calculate(Vector2.new(width, height), 36, 0, 1)

	assertViewport(width, height)

	assertCondition(layout.phone == true, `{label}: is treated as a phone`)
	assertCondition(layout.leftWidth == 0, `{label}: the stat column collapses`)
	assertCondition(layout.rightWidth == 0, `{label}: the leaderboard column collapses`)
	assertCondition(
		layout.centerWidth == layout.contentWidth,
		`{label}: the board column takes the full width`
	)
	assertCondition(
		layout.leaderboardHeight == 0,
		`{label}: the leaderboard is dropped during a phone run`
	)
	assertCondition(layout.statsStripHeight > 0, `{label}: the stats strip stays visible`)

	local stacked = layout.statsStripHeight
		+ layout.statsStripGap
		+ layout.boardStageHeight
		+ layout.trayGap
		+ layout.trayHeight
		+ layout.actionGap
		+ layout.actionsHeight
	assertCondition(
		stacked <= layout.contentHeight,
		`{label}: the stacked column fits the content height ({stacked} > {layout.contentHeight})`
	)
end

local tests = {}

tests.supportedPcViewports = function()
	assertViewport(1280, 720)
	assertViewport(1920, 1080)
	assertViewport(2560, 1440)
	assertViewport(3440, 1440)
end

tests.tabletViewportsKeepTheColumnLayout = function()
	for _, viewport in { { 768, 1024 }, { 1024, 768 }, { 820, 1180 } } do
		local layout = SoloLayout.calculate(Vector2.new(viewport[1], viewport[2]), 36, 0, 1)
		assertCondition(
			layout.phone == false,
			`{viewport[1]}x{viewport[2]}: tablets keep the three-column layout`
		)
		assertViewport(viewport[1], viewport[2])
	end
end

tests.narrowPhoneViewportsFit = function()
	-- The regression this guards: every one of these overflowed by 270-315px
	-- under the three-column layout.
	assertPhoneViewport(375, 667)
	assertPhoneViewport(375, 812)
	assertPhoneViewport(390, 844)
	assertPhoneViewport(414, 896)
	assertPhoneViewport(430, 932)
end

tests.shortPhoneViewportsFit = function()
	-- Short screens are the harder constraint: the stack runs out of height
	-- before it runs out of width, and the board has to give way rather than
	-- being clamped back up and pushing the action bar off-screen.
	assertPhoneViewport(320, 568)
	assertPhoneViewport(360, 640)
	assertPhoneViewport(667, 375)
	assertPhoneViewport(844, 390)
end

tests.phoneBoardsStayTappableOnSupportedSizes = function()
	-- Cells computed to roughly 22px under the old layout, before accounting
	-- for the overflow. This asserts the range the issue names (375-430 wide)
	-- comfortably beats that.
	for _, viewport in { { 375, 667 }, { 375, 812 }, { 390, 844 }, { 414, 896 }, { 430, 932 } } do
		local layout = SoloLayout.calculate(Vector2.new(viewport[1], viewport[2]), 36, 0, 1)
		assertCondition(
			layout.boardCell >= 28,
			`{viewport[1]}x{viewport[2]}: board cell {layout.boardCell} is too small to tap`
		)
	end
end

tests.phoneLayoutsHoldAcrossUiScales = function()
	for _, scale in { 0.9, 1, 1.12 } do
		for _, viewport in { { 375, 667 }, { 320, 568 }, { 430, 932 } } do
			local layout = SoloLayout.calculate(Vector2.new(viewport[1], viewport[2]), 36, 0, scale)
			local stacked = layout.statsStripHeight
				+ layout.statsStripGap
				+ layout.boardStageHeight
				+ layout.trayGap
				+ layout.trayHeight
				+ layout.actionGap
				+ layout.actionsHeight
			assertCondition(
				stacked <= layout.contentHeight,
				`{viewport[1]}x{viewport[2]}@{scale}: stacked column overflows`
			)
			assertCondition(
				layout.boardSize <= layout.contentWidth,
				`{viewport[1]}x{viewport[2]}@{scale}: board overflows the width`
			)
		end
	end
end

tests.safeAreaInsetsDoNotCauseOverflow = function()
	-- A notched phone hands back a large top inset; it must come out of the
	-- stack rather than pushing the action bar off the bottom.
	for _, inset in { 0, 36, 64, 92 } do
		local layout = SoloLayout.calculate(Vector2.new(390, 844), inset, 34, 1)
		local stacked = layout.statsStripHeight
			+ layout.statsStripGap
			+ layout.boardStageHeight
			+ layout.trayGap
			+ layout.trayHeight
			+ layout.actionGap
			+ layout.actionsHeight
		assertCondition(stacked <= layout.contentHeight, `inset {inset}: stacked column overflows`)
	end
end

tests.phoneBreakpointMatchesTheHub = function()
	assertCondition(
		SoloLayout.isPhoneViewport(Vector2.new(719, 900)),
		"Narrow viewports are phones"
	)
	assertCondition(SoloLayout.isPhoneViewport(Vector2.new(900, 519)), "Short viewports are phones")
	assertCondition(
		not SoloLayout.isPhoneViewport(Vector2.new(720, 520)),
		"The breakpoint itself is not a phone"
	)
	assertCondition(
		not SoloLayout.isPhoneViewport(Vector2.new(1280, 720)),
		"Desktops are not phones"
	)
end

tests.invalidValuesFallback = function()
	local layout = SoloLayout.calculate(nil, 0 / 0, math.huge, nil)

	assertCondition(layout.width == 1280, "Missing screen size should use safe width")
	assertCondition(layout.height == 720, "Missing screen size should use safe height")
	assertCondition(layout.boardSize > 0, "Fallback layout should still allocate the board")
	assertCondition(layout.phone == false, "The fallback viewport is not a phone")
end

tests.boardCellInvariant = function()
	assertCondition(
		SoloLayout.expectedBoardCellCount() == 64,
		"Solo layout should preserve the 64-cell board invariant"
	)
end

function SoloLayoutTests.run()
	local results = {}

	for name, test in tests do
		test()
		table.insert(results, name)
	end

	table.sort(results)
	return results
end

return SoloLayoutTests
