-- ╔═══════════════════════════════════════════════════════╗
-- ║        TERRAIN EDITOR v2.0 — Delta Executor          ║
-- ║        Client Only · Studio Lite Compatible           ║
-- ╚═══════════════════════════════════════════════════════╝

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")

local player   = Players.LocalPlayer
local mouse    = player:GetMouse()
local camera   = workspace.CurrentCamera
local terrain  = workspace.Terrain

-- ─── Estado ──────────────────────────────────────────────────
local active           = false
local mode             = "Add"
local brushRadius      = 10
local fillHeight       = 20
local selectedMatName  = "Grass"
local selectedMaterial = Enum.Material.Grass
local exportName       = "Terrain"
local terrainHistory   = {}

-- Seleção
local selActive  = false
local selStep    = 0
local selP1      = nil
local selP2      = nil
local selParts   = {}

-- Detecção de click real (sem arrasto)
local dragStart  = nil
local dragged    = false
local DRAG_THRESH = 7

-- Animações gradient centralizadas
local gradAnims  = {}  -- {grad, speed, phase}
local stripAnims = {}  -- {grad, speed, phase}

-- ─── Materiais ───────────────────────────────────────────────
local MATS = {
    { n="Grass",       c=Color3.fromRGB( 80,155, 55) },
    { n="LeafyGrass",  c=Color3.fromRGB( 55,135, 38) },
    { n="Sand",        c=Color3.fromRGB(215,195,115) },
    { n="Rock",        c=Color3.fromRGB(120,120,120) },
    { n="Ground",      c=Color3.fromRGB(100, 70, 45) },
    { n="Mud",         c=Color3.fromRGB( 85, 65, 38) },
    { n="Snow",        c=Color3.fromRGB(215,228,248) },
    { n="Ice",         c=Color3.fromRGB(145,205,238) },
    { n="Sandstone",   c=Color3.fromRGB(195,155, 85) },
    { n="Limestone",   c=Color3.fromRGB(185,175,155) },
    { n="Basalt",      c=Color3.fromRGB( 55, 55, 60) },
    { n="Salt",        c=Color3.fromRGB(238,235,225) },
    { n="Glacier",     c=Color3.fromRGB(130,195,228) },
    { n="CrackedLava", c=Color3.fromRGB(175, 55, 18) },
    { n="Asphalt",     c=Color3.fromRGB( 45, 45, 50) },
    { n="Pavement",    c=Color3.fromRGB(145,145,150) },
    { n="Cobblestone", c=Color3.fromRGB(115,105, 95) },
    { n="Water",       c=Color3.fromRGB( 35,115,195) },
}

-- ─────────────────────────────────────────────────────────────
-- CORES / CONSTANTES
-- ─────────────────────────────────────────────────────────────
local C_BG      = Color3.fromRGB(10, 6, 18)
local C_TITLE   = Color3.fromRGB(14, 8, 24)
local C_SECTION = Color3.fromRGB(16, 10, 28)
local C_BTN     = Color3.fromRGB(20, 12, 36)
local C_BTN_ACT = Color3.fromRGB(72, 25, 130)
local C_TEXT    = Color3.fromRGB(215, 195, 248)
local C_DIM     = Color3.fromRGB(110, 80, 155)
local C_SEP     = Color3.fromRGB(40, 24, 68)

local G_SEQ = ColorSequence.new({    -- gradiente dos botões/strips
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.35, Color3.fromRGB(160,  80, 255)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB( 80,  18, 160)),
    ColorSequenceKeypoint.new(0.65, Color3.fromRGB(160,  80, 255)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(255, 255, 255)),
})

-- ─────────────────────────────────────────────────────────────
-- HELPERS DE GUI
-- ─────────────────────────────────────────────────────────────

local function corner(r, p)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = p
    return c
end

local function padding(t, b, l, r, p)
    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, t)
    pad.PaddingBottom = UDim.new(0, b)
    pad.PaddingLeft   = UDim.new(0, l)
    pad.PaddingRight  = UDim.new(0, r)
    pad.Parent = p
end

local function listLayout(gap, align, p)
    local l = Instance.new("UIListLayout")
    l.Padding             = UDim.new(0, gap)
    l.HorizontalAlignment = align or Enum.HorizontalAlignment.Center
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.Parent = p
    return l
end

local function makeFrame(size, pos, color, parent, clip)
    local f = Instance.new("Frame")
    f.Size              = size
    f.Position          = pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3  = color or C_BG
    f.BorderSizePixel   = 0
    f.ClipsDescendants  = clip or false
    f.Parent            = parent
    return f
