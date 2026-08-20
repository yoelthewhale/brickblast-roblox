local button = script.Parent
local reward = button:FindFirstChild("Gumball")

if reward then
    button.ClickDetector.OnClick:Connect(function()
        local newReward = reward:Clone()
        newReward.Parent = button
        -- Optional: adjust position or handle overlap logic
    end)
end