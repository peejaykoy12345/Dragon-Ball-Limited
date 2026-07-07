local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local plr = Players.LocalPlayer
local ScreenGui = plr:WaitForChild("PlayerGui"):WaitForChild("MainMenu"):WaitForChild("Slots") :: ScreenGui
local SlotsFrame = ScreenGui:WaitForChild("Slots") :: Folder
local ConfirmButton = ScreenGui:WaitForChild("Confirm") :: ImageButton

local Modules = ReplicatedStorage.Modules
local Network = require(Modules.Network)
local MainMenuNamespace = Network["Main Menu"]
local MainMenuPackets = MainMenuNamespace.packets
local MainMenuQueries = MainMenuNamespace.queries

local CONFIG = {
    BUTTON_CLICK_COOLDOWN = 0.5,
}

local Slots = {}
Slots.__index = Slots

function Slots:_ConnectButtonClickedEvent(btn: ImageButton | TextButton, fn: () -> ())
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

function Slots:Init()
    self.btnClickCooldown = {}

    for _, btn in ipairs(SlotsFrame:GetChildren()) do
        if not btn:IsA("ImageButton") then continue end

        self:_ConnectButtonClickedEvent(btn, function()
            self.SlotSelected = btn.Name
        end)
    end

    self:_ConnectButtonClickedEvent(ConfirmButton, function()
        self:CloseUI()

        if not self.SlotSelected then return end

        MainMenuPackets.ChangeSlot.send({Slot = tonumber(self.SlotSelected)})
    end)
end

function Slots:OpenUI()
    ScreenGui.Enabled = true
    self.Open = true

    local slotData = MainMenuQueries.GetSlotData.invoke({})
    for slotNumber, data in ipairs(slotData) do
        local slotName = tostring(slotNumber)
        local frame = SlotsFrame:FindFirstChild(slotName)
        if not frame then continue end

        frame:WaitForChild("Lv.").Text = "Lv. " .. tostring(data.Level)

        local infoFrame = frame:WaitForChild("Info")
        local powerLevelInput = infoFrame:WaitForChild("Power Level Number") :: TextLabel
        local raceInput = infoFrame:WaitForChild("RaceInput") :: TextLabel

        powerLevelInput.Text = data.PowerLevel
        raceInput.Text = data.Race
    end
end

function Slots:CloseUI()
    ScreenGui.Enabled = false
    self.Open = false
end

return Slots