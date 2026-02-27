--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║              RBXLX LOADER - by Script Pro                       ║
    ║   Lê arquivos .rbxlx da pasta Games e importa pro jogo         ║
    ║   Compatível: Codex Mobile · Studio Lite (Roblox)              ║
    ╚══════════════════════════════════════════════════════════════════╝

    COMO USAR:
    1. Execute este script uma vez → ele cria a pasta "Games" no Workspace do Codex
    2. Coloque seu arquivo .rbxlx dentro da pasta Games
       Caminho: /storage/emulated/0/Codex/Workspace/Games/seuarquivo.rbxlx
    3. Execute novamente → a GUI aparece com os arquivos disponíveis
    4. Clique no arquivo e depois em "📥 Importar"
    5. Tudo será recriado no jogo!
]]

-- ════════════════════════════════════
--         SERVIÇOS
-- ════════════════════════════════════
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local Workspace         = game:GetService("Workspace")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage     = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting          = game:GetService("Lighting")
local StarterGui        = game:GetService("StarterGui")
local StarterPack       = game:GetService("StarterPack")
local StarterPlayer     = game:GetService("StarterPlayer")
local SoundService      = game:GetService("SoundService")
local Teams             = game:GetService("Teams")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ════════════════════════════════════
--         CAMINHOS
-- ════════════════════════════════════
local CODEX_WORKSPACE = "Codex/Workspace/"
local GAMES_FOLDER    = CODEX_WORKSPACE .. "Games"
local GAMES_FOLDER_ALT = "Workspace/Games" -- fallback

-- ════════════════════════════════════
--         UTILITÁRIOS DE ARQUIVO
-- ════════════════════════════════════

local function safeReadFile(path)
    local ok, result = pcall(readfile, path)
    if ok then return result end
    return nil
end

local function safeListFiles(path)
    local ok, result = pcall(listfiles, path)
    if ok and result then return result end
    return {}
end

local function safeMakeFolder(path)
    local ok = pcall(makefolder, path)
    return ok
end

local function fileExists(path)
    local ok, result = pcall(isfile, path)
    return ok and result
end

local function folderExists(path)
    local ok, result = pcall(isfolder, path)
    return ok and result
end

-- ════════════════════════════════════
--     CRIAR PASTA GAMES SE N EXISTIR
-- ════════════════════════════════════
local gamesPath = nil

-- Tenta caminhos possíveis
local pathsToTry = {
    "Codex/Workspace/Games",
    "Workspace/Games",
    "Games",
}

for _, p in ipairs(pathsToTry) do
    if folderExists(p) then
        gamesPath = p
        break
    end
end

if not gamesPath then
    -- Tenta criar
    for _, p in ipairs(pathsToTry) do
        -- Cria pastas pai se necessário
        local parts = p:split("/")
        local current = ""
        for i, part in ipairs(parts) do
            current = i == 1 and part or (current .. "/" .. part)
            if not folderExists(current) then
                safeMakeFolder(current)
            end
        end
        if folderExists(p) then
            gamesPath = p
            break
        end
    end
end

if not gamesPath then
    gamesPath = "Games" -- último recurso
    safeMakeFolder(gamesPath)
end

print("[RBXLX Loader] Pasta Games: " .. gamesPath)

-- ════════════════════════════════════
--         PARSER XML COMPLETO
-- ════════════════════════════════════

-- Decodifica entidades HTML/XML
local function decodeXMLEntities(s)
    if not s then return "" end
    s = s:gsub("&amp;",  "&")
    s = s:gsub("&lt;",   "<")
    s = s:gsub("&gt;",   ">")
    s = s:gsub("&quot;", '"')
    s = s:gsub("&apos;", "'")
    s = s:gsub("&#(%d+);", function(n)
        return string.char(tonumber(n))
    end)
    return s
end

-- Extrai atributos de uma tag
local function parseAttributes(tagStr)
    local attrs = {}
    for key, val in tagStr:gmatch('(%w+)%s*=%s*"([^"]*)"') do
        attrs[key] = decodeXMLEntities(val)
    end
    for key, val in tagStr:gmatch("(%w+)%s*=%s*'([^']*)'") do
        attrs[key] = decodeXMLEntities(val)
    end
    return attrs
end

