local Blocks = {}

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

function Blocks.getRandomShape(randomizer)
	local index = randomizer:NextInteger(1, #Blocks.Shapes)
	local shape = Blocks.Shapes[index]

	return {
		id = shape.id,
		cells = shape.cells,
		color = randomRainbowColor(randomizer),
	}
end

function Blocks.createHand(randomizer, count)
	local hand = {}

	for slot = 1, count do
		hand[slot] = Blocks.getRandomShape(randomizer)
	end

	return hand
end

return Blocks
