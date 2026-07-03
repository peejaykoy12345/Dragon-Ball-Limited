local Players = game:GetService("Players")

local player = Players.LocalPlayer

local function onCharacterAdded(char)
	local animate = char:WaitForChild("Animate", 5)
	if animate then
		animate:Destroy()
	end
end

if player.Character then
	onCharacterAdded(player.Character)
end

player.CharacterAdded:Connect(onCharacterAdded)