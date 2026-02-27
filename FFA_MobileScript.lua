--[[
    ╔══════════════════════════════════════════════════════╗
    ║          FFA Mobile Combat Script v2.0               ║
    ║  Auto-Aim (Pistola + Faca) | GUI Rayfield-Style      ║
    ║  Funciona no Mobile Codex                            ║
    ╚══════════════════════════════════════════════════════╝

    FUNCIONALIDADES:
    - Auto-aim para pistola no mobile (clique/toque na tela → atira no mais próximo ou no alvo selecionado)
    - Auto-aim para faca no mobile (clique → arremessa na pessoa mais próxima)
    - GUI estilo Rayfield para selecionar alvo (All = mais próximo, ou jogador específico)
    - Lista de jogadores com botão de refresh
    - Só funciona se a arma/faca estiver equipada
    - ESP (ver jogadores através das paredes)
    - Velocidade, Jump Power
    - Noclip
    - Infinite Ammo
    - Silent Aim (bala vai no alvo mesmo mirando longe)
]]

-- ╔══════════════════════════════╗
-- ║        CONFIGURAÇÕES         ║
-- ╚══════════════════════════════╝
local Config = {
    -- Auto-Aim
    AimEnabled = true,
    AimMode = "All",          -- "All" = mais próximo | "Player" = jogador selecionado
    SelectedTarget = nil,     -- nome do jogador selecionado

    -- Armas
    GunNames = {"Gun", "Pistol", "Pistola", "Weapon", "AK47", "M4", "Sniper", "Rifle"},
    KnifeNames = {"Knife", "ThrowingKnife", "Faca", "Blade", "Dagger"},

    -- ESP
    ESPEnabled = false,
    ESPColor = Color3.fromRGB(255, 0, 0),

    -- Extras
    SpeedEnabled = false,
    SpeedValue = 32,
    JumpEnabled = false,
    JumpValue = 100,
    NoclipEnabled = false,
    InfiniteAmmo = false,
    SilentAim = false,

    -- Cooldowns
    GunCooldown = 0.1,
    KnifeCooldown = 0.5,
}

-- ╔══════════════════════════════╗
-- ║         SERVIÇOS             ║
-- ╚══════════════════════════════╝
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local isMobile = UserInputService.TouchEnabled

-- ╔══════════════════════════════╗
-- ║        FUNÇÕES UTILITÁRIAS   ║
-- ╚══════════════════════════════╝

-- Verifica se uma ferramenta está equipada
local function getEquippedTool()
    local char = LocalPlayer.Character
    if not char then return nil end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            return item
        end
    end
    return nil
end

local function toolMatchesList(tool, nameList)
    if not tool then return false end
    for _, name in ipairs(nameList) do
        if tool.Name:lower():find(name:lower()) then
            return true
        end
    end
    return false
end

local function isGunEquipped()
    return toolMatchesList(getEquippedTool(), Config.GunNames)
end

local function isKnifeEquipped()
    return toolMatchesList(getEquippedTool(), Config.KnifeNames)
end

-- Pegar o personagem e HRP de um jogador
local function getCharParts(player)
    local char = player.Character
    if not char then return nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hrp, hum
end

