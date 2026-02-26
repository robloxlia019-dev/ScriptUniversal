--[[
╔══════════════════════════════════════════════════════════════════╗
║          ANIMAL SIMULATOR - SCRIPT COMPLETO                      ║
║          Rayfield UI • Auto Farm • Boss Kill • ESP               ║
║          Analisado direto dos scripts do jogo                    ║
║          Compatível: Synapse X, KRNL, Fluxus, Delta              ║
╚══════════════════════════════════════════════════════════════════╝

  REMOTES IDENTIFICADOS NO JOGO:
  • jdskhfsIIIllliiIIIdchgdIiIIIlIlIli  → Dano em NPC (principal)
  • CoinEvent (Events)                   → Coleta de coins
  • NPCDamageEvent (Events)              → Sistema de dano
  • rewardEvent (ReplicatedStorage)      → Recompensas
  • WeaponEvent (Events)                 → Armas/ataques
  • SpawnEvent (Events)                  → Spawn

  TAGS DOS INIMIGOS (CollectionService):
  • "Dummy"  → Training Dummies
  • "Dummy2" → Training Dummies 2
  • "NPC"    → Inimigos / Bosses

  BOSSES NO MAPA:
  • LavaGorilla • CRABBOSS • BOSSBEAR • BOSSDEER
  • DragonGiraffe • BOSSDINO • HenBoss

  STATS: leaderstats.Level, leaderstats.Coins
]]

-- ═══════════════════════════════════════════════════
-- RAYFIELD UI LOADER
-- ═══════════════════════════════════════════════════
local RayfieldLoaded, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not RayfieldLoaded then
    -- Fallback se Rayfield não carregar
    warn("[AnimalSim] Rayfield falhou. Usando UI básica.")
    Rayfield = {
        CreateWindow = function() return {CreateTab = function() return {CreateToggle=function()end,CreateButton=function()end,CreateSlider=function()end,CreateLabel=function()end} end} end,
        Notify = function(_, opts) print("[Notify] " .. tostring(opts and opts.Title or "")) end
    }
end

-- ═══════════════════════════════════════════════════
-- SERVIÇOS & VARIÁVEIS
-- ═══════════════════════════════════════════════════
local Players       = game:GetService("Players")
local RS            = game:GetService("RunService")
local TweenSvc      = game:GetService("TweenService")
local CollSvc       = game:GetService("CollectionService")
local RepStorage    = game:GetService("ReplicatedStorage")
local CoreGui       = game:GetService("CoreGui")
local WS            = game:GetService("Workspace")
local UIS           = game:GetService("UserInputService")

local LP            = Players.LocalPlayer
local Camera        = WS.CurrentCamera

-- Remotes do jogo
local Events        = RepStorage:FindFirstChild("Events")
local DamageRemote  = RepStorage:FindFirstChild("jdskhfsIIIllliiIIIdchgdIiIIIlIlIli")
local CoinEvent     = Events and Events:FindFirstChild("CoinEvent")
local NPCDmgEvent   = Events and Events:FindFirstChild("NPCDamageEvent")
local WeaponEvent   = Events and Events:FindFirstChild("WeaponEvent")
local RewardEvent   = RepStorage:FindFirstChild("rewardEvent")

-- ═══════════════════════════════════════════════════
-- CONFIGURAÇÕES PADRÃO
-- ═══════════════════════════════════════════════════
local CFG = {
    -- Auto Farm
    AutoFarm        = false,
    AutoFarmTarget  = "NPC",       -- "NPC" | "Dummy" | "Boss"
    FarmDelay       = 0.05,        -- delay entre hits (menor = mais rápido)
    FarmRange       = 999,         -- range de farm (9999 = todos do mapa)
    TeleportToNPC   = true,        -- teleporta até o NPC antes de atacar
    
    -- Boss Farm
    BossFarm        = false,
    BossTarget      = "BOSSBEAR",  -- nome do boss preferido
    BossDelay       = 0.05,
    
    -- Coin Farm
    CoinFarm        = false,
    CoinDelay       = 0.1,
    
    -- Player
    WalkSpeed       = 32,
    JumpPower       = 70,
    InfiniteJump    = false,
    
    -- Misc
    Noclip          = false,
    Fly             = false,
    AntiAFK         = true,
    AutoRespawn     = true,
    
    -- ESP
    ESP             = false,
    ESPNPCs         = false,
    ESPBosses       = false,
    ESPPlayers      = false,
    ESPCoins        = false,
    
    -- Dano
    DamageMulti     = 1,   -- multiplicador de dano (display only, real é server-side)
}

-- ═══════════════════════════════════════════════════
-- ESTADO DOS LOOPS
-- ═══════════════════════════════════════════════════
local Loops = {}
local ESPObjects = {}
local FlyObjects = {}

-- ═══════════════════════════════════════════════════
-- FUNÇÕES UTILITÁRIAS
-- ═══════════════════════════════════════════════════
local function getChar()
    return LP.Character
end

local function getRoot()
    local c = getChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function getHum()
    local c = getChar()
    return c and c:FindFirstChildWhichIsA("Humanoid")
end

