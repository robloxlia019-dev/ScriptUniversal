-- ╔══════════════════════════════════════════╗
-- ║    LETHAL APE ULTIMATE - SCRIPT HUB      ║
-- ║         com Rayfield UI Library          ║
-- ╚══════════════════════════════════════════╝

-- Carrega o Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ═══════════════════════════════════════════
--              SERVIÇOS & VARS
-- ═══════════════════════════════════════════
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local Workspace      = game:GetService("Workspace")
local TweenService   = game:GetService("TweenService")
local LocalPlayer    = Players.LocalPlayer
local Camera         = Workspace.CurrentCamera

-- Flags de controle
local Flags = {
    GoldFarm     = false,
    MonsterESP   = false,
    GoldESP      = false,
    AutoCollect  = false,
    Noclip       = false,
    SpeedHack    = false,
    SpeedValue   = 16,
}

-- Conexões ativas (para limpeza)
local Connections = {}
local ESPObjects  = {}

-- ═══════════════════════════════════════════
--            FUNÇÕES UTILITÁRIAS
-- ═══════════════════════════════════════════

-- Teleporte seguro
local function Teleport(position)
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        char.HumanoidRootPart.CFrame = CFrame.new(position + Vector3.new(0, 3, 0))
    end
end

-- Cria um highlight / ESP em uma instância
local function CreateESP(instance, color, label)
    -- Remove ESP existente
    local old = instance:FindFirstChild("_ESP_Highlight")
    if old then old:Destroy() end
    local oldBill = instance:FindFirstChild("_ESP_Bill")
    if oldBill then oldBill:Destroy() end

    -- Highlight
    local hl = Instance.new("Highlight")
    hl.Name = "_ESP_Highlight"
    hl.FillColor = color
    hl.OutlineColor = Color3.new(1, 1, 1)
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = instance

    -- Billboard com distância
    local billGui = Instance.new("BillboardGui")
    billGui.Name = "_ESP_Bill"
    billGui.AlwaysOnTop = true
    billGui.Size = UDim2.new(0, 100, 0, 40)
    billGui.StudsOffset = Vector3.new(0, 3, 0)
    billGui.Parent = instance

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.TextColor3 = color
    txt.TextStrokeTransparency = 0
    txt.TextStrokeColor3 = Color3.new(0, 0, 0)
    txt.Font = Enum.Font.GothamBold
    txt.TextScaled = true
    txt.Parent = billGui

    -- Atualiza label com distância
    local conn = RunService.RenderStepped:Connect(function()
        if not instance or not instance.Parent then
            hl:Destroy()
            billGui:Destroy()
            return
        end
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local pos = instance:IsA("Model") and instance:GetPivot().Position
                or (instance:FindFirstChild("HumanoidRootPart") and instance.HumanoidRootPart.Position)
                or (instance:IsA("BasePart") and instance.Position)
                or Vector3.new(0,0,0)
            local dist = math.floor((hrp.Position - pos).Magnitude)
            txt.Text = label .. "\n[" .. dist .. "m]"
        end
    end)

    table.insert(ESPObjects, {hl = hl, bill = billGui, conn = conn})
    return hl, billGui
end

-- Remove todos os ESPs
local function ClearAllESP()
    for _, obj in pairs(ESPObjects) do
        if obj.conn then obj.conn:Disconnect() end
        if obj.hl and obj.hl.Parent then obj.hl:Destroy() end
        if obj.bill and obj.bill.Parent then obj.bill:Destroy() end
    end
    ESPObjects = {}
end

-- Encontra todos os objetos de Ouro no workspace
local function GetGoldObjects()
    local golds = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if (name == "goldball" or name == "goldbar" or name:find("gold") or name:find("coin"))
            and (obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("Model")) then
            -- Evita duplicatas de Model vs Part
            if obj:IsA("Model") or (obj:IsA("BasePart") and not obj.Parent:IsA("Model")) then
                table.insert(golds, obj)
            end
        end
    end
    return golds
end

