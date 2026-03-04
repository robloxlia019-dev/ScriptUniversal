-- ═══════════════════════════════════════════════════════════
--   TRAITORS Script — by Claude
--   Game ID: 107949440670420
--   Botões arrastáveis, Aimbot, Teleports, Bomb Prank, ESP
-- ═══════════════════════════════════════════════════════════

-- ══════════════════════ SERVIÇOS ══════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService       = game:GetService("HttpService")
local Workspace        = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP       = Players.LocalPlayer
local Mouse    = LP:GetMouse()
local Camera   = Workspace.CurrentCamera
local PlayerGui = LP:WaitForChild("PlayerGui")

-- Atualizar character ao respawnar
local Character = LP.Character or LP.CharacterAdded:Wait()
local Humanoid, HRP
local function UpdateChar(char)
    Character = char
    Humanoid  = char:WaitForChild("Humanoid")
    HRP       = char:WaitForChild("HumanoidRootPart")
end
UpdateChar(Character)
LP.CharacterAdded:Connect(UpdateChar)

-- ══════════════════════ CONFIG ══════════════════════
local CFG = {
    AimbotEnabled  = false,
    AimbotOnClick  = true,   -- só mira quando botão pressionado
    AimbotTarget   = nil,
    AimbotFOV      = 200,    -- raio de detecção em pixels
    ShowFOVCircle  = true,
    ESPEnabled     = false,
    AutoShoot      = false,
    InfiniteAmmo   = false,
    SpeedHack      = false,
    SpeedValue     = 25,
    NoClip         = false,
    FlyEnabled     = false,
    FlySpeed       = 60,
    GodMode        = false,
    RoleLabel      = "Desconhecido",
}

-- ══════════════════════ RAYFIELD ══════════════════════
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok then warn("Rayfield falhou ao carregar") return end

-- ══════════════════════════════════════════════════════
--   SISTEMA DE BOTÕES ARRASTÁVEIS CUSTOMIZADOS
-- ══════════════════════════════════════════════════════
local DragUI = Instance.new("ScreenGui")
DragUI.Name              = "TraitorsDragUI"
DragUI.IgnoreGuiInset    = true
DragUI.ResetOnSpawn      = false
DragUI.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
DragUI.Parent            = PlayerGui

-- Container visual de todos os botões arrastáveis
local BtnFolder = Instance.new("Folder")
BtnFolder.Name   = "DragButtons"
BtnFolder.Parent = DragUI

-- Posições salvas dos botões
local SavedPositions = {}

-- ── Função: criar botão arrastável ──────────────────────
local function MakeDragButton(opts)
    --[[
        opts = {
            id       = string,   -- identificador único
            label    = string,
            size     = UDim2,
            pos      = UDim2,
            color    = Color3,
            textColor= Color3,
            round    = bool,     -- formato redondo
            onClick  = function
        }
    ]]
    local id    = opts.id or HttpService:GenerateGUID(false)
    local saved = SavedPositions[id]

    local Frame = Instance.new("Frame")
    Frame.Name            = "DragBtn_" .. id
    Frame.Size            = opts.size or UDim2.new(0, 120, 0, 42)
    Frame.Position        = saved or opts.pos or UDim2.new(0.5, 0, 0.5, 0)
    Frame.BackgroundColor3 = opts.color or Color3.fromRGB(30, 30, 40)
    Frame.BorderSizePixel = 0
    Frame.Active          = true
    Frame.ZIndex          = 10
    Frame.Parent          = DragUI

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = opts.round and UDim.new(1, 0) or UDim.new(0, 10)
    Corner.Parent       = Frame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color     = opts.color and opts.color:Lerp(Color3.new(1,1,1), 0.3) or Color3.fromRGB(80,80,120)
    Stroke.Thickness = 1.5
    Stroke.Parent    = Frame

    local Glow = Instance.new("Frame")
    Glow.Size               = UDim2.new(1, 0, 0.5, 0)
    Glow.Position           = UDim2.new(0, 0, 0, 0)
    Glow.BackgroundColor3   = Color3.new(1,1,1)
    Glow.BackgroundTransparency = 0.92
    Glow.BorderSizePixel    = 0
    Glow.ZIndex             = 11
    Glow.Parent             = Frame
    Instance.new("UICorner", Glow).CornerRadius = opts.round and UDim.new(1,0) or UDim.new(0,10)

    local Lbl = Instance.new("TextLabel")
    Lbl.Size                  = UDim2.new(1, 0, 1, 0)
    Lbl.BackgroundTransparency= 1
    Lbl.Text                  = opts.label or "Botão"
    Lbl.TextColor3            = opts.textColor or Color3.new(1,1,1)
    Lbl.Font                  = Enum.Font.GothamBold
    Lbl.TextSize              = opts.round and 11 or 13
    Lbl.ZIndex                = 12
    Lbl.TextWrapped           = true
    Lbl.Parent                = Frame

    -- ── BOTÃO DE TRANCA (🔒) ─────────────────────────────
    local LockBtn = Instance.new("TextButton")
    LockBtn.Size                  = UDim2.new(0, 18, 0, 18)
    LockBtn.Position              = UDim2.new(1, -20, 0, 2)
    LockBtn.BackgroundColor3      = Color3.fromRGB(50,50,70)
    LockBtn.TextColor3            = Color3.new(1,1,1)
    LockBtn.Font                  = Enum.Font.GothamBold
    LockBtn.TextSize              = 10
    LockBtn.Text                  = "🔓"
    LockBtn.BorderSizePixel       = 0
    LockBtn.ZIndex                = 15
    LockBtn.Parent                = Frame
    if opts.round then LockBtn.Visible = false end
    Instance.new("UICorner", LockBtn).CornerRadius = UDim.new(0, 4)

    -- ── ARRASTE ─────────────────────────────────────────
    local locked   = false
    local dragging = false
    local dragStart, startPos

    local function BeginDrag(input)
        if locked then return end
        dragging  = true
        dragStart = input.Position
        startPos  = Frame.Position
    end

    local function UpdateDrag(input)
        if not dragging then return end
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end

    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            BeginDrag(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            UpdateDrag(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                SavedPositions[id] = Frame.Position -- salvar posição
            end
        end
    end)

    -- ── TRANCA ──────────────────────────────────────────
    LockBtn.MouseButton1Click:Connect(function()
        locked = not locked
        LockBtn.Text = locked and "🔒" or "🔓"
        LockBtn.BackgroundColor3 = locked
            and Color3.fromRGB(180, 60, 60)
            or  Color3.fromRGB(50, 50, 70)
        if locked then
            SavedPositions[id] = Frame.Position
        end
    end)

    -- ── CLICK DO BOTÃO ──────────────────────────────────
    local clickConn
    Frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Só dispara click se não estava arrastando
            task.delay(0.12, function()
                if not dragging then
                    -- Feedback visual
                    TweenService:Create(Frame, TweenInfo.new(0.08), {
                        BackgroundColor3 = (opts.color or Color3.fromRGB(30,30,40)):Lerp(Color3.new(1,1,1), 0.15)
                    }):Play()
                    task.delay(0.1, function()
                        TweenService:Create(Frame, TweenInfo.new(0.08), {
                            BackgroundColor3 = opts.color or Color3.fromRGB(30,30,40)
                        }):Play()
                    end)
                    if opts.onClick then
                        pcall(opts.onClick)
                    end
                end
            end)
        end
    end)

    return Frame, Lbl, LockBtn
