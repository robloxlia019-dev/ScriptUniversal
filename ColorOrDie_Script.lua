-- ╔══════════════════════════════════════════════════════════╗
-- ║           COLOR OR DIE - ULTIMATE SCRIPT HUB            ║
-- ║                  Powered by Rayfield UI                  ║
-- ╚══════════════════════════════════════════════════════════╝

-- ─── CARREGA RAYFIELD ───────────────────────────────────────
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ─── SERVIÇOS ───────────────────────────────────────────────
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local Workspace        = game:GetService("Workspace")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui       = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- ─── FLAGS & ESTADO ─────────────────────────────────────────
local Flags = {
    -- ESP
    MonsterESP       = false,
    PlayerESP        = false,
    SafeZoneESP      = false,
    KeyESP           = false,
    DoorESP          = false,
    GemESP           = false,
    BrushESP         = false,
    PaintESP         = false,
    -- Movement
    SpeedHack        = false,
    SpeedValue       = 16,
    Noclip           = false,
    InfJump          = false,
    AntiKill         = false,
    -- Safe Zone
    AutoSafeZone     = false,
    AutoMatchColor   = false,
    -- Visuals
    FullBright       = false,
    NoFog            = false,
    CamFOV           = 70,
    PlayerChams      = false,
    -- Monster
    MonsterSpeed     = false,
    MonsterSpeedVal  = 16,
    FreezeMonster    = false,
    -- Game
    AutoEscape       = false,
    AutoKey          = false,
    AutoDoor         = false,
    SpamPaint        = false,
    -- Misc
    GodMode          = false,
    NoClipColor      = false,
}

local Connections   = {}
local ESPObjects    = {}
local ActiveConns   = {}

-- ═══════════════════════════════════════════════════════════
--                    FUNÇÕES CORE
-- ═══════════════════════════════════════════════════════════

local function SafeNotify(title, content, duration, img)
    Rayfield:Notify({
        Title   = title,
        Content = content,
        Duration = duration or 3,
        Image   = img or "4483362458",
    })
end

local function GetChar()
    return LocalPlayer.Character
end

local function GetHRP()
    local c = GetChar()
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function GetHum()
    local c = GetChar()
    return c and c:FindFirstChild("Humanoid")
end

local function Teleport(pos, offset)
    local hrp = GetHRP()
    if hrp then
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, offset or 4, 0))
    end
end

local function DistanceTo(pos)
    local hrp = GetHRP()
    if not hrp then return math.huge end
    return (hrp.Position - pos).Magnitude
end

-- Disconnect seguro
local function DisconnectAll(tbl)
    for _, c in pairs(tbl) do
        if c and c.Connected then c:Disconnect() end
    end
end

-- ═══════════════════════════════════════════════════════════
--                    SISTEMA ESP
-- ═══════════════════════════════════════════════════════════

local function MakeESP(instance, fillColor, outlineColor, labelText, tag)
    if not instance or not instance.Parent then return end

    -- Limpa antigo
    local oldHL   = instance:FindFirstChild("__ESP_HL_" .. (tag or ""))
    local oldBill = instance:FindFirstChild("__ESP_BILL_" .. (tag or ""))
    if oldHL then oldHL:Destroy() end
    if oldBill then oldBill:Destroy() end

    -- Highlight
    local hl = Instance.new("Highlight")
    hl.Name             = "__ESP_HL_" .. (tag or "")
    hl.FillColor        = fillColor
    hl.OutlineColor     = outlineColor or Color3.new(1,1,1)
    hl.FillTransparency = 0.45
    hl.OutlineTransparency = 0
    hl.DepthMode        = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent           = instance

    -- BillboardGui
    local bill = Instance.new("BillboardGui")
    bill.Name           = "__ESP_BILL_" .. (tag or "")
    bill.AlwaysOnTop    = true
    bill.Size           = UDim2.new(0, 120, 0, 45)
    bill.StudsOffset    = Vector3.new(0, 4, 0)
    bill.Parent         = instance

    local bg = Instance.new("Frame")
    bg.Size             = UDim2.new(1,0,1,0)
    bg.BackgroundColor3 = Color3.fromRGB(0,0,0)
    bg.BackgroundTransparency = 0.5
    bg.BorderSizePixel  = 0
    bg.Parent           = bill

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0,6)
    corner.Parent       = bg

    local txt = Instance.new("TextLabel")
    txt.Size              = UDim2.new(1,0,1,0)
    txt.BackgroundTransparency = 1
    txt.TextColor3        = fillColor
    txt.TextStrokeColor3  = Color3.new(0,0,0)
    txt.TextStrokeTransparency = 0
    txt.Font              = Enum.Font.GothamBold
    txt.TextScaled        = true
    txt.Text              = labelText or ""
    txt.Parent            = bg

    -- Atualiza distância em tempo real
    local conn = RunService.RenderStepped:Connect(function()
        if not instance or not instance.Parent then
            pcall(function() hl:Destroy() end)
            pcall(function() bill:Destroy() end)
            return
        end
        local hrp = GetHRP()
        if not hrp then return end

        local pos
        if instance:IsA("Model") then
            local ok, pv = pcall(function() return instance:GetPivot().Position end)
            pos = ok and pv or nil
        elseif instance:IsA("BasePart") then
            pos = instance.Position
        end

        if pos then
            local dist = math.floor((hrp.Position - pos).Magnitude)
            txt.Text = (labelText or "") .. "\n[" .. dist .. "m]"
        end
    end)

    local entry = {hl=hl, bill=bill, conn=conn, tag=tag, inst=instance}
    table.insert(ESPObjects, entry)
    return entry
end

local function ClearESPByTag(tag)
    local kept = {}
    for _, obj in pairs(ESPObjects) do
        if obj.tag == tag then
            if obj.conn then obj.conn:Disconnect() end
            pcall(function() obj.hl:Destroy() end)
            pcall(function() obj.bill:Destroy() end)
        else
            table.insert(kept, obj)
        end
    end
    ESPObjects = kept
end

local function ClearAllESP()
    for _, obj in pairs(ESPObjects) do
        if obj.conn then obj.conn:Disconnect() end
        pcall(function() obj.hl:Destroy() end)
        pcall(function() obj.bill:Destroy() end)
    end
    ESPObjects = {}
end

-- ═══════════════════════════════════════════════════════════
--               FUNÇÕES DE BUSCA NO JOGO
-- ═══════════════════════════════════════════════════════════

