-- ================================================================
--   MM2 5v5 MILBASE — SILENT AIM
--   script by tolopoofcpae / tolopo637883
-- ================================================================

local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local TweenService  = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local lp  = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")
local cam  = workspace.CurrentCamera

-- ================================================================
--  STATE
-- ================================================================
local char, hrp, hum
local function refreshChar(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
    hum  = c:WaitForChild("Humanoid")
end
if lp.Character then refreshChar(lp.Character) end
lp.CharacterAdded:Connect(refreshChar)

local saActive     = false   -- silent aim toggle
local _bypass      = false   -- allows our own FireServer calls through the hook
local _stabCooldown = false
local _gunCooldown  = false

-- ================================================================
--  GUN / KNIFE LISTS (from file analysis)
-- ================================================================
local GUN_TYPES = {
    ["Default Gun"]=true,["Alienbeam"]=true,["Amerilaser"]=true,["Blaster"]=true,
    ["Blizzard"]=true,["Chroma Blizzard"]=true,["Chroma Raygun"]=true,["Chroma Snowcannon"]=true,
    ["Chroma Snowstorm"]=true,["Darkshot"]=true,["Emeraldshot"]=true,["Evergun"]=true,
    ["Gingerscope"]=true,["Gold Xenoshot"]=true,["Silver Xenoshot"]=true,["Bronze Xenoshot"]=true,
    ["Red Xenoshot"]=true,["Cyan Xenoshot"]=true,["Harvester"]=true,["Admin Harvester"]=true,
    ["Heat"]=true,["Icebeam"]=true,["Iceblaster"]=true,["Icepiercer"]=true,["Admin Icepiercer"]=true,
    ["Jinglegun"]=true,["Laser"]=true,["Light Shot"]=true,["Lightbringer"]=true,
    ["Luger"]=true,["Red Luger"]=true,["Green Luger"]=true,["Ginger Luger"]=true,["Lugercane"]=true,
    ["Nightblade"]=true,["Ocean"]=true,["Phaser"]=true,["Plasmabeam"]=true,["Raygun"]=true,
    ["Script'o shot"]=true,["Snowcannon"]=true,["Snowstorm"]=true,["Spectre"]=true,
    ["Swirly Gun"]=true,["Traveler's Gun"]=true,["Valeshot"]=true,["Virtual"]=true,
    ["Constellation"]=true,["Silver Constellation"]=true,["Gold Constellation"]=true,
    ["Bronze Constellation"]=true,["Red Constellation"]=true,["Space Constellation"]=true,
    ["Cupidshot"]=true,["Gemscope"]=true,["Flowerwood Gun"]=true,["Vampire's Gun"]=true,
    ["Skibidi Spectre"]=true,["Hallowgun"]=true,["Borealis"]=true,
}

-- ================================================================
--  HELPERS
-- ================================================================
local function getEquippedTool()
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

local function isGun(tool)
    return tool and GUN_TYPES[tool.Name] == true
end

local function isKnife(tool)
    return tool and not GUN_TYPES[tool.Name]
end

local function getNearestEnemy()
    if not hrp then return nil end
    local best, bestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p == lp then continue end
        local c = p.Character
        if not c then continue end
        local h = c:FindFirstChildOfClass("Humanoid")
        if not h or h.Health <= 0 then continue end
        local root = c:FindFirstChild("HumanoidRootPart")
        if not root then continue end
        local d = (hrp.Position - root.Position).Magnitude
        if d < bestDist then
            bestDist = d
            best = root
        end
    end
    return best, bestDist
end

-- ================================================================
--  SILENT AIM ACTIONS
-- ================================================================

-- Gun: fire RequestShoot at nearest enemy
local function silentShoot()
    if _gunCooldown then return end
    local target, dist = getNearestEnemy()
    if not target then return end

    local remote = ReplicatedStorage:FindFirstChild("Remotes")
        and ReplicatedStorage.Remotes:FindFirstChild("WeaponRemotes")
        and ReplicatedStorage.Remotes.WeaponRemotes:FindFirstChild("RequestShoot")
    if not remote then return end

    local cx = cam.ViewportSize.X / 2
    local cy = cam.ViewportSize.Y / 2
    local screenRay = cam:ScreenPointToRay(cx, cy)
    local mouseLock = lp.PlayerScripts:FindFirstChild("MouseLock")
    local mlEnabled = mouseLock and mouseLock:GetAttribute("Enabled") or false

    _bypass = true
    pcall(function()
        remote:FireServer(target.Position, mlEnabled, screenRay)
    end)
    _bypass = false

    _gunCooldown = true
    task.delay(0.6, function() _gunCooldown = false end)
end

-- Knife: warp stab (teleport to target, fire Stab, teleport back)
local function silentStab()
    if _stabCooldown then return end
    local tool = getEquippedTool()
    if not tool then return end
    local stabRemote = tool:FindFirstChild("Stab")
    if not stabRemote then return end
    local target = getNearestEnemy()
    if not target or not hrp then return end

    _stabCooldown = true
    local origCF = hrp.CFrame

    _bypass = true
    pcall(function()
        hrp.CFrame = target.CFrame * CFrame.new(0, 0, 2.2)
        task.wait()
        stabRemote:FireServer(1)
    end)
    _bypass = false

    task.delay(0.15, function()
        pcall(function() hrp.CFrame = origCF end)
    end)
    task.delay(1.2, function() _stabCooldown = false end)
end

-- ================================================================
--  __namecall HOOK — block normal actions when SA active
-- ================================================================
local BLOCK_REMOTES = {
    RequestShoot = true,
    Stab         = true,
    Throw        = true,
    FlingKnifeEvent = true,
}

local oldNC
oldNC = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if saActive and not _bypass and method == "FireServer" then
        if self:IsA("RemoteEvent") and BLOCK_REMOTES[self.Name] then
            return nil
        end
    end
    return oldNC(self, ...)
end))

