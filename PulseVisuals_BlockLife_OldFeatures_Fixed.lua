-- Pulse Visuals | Xeno visual-only edition
-- Run as a client-side script. Visual HUD/crosshair/cosmetics only.
-- No through-wall ESP, combat automation, or anti-cheat bypass.
-- Optional part highlights apply only to parts explicitly tagged PulseHighlight
-- or carrying the PulseHighlight = true attribute in the experience.
-- Settings persist locally when the executor exposes readfile/writefile; otherwise session-only.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Prefer the executor's private UI container when available; otherwise use PlayerGui.
local guiParent = playerGui
pcall(function()
    if typeof(gethui) == "function" then
        guiParent = gethui()
    end
end)

local oldGui = guiParent:FindFirstChild("PulseVisuals")
if oldGui then oldGui:Destroy() end

local THEME = {
    bg = Color3.fromRGB(15, 13, 22),
    panel = Color3.fromRGB(24, 20, 34),
    panel2 = Color3.fromRGB(33, 27, 46),
    purple = Color3.fromRGB(157, 91, 255),
    purpleDark = Color3.fromRGB(76, 45, 115),
    text = Color3.fromRGB(242, 237, 250),
    muted = Color3.fromRGB(155, 146, 171),
    green = Color3.fromRGB(107, 230, 168),
    red = Color3.fromRGB(255, 111, 133),
}

local state = {
    menuOpen = true,
    fps = true,
    coordinates = true,
    ping = true,
    animatedCrosshair = true,
    targetHud = false,
    targetEsp = false,
    crosshair = false,
    playerTrail = false,
    taggedHighlights = false,
    particles = false,
    magentaAtmosphere = false,
    bloomGlow = false,
    groundAura = false,
    compactMode = false,
    accent = THEME.purple,
    highlightTransparency = 0.35,
    particleRate = 12,
}


local running = true

-- Core helpers and base window restored for the original feature set.
local connections = {}
local activeHighlights = {}
local frameCount, currentFps, lastFrame = 0, 0, os.clock()

local function connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(connections, connection)
    return connection
end

local function make(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local function addCorner(object, radius)
    return make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, object)
end

local function addStroke(object, color, transparency, thickness)
    return make("UIStroke", {
        Color = color or THEME.purple,
        Transparency = transparency or 0.25,
        Thickness = thickness or 1,
    }, object)
end

