-- BeeSwarmAscended.lua
-- Educational Roblox Studio prototype: pollen-capacity monitor + movement-pattern demo.
-- This is NOT a verified Xeno exploit and does not automate the live game's server systems.
-- Run only in a Roblox Studio place you own or have permission to test.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

local CONFIG = {
    Pattern = "Square", -- "Square", "Circle", "Zigzag", "Spiral"
    StepDistance = 12,
    MoveSpeed = 12,
    BackpackFullPercent = 95,
}

local running = false
local moveConnection
local gui

local function makeGui()
    local pg = player:WaitForChild("PlayerGui")
    local old = pg:FindFirstChild("BSAPrototypeGui")
    if old then old:Destroy() end

    gui = Instance.new("ScreenGui")
    gui.Name = "BSAPrototypeGui"
    gui.ResetOnSpawn = false
    gui.Parent = pg

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(310, 280)
    frame.Position = UDim2.new(0, 20, 0.35, 0)
    frame.BackgroundColor3 = Color3.fromRGB(28, 32, 42)
    frame.BorderSizePixel = 0
    frame.Parent = gui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 32)
    title.Position = UDim2.fromOffset(10, 8)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextColor3 = Color3.new(1, 1, 1)
    title.Text = "Bee Swarm — movement demo"
    title.Parent = frame

    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -20, 0, 48)
    status.Position = UDim2.fromOffset(10, 42)
    status.BackgroundTransparency = 1
    status.Font = Enum.Font.Gotham
    status.TextSize = 13
    status.TextWrapped = true
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.TextYAlignment = Enum.TextYAlignment.Top
    status.TextColor3 = Color3.fromRGB(220, 225, 235)
    status.Text = "Pollen: unavailable\nCapacity: unavailable"
    status.Parent = frame

    local patternButton = Instance.new("TextButton")
    patternButton.Name = "Pattern"
    patternButton.Size = UDim2.new(1, -20, 0, 32)
    patternButton.Position = UDim2.fromOffset(10, 100)
    patternButton.BackgroundColor3 = Color3.fromRGB(61, 76, 105)
    patternButton.TextColor3 = Color3.new(1, 1, 1)
    patternButton.Font = Enum.Font.GothamSemibold
    patternButton.TextSize = 13
    patternButton.Text = "Pattern: Square (click to change)"
    patternButton.Parent = frame
    Instance.new("UICorner", patternButton).CornerRadius = UDim.new(0, 6)

    local startButton = Instance.new("TextButton")
    startButton.Name = "StartStop"
    startButton.Size = UDim2.new(1, -20, 0, 32)
    startButton.Position = UDim2.fromOffset(10, 140)
    startButton.BackgroundColor3 = Color3.fromRGB(45, 130, 85)
    startButton.TextColor3 = Color3.new(1, 1, 1)
    startButton.Font = Enum.Font.GothamSemibold
    startButton.TextSize = 13
    startButton.Text = "Start movement demo"
    startButton.Parent = frame
    Instance.new("UICorner", startButton).CornerRadius = UDim.new(0, 6)

    local note = Instance.new("TextLabel")
    note.Size = UDim2.new(1, -20, 0, 85)
    note.Position = UDim2.fromOffset(10, 182)
    note.BackgroundTransparency = 1
    note.Font = Enum.Font.Gotham
    note.TextSize = 11
    note.TextWrapped = true
    note.TextXAlignment = Enum.TextXAlignment.Left
    note.TextYAlignment = Enum.TextYAlignment.Top
    note.TextColor3 = Color3.fromRGB(175, 185, 200)
    note.Text = "Studio prototype only. It reads no Ascended-specific backpack data. Set up your own test field and server-authorized pollen/capacity values before connecting collection or conversion."
    note.Parent = frame

    local patterns = {"Square", "Circle", "Zigzag", "Spiral"}
    local patternIndex = 1
    patternButton.MouseButton1Click:Connect(function()
        patternIndex = patternIndex % #patterns + 1
        CONFIG.Pattern = patterns[patternIndex]
        patternButton.Text = "Pattern: " .. CONFIG.Pattern .. " (click to change)"
    end)

    startButton.MouseButton1Click:Connect(function()
        running = not running
        startButton.Text = running and "Stop movement demo" or "Start movement demo"
        startButton.BackgroundColor3 = running and Color3.fromRGB(165, 75, 65) or Color3.fromRGB(45, 130, 85)
    end)

    return status
end

local statusLabel = makeGui()

-- These are common possible UI labels, not guaranteed names for Ascended.
-- The game may format them differently; unknown values remain "unavailable".
local function findTextValue(root, patterns)
    for _, item in ipairs(root:GetDescendants()) do
        if item:IsA("TextLabel") or item:IsA("TextButton") then
            local name = string.lower(item.Name)
            local text = string.lower(item.Text)
            for _, pattern in ipairs(patterns) do
                if string.find(name, pattern, 1, true) or string.find(text, pattern, 1, true) then
                    local digits = item.Text:gsub(",", ""):gsub("%s", "")
                    local current, maximum = digits:match("([%d%.]+)/([%d%.]+)")
                    if current and maximum then
                        return current .. " / " .. maximum
                    end
                    local number = digits:match("([%d%.]+)")
                    if number then return number end
                end
            end
        end
    end
    return "unavailable"
end

local function getBackpackReadout()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return "unavailable", "unavailable" end
    local pollen = findTextValue(pg, {"pollen", "capacity", "backpack"})
    local capacity = findTextValue(pg, {"capacity", "backpack", "max pollen"})
    return pollen, capacity
end

local function getRoot()
    local character = player.Character
    return character and character:FindFirstChild("HumanoidRootPart"), character and character:FindFirstChildOfClass("Humanoid")
end

local function pointForPattern(t, origin)
    local d = CONFIG.StepDistance
    if CONFIG.Pattern == "Square" then
        local side = math.floor(t / 2) % 4
        local offsets = {
            Vector3.new(d, 0, 0), Vector3.new(0, 0, d),
            Vector3.new(-d, 0, 0), Vector3.new(0, 0, -d),
        }
        return origin + offsets[side + 1]
    elseif CONFIG.Pattern == "Circle" then
        local angle = t * 0.35
        return origin + Vector3.new(math.cos(angle) * d, 0, math.sin(angle) * d)
    elseif CONFIG.Pattern == "Zigzag" then
        local x = ((t % 8) - 4) * (d / 2)
        local z = math.floor(t / 8) * (d / 2)
        return origin + Vector3.new(x, 0, z)
    else -- Spiral
        local angle = t * 0.35
        local radius = math.min(d, 1 + t * 0.12)
        return origin + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
    end
end

local elapsed = 0
local step = 0
local origin

RunService.Heartbeat:Connect(function(dt)
    local pollen, capacity = getBackpackReadout()
    if statusLabel and statusLabel.Parent then
        statusLabel.Text = "Pollen: " .. pollen .. "\nCapacity: " .. capacity ..
            "\nPattern: " .. CONFIG.Pattern ..
            "\nMovement: " .. (running and "ON (demo)" or "OFF")
    end

    if not running then
        origin = nil
        elapsed = 0
        step = 0
        return
    end

    local root, humanoid = getRoot()
    if not root or not humanoid then return end
    origin = origin or root.Position
    elapsed += dt
    if elapsed < 0.35 then return end
    elapsed = 0

    local target = pointForPattern(step, origin)
    step += 1
    local flatTarget = Vector3.new(target.X, root.Position.Y, target.Z)
    humanoid:MoveTo(flatTarget)
end)
