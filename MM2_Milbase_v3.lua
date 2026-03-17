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

-- Char refs
local char, hrp, hum
local function refreshChar(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
    hum  = c:WaitForChild("Humanoid")
end
if lp.Character then refreshChar(lp.Character) end
lp.CharacterAdded:Connect(refreshChar)

-- Gun list
local GUNS = {
    ["Default Gun"]=true,["Alienbeam"]=true,["Amerilaser"]=true,
    ["Blaster"]=true,["Blizzard"]=true,["Chroma Blizzard"]=true,
    ["Chroma Raygun"]=true,["Chroma Snowcannon"]=true,["Chroma Snowstorm"]=true,
    ["Darkshot"]=true,["Emeraldshot"]=true,["Evergun"]=true,
    ["Gingerscope"]=true,["Gold Xenoshot"]=true,["Silver Xenoshot"]=true,
    ["Bronze Xenoshot"]=true,["Red Xenoshot"]=true,["Cyan Xenoshot"]=true,
    ["Harvester"]=true,["Admin Harvester"]=true,["Heat"]=true,
    ["Icebeam"]=true,["Iceblaster"]=true,["Icepiercer"]=true,
    ["Admin Icepiercer"]=true,["Jinglegun"]=true,["Laser"]=true,
    ["Light Shot"]=true,["Lightbringer"]=true,["Luger"]=true,
    ["Red Luger"]=true,["Green Luger"]=true,["Ginger Luger"]=true,
    ["Lugercane"]=true,["Ocean"]=true,["Phaser"]=true,["Plasmabeam"]=true,
    ["Raygun"]=true,["Script'o shot"]=true,["Snowcannon"]=true,
    ["Snowstorm"]=true,["Spectre"]=true,["Swirly Gun"]=true,
    ["Traveler's Gun"]=true,["Valeshot"]=true,["Virtual"]=true,
    ["Constellation"]=true,["Silver Constellation"]=true,
    ["Gold Constellation"]=true,["Bronze Constellation"]=true,
    ["Red Constellation"]=true,["Space Constellation"]=true,
    ["Cupidshot"]=true,["Gemscope"]=true,["Flowerwood Gun"]=true,
    ["Vampire's Gun"]=true,["Skibidi Spectre"]=true,["Hallowgun"]=true,
    ["Borealis"]=true,["Elderwood Revolver"]=true,["Nightblade"]=true,
    ["Blue Gingerscope"]=true,["Gold Gingerscope"]=true,
    ["Silver Gingerscope"]=true,["Bronze Gingerscope"]=true,
}

local function getEquipped()
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end
local function isGun(t)   return t and GUNS[t.Name] == true end
local function isKnife(t) return t and not GUNS[t.Name] end

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

-- SA state
local saActive = false
local _bypass  = false
local _gunCD   = false
local _stabCD  = false

-- ================================================================
-- ACTION FUNCTIONS (defined now, hook applied after key)
-- ================================================================

local function silentGun()
    if _gunCD then return end
    local target = getNearestEnemy()
    if not target then return end
    local remote = RS:FindFirstChild("Remotes")
        and RS.Remotes:FindFirstChild("WeaponRemotes")
        and RS.Remotes.WeaponRemotes:FindFirstChild("RequestShoot")
    if not remote then return end
    local ml = lp.PlayerScripts:FindFirstChild("MouseLock")
    local mlEnabled = ml and ml:GetAttribute("Enabled") or false
    local vp  = cam.ViewportSize
    local ray = cam:ScreenPointToRay(vp.X/2, vp.Y/2)
    _bypass = true
    pcall(function() remote:FireServer(target.Position, mlEnabled, ray) end)
    _bypass = false
    _gunCD  = true
    task.delay(0.55, function() _gunCD = false end)
end

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
        hrp.CFrame = target.CFrame * CFrame.new(0,0,2.5)
        task.wait()
        stabRE:FireServer(1)
    end)
    _bypass = false
    task.delay(0.12, function()
        pcall(function() if hrp then hrp.CFrame = origCF end)
    end)
    task.delay(1.25, function() _stabCD = false end)
end

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
    _bypass=false; _gunCD=false; _stabCD=false
end)

