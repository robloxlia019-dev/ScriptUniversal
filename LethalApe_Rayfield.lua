-- ╔══════════════════════════════════════════════════════════════════╗
-- ║       LETHAL APE SCRIPT V3 - RAYFIELD UI                        ║
-- ║  AutoFarm Gold | ESP Bots | Anti-Scary | Anti-Jumpscare         ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- Carrega Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

-- ══════════════════════════════════
-- SERVIÇOS
-- ══════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")

local LP     = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ══════════════════════════════════
-- NOMES REAIS DO JOGO
-- ══════════════════════════════════
local BOT_FOLDERS = {"bots", "bots2", "bots3", "bots4", "bots5"}
local GOLD_NAMES  = {"Prop_GoldBar", "CoinCollection", "gold", "Gold", "GoldBar"}

-- ══════════════════════════════════
-- CONFIG
-- ══════════════════════════════════
local Cfg = {
    Fullbright      = false,
    AntiEscurecer   = false,
    AntiJumpscare   = false,
    NoFog           = false,
    ESPBots         = false,
    ESPPlayers      = false,
    ESPGold         = false,
    ESPHighlight    = false,
    AutoFarmGold    = false,
    FarmDelay       = 0.25,
    SpeedHack       = false,
    SpeedValue      = 28,
    InfiniteJump    = false,
    Noclip          = false,
    AntiDeath       = false,
}

local OrigLighting = {
    Brightness     = Lighting.Brightness,
    Ambient        = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    FogEnd         = Lighting.FogEnd,
    ClockTime      = Lighting.ClockTime,
}

-- ══════════════════════════════════
-- HELPERS DO PERSONAGEM
-- ══════════════════════════════════
local function GetChar()   return LP.Character end
local function GetRoot()   local c = GetChar() return c and c:FindFirstChild("HumanoidRootPart") end
local function GetHuman()  local c = GetChar() return c and c:FindFirstChildWhichIsA("Humanoid") end

local function GetDistance(pos)
    local r = GetRoot()
    return r and (r.Position - pos).Magnitude or 9999
end

local function TeleportTo(pos)
    local r = GetRoot()
    if r then r.CFrame = CFrame.new(pos + Vector3.new(0, 4, 0)) end
end

-- ══════════════════════════════════
-- LIGHTING
-- ══════════════════════════════════
local function ApplyFullbright()
    Lighting.Brightness       = 3
    Lighting.ClockTime        = 14
    Lighting.FogEnd           = 100000
    Lighting.Ambient          = Color3.fromRGB(178, 178, 178)
    Lighting.OutdoorAmbient   = Color3.fromRGB(178, 178, 178)
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("BlurEffect") or fx:IsA("ColorCorrectionEffect")
        or fx:IsA("SunRaysEffect") or fx:IsA("DepthOfFieldEffect") then
            fx.Enabled = false
        end
    end
end

local function RestoreLighting()
    Lighting.Brightness       = OrigLighting.Brightness
    Lighting.Ambient          = OrigLighting.Ambient
    Lighting.OutdoorAmbient   = OrigLighting.OutdoorAmbient
    Lighting.FogEnd           = OrigLighting.FogEnd
    Lighting.ClockTime        = OrigLighting.ClockTime
    for _, fx in ipairs(Lighting:GetChildren()) do
        if fx:IsA("BlurEffect") or fx:IsA("ColorCorrectionEffect")
        or fx:IsA("SunRaysEffect") or fx:IsA("DepthOfFieldEffect") then
            fx.Enabled = true
        end
    end
end

local scaryObj = Lighting:FindFirstChild("scary")
task.spawn(function() scaryObj = Lighting:WaitForChild("scary", 10) end)

local function BlockScary()
    if scaryObj then pcall(function() scaryObj.Enabled = false end) end
    pcall(function()
        local opts = LP.PlayerScripts:FindFirstChild("options")
        if opts then
            local sv = opts:FindFirstChild("scary")
            if sv then sv.Value = false end
        end
    end)
end

