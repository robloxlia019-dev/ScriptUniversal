-- ═══════════════════════════════════════════════════════════════
--  TRAITORS HUB  v2  —  by Claude
--  Game ID: 107949440670420
--  • Botões arrastáveis + travamento por posição
--  • Aparecem apenas quando ativados no menu Rayfield
--  • Aimbot com mira no Murderer / alvo mais próximo
--  • ESP correto usando GetPlayerData (Role real do servidor)
--  • Gold Bomb Prank (GoldFakeBomb emote)
--  • Teleports, Speed, Fly, NoClip, God Mode
-- ═══════════════════════════════════════════════════════════════

-- ─────────────────────────── SERVIÇOS ────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UIS              = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local RS               = game:GetService("ReplicatedStorage")
local Workspace        = game:GetService("Workspace")

local LP        = Players.LocalPlayer
local Camera    = Workspace.CurrentCamera
local PGui      = LP:WaitForChild("PlayerGui")

local Char, Hum, HRP
local function RefreshChar(c)
    Char = c
    Hum  = c:WaitForChild("Humanoid")
    HRP  = c:WaitForChild("HumanoidRootPart")
end
RefreshChar(LP.Character or LP.CharacterAdded:Wait())
LP.CharacterAdded:Connect(RefreshChar)

-- ─────────────────────────── REMOTES ─────────────────────────
local Game_RS    -- cache após round start
local function GetRemote(...)
    local cur = RS:FindFirstChild("Game")
    if not cur then return nil end
    cur = cur:FindFirstChild("Remotes")
    if not cur then return nil end
    for _, name in ipairs({...}) do
        cur = cur:FindFirstChild(name)
        if not cur then return nil end
    end
    return cur
end

-- ─────────────────────────── RAYFIELD ────────────────────────
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok then warn("[Traitors] Rayfield falhou: "..tostring(Rayfield)) return end

local function Notif(title, text, dur)
    Rayfield:Notify({ Title=title, Content=text, Duration=dur or 3, Image=14428634947 })
end

-- ═══════════════════════════════════════════════════════════════
--  SISTEMA DE BOTÕES ARRASTÁVEIS
--  • Criados dentro de um ScreenGui separado (DragLayer)
--  • Por padrão invisíveis; ativados aba a aba no Rayfield
--  • Cada botão tem trava de posição (ícone 🔒/🔓 no canto)
-- ═══════════════════════════════════════════════════════════════
local DragLayer = Instance.new("ScreenGui")
DragLayer.Name           = "TraitorsDragLayer"
DragLayer.IgnoreGuiInset = true
DragLayer.ResetOnSpawn   = false
DragLayer.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
DragLayer.Enabled        = false   -- começa oculto
DragLayer.Parent         = PGui

-- Tabela com posições salvas  { [id] = UDim2 }
local Locked   = {}  -- { [Frame] = bool }
local AllBtns  = {}  -- lista de todos os frames criados

-- ── MakeDragButton ────────────────────────────────────────────
--[[
    opts = {
        id        string   — id único para salvar posição
        label     string   — texto do botão
        size      UDim2    — tamanho padrão
        pos       UDim2    — posição inicial na tela
        color     Color3   — cor de fundo
        round     bool     — forma circular
        onClick   function — chamado ao clicar (sem arrastar)
        group     string   — "combat" | "teleport" | "misc"
    }
    Retorna: frame, labelObj
]]
local GroupFrames = {}  -- { [group] = { Frame, ... } }