-- ================================================================
-- ================================================================
--  LOADING SCREEN
-- ================================================================
-- ================================================================

local LoadGui = Instance.new("ScreenGui")
LoadGui.Name            = "MM2LoadScreen"
LoadGui.ResetOnSpawn    = false
LoadGui.IgnoreGuiInset  = true
LoadGui.DisplayOrder    = 9999
LoadGui.Parent          = pgui

-- Background
local BG = Instance.new("Frame")
BG.Size                   = UDim2.new(1,0,1,0)
BG.BackgroundColor3       = Color3.fromRGB(5, 5, 12)
BG.BorderSizePixel        = 0
BG.ZIndex                 = 1
BG.Parent                 = LoadGui

-- Moving gradient overlay
local gradFrame = Instance.new("Frame")
gradFrame.Size              = UDim2.new(2,0,1,0)
gradFrame.Position          = UDim2.new(-0.5,0,0,0)
gradFrame.BackgroundTransparency = 0
gradFrame.BorderSizePixel   = 0
gradFrame.ZIndex            = 2
gradFrame.Parent            = BG

local uig = Instance.new("UIGradient")
uig.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(5,5,12)),
    ColorSequenceKeypoint.new(0.3, Color3.fromRGB(0,30,60)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,60,120)),
    ColorSequenceKeypoint.new(0.7, Color3.fromRGB(0,30,60)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(5,5,12)),
})
uig.Rotation  = 45
uig.Parent    = gradFrame

-- Animate gradient
task.spawn(function()
    local t = 0
    while LoadGui.Parent do
        t = t + 0.003
        gradFrame.Position = UDim2.new(-0.5 + math.sin(t)*0.2, 0, 0, 0)
        uig.Rotation = 45 + math.sin(t*0.5)*15
        RunService.RenderStepped:Wait()
    end
end)

-- Scan lines
for i = 1, 25 do
    local line = Instance.new("Frame")
    line.Size            = UDim2.new(1,0,0,1)
    line.Position        = UDim2.new(0,0,i/25,0)
    line.BackgroundColor3 = Color3.fromRGB(0,120,255)
    line.BackgroundTransparency = 0.92
    line.BorderSizePixel = 0
    line.ZIndex          = 3
    line.Parent          = BG
end

-- Floating animated particles
local function spawnParticle()
    local p = Instance.new("Frame")
    local sz = math.random(4,14)
    p.Size               = UDim2.new(0,sz,0,sz)
    p.Position           = UDim2.new(math.random()/1,0, math.random()/1, 0)
    p.BackgroundColor3   = Color3.fromRGB(0, math.random(100,200), 255)
    p.BackgroundTransparency = math.random(50,80)/100
    p.BorderSizePixel    = 0
    p.ZIndex             = 4
    Instance.new("UICorner", p).CornerRadius = UDim.new(1,0)
    p.Parent = BG

    local startY = 1.1
    local destY  = -0.1
    local startX = math.random(0,100)/100
    p.Position = UDim2.new(startX, 0, startY, 0)

    TweenService:Create(p, TweenInfo.new(math.random(25,50)/10, Enum.EasingStyle.Linear), {
        Position = UDim2.new(startX + (math.random()-0.5)*0.3, 0, destY, 0),
        BackgroundTransparency = 1,
    }):Play()

    task.delay(6, function() p:Destroy() end)
