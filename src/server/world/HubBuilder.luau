local HubBuilder = {}
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ExperienceConfig = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("game"):WaitForChild("ExperienceConfig")
)

local ARENA_CENTERS = {
	Vector3.new(0, 8, -430),
	Vector3.new(190, 8, -440),
	Vector3.new(-190, 8, -440),
}

local PALETTE = {
	grass = Color3.fromRGB(137, 255, 206),
	grassDark = Color3.fromRGB(88, 214, 168),
	stone = Color3.fromRGB(255, 214, 235),
	stoneDark = Color3.fromRGB(219, 158, 197),
	marble = Color3.fromRGB(255, 247, 250),
	waterDeep = Color3.fromRGB(219, 86, 153),
	gold = Color3.fromRGB(255, 229, 120),
	cyan = Color3.fromRGB(137, 207, 255),
	purple = Color3.fromRGB(190, 150, 255),
	pink = Color3.fromRGB(255, 133, 193),
	orange = Color3.fromRGB(255, 163, 102),
	red = Color3.fromRGB(255, 99, 132),
	cloud = Color3.fromRGB(255, 240, 247),
	text = Color3.fromRGB(255, 255, 255),
}
PALETTE.water = PALETTE.pink
PALETTE.wood = PALETTE.marble
PALETTE.leaf = PALETTE.grass
PALETTE.shadow = PALETTE.stoneDark

local BLOCK_COLORS = {
	PALETTE.pink,
	PALETTE.cyan,
	PALETTE.grass,
	PALETTE.gold,
	PALETTE.purple,
	PALETTE.orange,
}

local queueVisuals = {}
local animatedParts = {}
local HUB_TERRAIN_CENTER = Vector3.new(0, 0, 0)
local HUB_TERRAIN_CLEAR_SIZE = Vector3.new(260, 110, 260)

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