local function MakeDragButton(opts)
    local id      = opts.id or tostring(math.random(1e9))
    local isRound = opts.round == true

    local Frame = Instance.new("Frame")
    Frame.Name                = "DBtn_"..id
    Frame.Size                = opts.size or UDim2.new(0,120,0,50)
    Frame.Position            = opts.pos  or UDim2.new(0.5,0,0.5,0)
    Frame.BackgroundColor3    = opts.color or Color3.fromRGB(25,25,40)
    Frame.BorderSizePixel     = 0
    Frame.Active              = true
    Frame.ZIndex              = 10
    Frame.Visible             = false   -- começa oculto
    Frame.Parent              = DragLayer

    local corner = Instance.new("UICorner", Frame)
    corner.CornerRadius = isRound and UDim.new(1,0) or UDim.new(0,10)

    -- Brilho sutil no topo
    local shine = Instance.new("Frame", Frame)
    shine.Size = UDim2.new(1,0,0.45,0)
    shine.BackgroundColor3 = Color3.new(1,1,1)
    shine.BackgroundTransparency = 0.90
    shine.BorderSizePixel = 0
    shine.ZIndex = 11
    Instance.new("UICorner", shine).CornerRadius = corner.CornerRadius

    -- Borda colorida
    local stroke = Instance.new("UIStroke", Frame)
    stroke.Color     = (opts.color or Color3.fromRGB(25,25,40)):Lerp(Color3.new(1,1,1), 0.25)
    stroke.Thickness = 1.5

    -- Label principal
    local Lbl = Instance.new("TextLabel", Frame)
    Lbl.Size = UDim2.new(1,-20,1,0)
    Lbl.Position = UDim2.new(0,0,0,0)
    Lbl.BackgroundTransparency = 1
    Lbl.Text      = opts.label or "Botão"
    Lbl.TextColor3 = Color3.new(1,1,1)
    Lbl.Font      = Enum.Font.GothamBold
    Lbl.TextSize  = isRound and 10 or 12
    Lbl.TextWrapped = true
    Lbl.ZIndex    = 12

    -- Botão de trava (só em não-redondos)
    local LockBtn
    if not isRound then
        LockBtn = Instance.new("TextButton", Frame)
        LockBtn.Size = UDim2.new(0,18,0,18)
        LockBtn.Position = UDim2.new(1,-20,0,2)
        LockBtn.BackgroundColor3 = Color3.fromRGB(50,50,70)
        LockBtn.TextColor3 = Color3.new(1,1,1)
        LockBtn.Font = Enum.Font.GothamBold
        LockBtn.TextSize = 9
        LockBtn.Text = "🔓"
        LockBtn.BorderSizePixel = 0
        LockBtn.ZIndex = 16
        Instance.new("UICorner", LockBtn).CornerRadius = UDim.new(0,4)
        Locked[Frame] = false

        LockBtn.MouseButton1Click:Connect(function()
            Locked[Frame] = not Locked[Frame]
            LockBtn.Text = Locked[Frame] and "🔒" or "🔓"
            LockBtn.BackgroundColor3 = Locked[Frame]
                and Color3.fromRGB(200,50,50)
                or  Color3.fromRGB(50,50,70)
        end)
    end

    -- ── Arraste ─────────────────────────────────────────────
    local dragging   = false
    local dragStart  = Vector2.new()
    local startPos   = Frame.Position
    local clickStart = 0

    Frame.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if Locked[Frame] then return end
        dragging   = true
        dragStart  = Vector2.new(inp.Position.X, inp.Position.Y)
        startPos   = Frame.Position
        clickStart = tick()
    end)

    UIS.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local delta = Vector2.new(inp.Position.X, inp.Position.Y) - dragStart
        Frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end)

    UIS.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if not dragging then return end
        local elapsed = tick() - clickStart
        local moved   = (Vector2.new(inp.Position.X, inp.Position.Y) - dragStart).Magnitude
        dragging = false

        -- Se não moveu quase nada e foi rápido → é um clique
        if elapsed < 0.25 and moved < 6 then
            -- Feedback visual
            local orig = Frame.BackgroundColor3
            TweenService:Create(Frame, TweenInfo.new(0.07), {
                BackgroundColor3 = orig:Lerp(Color3.new(1,1,1), 0.2)
            }):Play()
            task.delay(0.1, function()
                TweenService:Create(Frame, TweenInfo.new(0.1), {
                    BackgroundColor3 = orig
                }):Play()
            end)
            if opts.onClick then
                task.spawn(function() pcall(opts.onClick) end)
            end
        end
    end)

    -- Guardar na lista de grupo
    if opts.group then
        GroupFrames[opts.group] = GroupFrames[opts.group] or {}
        table.insert(GroupFrames[opts.group], Frame)
    end
    table.insert(AllBtns, Frame)

    return Frame, Lbl
end

-- Função: mostrar/esconder grupo de botões
local function SetGroupVisible(group, visible)
    if GroupFrames[group] then
        for _, f in ipairs(GroupFrames[group]) do
            f.Visible = visible
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
--  DETECÇÃO DE ROLE (via GetPlayerData remoto)
-- ═══════════════════════════════════════════════════════════════
local RoleCache = {}  -- { [PlayerName] = "Murderer"|"Sheriff"|"Innocent"|"Hero" }

local function RefreshRoles()
    local remote = GetRemote("Data","GetPlayerData")
    if not remote then return end
    local ok2, data = pcall(function() return remote:InvokeServer() end)
    if ok2 and data then
        for name, info in pairs(data) do
            if info and info.Role then
                RoleCache[name] = info.Role
            end
        end
    end
end

-- Fallback por inventário (quando GetPlayerData não responde)
local function GuessRoleByInventory(plr)
    local char    = plr.Character
    local backpack = plr:FindFirstChild("Backpack")
    local function checkTools(container)
        if not container then return nil end
        for _, t in pairs(container:GetChildren()) do
            if t:IsA("Tool") then
                local n = t.Name:lower()
                if t:FindFirstChild("IsGun") then return "Sheriff" end
                if n:find("gun") or n:find("sniper") or n:find("sheriff") then return "Sheriff" end
                if n:find("knife") or n:find("blade") then return "Murderer" end
            end
        end
        return nil
    end
    return checkTools(char) or checkTools(backpack)
end

local function GetRole(plr)
    return RoleCache[plr.Name] or GuessRoleByInventory(plr) or "Innocent"
end

local function FindByRole(role)
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and GetRole(plr) == role then return plr end
    end
    return nil
end

