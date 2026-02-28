--[[
    ╔══════════════════════════════════════════════╗
    ║         VFX LOADER - CODEX MOBILE            ║
    ║  Pasta: Codex > workspace > VFX > *.rbxm     ║
    ║  Por: Claude | Layout: Grid 3 Studs          ║
    ╚══════════════════════════════════════════════╝

    INSTRUÇÕES:
    1. Coloque seus arquivos .rbxm dentro de:
       Codex/workspace/VFX/
    2. Execute este script no Codex
    3. Use a GUI para visualizar e exportar as VFX
]]

-- ═══════════════════════════════════
--          CONFIGURAÇÕES
-- ═══════════════════════════════════
local CONFIG = {
    VFX_FOLDER_PATH = "VFX/",       -- Pasta dentro do workspace do Codex
    GRID_SPACING    = 3,             -- Studs de distância entre cada VFX
    GRID_COLUMNS    = 6,             -- Quantas colunas no grid
    BASE_POSITION   = Vector3.new(0, 5, 0), -- Onde começa o grid no mapa
    FOLDER_NAME     = "VFX_Pack",    -- Nome da pasta no Explorer
    GUI_TITLE       = "VFX Loader",
}

-- ═══════════════════════════════════
--         FUNÇÕES UTILITÁRIAS
-- ═══════════════════════════════════

-- Lê todos os arquivos .rbxm da pasta VFX
local function getVFXFiles()
    local files = {}
    local ok, result = pcall(function()
        -- listfiles é uma função do executor (UNC padrão)
        return listfiles(CONFIG.VFX_FOLDER_PATH)
    end)

    if not ok then
        -- Tenta caminho alternativo comum no Codex
        ok, result = pcall(function()
            return listfiles("workspace/VFX/")
        end)
    end

    if ok and result then
        for _, path in ipairs(result) do
            -- Filtra só .rbxm
            if path:match("%.rbxm$") or path:match("%.rbxmx$") then
                local name = path:match("([^/\\]+)%.rbxm") or path:match("([^/\\]+)%.rbxmx") or path
                table.insert(files, {
                    name = name,
                    path = path,
                    loaded = false,
                    instance = nil
                })
            end
        end
    end

    return files
end

-- Carrega um rbxm e retorna a instância
local function loadRBXM(path)
    local ok, result = pcall(function()
        -- readfile lê o binário, game:GetObjects desserializa
        local data = readfile(path)
        local objects = game:GetObjects("rbxm:" .. data)
        if objects and #objects > 0 then
            return objects[1]
        end
    end)

    if ok and result then
        return result
    end

    -- Fallback: tenta via loadstring/synasset se disponível
    local ok2, result2 = pcall(function()
        if syn and syn.deserialize then
            return syn.deserialize(readfile(path))
        end
    end)

    if ok2 and result2 then
        return result2
    end

    return nil
end

-- Calcula posição no grid
local function getGridPosition(index)
    local col = (index - 1) % CONFIG.GRID_COLUMNS
    local row = math.floor((index - 1) / CONFIG.GRID_COLUMNS)
    return CONFIG.BASE_POSITION + Vector3.new(
        col * CONFIG.GRID_SPACING,
        0,
        row * CONFIG.GRID_SPACING
    )
end

-- ═══════════════════════════════════
--       SISTEMA DE CARREGAMENTO
-- ═══════════════════════════════════

local vfxFolder = nil
local loadedVFX = {}

local function ensureFolder()
    if not vfxFolder or not vfxFolder.Parent then
        -- Cria pasta no Workspace
        local existing = workspace:FindFirstChild(CONFIG.FOLDER_NAME)
        if existing then existing:Destroy() end

        vfxFolder = Instance.new("Folder")
        vfxFolder.Name = CONFIG.FOLDER_NAME
        vfxFolder.Parent = workspace
    end
    return vfxFolder
end

local function loadVFX(fileInfo, index)
    if fileInfo.loaded and fileInfo.instance then
        return true, "Já carregado"
    end

    local obj = loadRBXM(fileInfo.path)
    if not obj then
        return false, "Falha ao ler o .rbxm"
    end

    local folder = ensureFolder()

    -- Cria sub-pasta com nome do arquivo
    local subFolder = Instance.new("Folder")
    subFolder.Name = fileInfo.name
    subFolder.Parent = folder

    -- Move objeto pra sub-pasta
    obj.Parent = subFolder

    -- Posiciona no grid (procura Parts/Models)
    local pos = getGridPosition(index)
    local function positionParts(parent, offset)
        for _, child in ipairs(parent:GetDescendants()) do
            if child:IsA("BasePart") then
                child.CFrame = CFrame.new(offset + child.Position - child.Position)
                child.Anchored = true
            elseif child:IsA("Model") and child.PrimaryPart then
                child:SetPrimaryPartCFrame(CFrame.new(offset))
            end
        end
        -- Se o objeto em si for um Model
        if parent:IsA("Model") and parent.PrimaryPart then
            parent:SetPrimaryPartCFrame(CFrame.new(pos))
        elseif parent:IsA("BasePart") then
            parent.CFrame = CFrame.new(pos)
            parent.Anchored = true
        end
    end

    positionParts(obj, pos)

    fileInfo.loaded = true
    fileInfo.instance = subFolder
    table.insert(loadedVFX, fileInfo)

    return true, "OK"
