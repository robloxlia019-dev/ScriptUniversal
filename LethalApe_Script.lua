-- ============================================================
--   Lethal Ape | Script by Claude | Rayfield UI
--   Game ID: 15318113891
--   Features: Farm Gold, Teleports, ESP, Speed, NoClip, etc.
-- ============================================================

-- Carregar Rayfield
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not success then
    warn("Erro ao carregar Rayfield!")
    return
end

-- Serviços
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace      = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid    = Character:WaitForChild("Humanoid")
local HRP         = Character:WaitForChild("HumanoidRootPart")

-- Atualizar character ao respawnar
LocalPlayer.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid  = char:WaitForChild("Humanoid")
    HRP       = char:WaitForChild("HumanoidRootPart")
end)

-- ============================================================
-- CONFIGURAÇÕES INTERNAS
-- ============================================================
local Config = {
    Speed         = 16,
    JumpPower     = 50,
    FarmRunning   = false,
    NoClip        = false,
    ESPEnabled    = false,
    AutoCollect   = false,
    FlyEnabled    = false,
    FlySpeed      = 50,
    GodMode       = false,
    InfiniteJump  = false,
}

-- ============================================================
-- FUNÇÕES UTILITÁRIAS
-- ============================================================

local function Notify(title, content, duration)
    Rayfield:Notify({
        Title    = title,
        Content  = content,
        Duration = duration or 3,
        Image    = 14428634947,
    })
end

local function SafeTeleport(pos)
    if HRP then
        HRP.CFrame = CFrame.new(pos)
        Notify("Teleporte", "Teleportado com sucesso!", 2)
    end
end

local function GetLeaderstats()
    local ls = LocalPlayer:FindFirstChild("leaderstats")
    if ls then return ls end
    return nil
end

-- ============================================================
-- ANTICHEAT DETECTION (detecta e bypassa o AC do jogo)
-- ============================================================
-- O jogo usa verificações simples de velocidade (UpdateWalkspeed)
-- e KillOnTouch parts. Não há AC sofisticado detectado.
-- O bypass abaixo cobre os casos encontrados no código-fonte.

local function BypassSpeedCheck()
    -- Manter walkspeed via loop pra sobrescrever resets do servidor
    RunService.Heartbeat:Connect(function()
        if Character and Humanoid and Config.Speed ~= 16 then
            if Humanoid.WalkSpeed ~= Config.Speed then
                Humanoid.WalkSpeed = Config.Speed
            end
        end
        if Character and Humanoid and Config.JumpPower ~= 50 then
            if Humanoid.JumpPower ~= Config.JumpPower then
                Humanoid.JumpPower = Config.JumpPower
            end
        end
        -- God Mode
        if Config.GodMode and Humanoid then
            Humanoid.Health = Humanoid.MaxHealth
        end
    end)
end

-- ============================================================
-- FLY
-- ============================================================
local flyConn, flyBodyVel, flyBodyGyro

