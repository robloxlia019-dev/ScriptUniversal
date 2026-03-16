-- ============================================================
--          LETHAL APE HUB | Rayfield UI
--          Compatível com Delta Executor
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ============================================================
-- SERVIÇOS & REFS
-- ============================================================
local Players       = game:GetService("Players")
local RunService    = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local Lighting      = game:GetService("Lighting")
local WS            = workspace
local lp            = Players.LocalPlayer

local char = lp.Character or lp.CharacterAdded:Wait()
local hrp  = char:WaitForChild("HumanoidRootPart")
local hum  = char:WaitForChild("Humanoid")

lp.CharacterAdded:Connect(function(c)
    char = c
    hrp  = c:WaitForChild("HumanoidRootPart")
    hum  = c:WaitForChild("Humanoid")
end)

-- ============================================================
-- HELPERS DE MONSTROS
-- ============================================================
local MONSTER_FOLDERS = {"bots","bots2","bots3","bots4","bots5"}

local function getAllMonsters()
    local list = {}
    for _, fname in ipairs(MONSTER_FOLDERS) do
        local folder = WS:FindFirstChild(fname)
        if folder then
            for _, m in ipairs(folder:GetChildren()) do
                if m:FindFirstChild("HumanoidRootPart") and m:FindFirstChild("Humanoid") then
                    table.insert(list, m)
                end
            end
        end
    end
    return list
end

local function getNearestMonster()
    local nearest, dist = nil, math.huge
    if not hrp then return nil, math.huge end
    for _, m in ipairs(getAllMonsters()) do
        local mhrp = m:FindFirstChild("HumanoidRootPart")
        if mhrp then
            local d = (hrp.Position - mhrp.Position).Magnitude
            if d < dist then dist = d nearest = m end
        end
    end
    return nearest, dist
end

-- ============================================================
-- JANELA RAYFIELD
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name              = "Lethal Ape Hub",
    Icon              = 0,
    LoadingTitle      = "Lethal Ape Hub",
    LoadingSubtitle   = "Delta Edition",
    Theme             = "Default",
    ShowText          = "Lethal Ape",
    ToggleUIKeybind   = "RightControl",
    DisableRayfieldPrompts  = false,
    DisableBuildWarnings    = false,
    ConfigurationSaving = { Enabled = false, FileName = "LethalApeHub" },
    Discord  = { Enabled = false },
    KeySystem = false,
})

-- ============================================================
-- TAB 1 — PLAYER
-- ============================================================
local PlayerTab = Window:CreateTab("Player", "user")

PlayerTab:CreateSection("Movimento")

PlayerTab:CreateSlider({
    Name         = "WalkSpeed",
    Range        = {16, 200},
    Increment    = 1,
    Suffix       = "spd",
    CurrentValue = 16,
    Flag         = "WalkSpeed",
    Callback = function(v)
        if hum then hum.WalkSpeed = v end
    end,
})

PlayerTab:CreateSlider({
    Name         = "JumpPower",
    Range        = {50, 350},
    Increment    = 5,
    Suffix       = "pwr",
    CurrentValue = 50,
    Flag         = "JumpPower",
    Callback = function(v)
        if hum then hum.JumpPower = v end
    end,
})

-- Infinite Jump
local _infJump = false
PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfJump",
    Callback = function(v) _infJump = v end,
})
UserInputService.JumpRequest:Connect(function()
    if _infJump and hum then
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- Noclip
local _noclip = false
PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(v)
        _noclip = v
        if not v and char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = true end
            end
        end
    end,
})
RunService.Stepped:Connect(function()
    if _noclip and char then
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") then p.CanCollide = false end
        end
    end
end)

-- Fly
local _flying = false
local _flySpeed = 60
local _bv, _bg

local function startFly()
    if not hrp then return end
    _bv = Instance.new("BodyVelocity")
    _bv.Velocity  = Vector3.new(0,0,0)
    _bv.MaxForce  = Vector3.new(1e5,1e5,1e5)
    _bv.Parent    = hrp
    _bg = Instance.new("BodyGyro")
    _bg.MaxTorque = Vector3.new(1e5,1e5,1e5)
    _bg.P         = 1e4
    _bg.CFrame    = hrp.CFrame
    _bg.Parent    = hrp
end

local function stopFly()
    if _bv then _bv:Destroy() _bv = nil end
    if _bg then _bg:Destroy() _bg = nil end
    if hum then hum.PlatformStand = false end
end

