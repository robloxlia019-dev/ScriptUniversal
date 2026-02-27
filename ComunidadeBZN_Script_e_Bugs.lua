--[[
╔══════════════════════════════════════════════════════════════════════╗
║     SCRIPT - COMUNIDADE BZN (Seu jogo de amigo)                     ║
║     Boombox • Fly • Speed • ESP • Info                               ║
║     Remote: PlayMusic (RemoteFunction) / RadioVolume / RadioSkin     ║
║     Boombox fica em: X=469.9, Y=5189.8, Z=6513.9                    ║
╚══════════════════════════════════════════════════════════════════════╝

  ════════════════════════════════════════════════════════
  ⚠️  LISTA DE ERROS/BUGS encontrados no jogo do seu amigo
  (copie e mande pra ele!)
  ════════════════════════════════════════════════════════

  ❌ BUG 1 — HD Admin gerando SPAM de produtos/gamepass
  Causa: O script "HDAdminLocalFirst" tem um LocalScript que está
  rodando DENTRO DO HD ADMIN e chama:
    MarketplaceService:GetProductInfo(1128442562, ...)
  Isso é um script do HD Admin chamado "songIDsModule" (nome errado
  porque o decompilador misturou o nome). O script fica num loop
  exibindo promoções/gamepasses do próprio HD Admin (loja do ForeverHD).
  
  ✅ SOLUÇÃO: No Roblox Studio, ir em:
    StarterGui > HDAdmin (ou onde o HD Admin estiver) >
    procurar LocalScript chamado "HDAdminLocalFirst" que tem dentro dele
    referência ao produto 1128442562.
    Deletar esse LocalScript OU desabilitar o "CountdownFeature" nas
    configurações do HD Admin (Settings > PromotionsEnabled = false).
  
  ════════════════════════════════════════════════════════
  
  ❌ BUG 2 — Script "TestRemoteFunction" rodando no jogo
  Causa: Tem um LocalScript chamado "TestRemoteFunction" que foi deixado
  no jogo por engano. Ele roda diagnósticos (print de todos os filhos
  do PlayerGui) toda vez que alguém entra. É um script de debug esquecido.
  
  ✅ SOLUÇÃO: Deletar o LocalScript "TestRemoteFunction" do jogo.
  Ele fica provavelmente em StarterPlayerScripts ou StarterCharacterScripts.
  
  ════════════════════════════════════════════════════════

  ❌ BUG 3 — "AFKLocalScript" está mal nomeado e no lugar errado
  Causa: Um script chamado "AFKLocalScript" na verdade cria o botão
  de boombox ("🎵 Boombox") e abre o BoomboxGui. Não tem NADA a ver
  com AFK. O nome induz a erro e pode fazer o script ser deletado
  por engano achando que é o sistema AFK.
  
  ✅ SOLUÇÃO: Renomear para "BoomboxButtonScript" ou similar.
  
  ════════════════════════════════════════════════════════
  
  ❌ BUG 4 — Boombox física no mapa em posição absurda
  Causa: Existe um Model chamado "Boombox" solto no mapa nas
  coordenadas X=469.9, Y=5189.8, Z=6513.9 — que é Y=5189 (bem
  acima do mapa), provavelmente voando no ar ou sumindo.
  
  ✅ SOLUÇÃO: Verificar no Explorer do Studio se esse Model
  "Boombox" existe e está no lugar certo. Se estiver no workspace
  flutuando, reposicioná-lo ou deletar.
  
  ════════════════════════════════════════════════════════
  
  ❌ BUG 5 — Dois scripts "AFKTag" vazios duplicados
  Causa: Existem 2 Scripts chamados "AFKTag" com source vazio (148 chars
  que é basicamente só o header do salvamento). Scripts vazios duplicados
  podem causar erros de referência e confusão.
  
  ✅ SOLUÇÃO: Deletar os dois scripts "AFKTag" e recriar um só se necessário.
  
  ════════════════════════════════════════════════════════
  
  ❌ BUG 6 — Dois "AFKLocalScript" com funções diferentes
  Causa: Existem 2 LocalScripts com o mesmo nome "AFKLocalScript":
  - Um cria o botão de Boombox (confundido como AFK)
  - Outro inicializa o HD Admin Player (também mal nomeado)
  Isso causa confusão de manutenção.
  
  ✅ SOLUÇÃO: Renomear ambos com nomes que refletem o que fazem.
  
  ════════════════════════════════════════════════════════
  
  ❌ BUG 7 — HD Admin: PageSettings cria produtos de jogos aleatórios
  Causa: O módulo "PageSettings" do HD Admin usa:
    HDAdminMain:GetModule("cf"):RandomiseTable({}, 86400)
  pra mostrar jogos aleatórios do HD Admin no painel Donor.
  Essa lista de jogos pode aparecer como "produtos" pra jogadores.
  
  ✅ SOLUÇÃO: Atualizar o HD Admin para versão mais recente OU
  ir nas configurações e desabilitar "ShowDonorGames = false".
  
  ════════════════════════════════════════════════════════

  RESUMO DOS REMOTES DO JOGO:
  • PlayMusic (RemoteFunction) → Tocar música na boombox
  • RadioVolume (RemoteEvent) → Ajustar volume
  • RadioSkin (RemoteEvent) → Mudar skin da boombox
  • GetRadioSkins (RemoteFunction) → Listar skins
  • EquipRadioSkin (RemoteEvent) → Equipar skin
]]