end

local function unloadVFX(fileInfo)
    if fileInfo.instance then
        fileInfo.instance:Destroy()
        fileInfo.instance = nil
    end
    fileInfo.loaded = false
    for i, v in ipairs(loadedVFX) do
        if v == fileInfo then
            table.remove(loadedVFX, i)
            break
        end
    end
end

local function loadAll(files, updateCallback)
    ensureFolder()
    for i, file in ipairs(files) do
        if not file.loaded then
            local ok, msg = loadVFX(file, i)
            if updateCallback then
                updateCallback(file, ok, msg)
            end
            task.wait(0.05) -- pequeno delay pra não travar
        end
    end
end

-- ═══════════════════════════════════
--              GUI
-- ═══════════════════════════════════

-- Remove GUI antiga se existir
local OLD_GUI = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("VFX_Loader_GUI")
if OLD_GUI then OLD_GUI:Destroy() end

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Criar ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "VFX_Loader_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 999
ScreenGui.IgnoreGuiInset = true
ScreenGui.Parent = PlayerGui

-- ── Janela Principal ──
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.new(0, 280, 0, 400)
Main.Position = UDim2.new(0.5, -140, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = ScreenGui

-- Borda arredondada
local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

-- Sombra
local Shadow = Instance.new("ImageLabel")
Shadow.Size = UDim2.new(1, 20, 1, 20)
Shadow.Position = UDim2.new(0, -10, 0, -10)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://5554236805"
Shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
Shadow.ImageTransparency = 0.5
Shadow.ScaleType = Enum.ScaleType.Slice
Shadow.SliceCenter = Rect.new(23, 23, 277, 277)
Shadow.ZIndex = -1
Shadow.Parent = Main

-- ── Header ──
local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 40)
Header.BackgroundColor3 = Color3.fromRGB(30, 80, 200)
Header.BorderSizePixel = 0
Header.Parent = Main

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 10)
HeaderCorner.Parent = Header

-- Fix: cobre cantos inferiores do header com rect
local HeaderFix = Instance.new("Frame")
HeaderFix.Size = UDim2.new(1, 0, 0, 10)
HeaderFix.Position = UDim2.new(0, 0, 1, -10)
HeaderFix.BackgroundColor3 = Color3.fromRGB(30, 80, 200)
HeaderFix.BorderSizePixel = 0
HeaderFix.Parent = Header

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -80, 1, 0)
TitleLabel.Position = UDim2.new(0, 10, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "🎆 " .. CONFIG.GUI_TITLE
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 14
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

-- Botão fechar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 13
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- Minimizar
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 30, 0, 30)
MinBtn.Position = UDim2.new(1, -70, 0, 5)
MinBtn.BackgroundColor3 = Color3.fromRGB(200, 160, 0)
MinBtn.Text = "–"
MinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MinBtn.TextSize = 16
MinBtn.Font = Enum.Font.GothamBold
MinBtn.BorderSizePixel = 0
MinBtn.Parent = Header

local MinCorner = Instance.new("UICorner")
MinCorner.CornerRadius = UDim.new(0, 6)
MinCorner.Parent = MinBtn

-- ── Status Bar ──
local StatusBar = Instance.new("Frame")
StatusBar.Size = UDim2.new(1, 0, 0, 26)
StatusBar.Position = UDim2.new(0, 0, 0, 40)
StatusBar.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
StatusBar.BorderSizePixel = 0
StatusBar.Parent = Main

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 1, 0)
StatusLabel.Position = UDim2.new(0, 8, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "📂 Pasta: Codex/workspace/VFX/"
StatusLabel.TextColor3 = Color3.fromRGB(120, 180, 255)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = StatusBar

-- ── Scroll de VFX ──
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -160)
ScrollFrame.Position = UDim2.new(0, 5, 0, 72)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 25)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 255)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = Main

local ScrollCorner = Instance.new("UICorner")
ScrollCorner.CornerRadius = UDim.new(0, 6)
ScrollCorner.Parent = ScrollFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.Padding = UDim.new(0, 3)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Parent = ScrollFrame

