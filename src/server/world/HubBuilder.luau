local HubBuilder = {}
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local ARENA_CENTERS = {
	Vector3.new(0, 8, -210),
	Vector3.new(135, 8, -205),
	Vector3.new(-135, 8, -205),
}

local PALETTE = {
	grass = Color3.fromRGB(72, 210, 119),
	grassDark = Color3.fromRGB(42, 158, 91),
	stone = Color3.fromRGB(211, 194, 166),
	stoneDark = Color3.fromRGB(156, 139, 118),
	marble = Color3.fromRGB(244, 241, 232),
	water = Color3.fromRGB(38, 172, 255),
	waterDeep = Color3.fromRGB(23, 104, 218),
	gold = Color3.fromRGB(255, 205, 82),
	cyan = Color3.fromRGB(40, 229, 255),
	purple = Color3.fromRGB(167, 109, 255),
	pink = Color3.fromRGB(255, 112, 189),
	orange = Color3.fromRGB(255, 154, 64),
	red = Color3.fromRGB(255, 91, 91),
	wood = Color3.fromRGB(138, 91, 54),
	leaf = Color3.fromRGB(32, 178, 101),
	cloud = Color3.fromRGB(246, 250, 255),
	shadow = Color3.fromRGB(97, 118, 137),
	text = Color3.fromRGB(255, 255, 255),
}

local BLOCK_COLORS = {
	Color3.fromRGB(255, 82, 82),
	Color3.fromRGB(255, 210, 62),
	Color3.fromRGB(63, 219, 118),
	Color3.fromRGB(48, 158, 255),
	Color3.fromRGB(167, 109, 255),
	Color3.fromRGB(255, 112, 189),
}

local queueVisuals = {}
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