-- Parser XML simples e robusto (não depende de libs externas)
local function parseXML(xml)
    local root = {tag = "root", attrs = {}, children = {}, text = ""}
    local stack = {root}
    local pos = 1
    local len = #xml

    while pos <= len do
        -- Acha próxima tag
        local tagStart = xml:find("<", pos)
        if not tagStart then break end

        -- Texto antes da tag
        if tagStart > pos then
            local text = xml:sub(pos, tagStart - 1):gsub("^%s+", ""):gsub("%s+$", "")
            if text ~= "" and #stack > 0 then
                local current = stack[#stack]
                current.text = (current.text or "") .. decodeXMLEntities(text)
            end
        end

        -- Verifica tipo de tag
        local tagEnd = xml:find(">", tagStart)
        if not tagEnd then break end

        local tagContent = xml:sub(tagStart + 1, tagEnd - 1)
        pos = tagEnd + 1

        -- Comentário ou declaração XML
        if tagContent:sub(1, 1) == "!" or tagContent:sub(1, 1) == "?" then
            -- ignora
        -- Tag de fechamento
        elseif tagContent:sub(1, 1) == "/" then
            if #stack > 1 then
                table.remove(stack)
            end
        else
            -- Auto-fechada?
            local selfClose = tagContent:sub(-1) == "/"
            if selfClose then
                tagContent = tagContent:sub(1, -2)
            end

            -- Nome da tag
            local tagName = tagContent:match("^([%w:_%-]+)")
            if tagName then
                local attrsStr = tagContent:sub(#tagName + 1)
                local attrs = parseAttributes(attrsStr)

                local node = {
                    tag      = tagName,
                    attrs    = attrs,
                    children = {},
                    text     = ""
                }

                local current = stack[#stack]
                table.insert(current.children, node)

                if not selfClose then
                    table.insert(stack, node)
                end
            end
        end
    end

    return root
end

-- ════════════════════════════════════
--     MAPEAMENTO: CLASSE → SERVIÇO
-- ════════════════════════════════════
local serviceMap = {
    Workspace             = Workspace,
    ServerScriptService   = ServerScriptService,
    ServerStorage         = ServerStorage,
    ReplicatedStorage     = ReplicatedStorage,
    Lighting              = Lighting,
    StarterGui            = StarterGui,
    StarterPack           = StarterPack,
    StarterPlayer         = StarterPlayer,
    SoundService          = SoundService,
    Teams                 = Teams,
    Players               = Players,
}

-- Tenta pegar serviço com segurança
local function getService(name)
    local svc = serviceMap[name]
    if svc then return svc end
    local ok, s = pcall(game.GetService, game, name)
    if ok and s then return s end
    return nil
end

-- ════════════════════════════════════
--     CRIADOR DE INSTÂNCIAS
-- ════════════════════════════════════

-- Converte string de cor "R, G, B" para Color3
local function parseColor3(s)
    local r, g, b = s:match("([%d%.]+),%s*([%d%.]+),%s*([%d%.]+)")
    if r then
        return Color3.new(tonumber(r), tonumber(g), tonumber(b))
    end
    return Color3.new(1, 1, 1)
end

-- Converte string de vetor "X, Y, Z" para Vector3
local function parseVector3(s)
    local x, y, z = s:match("([%d%.%-]+),%s*([%d%.%-]+),%s*([%d%.%-]+)")
    if x then
        return Vector3.new(tonumber(x), tonumber(y), tonumber(z))
    end
    return Vector3.new(0, 0, 0)
end

-- CFrame a partir de componentes
local function parseCFrame(node)
    -- Tenta pegar os 12 componentes do CFrame
    local components = {}
    for _, child in ipairs(node.children) do
        if child.tag == "XmlElement" or child.tag:match("^X") or child.tag:match("^Y") or child.tag:match("^Z") then
            -- parse inline
        end
        -- Componentes são filhos com nome específico
        local num = tonumber(child.text)
        if num then
            table.insert(components, num)
        end
    end
    if #components >= 12 then
        return CFrame.new(
            components[1], components[2], components[3],
            components[4], components[5], components[6],
            components[7], components[8], components[9],
            components[10], components[11], components[12]
        )
    end
    -- Fallback: só posição
    if #components >= 3 then
        return CFrame.new(components[1], components[2], components[3])
    end
    return CFrame.new()
end

-- Aplica uma propriedade à instância
local function applyProperty(instance, propName, propType, propNode)
    local ok, err = pcall(function()
        local text = propNode.text or ""

        if propType == "string" or propType == "ProtectedString" then
            instance[propName] = decodeXMLEntities(text)

        elseif propType == "bool" then
            instance[propName] = (text:lower() == "true")

        elseif propType == "int" or propType == "int64" then
            instance[propName] = tonumber(text) or 0

        elseif propType == "float" or propType == "double" then
            instance[propName] = tonumber(text) or 0

        elseif propType == "Color3" or propType == "Color3uint8" then
            -- Pode estar como número inteiro ou como filhos R/G/B
            local rNode, gNode, bNode
            for _, c in ipairs(propNode.children) do
                if c.tag == "R" then rNode = c
                elseif c.tag == "G" then gNode = c
                elseif c.tag == "B" then bNode = c end
            end
            if rNode and gNode and bNode then
                if propType == "Color3uint8" then
                    instance[propName] = Color3.fromRGB(
                        tonumber(rNode.text) or 255,
                        tonumber(gNode.text) or 255,
                        tonumber(bNode.text) or 255
                    )
                else
                    instance[propName] = Color3.new(
                        tonumber(rNode.text) or 1,
                        tonumber(gNode.text) or 1,
                        tonumber(bNode.text) or 1
                    )
                end
            elseif text ~= "" then
                local num = tonumber(text)
                if num then
                    -- Packed RGB
                    local r = bit32.rshift(bit32.band(num, 0xFF0000), 16) / 255
                    local g = bit32.rshift(bit32.band(num, 0x00FF00), 8)  / 255
                    local b = bit32.band(num, 0x0000FF) / 255
                    instance[propName] = Color3.new(r, g, b)
                end
            end

        elseif propType == "Vector3" then
            local xN, yN, zN
            for _, c in ipairs(propNode.children) do
                if c.tag == "X" then xN = c
                elseif c.tag == "Y" then yN = c
                elseif c.tag == "Z" then zN = c end
            end
            if xN and yN and zN then
                instance[propName] = Vector3.new(
                    tonumber(xN.text) or 0,
                    tonumber(yN.text) or 0,
                    tonumber(zN.text) or 0
                )
            end

        elseif propType == "Vector2" then
            local xN, yN
            for _, c in ipairs(propNode.children) do
                if c.tag == "X" then xN = c
                elseif c.tag == "Y" then yN = c end
            end
            if xN and yN then
                instance[propName] = Vector2.new(
                    tonumber(xN.text) or 0,
                    tonumber(yN.text) or 0
                )
            end

        elseif propType == "CoordinateFrame" then
            instance[propName] = parseCFrame(propNode)

        elseif propType == "token" then
            -- Enum: precisa saber o tipo exato
            local num = tonumber(text)
            if num and propName == "Material" then
                instance[propName] = Enum.Material:GetEnumItems()[num + 1] or Enum.Material.Plastic
            end
            -- Outros enums: tenta setar direto
            if num then
                pcall(function()
                    instance[propName] = num
                end)
            end

        elseif propType == "Content" then
            instance[propName] = text

        elseif propType == "BrickColor" then
            local num = tonumber(text)
            if num then
                instance[propName] = BrickColor.new(num)
            end

        elseif propType == "UDim2" then
            local xS, xO, yS, yO
            for _, c in ipairs(propNode.children) do
                if c.tag == "XS" then xS = c
                elseif c.tag == "XO" then xO = c
                elseif c.tag == "YS" then yS = c
                elseif c.tag == "YO" then yO = c end
            end
            if xS and xO and yS and yO then
                instance[propName] = UDim2.new(
                    tonumber(xS.text) or 0, tonumber(xO.text) or 0,
                    tonumber(yS.text) or 0, tonumber(yO.text) or 0
                )
            end

        elseif propType == "Rect2D" then
            -- Pula por agora

        elseif propType == "PhysicalProperties" then
            -- CustomPhysics
            local custom
            for _, c in ipairs(propNode.children) do
                if c.tag == "CustomPhysics" then
                    custom = c.text == "true"
                end
            end
            -- Não aplica se não for custom

        elseif propType == "NumberSequence" then
            -- Pula (complexo)
        elseif propType == "ColorSequence" then
            -- Pula (complexo)
        elseif propType == "Faces" then
            -- Pula
        elseif propType == "Axes" then
            -- Pula
        end
    end)

    if not ok then
        -- Silenciosamente ignora propriedades que não consegue setar
    end
end

-- Cria uma instância a partir de um nó XML do rbxlx
local function createInstanceFromNode(itemNode, parent)
    local className = itemNode.attrs.class
    if not className then return nil end

    -- Ignora serviços (são criados separadamente)
    local isService = serviceMap[className] ~= nil

    local instance = nil

    if isService then
        instance = getService(className)
    else
        local ok, inst = pcall(Instance.new, className)
        if ok and inst then
            instance = inst
        else
            -- Classe desconhecida: cria uma pasta como substituto
            local folder = Instance.new("Folder")
            folder.Name = "[" .. className .. "]"
            if parent then
                pcall(function() folder.Parent = parent end)
            end
            -- Ainda processa filhos
            for _, child in ipairs(itemNode.children) do
                if child.tag == "Item" then
                    createInstanceFromNode(child, folder)
                end
            end
            return folder
        end
    end

    if not instance then return nil end

    -- Aplica propriedades
    for _, propGroup in ipairs(itemNode.children) do
        if propGroup.tag == "Properties" then
            for _, prop in ipairs(propGroup.children) do
                local propName = prop.attrs.name
                local propType = prop.tag
                if propName and propType then
                    applyProperty(instance, propName, propType, prop)
                end
            end
        end
    end

    -- Define parent (exceto serviços)
    if not isService and parent then
        pcall(function()
            instance.Parent = parent
        end)
    end

    -- Processa filhos recursivamente
    for _, child in ipairs(itemNode.children) do
        if child.tag == "Item" then
            createInstanceFromNode(child, instance)
        end
    end

    return instance
end

-- ════════════════════════════════════
--         IMPORTADOR PRINCIPAL
-- ════════════════════════════════════
local importLog = {}
local importCount = 0
local errorCount = 0

local function importRBXLX(filePath)
    importLog = {}
    importCount = 0
    errorCount = 0

    local content = safeReadFile(filePath)
    if not content then
        return false, "Não foi possível ler o arquivo: " .. filePath
    end

    local function log(msg)
        table.insert(importLog, msg)
        print("[RBXLX] " .. msg)
    end

    log("Lendo arquivo: " .. filePath)
    log("Tamanho: " .. #content .. " bytes")

    -- Parseia XML
    local ok, xmlTree = pcall(parseXML, content)
    if not ok then
        return false, "Erro ao parsear XML: " .. tostring(xmlTree)
    end

    log("XML parseado com sucesso!")

    -- Encontra o nó raiz do rbxlx (geralmente <roblox>)
    local robloxNode = nil
    for _, child in ipairs(xmlTree.children) do
        if child.tag == "roblox" then
            robloxNode = child
            break
        end
    end

    if not robloxNode then
        -- Tenta pegar o primeiro filho significativo
        robloxNode = xmlTree
        log("Aviso: nó <roblox> não encontrado, usando raiz")
    end

    -- Processa cada Item de nível superior
    local topLevelItems = {}
    for _, child in ipairs(robloxNode.children) do
        if child.tag == "Item" then
            table.insert(topLevelItems, child)
        end
    end

    log("Encontrados " .. #topLevelItems .. " objetos de nível superior")

    -- Cria pasta de importação no Workspace como fallback
    local importFolder = Instance.new("Folder")
    importFolder.Name = "📦 Importado_" .. os.time()
    importFolder.Parent = Workspace

    for _, itemNode in ipairs(topLevelItems) do
        local className = itemNode.attrs.class or "?"

        -- Tenta colocar no serviço correto
        local targetParent = nil
        local svc = getService(className)

        if svc then
            -- É um serviço, processa os filhos dentro dele
            log("Importando serviço: " .. className)
            for _, child in ipairs(itemNode.children) do
                if child.tag == "Item" then
                    local ok2, err2 = pcall(createInstanceFromNode, child, svc)
                    if ok2 then
                        importCount = importCount + 1
                    else
                        errorCount = errorCount + 1
                        log("Erro em filho de " .. className .. ": " .. tostring(err2))
                    end
                end
            end
        else
            -- Objeto normal → tenta criar
            local ok2, result = pcall(createInstanceFromNode, itemNode, importFolder)
            if ok2 and result then
                importCount = importCount + 1
                log("✅ Criado: " .. className .. " → " .. (result.Name or "?"))
            else
                errorCount = errorCount + 1
                log("❌ Erro: " .. className .. " → " .. tostring(result))
            end
        end
    end

    log("════════════════════════")
    log("✅ Importados: " .. importCount)
    log("❌ Erros: " .. errorCount)
    log("Pasta fallback: " .. importFolder.Name)

    return true, "Concluído! " .. importCount .. " objetos importados. " .. errorCount .. " erros."
end

-- ════════════════════════════════════
--         SCANNER DE ARQUIVOS
-- ════════════════════════════════════
local function getGameFiles()
    local files = safeListFiles(gamesPath)
    local rbxlxFiles = {}
    for _, f in ipairs(files) do
        local name = tostring(f)
        -- Normaliza separador
        name = name:gsub("\\", "/")
        local shortName = name:match("([^/]+)$") or name
        if shortName:lower():match("%.rbxlx$") or shortName:lower():match("%.rbxl$") then
            table.insert(rbxlxFiles, {path = name, name = shortName})
        end
    end
    return rbxlxFiles
end

-- ════════════════════════════════════
--              GUI
-- ════════════════════════════════════

-- Remove GUI antiga
local oldGui = PlayerGui:FindFirstChild("RBXLXLoaderGUI")
if oldGui then oldGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RBXLXLoaderGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = PlayerGui

-- ════ JANELA PRINCIPAL ════
local MainFrame = Instance.new("Frame")
MainFrame.Name = "Main"
MainFrame.Size = UDim2.new(0, 360, 0, 560)
MainFrame.Position = UDim2.new(0.5, -180, 0.5, -280)
MainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 20)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(80, 150, 255)
mainStroke.Thickness = 2
mainStroke.Parent = MainFrame

-- Gradiente fundo
local mainGrad = Instance.new("UIGradient")
mainGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 16, 35)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 8, 18))
})
mainGrad.Rotation = 145
mainGrad.Parent = MainFrame

