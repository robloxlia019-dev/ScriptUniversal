--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║       MURDERERS VS SHERIFFS DUELS — SCRIPT v4               ║
    ║       Anti-detecção BAC_9 corrigida                         ║
    ║       Silent Aim via Mouse.__index (não toca game mt)       ║
    ╚══════════════════════════════════════════════════════════════╝
]]

-- ══════════════════════════════════════
-- CARREGAMENTO DO RAYFIELD
-- ══════════════════════════════════════
local Rayfield
pcall(function()
    Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not Rayfield then
    -- Fallback silencioso: cria stub vazio
    Rayfield = {}
    setmetatable(Rayfield, {__index = function() return function() return {} end end})
end

-- ══════════════════════════════════════
-- SERVIÇOS
-- ══════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Workspace         = game:GetService("Workspace")
local CoreGui           = game:GetService("CoreGui")
local Lighting          = game:GetService("Lighting")
local Camera            = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local Mouse       = LocalPlayer:GetMouse()

-- ══════════════════════════════════════
-- REMOTES (encontra de forma segura)
-- ══════════════════════════════════════
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local function getRemote(name)
    return Remotes and Remotes:FindFirstChild(name) or nil
end

-- ══════════════════════════════════════
-- ESTADO GLOBAL
-- ══════════════════════════════════════
local State = {
    -- Aimbot
    SilentAim        = false,
    SilentAimChance  = 85,
    AutoShot         = false,
    AutoShotChance   = 85,
    AutoShotDelay    = 0.18,
    AimbotFOV        = 150,
    ShowFOV          = true,
    AimbotPart       = "Head",
    AimbotSmooth     = false,
    AimbotSmoothFactor = 0.2,
    LockOnTarget     = false,

    -- ESP
    ESPEnabled       = false,
    ESPBoxes         = false,
    ESPNames         = true,
    ESPDistance      = true,
    ESPHealth        = true,
    ESPTracers       = false,
    ESPChams         = false,
    ESPTeamCheck     = true,
    ESPMaxDist       = 500,
    ESPMurdererColor = Color3.fromRGB(255, 60,  60),
    ESPSheriffColor  = Color3.fromRGB(60,  150, 255),
    ESPInnocentColor = Color3.fromRGB(100, 255, 100),

    -- Visual / Skin da Arma
    GunSkinEnabled    = false,
    SelectedGunSkin   = "Default",
    KnifeSkinEnabled  = false,
    SelectedKnife     = "Default",
    KillEffectEnabled = false,
    SelectedKillEffect = "Reef",

    -- Misc
    NoFog            = false,
    Fullbright       = false,
    InfiniteJump     = false,
    SpeedEnabled     = false,
    SpeedValue       = 20,
    NoClipEnabled    = false,
    AntiRagdoll      = false,
    AutoEquipGun     = false,
    CustomFOV        = false,
    CustomFOVValue   = 90,
    ShowFPS          = false,
    BHop             = false,
    FakeLag          = false,
    FakeLagValue     = 0,

    -- Chams storage
    _ChamObjects     = {},
}

-- ══════════════════════════════════════
-- LISTAS DE SKINS
-- ══════════════════════════════════════
local GunSkins = {
    "Default","Reef","Strife Purple","Strife Red","Strife Green","Strife Gold","Strife WhiteGold","Strife Frost",
    "Mermaid","Fang Red","Fang Green","Fang Blue","Fang Gray","Fang Purple","Fang Green-Purple","Fang Frost",
    "Willow Red","Willow Blue","Willow Green","Willow Purple",
    "Ice Pegasus White","Ice Pegasus Blue","Ice Pegasus Purple","Ice Pegasus Red","Ice Pegasus Black",
    "Bubble Purple","Bubble Blue","Bubble Pink","Bubble Red","Bubble Black","Bubble White","Bubble Frost",
    "Flutter Purple","Flutter Pink","Flutter Red","Flutter Blue","Flutter Black","Flutter Frost",
    "Elder Flame Blue","Elder Flame Black","Elder Flame Red","Elder Flame Purple","Elder Flame Frost",
    "Rhinestone Purple","Rhinestone Red","Rhinestone Blue","Rhinestone Black","Rhinestone Frost",
    "Rosethorn","Rosethorn Frost","Celestial","Frost Celestial","Reaper","Frost Reaper",
    "Angel","Techno","Harmonic","Frostbite","Leprichaun",
    "Nebula Blue","Nebula Red","Nebula Pink","Nebula Green","Nebula Black",
    "Android Purple","Android Blue","Android Green","Android Pink","Android White",
}

local KnifeSkins = {
    "Default","Feather","Leafstone","Bejeweled","Dragon Breathe","Bat Scythe","Saber","Rainbow",
    "Glyph","Shadow","Quartz","Reef","Hologram",
    "Strife Purple","Strife Red","Strife Green","Strife Black",
    "Moss","Webbed","Cryptic","Skeletal",
    "Willow Red","Willow Blue","Willow Green","Willow Purple",
    "Mermaid Blue","Mermaid Green","Mermaid Pink",
    "Fang Red","Fang Blue","Fang Purple","Fang Frost",
    "Angel","Celestial","Reaper","Frosthorn",
    "Butterfly Blue","Butterfly Purple",
}

local KillEffects = {
    "Reef","Vaporize","Burn","Bat","GradeA","Splatter","Vip","Void",
    "Reaper","FrostReaper","Angel","Demon","Techno","Celestial","FrostCelestial",
    "Harmonic","Frostbite","Swirly",
    "Crystal Blue","Crystal Purple","Crystal Green","Crystal White",
    "Strife Purple","Strife Red","Strife Green","Strife Gold","Strife WhiteGold","Strife Frost",
    "Willow Red","Willow Blue","Willow Green","Willow Purple",
    "Fang Red","Fang Green","Fang Blue","Fang Gray","Fang Purple","Fang Frost",
    "Flutter Purple","Flutter Pink","Flutter Red","Flutter Blue","Flutter Black","Flutter Frost",
    "Bubble Purple","Bubble Blue","Bubble Pink","Bubble Red","Bubble Black","Bubble White","Bubble Frost",
    "Elder Flame Blue","Elder Flame Black","Elder Flame Red","Elder Flame Purple","Elder Flame Frost",
    "Rhinestone Purple","Rhinestone Red","Rhinestone Blue","Rhinestone Black","Rhinestone Frost",
    "Ice Pegasus White","Ice Pegasus Blue","Ice Pegasus Purple","Ice Pegasus Red","Ice Pegasus Black",
    "Rosethorn","Rosethorn Frost","Nebula Blue","Nebula Red","Nebula Pink","Nebula Green","Nebula Black",
    "Android Purple","Android Blue","Android Green","Android Pink","Android White",
    "Frosthorn","Leprichaun",
}

-- ══════════════════════════════════════
-- AUXILIARES
-- ══════════════════════════════════════
local function getEnemies()
    local list = {}
    local myRole = LocalPlayer:GetAttribute("Role") or ""
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            if State.ESPTeamCheck and myRole == "Sheriff" then
                if (p:GetAttribute("Role") or "") ~= "Sheriff" then
                    table.insert(list, p)
                end
            else
                table.insert(list, p)
            end
        end
    end
    return list
end

local function getTargetPart(char, partName)
    if not char then return nil end
    return char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart")
end

local function getClosestToCursor(maxFOV)
    local closest, closestDist = nil, maxFOV or State.AimbotFOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local hum  = p.Character:FindFirstChildOfClass("Humanoid")
            local root = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hum.Health > 0 and root then
                local part = getTargetPart(p.Character, State.AimbotPart) or root
                local v3, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local dist = (center - Vector2.new(v3.X, v3.Y)).Magnitude
                    if dist < closestDist then
                        closestDist, closest = dist, p
                    end
                end
            end
        end
    end
    return closest
end

-- ══════════════════════════════════════════════════════════════
-- SILENT AIM — Hook Mouse.__index (NÃO toca getrawmetatable(game))
-- BAC_9 só verifica o metatable do objeto "game", NÃO do Mouse.
-- ══════════════════════════════════════════════════════════════
local _fakeHitEnabled = false
local _fakeHitCFrame  = CFrame.new(0, 0, 0)

pcall(function()
    local mouseMT = getrawmetatable(Mouse)
    setreadonly(mouseMT, false)
    local oldIndex = mouseMT.__index
    mouseMT.__index = newcclosure(function(self, key)
        if _fakeHitEnabled and State.SilentAim then
            if key == "Hit" then
                return _fakeHitCFrame
            end
            if key == "UnitRay" then
                local dir = (_fakeHitCFrame.Position - Camera.CFrame.Position).Unit
                return Ray.new(Camera.CFrame.Position, dir * 1000)
            end
        end
        return oldIndex(self, key)
    end)
    setreadonly(mouseMT, true)
end)

-- Ativa o fake hit antes do clique do mouse chegar ao GunController
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    if not State.SilentAim then return end

    local target = getClosestToCursor(State.AimbotFOV)
    if not target or not target.Character then return end
    local chance = math.random(1, 100)
    if chance > State.SilentAimChance then return end

    local part = getTargetPart(target.Character, State.AimbotPart)
    if not part then return end

    -- Ativa o fake hit
    _fakeHitCFrame  = CFrame.new(part.Position)
    _fakeHitEnabled = true
end)