-- Encontra todos os monstros
local function GetMonsters()
    local monsters = {}
    -- Verifica pasta Monsters
    local folder = Workspace:FindFirstChild("Monsters") or Workspace:FindFirstChild("monster")
    if folder then
        for _, m in pairs(folder:GetChildren()) do
            if m:IsA("Model") and m:FindFirstChild("Humanoid") then
                table.insert(monsters, m)
            end
        end
    end
    -- Busca global por humanoides não-player
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            if obj ~= LocalPlayer.Character then
                local isPlayer = false
                for _, p in pairs(Players:GetPlayers()) do
                    if p.Character == obj then isPlayer = true; break end
                end
                if not isPlayer then
                    -- Evita duplicatas
                    local found = false
                    for _, m in pairs(monsters) do if m == obj then found = true; break end end
                    if not found then
                        table.insert(monsters, obj)
                    end
                end
            end
        end
    end
    return monsters
end

-- ═══════════════════════════════════════════
--          SISTEMA GOLD FARM
-- ═══════════════════════════════════════════

local goldFarmConn = nil

local function StartGoldFarm()
    if goldFarmConn then goldFarmConn:Disconnect() end
    
    goldFarmConn = RunService.Heartbeat:Connect(function()
        if not Flags.GoldFarm then return end
        
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        
        local hrp = char.HumanoidRootPart
        local golds = GetGoldObjects()
        
        if #golds == 0 then
            -- Sem ouro disponível, espera spawnar
            return
        end
        
        -- Encontra o ouro mais próximo
        local nearest = nil
        local nearestDist = math.huge
        
        for _, g in pairs(golds) do
            local pos
            if g:IsA("Model") then
                local ok, pivot = pcall(function() return g:GetPivot().Position end)
                if ok then pos = pivot end
            elseif g:IsA("BasePart") then
                pos = g.Position
            end
            
            if pos then
                local dist = (hrp.Position - pos).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = {obj = g, pos = pos}
                end
            end
        end
        
        if nearest then
            -- Teleporta em cima do ouro se estiver longe
            if nearestDist > 5 then
                Teleport(nearest.pos)
            end
        end
    end)
    
    table.insert(Connections, goldFarmConn)
end

local function StopGoldFarm()
    Flags.GoldFarm = false
    if goldFarmConn then
        goldFarmConn:Disconnect()
        goldFarmConn = nil
    end
end

-- ═══════════════════════════════════════════
--          SISTEMA ESP MONSTROS
-- ═══════════════════════════════════════════

local monsterESPConn = nil

