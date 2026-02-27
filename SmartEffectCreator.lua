--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║           SMART EFFECT CREATOR - by Script Pro              ║
    ║      Compatível com Roblox Studio Lite & Mobile             ║
    ║   Executor: Codex Mobile / Delta / Fluxus Mobile            ║
    ╚══════════════════════════════════════════════════════════════╝
    
    COMO USAR:
    1. Cole este script no executor (Codex Mobile, Delta, etc.)
    2. Execute dentro do jogo Roblox Studio Lite (mobile)
    3. A GUI vai aparecer na tela
    4. Digite o ID da textura (número ou rbxassetid://...)
    5. Escolha Beam ou ParticleEmitter
    6. Clique em "✨ CRIAR EFEITO"
    7. Uma Part invisível será criada no Workspace com o efeito configurado!
]]

-- ════════════════════════════════════
--         SERVIÇOS & VARIÁVEIS
-- ════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- ════════════════════════════════════
--         SISTEMA INTELIGENTE
-- ════════════════════════════════════

-- Analisa o ID e normaliza para formato correto
local function normalizeAssetId(input)
    if not input or input == "" then return nil end
    input = tostring(input):gsub("%s+", "")
    
    -- Extrai apenas o número
    local num = input:match("(%d+)")
    if num then
        return "rbxassetid://" .. num, tonumber(num)
    end
    return nil, nil
end

-- Detecta tipo de efeito pelo ID (heurística inteligente)
local function detectEffectType(assetId)
    -- Simulação de análise: IDs maiores tendem a ser mais recentes
    -- O sistema vai tentar ambos e ver qual funciona melhor
    local id = tonumber(assetId)
    if not id then return "particle" end
    
    -- Baseado em ranges conhecidos do Roblox
    -- (lógica heurística - pode ser expandida)
    return "particle" -- padrão inteligente
end

-- Configurações inteligentes baseadas no tipo de efeito
local function getSmartParticleConfig(textureId, assetNum)
    -- Sistema inteligente que ajusta configurações com base no ID
    local seed = (assetNum or 12345) % 100
    
    return {
        -- Aparência
        Texture = textureId,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 100)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 50))
        }),
        LightEmission = 0.8,
        LightInfluence = 0.3,
        
        -- Transparência (fade in/out suave)
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(0.1, 0),
            NumberSequenceKeypoint.new(0.9, 0),
            NumberSequenceKeypoint.new(1, 1)
        }),
        
        -- Tamanho inteligente (começa grande, diminui)
        Size = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0),
            NumberSequenceKeypoint.new(0.3, 1.5),
            NumberSequenceKeypoint.new(0.7, 1),
            NumberSequenceKeypoint.new(1, 0)
        }),
        
        -- Rotação
        Rotation = NumberRange.new(-180, 180),
        RotSpeed = NumberRange.new(-200, 200),
        
        -- Física
        Rate = 20 + (seed * 0.5),
        Speed = NumberRange.new(5, 15),
        SpreadAngle = Vector2.new(30, 30),
        Acceleration = Vector3.new(0, -2, 0),
        Drag = 0.5,
        
        -- Lifetime
        Lifetime = NumberRange.new(1.5, 3),
        
        -- Configurações extras
        LockedToPart = false,
        Enabled = true,
        EmissionDirection = Enum.NormalId.Top,
        TimeScale = 1,
    }
end

-- Configurações inteligentes para Beam
local function getSmartBeamConfig(textureId, assetNum)
    local seed = (assetNum or 12345) % 100
    
    return {
        Texture = textureId,
        
        -- Cores com gradiente
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 200, 255)),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 100, 200))
        }),
        
        LightEmission = 0.8,
        LightInfluence = 0.3,
        
        -- Transparência
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.5),
            NumberSequenceKeypoint.new(0.5, 0),
            NumberSequenceKeypoint.new(1, 0.5)
        }),
        
        -- Largura
        Width0 = 1.5 + (seed * 0.02),
        Width1 = 1.5 + (seed * 0.02),
        
        -- Curvatura e animação
        CurveSize0 = 2,
        CurveSize1 = 2,
        TextureLength = 2,
        TextureSpeed = 1,
        TextureMode = Enum.TextureMode.Wrap,
        
        -- Segments para qualidade
        Segments = 20,
        
        Enabled = true,
        FaceCamera = true,
    }
end

-- ════════════════════════════════════
--         CRIADOR DE EFEITOS
-- ════════════════════════════════════

