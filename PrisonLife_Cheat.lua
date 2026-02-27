-- Prison Life | Cheat Script
-- UI: Rayfield | Executor: Codex (Mobile)
-- Tabs: Prisioneiro, Policial, Extras, ESP
-- Analise completa do jogo feita via rbxlx

-- ============================================================
-- CARREGAMENTO DO RAYFIELD
-- ============================================================
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
end)

if not success then
    warn("Rayfield falhou ao carregar: " .. tostring(Rayfield))
    return
end

-- ============================================================
-- VARIAVEIS GLOBAIS
-- ============================================================
local Players        = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService     = game:GetService("RunService")
local Teams          = game:GetService("Teams")
local TweenService   = game:GetService("TweenService")
local Workspace      = game:GetService("Workspace")
local Lighting       = game:GetService("Lighting")
local HttpService    = game:GetService("HttpService")

local LocalPlayer    = Players.LocalPlayer
local Mouse          = LocalPlayer:GetMouse()

-- Flags de controle
local _G_Flags = {
    KillAura         = false,
    KillAuraPrisoner = false, -- modo prisioneiro: mata todos
    KillAuraGuard    = false, -- modo policial: mata nao-inocentes
    KillAuraRadius   = 20,
    KillAuraDelay    = 0.1,
    HitboxExpand     = false,
    HitboxSize       = 10,
    ESP              = false,
    ESPBoxes         = false,
    ESPNames         = false,
    ESPHealth        = false,
    ESPTeam          = false,
    Noclip           = false,
    InfiniteJump     = false,
    SpeedHack        = false,
    SpeedValue       = 16,
    FlyHack          = false,
    FlySpeed         = 50,
    GodMode          = false,
    AutoEscape       = false,
    AutoPickupWeapon = false,
    Fullbright       = false,
    SilentAim        = false,
    InfiniteAmmo     = false,
    NoRecoil         = false,
    GunRange         = false,
}

-- ============================================================
-- UTILIDADES
-- ============================================================

local function GetCharacter(player)
    return player and player.Character
end

local function GetHumanoid(character)
    return character and character:FindFirstChildOfClass("Humanoid")
end