-- ════ TOPBAR ════
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 58)
TopBar.BackgroundColor3 = Color3.fromRGB(25, 20, 55)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 16)
topCorner.Parent = TopBar

local topGrad = Instance.new("UIGradient")
topGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 100, 220)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 50, 140))
})
topGrad.Rotation = 90
topGrad.Parent = TopBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(1, -55, 0, 30)
TitleLabel.Position = UDim2.new(0, 15, 0, 7)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "📦 RBXLX Loader"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 18
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local SubLabel = Instance.new("TextLabel")
SubLabel.Size = UDim2.new(1, -55, 0, 18)
SubLabel.Position = UDim2.new(0, 15, 0, 37)
SubLabel.BackgroundTransparency = 1
SubLabel.Text = gamesPath
SubLabel.TextColor3 = Color3.fromRGB(120, 170, 255)
SubLabel.TextSize = 10
SubLabel.Font = Enum.Font.Gotham
SubLabel.TextXAlignment = Enum.TextXAlignment.Left
SubLabel.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 36, 0, 36)
CloseBtn.Position = UDim2.new(1, -46, 0, 11)
CloseBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 80)
CloseBtn.Text = "✕"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 16
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.BorderSizePixel = 0
CloseBtn.Parent = MainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = CloseBtn

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- ════ INFO PATH ════
local PathLabel = Instance.new("TextLabel")
PathLabel.Size = UDim2.new(1, -20, 0, 30)
PathLabel.Position = UDim2.new(0, 10, 0, 60)
PathLabel.BackgroundColor3 = Color3.fromRGB(20, 40, 20)
PathLabel.BackgroundTransparency = 0
PathLabel.Text = "📁 Coloque .rbxlx em: Codex/Workspace/Games/"
PathLabel.TextColor3 = Color3.fromRGB(120, 220, 120)
PathLabel.TextSize = 10
PathLabel.Font = Enum.Font.Gotham
PathLabel.TextWrapped = true
PathLabel.BorderSizePixel = 0
PathLabel.Parent = MainFrame