end

-- ══════════════════════════════════════════════════════
--   ENCONTRAR MURDER / SHERIFF / INNOCENTS
-- ══════════════════════════════════════════════════════
local function GetRole(player)
    -- MM2: roles ficam em leaderstats ou em Values do char
    local char = player and player.Character
    if not char then return "Unknown" end
    -- Tentar pegar role
    local roleVal = char:FindFirstChild("Role") or char:FindFirstChild("MurdererChance")
    if roleVal then return roleVal.Value end
    -- Verificar se tem gun tool (sheriff)
    local backpack = player:FindFirstChild("Backpack")
    if backpack then
        for _, tool in pairs(backpack:GetChildren()) do
            if tool.Name:lower():find("gun") or tool.Name:lower():find("sheriff") then
                return "Sheriff"
            end
            if tool.Name:lower():find("knife") then
                return "Murderer"
            end
        end
    end
    if char then
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") then
                if tool.Name:lower():find("gun") or tool.Name:lower():find("sheriff") then
                    return "Sheriff"
                end
                if tool.Name:lower():find("knife") then
                    return "Murderer"
                end
            end
        end
    end
    return "Innocent"
end

local function FindMurderer()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP then
            local role = GetRole(plr)
            if role == "Murderer" then return plr end
        end
    end
    -- Fallback: procurar por knife tool equipada
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            for _, obj in pairs(plr.Character:GetChildren()) do
                if obj:IsA("Tool") and (obj.Name:lower():find("knife") or obj.Name:lower():find("blade")) then
                    return plr
                end
            end
        end
    end
    return nil
end

local function FindSheriff()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP then
            local role = GetRole(plr)
            if role == "Sheriff" then return plr end
        end
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LP and plr.Character then
            for _, obj in pairs(plr.Character:GetChildren()) do
                if obj:IsA("Tool") and obj.Name:lower():find("gun") then
                    return plr
                end
            end
        end
    end
    return nil
end

-- ══════════════════════════════════════════════════════
--   DETECÇÃO DE ARMA EQUIPADA + MUZZLE
-- ══════════════════════════════════════════════════════
local function GetEquippedTool()
    if not Character then return nil end
    for _, obj in pairs(Character:GetChildren()) do
        if obj:IsA("Tool") then return obj end
    end
    return nil
end

local function GetMuzzle(tool)
    if not tool then return nil end
    -- Procurar attachment "Muzzle" ou "MuzzlePoint" ou "GunPoint"
    for _, desc in pairs(tool:GetDescendants()) do
        if desc:IsA("Attachment") and 
           (desc.Name:lower():find("muzzle") or desc.Name:lower():find("gunpoint") or desc.Name == "Shoot") then
            return desc
        end
    end
    -- Fallback: Handle da tool
    local handle = tool:FindFirstChild("Handle")
    return handle
end

