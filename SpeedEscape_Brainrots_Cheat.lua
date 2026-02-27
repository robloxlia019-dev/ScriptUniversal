-- ╔══════════════════════════════════════════════════════════════╗
-- ║   SPEED ESCAPE FOR BRAINROTS  |  Cheat Script v1.0          ║
-- ║   UI: Rayfield  |  Executor: Codex (Mobile)                 ║
-- ║   Análise completa via .rbxlx                               ║
-- ╠══════════════════════════════════════════════════════════════╣
-- ║  DESCOBERTAS DA ANÁLISE:                                     ║
-- ║  • Anti-Teleport: checkpoint salvo por .Touched server-side  ║
-- ║    em workspace.Map.EntityZones → teleporte direto FALHA     ║
-- ║  • BYPASS: mover em lerp rápido → toca cada zona no caminho  ║
-- ║  • God Mode: LP:SetAttribute("Immunity", true) bypassa       ║
-- ║    Boulder (dist<15.8), Lava (Zone), Spikes (Touched),       ║
-- ║    MovingParts (Touched) — todos checam Immunity client-side ║
-- ║  • 60+ brainrots mapeados: Common → Supreme                  ║
-- ║  • 55 zonas totais (ZonesData), spawnam SpawnEntity tags     ║
-- ║  • ZonesData[55] = Secret 28%, Divine 20%, Supreme 10%       ║
-- ╚══════════════════════════════════════════════════════════════╝

-- RAYFIELD
local ok, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not ok then
    warn("[SpeedEscape] Rayfield falhou: "..tostring(Rayfield))
    Rayfield = {
        CreateWindow = function() return {CreateTab=function() return {CreateSection=function()end,CreateToggle=function()end,CreateSlider=function()end,CreateButton=function()end,CreateLabel=function()end} end} end,
        Notify = function(_, t) print("[Notify]", t.Title, t.Content) end,
    }
end

-- ══════════════════════════════════════════════
-- SERVIÇOS
-- ══════════════════════════════════════════════
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Lighting          = game:GetService("Lighting")

local LP  = Players.LocalPlayer
local WS  = workspace

-- ══════════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════════
local function Char()  return LP.Character end
local function HRP()   local c=Char(); return c and c:FindFirstChild("HumanoidRootPart") end
local function Hum()   local c=Char(); return c and c:FindFirstChildOfClass("Humanoid") end

local function Notify(title, msg, dur)
    Rayfield:Notify({ Title=title, Content=msg, Duration=dur or 3 })
end

-- ══════════════════════════════════════════════
-- GERENCIADOR DE CONEXÕES
-- ══════════════════════════════════════════════
local Conns = {}
local function Track(k, c) if Conns[k] then pcall(function() Conns[k]:Disconnect() end) end; Conns[k]=c end
local function Kill(k)     if Conns[k] then pcall(function() Conns[k]:Disconnect() end) end; Conns[k]=nil end

-- ══════════════════════════════════════════════
-- VARIÁVEIS GLOBAIS DE STATE
-- ══════════════════════════════════════════════
local FlyBV, FlyBG
local FlySpeed     = 80
local SpeedVal     = 80
local SpeedOn      = false
local AutoObbyOn   = false
local AutoBROn     = false
local AutoObbyTask = nil
local AutoBRTask   = nil

-- ══════════════════════════════════════════════
-- GOD MODE
-- ══════════════════════════════════════════════
-- LavaHandler: not LP:GetAttribute("Immunity") → kill
-- Boulder:     not LP:GetAttribute("Immunity") → kill
-- Spikes:      not LP:GetAttribute("Immunity") → kill
-- ⚠ MovingParts (Obby6) NÃO checa Immunity → usar Noclip

local function ApplyGod(char)
    if not char then return end
    LP:SetAttribute("Immunity", true)
    local h = char:WaitForChild("Humanoid", 3)
    if h then h.MaxHealth = math.huge; h.Health = math.huge end
end

local function SetGod(on)
    Kill("god")
    if on then
        if Char() then ApplyGod(Char()) end
        Track("god", LP.CharacterAdded:Connect(function(c) task.wait(0.3); ApplyGod(c) end))
    else
        LP:SetAttribute("Immunity", nil)
        local h = Hum(); if h then h.MaxHealth=100; h.Health=100 end
    end
end

