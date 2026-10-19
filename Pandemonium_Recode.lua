-- PANDEMONIUM RECODE
-- Universal-style UI shell for Roblox Lua.
-- Intended for Roblox Studio / experiences you own or are authorized to test.
-- Cosmetic UI, local lighting preview, and a non-targeting HUD demo.
-- RightShift: show/hide menu.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("PandemoniumRecode")
if oldGui then oldGui:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "PandemoniumRecode"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local Theme = {
    bg = Color3.fromRGB(13, 13, 17),
    panel = Color3.fromRGB(21, 20, 28),
    panel2 = Color3.fromRGB(31, 29, 40),
    line = Color3.fromRGB(67, 63, 82),
    white = Color3.fromRGB(245, 244, 250),
    muted = Color3.fromRGB(157, 153, 174),
    accent = Color3.fromRGB(210, 210, 220),
    on = Color3.fromRGB(239, 239, 245),
    off = Color3.fromRGB(67, 64, 82),
}

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local function round(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, obj)
end

local function outline(obj, color, transparency)
    make("UIStroke", {
        Color = color or Theme.line,
        Thickness = 1,
        Transparency = transparency or 0.15,
    }, obj)
end

local function label(parent, text, size, pos, fontSize, color, font)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        Size = size,
        Position = pos,
        Font = font or Enum.Font.Gotham,
        TextSize = fontSize or 13,
        TextColor3 = color or Theme.white,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }, parent)
end

local function draggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Main window
local main = make("Frame", {
    Name = "Main",
    Size = UDim2.fromOffset(920, 490),
    Position = UDim2.new(0.5, -460, 0.5, -245),
    BackgroundColor3 = Theme.bg,
    BorderSizePixel = 0,
    Visible = false,
}, gui)
round(main, 12)
outline(main, Theme.line, 0.05)

local header = make("Frame", {
    Size = UDim2.new(1, 0, 0, 54),
    BackgroundColor3 = Theme.panel,
    BorderSizePixel = 0,
}, main)
round(header, 12)
draggable(main, header)
label(header, "◈  PANDEMONIUM RECODE", UDim2.new(1, -100, 0, 25),
    UDim2.fromOffset(18, 6), 19, Theme.white, Enum.Font.GothamBold)
label(header, "UNIVERSAL UI  •  VISUAL PREVIEW", UDim2.new(1, -100, 0, 15),
    UDim2.fromOffset(20, 32), 9, Theme.muted, Enum.Font.GothamSemibold)

local close = make("TextButton", {
    Size = UDim2.fromOffset(32, 30),
    Position = UDim2.new(1, -45, 0, 12),
    BackgroundColor3 = Theme.panel2,
    BorderSizePixel = 0,
    Text = "×",
    TextSize = 22,
    TextColor3 = Theme.white,
    Font = Enum.Font.Gotham,
}, header)
round(close, 7)
close.Activated:Connect(function() main.Visible = false end)

local columns = {
    {name = "COMBAT", icon = "⚔", items = {
        {"Target HUD", "Toggle the local HUD preview", false},
        {"Target Box", "Visual box preview only", false},
        {"Crosshair", "Center-screen crosshair", false},
        {"Hit Indicators", "UI feedback preview", false},
        {"Damage Preview", "Demo-only damage indicator", false},
    }},
    {name = "MOVEMENT", icon = "➤", items = {
        {"Movement Info", "Show local movement status", true},
        {"Speed Display", "Display current WalkSpeed", true},
        {"Jump Display", "Display current JumpPower", false},
        {"Stamina Bar", "UI preview", false},
        {"Coordinate Display", "Display local coordinates", false},
    }},
    {name = "VISUALS", icon = "◎", items = {
        {"World Lighting", "Local lighting presets", true},
        {"Full Bright", "Local brightness preview", false},
        {"Atmosphere", "Enable local atmosphere effect", false},
        {"Crosshair", "Center-screen crosshair", false},
        {"Watermark", "Show PANDEMONIUM watermark", true},
    }},
    {name = "PLAYER", icon = "♙", items = {
        {"Player Panel", "Show your own character status", true},
        {"Health Bar", "Show local health information", true},
        {"Distance Display", "Local HUD demo", false},
        {"Name Display", "Local player name in HUD", true},
        {"Respawn Notice", "UI notification preview", false},
    }},
    {name = "MISC", icon = "⚙", items = {
        {"Notifications", "Show UI notifications", true},
        {"Menu Animations", "Animate menu visibility", true},
        {"Dark Theme", "Use the dark theme", true},
        {"Right Shift Toggle", "Open/close this menu", true},
        {"Reset Lighting", "Restore saved local lighting", false},
    }},
}

