--[[
    DRadio GUI v4 - Custom UI
    Sem library externa, GUI propria
    Pequena, bonita, mobile-friendly
    Auto-atualiza listas a cada 10s
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local lp                = Players.LocalPlayer
local pg                = lp:WaitForChild("PlayerGui")

-- Respawn
local char = lp.Character or lp.CharacterAdded:Wait()
local hum  = char:WaitForChild("Humanoid")
lp.CharacterAdded:Connect(function(c) char=c; hum=c:WaitForChild("Humanoid") end)

-- ============================================================
-- CORES
-- ============================================================
local C = {
    bg       = Color3.fromRGB(15,  15,  20),
    panel    = Color3.fromRGB(22,  22,  30),
    card     = Color3.fromRGB(30,  30,  42),
    accent   = Color3.fromRGB(120, 80,  255),
    accent2  = Color3.fromRGB(80,  200, 255),
    green    = Color3.fromRGB(80,  220, 130),
    red      = Color3.fromRGB(255, 80,  80),
    text     = Color3.fromRGB(230, 230, 245),
    sub      = Color3.fromRGB(140, 140, 165),
    white    = Color3.fromRGB(255, 255, 255),
    black    = Color3.fromRGB(0,   0,   0),
    tabSel   = Color3.fromRGB(120, 80,  255),
    tabNorm  = Color3.fromRGB(30,  30,  42),
}

-- Skins reais do jogo (do arquivo rbxlx)
local SKINS = {
    { name="RadioMesh",    display="Padrão",  color=Color3.fromRGB(180,180,180) },
    { name="GoldBoombox",  display="Gold",    color=Color3.fromRGB(255,200,50)  },
    { name="NeonBoombox",  display="Neon",    color=Color3.fromRGB(50,255,150)  },
    { name="DiamondBoombox",display="Diamond",color=Color3.fromRGB(150,220,255) },
    { name="FireBoombox",  display="Fire",    color=Color3.fromRGB(255,100,40)  },
    { name="IceBoombox",   display="Ice",     color=Color3.fromRGB(120,200,255) },
    { name="RainbowBoombox",display="Rainbow",color=Color3.fromRGB(255,80,200)  },
    { name="GalaxyBoombox",display="Galaxy",  color=Color3.fromRGB(160,80,255)  },
}

-- ============================================================
-- HELPERS
-- ============================================================
local function tween(obj, props, t, style, dir)
    local info = TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
    TweenService:Create(obj, info, props):Play()
end

local function corner(obj, r)
    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = obj
end

local function stroke(obj, col, thick)
    local s = Instance.new("UIStroke"); s.Color = col or C.accent; s.Thickness = thick or 1.5; s.Parent = obj
end

local function label(parent, txt, sz, col, font)
    local l = Instance.new("TextLabel")
    l.Text = txt; l.TextSize = sz or 13
    l.TextColor3 = col or C.text
    l.Font = font or Enum.Font.GothamBold
    l.BackgroundTransparency = 1
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Size = UDim2.new(1,0,1,0)
    l.Parent = parent
    return l
end

local function notify(msg, col)
    -- Pequeno toast no canto
    local notifGui = Instance.new("ScreenGui")
    notifGui.Name = "DRadioNotif"
    notifGui.ResetOnSpawn = false
    notifGui.IgnoreGuiInset = true
    notifGui.Parent = pg

    local box = Instance.new("Frame")
    box.Size = UDim2.new(0, 200, 0, 36)
    box.Position = UDim2.new(0.5, -100, 1, -60)
    box.BackgroundColor3 = C.card
    box.BorderSizePixel = 0
    box.Parent = notifGui
    corner(box, 10)
    stroke(box, col or C.accent, 1.5)

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 4, 1, 0)
    bar.BackgroundColor3 = col or C.accent
    bar.BorderSizePixel = 0
    bar.Parent = box
    corner(bar, 4)

    local txt = Instance.new("TextLabel")
    txt.Size = UDim2.new(1,-12,1,0)
    txt.Position = UDim2.new(0,10,0,0)
    txt.BackgroundTransparency = 1
    txt.Text = msg
    txt.TextSize = 12
    txt.Font = Enum.Font.GothamBold
    txt.TextColor3 = C.text
    txt.TextXAlignment = Enum.TextXAlignment.Left
    txt.TextTruncate = Enum.TextTruncate.AtEnd
    txt.Parent = box

    tween(box, {Position = UDim2.new(0.5,-100,1,-100)}, 0.25, Enum.EasingStyle.Back)
    task.delay(2.5, function()
        tween(box, {Position = UDim2.new(0.5,-100,1,20)}, 0.2)
        task.wait(0.25)
        notifGui:Destroy()
    end)
end

local function safe(fn, successMsg)
    local ok, err = pcall(fn)
    if ok then
        if successMsg then notify(successMsg, C.green) end
    else
        notify("Erro: "..tostring(err):sub(1,40), C.red)
        warn("[DRadio] "..tostring(err))
    end
end

-- ============================================================
-- GUI PRINCIPAL
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "DRadioGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = pg

-- Janela principal: PEQUENA pra DPI baixa
local WIN_W, WIN_H = 280, 340
local main = Instance.new("Frame")
main.Name = "Main"
main.Size = UDim2.new(0, WIN_W, 0, WIN_H)
main.Position = UDim2.new(0.5, -WIN_W/2, 0.5, -WIN_H/2)
main.BackgroundColor3 = C.bg
main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Parent = gui
corner(main, 14)
stroke(main, C.accent, 1.5)

-- Sombra (frame escuro atrás)
local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(1, 12, 1, 12)
shadow.Position = UDim2.new(0,-6,0,6)
shadow.BackgroundColor3 = C.black
shadow.BackgroundTransparency = 0.6
shadow.BorderSizePixel = 0
shadow.ZIndex = main.ZIndex - 1
shadow.Parent = main
corner(shadow, 16)

-- ---- TOPBAR ----
local topbar = Instance.new("Frame")
topbar.Size = UDim2.new(1,0,0,34)
topbar.BackgroundColor3 = C.panel
topbar.BorderSizePixel = 0
topbar.Parent = main

local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(1,0,0,2)
accentLine.Position = UDim2.new(0,0,1,-2)
accentLine.BackgroundColor3 = C.accent
accentLine.BorderSizePixel = 0
accentLine.Parent = topbar

-- Gradiente na accent line
local grad = Instance.new("UIGradient")
grad.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, C.accent),
    ColorSequenceKeypoint.new(1, C.accent2)
}
grad.Parent = accentLine