local pathCorner = Instance.new("UICorner")
pathCorner.CornerRadius = UDim.new(0, 8)
pathCorner.Parent = PathLabel

-- ════ LISTA DE ARQUIVOS ════
local ListTitle = Instance.new("TextLabel")
ListTitle.Size = UDim2.new(1, -20, 0, 22)
ListTitle.Position = UDim2.new(0, 15, 0, 98)
ListTitle.BackgroundTransparency = 1
ListTitle.Text = "🗂️  ARQUIVOS DISPONÍVEIS"
ListTitle.TextColor3 = Color3.fromRGB(100, 150, 255)
ListTitle.TextSize = 12
ListTitle.Font = Enum.Font.GothamBold
ListTitle.TextXAlignment = Enum.TextXAlignment.Left
ListTitle.Parent = MainFrame

-- ScrollingFrame para lista de arquivos
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -20, 0, 220)
ScrollFrame.Position = UDim2.new(0, 10, 0, 123)
ScrollFrame.BackgroundColor3 = Color3.fromRGB(8, 8, 18)
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(80, 120, 255)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.Parent = MainFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 10)
scrollCorner.Parent = ScrollFrame

local scrollStroke = Instance.new("UIStroke")
scrollStroke.Color = Color3.fromRGB(40, 60, 120)
scrollStroke.Thickness = 1
scrollStroke.Parent = ScrollFrame