-- Atualizar roles periodicamente
task.spawn(function()
    while true do
        pcall(RefreshRoles)
        task.wait(3)
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  AIMBOT
-- ═══════════════════════════════════════════════════════════════
local AimCFG = {
    On       = false,
    FOV      = 220,
    Smooth   = 0.30,
    ShowCircle = true,
    MurderOnly = true,   -- se false, mira no mais próximo do FOV
}
local AimHolding = false

-- Círculo de FOV na tela
local FOVCircle = Instance.new("Frame", DragLayer)
FOVCircle.Name = "FOVCircle"
FOVCircle.AnchorPoint = Vector2.new(0.5,0.5)
FOVCircle.BackgroundTransparency = 1
FOVCircle.BorderSizePixel = 0
FOVCircle.ZIndex = 5
local fovStroke = Instance.new("UIStroke", FOVCircle)
fovStroke.Color = Color3.fromRGB(255,80,80)
fovStroke.Thickness = 1.5
Instance.new("UICorner", FOVCircle).CornerRadius = UDim.new(1,0)

UIS.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then AimHolding=true end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton2 then AimHolding=false end end)

local function GetAimTarget()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    local best, bestDist = nil, AimCFG.FOV

    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local role = GetRole(plr)
        if AimCFG.MurderOnly and role ~= "Murderer" then continue end
        local ch = plr.Character
        if not ch then continue end
        local head = ch:FindFirstChild("Head")
        local hum2 = ch:FindFirstChild("Humanoid")
        if not head or not hum2 or hum2.Health <= 0 then continue end
        local _, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
        if not onScreen or depth <= 0 then continue end
        local sp   = Camera:WorldToViewportPoint(head.Position)
        local dist = (Vector2.new(sp.X,sp.Y) - center).Magnitude
        if dist < bestDist then bestDist=dist; best=plr end
    end
    return best
end

RunService.RenderStepped:Connect(function()
    -- FOV circle
    local r = AimCFG.FOV
    FOVCircle.Position = UDim2.new(0.5,0,0.5,0)
    FOVCircle.Size     = UDim2.new(0,r*2,0,r*2)
    FOVCircle.Visible  = AimCFG.On and AimCFG.ShowCircle and DragLayer.Enabled

    if not AimCFG.On then return end
    if not AimHolding then return end
    local target = GetAimTarget()
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end
    local _, on = Camera:WorldToViewportPoint(head.Position)
    if not on then return end
    Camera.CFrame = Camera.CFrame:Lerp(
        CFrame.new(Camera.CFrame.Position, head.Position),
        AimCFG.Smooth
    )
end)

-- ═══════════════════════════════════════════════════════════════
--  SHOOT MURDER — dispara via simulação de clique na gun
-- ═══════════════════════════════════════════════════════════════
local function GetEquipped()
    if not Char then return nil end
    for _, t in pairs(Char:GetChildren()) do
        if t:IsA("Tool") then return t end
    end
    return nil
end

local function ToolIsGun(tool)
    if not tool then return false end
    if tool:FindFirstChild("IsGun") then return true end
    local n = tool.Name:lower()
    return n:find("gun") or n:find("sniper") or n:find("sheriff") or n:find("pistol")
        or n:find("persuader") or n:find("zero") or n:find("freezer") or n:find("tempest")
        or n:find("marshal") or n:find("atlantic") or n:find("jolly") or n:find("crossbow")
end

local function DoShoot()
    -- 1) Verificar arma
    local tool = GetEquipped()
    if not tool       then return false,"❌ Nenhuma arma equipada" end
    if not ToolIsGun(tool) then return false,"❌ "..tool.Name.." não é uma gun" end

    -- 2) Encontrar murderer
    local murder = FindByRole("Murderer")
    if not murder or not murder.Character then
        -- fallback: qualquer player vivo mais perto
        for _, p in pairs(Players:GetPlayers()) do
            if p~=LP and p.Character and p.Character:FindFirstChild("Head") then
                murder = p; break
            end
        end
    end
    if not murder then return false,"❌ Murderer não encontrado" end

    local head = murder.Character:FindFirstChild("Head")
    if not head then return false,"❌ Head não achada" end

    -- 3) Apontar câmera EXATO para a head
    Camera.CFrame = CFrame.new(Camera.CFrame.Position, head.Position)
    task.wait(0.05)

    -- 4) Tentar remotos do jogo (Round)
    local fired = false
    local remRound = GetRemote("Round")
    if remRound then
        local rGunKill = remRound:FindFirstChild("GunKill")
        local rGunBeam = remRound:FindFirstChild("GunBeam")
        if rGunKill then pcall(function() rGunKill:FireServer(murder.Character, head.Position) end); fired=true end
        if rGunBeam then
            local muzzlePos = HRP and (HRP.Position + Vector3.new(0,1.5,0)) or head.Position
            -- procurar muzzle attachment na tool
            for _, a in pairs(tool:GetDescendants()) do
                if a:IsA("Attachment") and (a.Name:lower():find("muzzle") or a.Name:lower():find("gunpoint")) then
                    muzzlePos = a.WorldPosition; break
                end
            end
            pcall(function() rGunBeam:FireServer(murder, head.Position, muzzlePos) end)
            fired = true
        end
    end

    -- 5) Fallback — simular MouseClick via ContextAction ou evento interno da tool
    if not fired then
        local fireRE = tool:FindFirstChildWhichIsA("RemoteEvent")
        if fireRE then
            pcall(function() fireRE:FireServer(head.Position) end)
            fired = true
        end
        local shootBS = tool:FindFirstChild("Shoot") or tool:FindFirstChildWhichIsA("BindableEvent")
        if shootBS then
            pcall(function() shootBS:Fire(head.Position) end)
            fired = true
        end
    end

    return fired, fired
        and ("🎯 Atirou em "..murder.Name.."!")
        or  "⚠️ Sem remote para atirar — use o mouse manualmente"
