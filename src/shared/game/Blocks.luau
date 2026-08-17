local Blocks = {}

Blocks.PieceSkins = {
	"Rainbow",
	"Neon",
	"Pastel",
	"Ice",
}

Blocks.Shapes = {
	{
		id = "single",
		cells = { Vector2.new(0, 0) },
	},
	{
		id = "line2",
		cells = { Vector2.new(0, 0), Vector2.new(1, 0) },
	},
	{
		id = "line3",
		cells = { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(2, 0) },
	},
	{
		id = "vertical3",
		cells = { Vector2.new(0, 0), Vector2.new(0, 1), Vector2.new(0, 2) },
	},
	{
		id = "square2",
		cells = { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) },
	},
	{
		id = "corner",
		cells = { Vector2.new(0, 0), Vector2.new(0, 1), Vector2.new(1, 1) },
	},
	{
		id = "plus",
		cells = {
			Vector2.new(1, 0),
			Vector2.new(0, 1),
			Vector2.new(1, 1),
			Vector2.new(2, 1),
			Vector2.new(1, 2),
		},
	},
	{
		id = "line4",
		cells = { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(2, 0), Vector2.new(3, 0) },
	},
	{
		id = "vertical4",
		cells = { Vector2.new(0, 0), Vector2.new(0, 1), Vector2.new(0, 2), Vector2.new(0, 3) },
	},
	{
		id = "tShape",
		cells = { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(2, 0), Vector2.new(1, 1) },
	},
	{
		id = "sShape",
		cells = { Vector2.new(1, 0), Vector2.new(2, 0), Vector2.new(0, 1), Vector2.new(1, 1) },
	},
	{
		id = "zShape",
		cells = { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(1, 1), Vector2.new(2, 1) },
	},
	{
		id = "jShape",
		cells = { Vector2.new(1, 0), Vector2.new(1, 1), Vector2.new(0, 2), Vector2.new(1, 2) },
	},
	{
		id = "lShape",
		cells = { Vector2.new(0, 0), Vector2.new(0, 1), Vector2.new(0, 2), Vector2.new(1, 2) },
	},
	{
		id = "rect2x3",
		cells = {
			Vector2.new(0, 0),
			Vector2.new(1, 0),
			Vector2.new(2, 0),
			Vector2.new(0, 1),
			Vector2.new(1, 1),
			Vector2.new(2, 1),
		},
	},
	{
		id = "tShape2",
		cells = { Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1), Vector2.new(2, 1) },
	},
	{
		id = "tShape3",
		cells = { Vector2.new(0, 0), Vector2.new(0, 1), Vector2.new(1, 1), Vector2.new(0, 2) },
	},
	{
		id = "tShape4",
		cells = { Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1), Vector2.new(1, 2) },
	},
	{
		id = "sShape2",
		cells = { Vector2.new(0, 0), Vector2.new(0, 1), Vector2.new(1, 1), Vector2.new(1, 2) },
	},
	{
		id = "zShape2",
		cells = { Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1), Vector2.new(0, 2) },
	},
	{
		id = "jShape2",
		cells = { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(2, 0), Vector2.new(2, 1) },
	},
	{
		id = "jShape3",
		cells = { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(0, 2) },
	},
	{
		id = "jShape4",
		cells = { Vector2.new(0, 0), Vector2.new(0, 1), Vector2.new(1, 1), Vector2.new(2, 1) },
	},
	{
		id = "lShape2",
		cells = { Vector2.new(2, 0), Vector2.new(0, 1), Vector2.new(1, 1), Vector2.new(2, 1) },
	},
	{
		id = "lShape3",
		cells = { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(1, 1), Vector2.new(1, 2) },
	},
	{
		id = "lShape4",
		cells = { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(2, 0), Vector2.new(0, 1) },
	},
	{
		id = "corner2",
		cells = { Vector2.new(1, 0), Vector2.new(0, 1), Vector2.new(1, 1) },
	},
	{
		id = "corner3",
		cells = { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(1, 1) },
	},
	{
		id = "corner4",
		cells = { Vector2.new(0, 0), Vector2.new(1, 0), Vector2.new(0, 1) },
	},
	{
		id = "diagonal2",
		cells = { Vector2.new(0, 0), Vector2.new(1, 1) },
	},
	{
		id = "diagonal2Alt",
		cells = { Vector2.new(1, 0), Vector2.new(0, 1) },
	},
	{
		id = "diagonal3",
		cells = { Vector2.new(0, 0), Vector2.new(1, 1), Vector2.new(2, 2) },
	},
	{
		id = "diagonal3Alt",
		cells = { Vector2.new(2, 0), Vector2.new(1, 1), Vector2.new(0, 2) },
	},
}