-- ═══════════════════════════════════════════════════
-- SERVIÇOS
-- ═══════════════════════════════════════════════════
local Players    = game:GetService("Players")
local RS         = game:GetService("RunService")
local RepStorage = game:GetService("ReplicatedStorage")
local UIS        = game:GetService("UserInputService")
local CoreGui    = game:GetService("CoreGui")
local TweenSvc   = game:GetService("TweenService")

local LP         = Players.LocalPlayer
local Camera     = workspace.CurrentCamera

-- Remotes do jogo
local PlayMusic  = RepStorage:FindFirstChild("PlayMusic")   -- RemoteFunction
local RadioVol   = RepStorage:FindFirstChild("RadioVolume") -- RemoteEvent
local RadioSkin  = RepStorage:FindFirstChild("RadioSkin")   -- RemoteEvent
local GetSkins   = RepStorage:FindFirstChild("GetRadioSkins") -- RemoteFunction
local EquipSkin  = RepStorage:FindFirstChild("EquipRadioSkin") -- RemoteEvent

-- ═══════════════════════════════════════════════════
-- ESTADO
-- ═══════════════════════════════════════════════════
local Config = {
    Speed       = 32,
    Jump        = 70,
    Noclip      = false,
    Fly         = false,
    InfJump     = false,
    ESP         = false,
    AntiAFK     = true,
    GodMode     = false,
}

local Connections = {}
local FlyParts    = {}
local ESPHighlights = {}

-- ═══════════════════════════════════════════════════
-- UTILITÁRIOS
-- ═══════════════════════════════════════════════════
local function getChar()   return LP.Character end
local function getRoot()   local c = getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()    local c = getChar(); return c and c:FindFirstChildWhichIsA("Humanoid") end

local function notify(msg, duration)
    local sg = Instance.new("ScreenGui"); sg.Name="CMBRNotif"; sg.ResetOnSpawn=false; sg.IgnoreGuiInset=true
    local lbl = Instance.new("TextLabel", sg)
    lbl.Size = UDim2.new(0.4,0,0,40); lbl.Position = UDim2.new(0.3,0,0.9,0)
    lbl.BackgroundColor3 = Color3.fromRGB(20,20,35); lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Text = msg; lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 15
    lbl.BorderSizePixel = 0; Instance.new("UICorner", lbl).CornerRadius = UDim.new(0,8)
    sg.Parent = CoreGui
    task.delay(duration or 3, function() sg:Destroy() end)