-- Desativa o fake hit logo após (no próximo frame, depois do gun script rodar)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        task.defer(function()
            _fakeHitEnabled = false
        end)
    end
end)

-- ══════════════════════════════════════
-- AUTO SHOT — Simula InputBegan sem tocar game metatable
-- ══════════════════════════════════════
local lastAutoShot = 0

RunService.Heartbeat:Connect(function()
    if not State.AutoShot then return end
    if tick() - lastAutoShot < State.AutoShotDelay then return end

    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return end

    -- Só atira se tiver gun tool equipada
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end
    local ok, isGun = pcall(function() return CollectionService:HasTag(tool, "GunTool") end)
    if not (ok and isGun) then return end

    local target = getClosestToCursor(State.AimbotFOV)
    if not target or not target.Character then return end
    local tHum = target.Character:FindFirstChildOfClass("Humanoid")
    if not tHum or tHum.Health <= 0 then return end

    local chance = math.random(1, 100)
    if chance > State.AutoShotChance then return end

    local part = getTargetPart(target.Character, State.AimbotPart)
    if not part then return end

    lastAutoShot = tick()

    -- Ativa o fake hit para o auto shot também
    _fakeHitCFrame  = CFrame.new(part.Position)
    _fakeHitEnabled = true

    -- Dispara o sinal de input que o GunController escuta
    pcall(function()
        local vim = game:GetService("VirtualInputManager")
        vim:SendMouseButtonEvent(
            Camera.ViewportSize.X / 2,
            Camera.ViewportSize.Y / 2,
            0, true, game, 1
        )
    end)

    task.delay(0.05, function()
        pcall(function()
            local vim = game:GetService("VirtualInputManager")
            vim:SendMouseButtonEvent(
                Camera.ViewportSize.X / 2,
                Camera.ViewportSize.Y / 2,
                0, false, game, 1
            )
        end)
        _fakeHitEnabled = false
    end)
end)

-- ══════════════════════════════════════
-- FOV CIRCLE
-- ══════════════════════════════════════
local fovCircle
pcall(function()
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible   = false
    fovCircle.Color     = Color3.fromRGB(255, 255, 255)
    fovCircle.Thickness = 1.5
    fovCircle.Filled    = false
    fovCircle.NumSides  = 64
end)

RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Visible  = State.ShowFOV and (State.SilentAim or State.AutoShot)
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Radius   = State.AimbotFOV
    end
end)

-- ══════════════════════════════════════
-- LOCK ON TARGET (mantém câmera no alvo)
-- ══════════════════════════════════════
RunService.RenderStepped:Connect(function()
    if not State.LockOnTarget then return end
    local target = getClosestToCursor(State.AimbotFOV)
    if not target or not target.Character then return end
    local part = getTargetPart(target.Character, State.AimbotPart)
    if not part then return end
    local cf = CFrame.lookAt(Camera.CFrame.Position, part.Position)
    if State.AimbotSmooth then
        Camera.CFrame = Camera.CFrame:Lerp(cf, State.AimbotSmoothFactor)
    else
        Camera.CFrame = cf
    end
end)

-- ══════════════════════════════════════════════════
-- ESP SYSTEM
-- ══════════════════════════════════════════════════
local ESPObjects = {}

local function removeESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            pcall(function() obj:Remove() end)
        end
        ESPObjects[player] = nil
    end
end

local function createESP(player)
    if not player or player == LocalPlayer then return end
    removeESP(player)
    ESPObjects[player] = {}

    local function newDrawing(class, props)
        local d = Drawing.new(class)
        d.Visible = false
        for k, v in pairs(props) do d[k] = v end
        return d
    end

    ESPObjects[player].box        = newDrawing("Square",  {Color=Color3.fromRGB(255,255,255),Thickness=1.5,Filled=false})
    ESPObjects[player].boxFill    = newDrawing("Square",  {Color=Color3.fromRGB(255,255,255),Thickness=1,Filled=true,Transparency=0.7})
    ESPObjects[player].nameLabel  = newDrawing("Text",    {Color=Color3.fromRGB(255,255,255),Size=13,Center=true,Outline=true})
    ESPObjects[player].roleLabel  = newDrawing("Text",    {Color=Color3.fromRGB(255,200,50), Size=11,Center=true,Outline=true})
    ESPObjects[player].healthBg   = newDrawing("Square",  {Color=Color3.fromRGB(0,0,0),Filled=true})
    ESPObjects[player].healthBar  = newDrawing("Square",  {Color=Color3.fromRGB(0,255,0),Filled=true})
    ESPObjects[player].distLabel  = newDrawing("Text",    {Color=Color3.fromRGB(200,200,200),Size=11,Center=true,Outline=true})
    ESPObjects[player].tracer     = newDrawing("Line",    {Color=Color3.fromRGB(255,255,255),Thickness=1})
end

local function getESPColor(player)
    local role = player:GetAttribute("Role") or ""
    if role == "Murderer"  then return State.ESPMurdererColor
    elseif role == "Sheriff" then return State.ESPSheriffColor
    else return State.ESPInnocentColor
    end
end

RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not ESPObjects[player] then createESP(player) end

        local objs = ESPObjects[player]
        if not objs then continue end

        local char    = player.Character
        local enabled = State.ESPEnabled and char ~= nil

        if not enabled then
            for _, o in pairs(objs) do pcall(function() o.Visible = false end) end
            continue
        end

        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        local head = char:FindFirstChild("Head")

        if not root or not hum then
            for _, o in pairs(objs) do pcall(function() o.Visible = false end) end
            continue
        end

        local dist = (Camera.CFrame.Position - root.Position).Magnitude
        if dist > State.ESPMaxDist then
            for _, o in pairs(objs) do pcall(function() o.Visible = false end) end
            continue
        end

        local color = getESPColor(player)
        local headV, headOn = Camera:WorldToViewportPoint((head and head.Position or root.Position) + Vector3.new(0, 0.7, 0))
        local rootV, rootOn = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

        if not headOn or not rootOn or headV.Z <= 0 or rootV.Z <= 0 then
            for _, o in pairs(objs) do pcall(function() o.Visible = false end) end
            continue
        end

        local headPos = Vector2.new(headV.X, headV.Y)
        local rootPos = Vector2.new(rootV.X, rootV.Y)
        local height  = math.abs(headPos.Y - rootPos.Y)
        local width   = height * 0.55
        local topLeft = Vector2.new(headPos.X - width / 2, headPos.Y)

        -- Box
        if objs.box then
            objs.box.Visible   = State.ESPBoxes
            objs.box.Color     = color
            objs.box.Position  = topLeft
            objs.box.Size      = Vector2.new(width, height)
        end

        -- Box fill (chams 2D)
        if objs.boxFill then
            objs.boxFill.Visible      = State.ESPChams
            objs.boxFill.Color        = color
            objs.boxFill.Position     = topLeft
            objs.boxFill.Size         = Vector2.new(width, height)
            objs.boxFill.Transparency = 0.75
        end

        -- Name
        if objs.nameLabel then
            objs.nameLabel.Visible   = State.ESPNames
            objs.nameLabel.Color     = color
            objs.nameLabel.Text      = player.DisplayName
            objs.nameLabel.Position  = Vector2.new(headPos.X, headPos.Y - 16)
        end

        -- Role
        if objs.roleLabel then
            local role = player:GetAttribute("Role") or "?"
            objs.roleLabel.Visible   = State.ESPNames
            objs.roleLabel.Text      = "[" .. role .. "]"
            objs.roleLabel.Position  = Vector2.new(headPos.X, headPos.Y - 27)
        end

        -- Distance
        if objs.distLabel then
            objs.distLabel.Visible   = State.ESPDistance
            objs.distLabel.Text      = string.format("[%.0fm]", dist)
            objs.distLabel.Position  = Vector2.new(rootPos.X, rootPos.Y + 2)
        end

        -- Health bar
        local hp     = hum.Health
        local maxHp  = math.max(hum.MaxHealth, 1)
        local ratio  = hp / maxHp
        local barH   = height * ratio
        local barX   = topLeft.X - 6

        if objs.healthBg then
            objs.healthBg.Visible  = State.ESPHealth
            objs.healthBg.Position = Vector2.new(barX, headPos.Y)
            objs.healthBg.Size     = Vector2.new(4, height)
        end
        if objs.healthBar then
            objs.healthBar.Visible  = State.ESPHealth
            objs.healthBar.Color    = Color3.fromRGB(math.floor(255*(1-ratio)), math.floor(255*ratio), 0)
            objs.healthBar.Position = Vector2.new(barX, headPos.Y + height * (1 - ratio))
            objs.healthBar.Size     = Vector2.new(4, barH)
        end

        -- Tracer
        if objs.tracer then
            objs.tracer.Visible = State.ESPTracers
            objs.tracer.Color   = color
            objs.tracer.From    = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            objs.tracer.To      = rootPos
        end
    end
