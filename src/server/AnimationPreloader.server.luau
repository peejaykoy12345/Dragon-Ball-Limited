local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local function GetAllDescendants(instance: Instance): {Instance}
	local descendants = {}
	for _, descendant in ipairs(instance:GetDescendants()) do
		table.insert(descendants, descendant)
	end
	return descendants
end

local assets = GetAllDescendants(Assets)

ContentProvider:PreloadAsync(assets, function(assetId, status)
	if status ~= Enum.AssetFetchStatus.Success then
		warn(`Failed to preload {assetId}: {status}`)
	end
end)

local rig = Instance.new("Model")
rig.Name = "AnimationWarmupRig"

local rootPart = Instance.new("Part")
rootPart.Name = "HumanoidRootPart"
rootPart.Size = Vector3.new(2, 2, 1)
rootPart.Transparency = 1
rootPart.CanCollide = false
rootPart.Anchored = true
rootPart.Parent = rig
rig.PrimaryPart = rootPart

local humanoid = Instance.new("Humanoid")
humanoid.Parent = rig

local animator = Instance.new("Animator")
animator.Parent = humanoid

rig.Parent = workspace

local animCount = 0
local startTime = os.clock()

for _, asset in ipairs(assets) do
	if asset:IsA("Animation") then
		local track = animator:LoadAnimation(asset)
		track:Play()
		track:Stop(0)

		task.wait()
		track:Destroy()

		animCount += 1
	end
end

local elapsed = os.clock() - startTime

rig:Destroy()
print(string.format("[Server] Preloading done! Warmed up %d animations in %.2fs", animCount, elapsed))