local function IsGun(tool)
    if not tool then return false end
    local name = tool.Name:lower()
    return name:find("gun") or name:find("sniper") or name:find("pistol") 
        or name:find("rifle") or name:find("sheriff") or name:find("crossbow")
        or name:find("persuader") or name:find("zero") or name:find("jolly sniper")
        or name:find("freeze ray") or name:find("tempest") or name:find("marshal")
        or name:find("atlantic") or name:find("icespli")
end

-- ══════════════════════════════════════════════════════
--   AIMBOT SYSTEM
-- ══════════════════════════════════════════════════════
local FOVFrame do
    FOVFrame = Instance.new("Frame")
    FOVFrame.Name              = "FOVCircle"
    FOVFrame.Size              = UDim2.new(0, CFG.AimbotFOV*2, 0, CFG.AimbotFOV*2)
    FOVFrame.AnchorPoint       = Vector2.new(0.5, 0.5)
    FOVFrame.Position          = UDim2.new(0.5, 0, 0.5, 0)
    FOVFrame.BackgroundTransparency = 1
    FOVFrame.BorderSizePixel   = 0
    FOVFrame.ZIndex            = 20
    FOVFrame.Visible           = false
    FOVFrame.Parent            = DragUI

    local ring = Instance.new("UIStroke")
    ring.Color     = Color3.fromRGB(255, 80, 80)
    ring.Thickness = 1.5
    ring.Parent    = FOVFrame
    Instance.new("UICorner", FOVFrame).CornerRadius = UDim.new(1, 0)
end

local function WorldToScreen(pos)
    local _, onScreen, depth = Camera:WorldToViewportPoint(pos)
    return onScreen, depth
end

local function GetScreenPos(pos)
    local sp = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y)
end

local function GetBestTarget(excludeMurder)
    local center    = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    local best      = nil
    local bestDist  = CFG.AimbotFOV

    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LP then continue end
        local char = plr.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        if not head then continue end
        local hum = char:FindFirstChild("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local _, onScreen, depth = Camera:WorldToViewportPoint(head.Position)
        if not onScreen or depth <= 0 then continue end

        local sp   = GetScreenPos(head.Position)
        local dist = (sp - center).Magnitude
        if dist < bestDist then
            bestDist = dist
            best     = plr
        end
    end
    return best
end

-- Aimbot loop — só ativa quando botão pressionado (RightMouse) ou auto
local AimbotActive = false

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimbotActive = true
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        AimbotActive = false
    end
end)

RunService.RenderStepped:Connect(function()
    -- FOV Circle update
    FOVFrame.Visible = CFG.AimbotEnabled and CFG.ShowFOVCircle
    FOVFrame.Size    = UDim2.new(0, CFG.AimbotFOV*2, 0, CFG.AimbotFOV*2)

    if not CFG.AimbotEnabled then return end
    if CFG.AimbotOnClick and not AimbotActive then return end

    local target = GetBestTarget()
    if not target or not target.Character then return end
    local head = target.Character:FindFirstChild("Head")
    if not head then return end

    -- Smooth aim — mover câmera suavemente para o alvo
    local _, onScreen = Camera:WorldToViewportPoint(head.Position)
    if not onScreen then return end

    local cf = CFrame.new(Camera.CFrame.Position, head.Position)
    Camera.CFrame = Camera.CFrame:Lerp(cf, 0.35)

    CFG.AimbotTarget = target
end)

-- ══════════════════════════════════════════════════════
--   SHOOT MURDER — Atirar no murderer
-- ══════════════════════════════════════════════════════
local function ShootAtMurderer()
    local tool = GetEquippedTool()
    if not tool then
        return false, "Nenhuma arma equipada!"
    end
    if not IsGun(tool) then
        return false, "Ferramenta atual não é uma arma: " .. tool.Name
    end

    local murderer = FindMurderer()
    if not murderer or not murderer.Character then
        return false, "Murderer não encontrado!"
    end

    local head = murderer.Character:FindFirstChild("Head")
    if not head then
        return false, "Head do murderer não encontrada!"
    end

    -- Verificar linha de visão
    local muzzle   = GetMuzzle(tool)
    local muzzlePos = muzzle and muzzle.WorldPosition or (HRP and HRP.Position + Vector3.new(0,1.5,0))

    -- Aim preciso: apontar câmera exatamente para a head
    local targetCF = CFrame.new(Camera.CFrame.Position, head.Position)
    Camera.CFrame  = targetCF

    task.wait(0.05) -- pequena pausa para a câmera atualizar

    -- Tentar usar GunBeam remote (método primário MM2)
    local Remotes  = ReplicatedStorage:FindFirstChild("Game") and
                     ReplicatedStorage.Game:FindFirstChild("Remotes")

    local shot = false

    if Remotes then
        local gameplay = Remotes:FindFirstChild("Gameplay")
        if gameplay then
            local gunKill = gameplay:FindFirstChild("GunKill")
            local gunBeam = gameplay:FindFirstChild("GunBeam")
            if gunKill then
                pcall(function()
                    gunKill:FireServer(murderer.Character, head.Position)
                end)
                shot = true
            end
            if gunBeam then
                pcall(function()
                    gunBeam:FireServer(murderer, head.Position, muzzlePos)
                end)
                shot = true
            end
        end

        -- Tentar ShootOld também
        local shootOld = Remotes:FindFirstChild("ShootOld")
        if shootOld then
            pcall(function()
                shootOld:FireServer(head.Position, murderer.Character)
            end)
            shot = true
        end
    end

    -- Método via MouseClick simulado na tool (fallback)
    if not shot then
        local fireEvent = tool:FindFirstChildWhichIsA("RemoteEvent")
            or tool:FindFirstChildWhichIsA("BindableEvent")
        if fireEvent then
            pcall(function()
                if fireEvent:IsA("RemoteEvent") then
                    fireEvent:FireServer(head.Position)
                else
                    fireEvent:Fire(head.Position)
                end
            end)
            shot = true
        end
    end

    if shot then
        return true, "Tiro disparado em " .. murderer.Name .. "! 🎯"
    else
        return false, "Não foi possível disparar. Tente equipar a gun manualmente."
    end