end)

Players.PlayerRemoving:Connect(removeESP)

-- ══════════════════════════════════════
-- INFINITE JUMP
-- ══════════════════════════════════════
UserInputService.JumpRequest:Connect(function()
    if not State.InfiniteJump then return end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ══════════════════════════════════════
-- BHOP
-- ══════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not State.BHop then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end
    if hum:GetState() == Enum.HumanoidStateType.Landed then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ══════════════════════════════════════
-- SPEED
-- ══════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not State.SpeedEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        hum.WalkSpeed = State.SpeedValue
    end
end)

-- ══════════════════════════════════════
-- NOCLIP
-- ══════════════════════════════════════
RunService.Stepped:Connect(function()
    if not State.NoClipEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then p.CanCollide = false end
    end
end)

-- ══════════════════════════════════════
-- ANTI-RAGDOLL
-- ══════════════════════════════════════
local function applyAntiRagdoll(char)
    if not State.AntiRagdoll or not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") then
            pcall(function() v.Enabled = false end)
        end
    end
end
LocalPlayer.CharacterAdded:Connect(function(char)
    applyAntiRagdoll(char)
    char.DescendantAdded:Connect(function() applyAntiRagdoll(char) end)
end)

-- ══════════════════════════════════════
-- FULLBRIGHT / NO FOG
-- ══════════════════════════════════════
local origBright, origAmb, origOutAmb

local function setFullbright(on)
    if on then
        origBright   = Lighting.Brightness
        origAmb      = Lighting.Ambient
        origOutAmb   = Lighting.OutdoorAmbient
        Lighting.Brightness     = 2
        Lighting.Ambient        = Color3.fromRGB(178,178,178)
        Lighting.OutdoorAmbient = Color3.fromRGB(178,178,178)
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") then v.Density = 0; v.Haze = 0 end
        end
    else
        if origBright then
            Lighting.Brightness     = origBright
            Lighting.Ambient        = origAmb
            Lighting.OutdoorAmbient = origOutAmb
        end
    end
end

local function setNoFog(on)
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") then
            v.Density = on and 0 or 0.25
            v.Haze    = on and 0 or 1.48
        end
    end
    Lighting.FogEnd   = on and 100000 or 1000
    Lighting.FogStart = on and 99999  or 0
end

-- ══════════════════════════════════════
-- CUSTOM FOV
-- ══════════════════════════════════════
local function setCustomFOV(on, val)
    Camera.FieldOfView = on and val or 70
end

-- ══════════════════════════════════════
-- FAKE LAG (packet delay sim)
-- ══════════════════════════════════════
local _fakeLagConn
local function setFakeLag(on, val)
    if _fakeLagConn then _fakeLagConn:Disconnect(); _fakeLagConn = nil end
    if not on then return end
    -- Usar sleep para simular lag de forma simples
    _fakeLagConn = RunService.Heartbeat:Connect(function()
        if not State.FakeLag then _fakeLagConn:Disconnect(); return end
        task.wait(val / 1000)
    end)
end

-- ══════════════════════════════════════
-- FPS COUNTER
-- ══════════════════════════════════════
local fpsLabel
pcall(function()
    fpsLabel = Drawing.new("Text")
    fpsLabel.Visible  = false
    fpsLabel.Color    = Color3.fromRGB(0, 255, 0)
    fpsLabel.Size     = 14
    fpsLabel.Outline  = true
    fpsLabel.Position = Vector2.new(10, 10)
end)
local fpsCount, lastFPS, curFPS = 0, tick(), 0
RunService.RenderStepped:Connect(function()
    fpsCount += 1
    local now = tick()
    if now - lastFPS >= 1 then
        curFPS   = fpsCount
        fpsCount = 0
        lastFPS  = now
    end
    if fpsLabel then
        fpsLabel.Visible = State.ShowFPS
        fpsLabel.Text    = "FPS: " .. curFPS
    end
end)

-- ══════════════════════════════════════
-- SKINS DE ARMA
-- Usa SurfaceAppearance.ColorMap (método nativo do jogo)
-- ══════════════════════════════════════
local GunSkinTextures = {
    ["Reef"]              = "rbxassetid://14134879105",
    ["Strife Purple"]     = "rbxassetid://15222267465",
    ["Strife Red"]        = "rbxassetid://15222265229",
    ["Strife Green"]      = "rbxassetid://15222258241",
    ["Strife Gold"]       = "rbxassetid://15222262718",
    ["Strife WhiteGold"]  = "rbxassetid://15222270531",
    ["Strife Frost"]      = "rbxassetid://15222272409",
    ["Mermaid"]           = "rbxassetid://14208214271",
    ["Fang Red"]          = "rbxassetid://14074161508",
    ["Fang Green"]        = "rbxassetid://14074156095",
    ["Fang Blue"]         = "rbxassetid://14074165525",
    ["Fang Gray"]         = "rbxassetid://14074170044",
    ["Fang Purple"]       = "rbxassetid://13140835728",
    ["Fang Green-Purple"] = "rbxassetid://13140832483",
    ["Fang Frost"]        = "rbxassetid://13140830742",
    ["Willow Red"]        = "rbxassetid://15291413157",
    ["Willow Blue"]       = "rbxassetid://15291410308",
    ["Willow Green"]      = "rbxassetid://15291409077",
    ["Willow Purple"]     = "rbxassetid://15291412065",
}

