-- lap1nka.lua
-- Roblox Studio LocalScript: animated menu, RightShift toggle, light dim,
-- tabs, reusable toggles/sliders/keybinds, FPS and ping display, crosshair.
-- Place this LocalScript in StarterPlayer > StarterPlayerScripts.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Avoid duplicate GUIs if the LocalScript is rerun.
local oldGui = playerGui:FindFirstChild("lap1nka")
if oldGui then
    oldGui:Destroy()
end

local CONFIG = {
    ToggleKey = Enum.KeyCode.RightShift,
    DimTransparency = 0.93, -- Higher = less dark.
    AnimationTime = 0.22,
    ShowCrosshair = true,
    ShowStatus = true,
}

local COLORS = {
    Background = Color3.fromRGB(22, 25, 32),
    Panel = Color3.fromRGB(30, 34, 43),
    PanelAlt = Color3.fromRGB(38, 43, 54),
    Accent = Color3.fromRGB(155, 120, 255),
    Text = Color3.fromRGB(240, 242, 250),
    Muted = Color3.fromRGB(165, 171, 188),
    Green = Color3.fromRGB(78, 190, 130),
    Red = Color3.fromRGB(190, 85, 95),
}

local settings = {
    Crosshair = true,
    Status = true,
    MenuDim = true,
    AccentGlow = false,
    UIAnimations = true,
    UITransparency = 0,
    WalkSpeedDisplay = true,
}

local function create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function corner(parent, radius)
    return create("UICorner", { CornerRadius = UDim.new(0, radius or 8) }, parent)
end

local function stroke(parent, color, transparency)
    return create("UIStroke", {
        Color = color or COLORS.Accent,
        Transparency = transparency or 0.65,
        Thickness = 1,
    }, parent)
end

local gui = create("ScreenGui", {
    Name = "lap1nka",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local dim = create("Frame", {
    Name = "BackgroundDim",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 1,
}, gui)

local main = create("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.53),
    Size = UDim2.fromOffset(600, 420),
    BackgroundColor3 = COLORS.Background,
    BackgroundTransparency = 0,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 2,
}, gui)
corner(main, 14)
stroke(main, COLORS.Accent, 0.48)

local sizeConstraint = create("UISizeConstraint", {
    MinSize = Vector2.new(320, 280),
    MaxSize = Vector2.new(700, 520),
}, main)

local scale = create("UIScale", { Scale = 1 }, main)

local header = create("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 54),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
    ZIndex = 3,
}, main)
corner(header, 14)

-- Cover the lower rounded corners of the header for a tidy top-only header.
create("Frame", {
    Size = UDim2.new(1, 0, 0, 14),
    Position = UDim2.new(0, 0, 1, -14),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
    ZIndex = 3,
}, header)

create("TextLabel", {
    Name = "Brand",
    Position = UDim2.fromOffset(18, 0),
    Size = UDim2.new(1, -100, 1, 0),
    BackgroundTransparency = 1,
    Text = "lap1nka",
    TextColor3 = COLORS.Text,
    TextSize = 21,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
}, header)

create("TextLabel", {
    Name = "Subtitle",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -56, 0.5, 0),
    Size = UDim2.fromOffset(145, 24),
    BackgroundTransparency = 1,
    Text = "CLIENT  •  RIGHT SHIFT",
    TextColor3 = COLORS.Muted,
    TextSize = 9,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Right,
    ZIndex = 4,
}, header)

local closeButton = create("TextButton", {
    Name = "Close",
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -12, 0.5, 0),
    Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = COLORS.Red,
    Text = "×",
    TextColor3 = Color3.new(1, 1, 1),
    TextSize = 22,
    Font = Enum.Font.GothamMedium,
    AutoButtonColor = true,
    ZIndex = 4,
}, header)
corner(closeButton, 8)

local sidebar = create("Frame", {
    Name = "Sidebar",
    Position = UDim2.fromOffset(12, 66),
    Size = UDim2.new(0, 145, 1, -78),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
    ZIndex = 3,
}, main)
corner(sidebar, 10)