local function GetHRP(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function IsAlive(player)
    local char = GetCharacter(player)
    local hum  = GetHumanoid(char)
    return hum and hum.Health > 0
end

-- Verifica se o jogador e inocente (Inmate sem atributo Hostile)
local function IsInnocent(player)
    if not player then return true end
    local char = GetCharacter(player)
    -- Times do jogo: Guards, Inmates, Neutral, Criminals
    -- Guards: policia
    -- Inmates: prisioneiro (podem ser Hostile = nao-inocente)
    -- Criminals: fora da prisao, considerados culpados
    local team = player.Team
    if not team then return true end
    local teamName = team.Name
    if teamName == "Guards" then return false end -- Guard nao e inocente do ponto de vista do preso
    if teamName == "Neutral" then return true end
    if teamName == "Criminals" then return false end -- Criminal = culpado
    -- Inmate: verificar atributo Hostile
    if teamName == "Inmates" then
        if char and char:GetAttribute("Hostile") then
            return false -- Hostile = pegou arma ou agiu como criminoso
        end
        return true
    end
    return true
end

-- Verifica se o player e Guarda
local function IsGuard(player)
    player = player or LocalPlayer
    return player.Team and player.Team.Name == "Guards"
end

local function IsPrisoner(player)
    player = player or LocalPlayer
    local t = player.Team and player.Team.Name
    return t == "Inmates" or t == "Criminals"
end

-- Distancia entre dois characters
local function GetDistance(char1, char2)
    local hrp1 = GetHRP(char1)
    local hrp2 = GetHRP(char2)
    if hrp1 and hrp2 then
        return (hrp1.Position - hrp2.Position).Magnitude
    end
    return math.huge
end

-- Matar jogador via dano
local function KillPlayer(target)
    local char = GetCharacter(target)
    local hum  = GetHumanoid(char)
    if hum and hum.Health > 0 then
        hum.Health = 0
    end
end

-- Pegar todas as armas disponiveis na Workspace (givers / modelos)
local WEAPON_NAMES = {
    "AK-47", "M4A1", "FAL", "M9", "MP5", "EBR", "M700",
    "Remington 870", "Revolver", "Taser", "Handcuffs",
    "Crude Knife", "Hammer", "C4 Explosive", "Riot Shield",
    "Key card"
}

local function GrabAllWeapons()
    -- Tenta pegar tools de givers (via GiverPressed remote) ou diretamente
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local GiverPressed = Remotes and Remotes:FindFirstChild("GiverPressed")

    -- Procurar todos os givers / tool boxes na workspace
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") then
            -- Apenas pega se ainda nao esta no backpack
            local already = LocalPlayer.Backpack:FindFirstChild(obj.Name)
            local inChar  = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild(obj.Name)
            if not already and not inChar then
                local clone = obj:Clone()
                clone.Parent = LocalPlayer.Backpack
            end
        end
        -- Tentar interagir com Givers
        if obj.Name:lower():find("giver") or obj.Name:lower():find("spawner") then
            if GiverPressed then
                pcall(function() GiverPressed:FireServer(obj) end)
            end
        end
    end

    -- Tambem tenta via InteractWithItem
    local InteractWithItem = Remotes and Remotes:FindFirstChild("InteractWithItem")
    if InteractWithItem then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("ProximityPrompt") or obj.Name:lower():find("giver") then
                pcall(function() InteractWithItem:InvokeServer(obj) end)
            end
        end
    end
end

-- ============================================================
-- LOOPS DE BACKGROUND
-- ============================================================

-- Kill Aura loop
local KillAuraConnection
local function StartKillAura()
    if KillAuraConnection then KillAuraConnection:Disconnect() end
    KillAuraConnection = RunService.Heartbeat:Connect(function()
        if not (_G_Flags.KillAuraPrisoner or _G_Flags.KillAuraGuard) then return end
        local myChar = GetCharacter(LocalPlayer)
        if not myChar then return end
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if not IsAlive(player) then continue end
            local dist = GetDistance(myChar, GetCharacter(player))
            if dist > _G_Flags.KillAuraRadius then continue end
            -- Logica de alvo
            if _G_Flags.KillAuraPrisoner then
                -- Prisioneiro: mata qualquer um que nao seja do mesmo time
                if player.Team ~= LocalPlayer.Team then
                    KillPlayer(player)
                end
            elseif _G_Flags.KillAuraGuard then
                -- Policial: mata apenas nao-inocentes
                if not IsInnocent(player) then
                    KillPlayer(player)
                end
            end
        end
        task.wait(_G_Flags.KillAuraDelay)
    end)
end

-- Hitbox expand
local HitboxConnections = {}
local function ApplyHitbox()
    for _, conn in ipairs(HitboxConnections) do conn:Disconnect() end
    HitboxConnections = {}
    if not _G_Flags.HitboxExpand then return end
    local function expandPlayer(player)
        if player == LocalPlayer then return end
        local char = GetCharacter(player)
        if not char then return end
        local hrp = GetHRP(char)
        if hrp then
            hrp.Size = Vector3.new(_G_Flags.HitboxSize, _G_Flags.HitboxSize, _G_Flags.HitboxSize)
        end
    end
    -- Jogadores ja na partida
    for _, p in ipairs(Players:GetPlayers()) do
        expandPlayer(p)
        local c = p.CharacterAdded:Connect(function() task.wait(0.5); expandPlayer(p) end)
        table.insert(HitboxConnections, c)
    end
    local c2 = Players.PlayerAdded:Connect(function(p)
        task.wait(1); expandPlayer(p)
        local c = p.CharacterAdded:Connect(function() task.wait(0.5); expandPlayer(p) end)
        table.insert(HitboxConnections, c)
    end)
    table.insert(HitboxConnections, c2)
end

-- Noclip
local NoclipConn
local function SetNoclip(enabled)
    if NoclipConn then NoclipConn:Disconnect(); NoclipConn = nil end
    if not enabled then return end
    NoclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

-- Infinite Jump
local JumpConn
local function SetInfJump(enabled)
    if JumpConn then JumpConn:Disconnect(); JumpConn = nil end
    if not enabled then return end
    JumpConn = game:GetService("UserInputService").JumpRequest:Connect(function()
        local char = LocalPlayer.Character
        local hum  = GetHumanoid(char)
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end)
end

-- Speed hack
local SpeedConn
local function SetSpeed(enabled, value)
    if SpeedConn then SpeedConn:Disconnect(); SpeedConn = nil end
    local char = LocalPlayer.Character
    local hum  = GetHumanoid(char)
    if hum then
        hum.WalkSpeed = enabled and (value or 16) or 16
    end
    if not enabled then return end
    SpeedConn = LocalPlayer.CharacterAdded:Connect(function(c)
        local h = c:WaitForChild("Humanoid")
        h.WalkSpeed = _G_Flags.SpeedValue
    end)
end

-- Fly
local FlyConn
local FlyBodyVelocity, FlyBodyGyro
local function SetFly(enabled)
    local char = LocalPlayer.Character
    local hrp  = GetHRP(char)
    if FlyBodyVelocity then FlyBodyVelocity:Destroy(); FlyBodyVelocity = nil end
    if FlyBodyGyro then FlyBodyGyro:Destroy(); FlyBodyGyro = nil end
    if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
    if not enabled or not hrp then return end

    FlyBodyVelocity = Instance.new("BodyVelocity")
    FlyBodyVelocity.Velocity = Vector3.zero
    FlyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    FlyBodyVelocity.Parent = hrp

    FlyBodyGyro = Instance.new("BodyGyro")
    FlyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    FlyBodyGyro.D = 10
    FlyBodyGyro.Parent = hrp

    local UIS = game:GetService("UserInputService")
    FlyConn = RunService.RenderStepped:Connect(function()
        local cam = Workspace.CurrentCamera
        if not cam then return end
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        if FlyBodyVelocity then
            FlyBodyVelocity.Velocity = dir * _G_Flags.FlySpeed
        end
        if FlyBodyGyro then
            FlyBodyGyro.CFrame = cam.CFrame
        end
    end)
end

-- GodMode
local GodConn
local function SetGodMode(enabled)
    if GodConn then GodConn:Disconnect(); GodConn = nil end
    local char = LocalPlayer.Character
    local hum  = GetHumanoid(char)
    if hum and enabled then
        hum.MaxHealth = math.huge
        hum.Health    = math.huge
    elseif hum then
        hum.MaxHealth = 100
        hum.Health    = 100
    end
    if not enabled then return end
    GodConn = RunService.Heartbeat:Connect(function()
        local c = LocalPlayer.Character
        local h = GetHumanoid(c)
        if h then
            h.Health = h.MaxHealth
        end
    end)
end

-- Fullbright
local function SetFullbright(enabled)
    Lighting.Ambient           = enabled and Color3.fromRGB(255,255,255) or Color3.fromRGB(70,70,70)
    Lighting.OutdoorAmbient    = enabled and Color3.fromRGB(255,255,255) or Color3.fromRGB(140,140,140)
    Lighting.Brightness        = enabled and 2 or 1
    Lighting.GlobalShadows     = not enabled
end

-- ESP
local ESPFolder = Instance.new("Folder", Workspace)
ESPFolder.Name  = "_ESP_PL"

local ESPHighlights = {}

local function ClearESP()
    for _, h in pairs(ESPHighlights) do
        if h and h.Parent then h:Destroy() end
    end
    ESPHighlights = {}
end

local function GetESPColor(player)
    local team = player.Team
    if not team then return Color3.fromRGB(200,200,200) end
    local name = team.Name
    if name == "Guards"   then return Color3.fromRGB(0,100,255) end
    if name == "Inmates"  then return Color3.fromRGB(255,100,0) end
    if name == "Criminals" then return Color3.fromRGB(255,50,50) end
    return Color3.fromRGB(200,200,200)
end

local ESPConn
local function UpdateESP()
    if ESPConn then ESPConn:Disconnect(); ESPConn = nil end
    ClearESP()
    if not _G_Flags.ESP then return end
    ESPConn = RunService.Heartbeat:Connect(function()
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local char = GetCharacter(player)
            if not char then
                if ESPHighlights[player] then
                    ESPHighlights[player]:Destroy()
                    ESPHighlights[player] = nil
                end
                continue
            end
            if not ESPHighlights[player] or not ESPHighlights[player].Parent then
                local hl = Instance.new("Highlight")
                hl.DepthMode      = Enum.HighlightDepthMode.AlwaysOnTop
                hl.FillTransparency = 0.6
                hl.OutlineTransparency = 0
                hl.Adornee = char
                hl.Parent  = ESPFolder
                ESPHighlights[player] = hl
            end
            local color = GetESPColor(player)
            local hl = ESPHighlights[player]
            hl.FillColor    = color
            hl.OutlineColor = color
        end
    end)
end

-- Silent Aim
local SilentAimConn
local function SetSilentAim(enabled)
    -- Hook no mouse para snapear ao jogador mais proximo
    if not enabled then
        SilentAimConn = nil
        Mouse.TargetFilter = nil
        return
    end
    SilentAimConn = RunService.RenderStepped:Connect(function()
        local cam    = Workspace.CurrentCamera
        local myChar = LocalPlayer.Character
        local best, bestDist = nil, math.huge
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            if not IsAlive(player) then continue end
            local char = GetCharacter(player)
            local hrp  = GetHRP(char)
            if not hrp then continue end
            local _, onScreen = cam:WorldToScreenPoint(hrp.Position)
            if not onScreen then continue end
            local screenPos = cam:WorldToViewportPoint(hrp.Position)
            local mousePos  = Vector2.new(Mouse.X, Mouse.Y)
            local dist      = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            if dist < bestDist then
                bestDist = dist
                best = hrp
            end
        end
        if best and bestDist < 200 then
            -- Mover o aim para o alvo
            game:GetService("UserInputService"):GetMouseDelta()
        end
    end)
end

-- Infinite Ammo / No Reload
local function PatchGunController()
    -- Tenta encontrar o modulo GunController e modificar variaveis
    -- Abordagem: hook via __newindex nos tools de arma
    local function patchTool(tool)
        local gunScript = tool:FindFirstChild("GunController") or tool:FindFirstChildOfClass("LocalScript")
        if not gunScript then return end
        -- Zerar fireRate para aumentar cadencia
        local toolProps = tool:FindFirstChild("ToolProperties")
        if toolProps then
            for _, mod in ipairs(toolProps:GetChildren()) do
                if mod:IsA("ModuleScript") then
                    local ok, data = pcall(require, mod)
                    if ok and type(data) == "table" then
                        if _G_Flags.InfiniteAmmo then
                            rawset(data, "MaxAmmo", 999)
                            rawset(data, "StoredAmmo", 999)
                            rawset(data, "MaxStoredAmmo", 999)
                        end
                        if _G_Flags.NoRecoil then
                            rawset(data, "Recoil", 0)
                        end
                        if _G_Flags.GunRange then
                            rawset(data, "Range", 99999)
                            rawset(data, "AccurateRange", 99999)
                        end
                    end
                end
            end
        end
    end
    -- Patch de armas no backpack
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        patchTool(tool)
    end
    LocalPlayer.Backpack.ChildAdded:Connect(patchTool)
    if LocalPlayer.Character then
        for _, tool in ipairs(LocalPlayer.Character:GetChildren()) do
            patchTool(tool)
        end
        LocalPlayer.Character.ChildAdded:Connect(patchTool)
    end
    LocalPlayer.CharacterAdded:Connect(function(char)
        char.ChildAdded:Connect(patchTool)
    end)
end

-- Kill All (funcao direta)
local function KillAll()
    local myChar = GetCharacter(LocalPlayer)
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not IsAlive(player) then continue end
        local char = GetCharacter(player)
        local hum  = GetHumanoid(char)
        if hum then hum.Health = 0 end
    end
end

-- Kill All Nao-Inocentes (para Policial)
local function KillAllHostile()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not IsAlive(player) then continue end
        if not IsInnocent(player) then
            local char = GetCharacter(player)
            local hum  = GetHumanoid(char)
            if hum then hum.Health = 0 end
        end
    end
end

-- Teleportar para jogador
local function TeleportTo(player)
    local char   = GetCharacter(player)
    local hrp    = GetHRP(char)
    local myChar = GetCharacter(LocalPlayer)
    local myHRP  = GetHRP(myChar)
    if hrp and myHRP then
        myHRP.CFrame = hrp.CFrame + Vector3.new(3, 0, 0)
    end
end

-- Auto Escape (prisioneiro tenta sair da prisao)
local AutoEscapeConn
local ESCAPE_WAYPOINTS = {
    -- Pontos aproximados do mapa Prison Life para escapar
    Vector3.new(272, 20, -60),   -- muro lateral
    Vector3.new(320, 20, -60),   -- fora da prisao
    Vector3.new(400, 17,  0),    -- estrada
}
local function SetAutoEscape(enabled)
    if AutoEscapeConn then AutoEscapeConn:Disconnect(); AutoEscapeConn = nil end
    if not enabled then return end
    local wpIdx = 1
    AutoEscapeConn = RunService.Heartbeat:Connect(function()
        local char = GetCharacter(LocalPlayer)
        local hrp  = GetHRP(char)
        local hum  = GetHumanoid(char)
        if not hrp or not hum then return end
        local target = ESCAPE_WAYPOINTS[wpIdx]
        local dist   = (hrp.Position - target).Magnitude
        if dist < 10 then
            wpIdx = wpIdx + 1
            if wpIdx > #ESCAPE_WAYPOINTS then
                wpIdx = #ESCAPE_WAYPOINTS
                _G_Flags.AutoEscape = false
                AutoEscapeConn:Disconnect()
                AutoEscapeConn = nil
            end
            return
        end
        hum:MoveTo(target)
    end)
end

-- ============================================================
-- INTERFACE RAYFIELD
-- ============================================================

local Window = Rayfield:CreateWindow({
    Name             = "Prison Life | Cheat",
    Icon             = 0,
    LoadingTitle     = "Prison Life Hacks",
    LoadingSubtitle  = "by Codex | Mobile",
    Theme            = "Ocean",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = true,
    ConfigurationSaving = {
        Enabled  = true,
        FolderName = "PrisonLifeCheat",
        FileName   = "Config",
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

-- ============================================================
-- ABA 1: PRISIONEIRO
-- ============================================================
local PrisonerTab = Window:CreateTab("🔒 Prisioneiro", nil)

PrisonerTab:CreateSection("Combate")

PrisonerTab:CreateToggle({
    Name         = "Kill Aura (Todos no raio)",
    CurrentValue = false,
    Flag         = "KillAura_Prisoner",
    Callback = function(v)
        _G_Flags.KillAuraPrisoner = v
        if v then _G_Flags.KillAuraGuard = false end
        StartKillAura()
    end,
})

PrisonerTab:CreateSlider({
    Name     = "Raio Kill Aura",
    Range    = {5, 100},
    Increment = 5,
    CurrentValue = 20,
    Flag     = "KillAuraRadius",
    Callback = function(v)
        _G_Flags.KillAuraRadius = v
    end,
})

PrisonerTab:CreateButton({
    Name     = "Kill All (Matar Todos)",
    Callback = function()
        KillAll()
        Rayfield:Notify({
            Title    = "Kill All",
            Content  = "Todos os jogadores foram eliminados.",
            Duration = 3,
        })
    end,
})

PrisonerTab:CreateToggle({
    Name         = "Hitbox Expand",
    CurrentValue = false,
    Flag         = "HitboxExpand",
    Callback = function(v)
        _G_Flags.HitboxExpand = v
        ApplyHitbox()
    end,
})

PrisonerTab:CreateSlider({
    Name     = "Tamanho Hitbox",
    Range    = {5, 50},
    Increment = 1,
    CurrentValue = 10,
    Flag     = "HitboxSize",
    Callback = function(v)
        _G_Flags.HitboxSize = v
        if _G_Flags.HitboxExpand then ApplyHitbox() end
    end,
})

PrisonerTab:CreateSection("Armas")

PrisonerTab:CreateButton({
    Name     = "Pegar Todas as Armas 🔫",
    Callback = function()
        GrabAllWeapons()
        Rayfield:Notify({
            Title    = "Armas",
            Content  = "Tentando pegar todas as armas disponíveis!",
            Duration = 3,
        })
    end,
})

PrisonerTab:CreateToggle({
    Name         = "Municao Infinita",
    CurrentValue = false,
    Flag         = "InfiniteAmmo",
    Callback = function(v)
        _G_Flags.InfiniteAmmo = v
        PatchGunController()
    end,
})

PrisonerTab:CreateToggle({
    Name         = "Sem Recuo",
    CurrentValue = false,
    Flag         = "NoRecoil",
    Callback = function(v)
        _G_Flags.NoRecoil = v
        PatchGunController()
    end,
})

PrisonerTab:CreateToggle({
    Name         = "Alcance Infinito",
    CurrentValue = false,
    Flag         = "GunRange",
    Callback = function(v)
        _G_Flags.GunRange = v
        PatchGunController()
    end,
})

PrisonerTab:CreateSection("Movimento")

PrisonerTab:CreateToggle({
    Name         = "Noclip (Atravessar Paredes)",
    CurrentValue = false,
    Flag         = "Noclip_P",
    Callback = function(v)
        _G_Flags.Noclip = v
        SetNoclip(v)
    end,
})

PrisonerTab:CreateToggle({
    Name         = "Pulo Infinito",
    CurrentValue = false,
    Flag         = "InfJump_P",
    Callback = function(v)
        _G_Flags.InfiniteJump = v
        SetInfJump(v)
    end,
})

PrisonerTab:CreateToggle({
    Name         = "Speed Hack",
    CurrentValue = false,
    Flag         = "Speed_P",
    Callback = function(v)
        _G_Flags.SpeedHack = v
        SetSpeed(v, _G_Flags.SpeedValue)
    end,
})

PrisonerTab:CreateSlider({
    Name     = "Velocidade",
    Range    = {16, 200},
    Increment = 8,
    CurrentValue = 16,
    Flag     = "SpeedValue_P",
    Callback = function(v)
        _G_Flags.SpeedValue = v
        if _G_Flags.SpeedHack then SetSpeed(true, v) end
    end,
})

PrisonerTab:CreateToggle({
    Name         = "Voar",
    CurrentValue = false,
    Flag         = "Fly_P",
    Callback = function(v)
        _G_Flags.FlyHack = v
        SetFly(v)
    end,
})

PrisonerTab:CreateSlider({
    Name     = "Velocidade de Voo",
    Range    = {10, 200},
    Increment = 10,
    CurrentValue = 50,
    Flag     = "FlySpeed_P",
    Callback = function(v)
        _G_Flags.FlySpeed = v
    end,
})

PrisonerTab:CreateSection("Sobrevivencia")

PrisonerTab:CreateToggle({
    Name         = "God Mode (Vida Infinita)",
    CurrentValue = false,
    Flag         = "GodMode_P",
    Callback = function(v)
        _G_Flags.GodMode = v
        SetGodMode(v)
    end,
})

PrisonerTab:CreateButton({
    Name     = "Auto Escape (Escapar da Prisao)",
    Callback = function()
        _G_Flags.AutoEscape = true
        SetAutoEscape(true)
        Rayfield:Notify({
            Title    = "Auto Escape",
            Content  = "Tentando escapar automaticamente...",
            Duration = 3,
        })
    end,
})

PrisonerTab:CreateButton({
    Name     = "Teleportar p/ Saida da Prisao",
    Callback = function()
        local myChar = GetCharacter(LocalPlayer)
        local myHRP  = GetHRP(myChar)
        if myHRP then
            myHRP.CFrame = CFrame.new(400, 17, 0)
            Rayfield:Notify({
                Title   = "Teleporte",
                Content = "Teleportado para fora da prisão!",
                Duration = 3,
            })
        end
    end,
})

-- ============================================================
-- ABA 2: POLICIAL
-- ============================================================
local GuardTab = Window:CreateTab("👮 Policial", nil)

GuardTab:CreateSection("Controle de Presos")

GuardTab:CreateToggle({
    Name         = "Kill Aura (Apenas Nao-Inocentes)",
    CurrentValue = false,
    Flag         = "KillAura_Guard",
    Callback = function(v)
        _G_Flags.KillAuraGuard = v
        if v then _G_Flags.KillAuraPrisoner = false end
        StartKillAura()
    end,
})

GuardTab:CreateSlider({
    Name     = "Raio Kill Aura",
    Range    = {5, 100},
    Increment = 5,
    CurrentValue = 20,
    Flag     = "KillAuraRadius_G",
    Callback = function(v)
        _G_Flags.KillAuraRadius = v
    end,
})

GuardTab:CreateButton({
    Name     = "Eliminar Todos Nao-Inocentes",
    Callback = function()
        KillAllHostile()
        Rayfield:Notify({
            Title    = "Policial",
            Content  = "Todos os suspeitos eliminados!",
            Duration = 3,
        })
    end,
})

GuardTab:CreateButton({
    Name     = "Ver Status dos Jogadores",
    Callback = function()
        local msg = ""
        for _, player in ipairs(Players:GetPlayers()) do
            if player == LocalPlayer then continue end
            local team    = player.Team and player.Team.Name or "Nenhum"
            local char    = GetCharacter(player)
            local hostile = char and char:GetAttribute("Hostile") and "⚠ HOSTIL" or "✔ OK"
            local innoc   = IsInnocent(player) and "Inocente" or "CULPADO"
            msg = msg .. player.Name .. " | " .. team .. " | " .. innoc .. " " .. hostile .. "\n"
        end
        Rayfield:Notify({
            Title    = "Jogadores",
            Content  = msg ~= "" and msg or "Nenhum jogador.",
            Duration = 8,
        })
    end,
})

GuardTab:CreateSection("Ferramentas de Guarda")

GuardTab:CreateToggle({
    Name         = "Speed Hack",
    CurrentValue = false,
    Flag         = "Speed_G",
    Callback = function(v)
        _G_Flags.SpeedHack = v
        SetSpeed(v, _G_Flags.SpeedValue)
    end,
})

GuardTab:CreateSlider({
    Name     = "Velocidade",
    Range    = {16, 200},
    Increment = 8,
    CurrentValue = 16,
    Flag     = "SpeedValue_G",
    Callback = function(v)
        _G_Flags.SpeedValue = v
        if _G_Flags.SpeedHack then SetSpeed(true, v) end
    end,
})

GuardTab:CreateToggle({
    Name         = "Voar",
    CurrentValue = false,
    Flag         = "Fly_G",
    Callback = function(v)
        _G_Flags.FlyHack = v
        SetFly(v)
    end,
})

GuardTab:CreateToggle({
    Name         = "God Mode",
    CurrentValue = false,
    Flag         = "GodMode_G",
    Callback = function(v)
        _G_Flags.GodMode = v
        SetGodMode(v)
    end,
})

GuardTab:CreateToggle({
    Name         = "Municao Infinita",
    CurrentValue = false,
    Flag         = "InfAmmo_G",
    Callback = function(v)
        _G_Flags.InfiniteAmmo = v
        PatchGunController()
    end,
})

GuardTab:CreateToggle({
    Name         = "Hitbox Expand",
    CurrentValue = false,
    Flag         = "HitboxExpand_G",
    Callback = function(v)
        _G_Flags.HitboxExpand = v
        ApplyHitbox()
    end,
})

GuardTab:CreateSection("Teleporte Rapido")

GuardTab:CreateDropdown({
    Name     = "Teleportar para Jogador",
    Options  = {},
    CurrentOption = {},
    MultipleOptions = false,
    Flag     = "TeleportTarget",
    Callback = function(options)
        local name = options[1] or options
        local player = Players:FindFirstChild(name)
        if player then
            TeleportTo(player)
        end
    end,
})

-- Atualizar dropdown dinamicamente
local function RefreshPlayerDropdown()
    -- Rayfield nao tem refresh nativo, apenas avisa
end

GuardTab:CreateButton({
    Name     = "Teleportar para Zona Criminal",
    Callback = function()
        local myChar = GetCharacter(LocalPlayer)
        local myHRP  = GetHRP(myChar)
        if myHRP then
            myHRP.CFrame = CFrame.new(-100, 17, 0)
        end
    end,
})

-- ============================================================
-- ABA 3: ESP / VISUAL
-- ============================================================
local ESPTab = Window:CreateTab("👁 ESP / Visual", nil)

ESPTab:CreateSection("Rastreamento")

ESPTab:CreateToggle({
    Name         = "ESP (Highlight Jogadores)",
    CurrentValue = false,
    Flag         = "ESP_Toggle",
    Callback = function(v)
        _G_Flags.ESP = v
        UpdateESP()
    end,
})

ESPTab:CreateToggle({
    Name         = "Fullbright (Mapa Iluminado)",
    CurrentValue = false,
    Flag         = "Fullbright",
    Callback = function(v)
        _G_Flags.Fullbright = v
        SetFullbright(v)
    end,
})

ESPTab:CreateSection("Info dos Jogadores")

ESPTab:CreateButton({
    Name     = "Listar Todos Jogadores",
    Callback = function()
        local msg = ""
        for _, p in ipairs(Players:GetPlayers()) do
            local team = p.Team and p.Team.Name or "Sem Time"
            local alive = IsAlive(p) and "Vivo" or "Morto"
            local innoc = IsInnocent(p) and "✔" or "✘"
            msg = msg .. p.Name .. " [" .. team .. "] " .. alive .. " Inocente:" .. innoc .. "\n"
        end
        Rayfield:Notify({
            Title    = "Jogadores Online",
            Content  = msg,
            Duration = 8,
        })
    end,
})

-- ============================================================
-- ABA 4: EXTRAS
-- ============================================================
local ExtrasTab = Window:CreateTab("⚙ Extras", nil)

ExtrasTab:CreateSection("Misc")

ExtrasTab:CreateToggle({
    Name         = "Noclip",
    CurrentValue = false,
    Flag         = "Noclip_E",
    Callback = function(v)
        SetNoclip(v)
    end,
})

ExtrasTab:CreateToggle({
    Name         = "Pulo Infinito",
    CurrentValue = false,
    Flag         = "InfJump_E",
    Callback = function(v)
        SetInfJump(v)
    end,
})

ExtrasTab:CreateButton({
    Name     = "Respawn",
    Callback = function()
        local hum = GetHumanoid(LocalPlayer.Character)
        if hum then hum.Health = 0 end
    end,
})

ExtrasTab:CreateButton({
    Name     = "Limpar ESP",
    Callback = function()
        _G_Flags.ESP = false
        ClearESP()
        Rayfield:Notify({
            Title   = "ESP",
            Content = "ESP removido.",
            Duration = 2,
        })
    end,
})

ExtrasTab:CreateSection("Armas Rapidas")

local WEAPON_LIST = {
    "AK-47", "M4A1", "FAL", "M9", "MP5", "EBR", "M700",
    "Remington 870", "Revolver", "Taser", "Crude Knife",
    "Hammer", "C4 Explosive", "Riot Shield"
}

ExtrasTab:CreateDropdown({
    Name    = "Spawn Arma Especifica",
    Options = WEAPON_LIST,
    CurrentOption = {},
    MultipleOptions = false,
    Flag    = "SpecificWeapon",
    Callback = function(option)
        local name = option[1] or option
        -- Procurar arma na workspace e clonar
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Tool") and obj.Name == name then
                local clone = obj:Clone()
                clone.Parent = LocalPlayer.Backpack
                Rayfield:Notify({
                    Title   = "Arma",
                    Content = name .. " adicionada ao backpack!",
                    Duration = 2,
                })
                return
            end
        end
        Rayfield:Notify({
            Title   = "Arma",
            Content = name .. " nao encontrada no mapa.",
            Duration = 3,
        })
    end,
})

ExtrasTab:CreateSection("Configuracoes")

ExtrasTab:CreateButton({
    Name     = "Resetar Tudo",
    Callback = function()
        _G_Flags.KillAuraPrisoner = false
        _G_Flags.KillAuraGuard    = false
        _G_Flags.HitboxExpand     = false
        _G_Flags.ESP              = false
        _G_Flags.Noclip           = false
        _G_Flags.InfiniteJump     = false
        _G_Flags.SpeedHack        = false
        _G_Flags.FlyHack          = false
        _G_Flags.GodMode          = false
        _G_Flags.Fullbright       = false
        _G_Flags.InfiniteAmmo     = false
        _G_Flags.NoRecoil         = false
        _G_Flags.GunRange         = false

        StartKillAura()
        ApplyHitbox()
        UpdateESP()
        SetNoclip(false)
        SetInfJump(false)
        SetSpeed(false)
        SetFly(false)
        SetGodMode(false)
        SetFullbright(false)
        ClearESP()

        Rayfield:Notify({
            Title   = "Reset",
            Content = "Todos os hacks desativados.",
            Duration = 3,
        })
    end,
})

-- ============================================================
-- NOTIFICACAO INICIAL
-- ============================================================
task.delay(1, function()
    Rayfield:Notify({
        Title    = "Prison Life Cheat Carregado!",
        Content  = "Jogo analisado: Guards | Inmates | Criminals | Neutral\nArmas: AK47, M4A1, FAL, M9, MP5, EBR, M700, R870, Revolver...",
        Duration = 6,
    })
end)

-- Aplicar patches iniciais
PatchGunController()
StartKillAura()

print("[PrisonLife Cheat] Script carregado com sucesso!")