local function FindMonsters()
    local list = {}
    -- Pasta Monsters
    local mFolder = Workspace:FindFirstChild("Monsters") or Workspace:FindFirstChild("Monster")
    if mFolder then
        for _, m in pairs(mFolder:GetDescendants()) do
            if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then
                table.insert(list, m)
            end
        end
    end
    -- Busca global
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local isPlayer = false
            for _, p in pairs(Players:GetPlayers()) do
                if p.Character == obj then isPlayer=true; break end
            end
            if not isPlayer and obj ~= LocalPlayer.Character then
                local already = false
                for _, m in pairs(list) do if m==obj then already=true; break end end
                if not already then table.insert(list, obj) end
            end
        end
    end
    return list
end

local function FindByName(names, deep)
    local results = {}
    local search = deep and Workspace:GetDescendants() or Workspace:GetChildren()
    for _, obj in pairs(search) do
        for _, name in pairs(names) do
            if obj.Name:lower():find(name:lower()) then
                table.insert(results, obj)
                break
            end
        end
    end
    return results
end

local function FindSafeZones()
    local list = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if (n == "safezone" or n == "safe zone" or n:find("safe") or n:find("colorzone") or n:find("color_")) and (obj:IsA("BasePart") or obj:IsA("Model")) then
            table.insert(list, obj)
        end
    end
    return list
end

local function FindColorZones()
    local list = {}
    local colors = {"Color_Red","Color_Blue","Color_Green","Color_Orange","Color_Pink","Color_Purple","Color_Teal","Color_Yellow"}
    for _, obj in pairs(Workspace:GetDescendants()) do
        for _, cn in pairs(colors) do
            if obj.Name == cn then
                table.insert(list, obj)
                break
            end
        end
    end
    return list
end

local function FindKeys()
    local list = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name:lower() == "key" or obj.Name:lower() == "keytemplate" then
            table.insert(list, obj)
        end
    end
    return list
end

local function FindDoors()
    local list = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("door") or n == "escapedoor" then
            table.insert(list, obj)
        end
    end
    return list
end

local function FindGems()
    local list = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n == "gem" or n == "gemstone" or n == "limited_gemstone" then
            table.insert(list, obj)
        end
    end
    return list
end

local function FindBrushes()
    local list = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n == "brush" or n == "bigbrush" or n == "paintbrush" or n == "brushtemplate" then
            table.insert(list, obj)
        end
    end
    return list
end

local function FindPaintBuckets()
    local list = {}
    for _, obj in pairs(Workspace:GetDescendants()) do
        local n = obj.Name:lower()
        if n:find("bucket") or n:find("paintbucket") then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                table.insert(list, obj)
            end
        end
    end
    return list
end

local function FindNearest(list, getPos)
    local hrp = GetHRP()
    if not hrp then return nil, math.huge end
    local best, bestDist = nil, math.huge
    for _, obj in pairs(list) do
        local pos = getPos and getPos(obj) or (obj:IsA("BasePart") and obj.Position or (obj:IsA("Model") and pcall(function() return obj:GetPivot().Position end) and obj:GetPivot().Position))
        if pos then
            local d = (hrp.Position - pos).Magnitude
            if d < bestDist then bestDist=d; best=obj end
        end
    end
    return best, bestDist
end

-- ═══════════════════════════════════════════════════════════
--                    RAYFIELD WINDOW
-- ═══════════════════════════════════════════════════════════

local Window = Rayfield:CreateWindow({
    Name             = "🎨 Color or Die Hub",
    Icon             = 0,
    LoadingTitle     = "Color or Die - Ultimate Hub",
    LoadingSubtitle  = "Carregando módulos...",
    Theme            = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving = {
        Enabled    = true,
        FolderName = "ColorOrDieHub",
        FileName   = "Config",
    },
    KeySystem = false,
})

-- ╔══════════════════════════════════════════════════════════╗
-- ║                    TAB 1 - ESP                           ║
-- ╚══════════════════════════════════════════════════════════╝

local ESPTab = Window:CreateTab("🔍 ESP", 4483362458)

ESPTab:CreateSection("Inimigos & Monstros")

ESPTab:CreateToggle({
    Name = "👁 ESP Monstros",
    CurrentValue = false,
    Flag = "MonsterESP",
    Callback = function(v)
        Flags.MonsterESP = v
        ClearESPByTag("monster")
        if not v then return end

        local function scan()
            ClearESPByTag("monster")
            for _, m in pairs(FindMonsters()) do
                local hum = m:FindFirstChildOfClass("Humanoid")
                local hp = hum and math.floor(hum.Health) or "?"
                MakeESP(m, Color3.fromRGB(255,50,50), Color3.fromRGB(255,150,150),
                    "👹 " .. m.Name .. "\nHP: " .. tostring(hp), "monster")
            end
        end

        scan()
        local c = RunService.Heartbeat:Connect(function()
            if not Flags.MonsterESP then return end
            scan()
            task.wait(2)
        end)
        table.insert(ActiveConns, c)
    end
})

ESPTab:CreateToggle({
    Name = "🧍 ESP Players",
    CurrentValue = false,
    Flag = "PlayerESP",
    Callback = function(v)
        Flags.PlayerESP = v
        ClearESPByTag("player")
        if not v then return end

        local function addP(p)
            if p == LocalPlayer then return end
            local function onChar(char)
                task.wait(1)
                if not Flags.PlayerESP then return end
                MakeESP(char, Color3.fromRGB(60,120,255), Color3.fromRGB(150,180,255),
                    "🎮 " .. p.Name, "player")
            end
            if p.Character then onChar(p.Character) end
            p.CharacterAdded:Connect(onChar)
        end

        for _, p in pairs(Players:GetPlayers()) do addP(p) end
        local c = Players.PlayerAdded:Connect(addP)
        table.insert(ActiveConns, c)
    end
})

ESPTab:CreateSection("Objetos do Mapa")