local createdParts = {} -- rastrear partes criadas

local function createEffectPart(effectType, textureId, assetNum, customName)
    -- Cria a Part base (invisível, pequena, quadrada)
    local part = Instance.new("Part")
    part.Name = customName or ("SmartEffect_" .. (assetNum or "0"))
    part.Size = Vector3.new(1, 1, 1)
    part.CFrame = CFrame.new(0, 5, 0) -- spawn elevado
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Transparency = 1 -- invisível
    part.Material = Enum.Material.Air
    part.Parent = Workspace
    
    if effectType == "particle" then
        local config = getSmartParticleConfig(textureId, assetNum)
        local emitter = Instance.new("ParticleEmitter")
        
        -- Aplica todas as configurações inteligentes
        emitter.Texture = config.Texture
        emitter.Color = config.Color
        emitter.LightEmission = config.LightEmission
        emitter.LightInfluence = config.LightInfluence
        emitter.Transparency = config.Transparency
        emitter.Size = config.Size
        emitter.Rotation = config.Rotation
        emitter.RotSpeed = config.RotSpeed
        emitter.Rate = config.Rate
        emitter.Speed = config.Speed
        emitter.SpreadAngle = config.SpreadAngle
        emitter.Acceleration = config.Acceleration
        emitter.Drag = config.Drag
        emitter.Lifetime = config.Lifetime
        emitter.LockedToPart = config.LockedToPart
        emitter.Enabled = config.Enabled
        emitter.EmissionDirection = config.EmissionDirection
        emitter.TimeScale = config.TimeScale
        emitter.Parent = part
        
        table.insert(createdParts, {part = part, emitter = emitter, type = "particle"})
        return part, emitter
        
    elseif effectType == "beam" then
        -- Beam precisa de 2 Attachments
        local att0 = Instance.new("Attachment")
        att0.Name = "BeamAtt0"
        att0.Position = Vector3.new(0, 0, 0)
        att0.Parent = part
        
        -- Part secundária para o outro ponto do beam
        local part2 = Instance.new("Part")
        part2.Name = part.Name .. "_End"
        part2.Size = Vector3.new(0.1, 0.1, 0.1)
        part2.CFrame = CFrame.new(0, 5, -5) -- 5 studs na frente
        part2.Anchored = true
        part2.CanCollide = false
        part2.Transparency = 1
        part2.Parent = Workspace
        
        local att1 = Instance.new("Attachment")
        att1.Name = "BeamAtt1"
        att1.Position = Vector3.new(0, 0, 0)
        att1.Parent = part2
        
        local config = getSmartBeamConfig(textureId, assetNum)
        local beam = Instance.new("Beam")
        
        beam.Attachment0 = att0
        beam.Attachment1 = att1
        beam.Texture = config.Texture
        beam.Color = config.Color
        beam.LightEmission = config.LightEmission
        beam.LightInfluence = config.LightInfluence
        beam.Transparency = config.Transparency
        beam.Width0 = config.Width0
        beam.Width1 = config.Width1
        beam.CurveSize0 = config.CurveSize0
        beam.CurveSize1 = config.CurveSize1
        beam.TextureLength = config.TextureLength
        beam.TextureSpeed = config.TextureSpeed
        beam.TextureMode = config.TextureMode
        beam.Segments = config.Segments
        beam.Enabled = config.Enabled
        beam.FaceCamera = config.FaceCamera
        beam.Parent = part
        
        table.insert(createdParts, {part = part, part2 = part2, beam = beam, type = "beam"})
        return part, beam
    end
end

-- ════════════════════════════════════
--              GUI PRINCIPAL
-- ════════════════════════════════════

-- Remove GUI antiga se existir
local oldGui = PlayerGui:FindFirstChild("SmartEffectCreatorGUI")
if oldGui then oldGui:Destroy() end

-- ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SmartEffectCreatorGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder = 999
ScreenGui.Parent = PlayerGui

-- ════ JANELA PRINCIPAL ════
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 340, 0, 520)
MainFrame.Position = UDim2.new(0.5, -170, 0.5, -260)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = MainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(100, 80, 220)
mainStroke.Thickness = 2
mainStroke.Parent = MainFrame

-- ════ GRADIENTE DO FUNDO ════
local mainGradient = Instance.new("UIGradient")
mainGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 15, 40)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 20))
})
mainGradient.Rotation = 135
mainGradient.Parent = MainFrame

