local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Assets = ReplicatedStorage.Assets
local Models = Assets.Models

local IdleAnimation = Assets:WaitForChild("Animations"):WaitForChild("Default"):WaitForChild("Movement"):WaitForChild("Idle") :: Animation

local plr = Players.LocalPlayer
local ScreenGui = plr:WaitForChild("PlayerGui"):WaitForChild("MainMenu"):WaitForChild("Customization") :: ScreenGui
local CustomizationOptions = ScreenGui:WaitForChild("Customization options")
local Appearance = CustomizationOptions:WaitForChild("Appearance")
local CharacterAppearance = Appearance:WaitForChild("CharacterApperance")
local TypesFrame = CharacterAppearance:WaitForChild("Types") :: Frame

local ConfirmButton = Appearance:WaitForChild("Confirm") :: ImageButton

local ViewportFrame = ScreenGui:WaitForChild("ViewportFrame") :: ViewportFrame
local PreviewChar = ViewportFrame:WaitForChild("WorldModel"):WaitForChild("Preview")

local Modules = ReplicatedStorage.Modules
local Utilities = Modules.Utilities

local Animation = require(Utilities.Media.Animation)

local CustomizationUtils = require(Utilities.Misc.CustomizationUtils)

local Network = require(Modules.Network)
local MainMenuNamespace = Network["Main Menu"]
local MainMenuPackets = MainMenuNamespace.packets
local MainMenuQueries = MainMenuNamespace.queries
local GetCustomizationData = MainMenuQueries.GetCustomizationData

local CONFIG = {
    TYPES = {"Head/Hair"},
    SLIDER = {"Height", "Body Type"},
    ASSET_FOLDER = {
        ["Head/Hair"] = Models.Hair
    },
    EQUIP_FUNCTION = {
        ["Head/Hair"] = CustomizationUtils.PutOnHair
    },
    SLIDER_MIN_POS = 0.478,
    SLIDER_MAX_POS = 0.878,
    BUTTON_CLICK_COOLDOWN = 0.1,
    PROPORTIONS = {
        MINIMUM = {
            Height = 1,
            ["Body Type"] = 1,
        },
        MAXIMUM = {
            Height = 1.5,
            ["Body Type"] = 1.5,
        }
    }
}

local Customization = {}
Customization.__index = Customization

function Customization:_ConnectButtonClickedEvent(btn: ImageButton | TextButton, fn: () -> ())
    btn.Activated:Connect(function()
        if self.btnClickCooldown[btn] then return end
        if not self.Open then return end

        self.btnClickCooldown[btn] = true
        task.delay(CONFIG.BUTTON_CLICK_COOLDOWN, function()
            self.btnClickCooldown[btn] = nil
        end)

        fn()
    end)
end

function Customization:_PopulateTypes(btn)
    local assetFolder = CONFIG.ASSET_FOLDER[btn.Name]
    if not assetFolder then return end

    for _, child in TypesFrame:GetChildren() do
        if child.Name ~= "Template" and child:GetAttribute("TypeButton") then
            child:Destroy()
        end
    end

    local template = TypesFrame:FindFirstChild("Template")
    if not template then return end

    local items = assetFolder:GetChildren()

    for i, item in ipairs(items) do
        local itemName = "Type " .. tostring(i)

        local newBtn = template:Clone()
        newBtn.Name = itemName
        newBtn.Visible = true
        newBtn:SetAttribute("TypeButton", true)

        newBtn.TypeNumber.Text = itemName

        local yPos = 0.106 + (i - 1) * 0.067
        newBtn.Position = UDim2.new(newBtn.Position.X.Scale, 0, yPos, newBtn.Position.Y.Offset)

        newBtn.Parent = TypesFrame

        self:_ConnectButtonClickedEvent(newBtn, function()
            local char = PreviewChar
            local fn = CONFIG.EQUIP_FUNCTION[btn.Name]
            if not fn then return end

            local model = assetFolder:FindFirstChild(itemName)
            if not model then return end

            fn(char, model)

            if btn.Name == "Head/Hair" then
                self.customizationData.Hair = itemName
            end
        end)
    end