end

-- ══════════════════════════════════════════════════════
--   ESP SYSTEM
-- ══════════════════════════════════════════════════════
local ESPFolder = Instance.new("Folder")
ESPFolder.Name   = "TraitorsESP"
ESPFolder.Parent = Workspace

local RoleColors = {
    Murderer = Color3.fromRGB(255, 50,  50),
    Sheriff  = Color3.fromRGB(50,  150, 255),
    Innocent = Color3.fromRGB(50,  255, 100),
    Unknown  = Color3.fromRGB(200, 200, 200),
}

local function ClearESP()
    for _, v in pairs(ESPFolder:GetChildren()) do v:Destroy() end
end

local function MakeESP(player)
    if player == LP then return end
    local char = player.Character
    if not char then return end
    local hrp  = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local role  = GetRole(player)
    local color = RoleColors[role] or RoleColors.Unknown

    -- BillboardGui acima do player
    local bb = Instance.new("BillboardGui")
    bb.Name         = player.Name .. "_ESP"
    bb.AlwaysOnTop  = true
    bb.Size         = UDim2.new(0, 120, 0, 50)
    bb.StudsOffset  = Vector3.new(0, 3.2, 0)
    bb.Adornee      = hrp
    bb.Parent       = ESPFolder

    local bg = Instance.new("Frame")
    bg.Size                  = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3      = Color3.fromRGB(15,15,20)
    bg.BackgroundTransparency= 0.3
    bg.BorderSizePixel       = 0
    bg.Parent                = bb
    Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 6)

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size                  = UDim2.new(1, 0, 0.55, 0)
    nameLbl.BackgroundTransparency= 1
    nameLbl.Text                  = player.Name
    nameLbl.TextColor3            = color
    nameLbl.Font                  = Enum.Font.GothamBold
    nameLbl.TextSize              = 13
    nameLbl.TextStrokeTransparency = 0.5
    nameLbl.Parent                = bg

    local roleLbl = Instance.new("TextLabel")
    roleLbl.Size                  = UDim2.new(1, 0, 0.45, 0)
    roleLbl.Position              = UDim2.new(0, 0, 0.55, 0)
    roleLbl.BackgroundTransparency= 1
    roleLbl.Text                  = "[ " .. role .. " ]"
    roleLbl.TextColor3            = color
    roleLbl.Font                  = Enum.Font.Gotham
    roleLbl.TextSize              = 11
    roleLbl.TextStrokeTransparency = 0.5
    roleLbl.Parent                = bg

    -- Highlight no corpo
    local hl = Instance.new("SelectionBox")
    hl.Name          = player.Name .. "_HL"
    hl.Adornee       = char
    hl.Color3        = color
    hl.LineThickness = 0.06
    hl.SurfaceTransparency = 0.85
    hl.SurfaceColor3 = color
    hl.Parent        = ESPFolder
end

RunService.Heartbeat:Connect(function()
    if CFG.ESPEnabled then
        ClearESP()
        for _, plr in pairs(Players:GetPlayers()) do
            pcall(function() MakeESP(plr) end)
        end
    end
end)

-- ══════════════════════════════════════════════════════
--   FLY
-- ══════════════════════════════════════════════════════
local flyBV, flyBG, flyConn

local function EnableFly()
    if not HRP then return end
    flyBV = Instance.new("BodyVelocity")
    flyBV.Velocity  = Vector3.new(0,0,0)
    flyBV.MaxForce  = Vector3.new(1e9,1e9,1e9)
    flyBV.Parent    = HRP

    flyBG = Instance.new("BodyGyro")
    flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9)
    flyBG.D         = 100
    flyBG.Parent    = HRP

    flyConn = RunService.RenderStepped:Connect(function()
        if not CFG.FlyEnabled then return end
        local cam = Workspace.CurrentCamera
        local dir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)      then dir += Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)  then dir -= Vector3.new(0,1,0) end
        flyBV.Velocity         = dir * CFG.FlySpeed
        flyBG.CFrame           = cam.CFrame
        Humanoid.PlatformStand = true
    end)
end

local function DisableFly()
    if flyBV  then flyBV:Destroy()  end
    if flyBG  then flyBG:Destroy()  end
    if flyConn then flyConn:Disconnect() end
    if Humanoid then Humanoid.PlatformStand = false end
