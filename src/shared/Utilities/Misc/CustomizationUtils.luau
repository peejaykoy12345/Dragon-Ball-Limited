local CustomizationUtils = {}

function CustomizationUtils.PutOnHair(char: Model, hair: Model)
    local head = char:FindFirstChild("Head")
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

    for _, part in ipairs(newHair:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            part.CanCollide = false
        end
    end

    newHair.Parent = char

    local weld = Instance.new("Weld")
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
end

function CustomizationUtils.SetCharacterHeight(char: Model, scale: number)
    char:SetAttribute("HeightScale", scale)
    CustomizationUtils._ApplyScale(char)
end

function CustomizationUtils.SetCharacterWidth(char: Model, scale: number)
    char:SetAttribute("WidthScale", scale)
    CustomizationUtils._ApplyScale(char)
end

return CustomizationUtils