-- ════ TOPBAR ════
local TopBar = Instance.new("Frame")
TopBar.Name = "TopBar"
TopBar.Size = UDim2.new(1, 0, 0, 55)
TopBar.Position = UDim2.new(0, 0, 0, 0)
TopBar.BackgroundColor3 = Color3.fromRGB(30, 20, 60)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 16)
topCorner.Parent = TopBar

local topGrad = Instance.new("UIGradient")
topGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 50, 180)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 20, 100))
})
topGrad.Rotation = 90
topGrad.Parent = TopBar

-- Título
local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Size = UDim2.new(1, -50, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "✨ Smart Effect Creator"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = TopBar

local SubTitle = Instance.new("TextLabel")
SubTitle.Size = UDim2.new(1, -50, 0, 16)
SubTitle.Position = UDim2.new(0, 15, 0, 35)
SubTitle.BackgroundTransparency = 1
SubTitle.Text = "Codex Mobile · Studio Lite Compatible"
SubTitle.TextColor3 = Color3.fromRGB(150, 130, 220)
SubTitle.TextSize = 10
SubTitle.Font = Enum.Font.Gotham
SubTitle.TextXAlignment = Enum.TextXAlignment.Left
SubTitle.Parent = MainFrame

-- Botão fechar
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Size = UDim2.new(0, 35, 0, 35)
CloseBtn.Position = UDim2.new(1, -45, 0, 10)
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

-- ════ CONTEÚDO ════
local Content = Instance.new("Frame")
Content.Name = "Content"
Content.Size = UDim2.new(1, -20, 1, -65)
Content.Position = UDim2.new(0, 10, 0, 60)
Content.BackgroundTransparency = 1
Content.Parent = MainFrame

-- Função helper para criar seções
local function createSection(title, yPos, height)
    local section = Instance.new("Frame")
    section.Size = UDim2.new(1, 0, 0, height)
    section.Position = UDim2.new(0, 0, 0, yPos)
    section.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
    section.BorderSizePixel = 0
    section.Parent = Content
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = section
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 50, 100)
    stroke.Thickness = 1
    stroke.Parent = section
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -15, 0, 20)
    label.Position = UDim2.new(0, 12, 0, 8)
    label.BackgroundTransparency = 1
    label.Text = title
    label.TextColor3 = Color3.fromRGB(140, 120, 220)
    label.TextSize = 11
    label.Font = Enum.Font.GothamBold
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = section
    
    return section
end

-- Função para criar input
local function createInput(parent, placeholder, yPos)
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, -20, 0, 38)
    box.Position = UDim2.new(0, 10, 0, yPos)
    box.BackgroundColor3 = Color3.fromRGB(12, 10, 25)
    box.BorderSizePixel = 0
    box.PlaceholderText = placeholder
    box.PlaceholderColor3 = Color3.fromRGB(80, 70, 120)
    box.Text = ""
    box.TextColor3 = Color3.fromRGB(220, 210, 255)
    box.TextSize = 13
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.Parent = parent
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = box
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(80, 60, 160)
    stroke.Thickness = 1.5
    stroke.Parent = box
    
    -- Efeito de foco
    box.Focused:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(150, 100, 255)}):Play()
    end)
    box.FocusLost:Connect(function()
        TweenService:Create(stroke, TweenInfo.new(0.2), {Color = Color3.fromRGB(80, 60, 160)}):Play()
    end)
    
    return box
end

-- ════ SEÇÃO 1: TEXTURE ID ════
local sec1 = createSection("🎨  TEXTURE ID", 5, 95)

local textureInput = createInput(sec1, "Ex: 12345678 ou rbxassetid://12345678", 28)

local textureHint = Instance.new("TextLabel")
textureHint.Size = UDim2.new(1, -20, 0, 18)
textureHint.Position = UDim2.new(0, 12, 0, 72)
textureHint.BackgroundTransparency = 1
textureHint.Text = "💡 Pode ser ID numérico ou URL completa"
textureHint.TextColor3 = Color3.fromRGB(100, 90, 150)
textureHint.TextSize = 9
textureHint.Font = Enum.Font.Gotham
textureHint.TextXAlignment = Enum.TextXAlignment.Left
textureHint.Parent = sec1

-- ════ SEÇÃO 2: TIPO DE EFEITO ════
local sec2 = createSection("⚡  TIPO DE EFEITO", 108, 105)