-- ================================================================
-- ================================================================
--  1. LOADING SCREEN  (no executor calls here)
-- ================================================================
-- ================================================================

local LoadGui = Instance.new("ScreenGui")
LoadGui.Name           = "MM2_Load"
LoadGui.ResetOnSpawn   = false
LoadGui.IgnoreGuiInset = true
LoadGui.DisplayOrder   = 9999
LoadGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
LoadGui.Parent         = pgui

-- Background
local BG = Instance.new("Frame")
BG.Size             = UDim2.new(1,0,1,0)
BG.BackgroundColor3 = Color3.fromRGB(4,4,12)
BG.BorderSizePixel  = 0
BG.ZIndex           = 1
BG.Parent           = LoadGui

-- Moving gradient
do
    local gf = Instance.new("Frame")
    gf.Size = UDim2.new(4,0,1,0)
    gf.Position = UDim2.new(-1.5,0,0,0)
    gf.BackgroundTransparency = 1
    gf.BorderSizePixel = 0
    gf.ZIndex = 2
    gf.Parent = BG
    local ug = Instance.new("UIGradient")
    ug.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(4,4,12)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(0,25,65)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,65,140)),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(0,25,65)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(4,4,12)),
    })
    ug.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.9),
        NumberSequenceKeypoint.new(0.5, 0.25),
        NumberSequenceKeypoint.new(1, 0.9),
    })
    ug.Rotation = 0
    ug.Parent = gf
    task.spawn(function()
        local t = 0
        while LoadGui.Parent do
            t += 0.007
            gf.Position = UDim2.new(-1.5 + math.sin(t)*0.5, 0, 0, 0)
            ug.Rotation = math.sin(t*0.5)*30
            RunService.RenderStepped:Wait()
        end
    end)
end

-- Scan lines
for i = 1, 28 do
    local sl = Instance.new("Frame")
    sl.Size             = UDim2.new(1,0,0,1)
    sl.Position         = UDim2.new(0,0,i/28,0)
    sl.BackgroundColor3 = Color3.fromRGB(0,110,230)
    sl.BackgroundTransparency = 0.88
    sl.BorderSizePixel  = 0
    sl.ZIndex           = 3
    sl.Parent           = BG
end

-- Floating particles
local function spawnDot()
    local s = math.random(5,15)
    local p = Instance.new("Frame")
    p.Size  = UDim2.new(0,s,0,s)
    p.AnchorPoint = Vector2.new(0.5,0.5)
    p.Position = UDim2.new(math.random(5,95)/100, 0, 1.1, 0)
    p.BackgroundColor3 = Color3.fromRGB(
        math.random(0,30), math.random(110,200), 255)
    p.BackgroundTransparency = math.random(40,75)/100
    p.BorderSizePixel = 0
    p.ZIndex = 4
    Instance.new("UICorner",p).CornerRadius = UDim.new(1,0)
    p.Parent = BG
    local tw = TweenSvc:Create(p, TweenInfo.new(math.random(28,52)/10, Enum.EasingStyle.Linear), {
        Position = UDim2.new(p.Position.X.Scale+(math.random()-0.5)*0.25, 0, -0.15, 0),
        BackgroundTransparency = 1,
    })
    tw:Play()
    tw.Completed:Connect(function() p:Destroy() end)
end
task.spawn(function()
    while LoadGui.Parent do
        spawnDot()
        task.wait(math.random(8,22)/100)
    end
end)

-- Corner brackets
for _, cv in ipairs({
    {Vector2.new(0,0), UDim2.new(0,12,0,12)},
    {Vector2.new(1,0), UDim2.new(1,-12,0,12)},
    {Vector2.new(0,1), UDim2.new(0,12,1,-12)},
    {Vector2.new(1,1), UDim2.new(1,-12,1,-12)},
}) do
    local f = Instance.new("Frame")
    f.Size = UDim2.new(0,55,0,55)
    f.AnchorPoint = cv[1]
    f.Position = cv[2]
    f.BackgroundTransparency = 1
    f.BorderSizePixel = 0
    f.ZIndex = 5
    f.Parent = BG
    local st = Instance.new("UIStroke",f)
    st.Color = Color3.fromRGB(0,145,255)
    st.Thickness = 2
    TweenSvc:Create(st, TweenInfo.new(1.2,Enum.EasingStyle.Sine,
        Enum.EasingDirection.InOut,-1,true), {Transparency=0.88}):Play()
