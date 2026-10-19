-- PANDEMONIUM v1.0
-- Visual UI prototype for Roblox Studio / a place you own.
-- This is a cosmetic interface shell: toggles do not alter gameplay or track other players.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("PandemoniumUI")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "PandemoniumUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local C = {
    bg = Color3.fromRGB(12, 12, 14),
    panel = Color3.fromRGB(22, 22, 25),
    panel2 = Color3.fromRGB(31, 31, 35),
    white = Color3.fromRGB(242, 242, 245),
    muted = Color3.fromRGB(155, 155, 163),
    line = Color3.fromRGB(75, 75, 83),
    accent = Color3.fromRGB(220, 220, 228),
    on = Color3.fromRGB(235, 235, 240),
}

local function corner(parent, radius)
    local x = Instance.new("UICorner")
    x.CornerRadius = UDim.new(0, radius or 7)
    x.Parent = parent
    return x
end

local function stroke(parent, color, thickness, transparency)
    local x = Instance.new("UIStroke")
    x.Color = color or C.line
    x.Thickness = thickness or 1
    x.Transparency = transparency or 0
    x.Parent = parent
    return x
end

local function label(parent, text, size, pos, fontSize, color, font)
    local x = Instance.new("TextLabel")
    x.BackgroundTransparency = 1
    x.Text = text
    x.Size = size
    x.Position = pos
    x.Font = font or Enum.Font.Gotham
    x.TextSize = fontSize or 14
    x.TextColor3 = color or C.white
    x.TextXAlignment = Enum.TextXAlignment.Left
    x.TextYAlignment = Enum.TextYAlignment.Center
    x.Parent = parent
    return x
end

local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- Main ClickGUI
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.fromOffset(590, 390)
main.Position = UDim2.new(0.5, -295, 0.5, -195)
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 0
main.Visible = false
main.Parent = gui
corner(main, 10)
stroke(main, C.line, 1)

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 58)
header.BackgroundColor3 = C.panel
header.BorderSizePixel = 0
header.Parent = main
corner(header, 10)
makeDraggable(main, header)

label(header, "♜  PANDEMONIUM", UDim2.new(1, -120, 0, 28), UDim2.fromOffset(17, 7), 20, C.white, Enum.Font.GothamBold)
label(header, "UNIVERSAL UI  •  v1.0", UDim2.new(1, -120, 0, 18), UDim2.fromOffset(19, 34), 10, C.muted)

local close = Instance.new("TextButton")
close.Size = UDim2.fromOffset(32, 30)
close.Position = UDim2.new(1, -43, 0, 14)
close.BackgroundColor3 = C.panel2
close.Text = "×"
close.TextSize = 22
close.TextColor3 = C.white
close.Font = Enum.Font.Gotham
close.BorderSizePixel = 0
close.Parent = header
corner(close, 6)
close.MouseButton1Click:Connect(function() main.Visible = false end)

local categories = {"Combat", "Visuals", "Player", "Misc", "Settings"}
local moduleMap = {
    Combat = {"Target HUD (demo)", "Target Card Preview"},
    Visuals = {"HUD", "Crosshair Preview", "Interface Glow"},
    Player = {"Show Player Panel", "Movement Info (demo)"},
    Misc = {"Notifications", "Watermark"},
    Settings = {"Move HUD", "Compact Mode", "Show Demo Data"},
}
local selectedCategory = "Visuals"
local enabled = {
    ["Target HUD (demo)"] = true, ["Target Card Preview"] = true,
    ["HUD"] = true, ["Crosshair Preview"] = false, ["Interface Glow"] = true,
    ["Show Player Panel"] = false, ["Movement Info (demo)"] = false,
    ["Notifications"] = true, ["Watermark"] = true,
    ["Move HUD"] = false, ["Compact Mode"] = false, ["Show Demo Data"] = true,
}
local moduleArea = Instance.new("Frame")
moduleArea.Position = UDim2.fromOffset(14, 145)
moduleArea.Size = UDim2.new(1, -28, 1, -160)
moduleArea.BackgroundTransparency = 1
moduleArea.Parent = main

local function renderModules()
    moduleArea:ClearAllChildren()
    local grid = Instance.new("UIGridLayout")
    grid.CellSize = UDim2.new(0.5, -6, 0, 47)
    grid.CellPadding = UDim2.fromOffset(10, 9)
    grid.SortOrder = Enum.SortOrder.LayoutOrder
    grid.Parent = moduleArea

    for _, name in ipairs(moduleMap[selectedCategory] or {}) do
        local card = Instance.new("Frame")
        card.BackgroundColor3 = C.panel
        card.BorderSizePixel = 0
        card.Parent = moduleArea
        corner(card, 7)
        stroke(card, C.line, 1, 0.35)

        label(card, name, UDim2.new(1, -75, 1, 0), UDim2.fromOffset(12, 0), 13, C.white)

        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.fromOffset(45, 23)
        toggle.Position = UDim2.new(1, -56, 0.5, -11)
        toggle.BorderSizePixel = 0
        toggle.Font = Enum.Font.GothamBold
        toggle.TextSize = 10
        toggle.Parent = card
        corner(toggle, 6)

        local function updateToggle()
            toggle.Text = enabled[name] and "ON" or "OFF"
            toggle.BackgroundColor3 = enabled[name] and C.on or C.panel2
            toggle.TextColor3 = enabled[name] and C.bg or C.muted
        end
        updateToggle()
        toggle.MouseButton1Click:Connect(function()
            enabled[name] = not enabled[name]
            updateToggle()
            if name == "Move HUD" then
                -- The HUD can be dragged directly when this option is enabled.
                targetHud.Active = enabled[name]
            elseif name == "Target HUD (demo)" or name == "HUD" then
                targetHud.Visible = enabled[name]
            elseif name == "Show Demo Data" then
                demoDetails.Visible = enabled[name]
            end
        end)
    end