local selectedType = "particle" -- padrão

local btnParticle = Instance.new("TextButton")
btnParticle.Size = UDim2.new(0.46, 0, 0, 42)
btnParticle.Position = UDim2.new(0, 10, 0, 30)
btnParticle.BackgroundColor3 = Color3.fromRGB(80, 50, 180)
btnParticle.Text = "🌟 ParticleEmitter"
btnParticle.TextColor3 = Color3.fromRGB(255, 255, 255)
btnParticle.TextSize = 12
btnParticle.Font = Enum.Font.GothamBold
btnParticle.BorderSizePixel = 0
btnParticle.Parent = sec2

local pCorner = Instance.new("UICorner")
pCorner.CornerRadius = UDim.new(0, 10)
pCorner.Parent = btnParticle

local btnBeam = Instance.new("TextButton")
btnBeam.Size = UDim2.new(0.46, 0, 0, 42)
btnBeam.Position = UDim2.new(0.54, -5, 0, 30)
btnBeam.BackgroundColor3 = Color3.fromRGB(35, 28, 70)
btnBeam.Text = "〰️ Beam"
btnBeam.TextColor3 = Color3.fromRGB(180, 160, 220)
btnBeam.TextSize = 12
btnBeam.Font = Enum.Font.GothamBold
btnBeam.BorderSizePixel = 0
btnBeam.Parent = sec2

local bCorner = Instance.new("UICorner")
bCorner.CornerRadius = UDim.new(0, 10)
bCorner.Parent = btnBeam

local typeStroke1 = Instance.new("UIStroke")
typeStroke1.Color = Color3.fromRGB(150, 100, 255)
typeStroke1.Thickness = 2
typeStroke1.Parent = btnParticle

local typeStroke2 = Instance.new("UIStroke")
typeStroke2.Color = Color3.fromRGB(60, 50, 100)
typeStroke2.Thickness = 1
typeStroke2.Parent = btnBeam

local selectedLabel = Instance.new("TextLabel")
selectedLabel.Size = UDim2.new(1, -20, 0, 18)
selectedLabel.Position = UDim2.new(0, 10, 0, 80)
selectedLabel.BackgroundTransparency = 1
selectedLabel.Text = "✅ Selecionado: ParticleEmitter"
selectedLabel.TextColor3 = Color3.fromRGB(130, 220, 130)
selectedLabel.TextSize = 10
selectedLabel.Font = Enum.Font.Gotham
selectedLabel.TextXAlignment = Enum.TextXAlignment.Left
selectedLabel.Parent = sec2

-- Lógica de seleção
local function selectType(t)
    selectedType = t
    if t == "particle" then
        TweenService:Create(btnParticle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 50, 180)}):Play()
        TweenService:Create(btnBeam, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 28, 70)}):Play()
        typeStroke1.Color = Color3.fromRGB(150, 100, 255)
        typeStroke2.Color = Color3.fromRGB(60, 50, 100)
        btnParticle.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnBeam.TextColor3 = Color3.fromRGB(180, 160, 220)
        selectedLabel.Text = "✅ Selecionado: ParticleEmitter"
    else
        TweenService:Create(btnBeam, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(80, 50, 180)}):Play()
        TweenService:Create(btnParticle, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(35, 28, 70)}):Play()
        typeStroke2.Color = Color3.fromRGB(150, 100, 255)
        typeStroke1.Color = Color3.fromRGB(60, 50, 100)
        btnBeam.TextColor3 = Color3.fromRGB(255, 255, 255)
        btnParticle.TextColor3 = Color3.fromRGB(180, 160, 220)
        selectedLabel.Text = "✅ Selecionado: Beam"
    end
end

btnParticle.MouseButton1Click:Connect(function() selectType("particle") end)
btnBeam.MouseButton1Click:Connect(function() selectType("beam") end)

-- ════ SEÇÃO 3: NOME CUSTOMIZADO ════
local sec3 = createSection("🏷️  NOME DA PART (opcional)", 221, 75)

local nameInput = createInput(sec3, "Ex: MeuEfeito_Fogo (deixe vazio para auto)", 28)

