-- ================================================================
--   MM2 5v5 MILBASE  |  Silent Aim
--   script by tolopoofcpae / tolopo637883
-- ================================================================

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenSvc   = game:GetService("TweenService")
local UIS        = game:GetService("UserInputService")
local RS         = game:GetService("ReplicatedStorage")

local lp   = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")
local cam  = workspace.CurrentCamera

-- ================================================================
--  CHARACTER STATE
-- ================================================================
local char, hrp, hum

local function refreshChar(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
    hum  = c:WaitForChild("Humanoid")
end

if lp.Character then refreshChar(lp.Character) end
lp.CharacterAdded:Connect(refreshChar)

-- ================================================================
--  WEAPON LISTS  (from game file analysis)
-- ================================================================
local GUNS = {
    ["Default Gun"]=true,["Alienbeam"]=true,["Amerilaser"]=true,["Blaster"]=true,
    ["Blizzard"]=true,["Chroma Blizzard"]=true,["Chroma Raygun"]=true,
    ["Chroma Snowcannon"]=true,["Chroma Snowstorm"]=true,["Darkshot"]=true,
    ["Emeraldshot"]=true,["Evergun"]=true,["Gingerscope"]=true,
    ["Gold Xenoshot"]=true,["Silver Xenoshot"]=true,["Bronze Xenoshot"]=true,
    ["Red Xenoshot"]=true,["Cyan Xenoshot"]=true,["Harvester"]=true,
    ["Admin Harvester"]=true,["Heat"]=true,["Icebeam"]=true,
    ["Iceblaster"]=true,["Icepiercer"]=true,["Admin Icepiercer"]=true,
    ["Jinglegun"]=true,["Laser"]=true,["Light Shot"]=true,["Lightbringer"]=true,
    ["Luger"]=true,["Red Luger"]=true,["Green Luger"]=true,
    ["Ginger Luger"]=true,["Lugercane"]=true,["Ocean"]=true,["Phaser"]=true,
    ["Plasmabeam"]=true,["Raygun"]=true,["Script'o shot"]=true,
    ["Snowcannon"]=true,["Snowstorm"]=true,["Spectre"]=true,
    ["Swirly Gun"]=true,["Traveler's Gun"]=true,["Valeshot"]=true,
    ["Virtual"]=true,["Constellation"]=true,["Silver Constellation"]=true,
    ["Gold Constellation"]=true,["Bronze Constellation"]=true,
    ["Red Constellation"]=true,["Space Constellation"]=true,
    ["Cupidshot"]=true,["Gemscope"]=true,["Flowerwood Gun"]=true,
    ["Vampire's Gun"]=true,["Skibidi Spectre"]=true,["Hallowgun"]=true,
    ["Borealis"]=true,["Elderwood Revolver"]=true,["Gingerscythe"]=true,
    ["Blue Gingerscope"]=true,["Gold Gingerscope"]=true,
    ["Silver Gingerscope"]=true,["Bronze Gingerscope"]=true,
    ["Nightblade"]=true,
}

local function getEquipped()
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end
local function isGun(t)   return t and GUNS[t.Name] end
local function isKnife(t) return t and not GUNS[t.Name] end

-- ================================================================
--  NEAREST ENEMY
-- ================================================================
local function getNearestEnemy()
    if not hrp then return nil end
    local best, bd = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p == lp then continue end
        local c = p.Character
        if not c then continue end
        local h = c:FindFirstChildOfClass("Humanoid")
        if not h or h.Health <= 0 then continue end
        local r = c:FindFirstChild("HumanoidRootPart")
        if not r then continue end
        local d = (hrp.Position - r.Position).Magnitude
        if d < bd then bd = d; best = r end
    end
    return best
end

-- ================================================================
--  SA STATE
-- ================================================================
local saActive     = false
local _bypass      = false
local _gunCD       = false
local _stabCD      = false

-- ================================================================
--  __namecall HOOK
--  When SA ON: block Stab/Throw/RequestShoot from normal input.
--  Our buttons set _bypass = true before calling, so they pass.
-- ================================================================
local BLOCKED = { RequestShoot=true, Stab=true, Throw=true, FlingKnifeEvent=true }

local oldNC
oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    if saActive and not _bypass
    and getnamecallmethod() == "FireServer"
    and self:IsA("RemoteEvent")
    and BLOCKED[self.Name] then
        return nil
    end
    return oldNC(self, ...)
end))

