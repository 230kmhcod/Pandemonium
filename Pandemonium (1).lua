-- PANDEMONIUM | dark/white UI template
-- RightShift: open/close menu. Visual UI only; no gameplay exploits.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

pcall(function()
    local old = playerGui:FindFirstChild("PandemoniumUI")
    if old then old:Destroy() end
end)

local C = {
    bg = Color3.fromRGB(17,17,20), panel = Color3.fromRGB(27,27,31),
    panel2 = Color3.fromRGB(40,40,46), border = Color3.fromRGB(67,67,75),
    text = Color3.fromRGB(245,245,248), muted = Color3.fromRGB(158,158,168),
    white = Color3.fromRGB(230,230,235)
}
local function corner(o, r)
    local x = Instance.new("UICorner"); x.CornerRadius = UDim.new(0,r); x.Parent = o
end
local function outline(o)
    local x = Instance.new("UIStroke"); x.Color=C.border; x.Transparency=.25; x.Parent=o
end
local function label(parent, text, size, pos, fontSize, color, font)
    local x=Instance.new("TextLabel"); x.BackgroundTransparency=1; x.Text=text
    x.Size=size; x.Position=pos; x.TextSize=fontSize or 12; x.TextColor3=color or C.text
    x.Font=font or Enum.Font.Gotham; x.TextXAlignment=Enum.TextXAlignment.Left
    x.TextYAlignment=Enum.TextYAlignment.Center; x.Parent=parent; return x
end
local function button(parent, text, size, pos)
    local x=Instance.new("TextButton"); x.Size=size; x.Position=pos; x.Text=text
    x.TextSize=12; x.Font=Enum.Font.GothamMedium; x.TextColor3=C.text
    x.BackgroundColor3=C.panel2; x.BorderSizePixel=0; x.Parent=parent; corner(x,6); return x
end

local gui=Instance.new("ScreenGui")
gui.Name="PandemoniumUI"; gui.ResetOnSpawn=false; gui.IgnoreGuiInset=true
gui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; gui.Parent=playerGui

local dim=Instance.new("Frame")
dim.Name="BackgroundDim"; dim.Size=UDim2.fromScale(1,1); dim.BackgroundColor3=Color3.new(0,0,0)
dim.BackgroundTransparency=1; dim.BorderSizePixel=0; dim.Visible=false; dim.ZIndex=1; dim.Parent=gui

local menu=Instance.new("Frame")
menu.Name="MainWindow"; menu.Size=UDim2.fromOffset(590,420); menu.AnchorPoint=Vector2.new(.5,.5)
menu.Position=UDim2.fromScale(.5,.5); menu.BackgroundColor3=C.bg; menu.BorderSizePixel=0
menu.Visible=false; menu.ZIndex=2; menu.Parent=gui; corner(menu,11); outline(menu)
local scale=Instance.new("UIScale"); scale.Scale=.97; scale.Parent=menu

local header=Instance.new("Frame")
header.Size=UDim2.new(1,0,0,52); header.BackgroundColor3=C.panel; header.BorderSizePixel=0
header.ZIndex=3; header.Parent=menu; corner(header,11)
local headerMask=Instance.new("Frame"); headerMask.Size=UDim2.new(1,0,0,12)
headerMask.Position=UDim2.new(0,0,1,-12); headerMask.BackgroundColor3=C.panel
headerMask.BorderSizePixel=0; headerMask.ZIndex=3; headerMask.Parent=header
label(header,"P",UDim2.fromOffset(25,30),UDim2.fromOffset(15,10),21,C.text,Enum.Font.GothamBlack)
label(header,"PANDEMONIUM",UDim2.fromOffset(200,22),UDim2.fromOffset(45,7),15,C.text,Enum.Font.GothamBold)
label(header,"UNIVERSAL UI  •  DARK / WHITE",UDim2.fromOffset(230,16),UDim2.fromOffset(45,28),9,C.muted,Enum.Font.GothamMedium)
local close=button(header,"×",UDim2.fromOffset(32,29),UDim2.new(1,-43,0,11))
close.TextSize=19; close.BackgroundColor3=Color3.fromRGB(59,40,42); close.ZIndex=4

