local HubBuilder = {}
local Lighting = game:GetService("Lighting")

local ARENA_CENTERS = {
	Vector3.new(0, 2.25, -82),
	Vector3.new(112, 2.25, -82),
	Vector3.new(-112, 2.25, -82),
}

local function makePart(parent, name, size, position, color, material)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CastShadow = false
	part.Parent = parent

	return part
end

local function makeWall(parent, name, size, position, color)
	local wall = makePart(parent, name, size, position, color, Enum.Material.Concrete)
	wall.Transparency = 0.08

	return wall
end

local function makeBeam(parent, name, position, color)
	local beam =
		makePart(parent, name, Vector3.new(1.4, 18, 1.4), position, color, Enum.Material.Neon)
	beam.Transparency = 0.18

	return beam
end

local function addSurfaceText(part, text, face, color)
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "SurfaceText"
	surfaceGui.Face = face
	surfaceGui.AlwaysOnTop = false
	surfaceGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surfaceGui.PixelsPerStud = 40
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
	billboard.Size = UDim2.fromOffset(220, 82)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local titleLabel = Instance.new("TextLabel")
	titleLabel.BackgroundTransparency = 1
	titleLabel.Size = UDim2.fromScale(1, 0.55)
	titleLabel.Font = Enum.Font.GothamBlack
	titleLabel.Text = title
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
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
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt.Parent = part

	return prompt
end