local titleLbl = Instance.new("TextLabel")
titleLbl.Size = UDim2.new(1,-80,1,0)
titleLbl.Position = UDim2.new(0,12,0,0)
titleLbl.BackgroundTransparency = 1
titleLbl.Text = "DRadio Utils"
titleLbl.TextSize = 13
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextColor3 = C.white
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = topbar

-- Botao fechar
local btnClose = Instance.new("TextButton")
btnClose.Size = UDim2.new(0,28,0,22)
btnClose.Position = UDim2.new(1,-32,0.5,-11)
btnClose.BackgroundColor3 = C.red
btnClose.Text = "✕"
btnClose.TextSize = 11
btnClose.Font = Enum.Font.GothamBold
btnClose.TextColor3 = C.white
btnClose.BorderSizePixel = 0
btnClose.Parent = topbar
corner(btnClose, 6)

-- Botao minimizar
local isMin = false
local btnMin = Instance.new("TextButton")
btnMin.Size = UDim2.new(0,28,0,22)
btnMin.Position = UDim2.new(1,-64,0.5,-11)
btnMin.BackgroundColor3 = C.card
btnMin.Text = "−"
btnMin.TextSize = 13
btnMin.Font = Enum.Font.GothamBold
btnMin.TextColor3 = C.sub
btnMin.BorderSizePixel = 0
btnMin.Parent = topbar
corner(btnMin, 6)

-- Toggle abrir/fechar
local isOpen = true
btnClose.MouseButton1Click:Connect(function()
    isOpen = false
    tween(main, {Size=UDim2.new(0,WIN_W,0,0), Position=UDim2.new(0.5,-WIN_W/2,0.5,0)}, 0.2, Enum.EasingStyle.Quad)
    task.wait(0.22)
    main.Visible = false
end)

-- Botao flutuante pra reabrir
local fab = Instance.new("TextButton")
fab.Size = UDim2.new(0,44,0,44)
fab.Position = UDim2.new(0,10,0.5,-22)
fab.BackgroundColor3 = C.accent
fab.Text = "DR"
fab.TextSize = 12
fab.Font = Enum.Font.GothamBold
fab.TextColor3 = C.white
fab.BorderSizePixel = 0
fab.Visible = false
fab.Parent = gui
corner(fab, 22)
stroke(fab, C.accent2, 1.5)