local ListPadding = Instance.new("UIPadding")
ListPadding.PaddingTop = UDim.new(0, 4)
ListPadding.PaddingLeft = UDim.new(0, 4)
ListPadding.PaddingRight = UDim.new(0, 4)
ListPadding.Parent = ScrollFrame

-- ── Botões de Ação ──
local BtnArea = Instance.new("Frame")
BtnArea.Size = UDim2.new(1, 0, 0, 80)
BtnArea.Position = UDim2.new(0, 0, 1, -80)
BtnArea.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
BtnArea.BorderSizePixel = 0
BtnArea.Parent = Main

local BtnLayout = Instance.new("UIListLayout")
BtnLayout.FillDirection = Enum.FillDirection.Horizontal
BtnLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
BtnLayout.VerticalAlignment = Enum.VerticalAlignment.Center
BtnLayout.Padding = UDim.new(0, 6)
BtnLayout.Parent = BtnArea

local function makeButton(txt, color)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 82, 0, 32)
    btn.BackgroundColor3 = color
    btn.Text = txt
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.BorderSizePixel = 0
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = btn
    btn.Parent = BtnArea
    return btn
end

local BtnLoadAll  = makeButton("⬇ Carregar Tudo",  Color3.fromRGB(30, 150, 60))
local BtnUnload   = makeButton("🗑 Limpar",         Color3.fromRGB(180, 60, 60))
local BtnRefresh  = makeButton("🔄 Atualizar",      Color3.fromRGB(60, 60, 180))

-- ── Drag (arrastar janela) ──
local dragging, dragStart, startPos
Header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = Main.Position
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.Touch or
                     input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch or
       input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- Minimizar/Maximizar
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        Main.Size = UDim2.new(0, 280, 0, 40)
        MinBtn.Text = "+"
    else
        Main.Size = UDim2.new(0, 280, 0, 400)
        MinBtn.Text = "–"
    end
end)

-- ═══════════════════════════════════
--       CRIAÇÃO DOS ITENS DA LISTA
-- ═══════════════════════════════════

local fileList = {}
local itemFrames = {}

local function setStatus(msg, color)
    StatusLabel.Text = msg
    StatusLabel.TextColor3 = color or Color3.fromRGB(120, 180, 255)
end

local function updateItem(fileInfo)
    local frame = itemFrames[fileInfo.name]
    if not frame then return end

    local statusDot = frame:FindFirstChild("StatusDot")
    local nameLabel = frame:FindFirstChild("NameLabel")
    local toggleBtn = frame:FindFirstChild("ToggleBtn")

    if fileInfo.loaded then
        if statusDot then statusDot.BackgroundColor3 = Color3.fromRGB(0, 220, 80) end
        if toggleBtn then toggleBtn.Text = "✕" toggleBtn.BackgroundColor3 = Color3.fromRGB(180,50,50) end
    else
        if statusDot then statusDot.BackgroundColor3 = Color3.fromRGB(80, 80, 80) end
        if toggleBtn then toggleBtn.Text = "▶" toggleBtn.BackgroundColor3 = Color3.fromRGB(30,120,200) end
    end
end