end

-- Center card — starts below screen, slides up
local Card = Instance.new("Frame")
Card.Size = UDim2.new(0,500,0,285)
Card.AnchorPoint = Vector2.new(0.5,0.5)
Card.Position = UDim2.new(0.5,0, 1.7, 0)
Card.BackgroundColor3 = Color3.fromRGB(5,9,22)
Card.BackgroundTransparency = 0.18
Card.BorderSizePixel = 0
Card.ZIndex = 6
Card.Parent = BG
Instance.new("UICorner",Card).CornerRadius = UDim.new(0,18)

local cStroke = Instance.new("UIStroke",Card)
cStroke.Color = Color3.fromRGB(0,145,255)
cStroke.Thickness = 1.8
cStroke.Transparency = 0.15

do
    local cg = Instance.new("UIGradient",Card)
    cg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,14,40)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,33,72)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,14,40)),
    })
    cg.Rotation = 100
    task.spawn(function()
        local t=0
        while LoadGui.Parent do
            t+=0.013
            cg.Rotation = 100+math.sin(t)*25
            RunService.RenderStepped:Wait()
        end
    end)
end

-- Accent top line (expands)
local accent = Instance.new("Frame")
accent.Size = UDim2.new(0,0,0,3)
accent.AnchorPoint = Vector2.new(0.5,0)
accent.Position = UDim2.new(0.5,0,0,0)
accent.BackgroundColor3 = Color3.fromRGB(0,185,255)
accent.BorderSizePixel = 0
accent.ZIndex = 7
accent.Parent = Card
Instance.new("UICorner",accent).CornerRadius = UDim.new(0,2)

-- Badge
local function mkLabel(parent, text, size, ypos, color, font, align)
    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1,-30,0,size)
    lb.Position = UDim2.new(0,15,0,ypos)
    lb.BackgroundTransparency = 1
    lb.Text = text
    lb.TextColor3 = color or Color3.fromRGB(255,255,255)
    lb.Font = font or Enum.Font.Gotham
    lb.TextSize = size
    lb.TextXAlignment = align or Enum.TextXAlignment.Center
    lb.ZIndex = 7
    lb.Parent = parent
    return lb
end

mkLabel(Card,"▸  EXCLUSIVE  •  DELTA COMPATIBLE  ◂",11,14,Color3.fromRGB(0,160,255))

local titleLbl = mkLabel(Card,"",44,38,Color3.fromRGB(255,255,255),Enum.Font.GothamBlack)
do
    local tg = Instance.new("UIGradient",titleLbl)
    tg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,200,255)),
        ColorSequenceKeypoint.new(0.45,Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,200,255)),
    })
    task.spawn(function()
        local t=0
        while LoadGui.Parent do
            t+=0.016
            tg.Rotation=math.sin(t)*18
            RunService.RenderStepped:Wait()
        end
    end)
    local ts = Instance.new("UIStroke",titleLbl)
    ts.Color = Color3.fromRGB(0,150,255)
    ts.Thickness = 1.6
    ts.Transparency = 0.5
end

mkLabel(Card,"5v5  MILBASE  •  SILENT AIM EDITION",15,106,Color3.fromRGB(75,155,255),Enum.Font.GothamBold)

local divLine = Instance.new("Frame")
divLine.Size = UDim2.new(0,0,0,1)
divLine.Position = UDim2.new(0.075,0,0,140)
divLine.BackgroundColor3 = Color3.fromRGB(0,145,255)
divLine.BackgroundTransparency = 0.4
divLine.BorderSizePixel = 0
divLine.ZIndex = 7
divLine.Parent = Card

mkLabel(Card,"script by tolopoofcpae / tolopo637883",12,151,Color3.fromRGB(110,175,255))

local statusLbl = mkLabel(Card,"Inicializando...",11,179,Color3.fromRGB(55,130,255))

