local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Assets = ReplicatedStorage.Assets
local Models = Assets.Models :: Folder
local Clothing = Models:WaitForChild("Clothing") :: Folder
local Hairs = Models:WaitForChild("Hair") :: Folder

local Animations = Assets.Animations
local CharacterAnimations = Animations.Characters

local Animation = require(ReplicatedStorage.Modules.Utilities.Media.Animation)

local CustomizationUtils = {}

function CustomizationUtils._ResolveRig(char: Model)
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local visited = { [rootPart] = true }
	local queue = { rootPart }

	while #queue > 0 do
		local current = table.remove(queue, 1)

		for _, descendant in char:GetDescendants() do
			if not descendant:IsA("Motor6D") then continue end

			if descendant.Part0 == current and descendant.Part1 and not visited[descendant.Part1] then
				descendant.Part1.CFrame = current.CFrame * descendant.C0 * descendant.C1:Inverse()
				visited[descendant.Part1] = true
				table.insert(queue, descendant.Part1)
			end
		end
	end
end

function CustomizationUtils.PutOnHair(char: Model, hair: Model)
	local head = char:WaitForChild("Head")
	if not head then return end

	local existing = char:FindFirstChild("Hair")
	if existing then
		existing:Destroy()
	end

	local newHair = hair:Clone()
	newHair.Name = "Hair"

	local handle = newHair.PrimaryPart or newHair:FindFirstChild("Handle") or newHair:FindFirstChild("Base")
	if not handle then
		warn("PutOnHair: no Handle part found in hair model", hair.Name)
		newHair:Destroy()
		return
	end

	local heightScale = char:GetAttribute("HeightScale") or 1
	local widthScale = char:GetAttribute("WidthScale") or 1
	local scaleVec = Vector3.new(widthScale, heightScale, widthScale)

	for _, part in ipairs(newHair:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Size = part.Size * scaleVec

			if part ~= handle then
				local offset = handle.CFrame:ToObjectSpace(part.CFrame)
				local scaledOffset = CFrame.new(offset.Position * scaleVec) * offset.Rotation
				part.CFrame = handle.CFrame * scaledOffset
			end

			part.Anchored = false
			part.CanCollide = false
		end
	end

	newHair.Parent = char
	newHair:SetPrimaryPartCFrame(head.CFrame)

	local sourceRef = Instance.new("ObjectValue")
	sourceRef.Name = "SourceHair"
	sourceRef.Value = hair
	sourceRef.Parent = newHair

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = head
	weld.Part1 = handle
	weld.Parent = newHair
end

function CustomizationUtils.PutOnClothing(char: Model, clothing: Model)
	local existing = char:FindFirstChild("Clothing")
	if existing then
		existing:Destroy()
	end

	local newClothing = clothing:Clone()
	newClothing.Name = "Clothing"

	local referenceModel = newClothing:FindFirstChild("ReferenceModel")

	local function weldPart(part: BasePart, modelName: string)
		local charPart = char:FindFirstChild(modelName)
		if not charPart or not charPart:IsA("BasePart") then return end

		local refPart = referenceModel and referenceModel:FindFirstChild(modelName)

		if refPart and refPart:IsA("BasePart") then
			local offset = refPart.CFrame:toObjectSpace(part.CFrame)

			part:SetAttribute("OriginalClothingSize", part.Size)
			part:SetAttribute("OriginalClothingOffset", offset)

			local scaleRatio = charPart.Size / refPart.Size
			local sizeCorrection = part:GetAttribute("SizeCorrection") or Vector3.new(1, 1, 1)
			local finalScale = scaleRatio * sizeCorrection
			local scaledOffset = CFrame.new(offset.Position * scaleRatio) * offset.Rotation
			part.Size = part.Size * finalScale
			part.CFrame = charPart.CFrame * scaledOffset
		end

		local weld = Instance.new("WeldConstraint")
		weld.Part0 = charPart
		weld.Part1 = part
		weld.Parent = part

		part.Anchored = false
		part.CanCollide = false
	end

	for _, model in ipairs(newClothing:GetChildren()) do
		if model == referenceModel then continue end

		if model:IsA("Model") then
			for _, part in ipairs(model:GetChildren()) do
				if part:IsA("BasePart") then
					weldPart(part, model.Name)
				end
			end
		elseif model:IsA("BasePart") then
			weldPart(model, model.Name)
		end
	end

	local sourceRef = Instance.new("ObjectValue")
	sourceRef.Name = "SourceClothing"
	sourceRef.Value = clothing
	sourceRef.Parent = newClothing

	if referenceModel then
		referenceModel:Destroy()
	end

	newClothing.Parent = char
end

local SCALE_PARTS = {
	"HumanoidRootPart",
	"Head",
	"UpperTorso", "LowerTorso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
	"RightUpperLeg", "RightLowerLeg", "RightFoot",
}

function CustomizationUtils._ApplyScale(char: Model)
	local heightScale = char:GetAttribute("HeightScale") or 1
	local widthScale = char:GetAttribute("WidthScale") or 1
	local scaleVec = Vector3.new(widthScale, heightScale, widthScale)

	for _, partName in SCALE_PARTS do
		local part = char:FindFirstChild(partName)
		if not part or not part:IsA("BasePart") then continue end

		local originalSize = part:GetAttribute("OriginalSize")
		if not originalSize then
			part:SetAttribute("OriginalSize", part.Size)
			originalSize = part.Size
		end

		part.Size = originalSize * scaleVec
	end

	for _, descendant in char:GetDescendants() do
		if not descendant:IsA("Motor6D") then continue end

		local originalC0Pos = descendant:GetAttribute("OriginalC0Pos")
		if not originalC0Pos then
			descendant:SetAttribute("OriginalC0Pos", descendant.C0.Position)
			descendant:SetAttribute("OriginalC1Pos", descendant.C1.Position)
			originalC0Pos = descendant.C0.Position
		end

		local originalC1Pos = descendant:GetAttribute("OriginalC1Pos")

		descendant.C0 = CFrame.new(originalC0Pos * scaleVec) * descendant.C0.Rotation
		descendant.C1 = CFrame.new(originalC1Pos * scaleVec) * descendant.C1.Rotation
	end

	local parent = char.Parent
	if parent and parent:IsA("ViewportFrame") then
		CustomizationUtils._ResolveRig(char)
	end

	local humanoid = char:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local originalHipHeight = humanoid:GetAttribute("OriginalHipHeight")
		if not originalHipHeight then
			humanoid:SetAttribute("OriginalHipHeight", humanoid.HipHeight)
			originalHipHeight = humanoid.HipHeight
		end

		humanoid.HipHeight = originalHipHeight * heightScale
	end

	local hairModel = char:FindFirstChild("Hair")
	if hairModel then
		local sourceRef = hairModel:FindFirstChild("SourceHair")
		local sourceHair = sourceRef and sourceRef.Value
		if sourceHair then
			CustomizationUtils.PutOnHair(char, sourceHair)
		end
	end

	local clothingModel = char:FindFirstChild("Clothing")
	if clothingModel then
		local sourceRef = clothingModel:FindFirstChild("SourceClothing")
		local sourceClothing = sourceRef and sourceRef.Value
		if sourceClothing then
			CustomizationUtils.PutOnClothing(char, sourceClothing)
		end
	end
end

function CustomizationUtils.SetCharacterHeight(char: Model, scale: number)
	char:SetAttribute("HeightScale", scale)
	CustomizationUtils._ApplyScale(char)
end

function CustomizationUtils.SetCharacterWidth(char: Model, scale: number)
	char:SetAttribute("WidthScale", scale)
	CustomizationUtils._ApplyScale(char)
end

function CustomizationUtils.ApplyRaceAppearance(char: Model, raceName: string, raceData)
	if raceName == "Saiyan" then
		local hasTail = raceData.HasTail

		if not hasTail then return end

		local LowerTorso = char:FindFirstChild("LowerTorso")
		if not LowerTorso then return end

		local TailAttachment = LowerTorso:FindFirstChild("WaistBackAttachment") :: Attachment
		if not TailAttachment then return end

		local saiyanTailTemplate = Models.Tails:FindFirstChild("Saiyan Tail")
		if not saiyanTailTemplate then return end

		local tail = saiyanTailTemplate:Clone() :: Model
		tail:SetPrimaryPartCFrame(TailAttachment.WorldCFrame * CFrame.Angles(0, math.rad(180), 0))

		local tailPart = tail:FindFirstChild("Tail")
		if not tailPart then
			warn(`Tail part not found for {tail.Name}`)
			return
		end

		local weld = Instance.new("WeldConstraint")
		weld.Name = "TailWeldConstraint"
		weld.Part0 = LowerTorso
		weld.Part1 = tailPart
		weld.Parent = tail

		tail.Parent = LowerTorso

		Animation:Play(tail, CharacterAnimations.Saiyan.SaiyanTail)
	end
end

function CustomizationUtils.ApplyCustomizationDataToCharacter(char: Model, data: {[string]: string | number})
	local height = data.Height or 1
	local bodyType = data.BodyType or 1

	char:SetAttribute("HeightScale", height)
	char:SetAttribute("WidthScale", bodyType)
	CustomizationUtils._ApplyScale(char)

	if data.Hair then
		local hairModel = Hairs:FindFirstChild(data.Hair)
		if hairModel then
			CustomizationUtils.PutOnHair(char, hairModel)
		else
			warn("ApplyCustomizationDataToCharacter: Hair not found:", data.Hair)
		end
	end

	if data.Race then
		CustomizationUtils.ApplyRaceAppearance(char, data.Race :: string, data.RaceData or {})
	end

	if data.Clothing then
		local clothingModel = Clothing:FindFirstChild(data.Clothing)
		if clothingModel then
			CustomizationUtils.PutOnClothing(char, clothingModel)
		else
			warn("ApplyCustomizationDataToCharacter: Clothing not found:", data.Clothing)
		end
	end
end

return CustomizationUtils