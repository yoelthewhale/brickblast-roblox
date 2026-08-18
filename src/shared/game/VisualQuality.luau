-- Decides how much post-processing a client should run.
--
-- The effects stack (Bloom, SunRays, DepthOfField, hub particle emitters,
-- point lights) used to scale down only when the player manually turned on
-- Reduced Motion. A new mobile player has no reason to know that setting
-- exists, so low-end devices ran the full desktop stack by default --
-- SunRays and DepthOfField being among the most expensive post-effects on
-- mobile GPUs.
--
-- This decides the effects tier only. It deliberately does not touch the
-- player's Reduced Motion preference or the UI animations that setting
-- governs: turning off someone's animations because they are on a phone
-- would be a product decision, not a performance one.

local VisualQuality = {}

VisualQuality.Tier = {
	Full = "Full",
	Reduced = "Reduced",
}

-- Same breakpoint HUDController uses to decide the hub is on a phone, so the
-- two cannot disagree about what counts as a small screen.
VisualQuality.SmallScreenWidth = 720
VisualQuality.SmallScreenHeight = 520

local function screenDimensions(screenSize)
	if typeof(screenSize) == "Vector2" then
		return screenSize.X, screenSize.Y
	end

	if typeof(screenSize) == "table" then
		local width = typeof(screenSize.X) == "number" and screenSize.X or nil
		local height = typeof(screenSize.Y) == "number" and screenSize.Y or nil
		return width, height
	end

	return nil, nil
end

-- `device` describes the client: touchEnabled / keyboardEnabled come from
-- UserInputService, screenSize from the camera viewport.
function VisualQuality.isLowTierDevice(device)
	if typeof(device) ~= "table" then
		return false
	end

	-- Touch with no keyboard is a phone or tablet. A laptop with a
	-- touchscreen reports both and keeps the full stack.
	if device.touchEnabled == true and device.keyboardEnabled ~= true then
		return true
	end

	local width, height = screenDimensions(device.screenSize)
	if width and width < VisualQuality.SmallScreenWidth then
		return true
	end
	if height and height < VisualQuality.SmallScreenHeight then
		return true
	end

	return false
end

function VisualQuality.tierFor(device, reducedMotion)
	if reducedMotion == true or VisualQuality.isLowTierDevice(device) then
		return VisualQuality.Tier.Reduced
	end

	return VisualQuality.Tier.Full
end

function VisualQuality.usesReducedEffects(device, reducedMotion)
	return VisualQuality.tierFor(device, reducedMotion) == VisualQuality.Tier.Reduced
end

return VisualQuality
