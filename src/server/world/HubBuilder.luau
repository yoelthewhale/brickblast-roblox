local HubBuilder = {}
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local ARENA_CENTERS = {
	Vector3.new(0, 2.25, -96),
	Vector3.new(122, 2.25, -96),
	Vector3.new(-122, 2.25, -96),
}

local PALETTE = {
	void = Color3.fromRGB(7, 10, 20),
	navy = Color3.fromRGB(13, 19, 33),
	navyRaised = Color3.fromRGB(22, 31, 52),
	trim = Color3.fromRGB(45, 58, 88),
	blue = Color3.fromRGB(64, 156, 255),
	cyan = Color3.fromRGB(32, 224, 255),
	pink = Color3.fromRGB(244, 114, 182),
	purple = Color3.fromRGB(138, 92, 246),
	green = Color3.fromRGB(74, 222, 128),
	gold = Color3.fromRGB(255, 196, 87),
	orange = Color3.fromRGB(251, 146, 60),
	red = Color3.fromRGB(255, 105, 105),
	white = Color3.fromRGB(245, 247, 251),
}

local BLOCK_COLORS = {
	Color3.fromRGB(255, 76, 76),
	Color3.fromRGB(255, 204, 54),
	Color3.fromRGB(76, 217, 100),
	Color3.fromRGB(64, 156, 255),
	Color3.fromRGB(167, 139, 250),
	Color3.fromRGB(244, 114, 182),
}

local animatedParts = {}

local function toCFrame(positionOrCFrame)
	if typeof(positionOrCFrame) == "CFrame" then
		return positionOrCFrame
	end
	return CFrame.new(positionOrCFrame)
end

local function makePart(parent, name, size, positionOrCFrame, color, material, options)
	options = options or {}
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = toCFrame(positionOrCFrame)
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CastShadow = options.castShadow == true
	part.CanCollide = options.canCollide ~= false
	part.CanTouch = options.canTouch == true
	part.CanQuery = options.canQuery ~= false
	part.Transparency = options.transparency or 0
	if options.shape then
		part.Shape = options.shape
	end
	part.Parent = parent
	return part
end

local function makeWedge(parent, name, size, cframe, color, material, options)
	options = options or {}
	local wedge = Instance.new("WedgePart")
	wedge.Name = name
	wedge.Anchored = true
	wedge.Size = size
	wedge.CFrame = cframe
	wedge.Color = color
	wedge.Material = material or Enum.Material.SmoothPlastic
	wedge.TopSurface = Enum.SurfaceType.Smooth
	wedge.BottomSurface = Enum.SurfaceType.Smooth
	wedge.CastShadow = false
	wedge.CanCollide = options.canCollide ~= false
	wedge.CanTouch = options.canTouch == true
	wedge.CanQuery = options.canQuery ~= false
	wedge.Transparency = options.transparency or 0
	wedge.Parent = parent
	return wedge
end

local function makeBlock(parent, name, position, color, size)
	return makePart(
		parent,
		name,
		size or Vector3.new(5, 5, 5),
		position,
		color,
		Enum.Material.SmoothPlastic,
		{ canCollide = false }
	)
end

local function makeNeon(parent, name, size, positionOrCFrame, color, transparency)
	return makePart(parent, name, size, positionOrCFrame, color, Enum.Material.Neon, {
		canCollide = false,
		transparency = transparency or 0.12,
	})
end

local function addLight(parent, color, brightness, range)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = parent
	return light
end

local function addParticleBurst(parent, color, rate, lifetime, speed)
	local attachment = Instance.new("Attachment")
	attachment.Name = "VFXAnchor"
	attachment.Parent = parent

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "BoundedSparkles"
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.55
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(lifetime * 0.75, lifetime)
	emitter.Speed = NumberRange.new(speed * 0.5, speed)
	emitter.SpreadAngle = Vector2.new(12, 12)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.22),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.15),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = attachment
	return emitter
end

local function addSurfaceText(part, text, face, color)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "SurfaceText"
	surfaceGui.Face = face
	surfaceGui.AlwaysOnTop = false
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 42
	surfaceGui.Parent = part

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Parent = surfaceGui
end