local function animate(object, properties, duration)
    local ok, animation = pcall(function()
        return TweenService:Create(
            object,
            TweenInfo.new(duration or 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
            properties
        )
    end)
    if ok and animation then animation:Play() end
    return animation
end

local gui = make("ScreenGui", {
    Name = "PulseVisuals",
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, guiParent)

local main = make("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(680, 455),
    BackgroundColor3 = THEME.bg,
    BorderSizePixel = 0,
    ClipsDescendants = false,
}, gui)
addCorner(main, 12)
addStroke(main, THEME.purple, 0.18, 1.2)

local mainScale = make("UIScale", {Scale = 1}, main)
local header = make("Frame", {
    Name = "Header",
    Size = UDim2.new(1, 0, 0, 58),
    BackgroundColor3 = THEME.panel,
    BorderSizePixel = 0,
}, main)
addCorner(header, 12)
make("Frame", {
    Position = UDim2.new(0, 0, 1, -12),
    Size = UDim2.new(1, 0, 0, 12),
    BackgroundColor3 = THEME.panel,
    BorderSizePixel = 0,
}, header)

make("TextLabel", {
    Position = UDim2.fromOffset(18, 7),
    Size = UDim2.new(1, -90, 0, 27),
    BackgroundTransparency = 1,
    Text = "PULSE VISUALS",
    TextColor3 = THEME.text,
    Font = Enum.Font.GothamBold,
    TextSize = 18,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)
make("TextLabel", {
    Position = UDim2.fromOffset(19, 33),
    Size = UDim2.new(1, -90, 0, 15),
    BackgroundTransparency = 1,
    Text = "BLOCKLIFE PROFILE  •  VISUAL CLIENT",
    TextColor3 = THEME.muted,
    Font = Enum.Font.Gotham,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local closeButton = make("TextButton", {
    Name = "Close",
    Position = UDim2.new(1, -44, 0, 13),
    Size = UDim2.fromOffset(30, 30),
    BackgroundColor3 = THEME.panel2,
    BorderSizePixel = 0,
    Text = "×",
    TextColor3 = THEME.text,
    Font = Enum.Font.Gotham,
    TextSize = 22,
    AutoButtonColor = false,
}, header)
addCorner(closeButton, 7)

local sidebar = make("Frame", {
    Name = "Sidebar",
    Position = UDim2.fromOffset(12, 70),
    Size = UDim2.new(0, 138, 1, -82),
    BackgroundColor3 = THEME.panel,
    BorderSizePixel = 0,
}, main)
addCorner(sidebar, 9)
make("UIPadding", {
    PaddingTop = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8),
}, sidebar)
make("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, sidebar)

local pageTitle = make("TextLabel", {
    Position = UDim2.fromOffset(164, 70),
    Size = UDim2.new(1, -176, 0, 28),
    BackgroundTransparency = 1,
    Text = "Visuals",
    TextColor3 = THEME.purple,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
}, main)

local searchBox = make("TextBox", {
    Name = "Search",
    Position = UDim2.fromOffset(164, 101),
    Size = UDim2.new(1, -176, 0, 30),
    BackgroundColor3 = THEME.panel,
    BorderSizePixel = 0,
    PlaceholderText = "Search modules...",
    PlaceholderColor3 = THEME.muted,
    Text = "",
    TextColor3 = THEME.text,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    ClearTextOnFocus = false,
}, main)
addCorner(searchBox, 7)
make("UIPadding", {
    PaddingLeft = UDim.new(0, 10),
    PaddingRight = UDim.new(0, 8),
}, searchBox)

local list = make("ScrollingFrame", {
    Name = "ModuleList",
    Position = UDim2.fromOffset(164, 139),
    Size = UDim2.new(1, -176, 1, -151),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = THEME.purple,
    CanvasSize = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, main)
make("UIListLayout", {
    Padding = UDim.new(0, 7),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, list)

local toastHolder = make("Frame", {
    Name = "ToastHolder",
    AnchorPoint = Vector2.new(1, 0),
    Position = UDim2.new(1, -18, 0, 18),
    Size = UDim2.fromOffset(270, 220),
    BackgroundTransparency = 1,
}, gui)
make("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
    VerticalAlignment = Enum.VerticalAlignment.Top,
}, toastHolder)

-- Optional local persistence. Uses executor file APIs only when available; otherwise session-only.
local CONFIG_PATH = "PulseVisuals_config.json"
local function saveConfig()
    if type(writefile) ~= "function" then return end
    local payload = {
        fps = state.fps, coordinates = state.coordinates, ping = state.ping,
        targetHud = state.targetHud, targetEsp = state.targetEsp, crosshair = state.crosshair,
        animatedCrosshair = state.animatedCrosshair, playerTrail = state.playerTrail,
        taggedHighlights = state.taggedHighlights, particles = state.particles,
        magentaAtmosphere = state.magentaAtmosphere, bloomGlow = state.bloomGlow,
        groundAura = state.groundAura, compactMode = state.compactMode,
        accentName = state.accentName or "Purple",
        highlightTransparency = state.highlightTransparency, particleRate = state.particleRate,
    }
    pcall(function() writefile(CONFIG_PATH, HttpService:JSONEncode(payload)) end)
end
local function loadConfig()
    if type(readfile) ~= "function" or type(isfile) ~= "function" then return end
    local ok, payload = pcall(function()
        if not isfile(CONFIG_PATH) then return nil end
        return HttpService:JSONDecode(readfile(CONFIG_PATH))
    end)
    if not ok or type(payload) ~= "table" then return end
    for _, key in ipairs({"fps", "coordinates", "ping", "targetHud", "targetEsp", "crosshair", "animatedCrosshair", "playerTrail", "taggedHighlights", "particles", "magentaAtmosphere", "bloomGlow", "groundAura", "compactMode"}) do
        if type(payload[key]) == "boolean" then state[key] = payload[key] end
    end
    if type(payload.highlightTransparency) == "number" then state.highlightTransparency = math.clamp(payload.highlightTransparency, 0, 0.9) end
    if type(payload.particleRate) == "number" then state.particleRate = math.clamp(math.floor(payload.particleRate), 1, 40) end
    state.accentName = type(payload.accentName) == "string" and payload.accentName or "Purple"
end
loadConfig()
local savedThemes = {
    Purple = Color3.fromRGB(157, 91, 255),
    Crimson = Color3.fromRGB(255, 75, 105),
    ["Ice Blue"] = Color3.fromRGB(80, 190, 255),
    Matrix = Color3.fromRGB(85, 235, 135),
}
if savedThemes[state.accentName] then
    state.accent = savedThemes[state.accentName]
    THEME.purple = state.accent
end

local function notify(title, message)
    if not running then return end
    local toast = make("Frame", {
        Size = UDim2.fromOffset(260, 58),
        BackgroundColor3 = THEME.panel,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
    }, toastHolder)
    addCorner(toast, 9)
    addStroke(toast, THEME.purple, 0.35, 1)
    make("TextLabel", {
        Position = UDim2.fromOffset(12, 7),
        Size = UDim2.new(1, -22, 0, 18),
        BackgroundTransparency = 1,
        Text = title,
        TextColor3 = THEME.text,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, toast)
    make("TextLabel", {
        Position = UDim2.fromOffset(12, 27),
        Size = UDim2.new(1, -22, 0, 20),
        BackgroundTransparency = 1,
        Text = message,
        TextColor3 = THEME.muted,
        Font = Enum.Font.Gotham,
        TextSize = 10,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, toast)
    toast.Position = UDim2.fromOffset(25, 0)
    toast.BackgroundTransparency = 1
    animate(toast, {Position = UDim2.fromOffset(0, 0), BackgroundTransparency = 0.04}, 0.2)
    task.delay(3, function()
        if toast.Parent then
            animate(toast, {Position = UDim2.fromOffset(25, 0), BackgroundTransparency = 1}, 0.18)
            task.wait(0.2)
            if toast.Parent then toast:Destroy() end
        end
    end)
end

-- Per-module settings modal. Each module gets a gear button and module-specific controls.
local settingsOverlay = make("Frame", {
    Name = "ModuleSettingsOverlay",
    Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.new(0, 0, 0),
    BackgroundTransparency = 0.42,
    Visible = false,
    ZIndex = 20,
}, gui)

local settingsCard = make("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(360, 270),
    BackgroundColor3 = THEME.bg,
    BorderSizePixel = 0,
    ZIndex = 21,
}, settingsOverlay)
addCorner(settingsCard, 12)
addStroke(settingsCard, THEME.purple, 0.25, 1.2)

local settingsTitle = make("TextLabel", {
    Position = UDim2.fromOffset(16, 12),
    Size = UDim2.new(1, -70, 0, 26),
    BackgroundTransparency = 1,
    Text = "Module Settings",
    TextColor3 = THEME.text,
    Font = Enum.Font.GothamBold,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 22,
}, settingsCard)

local settingsClose = make("TextButton", {
    Position = UDim2.new(1, -42, 0, 10),
    Size = UDim2.fromOffset(28, 28),
    BackgroundColor3 = THEME.panel2,
    Text = "×",
    TextColor3 = THEME.text,
    Font = Enum.Font.Gotham,
    TextSize = 20,
    AutoButtonColor = false,
    ZIndex = 22,
}, settingsCard)
addCorner(settingsClose, 7)

local settingsBody = make("Frame", {
    Position = UDim2.fromOffset(14, 49),
    Size = UDim2.new(1, -28, 1, -62),
    BackgroundTransparency = 1,
    ZIndex = 22,
}, settingsCard)
make("UIListLayout", {
    Padding = UDim.new(0, 8),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, settingsBody)

local function clearSettingsBody()
    for _, child in ipairs(settingsBody:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
end

local function settingsLabel(text, parent)
    return make("TextLabel", {
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundTransparency = 1,
        Text = text,
        TextColor3 = THEME.muted,
        Font = Enum.Font.Gotham,
        TextSize = 11,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 23,
    }, parent)
end

local createSliderRow
local function openModuleSettings(definition)
    clearSettingsBody()
    settingsTitle.Text = definition.name .. " Settings"
    settingsOverlay.Visible = true

    settingsLabel(definition.description, settingsBody)

    if definition.id == "taggedHighlights" then
        settingsLabel("Highlights only affect BaseParts tagged PulseHighlight or with attribute PulseHighlight = true.", settingsBody)
        createSliderRow("Fill Transparency", "0 = opaque, 90 = very transparent", math.floor(state.highlightTransparency * 100), 0, 90, function(value)
            state.highlightTransparency = value / 100
            saveConfig()
            for _, highlight in pairs(activeHighlights) do
                if highlight and highlight.Parent then
                    highlight.FillTransparency = state.highlightTransparency
                end
            end
        end, settingsBody)
    elseif definition.id == "particles" then
        createSliderRow("Particle Rate", "Particles per second on your character", state.particleRate, 1, 40, function(value)
            state.particleRate = value
            if state.particles then setParticles(true) end
        end, settingsBody)
        settingsLabel("Particles are attached to your own avatar.", settingsBody)
    elseif definition.id == "playerTrail" then
        settingsLabel("Trail lifetime and color are controlled by the current client theme.", settingsBody)
        local button = make("TextButton", {
            Size = UDim2.new(1, 0, 0, 32),
            BackgroundColor3 = THEME.panel2,
            Text = "Rebuild Trail",
            TextColor3 = THEME.text,
            Font = Enum.Font.GothamMedium,
            TextSize = 11,
            AutoButtonColor = false,
            ZIndex = 23,
        }, settingsBody)
        addCorner(button, 7)
        connect(button.Activated, function()
            setTrail(state.playerTrail)
        end)
    elseif definition.id == "fps" or definition.id == "coordinates" or definition.id == "targetHud" then
        settingsLabel("Target HUD shows avatar, name, health, and distance for the character directly visible in the center-screen view.", settingsBody)
    elseif definition.id == "targetEsp" then
        settingsLabel("Visible-only ESP: highlights characters only when line of sight is clear. It does not reveal players through walls.", settingsBody)
    elseif definition.id == "crosshair" then
        settingsLabel("The crosshair uses your selected accent color.", settingsBody)
    elseif definition.id == "compactMode" then
        settingsLabel("Compact Mode resizes the main client window.", settingsBody)
    end

    local saveButton = make("TextButton", {
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundColor3 = THEME.purpleDark,
        Text = "Save Configuration",
        TextColor3 = THEME.text,
        Font = Enum.Font.GothamBold,
        TextSize = 11,
        AutoButtonColor = false,
        ZIndex = 23,
    }, settingsBody)
    addCorner(saveButton, 7)
    connect(saveButton.Activated, function()
        saveConfig()
        notify("Configuration", "Save requested")
    end)

    settingsCard.Size = UDim2.fromOffset(340, 240)
    animate(settingsCard, {Size = UDim2.fromOffset(360, 270)}, 0.18)
end

connect(settingsClose.Activated, function()
    settingsOverlay.Visible = false
end)
-- HUD
local hud = make("Frame", {
    Name = "HUD",
    Position = UDim2.fromOffset(16, 16),
    Size = UDim2.fromOffset(215, 89),
    BackgroundColor3 = THEME.bg,
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
    Visible = false,
}, gui)
addCorner(hud, 8)
addStroke(hud, THEME.purple, 0.45, 1)

local fpsLabel = make("TextLabel", {
    Position = UDim2.fromOffset(10, 7),
    Size = UDim2.new(1, -20, 0, 20),
    BackgroundTransparency = 1,
    Text = "FPS: --",
    TextColor3 = THEME.green,
    Font = Enum.Font.GothamBold,
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
}, hud)
local coordLabel = make("TextLabel", {
    Position = UDim2.fromOffset(10, 31),
    Size = UDim2.new(1, -20, 0, 20),
    BackgroundTransparency = 1,
    Text = "XYZ: --",
    TextColor3 = THEME.text,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
}, hud)
local pingLabel = make("TextLabel", {
    Position = UDim2.fromOffset(10, 55),
    Size = UDim2.new(1, -20, 0, 20),
    BackgroundTransparency = 1,
    Text = "Ping: --",
    TextColor3 = THEME.muted,
    Font = Enum.Font.Gotham,
    TextSize = 11,
    TextXAlignment = Enum.TextXAlignment.Left,
    Visible = state.ping,
}, hud)

-- Center crosshair
local crosshair = make("Frame", {
    Name = "Crosshair",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(18, 18),
    BackgroundTransparency = 1,
    Visible = false,
}, gui)
for _, spec in ipairs({
    {Position = UDim2.new(0.5, -1, 0, 0), Size = UDim2.fromOffset(2, 6)},
    {Position = UDim2.new(0.5, -1, 1, -6), Size = UDim2.fromOffset(2, 6)},
    {Position = UDim2.new(0, 0, 0.5, -1), Size = UDim2.fromOffset(6, 2)},
    {Position = UDim2.new(1, -6, 0.5, -1), Size = UDim2.fromOffset(6, 2)},
}) do
    make("Frame", {
        Position = spec.Position,
        Size = spec.Size,
        BackgroundColor3 = state.accent,
        BorderSizePixel = 0,
    }, crosshair)
end

-- Target HUD: displays only the player directly hit by the center camera ray.
local targetHud = make("Frame", {
    Name = "TargetHUD",
    AnchorPoint = Vector2.new(1, 1),
    Position = UDim2.new(1, -24, 1, -28),
    Size = UDim2.fromOffset(270, 94),
    BackgroundColor3 = THEME.bg,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    Visible = false,
}, gui)
addCorner(targetHud, 10)
addStroke(targetHud, THEME.purple, 0.22, 1.2)
local targetAvatar = make("ImageLabel", {
    Name = "TargetAvatar", Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(42, 42),
    BackgroundColor3 = THEME.panel2, BackgroundTransparency = 0, Image = "", BorderSizePixel = 0,
}, targetHud)
addCorner(targetAvatar, 8)
local lastAvatarUserId = nil
local targetName = make("TextLabel", {
    Position = UDim2.fromOffset(64, 9), Size = UDim2.new(1, -76, 0, 22),
    BackgroundTransparency = 1, Text = "Target", TextColor3 = THEME.text,
    Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
}, targetHud)
local targetHealthText = make("TextLabel", {
    Position = UDim2.fromOffset(64, 34), Size = UDim2.new(1, -76, 0, 16),
    BackgroundTransparency = 1, Text = "HP: -- / --", TextColor3 = THEME.muted,
    Font = Enum.Font.Gotham, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left,
}, targetHud)
local targetHealthBack = make("Frame", {
    Position = UDim2.fromOffset(64, 58), Size = UDim2.new(1, -77, 0, 8),
    BackgroundColor3 = THEME.panel2, BorderSizePixel = 0,
}, targetHud)
addCorner(targetHealthBack, 4)
local targetHealthFill = make("Frame", {
    Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.green, BorderSizePixel = 0,
}, targetHealthBack)
addCorner(targetHealthFill, 4)

local visiblePlayerEsp = {}
local function removePlayerEsp(plr)
    local objects = visiblePlayerEsp[plr]
    if objects then
        if objects.highlight then objects.highlight:Destroy() end
        if objects.billboard then objects.billboard:Destroy() end
        visiblePlayerEsp[plr] = nil
    end
end

local function getVisibleTarget()
    local camera = workspace.CurrentCamera
    if not camera then return nil end
    local origin = camera.CFrame.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {player.Character, gui}
    params.IgnoreWater = true
    local result = workspace:Raycast(origin, camera.CFrame.LookVector * 600, params)
    if not result then return nil end
    local model = result.Instance:FindFirstAncestorOfClass("Model")
    if not model then return nil end
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return nil end
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and other.Character == model then
            return other, humanoid
        end
    end
    return nil
end

local function updateTargetHud()
    if not state.targetHud then targetHud.Visible = false; return end
    local target, humanoid = getVisibleTarget()
    if not target or not humanoid then targetHud.Visible = false; return end
    local health = math.max(0, humanoid.Health)
    local maxHealth = math.max(1, humanoid.MaxHealth)
    local ratio = math.clamp(health / maxHealth, 0, 1)
    targetName.Text = target.DisplayName .. "  (@" .. target.Name .. ")"
    local myRoot = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    local distanceText = (myRoot and targetRoot) and string.format("  •  %.0f studs", (myRoot.Position - targetRoot.Position).Magnitude) or ""
    targetHealthText.Text = string.format("HP: %d / %d%s", math.floor(health + 0.5), math.floor(maxHealth + 0.5), distanceText)
    if lastAvatarUserId ~= target.UserId then
        lastAvatarUserId = target.UserId
        targetAvatar.Image = ""
        task.spawn(function()
            local ok, image = pcall(function()
                return Players:GetUserThumbnailAsync(target.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
            end)
            if ok and targetHud.Parent and lastAvatarUserId == target.UserId then targetAvatar.Image = image end
        end)
    end
    targetHealthFill.Size = UDim2.new(ratio, 0, 1, 0)
    targetHealthFill.BackgroundColor3 = ratio > 0.55 and THEME.green or (ratio > 0.25 and Color3.fromRGB(255, 190, 90) or THEME.red)
    targetHud.Visible = true
end

local function updateVisiblePlayerEsp()
    if not state.targetEsp then
        for plr in pairs(visiblePlayerEsp) do removePlayerEsp(plr) end
        return
    end
    local camera = workspace.CurrentCamera
    if not camera then return end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.IgnoreWater = true
    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= player and other.Character then
            local character = other.Character
            local head = character:FindFirstChild("Head")
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            local visible = false
            if head and humanoid and humanoid.Health > 0 then
                local viewport, onScreen = camera:WorldToViewportPoint(head.Position)
                if onScreen and viewport.Z > 0 then
                    params.FilterDescendantsInstances = {player.Character, gui}
                    local direction = head.Position - camera.CFrame.Position
                    local hit = workspace:Raycast(camera.CFrame.Position, direction, params)
                    visible = hit ~= nil and hit.Instance:IsDescendantOf(character)
                end
            end
            if visible then
                local objects = visiblePlayerEsp[other]
                if not objects or objects.character ~= character then
                    removePlayerEsp(other)
                    local highlight = make("Highlight", {
                        Name = "PulseVisiblePlayerHighlight", Adornee = character,
                        FillColor = state.accent, OutlineColor = state.accent,
                        FillTransparency = 0.78, OutlineTransparency = 0.08,
                        DepthMode = Enum.HighlightDepthMode.Occluded,
                    }, gui)
                    local billboard = make("BillboardGui", {
                        Name = "PulseVisiblePlayerLabel", Adornee = head,
                        Size = UDim2.fromOffset(180, 34), StudsOffset = Vector3.new(0, 2.1, 0),
                        AlwaysOnTop = false, MaxDistance = 450,
                    }, guiParent)
                    make("TextLabel", {
                        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1,
                        Text = other.DisplayName, TextColor3 = state.accent,
                        TextStrokeTransparency = 0.25, TextStrokeColor3 = Color3.new(0, 0, 0),
                        Font = Enum.Font.GothamBold, TextSize = 12,
                    }, billboard)
                    visiblePlayerEsp[other] = {highlight = highlight, billboard = billboard, character = character}
                else
                    objects.highlight.FillColor = state.accent
                    objects.highlight.OutlineColor = state.accent
                    local label = objects.billboard:FindFirstChildOfClass("TextLabel")
                    if label then label.Text = other.DisplayName; label.TextColor3 = state.accent end
                end
            else
                removePlayerEsp(other)
            end
        else
            removePlayerEsp(other)
        end
    end
end

local function getCharacterRoot()
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local function getCharacterHumanoid()
    local character = player.Character
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

-- Player trail effect (on your own avatar).
local trailObjects = {}
local function clearTrail()
    for _, object in ipairs(trailObjects) do
        if object and object.Parent then object:Destroy() end
    end
    table.clear(trailObjects)
end

local function setTrail(enabled)
    clearTrail()
    if not enabled then return end
    local character = player.Character
    if not character then return end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local a0 = make("Attachment", {Name = "PulseTrailA0", Position = Vector3.new(-0.45, 0, 0)}, root)
    local a1 = make("Attachment", {Name = "PulseTrailA1", Position = Vector3.new(0.45, 0, 0)}, root)
    local trail = make("Trail", {
        Name = "PulsePlayerTrail",
        Attachment0 = a0,
        Attachment1 = a1,
        Lifetime = 0.45,
        MinLength = 0.1,
        Color = ColorSequence.new(state.accent, Color3.fromRGB(80, 50, 140)),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.15),
            NumberSequenceKeypoint.new(1, 1),
        }),
        LightEmission = 0.8,
        Enabled = true,
    }, root)
    table.insert(trailObjects, a0)
    table.insert(trailObjects, a1)
    table.insert(trailObjects, trail)
end

-- Simple particle emitter attached to your own avatar.
local particleObjects = {}
local function clearParticles()
    for _, object in ipairs(particleObjects) do
        if object and object.Parent then object:Destroy() end
    end
    table.clear(particleObjects)
end

local function setParticles(enabled)
    clearParticles()
    if not enabled then return end
    local root = getCharacterRoot()
    if not root then return end
    local attachment = make("Attachment", {Name = "PulseParticlesAttachment"}, root)
    local emitter = make("ParticleEmitter", {
        Name = "PulseParticles",
        Texture = "rbxasset://textures/particles/sparkles_main.dds",
        Rate = state.particleRate,
        Lifetime = NumberRange.new(0.45, 0.9),
        Speed = NumberRange.new(0.4, 1.5),
        SpreadAngle = Vector2.new(180, 180),
        LightEmission = 0.7,
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.12),
            NumberSequenceKeypoint.new(1, 0),
        }),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.1),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Color = ColorSequence.new(state.accent, Color3.fromRGB(210, 170, 255)),
        Enabled = true,
    }, attachment)
    table.insert(particleObjects, attachment)
    table.insert(particleObjects, emitter)
end

-- Highlights only explicitly tagged/attributed parts in your own experience.
local function removeHighlight(part)
    local highlight = activeHighlights[part]
    if highlight then
        if highlight.Parent then highlight:Destroy() end
        activeHighlights[part] = nil
    end
end

local function shouldHighlight(instance)
    return instance:IsA("BasePart")
        and instance ~= workspace.CurrentCamera
        and (CollectionService:HasTag(instance, "PulseHighlight")
            or instance:GetAttribute("PulseHighlight") == true)
end

local function refreshHighlights()
    if not state.taggedHighlights then
        for part in pairs(activeHighlights) do removeHighlight(part) end
        return
    end
    for _, instance in ipairs(workspace:GetDescendants()) do
        if shouldHighlight(instance) and not activeHighlights[instance] then
            local highlight = make("Highlight", {
                Name = "PulseHighlightEffect",
                Adornee = instance,
                FillColor = state.accent,
                OutlineColor = state.accent,
                FillTransparency = state.highlightTransparency,
                OutlineTransparency = 0.05,
                DepthMode = Enum.HighlightDepthMode.Occluded,
            }, gui)
            activeHighlights[instance] = highlight
        end
    end
    for part in pairs(activeHighlights) do
        if not part.Parent or not shouldHighlight(part) then
            removeHighlight(part)
        end
    end
end


-- Optional client-side atmosphere/glow cosmetics.
-- Effects are attached locally and removed when their toggle is disabled.
local atmosphereEffect
local bloomEffect
local groundRings = {}

local function setMagentaAtmosphere(enabled)
    if atmosphereEffect then
        atmosphereEffect:Destroy()
        atmosphereEffect = nil
    end
    if not enabled then return end
    atmosphereEffect = Instance.new("ColorCorrectionEffect")
    atmosphereEffect.Name = "PulseVisuals_MagentaTint"
    atmosphereEffect.TintColor = Color3.fromRGB(255, 120, 245)
    atmosphereEffect.Saturation = 0.28
    atmosphereEffect.Contrast = 0.08
    atmosphereEffect.Brightness = 0.015
    atmosphereEffect.Parent = Lighting
end

local function setBloomGlow(enabled)
    if bloomEffect then
        bloomEffect:Destroy()
        bloomEffect = nil
    end
    if not enabled then return end
    bloomEffect = Instance.new("BloomEffect")
    bloomEffect.Name = "PulseVisuals_Bloom"
    bloomEffect.Intensity = 0.8
    bloomEffect.Size = 28
    bloomEffect.Threshold = 0.82
    bloomEffect.Parent = Lighting
end

local function clearGroundAura()
    for _, ring in ipairs(groundRings) do
        if ring and ring.Parent then ring:Destroy() end
    end
    table.clear(groundRings)
end

local function setGroundAura(enabled)
    clearGroundAura()
    if not enabled then return end
    for i = 1, 2 do
        local ring = Instance.new("Part")
        ring.Name = "PulseVisuals_GroundAura"
        ring.Shape = Enum.PartType.Cylinder
        ring.Size = Vector3.new(0.07, i == 1 and 4.2 or 6.2, i == 1 and 4.2 or 6.2)
        ring.Material = Enum.Material.Neon
        ring.Color = state.accent
        ring.Transparency = 0.28 + (i - 1) * 0.16
        ring.Anchored = true
        ring.CanCollide = false
        ring.CanTouch = false
        ring.CanQuery = false
        ring.CastShadow = false
        ring.Parent = workspace
        table.insert(groundRings, ring)
    end
end

-- Modules and settings.
local moduleDefinitions = {
    Combat = {
        -- Visual-only category: intentionally no combat automation or player tracking.
    },
    Visuals = {
        {id = "magentaAtmosphere", name = "Magenta Atmosphere", description = "Adds a pink-purple color grade"},
        {id = "bloomGlow", name = "Bloom Glow", description = "Adds a soft glow to bright colors"},
        {id = "taggedHighlights", name = "Tagged Highlights", description = "Highlights only experience-marked parts"},
        {id = "targetHud", name = "Target HUD", description = "Shows health for the character directly under your view"},
        {id = "targetEsp", name = "Target ESP (Visible Only)", description = "Highlights players only when line of sight is clear"},
        {id = "crosshair", name = "Crosshair", description = "Shows a simple center-screen crosshair"},
        {id = "fps", name = "FPS Counter", description = "Displays approximate client FPS"},
        {id = "coordinates", name = "Coordinates", description = "Displays your character position"},
        {id = "ping", name = "Ping Counter", description = "Displays network ping when the client exposes it"},
        {id = "animatedCrosshair", name = "Animated Crosshair", description = "Adds a subtle pulse to the crosshair"},
    },
    Player = {
        {id = "playerTrail", name = "Player Trail", description = "Adds a cosmetic trail to your character"},
        {id = "particles", name = "Character Particles", description = "Adds cosmetic particles to your character"},
        {id = "groundAura", name = "Ground Aura", description = "Adds neon rings around your own character"},
    },
    Settings = {
        {id = "compactMode", name = "Compact Mode", description = "Uses a smaller client window"},
    },
}

local pages = {"Combat", "Visuals", "Player", "Settings"}
local currentPage = "Visuals"
local renderPage

local suppressNotifications = false
local function setModule(id, enabled)
    state[id] = enabled
    if id == "fps" or id == "coordinates" or id == "ping" then
        hud.Visible = state.fps or state.coordinates or state.ping
        fpsLabel.Visible = state.fps
        coordLabel.Visible = state.coordinates
        pingLabel.Visible = state.ping
    elseif id == "animatedCrosshair" then
        state.animatedCrosshair = enabled
    elseif id == "targetHud" then
        targetHud.Visible = enabled
        if not enabled then targetHud.Visible = false end
    elseif id == "targetEsp" then
        if not enabled then updateVisiblePlayerEsp() end
    elseif id == "crosshair" then
        crosshair.Visible = enabled
    elseif id == "playerTrail" then
        setTrail(enabled)
    elseif id == "particles" then
        setParticles(enabled)
    elseif id == "taggedHighlights" then
        refreshHighlights()
    elseif id == "magentaAtmosphere" then
        setMagentaAtmosphere(enabled)
    elseif id == "bloomGlow" then
        setBloomGlow(enabled)
    elseif id == "groundAura" then
        setGroundAura(enabled)
    elseif id == "compactMode" then
        animate(main, {Size = enabled and UDim2.fromOffset(600, 410) or UDim2.fromOffset(680, 455)}, 0.2)
    end
    if not suppressNotifications then notify(id, enabled and "Enabled" or "Disabled") end
end

local function createToggleRow(definition, parent)
    local row = make("Frame", {
        Name = definition.id,
        Size = UDim2.new(1, -5, 0, 54),
        BackgroundColor3 = THEME.panel,
        BorderSizePixel = 0,
    }, parent)
    addCorner(row, 8)
    connect(row.MouseEnter, function()
        animate(row, {BackgroundColor3 = THEME.panel2}, 0.12)
    end)
    connect(row.MouseLeave, function()
        animate(row, {BackgroundColor3 = THEME.panel}, 0.16)
    end)

    make("TextLabel", {
        Position = UDim2.fromOffset(12, 7),
        Size = UDim2.new(1, -80, 0, 19),
        BackgroundTransparency = 1,
        Text = definition.name,
        TextColor3 = THEME.text,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    make("TextLabel", {
        Position = UDim2.fromOffset(12, 28),
        Size = UDim2.new(1, -80, 0, 17),
        BackgroundTransparency = 1,
        Text = definition.description,
        TextColor3 = THEME.muted,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local toggle = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -12, 0.5, 0),
        Size = UDim2.fromOffset(38, 21),
        BackgroundColor3 = state[definition.id] and state.accent or Color3.fromRGB(58, 52, 68),
        Text = "",
        AutoButtonColor = false,
    }, row)
    addCorner(toggle, 11)
    local knob = make("Frame", {
        Position = state[definition.id] and UDim2.fromOffset(20, 3) or UDim2.fromOffset(3, 3),
        Size = UDim2.fromOffset(15, 15),
        BackgroundColor3 = Color3.fromRGB(245, 241, 250),
        BorderSizePixel = 0,
    }, toggle)
    addCorner(knob, 10)

    local function sync()
        local isEnabled = state[definition.id] == true
        animate(toggle, {BackgroundColor3 = isEnabled and state.accent or Color3.fromRGB(58, 52, 68)}, 0.15)
        animate(knob, {Position = isEnabled and UDim2.fromOffset(20, 3) or UDim2.fromOffset(3, 3)}, 0.15)
    end

    toggle.Position = UDim2.new(1, -42, 0.5, 0)
    local gear = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -7, 0.5, 0),
        Size = UDim2.fromOffset(24, 24),
        BackgroundColor3 = THEME.panel2,
        Text = "⚙",
        TextColor3 = THEME.muted,
        Font = Enum.Font.Gotham,
        TextSize = 13,
        AutoButtonColor = false,
    }, row)
    addCorner(gear, 6)

    connect(toggle.Activated, function()
        setModule(definition.id, not state[definition.id])
        sync()
        saveConfig()
    end)
    connect(gear.Activated, function()
        openModuleSettings(definition)
    end)
    moduleRows[definition.id] = {row = row, sync = sync}
    return row