-- ================================================================
--  SILENT GUN
--  RequestShoot:FireServer(hitPos: Vector3, shiftLockEnabled: bool, Ray)
--  We pass target.Position so the server bullet goes to the enemy.
--  Works with and without shift lock because we bypass the mouse.
-- ================================================================
local function silentGun()
    if _gunCD then return end
    local target = getNearestEnemy()
    if not target then return end

    -- RemoteStorage path confirmed in file
    local remote = RS
        :FindFirstChild("Remotes")
        and RS.Remotes:FindFirstChild("WeaponRemotes")
        and RS.Remotes.WeaponRemotes:FindFirstChild("RequestShoot")
    if not remote then return end

    -- Read shift-lock state exactly as the original script does
    local ml = lp.PlayerScripts:FindFirstChild("MouseLock")
    local mlEnabled = ml and ml:GetAttribute("Enabled") or false

    -- Screen ray from crosshair centre (same as original)
    local vp = cam.ViewportSize
    local screenRay = cam:ScreenPointToRay(vp.X / 2, vp.Y / 2)

    _bypass = true
    pcall(function()
        remote:FireServer(target.Position, mlEnabled, screenRay)
    end)
    _bypass = false

    _gunCD = true
    task.delay(0.55, function() _gunCD = false end)
end

-- ================================================================
--  SILENT STAB
--  Stab:FireServer(1) — server checks proximity.
--  We teleport to the enemy briefly, fire, then return.
--  Works with shift lock: we modify HRP.CFrame directly.
-- ================================================================
local function silentStab()
    if _stabCD then return end
    local tool = getEquipped()
    if not tool then return end
    local stabRE = tool:FindFirstChild("Stab")
    if not stabRE then return end
    local target = getNearestEnemy()
    if not target or not hrp then return end

    _stabCD = true
    local origCF = hrp.CFrame

    _bypass = true
    pcall(function()
        hrp.CFrame = target.CFrame * CFrame.new(0, 0, 2.5)
        task.wait()
        stabRE:FireServer(1)
    end)
    _bypass = false

    task.delay(0.12, function()
        pcall(function() if hrp then hrp.CFrame = origCF end)
    end)
    task.delay(1.25, function() _stabCD = false end)
end

-- ================================================================
--  SILENT THROW  (Throw button — uses the throw remote instead)
--  Throw:FireServer(CFrame targetPos, Vector3 handlePos)
-- ================================================================
local function silentThrow()
    if _stabCD then return end
    local tool = getEquipped()
    if not tool then return end
    local throwRE = tool:FindFirstChild("Throw")
    local handle  = tool:FindFirstChild("Handle")
    if not throwRE or not handle then return end
    local target = getNearestEnemy()
    if not target then return end

    _stabCD = true
    _bypass = true
    pcall(function()
        throwRE:FireServer(CFrame.new(target.Position), handle.Position)
    end)
    _bypass = false
    task.delay(2.2, function() _stabCD = false end)
end

lp.CharacterAdded:Connect(function(c)
    refreshChar(c)
    _bypass = false; _gunCD = false; _stabCD = false
end)

-- ================================================================
-- ================================================================
--  LOADING SCREEN
-- ================================================================
-- ================================================================

local LoadGui = Instance.new("ScreenGui")
LoadGui.Name           = "MM2_Load"
LoadGui.ResetOnSpawn   = false
LoadGui.IgnoreGuiInset = true
LoadGui.DisplayOrder   = 9999
LoadGui.Parent         = pgui

-- Dark background
local BG = Instance.new("Frame", LoadGui)
BG.Size = UDim2.new(1,0,1,0)
BG.BackgroundColor3 = Color3.fromRGB(4, 4, 10)
BG.BorderSizePixel  = 0

-- Animated gradient overlay (moves left-right)
local gradHolder = Instance.new("Frame", BG)
gradHolder.Size = UDim2.new(3,0,1,0)
gradHolder.Position = UDim2.new(-1,0,0,0)
gradHolder.BackgroundTransparency = 1
gradHolder.BorderSizePixel = 0
gradHolder.ZIndex = 2

local uig = Instance.new("UIGradient", gradHolder)
uig.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(4,4,10)),
    ColorSequenceKeypoint.new(0.25, Color3.fromRGB(0,20,55)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0,60,130)),
    ColorSequenceKeypoint.new(0.75, Color3.fromRGB(0,20,55)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(4,4,10)),
})
uig.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0.9),
    NumberSequenceKeypoint.new(0.5, 0.3),
    NumberSequenceKeypoint.new(1, 0.9),
})
uig.Rotation = 0

-- Move gradient
task.spawn(function()
    local t = 0
    while LoadGui.Parent do
        t += 0.008
        gradHolder.Position = UDim2.new(-1 + math.sin(t)*0.4, 0, 0, 0)
        uig.Rotation = math.sin(t*0.4)*25
        RunService.RenderStepped:Wait()
    end
end)

-- Horizontal scan lines
for i = 0, 30 do
    local sl = Instance.new("Frame", BG)
    sl.Size = UDim2.new(1,0,0,1)
    sl.Position = UDim2.new(0,0,i/30,0)
    sl.BackgroundColor3 = Color3.fromRGB(0,100,220)
    sl.BackgroundTransparency = 0.88
    sl.BorderSizePixel = 0
    sl.ZIndex = 3
end