ESPTab:CreateToggle({
    Name = "🟩 ESP Safe Zones / Color Zones",
    CurrentValue = false,
    Flag = "SafeZoneESP",
    Callback = function(v)
        Flags.SafeZoneESP = v
        ClearESPByTag("safezone")
        if not v then return end

        local colorMap = {
            Color_Red    = Color3.fromRGB(255,60,60),
            Color_Blue   = Color3.fromRGB(60,100,255),
            Color_Green  = Color3.fromRGB(60,200,60),
            Color_Orange = Color3.fromRGB(255,140,0),
            Color_Pink   = Color3.fromRGB(255,105,180),
            Color_Purple = Color3.fromRGB(160,32,240),
            Color_Teal   = Color3.fromRGB(0,200,200),
            Color_Yellow = Color3.fromRGB(255,230,0),
        }

        local zones = FindColorZones()
        for _, z in pairs(zones) do
            local c = colorMap[z.Name] or Color3.fromRGB(0,255,0)
            MakeESP(z, c, Color3.new(1,1,1), "🎨 " .. z.Name:gsub("Color_",""), "safezone")
        end

        -- Safe zones genéricas
        for _, z in pairs(FindSafeZones()) do
            MakeESP(z, Color3.fromRGB(0,255,100), Color3.new(1,1,1), "✅ SAFE", "safezone")
        end
    end
})

ESPTab:CreateToggle({
    Name = "🗝 ESP Chaves (Keys)",
    CurrentValue = false,
    Flag = "KeyESP",
    Callback = function(v)
        Flags.KeyESP = v
        ClearESPByTag("key")
        if not v then return end

        local function scan()
            ClearESPByTag("key")
            for _, k in pairs(FindKeys()) do
                MakeESP(k, Color3.fromRGB(255,215,0), Color3.fromRGB(255,255,100), "🗝 KEY", "key")
            end
        end
        scan()
        local c = RunService.Heartbeat:Connect(function()
            if not Flags.KeyESP then return end
            scan(); task.wait(1)
        end)
        table.insert(ActiveConns, c)
    end
})

ESPTab:CreateToggle({
    Name = "🚪 ESP Portas (Doors)",
    CurrentValue = false,
    Flag = "DoorESP",
    Callback = function(v)
        Flags.DoorESP = v
        ClearESPByTag("door")
        if not v then return end

        for _, d in pairs(FindDoors()) do
            MakeESP(d, Color3.fromRGB(180,120,60), Color3.fromRGB(220,160,80), "🚪 " .. d.Name, "door")
        end
    end
})

ESPTab:CreateToggle({
    Name = "💎 ESP Gems / Gemstones",
    CurrentValue = false,
    Flag = "GemESP",
    Callback = function(v)
        Flags.GemESP = v
        ClearESPByTag("gem")
        if not v then return end

        local function scan()
            ClearESPByTag("gem")
            for _, g in pairs(FindGems()) do
                MakeESP(g, Color3.fromRGB(100,255,220), Color3.fromRGB(200,255,240), "💎 GEM", "gem")
            end
        end
        scan()
        local c = RunService.Heartbeat:Connect(function()
            if not Flags.GemESP then return end
            scan(); task.wait(1.5)
        end)
        table.insert(ActiveConns, c)
    end
})

ESPTab:CreateToggle({
    Name = "🖌 ESP Pincéis (Brushes)",
    CurrentValue = false,
    Flag = "BrushESP",
    Callback = function(v)
        Flags.BrushESP = v
        ClearESPByTag("brush")
        if not v then return end

        local function scan()
            ClearESPByTag("brush")
            for _, b in pairs(FindBrushes()) do
                MakeESP(b, Color3.fromRGB(255,180,0), Color3.fromRGB(255,220,100), "🖌 BRUSH", "brush")
            end
        end
        scan()
        local c = RunService.Heartbeat:Connect(function()
            if not Flags.BrushESP then return end
            scan(); task.wait(1.5)
        end)
        table.insert(ActiveConns, c)
    end
})

ESPTab:CreateToggle({
    Name = "🪣 ESP Paint Buckets",
    CurrentValue = false,
    Flag = "PaintESP",
    Callback = function(v)
        Flags.PaintESP = v
        ClearESPByTag("paint")
        if not v then return end

        local function scan()
            ClearESPByTag("paint")
            for _, b in pairs(FindPaintBuckets()) do
                MakeESP(b, Color3.fromRGB(200,80,255), Color3.fromRGB(220,150,255), "🪣 BUCKET", "paint")
            end
        end
        scan()
        local c = RunService.Heartbeat:Connect(function()
            if not Flags.PaintESP then return end
            scan(); task.wait(2)
        end)
        table.insert(ActiveConns, c)
    end
})

ESPTab:CreateSection("Controles")

ESPTab:CreateButton({
    Name = "🗑 Limpar Todos os ESPs",
    Callback = function()
        ClearAllESP()
        -- Reset todas flags ESP
        Flags.MonsterESP  = false
        Flags.PlayerESP   = false
        Flags.SafeZoneESP = false
        Flags.KeyESP      = false
        Flags.DoorESP     = false
        Flags.GemESP      = false
        Flags.BrushESP    = false
        Flags.PaintESP    = false
        SafeNotify("ESPs Limpos", "Todos os highlights foram removidos.", 2)
    end
})

-- ╔══════════════════════════════════════════════════════════╗
-- ║                 TAB 2 - MOVIMENTAÇÃO                     ║
-- ╚══════════════════════════════════════════════════════════╝

local MoveTab = Window:CreateTab("🏃 Movimento", 4483362458)

MoveTab:CreateSection("Velocidade & Pulo")

MoveTab:CreateToggle({
    Name = "⚡ Speed Hack",
    CurrentValue = false,
    Flag = "SpeedHack",
    Callback = function(v)
        Flags.SpeedHack = v
        local hum = GetHum()
        if hum then
            hum.WalkSpeed = v and Flags.SpeedValue or 16
        end
    end
})

MoveTab:CreateSlider({
    Name = "🔢 Velocidade (WalkSpeed)",
    Range = {16, 350},
    Increment = 5,
    Suffix = " sp",
    CurrentValue = 16,
    Flag = "SpeedValue",
    Callback = function(v)
        Flags.SpeedValue = v
        if Flags.SpeedHack then
            local hum = GetHum()
            if hum then hum.WalkSpeed = v end
        end
    end
})

MoveTab:CreateToggle({
    Name = "🦘 Pulo Infinito",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(v)
        Flags.InfJump = v
        if v then
            local c = UserInputService.JumpRequest:Connect(function()
                if not Flags.InfJump then return end
                local hum = GetHum()
                if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
            end)
            table.insert(ActiveConns, c)
        end
    end
})