end

task.spawn(function()
    while LoadGui.Parent do
        spawnParticle()
        task.wait(math.random(10,25)/100)
    end
end)

-- Flying corner decorations
for _, cfg2 in ipairs({
    {UDim2.new(0,0,0,0),   UDim2.new(0,80,0,80)},
    {UDim2.new(1,-80,0,0), UDim2.new(0,80,0,80)},
    {UDim2.new(0,0,1,-80), UDim2.new(0,80,0,80)},
    {UDim2.new(1,-80,1,-80),UDim2.new(0,80,0,80)},
}) do
    local corner = Instance.new("Frame")
    corner.Size                   = cfg2[2]
    corner.Position               = cfg2[1]
    corner.BackgroundTransparency = 1
    corner.BorderSizePixel        = 0
    corner.ZIndex                 = 5
    corner.Parent = BG
    local stroke = Instance.new("UIStroke", corner)
    stroke.Color     = Color3.fromRGB(0, 140, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.3
    -- Pulse
    task.spawn(function()
        while corner.Parent do
            TweenService:Create(stroke, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {Transparency=0.8}):Play()
            task.wait(0.5)
            break
        end
    end)
end

-- Center container
local Center = Instance.new("Frame")
Center.Size                   = UDim2.new(0, 520, 0, 280)
Center.AnchorPoint            = Vector2.new(0.5, 0.5)
Center.Position               = UDim2.new(0.5, 0, 0.5, 0)
Center.BackgroundColor3       = Color3.fromRGB(0, 10, 25)
Center.BackgroundTransparency = 0.35
Center.BorderSizePixel        = 0
Center.ZIndex                 = 6
Center.Parent                 = BG

Instance.new("UICorner", Center).CornerRadius = UDim.new(0, 16)
local centerStroke = Instance.new("UIStroke", Center)
centerStroke.Color     = Color3.fromRGB(0, 150, 255)
centerStroke.Thickness = 2

-- Center gradient
local cg = Instance.new("UIGradient")
cg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,20,50)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0,40,80)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,20,50)),
})
cg.Rotation = 90
cg.Parent = Center

task.spawn(function()
    local t2 = 0
    while LoadGui.Parent do
        t2 = t2 + 0.01
        cg.Rotation = 90 + math.sin(t2)*30
        RunService.RenderStepped:Wait()
    end
end)

-- Top badge line
local badge = Instance.new("Frame")
badge.Size               = UDim2.new(1,0,0,3)
badge.Position           = UDim2.new(0,0,0,0)
badge.BackgroundColor3   = Color3.fromRGB(0,180,255)
badge.BorderSizePixel    = 0
badge.ZIndex             = 7
badge.Parent             = Center
Instance.new("UICorner", badge)

-- MM2 label (small top)
local mm2lbl = Instance.new("TextLabel")
mm2lbl.Size                  = UDim2.new(1,0,0,28)
mm2lbl.Position               = UDim2.new(0,0,0,12)
mm2lbl.BackgroundTransparency = 1
mm2lbl.Text                   = "▸ MM2 EXCLUSIVE SCRIPT ◂"
mm2lbl.TextColor3             = Color3.fromRGB(0, 180, 255)
mm2lbl.Font                   = Enum.Font.GothamBold
mm2lbl.TextSize               = 13
mm2lbl.ZIndex                 = 7
mm2lbl.Parent                 = Center

-- Main title
local titleLbl = Instance.new("TextLabel")
titleLbl.Size                  = UDim2.new(1,-40,0,72)
titleLbl.Position               = UDim2.new(0,20,0,42)
titleLbl.BackgroundTransparency = 1
titleLbl.Text                   = ""
titleLbl.TextColor3             = Color3.fromRGB(255,255,255)
titleLbl.Font                   = Enum.Font.GothamBlack
titleLbl.TextSize               = 46
titleLbl.TextXAlignment         = Enum.TextXAlignment.Center
titleLbl.ZIndex                 = 7
titleLbl.Parent                 = Center