-- Floating particles
local function spawnDot()
    local p = Instance.new("Frame", BG)
    local s = math.random(4,16)
    p.Size = UDim2.new(0,s,0,s)
    p.AnchorPoint = Vector2.new(0.5,0.5)
    local startX = math.random(5, 95)/100
    p.Position = UDim2.new(startX, 0, 1.1, 0)
    p.BackgroundColor3 = Color3.fromRGB(
        math.random(0,40),
        math.random(100,200),
        255
    )
    p.BackgroundTransparency = math.random(40,70)/100
    p.BorderSizePixel = 0
    p.ZIndex = 4
    Instance.new("UICorner", p).CornerRadius = UDim.new(1,0)

    local tw = TweenSvc:Create(p, TweenInfo.new(
        math.random(25,55)/10, Enum.EasingStyle.Linear
    ), {
        Position = UDim2.new(startX + (math.random()-0.5)*0.25, 0, -0.15, 0),
        BackgroundTransparency = 1,
    })
    tw:Play()
    tw.Completed:Connect(function() p:Destroy() end)
end

task.spawn(function()
    while LoadGui.Parent do
        spawnDot()
        task.wait(math.random(8, 20)/100)
    end
end)

-- Corner brackets
local corners = {
    {a=Vector2.new(0,0), p=UDim2.new(0,10,0,10)},
    {a=Vector2.new(1,0), p=UDim2.new(1,-10,0,10)},
    {a=Vector2.new(0,1), p=UDim2.new(0,10,1,-10)},
    {a=Vector2.new(1,1), p=UDim2.new(1,-10,1,-10)},
}
for _, c in ipairs(corners) do
    local f = Instance.new("Frame", BG)
    f.Size = UDim2.new(0,60,0,60)
    f.AnchorPoint = c.a
    f.Position = c.p
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.ZIndex = 5
    local st = Instance.new("UIStroke", f)
    st.Color = Color3.fromRGB(0,140,255)
    st.Thickness = 2
    TweenSvc:Create(st, TweenInfo.new(1.1, Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut, -1, true), {Transparency=0.85}):Play()
end

-- ── CENTER CARD ──────────────────────────────────────────────────
local Card = Instance.new("Frame", BG)
Card.Size = UDim2.new(0,510,0,290)
Card.AnchorPoint = Vector2.new(0.5,0.5)
Card.Position = UDim2.new(0.5,0, 1.8, 0)   -- starts below screen
Card.BackgroundColor3 = Color3.fromRGB(6,10,22)
Card.BackgroundTransparency = 0.25
Card.BorderSizePixel = 0
Card.ZIndex = 6
Instance.new("UICorner", Card).CornerRadius = UDim.new(0,18)

local cardStroke = Instance.new("UIStroke", Card)
cardStroke.Color = Color3.fromRGB(0,140,255)
cardStroke.Thickness = 1.8
cardStroke.Transparency = 0.2

-- Card gradient
local cg = Instance.new("UIGradient", Card)
cg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,15,40)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,35,75)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,15,40)),
})
cg.Rotation = 95

task.spawn(function()
    local t = 0
    while LoadGui.Parent do
        t += 0.012
        cg.Rotation = 95 + math.sin(t)*28
        RunService.RenderStepped:Wait()
    end
end)

-- Top accent line
local accent = Instance.new("Frame", Card)
accent.Size = UDim2.new(0,0,0,3)
accent.Position = UDim2.new(0.5,0,0,0)
accent.AnchorPoint = Vector2.new(0.5,0)
accent.BackgroundColor3 = Color3.fromRGB(0,180,255)
accent.BorderSizePixel = 0
accent.ZIndex = 7
Instance.new("UICorner", accent).CornerRadius = UDim.new(0,2)

TweenSvc:Create(accent, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
    Size = UDim2.new(0.85,0,0,3),
}):Play()

-- Badge text
local badge = Instance.new("TextLabel", Card)
badge.Size = UDim2.new(1,0,0,22)
badge.Position = UDim2.new(0,0,0,14)
badge.BackgroundTransparency = 1
badge.Text = "▸  EXCLUSIVE SCRIPT  •  DELTA COMPATIBLE  ◂"
badge.TextColor3 = Color3.fromRGB(0,160,255)
badge.Font = Enum.Font.GothamBold
badge.TextSize = 11
badge.ZIndex = 7

-- Main title
local titleLabel = Instance.new("TextLabel", Card)
titleLabel.Size = UDim2.new(1,-30,0,68)
titleLabel.Position = UDim2.new(0,15,0,38)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = ""
titleLabel.TextColor3 = Color3.fromRGB(255,255,255)
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextSize = 44
titleLabel.ZIndex = 7

local titleGrad = Instance.new("UIGradient", titleLabel)
titleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,200,255)),
    ColorSequenceKeypoint.new(0.45, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,200,255)),
})
titleGrad.Rotation = 0
task.spawn(function()
    local t = 0
    while LoadGui.Parent do
        t += 0.018
        titleGrad.Rotation = math.sin(t)*18
        RunService.RenderStepped:Wait()
    end
end)