end

-- ═══════════════════════════════════════════════════════════════
--  ESP — usa GetPlayerData para roles reais
-- ═══════════════════════════════════════════════════════════════
local ESPOn     = false
local ESPFolder = Instance.new("Folder", Workspace)
ESPFolder.Name  = "TraitorsESP"

local RoleColor = {
    Murderer = Color3.fromRGB(255,50,50),
    Sheriff  = Color3.fromRGB(60,140,255),
    Hero     = Color3.fromRGB(255,220,0),
    Innocent = Color3.fromRGB(60,255,120),
}

local ESPObjects = {}  -- { [plr] = { bb, sel } }

local function RemoveESP(plr)
    if ESPObjects[plr] then
        for _, v in pairs(ESPObjects[plr]) do pcall(function() v:Destroy() end) end
        ESPObjects[plr] = nil
    end
end

local function BuildESP(plr)
    if plr == LP then return end
    RemoveESP(plr)
    local ch  = plr.Character
    if not ch then return end
    local hrp = ch:FindFirstChild("HumanoidRootPart")
    local head= ch:FindFirstChild("Head")
    if not hrp or not head then return end

    local role  = GetRole(plr)
    local color = RoleColor[role] or Color3.fromRGB(200,200,200)

    -- BillboardGui com fundo semi-transparente
    local bb = Instance.new("BillboardGui", ESPFolder)
    bb.Name        = "ESP_"..plr.Name
    bb.AlwaysOnTop = true
    bb.Size        = UDim2.new(0,130,0,52)
    bb.StudsOffset = Vector3.new(0,3.5,0)
    bb.Adornee     = head

    local bg = Instance.new("Frame", bb)
    bg.Size = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.fromRGB(10,10,18)
    bg.BackgroundTransparency = 0.25
    bg.BorderSizePixel = 0
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0,6)

    local bStroke = Instance.new("UIStroke", bg)
    bStroke.Color = color; bStroke.Thickness = 1.2

    local nameL = Instance.new("TextLabel", bg)
    nameL.Size = UDim2.new(1,0,0.52,0)
    nameL.BackgroundTransparency = 1
    nameL.Text = plr.Name
    nameL.TextColor3 = color
    nameL.Font = Enum.Font.GothamBold
    nameL.TextSize = 13
    nameL.TextStrokeTransparency = 0.4

    local roleL = Instance.new("TextLabel", bg)
    roleL.Size = UDim2.new(1,0,0.48,0)
    roleL.Position = UDim2.new(0,0,0.52,0)
    roleL.BackgroundTransparency = 1
    roleL.Text = "[ "..role.." ]"
    roleL.TextColor3 = color
    roleL.Font = Enum.Font.Gotham
    roleL.TextSize = 11
    roleL.TextStrokeTransparency = 0.5

    -- SelectionBox no corpo inteiro
    local sel = Instance.new("SelectionBox", ESPFolder)
    sel.Name = "SEL_"..plr.Name
    sel.Adornee = ch
    sel.Color3  = color
    sel.LineThickness = 0.055
    sel.SurfaceTransparency = 0.80
    sel.SurfaceColor3 = color

    ESPObjects[plr] = { bb, sel }
end