btnClose.MouseButton1Click:Connect(function()
    task.wait(0.3)
    fab.Visible = true
end)
fab.MouseButton1Click:Connect(function()
    fab.Visible = false
    main.Visible = true
    isOpen = true
    tween(main, {Size=UDim2.new(0,WIN_W,0,WIN_H)}, 0.22, Enum.EasingStyle.Back)
end)

-- Minimizar
local contentFrame -- definido abaixo
btnMin.MouseButton1Click:Connect(function()
    isMin = not isMin
    if isMin then
        tween(main, {Size=UDim2.new(0,WIN_W,0,34)}, 0.2)
        btnMin.Text = "+"
    else
        tween(main, {Size=UDim2.new(0,WIN_W,0,WIN_H)}, 0.2, Enum.EasingStyle.Back)
        btnMin.Text = "−"
    end
end)

-- ---- ARRASTAR ----
local dragging, dragStart, startPos = false, nil, nil
topbar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging  = true
        dragStart = inp.Position
        startPos  = main.Position
    end
end)
topbar.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch) then
        local delta = inp.Position - dragStart
        main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- ============================================================
-- ABAS
-- ============================================================
local TABS = {"Boombox","Ferramentas","Servidor"}
local tabFrames = {}
local tabBtns   = {}

local tabBar = Instance.new("Frame")
tabBar.Size = UDim2.new(1,0,0,28)
tabBar.Position = UDim2.new(0,0,0,34)
tabBar.BackgroundColor3 = C.panel
tabBar.BorderSizePixel = 0
tabBar.Parent = main

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Padding = UDim.new(0,2)
tabLayout.Parent = tabBar

local tabPad = Instance.new("UIPadding")
tabPad.PaddingLeft = UDim.new(0,4)
tabPad.PaddingTop  = UDim.new(0,4)
tabPad.Parent = tabBar

-- Área de conteúdo
contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1,0,1,-62)
contentFrame.Position = UDim2.new(0,0,0,62)
contentFrame.BackgroundTransparency = 1
contentFrame.ClipsDescendants = true
contentFrame.Parent = main

local function makeScroll(parent)
    local s = Instance.new("ScrollingFrame")
    s.Size = UDim2.new(1,0,1,0)
    s.BackgroundTransparency = 1
    s.BorderSizePixel = 0
    s.ScrollBarThickness = 3
    s.ScrollBarImageColor3 = C.accent
    s.CanvasSize = UDim2.new(0,0,0,0)
    s.AutomaticCanvasSize = Enum.AutomaticSize.Y
    s.Parent = parent
    local l = Instance.new("UIListLayout")
    l.SortOrder = Enum.SortOrder.LayoutOrder
    l.Padding = UDim.new(0,5)
    l.Parent = s
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0,6); p.PaddingBottom = UDim.new(0,6)
    p.PaddingLeft = UDim.new(0,7); p.PaddingRight = UDim.new(0,7)
    p.Parent = s
    return s
end

for i, name in ipairs(TABS) do
    -- Tab button
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 82, 0, 22)
    btn.BackgroundColor3 = C.tabNorm
    btn.Text = name
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.TextColor3 = C.sub
    btn.BorderSizePixel = 0
    btn.LayoutOrder = i
    btn.Parent = tabBar
    corner(btn, 6)
    tabBtns[i] = btn

    -- Tab content
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundTransparency = 1
    frame.Visible = (i == 1)
    frame.Parent = contentFrame
    tabFrames[i] = frame
end

local currentTab = 1
local function selectTab(idx)
    currentTab = idx
    for i, f in ipairs(tabFrames) do
        f.Visible = (i == idx)
        local btn = tabBtns[i]
        if i == idx then
            tween(btn, {BackgroundColor3 = C.tabSel, TextColor3 = C.white}, 0.15)
        else
            tween(btn, {BackgroundColor3 = C.tabNorm, TextColor3 = C.sub}, 0.15)
        end
    end
end

for i, btn in ipairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() selectTab(i) end)
end
selectTab(1)