local titleStroke = Instance.new("UIStroke", titleLabel)
titleStroke.Color = Color3.fromRGB(0,150,255)
titleStroke.Thickness = 1.8
titleStroke.Transparency = 0.45

-- Subtitle
local subLabel = Instance.new("TextLabel", Card)
subLabel.Size = UDim2.new(1,-30,0,24)
subLabel.Position = UDim2.new(0,15,0,108)
subLabel.BackgroundTransparency = 1
subLabel.Text = "5v5  MILBASE  •  SILENT  AIM  EDITION"
subLabel.TextColor3 = Color3.fromRGB(80,160,255)
subLabel.Font = Enum.Font.GothamBold
subLabel.TextSize = 15
subLabel.ZIndex = 7

-- Divider
local divider = Instance.new("Frame", Card)
divider.Size = UDim2.new(0,0,0,1)
divider.Position = UDim2.new(0.075,0,0,142)
divider.BackgroundColor3 = Color3.fromRGB(0,140,255)
divider.BackgroundTransparency = 0.4
divider.BorderSizePixel = 0
divider.ZIndex = 7
TweenSvc:Create(divider, TweenInfo.new(1.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
    Size = UDim2.new(0.85,0,0,1),
}):Play()

-- Credit
local credLabel = Instance.new("TextLabel", Card)
credLabel.Size = UDim2.new(1,-30,0,20)
credLabel.Position = UDim2.new(0,15,0,152)
credLabel.BackgroundTransparency = 1
credLabel.Text = "script by tolopoofcpae / tolopo637883"
credLabel.TextColor3 = Color3.fromRGB(120,180,255)
credLabel.Font = Enum.Font.Gotham
credLabel.TextSize = 12
credLabel.ZIndex = 7

-- Status
local statusLabel = Instance.new("TextLabel", Card)
statusLabel.Size = UDim2.new(1,-30,0,20)
statusLabel.Position = UDim2.new(0,15,0,180)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Inicializando..."
statusLabel.TextColor3 = Color3.fromRGB(60,140,255)
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextSize = 11
statusLabel.ZIndex = 7

-- Progress bar
local pbBG = Instance.new("Frame", Card)
pbBG.Size = UDim2.new(0.85,0,0,7)
pbBG.Position = UDim2.new(0.075,0,0,208)
pbBG.BackgroundColor3 = Color3.fromRGB(8,20,42)
pbBG.BorderSizePixel = 0
pbBG.ZIndex = 7
Instance.new("UICorner", pbBG).CornerRadius = UDim.new(1,0)

local pbFill = Instance.new("Frame", pbBG)
pbFill.Size = UDim2.new(0,0,1,0)
pbFill.BackgroundColor3 = Color3.fromRGB(0,180,255)
pbFill.BorderSizePixel = 0
pbFill.ZIndex = 8
Instance.new("UICorner", pbFill).CornerRadius = UDim.new(1,0)
Instance.new("UIGradient", pbFill).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,120,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120,230,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,180,255)),
})

-- Tag line
local tagLabel = Instance.new("TextLabel", Card)
tagLabel.Size = UDim2.new(1,-30,0,18)
tagLabel.Position = UDim2.new(0,15,0,226)
tagLabel.BackgroundTransparency = 1
tagLabel.Text = "v1.0  •  SHIFT LOCK SUPPORT  •  MOBILE READY"
tagLabel.TextColor3 = Color3.fromRGB(35,65,120)
tagLabel.Font = Enum.Font.Gotham
tagLabel.TextSize = 10
tagLabel.ZIndex = 7

-- Slide card up from bottom
TweenSvc:Create(Card, TweenInfo.new(0.8, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5,0, 0.5, 0),
}):Play()

-- Typewriter title
task.spawn(function()
    task.wait(0.5)
    local txt = "MM2 5v5 Milbase"
    for i = 1, #txt do
        titleLabel.Text = txt:sub(1,i)
        task.wait(0.055)
    end
end)

-- Loading stages
local stages = {
    {0.18, "Carregando hooks..."},
    {0.36, "Analisando remotes..."},
    {0.54, "Montando sistema de armas..."},
    {0.70, "Preparando botões mobile..."},
    {0.86, "Aplicando shift-lock patch..."},
    {0.96, "Quase lá..."},
    {1.00, "Pronto!"},
}
task.spawn(function()
    task.wait(0.3)
    for _, s in ipairs(stages) do
        task.wait(0.44)
        statusLabel.Text = s[2]
        TweenSvc:Create(pbFill, TweenInfo.new(0.38, Enum.EasingStyle.Cubic), {
            Size = UDim2.new(s[1],0,1,0),
        }):Play()
    end
end)

task.wait(4.6)