-- ══════════════════════════════════
-- BOTS & GOLD
-- ══════════════════════════════════
local function GetAllBots()
    local bots = {}
    for _, fn in ipairs(BOT_FOLDERS) do
        local folder = workspace:FindFirstChild(fn)
        if folder then
            for _, m in ipairs(folder:GetChildren()) do
                if m:IsA("Model") then
                    local root = m:FindFirstChild("HumanoidRootPart")
                    if root then
                        table.insert(bots, {
                            model  = m,
                            root   = root,
                            hum    = m:FindFirstChildWhichIsA("Humanoid"),
                            name   = m.Name,
                            folder = fn,
                        })
                    end
                end
            end
        end
    end
    return bots
end

local function GetAllGold()
    local golds = {}
    local seen  = {}
    for _, obj in ipairs(workspace:GetDescendants()) do
        if not seen[obj] then
            local name = obj.Name:lower()
            for _, kw in ipairs(GOLD_NAMES) do
                if name:find(kw:lower()) then
                    local part = obj:IsA("Model")
                        and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart"))
                        or (obj:IsA("BasePart") and obj or nil)
                    if part and not part:FindFirstAncestorWhichIsA("Tool") then
                        seen[obj] = true
                        table.insert(golds, {part = part, name = obj.Name})
                    end
                    break
                end
            end
            if obj:IsA("ProximityPrompt") then
                local t = (obj.ActionText .. obj.ObjectText):lower()
                if t:find("gold") or t:find("collect") then
                    local p = obj.Parent
                    if p and p:IsA("BasePart") and not seen[p] then
                        seen[p] = true
                        table.insert(golds, {part = p, name = p.Name, prompt = obj})
                    end
                end
            end
        end
    end
    return golds
end

-- ══════════════════════════════════
-- AUTO FARM
-- ══════════════════════════════════
local farmRunning = false

local function StartFarm()
    if farmRunning then return end
    farmRunning = true
    task.spawn(function()
        while farmRunning do
            if not GetRoot() then task.wait(1) continue end
            local golds = GetAllGold()
            table.sort(golds, function(a,b)
                return GetDistance(a.part.Position) < GetDistance(b.part.Position)
            end)
            for _, g in ipairs(golds) do
                if not farmRunning then break end
                if g.part and g.part.Parent then
                    TeleportTo(g.part.Position)
                    if g.prompt then
                        pcall(function() fireproximityprompt(g.prompt) end)
                    end
                    task.wait(Cfg.FarmDelay)
                end
            end
            task.wait(0.4)
        end
    end)
end

local function StopFarm()
    farmRunning = false
end

-- ══════════════════════════════════
-- ESP
-- ══════════════════════════════════
local ESPFolder = Instance.new("Folder", CoreGui)
ESPFolder.Name  = "LA_ESP_V3"
local ESPCache  = {}
local HLCache   = {}