-- Pegar o jogador mais próximo
local function getNearestPlayer()
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end

    local nearest, minDist = nil, math.huge
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local hrp, hum = getCharParts(plr)
            if hrp and hum and hum.Health > 0 then
                local dist = (hrp.Position - myHRP.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = plr
                end
            end
        end
    end
    return nearest
end

-- Pegar o alvo baseado na config
local function getTarget()
    if Config.AimMode == "All" then
        return getNearestPlayer()
    elseif Config.AimMode == "Player" and Config.SelectedTarget then
        local plr = Players:FindFirstChild(Config.SelectedTarget)
        if plr then
            local hrp, hum = getCharParts(plr)
            if hrp and hum and hum.Health > 0 then
                return plr
            end
        end
        return getNearestPlayer() -- fallback
    end
    return nil
end

-- ╔══════════════════════════════╗
-- ║        LÓGICA DE DISPARO     ║
-- ╚══════════════════════════════╝

local lastGunShot = 0
local lastKnifeThrow = 0

-- Disparar a pistola na direção do alvo
local function shootGun(targetPlayer)
    if not isGunEquipped() then return end
    local now = tick()
    if now - lastGunShot < Config.GunCooldown then return end
    lastGunShot = now

    local hrp = getCharParts(targetPlayer)
    if not hrp then return end

    -- Mover o mouse para o alvo (silently)
    local screenPos, onScreen = Camera:WorldToScreenPoint(hrp.Position)
    if not onScreen then return end

    -- Tentar disparar via Activated do tool
    local tool = getEquippedTool()
    if tool then
        -- Simular ativação apontando para o alvo
        if Config.SilentAim then
            -- Silent aim: setar o hit do mouse
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if myHRP then
                -- Firing remotely via known GunBeam path
                pcall(function()
                    local shootEvent = ReplicatedStorage:FindFirstChild("Events")
                        and ReplicatedStorage.Events:FindFirstChild("Shoot")
                    if shootEvent then
                        shootEvent:FireServer(hrp.Position, hrp)
                    else
                        -- Fallback: ativar a ferramenta
                        tool:Activate()
                    end
                end)
            end
        else
            -- Aim assist: mover câmera/mouse para o alvo e ativar
            pcall(function()
                -- Mover o mouse via MouseEvent
                local inputObject = InputObject.new and nil
                -- Ativar a tool na direção do alvo
                local cf = CFrame.new(Camera.CFrame.Position, hrp.Position)
                Camera.CFrame = CFrame.new(Camera.CFrame.Position, hrp.Position)
                tool:Activate()
            end)
        end
    end
end

-- Arremessar a faca no alvo
local function throwKnife(targetPlayer)
    if not isKnifeEquipped() then return end
    local now = tick()
    if now - lastKnifeThrow < Config.KnifeCooldown then return end
    lastKnifeThrow = now

    local hrp = getCharParts(targetPlayer)
    if not hrp then return end

    local tool = getEquippedTool()
    if not tool then return end

    pcall(function()
        -- Tentar via RemoteEvent do ThrowingKnife
        local throwEvent = ReplicatedStorage:FindFirstChild("Events")
            and ReplicatedStorage.Events:FindFirstChild("ThrowKnife")
        
        if throwEvent then
            throwEvent:FireServer(hrp.Position)
        else
            -- Apontar câmera para o alvo e ativar
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, hrp.Position)
            -- Mover personagem para olhar para o alvo
            local char = LocalPlayer.Character
            local myHRP = char and char:FindFirstChild("HumanoidRootPart")
            if myHRP then
                myHRP.CFrame = CFrame.new(myHRP.Position, Vector3.new(hrp.Position.X, myHRP.Position.Y, hrp.Position.Z))
            end
            tool:Activate()
        end
    end)
end

-- ╔══════════════════════════════╗
-- ║     DETECÇÃO DE TOQUE        ║
-- ╚══════════════════════════════╝

local function onTouchOrClick()
    if not Config.AimEnabled then return end
    
    local target = getTarget()
    if not target then return end

    -- Verificar qual arma está equipada
    if isGunEquipped() then
        shootGun(target)
    elseif isKnifeEquipped() then
        throwKnife(target)
    end
end

-- Mobile: detectar toque na tela
if isMobile then
    UserInputService.TouchTapInWorld:Connect(function(pos, processed)
        if not processed then
            onTouchOrClick()
        end
    end)
end

-- PC: detectar clique
UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        onTouchOrClick()
    end
end)

-- ╔══════════════════════════════╗
-- ║            ESP               ║
-- ╚══════════════════════════════╝

local espHighlights = {}

local function updateESP()
    -- Limpar highlights velhos
    for plr, highlight in pairs(espHighlights) do
        if not Players:FindFirstChild(plr.Name) or not plr.Character then
            if highlight and highlight.Parent then
                highlight:Destroy()
            end
            espHighlights[plr] = nil
        end
    end

    if not Config.ESPEnabled then
        for _, h in pairs(espHighlights) do
            if h and h.Parent then h:Destroy() end
        end
        espHighlights = {}
        return
    end

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            if not espHighlights[plr] then
                local h = Instance.new("Highlight")
                h.FillTransparency = 0.5
                h.OutlineTransparency = 0
                h.FillColor = Config.ESPColor
                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                h.Parent = plr.Character
                espHighlights[plr] = h
            end
        end
    end