end

-- ══════════════════════════════════════════════════════
--   NOCLIP
-- ══════════════════════════════════════════════════════
RunService.Stepped:Connect(function()
    if CFG.NoClip and Character then
        for _, p in pairs(Character:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- ══════════════════════════════════════════════════════
--   BOMB PRANK (Trap via PlaceTrap Remote)
-- ══════════════════════════════════════════════════════
local function PlaceBombPrank(targetPlayer)
    local Remotes = ReplicatedStorage:FindFirstChild("Game") and
                    ReplicatedStorage.Game:FindFirstChild("Remotes")
    if not Remotes then
        return false, "Remotes não encontrado"
    end

    -- SelectTroll = escolhe o troll/prank
    local SelectTroll = Remotes:FindFirstChild("SelectTroll")
    local PlaceTrap   = Remotes:FindFirstChild("PlaceTrap")
    local TrapTouch   = Remotes:FindFirstChild("TrapTouch")

    local pos = HRP and HRP.Position or Vector3.new(0,1,0)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
        pos = targetPlayer.Character.HumanoidRootPart.Position
    end

    local bombed = false

    if PlaceTrap then
        pcall(function()
            PlaceTrap:FireServer(pos, "Bomb")
            bombed = true
        end)
    end

    if SelectTroll then
        pcall(function()
            SelectTroll:FireServer("Bomb", targetPlayer)
            bombed = true
        end)
    end

    -- Tentar via Gameplay Trap remote
    if Remotes:FindFirstChild("Gameplay") then
        local gt = Remotes.Gameplay:FindFirstChild("Trap")
            or Remotes.Gameplay:FindFirstChild("PlaceTrap")
        if gt then
            pcall(function()
                gt:FireServer(pos)
                bombed = true
            end)
        end
    end

    if bombed then
        return true, "💣 Bomba colocada!"
    else
        return false, "Sem permissão para PlaceTrap (precisa ser Murderer ou ter Trap item)"
    end
end

-- ══════════════════════════════════════════════════════
--   TELEPORTE
-- ══════════════════════════════════════════════════════
local TpLocations = {
    ["🏠 Lobby"]    = Vector3.new(-61.3, 1048.5, 241.9),
    ["🗺️ Mapa"]     = Vector3.new(-47.2, 1055.0, 323.1),
    ["💀 Murderer"] = nil, -- dinâmico
    ["🔫 Sheriff"]  = nil, -- dinâmico
}

local function TeleportTo(pos)
    if not HRP or not pos then return end
    HRP.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
end

-- ══════════════════════════════════════════════════════════════════════
--   CRIAÇÃO DOS BOTÕES ARRASTÁVEIS — SHOOT MURDER + TELEPORTS + MISC
-- ══════════════════════════════════════════════════════════════════════

-- ── BOTÃO SHOOT MURDER ────────────────────────────────
local shootBtn, shootLbl = MakeDragButton({
    id       = "shoot_murder",
    label    = "🎯 SHOOT\nMURDER",
    size     = UDim2.new(0, 115, 0, 55),
    pos      = UDim2.new(0, 20, 0.5, -80),
    color    = Color3.fromRGB(180, 30, 30),
    onClick  = function()
        local ok, msg = ShootAtMurderer()
        Rayfield:Notify({
            Title   = ok and "✅ Tiro!" or "❌ Erro",
            Content = msg,
            Duration = 3,
        })
    end
})

-- ── BOTÃO AIMBOT TOGGLE ───────────────────────────────
local aimbotBtn, aimbotLbl = MakeDragButton({
    id      = "aimbot_toggle",
    label   = "🔴 AIMBOT\nOFF",
    size    = UDim2.new(0, 115, 0, 55),
    pos     = UDim2.new(0, 20, 0.5, -15),
    color   = Color3.fromRGB(40, 40, 60),
    onClick = function()
        CFG.AimbotEnabled = not CFG.AimbotEnabled
        if aimbotLbl then
            aimbotLbl.Text = CFG.AimbotEnabled and "🟢 AIMBOT\nON" or "🔴 AIMBOT\nOFF"
        end
        aimbotBtn.BackgroundColor3 = CFG.AimbotEnabled
            and Color3.fromRGB(20, 150, 50)
            or  Color3.fromRGB(40, 40, 60)
    end
})

-- ── BOTÕES TELEPORTE (redondos pequenos) ─────────────
local tpDefs = {
    { id="tp_lobby",    label="🏠\nLobby",    color=Color3.fromRGB(40,80,160),  pos=UDim2.new(0, 145, 0.5, -80) },
    { id="tp_map",      label="🗺️\nMapa",     color=Color3.fromRGB(40,140,80),  pos=UDim2.new(0, 215, 0.5, -80) },
    { id="tp_murder",   label="💀\nMurder",   color=Color3.fromRGB(160,30,30),  pos=UDim2.new(0, 145, 0.5, -15) },
    { id="tp_sheriff",  label="🔫\nSheriff",  color=Color3.fromRGB(60,120,200), pos=UDim2.new(0, 215, 0.5, -15) },
}

local tpActions = {
    tp_lobby   = function() TeleportTo(Vector3.new(-61.3, 1048.5, 241.9)) end,
    tp_map     = function() TeleportTo(Vector3.new(-47.2, 1055.0, 323.1)) end,
    tp_murder  = function()
        local m = FindMurderer()
        if m and m.Character and m.Character:FindFirstChild("HumanoidRootPart") then
            TeleportTo(m.Character.HumanoidRootPart.Position)
            Rayfield:Notify({Title="Teleporte", Content="Tp para " .. m.Name, Duration=2})
        else
            Rayfield:Notify({Title="❌ Erro", Content="Murderer não encontrado!", Duration=2})
        end
    end,
    tp_sheriff = function()
        local s = FindSheriff()
        if s and s.Character and s.Character:FindFirstChild("HumanoidRootPart") then
            TeleportTo(s.Character.HumanoidRootPart.Position)
            Rayfield:Notify({Title="Teleporte", Content="Tp para " .. s.Name, Duration=2})
        else
            Rayfield:Notify({Title="❌ Erro", Content="Sheriff não encontrado!", Duration=2})
        end
    end,
}

for _, def in pairs(tpDefs) do
    MakeDragButton({
        id      = def.id,
        label   = def.label,
        size    = UDim2.new(0, 60, 0, 60),
        pos     = def.pos,
        color   = def.color,
        round   = true,
        onClick = tpActions[def.id],
    })
end

-- ── BOTÃO BOMB PRANK ──────────────────────────────────
MakeDragButton({
    id      = "bomb_prank",
    label   = "💣 BOMB\nPRANK",
    size    = UDim2.new(0, 115, 0, 55),
    pos     = UDim2.new(0, 285, 0.5, -80),
    color   = Color3.fromRGB(150, 100, 20),
    onClick = function()
        local murderer = FindMurderer()
        local ok, msg  = PlaceBombPrank(murderer)
        Rayfield:Notify({
            Title   = ok and "💣 Bomba!" or "❌ Erro",
            Content = msg,
            Duration = 3,
        })
    end,
})

-- ── BOTÃO ESP TOGGLE ──────────────────────────────────
local espBtn, espLbl = MakeDragButton({
    id      = "esp_toggle",
    label   = "👁️ ESP\nOFF",
    size    = UDim2.new(0, 115, 0, 55),
    pos     = UDim2.new(0, 285, 0.5, -15),
    color   = Color3.fromRGB(40, 40, 60),
    onClick = function()
        CFG.ESPEnabled = not CFG.ESPEnabled
        if espLbl then
            espLbl.Text = CFG.ESPEnabled and "👁️ ESP\nON" or "👁️ ESP\nOFF"
        end
        espBtn.BackgroundColor3 = CFG.ESPEnabled
            and Color3.fromRGB(20, 130, 150)
            or  Color3.fromRGB(40, 40, 60)
        if not CFG.ESPEnabled then ClearESP() end
    end,
})

-- ══════════════════════════════════════════════════════
--   RAYFIELD WINDOW — Configurações avançadas
-- ══════════════════════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name             = "🔪 Traitors Script",
    LoadingTitle     = "Traitors Hub",
    LoadingSubtitle  = "by Claude",
    ConfigurationSaving = { Enabled = true, FileName = "TraitorsConfig" },
    KeySystem        = false,
})