-- ══════════════════════════════════════════════
-- NOCLIP
-- ══════════════════════════════════════════════
local function SetNoclip(on)
    Kill("noclip")
    if not on then
        local c = Char()
        if c then for _,p in c:GetDescendants() do if p:IsA("BasePart") then p.CanCollide=true end end end
        return
    end
    Track("noclip", RunService.Stepped:Connect(function()
        local c = Char(); if not c then return end
        for _, p in c:GetDescendants() do if p:IsA("BasePart") then p.CanCollide=false end end
    end))
end

-- ══════════════════════════════════════════════
-- SPEED HACK
-- ══════════════════════════════════════════════
local function SetSpeed(on, val)
    SpeedOn = on; SpeedVal = val or SpeedVal
    Kill("speed")
    local h = Hum(); if h then h.WalkSpeed = on and SpeedVal or 18 end
    if not on then return end
    Track("speed", LP.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        local hh = c:WaitForChild("Humanoid", 3)
        if hh then hh.WalkSpeed = SpeedVal end
    end))
end

-- ══════════════════════════════════════════════
-- INFINITE JUMP
-- ══════════════════════════════════════════════
local function SetInfJump(on)
    Kill("infjump")
    if not on then return end
    Track("infjump", UserInputService.JumpRequest:Connect(function()
        local h = Hum(); if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
    end))
end

-- ══════════════════════════════════════════════
-- FLY
-- ══════════════════════════════════════════════
local function SetFly(on)
    Kill("fly")
    if FlyBV then FlyBV:Destroy(); FlyBV=nil end
    if FlyBG then FlyBG:Destroy(); FlyBG=nil end
    if not on then return end
    local hrp = HRP(); if not hrp then return end

    FlyBV = Instance.new("BodyVelocity", hrp)
    FlyBV.MaxForce = Vector3.new(1e5,1e5,1e5)
    FlyBV.Velocity = Vector3.zero

    FlyBG = Instance.new("BodyGyro", hrp)
    FlyBG.MaxTorque = Vector3.new(1e5,1e5,1e5)
    FlyBG.D = 10

    Track("fly", RunService.RenderStepped:Connect(function()
        local cam = WS.CurrentCamera
        if not cam or not FlyBV then return end
        local dir = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W)           then dir += cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.S)           then dir -= cam.CFrame.LookVector  end
        if UserInputService:IsKeyDown(Enum.KeyCode.A)           then dir -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D)           then dir += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space)       then dir += Vector3.yAxis          end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir -= Vector3.yAxis          end
        FlyBV.Velocity = dir.Magnitude > 0 and dir.Unit * FlySpeed or Vector3.zero
        if FlyBG then FlyBG.CFrame = cam.CFrame end
    end))
end

-- ══════════════════════════════════════════════
-- FULLBRIGHT
-- ══════════════════════════════════════════════
local OrigLight = {}
local function SetFullbright(on)
    if on then
        OrigLight.Ambient        = Lighting.Ambient
        OrigLight.OutdoorAmbient = Lighting.OutdoorAmbient
        OrigLight.Brightness     = Lighting.Brightness
        OrigLight.GlobalShadows  = Lighting.GlobalShadows
        Lighting.Ambient         = Color3.fromRGB(255,255,255)
        Lighting.OutdoorAmbient  = Color3.fromRGB(255,255,255)
        Lighting.Brightness      = 2
        Lighting.GlobalShadows   = false
    else
        Lighting.Ambient        = OrigLight.Ambient        or Color3.fromRGB(70,70,70)
        Lighting.OutdoorAmbient = OrigLight.OutdoorAmbient or Color3.fromRGB(140,140,140)
        Lighting.Brightness     = OrigLight.Brightness     or 1
        Lighting.GlobalShadows  = OrigLight.GlobalShadows  ~= nil and OrigLight.GlobalShadows or true
    end
end

-- ══════════════════════════════════════════════
-- AUTO OBBY — ANTI-TELEPORT BYPASS
-- ══════════════════════════════════════════════
-- COMO FUNCIONA O CHECKPOINT:
--   Server script "Checkpoints" faz:
--     EntityZone.Touched:Connect → LP:SetAttribute("Checkpoint", zona.Name)
--   Logo, QUALQUER PARTE do personagem tocando a BasePart da zona = checkpoint salvo
--
-- BYPASS:
--   1. Ativar Noclip (passa por obby sem dano)
--   2. Ativar God (Immunity para Lava/Boulder/Spikes)
--   3. Mover em pequenos passos (lerp) passando por CADA zona em ordem
--   4. Cada zona é tocada automaticamente pelo personagem no caminho
--   5. O servidor registra o checkpoint normalmente