local ListLayout = Instance.new("UIListLayout")
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding = UDim.new(0, 4)
ListLayout.Parent = ScrollFrame

local ListPadding = Instance.new("UIPadding")
ListPadding.PaddingTop = UDim.new(0, 6)
ListPadding.PaddingLeft = UDim.new(0, 6)
ListPadding.PaddingRight = UDim.new(0, 6)
ListPadding.Parent = ScrollFrame

-- ════ SELEÇÃO ATUAL ════
local selectedFile = nil
local selectedBtn = nil

local SelectedLabel = Instance.new("TextLabel")
SelectedLabel.Size = UDim2.new(1, -20, 0, 32)
SelectedLabel.Position = UDim2.new(0, 10, 0, 350)
SelectedLabel.BackgroundColor3 = Color3.fromRGB(15, 25, 45)
SelectedLabel.BackgroundTransparency = 0
SelectedLabel.Text = "Nenhum arquivo selecionado"
SelectedLabel.TextColor3 = Color3.fromRGB(100, 120, 180)
SelectedLabel.TextSize = 11
SelectedLabel.Font = Enum.Font.Gotham
SelectedLabel.TextWrapped = true
SelectedLabel.BorderSizePixel = 0
SelectedLabel.Parent = MainFrame

local selCorner = Instance.new("UICorner")
selCorner.CornerRadius = UDim.new(0, 8)
selCorner.Parent = SelectedLabel