-- Rebuild ESP a cada segundo
task.spawn(function()
    while true do
        task.wait(1)
        if not ESPOn then
            for plr in pairs(ESPObjects) do RemoveESP(plr) end
        else
            pcall(RefreshRoles)
            for _, plr in pairs(Players:GetPlayers()) do
                pcall(function() BuildESP(plr) end)
            end
            -- limpar ESP de players que saíram
            for plr in pairs(ESPObjects) do
                if not plr.Parent then RemoveESP(plr) end
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
--  GOLD FAKE BOMB  (emote GoldFakeBomb)
--  Remote correto: game.ReplicatedStorage.Game.Remotes.Misc.PlayEmote:Fire("GoldFakeBomb")
-- ═══════════════════════════════════════════════════════════════
local function DoGoldBomb()
    -- Caminho 1: BindableEvent PlayEmote no Misc
    local PlayEmote = GetRemote("Misc","PlayEmote")
    if PlayEmote and PlayEmote:IsA("BindableEvent") then
        pcall(function() PlayEmote:Fire("GoldFakeBomb") end)
        return true, "💛 Gold Bomb disparada! (BindableEvent)"
    end

    -- Caminho 2: EmoteController global
    if _G.EmoteController then
        local ok2 = pcall(function()
            _G.EmoteController.Emotes = { nil, "Back", "GoldFakeBomb" }
        end)
        local emoteRE = GetRemote("Misc","PlayEmote")
        if emoteRE then
            pcall(function() emoteRE:Fire("GoldFakeBomb") end)
            return true, "💛 Gold Bomb via EmoteController"
        end
    end

    -- Caminho 3: via ReplicateToy (toys são items visuais como a bomba)
    local repToy = GetRemote("Misc","ReplicateToy")
    if repToy then
        local ok3 = pcall(function() repToy:InvokeServer("GoldFakeBomb") end)
        if ok3 then return true, "💛 Gold Bomb via ReplicateToy" end
    end

    -- Caminho 4: achar BindableEvent direto no character/backpack
    for _, d in pairs(LP:GetDescendants()) do
        if d:IsA("BindableEvent") and (d.Name == "PlayEmote" or d.Name == "Emote") then
            pcall(function() d:Fire("GoldFakeBomb") end)
            return true, "💛 Gold Bomb via BackpackEvent"
        end
    end

    return false, "⚠️ Bomba não disponível agora (precisa ter o item ou estar em round)"
end

-- ═══════════════════════════════════════════════════════════════
--  TELEPORTE
-- ═══════════════════════════════════════════════════════════════
local function TP(pos)
    if HRP then HRP.CFrame = CFrame.new(pos + Vector3.new(0,3,0)) end
end
local function TPToPlayer(plr)
    if plr and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        TP(plr.Character.HumanoidRootPart.Position)
        return true
    end
    return false
end

-- ═══════════════════════════════════════════════════════════════
--  FLY
-- ═══════════════════════════════════════════════════════════════
local FlyOn, FlySpeed = false, 60
local flyBV, flyBG, flyConn

local function StartFly()
    if not HRP then return end
    flyBV = Instance.new("BodyVelocity", HRP)
    flyBV.MaxForce = Vector3.new(1e9,1e9,1e9)
    flyBV.Velocity = Vector3.zero
    flyBG = Instance.new("BodyGyro", HRP)
    flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9)
    flyBG.D = 100
    flyConn = RunService.RenderStepped:Connect(function()
        if not FlyOn then return end
        local cam = Workspace.CurrentCamera
        local dir = Vector3.zero
        if UIS:IsKeyDown(Enum.KeyCode.W)          then dir += cam.CFrame.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.S)          then dir -= cam.CFrame.LookVector  end
        if UIS:IsKeyDown(Enum.KeyCode.A)          then dir -= cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D)          then dir += cam.CFrame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space)      then dir += Vector3.new(0,1,0)     end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift)  then dir -= Vector3.new(0,1,0)     end
        flyBV.Velocity = dir * FlySpeed
        flyBG.CFrame   = cam.CFrame
        if Hum then Hum.PlatformStand = true end
    end)
end
local function StopFly()
    FlyOn = false
    if flyBV  then flyBV:Destroy()  end
    if flyBG  then flyBG:Destroy()  end
    if flyConn then flyConn:Disconnect() end
    if Hum    then Hum.PlatformStand = false end
end