local function makeNeon(parent, name, size, positionOrCFrame, color, transparency)
	return makePart(parent, name, size, positionOrCFrame, color, Enum.Material.Neon, {
		canCollide = false,
		transparency = transparency or 0.1,
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

local function addParticles(parent, name, color, rate, lifetime, speed, spread)
	local attachment = Instance.new("Attachment")
	attachment.Name = `{name}Attachment`
	attachment.Parent = parent

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = name
	emitter:SetAttribute("DefaultRate", rate)
	emitter.Color = ColorSequence.new(color)
	emitter.LightEmission = 0.45
	emitter.Rate = rate
	emitter.Lifetime = NumberRange.new(lifetime * 0.75, lifetime)
	emitter.Speed = NumberRange.new(speed * 0.4, speed)
	emitter.SpreadAngle = Vector2.new(spread, spread)
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.35),
		NumberSequenceKeypoint.new(1, 0),
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	emitter.Parent = attachment
	return emitter
end

local function queueSpin(part, seconds, axis)
	table.insert(animatedParts, {
		part = part,
		seconds = seconds,
		axis = axis,
	})
end

local function addBillboard(part, title, subtitle, offset)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Label"
	billboard.Size = UDim2.fromOffset(250, 88)
	billboard.StudsOffset = offset or Vector3.new(0, 5.2, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.fromScale(1, 0.58)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Text = title
	titleLabel.TextColor3 = PALETTE.text
	titleLabel.TextStrokeTransparency = 0.35
	titleLabel.TextScaled = true
	titleLabel.Parent = billboard

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Position = UDim2.fromScale(0, 0.58)
	subtitleLabel.Size = UDim2.fromScale(1, 0.42)
	subtitleLabel.Font = Enum.Font.GothamBold
	subtitleLabel.Text = subtitle
	subtitleLabel.TextColor3 = Color3.fromRGB(235, 248, 255)
	subtitleLabel.TextStrokeTransparency = 0.45
	subtitleLabel.TextScaled = true
	subtitleLabel.Parent = billboard
end

local function addStatusBillboard(part, name, title, subtitle, offset)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = name
	billboard.Size = UDim2.fromOffset(290, 96)
	billboard.StudsOffset = offset or Vector3.new(0, 7, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.fromScale(1, 0.54)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Text = title
	titleLabel.TextColor3 = PALETTE.text
	titleLabel.TextStrokeTransparency = 0.25
	titleLabel.TextScaled = true
	titleLabel.Parent = billboard

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.Name = "Subtitle"
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Position = UDim2.fromScale(0, 0.54)
	subtitleLabel.Size = UDim2.fromScale(1, 0.46)
	subtitleLabel.Font = Enum.Font.GothamBold
	subtitleLabel.Text = subtitle
	subtitleLabel.TextColor3 = Color3.fromRGB(235, 248, 255)
	subtitleLabel.TextStrokeTransparency = 0.35
	subtitleLabel.TextScaled = true
	subtitleLabel.Parent = billboard

	return titleLabel, subtitleLabel
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

local function addPrompt(part, actionText, objectText)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.HoldDuration = 0.2
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = part
	return prompt
end

local function makeIsland(parent, name, center, radius, accent)
	local island = Instance.new("Folder")
	island.Name = name
	island.Parent = parent

	local top = makePart(
		island,
		"GrassTop",
		Vector3.new(radius * 2, 2.4, radius * 2),
		center,
		PALETTE.grass,
		Enum.Material.Grass
	)
	top.Shape = Enum.PartType.Cylinder
	top.CanCollide = true

	local stone = makePart(
		island,
		"StoneRim",
		Vector3.new(radius * 2.08, 2.2, radius * 2.08),
		center - Vector3.new(0, 1.7, 0),
		PALETTE.stone,
		Enum.Material.Rock
	)
	stone.Shape = Enum.PartType.Cylinder
	stone.CanCollide = false

	for index = 1, 10 do
		local angle = (math.pi * 2) * index / 10
		local shelf = makePart(
			island,
			`CliffShelf{index}`,
			Vector3.new(radius * 0.22, 2.2 + (index % 3), radius * 0.38),
			CFrame.new(
				center
					+ Vector3.new(
						math.cos(angle) * (radius * 0.82),
						-3.1 - (index % 2),
						math.sin(angle) * (radius * 0.82)
					)
			) * CFrame.Angles(0, -angle, 0),
			index % 2 == 0 and PALETTE.stone or PALETTE.stoneDark,
			Enum.Material.Rock,
			{ canCollide = false }
		)
		shelf.Transparency = 0.02
	end

	local underside = makePart(
		island,
		"FloatingKeel",
		Vector3.new(radius * 1.35, 10, radius * 1.35),
		center - Vector3.new(0, 8, 0),
		PALETTE.stoneDark,
		Enum.Material.Rock,
		{ canCollide = false }
	)
	underside.Shape = Enum.PartType.Ball
	underside.CFrame *= CFrame.new(0, -2, 0)

	local glow = makeNeon(
		island,
		"IslandMagicGlow",
		Vector3.new(radius * 1.6, 0.22, radius * 1.6),
		center + Vector3.new(0, 1.35, 0),
		accent,
		0.86
	)
	glow.Shape = Enum.PartType.Cylinder

	return island, top
end

local function makeBridge(parent, name, from, to, width, rise)
	local midpoint = (from + to) / 2 + Vector3.new(0, rise or 0, 0)
	local direction = to - from
	local length = Vector3.new(direction.X, 0, direction.Z).Magnitude
	local angle = math.atan2(direction.X, direction.Z)
	local bridge = Instance.new("Folder")
	bridge.Name = name
	bridge.Parent = parent

	local deck = makePart(
		bridge,
		"StoneBridgeDeck",
		Vector3.new(width, 1.1, length),
		CFrame.new(midpoint) * CFrame.Angles(0, angle, 0),
		PALETTE.stone,
		Enum.Material.Cobblestone
	)
	deck.CanCollide = true

	for side, x in { Left = -width / 2 + 0.6, Right = width / 2 - 0.6 } do
		makePart(
			bridge,
			`{side}MarbleRail`,
			Vector3.new(0.55, 2.4, length),
			CFrame.new(midpoint + Vector3.new(math.cos(angle) * x, 1.4, -math.sin(angle) * x))
				* CFrame.Angles(0, angle, 0),
			PALETTE.marble,
			Enum.Material.Marble
		)
	end

	for index = 1, math.max(2, math.floor(length / 18)) do
		local alpha = index / (math.max(2, math.floor(length / 18)) + 1)
		local base = from:Lerp(to, alpha) + Vector3.new(0, 1.1 + (rise or 0), 0)
		for _, side in { -1, 1 } do
			local post = makePart(
				bridge,
				`BridgeLantern{index}_{side}`,
				Vector3.new(1.1, 4.5, 1.1),
				base
					+ Vector3.new(
						math.cos(angle) * side * (width / 2 + 0.9),
						1.9,
						-math.sin(angle) * side * (width / 2 + 0.9)
					),
				PALETTE.wood,
				Enum.Material.Wood
			)
			local lamp = makeNeon(
				bridge,
				`BridgeGlow{index}_{side}`,
				Vector3.new(1.8, 1.8, 1.8),
				post.Position + Vector3.new(0, 3.1, 0),
				PALETTE.gold,
				0.12
			)
			post.CanCollide = false
			lamp.Shape = Enum.PartType.Ball
			addLight(lamp, PALETTE.gold, 0.55, 12)
		end
	end

	return deck
end

local function makeTree(parent, name, base, scale, leafColor)
	local tree = Instance.new("Folder")
	tree.Name = name
	tree.Parent = parent
	makePart(
		tree,
		"Trunk",
		Vector3.new(2.2 * scale, 8 * scale, 2.2 * scale),
		base + Vector3.new(0, 4 * scale, 0),
		PALETTE.wood,
		Enum.Material.Wood
	).CanCollide =
		false
	for index, offset in
		{
			Vector3.new(0, 9, 0),
			Vector3.new(2.5, 8.1, 0.6),
			Vector3.new(-2.4, 8.4, -0.5),
			Vector3.new(0.2, 10.6, -2.2),
		}
	do
		local leaf = makePart(
			tree,
			`LeafCluster{index}`,
			Vector3.new(6.2 * scale, 4.4 * scale, 6.2 * scale),
			base + offset * scale,
			leafColor or PALETTE.leaf,
			Enum.Material.Grass,
			{ canCollide = false }
		)
		leaf.Shape = Enum.PartType.Ball
	end
end

local function makeFlowerPatch(parent, origin, count, radius)
	for index = 1, count do
		local angle = (math.pi * 2) * index / count
		local distance = radius * (0.45 + (index % 4) * 0.12)
		local color = BLOCK_COLORS[((index - 1) % #BLOCK_COLORS) + 1]
		makePart(
			parent,
			`Flower{index}`,
			Vector3.new(0.7, 0.35, 0.7),
			origin + Vector3.new(math.cos(angle) * distance, 1.55, math.sin(angle) * distance),
			color,
			Enum.Material.SmoothPlastic,
			{ canCollide = false }
		)
	end
end

local function makeBench(parent, name, center, rotation)
	local cframe = CFrame.new(center) * CFrame.Angles(0, rotation, 0)
	makePart(
		parent,
		`{name}Seat`,
		Vector3.new(7, 0.8, 2),
		cframe,
		PALETTE.wood,
		Enum.Material.Wood,
		{ canCollide = false }
	)
	makePart(
		parent,
		`{name}Back`,
		Vector3.new(7, 2.5, 0.7),
		cframe * CFrame.new(0, 1.45, 0.9),
		PALETTE.wood,
		Enum.Material.Wood,
		{ canCollide = false }
	)
	for x in { -2.8, 2.8 } do
		makePart(
			parent,
			`{name}Leg{x}`,
			Vector3.new(0.7, 1.5, 0.7),
			cframe * CFrame.new(x, -0.9, 0),
			PALETTE.stoneDark,
			Enum.Material.Slate,
			{ canCollide = false }
		)
	end
end

local function makeWaterfall(parent, name, lip)
	local stream = makePart(
		parent,
		`${name}FallingWater`,
		Vector3.new(5, 34, 0.7),
		lip + Vector3.new(0, -15, 0),
		PALETTE.water,
		Enum.Material.Glass,
		{ canCollide = false, transparency = 0.42 }
	)
	addParticles(stream, `${name}Mist`, PALETTE.cloud, 3, 1.8, 2.5, 35)
	makeNeon(
		parent,
		`${name}EdgeShimmer`,
		Vector3.new(6.5, 0.25, 1),
		lip + Vector3.new(0, 1.3, 0),
		PALETTE.cyan,
		0.38
	)
end

local function makeCloud(parent, name, center, scale)
	local cloud = Instance.new("Folder")
	cloud.Name = name
	cloud.Parent = parent
	for index, offset in
		{
			Vector3.new(0, 0, 0),
			Vector3.new(8, 1, 2),
			Vector3.new(-8, 0.8, -1),
			Vector3.new(2, 2, -7),
			Vector3.new(-2, 1.3, 7),
		}
	do
		local puff = makePart(
			cloud,
			`CloudPuff{index}`,
			Vector3.new(16, 6, 12) * scale,
			center + offset * scale,
			PALETTE.cloud,
			Enum.Material.SmoothPlastic,
			{ canCollide = false, transparency = 0.22 }
		)
		puff.Shape = Enum.PartType.Ball
	end
	return cloud
end

local function makeBlockStatue(parent, name, origin, colors)
	local statue = Instance.new("Folder")
	statue.Name = name
	statue.Parent = parent
	for index, data in colors do
		makePart(
			statue,
			`StatueBlock{index}`,
			Vector3.new(4, 4, 4),
			origin + data.offset,
			data.color,
			Enum.Material.SmoothPlastic,
			{ canCollide = false }
		)
	end
end

local function makePortal(parent, name, center, primary, secondary, title, subtitle)
	local portal = Instance.new("Folder")
	portal.Name = name
	portal.Parent = parent

	local pad = makePart(
		portal,
		`${name}Pad`,
		Vector3.new(22, 1.2, 18),
		center,
		primary,
		Enum.Material.SmoothPlastic
	)
	addBillboard(pad, title, subtitle)

	for side, x in { Left = -9, Right = 9 } do
		local column = makePart(
			portal,
			`${side}Column`,
			Vector3.new(2.2, 17, 2.2),
			center + Vector3.new(x, 8.5, -5.8),
			PALETTE.marble,
			Enum.Material.Marble
		)
		makeNeon(
			portal,
			`${side}ColumnGlow`,
			Vector3.new(2.7, 1.1, 2.7),
			column.Position + Vector3.new(0, 8.6, 0),
			secondary,
			0.15
		)
	end
	makePart(
		portal,
		"StoneArchTop",
		Vector3.new(23, 2.2, 2.2),
		center + Vector3.new(0, 17, -5.8),
		PALETTE.marble,
		Enum.Material.Marble
	)
	local field = makeNeon(
		portal,
		"PortalEnergy",
		Vector3.new(15, 12, 0.35),
		center + Vector3.new(0, 9.4, -6),
		secondary,
		0.48
	)
	addLight(field, secondary, 1.8, 26)
	addParticles(field, "PortalSparkles", secondary, 3, 1.5, 2.2, 22)

	return pad
end

local function configureLighting()
	Lighting.Technology = Enum.Technology.Future
	Lighting.GlobalShadows = false
	Lighting.Brightness = 3
	Lighting.ClockTime = 17.35
	Lighting.ExposureCompensation = 0.05
	Lighting.EnvironmentDiffuseScale = 0.45
	Lighting.EnvironmentSpecularScale = 0.55
	Lighting.Ambient = Color3.fromRGB(152, 174, 195)
	Lighting.OutdoorAmbient = Color3.fromRGB(130, 152, 176)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 205, 145)
	Lighting.ColorShift_Bottom = Color3.fromRGB(131, 202, 255)

	for _, child in Lighting:GetChildren() do
		if child.Name:match("^BlockBlast") then
			child:Destroy()
		end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "BlockBlastAtmosphere"
	atmosphere.Color = Color3.fromRGB(180, 220, 255)
	atmosphere.Decay = Color3.fromRGB(255, 192, 145)
	atmosphere.Density = 0.22
	atmosphere.Offset = 0.12
	atmosphere.Glare = 0.16
	atmosphere.Haze = 1.35
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "BlockBlastBloom"
	bloom.Intensity = 0.22
	bloom.Size = 20
	bloom.Threshold = 1.55
	bloom.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Name = "BlockBlastSunRays"
	rays.Intensity = 0.035
	rays.Spread = 0.65
	rays.Parent = Lighting

	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "BlockBlastColor"
	correction.Brightness = 0.035
	correction.Contrast = 0.06
	correction.Saturation = 0.16
	correction.TintColor = Color3.fromRGB(255, 244, 228)
	correction.Parent = Lighting

	local depth = Instance.new("DepthOfFieldEffect")
	depth.Name = "BlockBlastDepthOfField"
	depth.FarIntensity = 0.08
	depth.FocusDistance = 170
	depth.InFocusRadius = 70
	depth.NearIntensity = 0
	depth.Parent = Lighting
end

local function buildMainIsland(parent)
	local island, top =
		makeIsland(parent, "MainSpawnIsland", Vector3.new(0, 6, 0), 58, PALETTE.cyan)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.Position = Vector3.new(0, 8.6, 28)
	spawn.Color = PALETTE.cyan
	spawn.Material = Enum.Material.Neon
	spawn.CastShadow = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Enabled = true
	spawn.CanCollide = true
	spawn.CanTouch = false
	spawn.CanQuery = true
	spawn.Parent = island
	addBillboard(spawn, "BLOCK BLAST", "Floating Battle Hub")

	for radiusIndex, radius in { 18, 32, 47 } do
		local ring = makePart(
			island,
			`StonePathRing{radiusIndex}`,
			Vector3.new(radius * 2, 0.35, radius * 2),
			Vector3.new(0, 7.38 + radiusIndex * 0.03, 0),
			radiusIndex == 2 and PALETTE.marble or PALETTE.stone,
			Enum.Material.Cobblestone,
			{ canCollide = false, transparency = 0.14 + radiusIndex * 0.05 }
		)
		ring.Shape = Enum.PartType.Cylinder
	end

	for index = 1, 14 do
		local angle = (math.pi * 2) * index / 14
		local radius = index % 2 == 0 and 44 or 36
		local pebble = makePart(
			island,
			`PathPebble{index}`,
			Vector3.new(4 + (index % 3), 0.35, 3),
			CFrame.new(Vector3.new(math.cos(angle) * radius, 7.75, math.sin(angle) * radius))
				* CFrame.Angles(0, -angle, 0),
			index % 2 == 0 and PALETTE.stone or PALETTE.marble,
			Enum.Material.Cobblestone,
			{ canCollide = false }
		)
		pebble.Transparency = 0.05
	end

	local coreBase = makePart(
		island,
		"CenterMarbleDais",
		Vector3.new(24, 2, 24),
		Vector3.new(0, 8.05, 0),
		PALETTE.marble,
		Enum.Material.Marble
	)
	coreBase.Shape = Enum.PartType.Cylinder
	local core = makeNeon(
		island,
		"FloatingBlockCore",
		Vector3.new(8, 8, 8),
		Vector3.new(0, 18, 0),
		PALETTE.cyan,
		0.05
	)
	core.CFrame *= CFrame.Angles(math.rad(18), math.rad(28), math.rad(12))
	queueSpin(core, 18, Vector3.new(0, 1, 0))
	addLight(core, PALETTE.cyan, 3, 46)
	addParticles(core, "CoreEnergy", PALETTE.cyan, 5, 1.8, 2.3, 30)

	local beam = makeNeon(
		island,
		"SkyEnergyBeam",
		Vector3.new(3.5, 88, 3.5),
		Vector3.new(0, 61, 0),
		PALETTE.purple,
		0.68
	)
	beam.Shape = Enum.PartType.Cylinder
	queueSpin(beam, 30, Vector3.new(0, 1, 0))

	for index, color in BLOCK_COLORS do
		local angle = (math.pi * 2) * index / #BLOCK_COLORS
		local block = makePart(
			island,
			`OrbitLogoBlock{index}`,
			Vector3.new(4, 4, 4),
			Vector3.new(math.cos(angle) * 14, 17 + (index % 2) * 3, math.sin(angle) * 14),
			color,
			Enum.Material.SmoothPlastic,
			{ canCollide = false }
		)
		queueSpin(block, 14 + index, Vector3.new(0, 1, 0))
	end

	for index, treeData in
		{
			{ pos = Vector3.new(-38, 8, 25), scale = 1.15 },
			{ pos = Vector3.new(40, 8, 18), scale = 0.95 },
			{ pos = Vector3.new(-32, 8, -30), scale = 1 },
			{ pos = Vector3.new(34, 8, -34), scale = 1.1 },
		}
	do
		makeTree(
			island,
			`CustomTree{index}`,
			treeData.pos,
			treeData.scale,
			index % 2 == 0 and PALETTE.grassDark or PALETTE.leaf
		)
	end
	makeFlowerPatch(island, Vector3.new(-25, 7, 18), 18, 12)
	makeFlowerPatch(island, Vector3.new(29, 7, -19), 16, 10)
	makeBench(island, "NorthBench", Vector3.new(-18, 8.2, 39), math.rad(25))
	makeBench(island, "SouthBench", Vector3.new(22, 8.2, 35), math.rad(-20))
	makeWaterfall(island, "EastWaterfall", Vector3.new(58, 7, 5))
	makeWaterfall(island, "WestWaterfall", Vector3.new(-58, 7, -8))

	makeBlockStatue(island, "PuzzleBlockStatue", Vector3.new(-6, 10, -43), {
		{ offset = Vector3.new(0, 0, 0), color = PALETTE.gold },
		{ offset = Vector3.new(4.2, 0, 0), color = PALETTE.gold },
		{ offset = Vector3.new(-4.2, 0, 0), color = PALETTE.gold },
		{ offset = Vector3.new(0, 4.2, 0), color = PALETTE.cyan },
		{ offset = Vector3.new(0, 8.4, 0), color = PALETTE.purple },
	})

	return island, top, spawn
end

local function buildSideIslands(parent)
	local training, trainingTop =
		makeIsland(parent, "TrainingIsland", Vector3.new(-92, 11, -18), 31, PALETTE.orange)
	makeBridge(
		parent,
		"TrainingBridge",
		Vector3.new(-42, 8.1, -8),
		Vector3.new(-66, 12, -15),
		11,
		1
	)
	addBillboard(trainingTop, "TRAINING", "Practice combos", Vector3.new(0, 8, 0))
	for index = 1, 4 do
		local dummy = makePart(
			training,
			`TrainingDummy{index}`,
			Vector3.new(4, 8, 4),
			Vector3.new(-108 + index * 8, 16, -23),
			PALETTE.orange,
			Enum.Material.SmoothPlastic
		)
		addParticles(dummy, `PracticePop{index}`, BLOCK_COLORS[index], 1.4, 1.1, 1.5, 28)
	end
	makePart(
		training,
		"SandboxCrates",
		Vector3.new(12, 5, 8),
		Vector3.new(-84, 14.5, 3),
		PALETTE.wood,
		Enum.Material.Wood
	)

	local leaderboard, leaderboardTop =
		makeIsland(parent, "LeaderboardIsland", Vector3.new(92, 12, -16), 33, PALETTE.gold)
	makeBridge(
		parent,
		"LeaderboardBridge",
		Vector3.new(42, 8.1, -8),
		Vector3.new(66, 12.2, -15),
		11,
		1
	)
	local board = makePart(
		leaderboard,
		"LeaderboardWall",
		Vector3.new(32, 18, 2),
		Vector3.new(92, 23, -33),
		PALETTE.marble,
		Enum.Material.Marble
	)
	addSurfaceText(board, "TOP PLAYERS", Enum.NormalId.Front, PALETTE.gold)
	makeBlockStatue(leaderboard, "TrophyStatues", Vector3.new(80, 15, 3), {
		{ offset = Vector3.new(0, 0, 0), color = PALETTE.gold },
		{ offset = Vector3.new(0, 4, 0), color = PALETTE.gold },
		{ offset = Vector3.new(-4, 0, 0), color = PALETTE.gold },
		{ offset = Vector3.new(4, 0, 0), color = PALETTE.gold },
	})
	addBillboard(leaderboardTop, "LEADERBOARDS", "Wins and scores", Vector3.new(0, 8, 0))

	local portalIsland, portalTop =
		makeIsland(parent, "PortalIsland", Vector3.new(0, 13, -82), 38, PALETTE.purple)
	makeBridge(parent, "PortalBridge", Vector3.new(0, 8.1, -45), Vector3.new(0, 13.2, -48), 13, 1.5)
	local battlePad = makePortal(
		portalIsland,
		"BattlePortal",
		Vector3.new(0, 16, -82),
		PALETTE.cyan,
		PALETTE.pink,
		"BATTLE QUEUE",
		"Casual matches"
	)
	battlePad.Name = "BattleQueuePad"
	battlePad:SetAttribute("QueueMode", "Battle")
	local battlePrompt = addPrompt(battlePad, "Join Queue", "Block Blast Battle")
	local battleTitle, battleSubtitle = addStatusBillboard(
		battlePad,
		"QueueStatus",
		"BATTLE QUEUE",
		"0 queued - step here or use Hub UI"
	)
	queueVisuals.battlePad = battlePad
	queueVisuals.battleTitle = battleTitle
	queueVisuals.battleSubtitle = battleSubtitle
	for index, portalData in
		{
			{ name = "RankedPortal", x = -22, title = "RANKED", color = PALETTE.gold },
			{ name = "DuelsPortal", x = 22, title = "DUELS", color = PALETTE.cyan },
			{ name = "EventsPortal", x = 0, title = "EVENTS", color = PALETTE.purple },
		}
	do
		local pad = makePart(
			portalIsland,
			portalData.name,
			Vector3.new(12, 1, 10),
			Vector3.new(portalData.x, 15.8, -102 + index * 6),
			portalData.color,
			Enum.Material.SmoothPlastic
		)
		addBillboard(pad, portalData.title, "Coming soon", Vector3.new(0, 4.8, 0))
	end
	portalTop.Name = "PortalIslandTop"

	local storyIsland, storyTop =
		makeIsland(parent, "StoryIsland", Vector3.new(74, 17, 70), 28, PALETTE.purple)
	makeBridge(parent, "StoryBridge", Vector3.new(34, 8.1, 34), Vector3.new(55, 16.2, 55), 10, 3)
	local storyPad = makePortal(
		storyIsland,
		"StoryPortal",
		Vector3.new(74, 20, 70),
		PALETTE.purple,
		PALETTE.cyan,
		"STORY MODE",
		"Solo training"
	)
	storyPad.Name = "StoryQueuePad"
	storyPad:SetAttribute("QueueMode", "Story")
	local storyPrompt = addPrompt(storyPad, "Start", "Story Training")
	local storyTitle, storySubtitle =
		addStatusBillboard(storyPad, "StoryStatus", "STORY MODE", "Solo missions - safe practice")
	queueVisuals.storyTitle = storyTitle
	queueVisuals.storySubtitle = storySubtitle
	makeTree(storyIsland, "GlowingStoryTree", Vector3.new(59, 19, 83), 0.9, PALETTE.purple)
	storyTop.Name = "StoryIslandTop"

	local vipIsland, vipTop =
		makeIsland(parent, "VIPIsland", Vector3.new(-80, 18, 72), 29, PALETTE.gold)
	makeBridge(parent, "VIPBridge", Vector3.new(-34, 8.1, 34), Vector3.new(-57, 17.2, 55), 10, 3)
	local fountain = makePart(
		vipIsland,
		"VIPFountain",
		Vector3.new(18, 2, 18),
		Vector3.new(-80, 20, 72),
		PALETTE.marble,
		Enum.Material.Marble
	)
	fountain.Shape = Enum.PartType.Cylinder
	local water = makeNeon(
		vipIsland,
		"FountainWater",
		Vector3.new(12, 0.6, 12),
		Vector3.new(-80, 21.5, 72),
		PALETTE.water,
		0.25
	)
	water.Shape = Enum.PartType.Cylinder
	addParticles(water, "FountainMist", PALETTE.cloud, 2.5, 1.2, 2, 45)
	for index = 1, 3 do
		makeTree(
			vipIsland,
			`VIPPalm{index}`,
			Vector3.new(-98 + index * 9, 20, 88),
			0.75,
			PALETTE.grass
		)
	end
	addBillboard(vipTop, "VIP ISLAND", "Gold lounge", Vector3.new(0, 8, 0))
	vipTop.Name = "VIPIslandTop"

	local secret, secretTop =
		makeIsland(parent, "SecretsIsland", Vector3.new(0, -3, 95), 22, PALETTE.cyan)
	makeBridge(
		parent,
		"SecretLowerBridge",
		Vector3.new(0, 7.7, 48),
		Vector3.new(0, -1.8, 73),
		8,
		-1
	)
	addBillboard(secretTop, "SECRET CAVE", "Explore below", Vector3.new(0, 8, 0))
	makePart(
		secret,
		"CaveMouth",
		Vector3.new(14, 8, 2),
		Vector3.new(0, 0.5, 75),
		PALETTE.stoneDark,
		Enum.Material.Rock
	)
	makePart(
		secret,
		"SecretChest",
		Vector3.new(7, 4, 5),
		Vector3.new(0, 0.8, 103),
		PALETTE.gold,
		Enum.Material.Wood
	)
	for index = 1, 5 do
		makePart(
			secret,
			`ObbyStep{index}`,
			Vector3.new(8, 1, 8),
			Vector3.new(-18 + index * 9, 0.5 + index * 0.8, 82 + index * 3),
			BLOCK_COLORS[index],
			Enum.Material.SmoothPlastic
		)
	end
	secretTop.Name = "SecretsIslandTop"

	return battlePrompt, storyPrompt
end

local function buildArena(parent, arenaIndex, arenaCenter)
	local arena = Instance.new("Folder")
	arena.Name = `BattleArena{arenaIndex}`
	arena.Parent = parent

	local _, top = makeIsland(
		arena,
		"ArenaFloatingIsland",
		arenaCenter + Vector3.new(0, 0, 0),
		44,
		arenaIndex == 1 and PALETTE.cyan or PALETTE.purple
	)
	top.Name = "ArenaFloor"
	makePart(
		arena,
		"ArenaBattleDeck",
		Vector3.new(76, 1, 48),
		arenaCenter + Vector3.new(0, 2.7, 0),
		PALETTE.marble,
		Enum.Material.Marble
	)
	makeNeon(
		arena,
		"CenterEnergyLane",
		Vector3.new(8, 0.3, 44),
		arenaCenter + Vector3.new(0, 3.3, 0),
		PALETTE.cyan,
		0.35
	)

	for side, x in { A = -24, B = 24 } do
		makePart(
			arena,
			`PlayerDeck{side}`,
			Vector3.new(25, 1, 28),
			arenaCenter + Vector3.new(x, 3.5, 0),
			side == "A" and PALETTE.cyan or PALETTE.pink,
			Enum.Material.SmoothPlastic
		)
	end

	local scoreboard = makePart(
		arena,
		"Scoreboard",
		Vector3.new(42, 10, 2),
		arenaCenter + Vector3.new(0, 17, -33),
		PALETTE.marble,
		Enum.Material.Marble
	)
	addSurfaceText(scoreboard, `ARENA {arenaIndex}`, Enum.NormalId.Front, PALETTE.gold)
	addLight(scoreboard, PALETTE.gold, 0.8, 20)

	local leftSpawn = makePart(
		arena,
		"PlayerSpawnA",
		Vector3.new(8, 1, 8),
		arenaCenter + Vector3.new(-24, 5.2, 18),
		PALETTE.cyan,
		Enum.Material.Neon
	)
	addBillboard(leftSpawn, "PLAYER A", "Your board")
	local rightSpawn = makePart(
		arena,
		"PlayerSpawnB",
		Vector3.new(8, 1, 8),
		arenaCenter + Vector3.new(24, 5.2, 18),
		PALETTE.pink,
		Enum.Material.Neon
	)
	addBillboard(rightSpawn, "PLAYER B", "Your board")
	local returnPad = makePart(
		arena,
		"ReturnHubPad",
		Vector3.new(12, 1, 8),
		arenaCenter + Vector3.new(0, 5.2, 27),
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	addBillboard(returnPad, "HUB", "Return after match")

	for index = 1, 8 do
		local angle = (math.pi * 2) * index / 8
		local pillar = makePart(
			arena,
			`ArenaColumn{index}`,
			Vector3.new(2, 9, 2),
			arenaCenter + Vector3.new(math.cos(angle) * 39, 8, math.sin(angle) * 32),
			PALETTE.marble,
			Enum.Material.Marble
		)
		local crystal = makeNeon(
			arena,
			`ArenaCrystal{index}`,
			Vector3.new(2.4, 2.4, 2.4),
			pillar.Position + Vector3.new(0, 5.8, 0),
			BLOCK_COLORS[((index - 1) % #BLOCK_COLORS) + 1],
			0.1
		)
		crystal.Shape = Enum.PartType.Ball
	end

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

	for index = 1, 18 do
		local angle = (math.pi * 2) * index / 18
		local radius = 145 + (index % 4) * 28
		makeCloud(
			scenery,
			`CloudBank{index}`,
			Vector3.new(
				math.cos(angle) * radius,
				-24 - (index % 3) * 4,
				math.sin(angle) * radius - 35
			),
			1 + (index % 3) * 0.18
		)
	end

	for index = 1, 12 do
		local angle = (math.pi * 2) * index / 12
		local rock = makePart(
			scenery,
			`FloatingRock{index}`,
			Vector3.new(8 + index % 4, 6 + index % 3, 8 + index % 5),
			Vector3.new(math.cos(angle) * 120, 12 + (index % 5) * 6, math.sin(angle) * 135 - 60),
			PALETTE.stoneDark,
			Enum.Material.Rock,
			{ canCollide = false }
		)
		rock.CFrame *= CFrame.Angles(math.rad(index * 11), math.rad(index * 19), 0)
		queueSpin(rock, 48 + index, Vector3.new(0, 1, 0))
	end

	local birdAnchor = makePart(
		scenery,
		"BirdParticleAnchor",
		Vector3.new(1, 1, 1),
		Vector3.new(0, 60, -35),
		PALETTE.cloud,
		Enum.Material.SmoothPlastic,
		{
			canCollide = false,
			canQuery = false,
			transparency = 1,
		}
	)
	addParticles(birdAnchor, "DistantBirds", PALETTE.cloud, 1.2, 6, 10, 70)

	local leavesAnchor = makePart(
		scenery,
		"LeavesParticleAnchor",
		Vector3.new(1, 1, 1),
		Vector3.new(0, 28, 0),
		PALETTE.grass,
		Enum.Material.SmoothPlastic,
		{
			canCollide = false,
			canQuery = false,
			transparency = 1,
		}
	)
	addParticles(leavesAnchor, "DriftingLeaves", PALETTE.grass, 2.2, 5, 4, 80)
end

local function buildHub(parent)
	local _, _, spawn = buildMainIsland(parent)
	local battlePrompt, storyPrompt = buildSideIslands(parent)
	buildBackground(parent)

	local battleSpawn = makePart(
		parent,
		"BattleArenaSpawn",
		Vector3.new(14, 1, 14),
		Vector3.new(0, 18, -126),
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)
	addBillboard(battleSpawn, "ARENAS", "Match starts here")
	makeBridge(
		parent,
		"ArenaMainBridge",
		Vector3.new(0, 15.2, -114),
		Vector3.new(0, 10.6, -166),
		13,
		-1
	)

	return spawn, battlePrompt, storyPrompt, battleSpawn
end

local function buildRecoveryPlatform(parent, hubSpawn)
	local platform = makePart(
		parent,
		"VoidRecoveryPlatform",
		Vector3.new(280, 2, 280),
		Vector3.new(0, -70, -20),
		PALETTE.cloud,
		Enum.Material.SmoothPlastic,
		{
			transparency = 0.9,
		}
	)
	platform.CanCollide = true
	platform.CanTouch = true
	platform.CanQuery = true

	platform.Touched:Connect(function(hit)
		local character = hit and hit.Parent
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoid and rootPart and humanoid.Health > 0 then
			character:PivotTo(hubSpawn.CFrame + Vector3.new(0, 7, 0))
		end
	end)

	return platform
end

function HubBuilder.build()
	configureLighting()
	table.clear(animatedParts)
	table.clear(queueVisuals)

	local existing = workspace:FindFirstChild("BlockBlastHub")
	if existing then
		existing:Destroy()
	end

	local hub = Instance.new("Folder")
	hub.Name = "BlockBlastHub"
	hub.Parent = workspace

	local spawn, battlePrompt, storyPrompt, battleSpawn = buildHub(hub)
	local recoveryPlatform = buildRecoveryPlatform(hub, spawn)

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
		recoveryPlatform = recoveryPlatform,
		arenas = arenas,
		arenaSpawns = arenas[1].spawns,
		arenaReturnPad = arenas[1].returnPad,
	}
end

function HubBuilder.setQueueVisuals(queueCount, minPlayers, secondsToSoloStart, openArenas)
	queueCount = queueCount or 0
	minPlayers = minPlayers or 2
	openArenas = openArenas or 0

	if queueVisuals.battleSubtitle then
		local queueText = `{queueCount}/{minPlayers} queued`
		if openArenas <= 0 then
			queueText = "Arenas full - wait for return"
		elseif queueCount > 0 and secondsToSoloStart and secondsToSoloStart > 0 then
			queueText ..= ` - solo in {secondsToSoloStart}s`
		else
			queueText ..= " - step here or use Hub UI"
		end
		queueVisuals.battleSubtitle.Text = queueText
	end

	if queueVisuals.battleTitle then
		queueVisuals.battleTitle.Text = queueCount > 0 and "QUEUE ACTIVE" or "BATTLE QUEUE"
	end

	if queueVisuals.battlePad then
		queueVisuals.battlePad.Color = queueCount > 0 and PALETTE.pink or PALETTE.cyan
	end

	if queueVisuals.storySubtitle then
		queueVisuals.storySubtitle.Text = openArenas > 0 and "Solo missions - safe practice"
			or "Arena busy - try soon"
	end
end

return HubBuilder
