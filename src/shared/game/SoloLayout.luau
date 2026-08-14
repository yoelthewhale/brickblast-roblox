local Config = require(script.Parent.Config)

local SoloLayout = {}

local MIN_BOARD_SIZE = 224
local MAX_BOARD_SIZE = 760

local function isFiniteNumber(value)
	return typeof(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function cleanNumber(value, fallback)
	return if isFiniteNumber(value) then value else fallback
end

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

local function fitMultiple(value, multiple)
	return math.floor(value / multiple) * multiple
end

function SoloLayout.expectedBoardCellCount()
	return Config.BoardSize * Config.BoardSize
end

function SoloLayout.calculate(screenSize, topInset, bottomInset, uiScale)
	local screenWidth = cleanNumber(screenSize and screenSize.X, 1280)
	local screenHeight = cleanNumber(screenSize and screenSize.Y, 720)
	local scale = clamp(cleanNumber(uiScale, 1), 0.9, 1.12)
	local topSafe = math.max(0, cleanNumber(topInset, 0))
	local bottomSafe = math.max(0, cleanNumber(bottomInset, 0))
	local outerPadding = clamp(math.floor(screenWidth * 0.014), 16, 30)
	local headerHeight = clamp(math.floor(58 * scale), 54, 68)
	local headerGap = clamp(math.floor(12 * scale), 10, 18)
	local columnGap = clamp(math.floor(screenWidth * 0.012), 14, 24)
	local statGap = clamp(math.floor(12 * scale), 10, 16)
	local trayGap = clamp(math.floor(14 * scale), 12, 20)
	local top = topSafe + outerPadding
	local bottom = bottomSafe + outerPadding
	local contentHeight = math.max(260, screenHeight - top - bottom - headerHeight - headerGap)
	local leftWidth = clamp(math.floor(screenWidth * 0.15), 174, 270)
	local rightWidth = clamp(math.floor(screenWidth * 0.19), 230, 350)
	local availableCenter = screenWidth
		- (outerPadding * 2)
		- leftWidth
		- rightWidth
		- (columnGap * 2)
	local trayHeight = clamp(math.floor(contentHeight * 0.17), 100, 150)
	local boardMaxHeight = contentHeight - trayGap - trayHeight
	local boardSize = fitMultiple(
		clamp(math.min(availableCenter, boardMaxHeight), MIN_BOARD_SIZE, MAX_BOARD_SIZE),
		Config.BoardSize
	)
	local boardGap = clamp(math.floor(boardSize / 96), 3, 7)
	local boardPadding = clamp(math.floor(boardSize / 25), 13, 28)
	local boardContent = boardSize - (boardPadding * 2) - (boardGap * (Config.BoardSize - 1))
	local boardCell = math.floor(boardContent / Config.BoardSize)
	local usedBoardPixels = boardCell * Config.BoardSize
		+ boardGap * (Config.BoardSize - 1)
		+ boardPadding * 2
	local centerWidth = math.max(boardSize, availableCenter)
	local contentWidth = screenWidth - outerPadding * 2
	local actionsHeight = clamp(math.floor(96 * scale), 86, 112)
	local leaderboardHeight = math.max(260, contentHeight - actionsHeight - statGap)

	return {
		width = screenWidth,
		height = screenHeight,
		top = top,
		outerPadding = outerPadding,
		headerHeight = headerHeight,
		headerGap = headerGap,
		columnGap = columnGap,
		leftWidth = leftWidth,
		centerWidth = centerWidth,
		rightWidth = rightWidth,
		contentWidth = contentWidth,
		contentHeight = contentHeight,
		statGap = statGap,
		boardPadding = boardPadding,
		boardGap = boardGap,
		boardSize = usedBoardPixels,
		boardCell = boardCell,
		boardStageHeight = usedBoardPixels,
		trayGap = trayGap,
		trayHeight = trayHeight,
		leaderboardHeight = leaderboardHeight,
		actionGap = statGap,
		actionsHeight = actionsHeight,
	}
end

return SoloLayout