-- Fade out
local fadeF = Instance.new("Frame", LoadGui)
fadeF.Size = UDim2.new(1,0,1,0)
fadeF.BackgroundColor3 = Color3.fromRGB(0,0,0)
fadeF.BackgroundTransparency = 1
fadeF.BorderSizePixel = 0
fadeF.ZIndex = 999
TweenSvc:Create(fadeF, TweenInfo.new(0.6, Enum.EasingStyle.Linear), {
    BackgroundTransparency = 0,
}):Play()
task.wait(0.65)
LoadGui:Destroy()

-- ================================================================
-- ================================================================
--  CUSTOM KEY GUI  — slides up from bottom
-- ================================================================
-- ================================================================

local CORRECT_KEY = "TopoOp-ofc_mohd"
local keyPassed   = false

local KeyGui = Instance.new("ScreenGui")
KeyGui.Name           = "MM2_Key"
KeyGui.ResetOnSpawn   = false
KeyGui.IgnoreGuiInset = true
KeyGui.DisplayOrder   = 8000
KeyGui.Parent         = pgui

-- Dark tinted BG
local keyBG = Instance.new("Frame", KeyGui)
keyBG.Size = UDim2.new(1,0,1,0)
keyBG.BackgroundColor3 = Color3.fromRGB(0,0,0)
keyBG.BackgroundTransparency = 0.55
keyBG.BorderSizePixel = 0
keyBG.ZIndex = 1

-- The panel
local Panel = Instance.new("Frame", KeyGui)
Panel.Size = UDim2.new(0,440,0,320)
Panel.AnchorPoint = Vector2.new(0.5,1)
Panel.Position = UDim2.new(0.5,0, 1.6, 0)  -- starts below screen
Panel.BackgroundColor3 = Color3.fromRGB(5,8,20)
Panel.BackgroundTransparency = 0.05
Panel.BorderSizePixel = 0
Panel.ZIndex = 2
Instance.new("UICorner", Panel).CornerRadius = UDim.new(0,20)

local panelStroke = Instance.new("UIStroke", Panel)
panelStroke.Color = Color3.fromRGB(0,150,255)
panelStroke.Thickness = 2

-- Panel gradient
local pg = Instance.new("UIGradient", Panel)
pg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,12,35)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,30,65)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,12,35)),
})
pg.Rotation = 120

task.spawn(function()
    local t = 0
    while KeyGui.Parent do
        t += 0.015
        pg.Rotation = 120 + math.sin(t)*20
        RunService.RenderStepped:Wait()
    end
end)

-- Top glow line
local topGlow = Instance.new("Frame", Panel)
topGlow.Size = UDim2.new(0.7,0,0,3)
topGlow.AnchorPoint = Vector2.new(0.5,0)
topGlow.Position = UDim2.new(0.5,0,0,0)
topGlow.BackgroundColor3 = Color3.fromRGB(0,200,255)
topGlow.BorderSizePixel = 0
topGlow.ZIndex = 3
Instance.new("UICorner", topGlow).CornerRadius = UDim.new(1,0)
TweenSvc:Create(topGlow, TweenInfo.new(0.8, Enum.EasingStyle.Sine,
    Enum.EasingDirection.InOut,-1,true), {
    BackgroundColor3 = Color3.fromRGB(0,100,200),
}):Play()

-- Lock icon
local lockIcon = Instance.new("TextLabel", Panel)
lockIcon.Size = UDim2.new(0,54,0,54)
lockIcon.AnchorPoint = Vector2.new(0.5,0)
lockIcon.Position = UDim2.new(0.5,0,0,18)
lockIcon.BackgroundColor3 = Color3.fromRGB(0,40,90)
lockIcon.BackgroundTransparency = 0.3
lockIcon.Text = "🔐"
lockIcon.TextSize = 26
lockIcon.Font = Enum.Font.GothamBold
lockIcon.ZIndex = 3
Instance.new("UICorner", lockIcon).CornerRadius = UDim.new(1,0)
Instance.new("UIStroke", lockIcon).Color = Color3.fromRGB(0,140,255)

-- Title
local keyTitle = Instance.new("TextLabel", Panel)
keyTitle.Size = UDim2.new(1,-30,0,30)
keyTitle.Position = UDim2.new(0,15,0,82)
keyTitle.BackgroundTransparency = 1
keyTitle.Text = "MM2  5v5  MILBASE"
keyTitle.TextColor3 = Color3.fromRGB(255,255,255)
keyTitle.Font = Enum.Font.GothamBlack
keyTitle.TextSize = 22
keyTitle.ZIndex = 3

local ktg = Instance.new("UIGradient", keyTitle)
ktg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,200,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,240,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,200,255)),
})
task.spawn(function()
    local t=0
    while KeyGui.Parent do
        t+=0.02
        ktg.Rotation = math.sin(t)*15
        RunService.RenderStepped:Wait()
    end
end)