end

local function makeSep(parent)
    local f = makeFrame(UDim2.new(1, 0, 0, 1), nil, C_SEP, parent)
    return f
end

local function sectionLabel(text, parent)
    local l = Instance.new("TextLabel")
    l.Size              = UDim2.new(1, 0, 0, 16)
    l.BackgroundTransparency = 1
    l.Text              = text
    l.TextColor3        = C_DIM
    l.TextSize          = 9
    l.Font              = Enum.Font.GothamBold
    l.TextXAlignment    = Enum.TextXAlignment.Left
    l.Parent            = parent
    return l
end

-- ── Botão com borda gradient animada ─────────────────────────
local function makeGBtn(text, h, parent)
    h = h or 28

    -- Container externo (borda gradient)
    local outer = makeFrame(UDim2.new(1, 0, 0, h), nil, Color3.new(1,1,1), parent)
    corner(7, outer)

    local grad = Instance.new("UIGradient")
    grad.Color  = G_SEQ
    grad.Parent = outer

    table.insert(gradAnims, { grad = grad, speed = 55, phase = math.random(0, 359) })

    -- Inner (botão real)
    local btn = Instance.new("TextButton")
    btn.Size              = UDim2.new(1, -4, 1, -4)
    btn.Position          = UDim2.new(0, 2, 0, 2)
    btn.BackgroundColor3  = C_BTN
    btn.BorderSizePixel   = 0
    btn.Text              = text
    btn.TextColor3        = C_TEXT
    btn.TextSize          = 11
    btn.Font              = Enum.Font.GothamBold
    btn.AutoButtonColor   = false
    btn.Parent            = outer
    corner(5, btn)

    -- hover
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(35, 20, 58) }):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = C_BTN }):Play()
    end)

    return btn, outer
end

-- ── TextBox estilizado ────────────────────────────────────────
local function makeTextBox(placeholder, text, parent, h)
    local outer = makeFrame(UDim2.new(1, 0, 0, h or 26), nil, Color3.new(1,1,1), parent)
    corner(6, outer)

    local grad = Instance.new("UIGradient")
    grad.Color  = G_SEQ
    grad.Parent = outer
    table.insert(gradAnims, { grad = grad, speed = 40, phase = math.random(0, 359) })

    local box = Instance.new("TextBox")
    box.Size              = UDim2.new(1, -4, 1, -4)
    box.Position          = UDim2.new(0, 2, 0, 2)
    box.BackgroundColor3  = Color3.fromRGB(18, 10, 32)
    box.BorderSizePixel   = 0
    box.Text              = text or ""
    box.PlaceholderText   = placeholder or ""
    box.TextColor3        = C_TEXT
    box.PlaceholderColor3 = Color3.fromRGB(80, 55, 110)
    box.TextSize          = 11
    box.Font              = Enum.Font.Gotham
    box.ClearTextOnFocus  = false
    box.Parent            = outer
    corner(5, box)

    return box, outer
end

-- ── Strip lateral animado ─────────────────────────────────────
local function makeStrip(parent, side)
    local strip = makeFrame(
        UDim2.new(0, 3, 1, 0),
        side == "L" and UDim2.new(0, 0, 0, 0) or UDim2.new(1, -3, 0, 0),
        Color3.new(1,1,1),
        parent
    )
    strip.ZIndex = 10
    corner(3, strip)

    local grad = Instance.new("UIGradient")
    grad.Color    = G_SEQ
    grad.Rotation = 90
    grad.Parent   = strip

    table.insert(stripAnims, { grad = grad, speed = 1.2, phase = math.random(0, 628) / 100 })
    return strip
end

-- ─────────────────────────────────────────────────────────────
-- GUI PRINCIPAL
-- ─────────────────────────────────────────────────────────────

local sg = Instance.new("ScreenGui")
sg.Name              = "TerrainEditorV2"
sg.ResetOnSpawn      = false
sg.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
sg.IgnoreGuiInset    = true
sg.Parent            = player.PlayerGui

-- ── Frame principal ───────────────────────────────────────────
local main = makeFrame(UDim2.new(0, 200, 0, 0), UDim2.new(0, 10, 0.5, -280), C_BG, sg)
main.AutomaticSize  = Enum.AutomaticSize.Y
main.Active         = true
main.Draggable      = true
main.ClipsDescendants = false
corner(12, main)

-- borda exterior sutil
local outerStroke = Instance.new("UIStroke")
outerStroke.Color        = Color3.fromRGB(60, 30, 100)
outerStroke.Thickness    = 1
outerStroke.Transparency = 0.4
outerStroke.Parent       = main