MoveTab:CreateSlider({
    Name = "🦘 Altura do Pulo",
    Range = {50, 500},
    Increment = 10,
    Suffix = " jp",
    CurrentValue = 50,
    Flag = "JumpPower",
    Callback = function(v)
        local hum = GetHum()
        if hum then
            hum.JumpPower = v
            hum.UseJumpPower = true
        end
    end
})

MoveTab:CreateSection("Colisão")

MoveTab:CreateToggle({
    Name = "👻 Noclip (Atravessa Paredes)",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v)
        Flags.Noclip = v
        if v then
            local c = RunService.Stepped:Connect(function()
                if not Flags.Noclip then return end
                local char = GetChar()
                if char then
                    for _, p in pairs(char:GetDescendants()) do
                        if p:IsA("BasePart") then p.CanCollide = false end
                    end
                end
            end)
            table.insert(ActiveConns, c)
        else
            local char = GetChar()
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end
    end
})

MoveTab:CreateToggle({
    Name = "🎨 Sem Colisão com Tinta (NoClip Paint)",
    CurrentValue = false,
    Flag = "NoClipColor",
    Callback = function(v)
        Flags.NoClipColor = v
        local c = RunService.Stepped:Connect(function()
            if not Flags.NoClipColor then return end
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") then
                    local n = obj.Name:lower()
                    if n:find("paint") or n:find("color") or n:find("safe") or n:find("zone") then
                        obj.CanCollide = false
                    end
                end
            end
        end)
        table.insert(ActiveConns, c)
    end
})

MoveTab:CreateSection("Sobrevivência")

MoveTab:CreateToggle({
    Name = "❤️ God Mode (HP Infinito)",
    CurrentValue = false,
    Flag = "GodMode",
    Callback = function(v)
        Flags.GodMode = v
        if v then
            local c = RunService.Heartbeat:Connect(function()
                if not Flags.GodMode then return end
                local hum = GetHum()
                if hum then hum.Health = hum.MaxHealth end
            end)
            table.insert(ActiveConns, c)
        end
    end
})

MoveTab:CreateToggle({
    Name = "🛡 Anti-Kill (Evita KillParts)",
    CurrentValue = false,
    Flag = "AntiKill",
    Callback = function(v)
        Flags.AntiKill = v
        if v then
            local c = RunService.Stepped:Connect(function()
                if not Flags.AntiKill then return end
                for _, obj in pairs(Workspace:GetDescendants()) do
                    if obj.Name == "KillPart" and obj:IsA("BasePart") then
                        obj.CanTouch = false
                        obj.CanCollide = false
                    end
                end
            end)
            table.insert(ActiveConns, c)
        end
    end
})

-- Mantém speed após respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    task.wait(0.5)
    local hum = char:FindFirstChild("Humanoid")
    if not hum then return end
    if Flags.SpeedHack then hum.WalkSpeed = Flags.SpeedValue end
    if Flags.GodMode then
        RunService.Heartbeat:Connect(function()
            if Flags.GodMode and hum then hum.Health = hum.MaxHealth end
        end)
    end
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║               TAB 3 - TELEPORTE                          ║
-- ╚══════════════════════════════════════════════════════════╝

local TeleTab = Window:CreateTab("📍 Teleporte", 4483362458)

TeleTab:CreateSection("Teleporte de Emergência")

TeleTab:CreateButton({
    Name = "🚨 Fugir do Monstro (Teleporte Rápido)",
    Callback = function()
        local monsters = FindMonsters()
        if #monsters == 0 then
            SafeNotify("Sem Monstros", "Nenhum monstro encontrado!", 2)
            return
        end
        local hrp = GetHRP()
        if not hrp then return end

        -- Acha monstro mais próximo
        local nearestM, nearestDist = nil, math.huge
        for _, m in pairs(monsters) do
            local mhrp = m:FindFirstChild("HumanoidRootPart")
            if mhrp then
                local d = (hrp.Position - mhrp.Position).Magnitude
                if d < nearestDist then nearestDist=d; nearestM=mhrp end
            end
        end

        if nearestM then
            -- Foge na direção oposta
            local dir = (hrp.Position - nearestM.Position).Unit
            Teleport(hrp.Position + dir * 80)
            SafeNotify("🚨 Fuga!", "Teleportado para longe do monstro!", 2)
        end
    end
})

TeleTab:CreateButton({
    Name = "🎨 Teleportar para Safe Zone Mais Próxima",
    Callback = function()
        local zones = FindColorZones()
        if #zones == 0 then zones = FindSafeZones() end
        if #zones == 0 then
            SafeNotify("Sem Zonas", "Nenhuma color zone encontrada!", 2)
            return
        end

        local hrp = GetHRP()
        if not hrp then return end
        local best, bestDist = nil, math.huge
        for _, z in pairs(zones) do
            local pos
            if z:IsA("BasePart") then pos = z.Position
            elseif z:IsA("Model") then
                local ok, pv = pcall(function() return z:GetPivot().Position end)
                if ok then pos = pv end
            end
            if pos then
                local d = (hrp.Position - pos).Magnitude
                if d < bestDist then bestDist=d; best=pos end
            end
        end
        if best then
            Teleport(best, 2)
            SafeNotify("✅ Safe Zone", "Teleportado para zona segura!", 2)
        end
    end
})

TeleTab:CreateButton({
    Name = "🗝 Teleportar para Chave Mais Próxima",
    Callback = function()
        local keys = FindKeys()
        if #keys == 0 then
            SafeNotify("Sem Chaves", "Nenhuma chave encontrada no mapa!", 2)
            return
        end
        local hrp = GetHRP()
        if not hrp then return end
        local best, bestDist = nil, math.huge
        for _, k in pairs(keys) do
            local pos = k:IsA("BasePart") and k.Position or (k:IsA("Model") and pcall(function() return k:GetPivot().Position end) and k:GetPivot().Position)
            if pos then
                local d = (hrp.Position - pos).Magnitude
                if d < bestDist then bestDist=d; best=pos end
            end
        end
        if best then
            Teleport(best)
            SafeNotify("🗝 Chave!", "Teleportado para a chave (" .. math.floor(bestDist) .. "m)", 2)
        end
    end
})

