--[[
    ╔════════════════════════════════════════════════════════════════╗
    ║          UNIVERSAL SCRIPT - ORION UI LIBRARY                   ║
    ║                    Script Completo Universal                   ║
    ║              Compatível com qualquer jogo Roblox               ║
    ╚════════════════════════════════════════════════════════════════╝
    
    Desenvolvido com OrionLib
    Versão: 3.5.0
    Última Atualização: 2026
]]

-- ═══════════════════════════════════════════════════════════════
-- CARREGAMENTO DO ORION LIBRARY
-- ═══════════════════════════════════════════════════════════════

local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/NymeraAnHomie/Library/refs/heads/main/OrionLib/Source.lua')))()

-- ═══════════════════════════════════════════════════════════════
-- SERVIÇOS DO ROBLOX
-- ═══════════════════════════════════════════════════════════════

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- ═══════════════════════════════════════════════════════════════
-- VARIÁVEIS GLOBAIS E CONFIGURAÇÕES
-- ═══════════════════════════════════════════════════════════════

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")
local Camera = Workspace.CurrentCamera

-- Estados Globais
local ScriptSettings = {
    -- Player
    WalkSpeed = 16,
    JumpPower = 50,
    Gravity = 196.2,
    FOV = 70,
    
    -- ESP
    ESPEnabled = false,
    ESPColor = Color3.fromRGB(255, 255, 255),
    ESPTransparency = 0.5,
    
    -- Teleporte
    TeleportOffset = Vector3.new(0, 5, 0),
    
    -- Auto Farm
    AutoFarmEnabled = false,
    AutoFarmTarget = nil,
    
    -- Misc
    InfiniteJump = false,
    NoClip = false,
    Fly = false,
    
    -- Visual
    FullBright = false,
    RemoveFog = false,
}

-- Tabelas de Estado
local ESPObjects = {}
local Connections = {}
local OriginalValues = {}
local TargetPlayers = {}

-- ═══════════════════════════════════════════════════════════════
-- FUNÇÕES UTILITÁRIAS
-- ═══════════════════════════════════════════════════════════════

local function Notify(title, content, duration)
    OrionLib:MakeNotification({
        Name = title,
        Content = content,
        Image = "rbxassetid://4483345998",
        Time = duration or 5
    })
end

local function GetCharacter()
    return Player.Character or Player.CharacterAdded:Wait()
end

local function GetRootPart()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChild("Humanoid")
end

local function TeleportTo(position, offset)
    offset = offset or ScriptSettings.TeleportOffset
    local root = GetRootPart()
    if root then
        root.CFrame = CFrame.new(position + offset)
        Notify("Teleporte", "Teleportado com sucesso!", 3)
    end
end

local function GetPlayersInRadius(radius)
    local players = {}
    local myPos = GetRootPart().Position
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player and player.Character then
            local theirRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if theirRoot then
                local distance = (myPos - theirRoot.Position).Magnitude
                if distance <= radius then
                    table.insert(players, player)
                end
            end
        end
    end
    
    return players
end

local function GetAllPlayersExceptMe()
    local players = {}
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player then
            table.insert(players, player.Name)
        end
    end
    return players
end

local function FindNearestPlayer()
    local nearest = nil
    local minDist = math.huge
    local myPos = GetRootPart().Position
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= Player and player.Character then
            local theirRoot = player.Character:FindFirstChild("HumanoidRootPart")
            if theirRoot then
                local dist = (myPos - theirRoot.Position).Magnitude
                if dist < minDist then
                    minDist = dist
                    nearest = player
                end
            end
        end
    end
    
    return nearest
end

-- ═══════════════════════════════════════════════════════════════
-- FUNÇÕES DE ESP (EXTRA SENSORY PERCEPTION)
-- ═══════════════════════════════════════════════════════════════

local function CreateESP(player)
    if player == Player then return end
    
    local character = player.Character
    if not character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_" .. player.Name
    highlight.FillColor = ScriptSettings.ESPColor
    highlight.FillTransparency = ScriptSettings.ESPTransparency
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.Parent = character
    
    ESPObjects[player.Name] = highlight
end

local function RemoveESP(player)
    if ESPObjects[player.Name] then
        ESPObjects[player.Name]:Destroy()
        ESPObjects[player.Name] = nil
    end
end

local function UpdateESP()
    if ScriptSettings.ESPEnabled then
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Player and not ESPObjects[player.Name] then
                CreateESP(player)
            end
        end
    else
        for _, esp in pairs(ESPObjects) do
            if esp then esp:Destroy() end
        end
        ESPObjects = {}
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FUNÇÕES DE MOVIMENTO
-- ═══════════════════════════════════════════════════════════════

local function SetWalkSpeed(speed)
    local humanoid = GetHumanoid()
    if humanoid then
        humanoid.WalkSpeed = speed
        ScriptSettings.WalkSpeed = speed
    end
end

local function SetJumpPower(power)
    local humanoid = GetHumanoid()
    if humanoid then
        humanoid.JumpPower = power
        ScriptSettings.JumpPower = power
    end
end