end

createSliderRow = function(name, description, initial, min, max, callback, parent)
    local row = make("Frame", {
        Size = UDim2.new(1, -5, 0, 67),
        BackgroundColor3 = THEME.panel,
        BorderSizePixel = 0,
    }, parent)
    addCorner(row, 8)
    local label = make("TextLabel", {
        Position = UDim2.fromOffset(12, 6),
        Size = UDim2.new(1, -24, 0, 18),
        BackgroundTransparency = 1,
        Text = name .. "  •  " .. tostring(initial),
        TextColor3 = THEME.text,
        Font = Enum.Font.GothamMedium,
        TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    make("TextLabel", {
        Position = UDim2.fromOffset(12, 24),
        Size = UDim2.new(1, -24, 0, 14),
        BackgroundTransparency = 1,
        Text = description,
        TextColor3 = THEME.muted,
        Font = Enum.Font.Gotham,
        TextSize = 9,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    local bar = make("Frame", {
        Position = UDim2.new(0, 12, 1, -17),
        Size = UDim2.new(1, -24, 0, 5),
        BackgroundColor3 = Color3.fromRGB(59, 51, 73),
        BorderSizePixel = 0,
    }, row)
    addCorner(bar, 5)
    local fill = make("Frame", {
        Size = UDim2.new((initial - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = state.accent,
        BorderSizePixel = 0,
    }, bar)
    addCorner(fill, 5)
    local hitbox = make("TextButton", {
        Position = UDim2.new(0, 0, 0, -10),
        Size = UDim2.new(1, 0, 0, 25),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
    }, bar)
    local draggingSlider = false
    local function setFromX(x)
        local width = math.max(bar.AbsoluteSize.X, 1)
        local alpha = math.clamp((x - bar.AbsolutePosition.X) / width, 0, 1)
        local value = math.floor(min + (max - min) * alpha + 0.5)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        label.Text = name .. "  •  " .. tostring(value)
        callback(value)
    end
    connect(hitbox.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
            setFromX(input.Position.X)
        end
    end)
    connect(UserInputService.InputChanged, function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromX(input.Position.X)
        end
    end)
    connect(UserInputService.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)
    return row
end

local function clearModuleList()
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("GuiObject") then child:Destroy() end
    end
    table.clear(moduleRows)
end

renderPage = function(category)
    currentPage = category
    pageTitle.Text = category
    clearModuleList()
    searchBox.Text = ""

    -- Staggered page-entry animation: rows slide upward and fade in.
    local pageRows = {}
    for _, definition in ipairs(moduleDefinitions[category] or {}) do
        local row = createToggleRow(definition, list)
        table.insert(pageRows, row)
    end
    for index, row in ipairs(pageRows) do
        local finalPosition = row.Position
        row.Position = finalPosition + UDim2.fromOffset(0, 10)
        row.BackgroundTransparency = 1
        for _, descendant in ipairs(row:GetDescendants()) do
            if descendant:IsA("TextLabel") then descendant.TextTransparency = 1 end
        end
        task.delay((index - 1) * 0.025, function()
            if not running or not row.Parent then return end
            animate(row, {Position = finalPosition, BackgroundTransparency = 0}, 0.22)
            for _, descendant in ipairs(row:GetDescendants()) do
                if descendant:IsA("TextLabel") then
                    animate(descendant, {TextTransparency = 0}, 0.20)
                end
            end
        end)
    end

    if category == "Combat" then
        local infoCard = make("Frame", {
            Name = "VisualOnlyNotice",
            Size = UDim2.new(1, -5, 0, 118),
            BackgroundColor3 = THEME.panel,
            BorderSizePixel = 0,
        }, list)
        addCorner(infoCard, 10)
        addStroke(infoCard, THEME.purple, 0.45, 1)
        make("TextLabel", {
            Position = UDim2.fromOffset(14, 12),
            Size = UDim2.new(1, -28, 0, 24),
            BackgroundTransparency = 1,
            Text = "VISUAL-ONLY PROFILE",
            TextColor3 = state.accent,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, infoCard)
        make("TextLabel", {
            Position = UDim2.fromOffset(14, 40),
            Size = UDim2.new(1, -28, 0, 62),
            BackgroundTransparency = 1,
            Text = "Visual-only modules: no aimbot, auto-attack, through-wall tracking, or anti-cheat bypass. Target ESP is limited to players with clear line of sight.",
            TextColor3 = THEME.muted,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
        }, infoCard)
    end

    if category == "Settings" then
        local persistenceNote = make("TextLabel", {
            Name = "PersistenceInfo", Size = UDim2.new(1, -5, 0, 34),
            BackgroundTransparency = 1,
            Text = (type(writefile) == "function" and type(readfile) == "function") and "Settings save locally when executor file APIs are available." or "This environment has no local config file API; settings are session-only.",
            TextColor3 = THEME.muted, Font = Enum.Font.Gotham, TextSize = 10,
            TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left,
        }, list)
        createSliderRow("Highlight Transparency", "Applies to tagged highlight objects", math.floor(state.highlightTransparency * 100), 0, 90, function(value)
            state.highlightTransparency = value / 100
            saveConfig()
            for _, highlight in pairs(activeHighlights) do
                if highlight and highlight.Parent then
                    highlight.FillTransparency = state.highlightTransparency
                end
            end
        end, list)
        createSliderRow("Particle Rate", "Particles per second on your character", state.particleRate, 1, 40, function(value)
            state.particleRate = value
            if state.particles then setParticles(true) end
        end, list)
        local accentRow = make("Frame", {
            Size = UDim2.new(1, -5, 0, 58),
            BackgroundColor3 = THEME.panel,
            BorderSizePixel = 0,
        }, list)
        addCorner(accentRow, 8)
        make("TextLabel", {
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -24, 1, 0),
            BackgroundTransparency = 1,
            Text = "Theme / Accent Color",
            TextColor3 = THEME.text,
            Font = Enum.Font.GothamMedium,
            TextSize = 10,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, accentRow)
        local colors = {
            {name = "Purple", color = Color3.fromRGB(157, 91, 255)},
            {name = "Blue", color = Color3.fromRGB(75, 155, 255)},
            {name = "Crimson", color = Color3.fromRGB(255, 75, 105)},
            {name = "Ice Blue", color = Color3.fromRGB(80, 190, 255)},
            {name = "Matrix", color = Color3.fromRGB(85, 235, 135)},
        }
        for i, item in ipairs(colors) do
            local button = make("TextButton", {
                Position = UDim2.new(1, -142 + (i - 1) * 31, 0.5, -11),
                Size = UDim2.fromOffset(23, 22),
                BackgroundColor3 = item.color,
                Text = "",
                AutoButtonColor = false,
            }, accentRow)
            addCorner(button, 6)
            connect(button.Activated, function()
                state.accent = item.color
                state.accentName = item.name
                THEME.purple = item.color
                for _, child in ipairs(crosshair:GetChildren()) do
                    if child:IsA("Frame") then child.BackgroundColor3 = item.color end
                end
                for _, highlight in pairs(activeHighlights) do
                    if highlight and highlight.Parent then
                        highlight.FillColor = item.color
                        highlight.OutlineColor = item.color
                    end
                end
                for _, object in ipairs(trailObjects) do
                    if object:IsA("Trail") then
                        object.Color = ColorSequence.new(item.color, Color3.fromRGB(80, 50, 140))
                    end
                end
                for _, object in ipairs(particleObjects) do
                    if object:IsA("ParticleEmitter") then
                        object.Color = ColorSequence.new(item.color, Color3.fromRGB(210, 170, 255))
                    end
                end
                for _, ring in ipairs(groundRings) do
                    if ring and ring.Parent then ring.Color = item.color end
                end
                for _, row in pairs(moduleRows) do row.sync() end
                saveConfig()
                notify("Accent Color", item.name .. " selected")
            end)
        end
    end
end

local navButtons = {}
for index, category in ipairs(pages) do
    local button = make("TextButton", {
        Name = category,
        Size = UDim2.new(1, 0, 0, 36),
        BackgroundColor3 = category == currentPage and THEME.purpleDark or THEME.panel,
        Text = "   " .. category,
        TextColor3 = category == currentPage and THEME.purple or THEME.muted,
        Font = Enum.Font.GothamMedium,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = index,
        AutoButtonColor = false,
    }, sidebar)
    addCorner(button, 7)
    navButtons[category] = button
    connect(button.Activated, function()
        for name, nav in pairs(navButtons) do
            animate(nav, {
                BackgroundColor3 = name == category and THEME.purpleDark or THEME.panel,
                TextColor3 = name == category and THEME.purple or THEME.muted,
            }, 0.15)
        end
        renderPage(category)
    end)
end

connect(searchBox:GetPropertyChangedSignal("Text"), function()
    local query = string.lower(searchBox.Text)
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") and child.Name ~= "" then
            local label = child:FindFirstChildWhichIsA("TextLabel")
            local haystack = string.lower(child.Name .. " " .. (label and label.Text or ""))
            child.Visible = string.find(haystack, query, 1, true) ~= nil
        end
    end
end)

-- Drag the window with mouse or touch.
local dragging = false
local dragInput
local dragStart
local startPosition
connect(header.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPosition = main.Position
        dragInput = input
    end
end)
connect(UserInputService.InputChanged, function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        main.Position = UDim2.new(
            startPosition.X.Scale, startPosition.X.Offset + delta.X,
            startPosition.Y.Scale, startPosition.Y.Offset + delta.Y
        )
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

local function setMenuOpen(open)
    state.menuOpen = open
    if open then
        main.Visible = true
        mainScale.Scale = 0.92
        local restingPosition = main.Position
        main.Position = restingPosition + UDim2.fromOffset(0, 10)
        animate(mainScale, {Scale = 1}, 0.24)
        animate(main, {BackgroundTransparency = 0, Position = restingPosition}, 0.24)
    else
        animate(mainScale, {Scale = 0.96}, 0.14)
        task.delay(0.15, function()
            if running and not state.menuOpen then main.Visible = false end
        end)
    end
end

connect(closeButton.Activated, function()
    setMenuOpen(false)
end)
connect(UserInputService.InputBegan, function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        setMenuOpen(not state.menuOpen)
    end
end)

-- Runtime HUD update and tagged-part scanning.
local scanTimer = 0
local espUpdateTimer = 0
connect(RunService.RenderStepped, function(deltaTime)
    if not running then return end
    frameCount += 1
    local now = os.clock()
    if now - lastFrame >= 0.5 then
        currentFps = math.floor(frameCount / (now - lastFrame) + 0.5)
        frameCount = 0
        lastFrame = now
        if state.fps then fpsLabel.Text = "FPS: " .. tostring(currentFps) end
        if state.ping then
            local pingText = "Ping: --"
            pcall(function()
                local stats = game:GetService("Stats")
                local network = stats.Network
                local serverStats = network.ServerStatsItem
                local dataPing = serverStats:FindFirstChild("Data Ping")
                if dataPing then pingText = "Ping: " .. tostring(dataPing:GetValueString()) end
            end)
            pingLabel.Text = pingText
        end
    end
    if state.animatedCrosshair and state.crosshair then
        local pulse = 1 + (math.sin(os.clock() * 4) + 1) * 0.06
        crosshair.Size = UDim2.fromOffset(18 * pulse, 18 * pulse)
    else
        crosshair.Size = UDim2.fromOffset(18, 18)
    end
    if state.coordinates then
        local root = getCharacterRoot()
        if root then
            local p = root.Position
            coordLabel.Text = string.format("XYZ: %d, %d, %d", math.floor(p.X + 0.5), math.floor(p.Y + 0.5), math.floor(p.Z + 0.5))
        else
            coordLabel.Text = "XYZ: waiting for character..."
        end
    end
    if state.groundAura then
        local root = getCharacterRoot()
        if root then
            local pulse = (math.sin(os.clock() * 2.4) + 1) / 2
            for i, ring in ipairs(groundRings) do
                if ring and ring.Parent then
                    local radius = (i == 1 and 4.2 or 6.2) + pulse * 0.5
                    ring.Size = Vector3.new(0.07, radius, radius)
                    ring.CFrame = CFrame.new(root.Position - Vector3.new(0, 2.75, 0)) * CFrame.Angles(0, 0, math.rad(90))
                    ring.Transparency = 0.2 + (i - 1) * 0.16 + pulse * 0.18
                    ring.Color = state.accent
                end
            end
        end
    end
    if state.taggedHighlights then
        scanTimer += deltaTime
        if scanTimer >= 1.25 then
            scanTimer = 0
            refreshHighlights()
        end
    end
    updateTargetHud()
    if state.targetEsp then
        espUpdateTimer += deltaTime
        if espUpdateTimer >= 0.15 then
            espUpdateTimer = 0
            updateVisiblePlayerEsp()
        end
    elseif next(visiblePlayerEsp) ~= nil then
        updateVisiblePlayerEsp()
    end
end)

connect(player.CharacterAdded, function()
    task.wait(0.75)
    if not running then return end
    if state.playerTrail then setTrail(true) end
    if state.particles then setParticles(true) end
    if state.groundAura and #groundRings == 0 then setGroundAura(true) end
end)

-- Cleanup if this LocalScript is removed.
local function cleanup()
    if not running then return end
    running = false
    clearTrail()
    clearParticles()
    clearGroundAura()
    targetHud.Visible = false
    for plr in pairs(visiblePlayerEsp) do removePlayerEsp(plr) end
    setMagentaAtmosphere(false)
    setBloomGlow(false)
    for part in pairs(activeHighlights) do removeHighlight(part) end
    for _, connection in ipairs(connections) do
        pcall(function() connection:Disconnect() end)
    end
end
pcall(function() connect(gui.Destroying, cleanup) end)

renderPage("Visuals")
-- Restore enabled modules after their UI/effect objects exist.
suppressNotifications = true
for _, category in ipairs(pages) do
    for _, definition in ipairs(moduleDefinitions[category] or {}) do
        if state[definition.id] == true then setModule(definition.id, true) end
    end
end
suppressNotifications = false
hud.Visible = state.fps or state.coordinates or state.ping
fpsLabel.Visible = state.fps
coordLabel.Visible = state.coordinates
pingLabel.Visible = state.ping
setMenuOpen(true)
notify("Pulse Visuals", "Client loaded. Press Right Shift to toggle GUI.")

print("[Pulse Visuals] Loaded successfully. Press RightShift to open/close.")
