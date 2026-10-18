
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local GUI = Instance.new("ScreenGui")
GUI.Name = "Pandemonium"
GUI.ResetOnSpawn = false
GUI.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Main window
local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(570, 360)
Main.Position = UDim2.new(0.5, -285, 0.5, -180)
Main.BackgroundColor3 = Color3.fromRGB(17, 15, 24)
Main.BorderSizePixel = 0
Main.Visible = false
Main.Parent = GUI

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 10)
mainCorner.Parent = Main

local function createLabel(parent, text, size, position, color)
    local label = Instance.new("TextLabel")
    label.Size = size
    label.Position = position
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color or Color3.fromRGB(235, 230, 255)
    label.TextSize = 14
    label.Font = Enum.Font.GothamMedium
    label.Parent = parent
    return label
end

-- Header
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 58)
Header.BackgroundColor3 = Color3.fromRGB(27, 21, 40)
Header.BorderSizePixel = 0
Header.Parent = Main

createLabel(
    Header,
    "PANDEMONIUM",
    UDim2.new(1, -30, 0, 30),
    UDim2.fromOffset(15, 5),
    Color3.fromRGB(190, 115, 255)
)

createLabel(
    Header,
    "XENO  |  VISUAL CLIENT",
    UDim2.new(1, -30, 0, 18),
    UDim2.fromOffset(16, 32),
    Color3.fromRGB(145, 130, 170)
)

-- Categories at the top
local Categories = {
    "Combat",
    "Visuals",
    "Player",
    "Misc",
    "Settings"
}

local SelectedCategory = "Visuals"

local CategoryBar = Instance.new("Frame")
CategoryBar.Position = UDim2.fromOffset(12, 70)
CategoryBar.Size = UDim2.new(1, -24, 0, 38)
CategoryBar.BackgroundTransparency = 1
CategoryBar.Parent = Main

local CategoryLayout = Instance.new("UIListLayout")
CategoryLayout.FillDirection = Enum.FillDirection.Horizontal
CategoryLayout.Padding = UDim.new(0, 6)
CategoryLayout.SortOrder = Enum.SortOrder.LayoutOrder
CategoryLayout.Parent = CategoryBar

local ModulesFrame = Instance.new("Frame")
ModulesFrame.Position = UDim2.fromOffset(12, 118)
ModulesFrame.Size = UDim2.new(1, -24, 1, -130)
ModulesFrame.BackgroundTransparency = 1
ModulesFrame.Parent = Main

local ModuleNames = {
    Visuals = {
        "Target HUD",
        "Target Box",
        "Distance Display",
        "Highlight",
        "Interface Effects"
    },
    Combat = {
        "Target Info"
    },
    Player = {
        "Player Info"
    },
    Misc = {
        "Notifications"
    },
    Settings = {
        "Show Target HUD",
        "Show Target Box"
    }
}

local Enabled = {
    ["Target HUD"] = true,
    ["Target Box"] = true,
    ["Distance Display"] = true,
    ["Highlight"] = false,
    ["Interface Effects"] = true,
    ["Target Info"] = false,
    ["Player Info"] = false,
    ["Notifications"] = true,
    ["Show Target HUD"] = true,
    ["Show Target Box"] = true
}

local function renderModules()
    ModulesFrame:ClearAllChildren()

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 7)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = ModulesFrame

    for _, name in ipairs(ModuleNames[SelectedCategory] or {}) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 36)
        button.BackgroundColor3 = Color3.fromRGB(31, 27, 42)
        button.BorderSizePixel = 0
        button.Text = ""
        button.Parent = ModulesFrame

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = button

        createLabel(
            button,
            name,
            UDim2.new(0.7, 0, 1, 0),
            UDim2.fromOffset(12, 0)
        )

        local state = createLabel(
            button,
Enabled[name] and "ON" or "OFF",
            UDim2.new(0, 55, 1, 0),
            UDim2.new(1, -65, 0, 0),
            Enabled[name]
                and Color3.fromRGB(190, 115, 255)
                or Color3.fromRGB(125, 115, 140)
        )

        button.MouseButton1Click:Connect(function()
            Enabled[name] = not Enabled[name]

            state.Text = Enabled[name] and "ON" or "OFF"
            state.TextColor3 = Enabled[name]
                and Color3.fromRGB(190, 115, 255)
                or Color3.fromRGB(125, 115, 140)
        end)
    end