local function getLeaderstat(name)
    local ls = LP:FindFirstChild("leaderstats")
    return ls and ls:FindFirstChild(name)
end

local function notify(title, content, duration)
    pcall(function()
        Rayfield:Notify({
            Title = title or "Animal Sim",
            Content = content or "",
            Duration = duration or 3,
            Image = "rbxassetid://4483345998",
            Options = nil,
        })
    end)
end

-- ═══════════════════════════════════════════════════
-- FUNÇÕES DE INIMIGOS
-- ═══════════════════════════════════════════════════
-- Retorna todos os NPCs/Dummies/Bosses vivos
local function getAllNPCs(tag)
    local result = {}
    tag = tag or "NPC"
    
    -- Via CollectionService tags
    local tags = {"NPC", "Dummy", "Dummy2"}
    if tag ~= "all" then tags = {tag} end
    
    for _, tagName in pairs(tags) do
        for _, obj in pairs(CollSvc:GetTagged(tagName)) do
            local hum = obj:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(result, obj)
            end
        end
    end
    
    -- Também busca por nome de boss
    local bossNames = {"LavaGorilla","CRABBOSS","BOSSBEAR","BOSSDEER","DragonGiraffe","BOSSDINO","HenBoss","Hen","chicken_guard1","chicken_guard2"}
    if tag == "Boss" or tag == "all" then
        for _, name in pairs(bossNames) do
            local boss = WS:FindFirstChild(name, true)
            if boss and boss:IsA("Model") then
                local hum = boss:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health > 0 then
                    table.insert(result, boss)
                end
            end
        end
        -- Também procura na pasta NPC
        local npcFolder = WS:FindFirstChild("NPC")
        if npcFolder then
            for _, v in pairs(npcFolder:GetChildren()) do
                local hum = v:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health > 0 then
                    table.insert(result, v)
                end
            end
        end
    end
    
    return result
end

-- Retorna o NPC mais próximo
local function getNearestNPC(tag, maxRange)
    local root = getRoot()
    if not root then return nil end
    maxRange = maxRange or CFG.FarmRange
    
    local nearest, nearestDist = nil, maxRange + 1
    local npcs = getAllNPCs(tag == "Boss" and "all" or tag)
    
    for _, npc in pairs(npcs) do
        local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
        if npcRoot then
            local dist = (root.Position - npcRoot.Position).Magnitude
            if dist < nearestDist then
                nearest = npc
                nearestDist = dist
            end
        end
    end
    
    return nearest, nearestDist
end

-- Dá dano em um NPC via RemoteEvent do jogo
local function hitNPC(npc, damage)
    if not npc then return end
    local hum = npc:FindFirstChildWhichIsA("Humanoid")
    if not hum or hum.Health <= 0 then return end
    
    -- Método principal: remote obfuscado (como o jogo faz)
    if DamageRemote then
        local success = pcall(function()
            DamageRemote:FireServer(hum, damage)
        end)
        if success then return end
    end
    
    -- Fallback: NPCDamageEvent
    if NPCDmgEvent then
        pcall(function()
            NPCDmgEvent:FireServer(npc, damage or 9999999)
        end)
    end
    
    -- Fallback 2: direto na humanoid (só funciona sem FE ou com executor level 7+)
    pcall(function()
        hum:TakeDamage(damage or 9999999)
    end)
end

-- ═══════════════════════════════════════════════════
-- AUTO FARM - NPCS
-- ═══════════════════════════════════════════════════
local function startAutoFarm()
    if Loops.autoFarm then return end
    CFG.AutoFarm = true
    
    Loops.autoFarm = task.spawn(function()
        while CFG.AutoFarm do
            local char = getChar()
            local root = getRoot()
            local hum = getHum()
            
            if char and root and hum and hum.Health > 0 then
                -- Busca NPCs pela tag definida
                local tagToSearch = "NPC"
                if CFG.AutoFarmTarget == "Dummy" then tagToSearch = "Dummy"
                elseif CFG.AutoFarmTarget == "Boss" then tagToSearch = "all"
                end
                
                local npcs = getAllNPCs(tagToSearch)
                
                if #npcs > 0 then
                    for _, npc in pairs(npcs) do
                        if not CFG.AutoFarm then break end
                        
                        local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
                        local hum2 = npc:FindFirstChildWhichIsA("Humanoid")
                        
                        if npcRoot and hum2 and hum2.Health > 0 then
                            local dist = (root.Position - npcRoot.Position).Magnitude
                            
                            if dist <= CFG.FarmRange then
                                -- Teleporta até o NPC se configurado
                                if CFG.TeleportToNPC and dist > 8 then
                                    root.CFrame = npcRoot.CFrame * CFrame.new(0, 0, 4)
                                end
                                
                                -- Ataca o NPC
                                hitNPC(npc, 9999999)
                                task.wait(CFG.FarmDelay)
                            end
                        end
                    end
                else
                    task.wait(0.5) -- espera se não tiver NPCs
                end
            else
                task.wait(1)
            end
            
            task.wait(CFG.FarmDelay)
        end
        Loops.autoFarm = nil
    end)
    
    notify("✅ Auto Farm", "Farm de NPCs iniciado!", 2)