-- Progress bar
local pbBG = Instance.new("Frame")
pbBG.Size = UDim2.new(0.85,0,0,7)
pbBG.Position = UDim2.new(0.075,0,0,205)
pbBG.BackgroundColor3 = Color3.fromRGB(7,18,40)
pbBG.BorderSizePixel = 0
pbBG.ZIndex = 7
pbBG.Parent = Card
Instance.new("UICorner",pbBG).CornerRadius = UDim.new(1,0)

local pbFill = Instance.new("Frame")
pbFill.Size = UDim2.new(0,0,1,0)
pbFill.BackgroundColor3 = Color3.fromRGB(0,185,255)
pbFill.BorderSizePixel = 0
pbFill.ZIndex = 8
pbFill.Parent = pbBG
Instance.new("UICorner",pbFill).CornerRadius = UDim.new(1,0)
Instance.new("UIGradient",pbFill).Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,120,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(130,230,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,185,255)),
})

mkLabel(Card,"v1.0  •  SHIFT LOCK SUPPORT  •  MOBILE",10,224,Color3.fromRGB(30,60,115))

-- Slide card up
TweenSvc:Create(Card, TweenInfo.new(0.8,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5,0,0.5,0),
}):Play()

-- Expand accent line
task.spawn(function()
    task.wait(0.4)
    TweenSvc:Create(accent, TweenInfo.new(0.9,Enum.EasingStyle.Cubic), {
        Size = UDim2.new(0.82,0,0,3),
    }):Play()
    TweenSvc:Create(divLine, TweenInfo.new(1.1,Enum.EasingStyle.Cubic), {
        Size = UDim2.new(0.85,0,0,1),
    }):Play()
end)

-- Typewriter title
task.spawn(function()
    task.wait(0.5)
    local txt = "MM2 5v5 Milbase"
    for i=1,#txt do
        titleLbl.Text = txt:sub(1,i)
        task.wait(0.055)
    end
end)

-- Progress stages
local stages = {
    {0.18,"Carregando hooks..."},
    {0.36,"Verificando remotes..."},
    {0.54,"Montando armas..."},
    {0.70,"Preparando botões mobile..."},
    {0.86,"Aplicando shift-lock patch..."},
    {0.96,"Quase lá..."},
    {1.00,"Pronto!"},
}
task.spawn(function()
    task.wait(0.3)
    for _, s in ipairs(stages) do
        task.wait(0.44)
        statusLbl.Text = s[2]
        TweenSvc:Create(pbFill, TweenInfo.new(0.38,Enum.EasingStyle.Cubic), {
            Size = UDim2.new(s[1],0,1,0),
        }):Play()
    end
end)

task.wait(4.5)

-- Fade out loading screen
do
    local fd = Instance.new("Frame")
    fd.Size = UDim2.new(1,0,1,0)
    fd.BackgroundColor3 = Color3.fromRGB(0,0,0)
    fd.BackgroundTransparency = 1
    fd.BorderSizePixel = 0
    fd.ZIndex = 200
    fd.Parent = LoadGui
    TweenSvc:Create(fd, TweenInfo.new(0.55,Enum.EasingStyle.Linear), {
        BackgroundTransparency = 0,
    }):Play()
    task.wait(0.6)
end
LoadGui:Destroy()

-- ================================================================
-- ================================================================
--  2. KEY GUI  (slides up from bottom)
-- ================================================================
-- ================================================================

local CORRECT_KEY = "TopoOp-ofc_mohd"
local keyOK = false

local KeyGui = Instance.new("ScreenGui")
KeyGui.Name           = "MM2_Key"
KeyGui.ResetOnSpawn   = false
KeyGui.IgnoreGuiInset = true
KeyGui.DisplayOrder   = 8000
KeyGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
KeyGui.Parent         = pgui

-- Dim overlay
local kBG = Instance.new("Frame")
kBG.Size = UDim2.new(1,0,1,0)
kBG.BackgroundColor3 = Color3.fromRGB(0,0,0)
kBG.BackgroundTransparency = 0.55
kBG.BorderSizePixel = 0
kBG.ZIndex = 1
kBG.Parent = KeyGui

