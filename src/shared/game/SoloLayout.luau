local Config = require(script.Parent.Config)

local SoloLayout = {}

local MIN_BOARD_SIZE = 224
local MAX_BOARD_SIZE = 760

-- Phone layouts stack vertically, so the board is usually limited by height
-- rather than width. Clamping it back up to the desktop minimum is exactly
-- what made the old three-column layout overflow a phone screen, so phones
-- get a much lower floor and simply take whatever the stack leaves them.
local PHONE_MIN_TRAY_HEIGHT = 84
-- Small boards cannot afford the desktop padding and gap floors: at a 48px
-- board they would eat 47 of the 48 pixels. Phones spend the pixels on
-- cells instead.
local PHONE_MIN_BOARD_PADDING = 8
local PHONE_MIN_BOARD_GAP = 2
local DESKTOP_MIN_BOARD_PADDING = 13
local DESKTOP_MIN_BOARD_GAP = 3
local PHONE_MAX_TRAY_HEIGHT = 132

-- The same breakpoint HUDController uses to decide the hub is on a phone, so
-- the hub and the gameplay screen cannot disagree about what a phone is.
-- (VisualQuality carries the same pair for the effects tier; worth collapsing
-- into one home if a fourth caller ever appears.)
SoloLayout.PhoneMaxWidth = 720
SoloLayout.PhoneMaxHeight = 520

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

local function isPhoneSize(width, height)
	return width < SoloLayout.PhoneMaxWidth or height < SoloLayout.PhoneMaxHeight
end

function SoloLayout.expectedBoardCellCount()
	return Config.BoardSize * Config.BoardSize
end

-- Narrow *or* short counts as a phone. A short landscape phone has plenty of
-- width but no room for three tall columns, and it is the height that the
-- stacked layout has to fight for.
function SoloLayout.isPhoneViewport(screenSize)
	return isPhoneSize(
		cleanNumber(screenSize and screenSize.X, 1280),
		cleanNumber(screenSize and screenSize.Y, 720)
	)
end

-- Whether a Solo run on this device should be locked to portrait.
--
-- A phone in landscape has no room for a playable board: after the safe-area
-- inset, padding, and header there is barely any height left for the stack, so
-- the 8x8 grid collapses to a few pixels per cell. That is not fixable by
-- tuning while the board stays 8x8, so phones play in portrait.
--
-- Both conditions matter. Touch alone would catch tablets, which have plenty
-- of room in either orientation and must not be restricted. Viewport size
-- alone would catch a small desktop window, where locking orientation is
-- meaningless (and a no-op in Roblox, but worth not asking for).
function SoloLayout.shouldLockPortrait(device)
	if typeof(device) ~= "table" then
		return false
	end

	-- A laptop with a touchscreen reports a keyboard too, and is left alone.
	if device.touchEnabled ~= true or device.keyboardEnabled == true then
		return false
	end

	return SoloLayout.isPhoneViewport(device.screenSize)
end

-- Board metrics for a given outer board size. The grid has to divide exactly
-- into 8 cells plus gaps and padding, so the usable size is recomputed from
-- the parts rather than assumed.
local function boardMetrics(boardSize, minPadding, minGap)
	local boardGap = clamp(math.floor(boardSize / 96), minGap, 7)
	local boardPadding = clamp(math.floor(boardSize / 25), minPadding, 28)
	local boardContent = boardSize - (boardPadding * 2) - (boardGap * (Config.BoardSize - 1))
	local boardCell = math.floor(boardContent / Config.BoardSize)
	local usedBoardPixels = boardCell * Config.BoardSize
		+ boardGap * (Config.BoardSize - 1)
		+ boardPadding * 2

	return boardGap, boardPadding, boardCell, usedBoardPixels
end