TeleTab:CreateButton({
    Name = "🚪 Teleportar para Porta de Saída",
    Callback = function()
        local doors = {}
        for _, obj in pairs(Workspace:GetDescendants()) do
            local n = obj.Name:lower()
            if n == "escapedoor" or n == "endingdoor1" or n == "endingdoor2" or n:find("escape") then
                table.insert(doors, obj)
            end
        end
        if #doors == 0 then
            SafeNotify("Sem Porta", "Porta de escape não encontrada!", 2)
            return
        end
        local hrp = GetHRP()
        if not hrp then return end
        local best, bestDist = nil, math.huge
        for _, d in pairs(doors) do
            local pos = d:IsA("BasePart") and d.Position or (d:IsA("Model") and pcall(function() return d:GetPivot().Position end) and d:GetPivot().Position)
            if pos then
                local dist = (hrp.Position - pos).Magnitude
                if dist < bestDist then bestDist=dist; best=pos end
            end
        end
        if best then
            Teleport(best)
            SafeNotify("🚪 Saída!", "Teleportado para porta de escape!", 2)
        end
    end
})

TeleTab:CreateButton({
    Name = "💎 Teleportar para Gem Mais Próxima",
    Callback = function()
        local gems = FindGems()
        if #gems == 0 then
            SafeNotify("Sem Gems", "Nenhuma gem encontrada!", 2)
            return
        end
        local hrp = GetHRP()
        if not hrp then return end
        local best, bestDist = nil, math.huge
        for _, g in pairs(gems) do
            local pos = g:IsA("BasePart") and g.Position or nil
            if pos then
                local d = (hrp.Position - pos).Magnitude
                if d < bestDist then bestDist=d; best=pos end
            end
        end
        if best then
            Teleport(best)
            SafeNotify("💎 Gem!", "Teleportado para gem (" .. math.floor(bestDist) .. "m)", 2)
        end
    end
})

TeleTab:CreateButton({
    Name = "🏠 Teleportar para Lobby",
    Callback = function()
        local lobby = Workspace:FindFirstChild("Lobby") or Workspace:FindFirstChild("LobbyDressing")
        if lobby then
            local pos
            if lobby:IsA("BasePart") then pos = lobby.Position
            elseif lobby:IsA("Model") then
                local ok, pv = pcall(function() return lobby:GetPivot().Position end)
                if ok then pos = pv end
            end
            if pos then
                Teleport(pos)
                SafeNotify("🏠 Lobby", "Teleportado para o lobby!", 2)
                return
            end
        end
        -- Tenta spawn
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("SpawnLocation") then
                Teleport(obj.Position)
                SafeNotify("🏠 Spawn", "Teleportado para spawn!", 2)
                return
            end
        end
        SafeNotify("Lobby", "Lobby não encontrado no mapa atual.", 2)
    end
})

TeleTab:CreateSection("Teleporte para Player")

TeleTab:CreateInput({
    Name = "👤 Nome do Player",
    PlaceholderText = "Digite o nome exato...",
    RemoveTextAfterFocusLost = false,
    Callback = function(text)
        local target = Players:FindFirstChild(text)
        if target and target.Character then
            local tHrp = target.Character:FindFirstChild("HumanoidRootPart")
            if tHrp then
                Teleport(tHrp.Position)
                SafeNotify("📍 Teleportado!", "Você foi para " .. text, 2)
                return
            end
        end
        SafeNotify("❌ Não encontrado", "Player '" .. text .. "' não está no jogo.", 3)
    end
})

TeleTab:CreateButton({
    Name = "📋 Listar Players Online",
    Callback = function()
        local hrp = GetHRP()
        local names = ""
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                local d = "?"
                if hrp and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    d = math.floor((hrp.Position - p.Character.HumanoidRootPart.Position).Magnitude) .. "m"
                end
                names = names .. "• " .. p.Name .. " [" .. d .. "]\n"
            end
        end
        if names == "" then names = "Nenhum outro player online." end
        SafeNotify("🎮 Players Online", names, 6)
    end
})

-- ╔══════════════════════════════════════════════════════════╗
-- ║               TAB 4 - AUTO PLAY                          ║
-- ╚══════════════════════════════════════════════════════════╝

local AutoTab = Window:CreateTab("🤖 Auto Play", 4483362458)

AutoTab:CreateSection("Auto Sobrevivência")

AutoTab:CreateToggle({
    Name = "🎨 Auto Safe Zone (Vai pra zona certa)",
    CurrentValue = false,
    Flag = "AutoSafeZone",
    Callback = function(v)
        Flags.AutoSafeZone = v
        if not v then return end

        local c = RunService.Heartbeat:Connect(function()
            if not Flags.AutoSafeZone then return end
            local hrp = GetHRP()
            if not hrp then return end

            -- Detecta qual cor está "ativa" (colorbar ou similar)
            -- Tenta achar zona mais próxima que não seja preta
            local zones = FindColorZones()
            if #zones == 0 then zones = FindSafeZones() end
            if #zones == 0 then return end

            -- Vai para a zona mais próxima
            local best, bestDist = nil, math.huge
            for _, z in pairs(zones) do
                local pos
                if z:IsA("BasePart") then pos = z.Position
                elseif z:IsA("Model") then
                    local ok, pv = pcall(function() return z:GetPivot().Position end)
                    if ok then pos = pv end
                end
                if pos then
                    local d = (hrp.Position - pos).Magnitude
                    if d < bestDist then bestDist=d; best=pos end
                end
            end

            if best and bestDist > 8 then
                Teleport(best, 1)
            end
            task.wait(1.5)
        end)
        table.insert(ActiveConns, c)
    end
})

AutoTab:CreateToggle({
    Name = "🗝 Auto Pegar Chave",
    CurrentValue = false,
    Flag = "AutoKey",
    Callback = function(v)
        Flags.AutoKey = v
        if not v then return end

        local c = RunService.Heartbeat:Connect(function()
            if not Flags.AutoKey then return end
            local keys = FindKeys()
            if #keys == 0 then return end
            local hrp = GetHRP()
            if not hrp then return end

            local best, bestDist = nil, math.huge
            for _, k in pairs(keys) do
                local pos = k:IsA("BasePart") and k.Position or nil
                if pos then
                    local d = (hrp.Position - pos).Magnitude
                    if d < bestDist then bestDist=d; best=pos end
                end
            end

            if best and bestDist > 4 then
                Teleport(best, 1)
            end
            task.wait(0.8)
        end)
        table.insert(ActiveConns, c)
    end
})