end

-- ═══════════════════════════════════════════════════
-- BOOMBOX FUNCTIONS
-- ═══════════════════════════════════════════════════
local function playMusic(musicId)
    if not PlayMusic then
        notify("⚠️ Remote PlayMusic não encontrado!", 4)
        return
    end
    local ok, result = pcall(function()
        return PlayMusic:InvokeServer("play", tonumber(musicId))
    end)
    if ok and result then
        notify("🎵 Tocando: " .. tostring(result.Name or musicId), 4)
        return result
    elseif ok and not result then
        notify("⚠️ ID inválido ou sem permissão.", 3)
    else
        notify("❌ Erro ao tocar: " .. tostring(result), 3)
    end
end

local function stopMusic()
    if not PlayMusic then return end
    pcall(function()
        PlayMusic:InvokeServer("stop")
    end)
    notify("⏹️ Música parada.", 2)
end

local function setVolume(vol) -- 0 a 1
    if not RadioVol then return end
    pcall(function()
        RadioVol:FireServer(vol * 10)
    end)
    notify("🔊 Volume: " .. math.floor(vol * 100) .. "%", 2)
end

local function getSkins()
    if not GetSkins then return {} end
    local ok, skins = pcall(function()
        return GetSkins:InvokeServer()
    end)
    return ok and skins or {}
end

local function equipSkin(skinName)
    if not EquipSkin then return end
    pcall(function()
        EquipSkin:FireServer(skinName)
    end)
    notify("🎨 Skin: " .. skinName, 2)
end

-- Teleportar para onde a Boombox fica no mapa
local function tpToBoombox()
    local root = getRoot()
    if root then
        -- Posição encontrada no arquivo do jogo: X=469.9, Y=5189.8, Z=6513.9
        -- Mas Y=5189 parece ser coordenada do modelo no espaço, vamos usar o local do DRadio GUI
        root.CFrame = CFrame.new(469.9, 5190, 6513.9)
        notify("📍 Teleportado para a Boombox!", 3)
    end
end

-- ═══════════════════════════════════════════════════
-- SPEED / JUMP
-- ═══════════════════════════════════════════════════
local function applyStats()
    local h = getHum()
    if h then h.WalkSpeed = Config.Speed; h.JumpPower = Config.Jump end
end

LP.CharacterAdded:Connect(function()
    task.wait(0.5)
    applyStats()
    if Config.GodMode then
        local h = getHum()
        if h then h.Health = h.MaxHealth end
    end
end)