local function UpdateMonsterESP()
    -- Limpa ESPs de monstros antigos
    for _, obj in pairs(ESPObjects) do
        if obj.isMonster then
            if obj.conn then obj.conn:Disconnect() end
            if obj.hl and obj.hl.Parent then obj.hl:Destroy() end
            if obj.bill and obj.bill.Parent then obj.bill:Destroy() end
        end
    end
    -- Filtra
    local newList = {}
    for _, obj in pairs(ESPObjects) do
        if not obj.isMonster then table.insert(newList, obj) end
    end
    ESPObjects = newList
    
    if not Flags.MonsterESP then return end
    
    local monsters = GetMonsters()
    for _, m in pairs(monsters) do
        local hum = m:FindFirstChild("Humanoid")
        local hp = hum and math.floor(hum.Health) or "?"
        local hl, bill = CreateESP(m, Color3.fromRGB(255, 60, 60), "👹 " .. m.Name .. "\nHP: " .. tostring(hp))
        -- Marca como monstro
        local entry = ESPObjects[#ESPObjects]
        if entry then entry.isMonster = true end
    end
end

local function StartMonsterESP()
    UpdateMonsterESP()
    
    if monsterESPConn then monsterESPConn:Disconnect() end
    monsterESPConn = RunService.Heartbeat:Connect(function()
        if not Flags.MonsterESP then return end
        -- Atualiza a cada 2 segundos aproximadamente
        UpdateMonsterESP()
        task.wait(2)
    end)
    table.insert(Connections, monsterESPConn)
end

local function StopMonsterESP()
    Flags.MonsterESP = false
    if monsterESPConn then
        monsterESPConn:Disconnect()
        monsterESPConn = nil
    end
    -- Limpa ESPs de monstros
    local newList = {}
    for _, obj in pairs(ESPObjects) do
        if obj.isMonster then
            if obj.conn then obj.conn:Disconnect() end
            if obj.hl and obj.hl.Parent then obj.hl:Destroy() end
            if obj.bill and obj.bill.Parent then obj.bill:Destroy() end
        else
            table.insert(newList, obj)
        end
    end
    ESPObjects = newList
end

-- ═══════════════════════════════════════════
--          SISTEMA ESP OURO
-- ═══════════════════════════════════════════

local goldESPConn = nil

local function UpdateGoldESP()
    -- Limpa ESPs de ouro antigos
    local newList = {}
    for _, obj in pairs(ESPObjects) do
        if obj.isGold then
            if obj.conn then obj.conn:Disconnect() end
            if obj.hl and obj.hl.Parent then obj.hl:Destroy() end
            if obj.bill and obj.bill.Parent then obj.bill:Destroy() end
        else
            table.insert(newList, obj)
        end
    end
    ESPObjects = newList
    
    if not Flags.GoldESP then return end
    
    local golds = GetGoldObjects()
    for _, g in pairs(golds) do
        CreateESP(g, Color3.fromRGB(255, 215, 0), "💰 GOLD")
        local entry = ESPObjects[#ESPObjects]
        if entry then entry.isGold = true end
    end
end

local function StartGoldESP()
    UpdateGoldESP()
    if goldESPConn then goldESPConn:Disconnect() end
    goldESPConn = RunService.Heartbeat:Connect(function()
        if not Flags.GoldESP then return end
        UpdateGoldESP()
        task.wait(3)
    end)
    table.insert(Connections, goldESPConn)
end

local function StopGoldESP()
    Flags.GoldESP = false
    if goldESPConn then goldESPConn:Disconnect(); goldESPConn = nil end
    local newList = {}
    for _, obj in pairs(ESPObjects) do
        if obj.isGold then
            if obj.conn then obj.conn:Disconnect() end
            if obj.hl and obj.hl.Parent then obj.hl:Destroy() end
            if obj.bill and obj.bill.Parent then obj.bill:Destroy() end
        else
            table.insert(newList, obj)
        end
    end
    ESPObjects = newList
end

-- ═══════════════════════════════════════════
--            SPEED HACK
-- ═══════════════════════════════════════════

local function ApplySpeed(value)
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChild("Humanoid")
        if hum then
            hum.WalkSpeed = value
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    if Flags.SpeedHack then
        task.wait(0.5)
        ApplySpeed(Flags.SpeedValue)
    end
end)

-- ═══════════════════════════════════════════
--              NOCLIP
-- ═══════════════════════════════════════════

local noclipConn = nil

local function StartNoclip()
    if noclipConn then noclipConn:Disconnect() end
    noclipConn = RunService.Stepped:Connect(function()
        if not Flags.Noclip then return end
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end)
    table.insert(Connections, noclipConn)
end

-- ═══════════════════════════════════════════
--          TELEPORTAR PARA MONSTRO
-- ═══════════════════════════════════════════

local function TeleportToNearestMonster()
    local monsters = GetMonsters()
    if #monsters == 0 then
        Rayfield:Notify({
            Title = "Nenhum Monstro",
            Content = "Nenhum monstro encontrado no mapa!",
            Duration = 3,
            Image = "4483362458",
        })
        return
    end
    
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    
    local nearest = nil
    local nearestDist = math.huge
    local hrp = char.HumanoidRootPart
    
    for _, m in pairs(monsters) do
        local mhrp = m:FindFirstChild("HumanoidRootPart")
        if mhrp then
            local d = (hrp.Position - mhrp.Position).Magnitude
            if d < nearestDist then
                nearestDist = d
                nearest = mhrp.Position
            end
        end
    end
    
    if nearest then
        Teleport(nearest)
        Rayfield:Notify({
            Title = "Teleportado!",
            Content = "Teleportado para monstro mais próximo (" .. math.floor(nearestDist) .. "m)",
            Duration = 2,
            Image = "4483362458",
        })
    end
end

-- ═══════════════════════════════════════════
--         AUTO COLLECT OURO
-- ═══════════════════════════════════════════

local autoCollectConn = nil

local function StartAutoCollect()
    if autoCollectConn then autoCollectConn:Disconnect() end
    autoCollectConn = RunService.Heartbeat:Connect(function()
        if not Flags.AutoCollect then return end
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            local name = obj.Name:lower()
            if (name == "goldball" or name == "goldbar" or name:find("gold")) and obj:IsA("BasePart") then
                local dist = (hrp.Position - obj.Position).Magnitude
                if dist < 30 then
                    -- Toca o objeto (trigger de coleta)
                    local fakeTouched = Instance.new("Part")
                    fakeTouched.Size = Vector3.new(1,1,1)
                    fakeTouched.CFrame = obj.CFrame
                    fakeTouched.Anchored = true
                    fakeTouched.CanCollide = false
                    fakeTouched.Transparency = 1
                    fakeTouched.Parent = Workspace
                    task.delay(0.1, function()
                        fakeTouched:Destroy()
                    end)
                end
            end
        end
    end)
    table.insert(Connections, autoCollectConn)
end

-- ═══════════════════════════════════════════
--              RAYFIELD UI
-- ═══════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name = "🦍 Lethal Ape Script",
    Icon = 0,
    LoadingTitle = "Lethal Ape Hub",
    LoadingSubtitle = "by Script Hub",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "LethalApeHub",
        FileName = "Config"
    },
    KeySystem = false,
})