-- Title gradient
local tg = Instance.new("UIGradient")
tg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,200,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,200,255)),
})
tg.Rotation = 0
tg.Parent = titleLbl

task.spawn(function()
    local t3 = 0
    while LoadGui.Parent do
        t3 = t3 + 0.02
        tg.Rotation = math.sin(t3)*15
        RunService.RenderStepped:Wait()
    end
end)

-- Title UIStroke for glow effect
local tStroke = Instance.new("UIStroke", titleLbl)
tStroke.Color     = Color3.fromRGB(0, 160, 255)
tStroke.Thickness = 2
tStroke.Transparency = 0.4

-- Sub title
local subLbl = Instance.new("TextLabel")
subLbl.Size                  = UDim2.new(1,-40,0,28)
subLbl.Position               = UDim2.new(0,20,0,116)
subLbl.BackgroundTransparency = 1
subLbl.Text                   = "5v5  MILBASE  •  SILENT  AIM  EDITION"
subLbl.TextColor3             = Color3.fromRGB(100,180,255)
subLbl.Font                   = Enum.Font.GothamBold
subLbl.TextSize               = 16
subLbl.TextXAlignment         = Enum.TextXAlignment.Center
subLbl.ZIndex                 = 7
subLbl.Parent                 = Center

-- Divider
local div = Instance.new("Frame")
div.Size               = UDim2.new(0,0,0,1)
div.Position           = UDim2.new(0.1,0,0,152)
div.BackgroundColor3   = Color3.fromRGB(0,150,255)
div.BackgroundTransparency = 0.3
div.BorderSizePixel    = 0
div.ZIndex             = 7
div.Parent             = Center

-- Credit label
local creditLbl = Instance.new("TextLabel")
creditLbl.Size                  = UDim2.new(1,-40,0,24)
creditLbl.Position               = UDim2.new(0,20,0,160)
creditLbl.BackgroundTransparency = 1
creditLbl.Text                   = "script by tolopoofcpae / tolopo637883"
creditLbl.TextColor3             = Color3.fromRGB(150,200,255)
creditLbl.Font                   = Enum.Font.Gotham
creditLbl.TextSize               = 13
creditLbl.TextXAlignment         = Enum.TextXAlignment.Center
creditLbl.ZIndex                 = 7
creditLbl.Parent                 = Center

-- Status text
local statusLbl = Instance.new("TextLabel")
statusLbl.Size                  = UDim2.new(1,-40,0,22)
statusLbl.Position               = UDim2.new(0,20,0,190)
statusLbl.BackgroundTransparency = 1
statusLbl.Text                   = "Inicializando módulos..."
statusLbl.TextColor3             = Color3.fromRGB(80,160,255)
statusLbl.Font                   = Enum.Font.Gotham
statusLbl.TextSize               = 12
statusLbl.TextXAlignment         = Enum.TextXAlignment.Center
statusLbl.ZIndex                 = 7
statusLbl.Parent                 = Center

-- Progress bar background
local pbBG = Instance.new("Frame")
pbBG.Size               = UDim2.new(0.8,0,0,8)
pbBG.Position           = UDim2.new(0.1,0,0,220)
pbBG.BackgroundColor3   = Color3.fromRGB(10,25,45)
pbBG.BorderSizePixel    = 0
pbBG.ZIndex             = 7
pbBG.Parent             = Center
Instance.new("UICorner", pbBG).CornerRadius = UDim.new(1,0)

-- Progress bar fill
local pbFill = Instance.new("Frame")
pbFill.Size               = UDim2.new(0,0,1,0)
pbFill.BackgroundColor3   = Color3.fromRGB(0,180,255)
pbFill.BorderSizePixel    = 0
pbFill.ZIndex             = 8
pbFill.Parent             = pbBG
Instance.new("UICorner", pbFill).CornerRadius = UDim.new(1,0)

-- Progress bar gradient
local pbg = Instance.new("UIGradient")
pbg.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(0,120,255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100,220,255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,180,255)),
})
pbg.Parent = pbFill

