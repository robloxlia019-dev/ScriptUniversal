-- ╔══════════════════════════════════════════════════╗
-- ║         VFX CONFIGURATOR  •  by Script            ║
-- ║   Mobile Friendly • Codex Compatible • Draggable  ║
-- ╚══════════════════════════════════════════════════╝

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════════════
--  CONFIGURAÇÕES PADRÃO DE VFX
-- ══════════════════════════════════
local CONFIG = {
    ParticleEmitter = {
        Rate          = 20,
        Lifetime      = NumberRange.new(1, 2),
        Speed         = NumberRange.new(5, 10),
        Size          = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(1, 0)
        }),
        Rotation      = NumberRange.new(0, 360),
        Color         = ColorSequence.new(Color3.fromRGB(100, 200, 255)),
        Transparency  = NumberSequence.new(0),
        LightEmission = 0.5,
        LightInfluence= 1,
        Enabled       = true,
    },
    Beam = {
        Width0        = 0.5,
        Width1        = 0.5,
        Segments      = 10,
        CurveSize0    = 0,
        CurveSize1    = 0,
        Color         = ColorSequence.new(Color3.fromRGB(100, 200, 255)),
        Transparency  = NumberSequence.new(0),
        LightEmission = 0.5,
        FaceCamera    = true,
        Enabled       = true,
    }
}

-- ══════════════════════════════════
--  UTILITÁRIOS
-- ══════════════════════════════════
local function tween(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.2, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out),
        props):Play()
end

local function findVFX()
    local particles, beams = {}, {}
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("ParticleEmitter") then
            table.insert(particles, v)
        elseif v:IsA("Beam") then
            table.insert(beams, v)
        end
    end
    return particles, beams
end

local function applyParticleConfig(pe)
    pe.Rate         = CONFIG.ParticleEmitter.Rate
    pe.Lifetime     = CONFIG.ParticleEmitter.Lifetime
    pe.Speed        = CONFIG.ParticleEmitter.Speed
    pe.Size         = CONFIG.ParticleEmitter.Size
    pe.Rotation     = CONFIG.ParticleEmitter.Rotation
    pe.Color        = CONFIG.ParticleEmitter.Color
    pe.Transparency = CONFIG.ParticleEmitter.Transparency
    pe.LightEmission= CONFIG.ParticleEmitter.LightEmission
    pe.LightInfluence=CONFIG.ParticleEmitter.LightInfluence
    pe.Enabled      = CONFIG.ParticleEmitter.Enabled
end

local function applyBeamConfig(b)
    b.Width0        = CONFIG.Beam.Width0
    b.Width1        = CONFIG.Beam.Width1
    b.Segments      = CONFIG.Beam.Segments
    b.CurveSize0    = CONFIG.Beam.CurveSize0
    b.CurveSize1    = CONFIG.Beam.CurveSize1
    b.Color         = CONFIG.Beam.Color
    b.Transparency  = CONFIG.Beam.Transparency
    b.LightEmission = CONFIG.Beam.LightEmission
    b.FaceCamera    = CONFIG.Beam.FaceCamera
    b.Enabled       = CONFIG.Beam.Enabled
end

-- ══════════════════════════════════
--  PALETA DE CORES
-- ══════════════════════════════════
local C = {
    BG      = Color3.fromRGB(10,  10,  18),
    Panel   = Color3.fromRGB(16,  16,  30),
    Card    = Color3.fromRGB(22,  22,  42),
    Accent  = Color3.fromRGB(80,  170, 255),
    Accent2 = Color3.fromRGB(160, 100, 255),
    Text    = Color3.fromRGB(220, 225, 240),
    SubText = Color3.fromRGB(130, 140, 165),
    Green   = Color3.fromRGB(80,  220, 140),
    Red     = Color3.fromRGB(255, 80,  100),
    Border  = Color3.fromRGB(40,  45,  75),
}

-- ══════════════════════════════════
--  SCREENGU + JANELA PRINCIPAL
-- ══════════════════════════════════
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VFX_Configurator"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 300, 0, 440)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -220)
MainFrame.BackgroundColor3 = C.BG
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 16)