end

for _, category in ipairs(Categories) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 103, 0, 34)
    button.BackgroundColor3 = Color3.fromRGB(31, 27, 42)
    button.Text = category
    button.TextColor3 = Color3.fromRGB(225, 215, 245)
    button.TextSize = 12
    button.Font = Enum.Font.GothamMedium
    button.BorderSizePixel = 0
    button.Parent = CategoryBar

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = button

    button.MouseButton1Click:Connect(function()
        SelectedCategory = category

        for _, child in ipairs(CategoryBar:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 =
                    child.Text == category
                    and Color3.fromRGB(91, 48, 130)
                    or Color3.fromRGB(31, 27, 42)
            end
        end

        renderModules()
    end)
end

renderModules()

-- Right Shift opens/closes the menu
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end

    if input.KeyCode == Enum.KeyCode.RightShift then
        Main.Visible = not Main.Visible
    end
end)

-- Target HUD
local TargetHUD = Instance.new("Frame")
TargetHUD.Size = UDim2.fromOffset(220, 72)
TargetHUD.Position = UDim2.new(0, 25, 0.5, -36)
TargetHUD.BackgroundColor3 = Color3.fromRGB(20, 17, 29)
TargetHUD.BackgroundTransparency = 0.08
TargetHUD.BorderSizePixel = 0
TargetHUD.Visible = true
TargetHUD.Parent = GUI

local hudCorner = Instance.new("UICorner")
hudCorner.CornerRadius = UDim.new(0, 8)
hudCorner.Parent = TargetHUD

local TargetName = createLabel(
    TargetHUD,
    "TARGET: NONE",
    UDim2.new(1, -16, 0, 28),
    UDim2.fromOffset(10, 8),
    Color3.fromRGB(200, 140, 255)
)

local TargetDistance = createLabel(
    TargetHUD,
    "Distance: --",
    UDim2.new(1, -16, 0, 22),
    UDim2.fromOffset(10, 38),
    Color3.fromRGB(225, 220, 235)
)

-- Target selection: nearest visible player
local TargetBox = Instance.new("Frame")
TargetBox.Size = UDim2.fromOffset(48, 48)
TargetBox.AnchorPoint = Vector2.new(0.5, 0.5)
TargetBox.BackgroundTransparency = 1
TargetBox.Visible = false
TargetBox.Parent = GUI

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(190, 115, 255)
stroke.Thickness = 2
stroke.Parent = TargetBox

local boxCorner = Instance.new("UICorner")
boxCorner.CornerRadius = UDim.new(0, 3)
boxCorner.Parent = TargetBox

local MAX_DISTANCE = 250

RunService.RenderStepped:Connect(function()
    local myCharacter = LocalPlayer.Character
    local myRoot = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")

    if not myRoot then
        TargetBox.Visible = false
        TargetHUD.Visible = false
        return
    end

    local bestPlayer = nil
    local bestDistance = MAX_DISTANCE
    local bestPosition = nil

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")

            if root and humanoid and humanoid.Health > 0 then
                local distance = (root.Position - myRoot.Position).Magnitude
                local screenPosition, onScreen = Camera:WorldToViewportPoint(root.Position)

                if distance < bestDistance and onScreen then
                    bestDistance = distance
                    bestPlayer = player
                    bestPosition = screenPosition
                end
            end
        end
    end

    TargetHUD.Visible = Enabled["Target HUD"]

    if bestPlayer then
        TargetName.Text = "TARGET: " .. bestPlayer.Name
        TargetDistance.Text = string.format(
            "Distance: %.1f studs",
            bestDistance
        )

        TargetBox.Visible = Enabled["Target Box"]
        TargetBox.Position = UDim2.fromOffset(
            bestPosition.X,
            bestPosition.Y
        )
    else
        TargetName.Text = "TARGET: NONE"
        TargetDistance.Text = "Distance: --"
        TargetBox.Visible = false
    end
end)