-- ── TAB: AIMBOT ───────────────────────────────────────
local AimTab = Window:CreateTab("🎯 Aimbot", 14428634947)
AimTab:CreateSection("Configurações de Mira")

AimTab:CreateToggle({
    Name="Aimbot Ativo", CurrentValue=false, Flag="AimbotOn",
    Callback=function(v)
        CFG.AimbotEnabled = v
        if aimbotLbl then aimbotLbl.Text = v and "🟢 AIMBOT\nON" or "🔴 AIMBOT\nOFF" end
        aimbotBtn.BackgroundColor3 = v and Color3.fromRGB(20,150,50) or Color3.fromRGB(40,40,60)
    end
})

AimTab:CreateToggle({
    Name="Mira só ao pressionar Clique Direito", CurrentValue=true, Flag="AimbotClick",
    Callback=function(v) CFG.AimbotOnClick = v end
})

AimTab:CreateToggle({
    Name="Mostrar Círculo FOV", CurrentValue=true, Flag="ShowFOV",
    Callback=function(v) CFG.ShowFOVCircle = v end
})

AimTab:CreateSlider({
    Name="Raio FOV (pixels)", Range={50,600}, Increment=10, CurrentValue=200, Flag="FOVVal",
    Callback=function(v) CFG.AimbotFOV = v end
})

AimTab:CreateSection("Arma Detectada")
local weaponLabel = AimTab:CreateLabel("🔫 Arma: Verificando...")

AimTab:CreateButton({
    Name="Verificar Arma Equipada",
    Callback=function()
        local tool = GetEquippedTool()
        if tool then
            local gun = IsGun(tool)
            weaponLabel:Set("🔫 Arma: " .. tool.Name .. (gun and " ✅ GUN" or " ⚠️ NÃO É GUN"))
            Rayfield:Notify({
                Title  = "Arma Detectada",
                Content = tool.Name .. (gun and " — Pode atirar!" or " — Não é uma gun!"),
                Duration = 3,
            })
        else
            weaponLabel:Set("❌ Nenhuma arma equipada!")
            Rayfield:Notify({Title="Sem Arma", Content="Equipe uma gun primeiro!", Duration=3})
        end
    end
})