-- Borda glow
local GlowBorder = Instance.new("Frame")
GlowBorder.Size = UDim2.new(1, 4, 1, 4)
GlowBorder.Position = UDim2.new(0, -2, 0, -2)
GlowBorder.BackgroundColor3 = C.Accent
GlowBorder.BackgroundTransparency = 0.55
GlowBorder.BorderSizePixel = 0
GlowBorder.ZIndex = MainFrame.ZIndex - 1
GlowBorder.Parent = MainFrame
Instance.new("UICorner", GlowBorder).CornerRadius = UDim.new(0, 18)

-- ── HEADER ──
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 52)
Header.BackgroundColor3 = C.Panel
Header.BorderSizePixel = 0
Header.ZIndex = 2
Header.Parent = MainFrame
Instance.new("UICorner", Header).CornerRadius = UDim.new(0, 16)

-- Fix do canto inferior do header
local HFix = Instance.new("Frame")
HFix.Size = UDim2.new(1, 0, 0, 16)
HFix.Position = UDim2.new(0, 0, 1, -16)
HFix.BackgroundColor3 = C.Panel
HFix.BorderSizePixel = 0
HFix.Parent = Header

-- Ícone pulsante
local IconLbl = Instance.new("TextLabel")
IconLbl.Size = UDim2.new(0, 34, 0, 34)
IconLbl.Position = UDim2.new(0, 10, 0.5, -17)
IconLbl.BackgroundTransparency = 1
IconLbl.Text = "✦"
IconLbl.TextColor3 = C.Accent
IconLbl.TextScaled = true
IconLbl.Font = Enum.Font.GothamBold
IconLbl.ZIndex = 3
IconLbl.Parent = Header

-- Animar ícone
task.spawn(function()
    while IconLbl.Parent do
        tween(IconLbl, {TextColor3 = C.Accent2}, 1.2)
        task.wait(1.2)
        tween(IconLbl, {TextColor3 = C.Accent}, 1.2)
        task.wait(1.2)
    end
end)

local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size = UDim2.new(1, -95, 0, 18)
TitleLbl.Position = UDim2.new(0, 50, 0.5, -17)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text = "VFX CONFIGURATOR"
TitleLbl.TextColor3 = C.Text
TitleLbl.TextSize = 12
TitleLbl.Font = Enum.Font.GothamBold
TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
TitleLbl.ZIndex = 3
TitleLbl.Parent = Header

local SubLbl = Instance.new("TextLabel")
SubLbl.Size = UDim2.new(1, -95, 0, 13)
SubLbl.Position = UDim2.new(0, 50, 0.5, 1)
SubLbl.BackgroundTransparency = 1
SubLbl.Text = "Mobile  ·  Codex Ready  ·  Drag me"
SubLbl.TextColor3 = C.SubText
SubLbl.TextSize = 9
SubLbl.Font = Enum.Font.Gotham
SubLbl.TextXAlignment = Enum.TextXAlignment.Left
SubLbl.ZIndex = 3
SubLbl.Parent = Header

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -40, 0.5, -15)
CloseBtn.BackgroundColor3 = C.Red
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.TextSize = 12
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.ZIndex = 4
CloseBtn.Parent = Header
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(1, 0)

CloseBtn.MouseButton1Click:Connect(function()
    tween(MainFrame, {
        Size     = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0.5, 0)
    }, 0.22)
    task.wait(0.25)
    ScreenGui:Destroy()
end)

-- ── SCROLL CONTENT ──
local Content = Instance.new("ScrollingFrame")
Content.Size = UDim2.new(1, 0, 1, -58)
Content.Position = UDim2.new(0, 0, 0, 58)
Content.BackgroundTransparency = 1
Content.ScrollBarThickness = 3
Content.ScrollBarImageColor3 = C.Accent
Content.CanvasSize = UDim2.new(0,0,0,0)
Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
Content.Parent = MainFrame

local CLayout = Instance.new("UIListLayout")
CLayout.Padding = UDim.new(0, 8)
CLayout.Parent = Content