local state = {}
for _, col in ipairs(columns) do
    for _, item in ipairs(col.items) do state[item[1]] = item[3] end
end

local contentArea = make("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(14, 67),
    Size = UDim2.new(1, -28, 1, -132),
}, main)
local colWidth = 172
local colGap = 10
local cardRefs = {}

local function notify(text)
    if not state.Notifications then return end
    local note = make("TextLabel", {
        Size = UDim2.fromOffset(280, 34),
        Position = UDim2.new(1, -300, 0, 24),
        BackgroundColor3 = Theme.panel,
        BorderSizePixel = 0,
        Text = text,
        TextColor3 = Theme.white,
        Font = Enum.Font.Gotham,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 20,
    }, gui)
    round(note, 8)
    outline(note, Theme.line)
    make("UIPadding", {PaddingLeft = UDim.new(0, 12)}, note)
    task.delay(2.2, function()
        if note then note:Destroy() end
    end)
end

local savedLighting = {
    ClockTime = Lighting.ClockTime,
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd = Lighting.FogEnd,
}

local function applyWorldPreset(preset)
    if preset == "Day" then
        Lighting.ClockTime = 14
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(135, 135, 145)
        Lighting.OutdoorAmbient = Color3.fromRGB(145, 145, 155)
    elseif preset == "Sunset" then
        Lighting.ClockTime = 18.3
        Lighting.Brightness = 1.5
        Lighting.Ambient = Color3.fromRGB(145, 95, 85)
        Lighting.OutdoorAmbient = Color3.fromRGB(165, 105, 85)
    elseif preset == "Night" then
        Lighting.ClockTime = 0
        Lighting.Brightness = 0.7
        Lighting.Ambient = Color3.fromRGB(45, 45, 75)
        Lighting.OutdoorAmbient = Color3.fromRGB(35, 35, 60)
    elseif preset == "Restore" then
        for property, value in pairs(savedLighting) do
            Lighting[property] = value
        end
    end
    notify("World preset: " .. preset)
end

-- Forward declarations used by callbacks defined before the UI elements.
local worldPanel
local watermark, crosshair, targetHud, playerPanel, playerName, playerHealth, characterBox