-- Panel starts off-screen bottom
local KPanel = Instance.new("Frame")
KPanel.Size = UDim2.new(0,420,0,310)
KPanel.AnchorPoint = Vector2.new(0.5,0.5)
KPanel.Position = UDim2.new(0.5,0, 1.8, 0)
KPanel.BackgroundColor3 = Color3.fromRGB(5,9,22)
KPanel.BackgroundTransparency = 0.05
KPanel.BorderSizePixel = 0
KPanel.ZIndex = 2
KPanel.Parent = KeyGui
Instance.new("UICorner",KPanel).CornerRadius = UDim.new(0,20)

local kpStroke = Instance.new("UIStroke",KPanel)
kpStroke.Color = Color3.fromRGB(0,150,255)
kpStroke.Thickness = 2

-- Panel gradient + animation
do
    local pg = Instance.new("UIGradient",KPanel)
    pg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,12,35)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,28,62)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,12,35)),
    })
    pg.Rotation = 115
    task.spawn(function()
        local t=0
        while KeyGui.Parent do
            t+=0.014
            pg.Rotation=115+math.sin(t)*22
            RunService.RenderStepped:Wait()
        end
    end)
end

-- Top glow
local kTopLine = Instance.new("Frame")
kTopLine.Size = UDim2.new(0.68,0,0,3)
kTopLine.AnchorPoint = Vector2.new(0.5,0)
kTopLine.Position = UDim2.new(0.5,0,0,0)
kTopLine.BackgroundColor3 = Color3.fromRGB(0,200,255)
kTopLine.BorderSizePixel = 0
kTopLine.ZIndex = 3
kTopLine.Parent = KPanel
Instance.new("UICorner",kTopLine).CornerRadius = UDim.new(1,0)
TweenSvc:Create(kTopLine, TweenInfo.new(1.3,Enum.EasingStyle.Sine,
    Enum.EasingDirection.InOut,-1,true), {
    BackgroundColor3 = Color3.fromRGB(0,90,200),
}):Play()

-- Lock icon frame
local lockF = Instance.new("Frame")
lockF.Size = UDim2.new(0,52,0,52)
lockF.AnchorPoint = Vector2.new(0.5,0)
lockF.Position = UDim2.new(0.5,0,0,16)
lockF.BackgroundColor3 = Color3.fromRGB(0,38,88)
lockF.BackgroundTransparency = 0.25
lockF.BorderSizePixel = 0
lockF.ZIndex = 3
lockF.Parent = KPanel
Instance.new("UICorner",lockF).CornerRadius = UDim.new(1,0)
Instance.new("UIStroke",lockF).Color = Color3.fromRGB(0,140,255)

local lockTxt = Instance.new("TextLabel")
lockTxt.Size = UDim2.new(1,0,1,0)
lockTxt.BackgroundTransparency = 1
lockTxt.Text = "🔐"
lockTxt.TextSize = 24
lockTxt.Font = Enum.Font.GothamBold
lockTxt.ZIndex = 4
lockTxt.Parent = lockF

-- Title
local kTitle = Instance.new("TextLabel")
kTitle.Size = UDim2.new(1,-30,0,30)
kTitle.Position = UDim2.new(0,15,0,80)
kTitle.BackgroundTransparency = 1
kTitle.Text = "MM2  5v5  MILBASE"
kTitle.TextColor3 = Color3.fromRGB(255,255,255)
kTitle.Font = Enum.Font.GothamBlack
kTitle.TextSize = 22
kTitle.TextXAlignment = Enum.TextXAlignment.Center
kTitle.ZIndex = 3
kTitle.Parent = KPanel

do
    local tg = Instance.new("UIGradient",kTitle)
    tg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,195,255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(200,240,255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,195,255)),
    })
    task.spawn(function()
        local t=0
        while KeyGui.Parent do
            t+=0.018
            tg.Rotation=math.sin(t)*14
            RunService.RenderStepped:Wait()
        end
    end)
end

local function kLbl(txt,y,sz,col,fnt)
    local lb = Instance.new("TextLabel")
    lb.Size = UDim2.new(1,-30,0,sz)
    lb.Position = UDim2.new(0,15,0,y)
    lb.BackgroundTransparency = 1
    lb.Text = txt
    lb.TextColor3 = col or Color3.fromRGB(80,150,220)
    lb.Font = fnt or Enum.Font.Gotham
    lb.TextSize = sz
    lb.TextXAlignment = Enum.TextXAlignment.Center
    lb.ZIndex = 3
    lb.Parent = KPanel
    return lb