-- ════ STATUS ════
local StatusFrame = Instance.new("Frame")
StatusFrame.Size = UDim2.new(1, -20, 0, 50)
StatusFrame.Position = UDim2.new(0, 10, 0, 390)
StatusFrame.BackgroundColor3 = Color3.fromRGB(15, 20, 35)
StatusFrame.BorderSizePixel = 0
StatusFrame.Parent = MainFrame

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 10)
statusCorner.Parent = StatusFrame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Size = UDim2.new(1, -10, 1, 0)
StatusLabel.Position = UDim2.new(0, 8, 0, 0)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Text = "⏳ Pronto. Selecione um arquivo e importe."
StatusLabel.TextColor3 = Color3.fromRGB(150, 180, 255)
StatusLabel.TextSize = 10
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextWrapped = true
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.TextYAlignment = Enum.TextYAlignment.Center
StatusLabel.Parent = StatusFrame

local function setStatus(msg, color)
    StatusLabel.Text = msg
    StatusLabel.TextColor3 = color or Color3.fromRGB(150, 180, 255)
end

-- ════ BOTÕES ════
local ImportBtn = Instance.new("TextButton")
ImportBtn.Size = UDim2.new(0.63, -5, 0, 50)
ImportBtn.Position = UDim2.new(0, 10, 0, 450)
ImportBtn.BackgroundColor3 = Color3.fromRGB(40, 100, 220)
ImportBtn.Text = "📥  IMPORTAR"
ImportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ImportBtn.TextSize = 15
ImportBtn.Font = Enum.Font.GothamBold
ImportBtn.BorderSizePixel = 0
ImportBtn.Parent = MainFrame