local sidebar=Instance.new("Frame"); sidebar.Size=UDim2.new(0,140,1,-64)
sidebar.Position=UDim2.fromOffset(9,56); sidebar.BackgroundColor3=C.panel
sidebar.BorderSizePixel=0; sidebar.ZIndex=3; sidebar.Parent=menu; corner(sidebar,8)
label(sidebar,"NAVIGATION",UDim2.new(1,-18,0,20),UDim2.fromOffset(10,9),9,C.muted,Enum.Font.GothamBold)
local holder=Instance.new("Frame"); holder.Size=UDim2.new(1,-164,1,-68)
holder.Position=UDim2.fromOffset(154,60); holder.BackgroundTransparency=1; holder.ZIndex=3; holder.Parent=menu

local names={"Combat","Visuals","Movement","HUD Editor","Settings"}
local tabs,pages={},{}
for i,name in ipairs(names) do
    local b=button(sidebar,"   "..name,UDim2.new(1,-14,0,33),UDim2.fromOffset(7,35+(i-1)*39))
    b.TextXAlignment=Enum.TextXAlignment.Left; b.BackgroundColor3=(i==1 and C.panel2 or C.panel)
    tabs[name]=b
    local p=Instance.new("ScrollingFrame"); p.Name=name; p.Size=UDim2.fromScale(1,1)
    p.BackgroundTransparency=1; p.BorderSizePixel=0; p.ScrollBarThickness=3
    p.ScrollBarImageColor3=C.border; p.CanvasSize=UDim2.new(0,0,0,0)
    p.Visible=(i==1); p.ZIndex=3; p.Parent=holder; pages[name]=p
end

local function section(p,text,y)
    label(p,string.upper(text),UDim2.new(1,-8,0,22),UDim2.fromOffset(4,y),10,C.muted,Enum.Font.GothamBold)
end
local function card(p,title,desc,y)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,-8,0,63); f.Position=UDim2.fromOffset(4,y)
    f.BackgroundColor3=C.panel; f.BorderSizePixel=0; f.ZIndex=4; f.Parent=p; corner(f,8); outline(f)
    label(f,title,UDim2.new(1,-18,0,22),UDim2.fromOffset(10,7),12,C.text,Enum.Font.GothamSemibold)
    label(f,desc,UDim2.new(1,-18,0,24),UDim2.fromOffset(10,30),9,C.muted)
end
local function toggle(p,title,desc,y,initial,callback)
    local f=Instance.new("Frame"); f.Size=UDim2.new(1,-8,0,54); f.Position=UDim2.fromOffset(4,y)
    f.BackgroundColor3=C.panel; f.BorderSizePixel=0; f.ZIndex=4; f.Parent=p; corner(f,8); outline(f)
    label(f,title,UDim2.new(1,-75,0,21),UDim2.fromOffset(10,5),12,C.text,Enum.Font.GothamMedium)
    label(f,desc,UDim2.new(1,-75,0,17),UDim2.fromOffset(10,28),9,C.muted)
    local state=initial
    local b=button(f,state and "ON" or "OFF",UDim2.fromOffset(46,24),UDim2.new(1,-56,.5,-12))
    b.ZIndex=5; b.BackgroundColor3=state and C.white or C.panel2
    if state then b.TextColor3=C.bg end
    b.MouseButton1Click:Connect(function()
        state=not state; b.Text=state and "ON" or "OFF"
        b.BackgroundColor3=state and C.white or C.panel2
        b.TextColor3=state and C.bg or C.text
        if callback then callback(state) end
    end)
end

section(pages.Combat,"Combat modules",4)
card(pages.Combat,"Gameplay automation unavailable","This template intentionally contains UI and visual features only.",30)
card(pages.Combat,"Game compatibility","Use built-in game settings for combat behavior.",103)