local function buildList(files)
    -- Limpa lista antiga
    for _, child in ipairs(ScrollFrame:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
    itemFrames = {}

    for i, file in ipairs(files) do
        local item = Instance.new("Frame")
        item.Name = file.name
        item.Size = UDim2.new(1, -8, 0, 36)
        item.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
        item.BorderSizePixel = 0
        item.LayoutOrder = i
        item.Parent = ScrollFrame

        local ItemCorner = Instance.new("UICorner")
        ItemCorner.CornerRadius = UDim.new(0, 6)
        ItemCorner.Parent = item

        -- Dot de status
        local dot = Instance.new("Frame")
        dot.Name = "StatusDot"
        dot.Size = UDim2.new(0, 8, 0, 8)
        dot.Position = UDim2.new(0, 8, 0.5, -4)
        dot.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        dot.BorderSizePixel = 0
        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot
        dot.Parent = item

        -- Ícone
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 20, 1, 0)
        icon.Position = UDim2.new(0, 18, 0, 0)
        icon.BackgroundTransparency = 1
        icon.Text = "🎆"
        icon.TextSize = 12
        icon.Font = Enum.Font.Gotham
        icon.TextColor3 = Color3.fromRGB(255, 200, 100)
        icon.Parent = item

        -- Nome
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Name = "NameLabel"
        nameLabel.Size = UDim2.new(1, -85, 1, 0)
        nameLabel.Position = UDim2.new(0, 40, 0, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = file.name
        nameLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
        nameLabel.TextSize = 11
        nameLabel.Font = Enum.Font.Gotham
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left
        nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
        nameLabel.Parent = item

        -- Botão toggle
        local toggleBtn = Instance.new("TextButton")
        toggleBtn.Name = "ToggleBtn"
        toggleBtn.Size = UDim2.new(0, 28, 0, 22)
        toggleBtn.Position = UDim2.new(1, -34, 0.5, -11)
        toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 120, 200)
        toggleBtn.Text = "▶"
        toggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggleBtn.TextSize = 11
        toggleBtn.Font = Enum.Font.GothamBold
        toggleBtn.BorderSizePixel = 0
        local toggleCorner = Instance.new("UICorner")
        toggleCorner.CornerRadius = UDim.new(0, 5)
        toggleCorner.Parent = toggleBtn
        toggleBtn.Parent = item

        -- Bind toggle
        local capturedFile = file
        local capturedIndex = i
        toggleBtn.MouseButton1Click:Connect(function()
            if capturedFile.loaded then
                unloadVFX(capturedFile)
                setStatus("❌ Removido: " .. capturedFile.name, Color3.fromRGB(255, 100, 100))
            else
                setStatus("⏳ Carregando: " .. capturedFile.name, Color3.fromRGB(255, 200, 80))
                local ok, msg = loadVFX(capturedFile, capturedIndex)
                if ok then
                    setStatus("✅ Carregado: " .. capturedFile.name, Color3.fromRGB(80, 255, 120))
                else
                    setStatus("❌ Erro: " .. msg, Color3.fromRGB(255, 80, 80))
                end
            end
            updateItem(capturedFile)
        end)

        itemFrames[file.name] = item
    end

    -- Ajusta canvas
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, #files * 39 + 8)
end

-- ═══════════════════════════════════
--         AÇÕES DOS BOTÕES
-- ═══════════════════════════════════

BtnRefresh.MouseButton1Click:Connect(function()
    setStatus("🔄 Escaneando pasta VFX...", Color3.fromRGB(100, 180, 255))
    task.wait(0.1)

    fileList = getVFXFiles()

    if #fileList == 0 then
        setStatus("⚠ Nenhum .rbxm encontrado em VFX/", Color3.fromRGB(255, 180, 50))
        buildList({})
        return
    end

    buildList(fileList)
    setStatus("📦 " .. #fileList .. " arquivo(s) encontrado(s)", Color3.fromRGB(80, 255, 150))
end)

BtnLoadAll.MouseButton1Click:Connect(function()
    if #fileList == 0 then
        setStatus("⚠ Clique em Atualizar primeiro!", Color3.fromRGB(255, 180, 50))
        return
    end

    setStatus("⏳ Carregando todos...", Color3.fromRGB(255, 200, 80))

    task.spawn(function()
        loadAll(fileList, function(file, ok, msg)
            updateItem(file)
            if ok then
                setStatus("✅ " .. file.name, Color3.fromRGB(80, 255, 120))
            else
                setStatus("❌ Falha: " .. file.name, Color3.fromRGB(255, 80, 80))
            end
        end)
        setStatus("🎆 Todos carregados! Pasta: " .. CONFIG.FOLDER_NAME, Color3.fromRGB(100, 255, 180))
    end)
end)

BtnUnload.MouseButton1Click:Connect(function()
    -- Limpa tudo
    for _, file in ipairs(fileList) do
        if file.loaded then
            unloadVFX(file)
            updateItem(file)
        end
    end

    if vfxFolder and vfxFolder.Parent then
        vfxFolder:Destroy()
        vfxFolder = nil
    end

    setStatus("🗑 Limpeza completa", Color3.fromRGB(255, 120, 120))
end)

-- ═══════════════════════════════════
--          INICIALIZAÇÃO
-- ═══════════════════════════════════

setStatus("📂 Pasta: Codex/workspace/VFX/")

-- Auto-scan ao iniciar
task.spawn(function()
    task.wait(0.5)
    fileList = getVFXFiles()

    if #fileList > 0 then
        buildList(fileList)
        setStatus("📦 " .. #fileList .. " arquivo(s) encontrado(s) | Clique ▶ ou Carregar Tudo", Color3.fromRGB(80, 255, 150))
    else
        buildList({})
        setStatus("⚠ Coloque .rbxm em Codex/workspace/VFX/ e clique Atualizar", Color3.fromRGB(255, 200, 80))
    end
end)

print("[VFX Loader] Script iniciado com sucesso!")
print("[VFX Loader] Pasta alvo: Codex/workspace/VFX/")
print("[VFX Loader] Pasta Explorer: workspace." .. CONFIG.FOLDER_NAME)