-- strips laterais
makeStrip(main, "L")
makeStrip(main, "R")

-- ── Título ────────────────────────────────────────────────────
local titleBar = makeFrame(UDim2.new(1, 0, 0, 34), nil, C_TITLE, main)
corner(12, titleBar)

-- fix canto inferior do título
local titleFix = makeFrame(UDim2.new(1, 0, 0, 12), UDim2.new(0,0,1,-12), C_TITLE, titleBar)

-- gradient no título
local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(14,  8, 24)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(38, 15, 70)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(14,  8, 24)),
})
titleGrad.Parent = titleBar
table.insert(gradAnims, { grad = titleGrad, speed = 25, phase = 0 })

local titleIcon = Instance.new("TextLabel")
titleIcon.Size              = UDim2.new(0, 26, 1, -4)
titleIcon.Position          = UDim2.new(0, 8, 0, 2)
titleIcon.BackgroundTransparency = 1
titleIcon.Text              = "⛰"
titleIcon.TextSize          = 15
titleIcon.Font              = Enum.Font.GothamBold
titleIcon.Parent            = titleBar

local titleLbl = Instance.new("TextLabel")
titleLbl.Size               = UDim2.new(1, -40, 1, 0)
titleLbl.Position           = UDim2.new(0, 32, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text               = "Terrain Editor v2.0"
titleLbl.TextColor3         = C_TEXT
titleLbl.TextSize           = 11
titleLbl.Font               = Enum.Font.GothamBold
titleLbl.TextXAlignment     = Enum.TextXAlignment.Left
titleLbl.Parent             = titleBar

-- ── Scroll principal ──────────────────────────────────────────
local scroll = Instance.new("ScrollingFrame")
scroll.Size                 = UDim2.new(1, 0, 0, 0)
scroll.Position             = UDim2.new(0, 0, 0, 34)
scroll.AutomaticSize        = Enum.AutomaticSize.Y
scroll.AutomaticCanvasSize  = Enum.AutomaticSize.Y
scroll.CanvasSize           = UDim2.new(0,0,0,0)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel      = 0
scroll.ScrollBarThickness   = 2
scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 40, 140)
scroll.Parent               = main

listLayout(3, Enum.HorizontalAlignment.Center, scroll)
padding(6, 10, 8, 8, scroll)

-- ─────────────────────────────────────────────────────────────
-- ATIVAR
-- ─────────────────────────────────────────────────────────────

local activateBtn = makeGBtn("🟢  Ativar Editor", 30, scroll)

makeSep(scroll)

-- ─────────────────────────────────────────────────────────────
-- MODO
-- ─────────────────────────────────────────────────────────────

sectionLabel("  MODO", scroll)

local addBtn,   addOuter   = makeGBtn("➕  Adicionar", 26, scroll)
local eraseBtn, eraseOuter = makeGBtn("🗑  Borracha",  26, scroll)

makeSep(scroll)

-- ─────────────────────────────────────────────────────────────
-- BRUSH / RADIUS
-- ─────────────────────────────────────────────────────────────

sectionLabel("  BRUSH RADIUS", scroll)

local radRow = makeFrame(UDim2.new(1, 0, 0, 26), nil, Color3.new(0,0,0,0), scroll)
radRow.BackgroundTransparency = 1
local radHL = Instance.new("UIListLayout")
radHL.FillDirection          = Enum.FillDirection.Horizontal
radHL.HorizontalAlignment    = Enum.HorizontalAlignment.Center
radHL.Padding                = UDim.new(0, 3)
radHL.Parent                 = radRow

local radMinBtn, _ = makeGBtn("−", 26, radRow)
radMinBtn.Parent.Size = UDim2.new(0, 28, 1, 0)
radMinBtn.TextSize = 15

local radDisp = Instance.new("TextLabel")
radDisp.Size             = UDim2.new(0, 86, 1, 0)
radDisp.BackgroundColor3 = Color3.fromRGB(18, 10, 32)
radDisp.BorderSizePixel  = 0
radDisp.Text             = "10"
radDisp.TextColor3       = Color3.fromRGB(200, 160, 255)
radDisp.TextSize         = 12
radDisp.Font             = Enum.Font.GothamBold
radDisp.Parent           = radRow
corner(5, radDisp)

local radPlusBtn, _ = makeGBtn("+", 26, radRow)
radPlusBtn.Parent.Size = UDim2.new(0, 28, 1, 0)
radPlusBtn.TextSize = 15

