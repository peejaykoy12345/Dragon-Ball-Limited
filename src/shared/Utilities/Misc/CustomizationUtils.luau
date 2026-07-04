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
        -- print("refPart for", modelName, ":", refPart)

        if refPart and refPart:IsA("BasePart") then
            local offset = refPart.CFrame:toObjectSpace(part.CFrame)
            local scaleRatio = charPart.Size / refPart.Size
            local sizeCorrection = part:GetAttribute("SizeCorrection") or Vector3.new(1, 1, 1)
            local finalScale = scaleRatio * sizeCorrection
            local scaledOffset = CFrame.new(offset.Position * scaleRatio) * offset.Rotation
            part.Size = part.Size * finalScale
            part.CFrame = charPart.CFrame * scaledOffset
        else
            -- warn("No refPart found for", modelName, "- clothing part will use template CFrame")
        end

        local weld = Instance.new("WeldConstraint")
        weld.Part0 = charPart
        weld.Part1 = part
        weld.Parent = part

        part.Anchored = false
        part.CanCollide = false
    end

    for _, model in ipairs(newClothing:GetChildren()) do
        -- print("Model | Part name: ", model.Name)
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

return CustomizationUtils