-- ============================================================
-- HELPER: CARD BOTAO
-- ============================================================
local function makeCardBtn(parent, text, subtext, acColor, order)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1,0,0,42)
    card.BackgroundColor3 = C.card
    card.BorderSizePixel = 0
    card.LayoutOrder = order or 1
    card.Parent = parent
    corner(card, 8)

    local leftBar = Instance.new("Frame")
    leftBar.Size = UDim2.new(0,3,0,26)
    leftBar.Position = UDim2.new(0,0,0.5,-13)
    leftBar.BackgroundColor3 = acColor or C.accent
    leftBar.BorderSizePixel = 0
    leftBar.Parent = card
    corner(leftBar, 2)

    local mainTxt = Instance.new("TextLabel")
    mainTxt.Size = UDim2.new(1,-50,0,18)
    mainTxt.Position = UDim2.new(0,10,0,6)
    mainTxt.BackgroundTransparency = 1
    mainTxt.Text = text
    mainTxt.TextSize = 12
    mainTxt.Font = Enum.Font.GothamBold
    mainTxt.TextColor3 = C.text
    mainTxt.TextXAlignment = Enum.TextXAlignment.Left
    mainTxt.TextTruncate = Enum.TextTruncate.AtEnd
    mainTxt.Parent = card

    if subtext and subtext ~= "" then
        local sub = Instance.new("TextLabel")
        sub.Size = UDim2.new(1,-50,0,14)
        sub.Position = UDim2.new(0,10,0,24)
        sub.BackgroundTransparency = 1
        sub.Text = subtext
        sub.TextSize = 10
        sub.Font = Enum.Font.Gotham
        sub.TextColor3 = C.sub
        sub.TextXAlignment = Enum.TextXAlignment.Left
        sub.TextTruncate = Enum.TextTruncate.AtEnd
        sub.Parent = card
    end

    -- Botao invisivel por cima
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1,0,1,0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = card

    -- Hover
    btn.MouseEnter:Connect(function()
        tween(card, {BackgroundColor3 = Color3.fromRGB(38,38,54)}, 0.1)
    end)
    btn.MouseLeave:Connect(function()
        tween(card, {BackgroundColor3 = C.card}, 0.1)
    end)
    btn.MouseButton1Down:Connect(function()
        tween(card, {BackgroundColor3 = Color3.fromRGB(45,45,65)}, 0.08)
    end)
    btn.MouseButton1Up:Connect(function()
        tween(card, {BackgroundColor3 = C.card}, 0.1)
    end)

    return btn, card
end

-- SECTION HEADER
local function makeSection(parent, text, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1,0,0,18)
    f.BackgroundTransparency = 1
    f.LayoutOrder = order or 0
    f.Parent = parent

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1,0,1,0)
    l.BackgroundTransparency = 1
    l.Text = text:upper()
    l.TextSize = 9
    l.Font = Enum.Font.GothamBold
    l.TextColor3 = C.accent
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    return f
end

-- ============================================================
-- ABA 1: BOOMBOX
-- ============================================================
local scrollBB = makeScroll(tabFrames[1])

makeSection(scrollBB, "● Skins do Rádio", 1)

-- Contador + botao atualizar
local skinHeaderF = Instance.new("Frame")
skinHeaderF.Size = UDim2.new(1,0,0,26)
skinHeaderF.BackgroundTransparency = 1
skinHeaderF.LayoutOrder = 2
skinHeaderF.Parent = scrollBB

local skinCountLbl = Instance.new("TextLabel")
skinCountLbl.Size = UDim2.new(0.65,0,1,0)
skinCountLbl.BackgroundTransparency = 1
skinCountLbl.Text = #SKINS .. " skins encontradas"
skinCountLbl.TextSize = 10
skinCountLbl.Font = Enum.Font.Gotham
skinCountLbl.TextColor3 = C.sub
skinCountLbl.TextXAlignment = Enum.TextXAlignment.Left
skinCountLbl.Parent = skinHeaderF

local timerLbl = Instance.new("TextLabel")
timerLbl.Size = UDim2.new(0.35,0,1,0)
timerLbl.Position = UDim2.new(0.65,0,0,0)
timerLbl.BackgroundTransparency = 1
timerLbl.Text = "↻ 10s"
timerLbl.TextSize = 9
timerLbl.Font = Enum.Font.Gotham
timerLbl.TextColor3 = C.sub
timerLbl.TextXAlignment = Enum.TextXAlignment.Right
timerLbl.Parent = skinHeaderF