local visual={Crosshair=true,Watermark=true,FPS=true,Ping=true}
local crosshair
local function updateCrosshair()
    if crosshair then crosshair:Destroy(); crosshair=nil end
    if not visual.Crosshair then return end
    crosshair=Instance.new("Frame"); crosshair.Name="PandemoniumCrosshair"
    crosshair.Size=UDim2.fromOffset(18,18); crosshair.AnchorPoint=Vector2.new(.5,.5)
    crosshair.Position=UDim2.fromScale(.5,.5); crosshair.BackgroundTransparency=1
    crosshair.ZIndex=20; crosshair.Parent=gui
    for _,v in ipairs({{UDim2.fromOffset(18,2),UDim2.fromOffset(0,8)},
                       {UDim2.fromOffset(2,18),UDim2.fromOffset(8,0)}}) do
        local line=Instance.new("Frame"); line.Size=v[1]; line.Position=v[2]
        line.BackgroundColor3=C.text; line.BorderSizePixel=0; line.ZIndex=21; line.Parent=crosshair
    end
end
section(pages.Visuals,"Screen visuals",4)
toggle(pages.Visuals,"Crosshair","Small center-screen crosshair",30,true,function(v) visual.Crosshair=v; updateCrosshair() end)
toggle(pages.Visuals,"Watermark","Show status widget in the corner",90,true,function(v) visual.Watermark=v end)
toggle(pages.Visuals,"FPS counter","Show client frame rate",150,true,function(v) visual.FPS=v end)
toggle(pages.Visuals,"Ping counter","Show latency when available",210,true,function(v) visual.Ping=v end)

section(pages.Movement,"Movement",4)
card(pages.Movement,"No movement modifications","This build leaves character movement unchanged.",30)
card(pages.Movement,"Experience-specific","Movement systems differ between Roblox games.",103)

section(pages["HUD Editor"],"HUD layout",4)
card(pages["HUD Editor"],"Move HUD widgets","Enable edit mode below, then drag the status and target cards.",30)
local editMode=false
toggle(pages["HUD Editor"],"HUD Edit Mode","Allow dragging HUD widgets",103,false,function(v) editMode=v end)

section(pages.Settings,"Interface settings",4)
card(pages.Settings,"Menu key","RightShift opens and closes the menu.",30)
card(pages.Settings,"Theme","Minimal dark gray with white accents.",103)
card(pages.Settings,"Animation","Fade + slight scale and subtle screen dim.",176)

-- Status HUD
local watermark=Instance.new("TextLabel"); watermark.Name="StatusHUD"
watermark.Size=UDim2.fromOffset(250,28); watermark.Position=UDim2.new(0,12,1,-42)
watermark.BackgroundColor3=C.bg; watermark.BackgroundTransparency=.08; watermark.BorderSizePixel=0
watermark.TextColor3=C.text; watermark.TextSize=10; watermark.Font=Enum.Font.GothamMedium
watermark.Text="PANDEMONIUM"; watermark.TextXAlignment=Enum.TextXAlignment.Left
watermark.ZIndex=10; watermark.Parent=gui; corner(watermark,7); outline(watermark)
local pad=Instance.new("UIPadding"); pad.PaddingLeft=UDim.new(0,10); pad.Parent=watermark

-- Target HUD preview, intentionally not connected to player targeting
local target=Instance.new("Frame"); target.Name="TargetHUD"; target.Size=UDim2.fromOffset(250,76)
target.Position=UDim2.new(.5,-125,.72,0); target.BackgroundColor3=C.bg
target.BackgroundTransparency=.04; target.BorderSizePixel=0; target.ZIndex=10; target.Parent=gui
corner(target,9); outline(target)
local avatar=Instance.new("Frame"); avatar.Size=UDim2.fromOffset(46,46); avatar.Position=UDim2.fromOffset(12,15)
avatar.BackgroundColor3=C.panel2; avatar.BorderSizePixel=0; avatar.ZIndex=11; avatar.Parent=target; corner(avatar,7)
local av=label(avatar,"P",UDim2.fromScale(1,1),UDim2.fromScale(0,0),22,C.text,Enum.Font.GothamBlack)
av.TextXAlignment=Enum.TextXAlignment.Center
label(target,"TARGET HUD",UDim2.new(1,-75,0,20),UDim2.fromOffset(69,10),11,C.text,Enum.Font.GothamBold)
label(target,"Preview  •  100 HP",UDim2.new(1,-75,0,17),UDim2.fromOffset(69,31),10,C.muted)
local hp=Instance.new("Frame"); hp.Size=UDim2.new(1,-82,0,6); hp.Position=UDim2.fromOffset(69,54)
hp.BackgroundColor3=C.panel2; hp.BorderSizePixel=0; hp.ZIndex=11; hp.Parent=target; corner(hp,3)
local fill=Instance.new("Frame"); fill.Size=UDim2.fromScale(1,1); fill.BackgroundColor3=C.white
fill.BorderSizePixel=0; fill.ZIndex=12; fill.Parent=hp; corner(fill,3)