end

kLbl("Insira a key para continuar",113,13)
kLbl("📌  Pega a key grátis no  scriptblox.com",130,11,Color3.fromRGB(50,105,185))

-- Input background
local inputBG = Instance.new("Frame")
inputBG.Size = UDim2.new(1,-40,0,46)
inputBG.Position = UDim2.new(0,20,0,152)
inputBG.BackgroundColor3 = Color3.fromRGB(0,14,36)
inputBG.BorderSizePixel = 0
inputBG.ZIndex = 3
inputBG.Parent = KPanel
Instance.new("UICorner",inputBG).CornerRadius = UDim.new(0,10)
local iStroke = Instance.new("UIStroke",inputBG)
iStroke.Color = Color3.fromRGB(0,100,200)
iStroke.Thickness = 1.5

local tbox = Instance.new("TextBox")
tbox.Size = UDim2.new(1,-16,1,0)
tbox.Position = UDim2.new(0,8,0,0)
tbox.BackgroundTransparency = 1
tbox.Text = ""
tbox.PlaceholderText = "Cole a key aqui..."
tbox.PlaceholderColor3 = Color3.fromRGB(45,78,130)
tbox.TextColor3 = Color3.fromRGB(190,225,255)
tbox.Font = Enum.Font.GothamBold
tbox.TextSize = 15
tbox.ClearTextOnFocus = false
tbox.ZIndex = 4
tbox.Parent = inputBG

tbox.Focused:Connect(function()
    TweenSvc:Create(iStroke,TweenInfo.new(0.18),{Color=Color3.fromRGB(0,200,255),Thickness=2}):Play()
end)
tbox.FocusLost:Connect(function()
    TweenSvc:Create(iStroke,TweenInfo.new(0.18),{Color=Color3.fromRGB(0,100,200),Thickness=1.5}):Play()
end)

-- Error label
local errLbl = kLbl("",207,12,Color3.fromRGB(255,80,80),Enum.Font.GothamBold)

-- Confirm button
local confBtn = Instance.new("TextButton")
confBtn.Size = UDim2.new(1,-40,0,44)
confBtn.Position = UDim2.new(0,20,0,230)
confBtn.Text = "CONFIRMAR KEY"
confBtn.TextColor3 = Color3.fromRGB(255,255,255)
confBtn.Font = Enum.Font.GothamBlack
confBtn.TextSize = 15
confBtn.BackgroundColor3 = Color3.fromRGB(0,80,200)
confBtn.BorderSizePixel = 0
confBtn.ZIndex = 3
confBtn.Parent = KPanel
Instance.new("UICorner",confBtn).CornerRadius = UDim.new(0,10)
local confGrad = Instance.new("UIGradient",confBtn)
confGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,100,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,58,195)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,100,255)),
})
confGrad.Rotation = 90
Instance.new("UIStroke",confBtn).Color = Color3.fromRGB(0,160,255)

confBtn.MouseButton1Down:Connect(function()
    TweenSvc:Create(confBtn,TweenInfo.new(0.07),{
        Size=UDim2.new(1,-48,0,41),
        Position=UDim2.new(0,24,0,232),
    }):Play()
end)

-- Slide panel up
TweenSvc:Create(KPanel, TweenInfo.new(0.75,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5,0,0.5,0),
}):Play()