local KnifeSkinTextures = {
    ["Default"]           = "rbxassetid://13140672466",
    ["Feather"]           = "rbxassetid://13140830742",
    ["Leafstone"]         = "rbxassetid://13140832483",
    ["Bejeweled"]         = "rbxassetid://13140835728",
    ["Reef"]              = "rbxassetid://14134879105",
    ["Hologram"]          = "rbxassetid://14208214271",
    ["Strife Purple"]     = "rbxassetid://15222267465",
    ["Strife Red"]        = "rbxassetid://15222265229",
    ["Strife Green"]      = "rbxassetid://15222258241",
    ["Strife Black"]      = "rbxassetid://15222262718",
    ["Moss"]              = "rbxassetid://15291088543",
    ["Webbed"]            = "rbxassetid://15291091889",
    ["Cryptic"]           = "rbxassetid://15291089821",
    ["Skeletal"]          = "rbxassetid://15291065966",
    ["Willow Red"]        = "rbxassetid://15291413157",
    ["Willow Blue"]       = "rbxassetid://15291410308",
    ["Willow Green"]      = "rbxassetid://15291409077",
    ["Willow Purple"]     = "rbxassetid://15291412065",
    ["Fang Red"]          = "rbxassetid://14074161508",
    ["Fang Blue"]         = "rbxassetid://14074165525",
    ["Fang Purple"]       = "rbxassetid://13140835728",
    ["Fang Frost"]        = "rbxassetid://13140830742",
    ["Mermaid Blue"]      = "rbxassetid://14208214271",
}

local function applyToTool(tool, textureId)
    if not tool then return end
    for _, part in ipairs(tool:GetDescendants()) do
        if part:IsA("MeshPart") then
            pcall(function()
                if textureId then
                    local sa = part:FindFirstChildOfClass("SurfaceAppearance")
                    if not sa then
                        sa = Instance.new("SurfaceAppearance", part)
                    end
                    sa.ColorMap = textureId
                else
                    -- Restaura default: remove SA custom
                    local sa = part:FindFirstChildOfClass("SurfaceAppearance")
                    if sa then sa:Destroy() end
                end
            end)
        end
    end
end

local function findTool(tags)
    local char = LocalPlayer.Character
    local bp   = LocalPlayer:FindFirstChild("Backpack")
    local function search(parent)
        if not parent then return nil end
        for _, t in ipairs(parent:GetChildren()) do
            if t:IsA("Tool") then
                for _, tag in ipairs(tags) do
                    local ok, has = pcall(function() return CollectionService:HasTag(t, tag) end)
                    if ok and has then return t end
                end
            end
        end
        return nil
    end
    return (char and search(char)) or (bp and search(bp))
end

local function applyGunSkin(skinName)
    local tool = findTool({"GunTool"})
    if not tool then
        -- Tentar qualquer tool se não achou pela tag
        local char = LocalPlayer.Character
        if char then
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") then
                    local ok, isKnife = pcall(function() return CollectionService:HasTag(t, "KnifeTool") end)
                    if not (ok and isKnife) then tool = t; break end
                end
            end
        end
    end
    local textureId = GunSkinTextures[skinName]
    applyToTool(tool, textureId)
end

local function applyKnifeSkin(skinName)
    local tool = findTool({"KnifeTool"})
    if not tool then
        local char = LocalPlayer.Character
        if char then
            for _, t in ipairs(char:GetChildren()) do
                if t:IsA("Tool") then
                    local ok, isGun = pcall(function() return CollectionService:HasTag(t, "GunTool") end)
                    if not (ok and isGun) then tool = t; break end
                end
            end
        end
    end
    local textureId = KnifeSkinTextures[skinName]
    applyToTool(tool, textureId)
end

-- Reaplicar skins quando equipar ferramenta
LocalPlayer.CharacterAdded:Connect(function(char)
    char.ChildAdded:Connect(function(child)
        if not child:IsA("Tool") then return end
        task.wait(0.1) -- esperar o tool aparecer
        if State.GunSkinEnabled then applyGunSkin(State.SelectedGunSkin) end
        if State.KnifeSkinEnabled then applyKnifeSkin(State.SelectedKnife) end
    end)
end)

-- ══════════════════════════════════════
-- EFEITO DE MORTE
-- ══════════════════════════════════════
local OnPlayerKilledRemote = getRemote("OnPlayerKilled")
if OnPlayerKilledRemote then
    OnPlayerKilledRemote.OnClientEvent:Connect(function(killedPlayer, killerPlayer)
        if not State.KillEffectEnabled then return end
        if killerPlayer ~= LocalPlayer then return end
        local char = killedPlayer and killedPlayer.Character
        if not char then return end
        pcall(function()
            -- Tenta encontrar o handler de efeito no PlayerScripts
            local ps = LocalPlayer:FindFirstChild("PlayerScripts")
            if not ps then return end
            local handler = ps:FindFirstChild("KillEffectHandler", true)
                         or ps:FindFirstChild("EffectHandler", true)
            if handler then
                local mod = require(handler)
                if type(mod) == "table" and mod.PlayEffect then
                    mod.PlayEffect(State.SelectedKillEffect, char)
                elseif type(mod) == "function" then
                    mod(State.SelectedKillEffect, char)
                end
            end
        end)
    end)
end