local CPad = Instance.new("UIPadding")
CPad.PaddingLeft  = UDim.new(0, 10)
CPad.PaddingRight = UDim.new(0, 10)
CPad.PaddingTop   = UDim.new(0, 10)
CPad.PaddingBottom= UDim.new(0, 12)
CPad.Parent = Content

-- ══════════════════════════════════
--  WIDGETS
-- ══════════════════════════════════
local function makeCard(title, icon)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 0)
    card.AutomaticSize = Enum.AutomaticSize.Y
    card.BackgroundColor3 = C.Card
    card.BorderSizePixel = 0
    card.Parent = Content
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft  = UDim.new(0, 10)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingTop   = UDim.new(0, 10)
    pad.PaddingBottom= UDim.new(0, 10)
    pad.Parent = card

    local lay = Instance.new("UIListLayout")
    lay.Padding = UDim.new(0, 7)
    lay.Parent = card

    local hdr = Instance.new("TextLabel")
    hdr.Size = UDim2.new(1, 0, 0, 18)
    hdr.BackgroundTransparency = 1
    hdr.Text = (icon or "◆") .. "  " .. title
    hdr.TextColor3 = C.Accent
    hdr.TextSize = 11
    hdr.Font = Enum.Font.GothamBold
    hdr.TextXAlignment = Enum.TextXAlignment.Left
    hdr.Parent = card

    return card
end

local function makeLine(parent)
    local s = Instance.new("Frame")
    s.Size = UDim2.new(1, 0, 0, 1)
    s.BackgroundColor3 = C.Border
    s.BorderSizePixel = 0
    s.Parent = parent
end

local function makeSlider(parent, label, minV, maxV, defV, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 44)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -52, 0, 15)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.SubText
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local valL = Instance.new("TextLabel")
    valL.Size = UDim2.new(0, 48, 0, 15)
    valL.Position = UDim2.new(1, -48, 0, 0)
    valL.BackgroundTransparency = 1
    valL.Text = tostring(defV)
    valL.TextColor3 = C.Accent
    valL.TextSize = 10
    valL.Font = Enum.Font.GothamBold
    valL.TextXAlignment = Enum.TextXAlignment.Right
    valL.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 8)
    track.Position = UDim2.new(0, 0, 0, 24)
    track.BackgroundColor3 = C.Border
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)
    track.Parent = row

    local pct0 = (defV - minV) / (maxV - minV)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(pct0, 0, 1, 0)
    fill.BackgroundColor3 = C.Accent
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    fill.Parent = track

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 18, 0, 18)
    thumb.Position = UDim2.new(pct0, -9, 0.5, -9)
    thumb.BackgroundColor3 = Color3.new(1,1,1)
    thumb.BorderSizePixel = 0
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1,0)
    thumb.Parent = track

    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, C.Accent),
        ColorSequenceKeypoint.new(1, C.Accent2)
    })
    grad.Parent = fill

    local dragging = false

    local function update(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        thumb.Position = UDim2.new(rel, -9, 0.5, -9)
        local val = math.round(minV + rel * (maxV - minV))
        valL.Text = tostring(val)
        if cb then cb(val) end
    end

    local btnOverlay = Instance.new("TextButton")
    btnOverlay.Size = UDim2.new(1, 0, 0, 28)
    btnOverlay.Position = UDim2.new(0, 0, 0, 16)
    btnOverlay.BackgroundTransparency = 1
    btnOverlay.Text = ""
    btnOverlay.Parent = row

    btnOverlay.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            update(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and (inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseMovement) then
            update(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch
        or inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return row
end

local function makeToggle(parent, label, defVal, cb)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 28)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -52, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = label
    lbl.TextColor3 = C.SubText
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local togBg = Instance.new("Frame")
    togBg.Size = UDim2.new(0, 44, 0, 22)
    togBg.Position = UDim2.new(1, -44, 0.5, -11)
    togBg.BackgroundColor3 = defVal and C.Green or C.Border
    togBg.BorderSizePixel = 0
    Instance.new("UICorner", togBg).CornerRadius = UDim.new(1, 0)
    togBg.Parent = row

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = defVal and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)
    knob.BackgroundColor3 = Color3.new(1,1,1)
    knob.BorderSizePixel = 0
    Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)
    knob.Parent = togBg

    local state = defVal
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = togBg

    btn.MouseButton1Click:Connect(function()
        state = not state
        tween(togBg, {BackgroundColor3 = state and C.Green or C.Border}, 0.15)
        tween(knob, {Position = state and UDim2.new(1,-20,0.5,-9) or UDim2.new(0,2,0.5,-9)}, 0.15)
        if cb then cb(state) end
    end)

    return row