end

-- ╔══════════════════════════════╗
-- ║       EXTRAS (SPEED ETC)     ║
-- ╚══════════════════════════════╝

local function applyExtras()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end

    if Config.SpeedEnabled then
        hum.WalkSpeed = Config.SpeedValue
    else
        hum.WalkSpeed = 16
    end

    if Config.JumpEnabled then
        hum.JumpPower = Config.JumpValue
    else
        hum.JumpPower = 50
    end
end

-- Noclip
local noclipConnection
local function setupNoclip()
    if noclipConnection then
        noclipConnection:Disconnect()
        noclipConnection = nil
    end
    if Config.NoclipEnabled then
        noclipConnection = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    else
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

-- Infinite Ammo
local function setupInfiniteAmmo()
    RunService.Heartbeat:Connect(function()
        if not Config.InfiniteAmmo then return end
        local char = LocalPlayer.Character
        if not char then return end
        local tool = getEquippedTool()
        if not tool then return end
        for _, v in ipairs(tool:GetDescendants()) do
            if v:IsA("IntValue") or v:IsA("NumberValue") then
                if v.Name:lower():find("ammo") or v.Name:lower():find("bullets") or v.Name:lower():find("mag") then
                    v.Value = 9999
                end
            end
        end
    end)
end

-- ╔══════════════════════════════╗
-- ║        LOOP PRINCIPAL        ║
-- ╚══════════════════════════════╝

RunService.Heartbeat:Connect(function()
    updateESP()
    applyExtras()
end)

setupNoclip()
setupInfiniteAmmo()

-- ╔══════════════════════════════════════════════════════╗
-- ║                  GUI RAYFIELD-STYLE                  ║
-- ╚══════════════════════════════════════════════════════╝

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "FFACombatGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = LocalPlayer.PlayerGui

-- Cores do tema
local COLORS = {
    bg = Color3.fromRGB(15, 15, 20),
    panel = Color3.fromRGB(22, 22, 30),
    accent = Color3.fromRGB(120, 80, 255),
    accentDark = Color3.fromRGB(80, 50, 200),
    text = Color3.fromRGB(220, 220, 230),
    textDim = Color3.fromRGB(130, 130, 150),
    green = Color3.fromRGB(80, 200, 120),
    red = Color3.fromRGB(220, 80, 80),
    card = Color3.fromRGB(30, 30, 42),
    border = Color3.fromRGB(50, 50, 70),
}

local function makeCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function makeStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or COLORS.border
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function makeLabel(parent, text, size, color, bold)
    local l = Instance.new("TextLabel")
    l.Text = text
    l.TextSize = size or 14
    l.TextColor3 = color or COLORS.text
    l.Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Size = UDim2.new(1, 0, 0, size and size + 4 or 18)
    l.Parent = parent
    return l
end

-- ── JANELA PRINCIPAL ─────────────────────────────────────────
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 320, 0, 480)
MainFrame.Position = UDim2.new(0.5, -160, 0.5, -240)
MainFrame.BackgroundColor3 = COLORS.bg
MainFrame.BorderSizePixel = 0
MainFrame.Parent = ScreenGui
makeCorner(MainFrame, 12)
makeStroke(MainFrame, COLORS.border, 1)

-- TÍTULO
local TitleBar = Instance.new("Frame")
TitleBar.Size = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3 = COLORS.panel
TitleBar.BorderSizePixel = 0
TitleBar.Parent = MainFrame
makeCorner(TitleBar, 12)

-- Fix canto inferior do título
local TitleFix = Instance.new("Frame")
TitleFix.Size = UDim2.new(1, 0, 0.5, 0)
TitleFix.Position = UDim2.new(0, 0, 0.5, 0)
TitleFix.BackgroundColor3 = COLORS.panel
TitleFix.BorderSizePixel = 0
TitleFix.Parent = TitleBar

local TitleIcon = Instance.new("TextLabel")
TitleIcon.Text = "⚔"
TitleIcon.TextSize = 20
TitleIcon.TextColor3 = COLORS.accent
TitleIcon.Font = Enum.Font.GothamBold
TitleIcon.BackgroundTransparency = 1
TitleIcon.Size = UDim2.new(0, 30, 1, 0)
TitleIcon.Position = UDim2.new(0, 12, 0, 0)
TitleIcon.Parent = TitleBar

