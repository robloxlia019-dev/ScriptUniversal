--[[
╔══════════════════════════════════════════════════════════════╗
║         COMUNIDADE BR - SCRIPT COMPLETO                      ║
║         Feito com base na análise dos scripts do jogo        ║
║         Compatível com: Synapse X, KRNL, Fluxus, Delta       ║
╚══════════════════════════════════════════════════════════════╝

  FUNÇÕES DISPONÍVEIS:
  [1] Boombox nas costas (equipa e toca música)
  [2] Tocar música pelo ID (FireServer PlayMusic)
  [3] Dinheiro infinito (loop de missão/daily)
  [4] Auto Daily Reward
  [5] Speed Hack / Noclip / FlyHack
  [6] Anti-AFK
  [7] Emote Spam
  [8] ESP (ver jogadores através das paredes)
  [9] Teleport para players
  [10] Hug Spam
  [11] Chat Spam / Mensagem
  [12] Modo invisível (LocalTransparency)
  [13] Auto Promocode (tenta códigos)
  [14] GUI completa com todos os botões

  AVISO: Use por sua conta e risco.
  Funciona em executor com nível 7+.
]]

-- ═══════════════════════════════════════════════
-- CONFIGURAÇÕES
-- ═══════════════════════════════════════════════
local CONFIG = {
    -- Boombox
    BoomboxSkin = "Boombox Normal",  -- Nome da skin (veja lista abaixo)
    MusicID = 18473699755,           -- ID da música para tocar (padrão: CASCA DE BALA)
    
    -- Speed
    WalkSpeed = 32,
    JumpPower = 75,
    
    -- Dinheiro
    MoneyLoopDelay = 0.1,   -- delay entre loops (menor = mais rápido, mas pode dar kick)
    
    -- ESP
    ESPColor = Color3.fromRGB(255, 50, 50),
    ESPThickness = 2,
}

--[[
  LISTA DE SKINS DE BOOMBOX (GamepassIDs do jogo):
  "Boombox Premium"     - gamepass 83141702
  "Boombox Normal"      - gamepass 83141762
  "Boombox Black"       - gamepass 152321948
  "Boombox Branca"      - gamepass 152322288
  "Boombox Vermelha"    - gamepass 152322237
  "Boombox Amarela"     - gamepass 152322014
  "Boombox Azul"        - gamepass 152322063
  "Boombox Roxa"        - gamepass 152322142
  "Boombox Verde"       - gamepass 152322186
  "Sky Boombox"         - gamepass 711190390
  "Boombox Carnaval 2026" - gamepass 1721318395
]]

--[[
  LISTA DE MÚSICAS DO JOGO (IDsDeMusicas):
  "Hoje eu Quero"                = 140555075230848
  "O PALHAÇO TÁ ALTERADO"        = 129804570129958
  "NitroNe Ritmada 2"            = 109794531843693
  "MONTAGEM VAI COCOTA"          = 92306125893928
  "MTG Explode"                  = 81384105684889
  "Zona Zero"                    = 110483047851014
  "Casca de Bala [POSTURADO]"    = 18473699755
  "Peças de Grife [POSTURADO]"   = 18473715636
  "10 CARROS [POSTURADO]"        = 16602428771
  "MDS [POSTURADO]"              = 16571767191
  ... e muitas mais no jogo!
]]

-- ═══════════════════════════════════════════════
-- VARIÁVEIS GLOBAIS
-- ═══════════════════════════════════════════════
local Players    = game:GetService("Players")
local RS         = game:GetService("RunService")
local TweenSvc   = game:GetService("TweenService")
local UIS        = game:GetService("UserInputService")
local HttpSvc    = game:GetService("HttpService")
local RepStorage = game:GetService("ReplicatedStorage")
local CoreGui    = game:GetService("CoreGui")

local LP         = Players.LocalPlayer
local PG         = LP:WaitForChild("PlayerGui")
local Camera     = workspace.CurrentCamera

-- Loops ativos
local loops = {
    antiAfk    = nil,
    moneyLoop  = nil,
    espLoop    = nil,
    flyLoop    = nil,
}
local flags = {
    noclip     = false,
    fly        = false,
    esp        = false,
    antiAfk    = false,
    boombox    = false,
    moneyLoop  = false,
    invisible  = false,
}

-- ═══════════════════════════════════════════════
-- FUNÇÃO: Obter remotes do jogo
-- ═══════════════════════════════════════════════
local function getRemote(type_, path)
    local success, result = pcall(function()
        local obj = RepStorage
        for _, part in pairs(path) do
            obj = obj:WaitForChild(part, 3)
            if not obj then return nil end
        end
        return obj
    end)
    if success and result then
        return result
    end
    return nil
