local SoundService = game:GetService("SoundService")

local SoundController = {}
SoundController.__index = SoundController

-- pitch shifts (via PlaybackSpeed) give the new Day44B animation cues a
-- distinct character without needing new uploaded assets: reusing an
-- already-verified sound at a different pitch is far lower risk than
-- guessing at unverified asset ids.
local SOUND_ASSETS = {
	Button = { id = "rbxassetid://12221967", pitch = 1 },
	Queue = { id = "rbxassetid://12221990", pitch = 1 },
	Place = { id = "rbxassetid://12221976", pitch = 1 },
	Blocked = { id = "rbxassetid://12221984", pitch = 1 },
	Clear = { id = "rbxassetid://12222005", pitch = 1 },
	Result = { id = "rbxassetid://12221990", pitch = 1 },
	Combo = { id = "rbxassetid://12222005", pitch = 1.18 },
	PerfectClear = { id = "rbxassetid://12221990", pitch = 0.85 },
	TrayRefill = { id = "rbxassetid://12221967", pitch = 1.35 },
}

function SoundController.new()
	local self = setmetatable({
		enabled = true,
		volume = 0.65,
		sounds = {},
	}, SoundController)

	for cueName, asset in SOUND_ASSETS do
		local sound = Instance.new("Sound")
		sound.Name = `BlockBlast{cueName}`
		sound.SoundId = asset.id
		sound.PlaybackSpeed = asset.pitch
		sound.Volume = self.volume
		sound.RollOffMode = Enum.RollOffMode.InverseTapered
		sound.Parent = SoundService
		self.sounds[cueName] = sound
	end

	return self
end

function SoundController:SetSettings(enabled, volume)
	self.enabled = enabled ~= false
	self.volume = math.clamp(volume or self.volume, 0, 1)

	for _, sound in self.sounds do
		sound.Volume = self.volume
	end
end

function SoundController:Play(cueName)
	local sound = self.sounds[cueName]
	if not self.enabled or self.volume <= 0 or not sound then
		return
	end

	sound.Volume = self.volume
	sound.TimePosition = 0
	sound:Play()
end

return SoundController