-- Bottom tag
local tagLbl = Instance.new("TextLabel")
tagLbl.Size                  = UDim2.new(1,-40,0,20)
tagLbl.Position               = UDim2.new(0,20,0,242)
tagLbl.BackgroundTransparency = 1
tagLbl.Text                   = "v1.0  •  DELTA COMPATIBLE  •  MOBILE READY"
tagLbl.TextColor3             = Color3.fromRGB(40,80,140)
tagLbl.Font                   = Enum.Font.Gotham
tagLbl.TextSize               = 10
tagLbl.TextXAlignment         = Enum.TextXAlignment.Center
tagLbl.ZIndex                 = 7
tagLbl.Parent                 = Center

-- ── Typewriter animation for title ──────────────────────────────
local TITLE_TEXT = "MM2 5v5 Milbase"
task.spawn(function()
    task.wait(0.3)
    for i = 1, #TITLE_TEXT do
        titleLbl.Text = TITLE_TEXT:sub(1, i)
        task.wait(0.06)
    end
end)

-- ── Loading stages ───────────────────────────────────────────────
local stages = {
    {0.15, "Carregando hooks..."},
    {0.35, "Verificando remotes..."},
    {0.52, "Montando sistema de armas..."},
    {0.68, "Preparando botões mobile..."},
    {0.82, "Configurando Rayfield..."},
    {0.95, "Quase lá..."},
    {1.00, "Pronto!"},
}

-- Expand divider
TweenService:Create(div, TweenInfo.new(1.8, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
    Size = UDim2.new(0.8, 0, 0, 1),
    Position = UDim2.new(0.1, 0, 0, 152),
}):Play()

task.spawn(function()
    task.wait(0.2)
    for _, s in ipairs(stages) do
        task.wait(0.45)
        statusLbl.Text = s[2]
        TweenService:Create(pbFill, TweenInfo.new(0.4, Enum.EasingStyle.Cubic), {
            Size = UDim2.new(s[1], 0, 1, 0),
        }):Play()
    end
end)

-- Center entry animation
Center.Position = UDim2.new(0.5, 0, 1.5, 0)
TweenService:Create(Center, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, 0, 0.5, 0),
}):Play()

-- ── Wait for loading, then fade out ─────────────────────────────
task.wait(4.5)

-- Fade out
local fadeFrame = Instance.new("Frame")
fadeFrame.Size                   = UDim2.new(1,0,1,0)
fadeFrame.BackgroundColor3       = Color3.fromRGB(0,0,0)
fadeFrame.BackgroundTransparency = 1
fadeFrame.BorderSizePixel        = 0
fadeFrame.ZIndex                 = 100
fadeFrame.Parent                 = LoadGui

TweenService:Create(fadeFrame, TweenInfo.new(0.7, Enum.EasingStyle.Linear), {
    BackgroundTransparency = 0,
}):Play()
task.wait(0.8)
LoadGui:Destroy()

-- ================================================================
-- ================================================================
--  RAYFIELD WITH KEY SYSTEM
-- ================================================================
-- ================================================================

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
    Name             = "MM2 5v5 Milbase",
    Icon             = 0,
    LoadingTitle     = "MM2 5v5 Milbase",
    LoadingSubtitle  = "script by tolopoofcpae / tolopo637883",
    Theme            = "Default",
    ShowText         = "MM2 SA",
    ToggleUIKeybind  = "RightControl",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving    = { Enabled = false, FileName = "MM2SA" },
    Discord  = { Enabled = false },
    KeySystem = true,
    KeySettings = {
        Title       = "MM2 5v5 Milbase",
        Subtitle    = "Key System",
        Note        = "Pega a Key no scriptblox.com — na descrição do script estará a Key.",
        FileName    = "MM2SA_Key",
        SaveKey     = true,
        GrabKeyFromSite = false,
        Key         = {"TopoOp-ofc_mohd"},
    },
})

-- ── Rayfield Tab (informação) ─────────────────────────────────────
local InfoTab = Window:CreateTab("Info", "info")

InfoTab:CreateSection("Silent Aim Ativo")
InfoTab:CreateLabel("Use os botões na tela para ativar o Silent Aim.")
InfoTab:CreateLabel("Botão SA   → Ativar/Desativar (arrastável)")
InfoTab:CreateLabel("Botão FACA → Taca na pessoa mais perto (arrastável)")
InfoTab:CreateLabel("Botão GUN  → Atira na pessoa mais perto (perto do Jump)")