-- ═══════════════════════════════════════════════════
-- NOCLIP
-- ═══════════════════════════════════════════════════
RS.Stepped:Connect(function()
    if Config.Noclip then
        local c = getChar()
        if c then
            for _, p in pairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════
-- FLY
-- ═══════════════════════════════════════════════════
local function startFly()
    Config.Fly = true
    local root = getRoot(); if not root then return end
    local hum = getHum(); if hum then hum.PlatformStand = true end

    local bg = Instance.new("BodyGyro")
    bg.MaxTorque = Vector3.new(1e9,1e9,1e9); bg.P = 1e9; bg.Parent = root
    local bv = Instance.new("BodyVelocity")
    bv.MaxForce = Vector3.new(1e9,1e9,1e9); bv.Velocity = Vector3.zero; bv.Parent = root
    FlyParts = {bg, bv}

    Connections.fly = RS.RenderStepped:Connect(function()
        if not Config.Fly then return end
        local cam = Camera; local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir = dir + cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir = dir - cam.CFrame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir = dir - cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir = dir + cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
        local spd = UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 100 or 40
        bv.Velocity = dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero
        if dir.Magnitude > 0 then bg.CFrame = CFrame.new(root.Position, root.Position + dir) end
    end)
end

local function stopFly()
    Config.Fly = false
    if Connections.fly then Connections.fly:Disconnect(); Connections.fly = nil end
    for _, p in pairs(FlyParts) do if p and p.Parent then p:Destroy() end end
    FlyParts = {}
    local hum = getHum(); if hum then hum.PlatformStand = false end
end

-- ═══════════════════════════════════════════════════
-- INFINITE JUMP
-- ═══════════════════════════════════════════════════
UIS.JumpRequest:Connect(function()
    if Config.InfJump then
        local h = getHum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ═══════════════════════════════════════════════════
-- ESP
-- ═══════════════════════════════════════════════════
local function clearESP()
    for _, h in pairs(ESPHighlights) do if h and h.Parent then h:Destroy() end end
    ESPHighlights = {}
end

local function updateESP()
    clearESP()
    if not Config.ESP then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LP and player.Character then
            local h = Instance.new("Highlight")
            h.Adornee = player.Character
            h.FillColor = Color3.fromRGB(0, 120, 255)
            h.OutlineColor = Color3.fromRGB(200, 230, 255)
            h.FillTransparency = 0.5
            h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            h.Parent = CoreGui
            table.insert(ESPHighlights, h)
        end
    end
end

task.spawn(function()
    while true do
        if Config.ESP then updateESP() end
        task.wait(2)
    end
end)

-- ═══════════════════════════════════════════════════
-- ANTI-AFK
-- ═══════════════════════════════════════════════════
task.spawn(function()
    while true do
        if Config.AntiAFK then
            pcall(function()
                local VU = game:GetService("VirtualUser")
                VU:CaptureController(); VU:ClickButton2(Vector2.new())
            end)
        end
        task.wait(15)
    end
end)

-- ═══════════════════════════════════════════════════
-- ██████████ GUI ██████████
-- ═══════════════════════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CMBRScript"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = CoreGui

-- Janela principal (relativa à tela, funciona em 360dpi)
local Main = Instance.new("Frame", ScreenGui)
Main.Size = UDim2.new(0.48, 0, 0.88, 0)
Main.Position = UDim2.new(0.01, 0, 0.06, 0)
Main.BackgroundColor3 = Color3.fromRGB(14, 14, 22)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0.015, 0)
local stroke = Instance.new("UIStroke", Main)
stroke.Color = Color3.fromRGB(80, 40, 200); stroke.Thickness = 3

-- Header
local Header = Instance.new("Frame", Main)
Header.Size = UDim2.new(1, 0, 0.065, 0)
Header.BackgroundColor3 = Color3.fromRGB(60, 30, 160)
Header.BorderSizePixel = 0
Instance.new("UICorner", Header).CornerRadius = UDim.new(0.5, 0)

local Title = Instance.new("TextLabel", Header)
Title.Size = UDim2.new(0.8, 0, 1, 0); Title.Position = UDim2.new(0.02, 0, 0, 0)
Title.BackgroundTransparency = 1; Title.Text = "🎵 Comunidade BZN Script"
Title.TextColor3 = Color3.new(1,1,1); Title.Font = Enum.Font.GothamBold
Title.TextScaled = true; Title.TextXAlignment = Enum.TextXAlignment.Left

local CloseBtn = Instance.new("TextButton", Header)
CloseBtn.Size = UDim2.new(0.1, 0, 0.8, 0); CloseBtn.Position = UDim2.new(0.88, 0, 0.1, 0)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220,50,50); CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1,1,1); CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextScaled = true; CloseBtn.BorderSizePixel = 0
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0.3, 0)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

-- Scroll
local Scroll = Instance.new("ScrollingFrame", Main)
Scroll.Size = UDim2.new(1, 0, 0.935, 0); Scroll.Position = UDim2.new(0, 0, 0.065, 0)
Scroll.BackgroundTransparency = 1; Scroll.ScrollBarThickness = 7
Scroll.CanvasSize = UDim2.new(0,0,0,0); Scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y

local List = Instance.new("UIListLayout", Scroll)
List.Padding = UDim.new(0.008, 0); List.SortOrder = Enum.SortOrder.LayoutOrder