local function doValidate()
    TweenSvc:Create(confBtn,TweenInfo.new(0.1),{
        Size=UDim2.new(1,-40,0,44),
        Position=UDim2.new(0,20,0,230),
    }):Play()
    local entered = tbox.Text:gsub("%s","")
    if entered == CORRECT_KEY then
        keyOK = true
        confBtn.Text = "✓  KEY CORRETA!"
        confBtn.BackgroundColor3 = Color3.fromRGB(0,155,55)
        errLbl.Text = ""
        task.delay(0.3, function()
            TweenSvc:Create(KPanel, TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.In), {
                Position = UDim2.new(0.5,0,1.8,0),
            }):Play()
            TweenSvc:Create(kBG, TweenInfo.new(0.5), {BackgroundTransparency=1}):Play()
            task.delay(0.55, function() KeyGui:Destroy() end)
        end)
    else
        errLbl.Text = "✗  Key incorreta."
        TweenSvc:Create(iStroke,TweenInfo.new(0.1),{Color=Color3.fromRGB(255,50,50)}):Play()
        task.delay(0.6,function()
            TweenSvc:Create(iStroke,TweenInfo.new(0.2),{Color=Color3.fromRGB(0,100,200)}):Play()
        end)
        -- Shake
        local orig = KPanel.Position
        task.spawn(function()
            for i=1,6 do
                TweenSvc:Create(KPanel,TweenInfo.new(0.04),{
                    Position=UDim2.new(0.5, i%2==0 and 10 or -10, 0.5, 0),
                }):Play()
                task.wait(0.045)
            end
            KPanel.Position = orig
        end)
    end
end

confBtn.MouseButton1Up:Connect(doValidate)
tbox.FocusLost:Connect(function(enter) if enter then doValidate() end end)

repeat task.wait(0.1) until keyOK

-- ================================================================
-- ================================================================
--  3. HOOK (after key — if it errors, buttons still show)
-- ================================================================
-- ================================================================

pcall(function()
    local BLOCKED = {RequestShoot=true,Stab=true,Throw=true,FlingKnifeEvent=true}
    local oldNC
    oldNC = hookmetamethod(game,"__namecall",newcclosure(function(self,...)
        if saActive and not _bypass
        and getnamecallmethod()=="FireServer"
        and self:IsA("RemoteEvent")
        and BLOCKED[self.Name] then
            return nil
        end
        return oldNC(self,...)
    end))
end)

-- ================================================================
-- ================================================================
--  4. MOBILE BUTTONS
-- ================================================================
-- ================================================================

local BtnGui = Instance.new("ScreenGui")
BtnGui.Name           = "MM2_SA_Btns"
BtnGui.ResetOnSpawn   = false
BtnGui.IgnoreGuiInset = true
BtnGui.DisplayOrder   = 500
BtnGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
BtnGui.Parent         = pgui