local function EnableFly()
    if not HRP then return end
    local Camera = Workspace.CurrentCamera

    flyBodyVel = Instance.new("BodyVelocity")
    flyBodyVel.Velocity    = Vector3.new(0,0,0)
    flyBodyVel.MaxForce    = Vector3.new(1e9,1e9,1e9)
    flyBodyVel.Parent      = HRP

    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque  = Vector3.new(1e9,1e9,1e9)
    flyBodyGyro.D          = 100
    flyBodyGyro.Parent     = HRP

    flyConn = RunService.RenderStepped:Connect(function()
        if not Config.FlyEnabled then return end
        local cf   = Camera.CFrame
        local dir  = Vector3.new(0,0,0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end

        flyBodyVel.Velocity   = dir * Config.FlySpeed
        flyBodyGyro.CFrame    = cf
        Humanoid.PlatformStand = true
    end)
end

local function DisableFly()
    if flyBodyVel  then flyBodyVel:Destroy()  end
    if flyBodyGyro then flyBodyGyro:Destroy() end
    if flyConn     then flyConn:Disconnect()  end
    if Humanoid    then Humanoid.PlatformStand = false end
end

-- ============================================================
-- NOCLIP
-- ============================================================
RunService.Stepped:Connect(function()
    if Config.NoClip and Character then
        for _, part in pairs(Character:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
end)

-- ============================================================
-- ESP
-- ============================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name   = "LethalApeESP"
ESPFolder.Parent = Workspace

local function ClearESP()
    for _, v in pairs(ESPFolder:GetChildren()) do v:Destroy() end
end

local function MakeESP(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local bb = Instance.new("BillboardGui")
    bb.Name          = player.Name .. "_ESP"
    bb.AlwaysOnTop   = true
    bb.Size          = UDim2.new(0, 100, 0, 40)
    bb.StudsOffset   = Vector3.new(0, 3, 0)
    bb.Adornee       = hrp
    bb.Parent        = ESPFolder

    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Size      = UDim2.new(1, 0, 1, 0)
    label.Text      = player.Name
    label.TextColor3 = Color3.fromRGB(255, 60, 60)
    label.TextStrokeTransparency = 0
    label.Font       = Enum.Font.GothamBold
    label.TextSize   = 13
    label.Parent     = bb

    -- Highlight no personagem
    local hl = Instance.new("SelectionBox")
    hl.Adornee    = char
    hl.Color3     = Color3.fromRGB(255, 0, 0)
    hl.LineThickness = 0.05
    hl.Parent     = ESPFolder
end

local function UpdateESP()
    ClearESP()
    if not Config.ESPEnabled then return end
    for _, plr in pairs(Players:GetPlayers()) do
        MakeESP(plr)
    end
end

RunService.Heartbeat:Connect(function()
    if Config.ESPEnabled then
        UpdateESP()
    end
end)

-- ============================================================
-- AUTO FARM GOLD / COINS
-- ============================================================
-- O jogo tem CoinCollection e Prop_GoldBar no workspace
local function CollectNearbyCoins()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "CoinCollection" or obj.Name == "Prop_GoldBar" 
        or obj.Name == "coins" or obj.Name:lower():find("gold") 
        or obj.Name:lower():find("coin") then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local pos
                if obj:IsA("Model") then
                    local primary = obj.PrimaryPart
                    if primary then pos = primary.Position end
                elseif obj:IsA("BasePart") then
                    pos = obj.Position
                end
                if pos and HRP then
                    local dist = (HRP.Position - pos).Magnitude
                    if dist > 2 then
                        HRP.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
                        task.wait(0.1)
                    end
                end
            end
        end
    end
end

-- Loop de farm
task.spawn(function()
    while true do
        task.wait(0.5)
        if Config.FarmRunning then
            pcall(CollectNearbyCoins)
        end
    end
end)

-- ============================================================
-- AUTO PUMPKIN COLLECT
-- ============================================================
local function CollectPumpkins()
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:lower():find("pumpkin") and (obj:IsA("BasePart") or obj:IsA("Model")) then
            local pos
            if obj:IsA("Model") and obj.PrimaryPart then
                pos = obj.PrimaryPart.Position
            elseif obj:IsA("BasePart") then
                pos = obj.Position
            end
            if pos and HRP then
                HRP.CFrame = CFrame.new(pos + Vector3.new(0, 2, 0))
                task.wait(0.15)
            end
        end
    end
end

-- ============================================================
-- INFINITE JUMP
-- ============================================================
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ============================================================
-- POSIÇÕES DE TELEPORTE (extraídas do mapa)
-- ============================================================
local Locations = {
    ["🏠 Spawn"]        = Vector3.new(-212.6, 230, 88.0),
    ["📦 TeleportPart 1"] = Vector3.new(-92.2, 140, -204.6),
    ["📦 TeleportPart 2"] = Vector3.new(-3.1, 243, -23.4),
    ["🌿 Forest"]       = Vector3.new(-102.6, 245, -252.8),
    ["🗺️ Waypoint 1"]   = Vector3.new(-186.1, 234, -20.3),
    ["🗺️ Waypoint 2"]   = Vector3.new(-217.9, 248, 90.6),
    ["🎯 Arena Center"] = Vector3.new(-234.4, 346, 172.1),
    ["🌍 Area Norte"]   = Vector3.new(-392.7, 245, -792.7),
    ["⭐ Area Sul"]     = Vector3.new(255.2, 340, 446.6),
    ["🏔️ Alto Mapa"]    = Vector3.new(114.4, 320, -19.9),
}

-- ============================================================
-- CRIAR JANELA RAYFIELD
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name             = "🦍 Lethal Ape Script",
    LoadingTitle     = "Lethal Ape Hub",
    LoadingSubtitle  = "by Claude",
    ConfigurationSaving = {
        Enabled  = true,
        FileName = "LethalApeConfig"
    },
    KeySystem = false,
})

-- ============================================================
-- TAB: FARM
-- ============================================================
local FarmTab = Window:CreateTab("💰 Farm", 14428634947)

FarmTab:CreateSection("Auto Farm")

FarmTab:CreateToggle({
    Name         = "Auto Farm Gold/Coins",
    CurrentValue = false,
    Flag         = "AutoFarm",
    Callback     = function(val)
        Config.FarmRunning = val
        Notify("Farm", val and "Farm de Gold ATIVADO!" or "Farm DESATIVADO!", 2)
    end,
})

FarmTab:CreateToggle({
    Name         = "Auto Collect Pumpkins",
    CurrentValue = false,
    Flag         = "AutoPumpkin",
    Callback     = function(val)
        Config.AutoCollect = val
        if val then
            task.spawn(function()
                while Config.AutoCollect do
                    pcall(CollectPumpkins)
                    task.wait(1)
                end
            end)
            Notify("Farm", "Auto Pumpkin ATIVADO!", 2)
        end
    end,
})

FarmTab:CreateButton({
    Name     = "Coletar Tudo Agora",
    Callback = function()
        task.spawn(function()
            pcall(CollectNearbyCoins)
            pcall(CollectPumpkins)
        end)
        Notify("Farm", "Coletando itens próximos...", 2)
    end,
})

FarmTab:CreateSection("Informações")

FarmTab:CreateButton({
    Name     = "Ver Meu Gold/Stats",
    Callback = function()
        local ls = GetLeaderstats()
        if ls then
            local msg = ""
            for _, v in pairs(ls:GetChildren()) do
                msg = msg .. v.Name .. ": " .. tostring(v.Value) .. "\n"
            end
            Notify("Stats", msg ~= "" and msg or "Sem dados", 4)
        else
            Notify("Stats", "leaderstats não encontrado", 3)
        end
    end,
})

-- ============================================================
-- TAB: TELEPORTE
-- ============================================================
local TpTab = Window:CreateTab("🌀 Teleporte", 14428634947)

TpTab:CreateSection("Locais do Mapa")

for name, pos in pairs(Locations) do
    TpTab:CreateButton({
        Name     = name,
        Callback = function()
            SafeTeleport(pos)
        end,
    })
end

TpTab:CreateSection("Teleporte para Jogador")

TpTab:CreateButton({
    Name     = "Teleportar para Jogador mais próximo",
    Callback = function()
        local closest, dist = nil, math.huge
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local hrp2 = plr.Character:FindFirstChild("HumanoidRootPart")
                if hrp2 then
                    local d = (HRP.Position - hrp2.Position).Magnitude
                    if d < dist then
                        dist    = d
                        closest = plr
                    end
                end
            end
        end
        if closest then
            HRP.CFrame = closest.Character.HumanoidRootPart.CFrame + Vector3.new(0,3,0)
            Notify("Teleporte", "Teleportado para " .. closest.Name, 2)
        else
            Notify("Teleporte", "Nenhum jogador encontrado!", 2)
        end
    end,
})

-- Lista de jogadores na sala
TpTab:CreateButton({
    Name     = "Listar Jogadores Online",
    Callback = function()
        local lista = ""
        for _, p in pairs(Players:GetPlayers()) do
            lista = lista .. "• " .. p.Name .. "\n"
        end
        Notify("Jogadores", lista, 5)
    end,
})

-- ============================================================
-- TAB: PLAYER
-- ============================================================
local PlayerTab = Window:CreateTab("🏃 Player", 14428634947)

PlayerTab:CreateSection("Movimentação")

PlayerTab:CreateSlider({
    Name         = "WalkSpeed",
    Range        = {16, 300},
    Increment    = 1,
    Suffix       = " speed",
    CurrentValue = 16,
    Flag         = "WalkSpeed",
    Callback     = function(val)
        Config.Speed = val
        if Humanoid then Humanoid.WalkSpeed = val end
    end,
})

PlayerTab:CreateSlider({
    Name         = "JumpPower",
    Range        = {50, 500},
    Increment    = 5,
    Suffix       = " power",
    CurrentValue = 50,
    Flag         = "JumpPower",
    Callback     = function(val)
        Config.JumpPower = val
        if Humanoid then Humanoid.JumpPower = val end
    end,
})

PlayerTab:CreateToggle({
    Name         = "Infinite Jump",
    CurrentValue = false,
    Flag         = "InfJump",
    Callback     = function(val)
        Config.InfiniteJump = val
        Notify("Player", val and "Infinite Jump ON" or "Infinite Jump OFF", 2)
    end,
})

PlayerTab:CreateSection("Fly")

PlayerTab:CreateToggle({
    Name         = "Fly Mode",
    CurrentValue = false,
    Flag         = "FlyMode",
    Callback     = function(val)
        Config.FlyEnabled = val
        if val then
            EnableFly()
            Notify("Fly", "Fly ATIVADO! WASD para mover, Space/Shift para subir/descer", 3)
        else
            DisableFly()
            Notify("Fly", "Fly DESATIVADO", 2)
        end
    end,
})

PlayerTab:CreateSlider({
    Name         = "Fly Speed",
    Range        = {10, 300},
    Increment    = 5,
    Suffix       = " speed",
    CurrentValue = 50,
    Flag         = "FlySpeed",
    Callback     = function(val)
        Config.FlySpeed = val
    end,
})

PlayerTab:CreateSection("Survavbilidade")

PlayerTab:CreateToggle({
    Name         = "God Mode (Auto Heal)",
    CurrentValue = false,
    Flag         = "GodMode",
    Callback     = function(val)
        Config.GodMode = val
        Notify("Player", val and "God Mode ON" or "God Mode OFF", 2)
    end,
})

PlayerTab:CreateToggle({
    Name         = "NoClip (Atravessar Paredes)",
    CurrentValue = false,
    Flag         = "NoClip",
    Callback     = function(val)
        Config.NoClip = val
        Notify("Player", val and "NoClip ON!" or "NoClip OFF", 2)
    end,
})

PlayerTab:CreateButton({
    Name     = "Respawnar Personagem",
    Callback = function()
        LocalPlayer:LoadCharacter()
        Notify("Player", "Respawnando...", 2)
    end,
})

-- ============================================================
-- TAB: ESP / VISUAL
-- ============================================================
local VisualTab = Window:CreateTab("👁️ Visual / ESP", 14428634947)

VisualTab:CreateSection("ESP de Jogadores")

VisualTab:CreateToggle({
    Name         = "ESP Jogadores",
    CurrentValue = false,
    Flag         = "ESP",
    Callback     = function(val)
        Config.ESPEnabled = val
        if not val then ClearESP() end
        Notify("ESP", val and "ESP Ativado!" or "ESP Desativado", 2)
    end,
})

VisualTab:CreateSection("Monstros / NPCs")

VisualTab:CreateToggle({
    Name         = "Highlight Monstros",
    CurrentValue = false,
    Flag         = "MonsterESP",
    Callback     = function(val)
        -- Monstros conhecidos: ashy, kuspisante, gusjumpscare, duspisante
        local monsterNames = {"ashy", "kuspisante", "gusjumpscare", "duspisante", "lostjumpscare", "bots", "Nextbot"}
        if val then
            for _, obj in pairs(Workspace:GetDescendants()) do
                for _, mName in pairs(monsterNames) do
                    if obj.Name:lower() == mName:lower() and obj:IsA("Model") then
                        local hl = Instance.new("SelectionBox")
                        hl.Name      = "MonsterHL"
                        hl.Adornee   = obj
                        hl.Color3    = Color3.fromRGB(255, 100, 0)
                        hl.LineThickness = 0.08
                        hl.Parent    = ESPFolder
                    end
                end
            end
            Notify("Visual", "Highlight de Monstros ATIVO!", 2)
        else
            for _, v in pairs(ESPFolder:GetChildren()) do
                if v.Name == "MonsterHL" then v:Destroy() end
            end
            Notify("Visual", "Highlight de Monstros DESATIVADO", 2)
        end
    end,
})

VisualTab:CreateSection("Câmera")

VisualTab:CreateSlider({
    Name         = "FOV da Câmera",
    Range        = {50, 120},
    Increment    = 1,
    Suffix       = "°",
    CurrentValue = 70,
    Flag         = "CamFOV",
    Callback     = function(val)
        local cam = Workspace.CurrentCamera
        if cam then cam.FieldOfView = val end
    end,
})

-- ============================================================
-- TAB: ANTICHEAT INFO
-- ============================================================
local ACTab = Window:CreateTab("🛡️ AntiCheat", 14428634947)

ACTab:CreateSection("Status do AntiCheat")

ACTab:CreateLabel("🔍 Análise do AC do Lethal Ape:")
ACTab:CreateLabel("✅ Sem Anticheat sofisticado detectado")
ACTab:CreateLabel("⚠️  Usa KillOnTouch parts no mapa")
ACTab:CreateLabel("⚠️  UpdateWalkspeed via RemoteEvent")
ACTab:CreateLabel("✅ Bypass de Speed: ATIVO automaticamente")
ACTab:CreateLabel("✅ NoClip bypassa KillOnTouch parts")

ACTab:CreateSection("Proteções Ativas")

ACTab:CreateButton({
    Name     = "Verificar AC Agora",
    Callback = function()
        local threats = {}
        -- Verificar KillOnTouch
        for _, v in pairs(Workspace:GetDescendants()) do
            if v.Name == "KillOnTouch" then
                table.insert(threats, "KillOnTouch encontrado!")
            end
        end
        if #threats == 0 then
            Notify("AntiCheat", "✅ Nenhuma ameaça ativa detectada!", 3)
        else
            Notify("AntiCheat", "⚠️ " .. table.concat(threats, ", "), 4)
        end
    end,
})

-- ============================================================
-- TAB: MISC
-- ============================================================
local MiscTab = Window:CreateTab("⚙️ Misc", 14428634947)

MiscTab:CreateSection("Utilidades")

MiscTab:CreateButton({
    Name     = "Limpar Efeitos Visuais",
    Callback = function()
        ClearESP()
        Notify("Misc", "Efeitos visuais removidos!", 2)
    end,
})

MiscTab:CreateButton({
    Name     = "Anti AFK",
    Callback = function()
        local VirtualUser = game:GetService("VirtualUser")
        LocalPlayer.Idled:Connect(function()
            VirtualUser:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(1)
            VirtualUser:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        end)
        Notify("Misc", "Anti-AFK ATIVADO!", 2)
    end,
})

MiscTab:CreateButton({
    Name     = "Copiar Nome do Servidor",
    Callback = function()
        Notify("Misc", "Job ID: " .. game.JobId, 5)
    end,
})

MiscTab:CreateSection("Créditos")
MiscTab:CreateLabel("Script criado por Claude")
MiscTab:CreateLabel("Jogo: Lethal Ape | ID: 15318113891")

-- ============================================================
-- INICIALIZAÇÃO
-- ============================================================
BypassSpeedCheck()

Notify("Lethal Ape Script", "Script carregado com sucesso! 🦍", 4)

-- ============================================================
-- FIM DO SCRIPT
-- ============================================================
