local Blocks = require(script.Parent.Blocks)
local Config = require(script.Parent.Config)
local Grid = require(script.Parent.Grid)

local HandGenerator = {}

HandGenerator.CandidateLimit = 48
HandGenerator.RecentHistoryLimit = 5

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

local function randomShapeId(randomizer)
	return Blocks.Shapes[randomizer:NextInteger(1, #Blocks.Shapes)].id
end

local function countOccupied(board)
	local occupied = 0

	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			if board[y][x] ~= false then
				occupied += 1
			end
		end
	end

	return occupied
end

local function lineFillAfterPlacement(board, shape, originX, originY)
	local rowCounts = {}
	local columnCounts = {}

	for index = 1, Config.BoardSize do
		rowCounts[index] = 0
		columnCounts[index] = 0
	end

	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			if board[y][x] ~= false then
				rowCounts[y] += 1
				columnCounts[x] += 1
			end
		end
	end

	for _, cell in shape.cells do
		local x = originX + cell.X
		local y = originY + cell.Y
		rowCounts[y] += 1
		columnCounts[x] += 1
	end

	local nearClear = 0
	for index = 1, Config.BoardSize do
		if rowCounts[index] == Config.BoardSize - 1 then
			nearClear += 1
		end
		if columnCounts[index] == Config.BoardSize - 1 then
			nearClear += 1
		end
	end

	return nearClear
end

local function analyzeShape(board, shape)
	local placements = 0
	local clearPlacements = 0
	local bestLinesCleared = 0
	local nearClear = 0

	for y = 1, Config.BoardSize do
		for x = 1, Config.BoardSize do
			if Grid.canPlace(board, shape, x, y) then
				placements += 1
				nearClear += lineFillAfterPlacement(board, shape, x, y)

				local preview = Grid.clone(board)
				Grid.place(preview, shape, x, y)
				local linesCleared = Grid.clearLines(preview)
				if linesCleared > 0 then
					clearPlacements += 1
					bestLinesCleared = math.max(bestLinesCleared, linesCleared)
				end
			end
		end
	end

	return {
		placements = placements,
		clearPlacements = clearPlacements,
		bestLinesCleared = bestLinesCleared,
		nearClear = nearClear,
		size = #shape.cells,
	}
end

local function shapeStatsById(board)
	local statsById = {}
	local fittingIds = {}

	for _, shapeDefinition in Blocks.Shapes do
		local shape = {
			id = shapeDefinition.id,
			cells = Blocks.cloneCells(shapeDefinition.cells),
		}
		local stats = analyzeShape(board, shape)
		statsById[shape.id] = stats
		if stats.placements > 0 then
			table.insert(fittingIds, shape.id)
		end
	end

	return statsById, fittingIds
end

function HandGenerator.handSignature(handOrIds)
	local ids = {}

	for index, shapeOrId in handOrIds do
		ids[index] = if typeof(shapeOrId) == "table" then shapeOrId.id else shapeOrId
	end

	table.sort(ids)
	return table.concat(ids, "|")
end

local function handContainsFittingShape(shapeIds, statsById)
	for _, shapeId in shapeIds do
		if statsById[shapeId] and statsById[shapeId].placements > 0 then
			return true
		end
	end

	return false
end

local function chooseFittingShapeId(fittingIds, statsById, randomizer)
	local totalWeight = 0
	local weights = {}

	for index, shapeId in fittingIds do
		local stats = statsById[shapeId]
		local weight = 1 + math.sqrt(stats.placements) + stats.clearPlacements * 0.5
		weights[index] = weight
		totalWeight += weight
	end

	local roll = randomizer:NextNumber(0, totalWeight)
	for index, shapeId in fittingIds do
		roll -= weights[index]
		if roll <= 0 then
			return shapeId
		end
	end

	return fittingIds[#fittingIds]
end

local function scoreShape(stats, crowdRatio, comboStreak)
	if stats.placements <= 0 then
		return -4
	end

	local flexibilityScore = clamp(stats.placements, 0, 18) * 1.4
	local clearScore = clamp(stats.clearPlacements, 0, 8) * 3.5 + stats.bestLinesCleared * 7
	local setupScore = clamp(stats.nearClear, 0, 12) * 0.7
	local crowdedScore = crowdRatio > 0.58 and (6 - stats.size) * (crowdRatio - 0.58) * 8 or 0
	local comboScore = comboStreak > 0 and (stats.clearPlacements * 4 + stats.bestLinesCleared * 8)
		or 0

	return 8 + flexibilityScore + clearScore + setupScore + crowdedScore + comboScore
end

function HandGenerator.scoreShapeIds(board, shapeIds, options)
	options = options or {}
	local statsById = options.statsById or shapeStatsById(board)
	local recentHands = options.recentHands or {}
	local comboStreak = options.comboStreak or 0
	local crowdRatio = countOccupied(board) / (Config.BoardSize * Config.BoardSize)
	local score = 0
	local seen = {}
	local fittingCount = 0
	local clearPieces = 0

	for _, shapeId in shapeIds do
		local stats = statsById[shapeId]
		if stats then
			score += scoreShape(stats, crowdRatio, comboStreak)
			if stats.placements > 0 then
				fittingCount += 1
			end
			if stats.clearPlacements > 0 then
				clearPieces += 1
			end
		end

		if seen[shapeId] then
			score -= 9
		end
		seen[shapeId] = true
	end

	if fittingCount == #shapeIds then
		score -= 4
	end
	if clearPieces > 1 then
		score -= (clearPieces - 1) * 6
	end

	local signature = HandGenerator.handSignature(shapeIds)
	for index, recentSignature in recentHands do
		if recentSignature == signature then
			score -= 14 / index
		end
	end

	return score
end

local function createHandFromIds(shapeIds, randomizer, pieceSkin)
	local hand = {}

	for slot, shapeId in shapeIds do
		hand[slot] = Blocks.createShape(shapeId, randomizer, pieceSkin)
	end

	return hand
end

function HandGenerator.rememberHand(recentHands, hand)
	recentHands = recentHands or {}
	table.insert(recentHands, 1, HandGenerator.handSignature(hand))

	while #recentHands > HandGenerator.RecentHistoryLimit do
		table.remove(recentHands)
	end

	return recentHands
end

function HandGenerator.generate(board, options)
	options = options or {}
	local randomizer = options.randomizer or Random.new()
	local count = options.count or Config.InventorySize
	local pieceSkin = options.pieceSkin
	local candidateLimit = options.candidateLimit or HandGenerator.CandidateLimit
	local statsById, fittingIds = shapeStatsById(board)
	local anyKnownShapeFits = #fittingIds > 0
	local bestIds = nil
	local bestScore = -math.huge
	local candidatesScored = 0

	for _ = 1, candidateLimit do
		local shapeIds = {}
		for slot = 1, count do
			shapeIds[slot] = randomShapeId(randomizer)
		end

		local score = HandGenerator.scoreShapeIds(board, shapeIds, {
			statsById = statsById,
			recentHands = options.recentHands,
			comboStreak = options.comboStreak,
		})
		score += randomizer:NextNumber(0, 8)
		candidatesScored += 1

		if anyKnownShapeFits and not handContainsFittingShape(shapeIds, statsById) then
			score -= 1000
		end

		if score > bestScore then
			bestScore = score
			bestIds = shapeIds
		end
	end

	if anyKnownShapeFits and not handContainsFittingShape(bestIds, statsById) then
		local replaceSlot = randomizer:NextInteger(1, count)
		bestIds[replaceSlot] = chooseFittingShapeId(fittingIds, statsById, randomizer)
	end

	return createHandFromIds(bestIds, randomizer, pieceSkin),
		{
			anyKnownShapeFits = anyKnownShapeFits,
			candidatesScored = candidatesScored,
			candidateLimit = candidateLimit,
			score = bestScore,
			shapeIds = bestIds,
		}
end

return HandGenerator