end

local function makeButton(parent, label, color, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 34)
    btn.BackgroundColor3 = color or C.Accent
    btn.Text = label
    btn.TextColor3 = Color3.new(1,1,1)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
    btn.Parent = parent

    local g = Instance.new("UIGradient")
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180,180,255))
    })
    g.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.12),
        NumberSequenceKeypoint.new(1, 0)
    })
    g.Rotation = 90
    g.Parent = btn

    btn.MouseButton1Click:Connect(function()
        tween(btn, {BackgroundTransparency = 0.35}, 0.07)
        task.wait(0.12)
        tween(btn, {BackgroundTransparency = 0}, 0.1)
        if cb then cb() end
    end)

    return btn
end

-- ══════════════════════════════════
--  CARD: PARTICLE EMITTER
-- ══════════════════════════════════
local pCard = makeCard("PARTICLE EMITTER", "✦")

makeSlider(pCard, "Rate  (particles/s)", 0, 100, 20, function(v)
    CONFIG.ParticleEmitter.Rate = v
end)

makeSlider(pCard, "Lifetime Min  (s)", 0, 10, 1, function(v)
    local mx = CONFIG.ParticleEmitter.Lifetime.Max
    CONFIG.ParticleEmitter.Lifetime = NumberRange.new(v, math.max(v, mx))
end)

makeSlider(pCard, "Lifetime Max  (s)", 0, 10, 2, function(v)
    local mn = CONFIG.ParticleEmitter.Lifetime.Min
    CONFIG.ParticleEmitter.Lifetime = NumberRange.new(math.min(mn, v), v)
end)

makeSlider(pCard, "Speed Min", 0, 50, 5, function(v)
    local mx = CONFIG.ParticleEmitter.Speed.Max
    CONFIG.ParticleEmitter.Speed = NumberRange.new(v, math.max(v, mx))
end)

makeSlider(pCard, "Speed Max", 0, 50, 10, function(v)
    local mn = CONFIG.ParticleEmitter.Speed.Min
    CONFIG.ParticleEmitter.Speed = NumberRange.new(math.min(mn, v), v)
end)

makeSlider(pCard, "Size Inicial (x0.1)", 0, 30, 5, function(v)
    local fv = v / 10
    CONFIG.ParticleEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, fv),
        NumberSequenceKeypoint.new(1, 0)
    })
end)

makeSlider(pCard, "Light Emission (%)", 0, 100, 50, function(v)
    CONFIG.ParticleEmitter.LightEmission = v / 100
end)

makeToggle(pCard, "Enabled", true, function(v)
    CONFIG.ParticleEmitter.Enabled = v
end)

makeLine(pCard)