-- NoClip
local NoClipOn = false
RunService.Stepped:Connect(function()
    if NoClipOn and Char then
        for _, p in pairs(Char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- God Mode + Speed loop
local GodOn, SpeedVal = false, 16
RunService.Heartbeat:Connect(function()
    if Hum then
        if GodOn   then Hum.Health    = Hum.MaxHealth end
        if SpeedVal ~= 16 then Hum.WalkSpeed = SpeedVal end
    end
end)

-- Infinite Jump
local InfJumpOn = false
UIS.JumpRequest:Connect(function()
    if InfJumpOn and Hum then Hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end)

-- ═══════════════════════════════════════════════════════════════
--  CRIAÇÃO DOS BOTÕES ARRASTÁVEIS
-- ═══════════════════════════════════════════════════════════════

-- ── GRUPO: COMBATE ──────────────────────────────────────────
local shootFrame, shootLbl = MakeDragButton({
    id="shoot_murder", label="🎯 ATIRAR\nMURDER",
    size=UDim2.new(0,118,0,58), pos=UDim2.new(0,20,0.45,-60),
    color=Color3.fromRGB(170,25,25), group="combat",
    onClick=function()
        local ok2,msg = DoShoot()
        Notif(ok2 and "✅ Tiro" or "❌ Erro", msg, 3)
    end
})

local aimFrame, aimLbl = MakeDragButton({
    id="aimbot_toggle", label="🔴 AIMBOT\nOFF",
    size=UDim2.new(0,118,0,58), pos=UDim2.new(0,20,0.45,10),
    color=Color3.fromRGB(35,35,55), group="combat",
    onClick=function()
        AimCFG.On = not AimCFG.On
        aimLbl.Text = AimCFG.On and "🟢 AIMBOT\nON" or "🔴 AIMBOT\nOFF"
        aimFrame.BackgroundColor3 = AimCFG.On
            and Color3.fromRGB(20,150,50)
            or  Color3.fromRGB(35,35,55)
    end
})

local espFrame, espLbl = MakeDragButton({
    id="esp_toggle", label="👁️ ESP\nOFF",
    size=UDim2.new(0,118,0,58), pos=UDim2.new(0,148,0.45,-60),
    color=Color3.fromRGB(30,80,130), group="combat",
    onClick=function()
        ESPOn = not ESPOn
        espLbl.Text = ESPOn and "👁️ ESP\nON" or "👁️ ESP\nOFF"
        espFrame.BackgroundColor3 = ESPOn
            and Color3.fromRGB(20,120,180)
            or  Color3.fromRGB(30,80,130)
        if not ESPOn then for plr in pairs(ESPObjects) do RemoveESP(plr) end end
        Notif("ESP", ESPOn and "ESP Ativado!" or "ESP Desativado", 2)
    end
})

local goldFrame = MakeDragButton({
    id="gold_bomb", label="💛 GOLD\nBOMB",
    size=UDim2.new(0,118,0,58), pos=UDim2.new(0,148,0.45,10),
    color=Color3.fromRGB(160,120,10), group="combat",
    onClick=function()
        local ok2,msg = DoGoldBomb()
        Notif(ok2 and "💛 Bomba!" or "❌ Erro", msg, 3)
    end
})

-- ── GRUPO: TELEPORTE (botões redondos) ──────────────────────
local tpDefs = {
    { id="tp_lobby",   label="🏠\nLobby",    pos=UDim2.new(0,20,0.7,-30),  color=Color3.fromRGB(35,70,160) },
    { id="tp_map",     label="🗺️\nMapa",     pos=UDim2.new(0,95,0.7,-30),  color=Color3.fromRGB(30,120,70) },
    { id="tp_murder",  label="💀\nMurder",   pos=UDim2.new(0,170,0.7,-30), color=Color3.fromRGB(160,25,25) },
    { id="tp_sheriff", label="🔫\nSheriff",  pos=UDim2.new(0,245,0.7,-30), color=Color3.fromRGB(40,90,200) },
}

local tpCallbacks = {
    tp_lobby   = function() TP(Vector3.new(-61.3,1048.5,241.9))  Notif("Tp","Lobby",2) end,
    tp_map     = function() TP(Vector3.new(-47.2,1055.0,323.1))  Notif("Tp","Mapa",2) end,
    tp_murder  = function()
        local m = FindByRole("Murderer")
        if TPToPlayer(m) then Notif("Tp 💀","Para "..m.Name,2)
        else Notif("❌","Murderer não encontrado",2) end
    end,
    tp_sheriff = function()
        local s = FindByRole("Sheriff")
        if TPToPlayer(s) then Notif("Tp 🔫","Para "..s.Name,2)
        else Notif("❌","Sheriff não encontrado",2) end
    end,
}

for _, d in ipairs(tpDefs) do
    MakeDragButton({
        id=d.id, label=d.label, round=true,
        size=UDim2.new(0,65,0,65), pos=d.pos,
        color=d.color, group="teleport",
        onClick=tpCallbacks[d.id]
    })
end

-- ═══════════════════════════════════════════════════════════════
--  RAYFIELD — JANELA PRINCIPAL
-- ═══════════════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name = "🔪 Traitors Hub v2",
    LoadingTitle = "Traitors Hub",
    LoadingSubtitle = "by Claude",
    ConfigurationSaving = { Enabled=true, FileName="TraitorsHubV2" },
    KeySystem = false,
})

-- ── TAB: PAINEL (ativar botões na tela) ───────────────────
local PainelTab = Window:CreateTab("🎮 Painel", 14428634947)
PainelTab:CreateSection("Botões Flutuantes na Tela")

PainelTab:CreateToggle({
    Name="Mostrar Painel na Tela", CurrentValue=false, Flag="ShowDrag",
    Callback=function(v)
        DragLayer.Enabled = v
        -- quando ativa, garante que grupos marcados apareçam
        Notif("Painel", v and "Painel visível! Arraste os botões como quiser." or "Painel oculto.", 2)
    end
})

PainelTab:CreateToggle({
    Name="Botões de Combate (🎯 Atirar / 🟢 Aimbot / 👁️ ESP / 💛 Bomb)", CurrentValue=false, Flag="ShowCombat",
    Callback=function(v) SetGroupVisible("combat", v) end
})

PainelTab:CreateToggle({
    Name="Botões de Teleporte (🏠🗺️💀🔫)", CurrentValue=false, Flag="ShowTP",
    Callback=function(v) SetGroupVisible("teleport", v) end
})