-- ───────────────────────────────────────────
--              TAB: GOLD FARM
-- ───────────────────────────────────────────

local GoldTab = Window:CreateTab("💰 Gold Farm", 4483362458)

GoldTab:CreateSection("Auto Gold Farm")

GoldTab:CreateToggle({
    Name = "🔄 Gold Farm (Auto Teleport)",
    CurrentValue = false,
    Flag = "GoldFarm",
    Callback = function(value)
        Flags.GoldFarm = value
        if value then
            StartGoldFarm()
            Rayfield:Notify({
                Title = "Gold Farm Ativado",
                Content = "Teleportando para o ouro automaticamente!",
                Duration = 3,
                Image = "4483362458",
            })
        else
            StopGoldFarm()
        end
    end
})

GoldTab:CreateToggle({
    Name = "✨ Auto Collect (Rádio de 30 studs)",
    CurrentValue = false,
    Flag = "AutoCollect",
    Callback = function(value)
        Flags.AutoCollect = value
        if value then
            StartAutoCollect()
        else
            if autoCollectConn then autoCollectConn:Disconnect(); autoCollectConn = nil end
        end
    end
})

GoldTab:CreateButton({
    Name = "⚡ Ir ao Ouro Mais Próximo (1x)",
    Callback = function()
        local golds = GetGoldObjects()
        if #golds == 0 then
            Rayfield:Notify({
                Title = "Sem Ouro",
                Content = "Nenhum ouro encontrado no mapa no momento!",
                Duration = 3,
                Image = "4483362458",
            })
            return
        end
        local char = LocalPlayer.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then return end
        local hrp = char.HumanoidRootPart
        local nearest, nearestDist = nil, math.huge
        for _, g in pairs(golds) do
            local pos
            if g:IsA("Model") then
                local ok, pv = pcall(function() return g:GetPivot().Position end)
                if ok then pos = pv end
            elseif g:IsA("BasePart") then
                pos = g.Position
            end
            if pos then
                local d = (hrp.Position - pos).Magnitude
                if d < nearestDist then nearestDist = d; nearest = pos end
            end
        end
        if nearest then
            Teleport(nearest)
            Rayfield:Notify({
                Title = "Teleportado!",
                Content = "Indo ao ouro (" .. math.floor(nearestDist) .. "m)",
                Duration = 2,
                Image = "4483362458",
            })
        end
    end
})

GoldTab:CreateSection("Ouro ESP")

GoldTab:CreateToggle({
    Name = "💛 ESP Ouro (Ver através de paredes)",
    CurrentValue = false,
    Flag = "GoldESP",
    Callback = function(value)
        Flags.GoldESP = value
        if value then
            StartGoldESP()
        else
            StopGoldESP()
        end
    end
})

-- ───────────────────────────────────────────
--              TAB: MONSTROS
-- ───────────────────────────────────────────

local MonsterTab = Window:CreateTab("👹 Monstros", 4483362458)

MonsterTab:CreateSection("Monster ESP")

MonsterTab:CreateToggle({
    Name = "🔴 ESP Monstros (Highlight + Distância)",
    CurrentValue = false,
    Flag = "MonsterESP",
    Callback = function(value)
        Flags.MonsterESP = value
        if value then
            StartMonsterESP()
        else
            StopMonsterESP()
        end
    end
})