AutoTab:CreateToggle({
    Name = "🚪 Auto Abrir Portas",
    CurrentValue = false,
    Flag = "AutoDoor",
    Callback = function(v)
        Flags.AutoDoor = v
        if not v then return end

        local c = RunService.Heartbeat:Connect(function()
            if not Flags.AutoDoor then return end
            local hrp = GetHRP()
            if not hrp then return end

            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("BasePart") and obj.Name:lower():find("door") then
                    local d = (hrp.Position - obj.Position).Magnitude
                    if d < 10 then
                        -- Simula clique/proximidade
                        obj.Transparency = 1
                        obj.CanCollide = false
                    end
                end
            end
            task.wait(0.5)
        end)
        table.insert(ActiveConns, c)
    end
})

AutoTab:CreateSection("Auto Farm")

AutoTab:CreateToggle({
    Name = "💎 Auto Coletar Gems",
    CurrentValue = false,
    Flag = "AutoGem",
    Callback = function(v)
        if not v then return end
        local c = RunService.Heartbeat:Connect(function()
            if not Flags.AutoGem then return end
            local gems = FindGems()
            if #gems == 0 then return end
            local hrp = GetHRP()
            if not hrp then return end
            local best, bestPos = nil, nil
            local bestDist = math.huge
            for _, g in pairs(gems) do
                local pos = g:IsA("BasePart") and g.Position or nil
                if pos then
                    local d = (hrp.Position - pos).Magnitude
                    if d < bestDist then bestDist=d; bestPos=pos end
                end
            end
            if bestPos and bestDist > 4 then Teleport(bestPos, 1) end
            task.wait(0.5)
        end)
        Flags.AutoGem = v
        table.insert(ActiveConns, c)
    end
})

AutoTab:CreateToggle({
    Name = "🖌 Auto Coletar Pincéis",
    CurrentValue = false,
    Flag = "AutoBrush",
    Callback = function(v)
        Flags.AutoBrush = v
        if not v then return end
        local c = RunService.Heartbeat:Connect(function()
            if not Flags.AutoBrush then return end
            local brushes = FindBrushes()
            if #brushes == 0 then return end
            local hrp = GetHRP()
            if not hrp then return end
            local best, bestDist = nil, math.huge
            for _, b in pairs(brushes) do
                local pos = b:IsA("BasePart") and b.Position or nil
                if pos then
                    local d = (hrp.Position - pos).Magnitude
                    if d < bestDist then bestDist=d; best=pos end
                end
            end
            if best and bestDist > 4 then Teleport(best, 1) end
            task.wait(0.5)
        end)
        table.insert(ActiveConns, c)
    end
})

AutoTab:CreateSection("Monster Mode")

AutoTab:CreateToggle({
    Name = "😈 Auto Caçar Players (Monster Mode)",
    CurrentValue = false,
    Flag = "AutoHunt",
    Callback = function(v)
        Flags.AutoHunt = v
        if not v then return end
        local c = RunService.Heartbeat:Connect(function()
            if not Flags.AutoHunt then return end
            local hrp = GetHRP()
            if not hrp then return end

            local bestP, bestDist = nil, math.huge
            for _, p in pairs(Players:GetPlayers()) do
                if p ~= LocalPlayer and p.Character then
                    local pHrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if pHrp then
                        local d = (hrp.Position - pHrp.Position).Magnitude
                        if d < bestDist then bestDist=d; bestP=pHrp end
                    end
                end
            end

            if bestP and bestDist > 5 then
                Teleport(bestP.Position)
            end
            task.wait(0.3)
        end)
        table.insert(ActiveConns, c)
    end
})

-- ╔══════════════════════════════════════════════════════════╗
-- ║              TAB 5 - MONSTRO                             ║
-- ╚══════════════════════════════════════════════════════════╝

local MonsterTab = Window:CreateTab("👹 Monstro", 4483362458)

MonsterTab:CreateSection("Info & ESP")