PainelTab:CreateLabel("💡 Arraste qualquer botão. Clique 🔓 para travar na posição.")

-- ── TAB: AIMBOT ───────────────────────────────────────────
local AimTab = Window:CreateTab("🎯 Aimbot", 14428634947)
AimTab:CreateSection("Configurações")

AimTab:CreateToggle({
    Name="Aimbot Ativo", CurrentValue=false, Flag="AimOn",
    Callback=function(v)
        AimCFG.On = v
        aimLbl.Text = v and "🟢 AIMBOT\nON" or "🔴 AIMBOT\nOFF"
        aimFrame.BackgroundColor3 = v and Color3.fromRGB(20,150,50) or Color3.fromRGB(35,35,55)
    end
})
AimTab:CreateToggle({
    Name="Só mirar no Murderer (desliga → qualquer inimigo)", CurrentValue=true, Flag="MurderOnly",
    Callback=function(v) AimCFG.MurderOnly = v end
})
AimTab:CreateToggle({
    Name="Segure Clique Direito para mirar", CurrentValue=true, Flag="AimHold",
    Callback=function(v)
        -- se desligar, aimbot é sempre ativo
        if not v then
            RunService.RenderStepped:Connect(function() AimHolding = AimCFG.On end)
        end
    end
})
AimTab:CreateToggle({
    Name="Mostrar Círculo FOV", CurrentValue=true, Flag="ShowFOV",
    Callback=function(v) AimCFG.ShowCircle = v end
})
AimTab:CreateSlider({
    Name="Raio FOV", Range={50,600}, Increment=10, CurrentValue=220, Flag="FOVSize",
    Callback=function(v) AimCFG.FOV = v end
})
AimTab:CreateSlider({
    Name="Suavidade (1=instantâneo)", Range={1,100}, Increment=1, CurrentValue=30, Flag="AimSmooth",
    Callback=function(v) AimCFG.Smooth = v/100 end
})
AimTab:CreateSection("Ação")
AimTab:CreateButton({
    Name="🎯 Atirar no Murderer AGORA",
    Callback=function()
        local ok2,msg = DoShoot()
        Notif(ok2 and "✅ Tiro!" or "❌ Erro", msg, 3)
    end
})
AimTab:CreateButton({
    Name="🔍 Verificar Arma Equipada",
    Callback=function()
        local t = GetEquipped()
        if t then
            local isG = ToolIsGun(t)
            Notif("Arma", t.Name..(isG and " ✅ Gun" or " ⚠️ não é gun"), 3)
        else
            Notif("Arma", "❌ Nenhuma tool equipada", 3)
        end
    end
})

-- ── TAB: ESP ─────────────────────────────────────────────
local ESPTab = Window:CreateTab("👁️ ESP", 14428634947)
ESPTab:CreateSection("Visualização")
ESPTab:CreateToggle({
    Name="ESP de Jogadores", CurrentValue=false, Flag="ESPOn",
    Callback=function(v)
        ESPOn = v
        espLbl.Text = v and "👁️ ESP\nON" or "👁️ ESP\nOFF"
        espFrame.BackgroundColor3 = v and Color3.fromRGB(20,120,180) or Color3.fromRGB(30,80,130)
        if not v then for plr in pairs(ESPObjects) do RemoveESP(plr) end end
    end
})
ESPTab:CreateButton({
    Name="🔄 Atualizar Roles Agora",
    Callback=function()
        pcall(RefreshRoles)
        local list = ""
        for name, role in pairs(RoleCache) do
            local ic = role=="Murderer" and "💀" or role=="Sheriff" and "🔫" or role=="Hero" and "⭐" or "😇"
            list = list..ic.." "..name.." — "..role.."\n"
        end
        Notif("Roles", list~="" and list or "Nenhum dado ainda (tente em round)", 6)
    end
})
ESPTab:CreateButton({
    Name="🕵️ Identificar Murderer",
    Callback=function()
        local m = FindByRole("Murderer")
        Notif("💀 Murderer", m and m.Name or "Não encontrado", 3)
    end
})
ESPTab:CreateButton({
    Name="🔫 Identificar Sheriff",
    Callback=function()
        local s = FindByRole("Sheriff")
        Notif("🔫 Sheriff", s and s.Name or "Não encontrado", 3)
    end
})

-- ── TAB: GOLD BOMB ────────────────────────────────────────
local GoldTab = Window:CreateTab("💛 Gold Bomb", 14428634947)
GoldTab:CreateSection("Bomba Gold Prank")
GoldTab:CreateLabel("💡 A Gold Fake Bomb é um emote de gamepass.")
GoldTab:CreateLabel("Precisa ter o item no inventário do jogo.")
GoldTab:CreateButton({
    Name="💛 Usar Gold Fake Bomb AGORA",
    Callback=function()
        local ok2,msg = DoGoldBomb()
        Notif(ok2 and "💛 Bomba!" or "❌ Erro", msg, 4)
    end
})
GoldTab:CreateButton({
    Name="🔍 Verificar se tenho o item",
    Callback=function()
        local syncData = GetRemote("Data","GetSyncData")
        if syncData then
            local ok2, emotes = pcall(function() return syncData:InvokeServer("Emotes") end)
            if ok2 and emotes and emotes["GoldFakeBomb"] then
                Notif("✅ Item", "Você TEM o GoldFakeBomb!", 3)
            else
                Notif("❌ Item", "GoldFakeBomb não encontrado no inventário.", 3)
            end
        else
            Notif("❌", "Remote GetSyncData não disponível agora", 3)
        end
    end
})