-- Subtitle
local keySubtitle = Instance.new("TextLabel", Panel)
keySubtitle.Size = UDim2.new(1,-30,0,20)
keySubtitle.Position = UDim2.new(0,15,0,114)
keySubtitle.BackgroundTransparency = 1
keySubtitle.Text = "Insira a key para continuar"
keySubtitle.TextColor3 = Color3.fromRGB(80,150,220)
keySubtitle.Font = Enum.Font.Gotham
keySubtitle.TextSize = 13
keySubtitle.ZIndex = 3

-- Where to get key
local whereLabel = Instance.new("TextLabel", Panel)
whereLabel.Size = UDim2.new(1,-30,0,18)
whereLabel.Position = UDim2.new(0,15,0,136)
whereLabel.BackgroundTransparency = 1
whereLabel.Text = "📌  Pega a key grátis no  scriptblox.com"
whereLabel.TextColor3 = Color3.fromRGB(55,110,190)
whereLabel.Font = Enum.Font.Gotham
whereLabel.TextSize = 11
whereLabel.ZIndex = 3

-- Input box bg
local inputBG = Instance.new("Frame", Panel)
inputBG.Size = UDim2.new(1,-40,0,46)
inputBG.Position = UDim2.new(0,20,0,166)
inputBG.BackgroundColor3 = Color3.fromRGB(0,15,38)
inputBG.BackgroundTransparency = 0
inputBG.BorderSizePixel = 0
inputBG.ZIndex = 3
Instance.new("UICorner", inputBG).CornerRadius = UDim.new(0,10)
local inputStroke = Instance.new("UIStroke", inputBG)
inputStroke.Color = Color3.fromRGB(0,100,200)
inputStroke.Thickness = 1.5

-- Actual TextBox
local textBox = Instance.new("TextBox", inputBG)
textBox.Size = UDim2.new(1,-16,1,0)
textBox.Position = UDim2.new(0,8,0,0)
textBox.BackgroundTransparency = 1
textBox.Text = ""
textBox.PlaceholderText = "Cole a key aqui..."
textBox.PlaceholderColor3 = Color3.fromRGB(50,80,130)
textBox.TextColor3 = Color3.fromRGB(200,230,255)
textBox.Font = Enum.Font.GothamBold
textBox.TextSize = 15
textBox.ClearTextOnFocus = false
textBox.ZIndex = 4

-- Focus glow
textBox.Focused:Connect(function()
    TweenSvc:Create(inputStroke, TweenInfo.new(0.2), {
        Color = Color3.fromRGB(0,200,255), Thickness=2,
    }):Play()
end)
textBox.FocusLost:Connect(function()
    TweenSvc:Create(inputStroke, TweenInfo.new(0.2), {
        Color = Color3.fromRGB(0,100,200), Thickness=1.5,
    }):Play()
end)

-- Status message under input
local keyStatus = Instance.new("TextLabel", Panel)
keyStatus.Size = UDim2.new(1,-30,0,18)
keyStatus.Position = UDim2.new(0,15,0,218)
keyStatus.BackgroundTransparency = 1
keyStatus.Text = ""
keyStatus.TextColor3 = Color3.fromRGB(255,80,80)
keyStatus.Font = Enum.Font.GothamBold
keyStatus.TextSize = 12
keyStatus.ZIndex = 3

-- Confirm button
local confirmBtn = Instance.new("TextButton", Panel)
confirmBtn.Size = UDim2.new(1,-40,0,44)
confirmBtn.Position = UDim2.new(0,20,0,244)
confirmBtn.Text = "CONFIRMAR  KEY"
confirmBtn.TextColor3 = Color3.fromRGB(255,255,255)
confirmBtn.Font = Enum.Font.GothamBlack
confirmBtn.TextSize = 15
confirmBtn.BackgroundColor3 = Color3.fromRGB(0,80,200)
confirmBtn.BorderSizePixel = 0
confirmBtn.ZIndex = 3
Instance.new("UICorner", confirmBtn).CornerRadius = UDim.new(0,10)

local confirmGrad = Instance.new("UIGradient", confirmBtn)
confirmGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,100,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,60,200)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,100,255)),
})
confirmGrad.Rotation = 90
Instance.new("UIStroke", confirmBtn).Color = Color3.fromRGB(0,160,255)

-- Button press effect
confirmBtn.MouseButton1Down:Connect(function()
    TweenSvc:Create(confirmBtn, TweenInfo.new(0.07), {
        BackgroundColor3 = Color3.fromRGB(0,50,150),
        Size = UDim2.new(1,-48,0,41),
        Position = UDim2.new(0,24,0,246),
    }):Play()
end)

-- Slide up animation
TweenSvc:Create(Panel, TweenInfo.new(0.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5,0, 0.5, 0),
    AnchorPoint = Vector2.new(0.5,0.5),
}):Play()