local tabList = create("Frame", {
    BackgroundTransparency = 1,
    Position = UDim2.fromOffset(8, 8),
    Size = UDim2.new(1, -16, 1, -16),
    ZIndex = 4,
}, sidebar)
create("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, tabList)

local content = create("Frame", {
    Name = "Content",
    Position = UDim2.new(0, 169, 0, 66),
    Size = UDim2.new(1, -181, 1, -78),
    BackgroundColor3 = COLORS.Panel,
    BorderSizePixel = 0,
    ZIndex = 3,
}, main)
corner(content, 10)

local pageTitle = create("TextLabel", {
    Position = UDim2.fromOffset(16, 10),
    Size = UDim2.new(1, -32, 0, 28),
    BackgroundTransparency = 1,
    Text = "General",
    TextColor3 = COLORS.Text,
    TextSize = 17,
    Font = Enum.Font.GothamBold,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
}, content)

local pageDescription = create("TextLabel", {
    Position = UDim2.fromOffset(16, 36),
    Size = UDim2.new(1, -32, 0, 20),
    BackgroundTransparency = 1,
    Text = "Personalize your local interface.",
    TextColor3 = COLORS.Muted,
    TextSize = 10,
    Font = Enum.Font.Gotham,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 4,
}, content)

local pages = {}
local selectedTab = nil
local tabButtons = {}

local function makePage(name, description)
    local page = create("ScrollingFrame", {
        Name = name,
        Position = UDim2.fromOffset(12, 64),
        Size = UDim2.new(1, -24, 1, -76),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = COLORS.Accent,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        ZIndex = 4,
    }, content)
    create("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
    }, page)
    create("UIPadding", {
        PaddingBottom = UDim.new(0, 8),
        PaddingRight = UDim.new(0, 4),
    }, page)
    pages[name] = { Frame = page, Description = description }
    return page
end

local function selectTab(name)
    selectedTab = name
    for tabName, button in pairs(tabButtons) do
        local active = tabName == name
        button.BackgroundColor3 = active and COLORS.Accent or COLORS.PanelAlt
        button.TextColor3 = active and Color3.new(1, 1, 1) or COLORS.Muted
    end
    for pageName, data in pairs(pages) do
        data.Frame.Visible = pageName == name
    end
    pageTitle.Text = name
    pageDescription.Text = pages[name].Description
end

local function makeTab(name, order, description)
    local button = create("TextButton", {
        Name = name .. "Tab",
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = COLORS.PanelAlt,
        Text = "   " .. name,
        TextColor3 = COLORS.Muted,
        TextSize = 12,
        Font = Enum.Font.GothamSemibold,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = true,
        LayoutOrder = order,
        ZIndex = 4,
    }, tabList)
    corner(button, 8)
    tabButtons[name] = button
    makePage(name, description)
    button.Activated:Connect(function()
        selectTab(name)
    end)
end

makeTab("General", 1, "Personalize your local interface.")
makeTab("Visuals", 2, "Optional local-only visual helpers.")
makeTab("Info", 3, "Controls and runtime information.")

local function addSection(parent, text)
    local label = create("TextLabel", {
        Size = UDim2.new(1, -2, 0, 22),
        BackgroundTransparency = 1,
        Text = text:upper(),
        TextColor3 = COLORS.Accent,
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 5,
    }, parent)
    return label
end

local function addToggle(parent, text, defaultValue, callback)
    local row = create("Frame", {
        Size = UDim2.new(1, -2, 0, 42),
        BackgroundColor3 = COLORS.PanelAlt,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, parent)
    corner(row, 8)

    create("TextLabel", {
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -82, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    }, row)

    local enabled = defaultValue
    local button = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -9, 0.5, 0),
        Size = UDim2.fromOffset(52, 25),
        BackgroundColor3 = enabled and COLORS.Green or COLORS.Red,
        Text = enabled and "ON" or "OFF",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        ZIndex = 6,
    }, row)
    corner(button, 7)

    button.Activated:Connect(function()
        enabled = not enabled
        button.Text = enabled and "ON" or "OFF"
        button.BackgroundColor3 = enabled and COLORS.Green or COLORS.Red
        if callback then
            local ok, err = pcall(callback, enabled)
            if not ok then warn("[lap1nka] toggle callback:", err) end
        end
    end)
    return function() return enabled end
end

local function addButton(parent, text, buttonText, callback)
    local row = create("Frame", {
        Size = UDim2.new(1, -2, 0, 42),
        BackgroundColor3 = COLORS.PanelAlt,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, parent)
    corner(row, 8)

    create("TextLabel", {
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -112, 1, 0),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    }, row)

    local button = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -9, 0.5, 0),
        Size = UDim2.fromOffset(86, 27),
        BackgroundColor3 = COLORS.Accent,
        Text = buttonText,
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 10,
        Font = Enum.Font.GothamBold,
        ZIndex = 6,
    }, row)
    corner(button, 7)
    button.Activated:Connect(function()
        if callback then callback(button) end
    end)
    return button