MonsterTab:CreateSection("Teleporte")

MonsterTab:CreateButton({
    Name = "💥 Teleportar ao Monstro Mais Próximo",
    Callback = function()
        TeleportToNearestMonster()
    end
})

MonsterTab:CreateButton({
    Name = "📋 Listar Monstros no Chat",
    Callback = function()
        local monsters = GetMonsters()
        if #monsters == 0 then
            Rayfield:Notify({
                Title = "Sem Monstros",
                Content = "Nenhum monstro encontrado!",
                Duration = 3,
                Image = "4483362458",
            })
            return
        end
        local char = LocalPlayer.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local lines = ""
        for i, m in pairs(monsters) do
            local mhrp = m:FindFirstChild("HumanoidRootPart")
            local dist = hrp and mhrp and math.floor((hrp.Position - mhrp.Position).Magnitude) or "?"
            local hum = m:FindFirstChild("Humanoid")
            local hp = hum and math.floor(hum.Health) or "?"
            lines = lines .. i .. ". " .. m.Name .. " | HP: " .. tostring(hp) .. " | " .. tostring(dist) .. "m\n"
        end
        Rayfield:Notify({
            Title = "🦍 Monstros (" .. #monsters .. ")",
            Content = lines,
            Duration = 8,
            Image = "4483362458",
        })
    end
})

-- ───────────────────────────────────────────
--              TAB: PLAYER
-- ───────────────────────────────────────────

local PlayerTab = Window:CreateTab("🧍 Player", 4483362458)

PlayerTab:CreateSection("Movimento")

PlayerTab:CreateToggle({
    Name = "🚀 Speed Hack",
    CurrentValue = false,
    Flag = "SpeedHack",
    Callback = function(value)
        Flags.SpeedHack = value
        if value then
            ApplySpeed(Flags.SpeedValue)
        else
            ApplySpeed(16)
        end
    end
})

PlayerTab:CreateSlider({
    Name = "Velocidade",
    Range = {16, 300},
    Increment = 5,
    Suffix = "studs/s",
    CurrentValue = 16,
    Flag = "SpeedValue",
    Callback = function(value)
        Flags.SpeedValue = value
        if Flags.SpeedHack then
            ApplySpeed(value)
        end
    end
})

PlayerTab:CreateToggle({
    Name = "👻 Noclip (Atravessa Paredes)",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(value)
        Flags.Noclip = value
        if value then
            StartNoclip()
        else
            -- Re-ativa colisão
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                    end
                end
            end
        end
    end
})

PlayerTab:CreateSection("Anti Morte")

PlayerTab:CreateToggle({
    Name = "❤️ God Mode (Infinite Health)",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(value)
        if value then
            local conn = RunService.Heartbeat:Connect(function()
                if not value then return end
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChild("Humanoid")
                    if hum then
                        hum.Health = hum.MaxHealth
                    end
                end
            end)
            table.insert(Connections, conn)
        end
    end
})

PlayerTab:CreateSection("Teleporte")

PlayerTab:CreateButton({
    Name = "🏠 Ir para Spawn",
    Callback = function()
        -- Tenta encontrar spawn point
        local spawn = Workspace:FindFirstChild("SpawnLocation")
            or Workspace:FindFirstChild("Respawn")
            or Workspace:FindFirstChild("PipeRespawn")
        
        if spawn and spawn:IsA("BasePart") then
            Teleport(spawn.Position)
        else
            -- Tenta achar qualquer SpawnLocation
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("SpawnLocation") then
                    Teleport(obj.Position)
                    return
                end
            end
            Rayfield:Notify({
                Title = "Spawn não encontrado",
                Content = "Não foi possível encontrar um ponto de spawn.",
                Duration = 3,
                Image = "4483362458",
            })
        end
    end
})

-- ───────────────────────────────────────────
--              TAB: ESP PLAYERS
-- ───────────────────────────────────────────

local ESPTab = Window:CreateTab("🎯 ESP Players", 4483362458)

ESPTab:CreateSection("Player ESP")

local playerESPConn = nil
local playerESPActive = false