-- Round button factory
local function makeBtn(cfg)
    local sz   = cfg.sz   or 74
    local pos  = cfg.pos  or UDim2.new(0.5,0,0.5,0)
    local txt  = cfg.txt  or "?"
    local tcol = cfg.tcol or Color3.fromRGB(255,255,255)
    local scol = cfg.scol or Color3.fromRGB(22,22,22)
    local drag = cfg.drag ~= false

    -- outer ring
    local outer = Instance.new("Frame")
    outer.Size = UDim2.new(0,sz,0,sz)
    outer.AnchorPoint = Vector2.new(0.5,0.5)
    outer.Position = pos
    outer.BackgroundColor3 = Color3.fromRGB(0,0,0)
    outer.BackgroundTransparency = 0.65
    outer.BorderSizePixel = 0
    outer.ZIndex = 10
    outer.Parent = BtnGui
    Instance.new("UICorner",outer).CornerRadius = UDim.new(1,0)
    local ostroke = Instance.new("UIStroke",outer)
    ostroke.Color = scol
    ostroke.Thickness = 2.2

    -- transparent gap ring
    local gap = Instance.new("Frame")
    gap.Size = UDim2.new(0,sz-12,0,sz-12)
    gap.AnchorPoint = Vector2.new(0.5,0.5)
    gap.Position = UDim2.new(0.5,0,0.5,0)
    gap.BackgroundTransparency = 1
    gap.BorderSizePixel = 0
    gap.ZIndex = 11
    gap.Parent = outer
    Instance.new("UICorner",gap).CornerRadius = UDim.new(1,0)

    -- inner circle
    local inner = Instance.new("Frame")
    inner.Size = UDim2.new(0,sz-18,0,sz-18)
    inner.AnchorPoint = Vector2.new(0.5,0.5)
    inner.Position = UDim2.new(0.5,0,0.5,0)
    inner.BackgroundColor3 = Color3.fromRGB(0,0,0)
    inner.BackgroundTransparency = 0.50
    inner.BorderSizePixel = 0
    inner.ZIndex = 12
    inner.Parent = outer
    Instance.new("UICorner",inner).CornerRadius = UDim.new(1,0)

    -- label
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = txt
    lbl.TextColor3 = tcol
    lbl.Font = Enum.Font.GothamBold
    lbl.TextScaled = true
    lbl.ZIndex = 13
    lbl.Parent = inner

    -- invisible hit area
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 14
    btn.Parent = outer
    Instance.new("UICorner",btn).CornerRadius = UDim.new(1,0)

    -- drag
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
                local d=i.Position-ds
                outer.Position=UDim2.new(
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

    -- press shrink
    btn.MouseButton1Down:Connect(function()
        TweenSvc:Create(outer,TweenInfo.new(0.07,Enum.EasingStyle.Quad),{
            Size=UDim2.new(0,sz*0.87,0,sz*0.87),
        }):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenSvc:Create(outer,TweenInfo.new(0.14,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
            Size=UDim2.new(0,sz,0,sz),
        }):Play()
    end)

    return {f=outer, btn=btn, lbl=lbl, inner=inner, stroke=ostroke}
end

-- SA button — draggable, left side
local saBtn = makeBtn({
    txt  = "SA\nOFF",
    sz   = 78,
    pos  = UDim2.new(0.12, 0, 0.80, 0),   -- scale positions
    tcol = Color3.fromRGB(255,80,60),
    scol = Color3.fromRGB(22,22,22),
    drag = true,
})

saBtn.btn.MouseButton1Up:Connect(function()
    saActive = not saActive
    if saActive then
        saBtn.lbl.Text = "SA\nON"
        saBtn.lbl.TextColor3 = Color3.fromRGB(80,255,100)
        saBtn.inner.BackgroundColor3 = Color3.fromRGB(0,22,0)
        saBtn.stroke.Color = Color3.fromRGB(0,100,0)
    else
        saBtn.lbl.Text = "SA\nOFF"
        saBtn.lbl.TextColor3 = Color3.fromRGB(255,80,60)
        saBtn.inner.BackgroundColor3 = Color3.fromRGB(0,0,0)
        saBtn.stroke.Color = Color3.fromRGB(22,22,22)
    end
end)

-- Knife/Stab button — draggable, above SA
local knifeBtn = makeBtn({
    txt  = "FACA",
    sz   = 74,
    pos  = UDim2.new(0.12, 0, 0.67, 0),
    tcol = Color3.fromRGB(180,200,255),
    scol = Color3.fromRGB(22,22,22),
    drag = true,
})

knifeBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then return end
    local tool = getEquipped()
    if not tool or not isKnife(tool) then return end
    if tool:FindFirstChild("Stab") then
        silentStab()
    elseif tool:FindFirstChild("Throw") then
        silentThrow()
    end
end)

-- Gun button — fixed, bottom-right near jump
local gunBtn = makeBtn({
    txt  = "GUN",
    sz   = 80,
    pos  = UDim2.new(0.88, 0, 0.87, 0),
    tcol = Color3.fromRGB(255,210,0),
    scol = Color3.fromRGB(22,22,22),
    drag = false,
})

gunBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then return end
    local tool = getEquipped()
    if not tool or not isGun(tool) then return end
    silentGun()
end)

-- Glow active weapon button
task.spawn(function()
    while true do
        task.wait(0.1)
        local tool = getEquipped()
        knifeBtn.stroke.Color = (saActive and tool and isKnife(tool))
            and Color3.fromRGB(80,100,255) or Color3.fromRGB(22,22,22)
        gunBtn.stroke.Color = (saActive and tool and isGun(tool))
            and Color3.fromRGB(255,180,0) or Color3.fromRGB(22,22,22)
    end
end)

-- Slide buttons in from bottom
for i, b in ipairs({saBtn, knifeBtn, gunBtn}) do
    local orig = b.f.Position
    b.f.Position = UDim2.new(orig.X.Scale, orig.X.Offset, orig.Y.Scale+0.35, orig.Y.Offset)
    task.delay(i*0.1, function()
        TweenSvc:Create(b.f, TweenInfo.new(0.52,Enum.EasingStyle.Back,Enum.EasingDirection.Out), {
            Position = orig,
        }):Play()
    end)
end