-- ══════════════════════════════════════
-- AUTO EQUIP GUN
-- ══════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not State.AutoEquipGun then return end
    local char = LocalPlayer.Character
    if not char then return end
    local tool = findTool({"GunTool"})
    if tool and tool.Parent ~= char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then pcall(function() hum:EquipTool(tool) end) end
    end
end)

-- ══════════════════════════════════════════════════════════════
-- GUI — RAYFIELD
-- ══════════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name             = "MVS DUELS v4",
    Icon             = 0,
    LoadingTitle     = "Murderers VS Sheriffs DUELS",
    LoadingSubtitle  = "v4 | BAC_9 Bypass",
    Theme            = "Default",
    DisableRayfieldPrompts = true,
    DisableBuildWarnings   = true,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "MVSDuels",
        FileName   = "Config",
    },
    KeySystem = false,
})

-- ══════════════════════════════════════════════════════════════
-- TAB 1 — AIMBOT
-- ══════════════════════════════════════════════════════════════
local AimTab = Window:CreateTab("🎯 Aimbot", 4483362458)

AimTab:CreateSection("Silent Aim")

AimTab:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "SilentAim",
    Callback = function(v) State.SilentAim = v end,
})

AimTab:CreateSlider({
    Name = "Chance de Acerto (%)",
    Range = {1,100}, Increment = 1, Suffix = "%",
    CurrentValue = 85, Flag = "SilentAimChance",
    Callback = function(v) State.SilentAimChance = v end,
})

AimTab:CreateSlider({
    Name = "FOV do Aimbot",
    Range = {10,500}, Increment = 5, Suffix = "px",
    CurrentValue = 150, Flag = "AimbotFOV",
    Callback = function(v) State.AimbotFOV = v end,
})

AimTab:CreateToggle({
    Name = "Mostrar Círculo FOV",
    CurrentValue = true, Flag = "ShowFOV",
    Callback = function(v) State.ShowFOV = v end,
})

AimTab:CreateDropdown({
    Name = "Parte Alvo",
    Options = {"Head","HumanoidRootPart","UpperTorso","LowerTorso"},
    CurrentOption = {"Head"}, MultipleOptions = false, Flag = "AimbotPart",
    Callback = function(v) State.AimbotPart = type(v)=="table" and v[1] or v end,
})

AimTab:CreateSection("Auto Shot")

AimTab:CreateToggle({
    Name = "Auto Shot",
    CurrentValue = false, Flag = "AutoShot",
    Callback = function(v) State.AutoShot = v end,
})

AimTab:CreateSlider({
    Name = "Chance Auto Shot (%)",
    Range = {1,100}, Increment = 1, Suffix = "%",
    CurrentValue = 85, Flag = "AutoShotChance",
    Callback = function(v) State.AutoShotChance = v end,
})

AimTab:CreateSlider({
    Name = "Delay Auto Shot (x0.01s)",
    Range = {5,100}, Increment = 5, Suffix = "x0.01s",
    CurrentValue = 18, Flag = "AutoShotDelay",
    Callback = function(v) State.AutoShotDelay = v/100 end,
})

AimTab:CreateSection("Lock On")

AimTab:CreateToggle({
    Name = "Lock On Alvo",
    CurrentValue = false, Flag = "LockOnTarget",
    Callback = function(v) State.LockOnTarget = v end,
})

AimTab:CreateToggle({
    Name = "Smooth Lock",
    CurrentValue = false, Flag = "AimbotSmooth",
    Callback = function(v) State.AimbotSmooth = v end,
})

AimTab:CreateSlider({
    Name = "Velocidade Smooth",
    Range = {1,20}, Increment = 1, Suffix = "",
    CurrentValue = 2, Flag = "AimbotSmoothFactor",
    Callback = function(v) State.AimbotSmoothFactor = v/20 end,
})

-- ══════════════════════════════════════════════════════════════
-- TAB 2 — ESP
-- ══════════════════════════════════════════════════════════════
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)

ESPTab:CreateSection("ESP Principal")

ESPTab:CreateToggle({Name="ESP Ativado",CurrentValue=false,Flag="ESPEnabled",
    Callback=function(v) State.ESPEnabled=v end})
ESPTab:CreateToggle({Name="Boxes",CurrentValue=false,Flag="ESPBoxes",
    Callback=function(v) State.ESPBoxes=v end})
ESPTab:CreateToggle({Name="Chams (Fill Box)",CurrentValue=false,Flag="ESPChams",
    Callback=function(v) State.ESPChams=v end})
ESPTab:CreateToggle({Name="Nomes + Role",CurrentValue=true,Flag="ESPNames",
    Callback=function(v) State.ESPNames=v end})
ESPTab:CreateToggle({Name="Distância",CurrentValue=true,Flag="ESPDistance",
    Callback=function(v) State.ESPDistance=v end})
ESPTab:CreateToggle({Name="Barra de Vida",CurrentValue=true,Flag="ESPHealth",
    Callback=function(v) State.ESPHealth=v end})
ESPTab:CreateToggle({Name="Tracers",CurrentValue=false,Flag="ESPTracers",
    Callback=function(v) State.ESPTracers=v end})
ESPTab:CreateToggle({Name="Check Time",CurrentValue=true,Flag="ESPTeamCheck",
    Callback=function(v) State.ESPTeamCheck=v end})

ESPTab:CreateSlider({
    Name="Distância Máxima", Range={50,2000}, Increment=50, Suffix="studs",
    CurrentValue=500, Flag="ESPMaxDist",
    Callback=function(v) State.ESPMaxDist=v end,
})

ESPTab:CreateSection("Cores ESP")

ESPTab:CreateColorPicker({Name="Cor Murderer",Color=Color3.fromRGB(255,60,60),Flag="ESPMurdererColor",
    Callback=function(v) State.ESPMurdererColor=v end})