local TitleText = Instance.new("TextLabel")
TitleText.Text = "FFA Combat | Mobile"
TitleText.TextSize = 15
TitleText.TextColor3 = COLORS.text
TitleText.Font = Enum.Font.GothamBold
TitleText.BackgroundTransparency = 1
TitleText.Size = UDim2.new(1, -80, 1, 0)
TitleText.Position = UDim2.new(0, 44, 0, 0)
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TitleBar

-- Botão fechar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Text = "✕"
CloseBtn.TextSize = 14
CloseBtn.TextColor3 = COLORS.textDim
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BackgroundTransparency = 1
CloseBtn.Size = UDim2.new(0, 36, 1, 0)
CloseBtn.Position = UDim2.new(1, -36, 0, 0)
CloseBtn.Parent = TitleBar

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Drag
local dragging, dragStart, startPos
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ── CONTEÚDO PRINCIPAL ────────────────────────────────────────
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, -16, 1, -52)
Content.Position = UDim2.new(0, 8, 0, 50)
Content.BackgroundTransparency = 1
Content.BorderSizePixel = 0
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = COLORS.accent
Content.CanvasSize = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = MainFrame

local ContentLayout = Instance.new("UIListLayout")
ContentLayout.Padding = UDim.new(0, 6)
ContentLayout.Parent = Content

-- ╔══ SEÇÃO: TARGET ══════════════════════════════════╗
local function makeSection(title)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, 0)
    section.AutomaticSize = Enum.AutomaticSize.Y
    section.BackgroundColor3 = COLORS.card
    section.BorderSizePixel = 0
    section.Parent = Content
    makeCorner(section, 8)
    makeStroke(section, COLORS.border, 1)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 4)
    layout.Parent = section

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = section

    local header = Instance.new("TextLabel")
    header.Text = "▸ " .. title
    header.TextSize = 12
    header.TextColor3 = COLORS.accent
    header.Font = Enum.Font.GothamBold
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, 18)
    header.TextXAlignment = Enum.TextXAlignment.Left
    header.Parent = section

    return section
end

-- ── FUNÇÃO: Toggle Button ────────────────────────────────────
local function makeToggle(parent, labelText, currentValue, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 32)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local label = Instance.new("TextLabel")
    label.Text = labelText
    label.TextSize = 13
    label.TextColor3 = COLORS.text
    label.Font = Enum.Font.Gotham
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -50, 1, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.new(0, 44, 0, 24)
    toggle.Position = UDim2.new(1, -44, 0.5, -12)
    toggle.BackgroundColor3 = currentValue and COLORS.green or COLORS.red
    toggle.Text = currentValue and "ON" or "OFF"
    toggle.TextSize = 11
    toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggle.Font = Enum.Font.GothamBold
    toggle.BorderSizePixel = 0
    toggle.Parent = row
    makeCorner(toggle, 12)

    local val = currentValue
    toggle.MouseButton1Click:Connect(function()
        val = not val
        toggle.BackgroundColor3 = val and COLORS.green or COLORS.red
        toggle.Text = val and "ON" or "OFF"
        if callback then callback(val) end
    end)
    return toggle
end