PlayerTab:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "Fly",
    Callback = function(v)
        _flying = v
        if v then startFly() else stopFly() end
    end,
})

PlayerTab:CreateSlider({
    Name         = "Fly Speed",
    Range        = {10, 250},
    Increment    = 5,
    Suffix       = "spd",
    CurrentValue = 60,
    Flag         = "FlySpeed",
    Callback = function(v) _flySpeed = v end,
})

RunService.RenderStepped:Connect(function()
    if _flying and _bv and _bg and hrp then
        local cam = WS.CurrentCamera
        local dir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W)            then dir += cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)            then dir -= cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)            then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)            then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)        then dir += Vector3.new(0,1,0)     end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)  then dir -= Vector3.new(0,1,0)     end
        _bv.Velocity = dir.Magnitude > 0 and dir.Unit * _flySpeed or Vector3.new(0,0,0)
        _bg.CFrame   = cam.CFrame
        if hum then hum.PlatformStand = true end
    end
end)

-- Godmode (local)
local _godmode = false
PlayerTab:CreateToggle({
    Name = "Godmode (Local)",
    CurrentValue = false,
    Flag = "Godmode",
    Callback = function(v) _godmode = v end,
})
RunService.Heartbeat:Connect(function()
    if _godmode and hum then
        hum.Health = hum.MaxHealth
    end
end)

PlayerTab:CreateSection("Teleporte")

local TELEPORTS = {
    ["Safe Zone"]        = Vector3.new(-232, 236, 20),
    ["Floresta"]         = Vector3.new(-797, 278, -106),
    ["Sala dos Monstros"]= Vector3.new(-262, 234, 92),
    ["Spawn Principal"]  = Vector3.new(-81, 243, -22),
}

for nome, pos in pairs(TELEPORTS) do
    PlayerTab:CreateButton({
        Name = "TP → " .. nome,
        Callback = function()
            if hrp then
                hrp.CFrame = CFrame.new(pos + Vector3.new(0,3,0))
                Rayfield:Notify({Title="Teleporte", Content=nome, Duration=3})
            end
        end,
    })
end

-- ============================================================
-- TAB 2 — VISUAL
-- ============================================================
local VisualTab = Window:CreateTab("Visual", "eye")

VisualTab:CreateSection("Efeitos")

-- Fullbright
local _origAmb, _origOut, _origBri
VisualTab:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "Fullbright",
    Callback = function(v)
        if v then
            _origAmb = Lighting.Ambient
            _origOut = Lighting.OutdoorAmbient
            _origBri = Lighting.Brightness
            Lighting.Ambient         = Color3.fromRGB(178,178,178)
            Lighting.OutdoorAmbient  = Color3.fromRGB(178,178,178)
            Lighting.Brightness      = 2
        else
            if _origAmb then
                Lighting.Ambient        = _origAmb
                Lighting.OutdoorAmbient = _origOut
                Lighting.Brightness     = _origBri
            end
        end
    end,
})

-- Desativar horror shader
VisualTab:CreateToggle({
    Name = "Desativar Efeito Horror",
    CurrentValue = false,
    Flag = "NoHorror",
    Callback = function(v)
        local scary = Lighting:FindFirstChild("scary")
        if scary then scary.Enabled = not v end
        pcall(function()
            local ops = lp.PlayerScripts:FindFirstChild("options")
            if ops then
                local sv = ops:FindFirstChild("scary")
                if sv then sv.Value = not v end
            end
        end)
    end,
})

-- Desativar VHS/Static overlay
VisualTab:CreateToggle({
    Name = "Desativar VHS / Static",
    CurrentValue = false,
    Flag = "NoVHS",
    Callback = function(v)
        local targets = {rgbstatic=true, static=true, vhs=true, Vignetii=true}
        for _, gui in ipairs(lp.PlayerGui:GetDescendants()) do
            if targets[gui.Name] and gui:IsA("GuiObject") then
                gui.Visible = not v
            end
        end
    end,
})

VisualTab:CreateSection("ESP")

-- Monster ESP via Highlight
local _espMonsters = false
local _espHighlights = {}

local function rebuildMonsterESP()
    for _, h in ipairs(_espHighlights) do pcall(function() h:Destroy() end) end
    _espHighlights = {}
    if not _espMonsters then return end
    for _, m in ipairs(getAllMonsters()) do
        local h = Instance.new("Highlight")
        h.FillColor          = Color3.fromRGB(255, 30, 30)
        h.OutlineColor       = Color3.fromRGB(255, 140, 0)
        h.FillTransparency   = 0.45
        h.OutlineTransparency= 0
        h.Adornee            = m
        h.Parent             = m
        table.insert(_espHighlights, h)
    end