local impCorner = Instance.new("UICorner")
impCorner.CornerRadius = UDim.new(0, 12)
impCorner.Parent = ImportBtn

local impGrad = Instance.new("UIGradient")
impGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(60, 140, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 80, 200))
})
impGrad.Rotation = 90
impGrad.Parent = ImportBtn

local RefreshBtn = Instance.new("TextButton")
RefreshBtn.Size = UDim2.new(0.37, -15, 0, 50)
RefreshBtn.Position = UDim2.new(0.63, 5, 0, 450)
RefreshBtn.BackgroundColor3 = Color3.fromRGB(35, 45, 80)
RefreshBtn.Text = "🔄 Atualizar"
RefreshBtn.TextColor3 = Color3.fromRGB(150, 180, 255)
RefreshBtn.TextSize = 12
RefreshBtn.Font = Enum.Font.GothamBold
RefreshBtn.BorderSizePixel = 0
RefreshBtn.Parent = MainFrame

local refCorner = Instance.new("UICorner")
refCorner.CornerRadius = UDim.new(0, 12)
refCorner.Parent = RefreshBtn

-- ════════════════════════════════════
--     POPULA LISTA DE ARQUIVOS
-- ════════════════════════════════════
local function populateFileList()
    -- Limpa lista atual
    for _, child in ipairs(ScrollFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            child:Destroy()
        end
    end
    selectedFile = nil
    selectedBtn = nil
    SelectedLabel.Text = "Nenhum arquivo selecionado"

    local files = getGameFiles()

    if #files == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1, 0, 0, 60)
        empty.BackgroundTransparency = 1
        empty.Text = "⚠️ Nenhum .rbxlx encontrado\nem " .. gamesPath
        empty.TextColor3 = Color3.fromRGB(180, 140, 60)
        empty.TextSize = 12
        empty.Font = Enum.Font.Gotham
        empty.TextWrapped = true
        empty.Parent = ScrollFrame
        ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 70)
        setStatus("📭 Pasta vazia. Adicione arquivos .rbxlx em:\n" .. gamesPath, Color3.fromRGB(255, 200, 80))
        return
    end

    local totalHeight = 8
    for i, fileInfo in ipairs(files) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, 46)
        btn.BackgroundColor3 = Color3.fromRGB(20, 28, 55)
        btn.BorderSizePixel = 0
        btn.LayoutOrder = i
        btn.AutoButtonColor = false
        btn.Parent = ScrollFrame

        local bCorner = Instance.new("UICorner")
        bCorner.CornerRadius = UDim.new(0, 8)
        bCorner.Parent = btn

        local bStroke = Instance.new("UIStroke")
        bStroke.Color = Color3.fromRGB(40, 60, 120)
        bStroke.Thickness = 1
        bStroke.Parent = btn

        -- Ícone
        local icon = Instance.new("TextLabel")
        icon.Size = UDim2.new(0, 36, 1, 0)
        icon.Position = UDim2.new(0, 8, 0, 0)
        icon.BackgroundTransparency = 1
        icon.Text = "📄"
        icon.TextSize = 20
        icon.Font = Enum.Font.Gotham
        icon.Parent = btn

        -- Nome arquivo
        local nameL = Instance.new("TextLabel")
        nameL.Size = UDim2.new(1, -55, 0, 24)
        nameL.Position = UDim2.new(0, 46, 0, 5)
        nameL.BackgroundTransparency = 1
        nameL.Text = fileInfo.name
        nameL.TextColor3 = Color3.fromRGB(220, 230, 255)
        nameL.TextSize = 12
        nameL.Font = Enum.Font.GothamBold
        nameL.TextXAlignment = Enum.TextXAlignment.Left
        nameL.TextTruncate = Enum.TextTruncate.AtEnd
        nameL.Parent = btn

        -- Caminho
        local pathL = Instance.new("TextLabel")
        pathL.Size = UDim2.new(1, -55, 0, 16)
        pathL.Position = UDim2.new(0, 46, 0, 27)
        pathL.BackgroundTransparency = 1
        pathL.Text = fileInfo.path
        pathL.TextColor3 = Color3.fromRGB(100, 120, 180)
        pathL.TextSize = 9
        pathL.Font = Enum.Font.Gotham
        pathL.TextXAlignment = Enum.TextXAlignment.Left
        pathL.TextTruncate = Enum.TextTruncate.AtEnd
        pathL.Parent = btn

        totalHeight = totalHeight + 50

        -- Seleção
        btn.MouseButton1Click:Connect(function()
            -- Deseleciona anterior
            if selectedBtn then
                TweenService:Create(selectedBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(20, 28, 55)}):Play()
                for _, s in ipairs(selectedBtn:GetChildren()) do
                    if s:IsA("UIStroke") then
                        s.Color = Color3.fromRGB(40, 60, 120)
                    end
                end
            end

            selectedFile = fileInfo
            selectedBtn = btn

            TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(30, 60, 140)}):Play()
            for _, s in ipairs(btn:GetChildren()) do
                if s:IsA("UIStroke") then
                    s.Color = Color3.fromRGB(80, 140, 255)
                end
            end

            SelectedLabel.Text = "✅ Selecionado: " .. fileInfo.name
            SelectedLabel.TextColor3 = Color3.fromRGB(100, 220, 150)
            setStatus("Pronto para importar: " .. fileInfo.name, Color3.fromRGB(100, 200, 255))
        end)
    end

    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)
    setStatus("🗂️ " .. #files .. " arquivo(s) encontrado(s). Selecione um.", Color3.fromRGB(150, 200, 255))
end

-- ════════════════════════════════════
--         LÓGICA DOS BOTÕES
-- ════════════════════════════════════

RefreshBtn.MouseButton1Click:Connect(function()
    setStatus("🔄 Atualizando lista...", Color3.fromRGB(200, 200, 100))
    populateFileList()
end)

ImportBtn.MouseButton1Click:Connect(function()
    if not selectedFile then
        setStatus("⚠️ Selecione um arquivo primeiro!", Color3.fromRGB(255, 200, 50))
        TweenService:Create(ImportBtn, TweenInfo.new(0.05), {BackgroundColor3 = Color3.fromRGB(180, 80, 30)}):Play()
        task.delay(0.3, function()
            TweenService:Create(ImportBtn, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(40, 100, 220)}):Play()
        end)
        return
    end

    -- Anima botão
    TweenService:Create(ImportBtn, TweenInfo.new(0.1), {Size = UDim2.new(0.63, -5, 0, 44)}):Play()
    task.delay(0.1, function()
        TweenService:Create(ImportBtn, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = UDim2.new(0.63, -5, 0, 50)}):Play()
    end)

    ImportBtn.Text = "⏳ Importando..."
    ImportBtn.Active = false

    setStatus("⚙️ Importando " .. selectedFile.name .. "...", Color3.fromRGB(255, 220, 80))

    task.spawn(function()
        local ok, msg = importRBXLX(selectedFile.path)

        task.wait(0.1) -- UI atualiza

        ImportBtn.Text = "📥  IMPORTAR"
        ImportBtn.Active = true

        if ok then
            setStatus("✅ " .. msg, Color3.fromRGB(100, 255, 150))
            TweenService:Create(StatusFrame, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(15, 40, 20)}):Play()
            task.delay(2, function()
                TweenService:Create(StatusFrame, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(15, 20, 35)}):Play()
            end)
        else
            setStatus("❌ " .. msg, Color3.fromRGB(255, 100, 100))
        end
    end)
end)

-- ════════════════════════════════════
--         ANIMAÇÃO ENTRADA
-- ════════════════════════════════════
MainFrame.Position = UDim2.new(0.5, -180, -0.6, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, -180, 0.5, -280)
}):Play()

-- Stroke animado
local hue = 0.6
RunService.Heartbeat:Connect(function(dt)
    if not MainFrame.Parent then return end
    hue = (hue + dt * 0.2) % 1
    mainStroke.Color = Color3.fromHSV(hue, 0.8, 1)
end)

-- ════════════════════════════════════
--         INICIALIZAÇÃO
-- ════════════════════════════════════
task.wait(0.3)
populateFileList()

print([[
╔══════════════════════════════════════╗
║        RBXLX Loader - CARREGADO      ║
║  Pasta criada: ]] .. gamesPath .. [[
║  Coloque .rbxlx lá e clique Importar ║
╚══════════════════════════════════════╝
]])