-- Drag helpers
local function draggable(obj,handle,allowed)
    local dragging=false; local startInput,startPos
    handle.InputBegan:Connect(function(input)
        if allowed and not allowed() then return end
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            dragging=true; startInput=input.Position; startPos=obj.Position
            input.Changed:Connect(function()
                if input.UserInputState==Enum.UserInputState.End then dragging=false end
            end)
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch) then
            local d=input.Position-startInput
            obj.Position=UDim2.new(startPos.X.Scale,startPos.X.Offset+d.X,startPos.Y.Scale,startPos.Y.Offset+d.Y)
        end
    end)
end
draggable(menu,header)
draggable(watermark,watermark,function() return editMode end)
draggable(target,target,function() return editMode end)

local function selectTab(name)
    for n,p in pairs(pages) do
        p.Visible=(n==name)
        tabs[n].BackgroundColor3=(n==name) and C.panel2 or C.panel
    end
end
for n,b in pairs(tabs) do b.MouseButton1Click:Connect(function() selectTab(n) end) end

for _,p in pairs(pages) do
    local function resize()
        local maxY=0
        for _,child in ipairs(p:GetChildren()) do
            if child:IsA("GuiObject") then maxY=math.max(maxY,child.Position.Y.Offset+child.Size.Y.Offset) end
        end
        p.CanvasSize=UDim2.fromOffset(0,maxY+12)
    end
    p.ChildAdded:Connect(resize); task.defer(resize)
end

local opened=false
local animating=false
local function setOpen(value)
    if animating or opened==value then return end
    opened=value; animating=true
    if value then
        dim.Visible=true; menu.Visible=true
        menu.Position=UDim2.fromScale(.5,.515); scale.Scale=.965; dim.BackgroundTransparency=1
        TweenService:Create(dim,TweenInfo.new(.23,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundTransparency=.78}):Play()
        local t=TweenService:Create(menu,TweenInfo.new(.23,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Position=UDim2.fromScale(.5,.5)})
        TweenService:Create(scale,TweenInfo.new(.23,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Scale=1}):Play()
        t:Play(); t.Completed:Once(function() animating=false end)
    else
        TweenService:Create(dim,TweenInfo.new(.18),{BackgroundTransparency=1}):Play()
        local t=TweenService:Create(menu,TweenInfo.new(.18,Enum.EasingStyle.Quad,Enum.EasingDirection.In),{Position=UDim2.fromScale(.5,.515)})
        TweenService:Create(scale,TweenInfo.new(.18),{Scale=.965}):Play()
        t:Play(); t.Completed:Once(function()
            if not opened then menu.Visible=false; dim.Visible=false end
            animating=false
        end)
    end
end
close.MouseButton1Click:Connect(function() setOpen(false) end)
UIS.InputBegan:Connect(function(input,processed)
    if not processed and input.KeyCode==Enum.KeyCode.RightShift then setOpen(not opened) end
end)

local frames,elapsed,fps=0,0,0
RunService.RenderStepped:Connect(function(dt)
    frames+=1; elapsed+=dt
    if elapsed>=1 then fps=math.floor(frames/elapsed+.5); frames=0; elapsed=0 end
    if visual.Watermark then
        local bits={"PANDEMONIUM"}
        if visual.FPS then table.insert(bits,tostring(fps).." FPS") end
        if visual.Ping then
            local ping
            pcall(function()
                local net=Stats:FindFirstChild("Network")
                local items=net and net:FindFirstChild("ServerStatsItem")
                local item=items and items:FindFirstChild("Data Ping")
                if item then ping=math.floor(item:GetValue()) end
            end)
            if ping then table.insert(bits,tostring(ping).." ms") end
        end
        watermark.Text=table.concat(bits,"   |   "); watermark.Visible=true
    else
        watermark.Visible=false
    end
end)

updateCrosshair()
print("[Pandemonium] UI loaded. Press RightShift to open/close.")