end

-- Remotes identificados no jogo:
local Remotes        = RepStorage:FindFirstChild("Remotes")
local BoomBoxStorage = RepStorage:FindFirstChild("BoomboxStorage")
local BoomBoxEvents  = BoomBoxStorage and BoomBoxStorage:FindFirstChild("BoomBoxEvents")

local function getR(folder, name)
    if folder then
        return folder:FindFirstChild(name)
    end
    return nil
end

-- ═══════════════════════════════════════════════
-- [1] BOOMBOX NAS COSTAS - Equipar e aparecer
-- ═══════════════════════════════════════════════
local function equipBoombox(skinName)
    skinName = skinName or CONFIG.BoomboxSkin
    
    local char = LP.Character
    if not char then
        warn("[Boombox] Personagem não encontrado!")
        return
    end
    
    -- Tenta via RemoteEvent ChangeSkin (BoomBoxEvents)
    local changeSkinRemote = getR(BoomBoxEvents, "ChangeSkin")
    if changeSkinRemote then
        changeSkinRemote:FireServer(skinName)
        print("[Boombox] ChangeSkin enviado: " .. skinName)
    end
    
    -- Tenta criar fisicamente a boombox nas costas (client-side visual)
    -- Primeiro verifica se já existe
    if char:FindFirstChild("Boombox_ClientSide") then
        char.Boombox_ClientSide:Destroy()
    end
    
    -- Clona a boombox do BoomboxStorage se existir
    local boomboxModel = nil
    if BoomBoxStorage then
        local boomboxes = BoomBoxStorage:FindFirstChild("BoomBoxs")
        if boomboxes then
            local original = boomboxes:FindFirstChild(skinName)
            if original then
                boomboxModel = original:Clone()
            else
                -- Tenta qualquer boombox
                boomboxModel = boomboxes:GetChildren()[1]
                if boomboxModel then boomboxModel = boomboxModel:Clone() end
            end
        end
    end
    
    if boomboxModel then
        boomboxModel.Name = "Boombox_ClientSide"
        boomboxModel.Parent = char
        
        -- Welda nas costas do personagem
        local torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
        if torso then
            local primaryPart = boomboxModel.PrimaryPart or boomboxModel:FindFirstChildWhichIsA("BasePart")
            if primaryPart then
                -- Posiciona nas costas
                local weld = Instance.new("Weld")
                weld.Part0 = torso
                weld.Part1 = primaryPart
                weld.C0 = CFrame.new(0, 0, 1.2) * CFrame.Angles(0, math.pi, 0)
                weld.Parent = torso
                
                -- Torna todas as partes não colidiveis
                for _, part in pairs(boomboxModel:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                        part.Anchored = false
                    end
                end
                
                flags.boombox = true
                print("[Boombox] ✓ Boombox equipada nas costas: " .. skinName)
            end
        end
    else
        print("[Boombox] Modelo não encontrado no storage. Tentando via Tool...")
        -- Tenta via Backpack como Tool
        local boomboxTool = LP.Backpack:FindFirstChild("Boombox") 
                         or LP.Backpack:FindFirstChild(skinName)
        if boomboxTool then
            local humanoid = char:FindFirstChildWhichIsA("Humanoid")
            if humanoid then
                humanoid:EquipTool(boomboxTool)
                print("[Boombox] ✓ Tool de boombox equipada!")
            end
        else
            print("[Boombox] ⚠ Você não tem o gamepass de boombox.")
            print("[Boombox] Mas a música ainda pode ser tocada via PlayMusic!")
        end
    end
end

local function desequiparBoombox()
    local desequiparRemote = getR(BoomBoxEvents, "Desequipar")
    if desequiparRemote then
        desequiparRemote:FireServer()
    end
    local char = LP.Character
    if char then
        local boombox = char:FindFirstChild("Boombox_ClientSide")
        if boombox then boombox:Destroy() end
    end
    flags.boombox = false
    print("[Boombox] Desequipada.")
end

-- ═══════════════════════════════════════════════
-- [2] TOCAR MÚSICA (FireServer PlayMusic)
-- ═══════════════════════════════════════════════
local function tocarMusica(musicId)
    musicId = tonumber(musicId) or CONFIG.MusicID
    
    local playMusicRemote = BoomBoxStorage and BoomBoxStorage:FindFirstChild("PlayMusic")
    if playMusicRemote then
        playMusicRemote:FireServer(musicId)
        print("[Música] ✓ Tocando música ID: " .. tostring(musicId))
        return true
    end
    
    -- Alternativa: via BoomBoxEvents Play
    local playRemote = getR(BoomBoxEvents, "Play")
    if playRemote then
        playRemote:FireServer(musicId)
        print("[Música] ✓ Enviado via BoomBoxEvents.Play: " .. tostring(musicId))
        return true
    end
    
    print("[Música] ⚠ Remote PlayMusic não encontrado.")
    return false
end

local function pararMusica()
    local stopRemote = getR(BoomBoxEvents, "Stop")
    if stopRemote then
        stopRemote:FireServer()
        print("[Música] Parada.")
    end
end

-- Tocar música localmente (apenas você escuta, não precisa de gamepass)
local function tocarMusicaLocal(musicId)
    musicId = tostring(musicId or CONFIG.MusicID)
    
    -- Remove som anterior
    local oldSound = workspace:FindFirstChild("_ScriptLocalMusic")
    if oldSound then oldSound:Destroy() end
    
    local sound = Instance.new("Sound")
    sound.Name = "_ScriptLocalMusic"
    sound.SoundId = "rbxassetid://" .. musicId
    sound.Volume = 1
    sound.Looped = true
    sound.Parent = workspace
    sound:Play()
    print("[Música Local] ✓ Tocando localmente ID: " .. musicId)
    return sound
end

-- ═══════════════════════════════════════════════
-- [3] DINHEIRO INFINITO (Auto-click missão/daily)
-- ═══════════════════════════════════════════════
-- O jogo tem DailyEvent (RemoteFunction) e outras formas de ganhar dinheiro
-- Também tem o sistema de trabalho (TrabalhoBar)

local function claimDaily()
    local dailyRemote = getR(Remotes, "DailyEvent")
    if dailyRemote then
        local success, result = pcall(function()
            return dailyRemote:InvokeServer()
        end)
        if success then
            print("[Daily] Coletado! Resultado: " .. tostring(result))
            return result
        else
            print("[Daily] Erro: " .. tostring(result))
        end
    else
        print("[Daily] Remote DailyEvent não encontrado.")
    end
    return nil
end

-- Loop de dinheiro: tenta usar Add remote repetidamente
-- (O remote Add provavelmente adiciona dinheiro no servidor via sistema de missão)
local function startMoneyLoop()
    if flags.moneyLoop then
        print("[Dinheiro] Loop já está ativo!")
        return
    end
    flags.moneyLoop = true
    print("[Dinheiro] ⚡ Loop de dinheiro iniciado!")
    print("[Dinheiro] Tentando via DailyEvent e outros remotes...")
    
    local addRemote = getR(Remotes, "Add")
    local dailyRemote = getR(Remotes, "DailyEvent")
    
    loops.moneyLoop = task.spawn(function()
        while flags.moneyLoop do
            -- Tenta DailyEvent (ganhar recompensa diária)
            if dailyRemote then
                pcall(function()
                    dailyRemote:InvokeServer()
                end)
            end
            
            -- Tenta Add remote (pode adicionar items/moeda)
            if addRemote then
                pcall(function()
                    addRemote:FireServer()
                end)
            end
            
            -- Atualiza display de dinheiro no GUI
            local leaderstats = LP:FindFirstChild("leaderstats")
            if leaderstats then
                local dinheiro = leaderstats:FindFirstChild("Dinheiro")
                if dinheiro then
                    -- Força atualização visual
                    dinheiro:GetPropertyChangedSignal("Value"):Connect(function()
                        print("[Dinheiro] 💰 Saldo atual: $" .. tostring(dinheiro.Value))
                    end)
                end
            end
            
            task.wait(CONFIG.MoneyLoopDelay)
        end
        print("[Dinheiro] Loop parado.")
    end)
end

local function stopMoneyLoop()
    flags.moneyLoop = false
    print("[Dinheiro] Loop parado.")
end

-- ═══════════════════════════════════════════════
-- [4] SPEED / WALKSPEED
-- ═══════════════════════════════════════════════
local function setSpeed(speed)
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum then
            hum.WalkSpeed = speed or CONFIG.WalkSpeed
            hum.JumpPower = CONFIG.JumpPower
            print("[Speed] WalkSpeed = " .. tostring(speed))
        end
    end
end

-- Re-aplica speed quando personagem respawn
LP.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum and flags.noclip == false then
        task.wait(0.5)
        if CONFIG.WalkSpeed ~= 16 then
            hum.WalkSpeed = CONFIG.WalkSpeed
        end
    end
end)