end

function Customization:_CreateXSlider(sliderButton: ImageButton, callback: (alpha: number) -> ())
    local dragging = false
    local dragConnection
    local endConnection

    local minPos = CONFIG.SLIDER_MIN_POS
    local maxPos = CONFIG.SLIDER_MAX_POS

    local function updatePosition(input: InputObject)
        local parent = sliderButton.Parent
        local parentAbsPos = parent.AbsolutePosition.X
        local parentAbsSize = parent.AbsoluteSize.X

        local mouseX = input.Position.X
        local relativeX = (mouseX - parentAbsPos) / parentAbsSize

        relativeX = math.clamp(relativeX, minPos, maxPos)

        sliderButton.Position = UDim2.new(
            relativeX,
            sliderButton.Position.X.Offset,
            sliderButton.Position.Y.Scale,
            sliderButton.Position.Y.Offset
        )
    end

    sliderButton.InputBegan:Connect(function(input: InputObject)
        if not self.Open then return end

        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            dragging = true

            dragConnection = UserInputService.InputChanged:Connect(function(changedInput)
                if dragging
                    and (changedInput.UserInputType == Enum.UserInputType.MouseMovement
                    or changedInput.UserInputType == Enum.UserInputType.Touch) then
                    updatePosition(changedInput)
                end
            end)

            endConnection = UserInputService.InputEnded:Connect(function(endedInput)
                if dragging
                    and (endedInput.UserInputType == Enum.UserInputType.MouseButton1
                    or endedInput.UserInputType == Enum.UserInputType.Touch) then

                    dragging = false

                    if dragConnection then
                        dragConnection:Disconnect()
                        dragConnection = nil
                    end
                    if endConnection then
                        endConnection:Disconnect()
                        endConnection = nil
                    end

                    local alpha = (sliderButton.Position.X.Scale - minPos) / (maxPos - minPos)
                    alpha = math.clamp(alpha, 0, 1)

                    callback(alpha)
                end
            end)
        end
    end)
end

function Customization:Init()
    self.btnClickCooldown = {}
    self.customizationData = {}

    for _, btn in ipairs(CharacterAppearance:GetChildren()) do
        if table.find(CONFIG.TYPES, btn.Name) then
            self:_ConnectButtonClickedEvent(btn, function()
                if self.typeOpened == btn then
                    TypesFrame.Visible = false
                    self.typeOpened = nil
                else
                    self:_PopulateTypes(btn)
                    TypesFrame.Visible = true
                    self.typeOpened = btn
                end
            end)
        elseif table.find(CONFIG.SLIDER, btn.Name) then
            local slider = btn:FindFirstChild("Slider") 
            if not slider then continue end

            local min = CONFIG.PROPORTIONS.MINIMUM[btn.Name]
            if not min then continue end

            local max = CONFIG.PROPORTIONS.MAXIMUM[btn.Name]
            if not max then continue end

            self:_CreateXSlider(slider, function(alpha)
                local scale = min + (max - min) * alpha

                if btn.Name == "Height" then
                    self.customizationData.Height = scale
                    CustomizationUtils.SetCharacterHeight(PreviewChar, scale)
                elseif btn.Name == "Body Type" then
                    self.customizationData.BodyType = scale
                    CustomizationUtils.SetCharacterWidth(PreviewChar, scale)
                end
            end)
        end
    end

    self:_ConnectButtonClickedEvent(ConfirmButton, function()
        self:CloseCustomization()
        MainMenuPackets.ConfirmCustomization.send(self.customizationData)
    end)

    Animation:Play(PreviewChar, IdleAnimation)
end

function Customization:OpenCustomization()
    self.customizationData = GetCustomizationData.invoke({})
    CustomizationUtils.ApplyCustomizationDataToCharacter(PreviewChar, self.customizationData)

    ScreenGui.Enabled = true
    self.Open = true
end

function Customization:CloseCustomization()
    ScreenGui.Enabled = false
    self.Open = false
end

return Customization