InfoTab:CreateSection("Como funciona")
InfoTab:CreateLabel("Quando SA está ON: toque normal é bloqueado.")
InfoTab:CreateLabel("Só atira/taca quando pressiona os botões.")

-- ================================================================
-- ================================================================
--  MOBILE BUTTONS
-- ================================================================
-- ================================================================

local BtnGui = Instance.new("ScreenGui")
BtnGui.Name            = "MM2_SA_Buttons"
BtnGui.ResetOnSpawn    = false
BtnGui.IgnoreGuiInset  = true
BtnGui.DisplayOrder    = 500
BtnGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
BtnGui.Parent          = pgui

-- ================================================================
-- Button factory
-- ================================================================
-- design: outer ring (black transparent + stroke) > gap (transparent) > inner circle (black transparent) > label
local function makeRoundBtn(opts)
    -- opts: {text, size, position, color, textColor, draggable, parent}
    local sz   = opts.size   or 72
    local pos  = opts.pos    or UDim2.new(0.5,0,0.5,0)
    local col  = opts.color  or Color3.fromRGB(0,0,0)
    local tcol = opts.tcolor or Color3.fromRGB(255,255,255)
    local drag = opts.drag   ~= false  -- default draggable
    local txt  = opts.text   or "BTN"
    local par  = opts.parent or BtnGui

    -- Outer container (hitbox + outer ring)
    local outer = Instance.new("Frame")
    outer.Size                   = UDim2.new(0, sz, 0, sz)
    outer.Position               = pos
    outer.AnchorPoint            = Vector2.new(0.5, 0.5)
    outer.BackgroundColor3       = col
    outer.BackgroundTransparency = 0.72
    outer.BorderSizePixel        = 0
    outer.ZIndex                 = 10
    outer.Parent                 = par
    Instance.new("UICorner", outer).CornerRadius = UDim.new(1, 0)
    local outerStroke = Instance.new("UIStroke", outer)
    outerStroke.Color     = opts.strokeColor or Color3.fromRGB(30, 30, 30)
    outerStroke.Thickness = 2.5

    -- Gap ring (transparent, slightly smaller)
    local gap = Instance.new("Frame")
    gap.Size               = UDim2.new(0, sz-14, 0, sz-14)
    gap.Position           = UDim2.new(0.5, 0, 0.5, 0)
    gap.AnchorPoint        = Vector2.new(0.5, 0.5)
    gap.BackgroundColor3   = Color3.fromRGB(0,0,0)
    gap.BackgroundTransparency = 1  -- invisible gap ring
    gap.BorderSizePixel    = 0
    gap.ZIndex             = 11
    gap.Parent             = outer
    Instance.new("UICorner", gap).CornerRadius = UDim.new(1, 0)

    -- Inner circle
    local inner = Instance.new("Frame")
    inner.Size               = UDim2.new(0, sz-18, 0, sz-18)
    inner.Position           = UDim2.new(0.5, 0, 0.5, 0)
    inner.AnchorPoint        = Vector2.new(0.5, 0.5)
    inner.BackgroundColor3   = col
    inner.BackgroundTransparency = 0.55
    inner.BorderSizePixel    = 0
    inner.ZIndex             = 12
    inner.Parent             = outer
    Instance.new("UICorner", inner).CornerRadius = UDim.new(1, 0)

    -- Label
    local lbl = Instance.new("TextLabel")
    lbl.Size                  = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text                   = txt
    lbl.TextColor3             = tcol
    lbl.Font                   = Enum.Font.GothamBold
    lbl.TextScaled             = true
    lbl.ZIndex                 = 13
    lbl.Parent                 = inner

    -- Invisible touch button over the whole outer frame
    local btn = Instance.new("TextButton")
    btn.Size                   = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text                   = ""
    btn.ZIndex                 = 14
    btn.Parent                 = outer
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    -- Drag logic
    if drag then
        local dragging, dragStart, btnStart = false, nil, nil
        btn.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch
            or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging  = true
                dragStart = inp.Position
                btnStart  = outer.Position
            end
        end)
        btn.InputChanged:Connect(function(inp)
            if dragging and (inp.UserInputType == Enum.UserInputType.Touch
            or inp.UserInputType == Enum.UserInputType.MouseMovement) then
                local delta = inp.Position - dragStart
                outer.Position = UDim2.new(
                    btnStart.X.Scale, btnStart.X.Offset + delta.X,
                    btnStart.Y.Scale, btnStart.Y.Offset + delta.Y
                )
            end
        end)
        btn.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.Touch
            or inp.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end

    -- Press visual feedback
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(outer, TweenInfo.new(0.08, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, sz*0.9, 0, sz*0.9)
        }):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(outer, TweenInfo.new(0.12, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, sz, 0, sz)
        }):Play()
    end)

    return {frame=outer, btn=btn, lbl=lbl, inner=inner, stroke=outerStroke}