AimTab:CreateButton({
    Name="🎯 Atirar no Murderer AGORA",
    Callback=function()
        local ok, msg = ShootAtMurderer()
        Rayfield:Notify({Title= ok and "✅ Tiro!" or "❌ Erro", Content=msg, Duration=3})
    end
})

-- ── TAB: ESP ─────────────────────────────────────────
local ESPTab = Window:CreateTab("👁️ ESP", 14428634947)
ESPTab:CreateSection("Visibilidade")

ESPTab:CreateToggle({
    Name="ESP de Jogadores", CurrentValue=false, Flag="ESPOn",
    Callback=function(v)
        CFG.ESPEnabled = v
        if espLbl then espLbl.Text = v and "👁️ ESP\nON" or "👁️ ESP\nOFF" end
        espBtn.BackgroundColor3 = v and Color3.fromRGB(20,130,150) or Color3.fromRGB(40,40,60)
        if not v then ClearESP() end
    end
})

ESPTab:CreateButton({
    Name="Identificar Murderer",
    Callback=function()
        local m = FindMurderer()
        Rayfield:Notify({
            Title   = "💀 Murderer",
            Content = m and ("É: " .. m.Name) or "Não identificado ainda",
            Duration = 4,
        })
    end
})

ESPTab:CreateButton({
    Name="Identificar Sheriff",
    Callback=function()
        local s = FindSheriff()
        Rayfield:Notify({
            Title   = "🔫 Sheriff",
            Content = s and ("É: " .. s.Name) or "Não identificado",
            Duration = 4,
        })
    end
})

ESPTab:CreateButton({
    Name="Listar Todos com Roles",
    Callback=function()
        local list = ""
        for _, plr in pairs(Players:GetPlayers()) do
            local role = GetRole(plr)
            local icon = role=="Murderer" and "💀" or role=="Sheriff" and "🔫" or "😇"
            list = list .. icon .. " " .. plr.Name .. " - " .. role .. "\n"
        end
        Rayfield:Notify({Title="Jogadores", Content=list ~= "" and list or "Ninguém", Duration=6})
    end
})

-- ── TAB: TELEPORTE ────────────────────────────────────
local TpTab = Window:CreateTab("🌀 Teleporte", 14428634947)
TpTab:CreateSection("Locais Fixos")

TpTab:CreateButton({Name="🏠 Ir para Lobby",    Callback=function() TeleportTo(Vector3.new(-61.3,1048.5,241.9)) end})
TpTab:CreateButton({Name="🗺️ Ir para Mapa",     Callback=function() TeleportTo(Vector3.new(-47.2,1055.0,323.1)) end})
TpTab:CreateButton({Name="🏪 Ir para MM2Lobby", Callback=function() TeleportTo(Vector3.new(-107.2,1052,251.6)) end})

TpTab:CreateSection("Teleporte Dinâmico")
TpTab:CreateButton({
    Name="💀 Tp para Murderer",
    Callback=function()
        local m = FindMurderer()
        if m and m.Character and m.Character:FindFirstChild("HumanoidRootPart") then
            TeleportTo(m.Character.HumanoidRootPart.Position)
            Rayfield:Notify({Title="Tp 💀", Content="Teleportado para " .. m.Name, Duration=2})
        else
            Rayfield:Notify({Title="❌", Content="Murderer não encontrado", Duration=2})
        end
    end
})
TpTab:CreateButton({
    Name="🔫 Tp para Sheriff",
    Callback=function()
        local s = FindSheriff()
        if s and s.Character and s.Character:FindFirstChild("HumanoidRootPart") then
            TeleportTo(s.Character.HumanoidRootPart.Position)
            Rayfield:Notify({Title="Tp 🔫", Content="Teleportado para " .. s.Name, Duration=2})
        else
            Rayfield:Notify({Title="❌", Content="Sheriff não encontrado", Duration=2})
        end
    end
})
TpTab:CreateButton({
    Name="🚶 Tp para Jogador (mais próximo)",
    Callback=function()
        local closest, dist = nil, math.huge
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LP and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local d = (HRP.Position - plr.Character.HumanoidRootPart.Position).Magnitude
                if d < dist then dist = d; closest = plr end
            end
        end
        if closest then
            TeleportTo(closest.Character.HumanoidRootPart.Position)
            Rayfield:Notify({Title="Tp", Content="Tp para " .. closest.Name, Duration=2})
        end
    end
})

-- ── TAB: PLAYER ───────────────────────────────────────
local PlayerTab = Window:CreateTab("🏃 Player", 14428634947)
PlayerTab:CreateSection("Movimento")

PlayerTab:CreateSlider({
    Name="WalkSpeed", Range={16,300}, Increment=1, CurrentValue=16, Flag="WSp",
    Callback=function(v)
        CFG.SpeedValue = v
        if Humanoid then Humanoid.WalkSpeed = v end
    end
})