ESPTab:CreateColorPicker({Name="Cor Sheriff",Color=Color3.fromRGB(60,150,255),Flag="ESPSheriffColor",
    Callback=function(v) State.ESPSheriffColor=v end})
ESPTab:CreateColorPicker({Name="Cor Innocent",Color=Color3.fromRGB(100,255,100),Flag="ESPInnocentColor",
    Callback=function(v) State.ESPInnocentColor=v end})

-- ══════════════════════════════════════════════════════════════
-- TAB 3 — ARMAS & SKINS
-- ══════════════════════════════════════════════════════════════
local WeaponTab = Window:CreateTab("🔫 Armas & Skins", 4483362458)

WeaponTab:CreateSection("Skin da Arma (Sheriff/Gun)")

WeaponTab:CreateToggle({
    Name="Ativar Skin de Arma", CurrentValue=false, Flag="GunSkinEnabled",
    Callback=function(v)
        State.GunSkinEnabled = v
        if v then applyGunSkin(State.SelectedGunSkin) end
    end,
})

WeaponTab:CreateDropdown({
    Name="Skin da Arma", Options=GunSkins,
    CurrentOption={"Default"}, MultipleOptions=false, Flag="SelectedGunSkin",
    Callback=function(v)
        State.SelectedGunSkin = type(v)=="table" and v[1] or v
        if State.GunSkinEnabled then applyGunSkin(State.SelectedGunSkin) end
    end,
})

WeaponTab:CreateButton({
    Name="Aplicar Skin Agora",
    Callback=function() applyGunSkin(State.SelectedGunSkin) end,
})

WeaponTab:CreateSection("Skin da Faca (Murderer)")

WeaponTab:CreateToggle({
    Name="Ativar Skin de Faca", CurrentValue=false, Flag="KnifeSkinEnabled",
    Callback=function(v)
        State.KnifeSkinEnabled = v
        if v then applyKnifeSkin(State.SelectedKnife) end
    end,
})

WeaponTab:CreateDropdown({
    Name="Skin da Faca", Options=KnifeSkins,
    CurrentOption={"Default"}, MultipleOptions=false, Flag="SelectedKnife",
    Callback=function(v)
        State.SelectedKnife = type(v)=="table" and v[1] or v
        if State.KnifeSkinEnabled then applyKnifeSkin(State.SelectedKnife) end
    end,
})

WeaponTab:CreateButton({
    Name="Aplicar Skin de Faca",
    Callback=function() applyKnifeSkin(State.SelectedKnife) end,
})

WeaponTab:CreateSection("Efeito de Morte")

WeaponTab:CreateToggle({
    Name="Ativar Efeito de Morte", CurrentValue=false, Flag="KillEffectEnabled",
    Callback=function(v) State.KillEffectEnabled=v end,
})

WeaponTab:CreateDropdown({
    Name="Efeito de Morte", Options=KillEffects,
    CurrentOption={"Reef"}, MultipleOptions=false, Flag="SelectedKillEffect",
    Callback=function(v) State.SelectedKillEffect = type(v)=="table" and v[1] or v end,
})

-- ══════════════════════════════════════════════════════════════
-- TAB 4 — MISC
-- ══════════════════════════════════════════════════════════════
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

MiscTab:CreateSection("Movimento")

MiscTab:CreateToggle({Name="Infinite Jump",CurrentValue=false,Flag="InfiniteJump",
    Callback=function(v) State.InfiniteJump=v end})

MiscTab:CreateToggle({Name="BHop",CurrentValue=false,Flag="BHop",
    Callback=function(v) State.BHop=v end})

MiscTab:CreateToggle({
    Name="Speed Hack", CurrentValue=false, Flag="SpeedEnabled",
    Callback=function(v)
        State.SpeedEnabled = v
        if not v then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
        end
    end,
})

MiscTab:CreateSlider({
    Name="Velocidade", Range={16,200}, Increment=2, Suffix=" WS",
    CurrentValue=20, Flag="SpeedValue",
    Callback=function(v) State.SpeedValue=v end,
})

MiscTab:CreateToggle({Name="NoClip",CurrentValue=false,Flag="NoClipEnabled",
    Callback=function(v) State.NoClipEnabled=v end})

MiscTab:CreateToggle({Name="Anti-Ragdoll",CurrentValue=false,Flag="AntiRagdoll",
    Callback=function(v)
        State.AntiRagdoll=v
        if v then applyAntiRagdoll(LocalPlayer.Character) end
    end,
})

MiscTab:CreateToggle({Name="Auto Equipar Arma",CurrentValue=false,Flag="AutoEquipGun",
    Callback=function(v) State.AutoEquipGun=v end})

MiscTab:CreateSection("Visual")

MiscTab:CreateToggle({Name="Fullbright",CurrentValue=false,Flag="Fullbright",
    Callback=function(v) State.Fullbright=v; setFullbright(v) end})

MiscTab:CreateToggle({Name="No Fog",CurrentValue=false,Flag="NoFog",
    Callback=function(v) State.NoFog=v; setNoFog(v) end})

MiscTab:CreateToggle({
    Name="FOV Customizado", CurrentValue=false, Flag="CustomFOV",
    Callback=function(v) State.CustomFOV=v; setCustomFOV(v,State.CustomFOVValue) end,
})

MiscTab:CreateSlider({
    Name="Valor FOV", Range={30,120}, Increment=5, Suffix="°",
    CurrentValue=70, Flag="CustomFOVValue",
    Callback=function(v)
        State.CustomFOVValue=v
        if State.CustomFOV then setCustomFOV(true,v) end
    end,
})

MiscTab:CreateToggle({Name="Mostrar FPS",CurrentValue=false,Flag="ShowFPS",
    Callback=function(v) State.ShowFPS=v end})

MiscTab:CreateSection("Fake Lag")