local function GetESP(key, color, adornee)
    if ESPCache[key] and ESPCache[key].bb.Parent then return ESPCache[key] end
    local bb = Instance.new("BillboardGui")
    bb.AlwaysOnTop = true
    bb.Size        = UDim2.new(0, 150, 0, 44)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.Adornee     = adornee
    bb.Parent      = ESPFolder
    local lbl = Instance.new("TextLabel", bb)
    lbl.Size = UDim2.new(1,0,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 13
    lbl.TextColor3 = color
    lbl.TextStrokeTransparency = 0.3
    lbl.TextStrokeColor3 = Color3.new(0,0,0)
    lbl.TextWrapped = true
    ESPCache[key] = {bb = bb, lbl = lbl}
    return ESPCache[key]
end

local function RemoveESP(key)
    if ESPCache[key] then
        pcall(function() ESPCache[key].bb:Destroy() end)
        ESPCache[key] = nil
    end
end

local function ClearESPPrefix(prefix)
    for k in pairs(ESPCache) do
        if k:sub(1, #prefix) == prefix then RemoveESP(k) end
    end
end

local function AddHL(model)
    local k = tostring(model)
    if HLCache[k] then return end
    local hl = Instance.new("Highlight")
    hl.Adornee              = model
    hl.FillColor            = Color3.fromRGB(255, 50, 0)
    hl.OutlineColor         = Color3.fromRGB(255, 0, 0)
    hl.FillTransparency     = 0.5
    hl.OutlineTransparency  = 0
    hl.Parent               = model
    HLCache[k] = hl
end

local function ClearHL()
    for k, v in pairs(HLCache) do
        pcall(function() v:Destroy() end)
        HLCache[k] = nil
    end
end

RunService.RenderStepped:Connect(function()
    local root = GetRoot()
    if not root then return end

    -- Bots ESP
    if Cfg.ESPBots or Cfg.ESPHighlight then
        for _, b in ipairs(GetAllBots()) do
            local key = "bot_" .. tostring(b.root)
            if Cfg.ESPBots then
                local e   = GetESP(key, Color3.fromRGB(255,60,60), b.root)
                local hp  = b.hum and math.floor(b.hum.Health) or "?"
                local dist = math.floor(GetDistance(b.root.Position))
                e.lbl.Text = "☠️ " .. b.name .. "\n❤️ " .. hp .. "  📍 " .. dist .. "m"
                e.bb.Enabled = true
            end
            if Cfg.ESPHighlight then AddHL(b.model) end
        end
    end
    if not Cfg.ESPBots    then ClearESPPrefix("bot_")  end
    if not Cfg.ESPHighlight then ClearHL() end

    -- Players ESP
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local key = "ply_" .. p.UserId
        local pchar = p.Character
        local proot = pchar and pchar:FindFirstChild("HumanoidRootPart")
        if Cfg.ESPPlayers and proot then
            local e = GetESP(key, Color3.fromRGB(0,200,255), proot)
            e.lbl.Text = "👤 " .. p.Name .. "\n📍 " .. math.floor(GetDistance(proot.Position)) .. "m"
            e.bb.Enabled = true
        else
            RemoveESP(key)
        end
    end

    -- Gold ESP
    if Cfg.ESPGold then
        for _, g in ipairs(GetAllGold()) do
            local key  = "gold_" .. tostring(g.part)
            local dist = math.floor(GetDistance(g.part.Position))
            if dist <= 400 then
                local e = GetESP(key, Color3.fromRGB(255,215,0), g.part)
                e.lbl.Text = "💰 Gold  📍 " .. dist .. "m"
                e.bb.Enabled = true
            end
        end
    else
        ClearESPPrefix("gold_")
    end
end)

-- ══════════════════════════════════
-- HEARTBEAT
-- ══════════════════════════════════
RunService.Heartbeat:Connect(function()
    if Cfg.Fullbright then
        if Lighting.Brightness < 2    then Lighting.Brightness = 3        end
        if Lighting.ClockTime  < 13   then Lighting.ClockTime  = 14       end
        if Lighting.FogEnd     < 50000 then Lighting.FogEnd    = 100000   end
    end
    if Cfg.AntiEscurecer then
        BlockScary()
        if Lighting.Ambient.R < 0.3 then
            Lighting.Ambient        = Color3.fromRGB(178,178,178)
            Lighting.OutdoorAmbient = Color3.fromRGB(178,178,178)
        end
    end
    if Cfg.AntiDeath then
        local h = GetHuman()
        if h and h.Health > 0 and h.Health < 1 then h.Health = h.MaxHealth end
    end
    if Cfg.SpeedHack then
        local h = GetHuman()
        if h and h.WalkSpeed ~= Cfg.SpeedValue then h.WalkSpeed = Cfg.SpeedValue end
    end
    if Cfg.Noclip then
        local c = GetChar()
        if c then
            for _, p in ipairs(c:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Cfg.InfiniteJump then
        local h = GetHuman()
        if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- Anti-Jumpscare
local jumpConn = nil
local function EnableAntiJS()
    local ev = ReplicatedStorage:FindFirstChild("JumpscareCamera")
    if ev then
        jumpConn = ev.OnClientEvent:Connect(function()
            task.wait(0.01)
            Camera.CameraType = Enum.CameraType.Custom
            local c = GetChar()
            if c and c:FindFirstChild("Humanoid") then
                Camera.CameraSubject = c.Humanoid
            end
        end)
    end
end
local function DisableAntiJS()
    if jumpConn then jumpConn:Disconnect() jumpConn = nil end
end

-- ══════════════════════════════════
-- RAYFIELD UI
-- ══════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name             = "🦍 Lethal Ape Script",
    LoadingTitle     = "Lethal Ape Script",
    LoadingSubtitle  = "by Script V3 • Código Real do Jogo",
    ConfigurationSaving = {
        Enabled  = true,
        FileName = "LethalApe_Config",
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

-- ════════════════════════════
-- TAB: AUTO FARM
-- ════════════════════════════
local FarmTab = Window:CreateTab("⚡ Auto Farm", 4483362458)

FarmTab:CreateToggle({
    Name        = "AutoFarm Gold",
    CurrentValue = false,
    Flag        = "AutoFarmGold",
    Callback    = function(v)
        Cfg.AutoFarmGold = v
        if v then StartFarm() else StopFarm() end
    end,
})

FarmTab:CreateSlider({
    Name         = "Delay entre Teleportes (s)",
    Range        = {0.05, 2},
    Increment    = 0.05,
    Suffix       = "s",
    CurrentValue = 0.25,
    Flag         = "FarmDelay",
    Callback     = function(v)
        Cfg.FarmDelay = v
    end,
})

FarmTab:CreateButton({
    Name     = "💰 Teleportar ao Gold mais próximo",
    Callback = function()
        local golds = GetAllGold()
        if #golds == 0 then
            Rayfield:Notify({Title="Gold", Content="Nenhum gold encontrado no mapa!", Duration=3})
            return
        end
        table.sort(golds, function(a,b) return GetDistance(a.part.Position) < GetDistance(b.part.Position) end)
        TeleportTo(golds[1].part.Position)
        Rayfield:Notify({Title="Teleporte", Content="Teleportado ao gold mais próximo!", Duration=2})
    end,
})

FarmTab:CreateButton({
    Name     = "📍 Teleportar ao Spawn",
    Callback = function()
        local sp = workspace:FindFirstChildWhichIsA("SpawnLocation")
        if sp then
            TeleportTo(sp.Position)
            Rayfield:Notify({Title="Spawn", Content="Teleportado ao Spawn!", Duration=2})
        else
            Rayfield:Notify({Title="Spawn", Content="SpawnLocation não encontrado!", Duration=2})
        end
    end,
})

FarmTab:CreateButton({
    Name     = "📊 Contar Gold no Mapa",
    Callback = function()
        local golds = GetAllGold()
        Rayfield:Notify({
            Title   = "Gold no Mapa",
            Content = "Encontrado: " .. #golds .. " gold(s)",
            Duration = 4,
        })
    end,
})

-- ════════════════════════════
-- TAB: ESP
-- ════════════════════════════
local EspTab = Window:CreateTab("👁 ESP", 4483362458)

EspTab:CreateToggle({
    Name         = "ESP Bots (bots1~bots5)",
    CurrentValue = false,
    Flag         = "ESPBots",
    Callback     = function(v)
        Cfg.ESPBots = v
        if not v then ClearESPPrefix("bot_") end
    end,
})

EspTab:CreateToggle({
    Name         = "Highlight Bots (nativo Roblox)",
    CurrentValue = false,
    Flag         = "ESPHighlight",
    Callback     = function(v)
        Cfg.ESPHighlight = v
        if not v then ClearHL() end
    end,
})

EspTab:CreateToggle({
    Name         = "ESP Players",
    CurrentValue = false,
    Flag         = "ESPPlayers",
    Callback     = function(v)
        Cfg.ESPPlayers = v
        if not v then ClearESPPrefix("ply_") end
    end,
})

EspTab:CreateToggle({
    Name         = "ESP Gold (≤ 400m)",
    CurrentValue = false,
    Flag         = "ESPGold",
    Callback     = function(v)
        Cfg.ESPGold = v
        if not v then ClearESPPrefix("gold_") end
    end,
})

EspTab:CreateButton({
    Name     = "🔄 Limpar ESP Cache",
    Callback = function()
        for k in pairs(ESPCache) do RemoveESP(k) end
        ClearHL()
        Rayfield:Notify({Title="ESP", Content="Cache limpo!", Duration=2})
    end,
})

-- ════════════════════════════
-- TAB: VISUAL
-- ════════════════════════════
local VisualTab = Window:CreateTab("💡 Visual", 4483362458)

VisualTab:CreateToggle({
    Name         = "Fullbright (Luz Máxima Permanente)",
    CurrentValue = false,
    Flag         = "Fullbright",
    Callback     = function(v)
        Cfg.Fullbright = v
        if v then
            ApplyFullbright()
            Rayfield:Notify({Title="Fullbright", Content="Luz máxima ATIVA!", Duration=3})
        else
            RestoreLighting()
            Rayfield:Notify({Title="Fullbright", Content="Desativado.", Duration=2})
        end
    end,
})

VisualTab:CreateToggle({
    Name         = "Anti-Escurecer (Bloqueia 'scary')",
    CurrentValue = false,
    Flag         = "AntiEscurecer",
    Callback     = function(v)
        Cfg.AntiEscurecer = v
        if v then
            Rayfield:Notify({Title="Anti-Scary", Content="Escurecimento BLOQUEADO!", Duration=3})
        end
    end,
})

VisualTab:CreateToggle({
    Name         = "Anti-Jumpscare (JumpscareCamera)",
    CurrentValue = false,
    Flag         = "AntiJumpscare",
    Callback     = function(v)
        Cfg.AntiJumpscare = v
        if v then EnableAntiJS()
        else      DisableAntiJS() end
        Rayfield:Notify({
            Title   = "Anti-Jumpscare",
            Content = v and "Jumpscares BLOQUEADOS!" or "Desativado.",
            Duration = 3,
        })
    end,
})

VisualTab:CreateToggle({
    Name         = "Sem Névoa (NoFog)",
    CurrentValue = false,
    Flag         = "NoFog",
    Callback     = function(v)
        Cfg.NoFog = v
        Lighting.FogEnd = v and 100000 or OrigLighting.FogEnd
    end,
})

-- ════════════════════════════
-- TAB: MOVIMENTO
-- ════════════════════════════
local MoveTab = Window:CreateTab("🏃 Movimento", 4483362458)

MoveTab:CreateToggle({
    Name         = "Speed Hack",
    CurrentValue = false,
    Flag         = "SpeedHack",
    Callback     = function(v)
        Cfg.SpeedHack = v
        local h = GetHuman()
        if h then h.WalkSpeed = v and Cfg.SpeedValue or 16 end
    end,
})

MoveTab:CreateSlider({
    Name         = "Velocidade (WalkSpeed)",
    Range        = {16, 100},
    Increment    = 2,
    Suffix       = " studs/s",
    CurrentValue = 28,
    Flag         = "SpeedValue",
    Callback     = function(v)
        Cfg.SpeedValue = v
        if Cfg.SpeedHack then
            local h = GetHuman()
            if h then h.WalkSpeed = v end
        end
    end,
})

MoveTab:CreateToggle({
    Name         = "Infinite Jump",
    CurrentValue = false,
    Flag         = "InfiniteJump",
    Callback     = function(v) Cfg.InfiniteJump = v end,
})

MoveTab:CreateToggle({
    Name         = "Noclip (Atravessa paredes)",
    CurrentValue = false,
    Flag         = "Noclip",
    Callback     = function(v)
        Cfg.Noclip = v
        if not v then
            local c = GetChar()
            if c then
                for _, p in ipairs(c:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end
    end,
})

-- ════════════════════════════
-- TAB: COMBATE
-- ════════════════════════════
local CombateTab = Window:CreateTab("⚔️ Combate", 4483362458)

CombateTab:CreateToggle({
    Name         = "Anti-Death (HP sempre máximo)",
    CurrentValue = false,
    Flag         = "AntiDeath",
    Callback     = function(v) Cfg.AntiDeath = v end,
})

CombateTab:CreateButton({
    Name     = "☠️ Matar todos os Bots agora",
    Callback = function()
        local bots = GetAllBots()
        local count = 0
        for _, b in ipairs(bots) do
            if b.hum then
                pcall(function() b.hum.Health = 0 end)
                count = count + 1
            end
        end
        Rayfield:Notify({
            Title   = "Kill Bots",
            Content = count .. " bots eliminados!",
            Duration = 4,
        })
    end,
})

CombateTab:CreateButton({
    Name     = "📊 Info dos Bots no Mapa",
    Callback = function()
        local bots = GetAllBots()
        local counts = {}
        for _, b in ipairs(bots) do
            counts[b.folder] = (counts[b.folder] or 0) + 1
        end
        local msg = "Total: " .. #bots .. "\n"
        for fn, cnt in pairs(counts) do
            msg = msg .. fn .. ": " .. cnt .. "  "
        end
        Rayfield:Notify({Title="Bots no Mapa", Content=msg, Duration=6})
    end,
})

-- ════════════════════════════
-- TAB: INFO
-- ════════════════════════════
local InfoTab = Window:CreateTab("ℹ️ Info", 4483362458)

local goldLbl   = InfoTab:CreateLabel("💰 Gold: carregando...")
local botsLbl   = InfoTab:CreateLabel("☠️ Bots: carregando...")
local posLbl    = InfoTab:CreateLabel("📍 Posição: carregando...")

task.spawn(function()
    while task.wait(2) do
        local goldVal = "?"
        pcall(function() goldVal = tostring(LP.leaderstats.Golds.Value) end)

        local bots  = #GetAllBots()
        local golds = #GetAllGold()
        local root  = GetRoot()
        local pos   = root and root.Position or Vector3.new(0,0,0)

        pcall(function()
            goldLbl:Set("💰 Gold atual: " .. goldVal .. "  |  Gold no mapa: " .. golds)
            botsLbl:Set("☠️ Bots vivos no mapa: " .. bots)
            posLbl:Set(string.format("📍 Posição: X=%.0f  Y=%.0f  Z=%.0f", pos.X, pos.Y, pos.Z))
        end)
    end
end)

InfoTab:CreateButton({
    Name     = "🦍 Créditos",
    Callback = function()
        Rayfield:Notify({
            Title   = "Lethal Ape Script V3",
            Content = "Script feito com código real do jogo\nBots: bots1~bots5 | Gold: Prop_GoldBar\nAnti-Scary: Lighting.scary bloqueado\nAnti-JS: JumpscareCamera interceptado",
            Duration = 8,
        })
    end,
})

-- ══════════════════════════════════
-- HOTKEYS
-- ══════════════════════════════════
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    -- RightBracket = ] para abrir/fechar (Rayfield usa Insert por padrão também)
    if inp.KeyCode == Enum.KeyCode.F3 then
        Cfg.Fullbright = not Cfg.Fullbright
        if Cfg.Fullbright then ApplyFullbright() else RestoreLighting() end
        Rayfield:Notify({Title="Fullbright", Content=Cfg.Fullbright and "ON" or "OFF", Duration=2})
    elseif inp.KeyCode == Enum.KeyCode.F4 then
        Cfg.ESPBots = not Cfg.ESPBots
        if not Cfg.ESPBots then ClearESPPrefix("bot_") end
        Rayfield:Notify({Title="ESP Bots", Content=Cfg.ESPBots and "ON" or "OFF", Duration=2})
    elseif inp.KeyCode == Enum.KeyCode.F5 then
        Cfg.AntiEscurecer = not Cfg.AntiEscurecer
        Rayfield:Notify({Title="Anti-Scary", Content=Cfg.AntiEscurecer and "ATIVO" or "OFF", Duration=2})
    end
end)

-- ══════════════════════════════════
-- NOTIFICAÇÃO INICIAL
-- ══════════════════════════════════
task.wait(3)
Rayfield:Notify({
    Title    = "🦍 Lethal Ape Script V3",
    Content  = "Carregado com sucesso!\nInsert = Abrir/Fechar GUI\nF3=Luz | F4=ESP | F5=AntiScary",
    Duration = 6,
    Image    = 4483362458,
})

print("╔══════════════════════════════════════╗")
print("║  LETHAL APE SCRIPT V3 - RAYFIELD     ║")
print("║  Insert  = Abrir/Fechar GUI          ║")
print("║  F3      = Fullbright                ║")
print("║  F4      = ESP Bots                  ║")
print("║  F5      = Anti-Escurecer            ║")
print("╚══════════════════════════════════════╝")