-- ── TAB: TELEPORTE ────────────────────────────────────────
local TpTab = Window:CreateTab("🌀 Teleporte", 14428634947)
TpTab:CreateSection("Locais Fixos")
TpTab:CreateButton({Name="🏠 Lobby", Callback=function() TP(Vector3.new(-61.3,1048.5,241.9)) end})
TpTab:CreateButton({Name="🗺️ Mapa (vote pad)", Callback=function() TP(Vector3.new(-47.2,1055.0,323.1)) end})
TpTab:CreateButton({Name="🏪 MM2Lobby", Callback=function() TP(Vector3.new(-107.2,1052,251.6)) end})
TpTab:CreateSection("Dinâmico")
TpTab:CreateButton({
    Name="💀 Tp para Murderer",
    Callback=function()
        local m = FindByRole("Murderer")
        if TPToPlayer(m) then Notif("Tp","Para "..m.Name,2) else Notif("❌","Murderer não achado",2) end
    end
})
TpTab:CreateButton({
    Name="🔫 Tp para Sheriff",
    Callback=function()
        local s = FindByRole("Sheriff")
        if TPToPlayer(s) then Notif("Tp","Para "..s.Name,2) else Notif("❌","Sheriff não achado",2) end
    end
})
TpTab:CreateButton({
    Name="🚶 Tp para jogador mais próximo",
    Callback=function()
        local cl, d = nil, math.huge
        for _, p in pairs(Players:GetPlayers()) do
            if p~=LP and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local d2 = (HRP.Position - p.Character.HumanoidRootPart.Position).Magnitude
                if d2<d then d=d2; cl=p end
            end
        end
        if cl then TPToPlayer(cl); Notif("Tp",cl.Name,2) end
    end
})

-- ── TAB: PLAYER ───────────────────────────────────────────
local PlTab = Window:CreateTab("🏃 Player", 14428634947)
PlTab:CreateSection("Movimento")
PlTab:CreateSlider({
    Name="WalkSpeed", Range={16,300}, Increment=1, CurrentValue=16, Flag="WSpeed",
    Callback=function(v) SpeedVal=v; if Hum then Hum.WalkSpeed=v end end
})
PlTab:CreateToggle({
    Name="Infinite Jump", CurrentValue=false, Flag="InfJ",
    Callback=function(v) InfJumpOn=v end
})
PlTab:CreateToggle({
    Name="NoClip", CurrentValue=false, Flag="NClip",
    Callback=function(v) NoClipOn=v end
})
PlTab:CreateToggle({
    Name="God Mode", CurrentValue=false, Flag="God",
    Callback=function(v) GodOn=v end
})
PlTab:CreateSection("Fly  (WASD + Space / Shift)")
PlTab:CreateToggle({
    Name="Fly Mode", CurrentValue=false, Flag="FlyMode",
    Callback=function(v)
        FlyOn=v
        if v then StartFly() else StopFly() end
    end
})
PlTab:CreateSlider({
    Name="Fly Speed", Range={10,300}, Increment=5, CurrentValue=60, Flag="FlySpd",
    Callback=function(v) FlySpeed=v end
})

-- ── TAB: MISC ─────────────────────────────────────────────
local MTab = Window:CreateTab("⚙️ Misc", 14428634947)
MTab:CreateSection("Utilitários")
MTab:CreateButton({
    Name="Anti-AFK",
    Callback=function()
        local vu = game:GetService("VirtualUser")
        LP.Idled:Connect(function()
            vu:Button2Down(Vector2.new(0,0), Camera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0), Camera.CFrame)
        end)
        Notif("Anti-AFK","Ativado!",2)
    end
})
MTab:CreateButton({
    Name="Ver Job ID do servidor",
    Callback=function() Notif("Server","JobID: "..game.JobId,5) end
})
MTab:CreateButton({
    Name="Respawnar personagem",
    Callback=function() LP:LoadCharacter() end
})
MTab:CreateSection("Info")
MTab:CreateLabel("Script: Traitors Hub v2 | by Claude")
MTab:CreateLabel("Game ID: 107949440670420")
MTab:CreateLabel("Ative o Painel na aba 🎮 para ver os botões")

-- ═══════════════════════════════════════════════════════════════
--  NOTIF INICIAL
-- ═══════════════════════════════════════════════════════════════
task.wait(1)
Notif("🔪 Traitors Hub v2",
    "Carregado! Vá em 🎮 Painel para ativar os botões flutuantes na tela.",
    5)