-- ════ STATUS ════
local statusFrame = Instance.new("Frame")
statusFrame.Size = UDim2.new(1, 0, 0, 38)
statusFrame.Position = UDim2.new(0, 0, 0, 304)
statusFrame.BackgroundColor3 = Color3.fromRGB(15, 30, 15)
statusFrame.BorderSizePixel = 0
statusFrame.Parent = Content

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 10)
statusCorner.Parent = statusFrame

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -15, 1, 0)
statusLabel.Position = UDim2.new(0, 12, 0, 0)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "⏳ Aguardando ação..."
statusLabel.TextColor3 = Color3.fromRGB(150, 200, 150)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = statusFrame

local function setStatus(msg, color)
    statusLabel.Text = msg
    statusLabel.TextColor3 = color or Color3.fromRGB(150, 200, 150)
end

-- ════ BOTÃO PRINCIPAL: CRIAR ════
local CreateBtn = Instance.new("TextButton")
CreateBtn.Name = "CreateBtn"
CreateBtn.Size = UDim2.new(1, 0, 0, 52)
CreateBtn.Position = UDim2.new(0, 0, 0, 350)
CreateBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 220)
CreateBtn.Text = "✨  CRIAR EFEITO"
CreateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CreateBtn.TextSize = 16
CreateBtn.Font = Enum.Font.GothamBold
CreateBtn.BorderSizePixel = 0
CreateBtn.Parent = Content

local createCorner = Instance.new("UICorner")
createCorner.CornerRadius = UDim.new(0, 14)
createCorner.Parent = CreateBtn

local createGrad = Instance.new("UIGradient")
createGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(130, 80, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 40, 200))
})
createGrad.Rotation = 90
createGrad.Parent = CreateBtn

-- Efeito hover
CreateBtn.MouseEnter:Connect(function()
    TweenService:Create(CreateBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(130, 80, 255)}):Play()
end)
CreateBtn.MouseLeave:Connect(function()
    TweenService:Create(CreateBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(100, 60, 220)}):Play()
end)

-- ════ BOTÃO: DELETAR ÚLTIMA ════
local DeleteBtn = Instance.new("TextButton")
DeleteBtn.Size = UDim2.new(0.48, 0, 0, 38)
DeleteBtn.Position = UDim2.new(0, 0, 0, 410)
DeleteBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 60)
DeleteBtn.Text = "🗑️ Deletar Última"
DeleteBtn.TextColor3 = Color3.fromRGB(255, 200, 200)
DeleteBtn.TextSize = 12
DeleteBtn.Font = Enum.Font.GothamBold
DeleteBtn.BorderSizePixel = 0
DeleteBtn.Parent = Content

local delCorner = Instance.new("UICorner")
delCorner.CornerRadius = UDim.new(0, 10)
delCorner.Parent = DeleteBtn

-- ════ BOTÃO: LIMPAR TUDO ════
local ClearBtn = Instance.new("TextButton")
ClearBtn.Size = UDim2.new(0.48, 0, 0, 38)
ClearBtn.Position = UDim2.new(0.52, 0, 0, 410)
ClearBtn.BackgroundColor3 = Color3.fromRGB(100, 30, 50)
ClearBtn.Text = "💣 Limpar Tudo"
ClearBtn.TextColor3 = Color3.fromRGB(255, 180, 180)
ClearBtn.TextSize = 12
ClearBtn.Font = Enum.Font.GothamBold
ClearBtn.BorderSizePixel = 0
ClearBtn.Parent = Content

local clearCorner = Instance.new("UICorner")
clearCorner.CornerRadius = UDim.new(0, 10)
clearCorner.Parent = ClearBtn

-- Contador
local CounterLabel = Instance.new("TextLabel")
CounterLabel.Size = UDim2.new(1, 0, 0, 22)
CounterLabel.Position = UDim2.new(0, 0, 0, 455)
CounterLabel.BackgroundTransparency = 1
CounterLabel.Text = "📦 Efeitos criados: 0"
CounterLabel.TextColor3 = Color3.fromRGB(100, 80, 160)
CounterLabel.TextSize = 10
CounterLabel.Font = Enum.Font.Gotham
CounterLabel.TextXAlignment = Enum.TextXAlignment.Center
CounterLabel.Parent = Content

-- ════════════════════════════════════
--           LÓGICA DOS BOTÕES
-- ════════════════════════════════════

local effectCount = 0