end

local function stopAutoFarm()
    CFG.AutoFarm = false
    Loops.autoFarm = nil
    notify("❌ Auto Farm", "Farm parado.", 2)
end

-- ═══════════════════════════════════════════════════
-- BOSS FARM
-- ═══════════════════════════════════════════════════
local BOSS_NAMES = {
    "LavaGorilla", "CRABBOSS", "BOSSBEAR", "BOSSDEER",
    "DragonGiraffe", "BOSSDINO", "HenBoss", "Hen",
    "chicken_guard1", "chicken_guard2"
}

local function findBoss(preferredName)
    -- Procura boss específico primeiro
    if preferredName and preferredName ~= "Qualquer" then
        local boss = WS:FindFirstChild(preferredName, true)
        if boss and boss:IsA("Model") then
            local hum = boss:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.Health > 0 then return boss end
        end
    end
    
    -- Procura qualquer boss
    for _, bossName in pairs(BOSS_NAMES) do
        local boss = WS:FindFirstChild(bossName, true)
        if boss and boss:IsA("Model") then
            local hum = boss:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.Health > 0 then return boss end
        end
    end
    
    -- Procura por tag NPC também
    for _, tagged in pairs(CollSvc:GetTagged("NPC")) do
        local hum = tagged:FindFirstChildWhichIsA("Humanoid")
        if hum and hum.Health > 0 and tagged.Name ~= "Dummy" then
            return tagged
        end
    end
    
    return nil
end

local function startBossFarm()
    if Loops.bossFarm then return end
    CFG.BossFarm = true
    
    Loops.bossFarm = task.spawn(function()
        while CFG.BossFarm do
            local root = getRoot()
            local hum = getHum()
            
            if root and hum and hum.Health > 0 then
                local boss = findBoss(CFG.BossTarget)
                
                if boss then
                    local bossRoot = boss:FindFirstChild("HumanoidRootPart") or boss.PrimaryPart
                    local bossHum = boss:FindFirstChildWhichIsA("Humanoid")
                    
                    if bossRoot and bossHum and bossHum.Health > 0 then
                        -- Teleporta perto do boss
                        root.CFrame = bossRoot.CFrame * CFrame.new(0, 0, 5)
                        task.wait(0.05)
                        
                        -- Ataca o boss em loop até morrer
                        while CFG.BossFarm and bossHum.Health > 0 do
                            hitNPC(boss, 9999999)
                            task.wait(CFG.BossDelay)
                        end
                        
                        if bossHum.Health <= 0 then
                            notify("💀 Boss Morto!", boss.Name .. " eliminado!", 3)
                            task.wait(2) -- espera respawn
                        end
                    end
                else
                    task.wait(2) -- boss não encontrado, aguarda
                end
            else
                task.wait(1)
            end
        end
        Loops.bossFarm = nil
    end)
    
    notify("⚔️ Boss Farm", "Farm de boss iniciado: " .. CFG.BossTarget, 3)
end

local function stopBossFarm()
    CFG.BossFarm = false
    Loops.bossFarm = nil
    notify("❌ Boss Farm", "Boss farm parado.", 2)
end

-- ═══════════════════════════════════════════════════
-- COIN AUTO FARM
-- ═══════════════════════════════════════════════════
local function startCoinFarm()
    if Loops.coinFarm then return end
    CFG.CoinFarm = true
    
    Loops.coinFarm = task.spawn(function()
        while CFG.CoinFarm do
            local root = getRoot()
            if root then
                -- Pega todas as coins no workspace
                local coinFolder = WS:FindFirstChild("CoinContainer")
                local coins = {}
                
                if coinFolder then
                    for _, coin in pairs(coinFolder:GetChildren()) do
                        table.insert(coins, coin)
                    end
                end
                
                -- Também procura coins soltas no workspace
                for _, obj in pairs(WS:GetDescendants()) do
                    if obj.Name == "CoinTemplate" or obj.Name == "Coin" or obj.Name == "Chest" then
                        local part = obj:FindFirstChildWhichIsA("BasePart") or (obj:IsA("BasePart") and obj)
                        if part then
                            table.insert(coins, obj)
                        end
                    end
                end
                
                for _, coin in pairs(coins) do
                    if not CFG.CoinFarm then break end
                    local part = coin:FindFirstChildWhichIsA("BasePart") or (coin:IsA("BasePart") and coin)
                    if part then
                        -- Teleporta até a coin para coletar
                        root.CFrame = part.CFrame
                        
                        -- Fires CoinEvent se tiver
                        if CoinEvent then
                            pcall(function()
                                CoinEvent:FireServer()
                            end)
                        end
                        
                        task.wait(CFG.CoinDelay)
                    end
                end
            end
            task.wait(0.5)
        end
        Loops.coinFarm = nil
    end)
    
    notify("🪙 Coin Farm", "Coletando coins automaticamente!", 2)
end

local function stopCoinFarm()
    CFG.CoinFarm = false
    Loops.coinFarm = nil
    notify("❌ Coin Farm", "Coin farm parado.", 2)
end