function SoloLayout.calculate(screenSize, topInset, bottomInset, uiScale)
	local screenWidth = cleanNumber(screenSize and screenSize.X, 1280)
	local screenHeight = cleanNumber(screenSize and screenSize.Y, 720)
	local scale = clamp(cleanNumber(uiScale, 1), 0.9, 1.12)
	local topSafe = math.max(0, cleanNumber(topInset, 0))
	local bottomSafe = math.max(0, cleanNumber(bottomInset, 0))
	local phone = isPhoneSize(screenWidth, screenHeight)
	local outerPadding = clamp(math.floor(screenWidth * 0.014), 16, 30)
	local headerHeight = if phone
		then clamp(math.floor(46 * scale), 44, 54)
		else clamp(math.floor(58 * scale), 54, 68)
	local headerGap = if phone
		then clamp(math.floor(10 * scale), 8, 14)
		else clamp(math.floor(12 * scale), 10, 18)
	local statGap = clamp(math.floor(12 * scale), 10, 16)
	local trayGap = if phone
		then clamp(math.floor(10 * scale), 8, 14)
		else clamp(math.floor(14 * scale), 12, 20)
	local top = topSafe + outerPadding
	local bottom = bottomSafe + outerPadding
	local contentHeight = math.max(260, screenHeight - top - bottom - headerHeight - headerGap)
	local contentWidth = screenWidth - outerPadding * 2

	if phone then
		-- Single column: stats strip, board, tray, action bar. The side
		-- columns collapse to zero width and the board takes the full content
		-- width, which is the only way an 8x8 grid reaches a usable cell size
		-- on a phone. The leaderboard is dropped for the run -- it is the one
		-- element with no phone home and the only one not needed mid-run.
		-- Chrome is proportional so it shrinks on short screens instead of
		-- crowding the board out of existence, with floors that keep the
		-- stats readable and the action buttons tappable.
		local statsStripHeight = clamp(math.floor(contentHeight * 0.095), 40, 60)
		local statsStripGap = clamp(math.floor(10 * scale), 8, 14)
		local actionBarHeight = clamp(math.floor(contentHeight * 0.125), 52, 76)
		local actionBarGap = statsStripGap

		local stackHeight = contentHeight
			- statsStripHeight
			- statsStripGap
			- actionBarHeight
			- actionBarGap
		local trayHeight =
			clamp(math.floor(stackHeight * 0.2), PHONE_MIN_TRAY_HEIGHT, PHONE_MAX_TRAY_HEIGHT)
		local boardBudget = stackHeight - trayGap - trayHeight
		-- No lower clamp on purpose. Forcing the board back up to a minimum is
		-- precisely what made the old layout overflow: the board takes what the
		-- stack leaves it, so the stack always fits.
		local boardSize = fitMultiple(
			clamp(math.min(contentWidth, boardBudget), 0, MAX_BOARD_SIZE),
			Config.BoardSize
		)
		-- On taller phones the board runs out of width before height. Hand the
		-- leftover to the tray rather than leaving a dead gap, up to its cap.
		trayHeight = clamp(
			trayHeight + math.max(0, boardBudget - boardSize),
			PHONE_MIN_TRAY_HEIGHT,
			PHONE_MAX_TRAY_HEIGHT
		)

		local boardGap, boardPadding, boardCell, usedBoardPixels =
			boardMetrics(boardSize, PHONE_MIN_BOARD_PADDING, PHONE_MIN_BOARD_GAP)

		return {
			phone = true,
			width = screenWidth,
			height = screenHeight,
			top = top,
			outerPadding = outerPadding,
			headerHeight = headerHeight,
			headerGap = headerGap,
			columnGap = 0,
			leftWidth = 0,
			centerWidth = contentWidth,
			rightWidth = 0,
			contentWidth = contentWidth,
			contentHeight = contentHeight,
			statGap = statGap,
			statsStripHeight = statsStripHeight,
			statsStripGap = statsStripGap,
			boardPadding = boardPadding,
			boardGap = boardGap,
			boardSize = usedBoardPixels,
			boardCell = boardCell,
			boardStageHeight = usedBoardPixels,
			trayGap = trayGap,
			trayHeight = trayHeight,
			-- Hidden during a phone run; it stays available in the hub and on
			-- the result panel where it already has a better home.
			leaderboardHeight = 0,
			actionGap = actionBarGap,
			actionsHeight = actionBarHeight,
		}
	end

	local columnGap = clamp(math.floor(screenWidth * 0.012), 14, 24)
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
	local boardGap, boardPadding, boardCell, usedBoardPixels =
		boardMetrics(boardSize, DESKTOP_MIN_BOARD_PADDING, DESKTOP_MIN_BOARD_GAP)
	local centerWidth = math.max(boardSize, availableCenter)
	local actionsHeight = clamp(math.floor(96 * scale), 86, 112)
	local leaderboardHeight = math.max(260, contentHeight - actionsHeight - statGap)

	return {
		phone = false,
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
		statsStripHeight = 0,
		statsStripGap = 0,
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