-- ── FUNÇÃO: Slider ────────────────────────────────────────────
local function makeSlider(parent, labelText, min, max, default, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 0, 44)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 18)
    header.BackgroundTransparency = 1
    header.Parent = container

    local lbl = Instance.new("TextLabel")
    lbl.Text = labelText
    lbl.TextSize = 12
    lbl.TextColor3 = COLORS.text
    lbl.Font = Enum.Font.Gotham
    lbl.BackgroundTransparency = 1
    lbl.Size = UDim2.new(0.7, 0, 1, 0)
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = header

    local valLbl = Instance.new("TextLabel")
    valLbl.Text = tostring(default)
    valLbl.TextSize = 12
    valLbl.TextColor3 = COLORS.accent
    valLbl.Font = Enum.Font.GothamBold
    valLbl.BackgroundTransparency = 1
    valLbl.Size = UDim2.new(0.3, 0, 1, 0)
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.Parent = header

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0, 26)
    track.BackgroundColor3 = COLORS.border
    track.BorderSizePixel = 0
    track.Parent = container
    makeCorner(track, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = COLORS.accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    makeCorner(fill, 3)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.Position = UDim2.new((default - min) / (max - min), -7, 0.5, -7)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.Parent = track
    makeCorner(thumb, 7)

    local draggingSlider = false
    thumb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = true
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            draggingSlider = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if draggingSlider and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local trackPos = track.AbsolutePosition
            local trackSize = track.AbsoluteSize
            local mouseX = input.Position.X
            local relX = math.clamp((mouseX - trackPos.X) / trackSize.X, 0, 1)
            local value = math.floor(min + relX * (max - min))
            fill.Size = UDim2.new(relX, 0, 1, 0)
            thumb.Position = UDim2.new(relX, -7, 0.5, -7)
            valLbl.Text = tostring(value)
            if callback then callback(value) end
        end
    end)

    return container
end

-- ╔══ SEÇÃO: AUTO-AIM ═══════════════════════════════════════╗
local aimSection = makeSection("AUTO-AIM")

makeToggle(aimSection, "Auto-Aim Ativado", Config.AimEnabled, function(v)
    Config.AimEnabled = v
end)

-- Modo de alvo
local modeRow = Instance.new("Frame")
modeRow.Size = UDim2.new(1, 0, 0, 32)
modeRow.BackgroundTransparency = 1
modeRow.Parent = aimSection

local modeLabel = Instance.new("TextLabel")
modeLabel.Text = "Modo:"
modeLabel.TextSize = 13
modeLabel.TextColor3 = COLORS.text
modeLabel.Font = Enum.Font.Gotham
modeLabel.BackgroundTransparency = 1
modeLabel.Size = UDim2.new(0.35, 0, 1, 0)
modeLabel.TextXAlignment = Enum.TextXAlignment.Left
modeLabel.Parent = modeRow

local modeAllBtn = Instance.new("TextButton")
modeAllBtn.Text = "TODOS"
modeAllBtn.TextSize = 11
modeAllBtn.Font = Enum.Font.GothamBold
modeAllBtn.Size = UDim2.new(0.3, -3, 0, 26)
modeAllBtn.Position = UDim2.new(0.35, 0, 0.5, -13)
modeAllBtn.BackgroundColor3 = Config.AimMode == "All" and COLORS.accent or COLORS.border
modeAllBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
modeAllBtn.BorderSizePixel = 0
modeAllBtn.Parent = modeRow
makeCorner(modeAllBtn, 6)

local modePlayerBtn = Instance.new("TextButton")
modePlayerBtn.Text = "JOGADOR"
modePlayerBtn.TextSize = 11
modePlayerBtn.Font = Enum.Font.GothamBold
modePlayerBtn.Size = UDim2.new(0.33, -3, 0, 26)
modePlayerBtn.Position = UDim2.new(0.67, 0, 0.5, -13)
modePlayerBtn.BackgroundColor3 = Config.AimMode == "Player" and COLORS.accent or COLORS.border
modePlayerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
modePlayerBtn.BorderSizePixel = 0
modePlayerBtn.Parent = modeRow
makeCorner(modePlayerBtn, 6)

modeAllBtn.MouseButton1Click:Connect(function()
    Config.AimMode = "All"
    Config.SelectedTarget = nil
    modeAllBtn.BackgroundColor3 = COLORS.accent
    modePlayerBtn.BackgroundColor3 = COLORS.border
end)

modePlayerBtn.MouseButton1Click:Connect(function()
    Config.AimMode = "Player"
    modePlayerBtn.BackgroundColor3 = COLORS.accent
    modeAllBtn.BackgroundColor3 = COLORS.border
end)

-- ╔══ SEÇÃO: LISTA DE JOGADORES ══════════════════════════════╗
local playerSection = makeSection("LISTA DE JOGADORES")

local statusLabel = Instance.new("TextLabel")
statusLabel.Text = "Alvo: Nenhum selecionado"
statusLabel.TextSize = 12
statusLabel.TextColor3 = COLORS.textDim
statusLabel.Font = Enum.Font.Gotham
statusLabel.BackgroundTransparency = 1
statusLabel.Size = UDim2.new(1, 0, 0, 18)
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = playerSection