end

VisualTab:CreateToggle({
    Name = "ESP Monstros (Highlight)",
    CurrentValue = false,
    Flag = "MonsterESP",
    Callback = function(v)
        _espMonsters = v
        rebuildMonsterESP()
    end,
})

task.spawn(function()
    while task.wait(2) do
        if _espMonsters then rebuildMonsterESP() end
    end
end)

-- Player ESP
local _espPlayers = false
local _playerHL   = {}

VisualTab:CreateToggle({
    Name = "ESP Jogadores",
    CurrentValue = false,
    Flag = "PlayerESP",
    Callback = function(v)
        _espPlayers = v
        for _, h in ipairs(_playerHL) do pcall(function() h:Destroy() end) end
        _playerHL = {}
        if not v then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= lp and p.Character then
                local h = Instance.new("Highlight")
                h.FillColor    = Color3.fromRGB(0, 170, 255)
                h.OutlineColor = Color3.fromRGB(255, 255, 255)
                h.FillTransparency = 0.5
                h.Adornee = p.Character
                h.Parent  = p.Character
                table.insert(_playerHL, h)
            end
        end
    end,
})

-- Tracer (linha 2D no BillboardGui para monstros)
local _tracers = false
local _tracerGuis = {}
VisualTab:CreateToggle({
    Name = "Tracer Monstros (Nome + Dist)",
    CurrentValue = false,
    Flag = "MonsterTracer",
    Callback = function(v)
        _tracers = v
        for _, bg in ipairs(_tracerGuis) do pcall(function() bg:Destroy() end) end
        _tracerGuis = {}
        if not v then return end
        for _, m in ipairs(getAllMonsters()) do
            local mhrp = m:FindFirstChild("HumanoidRootPart")
            if mhrp then
                local bg = Instance.new("BillboardGui")
                bg.Size          = UDim2.new(0,120,0,36)
                bg.StudsOffset   = Vector3.new(0,3.5,0)
                bg.AlwaysOnTop   = true
                bg.Adornee       = mhrp
                bg.Parent        = mhrp
                local lbl = Instance.new("TextLabel", bg)
                lbl.Size = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.TextColor3 = Color3.fromRGB(255,80,80)
                lbl.TextStrokeTransparency = 0.5
                lbl.Font = Enum.Font.GothamBold
                lbl.TextScaled = true
                lbl.Text = m.Name
                -- atualiza distância
                task.spawn(function()
                    while bg.Parent and _tracers do
                        if hrp and mhrp then
                            lbl.Text = m.Name .. "\n" .. math.floor((hrp.Position - mhrp.Position).Magnitude) .. "s"
                        end
                        task.wait(0.5)
                    end
                end)
                table.insert(_tracerGuis, bg)
            end
        end
    end,
})

-- ============================================================
-- TAB 3 — MONSTROS
-- ============================================================
local MonsterTab = Window:CreateTab("Monstros", "skull")

MonsterTab:CreateSection("Informações")

MonsterTab:CreateButton({
    Name = "Ver Monstro Mais Próximo",
    Callback = function()
        local m, dist = getNearestMonster()
        if m then
            Rayfield:Notify({Title="Monstro Próximo", Content=m.Name.." — "..math.floor(dist).." studs", Duration=5})
        else
            Rayfield:Notify({Title="Monstros", Content="Nenhum monstro encontrado.", Duration=3})
        end
    end,
})

