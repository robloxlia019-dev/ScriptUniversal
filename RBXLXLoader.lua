--[[
    ╔══════════════════════════════════════════════════════════╗
    ║             RBXLX LOADER v2 - Corrigido                 ║
    ║   Codex Mobile · Studio Lite · Android                  ║
    ╠══════════════════════════════════════════════════════════╣
    ║  COMO USAR:                                             ║
    ║  1. Execute → cria pasta "Games" no Workspace do Codex  ║
    ║  2. Abra gerenciador de arquivos do celular             ║
    ║  3. Vá em: Codex > Workspace > Games                   ║
    ║  4. Cole seu arquivo .rbxlx lá dentro                   ║
    ║  5. Execute o script de novo → GUI aparece              ║
    ║  6. Selecione o arquivo → clique Importar               ║
    ╚══════════════════════════════════════════════════════════╝
]]

-- ══════════════════════════════════
--   PASSO 1: DIAGNÓSTICO DO SISTEMA
-- ══════════════════════════════════
-- Identifica quais funções de filesystem estão disponíveis
local fs = {
    read     = readfile      or nil,
    write    = writefile     or nil,
    list     = listfiles     or nil,
    mkdir    = makefolder    or nil,
    isfile   = isfile        or nil,
    isfolder = isfolder      or nil,
    delfile  = delfile       or nil,
    append   = appendfile    or nil,
}

-- Verifica se tem filesystem mínimo
local hasFSBasic = fs.read and fs.list and fs.mkdir

print("=== RBXLX Loader - Diagnóstico ===")
print("readfile:   ", fs.read    and "✅" or "❌")
print("writefile:  ", fs.write   and "✅" or "❌")
print("listfiles:  ", fs.list    and "✅" or "❌")
print("makefolder: ", fs.mkdir   and "✅" or "❌")
print("isfile:     ", fs.isfile  and "✅" or "❌")
print("isfolder:   ", fs.isfolder and "✅" or "❌")

-- ══════════════════════════════════
--   PASSO 2: CRIAR PASTA GAMES
-- ══════════════════════════════════
-- No executor, makefolder("Games") cria dentro do Workspace do executor
-- Não precisa de path absoluto!

local FOLDER_NAME = "Games"
local folderCreated = false
local folderPath = FOLDER_NAME -- path relativo usado nas funções

-- Verifica se a pasta já existe tentando listar ela
-- (mais confiável que isfolder, que nem sempre está disponível)
if fs.mkdir then
    local jaExiste = false

    -- Método 1: isfolder
    if fs.isfolder then
        local ok, result = pcall(fs.isfolder, FOLDER_NAME)
        if ok and result then jaExiste = true end
    end

    -- Método 2: tenta listfiles — se não der erro, a pasta existe
    if not jaExiste and fs.list then
        local ok, _ = pcall(fs.list, FOLDER_NAME)
        if ok then jaExiste = true end
    end

    if jaExiste then
        print("✅ Pasta 'Games' já existe, pulando criação.")
        folderCreated = true
    else
        local ok, err = pcall(fs.mkdir, FOLDER_NAME)
        if ok then
            print("✅ Pasta 'Games' criada no Workspace do Codex!")
            folderCreated = true
        else
            print("⚠️ makefolder erro: " .. tostring(err))
        end
    end
else
    print("❌ makefolder não disponível neste executor")
end

-- ══════════════════════════════════
--   PASSO 3: LISTAR ARQUIVOS
-- ══════════════════════════════════
local function getFiles()
    local found = {}
    if not fs.list then return found end

    -- listfiles retorna caminhos completos no Android
    -- ex: /storage/emulated/0/Codex/Workspace/Games/mapa.rbxlx
    local ok, files = pcall(fs.list, FOLDER_NAME)
    if not ok or not files then
        print("listfiles falhou: " .. tostring(files))
        return found
    end

    for _, fullPath in ipairs(files) do
        local path = tostring(fullPath)
        -- Normaliza separadores
        path = path:gsub("\\", "/")
        -- Pega o nome do arquivo (último segmento)
        local name = path:match("([^/]+)$") or path
        local ext  = name:lower():match("%.([^%.]+)$") or ""

        if ext == "rbxlx" or ext == "rbxl" then
            table.insert(found, {
                fullPath = path,
                name     = name,
                ext      = ext,
            })
            print("📄 Encontrado: " .. name .. " (" .. path .. ")")
        end
    end

    if #found == 0 then
        print("⚠️ Nenhum .rbxlx encontrado em '" .. FOLDER_NAME .. "'")
        print("   Coloque o arquivo em: Codex/Workspace/Games/")
    end

    return found