end

local function addSlider(parent, text, minValue, maxValue, initialValue, callback)
    local row = create("Frame", {
        Size = UDim2.new(1, -2, 0, 60),
        BackgroundColor3 = COLORS.PanelAlt,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, parent)
    corner(row, 8)

    local value = initialValue
    local label = create("TextLabel", {
        Position = UDim2.fromOffset(12, 5),
        Size = UDim2.new(1, -24, 0, 20),
        BackgroundTransparency = 1,
        Text = text .. ": " .. tostring(value),
        TextColor3 = COLORS.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 6,
    }, row)

    local track = create("TextButton", {
        Position = UDim2.new(0, 12, 0, 34),
        Size = UDim2.new(1, -24, 0, 12),
        BackgroundColor3 = COLORS.Background,
        Text = "",
        AutoButtonColor = false,
        ZIndex = 6,
    }, row)
    corner(track, 6)

    local fill = create("Frame", {
        Size = UDim2.new((value - minValue) / (maxValue - minValue), 0, 1, 0),
        BackgroundColor3 = COLORS.Accent,
        BorderSizePixel = 0,
        ZIndex = 7,
    }, track)
    corner(fill, 6)

    local dragging = false
    local function setFromX(x)
        local width = math.max(track.AbsoluteSize.X, 1)
        local alpha = math.clamp((x - track.AbsolutePosition.X) / width, 0, 1)
        value = math.floor((minValue + (maxValue - minValue) * alpha) * 10 + 0.5) / 10
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        label.Text = text .. ": " .. tostring(value)
        if callback then callback(value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

local general = pages.General.Frame
addSection(general, "Interface")
addToggle(general, "Enable subtle background dim", true, function(value)
    settings.MenuDim = value
end)
addToggle(general, "Enable UI animations", true, function(value)
    settings.UIAnimations = value
end)
addButton(general, "Menu toggle key", "RightShift", function(button)
    button.Text = "Press key"
    local connection
    connection = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
        if input.KeyCode == Enum.KeyCode.Unknown then return end
        CONFIG.ToggleKey = input.KeyCode
        button.Text = input.KeyCode.Name
        connection:Disconnect()
    end)
    task.delay(5, function()
        if connection and connection.Connected then
            connection:Disconnect()
            button.Text = CONFIG.ToggleKey.Name
        end
    end)
end)
addSlider(general, "Menu transparency", 0, 0.25, 0, function(value)
    settings.UITransparency = value
    main.BackgroundTransparency = value
end)

local visuals = pages.Visuals.Frame
addSection(visuals, "Local visuals")
addToggle(visuals, "Center crosshair", true, function(value)
    settings.Crosshair = value
end)
addToggle(visuals, "FPS / ping status", true, function(value)
    settings.Status = value
end)
addToggle(visuals, "Accent glow", false, function(value)
    settings.AccentGlow = value
end)

local info = pages.Info.Frame
addSection(info, "Controls")
addButton(info, "Show / hide menu", "RightShift", function()
    toggleMenu()
end)
addButton(info, "Reset menu position", "Reset", function()
    main.Position = UDim2.fromScale(0.5, 0.53)
end)
addSection(info, "About")
local about = create("TextLabel", {
    Size = UDim2.new(1, -2, 0, 72),
    BackgroundColor3 = COLORS.PanelAlt,
    Text = "lap1nka is a local interface template for your own Roblox experience.\nIt does not modify other players or provide combat cheats.",
    TextColor3 = COLORS.Muted,
    TextSize = 11,
    Font = Enum.Font.Gotham,
    TextWrapped = true,
    ZIndex = 5,
}, info)
corner(about, 8)

-- Center crosshair, drawn as two simple GUI frames.
local crosshair = create("Frame", {
    Name = "Crosshair",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(20, 20),
    BackgroundTransparency = 1,
    Visible = settings.Crosshair,
    ZIndex = 10,
}, gui)
create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(18, 2),
    BackgroundColor3 = COLORS.Accent,
    BorderSizePixel = 0,
    ZIndex = 10,
}, crosshair)
create("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(2, 18),
    BackgroundColor3 = COLORS.Accent,
    BorderSizePixel = 0,
    ZIndex = 10,
}, crosshair)