local function addSound(parent, name, soundId, volume, pitch)
	local sound = Instance.new("Sound")
	sound.Name = name
	sound.SoundId = soundId
	sound.Volume = volume or 0.35
	sound.PlaybackSpeed = pitch or 1
	sound.RollOffMaxDistance = 60
	sound.RollOffMinDistance = 8
	sound.Parent = parent
	return sound
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
	billboard.Size = UDim2.fromOffset(170, subtitle == "" and 42 or 62)
	billboard.StudsOffset = offset or Vector3.new(0, 4.4, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 105
	billboard.Parent = part

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = subtitle == "" and UDim2.fromScale(1, 1) or UDim2.fromScale(1, 0.62)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Text = title
	titleLabel.TextColor3 = PALETTE.text
	titleLabel.TextStrokeTransparency = 0.42
	titleLabel.TextScaled = true
	titleLabel.Parent = billboard

	local subtitleLabel = Instance.new("TextLabel")
	subtitleLabel.BackgroundTransparency = 1
	subtitleLabel.Position = UDim2.fromScale(0, 0.62)
	subtitleLabel.Size = UDim2.fromScale(1, 0.38)
	subtitleLabel.Font = Enum.Font.GothamBold
	subtitleLabel.Text = subtitle
	subtitleLabel.TextColor3 = Color3.fromRGB(235, 248, 255)
	subtitleLabel.TextStrokeTransparency = 0.52
	subtitleLabel.TextScaled = true
	subtitleLabel.Visible = subtitle ~= ""
	subtitleLabel.Parent = billboard

	return billboard, titleLabel, subtitleLabel
end

local function addStatusBillboard(part, name, title, subtitle, offset)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = name
	billboard.Size = UDim2.fromOffset(190, 66)
	billboard.StudsOffset = offset or Vector3.new(0, 5.8, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 55
	billboard.Parent = part

	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.fromScale(1, 0.54)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Text = title
	titleLabel.TextColor3 = PALETTE.text
	titleLabel.TextStrokeTransparency = 0.4
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
	subtitleLabel.TextStrokeTransparency = 0.55
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

local function clearHubTerrain()
	workspace.Terrain:FillBlock(
		CFrame.new(HUB_TERRAIN_CENTER + Vector3.new(0, -8, 0)),
		HUB_TERRAIN_CLEAR_SIZE,
		Enum.Material.Air
	)
end

local function fillTerrainBall(center, radius, material)
	workspace.Terrain:FillBall(center, radius, material)
end

local function fillTerrainBlock(center, size, material, rotationY)
	workspace.Terrain:FillBlock(
		CFrame.new(center) * CFrame.Angles(0, rotationY or 0, 0),
		size,
		material
	)
end

local function safeLightingSet(property, value)
	local ok, err = pcall(function()
		Lighting[property] = value
	end)
	if not ok then
		warn(`Block Blast lighting skipped {property}: {err}`)
	end
end

local function removeBootstrapSafetyParts()
	for _, name in { "BootstrapHubSafetyFloor", "BootstrapHubSpawn" } do
		local object = workspace:FindFirstChild(name)
		if object then
			object:Destroy()
		end
	end
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

local CANDY_PUFF_OFFSETS = {
	Vector3.new(0, 0, 0),
	Vector3.new(3.2, 0.6, 1.4),
	Vector3.new(-3.4, 0.4, -1.2),
	Vector3.new(1.6, 1.2, -2.6),
	Vector3.new(-1.8, 0.9, 2.4),
}

local function makeCloud(parent, name, center, scale, options)
	options = options or {}
	local cloud = Instance.new("Folder")
	cloud.Name = name
	cloud.Parent = parent
	local offsets = options.offsets
		or {
			Vector3.new(0, 0, 0),
			Vector3.new(8, 1, 2),
			Vector3.new(-8, 0.8, -1),
			Vector3.new(2, 2, -7),
			Vector3.new(-2, 1.3, 7),
		}
	local puffSize = options.puffSize or Vector3.new(16, 6, 12)
	for index, offset in offsets do
		local puff = makePart(
			cloud,
			`CloudPuff{index}`,
			puffSize * scale,
			center + offset * scale,
			options.color or PALETTE.cloud,
			options.material or Enum.Material.SmoothPlastic,
			{ canCollide = false, transparency = options.transparency or 0.22 }
		)
		puff.Shape = Enum.PartType.Ball
	end
	return cloud
end

local function makeFestivalFlags(parent, name, startPosition, endPosition, count)
	local flags = Instance.new("Folder")
	flags.Name = name
	flags.Parent = parent
	local delta = endPosition - startPosition
	for index = 1, count do
		local alpha = index / (count + 1)
		local position = startPosition + delta * alpha
		local flag = makePart(
			flags,
			`Flag{index}`,
			Vector3.new(3, 2.2, 0.25),
			CFrame.new(position) * CFrame.Angles(0, math.atan2(delta.X, delta.Z), 0),
			BLOCK_COLORS[((index - 1) % #BLOCK_COLORS) + 1],
			Enum.Material.SmoothPlastic,
			{ canCollide = false }
		)
		flag.Transparency = 0.02
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

local function makeZoneFolder(parent, name)
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function makePathSlab(parent, name, center, size, rotation, color)
	local slab = makePart(
		parent,
		name,
		size,
		CFrame.new(center) * CFrame.Angles(0, rotation or 0, 0),
		color or PALETTE.stone,
		Enum.Material.Cobblestone,
		{ canCollide = false }
	)
	slab.Transparency = 0.04
	return slab
end

local function makeLowPolyRock(parent, name, center, scale, color)
	local cluster = makeZoneFolder(parent, name)
	local rockColor = color or PALETTE.stoneDark
	for index, offset in
		{
			Vector3.new(0, 0, 0),
			Vector3.new(2.4, 0.8, 0.7),
			Vector3.new(-2, 0.6, -0.5),
			Vector3.new(0.6, 1.6, -1.8),
		}
	do
		local rock = makePart(
			cluster,
			`RockFacet{index}`,
			Vector3.new(5.5, 3.6, 4.8) * scale * (0.85 + index * 0.06),
			center + offset * scale,
			index % 2 == 0 and rockColor or PALETTE.stone,
			Enum.Material.Rock,
			{ canCollide = false, shape = Enum.PartType.Ball }
		)
		rock.CFrame *= CFrame.Angles(
			math.rad(index * 13),
			math.rad(index * 29),
			math.rad(index * 7)
		)
	end
	return cluster
end

local function makeLamp(parent, name, center, color)
	local lamp = makeZoneFolder(parent, name)
	makePart(
		lamp,
		"Post",
		Vector3.new(0.9, 6.4, 0.9),
		center + Vector3.new(0, 3.2, 0),
		PALETTE.wood,
		Enum.Material.Wood,
		{ canCollide = false }
	)
	local cap = makePart(
		lamp,
		"Cap",
		Vector3.new(3.1, 0.55, 3.1),
		center + Vector3.new(0, 6.7, 0),
		PALETTE.stoneDark,
		Enum.Material.Slate,
		{ canCollide = false }
	)
	local glow = makeNeon(
		lamp,
		"Glow",
		Vector3.new(2.1, 2.1, 2.1),
		center + Vector3.new(0, 5.55, 0),
		color or PALETTE.gold,
		0.16
	)
	glow.Shape = Enum.PartType.Ball
	addLight(glow, color or PALETTE.gold, 0.35, 10)
	cap.CanCollide = false
	return lamp
end

local function makeBanner(parent, name, center, rotation, color, label)
	local banner = makeZoneFolder(parent, name)
	local cframe = CFrame.new(center) * CFrame.Angles(0, rotation or 0, 0)
	makePart(
		banner,
		"Pole",
		Vector3.new(0.8, 9, 0.8),
		cframe * CFrame.new(0, 4.5, 0),
		PALETTE.wood,
		Enum.Material.Wood,
		{ canCollide = false }
	)
	local cloth = makePart(
		banner,
		"Cloth",
		Vector3.new(5.2, 4, 0.25),
		cframe * CFrame.new(2.7, 6.4, 0),
		color,
		Enum.Material.SmoothPlastic,
		{ canCollide = false }
	)
	addSurfaceText(cloth, label or "", Enum.NormalId.Front, PALETTE.text)
	return banner
end

local function makeRuinArch(parent, name, center, rotation, accent)
	local arch = makeZoneFolder(parent, name)
	local cframe = CFrame.new(center) * CFrame.Angles(0, rotation or 0, 0)
	for side, x in { Left = -5.8, Right = 5.8 } do
		makePart(
			arch,
			`{side}ColumnBase`,
			Vector3.new(3.8, 2.2, 3.8),
			cframe * CFrame.new(x, 1.1, 0),
			PALETTE.stone,
			Enum.Material.Marble,
			{ canCollide = false }
		)
		makePart(
			arch,
			`{side}Column`,
			Vector3.new(2.4, 11, 2.4),
			cframe * CFrame.new(x, 7.5, 0),
			PALETTE.marble,
			Enum.Material.Marble,
			{ canCollide = false }
		)
	end
	makePart(
		arch,
		"ArchTop",
		Vector3.new(15, 2.6, 3.2),
		cframe * CFrame.new(0, 14.3, 0),
		PALETTE.marble,
		Enum.Material.Marble,
		{ canCollide = false }
	)
	makeNeon(
		arch,
		"RunicAccent",
		Vector3.new(13.2, 0.35, 0.35),
		cframe * CFrame.new(0, 12.4, -1.75),
		accent or PALETTE.cyan,
		0.18
	)
	return arch
end

local function makePuzzleMonument(parent, name, center, scale, colors)
	local monument = makeZoneFolder(parent, name)
	for index, data in colors do
		local block = makePart(
			monument,
			`MonumentBlock{index}`,
			Vector3.new(4.5, 4.5, 4.5) * scale,
			center + data.offset * scale,
			data.color,
			Enum.Material.SmoothPlastic,
			{ canCollide = false }
		)
		block.CFrame *= CFrame.Angles(
			math.rad(data.rx or 0),
			math.rad(data.ry or 0),
			math.rad(data.rz or 0)
		)
	end
	return monument
end

local function makeGateway(parent, name, center, rotation, leftColor, rightColor, title)
	local gate = makeZoneFolder(parent, name)
	local cframe = CFrame.new(center) * CFrame.Angles(0, rotation or 0, 0)
	for side, x in { Blue = -7, Red = 7 } do
		local color = side == "Blue" and leftColor or rightColor
		makePart(
			gate,
			`{side}Tower`,
			Vector3.new(4.5, 18, 4.5),
			cframe * CFrame.new(x, 9, 0),
			color,
			Enum.Material.SmoothPlastic,
			{ canCollide = false }
		)
		makeNeon(
			gate,
			`{side}TopGlow`,
			Vector3.new(5.2, 1, 5.2),
			cframe * CFrame.new(x, 18.6, 0),
			color,
			0.2
		)
	end
	local sign = makePart(
		gate,
		"GateSign",
		Vector3.new(20, 4, 1.2),
		cframe * CFrame.new(0, 17.5, -0.2),
		PALETTE.stoneDark,
		Enum.Material.Slate,
		{ canCollide = false }
	)
	addSurfaceText(sign, title, Enum.NormalId.Front, PALETTE.gold)
	return gate
end

local function configureLighting()
	safeLightingSet("GlobalShadows", true)
	safeLightingSet("Brightness", 2.15)
	safeLightingSet("ClockTime", 15.65)
	safeLightingSet("ExposureCompensation", -0.18)
	safeLightingSet("EnvironmentDiffuseScale", 0.35)
	safeLightingSet("EnvironmentSpecularScale", 0.42)
	safeLightingSet("Ambient", Color3.fromRGB(215, 179, 235))
	safeLightingSet("OutdoorAmbient", Color3.fromRGB(207, 190, 245))
	safeLightingSet("ColorShift_Top", Color3.fromRGB(255, 191, 224))
	safeLightingSet("ColorShift_Bottom", Color3.fromRGB(190, 220, 255))

	for _, child in Lighting:GetChildren() do
		if child.Name:match("^BlockBlast") then
			child:Destroy()
		end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "BlockBlastAtmosphere"
	atmosphere.Color = Color3.fromRGB(255, 214, 235)
	atmosphere.Decay = Color3.fromRGB(214, 179, 245)
	atmosphere.Density = 0.16
	atmosphere.Offset = 0.1
	atmosphere.Glare = 0.2
	atmosphere.Haze = 1.1
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "BlockBlastBloom"
	bloom.Intensity = 0.22
	bloom.Size = 22
	bloom.Threshold = 1.5
	bloom.Parent = Lighting

	local rays = Instance.new("SunRaysEffect")
	rays.Name = "BlockBlastSunRays"
	rays.Intensity = 0.05
	rays.Spread = 0.7
	rays.Parent = Lighting

	local correction = Instance.new("ColorCorrectionEffect")
	correction.Name = "BlockBlastColor"
	correction.Brightness = 0
	correction.Contrast = 0.14
	correction.Saturation = 0.28
	correction.TintColor = Color3.fromRGB(255, 240, 250)
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
	clearHubTerrain()

	local island = makeZoneFolder(parent, "CentralHubIsland")

	local terrainBlobs = {
		{ center = Vector3.new(0, 0, 0), radius = 54, material = Enum.Material.Rock },
		{ center = Vector3.new(-32, 5, 8), radius = 34, material = Enum.Material.Ground },
		{ center = Vector3.new(29, 5, -5), radius = 37, material = Enum.Material.Ground },
		{ center = Vector3.new(0, 7, 30), radius = 35, material = Enum.Material.Grass },
		{ center = Vector3.new(0, 8, -32), radius = 39, material = Enum.Material.Grass },
		{ center = Vector3.new(-45, 7, -16), radius = 25, material = Enum.Material.Grass },
		{ center = Vector3.new(45, 7, 14), radius = 27, material = Enum.Material.Grass },
		{ center = Vector3.new(-16, -13, 2), radius = 35, material = Enum.Material.Slate },
		{ center = Vector3.new(14, -25, -6), radius = 24, material = Enum.Material.Rock },
		{ center = Vector3.new(0, -41, 0), radius = 12, material = Enum.Material.Slate },
	}
	for _, blob in terrainBlobs do
		fillTerrainBall(blob.center, blob.radius, blob.material)
	end

	for index, cliff in
		{
			{ pos = Vector3.new(-58, -5, -12), size = Vector3.new(15, 30, 42), rot = 0.25 },
			{ pos = Vector3.new(58, -4, 10), size = Vector3.new(14, 31, 40), rot = -0.3 },
			{ pos = Vector3.new(-24, -8, -57), size = Vector3.new(44, 30, 14), rot = 0.1 },
			{ pos = Vector3.new(29, -7, 58), size = Vector3.new(43, 27, 14), rot = -0.1 },
			{ pos = Vector3.new(-39, -2, 39), size = Vector3.new(20, 18, 18), rot = 0.7 },
			{ pos = Vector3.new(39, -1, -37), size = Vector3.new(19, 18, 18), rot = -0.65 },
		}
	do
		fillTerrainBlock(cliff.pos, cliff.size, Enum.Material.Rock, cliff.rot)
		makeLowPolyRock(
			island,
			`VisibleCliffOutcrop{index}`,
			Vector3.new(cliff.pos.X, 3.5, cliff.pos.Z),
			1.45,
			PALETTE.stoneDark
		)
	end

	local walkSurface = makePart(
		island,
		"CentralHubSafeWalkSurface",
		Vector3.new(112, 1, 98),
		Vector3.new(0, 8.15, -4),
		PALETTE.grass,
		Enum.Material.Grass,
		{
			transparency = 1,
		}
	)
	walkSurface.CanCollide = true
	walkSurface.CanQuery = false

	local spawnPlaza = makePart(
		island,
		"SafeSoloSpawnPlaza",
		Vector3.new(44, 2, 32),
		Vector3.new(0, 11.25, 42),
		PALETTE.marble,
		Enum.Material.Marble,
		{ shape = Enum.PartType.Cylinder }
	)
	spawnPlaza.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	makePathSlab(
		island,
		"SoloSpawnEntryPath",
		Vector3.new(0, 11.95, 26),
		Vector3.new(18, 0.5, 24),
		0,
		PALETTE.stone
	)
	for side, x in { Left = -18, Right = 18 } do
		makeLamp(island, `SafeSpawnLamp{side}`, Vector3.new(x, 12.15, 42), PALETTE.gold)
	end

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(16, 1, 16)
	spawn.CFrame = CFrame.new(0, 12.8, 42) * CFrame.Angles(0, math.rad(180), 0)
	spawn.Color = PALETTE.cyan
	spawn.Material = Enum.Material.Neon
	spawn.CastShadow = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Enabled = true
	spawn.CanCollide = true
	spawn.CanTouch = false
	spawn.CanQuery = true
	spawn.Transparency = 1
	spawn.Parent = island

	local plaza = makeZoneFolder(island, "LayeredCentralPlaza")
	for radiusIndex, radius in { 17, 27, 38 } do
		local ring = makePart(
			plaza,
			`StonePathRing{radiusIndex}`,
			Vector3.new(radius * 2, 0.5, radius * 2),
			Vector3.new(0, 9.05 + radiusIndex * 0.08, 0),
			radiusIndex == 2 and PALETTE.marble or PALETTE.stone,
			Enum.Material.Cobblestone,
			{ canCollide = false, transparency = 0.14 + radiusIndex * 0.05 }
		)
		ring.Shape = Enum.PartType.Cylinder
	end

	for index = 1, 20 do
		local angle = (math.pi * 2) * index / 20
		local radius = index % 2 == 0 and 43 or 34
		makePart(
			plaza,
			`RadialMosaicStone{index}`,
			Vector3.new(7 + (index % 3), 0.45, 4),
			CFrame.new(Vector3.new(math.cos(angle) * radius, 9.42, math.sin(angle) * radius))
				* CFrame.Angles(0, -angle, 0),
			index % 3 == 0 and PALETTE.marble or PALETTE.stone,
			Enum.Material.Cobblestone,
			{ canCollide = false, transparency = 0.02 }
		)
	end

	local coreBase = makePart(
		plaza,
		"BrickCoreLowerPedestal",
		Vector3.new(36, 2.8, 36),
		Vector3.new(0, 10, 0),
		PALETTE.marble,
		Enum.Material.Marble
	)
	coreBase.Shape = Enum.PartType.Cylinder
	local upperBase = makePart(
		plaza,
		"BrickCoreUpperPedestal",
		Vector3.new(25, 2.6, 25),
		Vector3.new(0, 12.5, 0),
		PALETTE.stone,
		Enum.Material.Marble
	)
	upperBase.Shape = Enum.PartType.Cylinder

	local coreFrame = makeZoneFolder(plaza, "BrickCoreLandmark")
	for index = 1, 6 do
		local angle = (math.pi * 2) * index / 6
		local column = makePart(
			coreFrame,
			`CoreFramePillar{index}`,
			Vector3.new(3.2, 19, 3.2),
			CFrame.new(Vector3.new(math.cos(angle) * 14, 21.5, math.sin(angle) * 14))
				* CFrame.Angles(0, -angle, 0),
			index % 2 == 0 and PALETTE.stoneDark or PALETTE.marble,
			Enum.Material.Marble,
			{ canCollide = false }
		)
		addLight(column, index % 2 == 0 and PALETTE.cyan or PALETTE.gold, 0.35, 16)
	end

	makePart(
		coreFrame,
		"CoreTopCrown",
		Vector3.new(27, 2.6, 27),
		Vector3.new(0, 32.5, 0),
		PALETTE.gold,
		Enum.Material.Metal,
		{ canCollide = false, shape = Enum.PartType.Cylinder }
	)

	local coreBlocks = {
		{
			name = "CoreCenterCyan",
			offset = Vector3.new(0, 0, 0),
			size = Vector3.new(11, 11, 11),
			color = PALETTE.cyan,
		},
		{
			name = "CoreLeftBlue",
			offset = Vector3.new(-10.2, 0, 0),
			size = Vector3.new(8, 8, 8),
			color = Color3.fromRGB(45, 151, 255),
		},
		{
			name = "CoreRightPurple",
			offset = Vector3.new(10.2, 0, 0),
			size = Vector3.new(8, 8, 8),
			color = PALETTE.purple,
		},
		{
			name = "CoreTopGold",
			offset = Vector3.new(0, 10.2, 0),
			size = Vector3.new(7.2, 7.2, 7.2),
			color = PALETTE.gold,
		},
		{
			name = "CoreFrontGreen",
			offset = Vector3.new(0, 0, -10.2),
			size = Vector3.new(7.6, 7.6, 7.6),
			color = PALETTE.grass,
		},
	}
	for index, block in coreBlocks do
		local corePiece = makePart(
			coreFrame,
			block.name,
			block.size,
			Vector3.new(0, 22.5, 0) + block.offset,
			block.color,
			index == 1 and Enum.Material.Neon or Enum.Material.SmoothPlastic,
			{ canCollide = false }
		)
		corePiece.CFrame *= CFrame.Angles(
			math.rad(8 * index),
			math.rad(18 * index),
			math.rad(-5 * index)
		)
		queueSpin(corePiece, 22 + index, Vector3.new(0, 1, 0))
	end
	local beam = makeNeon(
		coreFrame,
		"ControlledCoreBeam",
		Vector3.new(2.8, 70, 2.8),
		Vector3.new(0, 63, 0),
		PALETTE.purple,
		0.76
	)
	beam.Shape = Enum.PartType.Cylinder
	addLight(coreFrame:FindFirstChild("CoreCenterCyan"), PALETTE.cyan, 2.2, 42)
	addParticles(coreBase, "CoreSparkles", PALETTE.gold, 2.4, 1.7, 2.1, 32)

	local routeFolder = makeZoneFolder(island, "SoloPuzzleSocialArea")
	makePathSlab(
		routeFolder,
		"SoloPuzzlePath",
		Vector3.new(0, 9.7, 27),
		Vector3.new(24, 0.65, 34),
		0,
		PALETTE.marble
	)
	local soloPad = makePortal(
		routeFolder,
		"SoloPuzzlePortal",
		Vector3.new(0, 13.6, -34),
		PALETTE.cyan,
		PALETTE.gold,
		"SOLO PUZZLE",
		"Beat your best score"
	)
	soloPad.Name = "SoloPlayPad"
	soloPad:SetAttribute("QueueMode", "Solo")
	local soloPrompt = addPrompt(soloPad, "Play", "Solo Puzzle")
	queueVisuals.soloPad = soloPad

	for index, lampData in
		{
			{ pos = Vector3.new(-13, 9.7, -23), color = PALETTE.cyan },
			{ pos = Vector3.new(13, 9.7, -23), color = PALETTE.gold },
			{ pos = Vector3.new(-22, 9.7, 24), color = PALETTE.gold },
			{ pos = Vector3.new(22, 9.7, 25), color = PALETTE.cyan },
		}
	do
		makeLamp(routeFolder, `RouteLamp{index}`, lampData.pos, lampData.color)
	end

	makeBanner(
		routeFolder,
		"SoloDirectionalBanner",
		Vector3.new(-18, 9.85, -49),
		0,
		PALETTE.cyan,
		"PLAY"
	)

	for index, treeData in
		{
			{ pos = Vector3.new(-45, 9.5, 31), scale = 1.35 },
			{ pos = Vector3.new(41, 9.5, -31), scale = 1.15 },
			{ pos = Vector3.new(-43, 9.4, -28), scale = 1 },
			{ pos = Vector3.new(25, 9.6, 48), scale = 1.1 },
			{ pos = Vector3.new(-24, 9.6, 49), scale = 0.95 },
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
	makeFlowerPatch(island, Vector3.new(-32, 8.7, 21), 18, 12)
	makeFlowerPatch(island, Vector3.new(33, 8.7, -24), 16, 10)
	makeBench(island, "SpawnViewBenchA", Vector3.new(-17, 9.75, 43), math.rad(25))
	makeBench(island, "SpawnViewBenchB", Vector3.new(22, 9.75, 42), math.rad(-20))
	makeWaterfall(island, "SouthCliffWaterfall", Vector3.new(-55, 6, 28))
	makeWaterfall(island, "EastCliffWaterfall", Vector3.new(57, 6, -5))

	addParticles(coreBase, "PlazaGoldDust", PALETTE.gold, 1.1, 2.4, 2, 38)

	return island, walkSurface, spawn, soloPrompt
end

local function buildSideIslands(parent)
	if not ExperienceConfig.isBattleVisible() and not ExperienceConfig.isStoryVisible() then
		return nil, nil
	end

	local zones = makeZoneFolder(parent, "Day30RouteEndpoints")

	local battlePrompt = nil
	if ExperienceConfig.isBattleVisible() then
		local battleZone = makeZoneFolder(zones, "BattleRouteEndpoint")
		fillTerrainBall(Vector3.new(0, 4, -116), 35, Enum.Material.Rock)
		fillTerrainBall(Vector3.new(-12, 9, -109), 27, Enum.Material.Grass)
		fillTerrainBall(Vector3.new(14, 9, -122), 28, Enum.Material.Grass)
		fillTerrainBall(Vector3.new(0, -14, -116), 22, Enum.Material.Slate)
		local battleLanding = makePart(
			battleZone,
			"BattleLandingSafeSurface",
			Vector3.new(70, 1, 54),
			Vector3.new(0, 12.1, -116),
			PALETTE.grass,
			Enum.Material.Grass,
			{ transparency = 1 }
		)
		battleLanding.CanCollide = true
		battleLanding.CanQuery = false
		makeBridge(
			parent,
			"BattleBridge",
			Vector3.new(0, 10, -65),
			Vector3.new(0, 12.5, -93),
			19,
			0.7
		)
		makePathSlab(
			battleZone,
			"BattleLandingBluePath",
			Vector3.new(-9, 12.7, -114),
			Vector3.new(15, 0.55, 42),
			0,
			PALETTE.cyan
		)
		makePathSlab(
			battleZone,
			"BattleLandingRedPath",
			Vector3.new(9, 12.72, -114),
			Vector3.new(15, 0.55, 42),
			0,
			PALETTE.red
		)
		makeGateway(
			battleZone,
			"BattleArenaGate",
			Vector3.new(0, 16.4, -137),
			0,
			Color3.fromRGB(44, 178, 255),
			Color3.fromRGB(255, 88, 88),
			"BATTLE"
		)
		local battlePad = makePortal(
			battleZone,
			"BattlePortal",
			Vector3.new(0, 15.4, -110),
			Color3.fromRGB(44, 178, 255),
			Color3.fromRGB(255, 88, 88),
			"BATTLE QUEUE",
			"Casual matches"
		)
		battlePad.Name = "BattleQueuePad"
		battlePad:SetAttribute("QueueMode", "Battle")
		battlePrompt = addPrompt(battlePad, "Join Queue", "Block Blast Battle")
		local battleTitle, battleSubtitle = addStatusBillboard(
			battlePad,
			"QueueStatus",
			"BATTLE QUEUE",
			"0 queued - step here or use Hub UI"
		)
		queueVisuals.battlePad = battlePad
		queueVisuals.battleTitle = battleTitle
		queueVisuals.battleSubtitle = battleSubtitle
		makePuzzleMonument(battleZone, "VersusBlockSculpture", Vector3.new(0, 16.2, -150), 1.05, {
			{ offset = Vector3.new(-6, 0, 0), color = PALETTE.cyan, ry = 12 },
			{ offset = Vector3.new(-2, 4.6, 0), color = PALETTE.cyan, ry = -16 },
			{ offset = Vector3.new(2, 0, 0), color = PALETTE.red, ry = 18 },
			{ offset = Vector3.new(6, 4.6, 0), color = PALETTE.red, ry = -12 },
		})
		makeFestivalFlags(
			battleZone,
			"BattleBunting",
			Vector3.new(-32, 25, -94),
			Vector3.new(32, 25, -94),
			11
		)
		for index, side in { -1, 1 } do
			makeLamp(
				battleZone,
				`BattleBridgeLamp{index}`,
				Vector3.new(side * 17, 12.5, -94),
				side < 0 and PALETTE.cyan or PALETTE.red
			)
		end
	end

	local storyPrompt = nil
	if ExperienceConfig.isStoryVisible() then
		local storyZone = makeZoneFolder(zones, "StoryRouteEndpoint")
		fillTerrainBall(Vector3.new(112, 4, 80), 31, Enum.Material.Rock)
		fillTerrainBall(Vector3.new(103, 9, 72), 24, Enum.Material.Grass)
		fillTerrainBall(Vector3.new(124, 9, 88), 24, Enum.Material.Grass)
		fillTerrainBall(Vector3.new(112, -13, 80), 18, Enum.Material.Slate)
		local storyLanding = makePart(
			storyZone,
			"StoryLandingSafeSurface",
			Vector3.new(60, 1, 48),
			Vector3.new(112, 12.2, 80),
			PALETTE.grass,
			Enum.Material.Grass,
			{ transparency = 1 }
		)
		storyLanding.CanCollide = true
		storyLanding.CanQuery = false
		makeBridge(
			parent,
			"StoryBridge",
			Vector3.new(58, 10.1, 39),
			Vector3.new(88, 12.8, 61),
			15,
			2.55
		)
		makePathSlab(
			storyZone,
			"StoryLandingGoldPath",
			Vector3.new(112, 12.85, 80),
			Vector3.new(20, 0.55, 42),
			math.rad(-52),
			PALETTE.gold
		)
		local storyPad = makePortal(
			storyZone,
			"StoryPortal",
			Vector3.new(112, 15.3, 83),
			PALETTE.purple,
			PALETTE.gold,
			"STORY MODE",
			"Solo training"
		)
		storyPad.Name = "StoryQueuePad"
		storyPad:SetAttribute("QueueMode", "Story")
		storyPrompt = addPrompt(storyPad, "Start", "Story Training")
		local storyTitle, storySubtitle = addStatusBillboard(
			storyPad,
			"StoryStatus",
			"STORY MODE",
			"Solo missions - safe practice"
		)
		queueVisuals.storyTitle = storyTitle
		queueVisuals.storySubtitle = storySubtitle
		makeRuinArch(
			storyZone,
			"AncientPuzzleArch",
			Vector3.new(108, 15.2, 61),
			math.rad(180),
			PALETTE.gold
		)
		makeRuinArch(
			storyZone,
			"BrokenSideArchA",
			Vector3.new(94, 14.2, 98),
			math.rad(35),
			PALETTE.purple
		)
		makeRuinArch(
			storyZone,
			"BrokenSideArchB",
			Vector3.new(130, 14.2, 100),
			math.rad(-35),
			PALETTE.purple
		)
		for index = 1, 5 do
			local angle = (math.pi * 2) * index / 7
			local fragment = makePart(
				storyZone,
				`FloatingStoryFragment{index}`,
				Vector3.new(3.8, 2.2, 5.4),
				Vector3.new(
					112 + math.cos(angle) * 18,
					23 + (index % 3) * 2,
					83 + math.sin(angle) * 15
				),
				index % 2 == 0 and PALETTE.stone or PALETTE.marble,
				Enum.Material.Marble,
				{ canCollide = false }
			)
			fragment.CFrame *= CFrame.Angles(
				math.rad(index * 12),
				math.rad(index * 24),
				math.rad(index * 7)
			)
			queueSpin(fragment, 42 + index, Vector3.new(0, 1, 0))
		end
		makeTree(storyZone, "GlowingStoryTree", Vector3.new(96, 12.8, 101), 0.95, PALETTE.purple)
		makeLowPolyRock(
			storyZone,
			"StoryCliffRocks",
			Vector3.new(132, 12.5, 67),
			1,
			PALETTE.stoneDark
		)
		makeLamp(storyZone, "StoryGoldLampA", Vector3.new(96, 12.8, 76), PALETTE.gold)
		makeLamp(storyZone, "StoryGoldLampB", Vector3.new(128, 12.8, 79), PALETTE.gold)
	end

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
	local rightSpawn = makePart(
		arena,
		"PlayerSpawnB",
		Vector3.new(8, 1, 8),
		arenaCenter + Vector3.new(24, 5.2, 18),
		PALETTE.pink,
		Enum.Material.Neon
	)
	local returnPad = makePart(
		arena,
		"ReturnHubPad",
		Vector3.new(12, 1, 8),
		arenaCenter + Vector3.new(0, 5.2, 27),
		PALETTE.gold,
		Enum.Material.SmoothPlastic
	)

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

	for index = 1, 7 do
		local angle = (math.pi * 2) * index / 7
		local radius = 190 + (index % 3) * 38
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

	for index = 1, 5 do
		local angle = (math.pi * 2) * index / 5 + 0.22
		local rock = makePart(
			scenery,
			`FloatingRock{index}`,
			Vector3.new(16 + index % 4, 10 + index % 3, 15 + index % 5),
			Vector3.new(math.cos(angle) * 155, 9 + (index % 4) * 9, math.sin(angle) * 165 - 70),
			PALETTE.stoneDark,
			Enum.Material.Rock,
			{ canCollide = false }
		)
		rock.CFrame *= CFrame.Angles(math.rad(index * 11), math.rad(index * 19), 0)
		queueSpin(rock, 48 + index, Vector3.new(0, 1, 0))
	end

	for index = 1, 4 do
		local angle = (math.pi * 2) * index / 4 + 0.35
		local base =
			Vector3.new(math.cos(angle) * 245, -10 + (index % 3) * 7, math.sin(angle) * 230 - 105)
		local silhouette = makeZoneFolder(scenery, `DistantPuzzleKingdomSilhouette{index}`)
		local island = makePart(
			silhouette,
			"FarIslandBase",
			Vector3.new(34 + index * 2, 2, 25 + index),
			base,
			Color3.fromRGB(91, 129, 151),
			Enum.Material.Slate,
			{ canCollide = false, transparency = 0.28, shape = Enum.PartType.Cylinder }
		)
		island.CFrame *= CFrame.Angles(0, angle, math.rad(90))
		for towerIndex = 1, 3 do
			makePart(
				silhouette,
				`FarTower{towerIndex}`,
				Vector3.new(5, 12 + towerIndex * 3, 5),
				base
					+ Vector3.new(
						-9 + towerIndex * 8,
						7 + towerIndex * 1.5,
						(towerIndex % 2 == 0 and 5 or -3)
					),
				Color3.fromRGB(99, 144, 171),
				Enum.Material.Slate,
				{ canCollide = false, transparency = 0.32 }
			)
		end
	end
end

local function makeToyBlock(parent, name, center, size, color, options)
	options = options or {}
	local block = makePart(parent, name, size, center, color, Enum.Material.SmoothPlastic, options)
	block.Reflectance = options.reflectance or 0.05

	if options.studs ~= false then
		local studsX = math.max(1, math.floor(size.X / 4))
		local studsZ = math.max(1, math.floor(size.Z / 4))
		for xIndex = 1, studsX do
			for zIndex = 1, studsZ do
				local sprinkleColor = BLOCK_COLORS[((xIndex * 7 + zIndex * 3) % #BLOCK_COLORS) + 1]
				local stud = makePart(
					parent,
					`{name}Stud{xIndex}_{zIndex}`,
					Vector3.new(1.1, 1.1, 1.1),
					Vector3.new(
						center.X - size.X / 2 + (xIndex - 0.5) * (size.X / studsX),
						center.Y + size.Y / 2 + 0.35,
						center.Z - size.Z / 2 + (zIndex - 0.5) * (size.Z / studsZ)
					),
					sprinkleColor:Lerp(Color3.fromRGB(255, 255, 255), 0.1),
					Enum.Material.SmoothPlastic,
					{ canCollide = false, shape = Enum.PartType.Ball }
				)
				stud.Reflectance = 0.08
			end
		end
	end

	return block
end

local function makeToyboxSlide(parent, name, startCenter, length, color)
	local slide = makeZoneFolder(parent, name)
	for index = 1, 4 do
		local alpha = (index - 1) / 3
		local position = startCenter + Vector3.new(0, -alpha * 8, alpha * length)
		local stripeColor = index % 2 == 0 and PALETTE.marble or color
		local segment = makePart(
			slide,
			`SlideSegment{index}`,
			Vector3.new(11, 1, 12),
			CFrame.new(position) * CFrame.Angles(math.rad(-12), 0, 0),
			stripeColor,
			Enum.Material.SmoothPlastic
		)
		segment.CustomPhysicalProperties = PhysicalProperties.new(0.7, 0.05, 0.25)
	end
end

local function makeBouncePad(parent, name, center, color)
	local pad =
		makePart(parent, name, Vector3.new(22, 1.4, 22), center, color, Enum.Material.SmoothPlastic)
	pad.Shape = Enum.PartType.Cylinder
	addSurfaceText(pad, "BOUNCE", Enum.NormalId.Top, PALETTE.text)
	addParticles(
		pad,
		"BounceSparkles",
		color:Lerp(Color3.fromRGB(255, 255, 255), 0.35),
		4,
		0.65,
		3,
		22
	)
	local bounceSound =
		addSound(pad, "BouncePadPop", "rbxasset://sounds/action_jump.mp3", 0.22, 1.18)
	local cooldowns = {}
	pad.Touched:Connect(function(hit)
		local character = hit and hit.Parent
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and rootPart and humanoid.Health > 0 then
			local now = os.clock()
			if cooldowns[character] and now - cooldowns[character] < 0.65 then
				return
			end
			cooldowns[character] = now
			rootPart.AssemblyLinearVelocity = Vector3.new(0, 78, 0)
			bounceSound:Play()
		end
	end)
	return pad
end

local function makeLauncher(parent, name, center)
	local launcher = makePart(
		parent,
		name,
		Vector3.new(22, 1.2, 22),
		center,
		PALETTE.green or PALETTE.grass,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Cylinder }
	)
	addSurfaceText(launcher, "LAUNCH", Enum.NormalId.Top, PALETTE.text)
	addParticles(launcher, "LauncherTrail", PALETTE.cyan, 5, 0.55, 5, 28)
	local launchSound = addSound(
		launcher,
		"LauncherWhoosh",
		"rbxasset://sounds/action_footsteps_plastic.mp3",
		0.18,
		1.28
	)
	local cooldowns = {}
	launcher.Touched:Connect(function(hit)
		local character = hit and hit.Parent
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid and rootPart and humanoid.Health > 0 then
			local now = os.clock()
			if cooldowns[character] and now - cooldowns[character] < 1 then
				return
			end
			cooldowns[character] = now
			rootPart.AssemblyLinearVelocity = Vector3.new(-44, 52, -16)
			launchSound:Play()
		end
	end)
end

local function makePressButton(parent, name, center, color)
	local button =
		makePart(parent, name, Vector3.new(16, 2.5, 16), center, color, Enum.Material.SmoothPlastic)
	button.Shape = Enum.PartType.Cylinder
	addLight(button, color, 0.45, 16)
	addParticles(button, "ButtonStars", color:Lerp(PALETTE.gold, 0.5), 2, 0.45, 2, 18)
	local pressSound = addSound(button, "ButtonClick", "rbxasset://sounds/uuhhh.mp3", 0.12, 1.65)
	local baseCFrame = button.CFrame
	local debounce = false
	button.Touched:Connect(function(hit)
		local character = hit and hit.Parent
		if debounce or not (character and character:FindFirstChildOfClass("Humanoid")) then
			return
		end
		debounce = true
		pressSound:Play()
		TweenService:Create(button, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
			CFrame = baseCFrame * CFrame.new(-1.2, 0, 0),
		}):Play()
		task.delay(0.8, function()
			if button.Parent then
				TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
					CFrame = baseCFrame,
				}):Play()
			end
			debounce = false
		end)
	end)
end

local function makeToyboxMachine(parent)
	local machine = makeZoneFolder(parent, "GumballMachine")
	local machineCenter = Vector3.new(36, 7, -22)
	makeToyBlock(machine, "MachineBase", machineCenter, Vector3.new(18, 8, 13), PALETTE.red, {
		studs = false,
	})
	makePart(
		machine,
		"MachineWindow",
		Vector3.new(12, 8, 1),
		machineCenter + Vector3.new(0, 6, -7.1),
		Color3.fromRGB(255, 214, 235),
		Enum.Material.Glass,
		{ transparency = 0.32, canCollide = false }
	)
	makePart(
		machine,
		"MachineDome",
		Vector3.new(14, 9, 11),
		machineCenter + Vector3.new(0, 8.5, 0),
		Color3.fromRGB(255, 247, 250),
		Enum.Material.Glass,
		{ transparency = 0.28, canCollide = false, shape = Enum.PartType.Ball }
	)
	for index = 1, 4 do
		local block = makePart(
			machine,
			`MachineGumball{index}`,
			Vector3.new(2.6, 2.6, 2.6),
			machineCenter
				+ Vector3.new(-4.5 + (index % 2) * 5, 6.5 + math.floor((index - 1) / 2) * 2.4, -3.5),
			BLOCK_COLORS[((index - 1) % #BLOCK_COLORS) + 1],
			Enum.Material.SmoothPlastic,
			{ canCollide = false, shape = Enum.PartType.Ball }
		)
		block.Reflectance = 0.15
		queueSpin(block, 20 + index, Vector3.new(0, 1, 0))
	end
	makePressButton(machine, "MachineButton", Vector3.new(43, 5.3, -9), PALETTE.red)
end

local function makeToyRail(parent, name, startX, endX, z, y, color)
	local rail = makeZoneFolder(parent, name)
	local length = math.abs(endX - startX)
	local centerX = (startX + endX) / 2
	makePart(
		rail,
		"RailBeam",
		Vector3.new(length, 1.2, 1.2),
		Vector3.new(centerX, y, z),
		color,
		Enum.Material.SmoothPlastic,
		{ canCollide = false }
	)
	for step = 0, 5 do
		local x = startX + (endX - startX) * (step / 5)
		makePart(
			rail,
			`RailPost{step}`,
			Vector3.new(1.4, 4, 1.4),
			Vector3.new(x, y - 1.6, z),
			PALETTE.marble,
			Enum.Material.SmoothPlastic,
			{ canCollide = false }
		)
	end
end

local function makeToyDiskPlatform(parent, name, center, radius, height, topColor, baseColor)
	makePart(
		parent,
		`${name}Base`,
		Vector3.new(radius * 2 + 10, height, radius * 2 + 10),
		center + Vector3.new(0, -height / 2, 0),
		baseColor or PALETTE.stoneDark,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Cylinder }
	)

	local top = makePart(
		parent,
		`${name}Top`,
		Vector3.new(radius * 2, 1.1, radius * 2),
		center + Vector3.new(0, 0.75, 0),
		topColor,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Cylinder }
	)
	top.CanCollide = true

	return top
end

local function makeToyWalkway(parent, name, center, size, color, trimColor)
	local base = makeToyBlock(
		parent,
		`${name}Base`,
		center + Vector3.new(0, -1.7, 0),
		Vector3.new(size.X + 4, 3.4, size.Z + 4),
		trimColor or PALETTE.stoneDark,
		{ studs = false }
	)
	base.CanCollide = true

	local path =
		makePart(parent, name, size, center, color or PALETTE.marble, Enum.Material.SmoothPlastic)
	path.CanCollide = true
	return path
end

local function makeToyFence(parent, name, start, finish, color)
	local fence = makeZoneFolder(parent, name)
	local delta = finish - start
	local length = delta.Magnitude
	if length <= 0 then
		return fence
	end
	local angle = math.atan2(delta.X, delta.Z)
	local midpoint = start:Lerp(finish, 0.5)
	makePart(
		fence,
		"TopRail",
		Vector3.new(1.2, 1.1, length),
		CFrame.new(midpoint + Vector3.new(0, 4.6, 0)) * CFrame.Angles(0, angle, 0),
		color or PALETTE.waterDeep,
		Enum.Material.SmoothPlastic,
		{ canCollide = false }
	)
	makePart(
		fence,
		"BottomRail",
		Vector3.new(1, 0.9, length),
		CFrame.new(midpoint + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, angle, 0),
		color or PALETTE.waterDeep,
		Enum.Material.SmoothPlastic,
		{ canCollide = false }
	)
	for index = 0, 5 do
		local alpha = index / 5
		local post = makePart(
			fence,
			`Post{index}`,
			Vector3.new(1.8, 5.2, 1.8),
			start:Lerp(finish, alpha) + Vector3.new(0, 2.6, 0),
			index % 2 == 0 and PALETTE.marble or PALETTE.red,
			Enum.Material.SmoothPlastic,
			{ canCollide = false, shape = Enum.PartType.Cylinder }
		)
		post.CFrame *= CFrame.Angles(math.rad(90), 0, 0)
	end
	return fence
end

local function makeLollipopProp(parent, name, center, scale, color)
	scale = scale or 1
	local prop = makeZoneFolder(parent, name)
	local stick = makePart(
		prop,
		"Stick",
		Vector3.new(0.55, 5.4 * scale, 0.55),
		center + Vector3.new(0, 2.7 * scale, 0),
		PALETTE.marble,
		Enum.Material.SmoothPlastic,
		{ canCollide = false, shape = Enum.PartType.Cylinder }
	)
	stick.CFrame *= CFrame.Angles(0, 0, math.rad(90))
	local candyCenter = center + Vector3.new(0, 5.6 * scale, 0)
	local candy = makePart(
		prop,
		"Candy",
		Vector3.new(4.2 * scale, 4.2 * scale, 1.4 * scale),
		candyCenter,
		color,
		Enum.Material.SmoothPlastic,
		{ canCollide = false, shape = Enum.PartType.Ball }
	)
	local swirl = makePart(
		prop,
		"Swirl",
		Vector3.new(2.6 * scale, 2.6 * scale, 1.6 * scale),
		candyCenter,
		PALETTE.marble,
		Enum.Material.SmoothPlastic,
		{ canCollide = false, shape = Enum.PartType.Ball, transparency = 0.25 }
	)
	swirl.CFrame *= CFrame.Angles(0, 0, math.rad(35))
	queueSpin(candy, 30, Vector3.new(0, 0, 1))
	return prop
end

local function buildToyboxHub(parent)
	local hub = makeZoneFolder(parent, "BubblegumSoloHub")

	local floor = makePart(
		hub,
		"ToyboxMainPlayFloor",
		Vector3.new(148, 3, 122),
		Vector3.new(0, 0, 0),
		PALETTE.stone,
		Enum.Material.Concrete
	)
	floor.Transparency = 1
	floor.CanCollide = false
	floor.CanQuery = false
	floor.CanTouch = false

	makeToyBlock(
		hub,
		"ToyPlaysetCenterFoundation",
		Vector3.new(0, 2.45, 8),
		Vector3.new(74, 5.2, 76),
		Color3.fromRGB(255, 178, 217),
		{ studs = false }
	)
	makeToyBlock(
		hub,
		"ToyPlaysetSpawnConnectorFoundation",
		Vector3.new(0, 2.85, 51),
		Vector3.new(34, 4.4, 40),
		Color3.fromRGB(255, 191, 224),
		{ studs = false }
	)
	makeToyBlock(
		hub,
		"ToyPlaysetSpawnLandingFoundation",
		Vector3.new(0, 3.05, 76),
		Vector3.new(44, 4, 32),
		Color3.fromRGB(255, 201, 229),
		{ studs = false }
	)
	makeToyBlock(
		hub,
		"ToyPlaysetLeftActivityFoundation",
		Vector3.new(-35, 2.3, 15),
		Vector3.new(34, 4.5, 42),
		PALETTE.purple,
		{ studs = false }
	)
	makeToyBlock(
		hub,
		"ToyPlaysetRightActivityFoundation",
		Vector3.new(35, 2.3, 16),
		Vector3.new(34, 4.5, 46),
		PALETTE.grass,
		{ studs = false }
	)
	makeToyBlock(
		hub,
		"ToyPlaysetRearActivityFoundation",
		Vector3.new(14, 2.35, -36),
		Vector3.new(54, 4.7, 32),
		PALETTE.cyan,
		{ studs = false }
	)
	makeToyBlock(
		hub,
		"ToyFoundationFrontCreamLip",
		Vector3.new(0, 5.45, 47),
		Vector3.new(74, 2, 4),
		PALETTE.marble,
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"ToyFoundationRearCreamLip",
		Vector3.new(0, 5.45, -30),
		Vector3.new(74, 2, 4),
		PALETTE.marble,
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"ToyFoundationLeftCreamLip",
		Vector3.new(-39, 5.45, 8),
		Vector3.new(4, 2, 74),
		PALETTE.marble,
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"ToyFoundationRightCreamLip",
		Vector3.new(39, 5.45, 8),
		Vector3.new(4, 2, 74),
		PALETTE.marble,
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"SpawnFoundationFrontLip",
		Vector3.new(0, 5.4, 57),
		Vector3.new(44, 1.8, 4),
		PALETTE.gold,
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"SpawnFoundationBackLip",
		Vector3.new(0, 5.4, 92),
		Vector3.new(44, 1.8, 4),
		PALETTE.gold,
		{ studs = false, canCollide = false }
	)

	makeToyDiskPlatform(
		hub,
		"CentralPlaysetIsland",
		Vector3.new(0, 3.8, 8),
		43,
		5,
		PALETTE.cloud,
		PALETTE.stoneDark
	)
	makeToyDiskPlatform(
		hub,
		"MachineIsland",
		Vector3.new(36, 4.2, -20),
		17,
		4,
		PALETTE.gold,
		Color3.fromRGB(224, 132, 92)
	)
	makeToyDiskPlatform(
		hub,
		"FunZoneIsland",
		Vector3.new(-36, 4.2, 16),
		18,
		4,
		PALETTE.pink,
		PALETTE.waterDeep
	)
	makeToyDiskPlatform(
		hub,
		"LaunchIsland",
		Vector3.new(38, 4.4, 38),
		15,
		4,
		PALETTE.grass,
		PALETTE.grassDark
	)
	makeToyDiskPlatform(
		hub,
		"SlideTowerIsland",
		Vector3.new(38, 6.4, -45),
		14,
		5,
		PALETTE.cyan,
		Color3.fromRGB(90, 160, 224)
	)
	makeToyWalkway(
		hub,
		"SpawnToPlayPath",
		Vector3.new(0, 6.15, 47),
		Vector3.new(32, 1.1, 56),
		PALETTE.marble,
		PALETTE.waterDeep
	)
	makeToyWalkway(
		hub,
		"PlayToRearAttractionsPath",
		Vector3.new(0, 5.95, -27),
		Vector3.new(24, 1.1, 28),
		PALETTE.marble,
		PALETTE.waterDeep
	)
	makeToyWalkway(
		hub,
		"PlayToMachinePath",
		Vector3.new(23, 5.95, -11),
		Vector3.new(26, 1.1, 15),
		PALETTE.gold,
		Color3.fromRGB(224, 188, 66)
	)
	makeToyWalkway(
		hub,
		"PlayToFunPath",
		Vector3.new(-22, 5.95, 15),
		Vector3.new(25, 1.1, 15),
		Color3.fromRGB(255, 201, 229),
		PALETTE.waterDeep
	)
	makeToyWalkway(
		hub,
		"PlayToLaunchPath",
		Vector3.new(24, 6.05, 33),
		Vector3.new(23, 1.1, 14),
		Color3.fromRGB(202, 255, 230),
		PALETTE.grassDark
	)

	makePart(
		hub,
		"RoundPuzzlePlaza",
		Vector3.new(58, 1.2, 58),
		Vector3.new(0, 5.75, 8),
		PALETTE.marble,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Cylinder }
	)
	makePart(
		hub,
		"ToyPlazaCyanRing",
		Vector3.new(64, 0.7, 64),
		Vector3.new(0, 5.38, 8),
		PALETTE.pink,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Cylinder, canCollide = false }
	)

	local spawnDeck = makePart(
		hub,
		"ToyboxSafeSpawnDeck",
		Vector3.new(38, 2, 24),
		Vector3.new(0, 6.35, 78),
		PALETTE.marble,
		Enum.Material.SmoothPlastic
	)
	makeToyBlock(
		hub,
		"SpawnDeckBlueLip",
		Vector3.new(0, 8.2, 62),
		Vector3.new(40, 2.4, 3.5),
		PALETTE.cyan,
		{
			studs = false,
			canCollide = false,
		}
	)
	makePart(
		hub,
		"SpawnDeckOrangeBase",
		Vector3.new(42, 1.6, 26),
		Vector3.new(0, 4.75, 78),
		PALETTE.orange,
		Enum.Material.SmoothPlastic
	)
	makeToyBlock(
		hub,
		"SpawnWelcomeLeftMarker",
		Vector3.new(-18, 7.2, 65),
		Vector3.new(4, 3, 4),
		PALETTE.gold,
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"SpawnWelcomeRightMarker",
		Vector3.new(18, 7.2, 65),
		Vector3.new(4, 3, 4),
		PALETTE.gold,
		{ studs = false, canCollide = false }
	)
	makeLollipopProp(hub, "SpawnLollipopLeft", Vector3.new(-24, 7.4, 68), 1.1, PALETTE.red)
	makeLollipopProp(hub, "SpawnLollipopRight", Vector3.new(24, 7.4, 68), 1.1, PALETTE.purple)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.CFrame = CFrame.new(0, 8.1, 78)
	spawn.Transparency = 1
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Enabled = true
	spawn.CanCollide = true
	spawn.CanTouch = false
	spawn.Parent = hub
	spawnDeck.CanCollide = true

	local playPad = makePart(
		hub,
		"SoloPlayPad",
		Vector3.new(32, 3, 18),
		Vector3.new(0, 6.65, 15),
		PALETTE.cyan,
		Enum.Material.SmoothPlastic
	)
	playPad:SetAttribute("QueueMode", "Solo")
	addSurfaceText(playPad, "PLAY", Enum.NormalId.Top, PALETTE.text)
	local soloPrompt = addPrompt(playPad, "Play", "Solo Puzzle")
	makePart(
		hub,
		"PlayPadWhiteLip",
		Vector3.new(38, 1, 24),
		Vector3.new(0, 4.65, 15),
		PALETTE.marble,
		Enum.Material.SmoothPlastic
	)
	makePart(
		hub,
		"PlayPadOrangeBase",
		Vector3.new(42, 1.2, 28),
		Vector3.new(0, 3.85, 15),
		PALETTE.orange,
		Enum.Material.SmoothPlastic
	)
	makeToyBlock(
		hub,
		"PlayStageCyanSideLeft",
		Vector3.new(-22, 5.45, 15),
		Vector3.new(4, 3.2, 26),
		PALETTE.cyan,
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"PlayStageCyanSideRight",
		Vector3.new(22, 5.45, 15),
		Vector3.new(4, 3.2, 26),
		PALETTE.cyan,
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"PlaySignLeftSupport",
		Vector3.new(-14, 10, 4),
		Vector3.new(2, 7, 2),
		PALETTE.marble,
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"PlaySignRightSupport",
		Vector3.new(14, 10, 4),
		Vector3.new(2, 7, 2),
		PALETTE.marble,
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"PlaySignSupportBar",
		Vector3.new(0, 13.1, 4),
		Vector3.new(31, 2, 2),
		PALETTE.gold,
		{ studs = false, canCollide = false }
	)
	addBillboard(playPad, "PLAY", "Solo Puzzle", Vector3.new(0, 6.2, 0))

	makeToyboxMachine(hub)
	makeToyboxSlide(hub, "BlueToySlide", Vector3.new(38, 18, -51), 24, PALETTE.red)
	makeBouncePad(hub, "RedSpringBouncePad", Vector3.new(-38, 7.2, 32), PALETTE.pink)
	makeLauncher(hub, "GreenLauncherPad", Vector3.new(38, 7.15, 38))
	makePressButton(hub, "PurpleSpinnerButton", Vector3.new(34, 7.3, -4), PALETTE.purple)
	makeToyBlock(
		hub,
		"MachineStationBackWall",
		Vector3.new(36, 8.2, -30),
		Vector3.new(24, 7, 2),
		Color3.fromRGB(255, 201, 229),
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"MachineStationGoldCap",
		Vector3.new(36, 12, -30),
		Vector3.new(26, 2, 4),
		PALETTE.gold,
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"BounceSpringBase",
		Vector3.new(-38, 5.9, 32),
		Vector3.new(24, 2, 24),
		PALETTE.stone,
		{ studs = false }
	)
	makePart(
		hub,
		"BounceSpringCoilA",
		Vector3.new(17, 1.3, 17),
		Vector3.new(-38, 8.6, 32),
		PALETTE.marble,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Cylinder, canCollide = false }
	)
	makePart(
		hub,
		"BounceSpringCoilB",
		Vector3.new(13, 1.3, 13),
		Vector3.new(-38, 10.4, 32),
		PALETTE.red,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Cylinder, canCollide = false }
	)
	makeToyBlock(
		hub,
		"LauncherArrowBase",
		Vector3.new(38, 5.95, 28),
		Vector3.new(20, 2, 8),
		Color3.fromRGB(210, 255, 235),
		{ studs = false }
	)
	makeToyBlock(
		hub,
		"SpinnerPurpleGuard",
		Vector3.new(-34, 5.9, -18),
		Vector3.new(24, 2, 6),
		Color3.fromRGB(216, 191, 255),
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"MoverTrackBase",
		Vector3.new(-20, 6.4, -35),
		Vector3.new(32, 1.4, 12),
		PALETTE.gold,
		{ studs = false }
	)
	makeToyRail(hub, "LeftSpawnRail", -22, -8, 63, 9.4, PALETTE.pink)
	makeToyRail(hub, "RightSpawnRail", 8, 22, 63, 9.4, PALETTE.pink)
	makeToyFence(
		hub,
		"SpawnWestFence",
		Vector3.new(-23, 6.8, 68),
		Vector3.new(-23, 6.8, 88),
		PALETTE.waterDeep
	)
	makeToyFence(
		hub,
		"SpawnEastFence",
		Vector3.new(23, 6.8, 68),
		Vector3.new(23, 6.8, 88),
		PALETTE.waterDeep
	)
	makeToyFence(
		hub,
		"RearAttractionFence",
		Vector3.new(-24, 6.4, -45),
		Vector3.new(24, 6.4, -45),
		PALETTE.gold
	)

	local spinner = makePart(
		hub,
		"ToyboxSpinnerPlatform",
		Vector3.new(20, 2, 20),
		Vector3.new(-34, 7.4, -6),
		PALETTE.purple,
		Enum.Material.SmoothPlastic,
		{ shape = Enum.PartType.Cylinder }
	)
	queueSpin(spinner, 10, Vector3.new(0, 1, 0))
	addBillboard(spinner, "SPIN", "Ride the gumdrop wheel", Vector3.new(0, 5.8, 0))

	for _, cloudData in
		{
			{
				name = "CloudNorthPink",
				center = Vector3.new(-52, 26, -12),
				scale = 1.4,
				color = PALETTE.pink,
			},
			{
				name = "CloudNorthBlue",
				center = Vector3.new(58, 24, 4),
				scale = 1.2,
				color = PALETTE.cyan,
			},
			{
				name = "CloudSouthPink",
				center = Vector3.new(-10, 22, 96),
				scale = 1.1,
				color = PALETTE.pink,
			},
			{
				name = "CloudSouthPurple",
				center = Vector3.new(30, 25, 100),
				scale = 1.3,
				color = PALETTE.purple,
			},
			{
				name = "CloudRearMint",
				center = Vector3.new(0, 30, -70),
				scale = 1.5,
				color = PALETTE.grass,
			},
		}
	do
		makeCloud(hub, cloudData.name, cloudData.center, cloudData.scale, {
			color = cloudData.color,
			material = Enum.Material.Neon,
			transparency = 0.35,
			puffSize = Vector3.new(4.6, 3.6, 4.6),
			offsets = CANDY_PUFF_OFFSETS,
		})
	end
	makeLollipopProp(hub, "PlazaLollipopA", Vector3.new(-30, 6.3, -8), 1, PALETTE.pink)
	makeLollipopProp(hub, "PlazaLollipopB", Vector3.new(28, 6.3, 26), 0.9, PALETTE.cyan)

	local mover = makeToyBlock(
		hub,
		"MovingPuzzlePlatform",
		Vector3.new(-20, 8.4, -35),
		Vector3.new(14, 2, 10),
		PALETTE.gold,
		{ studs = false }
	)
	task.spawn(function()
		local left = CFrame.new(-27, 8.4, -35)
		local right = CFrame.new(-13, 8.4, -35)
		while hub.Parent and mover.Parent do
			TweenService
				:Create(
					mover,
					TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{
						CFrame = right,
					}
				)
				:Play()
			task.wait(2.8)
			TweenService
				:Create(
					mover,
					TweenInfo.new(2.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{
						CFrame = left,
					}
				)
				:Play()
			task.wait(2.8)
		end
	end)

	makeToyBlock(
		hub,
		"RearToyBackdropBase",
		Vector3.new(0, 12, -82),
		Vector3.new(48, 10, 4),
		Color3.fromRGB(255, 191, 224),
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"RearToyBackdropTop",
		Vector3.new(0, 18, -82),
		Vector3.new(36, 4, 4),
		PALETTE.gold,
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"RearToyBackdropLeftDot",
		Vector3.new(-18, 19.8, -79),
		Vector3.new(5, 5, 2),
		PALETTE.red,
		{ studs = false, canCollide = false }
	)
	makeToyBlock(
		hub,
		"RearToyBackdropRightDot",
		Vector3.new(18, 19.8, -79),
		Vector3.new(5, 5, 2),
		PALETTE.cyan,
		{ studs = false, canCollide = false }
	)

	return spawn, nil, nil, nil, soloPrompt
end

local function buildHub(parent)
	if ExperienceConfig.World.UseToyboxHub then
		return buildToyboxHub(parent)
	end

	local _, _, spawn, soloPrompt = buildMainIsland(parent)
	local battlePrompt, storyPrompt = buildSideIslands(parent)
	buildBackground(parent)

	local battleSpawn = nil
	if ExperienceConfig.World.BuildBattleArenas then
		battleSpawn = makePart(
			parent,
			"BattleArenaSpawn",
			Vector3.new(14, 1, 14),
			Vector3.new(0, 18, -172),
			PALETTE.gold,
			Enum.Material.SmoothPlastic
		)
		makeBridge(
			parent,
			"ArenaMainBridge",
			Vector3.new(0, 15.2, -146),
			Vector3.new(0, 10.6, -270),
			13,
			-1
		)
	end

	return spawn, battlePrompt, storyPrompt, battleSpawn, soloPrompt
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
			transparency = 1,
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

	local spawn, battlePrompt, storyPrompt, battleSpawn, soloPrompt = buildHub(hub)
	local recoveryPlatform = buildRecoveryPlatform(hub, spawn)

	local arenas = {}
	if ExperienceConfig.World.BuildBattleArenas then
		for arenaIndex, arenaCenter in ARENA_CENTERS do
			table.insert(arenas, buildArena(hub, arenaIndex, arenaCenter))
		end
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

	removeBootstrapSafetyParts()

	return {
		hub = hub,
		spawn = spawn,
		soloPrompt = soloPrompt,
		battlePrompt = battlePrompt,
		storyPrompt = storyPrompt,
		battleSpawn = battleSpawn,
		recoveryPlatform = recoveryPlatform,
		arenas = arenas,
		arenaSpawns = arenas[1] and arenas[1].spawns or {},
		arenaReturnPad = arenas[1] and arenas[1].returnPad or nil,
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