local function GetZones()
    local map = WS:FindFirstChild("Map"); if not map then return {} end
    local ez  = map:FindFirstChild("EntityZones"); if not ez then return {} end
    local zones = {}
    for _, z in ez:GetChildren() do
        local n = tonumber(z.Name)
        if n then
            local part = z:IsA("BasePart") and z or z:FindFirstChildOfClass("BasePart")
            if part then table.insert(zones, {num=n, pos=part.Position}) end
        end
    end
    table.sort(zones, function(a,b) return a.num < b.num end)
    return zones
end

local function StartAutoObby(on)
    AutoObbyOn = on
    if AutoObbyTask then task.cancel(AutoObbyTask); AutoObbyTask=nil end
    if not on then return end

    SetGod(true); SetNoclip(true)

    AutoObbyTask = task.spawn(function()
        local zones = GetZones()
        if #zones == 0 then
            Notify("Auto Obby", "EntityZones não encontradas!", 4)
            AutoObbyOn = false; return
        end
        Notify("Auto Obby", ("Passando por %d zonas..."):format(#zones), 4)

        for _, z in zones do
            if not AutoObbyOn then break end
            local target = z.pos + Vector3.new(0,4,0)
            local maxI   = 150; local i = 0
            while AutoObbyOn and i < maxI do
                i += 1
                local hrp = HRP(); if not hrp then task.wait(0.5); break end
                local dist = (hrp.Position - target).Magnitude
                if dist < 4 then break end
                hrp.CFrame = hrp.CFrame + (target - hrp.Position).Unit * math.min(18, dist)
                task.wait(0.03)
            end
            task.wait(0.12) -- Touched registrar
        end

        if AutoObbyOn then
            Notify("Auto Obby", "Concluído! ✅ Todos checkpoints registrados.", 5)
        end
        AutoObbyOn = false
    end)
end

-- ══════════════════════════════════════════════
-- ESP BRAINROTS
-- ══════════════════════════════════════════════
local RARITY_COLOR = {
    Common=Color3.fromRGB(200,200,200), Rare=Color3.fromRGB(0,120,255),
    Epic=Color3.fromRGB(160,0,255),     Legendary=Color3.fromRGB(255,180,0),
    Exotic=Color3.fromRGB(255,50,50),   Secret=Color3.fromRGB(255,0,120),
    Divine=Color3.fromRGB(0,255,200),   Supreme=Color3.fromRGB(255,100,0),
}

local ESPFolder = Instance.new("Folder"); ESPFolder.Name="_BRESP"; ESPFolder.Parent=WS
local ESPCache  = {}

local function ClearESP()
    Kill("esp")
    for _, h in pairs(ESPCache) do pcall(function() h:Destroy() end) end
    ESPCache = {}
end

local function SetESP(on)
    ClearESP(); if not on then return end
    Track("esp", RunService.Heartbeat:Connect(function()
        for obj, hl in pairs(ESPCache) do
            if not obj.Parent then hl:Destroy(); ESPCache[obj]=nil end
        end
        local function addHL(obj, col)
            if ESPCache[obj] then return end
            local hl = Instance.new("Highlight")
            hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
            hl.FillTransparency=0.45; hl.OutlineTransparency=0
            hl.FillColor=col; hl.OutlineColor=col
            hl.Adornee=obj; hl.Parent=ESPFolder
            ESPCache[obj]=hl
        end
        for _, o in CollectionService:GetTagged("SpawnEntity")  do addHL(o, RARITY_COLOR.Legendary) end
        for _, o in CollectionService:GetTagged("StaticEntity") do addHL(o, RARITY_COLOR.Exotic) end
    end))
end

-- ══════════════════════════════════════════════
-- AUTO BRAINROT
-- ══════════════════════════════════════════════
local function StartAutoBR(on)
    AutoBROn = on
    if AutoBRTask then task.cancel(AutoBRTask); AutoBRTask=nil end
    if not on then return end

    AutoBRTask = task.spawn(function()
        while AutoBROn do
            local hrp = HRP()
            if hrp then
                local function tryGet(tag)
                    for _, obj in CollectionService:GetTagged(tag) do
                        if not AutoBROn then break end
                        local part = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildOfClass("BasePart")
                        if not part then continue end
                        if (hrp.Position - part.Position).Magnitude > 400 then continue end
                        local s  = hrp.Position
                        local tg = part.Position + Vector3.new(0,4,0)
                        for i=1,10 do
                            local h2 = HRP(); if not h2 then break end
                            h2.CFrame = CFrame.new(s:Lerp(tg, i/10))
                            task.wait(0.025)
                        end
                        local pp = obj:FindFirstChildOfClass("ProximityPrompt")
                        if pp then pcall(fireproximityprompt, pp) end
                        task.wait(0.1)
                    end
                end
                tryGet("SpawnEntity")
                tryGet("StaticEntity")
            end
            task.wait(0.5)
        end
    end)
end

-- ══════════════════════════════════════════════
-- TP BRAINROT MAIS PRÓXIMO
-- ══════════════════════════════════════════════
local function TPNearestBR()
    local hrp = HRP(); if not hrp then Notify("BR","Sem personagem!",3); return end
    local best, bestD, bestObj = nil, math.huge, nil
    local function check(tag)
        for _, obj in CollectionService:GetTagged(tag) do
            local p = obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildOfClass("BasePart")
            if p then local d=(hrp.Position-p.Position).Magnitude; if d<bestD then bestD=d;best=p.Position;bestObj=obj end end
        end
    end
    check("SpawnEntity"); check("StaticEntity")
    if not best then Notify("BR","Nenhum brainrot encontrado!",3); return end
    local start = hrp.Position
    local target = best + Vector3.new(0,4,0)
    task.spawn(function()
        for i=1,15 do
            local h=HRP(); if not h then break end
            h.CFrame = CFrame.new(start:Lerp(target, i/15))
            task.wait(0.025)
        end
        if bestObj then
            local pp = bestObj:FindFirstChildOfClass("ProximityPrompt")
            if pp then pcall(fireproximityprompt, pp) end
        end
    end)
    Notify("Brainrot", ("Indo ao mais próximo (%.0f studs)"):format(bestD), 3)
end

-- ══════════════════════════════════════════════════════════════
-- RAYFIELD WINDOW
-- ══════════════════════════════════════════════════════════════
local W = Rayfield:CreateWindow({
    Name                   = "Speed Escape | Brainrots",
    Icon                   = 0,
    LoadingTitle           = "Speed Escape Hack",
    LoadingSubtitle        = "Análise completa .rbxlx",
    Theme                  = "Amethyst",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = true,
    ConfigurationSaving    = { Enabled=true, FolderName="SEBrainrots", FileName="cfg" },
    KeySystem              = false,
})

-- ────────────────────────────────────────────────────────
-- ABA 1: SOBREVIVER
-- ────────────────────────────────────────────────────────
local T1 = W:CreateTab("🛡️ Sobreviver", nil)

T1:CreateSection("God Mode")
T1:CreateLabel("Immunity bypassa Lava, Boulder, Spikes")
T1:CreateLabel("Noclip bypassa MovingParts (Obby6)")

T1:CreateToggle({ Name="God Mode  (Immunity + HP infinito)", CurrentValue=false, Flag="godmode",
    Callback=function(v)
        SetGod(v)
        Notify("God Mode", v and "Ativo! Lava/Boulder/Spikes ignorados." or "Desativado.", 3)
    end,
})

T1:CreateToggle({ Name="Noclip  (passa paredes do obby)", CurrentValue=false, Flag="noclip",
    Callback=function(v) SetNoclip(v) end,
})

T1:CreateSection("Movimento")

T1:CreateToggle({ Name="Speed Hack", CurrentValue=false, Flag="speedon",
    Callback=function(v)
        SpeedOn = v
        SetSpeed(v, SpeedVal)
    end,
})

T1:CreateSlider({ Name="Velocidade", Range={18,500}, Increment=10, CurrentValue=80, Flag="speedval",
    Callback=function(v)
        SpeedVal = v
        if SpeedOn then SetSpeed(true, v) end
    end,
})

T1:CreateToggle({ Name="Infinite Jump", CurrentValue=false, Flag="infjump",
    Callback=function(v) SetInfJump(v) end,
})

T1:CreateToggle({ Name="Voar  (WASD + Space/Ctrl)", CurrentValue=false, Flag="fly",
    Callback=function(v)
        SetFly(v)
        Notify("Fly", v and "Ativo! WASD mover, Space subir, Ctrl descer." or "Desativado.", 3)
    end,
})

T1:CreateSlider({ Name="Velocidade de Voo", Range={20,500}, Increment=10, CurrentValue=80, Flag="flyspd",
    Callback=function(v) FlySpeed = v end,
})

T1:CreateSection("Visual")
T1:CreateToggle({ Name="Fullbright", CurrentValue=false, Flag="fullbright",
    Callback=function(v) SetFullbright(v) end,
})

-- ────────────────────────────────────────────────────────
-- ABA 2: OBBY / CHECKPOINTS
-- ────────────────────────────────────────────────────────
local T2 = W:CreateTab("🏃 Obby", nil)

T2:CreateSection("Anti-Teleport Bypass")
T2:CreateLabel("Checkpoint = .Touched em EntityZones (servidor)")
T2:CreateLabel("Teleporte direto → checkpoint não registra")
T2:CreateLabel("BYPASS: lerp rápido toca cada zona → ok ✅")

T2:CreateSection("Auto Obby")

T2:CreateToggle({ Name="🤖 Auto Obby  (passa o obby inteiro)", CurrentValue=false, Flag="autoobby",
    Callback=function(v)
        if v then StartAutoObby(true) else StartAutoObby(false) end
    end,
})

T2:CreateButton({ Name="Ver Checkpoint Atual",
    Callback=function()
        Notify("Checkpoint", ("Atual: %s"):format(tostring(LP:GetAttribute("Checkpoint") or "0")), 4)
    end,
})

T2:CreateButton({ Name="Ir p/ Zona Final (passa todas as zonas)",
    Callback=function()
        local zones = GetZones()
        if #zones==0 then Notify("Zonas","Não encontradas.",3); return end
        SetNoclip(true); SetGod(true)
        task.spawn(function()
            for _, z in zones do
                local h=HRP(); if not h then break end
                local s2=h.Position; local tg=z.pos+Vector3.new(0,4,0)
                for i=1,6 do h=HRP();if not h then break end;h.CFrame=CFrame.new(s2:Lerp(tg,i/6));task.wait(0.025) end
                task.wait(0.1)
            end
            Notify("Zonas", ("Zona %d alcançada! ✅"):format(zones[#zones].num), 5)
        end)
    end,
})

T2:CreateButton({ Name="Respawn",
    Callback=function() local h=Hum();if h then h.Health=0 end end,
})

T2:CreateSection("Info Obstáculos")
T2:CreateLabel("Obby1-2: Conveyors → God+Noclip resolve")
T2:CreateLabel("Obby3: Boulder — check dist < 15.8 → Immunity")
T2:CreateLabel("Obby6: MovingParts — Touched → Noclip")
T2:CreateLabel("Obby9: Spikes — Touched (a cada 5.75s) → Immunity")
T2:CreateLabel("Lava: Zone WholeBody → Immunity")
T2:CreateLabel("FallParts: Touched → queda (Noclip resolve)")

-- ────────────────────────────────────────────────────────
-- ABA 3: BRAINROTS
-- ────────────────────────────────────────────────────────
local T3 = W:CreateTab("🧠 Brainrots", nil)

T3:CreateSection("Auto Coleta")

T3:CreateToggle({ Name="🤖 Auto Pegar Brainrots", CurrentValue=false, Flag="autobr",
    Callback=function(v)
        StartAutoBR(v)
        if v then Notify("Auto BR","Coletando automaticamente...",3) end
    end,
})

T3:CreateButton({ Name="🧠 Pegar Brainrot Mais Próximo",
    Callback=function() TPNearestBR() end,
})

T3:CreateButton({ Name="Contar Brainrots no Mapa",
    Callback=function()
        local s  = #CollectionService:GetTagged("SpawnEntity")
        local st = #CollectionService:GetTagged("StaticEntity")
        Notify("Brainrots", ("SpawnEntity: %d | Static: %d | Total: %d"):format(s,st,s+st), 5)
    end,
})

T3:CreateSection("ESP  (Highlight por raridade)")

T3:CreateToggle({ Name="ESP Brainrots", CurrentValue=false, Flag="esp",
    Callback=function(v)
        SetESP(v)
        if v then Notify("ESP","🟡 Legendary | 🔴 Exotic | 💠 Divine | 🔥 Supreme",5) end
    end,
})

T3:CreateSection("Chances por Zona (ZonesData)")
T3:CreateLabel("Zonas 1-8:  Common 100-75%")
T3:CreateLabel("Zonas 9-12: Legendary 5%")
T3:CreateLabel("Zonas 13-17: Exotic 10% | Legendary 30%")
T3:CreateLabel("Zonas 18-21: Secret 5% | Exotic 35%")
T3:CreateLabel("Zonas 22-29: Epic/Legendary/Exotic")
T3:CreateLabel("Zonas 38-42: Exotic 25% | Secret 15%")
T3:CreateLabel("Zonas 43-45: Exotic 10% | Secret 20%")
T3:CreateLabel("Zonas 46-55: Secret 28% | Divine 20% | Supreme 10% ⭐")

T3:CreateSection("Lista Completa")
T3:CreateLabel("Common: LiriliLarila, FrulliFrulla, TungTungSahur, BrrPatapim, TimCheese, MarryMe")
T3:CreateLabel("Rare: BonecaAmbalabu, TrippiTroppi, GangsterFootera, CapuccinoAssassino, PipiAvocado, Perrito")
T3:CreateLabel("Epic: IlCactoHipopotamo, FrigoCamelo, Trulimero, ChimpanziniBananini, Ballerina, Bananita, VacaLovini, LoviniCat")
T3:CreateLabel("Legendary: OrcaleroOrcala, BombardinoCrocodilo, RhinoToasterino, BombardiniGusini, Espressona, Matteo, 67, Confestteo, CorazonBici")
T3:CreateLabel("Exotic: GlorboFruttodrillo, StrawberryFlamingelli, SalaminoPinguino, TipiTopiTaco, Tralalerita, CookiAndMilki, Pakrahmatmamat, VacaCorazon, LosBridesman")
T3:CreateLabel("Secret: GaramaAndMadundung, LosTralaleritos, SneakyTralalaeritos, EsokSekolah, SwagSoda, AvocadiniAntilopini, ChillinChilli, NooMyLove, CorazonBrokini, ChocoratCherat, 41")
T3:CreateLabel("Divine: VacaSaturnoSaturnita, OdinDinDinDun, LosCrocodillitos, KarkerkarKurkur, StrawberryElephant, MiniLagrandeLove, Antonio, Fourteen")
T3:CreateLabel("Supreme: Amalgamation, DragonCannelloni, LaSupremeCombinasion, LoversMeowy, DragonniChocolate, 1x1x1x1, Guest666, 666, LagrandeLove, VulturinoSkeletono")

-- ────────────────────────────────────────────────────────
-- ABA 4: MISC
-- ────────────────────────────────────────────────────────
local T4 = W:CreateTab("⚙️ Misc", nil)

T4:CreateSection("Atalhos")

T4:CreateButton({ Name="⚡ Pacote Completo (God + Noclip + Speed + Jump)",
    Callback=function()
        SetGod(true); SetNoclip(true); SetSpeed(true, 120); SetInfJump(true)
        Notify("Pacote", "God + Noclip + Speed 120 + InfJump ativados!", 4)
    end,
})

T4:CreateButton({ Name="🔄 Resetar Tudo",
    Callback=function()
        SetGod(false); SetNoclip(false); SetSpeed(false, 18); SetInfJump(false)
        SetFly(false); SetFullbright(false); SetESP(false)
        StartAutoObby(false); StartAutoBR(false)
        LP:SetAttribute("Immunity", nil)
        Notify("Reset", "Tudo desativado e restaurado.", 3)
    end,
})

T4:CreateSection("Status")

T4:CreateButton({ Name="Ver Status Atual",
    Callback=function()
        local h  = Hum()
        local sp = h and math.floor(h.WalkSpeed) or 0
        local cp = LP:GetAttribute("Checkpoint") or 0
        local im = LP:GetAttribute("Immunity") and "✅" or "❌"
        Notify("Status", ("Speed: %d | Checkpoint: %s | Immunity: %s"):format(sp, tostring(cp), im), 5)
    end,
})

T4:CreateSection("Sobre o Jogo")
T4:CreateLabel("55 EntityZones (checkpoints server-side)")
T4:CreateLabel("60+ Brainrots em 8 raridades (Common→Supreme)")
T4:CreateLabel("9 Obbies mapeados (Conveyor, Boulder, Spike...)")
T4:CreateLabel("Speed base 18, cresce +2/nível × 1.25 growth")
T4:CreateLabel("Anti-TP: .Touched server → bypass = lerp ✅")
T4:CreateLabel("Immunity attr → bypassa 4/5 obstáculos ✅")

-- ══════════════════════════════════════════════
-- BOOT
-- ══════════════════════════════════════════════
task.delay(1.5, function()
    Notify(
        "Speed Escape | Brainrots ✅",
        "60+ brainrots | 55 zonas | Anti-TP bypass | God Mode via Immunity",
        8
    )
end)

print("[SpeedEscape] Script carregado com sucesso!")