local function randomRainbowColor(randomizer)
	local hue = randomizer:NextNumber(0, 1)
	local saturation = randomizer:NextNumber(0.72, 0.96)
	local value = randomizer:NextNumber(0.88, 1)

	return Color3.fromHSV(hue, saturation, value)
end

local function randomPieceColor(randomizer, pieceSkin)
	if pieceSkin == "Neon" then
		return Color3.fromHSV(randomizer:NextNumber(0, 1), 1, 1)
	elseif pieceSkin == "Pastel" then
		return Color3.fromHSV(randomizer:NextNumber(0, 1), 0.38, 1)
	elseif pieceSkin == "Ice" then
		return Color3.fromRGB(
			randomizer:NextInteger(130, 180),
			randomizer:NextInteger(210, 245),
			randomizer:NextInteger(235, 255)
		)
	end

	return randomRainbowColor(randomizer)
end

local function normalizeCells(cells)
	local minX = math.huge
	local minY = math.huge
	for _, cell in cells do
		minX = math.min(minX, cell.X)
		minY = math.min(minY, cell.Y)
	end

	local normalized = {}
	for index, cell in cells do
		normalized[index] = Vector2.new(cell.X - minX, cell.Y - minY)
	end
	table.sort(normalized, function(left, right)
		if left.Y == right.Y then
			return left.X < right.X
		end
		return left.Y < right.Y
	end)

	return normalized
end

function Blocks.cloneCells(cells)
	local cloned = {}
	for index, cell in cells do
		cloned[index] = Vector2.new(cell.X, cell.Y)
	end

	return cloned
end

function Blocks.isValidPieceSkin(pieceSkin)
	for _, skin in Blocks.PieceSkins do
		if skin == pieceSkin then
			return true
		end
	end

	return false
end

function Blocks.getShapeDefinition(shapeId)
	for _, shape in Blocks.Shapes do
		if shape.id == shapeId then
			return shape
		end
	end

	return nil
end

function Blocks.rotateShape(shape)
	if typeof(shape) ~= "table" or typeof(shape.cells) ~= "table" then
		return nil
	end

	local rotated = {}
	for index, cell in shape.cells do
		rotated[index] = Vector2.new(cell.Y, -cell.X)
	end

	return {
		id = `{shape.id}:rot`,
		cells = normalizeCells(rotated),
		color = shape.color,
	}
end

function Blocks.createShape(shapeId, randomizer, pieceSkin)
	local shape = Blocks.getShapeDefinition(shapeId)
	if not shape then
		return nil
	end

	return {
		id = shape.id,
		cells = Blocks.cloneCells(shape.cells),
		color = randomPieceColor(randomizer, pieceSkin),
	}
end

function Blocks.getRandomShape(randomizer, pieceSkin)
	local index = randomizer:NextInteger(1, #Blocks.Shapes)
	local shape = Blocks.Shapes[index]

	return Blocks.createShape(shape.id, randomizer, pieceSkin)
end

function Blocks.createHand(randomizer, count, pieceSkin)
	local hand = {}

	for slot = 1, count do
		hand[slot] = Blocks.getRandomShape(randomizer, pieceSkin)
	end

	return hand
end

return Blocks