PlayerTab:CreateToggle({
    Name="Infinite Jump", CurrentValue=false, Flag="InfJump",
    Callback=function(v) CFG.InfJump = v end
})

UserInputService.JumpRequest:Connect(function()
    if CFG.InfJump and Humanoid then
        Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

PlayerTab:CreateToggle({
    Name="NoClip", CurrentValue=false, Flag="NCli",
    Callback=function(v) CFG.NoClip = v end
})

PlayerTab:CreateToggle({
    Name="God Mode", CurrentValue=false, Flag="God",
    Callback=function(v) CFG.GodMode = v end
})

PlayerTab:CreateToggle({
    Name="Fly Mode (WASD + Space/Shift)", CurrentValue=false, Flag="Fly",
    Callback=function(v)
        CFG.FlyEnabled = v
        if v then EnableFly() else DisableFly() end
    end
})

PlayerTab:CreateSlider({
    Name="Fly Speed", Range={10,300}, Increment=5, CurrentValue=60, Flag="FlySpd",
    Callback=function(v) CFG.FlySpeed = v end
})

-- God Mode loop
RunService.Heartbeat:Connect(function()
    if CFG.GodMode and Humanoid then
        Humanoid.Health = Humanoid.MaxHealth
    end
    if CFG.SpeedValue ~= 16 and Humanoid then
        Humanoid.WalkSpeed = CFG.SpeedValue
    end
end)

-- ── TAB: BOMB PRANK ───────────────────────────────────
local BombTab = Window:CreateTab("💣 Bomb Prank", 14428634947)
BombTab:CreateSection("Prank System")
BombTab:CreateLabel("💡 Requer papel de Murderer ou item Trap")

BombTab:CreateButton({
    Name="💣 Colocar Bomba (posição atual)",
    Callback=function()
        local ok, msg = PlaceBombPrank(nil)
        Rayfield:Notify({Title= ok and "💣 Bomba!" or "❌ Erro", Content=msg, Duration=3})
    end
})

BombTab:CreateButton({
    Name="💣 Bomba no Murderer",
    Callback=function()
        local m = FindMurderer()
        local ok, msg = PlaceBombPrank(m)
        Rayfield:Notify({Title= ok and "💣 Boom!" or "❌ Erro", Content=msg, Duration=3})
    end
})

BombTab:CreateButton({
    Name="💣 Bomba no Sheriff",
    Callback=function()
        local s = FindSheriff()
        local ok, msg = PlaceBombPrank(s)
        Rayfield:Notify({Title= ok and "💣 Boom!" or "❌ Erro", Content=msg, Duration=3})
    end
})

BombTab:CreateSection("Trolls Extras")
BombTab:CreateButton({
    Name="Ativar Stealth (Invisível)",
    Callback=function()
        local Remotes = ReplicatedStorage:FindFirstChild("Game") and
                        ReplicatedStorage.Game:FindFirstChild("Remotes")
        local stealth = Remotes and Remotes.Gameplay and Remotes.Gameplay:FindFirstChild("Stealth")
        if stealth then
            pcall(function() stealth:FireServer() end)
            Rayfield:Notify({Title="Stealth", Content="Modo invisível ativado!", Duration=3})
        else
            Rayfield:Notify({Title="❌", Content="Stealth não disponível (requer role)", Duration=3})
        end
    end
})

-- ── TAB: MISC ─────────────────────────────────────────
local MiscTab = Window:CreateTab("⚙️ Misc", 14428634947)
MiscTab:CreateSection("Interface")

MiscTab:CreateButton({
    Name="🔁 Mostrar/Ocultar Botões Drag",
    Callback=function()
        DragUI.Enabled = not DragUI.Enabled
        Rayfield:Notify({Title="UI", Content=DragUI.Enabled and "Botões visíveis" or "Botões ocultos", Duration=2})
    end
})

MiscTab:CreateButton({
    Name="🔄 Resetar Posições dos Botões",
    Callback=function()
        SavedPositions = {}
        Rayfield:Notify({Title="Reset", Content="Reabra o script para resetar posições", Duration=3})
    end
})

MiscTab:CreateSection("Anti-AFK")
MiscTab:CreateButton({
    Name="Ativar Anti-AFK",
    Callback=function()
        local vu = game:GetService("VirtualUser")
        LP.Idled:Connect(function()
            vu:Button2Down(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0,0), Workspace.CurrentCamera.CFrame)
        end)
        Rayfield:Notify({Title="Anti-AFK", Content="Ativado!", Duration=2})
    end
})

MiscTab:CreateSection("Info")
MiscTab:CreateLabel("Script: Traitors | Claude")
MiscTab:CreateLabel("ID do Jogo: 107949440670420")
MiscTab:CreateLabel("Botões arrastáveis — arraste e trave com 🔒")

-- ══════════════════════════════════════════════════════
--   INICIALIZAÇÃO
-- ══════════════════════════════════════════════════════
Rayfield:Notify({
    Title   = "🔪 Traitors Script",
    Content = "Carregado! Botões visíveis na tela.\nSegure Clique Direito para Aimbot.",
    Duration = 5,
})