local function openWorldPanel()
    if worldPanel then worldPanel:Destroy() end
    worldPanel = make("Frame", {
        Size = UDim2.fromOffset(230, 184),
        Position = UDim2.new(0.5, -115, 1, -64),
        BackgroundColor3 = Theme.panel,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, main)
    round(worldPanel, 9)
    outline(worldPanel, Theme.line)
    label(worldPanel, "WORLD  /  LOCAL LIGHTING", UDim2.new(1, -20, 0, 25),
        UDim2.fromOffset(12, 7), 11, Theme.white, Enum.Font.GothamBold).ZIndex = 6
    local presets = {"Day", "Sunset", "Night", "Restore"}
    for i, preset in ipairs(presets) do
        local b = make("TextButton", {
            Size = UDim2.fromOffset(98, 34),
            Position = UDim2.fromOffset(12 + ((i - 1) % 2) * 108, 39 + math.floor((i - 1) / 2) * 42),
            BackgroundColor3 = Theme.panel2,
            BorderSizePixel = 0,
            Text = preset,
            TextColor3 = Theme.white,
            Font = Enum.Font.GothamSemibold,
            TextSize = 12,
            ZIndex = 6,
        }, worldPanel)
        round(b, 6)
        b.Activated:Connect(function() applyWorldPreset(preset) end)
    end
    label(worldPanel, "Local preview; server may override it.", UDim2.new(1, -20, 0, 18),
        UDim2.fromOffset(12, 132), 9, Theme.muted).ZIndex = 6
end

local function toggleAction(name, enabled)
    if name == "World Lighting" and enabled then
        openWorldPanel()
    elseif name == "World Lighting" and not enabled then
        if worldPanel then worldPanel:Destroy(); worldPanel = nil end
    elseif name == "Full Bright" then
        if enabled then
            Lighting.Brightness = 3
            Lighting.Ambient = Color3.fromRGB(200, 200, 200)
            Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
        else
            applyWorldPreset("Restore")
        end
    elseif name == "Reset Lighting" and enabled then
        applyWorldPreset("Restore")
        state[name] = false
    elseif name == "Watermark" then
        watermark.Visible = enabled
    elseif name == "Crosshair" then
        crosshair.Visible = enabled
    elseif name == "Target HUD" then
        targetHud.Visible = enabled
    elseif name == "Target Box" then
        characterBox.Visible = enabled
    elseif name == "Player Panel" or name == "Health Bar" or name == "Name Display" then
        playerPanel.Visible = state["Player Panel"] or state["Health Bar"] or state["Name Display"]
        playerName.Visible = state["Name Display"]
        playerHealth.Visible = state["Health Bar"]
    end
end

for i, col in ipairs(columns) do
    local card = make("Frame", {
        Size = UDim2.fromOffset(colWidth, 340),
        Position = UDim2.fromOffset((i - 1) * (colWidth + colGap), 0),
        BackgroundColor3 = Theme.panel,
        BorderSizePixel = 0,
    }, contentArea)
    round(card, 9)
    outline(card, Theme.line, 0.2)
    cardRefs[col.name] = card

    label(card, col.icon .. "  " .. col.name, UDim2.new(1, -16, 0, 32),
        UDim2.fromOffset(10, 5), 12, Theme.white, Enum.Font.GothamBold)
    local divider = make("Frame", {
        Size = UDim2.new(1, -20, 0, 1),
        Position = UDim2.fromOffset(10, 39),
        BackgroundColor3 = Theme.line,
        BorderSizePixel = 0,
    }, card)

    local list = make("ScrollingFrame", {
        Position = UDim2.fromOffset(7, 45),
        Size = UDim2.new(1, -14, 1, -52),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Theme.muted,
        CanvasSize = UDim2.new(0, 0, 0, #col.items * 48),
    }, card)
    local layout = make("UIListLayout", {
        Padding = UDim.new(0, 3),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, list)

    for index, item in ipairs(col.items) do
        local name, description = item[1], item[2]
        local row = make("Frame", {
            Size = UDim2.new(1, -2, 0, 44),
            BackgroundColor3 = Theme.panel,
            BorderSizePixel = 0,
            LayoutOrder = index,
        }, list)
        label(row, name, UDim2.new(1, -43, 0, 20), UDim2.fromOffset(4, 2),
            11, Theme.white, Enum.Font.GothamSemibold)
        label(row, description, UDim2.new(1, -10, 0, 14), UDim2.fromOffset(4, 23),
            8, Theme.muted)

        local toggle = make("TextButton", {
            Size = UDim2.fromOffset(29, 17),
            Position = UDim2.new(1, -33, 0, 5),
            BackgroundColor3 = state[name] and Theme.accent or Theme.off,
            BorderSizePixel = 0,
            Text = "",
            AutoButtonColor = false,
        }, row)
        round(toggle, 9)
        local knob = make("Frame", {
            Size = UDim2.fromOffset(11, 11),
            Position = state[name] and UDim2.fromOffset(15, 3) or UDim2.fromOffset(3, 3),
            BackgroundColor3 = state[name] and Theme.bg or Theme.muted,
            BorderSizePixel = 0,
        }, toggle)
        round(knob, 6)

        local function paintToggle()
            toggle.BackgroundColor3 = state[name] and Theme.accent or Theme.off
            knob.BackgroundColor3 = state[name] and Theme.bg or Theme.muted
            local target = state[name] and UDim2.fromOffset(15, 3) or UDim2.fromOffset(3, 3)
            TweenService:Create(knob, TweenInfo.new(0.12), {Position = target}):Play()
        end
        toggle.Activated:Connect(function()
            state[name] = not state[name]
            paintToggle()
            toggleAction(name, state[name])
            if name == "Reset Lighting" then paintToggle() end
            notify(name .. (state[name] and " enabled" or " disabled"))
        end)
    end
end

-- Footer search filters the visible rows by name.
local search = make("TextBox", {
    Size = UDim2.fromOffset(260, 31),
    Position = UDim2.new(0.5, -130, 1, -44),
    BackgroundColor3 = Theme.panel,
    BorderSizePixel = 0,
    PlaceholderText = "⌕  Search modules...",
    PlaceholderColor3 = Theme.muted,
    Text = "",
    TextColor3 = Theme.white,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    ClearTextOnFocus = false,
}, main)
round(search, 8)
outline(search, Theme.line, 0.2)
make("UIPadding", {PaddingLeft = UDim.new(0, 10)}, search)

search:GetPropertyChangedSignal("Text"):Connect(function()
    local query = string.lower(search.Text)
    for _, card in pairs(cardRefs) do
        for _, child in ipairs(card:GetDescendants()) do
            if child:IsA("TextLabel") and child.Parent and child.Parent:IsA("Frame") then
                local row = child.Parent
                if row.Parent and row.Parent:IsA("ScrollingFrame") then
                    local rowName = row:FindFirstChildWhichIsA("TextLabel")
                    row.Visible = (query == "") or (rowName and string.find(string.lower(rowName.Text), query, 1, true) ~= nil)
                end
            end
        end
    end
end)

-- Local-only status card; it never selects or tracks other players.
playerPanel = make("Frame", {
    Size = UDim2.fromOffset(220, 65),
    Position = UDim2.new(1, -236, 0, 70),
    BackgroundColor3 = Theme.bg,
    BackgroundTransparency = 0.06,
    BorderSizePixel = 0,
}, gui)
round(playerPanel, 9)
outline(playerPanel, Theme.line, 0.1)
playerName = label(playerPanel, "PLAYER: " .. player.Name, UDim2.new(1, -18, 0, 22),
    UDim2.fromOffset(10, 5), 12, Theme.white, Enum.Font.GothamBold)
playerHealth = label(playerPanel, "Health: --", UDim2.new(1, -18, 0, 18),
    UDim2.fromOffset(10, 31), 10, Theme.muted)
playerPanel.Visible = true

local function updateLocalStatus()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        playerHealth.Text = string.format("Health: %d / %d", math.max(0, math.floor(humanoid.Health)),
            math.floor(humanoid.MaxHealth))
    else
        playerHealth.Text = "Health: --"
    end
end
task.spawn(function()
    while gui.Parent do
        updateLocalStatus()
        task.wait(0.4)
    end
end)

targetHud = make("Frame", {
    Name = "TargetHUDPreview",
    Size = UDim2.fromOffset(300, 92),
    Position = UDim2.new(0.5, -150, 0.62, 0),
    BackgroundColor3 = Color3.fromRGB(18, 17, 27),
    BackgroundTransparency = 0.04,
    BorderSizePixel = 0,
    Visible = false,
    Active = true,
}, gui)
round(targetHud, 9)
outline(targetHud, Theme.line, 0.05)

-- Drag by the header or anywhere on the card.
draggable(targetHud, targetHud)

local targetPortrait = make("Frame", {
    Size = UDim2.fromOffset(58, 64),
    Position = UDim2.fromOffset(10, 14),
    BackgroundColor3 = Color3.fromRGB(42, 20, 65),
    BorderSizePixel = 0,
}, targetHud)
round(targetPortrait, 6)
outline(targetPortrait, Theme.accent, 0.1)
-- Corner-bracket target box motif.
local function bracket(pos, size)
    make("Frame", {
        Position = pos, Size = size,
        BackgroundColor3 = Theme.white, BorderSizePixel = 0,
    }, targetPortrait)
end
bracket(UDim2.fromOffset(0, 0), UDim2.fromOffset(15, 3))
bracket(UDim2.fromOffset(0, 0), UDim2.fromOffset(3, 15))
bracket(UDim2.new(1, -15, 0, 0), UDim2.fromOffset(15, 3))
bracket(UDim2.new(1, -3, 0, 0), UDim2.fromOffset(3, 15))
bracket(UDim2.new(0, 0, 1, -3), UDim2.fromOffset(15, 3))
bracket(UDim2.new(0, 0, 1, -15), UDim2.fromOffset(3, 15))
bracket(UDim2.new(1, -15, 1, -3), UDim2.fromOffset(15, 3))
bracket(UDim2.new(1, -3, 1, -15), UDim2.fromOffset(3, 15))

local targetName = label(targetHud, "PLAYER: " .. player.Name,
    UDim2.new(1, -90, 0, 24), UDim2.fromOffset(80, 12), 15, Theme.white, Enum.Font.GothamBold)
local targetHealthText = label(targetHud, "HP: -- / --",
    UDim2.new(1, -90, 0, 18), UDim2.fromOffset(80, 39), 11, Theme.muted)
local targetHealthBack = make("Frame", {
    Position = UDim2.fromOffset(80, 64),
    Size = UDim2.new(1, -94, 0, 10),
    BackgroundColor3 = Theme.panel2,
    BorderSizePixel = 0,
}, targetHud)
round(targetHealthBack, 5)
local targetHealthFill = make("Frame", {
    Size = UDim2.new(1, 0, 1, 0),
    BackgroundColor3 = Theme.accent,
    BorderSizePixel = 0,
}, targetHealthBack)
round(targetHealthFill, 5)

local function updateTargetHud()
    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        local hp = math.max(0, humanoid.Health)
        local maxHp = math.max(1, humanoid.MaxHealth)
        targetName.Text = "PLAYER: " .. player.Name
        targetHealthText.Text = string.format("HP: %d / %d", math.floor(hp), math.floor(maxHp))
        targetHealthFill.Size = UDim2.new(math.clamp(hp / maxHp, 0, 1), 0, 1, 0)
    else
        targetName.Text = "PLAYER: " .. player.Name
        targetHealthText.Text = "HP: waiting for character..."
        targetHealthFill.Size = UDim2.new(0, 0, 1, 0)
    end
end
task.spawn(function()
    while gui.Parent do
        updateTargetHud()
        task.wait(0.25)
    end
end)

crosshair = label(gui, "+", UDim2.fromOffset(22, 24),
    UDim2.new(0.5, -11, 0.5, -12), 22, Theme.white, Enum.Font.GothamBold)
crosshair.Visible = false

-- Local character box preview (does not draw boxes around other players).
characterBox = make("SelectionBox", {
    Name = "LocalCharacterBox",
    LineThickness = 0.045,
    Color3 = Theme.accent,
    SurfaceTransparency = 1,
    Visible = false,
}, gui)

local function bindLocalCharacter(character)
    characterBox.Adornee = character
end
if player.Character then bindLocalCharacter(player.Character) end
player.CharacterAdded:Connect(bindLocalCharacter)

-- Top watermark inspired by the reference: compact dark status strip.
watermark = make("Frame", {
    Name = "PandemoniumWatermark",
    Size = UDim2.fromOffset(330, 30),
    Position = UDim2.new(0, 18, 0, 18),
    BackgroundColor3 = Color3.fromRGB(15, 16, 20),
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
}, gui)
round(watermark, 7)
outline(watermark, Theme.line, 0.45)

local watermarkTitle = label(watermark, "♜  pandemonium", UDim2.fromOffset(112, 30),
    UDim2.fromOffset(9, 0), 11, Theme.white, Enum.Font.GothamBold)
watermarkTitle.TextXAlignment = Enum.TextXAlignment.Left

make("Frame", {
    Size = UDim2.fromOffset(1, 15),
    Position = UDim2.fromOffset(125, 7),
    BackgroundColor3 = Theme.line,
    BorderSizePixel = 0,
}, watermark)

local adminTag = label(watermark, "◆ Recode", UDim2.fromOffset(61, 30),
    UDim2.fromOffset(134, 0), 10, Color3.fromRGB(220, 220, 228), Enum.Font.GothamSemibold)

make("Frame", {
    Size = UDim2.fromOffset(1, 15),
    Position = UDim2.fromOffset(199, 7),
    BackgroundColor3 = Theme.line,
    BorderSizePixel = 0,
}, watermark)

local fpsLabel = label(watermark, "▣ UI", UDim2.fromOffset(42, 30),
    UDim2.fromOffset(207, 0), 10, Theme.white, Enum.Font.GothamSemibold)

make("Frame", {
    Size = UDim2.fromOffset(1, 15),
    Position = UDim2.fromOffset(252, 7),
    BackgroundColor3 = Theme.line,
    BorderSizePixel = 0,
}, watermark)

local pingLabel = label(watermark, "◈ Ready", UDim2.fromOffset(67, 30),
    UDim2.fromOffset(260, 0), 10, Theme.white, Enum.Font.GothamSemibold)

-- Keybind and initial state
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift and state["Right Shift Toggle"] then
        main.Visible = not main.Visible
    end
end)

-- Initial module setup
playerPanel.Visible = state["Player Panel"] or state["Health Bar"] or state["Name Display"]
playerName.Visible = state["Name Display"]
playerHealth.Visible = state["Health Bar"]
if state["World Lighting"] then openWorldPanel() end

print("PANDEMONIUM RECODE loaded. Press RightShift to toggle the UI.")