makeSep(scroll)

-- ─────────────────────────────────────────────────────────────
-- MATERIAIS
-- ─────────────────────────────────────────────────────────────

sectionLabel("  MATERIAL", scroll)

local matBtns = {}

for _, mat in ipairs(MATS) do
    local row = makeFrame(UDim2.new(1, 0, 0, 22), nil, Color3.fromRGB(22, 13, 38), scroll)
    corner(5, row)

    local dot = makeFrame(UDim2.new(0, 8, 0, 8), UDim2.new(0, 7, 0.5, -4), mat.c, row)
    corner(4, dot)

    local lbl = Instance.new("TextLabel")
    lbl.Size             = UDim2.new(1, -22, 1, 0)
    lbl.Position         = UDim2.new(0, 20, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text             = mat.n
    lbl.TextColor3       = Color3.fromRGB(185, 165, 220)
    lbl.TextSize         = 10
    lbl.Font             = Enum.Font.Gotham
    lbl.TextXAlignment   = Enum.TextXAlignment.Left
    lbl.Parent           = row

    local hit = Instance.new("TextButton")
    hit.Size             = UDim2.new(1, 0, 1, 0)
    hit.BackgroundTransparency = 1
    hit.Text             = ""
    hit.Parent           = row

    matBtns[mat.n] = { row = row }

    hit.MouseButton1Click:Connect(function()
        for k, v in pairs(matBtns) do
            v.row.BackgroundColor3 = Color3.fromRGB(22, 13, 38)
        end
        row.BackgroundColor3 = Color3.fromRGB(50, 20, 88)
        selectedMaterial = Enum.Material[mat.n]
        selectedMatName  = mat.n
    end)

    hit.MouseEnter:Connect(function()
        if selectedMatName ~= mat.n then
            TweenService:Create(row, TweenInfo.new(0.1),
                { BackgroundColor3 = Color3.fromRGB(32, 18, 55) }):Play()
        end
    end)
    hit.MouseLeave:Connect(function()
        if selectedMatName ~= mat.n then
            TweenService:Create(row, TweenInfo.new(0.1),
                { BackgroundColor3 = Color3.fromRGB(22, 13, 38) }):Play()
        end
    end)
end

matBtns["Grass"].row.BackgroundColor3 = Color3.fromRGB(50, 20, 88)

makeSep(scroll)

-- ─────────────────────────────────────────────────────────────
-- SELEÇÃO DE ÁREA
-- ─────────────────────────────────────────────────────────────

sectionLabel("  ÁREA", scroll)

local selAreaBtn, _ = makeGBtn("📐  Selecionar Área", 26, scroll)

-- Altura do preenchimento
local heightRow = makeFrame(UDim2.new(1, 0, 0, 26), nil, nil, scroll)
heightRow.BackgroundTransparency = 1

local heightHL = Instance.new("UIListLayout")
heightHL.FillDirection       = Enum.FillDirection.Horizontal
heightHL.HorizontalAlignment = Enum.HorizontalAlignment.Center
heightHL.Padding             = UDim.new(0, 4)
heightHL.Parent              = heightRow

local heightIconLbl = Instance.new("TextLabel")
heightIconLbl.Size             = UDim2.new(0, 56, 1, 0)
heightIconLbl.BackgroundColor3 = Color3.fromRGB(18, 10, 32)
heightIconLbl.BorderSizePixel  = 0
heightIconLbl.Text             = "↕ Alt:"
heightIconLbl.TextColor3       = C_DIM
heightIconLbl.TextSize         = 10
heightIconLbl.Font             = Enum.Font.GothamBold
heightIconLbl.Parent           = heightRow
corner(5, heightIconLbl)

local heightBox, _ = makeTextBox("20", "20", heightRow, 26)
heightBox.Parent.Size = UDim2.new(1, -64, 1, 0)

heightBox:GetPropertyChangedSignal("Text"):Connect(function()
    local v = tonumber(heightBox.Text)
    if v then fillHeight = math.clamp(v, 1, 800) end
end)

local fillAreaBtn, _ = makeGBtn("🎨  Preencher Área", 26, scroll)

makeSep(scroll)

-- ─────────────────────────────────────────────────────────────
-- EXPORT
-- ─────────────────────────────────────────────────────────────

sectionLabel("  EXPORTAR SCRIPT", scroll)

local nameBox, _ = makeTextBox("Nome do arquivo...", "Terrain", scroll, 26)

nameBox:GetPropertyChangedSignal("Text"):Connect(function()
    if nameBox.Text ~= "" then
        exportName = nameBox.Text
    end
end)

local exportBtn, _ = makeGBtn("📥  Baixar Script .lua", 28, scroll)
exportBtn.TextSize = 10

-- ─────────────────────────────────────────────────────────────
-- BRUSH PREVIEW
-- ─────────────────────────────────────────────────────────────

local brushBall = Instance.new("Part")
brushBall.Name          = "TE_BrushBall"
brushBall.Shape         = Enum.PartType.Ball
brushBall.Size          = Vector3.new(20, 20, 20)
brushBall.Anchored      = true
brushBall.CanCollide    = false
brushBall.CastShadow    = false
brushBall.Material      = Enum.Material.Neon
brushBall.Transparency  = 1
brushBall.Parent        = workspace

local brushRing = Instance.new("Part")
brushRing.Name          = "TE_BrushRing"
brushRing.Shape         = Enum.PartType.Cylinder
brushRing.Size          = Vector3.new(0.4, 20, 20)
brushRing.Anchored      = true
brushRing.CanCollide    = false
brushRing.CastShadow    = false
brushRing.Material      = Enum.Material.Neon
brushRing.Transparency  = 1
brushRing.Parent        = workspace

-- ─────────────────────────────────────────────────────────────
-- LOOP DE ANIMAÇÃO
-- ─────────────────────────────────────────────────────────────

RunService.RenderStepped:Connect(function(dt)
    -- Gradientes dos botões / título (rotação)
    for _, a in ipairs(gradAnims) do
        a.phase = (a.phase + a.speed * dt) % 360
        a.grad.Rotation = a.phase
    end

    -- Strips laterais (offset senoidal — efeito de shimmer)
    for _, a in ipairs(stripAnims) do
        a.phase = a.phase + a.speed * dt
        a.grad.Offset = Vector2.new(0, math.sin(a.phase) * 0.7)
    end

    -- Brush preview
    if active and not selActive then
        local rp = RaycastParams.new()
        rp.FilterType = Enum.RaycastFilterType.Exclude
        rp.FilterDescendantsInstances = { brushBall, brushRing }

        local ray    = camera:ScreenPointToRay(mouse.X, mouse.Y)
        local result = workspace:Raycast(ray.Origin, ray.Direction * 2000, rp)

        if result then
            local col = mode == "Add"
                and Color3.fromRGB(130, 60, 255)
                or  Color3.fromRGB(255, 70, 70)

            brushBall.CFrame      = CFrame.new(result.Position)
            brushBall.Size        = Vector3.new(brushRadius*2, brushRadius*2, brushRadius*2)
            brushBall.Color       = col
            brushBall.Transparency = 0.78

            brushRing.CFrame      = CFrame.new(result.Position) * CFrame.Angles(0, 0, math.pi/2)
            brushRing.Size        = Vector3.new(0.4, brushRadius*2, brushRadius*2)
            brushRing.Color       = col
            brushRing.Transparency = 0.3
        else
            brushBall.Transparency = 1
            brushRing.Transparency = 1
        end
    else
        brushBall.Transparency = 1
        brushRing.Transparency = 1
    end
end)

-- ─────────────────────────────────────────────────────────────
-- RAYCAST HELPER
-- ─────────────────────────────────────────────────────────────

local function getRayHit()
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude
    rp.FilterDescendantsInstances = { brushBall, brushRing }

    local ray    = camera:ScreenPointToRay(mouse.X, mouse.Y)
    local result = workspace:Raycast(ray.Origin, ray.Direction * 2000, rp)
    return result and result.Position or nil
end

-- ─────────────────────────────────────────────────────────────
-- FUNÇÕES DE TERRAIN
-- ─────────────────────────────────────────────────────────────

local function paintAt(pos)
    local mat = mode == "Erase" and Enum.Material.Air or selectedMaterial
    local matN = mode == "Erase" and "Air" or selectedMatName

    local ok, err = pcall(function()
        terrain:FillBall(pos, brushRadius, mat)
    end)

    if ok and mode == "Add" then
        table.insert(terrainHistory, {
            pos    = pos,
            radius = brushRadius,
            mat    = matN,
        })
        if #terrainHistory > 2000 then table.remove(terrainHistory, 1) end
    elseif not ok then
        warn("[TE] FillBall: " .. tostring(err))
    end
end

-- ─────────────────────────────────────────────────────────────
-- SELEÇÃO VISUAL
-- ─────────────────────────────────────────────────────────────

local function clearSel()
    for _, p in ipairs(selParts) do pcall(function() p:Destroy() end) end
    selParts = {}
end

local function drawSelBox(p1, p2)
    clearSel()

    local halfH = fillHeight / 2
    local minV  = Vector3.new(
        math.min(p1.X, p2.X),
        math.min(p1.Y, p2.Y) - halfH,
        math.min(p1.Z, p2.Z)
    )
    local maxV = Vector3.new(
        math.max(p1.X, p2.X),
        math.max(p1.Y, p2.Y) + halfH,
        math.max(p1.Z, p2.Z)
    )

    local center = (minV + maxV) / 2
    local size   = maxV - minV

    local box = Instance.new("Part")
    box.Name         = "TE_SelBox"
    box.Size         = size
    box.CFrame       = CFrame.new(center)
    box.Anchored     = true
    box.CanCollide   = false
    box.Material     = Enum.Material.Neon
    box.Color        = Color3.fromRGB(140, 60, 240)
    box.Transparency = 0.92
    box.Parent       = workspace
    table.insert(selParts, box)

    local sel = Instance.new("SelectionBox")
    sel.Adornee             = box
    sel.Color3              = Color3.fromRGB(160, 80, 255)
    sel.LineThickness       = 0.07
    sel.SurfaceTransparency = 1
    sel.Parent              = workspace
    table.insert(selParts, sel)

    for _, pt in ipairs({ p1, p2 }) do
        local m = Instance.new("Part")
        m.Shape       = Enum.PartType.Ball
        m.Size        = Vector3.new(1.8, 1.8, 1.8)
        m.CFrame      = CFrame.new(pt)
        m.Anchored    = true
        m.CanCollide  = false
        m.Material    = Enum.Material.Neon
        m.Color       = Color3.fromRGB(200, 100, 255)
        m.Transparency = 0.15
        m.Parent      = workspace
        table.insert(selParts, m)
    end
end

-- ─────────────────────────────────────────────────────────────
-- NOTIFICAÇÃO
-- ─────────────────────────────────────────────────────────────

local function notif(msg, col)
    local ng = Instance.new("ScreenGui")
    ng.IgnoreGuiInset = true
    ng.Parent = player.PlayerGui

    local nf = makeFrame(UDim2.new(0, 300, 0, 42), UDim2.new(0.5, -150, 0, -55), C_TITLE, ng)
    corner(9, nf)

    local ns = Instance.new("UIStroke")
    ns.Color     = col or Color3.fromRGB(120, 50, 200)
    ns.Thickness = 1
    ns.Parent    = nf

    local nl = Instance.new("TextLabel")
    nl.Size             = UDim2.new(1, 0, 1, 0)
    nl.BackgroundTransparency = 1
    nl.Text             = msg
    nl.TextColor3       = C_TEXT
    nl.TextSize         = 11
    nl.Font             = Enum.Font.Gotham
    nl.Parent           = nf

    TweenService:Create(nf, TweenInfo.new(0.25, Enum.EasingStyle.Back),
        { Position = UDim2.new(0.5, -150, 0, 12) }):Play()

    game:GetService("Debris"):AddItem(ng, 3)
end

-- ─────────────────────────────────────────────────────────────
-- ESTADO — setters
-- ─────────────────────────────────────────────────────────────

local function setActive(v)
    active = v
    if active then
        activateBtn.Text             = "🔴  Desativar Editor"
        activateBtn.BackgroundColor3 = Color3.fromRGB(100, 20, 20)
        notif("✅ Editor ativado", Color3.fromRGB(60, 200, 60))
    else
        activateBtn.Text             = "🟢  Ativar Editor"
        activateBtn.BackgroundColor3 = C_BTN
        notif("⛔ Editor desativado", Color3.fromRGB(180, 50, 50))
    end
end

local function setMode(m)
    mode = m
    addBtn.BackgroundColor3   = m == "Add"   and C_BTN_ACT or C_BTN
    eraseBtn.BackgroundColor3 = m == "Erase" and Color3.fromRGB(100, 20, 20) or C_BTN
end

local function setRadius(r)
    brushRadius      = math.clamp(r, 2, 100)
    radDisp.Text     = tostring(brushRadius)
end

-- ─────────────────────────────────────────────────────────────
-- BOTÕES — EVENTOS
-- ─────────────────────────────────────────────────────────────

activateBtn.MouseButton1Click:Connect(function() setActive(not active) end)
addBtn.MouseButton1Click:Connect(function()     setMode("Add")         end)
eraseBtn.MouseButton1Click:Connect(function()   setMode("Erase")       end)
radMinBtn.MouseButton1Click:Connect(function()  setRadius(brushRadius - 2) end)
radPlusBtn.MouseButton1Click:Connect(function() setRadius(brushRadius + 2) end)

-- scroll do mouse
UserInputService.InputChanged:Connect(function(input)
    if not active then return end
    if input.UserInputType == Enum.UserInputType.MouseWheel then
        setRadius(brushRadius + (input.Position.Z > 0 and 2 or -2))
    end
end)

-- Selecionar Área
selAreaBtn.MouseButton1Click:Connect(function()
    selActive = not selActive
    selStep   = 0
    selP1     = nil
    selP2     = nil

    if selActive then
        selAreaBtn.Text             = "📐  Clique Ponto 1..."
        selAreaBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 10)
        clearSel()
    else
        selAreaBtn.Text             = "📐  Selecionar Área"
        selAreaBtn.BackgroundColor3 = C_BTN
        clearSel()
    end
end)

