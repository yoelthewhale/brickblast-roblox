local SoundService = game:GetService("SoundService")

local SoundController = {}
SoundController.__index = SoundController

local SOUND_ASSETS = {
	Button = "rbxassetid://12221967",
	Queue = "rbxassetid://12221990",
	Place = "rbxassetid://12221976",
	Blocked = "rbxassetid://12221984",
	Clear = "rbxassetid://12222005",
	Result = "rbxassetid://12221990",
}

function SoundController.new()
	local self = setmetatable({
		enabled = true,
		volume = 0.65,
		sounds = {},
	}, SoundController)

	for cueName, soundId in SOUND_ASSETS do
		local sound = Instance.new("Sound")
		sound.Name = `BlockBlast{cueName}`
		sound.SoundId = soundId
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