local refreshBtn = Instance.new("TextButton")
refreshBtn.Text = "🔄 Atualizar Lista"
refreshBtn.TextSize = 12
refreshBtn.Font = Enum.Font.GothamBold
refreshBtn.Size = UDim2.new(1, 0, 0, 28)
refreshBtn.BackgroundColor3 = COLORS.accentDark
refreshBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
refreshBtn.BorderSizePixel = 0
refreshBtn.Parent = playerSection
makeCorner(refreshBtn, 6)

local playerList = Instance.new("Frame")
playerList.Size = UDim2.new(1, 0, 0, 0)
playerList.AutomaticSize = Enum.AutomaticSize.Y
playerList.BackgroundTransparency = 1
playerList.BorderSizePixel = 0
playerList.Parent = playerSection

local playerListLayout = Instance.new("UIListLayout")
playerListLayout.Padding = UDim.new(0, 4)
playerListLayout.Parent = playerList

local playerButtons = {}

local function refreshPlayerList()
    for _, btn in pairs(playerButtons) do
        if btn and btn.Parent then btn:Destroy() end
    end
    playerButtons = {}

    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local btn = Instance.new("TextButton")
            btn.Text = "👤 " .. plr.DisplayName .. " (@" .. plr.Name .. ")"
            btn.TextSize = 12
            btn.Font = Enum.Font.Gotham
            btn.Size = UDim2.new(1, 0, 0, 32)
            btn.BackgroundColor3 = Config.SelectedTarget == plr.Name and COLORS.accent or COLORS.card
            btn.TextColor3 = COLORS.text
            btn.BorderSizePixel = 0
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.Parent = playerList
            makeCorner(btn, 6)
            makeStroke(btn, COLORS.border, 1)

            local btnPad = Instance.new("UIPadding")
            btnPad.PaddingLeft = UDim.new(0, 8)
            btnPad.Parent = btn

            btn.MouseButton1Click:Connect(function()
                -- Resetar todos
                for _, b in pairs(playerButtons) do
                    if b and b.Parent then
                        b.BackgroundColor3 = COLORS.card
                    end
                end

                Config.SelectedTarget = plr.Name
                Config.AimMode = "Player"
                modePlayerBtn.BackgroundColor3 = COLORS.accent
                modeAllBtn.BackgroundColor3 = COLORS.border
                btn.BackgroundColor3 = COLORS.accent
                statusLabel.Text = "Alvo: " .. plr.DisplayName
            end)

            table.insert(playerButtons, btn)
        end
    end

    if #playerButtons == 0 then
        local empty = Instance.new("TextLabel")
        empty.Text = "Nenhum jogador encontrado"
        empty.TextSize = 12
        empty.TextColor3 = COLORS.textDim
        empty.Font = Enum.Font.Gotham
        empty.BackgroundTransparency = 1
        empty.Size = UDim2.new(1, 0, 0, 24)
        empty.TextXAlignment = Enum.TextXAlignment.Center
        empty.Parent = playerList
        table.insert(playerButtons, empty)
    end
end

refreshBtn.MouseButton1Click:Connect(refreshPlayerList)
refreshPlayerList()

Players.PlayerAdded:Connect(refreshPlayerList)
Players.PlayerRemoving:Connect(function(plr)
    if Config.SelectedTarget == plr.Name then
        Config.SelectedTarget = nil
        statusLabel.Text = "Alvo: Nenhum selecionado"
    end
    task.wait(0.1)
    refreshPlayerList()
end)

-- ╔══ SEÇÃO: ESP ═════════════════════════════════════════════╗
local espSection = makeSection("EXTRAS VISUAIS")

makeToggle(espSection, "ESP (ver através das paredes)", Config.ESPEnabled, function(v)
    Config.ESPEnabled = v
    updateESP()
end)

-- ╔══ SEÇÃO: VELOCIDADE / JUMP ═══════════════════════════════╗
local moveSection = makeSection("MOVIMENTAÇÃO")

makeToggle(moveSection, "Speed Hack", Config.SpeedEnabled, function(v)
    Config.SpeedEnabled = v
    applyExtras()
end)