end

-- ================================================================
-- BUTTON 1: SA Toggle (draggable, left side)
-- ================================================================
local saBtn = makeRoundBtn({
    text   = "SA\nOFF",
    size   = 76,
    pos    = UDim2.new(0, 90, 0.78, 0),
    color  = Color3.fromRGB(0, 0, 0),
    tcolor = Color3.fromRGB(255, 80, 60),
    strokeColor = Color3.fromRGB(20, 20, 20),
    drag   = true,
    parent = BtnGui,
})

saBtn.btn.MouseButton1Up:Connect(function()
    saActive = not saActive
    if saActive then
        saBtn.lbl.Text         = "SA\nON"
        saBtn.lbl.TextColor3   = Color3.fromRGB(80, 255, 100)
        saBtn.inner.BackgroundColor3 = Color3.fromRGB(0, 30, 0)
        saBtn.stroke.Color     = Color3.fromRGB(0, 80, 0)
    else
        saBtn.lbl.Text         = "SA\nOFF"
        saBtn.lbl.TextColor3   = Color3.fromRGB(255, 80, 60)
        saBtn.inner.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        saBtn.stroke.Color     = Color3.fromRGB(20, 20, 20)
    end
end)

-- ================================================================
-- BUTTON 2: Knife Silent Stab (draggable)
-- ================================================================
local knifeBtn = makeRoundBtn({
    text   = "FACA",
    size   = 72,
    pos    = UDim2.new(0, 90, 0.64, 0),
    color  = Color3.fromRGB(0, 0, 0),
    tcolor = Color3.fromRGB(200, 200, 255),
    strokeColor = Color3.fromRGB(20, 20, 20),
    drag   = true,
    parent = BtnGui,
})

knifeBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then
        -- quando SA tá off, não faz nada
        return
    end
    local tool = getEquippedTool()
    if tool and isKnife(tool) then
        silentStab()
    end
end)

-- ================================================================
-- BUTTON 3: Gun Shoot (fixed, near jump button, NOT draggable)
-- ================================================================
-- positioned bottom-right near jump area
local gunBtn = makeRoundBtn({
    text   = "GUN",
    size   = 78,
    pos    = UDim2.new(1, -80, 1, -100),
    color  = Color3.fromRGB(0, 0, 0),
    tcolor = Color3.fromRGB(255, 200, 0),
    strokeColor = Color3.fromRGB(20, 20, 20),
    drag   = false,
    parent = BtnGui,
})

gunBtn.btn.MouseButton1Up:Connect(function()
    if not saActive then return end
    local tool = getEquippedTool()
    if tool and isGun(tool) then
        silentShoot()
    end
end)

-- ================================================================
--  Visual pulse on active buttons
-- ================================================================
task.spawn(function()
    while true do
        RunService.Heartbeat:Wait()
        local tool = getEquippedTool()
        -- Knife button glow when knife equipped & SA on
        if saActive and tool and isKnife(tool) then
            knifeBtn.stroke.Color = Color3.fromRGB(100, 100, 255)
        else
            knifeBtn.stroke.Color = Color3.fromRGB(20, 20, 20)
        end
        -- Gun button glow when gun equipped & SA on
        if saActive and tool and isGun(tool) then
            gunBtn.stroke.Color = Color3.fromRGB(255, 180, 0)
        else
            gunBtn.stroke.Color = Color3.fromRGB(20, 20, 20)
        end
    end
end)

-- ================================================================
--  Respawn handler: refresh refs and reattach
-- ================================================================
lp.CharacterAdded:Connect(function(c)
    refreshChar(c)
    _bypass      = false
    _stabCooldown = false
    _gunCooldown  = false
end)

-- ================================================================
-- Done notification
-- ================================================================
Rayfield:Notify({
    Title    = "MM2 5v5 Milbase",
    Content  = "Silent Aim carregado! Pressione SA para ativar.",
    Duration = 5,
    Image    = 4483362458,
})