-- ═══════════════════════════════════════════════════
-- AUTO RESPAWN
-- ═══════════════════════════════════════════════════
LP.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    
    -- Reaplicar speed
    task.wait(0.5)
    if CFG.WalkSpeed ~= 16 then
        hum.WalkSpeed = CFG.WalkSpeed
    end
    hum.JumpPower = CFG.JumpPower
    
    -- Re-ativar noclip
    if CFG.Noclip then
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- ═══════════════════════════════════════════════════
-- NOCLIP
-- ═══════════════════════════════════════════════════
RS.Stepped:Connect(function()
    if CFG.Noclip then
        local char = getChar()
        if char then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════
-- FLY
-- ═══════════════════════════════════════════════════
local function startFly()
    CFG.Fly = true
    local root = getRoot()
    if not root then return end
    local hum = getHum()
    if hum then hum.PlatformStand = true end
    
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.P = 1e9
    bg.Parent = root
    FlyObjects.gyro = bg
    
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity = Vector3.zero
    bv.Parent = root
    FlyObjects.velocity = bv
    
    Loops.fly = RS.RenderStepped:Connect(function()
        if not CFG.Fly then return end
        local cam = Camera
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        local spd = UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 120 or 50
        bv.Velocity = dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero
        if dir.Magnitude > 0 then bg.CFrame = CFrame.new(root.Position, root.Position + dir) end
    end)
end

local function stopFly()
    CFG.Fly = false
    if Loops.fly then Loops.fly:Disconnect(); Loops.fly = nil end
    if FlyObjects.gyro then FlyObjects.gyro:Destroy() end
    if FlyObjects.velocity then FlyObjects.velocity:Destroy() end
    FlyObjects = {}
    local hum = getHum()
    if hum then hum.PlatformStand = false end
end

-- ═══════════════════════════════════════════════════
-- INFINITE JUMP
-- ═══════════════════════════════════════════════════
UIS.JumpRequest:Connect(function()
    if CFG.InfiniteJump then
        local hum = getHum()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ═══════════════════════════════════════════════════
-- ANTI-AFK
-- ═══════════════════════════════════════════════════
task.spawn(function()
    while true do
        if CFG.AntiAFK then
            local VU = game:GetService("VirtualUser")
            VU:CaptureController()
            VU:ClickButton2(Vector2.new())
        end
        task.wait(15)
    end
end)

-- ═══════════════════════════════════════════════════
-- ESP SYSTEM
-- ═══════════════════════════════════════════════════
local function clearESP(category)
    if category then
        if ESPObjects[category] then
            for _, h in pairs(ESPObjects[category]) do
                if h and h.Parent then h:Destroy() end
            end
            ESPObjects[category] = {}
        end
    else
        for _, cat in pairs(ESPObjects) do
            for _, h in pairs(cat) do
                if h and h.Parent then h:Destroy() end
            end
        end
        ESPObjects = {}
    end
end

local function addHighlight(model, fillColor, outlineColor, category)
    if not model or not model:IsA("Model") then return end
    category = category or "misc"
    if not ESPObjects[category] then ESPObjects[category] = {} end
    
    -- Remove highlight existente
    local existing = CoreGui:FindFirstChild("ESP_" .. model.Name .. "_" .. category)
    if existing then existing:Destroy() end
    
    local h = Instance.new("Highlight")
    h.Name = "ESP_" .. model.Name .. "_" .. category
    h.Adornee = model
    h.FillColor = fillColor or Color3.fromRGB(255,50,50)
    h.OutlineColor = outlineColor or Color3.new(1,1,1)
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Parent = CoreGui
    
    table.insert(ESPObjects[category], h)
    return h
end

-- ESP para NPCs
local function updateNPCESP()
    clearESP("npc")
    if not CFG.ESPNPCs then return end
    
    local tags = {"NPC", "Dummy", "Dummy2"}
    for _, tag in pairs(tags) do
        for _, obj in pairs(CollSvc:GetTagged(tag)) do
            local hum = obj:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.Health > 0 then
                addHighlight(obj, Color3.fromRGB(255, 160, 0), Color3.fromRGB(255,255,0), "npc")
            end
        end
    end
end

-- ESP para Bosses
local function updateBossESP()
    clearESP("boss")
    if not CFG.ESPBosses then return end
    
    for _, bossName in pairs(BOSS_NAMES) do
        for _, obj in pairs(WS:GetDescendants()) do
            if obj.Name == bossName and obj:IsA("Model") then
                local hum = obj:FindFirstChildWhichIsA("Humanoid")
                if hum and hum.Health > 0 then
                    addHighlight(obj, Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 100, 0), "boss")
                end
            end
        end
    end
end

-- ESP para Players
local function updatePlayerESP()
    clearESP("players")
    if not CFG.ESPPlayers then return end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            addHighlight(player.Character, Color3.fromRGB(0, 150, 255), Color3.fromRGB(200, 230, 255), "players")
        end
    end
end

-- Loop de atualização do ESP
task.spawn(function()
    while true do
        if CFG.ESPNPCs then updateNPCESP() end
        if CFG.ESPBosses then updateBossESP() end
        if CFG.ESPPlayers then updatePlayerESP() end
        task.wait(2)
    end
end)

-- ═══════════════════════════════════════════════════
-- WALK SPEED / JUMP
-- ═══════════════════════════════════════════════════
local function applyStats()
    local hum = getHum()
    if hum then
        hum.WalkSpeed = CFG.WalkSpeed
        hum.JumpPower = CFG.JumpPower
    end
end

-- ═══════════════════════════════════════════════════
-- TELEPORT PARA BOSS
-- ═══════════════════════════════════════════════════
local function teleportToBoss(bossName)
    local root = getRoot()
    if not root then return end
    
    local boss = findBoss(bossName)
    if boss then
        local bossRoot = boss:FindFirstChild("HumanoidRootPart") or boss.PrimaryPart
        if bossRoot then
            root.CFrame = bossRoot.CFrame * CFrame.new(0, 0, 6)
            notify("📍 Teleport", "Teleportado para " .. boss.Name, 2)
        end
    else
        notify("⚠️ Boss", "Boss não encontrado no mapa!", 3)
    end
end

-- ═══════════════════════════════════════════════════
-- KILL AURA (hit todos em range instantâneo)
-- ═══════════════════════════════════════════════════
local function killAura()
    local root = getRoot()
    if not root then return end
    
    local killed = 0
    for _, tag in pairs({"NPC", "Dummy", "Dummy2"}) do
        for _, npc in pairs(CollSvc:GetTagged(tag)) do
            local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
            local hum = npc:FindFirstChildWhichIsA("Humanoid")
            if npcRoot and hum and hum.Health > 0 then
                local dist = (root.Position - npcRoot.Position).Magnitude
                if dist <= CFG.FarmRange then
                    hitNPC(npc, 9999999)
                    killed = killed + 1
                    task.wait(0.02)
                end
            end
        end
    end
    
    notify("💥 Kill Aura", killed .. " inimigos atingidos!", 2)
end

-- ═══════════════════════════════════════════════════
-- INFO DO PLAYER
-- ═══════════════════════════════════════════════════
local function getPlayerInfo()
    local level = getLeaderstat("Level")
    local coins = getLeaderstat("Coins")
    local lvl = level and level.Value or "?"
    local cns = coins and coins.Value or "?"
    notify("📊 Stats", "Level: " .. tostring(lvl) .. " | Coins: " .. tostring(cns), 4)
    return lvl, cns
end

-- ═══════════════════════════════════════════════════
-- ██████████ RAYFIELD UI ██████████
-- ═══════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name = "🦁 Animal Simulator Script",
    LoadingTitle = "Animal Simulator",
    LoadingSubtitle = "by Script • Carregando...",
    ConfigurationSaving = {
        Enabled = false,
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

-- ═══════════════════════════════════════════════════
-- TAB 1: AUTO FARM
-- ═══════════════════════════════════════════════════
local FarmTab = Window:CreateTab("⚔️ Auto Farm", 4483345998)

FarmTab:CreateSection("Configurações de Farm")

FarmTab:CreateToggle({
    Name = "🔄 Auto Farm NPCs",
    CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(val)
        if val then startAutoFarm() else stopAutoFarm() end
    end,
})

FarmTab:CreateDropdown({
    Name = "🎯 Alvo do Farm",
    Options = {"NPC", "Dummy", "Boss", "Todos"},
    CurrentOption = {"NPC"},
    Flag = "FarmTarget",
    Callback = function(option)
        CFG.AutoFarmTarget = option[1] or "NPC"
    end,
})

FarmTab:CreateSlider({
    Name = "⏱ Delay do Farm (ms)",
    Range = {1, 500},
    Increment = 1,
    Suffix = "ms",
    CurrentValue = 50,
    Flag = "FarmDelay",
    Callback = function(val)
        CFG.FarmDelay = val / 1000
    end,
})

FarmTab:CreateSlider({
    Name = "📏 Range do Farm",
    Range = {5, 9999},
    Increment = 5,
    Suffix = "studs",
    CurrentValue = 999,
    Flag = "FarmRange",
    Callback = function(val)
        CFG.FarmRange = val
    end,
})

FarmTab:CreateToggle({
    Name = "📍 Teleportar até NPC",
    CurrentValue = true,
    Flag = "TeleportFarm",
    Callback = function(val)
        CFG.TeleportToNPC = val
    end,
})

FarmTab:CreateSection("Kill Aura")

FarmTab:CreateButton({
    Name = "💥 Kill Aura (Hit Todos em Range)",
    Callback = function()
        killAura()
    end,
})

FarmTab:CreateButton({
    Name = "💀 Matar TODOS os NPCs do Mapa",
    Callback = function()
        local savedRange = CFG.FarmRange
        CFG.FarmRange = 99999
        local root = getRoot()
        if root then
            local killed = 0
            for _, tag in pairs({"NPC", "Dummy", "Dummy2"}) do
                for _, npc in pairs(CollSvc:GetTagged(tag)) do
                    local hum = npc:FindFirstChildWhichIsA("Humanoid")
                    if hum and hum.Health > 0 then
                        hitNPC(npc, 9999999)
                        killed = killed + 1
                        task.wait(0.02)
                    end
                end
            end
            notify("☠️ Limpeza!", killed .. " NPCs eliminados!", 3)
        end
        CFG.FarmRange = savedRange
    end,
})

-- ═══════════════════════════════════════════════════
-- TAB 2: BOSS FARM
-- ═══════════════════════════════════════════════════
local BossTab = Window:CreateTab("👹 Boss Farm", 4483345998)

BossTab:CreateSection("Bosses do Mapa")

BossTab:CreateDropdown({
    Name = "👹 Boss Alvo",
    Options = {"Qualquer", "BOSSBEAR", "CRABBOSS", "LavaGorilla", "BOSSDEER", "DragonGiraffe", "BOSSDINO", "HenBoss"},
    CurrentOption = {"Qualquer"},
    Flag = "BossTarget",
    Callback = function(option)
        CFG.BossTarget = option[1] or "Qualquer"
    end,
})

BossTab:CreateToggle({
    Name = "⚔️ Auto Boss Farm",
    CurrentValue = false,
    Flag = "BossFarm",
    Callback = function(val)
        if val then startBossFarm() else stopBossFarm() end
    end,
})

BossTab:CreateSlider({
    Name = "⏱ Delay Boss Farm (ms)",
    Range = {1, 500},
    Increment = 1,
    Suffix = "ms",
    CurrentValue = 50,
    Flag = "BossDelay",
    Callback = function(val)
        CFG.BossDelay = val / 1000
    end,
})

BossTab:CreateSection("Teleport Rápido")

for _, bossName in pairs({"BOSSBEAR", "CRABBOSS", "LavaGorilla", "BOSSDEER", "DragonGiraffe", "BOSSDINO", "HenBoss"}) do
    BossTab:CreateButton({
        Name = "📍 TP → " .. bossName,
        Callback = function()
            teleportToBoss(bossName)
        end,
    })
end

BossTab:CreateButton({
    Name = "💀 Matar Boss Instantâneo",
    Callback = function()
        local boss = findBoss(CFG.BossTarget)
        if boss then
            local hum = boss:FindFirstChildWhichIsA("Humanoid")
            if hum and hum.Health > 0 then
                for i = 1, 20 do
                    hitNPC(boss, 9999999)
                    task.wait(0.02)
                end
                notify("💀 Boss Morto!", boss.Name .. " eliminado!", 3)
            end
        else
            notify("⚠️", "Nenhum boss encontrado!", 3)
        end
    end,
})

-- ═══════════════════════════════════════════════════
-- TAB 3: COINS & EXP
-- ═══════════════════════════════════════════════════
local CoinsTab = Window:CreateTab("🪙 Coins & EXP", 4483345998)

CoinsTab:CreateSection("Farm de Moedas")

CoinsTab:CreateToggle({
    Name = "🪙 Auto Coin Farm",
    CurrentValue = false,
    Flag = "CoinFarm",
    Callback = function(val)
        if val then startCoinFarm() else stopCoinFarm() end
    end,
})

CoinsTab:CreateButton({
    Name = "📊 Ver Stats Atuais",
    Callback = function()
        getPlayerInfo()
    end,
})

CoinsTab:CreateSection("Farm Rápido de EXP")

CoinsTab:CreateButton({
    Name = "⚡ Farm EXP (Training Dummies)",
    Callback = function()
        local savedTarget = CFG.AutoFarmTarget
        local savedFarm = CFG.AutoFarm
        CFG.AutoFarmTarget = "Dummy"
        if not CFG.AutoFarm then startAutoFarm() end
        notify("⚡ EXP Farm", "Farmando em Training Dummies!", 3)
    end,
})

CoinsTab:CreateButton({
    Name = "🏆 Farm EXP Máximo (NPCs + Bosses)",
    Callback = function()
        CFG.AutoFarmTarget = "Todos"
        CFG.FarmRange = 99999
        if not CFG.AutoFarm then startAutoFarm() end
        if not CFG.BossFarm then startBossFarm() end
        notify("🏆 EXP MAX", "Farmando NPCs + Bosses simultaneamente!", 4)
    end,
})

CoinsTab:CreateSection("Coleta Rápida")

CoinsTab:CreateButton({
    Name = "🧲 Coletar Todas as Coins do Mapa",
    Callback = function()
        local root = getRoot()
        if not root then return end
        local count = 0
        for _, obj in pairs(WS:GetDescendants()) do
            if (obj.Name == "Chest" or obj.Name == "CoinTemplate") and obj:IsA("Model") then
                local part = obj:FindFirstChildWhichIsA("BasePart")
                if part then
                    root.CFrame = part.CFrame
                    if CoinEvent then
                        pcall(function() CoinEvent:FireServer() end)
                    end
                    count = count + 1
                    task.wait(0.05)
                end
            end
        end
        notify("🪙 Coins", count .. " coins coletadas!", 3)
    end,
})

-- ═══════════════════════════════════════════════════
-- TAB 4: PLAYER
-- ═══════════════════════════════════════════════════
local PlayerTab = Window:CreateTab("🏃 Player", 4483345998)

PlayerTab:CreateSection("Movimento")

PlayerTab:CreateSlider({
    Name = "⚡ WalkSpeed",
    Range = {16, 500},
    Increment = 1,
    Suffix = "studs/s",
    CurrentValue = 32,
    Flag = "WalkSpeed",
    Callback = function(val)
        CFG.WalkSpeed = val
        applyStats()
    end,
})

PlayerTab:CreateSlider({
    Name = "🦘 JumpPower",
    Range = {50, 500},
    Increment = 5,
    Suffix = "power",
    CurrentValue = 70,
    Flag = "JumpPower",
    Callback = function(val)
        CFG.JumpPower = val
        applyStats()
    end,
})

PlayerTab:CreateToggle({
    Name = "♾️ Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(val)
        CFG.InfiniteJump = val
    end,
})

PlayerTab:CreateSection("Habilidades")

PlayerTab:CreateToggle({
    Name = "👻 Noclip (Atravessa Paredes)",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(val)
        CFG.Noclip = val
        if not val then
            local char = getChar()
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end
    end,
})

PlayerTab:CreateToggle({
    Name = "🦅 Fly (WASD + Space + Shift Turbo)",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(val)
        if val then startFly() else stopFly() end
    end,
})

PlayerTab:CreateButton({
    Name = "❤️ Curar HP (Full Health)",
    Callback = function()
        local hum = getHum()
        if hum then
            hum.Health = hum.MaxHealth
            notify("❤️ HP", "HP restaurado!", 2)
        end
    end,
})

PlayerTab:CreateSection("Utilidades")

PlayerTab:CreateToggle({
    Name = "🎭 Anti-AFK",
    CurrentValue = true,
    Flag = "AntiAFK",
    Callback = function(val)
        CFG.AntiAFK = val
    end,
})

PlayerTab:CreateButton({
    Name = "🔄 Resetar Personagem",
    Callback = function()
        local hum = getHum()
        if hum then hum.Health = 0 end
    end,
})

-- ═══════════════════════════════════════════════════
-- TAB 5: ESP
-- ═══════════════════════════════════════════════════
local ESPTab = Window:CreateTab("👁️ ESP", 4483345998)

ESPTab:CreateSection("ESP de Inimigos")

ESPTab:CreateToggle({
    Name = "🟠 ESP - NPCs (Laranja)",
    CurrentValue = false,
    Flag = "ESPNPCs",
    Callback = function(val)
        CFG.ESPNPCs = val
        if val then updateNPCESP() else clearESP("npc") end
    end,
})

ESPTab:CreateToggle({
    Name = "🔴 ESP - Bosses (Vermelho)",
    CurrentValue = false,
    Flag = "ESPBosses",
    Callback = function(val)
        CFG.ESPBosses = val
        if val then updateBossESP() else clearESP("boss") end
    end,
})

ESPTab:CreateToggle({
    Name = "🔵 ESP - Players (Azul)",
    CurrentValue = false,
    Flag = "ESPPlayers",
    Callback = function(val)
        CFG.ESPPlayers = val
        if val then updatePlayerESP() else clearESP("players") end
    end,
})

ESPTab:CreateButton({
    Name = "🔄 Atualizar ESP",
    Callback = function()
        if CFG.ESPNPCs then updateNPCESP() end
        if CFG.ESPBosses then updateBossESP() end
        if CFG.ESPPlayers then updatePlayerESP() end
        notify("👁️ ESP", "ESP atualizado!", 2)
    end,
})

ESPTab:CreateButton({
    Name = "❌ Limpar Todo ESP",
    Callback = function()
        clearESP()
        CFG.ESPNPCs = false
        CFG.ESPBosses = false
        CFG.ESPPlayers = false
        notify("👁️ ESP", "ESP limpo!", 2)
    end,
})

-- ═══════════════════════════════════════════════════
-- TAB 6: TELEPORT
-- ═══════════════════════════════════════════════════
local TeleTab = Window:CreateTab("📍 Teleport", 4483345998)

TeleTab:CreateSection("Teleport para Jogadores")

TeleTab:CreateButton({
    Name = "📋 Listar Jogadores no Chat",
    Callback = function()
        local msg = "Jogadores online: "
        for _, p in pairs(Players:GetPlayers()) do
            msg = msg .. p.Name .. " | "
        end
        notify("👥 Players", msg, 5)
    end,
})

-- Teleport dinâmico para jogadores
for _, player in pairs(Players:GetPlayers()) do
    if player ~= LP then
        TeleTab:CreateButton({
            Name = "📍 TP → " .. player.Name,
            Callback = function()
                local root = getRoot()
                local targetChar = player.Character
                if root and targetChar then
                    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
                    if targetRoot then
                        root.CFrame = targetRoot.CFrame * CFrame.new(3, 0, 0)
                        notify("📍 Teleport", "Teleportado para " .. player.Name, 2)
                    end
                end
            end,
        })
    end
end

TeleTab:CreateSection("Locais do Mapa")

TeleTab:CreateButton({
    Name = "🌋 Zona da LavaGorilla",
    Callback = function()
        local root = getRoot()
        if root then
            local boss = WS:FindFirstChild("LavaGorilla", true)
            if boss and boss.PrimaryPart then
                root.CFrame = boss.PrimaryPart.CFrame * CFrame.new(10, 0, 0)
                notify("📍", "Teleportado para zona da LavaGorilla!", 2)
            else
                notify("⚠️", "LavaGorilla não encontrada!", 2)
            end
        end
    end,
})

TeleTab:CreateButton({
    Name = "🐻 Zona do BossBear",
    Callback = function()
        local root = getRoot()
        if root then
            local boss = WS:FindFirstChild("BOSSBEAR", true)
            if boss and boss.PrimaryPart then
                root.CFrame = boss.PrimaryPart.CFrame * CFrame.new(10, 0, 0)
                notify("📍", "Teleportado para zona do BOSSBEAR!", 2)
            else
                notify("⚠️", "BOSSBEAR não encontrado!", 2)
            end
        end
    end,
})

-- ═══════════════════════════════════════════════════
-- TAB 7: MISC
-- ═══════════════════════════════════════════════════
local MiscTab = Window:CreateTab("⚙️ Misc", 4483345998)

MiscTab:CreateSection("Configurações Gerais")

MiscTab:CreateToggle({
    Name = "🌟 God Mode (MaxHealth sempre cheio)",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(val)
        if val then
            Loops.godMode = RS.Heartbeat:Connect(function()
                local hum = getHum()
                if hum then
                    hum.Health = hum.MaxHealth
                end
            end)
            notify("🌟 God Mode", "Ativado!", 2)
        else
            if Loops.godMode then Loops.godMode:Disconnect(); Loops.godMode = nil end
            notify("🌟 God Mode", "Desativado.", 2)
        end
    end,
})

MiscTab:CreateToggle({
    Name = "👤 Transparência Local (Invisível)",
    CurrentValue = false,
    Flag = "Invisible",
    Callback = function(val)
        local char = getChar()
        if not char then return end
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                p.LocalTransparencyModifier = val and 1 or 0
            end
        end
        notify("👤", val and "Invisível ativado!" or "Visibilidade restaurada.", 2)
    end,
})

MiscTab:CreateSection("Debug & Info")

MiscTab:CreateButton({
    Name = "📊 Info do Personagem",
    Callback = function()
        local hum = getHum()
        local level = getLeaderstat("Level")
        local coins = getLeaderstat("Coins")
        local info = string.format(
            "HP: %s/%s | Level: %s | Coins: %s | Speed: %s",
            hum and math.floor(hum.Health) or "?",
            hum and hum.MaxHealth or "?",
            level and level.Value or "?",
            coins and coins.Value or "?",
            hum and hum.WalkSpeed or "?"
        )
        notify("📊 Info", info, 6)
        print("[AnimalSim] " .. info)
    end,
})

MiscTab:CreateButton({
    Name = "🗺️ Listar NPCs no Console",
    Callback = function()
        print("═══ NPCs no Mapa ═══")
        for _, tag in pairs({"NPC", "Dummy", "Dummy2"}) do
            for _, npc in pairs(CollSvc:GetTagged(tag)) do
                local hum = npc:FindFirstChildWhichIsA("Humanoid")
                if hum then
                    print(string.format("[%s] %s | HP: %s/%s", tag, npc.Name, math.floor(hum.Health), hum.MaxHealth))
                end
            end
        end
        print("═══════════════════")
        notify("🗺️", "NPCs listados no console (F9)!", 3)
    end,
})

MiscTab:CreateButton({
    Name = "🔄 Parar Todos os Loops",
    Callback = function()
        CFG.AutoFarm = false
        CFG.BossFarm = false
        CFG.CoinFarm = false
        for key, loop in pairs(Loops) do
            if typeof(loop) == "RBXScriptConnection" then
                loop:Disconnect()
            end
            Loops[key] = nil
        end
        stopFly()
        notify("🔄", "Todos os loops parados!", 3)
    end,
})

MiscTab:CreateSection("Créditos")

MiscTab:CreateLabel("🦁 Animal Simulator Script")
MiscTab:CreateLabel("Analisado da build: place_5712833750")
MiscTab:CreateLabel("Remotes identificados no jogo real")

-- ═══════════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════
task.spawn(function()
    task.wait(2)
    
    -- Aplica stats iniciais
    applyStats()
    
    -- Notificação de carregamento
    notify(
        "🦁 Animal Simulator Script",
        "Script carregado com sucesso! " ..
        "Remotes: CoinEvent, NPCDmg, jdskhfs... identificados.",
        5
    )
    
    -- Info inicial
    task.wait(1)
    getPlayerInfo()
    
    print("═══════════════════════════════════════")
    print("  🦁 ANIMAL SIMULATOR SCRIPT CARREGADO")
    print("  Rayfield UI aberta.")
    print("  Remote de dano: jdskhfsIII...lIlIli")
    print("  Boss Farm: BOSSBEAR, CRABBOSS, etc.")
    print("═══════════════════════════════════════")
end)

-- Auto-respawn após morte
LP.CharacterAdded:Connect(function()
    if CFG.AutoFarm or CFG.BossFarm then
        task.wait(2)
        applyStats()
        notify("🔄 Respawn", "Personagem respawnado! Farm continua.", 3)
    end
end)
