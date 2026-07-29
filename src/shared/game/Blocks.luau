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

function Blocks.isValidPieceSkin(pieceSkin)
	for _, skin in Blocks.PieceSkins do
		if skin == pieceSkin then
			return true
		end
	end

	return false
end

function Blocks.getRandomShape(randomizer, pieceSkin)
	local index = randomizer:NextInteger(1, #Blocks.Shapes)
	local shape = Blocks.Shapes[index]

	return {
		id = shape.id,
		cells = shape.cells,
		color = randomPieceColor(randomizer, pieceSkin),
	}
end

function Blocks.createHand(randomizer, count, pieceSkin)
	local hand = {}

	for slot = 1, count do
		hand[slot] = Blocks.getRandomShape(randomizer, pieceSkin)
	end

	return hand
end

return Blocks