-- Preencher Área
fillAreaBtn.MouseButton1Click:Connect(function()
    if not selP1 or not selP2 then
        notif("⚠️ Selecione uma área primeiro!", Color3.fromRGB(200, 140, 20))
        return
    end

    local halfH = fillHeight / 2
    local p1 = Vector3.new(
        math.min(selP1.X, selP2.X),
        math.min(selP1.Y, selP2.Y) - halfH,
        math.min(selP1.Z, selP2.Z)
    )
    local p2 = Vector3.new(
        math.max(selP1.X, selP2.X),
        math.max(selP1.Y, selP2.Y) + halfH,
        math.max(selP1.Z, selP2.Z)
    )

    local ok, err = pcall(function()
        local region = Region3.new(p1, p2)
        terrain:FillRegion(region, 4, selectedMaterial)
    end)

    if ok then
        notif("🎨 Área preenchida com " .. selectedMatName .. "!", Color3.fromRGB(100, 50, 200))
        -- adicionar ao histórico como bloco
        table.insert(terrainHistory, {
            type    = "region",
            p1      = p1,
            p2      = p2,
            mat     = selectedMatName,
        })
    else
        notif("❌ Erro: " .. tostring(err), Color3.fromRGB(200, 40, 40))
    end
end)

-- ─────────────────────────────────────────────────────────────
-- EXPORT — gera script e salva com writefile
-- ─────────────────────────────────────────────────────────────