end

-- ══════════════════════════════════
--   PASSO 4: PARSER XML ROBUSTO
-- ══════════════════════════════════

local function decodeXML(s)
    if not s then return "" end
    return (s
        :gsub("&amp;",  "&")
        :gsub("&lt;",   "<")
        :gsub("&gt;",   ">")
        :gsub("&quot;", '"')
        :gsub("&apos;", "'")
        :gsub("&#(%d+);", function(n)
            local num = tonumber(n)
            if num and num >= 32 and num < 128 then
                return string.char(num)
            end
            return ""
        end)
    )
end

-- Parser de XML compacto e robusto
-- Retorna árvore de nós: {tag, attrs={}, children={}, text=""}
local function parseXML(xml)
    -- Remove declaração XML e comentários
    xml = xml:gsub("<%?xml[^>]*%?>", "")
    xml = xml:gsub("<!%-%-.-%-%->" , "")
    xml = xml:gsub("<!%[CDATA%[(.-)%]%]>", function(inner)
        return inner -- mantém conteúdo CDATA
    end)

    local root  = {tag="__root__", attrs={}, children={}, text=""}
    local stack = {root}

    local i = 1
    local len = #xml

    while i <= len do
        local lt = xml:find("<", i, true)
        if not lt then break end

        -- Texto antes da tag
        if lt > i then
            local raw = xml:sub(i, lt - 1)
            local trimmed = raw:match("^%s*(.-)%s*$")
            if trimmed ~= "" then
                local top = stack[#stack]
                top.text = (top.text or "") .. decodeXML(trimmed)
            end
        end

        local gt = xml:find(">", lt, true)
        if not gt then break end

        local tag_content = xml:sub(lt + 1, gt - 1)
        i = gt + 1

        -- Comentário / PI
        if tag_content:sub(1,1) == "!" or tag_content:sub(1,1) == "?" then
            -- ignora

        -- Fechamento
        elseif tag_content:sub(1,1) == "/" then
            if #stack > 1 then table.remove(stack) end

        else
            local selfClose = tag_content:sub(-1) == "/"
            if selfClose then tag_content = tag_content:sub(1,-2) end

            -- Nome da tag
            local tagName = tag_content:match("^([%w:_%.%-]+)")
            if tagName then
                -- Atributos
                local attrsStr = tag_content:sub(#tagName+1)
                local attrs = {}
                -- name="value" ou name='value'
                for k,v in attrsStr:gmatch('([%w:_%-]+)%s*=%s*"([^"]*)"') do
                    attrs[k] = decodeXML(v)
                end
                for k,v in attrsStr:gmatch("([%w:_%-]+)%s*=%s*'([^']*)'") do
                    attrs[k] = decodeXML(v)
                end

                local node = {tag=tagName, attrs=attrs, children={}, text=""}
                local top  = stack[#stack]
                table.insert(top.children, node)

                if not selfClose then
                    table.insert(stack, node)
                end
            end
        end
    end

    return root
end

-- ══════════════════════════════════
--   PASSO 5: IMPORTADOR
-- ══════════════════════════════════

-- Serviços alvo
local SVC = {
    Workspace           = game:GetService("Workspace"),
    ServerScriptService = game:GetService("ServerScriptService"),
    ServerStorage       = game:GetService("ServerStorage"),
    ReplicatedStorage   = game:GetService("ReplicatedStorage"),
    Lighting            = game:GetService("Lighting"),
    StarterGui          = game:GetService("StarterGui"),
    StarterPack         = game:GetService("StarterPack"),
    StarterPlayer       = game:GetService("StarterPlayer"),
    SoundService        = game:GetService("SoundService"),
    Teams               = game:GetService("Teams"),
}

-- Aplica propriedade com tratamento de erros
local function setprop(inst, name, ptype, node)
    pcall(function()
        local txt = node.text or ""
        local ch  = node.children

        -- Helper: pega filho pelo tag
        local function child(tag)
            for _, c in ipairs(ch) do
                if c.tag == tag then return c end
            end
        end

        if ptype == "string" or ptype == "ProtectedString" then
            inst[name] = decodeXML(txt)

        elseif ptype == "bool" then
            inst[name] = txt:lower() == "true"

        elseif ptype == "int" or ptype == "int64" then
            inst[name] = math.floor(tonumber(txt) or 0)

        elseif ptype == "float" or ptype == "double" then
            inst[name] = tonumber(txt) or 0

        elseif ptype == "Color3" then
            local r = child("R"); local g = child("G"); local b = child("B")
            if r and g and b then
                inst[name] = Color3.new(
                    tonumber(r.text) or 1,
                    tonumber(g.text) or 1,
                    tonumber(b.text) or 1)
            end

        elseif ptype == "Color3uint8" then
            local r = child("R"); local g = child("G"); local b = child("B")
            if r and g and b then
                inst[name] = Color3.fromRGB(
                    tonumber(r.text) or 255,
                    tonumber(g.text) or 255,
                    tonumber(b.text) or 255)
            end

        elseif ptype == "Vector3" then
            local x = child("X"); local y = child("Y"); local z = child("Z")
            if x and y and z then
                inst[name] = Vector3.new(
                    tonumber(x.text) or 0,
                    tonumber(y.text) or 0,
                    tonumber(z.text) or 0)
            end

        elseif ptype == "Vector2" then
            local x = child("X"); local y = child("Y")
            if x and y then
                inst[name] = Vector2.new(tonumber(x.text) or 0, tonumber(y.text) or 0)
            end

        elseif ptype == "CoordinateFrame" then
            -- CFrame: filhos X,Y,Z,R00..R22
            local vals = {}
            local order = {"X","Y","Z","R00","R01","R02","R10","R11","R12","R20","R21","R22"}
            for _, k in ipairs(order) do
                local c = child(k)
                table.insert(vals, c and (tonumber(c.text) or 0) or 0)
            end
            if #vals >= 12 then
                inst[name] = CFrame.new(
                    vals[1],vals[2],vals[3],
                    vals[4],vals[5],vals[6],
                    vals[7],vals[8],vals[9],
                    vals[10],vals[11],vals[12])
            end

        elseif ptype == "BrickColor" then
            local n = tonumber(txt)
            if n then inst[name] = BrickColor.new(n) end

        elseif ptype == "token" then
            -- Enum como número
            local n = tonumber(txt)
            if n then
                -- Tenta direto (alguns enums aceitam número)
                pcall(function() inst[name] = n end)
            end

        elseif ptype == "Content" then
            inst[name] = txt

        elseif ptype == "UDim2" then
            local xs = child("XS"); local xo = child("XO")
            local ys = child("YS"); local yo = child("YO")
            if xs and xo and ys and yo then
                inst[name] = UDim2.new(
                    tonumber(xs.text) or 0, tonumber(xo.text) or 0,
                    tonumber(ys.text) or 0, tonumber(yo.text) or 0)
            end

        elseif ptype == "UDim" then
            local s = child("S"); local o = child("O")
            if s and o then
                inst[name] = UDim.new(tonumber(s.text) or 0, tonumber(o.text) or 0)
            end
        end
    end)
end

-- Cria instância recursivamente
local function buildInstance(itemNode, parent)
    local cls = itemNode.attrs.class
    if not cls then return nil end

    -- É um serviço raiz?
    local svc = SVC[cls]
    local inst = nil

    if svc then
        inst = svc
    else
        local ok, obj = pcall(Instance.new, cls)
        if ok and obj then
            inst = obj
        else
            -- Fallback: Folder com nome da classe
            inst = Instance.new("Folder")
            inst.Name = "[" .. cls .. "]"
        end
    end

    -- Aplica propriedades
    for _, node in ipairs(itemNode.children) do
        if node.tag == "Properties" then
            for _, prop in ipairs(node.children) do
                if prop.attrs.name then
                    setprop(inst, prop.attrs.name, prop.tag, prop)
                end
            end
        end
    end

    -- Parent (apenas não-serviços)
    if not svc and parent then
        pcall(function() inst.Parent = parent end)
    end

    -- Filhos recursivos
    for _, node in ipairs(itemNode.children) do
        if node.tag == "Item" then
            buildInstance(node, inst)
        end
    end

    return inst
end

local importStats = {ok=0, fail=0, log={}}

local function doImport(filePath)
    importStats = {ok=0, fail=0, log={}}

    local function log(msg)
        table.insert(importStats.log, msg)
        print("[Import] " .. msg)
    end

    -- Lê o arquivo
    log("Lendo: " .. filePath)
    local content
    local ok, result = pcall(fs.read, filePath)
    if ok then
        content = result
    else
        log("❌ Erro ao ler: " .. tostring(result))
        return false, "Não consegui ler o arquivo."
    end

    if not content or #content == 0 then
        return false, "Arquivo vazio ou ilegível."
    end

    log("Arquivo lido: " .. #content .. " bytes")

    -- Parseia
    local xmlOk, tree = pcall(parseXML, content)
    if not xmlOk then
        log("❌ Erro no parser: " .. tostring(tree))
        return false, "Erro ao parsear XML."
    end

    -- Encontra <roblox>
    local robloxNode = nil
    for _, c in ipairs(tree.children) do
        if c.tag == "roblox" then robloxNode = c; break end
    end
    if not robloxNode then
        -- Usa raiz
        robloxNode = tree
        log("⚠️ Tag <roblox> não encontrada, usando raiz")
    end

    -- Pasta fallback no Workspace
    local fallback = Instance.new("Folder")
    fallback.Name  = "📦 Import_" .. os.date("%H%M%S")
    fallback.Parent = game:GetService("Workspace")

    -- Processa itens de topo
    local topItems = {}
    for _, c in ipairs(robloxNode.children) do
        if c.tag == "Item" then table.insert(topItems, c) end
    end

    log("Objetos no topo: " .. #topItems)

    for _, itemNode in ipairs(topItems) do
        local cls = itemNode.attrs.class or "?"
        local svc = SVC[cls]

        if svc then
            -- É um serviço: importa filhos direto dentro dele
            log("Serviço: " .. cls)
            for _, child in ipairs(itemNode.children) do
                if child.tag == "Item" then
                    local ok2, err2 = pcall(buildInstance, child, svc)
                    if ok2 then
                        importStats.ok = importStats.ok + 1
                    else
                        importStats.fail = importStats.fail + 1
                        log("  ❌ Filho de " .. cls .. ": " .. tostring(err2))
                    end
                end
            end
        else
            -- Objeto normal
            local ok2, err2 = pcall(buildInstance, itemNode, fallback)
            if ok2 then
                importStats.ok = importStats.ok + 1
                log("✅ " .. cls)
            else
                importStats.fail = importStats.fail + 1
                log("❌ " .. cls .. ": " .. tostring(err2))
            end
        end
    end

    -- Se fallback ficou vazio, remove
    if #fallback:GetChildren() == 0 then
        fallback:Destroy()
    else
        log("📁 Fallback criado: " .. fallback.Name)
    end

    log("══════════════════════")
    log("✅ OK: "   .. importStats.ok)
    log("❌ Fail: " .. importStats.fail)

    local msg = importStats.ok .. " obj importados"
    if importStats.fail > 0 then msg = msg .. ", " .. importStats.fail .. " erros" end
    return true, msg
end

-- ══════════════════════════════════
--   PASSO 6: GUI
-- ══════════════════════════════════
local Players    = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- Remove GUI antiga
local old = PlayerGui:FindFirstChild("RBXLXv2")
if old then old:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name = "RBXLXv2"
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder = 1000
SG.Parent = PlayerGui

-- ── Janela ──
local Win = Instance.new("Frame")
Win.Size = UDim2.new(0, 350, 0, 530)
Win.Position = UDim2.new(0.5,-175, -0.7, 0)
Win.BackgroundColor3 = Color3.fromRGB(10,10,18)
Win.BorderSizePixel = 0
Win.Active = true
Win.Draggable = true
Win.Parent = SG

do
    local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,16); c.Parent=Win
    local s = Instance.new("UIStroke"); s.Thickness=2; s.Color=Color3.fromRGB(60,120,255); s.Parent=Win
    -- Anima entrada
    TweenService:Create(Win,TweenInfo.new(0.5,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
        {Position=UDim2.new(0.5,-175,0.5,-265)}):Play()
    -- Stroke animado
    task.spawn(function()
        local h = 0.6
        while Win.Parent do
            h=(h+0.003)%1
            s.Color = Color3.fromHSV(h,0.8,1)
            task.wait(0.05)
        end
    end)
end

-- ── Helper UI ──
local function Label(txt, sz, col, parent, pos, size, align, wrap)
    local l = Instance.new("TextLabel")
    l.Text = txt; l.TextSize = sz or 12
    l.TextColor3 = col or Color3.new(1,1,1)
    l.BackgroundTransparency = 1
    l.Font = Enum.Font.GothamBold
    l.Position = pos or UDim2.new(0,0,0,0)
    l.Size = size or UDim2.new(1,0,0,20)
    l.TextXAlignment = align or Enum.TextXAlignment.Left
    l.TextWrapped = wrap or false
    l.Parent = parent
    return l
end

local function Frame(col, parent, pos, size, radius)
    local f = Instance.new("Frame")
    f.BackgroundColor3 = col
    f.BorderSizePixel = 0
    f.Position = pos; f.Size = size
    f.Parent = parent
    if radius then
        local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,radius); c.Parent=f
    end
    return f
end

local function Btn(txt, col, parent, pos, size)
    local b = Instance.new("TextButton")
    b.Text = txt
    b.TextColor3 = Color3.new(1,1,1)
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.BackgroundColor3 = col
    b.BorderSizePixel = 0
    b.Position = pos; b.Size = size
    b.AutoButtonColor = false
    b.Parent = parent
    local c = Instance.new("UICorner"); c.CornerRadius=UDim.new(0,10); c.Parent=b
    return b
end

-- ── Topbar ──
local top = Frame(Color3.fromRGB(20,15,50), Win, UDim2.new(0,0,0,0), UDim2.new(1,0,0,52), 16)
do
    local tg = Instance.new("UIGradient")
    tg.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(50,100,230)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(25,50,160))
    }
    tg.Rotation=90; tg.Parent=top
    Label("📦  RBXLX Loader v2", 17, Color3.new(1,1,1), top,
        UDim2.new(0,12,0,8), UDim2.new(1,-55,0,22))
    Label("Codex Mobile · Studio Lite", 10, Color3.fromRGB(130,160,255), top,
        UDim2.new(0,12,0,30), UDim2.new(1,-55,0,16))
    -- X
    local xb = Btn("✕", Color3.fromRGB(200,50,70), Win,
        UDim2.new(1,-46,0,9), UDim2.new(0,34,0,34))
    xb.MouseButton1Click:Connect(function() SG:Destroy() end)
end

-- ── Caixa de info ──
local infoBox = Frame(Color3.fromRGB(15,35,15), Win,
    UDim2.new(0,10,0,58), UDim2.new(1,-20,0,38), 8)
do
    local s2 = Instance.new("UIStroke"); s2.Color=Color3.fromRGB(40,100,40); s2.Thickness=1; s2.Parent=infoBox
    local pathTxt = "📁  Coloque .rbxlx em: Codex  ›  Workspace  ›  Games"
    Label(pathTxt, 10, Color3.fromRGB(100,220,100), infoBox,
        UDim2.new(0,8,0,0), UDim2.new(1,-10,1,0), Enum.TextXAlignment.Left, true)
end

-- ── Diagnóstico ──
local diagBox = Frame(Color3.fromRGB(12,12,30), Win,
    UDim2.new(0,10,0,103), UDim2.new(1,-20,0,28), 8)
do
    local s2 = Instance.new("UIStroke"); s2.Color=Color3.fromRGB(40,50,100); s2.Thickness=1; s2.Parent=diagBox
    local diag = "FS: "
      .. (fs.read and "read✅ " or "read❌ ")
      .. (fs.list and "list✅ " or "list❌ ")
      .. (fs.mkdir and "mkdir✅ " or "mkdir❌ ")
      .. " | Pasta Games: " .. (folderCreated and "✅" or "⚠️")
    Label(diag, 9, Color3.fromRGB(120,130,180), diagBox,
        UDim2.new(0,8,0,0), UDim2.new(1,-10,1,0), Enum.TextXAlignment.Left, true)
end

-- ── Lista de arquivos ──
Label("🗂️  ARQUIVOS .RBXLX", 11, Color3.fromRGB(100,150,255), Win,
    UDim2.new(0,14,0,136), UDim2.new(1,-28,0,18))

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1,-20,0,190)
scroll.Position = UDim2.new(0,10,0,157)
scroll.BackgroundColor3 = Color3.fromRGB(8,8,18)
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 5
scroll.ScrollBarImageColor3 = Color3.fromRGB(70,120,255)
scroll.CanvasSize = UDim2.new(0,0,0,0)
scroll.Parent = Win
do
    local c=Instance.new("UICorner");c.CornerRadius=UDim.new(0,10);c.Parent=scroll
    local s=Instance.new("UIStroke");s.Color=Color3.fromRGB(35,55,110);s.Thickness=1;s.Parent=scroll
    local ll=Instance.new("UIListLayout");ll.SortOrder=Enum.SortOrder.LayoutOrder;ll.Padding=UDim.new(0,4);ll.Parent=scroll
    local pp=Instance.new("UIPadding");pp.PaddingAll=UDim.new(0,6);pp.Parent=scroll
end

-- ── Selecionado ──
local selBox = Frame(Color3.fromRGB(12,20,40), Win,
    UDim2.new(0,10,0,354), UDim2.new(1,-20,0,34), 8)
do
    local s2=Instance.new("UIStroke");s2.Color=Color3.fromRGB(40,60,120);s2.Thickness=1;s2.Parent=selBox
end
local selLbl = Label("Nenhum arquivo selecionado", 10, Color3.fromRGB(100,120,180), selBox,
    UDim2.new(0,8,0,0), UDim2.new(1,-16,1,0), Enum.TextXAlignment.Left, true)

-- ── Status ──
local statBox = Frame(Color3.fromRGB(12,18,30), Win,
    UDim2.new(0,10,0,394), UDim2.new(1,-20,0,48), 10)
do
    local s2=Instance.new("UIStroke");s2.Color=Color3.fromRGB(40,60,120);s2.Thickness=1;s2.Parent=statBox
end
local statLbl = Label("⏳ Aguardando...", 10, Color3.fromRGB(150,180,255), statBox,
    UDim2.new(0,8,0,0), UDim2.new(1,-16,1,0), Enum.TextXAlignment.Left, true)

local function setStatus(msg, col)
    statLbl.Text = msg
    statLbl.TextColor3 = col or Color3.fromRGB(150,180,255)
end

-- ── Botões ──
local btnImport = Btn("📥  IMPORTAR", Color3.fromRGB(40,100,220), Win,
    UDim2.new(0,10,0,450), UDim2.new(0.6,-14,0,50))
do
    local g=Instance.new("UIGradient");g.Color=ColorSequence.new{
        ColorSequenceKeypoint.new(0,Color3.fromRGB(60,140,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(30,80,200))
    };g.Rotation=90;g.Parent=btnImport
end

local btnRefresh = Btn("🔄 Atualizar", Color3.fromRGB(30,40,80), Win,
    UDim2.new(0.6,4,0,450), UDim2.new(0.4,-14,0,50))

-- ══════════════════════════════════
--   LÓGICA: POPULA LISTA
-- ══════════════════════════════════
local selectedFile = nil
local selectedBtn  = nil

local function populateList()
    -- Limpa lista
    for _, c in ipairs(scroll:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
    end
    selectedFile = nil; selectedBtn = nil
    selLbl.Text = "Nenhum arquivo selecionado"
    selLbl.TextColor3 = Color3.fromRGB(100,120,180)

    local files = getFiles()

    if #files == 0 then
        local empty = Instance.new("TextLabel")
        empty.Size = UDim2.new(1,-12,0,70)
        empty.BackgroundTransparency = 1
        empty.Text = "⚠️ Nenhum .rbxlx encontrado.\n\nColoque em:\nCodex  ›  Workspace  ›  Games"
        empty.TextColor3 = Color3.fromRGB(200,160,60)
        empty.TextSize = 11
        empty.Font = Enum.Font.Gotham
        empty.TextWrapped = true
        empty.TextYAlignment = Enum.TextYAlignment.Center
        empty.Parent = scroll
        scroll.CanvasSize = UDim2.new(0,0,0,80)
        setStatus("📭 Pasta vazia. Adicione .rbxlx em Games/", Color3.fromRGB(255,200,80))
        return
    end

    local totalH = 12
    for i, fi in ipairs(files) do
        local row = Instance.new("TextButton")
        row.Size = UDim2.new(1,-12,0,50)
        row.BackgroundColor3 = Color3.fromRGB(18,26,52)
        row.BorderSizePixel = 0
        row.LayoutOrder = i
        row.AutoButtonColor = false
        row.Text = ""
        row.Parent = scroll
        local rc=Instance.new("UICorner");rc.CornerRadius=UDim.new(0,8);rc.Parent=row
        local rs=Instance.new("UIStroke");rs.Color=Color3.fromRGB(40,60,120);rs.Thickness=1;rs.Parent=row

        -- Ícone
        local ic = Instance.new("TextLabel")
        ic.Size=UDim2.new(0,36,1,0); ic.Position=UDim2.new(0,6,0,0)
        ic.BackgroundTransparency=1; ic.Text="📄"; ic.TextSize=20
        ic.Font=Enum.Font.Gotham; ic.Parent=row

        -- Nome
        local nm = Instance.new("TextLabel")
        nm.Size=UDim2.new(1,-50,0,22); nm.Position=UDim2.new(0,44,0,4)
        nm.BackgroundTransparency=1
        nm.Text=fi.name; nm.TextSize=12; nm.Font=Enum.Font.GothamBold
        nm.TextColor3=Color3.fromRGB(220,230,255)
        nm.TextXAlignment=Enum.TextXAlignment.Left
        nm.TextTruncate=Enum.TextTruncate.AtEnd; nm.Parent=row

        -- Path curto
        local pt = Instance.new("TextLabel")
        pt.Size=UDim2.new(1,-50,0,16); pt.Position=UDim2.new(0,44,0,28)
        pt.BackgroundTransparency=1
        pt.Text=fi.fullPath; pt.TextSize=8; pt.Font=Enum.Font.Gotham
        pt.TextColor3=Color3.fromRGB(90,110,170)
        pt.TextXAlignment=Enum.TextXAlignment.Left
        pt.TextTruncate=Enum.TextTruncate.AtEnd; pt.Parent=row

        totalH = totalH + 54

        row.MouseButton1Click:Connect(function()
            -- Deseleciona anterior
            if selectedBtn then
                TweenService:Create(selectedBtn,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(18,26,52)}):Play()
                for _,s in ipairs(selectedBtn:GetChildren()) do
                    if s:IsA("UIStroke") then s.Color=Color3.fromRGB(40,60,120) end
                end
            end
            selectedFile = fi; selectedBtn = row
            TweenService:Create(row,TweenInfo.new(0.15),{BackgroundColor3=Color3.fromRGB(25,55,130)}):Play()
            for _,s in ipairs(row:GetChildren()) do
                if s:IsA("UIStroke") then s.Color=Color3.fromRGB(80,140,255) end
            end
            selLbl.Text = "✅ " .. fi.name
            selLbl.TextColor3 = Color3.fromRGB(100,220,140)
            setStatus("Pronto: " .. fi.name, Color3.fromRGB(100,200,255))
        end)
    end

    scroll.CanvasSize = UDim2.new(0,0,0,totalH)
    setStatus("🗂️ " .. #files .. " arquivo(s). Selecione um.", Color3.fromRGB(150,200,255))
end

-- ══════════════════════════════════
--   LÓGICA BOTÕES
-- ══════════════════════════════════

btnRefresh.MouseButton1Click:Connect(function()
    setStatus("🔄 Atualizando...", Color3.fromRGB(255,220,80))
    populateList()
end)

btnImport.MouseButton1Click:Connect(function()
    if not selectedFile then
        setStatus("⚠️ Selecione um arquivo primeiro!", Color3.fromRGB(255,200,50))
        return
    end
    if not hasFSBasic then
        setStatus("❌ Executor não suporta filesystem!", Color3.fromRGB(255,80,80))
        return
    end

    btnImport.Text = "⏳ Importando..."
    btnImport.Active = false
    setStatus("⚙️ Processando " .. selectedFile.name .. "...", Color3.fromRGB(255,220,80))

    task.spawn(function()
        local ok, msg = doImport(selectedFile.fullPath)
        task.wait(0.1)
        btnImport.Text = "📥  IMPORTAR"
        btnImport.Active = true
        if ok then
            setStatus("✅ " .. msg, Color3.fromRGB(100,255,150))
        else
            setStatus("❌ " .. msg, Color3.fromRGB(255,100,100))
        end
    end)
end)

-- ══════════════════════════════════
--   INICIALIZA
-- ══════════════════════════════════
setStatus("🚀 Script carregado! Pasta: Games/", Color3.fromRGB(120,220,255))
task.wait(0.4)
populateList()

print("=== RBXLX Loader v2 pronto! ===")
print("Pasta Games: " .. FOLDER_NAME)
print("hasFSBasic: " .. tostring(hasFSBasic))