local Pad = Instance.new("UIPadding", Scroll)
Pad.PaddingTop = UDim.new(0.008, 0); Pad.PaddingLeft = UDim.new(0.02, 0); Pad.PaddingRight = UDim.new(0.02, 0)

-- ════ HELPERS ════
local function section(name)
    local f = Instance.new("TextLabel", Scroll)
    f.Size = UDim2.new(1, 0, 0, 0); f.AutomaticSize = Enum.AutomaticSize.Y
    f.BackgroundColor3 = Color3.fromRGB(40,20,90)
    f.Text = " ─── " .. name .. " ───"; f.TextColor3 = Color3.fromRGB(180,140,255)
    f.Font = Enum.Font.GothamBold; f.TextSize = 22; f.BorderSizePixel = 0
    f.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", f).CornerRadius = UDim.new(0.3, 0)
    local p = Instance.new("UIPadding", f); p.PaddingLeft = UDim.new(0,10); p.PaddingTop = UDim.new(0,6); p.PaddingBottom = UDim.new(0,6)
    return f
end

local function btn(text, color, cb)
    local b = Instance.new("TextButton", Scroll)
    b.Size = UDim2.new(1, 0, 0, 62); b.BackgroundColor3 = color or Color3.fromRGB(45,45,75)
    b.Text = text; b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamBold
    b.TextSize = 22; b.BorderSizePixel = 0
    Instance.new("UICorner", b).CornerRadius = UDim.new(0.25, 0)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function toggle(text, state, cb)
    local b = Instance.new("TextButton", Scroll)
    local active = state or false
    b.Size = UDim2.new(1, 0, 0, 62)
    b.BackgroundColor3 = active and Color3.fromRGB(40,160,50) or Color3.fromRGB(45,45,75)
    b.Text = (active and "✅  " or "⬜  ") .. text
    b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamBold
    b.TextSize = 22; b.BorderSizePixel = 0; b.TextXAlignment = Enum.TextXAlignment.Left
    Instance.new("UICorner", b).CornerRadius = UDim.new(0.25, 0)
    local pad = Instance.new("UIPadding", b); pad.PaddingLeft = UDim.new(0,14)
    b.MouseButton1Click:Connect(function()
        active = not active; cb(active)
        b.BackgroundColor3 = active and Color3.fromRGB(40,160,50) or Color3.fromRGB(45,45,75)
        b.Text = (active and "✅  " or "⬜  ") .. text
    end)
    return b
end

local function inputBtn(placeholder, btnText, color, cb)
    local frame = Instance.new("Frame", Scroll)
    frame.Size = UDim2.new(1, 0, 0, 62); frame.BackgroundTransparency = 1
    local inp = Instance.new("TextBox", frame)
    inp.Size = UDim2.new(0.63, -3, 1, 0); inp.BackgroundColor3 = Color3.fromRGB(25,25,45)
    inp.PlaceholderText = placeholder; inp.Text = ""; inp.TextColor3 = Color3.new(1,1,1)
    inp.PlaceholderColor3 = Color3.fromRGB(120,120,150); inp.Font = Enum.Font.Gotham
    inp.TextSize = 20; inp.ClearTextOnFocus = false; inp.BorderSizePixel = 0
    Instance.new("UICorner", inp).CornerRadius = UDim.new(0.25, 0)
    local p2 = Instance.new("UIPadding", inp); p2.PaddingLeft = UDim.new(0,10)
    local b = Instance.new("TextButton", frame)
    b.Size = UDim2.new(0.36, 0, 1, 0); b.Position = UDim2.new(0.64, 3, 0, 0)
    b.BackgroundColor3 = color or Color3.fromRGB(70,30,180); b.Text = btnText
    b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamBold; b.TextSize = 20
    b.BorderSizePixel = 0; Instance.new("UICorner", b).CornerRadius = UDim.new(0.25, 0)
    b.MouseButton1Click:Connect(function() cb(inp.Text) end)
    return frame, inp
end