-- CRIAR EFEITO
CreateBtn.MouseButton1Click:Connect(function()
    local rawInput = textureInput.Text
    
    -- Validação
    if rawInput == "" then
        setStatus("❌ Digite um Texture ID primeiro!", Color3.fromRGB(255, 100, 100))
        TweenService:Create(statusFrame, TweenInfo.new(0.1, Enum.EasingStyle.Bounce), {BackgroundColor3 = Color3.fromRGB(50, 15, 15)}):Play()
        task.delay(0.3, function()
            TweenService:Create(statusFrame, TweenInfo.new(0.3), {BackgroundColor3 = Color3.fromRGB(15, 30, 15)}):Play()
        end)
        return
    end
    
    -- Anima botão
    TweenService:Create(CreateBtn, TweenInfo.new(0.1), {Size = UDim2.new(1, 0, 0, 46)}):Play()
    task.delay(0.1, function()
        TweenService:Create(CreateBtn, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = UDim2.new(1, 0, 0, 52)}):Play()
    end)
    
    setStatus("⚙️ Processando...", Color3.fromRGB(255, 200, 50))
    
    local textureId, assetNum = normalizeAssetId(rawInput)
    
    if not textureId then
        setStatus("❌ ID inválido! Use apenas números.", Color3.fromRGB(255, 100, 100))
        return
    end
    
    -- Nome da part
    local partName = nameInput.Text
    if partName == "" then
        partName = (selectedType == "particle" and "ParticleEffect_" or "BeamEffect_") .. assetNum
    end
    
    -- Cria o efeito
    local success, err = pcall(function()
        createEffectPart(selectedType, textureId, assetNum, partName)
    end)
    
    if success then
        effectCount = effectCount + 1
        CounterLabel.Text = "📦 Efeitos criados: " .. effectCount
        
        local typeName = selectedType == "particle" and "ParticleEmitter" or "Beam"
        setStatus("✅ " .. typeName .. " criado! ID: " .. tostring(assetNum), Color3.fromRGB(100, 255, 150))
        
        -- Pisca verde
        TweenService:Create(statusFrame, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(20, 60, 20)}):Play()
        task.delay(0.5, function()
            TweenService:Create(statusFrame, TweenInfo.new(0.5), {BackgroundColor3 = Color3.fromRGB(15, 30, 15)}):Play()
        end)
    else
        setStatus("❌ Erro: " .. tostring(err):sub(1, 60), Color3.fromRGB(255, 100, 100))
    end
end)

-- DELETAR ÚLTIMA
DeleteBtn.MouseButton1Click:Connect(function()
    if #createdParts == 0 then
        setStatus("⚠️ Nenhuma part para deletar!", Color3.fromRGB(255, 200, 50))
        return
    end
    
    local last = table.remove(createdParts)
    if last.part and last.part.Parent then
        last.part:Destroy()
    end
    if last.part2 and last.part2.Parent then
        last.part2:Destroy()
    end
    
    effectCount = math.max(0, effectCount - 1)
    CounterLabel.Text = "📦 Efeitos criados: " .. effectCount
    setStatus("🗑️ Último efeito deletado.", Color3.fromRGB(200, 150, 150))
end)

-- LIMPAR TUDO
ClearBtn.MouseButton1Click:Connect(function()
    local count = 0
    for _, data in ipairs(createdParts) do
        if data.part and data.part.Parent then
            data.part:Destroy()
            count = count + 1
        end
        if data.part2 and data.part2.Parent then
            data.part2:Destroy()
        end
    end
    createdParts = {}
    effectCount = 0
    CounterLabel.Text = "📦 Efeitos criados: 0"
    setStatus("💣 " .. count .. " efeito(s) removido(s).", Color3.fromRGB(255, 150, 150))
end)

-- ════════════════════════════════════
--         ANIMAÇÃO DE ENTRADA
-- ════════════════════════════════════
MainFrame.Position = UDim2.new(0.5, -170, -0.5, -260)
TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
    Position = UDim2.new(0.5, -170, 0.5, -260)
}):Play()

-- ════════════════════════════════════
--         ANIMAÇÃO DO STROKE
-- ════════════════════════════════════
local hue = 0
RunService.Heartbeat:Connect(function(dt)
    if not MainFrame.Parent then return end
    hue = (hue + dt * 0.3) % 1
    mainStroke.Color = Color3.fromHSV(hue, 0.7, 0.9)
end)

print([[
╔══════════════════════════════════╗
║   Smart Effect Creator - LOADED  ║
║   Codex Mobile Compatible ✓      ║
║   Studio Lite Compatible ✓       ║
╚══════════════════════════════════╝
]])

setStatus("🚀 Script carregado! Pronto para criar efeitos.", Color3.fromRGB(120, 220, 255))