local function ToggleInfiniteJump(enabled)
    ScriptSettings.InfiniteJump = enabled
    
    if enabled then
        Connections.InfiniteJump = UserInputService.JumpRequest:Connect(function()
            if ScriptSettings.InfiniteJump then
                local humanoid = GetHumanoid()
                if humanoid then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    else
        if Connections.InfiniteJump then
            Connections.InfiniteJump:Disconnect()
            Connections.InfiniteJump = nil
        end
    end
end

local function ToggleNoClip(enabled)
    ScriptSettings.NoClip = enabled
    
    if enabled then
        Connections.NoClip = RunService.Stepped:Connect(function()
            if ScriptSettings.NoClip then
                local character = GetCharacter()
                if character then
                    for _, part in pairs(character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end
        end)
    else
        if Connections.NoClip then
            Connections.NoClip:Disconnect()
            Connections.NoClip = nil
        end
        
        local character = GetCharacter()
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end

local flySpeed = 50
local flyConnection = nil
local flyBV = nil
local flyBG = nil

local function ToggleFly(enabled)
    ScriptSettings.Fly = enabled
    local root = GetRootPart()
    
    if enabled and root then
        flyBV = Instance.new("BodyVelocity")
        flyBV.Velocity = Vector3.new(0, 0, 0)
        flyBV.MaxForce = Vector3.new(9e9, 9e9, 9e9)
        flyBV.Parent = root
        
        flyBG = Instance.new("BodyGyro")
        flyBG.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
        flyBG.CFrame = root.CFrame
        flyBG.Parent = root
        
        flyConnection = RunService.Heartbeat:Connect(function()
            if not ScriptSettings.Fly then return end
            
            local cam = Camera
            local root = GetRootPart()
            if not root then return end
            
            local moveDirection = Vector3.new(0, 0, 0)
            
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                moveDirection = moveDirection + (cam.CFrame.LookVector)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                moveDirection = moveDirection - (cam.CFrame.LookVector)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                moveDirection = moveDirection - (cam.CFrame.RightVector)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                moveDirection = moveDirection + (cam.CFrame.RightVector)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                moveDirection = moveDirection + Vector3.new(0, 1, 0)
            end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
                moveDirection = moveDirection - Vector3.new(0, 1, 0)
            end
            
            flyBV.Velocity = moveDirection * flySpeed
            flyBG.CFrame = cam.CFrame
        end)
        
        Notify("Fly", "Modo voo ativado! Use WASD + Space/Shift", 4)
    else
        if flyConnection then
            flyConnection:Disconnect()
            flyConnection = nil
        end
        if flyBV then flyBV:Destroy() flyBV = nil end
        if flyBG then flyBG:Destroy() flyBG = nil end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FUNÇÕES VISUAIS
-- ═══════════════════════════════════════════════════════════════

local function ToggleFullBright(enabled)
    ScriptSettings.FullBright = enabled
    
    if enabled then
        if not OriginalValues.Brightness then
            OriginalValues.Brightness = Lighting.Brightness
            OriginalValues.ClockTime = Lighting.ClockTime
            OriginalValues.Ambient = Lighting.Ambient
        end
        
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    else
        if OriginalValues.Brightness then
            Lighting.Brightness = OriginalValues.Brightness
            Lighting.ClockTime = OriginalValues.ClockTime
            Lighting.Ambient = OriginalValues.Ambient
        end
    end
end

local function ToggleRemoveFog(enabled)
    ScriptSettings.RemoveFog = enabled
    
    if enabled then
        if not OriginalValues.FogEnd then
            OriginalValues.FogEnd = Lighting.FogEnd
        end
        Lighting.FogEnd = 100000
    else
        if OriginalValues.FogEnd then
            Lighting.FogEnd = OriginalValues.FogEnd
        end
    end
end

local function SetFOV(value)
    Camera.FieldOfView = value
    ScriptSettings.FOV = value
end

local function ToggleXRay(enabled)
    if enabled then
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = 0.5
            end
        end
    else
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                part.LocalTransparencyModifier = 0
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FUNÇÕES DE WORKSPACE
-- ═══════════════════════════════════════════════════════════════

local function GetAllPartsInWorkspace()
    local parts = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            table.insert(parts, obj.Name)
        end
    end
    return parts
end

local function HighlightObject(objectName)
    local obj = Workspace:FindFirstChild(objectName, true)
    if obj and obj:IsA("BasePart") then
        local highlight = Instance.new("SelectionBox")
        highlight.Adornee = obj
        highlight.Color3 = Color3.fromRGB(0, 255, 0)
        highlight.LineThickness = 0.1
        highlight.Parent = obj
        
        Notify("Destaque", "Objeto destacado: " .. objectName, 3)
    end
end

local function TeleportToObject(objectName)
    local obj = Workspace:FindFirstChild(objectName, true)
    if obj and obj:IsA("BasePart") then
        TeleportTo(obj.Position)
    else
        Notify("Erro", "Objeto não encontrado!", 3)
    end
end

local function BringObject(objectName)
    local obj = Workspace:FindFirstChild(objectName, true)
    local root = GetRootPart()
    
    if obj and obj:IsA("BasePart") and root then
        obj.CFrame = root.CFrame + root.CFrame.LookVector * 5
        Notify("Trazer", "Objeto trazido para você!", 3)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FUNÇÕES DE CHAT E COMUNICAÇÃO
-- ═══════════════════════════════════════════════════════════════

local function SendChatMessage(message)
    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
end

local function SpamChat(message, times, delay)
    for i = 1, times do
        SendChatMessage(message)
        wait(delay or 1)
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FUNÇÕES DE ANTI-AFK
-- ═══════════════════════════════════════════════════════════════

local antiAFKEnabled = false
local antiAFKConnection = nil

local function ToggleAntiAFK(enabled)
    antiAFKEnabled = enabled
    
    if enabled then
        antiAFKConnection = RunService.Heartbeat:Connect(function()
            if antiAFKEnabled then
                VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
                wait(0.1)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
            end
        end)
        Notify("Anti-AFK", "Anti-AFK ativado!", 3)
    else
        if antiAFKConnection then
            antiAFKConnection:Disconnect()
            antiAFKConnection = nil
        end
    end
end

-- ═══════════════════════════════════════════════════════════════
-- FUNÇÕES DE SERVIDOR
-- ═══════════════════════════════════════════════════════════════

local function RejoinServer()
    TeleportService:Teleport(game.PlaceId, Player)
end

local function ServerHop()
    local servers = {}
    local success, result = pcall(function()
        return HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    end)
    
    if success and result.data then
        for _, server in pairs(result.data) do
            if server.id ~= game.JobId and server.playing < server.maxPlayers then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, Player)
                return
            end
        end
    end
    
    Notify("Erro", "Não foi possível encontrar outro servidor!", 4)
end

-- ═══════════════════════════════════════════════════════════════
-- CONFIGURAÇÃO DA INTERFACE ORIONLIB
-- ═══════════════════════════════════════════════════════════════

OrionLib.SelectedTheme = "Eclipse"

local Window = OrionLib:MakeWindow({
    Name = "🌟 Universal Script Hub v3.5",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "UniversalScriptHub",
    IntroEnabled = true,
    IntroText = "Universal Script Hub",
    IntroIcon = "rbxassetid://4483345998"
})

-- ═══════════════════════════════════════════════════════════════
-- TAB 1: PLAYER
-- ═══════════════════════════════════════════════════════════════

local PlayerTab = Window:MakeTab({
    Name = "👤 Player",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

PlayerTab:AddSection({
    Name = "Configurações do Jogador"
})

PlayerTab:AddSlider({
    Name = "Velocidade de Movimento",
    Min = 16,
    Max = 500,
    Default = 16,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Velocidade",
    Callback = function(Value)
        SetWalkSpeed(Value)
    end    
})

PlayerTab:AddSlider({
    Name = "Força do Pulo",
    Min = 50,
    Max = 500,
    Default = 50,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Força",
    Callback = function(Value)
        SetJumpPower(Value)
    end    
})

PlayerTab:AddSlider({
    Name = "Gravidade",
    Min = 0,
    Max = 196.2,
    Default = 196.2,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Gravidade",
    Callback = function(Value)
        Workspace.Gravity = Value
        ScriptSettings.Gravity = Value
    end    
})

PlayerTab:AddToggle({
    Name = "Pulo Infinito",
    Default = false,
    Save = true,
    Flag = "InfiniteJump",
    Callback = function(Value)
        ToggleInfiniteJump(Value)
    end    
})

PlayerTab:AddToggle({
    Name = "NoClip",
    Default = false,
    Save = true,
    Flag = "NoClip",
    Callback = function(Value)
        ToggleNoClip(Value)
    end    
})

PlayerTab:AddToggle({
    Name = "Modo Voar",
    Default = false,
    Save = true,
    Flag = "Fly",
    Callback = function(Value)
        ToggleFly(Value)
    end    
})

PlayerTab:AddSlider({
    Name = "Velocidade de Voo",
    Min = 10,
    Max = 200,
    Default = 50,
    Color = Color3.fromRGB(255,255,255),
    Increment = 5,
    ValueName = "Velocidade",
    Callback = function(Value)
        flySpeed = Value
    end    
})

PlayerTab:AddSection({
    Name = "Ações Rápidas"
})

PlayerTab:AddButton({
    Name = "Resetar Personagem",
    Callback = function()
        local humanoid = GetHumanoid()
        if humanoid then
            humanoid.Health = 0
        end
    end    
})

PlayerTab:AddButton({
    Name = "Remover Acessórios",
    Callback = function()
        local character = GetCharacter()
        if character then
            for _, accessory in pairs(character:GetChildren()) do
                if accessory:IsA("Accessory") then
                    accessory:Destroy()
                end
            end
            Notify("Acessórios", "Todos os acessórios foram removidos!", 3)
        end
    end    
})

PlayerTab:AddButton({
    Name = "Tornar Invisível (Visual)",
    Callback = function()
        local character = GetCharacter()
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") or part:IsA("Decal") then
                    part.Transparency = 1
                end
            end
        end
    end    
})

PlayerTab:AddButton({
    Name = "Restaurar Visibilidade",
    Callback = function()
        local character = GetCharacter()
        if character then
            for _, part in pairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Transparency = 0
                end
            end
        end
    end    
})

-- ═══════════════════════════════════════════════════════════════
-- TAB 2: VISUAL
-- ═══════════════════════════════════════════════════════════════

local VisualTab = Window:MakeTab({
    Name = "👁️ Visual",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

VisualTab:AddSection({
    Name = "Configurações Visuais"
})

VisualTab:AddToggle({
    Name = "FullBright",
    Default = false,
    Save = true,
    Flag = "FullBright",
    Callback = function(Value)
        ToggleFullBright(Value)
    end    
})

VisualTab:AddToggle({
    Name = "Remover Neblina",
    Default = false,
    Save = true,
    Flag = "RemoveFog",
    Callback = function(Value)
        ToggleRemoveFog(Value)
    end    
})

VisualTab:AddSlider({
    Name = "Campo de Visão (FOV)",
    Min = 70,
    Max = 120,
    Default = 70,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "FOV",
    Callback = function(Value)
        SetFOV(Value)
    end    
})

VisualTab:AddToggle({
    Name = "X-Ray (Transparência)",
    Default = false,
    Callback = function(Value)
        ToggleXRay(Value)
    end    
})

VisualTab:AddSection({
    Name = "ESP (Extra Sensory Perception)"
})

VisualTab:AddToggle({
    Name = "Ativar ESP",
    Default = false,
    Save = true,
    Flag = "ESP",
    Callback = function(Value)
        ScriptSettings.ESPEnabled = Value
        UpdateESP()
    end    
})

VisualTab:AddColorpicker({
    Name = "Cor do ESP",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        ScriptSettings.ESPColor = Value
        UpdateESP()
    end      
})

VisualTab:AddSlider({
    Name = "Transparência do ESP",
    Min = 0,
    Max = 1,
    Default = 0.5,
    Color = Color3.fromRGB(255,255,255),
    Increment = 0.1,
    ValueName = "Transparência",
    Callback = function(Value)
        ScriptSettings.ESPTransparency = Value
        UpdateESP()
    end    
})

VisualTab:AddSection({
    Name = "Iluminação"
})

VisualTab:AddSlider({
    Name = "Brilho",
    Min = 0,
    Max = 10,
    Default = 2,
    Color = Color3.fromRGB(255,255,255),
    Increment = 0.5,
    ValueName = "Brilho",
    Callback = function(Value)
        Lighting.Brightness = Value
    end    
})

VisualTab:AddSlider({
    Name = "Hora do Dia",
    Min = 0,
    Max = 24,
    Default = 14,
    Color = Color3.fromRGB(255,255,255),
    Increment = 0.5,
    ValueName = "Horas",
    Callback = function(Value)
        Lighting.ClockTime = Value
    end    
})

VisualTab:AddButton({
    Name = "Dia Completo",
    Callback = function()
        Lighting.ClockTime = 14
    end    
})

VisualTab:AddButton({
    Name = "Noite Completa",
    Callback = function()
        Lighting.ClockTime = 0
    end    
})

-- ═══════════════════════════════════════════════════════════════
-- TAB 3: TELEPORTE
-- ═══════════════════════════════════════════════════════════════

local TeleportTab = Window:MakeTab({
    Name = "📍 Teleporte",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

TeleportTab:AddSection({
    Name = "Teleporte para Jogadores"
})

local SelectedPlayer = nil
local PlayerDropdown = TeleportTab:AddDropdown({
    Name = "Selecionar Jogador",
    Default = "",
    Options = GetAllPlayersExceptMe(),
    Callback = function(Value)
        SelectedPlayer = Value
    end    
})

TeleportTab:AddButton({
    Name = "Teleportar para Jogador",
    Callback = function()
        if SelectedPlayer then
            local targetPlayer = Players:FindFirstChild(SelectedPlayer)
            if targetPlayer and targetPlayer.Character then
                local theirRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if theirRoot then
                    TeleportTo(theirRoot.Position)
                end
            end
        else
            Notify("Erro", "Selecione um jogador primeiro!", 3)
        end
    end    
})

TeleportTab:AddButton({
    Name = "Teleportar Atrás do Jogador",
    Callback = function()
        if SelectedPlayer then
            TeleportBehindPlayer(SelectedPlayer)
        else
            Notify("Erro", "Selecione um jogador primeiro!", 3)
        end
    end    
})

TeleportTab:AddButton({
    Name = "Atualizar Lista de Jogadores",
    Callback = function()
        PlayerDropdown:Refresh(GetAllPlayersExceptMe(), true)
        Notify("Atualizado", "Lista de jogadores atualizada!", 2)
    end    
})

TeleportTab:AddSection({
    Name = "Teleporte para Objetos"
})

local SelectedObject = nil
local ObjectSearchText = ""

local ObjectDropdown = TeleportTab:AddDropdown({
    Name = "Selecionar Objeto",
    Default = "",
    Options = {},
    Callback = function(Value)
        SelectedObject = Value
    end    
})

TeleportTab:AddTextbox({
    Name = "Buscar Objeto",
    Default = "",
    TextDisappear = false,
    Callback = function(Value)
        ObjectSearchText = Value:lower()
        local filteredObjects = {}
        
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name:lower():find(ObjectSearchText) then
                table.insert(filteredObjects, obj.Name)
            end
        end
        
        ObjectDropdown:Refresh(filteredObjects, true)
        if #filteredObjects > 0 then
            SelectedObject = filteredObjects[1]
            ObjectDropdown:Set(filteredObjects[1])
        end
    end    
})

TeleportTab:AddButton({
    Name = "Teleportar para Objeto",
    Callback = function()
        if SelectedObject then
            TeleportToObject(SelectedObject)
        else
            Notify("Erro", "Selecione um objeto primeiro!", 3)
        end
    end    
})

TeleportTab:AddButton({
    Name = "Destacar Objeto",
    Callback = function()
        if SelectedObject then
            HighlightObject(SelectedObject)
        else
            Notify("Erro", "Selecione um objeto primeiro!", 3)
        end
    end    
})

TeleportTab:AddButton({
    Name = "Trazer Objeto",
    Callback = function()
        if SelectedObject then
            BringObject(SelectedObject)
        else
            Notify("Erro", "Selecione um objeto primeiro!", 3)
        end
    end    
})

TeleportTab:AddSection({
    Name = "Teleporte Rápido"
})

TeleportTab:AddButton({
    Name = "Teleportar para Jogador Mais Próximo",
    Callback = function()
        local nearest = FindNearestPlayer()
        if nearest and nearest.Character then
            local theirRoot = nearest.Character:FindFirstChild("HumanoidRootPart")
            if theirRoot then
                TeleportTo(theirRoot.Position)
                Notify("Teleporte", "Teleportado para " .. nearest.Name, 3)
            end
        else
            Notify("Erro", "Nenhum jogador próximo encontrado!", 3)
        end
    end    
})

TeleportTab:AddSection({
    Name = "Waypoints Customizados"
})

local savedWaypoints = {}
local waypointName = ""

TeleportTab:AddTextbox({
    Name = "Nome do Waypoint",
    Default = "Waypoint1",
    TextDisappear = false,
    Callback = function(Value)
        waypointName = Value
    end    
})

TeleportTab:AddButton({
    Name = "Salvar Posição Atual",
    Callback = function()
        if waypointName ~= "" then
            local root = GetRootPart()
            if root then
                savedWaypoints[waypointName] = root.Position
                Notify("Waypoint", "Posição salva: " .. waypointName, 3)
            end
        else
            Notify("Erro", "Digite um nome para o waypoint!", 3)
        end
    end    
})

TeleportTab:AddButton({
    Name = "Teleportar para Waypoint",
    Callback = function()
        if waypointName ~= "" and savedWaypoints[waypointName] then
            TeleportTo(savedWaypoints[waypointName])
            Notify("Waypoint", "Teleportado para: " .. waypointName, 3)
        else
            Notify("Erro", "Waypoint não encontrado!", 3)
        end
    end    
})

TeleportTab:AddButton({
    Name = "Listar Waypoints Salvos",
    Callback = function()
        print("=== WAYPOINTS SALVOS ===")
        local count = 0
        for name, pos in pairs(savedWaypoints) do
            count = count + 1
            print(count .. ". " .. name .. " - Posição: " .. tostring(pos))
        end
        if count == 0 then
            print("Nenhum waypoint salvo!")
        end
        Notify("Waypoints", "Confira o console (F9)!", 3)
    end    
})

TeleportTab:AddButton({
    Name = "Deletar Waypoint",
    Callback = function()
        if waypointName ~= "" and savedWaypoints[waypointName] then
            savedWaypoints[waypointName] = nil
            Notify("Waypoint", "Waypoint deletado: " .. waypointName, 3)
        else
            Notify("Erro", "Waypoint não encontrado!", 3)
        end
    end    
})

-- ═══════════════════════════════════════════════════════════════
-- TAB 4: ANIMATION & EMOTES
-- ═══════════════════════════════════════════════════════════════

local AnimationTab = Window:MakeTab({
    Name = "💃 Animações",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

AnimationTab:AddSection({
    Name = "Controle de Animações"
})

local currentAnimation = nil

AnimationTab:AddButton({
    Name = "Parar Todas as Animações",
    Callback = function()
        local humanoid = GetHumanoid()
        if humanoid then
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                track:Stop()
            end
            Notify("Animações", "Todas as animações paradas!", 2)
        end
    end    
})

AnimationTab:AddButton({
    Name = "Congelar Animação Atual",
    Callback = function()
        local humanoid = GetHumanoid()
        if humanoid then
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                track:AdjustSpeed(0)
            end
            Notify("Animações", "Animação congelada!", 2)
        end
    end    
})

AnimationTab:AddButton({
    Name = "Descongelar Animação",
    Callback = function()
        local humanoid = GetHumanoid()
        if humanoid then
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                track:AdjustSpeed(1)
            end
            Notify("Animações", "Animação retomada!", 2)
        end
    end    
})

AnimationTab:AddSection({
    Name = "Velocidade de Animação"
})

AnimationTab:AddSlider({
    Name = "Velocidade das Animações",
    Min = 0,
    Max = 5,
    Default = 1,
    Color = Color3.fromRGB(255,255,255),
    Increment = 0.1,
    ValueName = "x",
    Callback = function(Value)
        local humanoid = GetHumanoid()
        if humanoid then
            for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
                track:AdjustSpeed(Value)
            end
        end
    end    
})

AnimationTab:AddSection({
    Name = "Emotes Customizados"
})

local emoteIds = {
    ["Dança 1"] = "rbxassetid://507770239",
    ["Dança 2"] = "rbxassetid://507770451",
    ["Dança 3"] = "rbxassetid://507770818",
    ["Acenar"] = "rbxassetid://507770453",
    ["Apontar"] = "rbxassetid://507770375",
    ["Rir"] = "rbxassetid://507770439",
    ["Aplaudir"] = "rbxassetid://507770677",
    ["Stadium"] = "rbxassetid://507777623"
}

for emoteName, emoteId in pairs(emoteIds) do
    AnimationTab:AddButton({
        Name = "Emote: " .. emoteName,
        Callback = function()
            local humanoid = GetHumanoid()
            if humanoid then
                local anim = Instance.new("Animation")
                anim.AnimationId = emoteId
                local track = humanoid:LoadAnimation(anim)
                track:Play()
                currentAnimation = track
                Notify("Emote", "Executando: " .. emoteName, 2)
            end
        end    
    })
end

AnimationTab:AddSection({
    Name = "Animação Customizada"
})

local customAnimId = ""

AnimationTab:AddTextbox({
    Name = "ID da Animação",
    Default = "",
    TextDisappear = false,
    Callback = function(Value)
        customAnimId = Value
    end    
})

AnimationTab:AddButton({
    Name = "Executar Animação Custom",
    Callback = function()
        if customAnimId ~= "" then
            local humanoid = GetHumanoid()
            if humanoid then
                local anim = Instance.new("Animation")
                anim.AnimationId = "rbxassetid://" .. customAnimId
                local track = humanoid:LoadAnimation(anim)
                track:Play()
                Notify("Animação", "Animação customizada executada!", 2)
            end
        else
            Notify("Erro", "Insira um ID de animação!", 3)
        end
    end    
})

-- ═══════════════════════════════════════════════════════════════
-- TAB 5: GAME UTILITIES
-- ═══════════════════════════════════════════════════════════════

local UtilitiesTab = Window:MakeTab({
    Name = "🎮 Utilidades",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

UtilitiesTab:AddSection({
    Name = "Controle de Câmera"
})

UtilitiesTab:AddButton({
    Name = "Câmera em Primeira Pessoa",
    Callback = function()
        Player.CameraMode = Enum.CameraMode.LockFirstPerson
        Notify("Câmera", "Modo primeira pessoa ativado!", 2)
    end    
})

UtilitiesTab:AddButton({
    Name = "Câmera Livre",
    Callback = function()
        Player.CameraMode = Enum.CameraMode.Classic
        Notify("Câmera", "Câmera livre ativada!", 2)
    end    
})

UtilitiesTab:AddSlider({
    Name = "Distância da Câmera (Max)",
    Min = 10,
    Max = 500,
    Default = 128,
    Color = Color3.fromRGB(255,255,255),
    Increment = 10,
    ValueName = "Studs",
    Callback = function(Value)
        Player.CameraMaxZoomDistance = Value
        Notify("Câmera", "Distância máxima: " .. Value, 2)
    end    
})

UtilitiesTab:AddSlider({
    Name = "Distância da Câmera (Min)",
    Min = 0,
    Max = 50,
    Default = 0.5,
    Color = Color3.fromRGB(255,255,255),
    Increment = 0.5,
    ValueName = "Studs",
    Callback = function(Value)
        Player.CameraMinZoomDistance = Value
    end    
})

UtilitiesTab:AddSection({
    Name = "Controles e Input"
})

UtilitiesTab:AddToggle({
    Name = "Shift Lock Sempre Ativo",
    Default = false,
    Callback = function(Value)
        if Value then
            Player.DevEnableMouseLock = true
            Notify("Shift Lock", "Shift Lock ativado!", 2)
        else
            Player.DevEnableMouseLock = false
        end
    end    
})

UtilitiesTab:AddButton({
    Name = "Resetar Controles",
    Callback = function()
        Player.CameraMode = Enum.CameraMode.Classic
        Player.CameraMaxZoomDistance = 128
        Player.CameraMinZoomDistance = 0.5
        Notify("Controles", "Controles resetados!", 2)
    end    
})

UtilitiesTab:AddSection({
    Name = "Nome e Display"
})

UtilitiesTab:AddButton({
    Name = "Remover Nome do Personagem",
    Callback = function()
        local character = GetCharacter()
        if character then
            local head = character:FindFirstChild("Head")
            if head then
                for _, obj in pairs(head:GetChildren()) do
                    if obj:IsA("BillboardGui") then
                        obj:Destroy()
                    end
                end
                Notify("Display", "Nome removido!", 2)
            end
        end
    end    
})

UtilitiesTab:AddTextbox({
    Name = "Texto Customizado Acima da Cabeça",
    Default = "",
    TextDisappear = false,
    Callback = function(Value)
        local character = GetCharacter()
        if character then
            local head = character:FindFirstChild("Head")
            if head then
                -- Remove billboards antigos
                for _, obj in pairs(head:GetChildren()) do
                    if obj:IsA("BillboardGui") and obj.Name == "CustomNameTag" then
                        obj:Destroy()
                    end
                end
                
                -- Cria novo billboard
                local billboard = Instance.new("BillboardGui")
                billboard.Name = "CustomNameTag"
                billboard.Size = UDim2.new(0, 200, 0, 50)
                billboard.StudsOffset = Vector3.new(0, 3, 0)
                billboard.AlwaysOnTop = true
                billboard.Parent = head
                
                local textLabel = Instance.new("TextLabel")
                textLabel.Size = UDim2.new(1, 0, 1, 0)
                textLabel.BackgroundTransparency = 1
                textLabel.Text = Value
                textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                textLabel.TextScaled = true
                textLabel.Font = Enum.Font.SourceSansBold
                textLabel.Parent = billboard
                
                Notify("Display", "Texto customizado adicionado!", 2)
            end
        end
    end    
})

UtilitiesTab:AddSection({
    Name = "Ferramentas e Itens"
})

UtilitiesTab:AddButton({
    Name = "Dropar Todas as Ferramentas",
    Callback = function()
        local character = GetCharacter()
        if character then
            for _, tool in pairs(character:GetChildren()) do
                if tool:IsA("Tool") then
                    tool.Parent = Workspace
                end
            end
            Notify("Ferramentas", "Todas as ferramentas dropadas!", 2)
        end
    end    
})

UtilitiesTab:AddButton({
    Name = "Deletar Ferramentas do Inventário",
    Callback = function()
        local backpack = Player:FindFirstChild("Backpack")
        if backpack then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    tool:Destroy()
                end
            end
            Notify("Inventário", "Inventário limpo!", 2)
        end
    end    
})

UtilitiesTab:AddButton({
    Name = "Equipar Todas as Ferramentas",
    Callback = function()
        local backpack = Player:FindFirstChild("Backpack")
        local character = GetCharacter()
        local humanoid = GetHumanoid()
        
        if backpack and humanoid then
            for _, tool in pairs(backpack:GetChildren()) do
                if tool:IsA("Tool") then
                    humanoid:EquipTool(tool)
                    wait(0.1)
                end
            end
        end
    end    
})

UtilitiesTab:AddSection({
    Name = "Física do Personagem"
})

UtilitiesTab:AddToggle({
    Name = "Ragdoll Manual",
    Default = false,
    Callback = function(Value)
        local character = GetCharacter()
        if character then
            for _, joint in pairs(character:GetDescendants()) do
                if joint:IsA("Motor6D") then
                    if Value then
                        joint.Enabled = false
                    else
                        joint.Enabled = true
                    end
                end
            end
        end
    end    
})

UtilitiesTab:AddButton({
    Name = "Congelar Posição",
    Callback = function()
        local root = GetRootPart()
        if root then
            root.Anchored = true
            Notify("Física", "Posição congelada!", 2)
        end
    end    
})

UtilitiesTab:AddButton({
    Name = "Descongelar Posição",
    Callback = function()
        local root = GetRootPart()
        if root then
            root.Anchored = false
            Notify("Física", "Posição descongelada!", 2)
        end
    end    
})

UtilitiesTab:AddSection({
    Name = "Respawn e Reset"
})

UtilitiesTab:AddButton({
    Name = "Respawn Instantâneo",
    Callback = function()
        local char = Player.Character
        if char then
            char:BreakJoints()
            Player:LoadCharacter()
        end
    end    
})

UtilitiesTab:AddButton({
    Name = "Teleportar para Spawn",
    Callback = function()
        local spawnLocation = Workspace:FindFirstChild("SpawnLocation") or Workspace:FindFirstChildOfClass("SpawnLocation")
        if spawnLocation then
            TeleportTo(spawnLocation.Position)
        else
            Notify("Erro", "Spawn não encontrado!", 3)
        end
    end    
})

-- ═══════════════════════════════════════════════════════════════
-- TAB 6: TOOLS & BUILDING
-- ═══════════════════════════════════════════════════════════════

local ToolsTab = Window:MakeTab({
    Name = "🔨 Ferramentas",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ToolsTab:AddSection({
    Name = "Construção e Edição"
})

ToolsTab:AddButton({
    Name = "Criar Plataforma sob Você",
    Callback = function()
        local root = GetRootPart()
        if root then
            local platform = Instance.new("Part")
            platform.Size = Vector3.new(10, 1, 10)
            platform.Position = root.Position - Vector3.new(0, 5, 0)
            platform.Anchored = true
            platform.BrickColor = BrickColor.new("Bright blue")
            platform.Material = Enum.Material.Neon
            platform.Parent = Workspace
            Notify("Build", "Plataforma criada!", 2)
        end
    end    
})

ToolsTab:AddButton({
    Name = "Criar Escada para Cima",
    Callback = function()
        local root = GetRootPart()
        if root then
            for i = 1, 20 do
                local step = Instance.new("Part")
                step.Size = Vector3.new(8, 1, 8)
                step.Position = root.Position + Vector3.new(0, i * 3, i * 2)
                step.Anchored = true
                step.BrickColor = BrickColor.Random()
                step.Parent = Workspace
                wait(0.05)
            end
            Notify("Build", "Escada criada!", 2)
        end
    end    
})

ToolsTab:AddButton({
    Name = "Criar Torre de Observação",
    Callback = function()
        local root = GetRootPart()
        if root then
            -- Base
            local base = Instance.new("Part")
            base.Size = Vector3.new(15, 1, 15)
            base.Position = root.Position
            base.Anchored = true
            base.BrickColor = BrickColor.new("Dark stone grey")
            base.Parent = Workspace
            
            -- Torre
            local tower = Instance.new("Part")
            tower.Size = Vector3.new(2, 50, 2)
            tower.Position = root.Position + Vector3.new(0, 25, 0)
            tower.Anchored = true
            tower.BrickColor = BrickColor.new("Medium stone grey")
            tower.Parent = Workspace
            
            -- Plataforma superior
            local top = Instance.new("Part")
            top.Size = Vector3.new(12, 1, 12)
            top.Position = root.Position + Vector3.new(0, 50, 0)
            top.Anchored = true
            top.BrickColor = BrickColor.new("Bright red")
            top.Material = Enum.Material.Neon
            top.Parent = Workspace
            
            Notify("Build", "Torre criada! Voe até o topo!", 3)
        end
    end    
})

ToolsTab:AddSection({
    Name = "Spawn de Objetos"
})

local objectSize = 5
local objectColor = Color3.fromRGB(255, 255, 255)

ToolsTab:AddSlider({
    Name = "Tamanho do Objeto",
    Min = 1,
    Max = 50,
    Default = 5,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Studs",
    Callback = function(Value)
        objectSize = Value
    end    
})

ToolsTab:AddColorpicker({
    Name = "Cor do Objeto",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function(Value)
        objectColor = Value
    end      
})

ToolsTab:AddButton({
    Name = "Spawnar Cubo",
    Callback = function()
        local root = GetRootPart()
        if root then
            local part = Instance.new("Part")
            part.Size = Vector3.new(objectSize, objectSize, objectSize)
            part.Position = root.Position + root.CFrame.LookVector * 10
            part.Anchored = true
            part.Color = objectColor
            part.Parent = Workspace
            Notify("Spawn", "Cubo criado!", 2)
        end
    end    
})

ToolsTab:AddButton({
    Name = "Spawnar Esfera",
    Callback = function()
        local root = GetRootPart()
        if root then
            local part = Instance.new("Part")
            part.Shape = Enum.PartType.Ball
            part.Size = Vector3.new(objectSize, objectSize, objectSize)
            part.Position = root.Position + root.CFrame.LookVector * 10
            part.Anchored = true
            part.Color = objectColor
            part.Parent = Workspace
            Notify("Spawn", "Esfera criada!", 2)
        end
    end    
})

ToolsTab:AddButton({
    Name = "Spawnar Cilindro",
    Callback = function()
        local root = GetRootPart()
        if root then
            local part = Instance.new("Part")
            part.Shape = Enum.PartType.Cylinder
            part.Size = Vector3.new(objectSize, objectSize, objectSize)
            part.Position = root.Position + root.CFrame.LookVector * 10
            part.Anchored = true
            part.Color = objectColor
            part.Parent = Workspace
            Notify("Spawn", "Cilindro criado!", 2)
        end
    end    
})

ToolsTab:AddSection({
    Name = "Efeitos Especiais"
})

ToolsTab:AddButton({
    Name = "Criar Explosão",
    Callback = function()
        local root = GetRootPart()
        if root then
            local explosion = Instance.new("Explosion")
            explosion.Position = root.Position + root.CFrame.LookVector * 20
            explosion.BlastRadius = 30
            explosion.BlastPressure = 500000
            explosion.Parent = Workspace
            Notify("FX", "Explosão criada!", 2)
        end
    end    
})

ToolsTab:AddButton({
    Name = "Criar Partículas de Fogo",
    Callback = function()
        local root = GetRootPart()
        if root then
            local fire = Instance.new("Fire")
            fire.Size = 20
            fire.Heat = 25
            fire.Parent = root
            
            spawn(function()
                wait(10)
                fire:Destroy()
            end)
            
            Notify("FX", "Efeito de fogo adicionado!", 2)
        end
    end    
})

ToolsTab:AddButton({
    Name = "Criar Fumaça",
    Callback = function()
        local root = GetRootPart()
        if root then
            local smoke = Instance.new("Smoke")
            smoke.Size = 20
            smoke.Opacity = 0.8
            smoke.RiseVelocity = 5
            smoke.Parent = root
            
            spawn(function()
                wait(10)
                smoke:Destroy()
            end)
            
            Notify("FX", "Efeito de fumaça adicionado!", 2)
        end
    end    
})

ToolsTab:AddButton({
    Name = "Criar Brilho (Sparkles)",
    Callback = function()
        local root = GetRootPart()
        if root then
            local sparkles = Instance.new("Sparkles")
            sparkles.Parent = root
            
            spawn(function()
                wait(10)
                sparkles:Destroy()
            end)
            
            Notify("FX", "Efeito de brilho adicionado!", 2)
        end
    end    
})

ToolsTab:AddSection({
    Name = "Limpeza"
})

ToolsTab:AddButton({
    Name = "Deletar Objetos Criados Recentemente",
    Callback = function()
        -- Deleta partes não nomeadas (geralmente criadas por scripts)
        local deleted = 0
        for _, part in pairs(Workspace:GetChildren()) do
            if part:IsA("BasePart") and part.Name == "Part" then
                part:Destroy()
                deleted = deleted + 1
            end
        end
        Notify("Limpeza", "Deletados " .. deleted .. " objetos!", 2)
    end    
})

ToolsTab:AddButton({
    Name = "Remover Todos os Efeitos do Personagem",
    Callback = function()
        local character = GetCharacter()
        if character then
            for _, obj in pairs(character:GetDescendants()) do
                if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") or obj:IsA("ParticleEmitter") then
                    obj:Destroy()
                end
            end
            Notify("Limpeza", "Efeitos removidos!", 2)
        end
    end    
})

-- ═══════════════════════════════════════════════════════════════
-- TAB 7: WORKSPACE (Mantido e editado)
-- ═══════════════════════════════════════════════════════════════

local WorkspaceTab = Window:MakeTab({
    Name = "🌍 Workspace",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

WorkspaceTab:AddSection({
    Name = "Manipulação do Workspace"
})

WorkspaceTab:AddButton({
    Name = "Remover Todas as Portas",
    Callback = function()
        local removed = 0
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find("door") and obj:IsA("BasePart") then
                obj:Destroy()
                removed = removed + 1
            end
        end
        Notify("Workspace", "Removidas " .. removed .. " portas!", 3)
    end    
})

WorkspaceTab:AddButton({
    Name = "Remover Todos os Obstáculos",
    Callback = function()
        local removed = 0
        for _, obj in pairs(Workspace:GetDescendants()) do
            if (obj.Name:lower():find("wall") or obj.Name:lower():find("barrier")) and obj:IsA("BasePart") then
                obj:Destroy()
                removed = removed + 1
            end
        end
        Notify("Workspace", "Removidos " .. removed .. " obstáculos!", 3)
    end    
})

WorkspaceTab:AddButton({
    Name = "Tornar Tudo Não-Colidível",
    Callback = function()
        for _, part in pairs(Workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
        Notify("Workspace", "Todas as partes agora são não-colidíveis!", 3)
    end    
})

WorkspaceTab:AddButton({
    Name = "Deletar Todos os Veículos",
    Callback = function()
        local removed = 0
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find("vehicle") or obj.Name:lower():find("car") then
                obj:Destroy()
                removed = removed + 1
            end
        end
        Notify("Workspace", "Removidos " .. removed .. " veículos!", 3)
    end    
})

WorkspaceTab:AddSection({
    Name = "Exploração"
})

WorkspaceTab:AddButton({
    Name = "Listar Todas as Pastas no Workspace",
    Callback = function()
        local folders = {}
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj:IsA("Folder") or obj:IsA("Model") then
                table.insert(folders, obj.Name)
            end
        end
        
        print("=== PASTAS NO WORKSPACE ===")
        for _, name in pairs(folders) do
            print(name)
        end
        Notify("Workspace", "Confira o console (F9) para ver as pastas!", 4)
    end    
})

WorkspaceTab:AddButton({
    Name = "Encontrar Todas as Moedas",
    Callback = function()
        local coins = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj.Name:lower():find("coin") and obj:IsA("BasePart") then
                table.insert(coins, obj)
            end
        end
        
        print("=== MOEDAS ENCONTRADAS (" .. #coins .. ") ===")
        for i, coin in pairs(coins) do
            print(i, coin:GetFullName())
        end
        Notify("Workspace", "Encontradas " .. #coins .. " moedas! Veja o console (F9)", 4)
    end    
})

WorkspaceTab:AddButton({
    Name = "Encontrar Todos os NPCs",
    Callback = function()
        local npcs = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
                table.insert(npcs, obj.Name)
            end
        end
        
        print("=== NPCs ENCONTRADOS (" .. #npcs .. ") ===")
        for i, npc in pairs(npcs) do
            print(i, npc)
        end
        Notify("Workspace", "Encontrados " .. #npcs .. " NPCs! Veja o console (F9)", 4)
    end    
})

-- ═══════════════════════════════════════════════════════════════
-- TAB 7: MISC (DIVERSOS)
-- ═══════════════════════════════════════════════════════════════

-- ═══════════════════════════════════════════════════════════════
-- TAB 8: SOUND & MUSIC
-- ═══════════════════════════════════════════════════════════════

local SoundTab = Window:MakeTab({
    Name = "🎵 Som",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

SoundTab:AddSection({
    Name = "Controle de Áudio"
})

SoundTab:AddSlider({
    Name = "Volume Mestre",
    Min = 0,
    Max = 10,
    Default = 0.5,
    Color = Color3.fromRGB(255,255,255),
    Increment = 0.1,
    ValueName = "Volume",
    Callback = function(Value)
        for _, sound in pairs(Workspace:GetDescendants()) do
            if sound:IsA("Sound") then
                sound.Volume = Value
            end
        end
    end    
})

SoundTab:AddButton({
    Name = "Mutar Todos os Sons",
    Callback = function()
        for _, sound in pairs(Workspace:GetDescendants()) do
            if sound:IsA("Sound") then
                sound.Volume = 0
            end
        end
        Notify("Som", "Todos os sons mutados!", 2)
    end    
})

SoundTab:AddButton({
    Name = "Pausar Todos os Sons",
    Callback = function()
        for _, sound in pairs(Workspace:GetDescendants()) do
            if sound:IsA("Sound") and sound.Playing then
                sound:Pause()
            end
        end
        Notify("Som", "Todos os sons pausados!", 2)
    end    
})

SoundTab:AddButton({
    Name = "Retomar Todos os Sons",
    Callback = function()
        for _, sound in pairs(Workspace:GetDescendants()) do
            if sound:IsA("Sound") then
                sound:Resume()
            end
        end
        Notify("Som", "Sons retomados!", 2)
    end    
})

SoundTab:AddButton({
    Name = "Deletar Todos os Sons",
    Callback = function()
        local deleted = 0
        for _, sound in pairs(Workspace:GetDescendants()) do
            if sound:IsA("Sound") then
                sound:Destroy()
                deleted = deleted + 1
            end
        end
        Notify("Som", deleted .. " sons deletados!", 2)
    end    
})

SoundTab:AddSection({
    Name = "Tocar Música Customizada"
})

local soundId = ""
local customSound = nil

SoundTab:AddTextbox({
    Name = "ID da Música (Roblox)",
    Default = "",
    TextDisappear = false,
    Callback = function(Value)
        soundId = Value
    end    
})

SoundTab:AddSlider({
    Name = "Volume da Música",
    Min = 0,
    Max = 5,
    Default = 1,
    Color = Color3.fromRGB(255,255,255),
    Increment = 0.1,
    ValueName = "Volume",
    Callback = function(Value)
        if customSound then
            customSound.Volume = Value
        end
    end    
})

SoundTab:AddButton({
    Name = "Tocar Música",
    Callback = function()
        if soundId ~= "" then
            if customSound then
                customSound:Destroy()
            end
            
            customSound = Instance.new("Sound")
            customSound.SoundId = "rbxassetid://" .. soundId
            customSound.Volume = 1
            customSound.Looped = true
            customSound.Parent = Workspace
            customSound:Play()
            
            Notify("Música", "Tocando ID: " .. soundId, 3)
        else
            Notify("Erro", "Insira um ID de música!", 3)
        end
    end    
})

SoundTab:AddButton({
    Name = "Pausar Música",
    Callback = function()
        if customSound then
            customSound:Pause()
            Notify("Música", "Música pausada!", 2)
        end
    end    
})

SoundTab:AddButton({
    Name = "Parar Música",
    Callback = function()
        if customSound then
            customSound:Stop()
            customSound:Destroy()
            customSound = nil
            Notify("Música", "Música parada!", 2)
        end
    end    
})

SoundTab:AddSection({
    Name = "Músicas Populares"
})

local popularSongs = {
    ["Dream Mask"] = "6914074883",
    ["Megalovania"] = "2996427130",
    ["Astronomia"] = "4919817721",
    ["Never Gonna Give You Up"] = "6760408114",
    ["Giorno Theme"] = "4924703901",
    ["Jojo To Be Continued"] = "2697431795",
    ["OMFG Hello"] = "2581460615",
    ["Scary Monsters"] = "143994596"
}

for songName, songId in pairs(popularSongs) do
    SoundTab:AddButton({
        Name = "Tocar: " .. songName,
        Callback = function()
            if customSound then
                customSound:Destroy()
            end
            
            customSound = Instance.new("Sound")
            customSound.SoundId = "rbxassetid://" .. songId
            customSound.Volume = 1
            customSound.Looped = true
            customSound.Parent = Workspace
            customSound:Play()
            
            Notify("🎵", "Tocando: " .. songName, 3)
        end    
    })
end

SoundTab:AddSection({
    Name = "Efeitos Sonoros"
})

SoundTab:AddButton({
    Name = "Reverb/Echo em Todos os Sons",
    Callback = function()
        for _, sound in pairs(Workspace:GetDescendants()) do
            if sound:IsA("Sound") then
                local reverb = Instance.new("ReverbSoundEffect")
                reverb.Parent = sound
            end
        end
        Notify("FX", "Efeito reverb aplicado!", 2)
    end    
})

SoundTab:AddButton({
    Name = "Distorção em Todos os Sons",
    Callback = function()
        for _, sound in pairs(Workspace:GetDescendants()) do
            if sound:IsA("Sound") then
                local distortion = Instance.new("DistortionSoundEffect")
                distortion.Level = 0.75
                distortion.Parent = sound
            end
        end
        Notify("FX", "Efeito distorção aplicado!", 2)
    end    
})

SoundTab:AddButton({
    Name = "Remover Efeitos Sonoros",
    Callback = function()
        for _, sound in pairs(Workspace:GetDescendants()) do
            if sound:IsA("Sound") then
                for _, effect in pairs(sound:GetChildren()) do
                    if effect:IsA("SoundEffect") then
                        effect:Destroy()
                    end
                end
            end
        end
        Notify("FX", "Efeitos removidos!", 2)
    end    
})

-- ═══════════════════════════════════════════════════════════════
-- TAB 8: MISC (DIVERSOS) - Atualizado
-- ═══════════════════════════════════════════════════════════════

local MiscTab = Window:MakeTab({
    Name = "🔧 Misc",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

MiscTab:AddSection({
    Name = "Anti-AFK"
})

MiscTab:AddToggle({
    Name = "Anti-AFK",
    Default = false,
    Save = true,
    Flag = "AntiAFK",
    Callback = function(Value)
        ToggleAntiAFK(Value)
    end    
})

MiscTab:AddSection({
    Name = "Chat"
})

MiscTab:AddTextbox({
    Name = "Mensagem do Chat",
    Default = "Hello!",
    TextDisappear = false,
    Callback = function(Value)
    end    
})

MiscTab:AddButton({
    Name = "Enviar Mensagem",
    Callback = function()
        local msg = "Hello!"
        SendChatMessage(msg)
    end    
})

MiscTab:AddButton({
    Name = "Spam Chat (10x)",
    Callback = function()
        SpamChat("Spam!", 10, 0.5)
    end    
})

MiscTab:AddSection({
    Name = "Servidor"
})

MiscTab:AddButton({
    Name = "Rejoin (Voltar ao Servidor)",
    Callback = function()
        RejoinServer()
    end    
})

MiscTab:AddButton({
    Name = "Server Hop (Trocar Servidor)",
    Callback = function()
        ServerHop()
    end    
})

MiscTab:AddButton({
    Name = "Copiar ID do Jogo",
    Callback = function()
        setclipboard(tostring(game.PlaceId))
        Notify("Misc", "ID do jogo copiado: " .. game.PlaceId, 3)
    end    
})

MiscTab:AddButton({
    Name = "Copiar Job ID",
    Callback = function()
        setclipboard(tostring(game.JobId))
        Notify("Misc", "Job ID copiado!", 3)
    end    
})

MiscTab:AddSection({
    Name = "Informações"
})

MiscTab:AddLabel("Nome do Jogo: " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name)
MiscTab:AddLabel("Jogadores no Servidor: " .. #Players:GetPlayers())
MiscTab:AddLabel("Seu Nome: " .. Player.Name)
MiscTab:AddLabel("Seu DisplayName: " .. Player.DisplayName)
MiscTab:AddLabel("Seu UserID: " .. Player.UserId)

MiscTab:AddSection({
    Name = "Ações Rápidas"
})

MiscTab:AddButton({
    Name = "Limpar Console (F9)",
    Callback = function()
        for i = 1, 100 do
            print(" ")
        end
        Notify("Console", "Console limpo!", 2)
    end    
})

MiscTab:AddButton({
    Name = "Mostrar FPS no Console",
    Callback = function()
        local fps = 0
        local lastUpdate = tick()
        
        RunService.Heartbeat:Connect(function()
            if tick() - lastUpdate >= 1 then
                print("FPS: " .. fps)
                fps = 0
                lastUpdate = tick()
            else
                fps = fps + 1
            end
        end)
        
        Notify("FPS", "Monitoramento de FPS iniciado no console!", 3)
    end    
})

-- ═══════════════════════════════════════════════════════════════
-- TAB 9: ADMIN COMMANDS
-- ═══════════════════════════════════════════════════════════════

local AdminTab = Window:MakeTab({
    Name = "👑 Admin",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

AdminTab:AddSection({
    Name = "Comandos de Admin (Requer Permissões)"
})

AdminTab:AddButton({
    Name = "Kickar Jogador Selecionado",
    Callback = function()
        if SelectedPlayer then
            local targetPlayer = Players:FindFirstChild(SelectedPlayer)
            if targetPlayer then
                targetPlayer:Kick("Você foi kickado!")
            end
        else
            Notify("Erro", "Selecione um jogador primeiro!", 3)
        end
    end    
})

AdminTab:AddButton({
    Name = "Banir Jogador (Kick Loop)",
    Callback = function()
        if SelectedPlayer then
            local targetPlayer = Players:FindFirstChild(SelectedPlayer)
            if targetPlayer then
                while targetPlayer.Parent do
                    targetPlayer:Kick("Banido!")
                    wait(0.1)
                end
            end
        else
            Notify("Erro", "Selecione um jogador primeiro!", 3)
        end
    end    
})

AdminTab:AddButton({
    Name = "Congelar Jogador",
    Callback = function()
        if SelectedPlayer then
            local targetPlayer = Players:FindFirstChild(SelectedPlayer)
            if targetPlayer and targetPlayer.Character then
                local root = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Anchored = true
                    Notify("Admin", targetPlayer.Name .. " foi congelado!", 3)
                end
            end
        else
            Notify("Erro", "Selecione um jogador primeiro!", 3)
        end
    end    
})

AdminTab:AddButton({
    Name = "Descongelar Jogador",
    Callback = function()
        if SelectedPlayer then
            local targetPlayer = Players:FindFirstChild(SelectedPlayer)
            if targetPlayer and targetPlayer.Character then
                local root = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Anchored = false
                    Notify("Admin", targetPlayer.Name .. " foi descongelado!", 3)
                end
            end
        else
            Notify("Erro", "Selecione um jogador primeiro!", 3)
        end
    end    
})

AdminTab:AddSection({
    Name = "Modificações de Servidor"
})

AdminTab:AddButton({
    Name = "Limpar Todo o Workspace",
    Callback = function()
        for _, obj in pairs(Workspace:GetChildren()) do
            if obj ~= Camera and not obj:IsA("Terrain") and obj.Name ~= "Baseplate" then
                obj:Destroy()
            end
        end
        Notify("Admin", "Workspace limpo!", 3)
    end    
})

AdminTab:AddButton({
    Name = "Remover Todos os Scripts do Workspace",
    Callback = function()
        local removed = 0
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Script") or obj:IsA("LocalScript") then
                obj:Destroy()
                removed = removed + 1
            end
        end
        Notify("Admin", "Removidos " .. removed .. " scripts!", 3)
    end    
})

AdminTab:AddSection({
    Name = "Ferramentas de Admin"
})

AdminTab:AddButton({
    Name = "Infinite Yield (Admin Commands)",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
        Notify("Admin", "Infinite Yield carregado!", 3)
    end    
})

AdminTab:AddButton({
    Name = "Teleportar Todos para Você",
    Callback = function()
        local root = GetRootPart()
        if not root then return end
        
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= Player and player.Character then
                local theirRoot = player.Character:FindFirstChild("HumanoidRootPart")
                if theirRoot then
                    theirRoot.CFrame = root.CFrame + Vector3.new(math.random(-10, 10), 0, math.random(-10, 10))
                end
            end
        end
        Notify("Teleporte", "Todos trazidos para você!", 3)
    end    
})

AdminTab:AddButton({
    Name = "Explodir Todos (Visual)",
    Callback = function()
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local explosion = Instance.new("Explosion")
                    explosion.Position = root.Position
                    explosion.BlastRadius = 10
                    explosion.BlastPressure = 100000
                    explosion.Parent = Workspace
                end
            end
        end
        Notify("Admin", "Explosões criadas!", 2)
    end    
})

AdminTab:AddSection({
    Name = "Modificações Visuais de Jogadores"
})

AdminTab:AddButton({
    Name = "Tornar Todos Invisíveis",
    Callback = function()
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                for _, part in pairs(player.Character:GetDescendants()) do
                    if part:IsA("BasePart") or part:IsA("Decal") then
                        part.Transparency = 1
                    end
                end
            end
        end
        Notify("Admin", "Todos invisíveis!", 2)
    end    
})

AdminTab:AddButton({
    Name = "Fogo em Todos",
    Callback = function()
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                local root = player.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local fire = Instance.new("Fire")
                    fire.Size = 10
                    fire.Parent = root
                end
            end
        end
        Notify("Admin", "Fogo adicionado a todos!", 2)
    end    
})

AdminTab:AddButton({
    Name = "Remover Efeitos de Todos",
    Callback = function()
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                for _, obj in pairs(player.Character:GetDescendants()) do
                    if obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then
                        obj:Destroy()
                    end
                end
            end
        end
        Notify("Admin", "Efeitos removidos!", 2)
    end    
})

-- ═══════════════════════════════════════════════════════════════
-- TAB 10: SCRIPTS CUSTOMIZADOS
-- ═══════════════════════════════════════════════════════════════

local ScriptsTab = Window:MakeTab({
    Name = "📜 Scripts",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

ScriptsTab:AddSection({
    Name = "Executor de Scripts"
})

local ScriptToExecute = ""

ScriptsTab:AddTextbox({
    Name = "Cole seu Script Aqui",
    Default = "",
    TextDisappear = false,
    Callback = function(Value)
        ScriptToExecute = Value
    end    
})

ScriptsTab:AddButton({
    Name = "Executar Script",
    Callback = function()
        if ScriptToExecute ~= "" then
            local success, err = pcall(function()
                loadstring(ScriptToExecute)()
            end)
            
            if success then
                Notify("Script", "Script executado com sucesso!", 3)
            else
                Notify("Erro", "Erro ao executar script: " .. tostring(err), 5)
            end
        else
            Notify("Erro", "Cole um script primeiro!", 3)
        end
    end    
})

ScriptsTab:AddSection({
    Name = "Scripts Populares"
})

ScriptsTab:AddButton({
    Name = "Infinite Yield",
    Callback = function()
        loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()
    end    
})

ScriptsTab:AddButton({
    Name = "Dark Dex",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Babyhamsta/RBLX_Scripts/main/Universal/BypassedDarkDexV3.lua", true))()
    end    
})

ScriptsTab:AddButton({
    Name = "Remote Spy",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/exxtremestuffs/SimpleSpySource/master/SimpleSpy.lua"))()
    end    
})

ScriptsTab:AddButton({
    Name = "Universal ESP",
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/GhostPlayer352/Test4/main/UniversalEsp"))()
    end    
})

-- ═══════════════════════════════════════════════════════════════
-- TAB 11: CONFIGURAÇÕES
-- ═══════════════════════════════════════════════════════════════

local SettingsTab = Window:MakeTab({
    Name = "⚙️ Configurações",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

SettingsTab:AddSection({
    Name = "Interface"
})

SettingsTab:AddButton({
    Name = "Destruir GUI",
    Callback = function()
        OrionLib:Destroy()
    end    
})

SettingsTab:AddSection({
    Name = "Temas"
})

local themes = {"Default", "Eclipse", "Dark", "Light", "Neon", "Purple"}

for _, theme in pairs(themes) do
    SettingsTab:AddButton({
        Name = "Tema: " .. theme,
        Callback = function()
            OrionLib.SelectedTheme = theme
            Notify("Tema", "Tema alterado para " .. theme .. "! Recarregue o script.", 4)
        end    
    })
end

SettingsTab:AddSection({
    Name = "Informações do Script"
})

SettingsTab:AddLabel("Versão: 3.5.0")
SettingsTab:AddLabel("Desenvolvido com OrionLib")
SettingsTab:AddLabel("Script Universal para Roblox")
SettingsTab:AddLabel("Última Atualização: 2026")
SettingsTab:AddLabel("Total de Abas: 12")
SettingsTab:AddLabel("Linhas de Código: ~2900+")

SettingsTab:AddSection({
    Name = "Créditos"
})

SettingsTab:AddParagraph("Desenvolvedor", "Este é um script universal desenvolvido para demonstrar as capacidades do OrionLib. Use com responsabilidade!")

SettingsTab:AddParagraph("Aviso", "Este script é apenas para fins educacionais. O uso em jogos reais pode resultar em banimento. Use por sua conta e risco.")

SettingsTab:AddParagraph("Features", "✅ ESP • ✅ Voo • ✅ NoClip • ✅ Teleporte • ✅ Waypoints • ✅ Animações • ✅ Construção • ✅ Som • ✅ Admin Tools")

-- ═══════════════════════════════════════════════════════════════
-- ATUALIZAÇÃO AUTOMÁTICA DE LISTAS
-- ═══════════════════════════════════════════════════════════════

spawn(function()
    while wait(5) do
        if PlayerDropdown then
            PlayerDropdown:Refresh(GetAllPlayersExceptMe(), false)
        end
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- EVENTOS DE PERSONAGEM
-- ═══════════════════════════════════════════════════════════════

Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
    RootPart = char:WaitForChild("HumanoidRootPart")
    
    wait(1)
    
    if ScriptSettings.WalkSpeed ~= 16 then
        SetWalkSpeed(ScriptSettings.WalkSpeed)
    end
    
    if ScriptSettings.JumpPower ~= 50 then
        SetJumpPower(ScriptSettings.JumpPower)
    end
    
    if ScriptSettings.InfiniteJump then
        ToggleInfiniteJump(true)
    end
    
    if ScriptSettings.NoClip then
        ToggleNoClip(true)
    end
end)

-- ═══════════════════════════════════════════════════════════════
-- INICIALIZAÇÃO FINAL
-- ═══════════════════════════════════════════════════════════════

Notify("Script Carregado!", "Universal Script Hub v3.5 carregado com sucesso!", 5)

-- Detecta se está em mobile
local IsMobile = (UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled)
if IsMobile then
    Notify("Mobile", "Modo Mobile detectado! Use com cuidado.", 4)
end

-- Inicializa a biblioteca
OrionLib:Init()

-- ═══════════════════════════════════════════════════════════════
-- CLEANUP AO FECHAR
-- ═══════════════════════════════════════════════════════════════

game:GetService("CoreGui").DescendantRemoving:Connect(function(descendant)
    if descendant.Name == "Orion" then
        for _, connection in pairs(Connections) do
            if connection then
                connection:Disconnect()
            end
        end
        
        for _, esp in pairs(ESPObjects) do
            if esp then
                esp:Destroy()
            end
        end
        
        if flyBV then flyBV:Destroy() end
        if flyBG then flyBG:Destroy() end
        
        if OriginalValues.WalkSpeed then
            SetWalkSpeed(16)
        end
        
        if OriginalValues.Brightness then
            ToggleFullBright(false)
        end
        
        if OriginalValues.FogEnd then
            ToggleRemoveFog(false)
        end
        
        Workspace.Gravity = 196.2
        Camera.FieldOfView = 70
    end
end)

print("═══════════════════════════════════════════════════════════════")
print("    UNIVERSAL SCRIPT HUB v3.5 - CARREGADO COM SUCESSO")
print("═══════════════════════════════════════════════════════════════")
print("Desenvolvido com OrionLib")
print("Total de Linhas: ~2900+")
print("Features: Player, Visual, Teleporte, Animações, Utilidades,")
print("          Ferramentas, Workspace, Som, Misc, Admin, Scripts,")
print("          Configurações, Waypoints, Efeitos Especiais")
print("═══════════════════════════════════════════════════════════════")
print("")
print("📋 11 ABAS FUNCIONAIS:")
print("1. 👤 Player - Movimento, voo, noclip")
print("2. 👁️ Visual - ESP, FullBright, FOV, X-Ray")
print("3. 📍 Teleporte - Jogadores, objetos, waypoints customizados")
print("4. 💃 Animações - Emotes, controle de animações")
print("5. 🎮 Utilidades - Câmera, controles, ferramentas")
print("6. 🔨 Ferramentas - Construção, spawn de objetos, FX")
print("7. 🌍 Workspace - Manipulação do ambiente")
print("8. 🎵 Som - Música customizada, controle de áudio")
print("9. 🔧 Misc - Anti-AFK, chat, servidor")
print("10. 👑 Admin - Comandos administrativos")
print("11. 📜 Scripts - Executor + scripts populares")
print("12. ⚙️ Configurações - Temas, UI, créditos")
print("═══════════════════════════════════════════════════════════════")