makeSlider(moveSection, "Velocidade", 16, 100, Config.SpeedValue, function(v)
    Config.SpeedValue = v
    applyExtras()
end)

makeToggle(moveSection, "High Jump", Config.JumpEnabled, function(v)
    Config.JumpEnabled = v
    applyExtras()
end)

makeSlider(moveSection, "Jump Power", 50, 300, Config.JumpValue, function(v)
    Config.JumpValue = v
    applyExtras()
end)

makeToggle(moveSection, "Noclip", Config.NoclipEnabled, function(v)
    Config.NoclipEnabled = v
    setupNoclip()
end)

-- ╔══ SEÇÃO: ARMAS ════════════════════════════════════════════╗
local weaponSection = makeSection("ARMAS")

makeToggle(weaponSection, "Infinite Ammo", Config.InfiniteAmmo, function(v)
    Config.InfiniteAmmo = v
end)

makeToggle(weaponSection, "Silent Aim", Config.SilentAim, function(v)
    Config.SilentAim = v
end)

makeSlider(weaponSection, "Cooldown Pistola (s×100)", 1, 100, math.floor(Config.GunCooldown * 100), function(v)
    Config.GunCooldown = v / 100
end)

makeSlider(weaponSection, "Cooldown Faca (s×100)", 10, 300, math.floor(Config.KnifeCooldown * 100), function(v)
    Config.KnifeCooldown = v / 100
end)

-- ╔══ SEÇÃO: STATUS ══════════════════════════════════════════╗
local statusSection = makeSection("STATUS")

local statusInfoLabel = Instance.new("TextLabel")
statusInfoLabel.Text = "Aguardando..."
statusInfoLabel.TextSize = 12
statusInfoLabel.TextColor3 = COLORS.textDim
statusInfoLabel.Font = Enum.Font.Gotham
statusInfoLabel.BackgroundTransparency = 1
statusInfoLabel.Size = UDim2.new(1, 0, 0, 18)
statusInfoLabel.TextXAlignment = Enum.TextXAlignment.Left
statusInfoLabel.Parent = statusSection

-- Atualizar status
RunService.Heartbeat:Connect(function()
    local tool = getEquippedTool()
    local toolName = tool and tool.Name or "Nenhuma"
    local targetPlr = getTarget()
    local targetName = targetPlr and targetPlr.DisplayName or "Nenhum"
    local gunEquip = isGunEquipped() and "✓" or "✗"
    local knifeEquip = isKnifeEquipped() and "✓" or "✗"
    statusInfoLabel.Text = string.format("Ferramenta: %s | Pistola: %s | Faca: %s\nAlvo: %s", toolName, gunEquip, knifeEquip, targetName)
    statusInfoLabel.Size = UDim2.new(1, 0, 0, 36)
end)

-- ╔══ BOTÃO MINIMIZAR (Mobile) ════════════════════════════════╗
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Text = "⚔ FFA"
MinimizeBtn.TextSize = 13
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Size = UDim2.new(0, 70, 0, 36)
MinimizeBtn.Position = UDim2.new(0, 8, 1, -50)
MinimizeBtn.BackgroundColor3 = COLORS.accent
MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinimizeBtn.BorderSizePixel = 0
MinimizeBtn.Visible = true
MinimizeBtn.Parent = ScreenGui
makeCorner(MinimizeBtn, 10)
makeStroke(MinimizeBtn, COLORS.accentDark, 2)

MinimizeBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    MinimizeBtn.Text = MainFrame.Visible and "✕ Fechar" or "⚔ FFA"
end)

-- Drag do botão minimizado
local dragMin, dragMinStart, dragMinPos
MinimizeBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragMin = true
        dragMinStart = input.Position
        dragMinPos = MinimizeBtn.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragMin and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragMinStart
        if delta.Magnitude > 5 then
            MinimizeBtn.Position = UDim2.new(dragMinPos.X.Scale, dragMinPos.X.Offset + delta.X, dragMinPos.Y.Scale, dragMinPos.Y.Offset + delta.Y)
        end
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragMin = false
    end
end)

print("[FFA Script] Carregado com sucesso! Pressione ⚔ FFA para abrir o menu.")
print("[FFA Script] Mobile: " .. (isMobile and "SIM" or "NÃO"))