-- Container pras skins
local skinContainer = Instance.new("Frame")
skinContainer.Size = UDim2.new(1,0,0,0)
skinContainer.AutomaticSize = Enum.AutomaticSize.Y
skinContainer.BackgroundTransparency = 1
skinContainer.LayoutOrder = 3
skinContainer.Parent = scrollBB

local skinLayout = Instance.new("UIListLayout")
skinLayout.SortOrder = Enum.SortOrder.LayoutOrder
skinLayout.Padding = UDim.new(0,5)
skinLayout.Parent = skinContainer

local function buildSkinList()
    -- Limpa
    for _, c in pairs(skinContainer:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    -- Tenta buscar skins reais do servidor
    local serverSkins = nil
    safe(function()
        local r = ReplicatedStorage:FindFirstChild("GetRadioSkins")
        if r and r:IsA("RemoteFunction") then
            local ok2, res = pcall(function() return r:InvokeServer() end)
            if ok2 and res and #res > 0 then
                serverSkins = res
            end
        end
    end)

    local listToUse = SKINS
    if serverSkins then
        listToUse = {}
        for _, v in ipairs(serverSkins) do
            local n = type(v)=="table" and (v.name or v.Name) or tostring(v)
            local d = type(v)=="table" and (v.displayName or v.name) or tostring(v)
            table.insert(listToUse, {name=n, display=d, color=C.accent})
        end
        skinCountLbl.Text = #listToUse .. " skins (servidor)"
    else
        skinCountLbl.Text = #SKINS .. " skins (local)"
    end

    for i, skin in ipairs(listToUse) do
        local sName    = type(skin)=="table" and skin.name    or skin
        local sDisplay = type(skin)=="table" and skin.display or skin
        local sColor   = type(skin)=="table" and (skin.color or C.accent) or C.accent

        local btn, card = makeCardBtn(skinContainer, sDisplay, sName, sColor, i)
        btn.MouseButton1Click:Connect(function()
            safe(function()
                local r = ReplicatedStorage:WaitForChild("EquipRadioSkin", 5)
                r:FireServer(sName)
            end, "Skin '"..sDisplay.."' equipada!")
        end)
    end
end

buildSkinList()

-- ============================================================
-- ABA 2: FERRAMENTAS (Tools no mapa)
-- ============================================================
local scrollTool = makeScroll(tabFrames[2])

makeSection(scrollTool, "● Tools no Mapa", 1)

local toolHeaderF = Instance.new("Frame")
toolHeaderF.Size = UDim2.new(1,0,0,26)
toolHeaderF.BackgroundTransparency = 1
toolHeaderF.LayoutOrder = 2
toolHeaderF.Parent = scrollTool

local toolCountLbl = Instance.new("TextLabel")
toolCountLbl.Size = UDim2.new(0.65,0,1,0)
toolCountLbl.BackgroundTransparency = 1
toolCountLbl.Text = "Buscando..."
toolCountLbl.TextSize = 10
toolCountLbl.Font = Enum.Font.Gotham
toolCountLbl.TextColor3 = C.sub
toolCountLbl.TextXAlignment = Enum.TextXAlignment.Left
toolCountLbl.Parent = toolHeaderF

local toolTimerLbl = Instance.new("TextLabel")
toolTimerLbl.Size = UDim2.new(0.35,0,1,0)
toolTimerLbl.Position = UDim2.new(0.65,0,0,0)
toolTimerLbl.BackgroundTransparency = 1
toolTimerLbl.Text = "↻ 10s"
toolTimerLbl.TextSize = 9
toolTimerLbl.Font = Enum.Font.Gotham
toolTimerLbl.TextColor3 = C.sub
toolTimerLbl.TextXAlignment = Enum.TextXAlignment.Right
toolTimerLbl.Parent = toolHeaderF

local toolContainer = Instance.new("Frame")
toolContainer.Size = UDim2.new(1,0,0,0)
toolContainer.AutomaticSize = Enum.AutomaticSize.Y
toolContainer.BackgroundTransparency = 1
toolContainer.LayoutOrder = 3
toolContainer.Parent = scrollTool

local toolLayout = Instance.new("UIListLayout")
toolLayout.SortOrder = Enum.SortOrder.LayoutOrder
toolLayout.Padding = UDim.new(0,5)
toolLayout.Parent = toolContainer

local function buildToolList()
    for _, c in pairs(toolContainer:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    -- Busca tools no Workspace E no ReplicatedStorage
    local found = {}
    local function scanForTools(obj, depth)
        if depth > 6 then return end
        for _, child in pairs(obj:GetChildren()) do
            if child:IsA("Tool") then
                -- evita duplicatas
                local key = child.Name
                if not found[key] then
                    found[key] = child
                end
            elseif not child:IsA("LocalScript") and not child:IsA("Script") then
                scanForTools(child, depth + 1)
            end
        end
    end

    pcall(function() scanForTools(game:GetService("Workspace"), 1) end)
    pcall(function() scanForTools(ReplicatedStorage, 1) end)
    pcall(function() scanForTools(lp.Backpack, 1) end)

    local list = {}
    for name, tool in pairs(found) do
        table.insert(list, {name=name, tool=tool})
    end
    table.sort(list, function(a,b) return a.name < b.name end)

    toolCountLbl.Text = #list .. " tool(s) encontrada(s)"

    if #list == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1,0,0,30)
        empty.BackgroundTransparency = 1
        empty.Text = "Nenhuma tool encontrada."
        empty.TextSize = 11
        empty.Font = Enum.Font.Gotham
        empty.TextColor3 = C.sub
        empty.TextXAlignment = Enum.TextXAlignment.Center
        empty.LayoutOrder = 1
        empty.Parent = toolContainer
        return
    end

    for i, item in ipairs(list) do
        local btn, card = makeCardBtn(toolContainer, item.name, "Tool", C.green, i)
        btn.MouseButton1Click:Connect(function()
            safe(function()
                -- Equipa a tool usando o remote Tool do jogo
                local toolRemote = ReplicatedStorage:FindFirstChild("Tool")
                if toolRemote and toolRemote:IsA("RemoteEvent") then
                    toolRemote:FireServer(item.name)
                    notify("Tool '"..item.name.."' ativada!", C.green)
                else
                    -- Fallback: move pra backpack
                    local clone = item.tool:Clone()
                    clone.Parent = lp.Backpack
                    notify("Tool '"..item.name.."' no Backpack!", C.green)
                end
            end)
        end)
    end
end

buildToolList()

-- ============================================================
-- ABA 3: SERVIDOR
-- ============================================================
local scrollSrv = makeScroll(tabFrames[3])

makeSection(scrollSrv, "● Jogadores Online", 1)

local srvHeaderF = Instance.new("Frame")
srvHeaderF.Size = UDim2.new(1,0,0,26)
srvHeaderF.BackgroundTransparency = 1
srvHeaderF.LayoutOrder = 2
srvHeaderF.Parent = scrollSrv

local srvCountLbl = Instance.new("TextLabel")
srvCountLbl.Size = UDim2.new(0.65,0,1,0)
srvCountLbl.BackgroundTransparency = 1
srvCountLbl.Text = "Carregando..."
srvCountLbl.TextSize = 10
srvCountLbl.Font = Enum.Font.Gotham
srvCountLbl.TextColor3 = C.sub
srvCountLbl.TextXAlignment = Enum.TextXAlignment.Left
srvCountLbl.Parent = srvHeaderF

local srvTimerLbl = Instance.new("TextLabel")
srvTimerLbl.Size = UDim2.new(0.35,0,1,0)
srvTimerLbl.Position = UDim2.new(0.65,0,0,0)
srvTimerLbl.BackgroundTransparency = 1
srvTimerLbl.Text = "↻ 10s"
srvTimerLbl.TextSize = 9
srvTimerLbl.Font = Enum.Font.Gotham
srvTimerLbl.TextColor3 = C.sub
srvTimerLbl.TextXAlignment = Enum.TextXAlignment.Right
srvTimerLbl.Parent = srvHeaderF

local srvContainer = Instance.new("Frame")
srvContainer.Size = UDim2.new(1,0,0,0)
srvContainer.AutomaticSize = Enum.AutomaticSize.Y
srvContainer.BackgroundTransparency = 1
srvContainer.LayoutOrder = 3
srvContainer.Parent = scrollSrv

local srvLayout = Instance.new("UIListLayout")
srvLayout.SortOrder = Enum.SortOrder.LayoutOrder
srvLayout.Padding = UDim.new(0,5)
srvLayout.Parent = srvContainer

local function buildServerList()
    for _, c in pairs(srvContainer:GetChildren()) do
        if c:IsA("Frame") then c:Destroy() end
    end

    local all = Players:GetPlayers()
    srvCountLbl.Text = #all .. " jogador(es) online"

    for i, p in ipairs(all) do
        local ping = math.floor(p:GetNetworkPing() * 1000)
        local pingColor = ping < 80 and C.green or ping < 200 and C.accent2 or C.red
        local pingText  = ping .. "ms"
        local isMe = (p == lp)

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1,0,0,40)
        card.BackgroundColor3 = isMe and Color3.fromRGB(30,30,50) or C.card
        card.BorderSizePixel = 0
        card.LayoutOrder = i
        card.Parent = srvContainer
        corner(card, 8)
        if isMe then stroke(card, C.accent, 1) end

        -- Ping dot
        local dot = Instance.new("Frame")
        dot.Size = UDim2.new(0,7,0,7)
        dot.Position = UDim2.new(0,8,0.5,-3.5)
        dot.BackgroundColor3 = pingColor
        dot.BorderSizePixel = 0
        dot.Parent = card
        corner(dot, 4)

        local nameLbl = Instance.new("TextLabel")
        nameLbl.Size = UDim2.new(1,-80,0,18)
        nameLbl.Position = UDim2.new(0,20,0,4)
        nameLbl.BackgroundTransparency = 1
        nameLbl.Text = p.Name .. (isMe and " (você)" or "")
        nameLbl.TextSize = 12
        nameLbl.Font = Enum.Font.GothamBold
        nameLbl.TextColor3 = isMe and C.accent2 or C.text
        nameLbl.TextXAlignment = Enum.TextXAlignment.Left
        nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
        nameLbl.Parent = card

        local pingLbl = Instance.new("TextLabel")
        pingLbl.Size = UDim2.new(0,55,0,14)
        pingLbl.Position = UDim2.new(1,-58,0,5)
        pingLbl.BackgroundTransparency = 1
        pingLbl.Text = pingText
        pingLbl.TextSize = 10
        pingLbl.Font = Enum.Font.GothamBold
        pingLbl.TextColor3 = pingColor
        pingLbl.TextXAlignment = Enum.TextXAlignment.Right
        pingLbl.Parent = card

        -- WalkSpeed
        local spd = ""
        local c2 = p.Character
        local h2 = c2 and c2:FindFirstChildOfClass("Humanoid")
        if h2 then
            spd = "Speed: " .. math.floor(h2.WalkSpeed)
            if h2.WalkSpeed > 20 then spd = spd .. " ⚠" end
        end

        local subLbl = Instance.new("TextLabel")
        subLbl.Size = UDim2.new(1,-80,0,14)
        subLbl.Position = UDim2.new(0,20,0,22)
        subLbl.BackgroundTransparency = 1
        subLbl.Text = spd ~= "" and spd or "ID: "..p.UserId
        subLbl.TextSize = 10
        subLbl.Font = Enum.Font.Gotham
        subLbl.TextColor3 = (h2 and h2.WalkSpeed > 20) and C.red or C.sub
        subLbl.TextXAlignment = Enum.TextXAlignment.Left
        subLbl.Parent = card
    end
end

buildServerList()

-- ============================================================
-- AUTO-ATUALIZAR A CADA 10 SEGUNDOS
-- ============================================================
local countdown = 10
local timerRunning = true

task.spawn(function()
    while timerRunning do
        for i = 10, 1, -1 do
            if not timerRunning then break end
            local txt = "↻ " .. i .. "s"
            -- Atualiza todos os timers
            pcall(function() timerLbl.Text     = txt end)
            pcall(function() toolTimerLbl.Text = txt end)
            pcall(function() srvTimerLbl.Text  = txt end)
            task.wait(1)
        end
        if not timerRunning then break end
        -- Reconstroi as listas
        pcall(buildSkinList)
        pcall(buildToolList)
        pcall(buildServerList)
    end
end)

-- Para o timer ao sair
gui.AncestryChanged:Connect(function()
    if not gui.Parent then timerRunning = false end
end)

-- ============================================================
-- ANIMACAO DE ENTRADA
-- ============================================================
main.Size = UDim2.new(0,WIN_W,0,0)
main.BackgroundTransparency = 1
tween(main, {Size = UDim2.new(0,WIN_W,0,WIN_H), BackgroundTransparency = 0}, 0.3, Enum.EasingStyle.Back)

notify("DRadio Utils carregado!", C.accent)