local function slider(text, min, max, default, cb)
    local frame = Instance.new("Frame", Scroll)
    frame.Size = UDim2.new(1, 0, 0, 80); frame.BackgroundColor3 = Color3.fromRGB(30,30,55)
    frame.BorderSizePixel = 0; Instance.new("UICorner", frame).CornerRadius = UDim.new(0.2, 0)
    
    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,0,0.45,0); lbl.BackgroundTransparency = 1
    lbl.Text = text .. ": " .. default; lbl.TextColor3 = Color3.new(1,1,1)
    lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 20; lbl.BorderSizePixel = 0
    
    local track = Instance.new("Frame", frame)
    track.Size = UDim2.new(0.9, 0, 0.2, 0); track.Position = UDim2.new(0.05, 0, 0.65, 0)
    track.BackgroundColor3 = Color3.fromRGB(60,60,100); track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    
    local fill = Instance.new("Frame", track)
    local pct = (default - min) / (max - min)
    fill.Size = UDim2.new(pct, 0, 1, 0); fill.BackgroundColor3 = Color3.fromRGB(100,50,220)
    fill.BorderSizePixel = 0; Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    
    local drag = false
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = true
        end
    end)
    game:GetService("UserInputService").InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            drag = false
        end
    end)
    game:GetService("UserInputService").InputChanged:Connect(function(inp)
        if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
            local rel = math.clamp((inp.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            local val = math.floor(min + rel * (max - min))
            lbl.Text = text .. ": " .. val
            cb(val)
        end
    end)
    
    return frame
end

-- ════════════════════════════════════════
-- SEÇÃO BOOMBOX
-- ════════════════════════════════════════
section("🎵 BOOMBOX")

inputBtn("ID da Música...", "▶ Tocar Global", Color3.fromRGB(30,150,60), function(txt)
    if txt ~= "" then playMusic(txt) end
end)

btn("⏹️ Parar Música", Color3.fromRGB(160,30,30), stopMusic)

btn("📍 TP → Onde Fica a Boombox", Color3.fromRGB(50,100,180), tpToBoombox)

btn("🎨 Listar Skins da Boombox (console)", Color3.fromRGB(100,50,180), function()
    local skins = getSkins()
    if skins and #skins > 0 then
        print("=== SKINS DISPONÍVEIS ===")
        for i, skin in pairs(skins) do
            print(i, skin)
        end
        notify("🎨 " .. #skins .. " skins no console (F9)", 3)
    else
        notify("⚠️ Sem skins ou sem permissão.", 3)
    end
end)

-- Volume slider
slider("🔊 Volume", 0, 100, 100, function(val)
    setVolume(val / 100)
end)

-- ════════════════════════════════════════
-- SEÇÃO PLAYER
-- ════════════════════════════════════════
section("🏃 PLAYER")

slider("⚡ Speed", 16, 300, 32, function(val)
    Config.Speed = val; applyStats()
end)

slider("🦘 Jump", 50, 300, 70, function(val)
    Config.Jump = val; applyStats()
end)

toggle("♾️ Infinite Jump", false, function(v)
    Config.InfJump = v
    notify(v and "♾️ Infinite Jump ON" or "♾️ Infinite Jump OFF", 2)
end)

toggle("👻 Noclip", false, function(v)
    Config.Noclip = v
    if not v then
        local c = getChar()
        if c then for _, p in pairs(c:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
    end
    notify(v and "👻 Noclip ON" or "👻 Noclip OFF", 2)
end)

toggle("🦅 Fly  [WASD + Space + Ctrl + Shift=Turbo]", false, function(v)
    if v then startFly() else stopFly() end
    notify(v and "🦅 Fly ON" or "🦅 Fly OFF", 2)
end)

toggle("🌟 God Mode (HP sempre cheio)", false, function(v)
    Config.GodMode = v
    if v then
        Connections.god = RS.Heartbeat:Connect(function()
            local h = getHum(); if h then h.Health = h.MaxHealth end
        end)
        notify("🌟 God Mode ON", 2)
    else
        if Connections.god then Connections.god:Disconnect(); Connections.god = nil end
        notify("🌟 God Mode OFF", 2)
    end
end)

btn("❤️ Curar HP Agora", Color3.fromRGB(180,30,60), function()
    local h = getHum(); if h then h.Health = h.MaxHealth end
    notify("❤️ HP cheio!", 2)
end)

-- ════════════════════════════════════════
-- SEÇÃO ESP
-- ════════════════════════════════════════
section("👁️ ESP & MISC")

toggle("🔵 ESP Players (Azul)", false, function(v)
    Config.ESP = v
    if v then updateESP() else clearESP() end
    notify(v and "👁️ ESP ON" or "👁️ ESP OFF", 2)
end)

toggle("🎭 Anti-AFK", true, function(v)
    Config.AntiAFK = v
    notify(v and "✅ Anti-AFK ON" or "❌ Anti-AFK OFF", 2)
end)

toggle("🕶️ Invisível (Local)", false, function(v)
    local c = getChar()
    if c then
        for _, p in pairs(c:GetDescendants()) do
            if p:IsA("BasePart") or p:IsA("Decal") then
                p.LocalTransparencyModifier = v and 1 or 0
            end
        end
    end
    notify(v and "🕶️ Invisível ON" or "🕶️ Visível ON", 2)
end)

btn("📊 Meu UserId / Stats", Color3.fromRGB(30,80,160), function()
    local info = string.format("👤 %s | ID: %d | Speed: %d | Jump: %d",
        LP.DisplayName, LP.UserId, Config.Speed, Config.Jump)
    notify(info, 5)
    print(info)
end)

btn("📋 Listar Jogadores Online", Color3.fromRGB(30,80,100), function()
    local list = ""
    for _, p in pairs(Players:GetPlayers()) do
        list = list .. p.Name .. " | "
    end
    notify("👥 " .. list, 5)
    print("PLAYERS: " .. list)
end)

-- ════════════════════════════════════════
-- SEÇÃO TELEPORT
-- ════════════════════════════════════════
section("📍 TELEPORT")

inputBtn("Nome do player...", "📍 TP", Color3.fromRGB(80,40,160), function(name)
    for _, p in pairs(Players:GetPlayers()) do
        if p.Name:lower():find(name:lower()) and p ~= LP then
            local root = getRoot()
            local tc = p.Character
            if root and tc then
                local tr = tc:FindFirstChild("HumanoidRootPart")
                if tr then
                    root.CFrame = tr.CFrame * CFrame.new(3,0,0)
                    notify("📍 TP → " .. p.Name, 2)
                    return
                end
            end
        end
    end
    notify("⚠️ Player não encontrado: " .. name, 3)
end)

btn("🌀 TP → Origem (0,0,0)", Color3.fromRGB(50,50,100), function()
    local root = getRoot()
    if root then root.CFrame = CFrame.new(0,10,0); notify("🌀 Teleportado para origem", 2) end
end)

-- Crédito
local cred = Instance.new("TextLabel", Scroll)
cred.Size = UDim2.new(1,0,0,38); cred.BackgroundTransparency = 1
cred.Text = "Comunidade BZN Script • Analisado do jogo real"
cred.TextColor3 = Color3.fromRGB(80,80,130); cred.Font = Enum.Font.Gotham; cred.TextSize = 17

-- ═══════════════════════════════════════════════════
-- INIT
-- ═══════════════════════════════════════════════════
task.spawn(function()
    task.wait(1.5)
    applyStats()
    notify("🎵 Comunidade BZN Script carregado!", 4)
    print("===========================================")
    print("  COMUNIDADE BZN SCRIPT")
    print("  Remote Boombox: PlayMusic (RemoteFunction)")
    print("  Posição da Boombox: 469.9 / 5189.8 / 6513.9")
    print("  Erros encontrados: 7 (ver comentário no script)")
    print("===========================================")
end)