-- Validate key
local function validateKey()
    TweenSvc:Create(confirmBtn, TweenInfo.new(0.1), {
        BackgroundColor3 = Color3.fromRGB(0,80,200),
        Size = UDim2.new(1,-40,0,44),
        Position = UDim2.new(0,20,0,244),
    }):Play()

    local entered = textBox.Text:gsub("%s","")

    if entered == CORRECT_KEY then
        keyPassed = true
        confirmBtn.Text = "✓  KEY CORRETA!"
        confirmBtn.BackgroundColor3 = Color3.fromRGB(0,160,60)
        keyStatus.Text = ""
        -- Slide panel down and destroy
        TweenSvc:Create(Panel, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Position = UDim2.new(0.5,0, 1.6, 0),
            AnchorPoint = Vector2.new(0.5,0.5),
        }):Play()
        TweenSvc:Create(keyBG, TweenInfo.new(0.55), {
            BackgroundTransparency = 1,
        }):Play()
        task.delay(0.6, function() KeyGui:Destroy() end)
    else
        keyStatus.Text = "✗  Key incorreta. Tente novamente."
        keyStatus.TextColor3 = Color3.fromRGB(255,80,80)
        -- Shake panel
        local origPos = Panel.Position
        task.spawn(function()
            for i = 1, 5 do
                TweenSvc:Create(Panel, TweenInfo.new(0.04), {
                    Position = UDim2.new(0.5, (i%2==0 and 12 or -12), 0.5, 0),
                }):Play()
                task.wait(0.04)
            end
            Panel.Position = origPos
        end)
        -- Red flash on input
        TweenSvc:Create(inputStroke, TweenInfo.new(0.1), {
            Color = Color3.fromRGB(255,50,50),
        }):Play()
        task.delay(0.6, function()
            TweenSvc:Create(inputStroke, TweenInfo.new(0.2), {
                Color = Color3.fromRGB(0,100,200),
            }):Play()
        end)
    end
end

confirmBtn.MouseButton1Up:Connect(validateKey)
textBox.FocusLost:Connect(function(enter)
    if enter then validateKey() end
end)

-- Wait until key is passed
repeat task.wait(0.1) until keyPassed

-- ================================================================
-- ================================================================
--  MOBILE BUTTONS
-- ================================================================
-- ================================================================

local BtnGui = Instance.new("ScreenGui")
BtnGui.Name           = "MM2_SA_Btns"
BtnGui.ResetOnSpawn   = false
BtnGui.IgnoreGuiInset = true
BtnGui.DisplayOrder   = 500
BtnGui.Parent         = pgui