-- ═══════════════════════════════════════════════
-- [5] NOCLIP
-- ═══════════════════════════════════════════════
RS.Stepped:Connect(function()
    if flags.noclip then
        local char = LP.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end
    end
end)

local function toggleNoclip()
    flags.noclip = not flags.noclip
    if not flags.noclip then
        -- Restaura colisão
        local char = LP.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
    print("[Noclip] " .. (flags.noclip and "ATIVADO ✓" or "DESATIVADO"))
end

-- ═══════════════════════════════════════════════
-- [6] FLY HACK
-- ═══════════════════════════════════════════════
local flyBody = {}

local function startFly()
    flags.fly = true
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    -- Remove gravidade
    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    bg.P = 1e9
    bg.Parent = root
    flyBody.gyro = bg
    
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    bv.Velocity = Vector3.zero
    bv.Parent = root
    flyBody.velocity = bv
    
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if hum then hum.PlatformStand = true end
    
    loops.flyLoop = RS.RenderStepped:Connect(function()
        if not flags.fly then return end
        local cam = Camera
        local moveDir = Vector3.zero
        
        if UIS:IsKeyDown(Enum.KeyCode.W) then moveDir = moveDir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then moveDir = moveDir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then moveDir = moveDir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then moveDir = moveDir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then moveDir = moveDir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then moveDir = moveDir - Vector3.new(0,1,0) end
        
        local speed = UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 80 or 40
        
        if moveDir.Magnitude > 0 then
            bv.Velocity = moveDir.Unit * speed
        else
            bv.Velocity = Vector3.zero
        end
        
        if moveDir.Magnitude > 0 then
            bg.CFrame = CFrame.new(root.Position, root.Position + moveDir)
        end
    end)
    
    print("[Fly] ✓ Ativado! WASD = mover, Space = subir, Ctrl = descer, Shift = turbo")