MonsterTab:CreateButton({
    Name = "📊 Info de Monstros no Mapa",
    Callback = function()
        local monsters = FindMonsters()
        if #monsters == 0 then
            SafeNotify("👹 Monstros", "Nenhum monstro no mapa!", 3)
            return
        end
        local hrp = GetHRP()
        local info = ""
        for i, m in pairs(monsters) do
            local mhrp = m:FindFirstChild("HumanoidRootPart")
            local hum = m:FindFirstChildOfClass("Humanoid")
            local dist = hrp and mhrp and math.floor((hrp.Position - mhrp.Position).Magnitude) or "?"
            local hp = hum and math.floor(hum.Health) or "?"
            info = info .. i .. ". " .. m.Name .. "\n   HP: " .. hp .. " | Dist: " .. dist .. "m\n"
        end
        SafeNotify("👹 " .. #monsters .. " Monstro(s)", info, 7)
    end
})

MonsterTab:CreateButton({
    Name = "📍 Teleportar para Monstro Mais Próximo",
    Callback = function()
        local monsters = FindMonsters()
        if #monsters == 0 then
            SafeNotify("👹", "Nenhum monstro encontrado!", 2)
            return
        end
        local hrp = GetHRP()
        if not hrp then return end
        local best, bestDist = nil, math.huge
        for _, m in pairs(monsters) do
            local mhrp = m:FindFirstChild("HumanoidRootPart")
            if mhrp then
                local d = (hrp.Position - mhrp.Position).Magnitude
                if d < bestDist then bestDist=d; best=mhrp.Position end
            end
        end
        if best then
            Teleport(best)
            SafeNotify("👹 Teleportado!", "Você foi para o monstro (" .. math.floor(bestDist) .. "m)", 2)
        end
    end
})

MonsterTab:CreateSection("Controle do Monstro")

MonsterTab:CreateToggle({
    Name = "🧊 Congelar Monstro (Freeze)",
    CurrentValue = false,
    Flag = "FreezeMonster",
    Callback = function(v)
        Flags.FreezeMonster = v
        if not v then
            -- Descongela
            for _, m in pairs(FindMonsters()) do
                local hum = m:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
            return
        end
        local c = RunService.Heartbeat:Connect(function()
            if not Flags.FreezeMonster then return end
            for _, m in pairs(FindMonsters()) do
                local hum = m:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 0 end
            end
        end)
        table.insert(ActiveConns, c)
    end
})

MonsterTab:CreateToggle({
    Name = "🐢 Deixar Monstro Lento",
    CurrentValue = false,
    Flag = "SlowMonster",
    Callback = function(v)
        Flags.SlowMonster = v
        if not v then
            for _, m in pairs(FindMonsters()) do
                local hum = m:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
            return
        end
        local c = RunService.Heartbeat:Connect(function()
            if not Flags.SlowMonster then return end
            for _, m in pairs(FindMonsters()) do
                local hum = m:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 2 end
            end
        end)
        table.insert(ActiveConns, c)
    end
})

MonsterTab:CreateSlider({
    Name = "Velocidade do Monstro",
    Range = {0, 100},
    Increment = 2,
    Suffix = " sp",
    CurrentValue = 16,
    Flag = "MonsterSpeedVal",
    Callback = function(v)
        for _, m in pairs(FindMonsters()) do
            local hum = m:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end
})

-- ╔══════════════════════════════════════════════════════════╗
-- ║               TAB 6 - VISUAIS                            ║
-- ╚══════════════════════════════════════════════════════════╝

local VisTab = Window:CreateTab("🌈 Visuais", 4483362458)

VisTab:CreateSection("Câmera & Iluminação")

VisTab:CreateSlider({
    Name = "🎥 Campo de Visão (FOV)",
    Range = {60, 130},
    Increment = 5,
    Suffix = "°",
    CurrentValue = 70,
    Flag = "CamFOV",
    Callback = function(v)
        Camera.FieldOfView = v
    end
})

VisTab:CreateToggle({
    Name = "☀️ FullBright (Mapa Claro)",
    CurrentValue = false,
    Flag = "FullBright",
    Callback = function(v)
        Flags.FullBright = v
        local lighting = game:GetService("Lighting")
        if v then
            lighting.Brightness = 10
            lighting.GlobalShadows = false
            lighting.FogEnd = 100000
            lighting.ClockTime = 12
            lighting.Ambient = Color3.fromRGB(255,255,255)
            lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
            for _, fx in pairs(lighting:GetChildren()) do
                if fx:IsA("BlurEffect") or fx:IsA("ColorCorrectionEffect") or fx:IsA("Atmosphere") then
                    fx.Enabled = false
                end
            end
        else
            lighting.Brightness = 2
            lighting.GlobalShadows = true
            lighting.ClockTime = 14
            for _, fx in pairs(lighting:GetChildren()) do
                if fx:IsA("BlurEffect") or fx:IsA("ColorCorrectionEffect") or fx:IsA("Atmosphere") then
                    fx.Enabled = true
                end
            end
        end
    end
})

VisTab:CreateToggle({
    Name = "🌫 Sem Névoa (No Fog)",
    CurrentValue = false,
    Flag = "NoFog",
    Callback = function(v)
        local lighting = game:GetService("Lighting")
        if v then
            lighting.FogStart = 0
            lighting.FogEnd = 999999
        end
    end
})

VisTab:CreateSection("Player Chams")

VisTab:CreateToggle({
    Name = "💜 Chams - Todos os Players",
    CurrentValue = false,
    Flag = "PlayerChams",
    Callback = function(v)
        Flags.PlayerChams = v
        if not v then
            ClearESPByTag("chams")
            return
        end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                MakeESP(p.Character, Color3.fromRGB(180,0,255), Color3.fromRGB(220,100,255), "● " .. p.Name, "chams")
            end
        end
    end
})

VisTab:CreateSection("Customização")

VisTab:CreateColorPicker({
    Name = "🎨 Cor do Seu Personagem",
    Color = Color3.fromRGB(255,255,255),
    Flag = "CharColor",
    Callback = function(v)
        local char = GetChar()
        if not char then return end
        for _, p in pairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.Color = v
            end
        end
    end
})

VisTab:CreateToggle({
    Name = "👁 Câmera Terceira Pessoa Fixa",
    CurrentValue = false,
    Flag = "ThirdPerson",
    Callback = function(v)
        if v then
            Camera.CameraType = Enum.CameraType.Custom
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
        end
    end
})

-- ╔══════════════════════════════════════════════════════════╗
-- ║               TAB 7 - INFORMAÇÕES                        ║
-- ╚══════════════════════════════════════════════════════════╝

local InfoTab = Window:CreateTab("📊 Info", 4483362458)

InfoTab:CreateSection("Status do Jogo")

InfoTab:CreateButton({
    Name = "🔍 Escanear Mapa Atual",
    Callback = function()
        local monsters = FindMonsters()
        local keys     = FindKeys()
        local gems     = FindGems()
        local doors    = FindDoors()
        local zones    = FindColorZones()
        local brushes  = FindBrushes()
        local players  = Players:GetPlayers()

        local info = string.format(
            "👹 Monstros: %d\n🎮 Players: %d\n🗝 Chaves: %d\n💎 Gems: %d\n🚪 Portas: %d\n🎨 Color Zones: %d\n🖌 Brushes: %d",
            #monsters, #players, #keys, #gems, #doors, #zones, #brushes
        )
        SafeNotify("📊 Scan do Mapa", info, 8)
    end
})

InfoTab:CreateButton({
    Name = "👤 Meu Status",
    Callback = function()
        local hrp = GetHRP()
        local hum = GetHum()
        if not hrp or not hum then return end

        local pos = hrp.Position
        local info = string.format(
            "💚 HP: %d / %d\n⚡ Speed: %d\n📍 Pos: %.0f, %.0f, %.0f\n🏃 Estado: %s",
            math.floor(hum.Health), math.floor(hum.MaxHealth),
            math.floor(hum.WalkSpeed),
            pos.X, pos.Y, pos.Z,
            tostring(hum:GetState())
        )
        SafeNotify("👤 " .. LocalPlayer.Name, info, 6)
    end
})

InfoTab:CreateButton({
    Name = "📡 Copiar Posição Atual",
    Callback = function()
        local hrp = GetHRP()
        if not hrp then return end
        local p = hrp.Position
        local str = string.format("Vector3.new(%.2f, %.2f, %.2f)", p.X, p.Y, p.Z)
        setclipboard(str)
        SafeNotify("📡 Copiado!", str, 3)
    end
})

InfoTab:CreateSection("FPS & Performance")

local fpsLabel = nil
InfoTab:CreateToggle({
    Name = "📈 Mostrar FPS no Notify",
    CurrentValue = false,
    Flag = "ShowFPS",
    Callback = function(v)
        if not v then return end
        local frames = 0
        local last = tick()
        local c = RunService.RenderStepped:Connect(function()
            if not Flags.ShowFPS then return end
            frames = frames + 1
            if tick() - last >= 2 then
                SafeNotify("📈 FPS", "FPS Atual: " .. math.floor(frames/2), 1.5)
                frames = 0
                last = tick()
            end
        end)
        Flags.ShowFPS = true
        table.insert(ActiveConns, c)
    end
})

InfoTab:CreateSection("Créditos")
InfoTab:CreateLabel("🎨 Color or Die - Ultimate Script Hub")
InfoTab:CreateLabel("Criado com base no mapa original do jogo")
InfoTab:CreateLabel("UI: Rayfield Library by Sirius")
InfoTab:CreateLabel("⚠️ Use por sua conta e risco")

-- ╔══════════════════════════════════════════════════════════╗
-- ║               TAB 8 - MISC                               ║
-- ╚══════════════════════════════════════════════════════════╝

local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

MiscTab:CreateSection("Utilidades Gerais")

MiscTab:CreateButton({
    Name = "🔄 Rejoin Servidor",
    Callback = function()
        local TS = game:GetService("TeleportService")
        TS:Teleport(game.PlaceId, LocalPlayer)
    end
})

MiscTab:CreateButton({
    Name = "💬 Spam Chat (Teste)",
    Callback = function()
        -- Apenas notifica
        SafeNotify("💬 Chat", "Use o chat do jogo normalmente.", 2)
    end
})

MiscTab:CreateToggle({
    Name = "🔕 Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(v)
        if v then
            local VIS = game:GetService("VirtualInputManager")
            local c = RunService.Heartbeat:Connect(function()
                if not Flags.AntiAFK then return end
                VIS:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                task.wait(60)
            end)
            Flags.AntiAFK = true
            table.insert(ActiveConns, c)
        else
            Flags.AntiAFK = false
        end
    end
})

MiscTab:CreateToggle({
    Name = "🚫 Esconder GUI do Jogo",
    CurrentValue = false,
    Flag = "HideGui",
    Callback = function(v)
        for _, gui in pairs(LocalPlayer.PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") and not gui.Name:find("Rayfield") then
                gui.Enabled = not v
            end
        end
    end
})

MiscTab:CreateSection("Render")

MiscTab:CreateToggle({
    Name = "🌑 Escurecer Mapa (Black Room)",
    CurrentValue = false,
    Flag = "DarkMap",
    Callback = function(v)
        local lighting = game:GetService("Lighting")
        if v then
            lighting.Brightness = 0
            lighting.Ambient = Color3.fromRGB(0,0,0)
            lighting.OutdoorAmbient = Color3.fromRGB(0,0,0)
        else
            lighting.Brightness = 2
            lighting.Ambient = Color3.fromRGB(70,70,70)
            lighting.OutdoorAmbient = Color3.fromRGB(128,128,128)
        end
    end
})

MiscTab:CreateToggle({
    Name = "🌈 Rainbow Character",
    CurrentValue = false,
    Flag = "Rainbow",
    Callback = function(v)
        Flags.Rainbow = v
        if not v then return end
        local hue = 0
        local c = RunService.RenderStepped:Connect(function()
            if not Flags.Rainbow then return end
            hue = (hue + 0.005) % 1
            local col = Color3.fromHSV(hue, 1, 1)
            local char = GetChar()
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                        p.Color = col
                    end
                end
            end
        end)
        table.insert(ActiveConns, c)
    end
})

MiscTab:CreateSection("Keybinds Rápidos")
MiscTab:CreateLabel("⌨️ DEL = Teleportar longe do monstro")
MiscTab:CreateLabel("⌨️ F1 = Toggle Speed Hack")
MiscTab:CreateLabel("⌨️ F2 = Toggle Noclip")
MiscTab:CreateLabel("⌨️ F3 = Toggle God Mode")
MiscTab:CreateLabel("⌨️ F4 = Ir pra Safe Zone")

-- ═══════════════════════════════════════════════════════════
--                    KEYBINDS GLOBAIS
-- ═══════════════════════════════════════════════════════════

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end

    -- DEL = Fuga rápida
    if input.KeyCode == Enum.KeyCode.Delete then
        local monsters = FindMonsters()
        local hrp = GetHRP()
        if monsters[1] and hrp then
            local mhrp = monsters[1]:FindFirstChild("HumanoidRootPart")
            if mhrp then
                local dir = (hrp.Position - mhrp.Position).Unit
                Teleport(hrp.Position + dir * 100)
                SafeNotify("🚨 Fuga!", "Keybind DEL ativado!", 1.5)
            end
        end

    -- F1 = Speed
    elseif input.KeyCode == Enum.KeyCode.F1 then
        Flags.SpeedHack = not Flags.SpeedHack
        local hum = GetHum()
        if hum then hum.WalkSpeed = Flags.SpeedHack and Flags.SpeedValue or 16 end
        SafeNotify("⚡ Speed", Flags.SpeedHack and "ON - " .. Flags.SpeedValue or "OFF", 1.5)

    -- F2 = Noclip
    elseif input.KeyCode == Enum.KeyCode.F2 then
        Flags.Noclip = not Flags.Noclip
        SafeNotify("👻 Noclip", Flags.Noclip and "ON" or "OFF", 1.5)

    -- F3 = God Mode
    elseif input.KeyCode == Enum.KeyCode.F3 then
        Flags.GodMode = not Flags.GodMode
        SafeNotify("❤️ God Mode", Flags.GodMode and "ON" or "OFF", 1.5)

    -- F4 = Safe Zone
    elseif input.KeyCode == Enum.KeyCode.F4 then
        local zones = FindColorZones()
        if #zones == 0 then zones = FindSafeZones() end
        if #zones > 0 then
            local best, bestDist = nil, math.huge
            local hrp = GetHRP()
            for _, z in pairs(zones) do
                local pos = z:IsA("BasePart") and z.Position or nil
                if pos and hrp then
                    local d = (hrp.Position - pos).Magnitude
                    if d < bestDist then bestDist=d; best=pos end
                end
            end
            if best then
                Teleport(best, 2)
                SafeNotify("🎨 Safe!", "F4: Safe Zone!", 1.5)
            end
        end
    end
end)

-- ═══════════════════════════════════════════════════════════
--                    INICIALIZAÇÃO
-- ═══════════════════════════════════════════════════════════

Rayfield:LoadConfiguration()

task.wait(1)
SafeNotify(
    "🎨 Color or Die Hub",
    "Script carregado! Use as abas para navegar.\n⌨️ DEL=Fuga | F1=Speed | F2=Noclip | F3=God | F4=Safe",
    7
)

print("[Color or Die Hub] ✅ Carregado com sucesso!")