-- ── Round button factory ─────────────────────────────────────────
-- Design: outer black-transparent ring with dark stroke
--         invisible gap layer (transparent)
--         inner black-transparent circle
--         label in center
local function makeBtn(opts)
    local sz     = opts.sz     or 74
    local pos    = opts.pos    or UDim2.new(0.5,0,0.5,0)
    local txt    = opts.txt    or "?"
    local tcol   = opts.tcol   or Color3.fromRGB(255,255,255)
    local scol   = opts.scol   or Color3.fromRGB(25,25,25)
    local drag   = opts.drag   ~= false

    -- Outer ring frame
    local outer = Instance.new("Frame", BtnGui)
    outer.Size = UDim2.new(0,sz,0,sz)
    outer.AnchorPoint = Vector2.new(0.5,0.5)
    outer.Position = pos
    outer.BackgroundColor3 = Color3.fromRGB(0,0,0)
    outer.BackgroundTransparency = 0.68
    outer.BorderSizePixel = 0
    outer.ZIndex = 10
    Instance.new("UICorner", outer).CornerRadius = UDim.new(1,0)
    local stroke = Instance.new("UIStroke", outer)
    stroke.Color = scol
    stroke.Thickness = 2.2

    -- Gap (pure transparent, acts as visual spacing)
    local gap = Instance.new("Frame", outer)
    gap.Size = UDim2.new(0,sz-12,0,sz-12)
    gap.AnchorPoint = Vector2.new(0.5,0.5)
    gap.Position = UDim2.new(0.5,0,0.5,0)
    gap.BackgroundTransparency = 1
    gap.BorderSizePixel = 0
    gap.ZIndex = 11
    Instance.new("UICorner", gap).CornerRadius = UDim.new(1,0)

    -- Inner circle
    local inner = Instance.new("Frame", outer)
    inner.Size = UDim2.new(0,sz-17,0,sz-17)
    inner.AnchorPoint = Vector2.new(0.5,0.5)
    inner.Position = UDim2.new(0.5,0,0.5,0)
    inner.BackgroundColor3 = Color3.fromRGB(0,0,0)
    inner.BackgroundTransparency = 0.52
    inner.BorderSizePixel = 0
    inner.ZIndex = 12
    Instance.new("UICorner", inner).CornerRadius = UDim.new(1,0)

    -- Label
    local lbl = Instance.new("TextLabel", inner)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.TextColor3 = tcol
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.ZIndex = 13

    -- Invisible hit button
    local btn = Instance.new("TextButton", outer)
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 14
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1,0)

    -- Drag
    if drag then
        local dg, ds, dp = false, nil, nil
        btn.InputBegan:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Touch
            or i.UserInputType==Enum.UserInputType.MouseButton1 then
                dg=true; ds=i.Position; dp=outer.Position
            end
        end)
        btn.InputChanged:Connect(function(i)
            if dg and (i.UserInputType==Enum.UserInputType.Touch
            or i.UserInputType==Enum.UserInputType.MouseMovement) then
                local d = i.Position - ds
                outer.Position = UDim2.new(
                    dp.X.Scale, dp.X.Offset+d.X,
                    dp.Y.Scale, dp.Y.Offset+d.Y)
            end
        end)
        btn.InputEnded:Connect(function(i)
            if i.UserInputType==Enum.UserInputType.Touch
            or i.UserInputType==Enum.UserInputType.MouseButton1 then
                dg=false
            end
        end)
    end

    -- Press shrink
    btn.MouseButton1Down:Connect(function()
        TweenSvc:Create(outer, TweenInfo.new(0.07,Enum.EasingStyle.Quad), {
            Size=UDim2.new(0,sz*0.88,0,sz*0.88)
        }):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenSvc:Create(outer, TweenInfo.new(0.14,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {
            Size=UDim2.new(0,sz,0,sz)
        }):Play()
    end)

    return {f=outer, btn=btn, lbl=lbl, inner=inner, stroke=stroke}
end

-- ── BUTTON 1: SA toggle (draggable, left side) ───────────────────
local saBtn = makeBtn({
    txt  = "SA\nOFF",
    sz   = 78,
    pos  = UDim2.new(0,90,0,570),
    tcol = Color3.fromRGB(255,80,60),
    scol = Color3.fromRGB(20,20,20),
    drag = true,
})

saBtn.btn.MouseButton1Up:Connect(function()
    saActive = not saActive
    if saActive then
        saBtn.lbl.Text       = "SA\nON"
        saBtn.lbl.TextColor3 = Color3.fromRGB(80,255,100)
        saBtn.inner.BackgroundColor3 = Color3.fromRGB(0,25,0)
        saBtn.stroke.Color   = Color3.fromRGB(0,90,0)
    else
        saBtn.lbl.Text       = "SA\nOFF"
        saBtn.lbl.TextColor3 = Color3.fromRGB(255,80,60)
        saBtn.inner.BackgroundColor3 = Color3.fromRGB(0,0,0)
        saBtn.stroke.Color   = Color3.fromRGB(20,20,20)
    end
end)

-- ── BUTTON 2: Stab / Throw (draggable, above SA) ─────────────────
local knifeBtn = makeBtn({
    txt  = "FACA",
    sz   = 74,
    pos  = UDim2.new(0,90,0,485),
    tcol = Color3.fromRGB(180,200,255),
    scol = Color3.fromRGB(20,20,20),
    drag = true,
})

knifeBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then return end
    local tool = getEquipped()
    if not tool or not isKnife(tool) then return end

    -- Try stab first, fallback to throw
    if tool:FindFirstChild("Stab") then
        silentStab()
    elseif tool:FindFirstChild("Throw") then
        silentThrow()
    end
end)

-- ── BUTTON 3: Gun (fixed, bottom-right near Jump) ────────────────
-- NOT draggable, placed near the jump button area
local gunBtn = makeBtn({
    txt  = "GUN",
    sz   = 80,
    pos  = UDim2.new(1,-85,1,-105),
    tcol = Color3.fromRGB(255,210,0),
    scol = Color3.fromRGB(20,20,20),
    drag = false,
})

gunBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then return end
    local tool = getEquipped()
    if not tool or not isGun(tool) then return end
    silentGun()
end)

-- ── Glow the active weapon button ────────────────────────────────
task.spawn(function()
    while true do
        task.wait(0.08)
        local tool = getEquipped()
        if saActive and tool and isKnife(tool) then
            knifeBtn.stroke.Color = Color3.fromRGB(80,100,255)
        else
            knifeBtn.stroke.Color = Color3.fromRGB(20,20,20)
        end
        if saActive and tool and isGun(tool) then
            gunBtn.stroke.Color = Color3.fromRGB(255,180,0)
        else
            gunBtn.stroke.Color = Color3.fromRGB(20,20,20)
        end
    end
end)

-- ── Slide buttons in from bottom ─────────────────────────────────
-- They start off-screen and slide in
for _, b in ipairs({saBtn, knifeBtn, gunBtn}) do
    local orig = b.f.Position
    b.f.Position = UDim2.new(orig.X.Scale, orig.X.Offset, orig.Y.Scale+0.4, orig.Y.Offset)
    TweenSvc:Create(b.f, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = orig,
    }):Play()
    task.wait(0.1)
end