local function buildArena(parent, arenaIndex, arenaCenter)
	local arena = Instance.new("Folder")
	arena.Name = `BattleArena{arenaIndex}`
	arena.Parent = parent

	makePart(
		arena,
		"ArenaFloor",
		Vector3.new(86, 2, 62),
		arenaCenter + Vector3.new(0, -0.25, 0),
		Color3.fromRGB(22, 24, 32),
		Enum.Material.Metal
	)
	makePart(
		arena,
		"CenterLane",
		Vector3.new(10, 0.4, 54),
		arenaCenter + Vector3.new(0, 1.05, 0),
		Color3.fromRGB(64, 156, 255),
		Enum.Material.Neon
	).Transparency =
		0.35
	makePart(
		arena,
		"LeftPlayerDeck",
		Vector3.new(28, 1, 28),
		arenaCenter + Vector3.new(-25, 1.1, 0),
		Color3.fromRGB(45, 58, 82),
		Enum.Material.Slate
	)
	makePart(
		arena,
		"RightPlayerDeck",
		Vector3.new(28, 1, 28),
		arenaCenter + Vector3.new(25, 1.1, 0),
		Color3.fromRGB(45, 58, 82),
		Enum.Material.Slate
	)

	makeWall(
		arena,
		"NorthWall",
		Vector3.new(86, 12, 2),
		arenaCenter + Vector3.new(0, 6, -31),
		Color3.fromRGB(35, 42, 56)
	)
	makeWall(
		arena,
		"SouthWall",
		Vector3.new(86, 8, 2),
		arenaCenter + Vector3.new(0, 4, 31),
		Color3.fromRGB(35, 42, 56)
	)
	makeWall(
		arena,
		"LeftWall",
		Vector3.new(2, 10, 62),
		arenaCenter + Vector3.new(-43, 5, 0),
		Color3.fromRGB(31, 38, 52)
	)
	makeWall(
		arena,
		"RightWall",
		Vector3.new(2, 10, 62),
		arenaCenter + Vector3.new(43, 5, 0),
		Color3.fromRGB(31, 38, 52)
	)

	for _, offset in
		{
			Vector3.new(-39, 10, -27),
			Vector3.new(39, 10, -27),
			Vector3.new(-39, 10, 27),
			Vector3.new(39, 10, 27),
		}
	do
		makeBeam(arena, "ArenaGlowPillar", arenaCenter + offset, Color3.fromRGB(244, 114, 182))
	end

	local scoreboard = makePart(
		arena,
		"Scoreboard",
		Vector3.new(34, 8, 1),
		arenaCenter + Vector3.new(0, 9, -29.5),
		Color3.fromRGB(12, 16, 24),
		Enum.Material.SmoothPlastic
	)
	addSurfaceText(
		scoreboard,
		`BLOCK BLAST BATTLE - ARENA {arenaIndex}`,
		Enum.NormalId.Front,
		Color3.fromRGB(245, 247, 251)
	)

	local leftSpawn = makePart(
		arena,
		"PlayerSpawnA",
		Vector3.new(8, 1, 8),
		arenaCenter + Vector3.new(-25, 2.25, 17),
		Color3.fromRGB(64, 156, 255),
		Enum.Material.Neon
	)
	addLabel(leftSpawn, "PLAYER A", "Your board")

	local rightSpawn = makePart(
		arena,
		"PlayerSpawnB",
		Vector3.new(8, 1, 8),
		arenaCenter + Vector3.new(25, 2.25, 17),
		Color3.fromRGB(244, 114, 182),
		Enum.Material.Neon
	)
	addLabel(rightSpawn, "PLAYER B", "Your board")

	local returnPad = makePart(
		arena,
		"ReturnHubPad",
		Vector3.new(12, 1, 8),
		arenaCenter + Vector3.new(0, 2.25, 23),
		Color3.fromRGB(251, 146, 60),
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

function HubBuilder.build()
	Lighting.GlobalShadows = false
	Lighting.EnvironmentDiffuseScale = 0.25
	Lighting.EnvironmentSpecularScale = 0.15

	local existing = workspace:FindFirstChild("BlockBlastHub")
	if existing then
		existing:Destroy()
	end

	local hub = Instance.new("Folder")
	hub.Name = "BlockBlastHub"
	hub.Parent = workspace

	makePart(
		hub,
		"Base",
		Vector3.new(96, 2, 72),
		Vector3.new(0, 0, 0),
		Color3.fromRGB(31, 38, 52),
		Enum.Material.Slate
	)
	makePart(
		hub,
		"BattleWalkway",
		Vector3.new(28, 1, 10),
		Vector3.new(-25, 1.5, 0),
		Color3.fromRGB(45, 58, 82),
		Enum.Material.Concrete
	)
	makePart(
		hub,
		"StoryWalkway",
		Vector3.new(28, 1, 10),
		Vector3.new(25, 1.5, 0),
		Color3.fromRGB(45, 58, 82),
		Enum.Material.Concrete
	)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "HubSpawn"
	spawn.Anchored = true
	spawn.Size = Vector3.new(14, 1, 14)
	spawn.Position = Vector3.new(0, 2.25, 20)
	spawn.Color = Color3.fromRGB(64, 156, 255)
	spawn.Material = Enum.Material.Neon
	spawn.CastShadow = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = hub
	addLabel(spawn, "BLOCK BLAST", "Battle Hub")

	local battlePad = makePart(
		hub,
		"BattleQueuePad",
		Vector3.new(16, 1, 16),
		Vector3.new(-34, 2.25, 0),
		Color3.fromRGB(244, 114, 182),
		Enum.Material.SmoothPlastic
	)
	battlePad:SetAttribute("QueueMode", "Battle")
	addLabel(battlePad, "BATTLE QUEUE", "Clear lines to attack")
	local battlePrompt = addPrompt(battlePad, "Join Queue", "Block Blast Battle")

	local storyPad = makePart(
		hub,
		"StoryQueuePad",
		Vector3.new(16, 1, 16),
		Vector3.new(34, 2.25, 0),
		Color3.fromRGB(74, 222, 128),
		Enum.Material.SmoothPlastic
	)
	storyPad:SetAttribute("QueueMode", "Story")
	addLabel(storyPad, "STORY MODE", "Solo training")
	local storyPrompt = addPrompt(storyPad, "Start", "Story Training")

	local battleSpawn = makePart(
		hub,
		"BattleArenaSpawn",
		Vector3.new(12, 1, 12),
		Vector3.new(0, 2.25, -36),
		Color3.fromRGB(251, 146, 60),
		Enum.Material.SmoothPlastic
	)
	battleSpawn.Transparency = 0
	addLabel(battleSpawn, "ARENA", "Match starts here")

	makePart(
		hub,
		"ArenaBridge",
		Vector3.new(14, 1, 42),
		Vector3.new(0, 1.5, -56),
		Color3.fromRGB(45, 58, 82),
		Enum.Material.Concrete
	)
	makeBeam(hub, "BattlePortalLeft", Vector3.new(-8, 10, -36), Color3.fromRGB(64, 156, 255))
	makeBeam(hub, "BattlePortalRight", Vector3.new(8, 10, -36), Color3.fromRGB(244, 114, 182))
	local arenas = {}
	for arenaIndex, arenaCenter in ARENA_CENTERS do
		table.insert(arenas, buildArena(hub, arenaIndex, arenaCenter))
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