local status = create("TextLabel", {
    Name = "Status",
    AnchorPoint = Vector2.new(0, 1),
    Position = UDim2.new(0, 12, 1, -12),
    Size = UDim2.fromOffset(240, 24),
    BackgroundColor3 = COLORS.Background,
    BackgroundTransparency = 0.2,
    Text = "lap1nka  |  FPS: --  |  Ping: --",
    TextColor3 = COLORS.Text,
    TextSize = 10,
    Font = Enum.Font.GothamMedium,
    TextXAlignment = Enum.TextXAlignment.Left,
    Visible = settings.Status,
    ZIndex = 10,
}, gui)
corner(status, 7)
create("UIPadding", {
    PaddingLeft = UDim.new(0, 9),
}, status)

selectTab("General")

local menuOpen = false
local animating = false
local activeTweens = {}

local function cancelTweens()
    for _, tween in ipairs(activeTweens) do
        pcall(function() tween:Cancel() end)
    end
    table.clear(activeTweens)
end

local function playTween(instance, infoTween, properties)
    local tween = TweenService:Create(instance, infoTween, properties)
    table.insert(activeTweens, tween)
    tween:Play()
    return tween
end

local function setMenu(open)
    if animating or menuOpen == open then return end
    menuOpen = open
    animating = true
    cancelTweens()

    local duration = settings.UIAnimations and CONFIG.AnimationTime or 0
    if open then
        main.Visible = true
        main.Position = UDim2.fromScale(0.5, 0.53)
        scale.Scale = 0.96
        dim.Visible = settings.MenuDim
        dim.BackgroundTransparency = 1

        local infoTween = TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
        local menuTween = playTween(main, infoTween, {
            Position = UDim2.fromScale(0.5, 0.5),
        })
        playTween(scale, infoTween, { Scale = 1 })
        if settings.MenuDim then
            playTween(dim, infoTween, { BackgroundTransparency = CONFIG.DimTransparency })
        end
        menuTween.Completed:Once(function()
            animating = false
        end)
    else
        local infoTween = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        local menuTween = playTween(main, infoTween, {
            Position = UDim2.fromScale(0.5, 0.53),
        })
        playTween(scale, infoTween, { Scale = 0.96 })
        if dim.Visible then
            playTween(dim, infoTween, { BackgroundTransparency = 1 })
        end
        menuTween.Completed:Once(function()
            main.Visible = false
            dim.Visible = false
            animating = false
        end)
    end
end

toggleMenu = function()
    setMenu(not menuOpen)
end

closeButton.Activated:Connect(function()
    setMenu(false)
end)

dim.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        setMenu(false)
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == CONFIG.ToggleKey then
        setMenu(not menuOpen)
    end
end)

local frameCount = 0
local elapsed = 0
local lastFps = 0
RunService.RenderStepped:Connect(function(dt)
    frameCount += 1
    elapsed += dt
    crosshair.Visible = settings.Crosshair
    status.Visible = settings.Status

    if settings.AccentGlow then
        local pulse = (math.sin(os.clock() * 2) + 1) / 2
        local uiStroke = main:FindFirstChildOfClass("UIStroke")
        if uiStroke then uiStroke.Transparency = 0.35 + pulse * 0.4 end
    else
        local uiStroke = main:FindFirstChildOfClass("UIStroke")
        if uiStroke then uiStroke.Transparency = 0.48 end
    end

    if elapsed >= 1 then
        lastFps = frameCount
        frameCount = 0
        elapsed = 0
        local ping = "--"
        local ok, value = pcall(function()
            local network = Stats:FindFirstChild("Network")
            local serverStats = network and network:FindFirstChild("ServerStatsItem")
            local item = serverStats and serverStats:FindFirstChild("Data Ping")
            return item and math.floor(item:GetValue()) or nil
        end)
        if ok and value then ping = tostring(value) .. " ms" end
        status.Text = string.format("lap1nka  |  FPS: %d  |  Ping: %s", lastFps, ping)
    end
end)

-- Keep the window usable on smaller screens.
local function updateResponsiveSize()
    local camera = workspace.CurrentCamera
    if not camera then return end
    local viewport = camera.ViewportSize
    local width = math.clamp(viewport.X - 24, 320, 600)
    local height = math.clamp(viewport.Y - 40, 280, 420)
    main.Size = UDim2.fromOffset(width, height)
end
updateResponsiveSize()
if workspace.CurrentCamera then
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsiveSize)
end

print("[lap1nka] Loaded. Press RightShift to open/close the menu.")