MiscTab:CreateToggle({
    Name="Fake Lag", CurrentValue=false, Flag="FakeLag",
    Callback=function(v)
        State.FakeLag=v
        setFakeLag(v, State.FakeLagValue)
    end,
})

MiscTab:CreateSlider({
    Name="Intensidade (ms)", Range={0,500}, Increment=10, Suffix="ms",
    CurrentValue=0, Flag="FakeLagValue",
    Callback=function(v)
        State.FakeLagValue=v
        if State.FakeLag then setFakeLag(true,v) end
    end,
})

-- ══════════════════════════════════════════════════════════════
-- TAB 5 — JOGO
-- ══════════════════════════════════════════════════════════════
local GameTab = Window:CreateTab("🎮 Jogo", 4483362458)

GameTab:CreateSection("Info do Servidor")

GameTab:CreateButton({
    Name="Ver Info do Servidor",
    Callback=function()
        Rayfield:Notify({
            Title   = "Servidor",
            Content = string.format("Jogadores: %d\nJob ID: %s", #Players:GetPlayers(), tostring(game.JobId):sub(1,16)),
            Duration = 5,
        })
    end,
})

GameTab:CreateSection("Papéis")

GameTab:CreateButton({
    Name="Ver Papéis de Todos",
    Callback=function()
        local lines = {}
        for _, p in ipairs(Players:GetPlayers()) do
            local role = p:GetAttribute("Role") or "?"
            table.insert(lines, p.Name .. ": " .. role)
        end
        Rayfield:Notify({
            Title   = "Papéis",
            Content = table.concat(lines, "\n"),
            Duration = 8,
        })
    end,
})

GameTab:CreateButton({
    Name="Ver Meu Papel",
    Callback=function()
        local role  = LocalPlayer:GetAttribute("Role") or "Sem papel"
        local kills = LocalPlayer:GetAttribute("Kills") or 0
        local deaths= LocalPlayer:GetAttribute("Deaths") or 0
        Rayfield:Notify({
            Title   = "Meu Status",
            Content = "Papel: "..role.."\nK: "..kills.."  D: "..deaths,
            Duration = 4,
        })
    end,
})

GameTab:CreateSection("Teleporte")

GameTab:CreateButton({
    Name="Teleportar para Alvo Mais Próximo",
    Callback=function()
        local target = getClosestToCursor(9999)
        if not target or not target.Character then
            Rayfield:Notify({Title="Erro",Content="Nenhum alvo encontrado.",Duration=3})
            return
        end
        local root = target.Character:FindFirstChild("HumanoidRootPart")
        local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and myRoot then
            myRoot.CFrame = root.CFrame + Vector3.new(3, 0, 0)
        end
    end,
})

GameTab:CreateSection("Stats")

GameTab:CreateButton({
    Name="Ver Meus Stats",
    Callback=function()
        local k = LocalPlayer:GetAttribute("Kills")  or 0
        local d = LocalPlayer:GetAttribute("Deaths") or 0
        local w = LocalPlayer:GetAttribute("Wins")   or 0
        Rayfield:Notify({
            Title   = "Seus Stats",
            Content = string.format("Kills: %d\nDeaths: %d\nWins: %d", k, d, w),
            Duration = 5,
        })
    end,
})

-- ══════════════════════════════════════════════════════════════
-- TAB 6 — CONFIG
-- ══════════════════════════════════════════════════════════════
local ConfigTab = Window:CreateTab("💾 Config", 4483362458)

ConfigTab:CreateSection("Sobre")
ConfigTab:CreateLabel("MVS DUELS Script v4")
ConfigTab:CreateLabel("BAC_9 bypass via Mouse.__index")
ConfigTab:CreateLabel("Silent Aim | AutoShot | ESP | Skins")

-- ══════════════════════════════════════
-- BOTÃO FLUTUANTE ARRASTÁVEL
-- ══════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "MVSToggle"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
pcall(function() ScreenGui.Parent = CoreGui end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local Btn = Instance.new("TextButton")
Btn.Name              = "MVSBtn"
Btn.Size              = UDim2.new(0, 65, 0, 32)
Btn.Position          = UDim2.new(1, -85, 0.5, -16)
Btn.BackgroundColor3  = Color3.fromRGB(15, 15, 25)
Btn.TextColor3        = Color3.fromRGB(255, 255, 255)
Btn.Text              = "MVS"
Btn.Font              = Enum.Font.GothamBold
Btn.TextSize          = 14
Btn.BorderSizePixel   = 0
Btn.Parent            = ScreenGui

Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 8)
local stroke = Instance.new("UIStroke", Btn)
stroke.Color     = Color3.fromRGB(0, 180, 255)
stroke.Thickness = 1.5

-- Arrastar
local dragging, dragStart, dragOrigin = false, nil, nil
Btn.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging   = true
        dragStart  = i.Position
        dragOrigin = Btn.Position
    end
end)
UserInputService.InputChanged:Connect(function(i)
    if not dragging then return end
    if i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch then
        local delta = i.Position - dragStart
        Btn.Position = UDim2.new(dragOrigin.X.Scale, dragOrigin.X.Offset + delta.X,
                                  dragOrigin.Y.Scale, dragOrigin.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Toggle GUI
local clickT = 0
Btn.MouseButton1Down:Connect(function() clickT = tick() end)
Btn.MouseButton1Up:Connect(function()
    if tick() - clickT < 0.2 and not dragging then
        pcall(function() Rayfield:Toggle() end)
        TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(0,180,255)}):Play()
        task.delay(0.3, function()
            TweenService:Create(Btn, TweenInfo.new(0.15), {BackgroundColor3=Color3.fromRGB(15,15,25)}):Play()
        end)
    end
end)

print("[MVS v4] Script carregado. BAC_9 bypass ativo.")