ESPTab:CreateToggle({
    Name = "🔵 ESP Todos os Players",
    CurrentValue = false,
    Flag = "PlayerESP",
    Callback = function(value)
        playerESPActive = value
        
        if not value then
            -- Limpa ESP de players
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local hl = p.Character:FindFirstChild("_ESP_Highlight")
                    if hl then hl:Destroy() end
                    local bill = p.Character:FindFirstChild("_ESP_Bill")
                    if bill then bill:Destroy() end
                end
            end
            if playerESPConn then playerESPConn:Disconnect(); playerESPConn = nil end
            return
        end
        
        local function addPlayerESP(player)
            if player == LocalPlayer then return end
            local function onChar(char)
                task.wait(1)
                if not playerESPActive then return end
                CreateESP(char, Color3.fromRGB(0, 120, 255), "🎮 " .. player.Name)
            end
            if player.Character then onChar(player.Character) end
            player.CharacterAdded:Connect(onChar)
        end
        
        for _, p in pairs(Players:GetPlayers()) do addPlayerESP(p) end
        Players.PlayerAdded:Connect(addPlayerESP)
    end
})

ESPTab:CreateSection("Rastrear Player Específico")

ESPTab:CreateInput({
    Name = "Nome do Player para Seguir",
    PlaceholderText = "Digite o nome...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local target = Players:FindFirstChild(text)
        if target and target.Character then
            local hrp = target.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                Teleport(hrp.Position)
                Rayfield:Notify({
                    Title = "Teleportado!",
                    Content = "Teleportado para " .. text,
                    Duration = 3,
                    Image = "4483362458",
                })
            end
        else
            Rayfield:Notify({
                Title = "Player não encontrado",
                Content = "'" .. text .. "' não está no jogo.",
                Duration = 3,
                Image = "4483362458",
            })
        end
    end
})

-- ───────────────────────────────────────────
--              TAB: MISC
-- ───────────────────────────────────────────

local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

MiscTab:CreateSection("Câmera")

MiscTab:CreateSlider({
    Name = "Campo de Visão (FOV)",
    Range = {70, 130},
    Increment = 5,
    Suffix = "°",
    CurrentValue = 70,
    Flag = "FOV",
    Callback = function(value)
        Camera.FieldOfView = value
    end
})

MiscTab:CreateSection("Utilidades")

MiscTab:CreateButton({
    Name = "🔄 Rejoin Servidor",
    Callback = function()
        local TeleportService = game:GetService("TeleportService")
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end
})

MiscTab:CreateButton({
    Name = "🧹 Limpar Todos ESPs",
    Callback = function()
        ClearAllESP()
        Rayfield:Notify({
            Title = "ESPs Limpos",
            Content = "Todos os highlights foram removidos.",
            Duration = 2,
            Image = "4483362458",
        })
    end
})

MiscTab:CreateButton({
    Name = "💡 Contar Ouros no Mapa",
    Callback = function()
        local golds = GetGoldObjects()
        Rayfield:Notify({
            Title = "💰 Contagem de Ouro",
            Content = "Encontrado " .. #golds .. " objeto(s) de ouro no mapa!",
            Duration = 4,
            Image = "4483362458",
        })
    end
})

MiscTab:CreateButton({
    Name = "🦍 Contar Monstros no Mapa",
    Callback = function()
        local monsters = GetMonsters()
        Rayfield:Notify({
            Title = "👹 Contagem de Monstros",
            Content = "Encontrado " .. #monsters .. " monstro(s) no mapa!",
            Duration = 4,
            Image = "4483362458",
        })
    end
})

MiscTab:CreateSection("Créditos")

MiscTab:CreateLabel("✨ Lethal Ape Script Hub")
MiscTab:CreateLabel("Funciona em: Lethal Ape Ultimate")
MiscTab:CreateLabel("UI: Rayfield Library")

-- ═══════════════════════════════════════════
--              INICIALIZAÇÃO
-- ═══════════════════════════════════════════

Rayfield:LoadConfiguration()

Rayfield:Notify({
    Title = "🦍 Lethal Ape Hub",
    Content = "Script carregado com sucesso!\nUse as abas para navegar.",
    Duration = 5,
    Image = "4483362458",
})

print("[Lethal Ape Hub] Script iniciado com sucesso!")
