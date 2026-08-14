local Blocks = require(script.Parent.Blocks)
local Config = require(script.Parent.Config)
local Grid = require(script.Parent.Grid)

local HandGenerator = {}

HandGenerator.CandidateLimit = Config.HandGeneration.CandidateLimit
HandGenerator.RecentHistoryLimit = Config.HandGeneration.RecentHistoryLimit

local function clamp(value, minimum, maximum)
	return math.max(minimum, math.min(maximum, value))
end

local function randomShapeId(randomizer)
	return Blocks.Shapes[randomizer:NextInteger(1, #Blocks.Shapes)].id
end

local function isFlexible(shapeId)
	return Config.HandGeneration.FlexibleShapeIds[shapeId] == true
end

local function isRestrictive(shapeId)
	return Config.HandGeneration.RestrictiveShapeIds[shapeId] == true
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

function HandGenerator.newAssistance()
	return {
		remaining = Config.HandGeneration.AssistanceStart,
		cap = Config.HandGeneration.AssistanceMax,
		lastHandConsumed = false,
		lastHandReason = "new run",
	}
end

function HandGenerator.sanitizeAssistance(assistance)
	local cap = Config.HandGeneration.AssistanceMax
	if typeof(assistance) ~= "table" then
		return HandGenerator.newAssistance()
	end

	local remaining = assistance.remaining
	if typeof(remaining) ~= "number" or remaining ~= remaining then
		remaining = Config.HandGeneration.AssistanceStart
	end

	return {
		remaining = clamp(math.floor(remaining), 0, cap),
		cap = cap,
		lastHandConsumed = assistance.lastHandConsumed == true,
		lastHandReason = typeof(assistance.lastHandReason) == "string"
				and assistance.lastHandReason
			or "unknown",
	}
end

function HandGenerator.restoreAssistance(assistance, amount, reason)
	local nextAssistance = HandGenerator.sanitizeAssistance(assistance)
	if typeof(amount) ~= "number" or amount ~= amount or amount <= 0 then
		return nextAssistance
	end

	nextAssistance.remaining =
		clamp(nextAssistance.remaining + math.floor(amount), 0, nextAssistance.cap)
	nextAssistance.lastRestoreReason = reason
	return nextAssistance
end

function HandGenerator.difficultyForStage(stage)
	if typeof(stage) ~= "number" or stage ~= stage or stage < 1 then
		stage = 1
	end

	local pressureStage =
		math.max(0, math.floor(stage) - Config.HandGeneration.StagePressureStart + 1)
	local pressure = clamp(
		pressureStage * Config.HandGeneration.PressurePerStage,
		0,
		Config.HandGeneration.MaxPressure
	)
	return {
		stage = math.max(1, math.floor(stage)),
		pressure = pressure,
		assistanceMultiplier = 1 - pressure,
		restrictiveBias = pressure,
	}
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

local function recentFlexibleCount(recentHands)
	local count = 0
	for _, signature in recentHands do
		for shapeId in string.gmatch(signature, "[^|]+") do
			if isFlexible(shapeId) then
				count += 1
			end
		end
	end
	return count
end

local function scoreShape(
	shapeId,
	stats,
	crowdRatio,
	comboStreak,
	difficulty,
	assistanceActive,
	flexibleFatigue
)
	if stats.placements <= 0 then
		return -4
	end

	local pressure = difficulty and difficulty.pressure or 0
	local assistanceMultiplier = assistanceActive
			and (difficulty and difficulty.assistanceMultiplier or 1)
		or 0
	local flexibilityScore = clamp(stats.placements, 0, 12) * (0.72 + assistanceMultiplier * 0.34)
	local clearScore = clamp(stats.clearPlacements, 0, 5) * (1.45 + assistanceMultiplier * 0.75)
		+ stats.bestLinesCleared * (3.25 + assistanceMultiplier * 1.5)
	local setupScore = clamp(stats.nearClear, 0, 8) * (0.22 + assistanceMultiplier * 0.18)
	local crowdedScore = if crowdRatio > Config.HandGeneration.CrowdedRescueThreshold
		then (6 - stats.size)
			* (crowdRatio - Config.HandGeneration.CrowdedRescueThreshold)
			* (2.8 + assistanceMultiplier * 4.4)
		else 0
	local comboScore = comboStreak > 0
			and (stats.clearPlacements * 1.4 + stats.bestLinesCleared * 2.6)
		or 0
	local pressureScore = if isRestrictive(shapeId) then pressure * 5.5 else 0
	local flexiblePenalty = if isFlexible(shapeId) then pressure * 4 + flexibleFatigue * 1.8 else 0

	return 5
		+ flexibilityScore
		+ clearScore
		+ setupScore
		+ crowdedScore
		+ comboScore
		+ pressureScore
		- flexiblePenalty
end

function HandGenerator.scoreShapeIds(board, shapeIds, options)
	options = options or {}
	local statsById = options.statsById or shapeStatsById(board)
	local recentHands = options.recentHands or {}
	local comboStreak = options.comboStreak or 0
	local difficulty = options.difficulty or HandGenerator.difficultyForStage(options.stage or 1)
	local assistanceActive = options.assistanceActive == true
	local flexibleFatigue = recentFlexibleCount(recentHands)
	local crowdRatio = countOccupied(board) / (Config.BoardSize * Config.BoardSize)
	local score = 0
	local seen = {}
	local fittingCount = 0
	local clearPieces = 0

	for _, shapeId in shapeIds do
		local stats = statsById[shapeId]
		if stats then
			score += scoreShape(
				shapeId,
				stats,
				crowdRatio,
				comboStreak,
				difficulty,
				assistanceActive,
				flexibleFatigue
			)
			if stats.placements > 0 then
				fittingCount += 1
			end
			if stats.clearPlacements > 0 then
				clearPieces += 1
			end
		end

		if seen[shapeId] then
			score -= 11
		end
		seen[shapeId] = true
	end

	if fittingCount == #shapeIds then
		score -= 9
	end
	if clearPieces > 1 then
		score -= (clearPieces - 1) * 9
	end

	local signature = HandGenerator.handSignature(shapeIds)
	for index, recentSignature in recentHands do
		if recentSignature == signature then
			score -= 20 / index
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
	local candidateLimit =
		math.max(1, math.floor(options.candidateLimit or HandGenerator.CandidateLimit))
	local statsById, fittingIds = shapeStatsById(board)
	local anyKnownShapeFits = #fittingIds > 0
	local assistance = HandGenerator.sanitizeAssistance(options.assistance)
	local stage = options.stage or 1
	local difficulty = HandGenerator.difficultyForStage(stage)
	local crowdRatio = countOccupied(board) / (Config.BoardSize * Config.BoardSize)
	local assistanceEligible = assistance.remaining > 0
		and anyKnownShapeFits
		and (
			crowdRatio >= Config.HandGeneration.CrowdedRescueThreshold
			or #fittingIds <= Config.HandGeneration.TightBoardFitThreshold
		)
	local bestIds = nil
	local bestScore = -math.huge
	local candidatesScored = 0

	for _ = 1, candidateLimit do
		local shapeIds = {}
		for slot = 1, count do
			local shapeId = randomShapeId(randomizer)
			if
				difficulty.restrictiveBias > 0
				and randomizer:NextNumber() < difficulty.restrictiveBias * 0.28
			then
				local restrictive = {}
				for _, definition in Blocks.Shapes do
					if isRestrictive(definition.id) then
						table.insert(restrictive, definition.id)
					end
				end
				shapeId = restrictive[randomizer:NextInteger(1, #restrictive)]
			end
			shapeIds[slot] = shapeId
		end

		local score = HandGenerator.scoreShapeIds(board, shapeIds, {
			statsById = statsById,
			recentHands = options.recentHands,
			comboStreak = options.comboStreak,
			stage = stage,
			difficulty = difficulty,
			assistanceActive = assistanceEligible,
		})
		score += randomizer:NextNumber(0, 11)
		candidatesScored += 1

		if anyKnownShapeFits and not handContainsFittingShape(shapeIds, statsById) then
			score -= 1000
		end

		if score > bestScore then
			bestScore = score
			bestIds = shapeIds
		end
	end

	local forcedFitting = false
	if anyKnownShapeFits and not handContainsFittingShape(bestIds, statsById) then
		local replaceSlot = randomizer:NextInteger(1, count)
		bestIds[replaceSlot] = chooseFittingShapeId(fittingIds, statsById, randomizer)
		forcedFitting = true
	end

	local consumedAssistance = false
	local assistanceReason = "none"
	if assistanceEligible and handContainsFittingShape(bestIds, statsById) then
		local usedFlexibleRescue = false
		for _, shapeId in bestIds do
			local stats = statsById[shapeId]
			if stats and stats.placements > 0 and isFlexible(shapeId) then
				usedFlexibleRescue = true
				break
			end
		end

		if
			forcedFitting
			or crowdRatio >= Config.HandGeneration.CrowdedRescueThreshold
			or usedFlexibleRescue
		then
			assistance.remaining =
				math.max(0, assistance.remaining - Config.HandGeneration.RescueCost)
			consumedAssistance = true
			assistanceReason = forcedFitting and "forced fitting piece"
				or crowdRatio >= Config.HandGeneration.CrowdedRescueThreshold and "crowded board rescue"
				or "flexible rescue"
		end
	end
	assistance.lastHandConsumed = consumedAssistance
	assistance.lastHandReason = assistanceReason

	return createHandFromIds(bestIds, randomizer, pieceSkin),
		{
			anyKnownShapeFits = anyKnownShapeFits,
			candidatesScored = candidatesScored,
			candidateLimit = candidateLimit,
			score = bestScore,
			shapeIds = bestIds,
			assistance = assistance,
			assistanceConsumed = consumedAssistance,
			assistanceReason = assistanceReason,
			effectiveDifficulty = difficulty,
			legalPlacementCounts = statsById,
		}
end

return HandGenerator