local function addLabel(part, title, subtitle)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(240, 86)
	billboard.StudsOffset = Vector3.new(0, 4.4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.fromScale(1, 0.55)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Text = title
	titleLabel.TextColor3 = PALETTE.white
	titleLabel.TextScaled = true
	titleLabel.Parent = billboard

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Position = UDim2.fromScale(0, 0.55)
	subtitleLabel.Size = UDim2.fromScale(1, 0.45)
	subtitleLabel.Font = Enum.Font.GothamBold
	subtitleLabel.Text = subtitle
	subtitleLabel.TextColor3 = Color3.fromRGB(210, 224, 255)
	subtitleLabel.TextScaled = true
	subtitleLabel.Parent = billboard
end

local function addPrompt(part, actionText, objectText)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 13
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

local function queueSpin(part, seconds, axis)
	table.insert(animatedParts, {
		part = part,
		base = part.CFrame,
		seconds = seconds,
		axis = axis,
	})
end

local function makePath(parent, name, startZ, endZ, x, color)
	local length = math.abs(endZ - startZ)
	local centerZ = (startZ + endZ) / 2
	makePart(
		parent,
		`${name}Deck`,
		Vector3.new(12, 1, length),
		Vector3.new(x, 1.45, centerZ),
		PALETTE.navyRaised,
		Enum.Material.Concrete
	)
	makeNeon(
		parent,
		`${name}LeftGuide`,
		Vector3.new(0.35, 0.2, length - 3),
		Vector3.new(x - 4.6, 2.05, centerZ),
		color,
		0.25
	)
	makeNeon(
		parent,
		`${name}RightGuide`,
		Vector3.new(0.35, 0.2, length - 3),
		Vector3.new(x + 4.6, 2.05, centerZ),
		color,
		0.25
	)
end

local function makePortal(parent, name, center, primary, secondary, labelTitle, labelSubtitle)
	local portal = Instance.new("Folder")
	portal.Name = name
	portal.Parent = parent

	local pad = makePart(
		portal,
		`${name}Pad`,
		Vector3.new(20, 1.2, 20),
		center,
		primary,
		Enum.Material.SmoothPlastic
	)
	addLabel(pad, labelTitle, labelSubtitle)

	makeNeon(
		portal,
		`${name}RingTop`,
		Vector3.new(24, 1.2, 1.2),
		center + Vector3.new(0, 16, -6),
		primary,
		0.05
	)
	makeNeon(
		portal,
		`${name}RingLeft`,
		Vector3.new(1.2, 18, 1.2),
		center + Vector3.new(-11, 9, -6),
		primary,
		0.05
	)
	makeNeon(
		portal,
		`${name}RingRight`,
		Vector3.new(1.2, 18, 1.2),
		center + Vector3.new(11, 9, -6),
		secondary,
		0.05
	)
	local field = makeNeon(
		portal,
		`${name}EnergyField`,
		Vector3.new(18, 13, 0.35),
		center + Vector3.new(0, 8.5, -6.2),
		secondary,
		0.55
	)
	addLight(field, secondary, 1.8, 22)
	addParticleBurst(field, secondary, 3, 1.4, 1.8)

	return pad
end

local function makeFloatingIsland(parent, index, position, scale, accent)
	local island = Instance.new("Folder")
	island.Name = `FloatingIsland{index}`
	island.Parent = parent

	makePart(
		island,
		"IslandTop",
		Vector3.new(20 * scale, 1.8, 14 * scale),
		position,
		PALETTE.navyRaised,
		Enum.Material.Slate,
		{ canCollide = false }
	)
	makeWedge(
		island,
		"IslandKeel",
		Vector3.new(20 * scale, 8 * scale, 14 * scale),
		CFrame.new(position + Vector3.new(0, -4.2 * scale, 0)) * CFrame.Angles(math.rad(180), 0, 0),
		PALETTE.navy,
		Enum.Material.Rock,
		{ canCollide = false }
	)
	makeNeon(
		island,
		"IslandSignal",
		Vector3.new(3 * scale, 3 * scale, 3 * scale),
		position + Vector3.new(0, 3.2 * scale, 0),
		accent,
		0.15
	)
	return island
end

local function makeBlockStack(parent, name, origin, colors)
	local stack = Instance.new("Folder")
	stack.Name = name
	stack.Parent = parent
	for index, color in colors do
		local x = ((index - 1) % 3) * 4 - 4
		local y = math.floor((index - 1) / 3) * 4
		local z = (index % 2 == 0) and 2 or -2
		local block = makeBlock(
			stack,
			`PuzzleBlock{index}`,
			origin + Vector3.new(x, 2.8 + y, z),
			color,
			Vector3.new(3.6, 3.6, 3.6)
		)
		block.CFrame *= CFrame.Angles(0, math.rad(index * 7), 0)
	end
	return stack
end

local function configureLighting()
	Lighting.Technology = Enum.Technology.Future
	Lighting.GlobalShadows = false
	Lighting.Brightness = 2.4
	Lighting.ClockTime = 16.8
	Lighting.ExposureCompensation = 0.1
	Lighting.EnvironmentDiffuseScale = 0.35
	Lighting.EnvironmentSpecularScale = 0.4
	Lighting.Ambient = Color3.fromRGB(62, 73, 105)
	Lighting.OutdoorAmbient = Color3.fromRGB(24, 30, 52)
	Lighting.ColorShift_Top = Color3.fromRGB(96, 156, 255)
	Lighting.ColorShift_Bottom = Color3.fromRGB(138, 92, 246)

	for _, child in Lighting:GetChildren() do
		if child.Name:match("^BlockBlast") then
			child:Destroy()
		end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "BlockBlastAtmosphere"
	atmosphere.Color = Color3.fromRGB(126, 156, 255)
	atmosphere.Decay = Color3.fromRGB(20, 24, 48)
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.08
	atmosphere.Glare = 0.08
	atmosphere.Haze = 1.7
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "BlockBlastBloom"
	bloom.Intensity = 0.28
	bloom.Size = 18
	bloom.Threshold = 1.45
	bloom.Parent = Lighting

	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "BlockBlastColor"
	correction.Brightness = 0.03
	correction.Contrast = 0.08
	correction.Saturation = 0.12
	correction.TintColor = Color3.fromRGB(236, 241, 255)
	correction.Parent = Lighting
end

local function buildArena(parent, arenaIndex, arenaCenter)
	local arena = Instance.new("Folder")
	arena.Name = `BattleArena{arenaIndex}`
	arena.Parent = parent

	makePart(
		arena,
		"ArenaFloor",
		Vector3.new(92, 2, 66),
		arenaCenter + Vector3.new(0, -0.25, 0),
		PALETTE.navy,
		Enum.Material.Metal
	)
	makePart(
		arena,
		"ArenaTrim",
		Vector3.new(100, 0.7, 74),
		arenaCenter + Vector3.new(0, -0.85, 0),
		PALETTE.trim,
		Enum.Material.Metal,
		{ canCollide = false }
	)
	makeNeon(
		arena,
		"CenterEnergyLane",
		Vector3.new(10, 0.35, 58),
		arenaCenter + Vector3.new(0, 1.08, 0),
		PALETTE.blue,
		0.32
	)
	makeNeon(
		arena,
		"AttackChannelA",
		Vector3.new(2, 0.35, 52),
		arenaCenter + Vector3.new(-7, 1.12, 0),
		PALETTE.pink,
		0.42
	)
	makeNeon(
		arena,
		"AttackChannelB",
		Vector3.new(2, 0.35, 52),
		arenaCenter + Vector3.new(7, 1.12, 0),
		PALETTE.cyan,
		0.42
	)

	for side, x in { A = -27, B = 27 } do
		makePart(
			arena,
			`PlayerDeck{side}`,
			Vector3.new(30, 1, 30),
			arenaCenter + Vector3.new(x, 1.1, 0),
			PALETTE.navyRaised,
			Enum.Material.Slate
		)
		makeNeon(
			arena,
			`Deck{side}Frame`,
			Vector3.new(33, 0.35, 33),
			arenaCenter + Vector3.new(x, 1.48, 0),
			side == "A" and PALETTE.blue or PALETTE.pink,
			0.78
		)
	end

	makePart(
		arena,
		"NorthWall",
		Vector3.new(92, 12, 2),
		arenaCenter + Vector3.new(0, 6, -33),
		PALETTE.navyRaised,
		Enum.Material.Metal
	)
	makePart(
		arena,
		"SouthRail",
		Vector3.new(92, 4, 2),
		arenaCenter + Vector3.new(0, 3.2, 33),
		PALETTE.trim,
		Enum.Material.Metal
	)
	makePart(
		arena,
		"LeftRail",
		Vector3.new(2, 5, 66),
		arenaCenter + Vector3.new(-46, 3.2, 0),
		PALETTE.trim,
		Enum.Material.Metal
	)
	makePart(
		arena,
		"RightRail",
		Vector3.new(2, 5, 66),
		arenaCenter + Vector3.new(46, 3.2, 0),
		PALETTE.trim,
		Enum.Material.Metal
	)

	for _, offset in
		{
			Vector3.new(-42, 10, -29),
			Vector3.new(42, 10, -29),
			Vector3.new(-42, 10, 29),
			Vector3.new(42, 10, 29),
		}
	do
		local pillar = makeNeon(
			arena,
			"ArenaGlowPillar",
			Vector3.new(1.6, 18, 1.6),
			arenaCenter + offset,
			PALETTE.purple,
			0.12
		)
		addLight(pillar, PALETTE.purple, 1, 16)
	end

	for index = 1, 10 do
		local z = -25 + (index - 1) * 5.4
		makePart(
			arena,
			`ConveyorTile{index}`,
			Vector3.new(5.4, 0.26, 1.2),
			arenaCenter + Vector3.new(0, 1.34, z),
			index % 2 == 0 and PALETTE.cyan or PALETTE.blue,
			Enum.Material.Neon,
			{ canCollide = false, transparency = 0.32 }
		)
	end

	local scoreboard = makePart(
		arena,
		"Scoreboard",
		Vector3.new(42, 9, 1),
		arenaCenter + Vector3.new(0, 10, -32.5),
		PALETTE.void,
		Enum.Material.SmoothPlastic
	)
	addSurfaceText(
		scoreboard,
		`ARENA {arenaIndex} - BLOCK BLAST BATTLE`,
		Enum.NormalId.Front,
		PALETTE.white
	)
	makeNeon(
		arena,
		"ScoreboardCrown",
		Vector3.new(46, 0.7, 1.4),
		arenaCenter + Vector3.new(0, 15, -32.5),
		PALETTE.gold,
		0.1
	)

	makeBlockStack(
		arena,
		"SpectatorBlocksLeft",
		arenaCenter + Vector3.new(-54, 3, -8),
		{ PALETTE.blue, PALETTE.purple, PALETTE.gold, PALETTE.green, PALETTE.pink }
	)
	makeBlockStack(
		arena,
		"SpectatorBlocksRight",
		arenaCenter + Vector3.new(54, 3, -8),
		{ PALETTE.pink, PALETTE.orange, PALETTE.cyan, PALETTE.blue, PALETTE.green }
	)

	local leftSpawn = makePart(
		arena,
		"PlayerSpawnA",
		Vector3.new(8, 1, 8),
		arenaCenter + Vector3.new(-27, 2.25, 18),
		PALETTE.blue,
		Enum.Material.Neon
	)
	addLabel(leftSpawn, "PLAYER A", "Your board")

	local rightSpawn = makePart(
		arena,
		"PlayerSpawnB",
		Vector3.new(8, 1, 8),
		arenaCenter + Vector3.new(27, 2.25, 18),
		PALETTE.pink,
		Enum.Material.Neon
	)
	addLabel(rightSpawn, "PLAYER B", "Your board")

	local returnPad = makePart(
		arena,
		"ReturnHubPad",
		Vector3.new(12, 1, 8),
		arenaCenter + Vector3.new(0, 2.25, 25),
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	addLabel(returnPad, "HUB", "Return after match")

	return {
		folder = arena,
		index = arenaIndex,
		spawns = { leftSpawn, rightSpawn },
		returnPad = returnPad,
	}
end

local function buildBackground(parent)
	local scenery = Instance.new("Folder")
	scenery.Name = "DistantFloatingScenery"
	scenery.Parent = parent

	local positions = {
		Vector3.new(-96, -2, 50),
		Vector3.new(92, -5, 38),
		Vector3.new(-142, -6, -8),
		Vector3.new(142, -7, -18),
		Vector3.new(-86, -4, -150),
		Vector3.new(88, -3, -156),
	}
	for index, position in positions do
		makeFloatingIsland(
			scenery,
			index,
			position,
			index % 2 == 0 and 0.9 or 1.15,
			BLOCK_COLORS[((index - 1) % #BLOCK_COLORS) + 1]
		)
	end

	for index = 1, 18 do
		local angle = (math.pi * 2) * index / 18
		local radius = 130 + (index % 3) * 28
		local y = 14 + (index % 5) * 8
		local block = makeBlock(
			scenery,
			`DistantPuzzleSilhouette{index}`,
			Vector3.new(math.cos(angle) * radius, y, math.sin(angle) * radius - 60),
			BLOCK_COLORS[((index - 1) % #BLOCK_COLORS) + 1],
			Vector3.new(7, 7, 7)
		)
		block.Transparency = 0.18
		block.CFrame *= CFrame.Angles(math.rad(index * 13), math.rad(index * 19), 0)
		queueSpin(block, 38 + index, Vector3.new(0, 1, 0))
	end
end

local function buildHub(parent)
	makePart(
		parent,
		"MainFloatingPlaza",
		Vector3.new(112, 2, 84),
		Vector3.new(0, 0, 0),
		PALETTE.navyRaised,
		Enum.Material.Slate
	)
	makePart(
		parent,
		"LowerIslandMass",
		Vector3.new(100, 8, 72),
		Vector3.new(0, -5.1, 0),
		PALETTE.navy,
		Enum.Material.Rock,
		{ canCollide = false }
	)
	makeNeon(
		parent,
		"PlazaOuterGlow",
		Vector3.new(118, 0.35, 90),
		Vector3.new(0, 1.18, 0),
		PALETTE.purple,
		0.84
	)

	makePath(parent, "BattlePath", -10, -40, 0, PALETTE.blue)
	makePath(parent, "StoryPath", 9, -18, 34, PALETTE.green)
	makePath(parent, "MarketPath", 8, -18, -34, PALETTE.gold)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(15, 1, 15)
	spawn.Position = Vector3.new(0, 2.25, 22)
	spawn.Color = PALETTE.blue
	spawn.Material = Enum.Material.Neon
	spawn.CastShadow = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = parent
	addLabel(spawn, "BLOCK BLAST", "Floating Puzzle Hub")

	local coreBase = makePart(
		parent,
		"BlockCoreBase",
		Vector3.new(28, 1.2, 28),
		Vector3.new(0, 2.1, 0),
		PALETTE.void,
		Enum.Material.Metal
	)
	makeNeon(
		parent,
		"BlockCoreRing",
		Vector3.new(34, 0.5, 34),
		Vector3.new(0, 3, 0),
		PALETTE.gold,
		0.78
	)
	addLight(coreBase, PALETTE.blue, 2.5, 34)
	for index, color in BLOCK_COLORS do
		local angle = (math.pi * 2) * index / #BLOCK_COLORS
		local block = makeBlock(
			parent,
			`CoreOrbitBlock{index}`,
			Vector3.new(math.cos(angle) * 10, 8 + (index % 2) * 2, math.sin(angle) * 10),
			color,
			Vector3.new(4, 4, 4)
		)
		queueSpin(block, 14 + index, Vector3.new(0, 1, 0))
	end
	local core = makeNeon(
		parent,
		"FloatingBlockCore",
		Vector3.new(7, 7, 7),
		Vector3.new(0, 11, 0),
		PALETTE.cyan,
		0.08
	)
	queueSpin(core, 18, Vector3.new(0, 1, 0))
	addParticleBurst(core, PALETTE.cyan, 4, 1.6, 2.2)

	local battlePad = makePortal(
		parent,
		"BattlePortal",
		Vector3.new(0, 2.25, -36),
		PALETTE.blue,
		PALETTE.pink,
		"BATTLE QUEUE",
		"Clear lines to attack"
	)
	battlePad.Name = "BattleQueuePad"
	battlePad:SetAttribute("QueueMode", "Battle")
	local battlePrompt = addPrompt(battlePad, "Join Queue", "Block Blast Battle")

	local storyPad = makePortal(
		parent,
		"StoryPortal",
		Vector3.new(36, 2.25, -8),
		PALETTE.green,
		PALETTE.purple,
		"STORY MODE",
		"Solo training"
	)
	storyPad.Name = "StoryQueuePad"
	storyPad:SetAttribute("QueueMode", "Story")
	local storyPrompt = addPrompt(storyPad, "Start", "Story Training")

	local marketPad = makePart(
		parent,
		"BlockMarketPlaza",
		Vector3.new(26, 1.1, 20),
		Vector3.new(-36, 2.15, -8),
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	addLabel(marketPad, "BLOCK MARKET", "Shop & Closet")
	makeBlockStack(
		parent,
		"MarketDisplayBlocks",
		Vector3.new(-36, 3.8, -20),
		{ PALETTE.gold, PALETTE.blue, PALETTE.pink, PALETTE.green, PALETTE.purple, PALETTE.orange }
	)
	makeNeon(
		parent,
		"MarketAwningGlow",
		Vector3.new(28, 0.45, 2),
		Vector3.new(-36, 9.4, -18),
		PALETTE.gold,
		0.15
	)

	local guidePad = makePart(
		parent,
		"GuideTrainingCorner",
		Vector3.new(24, 1, 16),
		Vector3.new(0, 2.05, 38),
		PALETTE.trim,
		Enum.Material.Concrete
	)
	addLabel(guidePad, "GUIDE", "Learn shapes")
	for index, color in { PALETTE.blue, PALETTE.green, PALETTE.gold } do
		makeBlock(
			parent,
			`GuideShapeDemo{index}`,
			Vector3.new(-8 + index * 5, 5.1, 38),
			color,
			Vector3.new(3, 3, 3)
		)
	end

	local leaderboard = makePart(
		parent,
		"LeaderboardMonolith",
		Vector3.new(20, 12, 1.2),
		Vector3.new(42, 8, 24),
		PALETTE.void,
		Enum.Material.SmoothPlastic
	)
	addSurfaceText(leaderboard, "LEADERBOARDS", Enum.NormalId.Front, PALETTE.gold)
	makeNeon(
		parent,
		"LeaderboardGoldTrim",
		Vector3.new(22, 0.6, 1.4),
		Vector3.new(42, 14.5, 24),
		PALETTE.gold,
		0.1
	)

	local battleSpawn = makePart(
		parent,
		"BattleArenaSpawn",
		Vector3.new(12, 1, 12),
		Vector3.new(0, 2.25, -54),
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	addLabel(battleSpawn, "ARENA", "Match starts here")
	makePart(
		parent,
		"ArenaBridge",
		Vector3.new(16, 1, 46),
		Vector3.new(0, 1.5, -70),
		PALETTE.navyRaised,
		Enum.Material.Concrete
	)
	makeNeon(
		parent,
		"ArenaBridgeGlow",
		Vector3.new(3, 0.25, 44),
		Vector3.new(0, 2.1, -70),
		PALETTE.blue,
		0.3
	)

	return spawn, battlePrompt, storyPrompt, battleSpawn
end

function HubBuilder.build()
	configureLighting()
	table.clear(animatedParts)

	local existing = workspace:FindFirstChild("BlockBlastHub")
	if existing then
		existing:Destroy()
	end

	local hub = Instance.new("Folder")
	hub.Name = "BlockBlastHub"
	hub.Parent = workspace

	local spawn, battlePrompt, storyPrompt, battleSpawn = buildHub(hub)
	buildBackground(hub)

	local arenas = {}
	for arenaIndex, arenaCenter in ARENA_CENTERS do
		table.insert(arenas, buildArena(hub, arenaIndex, arenaCenter))
	end

	for _, item in animatedParts do
		task.spawn(function()
			while hub.Parent and item.part.Parent do
				local axis = item.axis
				local spin = CFrame.Angles(
					axis.X * math.rad(180),
					axis.Y * math.rad(180),
					axis.Z * math.rad(180)
				)
				local tween = TweenService:Create(
					item.part,
					TweenInfo.new(item.seconds, Enum.EasingStyle.Linear),
					{ CFrame = item.part.CFrame * spin }
				)
				tween:Play()
				tween.Completed:Wait()
			end
		end)
	end

	return {
		hub = hub,
		spawn = spawn,
		battlePrompt = battlePrompt,
		storyPrompt = storyPrompt,
		battleSpawn = battleSpawn,
		arenas = arenas,
		arenaSpawns = arenas[1].spawns,
		arenaReturnPad = arenas[1].returnPad,
	}
end

return HubBuilder
