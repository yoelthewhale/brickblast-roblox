local Config = require(script.Parent.Config)
local SoloLayout = require(script.Parent.SoloLayout)

local SoloLayoutTests = {}

local function assertCondition(condition, message)
	if not condition then
		error(message, 2)
	end
end

local function assertViewport(width, height)
	local layout = SoloLayout.calculate(Vector2.new(width, height), 36, 0, 1)

	assertCondition(layout.boardSize == layout.boardStageHeight, "Board stage should be square")
	assertCondition(layout.boardCell > 0, "Board cells should have positive size")
	assertCondition(
		layout.boardCell * Config.BoardSize
				+ layout.boardGap * (Config.BoardSize - 1)
				+ layout.boardPadding * 2
			== layout.boardSize,
		"Board measurements should exactly fit the 8x8 grid"
	)
	assertCondition(
		layout.trayHeight > 0 and layout.trayGap > 0,
		"Tray should have separated measured space"
	)
	assertCondition(
		layout.leftWidth + layout.centerWidth + layout.rightWidth + layout.columnGap * 2
			<= layout.contentWidth,
		"Columns should remain inside the viewport"
	)
end

local tests = {}

tests.supportedPcViewports = function()
	assertViewport(1280, 720)
	assertViewport(1920, 1080)
	assertViewport(2560, 1440)
end

tests.invalidValuesFallback = function()
	local layout = SoloLayout.calculate(nil, 0 / 0, math.huge, nil)

	assertCondition(layout.width == 1280, "Missing screen size should use safe width")
	assertCondition(layout.height == 720, "Missing screen size should use safe height")
	assertCondition(layout.boardSize > 0, "Fallback layout should still allocate the board")
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