makeButton(pCard, "✦  APLICAR PARTICLE EMITTERS", C.Accent, function()
    local ps, _ = findVFX()
    for _, pe in ipairs(ps) do applyParticleConfig(pe) end
    print("[VFX] ParticleEmitters configurados: " .. #ps)
end)

-- ══════════════════════════════════
--  CARD: BEAM
-- ══════════════════════════════════
local bCard = makeCard("BEAM", "◈")

makeSlider(bCard, "Width Início (x0.1)", 0, 30, 5, function(v)
    CONFIG.Beam.Width0 = v / 10
end)

makeSlider(bCard, "Width Fim (x0.1)", 0, 30, 5, function(v)
    CONFIG.Beam.Width1 = v / 10
end)

makeSlider(bCard, "Segments", 1, 50, 10, function(v)
    CONFIG.Beam.Segments = v
end)

makeSlider(bCard, "CurveSize Início", 0, 20, 0, function(v)
    CONFIG.Beam.CurveSize0 = v / 2
end)

makeSlider(bCard, "CurveSize Fim", 0, 20, 0, function(v)
    CONFIG.Beam.CurveSize1 = v / 2
end)

makeSlider(bCard, "Light Emission (%)", 0, 100, 50, function(v)
    CONFIG.Beam.LightEmission = v / 100
end)

makeToggle(bCard, "Face Camera", true, function(v)
    CONFIG.Beam.FaceCamera = v
end)

makeToggle(bCard, "Enabled", true, function(v)
    CONFIG.Beam.Enabled = v
end)

makeLine(bCard)

makeButton(bCard, "◈  APLICAR BEAMS", C.Accent2, function()
    local _, bs = findVFX()
    for _, b in ipairs(bs) do applyBeamConfig(b) end
    print("[VFX] Beams configurados: " .. #bs)
end)

-- ══════════════════════════════════
--  CARD: GLOBAL
-- ══════════════════════════════════
local gCard = makeCard("AÇÕES GLOBAIS", "⚡")

makeButton(gCard, "⚡  APLICAR TUDO", Color3.fromRGB(80,200,140), function()
    local ps, bs = findVFX()
    for _, pe in ipairs(ps) do applyParticleConfig(pe) end
    for _, b  in ipairs(bs) do applyBeamConfig(b)      end
    print("[VFX] Aplicado! Particles: " .. #ps .. " | Beams: " .. #bs)
end)

makeButton(gCard, "⏹  DESATIVAR TODOS", C.Red, function()
    local ps, bs = findVFX()
    for _, pe in ipairs(ps) do pe.Enabled = false end
    for _, b  in ipairs(bs) do b.Enabled  = false end
    print("[VFX] Todos desativados.")
end)

makeButton(gCard, "▶  REATIVAR TODOS", Color3.fromRGB(60,180,110), function()
    local ps, bs = findVFX()
    for _, pe in ipairs(ps) do pe.Enabled = true end
    for _, b  in ipairs(bs) do b.Enabled  = true end
    print("[VFX] Todos reativados.")
end)

makeButton(gCard, "🔍  LISTAR VFX (Output)", C.SubText, function()
    local ps, bs = findVFX()
    print("── VFX no Workspace ──")
    print("  ParticleEmitters: " .. #ps)
    for i, pe in ipairs(ps) do
        print("    " .. i .. ". " .. pe:GetFullName())
    end
    print("  Beams: " .. #bs)
    for i, b in ipairs(bs) do
        print("    " .. i .. ". " .. b:GetFullName())
    end
end)

-- ══════════════════════════════════
--  DRAG (Mobile + PC)
-- ══════════════════════════════════
local dragging = false
local dragStart, startPos

local function isDragInput(inp)
    return inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch
end

Header.InputBegan:Connect(function(inp)
    if isDragInput(inp) then
        dragging  = true
        dragStart = inp.Position
        startPos  = MainFrame.Position
    end
end)

Header.InputEnded:Connect(function(inp)
    if isDragInput(inp) then dragging = false end
end)

UserInputService.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - dragStart
        local vp    = workspace.CurrentCamera.ViewportSize
        local fw    = MainFrame.AbsoluteSize.X
        local fh    = MainFrame.AbsoluteSize.Y
        local ox    = math.clamp(startPos.X.Offset + delta.X, -vp.X/2 + fw/2, vp.X/2 - fw/2)
        local oy    = math.clamp(startPos.Y.Offset + delta.Y, -vp.Y/2 + fh/2, vp.Y/2 - fh/2)
        MainFrame.Position = UDim2.new(startPos.X.Scale, ox, startPos.Y.Scale, oy)
    end
end)

-- ══════════════════════════════════
--  ANIMAÇÃO DE ENTRADA
-- ══════════════════════════════════
MainFrame.Size = UDim2.new(0, 0, 0, 0)
MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)

tween(MainFrame, {
    Size     = UDim2.new(0, 300, 0, 440),
    Position = UDim2.new(0.5, -150, 0.5, -220),
}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)

print("╔════════════════════════════════════╗")
print("║   VFX Configurator carregado!      ║")
print("║   Arraste pelo header • Mobile OK  ║")
print("╚════════════════════════════════════╝")
