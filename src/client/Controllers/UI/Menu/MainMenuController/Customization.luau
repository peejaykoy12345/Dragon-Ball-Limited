local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local ScreenGui = plr:WaitForChild("PlayerGui"):WaitForChild("MainMenu"):WaitForChild("Customization") :: ScreenGui
local CustomizationOptions = ScreenGui:WaitForChild("Customization options")
local Appearance = CustomizationOptions:WaitForChild("Appearance")
local CharacterAppearance = Appearance:WaitForChild("CharacterApperance")
local TypesFrame = CharacterAppearance:WaitForChild("Types") :: Frame

local ViewportFrame = ScreenGui:WaitForChild("ViewportFrame") :: ViewportFrame
local PreviewChar = ViewportFrame:WaitForChild("Preview")

local CustomizationUtils = require(ReplicatedStorage.Modules.Utilities.Misc.CustomizationUtils)

local Network = require(ReplicatedStorage.Modules.Network)
local MainMenuNamespace = Network["Main Menu"]
local MainMenuQueries = MainMenuNamespace.queries
local GetCustomizationData = MainMenuQueries.GetCustomizationData

local CONFIG = {
    TYPES = {"Head/Hair"},
    SLIDER = {"Height", "Body Type"},
    SLIDER_MIN_POS = 0.478,
    SLIDER_MAX_POS = 0.878,
    BUTTON_CLICK_COOLDOWN = 0.1,
    PROPORTIONS = {
        MINIMUM = {
            Height = 0.8,
            ["Body Type"] = 0.8,
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
        print("Open: ", self.Open)
        if self.btnClickCooldown[btn] then return end
        if not self.Open then return end

        self.btnClickCooldown[btn] = true
        task.delay(CONFIG.BUTTON_CLICK_COOLDOWN, function()
            self.btnClickCooldown[btn] = nil
        end)

        fn()
    end)
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

    self.defaultCustomizationData = GetCustomizationData.invoke({})

    for _, btn in ipairs(CharacterAppearance:GetChildren()) do
        if table.find(CONFIG.TYPES, btn.Name) then
            self:_ConnectButtonClickedEvent(btn, function()
                if self.typeOpened == btn then
                    TypesFrame.Visible = false
                    self.typeOpened = nil

                else
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

                print("Scale: ", scale)

                if btn.Name == "Height" then
                    CustomizationUtils.SetCharacterHeight(PreviewChar, scale)
                elseif btn.Name == "Body Type" then
                    CustomizationUtils.SetCharacterWidth(PreviewChar, scale)
                end
            end)
        end
    end

    for _, typeButton in ipairs(TypesFrame:GetChildren()) do
        if not typeButton:IsA("ImageButton") and not typeButton:IsA("TextButton") then continue end
        print("Type Button: ", typeButton)
        self:_ConnectButtonClickedEvent(typeButton, function()
            print("Types opened: ", self.typeOpened, " Types: Type ", typeButton.Name)
        end)
    end

    CustomizationUtils.ApplyCustomizationDataToCharacter(PreviewChar, self.defaultCustomizationData)
end

function Customization:OpenCustomization()
    ScreenGui.Enabled = true
    self.Open = true
end

return Customization