end

local catBar = Instance.new("Frame")
catBar.Position = UDim2.fromOffset(14, 69)
catBar.Size = UDim2.new(1, -28, 0, 34)
catBar.BackgroundTransparency = 1
catBar.Parent = main
local catLayout = Instance.new("UIListLayout")
catLayout.FillDirection = Enum.FillDirection.Horizontal
catLayout.Padding = UDim.new(0, 7)
catLayout.Parent = catBar

local categoryButtons = {}
local function updateCategoryColors()
    for name, button in pairs(categoryButtons) do
        button.BackgroundColor3 = (name == selectedCategory) and C.white or C.panel2
        button.TextColor3 = (name == selectedCategory) and C.bg or C.white
    end
end

for _, name in ipairs(categories) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 105, 1, 0)
    button.BackgroundColor3 = C.panel2
    button.BorderSizePixel = 0
    button.Text = name
    button.TextSize = 12
    button.Font = Enum.Font.GothamSemibold
    button.TextColor3 = C.white
    button.Parent = catBar
    corner(button, 6)
    categoryButtons[name] = button
    button.MouseButton1Click:Connect(function()
        selectedCategory = name
        updateCategoryColors()
        renderModules()
    end)
end
updateCategoryColors()
label(main, "MODULES  /  CLICK TO TOGGLE", UDim2.new(1, -30, 0, 20), UDim2.fromOffset(16, 115), 10, C.muted, Enum.Font.GothamBold)
renderModules()

-- Target HUD demo card (does not select or track real players)
local targetHud = Instance.new("Frame")
targetHud.Name = "TargetHUD"
targetHud.Size = UDim2.fromOffset(310, 94)
targetHud.Position = UDim2.new(0.5, -155, 0.18, 0)
targetHud.BackgroundColor3 = C.bg
targetHud.BackgroundTransparency = 0.06
targetHud.BorderSizePixel = 0
targetHud.Parent = gui
corner(targetHud, 9)
stroke(targetHud, C.accent, 1.2, 0.05)
makeDraggable(targetHud, targetHud)

local avatar = Instance.new("ImageLabel")
avatar.Size = UDim2.fromOffset(62, 62)
avatar.Position = UDim2.fromOffset(12, 16)
avatar.BackgroundColor3 = C.panel2
avatar.BorderSizePixel = 0
avatar.Image = ""
avatar.Parent = targetHud
corner(avatar, 6)
stroke(avatar, C.line, 1)

label(targetHud, "PLAYER_NAME", UDim2.new(1, -95, 0, 22), UDim2.fromOffset(86, 12), 15, C.white, Enum.Font.GothamBold)
local demoDetails = Instance.new("Frame")
demoDetails.BackgroundTransparency = 1
demoDetails.Position = UDim2.fromOffset(86, 36)
demoDetails.Size = UDim2.new(1, -98, 1, -40)
demoDetails.Parent = targetHud
label(demoDetails, "HP: 85 / 100", UDim2.new(1, 0, 0, 16), UDim2.fromOffset(0, 0), 11, C.muted)
local hpBack = Instance.new("Frame")
hpBack.Position = UDim2.fromOffset(0, 20)
hpBack.Size = UDim2.new(1, -2, 0, 8)
hpBack.BackgroundColor3 = C.panel2
hpBack.BorderSizePixel = 0
hpBack.Parent = demoDetails
corner(hpBack, 4)
local hpFill = Instance.new("Frame")
hpFill.Size = UDim2.new(0.85, 0, 1, 0)
hpFill.BackgroundColor3 = C.white
hpFill.BorderSizePixel = 0
hpFill.Parent = hpBack
corner(hpFill, 4)
label(demoDetails, "Distance: --", UDim2.new(1, 0, 0, 16), UDim2.fromOffset(0, 30), 11, C.muted)

local watermark = label(gui, "PANDEMONIUM  •  UI DEMO", UDim2.fromOffset(230, 22), UDim2.new(0, 14, 1, -34), 11, C.muted, Enum.Font.GothamBold)

-- Optional center crosshair preview
local crosshair = label(gui, "+", UDim2.fromOffset(20, 24), UDim2.new(0.5, -10, 0.5, -12), 22, C.white, Enum.Font.Gotham)
crosshair.Visible = enabled["Crosshair Preview"]

-- Keep cosmetic preview toggles reflected on screen
local function syncCosmetics()
    crosshair.Visible = enabled["Crosshair Preview"]
    watermark.Visible = enabled["Watermark"]
    targetHud.Visible = enabled["HUD"] and enabled["Target HUD (demo)"]
end
for _, name in ipairs({"Crosshair Preview", "Watermark", "HUD", "Target HUD (demo)"}) do
    -- Module buttons call render logic; sync also runs when a key toggles the GUI.
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        main.Visible = not main.Visible
    end
end)

-- Initial state
targetHud.Visible = true
demoDetails.Visible = enabled["Show Demo Data"]
print("PANDEMONIUM UI loaded. RightShift toggles the menu.")