end

local function stopFly()
    flags.fly = false
    if loops.flyLoop then loops.flyLoop:Disconnect(); loops.flyLoop = nil end
    if flyBody.gyro then flyBody.gyro:Destroy() end
    if flyBody.velocity then flyBody.velocity:Destroy() end
    flyBody = {}
    
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildWhichIsA("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    print("[Fly] Desativado.")
end

local function toggleFly()
    if flags.fly then stopFly() else startFly() end
end

-- ═══════════════════════════════════════════════
-- [7] ANTI-AFK
-- ═══════════════════════════════════════════════
local function toggleAntiAfk()
    flags.antiAfk = not flags.antiAfk
    if flags.antiAfk then
        loops.antiAfk = task.spawn(function()
            local VirtualUser = game:GetService("VirtualUser")
            while flags.antiAfk do
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
                task.wait(15)
            end
        end)
        print("[Anti-AFK] ✓ Ativado!")
    else
        print("[Anti-AFK] Desativado.")
    end
end

-- ═══════════════════════════════════════════════
-- [8] ESP - Ver jogadores através das paredes
-- ═══════════════════════════════════════════════
local espObjects = {}

local function createESP(player)
    if player == LP then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_" .. player.Name
    highlight.FillColor = CONFIG.ESPColor
    highlight.OutlineColor = Color3.new(1,1,1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    
    local function update()
        local char = player.Character
        if char and highlight then
            highlight.Adornee = char
            highlight.Parent = CoreGui
        end
    end
    
    update()
    player.CharacterAdded:Connect(update)
    espObjects[player.Name] = highlight
end

local function removeESP(player)
    local esp = espObjects[player.Name]
    if esp then
        esp:Destroy()
        espObjects[player.Name] = nil
    end
end

local function toggleESP()
    flags.esp = not flags.esp
    if flags.esp then
        for _, player in pairs(Players:GetPlayers()) do
            createESP(player)
        end
        Players.PlayerAdded:Connect(function(p)
            if flags.esp then createESP(p) end
        end)
        Players.PlayerRemoving:Connect(function(p)
            removeESP(p)
        end)
        print("[ESP] ✓ Ativado!")
    else
        for _, esp in pairs(espObjects) do
            if esp then esp:Destroy() end
        end
        espObjects = {}
        print("[ESP] Desativado.")
    end
end

-- ═══════════════════════════════════════════════
-- [9] TELEPORT PARA PLAYER
-- ═══════════════════════════════════════════════
local function teleportTo(playerName)
    local target = Players:FindFirstChild(playerName)
    if not target then
        -- Busca parcial
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():find(playerName:lower()) then
                target = p
                break
            end
        end
    end
    
    if not target then
        print("[Teleport] ⚠ Jogador '" .. playerName .. "' não encontrado.")
        return
    end
    
    local char = LP.Character
    local targetChar = target.Character
    
    if char and targetChar then
        local root = char:FindFirstChild("HumanoidRootPart")
        local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
        if root and targetRoot then
            root.CFrame = targetRoot.CFrame + Vector3.new(2, 0, 0)
            print("[Teleport] ✓ Teleportado para " .. target.Name)
        end
    end
end

-- ═══════════════════════════════════════════════
-- [10] HUG SPAM
-- ═══════════════════════════════════════════════
local function hugPlayer(playerName)
    local target = Players:FindFirstChild(playerName)
    if not target then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Name:lower():find(playerName:lower()) then
                target = p
                break
            end
        end
    end
    
    if not target then
        print("[Hug] Jogador não encontrado: " .. playerName)
        return
    end
    
    local hugRemote = getR(Remotes, "Hug")
    if hugRemote then
        hugRemote:FireServer(target)
        print("[Hug] ✓ Abraçou " .. target.Name)
    else
        print("[Hug] Remote Hug não encontrado.")
    end
end

local function hugSpam(playerName, amount)
    amount = amount or 10
    task.spawn(function()
        for i = 1, amount do
            hugPlayer(playerName)
            task.wait(0.1)
        end
        print("[Hug Spam] ✓ Enviou " .. amount .. " abraços para " .. playerName)
    end)
end

-- ═══════════════════════════════════════════════
-- [11] MODO INVISÍVEL (transparência local)
-- ═══════════════════════════════════════════════
local function toggleInvisivel()
    flags.invisible = not flags.invisible
    local char = LP.Character
    if not char then return end
    
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") or part:IsA("Decal") then
            part.LocalTransparencyModifier = flags.invisible and 1 or 0
        end
    end
    print("[Invisível] " .. (flags.invisible and "ATIVADO (apenas visual)" or "DESATIVADO"))
end

-- ═══════════════════════════════════════════════
-- [12] EMOTE SPAM
-- ═══════════════════════════════════════════════
-- IDs de emote encontrados no script syncEmote do jogo:
local EMOTE_IDS = {
    100545872015841, 119696276842469, 123312690441973, 83311999765713,
    94505880782162, 100681208320300, 93397307125368, 79716874437437,
    102544119718369, 133718157859498, 92200253218088, 97185364700038,
    85961795938515, 96357779735687
}

local function playEmote(emoteId)
    emoteId = emoteId or EMOTE_IDS[1]
    
    -- Tenta via BindableFunction PlayEmote (encontrado no jogo)
    local char = LP.Character
    if char then
        local playEmoteBF = char:FindFirstChild("PlayEmote")
        if playEmoteBF and playEmoteBF:IsA("BindableFunction") then
            pcall(function()
                playEmoteBF:Invoke(emoteId)
            end)
            print("[Emote] Tocando emote ID: " .. tostring(emoteId))
            return
        end
    end
    
    -- Tenta via AnimationSync
    local animSyncRemote = RepStorage:FindFirstChild("SychronizationRemotes")
    if animSyncRemote then
        local syncRemote = animSyncRemote:FindFirstChild("AnimationSync")
        if syncRemote then
            pcall(function()
                syncRemote:FireServer(emoteId)
            end)
            print("[Emote] Enviado via AnimationSync: " .. tostring(emoteId))
        end
    end
end

-- ═══════════════════════════════════════════════
-- [13] AUTO PROMOCODE (força todos os codes)
-- ═══════════════════════════════════════════════
-- Codes populares de jogos BR no Roblox
local CODES_PARA_TENTAR = {
    "LAUNCH", "UPDATE", "COMUNIDADE", "BRASIL", "BR2024", "BR2025", "BR2026",
    "GRATIS", "DINHEIRO", "MONEY", "FREE", "SORTEIO", "EVENTO", "CARNAVAL",
    "NATAL", "ANIVERSARIO", "DISCORD", "GRUPO", "FAVORITO", "LIKE",
    "100K", "500K", "1M", "2M", "5M", "10M", "50M", "100M",
    "GAZINH", "BOOMBOX", "NOVIDADE", "ATUALIZAÇÃO", "UPDATE1", "UPDATE2",
}

local function tryPromocode(code)
    local promocodeRemote = getR(Remotes, "Promocodes")
    if promocodeRemote then
        local success, result = pcall(function()
            return promocodeRemote:InvokeServer(code)
        end)
        if success and result then
            if result:find("resgatado") or result:find("sucesso") then
                print("[Promo] ✅ CÓDIGO FUNCIONOU: " .. code .. " -> " .. tostring(result))
                return true
            end
        end
    end
    return false
end

local function autoTryAllCodes()
    print("[Promo] Tentando " .. #CODES_PARA_TENTAR .. " códigos...")
    task.spawn(function()
        for _, code in pairs(CODES_PARA_TENTAR) do
            tryPromocode(code)
            task.wait(0.5)
        end
        print("[Promo] ✓ Tentativa de todos os códigos concluída!")
    end)
end

-- ═══════════════════════════════════════════════
-- [14] INFORMAÇÕES DO JOGADOR
-- ═══════════════════════════════════════════════
local function printPlayerInfo()
    local leaderstats = LP:FindFirstChild("leaderstats")
    print("═══════════════════════════════")
    print("  COMUNIDADE BR - INFO DO PLAYER")
    print("═══════════════════════════════")
    print("  Nome: " .. LP.Name)
    print("  UserId: " .. LP.UserId)
    if leaderstats then
        for _, stat in pairs(leaderstats:GetChildren()) do
            print("  " .. stat.Name .. ": " .. tostring(stat.Value))
        end
    else
        print("  (leaderstats não carregou ainda)")
    end
    print("═══════════════════════════════")
end

-- ═══════════════════════════════════════════════
-- [15] CRIAR GUI PRINCIPAL
-- ═══════════════════════════════════════════════
local function createGUI()
    -- Remove GUI anterior se existir
    local oldGui = CoreGui:FindFirstChild("ComunidadeBR_Script")
    if oldGui then oldGui:Destroy() end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ComunidadeBR_Script"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui
    
    -- Escala automática para DPI alto (360 DPI = viewport menor)
    -- Usa escala relativa à tela para funcionar em qualquer resolução
    local vp = Camera.ViewportSize
    local scale = math.clamp(vp.Y / 600, 1, 2.5)  -- escala adaptativa

    -- Frame principal (ocupa ~55% da largura, ~85% da altura, centralizado)
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0.55, 0, 0.85, 0)
    Main.Position = UDim2.new(0.01, 0, 0.07, 0)
    Main.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    Main.BorderSizePixel = 0
    Main.Active = true
    Main.Draggable = true
    Main.Parent = ScreenGui
    
    -- Borda/Corner
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0.02, 0)
    corner.Parent = Main
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(100, 60, 220)
    stroke.Thickness = 3
    stroke.Parent = Main
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0.07, 0)
    Header.BackgroundColor3 = Color3.fromRGB(80, 40, 180)
    Header.BorderSizePixel = 0
    Header.Parent = Main
    
    local hCorner = Instance.new("UICorner")
    hCorner.CornerRadius = UDim.new(0.5, 0)
    hCorner.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(0.82, 0, 1, 0)
    Title.Position = UDim2.new(0.02, 0, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "🎵 COMUNIDADE BR SCRIPT"
    Title.TextColor3 = Color3.new(1,1,1)
    Title.Font = Enum.Font.GothamBold
    Title.TextScaled = true
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    -- Botão fechar
    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0.1, 0, 0.75, 0)
    CloseBtn.Position = UDim2.new(0.88, 0, 0.12, 0)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
    CloseBtn.Text = "✕"
    CloseBtn.TextColor3 = Color3.new(1,1,1)
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextScaled = true
    CloseBtn.BorderSizePixel = 0
    CloseBtn.Parent = Header
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0.3, 0)
    
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    -- Área de scroll para botões
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Size = UDim2.new(1, 0, 0.93, 0)
    Scroll.Position = UDim2.new(0, 0, 0.07, 0)
    Scroll.BackgroundTransparency = 1
    Scroll.ScrollBarThickness = 6
    Scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Scroll.Parent = Main
    
    local ListLayout = Instance.new("UIListLayout")
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Padding = UDim.new(0.008, 0)
    ListLayout.Parent = Scroll
    
    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0.008, 0)
    Padding.PaddingLeft = UDim.new(0.02, 0)
    Padding.PaddingRight = UDim.new(0.02, 0)
    Padding.Parent = Scroll
    
    -- Função para criar seção
    local function createSection(name)
        local section = Instance.new("TextLabel")
        section.Size = UDim2.new(1, 0, 0, 0)
        section.AutomaticSize = Enum.AutomaticSize.Y
        section.BackgroundColor3 = Color3.fromRGB(50, 30, 100)
        section.Text = " ── " .. name .. " ──"
        section.TextColor3 = Color3.fromRGB(200, 160, 255)
        section.Font = Enum.Font.GothamBold
        section.TextScaled = false
        section.TextSize = 22
        section.BorderSizePixel = 0
        section.Parent = Scroll
        Instance.new("UICorner", section).CornerRadius = UDim.new(0.3, 0)
        local p = Instance.new("UIPadding")
        p.PaddingTop = UDim.new(0,6); p.PaddingBottom = UDim.new(0,6)
        p.PaddingLeft = UDim.new(0,8)
        p.Parent = section
        return section
    end
    
    -- Função para criar botão toggle
    local function createToggle(text, callback, isActive)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 60)
        btn.BackgroundColor3 = isActive and Color3.fromRGB(50, 160, 50) or Color3.fromRGB(40, 40, 65)
        btn.Text = (isActive and "✓  " or "      ") .. text
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 22
        btn.BorderSizePixel = 0
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = Scroll
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0.3, 0)
        btnCorner.Parent = btn
        
        local BtnPad = Instance.new("UIPadding")
        BtnPad.PaddingLeft = UDim.new(0, 14)
        BtnPad.Parent = btn
        
        local active = isActive or false
        btn.MouseButton1Click:Connect(function()
            active = not active
            callback(active)
            btn.BackgroundColor3 = active and Color3.fromRGB(50, 160, 50) or Color3.fromRGB(40, 40, 65)
            btn.Text = (active and "✓  " or "      ") .. text
        end)
        
        return btn
    end
    
    -- Função para criar botão simples
    local function createButton(text, color, callback)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 60)
        btn.BackgroundColor3 = color or Color3.fromRGB(60, 60, 100)
        btn.Text = text
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 22
        btn.BorderSizePixel = 0
        btn.Parent = Scroll
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0.3, 0)
        btn.MouseButton1Click:Connect(callback)
        return btn
    end
    
    -- Função para criar input + botão
    local function createInputButton(placeholder, btnText, color, callback)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, 0, 0, 60)
        frame.BackgroundTransparency = 1
        frame.Parent = Scroll
        
        local input = Instance.new("TextBox")
        input.Size = UDim2.new(0.65, -4, 1, 0)
        input.BackgroundColor3 = Color3.fromRGB(30, 30, 52)
        input.PlaceholderText = placeholder
        input.Text = ""
        input.TextColor3 = Color3.new(1,1,1)
        input.PlaceholderColor3 = Color3.fromRGB(130,130,160)
        input.Font = Enum.Font.Gotham
        input.TextSize = 20
        input.ClearTextOnFocus = false
        input.BorderSizePixel = 0
        input.Parent = frame
        Instance.new("UICorner", input).CornerRadius = UDim.new(0.3, 0)
        local ip = Instance.new("UIPadding"); ip.PaddingLeft = UDim.new(0,10); ip.Parent = input
        
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.34, 0, 1, 0)
        btn.Position = UDim2.new(0.66, 4, 0, 0)
        btn.BackgroundColor3 = color or Color3.fromRGB(80, 40, 180)
        btn.Text = btnText
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 19
        btn.BorderSizePixel = 0
        btn.Parent = frame
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0.3, 0)
        
        btn.MouseButton1Click:Connect(function()
            callback(input.Text)
        end)
        
        return frame, input
    end
    
    -- ═══════════ SEÇÃO: BOOMBOX ═══════════
    createSection("🎵 BOOMBOX")
    
    createButton("🎒 Equipar Boombox (Costas)", Color3.fromRGB(130, 60, 200), function()
        equipBoombox(CONFIG.BoomboxSkin)
    end)
    
    createButton("❌ Desequipar Boombox", Color3.fromRGB(150, 40, 40), function()
        desequiparBoombox()
    end)
    
    local _, musicInput = createInputButton("ID da Música...", "🎵 Tocar (Global)", Color3.fromRGB(80, 150, 80), function(text)
        local id = tonumber(text)
        if id then
            tocarMusica(id)
        else
            print("[Música] Digite um ID numérico válido!")
        end
    end)
    
    local _, localMusicInput = createInputButton("ID da Música (local)...", "🔈 Local", Color3.fromRGB(60, 120, 160), function(text)
        local id = tonumber(text) or text
        tocarMusicaLocal(tostring(id))
    end)
    
    createButton("⏹ Parar Música", Color3.fromRGB(120, 60, 60), function()
        pararMusica()
        local s = workspace:FindFirstChild("_ScriptLocalMusic")
        if s then s:Destroy() end
    end)
    
    -- ═══════════ SEÇÃO: MOVIMENTO ═══════════
    createSection("⚡ MOVIMENTO")
    
    createToggle("🚀 Speed Hack (x2)", function(active)
        CONFIG.WalkSpeed = active and 48 or 16
        setSpeed(CONFIG.WalkSpeed)
    end)
    
    createToggle("👟 Speed Máximo", function(active)
        CONFIG.WalkSpeed = active and 100 or 16
        setSpeed(CONFIG.WalkSpeed)
    end)
    
    createToggle("👻 Noclip", function(active)
        flags.noclip = active
        if not active then
            local char = LP.Character
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end
    end)
    
    createToggle("🦅 Fly (WASD + Space)", function(active)
        if active then startFly() else stopFly() end
    end)
    
    -- ═══════════ SEÇÃO: DINHEIRO ═══════════
    createSection("💰 DINHEIRO")
    
    createButton("🎁 Coletar Daily Reward", Color3.fromRGB(200, 150, 20), function()
        claimDaily()
    end)
    
    createToggle("⚡ Loop de Dinheiro (Auto)", function(active)
        if active then startMoneyLoop() else stopMoneyLoop() end
    end)
    
    createButton("💬 Ver Saldo Atual", Color3.fromRGB(60, 120, 60), function()
        printPlayerInfo()
    end)
    
    -- ═══════════ SEÇÃO: PLAYERS ═══════════
    createSection("👥 PLAYERS")
    
    local _, tpInput = createInputButton("Nome do jogador...", "📍 Teleport", Color3.fromRGB(80, 80, 180), function(text)
        if text ~= "" then teleportTo(text) end
    end)
    
    local _, hugInput = createInputButton("Nome do jogador...", "🤗 Hug x10", Color3.fromRGB(180, 80, 140), function(text)
        if text ~= "" then hugSpam(text, 10) end
    end)
    
    -- ═══════════ SEÇÃO: EXTRAS ═══════════
    createSection("🔧 EXTRAS")
    
    createToggle("👁 ESP (ver jogadores)", function(active)
        flags.esp = active
        toggleESP()
    end)
    
    createToggle("💀 Invisível (local)", function(active)
        flags.invisible = active
        toggleInvisivel()
    end)
    
    createToggle("🎭 Anti-AFK", function(active)
        flags.antiAfk = active
        if active then toggleAntiAfk() else flags.antiAfk = false end
    end)
    
    createButton("🎟 Tentar Todos Promocodes", Color3.fromRGB(200, 120, 20), function()
        autoTryAllCodes()
    end)
    
    local _, promoInput = createInputButton("Código...", "✅ Resgatar", Color3.fromRGB(200, 150, 20), function(text)
        if text ~= "" then
            local result = tryPromocode(text)
            print("[Promo] " .. (result and "✅ Sucesso!" or "❌ Inválido."))
        end
    end)
    
    createButton("🎵 Emote Aleatório", Color3.fromRGB(100, 60, 160), function()
        local emoteId = EMOTE_IDS[math.random(1, #EMOTE_IDS)]
        playEmote(emoteId)
    end)
    
    createButton("ℹ Info do Jogador", Color3.fromRGB(50, 80, 130), function()
        printPlayerInfo()
    end)
    
    -- Label de crédito
    local credit = Instance.new("TextLabel")
    credit.Size = UDim2.new(1, 0, 0, 36)
    credit.BackgroundTransparency = 1
    credit.Text = "Comunidade BR Script • v1.0"
    credit.TextColor3 = Color3.fromRGB(100, 100, 150)
    credit.Font = Enum.Font.Gotham
    credit.TextSize = 18
    credit.Parent = Scroll
    
    print("═══════════════════════════════════════")
    print("  ✓ COMUNIDADE BR SCRIPT CARREGADO!")
    print("  GUI aberta. Drag para mover.")
    print("═══════════════════════════════════════")
    
    return ScreenGui
end

-- ═══════════════════════════════════════════════
-- INICIALIZAÇÃO
-- ═══════════════════════════════════════════════

-- Aguarda personagem carregar
local function init()
    if not LP.Character then
        LP.CharacterAdded:Wait()
    end
    
    -- Anti-AFK por padrão
    toggleAntiAfk()
    
    -- Cria GUI
    createGUI()
    
    -- Mostra info inicial
    task.wait(1)
    printPlayerInfo()
end

task.spawn(init)

--[[
  ═══════════════════════════════════════════
  GUIA DE MÚSICAS DO JOGO (BoomboxStorage)
  Para tocar globalmente use: tocarMusica(ID)
  Para tocar só pra você: tocarMusicaLocal("ID")
  ═══════════════════════════════════════════
  
  Coloca um ID aqui para tocar automaticamente:
  tocarMusica(18473699755) -- CASCA DE BALA
  tocarMusica(16602428771) -- 10 CARROS
  tocarMusica(110483047851014) -- ZONA ZERO
  tocarMusica(92306125893928) -- MONTAGEM VAI COCOTA
  
  Para boombox nas costas:
  CONFIG.BoomboxSkin = "Boombox Normal"
  equipBoombox()
  
  Para speed:
  setSpeed(50) -- velocidade customizada
  
  Para teleportar:
  teleportTo("NomeDoJogador")
]]