exportBtn.MouseButton1Click:Connect(function()
    if #terrainHistory == 0 then
        notif("⚠️ Nada para exportar ainda!", Color3.fromRGB(200, 140, 20))
        return
    end

    local fileName = (exportName ~= "" and exportName or "Terrain") .. ".lua"

    local lines = {
        "-- ╔════════════════════════════════════════╗",
        "-- ║  " .. exportName .. " — Terrain Editor v2.0 Export  ║",
        "-- ║  Colocar em: ServerScriptService       ║",
        "-- ╚════════════════════════════════════════╝",
        "",
        'local terrain = game:GetService("Workspace").Terrain',
        "",
        "-- Aguardar o jogo carregar",
        "game.Loaded:Wait()",
        "task.wait(1)",
        "",
        "-- ── Operações de Terrain ──────────────────",
        "",
    }

    for _, e in ipairs(terrainHistory) do
        if e.type == "region" then
            lines[#lines+1] = string.format(
                "terrain:FillBlock(\n\tCFrame.new(%g, %g, %g),\n\tVector3.new(%g, %g, %g),\n\tEnum.Material.%s\n)",
                (e.p1.X + e.p2.X)/2, (e.p1.Y + e.p2.Y)/2, (e.p1.Z + e.p2.Z)/2,
                e.p2.X - e.p1.X, e.p2.Y - e.p1.Y, e.p2.Z - e.p1.Z,
                e.mat
            )
        else
            lines[#lines+1] = string.format(
                "terrain:FillBall(Vector3.new(%g, %g, %g), %g, Enum.Material.%s)",
                e.pos.X, e.pos.Y, e.pos.Z, e.radius, e.mat
            )
        end
    end

    lines[#lines+1] = ""
    lines[#lines+1] = 'print("[' .. exportName .. '] Terrain carregado! (' .. #terrainHistory .. ' ops)")'

    local content = table.concat(lines, "\n")

    -- Tentar writefile (Delta executor)
    local saved = false
    if writefile then
        local ok, err = pcall(writefile, fileName, content)
        if ok then
            notif("✅ Salvo: " .. fileName, Color3.fromRGB(60, 200, 60))
            saved = true
        end
    end

    -- Fallback: janela de texto para copiar
    if not saved then
        local esg = Instance.new("ScreenGui")
        esg.IgnoreGuiInset = true
        esg.Parent = player.PlayerGui

        local ef = makeFrame(UDim2.new(0, 480, 0, 400), UDim2.new(0.5, -240, 0.5, -200), C_BG, esg)
        ef.Active    = true
        ef.Draggable = true
        corner(12, ef)

        local etitle = makeFrame(UDim2.new(1, 0, 0, 32), nil, C_TITLE, ef)
        corner(12, etitle)
        local etfix = makeFrame(UDim2.new(1,0,0,12), UDim2.new(0,0,1,-12), C_TITLE, etitle)
        local etlbl = Instance.new("TextLabel")
        etlbl.Size             = UDim2.new(1, 0, 1, 0)
        etlbl.BackgroundTransparency = 1
        etlbl.Text             = "📥  " .. fileName .. " — Copie o conteúdo"
        etlbl.TextColor3       = C_TEXT
        etlbl.TextSize         = 11
        etlbl.Font             = Enum.Font.GothamBold
        etlbl.Parent           = etitle

        local ebox = Instance.new("TextBox")
        ebox.Size             = UDim2.new(1, -16, 1, -80)
        ebox.Position         = UDim2.new(0, 8, 0, 38)
        ebox.BackgroundColor3 = Color3.fromRGB(18, 10, 32)
        ebox.BorderSizePixel  = 0
        ebox.Text             = content
        ebox.TextColor3       = Color3.fromRGB(120, 255, 160)
        ebox.TextSize         = 10
        ebox.Font             = Enum.Font.Code
        ebox.TextXAlignment   = Enum.TextXAlignment.Left
        ebox.TextYAlignment   = Enum.TextYAlignment.Top
        ebox.MultiLine        = true
        ebox.ClearTextOnFocus = false
        ebox.TextEditable     = false
        ebox.Parent           = ef
        corner(6, ebox)

        local closeBtn, _ = makeGBtn("✖  Fechar", 26, ef)
        closeBtn.Parent.Size     = UDim2.new(0, 100, 0, 26)
        closeBtn.Parent.Position = UDim2.new(1, -110, 1, -34)
        closeBtn.Parent.AnchorPoint = Vector2.new(0, 0)
        closeBtn.MouseButton1Click:Connect(function() esg:Destroy() end)
    end
end)

-- ─────────────────────────────────────────────────────────────
-- INPUT — detecção de click real vs arrasto
-- ─────────────────────────────────────────────────────────────

UserInputService.InputBegan:Connect(function(input, gpe)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    dragStart = Vector2.new(mouse.X, mouse.Y)
    dragged   = false
end)

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if dragStart then
            local delta = Vector2.new(mouse.X, mouse.Y) - dragStart
            if delta.Magnitude > DRAG_THRESH then
                dragged = true
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, gpe)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    local wasReal = not dragged
    dragStart = nil
    dragged   = false

    if not wasReal then return end -- arrasto → ignora
    if gpe then return end         -- clique em GUI → ignora

    -- ── Modo seleção ──────────────────────────────────────────
    if selActive then
        local hit = getRayHit()
        if not hit then return end

        if selStep == 0 then
            selP1  = hit
            selStep = 1
            selAreaBtn.Text = "📐  Clique Ponto 2..."
        else
            selP2    = hit
            selActive = false
            selStep   = 2
            selAreaBtn.Text             = "📐  Selecionar Área"
            selAreaBtn.BackgroundColor3 = C_BTN
            drawSelBox(selP1, selP2)
            notif("✅ Área selecionada! Use Preencher.", Color3.fromRGB(160, 80, 255))
        end
        return
    end

    -- ── Modo pintura ──────────────────────────────────────────
    if not active then return end

    local hit = getRayHit()
    if hit then
        paintAt(hit)
    end
end)

-- ─────────────────────────────────────────────────────────────
-- CLEANUP
-- ─────────────────────────────────────────────────────────────

player.CharacterRemoving:Connect(function()
    pcall(function() brushBall:Destroy() end)
    pcall(function() brushRing:Destroy() end)
    clearSel()
end)

-- ─────────────────────────────────────────────────────────────
-- INIT
-- ─────────────────────────────────────────────────────────────

setActive(false)
setMode("Add")
setRadius(10)

notif("⛰ Terrain Editor v2.0 carregado!", Color3.fromRGB(120, 50, 200))
print("[TerrainEditor v2.0] Pronto.")