MonsterTab:CreateButton({
    Name = "Listar Todos os Monstros",
    Callback = function()
        local list = getAllMonsters()
        if #list == 0 then
            Rayfield:Notify({Title="Monstros", Content="Nenhum monstro vivo!", Duration=3})
        else
            local names = {}
            for _, m in ipairs(list) do table.insert(names, m.Name) end
            Rayfield:Notify({Title=tostring(#list).." Monstros", Content=table.concat(names, ", "), Duration=7})
        end
    end,
})

MonsterTab:CreateSection("Ações")

MonsterTab:CreateButton({
    Name = "Fugir do Monstro Mais Próximo",
    Callback = function()
        local m, dist = getNearestMonster()
        if m and hrp then
            local mhrp = m:FindFirstChild("HumanoidRootPart")
            if mhrp then
                local dir = (hrp.Position - mhrp.Position)
                local safeDir = dir.Magnitude > 0 and dir.Unit or Vector3.new(0,0,1)
                hrp.CFrame = CFrame.new(hrp.Position + safeDir * 70 + Vector3.new(0,3,0))
                Rayfield:Notify({Title="Fuga", Content="Teleportado longe de "..m.Name, Duration=3})
            end
        else
            Rayfield:Notify({Title="Fuga", Content="Nenhum monstro perto.", Duration=3})
        end
    end,
})

MonsterTab:CreateButton({
    Name = "Teleportar para Monstro",
    Callback = function()
        local m = getNearestMonster()
        if m then
            local mhrp = m:FindFirstChild("HumanoidRootPart")
            if mhrp and hrp then
                hrp.CFrame = mhrp.CFrame + Vector3.new(0,5,0)
                Rayfield:Notify({Title="TP", Content="Em cima de "..m.Name, Duration=3})
            end
        end
    end,
})

MonsterTab:CreateButton({
    Name = "Matar Monstro Mais Próximo",
    Callback = function()
        local m = getNearestMonster()
        if m then
            local h = m:FindFirstChildOfClass("Humanoid")
            if h then
                h.Health = 0
                Rayfield:Notify({Title="Kill", Content=m.Name.." eliminado!", Duration=3})
            end
        end
    end,
})

MonsterTab:CreateButton({
    Name = "Matar TODOS os Monstros",
    Callback = function()
        local count = 0
        for _, m in ipairs(getAllMonsters()) do
            local h = m:FindFirstChildOfClass("Humanoid")
            if h then h.Health = 0 count += 1 end
        end
        Rayfield:Notify({Title="Kill All", Content=count.." monstro(s) eliminado(s)!", Duration=4})
    end,
})

MonsterTab:CreateButton({
    Name = "Congelar Todos os Monstros",
    Callback = function()
        for _, m in ipairs(getAllMonsters()) do
            local h = m:FindFirstChildOfClass("Humanoid")
            if h then h.WalkSpeed = 0 h.JumpPower = 0 end
        end
        Rayfield:Notify({Title="Freeze", Content="Monstros congelados!", Duration=4})
    end,
})

MonsterTab:CreateSection("Auto Fuga")

local _autoEscape = false
local _escapeDist = 30
MonsterTab:CreateToggle({
    Name = "Auto Fugir de Monstros",
    CurrentValue = false,
    Flag = "AutoEscape",
    Callback = function(v) _autoEscape = v end,
})

MonsterTab:CreateSlider({
    Name         = "Distância de Fuga",
    Range        = {10, 100},
    Increment    = 5,
    Suffix       = "studs",
    CurrentValue = 30,
    Flag         = "EscapeDist",
    Callback = function(v) _escapeDist = v end,
})

task.spawn(function()
    while task.wait(0.5) do
        if _autoEscape and hrp then
            local m, dist = getNearestMonster()
            if m and dist <= _escapeDist then
                local mhrp = m:FindFirstChild("HumanoidRootPart")
                if mhrp then
                    local dir = (hrp.Position - mhrp.Position)
                    local safeDir = dir.Magnitude > 0 and dir.Unit or Vector3.new(0,0,1)
                    hrp.CFrame = CFrame.new(hrp.Position + safeDir * 65 + Vector3.new(0,2,0))
                end
            end
        end
    end
end)

-- ============================================================
-- TAB 4 — ANTI-HORROR
-- ============================================================
local AntiTab = Window:CreateTab("Anti-Horror", "shield")

AntiTab:CreateSection("Jumpscares")

-- Block jumpscares usando metatable hook nos RemoteEvents
local _blockJumpscare = false
local _jumpscareConnections = {}

local JUMPSCARE_REMOTES = {
    "JumpscareCamera","ActivateMonsterCamera","ChasedEvent",
    "PlayAshy","PlayBloodMan","PlayDus","PlayGus",
    "PlayKus","PlaySandManAshy","PlayScarJumpscare",
    "PlayAshyJumpscareAnim","PlayBloodManJumpscareAnim",
    "PlayDusJumpscareAnim","PlayGusJumpscareAnim",
    "PlayKusJumpscareAnim","PlaySandmanJumpscareAnim",
    "PlayJumpscareSound","PlayScarJumpscare","gusjumpscare","lostjumpscare",
}

local function hookJumpscareRemotes()
    for _, c in ipairs(_jumpscareConnections) do pcall(function() c:Disconnect() end) end
    _jumpscareConnections = {}
    if not _blockJumpscare then return end

    local function scanAndHook(inst)
        if inst:IsA("RemoteEvent") then
            for _, name in ipairs(JUMPSCARE_REMOTES) do
                if inst.Name == name then
                    -- Registra um handler vazio que tem prioridade máxima
                    local ok, con = pcall(function()
                        return inst.OnClientEvent:Connect(function() end)
                    end)
                    if ok then table.insert(_jumpscareConnections, con) end
                end
            end
        end
    end

    for _, d in ipairs(WS:GetDescendants()) do scanAndHook(d) end
    WS.DescendantAdded:Connect(scanAndHook)
end

AntiTab:CreateToggle({
    Name = "Bloquear Jumpscares",
    CurrentValue = false,
    Flag = "BlockJumpscare",
    Callback = function(v)
        _blockJumpscare = v
        hookJumpscareRemotes()
        if v then
            Rayfield:Notify({Title="Anti-Horror", Content="Jumpscares bloqueados!", Duration=3})
        end
    end,
})

AntiTab:CreateSection("Sons")

-- Guardar volumes originais
local _origVolumes = {}
local function muteSounds(v, filter)
    for _, obj in ipairs(WS:GetDescendants()) do
        if obj:IsA("Sound") then
            local match = false
            for _, n in ipairs(filter) do
                if obj.Name:lower():find(n:lower()) then match = true break end
            end
            if match then
                if v then
                    if not _origVolumes[obj] then _origVolumes[obj] = obj.Volume end
                    obj.Volume = 0
                else
                    if _origVolumes[obj] then
                        obj.Volume = _origVolumes[obj]
                        _origVolumes[obj] = nil
                    end
                end
            end
        end
    end
end

AntiTab:CreateToggle({
    Name = "Silenciar Música de Chase",
    CurrentValue = false,
    Flag = "SilenceChase",
    Callback = function(v)
        muteSounds(v, {"chase","Chase","chasetheme"})
    end,
})

AntiTab:CreateToggle({
    Name = "Silenciar Sons Ambiente Horror",
    CurrentValue = false,
    Flag = "SilenceAmbient",
    Callback = function(v)
        muteSounds(v, {"ambient","Ambient","static","scary"})
        local ar = WS:FindFirstChild("Ambient_Room")
        if ar and ar:IsA("Sound") then
            ar.Volume = v and 0 or 3
        end
    end,
})

AntiTab:CreateToggle({
    Name = "Silenciar Vozes dos Monstros",
    CurrentValue = false,
    Flag = "SilenceMonsterVoices",
    Callback = function(v)
        muteSounds(v, {"duspisante","kuspisante","dus voices","ashy","gus","scream","jumpscare","scary2"})
    end,
})

AntiTab:CreateSection("Câmera & Efeitos")

AntiTab:CreateToggle({
    Name = "Travar Câmera no Personagem",
    CurrentValue = false,
    Flag = "LockCamera",
    Callback = function(v)
        if v then
            WS.CurrentCamera.CameraType = Enum.CameraType.Custom
            pcall(function() lp.CameraMode = Enum.CameraMode.Classic end)
        end
    end,
})

-- Desativar PostEffects (blur de jumpscare etc)
AntiTab:CreateToggle({
    Name = "Desativar PostEffects (Blur/Glow)",
    CurrentValue = false,
    Flag = "NoPostFX",
    Callback = function(v)
        for _, fx in ipairs(Lighting:GetDescendants()) do
            if fx:IsA("PostEffect") and fx.Name ~= "scary" then
                fx.Enabled = not v
            end
        end
        for _, fx in ipairs(WS.CurrentCamera:GetDescendants()) do
            if fx:IsA("PostEffect") then fx.Enabled = not v end
        end
    end,
})

-- ============================================================
-- TAB 5 — MISC
-- ============================================================
local MiscTab = Window:CreateTab("Misc", "settings")

MiscTab:CreateSection("Utilidades")

-- Auto Coletar Moedas (toca nos touchparts de coin)
MiscTab:CreateButton({
    Name = "Auto Coletar Moedas",
    Callback = function()
        if not hrp then return end
        local count = 0
        local orig = hrp.CFrame
        for _, obj in ipairs(WS:GetDescendants()) do
            local n = obj.Name:lower()
            if (n == "coins" or n == "coin" or n:find("coin")) and obj:IsA("BasePart") then
                hrp.CFrame = CFrame.new(obj.Position + Vector3.new(0,1,0))
                task.wait(0.03)
                count += 1
            end
        end
        hrp.CFrame = orig
        Rayfield:Notify({Title="Coins", Content=count.." moeda(s) coletada(s)!", Duration=4})
    end,
})

-- Silent Aim
local _silentAim = false
MiscTab:CreateToggle({
    Name = "Silent Aim (Gun)",
    CurrentValue = false,
    Flag = "SilentAim",
    Callback = function(v)
        _silentAim = v
        if v then Rayfield:Notify({Title="Silent Aim", Content="Ativo — mira no HRP do inimigo mais próximo", Duration=3}) end
    end,
})

-- Hook do mouse para silent aim (compatibilidade Delta)
pcall(function()
    local mouse = lp:GetMouse()
    local mt = getrawmetatable(game)
    if mt then
        local oldIndex = mt.__index
        setreadonly(mt, false)
        mt.__index = newcclosure(function(self, key)
            if _silentAim and rawequal(self, mouse) and (key == "Hit" or key == "Target") then
                local closest, cdist = nil, math.huge
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= lp and p.Character then
                        local h = p.Character:FindFirstChild("HumanoidRootPart")
                        if h and hrp then
                            local d = (hrp.Position - h.Position).Magnitude
                            if d < cdist then cdist = d closest = h end
                        end
                    end
                end
                if closest then
                    if key == "Hit"    then return closest.CFrame end
                    if key == "Target" then return closest end
                end
            end
            return oldIndex(self, key)
        end)
        setreadonly(mt, true)
    end
end)

-- Velocidade infinita da bala (spread = 0)
MiscTab:CreateToggle({
    Name = "No Spread (Gun)",
    CurrentValue = false,
    Flag = "NoSpread",
    Callback = function(v)
        pcall(function()
            for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") then
                    local setting = tool:FindFirstChild("Setting")
                    if setting and setting:IsA("ModuleScript") then
                        -- Não é possível modificar ModuleScript em runtime via exploit seguro,
                        -- mas tentamos via rawset na tabela cacheada
                        local ok, mod = pcall(require, setting)
                        if ok and type(mod) == "table" then
                            rawset(mod, "Spread", v and 0 or 1.25)
                        end
                    end
                end
            end
        end)
    end,
})

-- FPS Cap
MiscTab:CreateSlider({
    Name         = "FPS Cap",
    Range        = {30, 240},
    Increment    = 10,
    Suffix       = "fps",
    CurrentValue = 60,
    Flag         = "FPSCap",
    Callback = function(v)
        pcall(function()
            if setfpscap then setfpscap(v) end
        end)
    end,
})

-- Anti-AFK
local _antiAfk = false
MiscTab:CreateToggle({
    Name = "Anti-AFK",
    CurrentValue = false,
    Flag = "AntiAFK",
    Callback = function(v)
        _antiAfk = v
        if v then
            task.spawn(function()
                while _antiAfk do
                    task.wait(55)
                    if _antiAfk then
                        pcall(function()
                            local vim = game:GetService("VirtualInputManager")
                            vim:SendKeyEvent(true,  Enum.KeyCode.LeftShift, false, game)
                            task.wait(0.1)
                            vim:SendKeyEvent(false, Enum.KeyCode.LeftShift, false, game)
                        end)
                    end
                end
            end)
        end
    end,
})

MiscTab:CreateSection("Info")

MiscTab:CreateButton({
    Name = "Ver Meu UserID",
    Callback = function()
        Rayfield:Notify({Title="Info", Content="UserID: "..tostring(lp.UserId), Duration=5})
    end,
})

MiscTab:CreateButton({
    Name = "Ver Distância Todos Monstros",
    Callback = function()
        local monsters = getAllMonsters()
        if #monsters == 0 then
            Rayfield:Notify({Title="Monstros", Content="Nenhum encontrado.", Duration=3})
            return
        end
        local lines = {}
        for _, m in ipairs(monsters) do
            local mhrp = m:FindFirstChild("HumanoidRootPart")
            if mhrp and hrp then
                local d = math.floor((hrp.Position - mhrp.Position).Magnitude)
                table.insert(lines, m.Name..": "..d.."s")
            end
        end
        Rayfield:Notify({Title="Distâncias", Content=table.concat(lines, " | "), Duration=8})
    end,
})

-- ============================================================
-- NOTIFICAÇÃO INICIAL
-- ============================================================
Rayfield:Notify({
    Title    = "Lethal Ape Hub",
    Content  = "Carregado! RCtrl = abrir/fechar UI.",
    Duration = 6,
    Image    = 4483362458,
})
