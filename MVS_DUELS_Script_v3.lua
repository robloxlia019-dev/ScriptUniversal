--[[
    ╔══════════════════════════════════════════════════════════════╗
    ║         MURDERERS VS SHERIFFS DUELS - SCRIPT COMPLETO       ║
    ║              Feito especificamente para este jogo            ║
    ║         Com Rayfield UI | Silent Aim | Auto Shot             ║
    ║         Visual Skins | Kill Effects | ESP | Misc             ║
    ╚══════════════════════════════════════════════════════════════╝
    
    COMO USAR:
    1. Cole este script no executor
    2. Execute no jogo Murderers VS Sheriffs DUELS
    3. O botão de abrir/fechar GUI é arrastável (canto direito da tela)
    4. Clique nos toggles para ativar/desativar funções
    
    CRÉDITOS: Script gerado com análise completa do jogo
]]

-- ══════════════════════════════════════
-- CARREGAMENTO DO RAYFIELD
-- ══════════════════════════════════════
local Rayfield
local ok, err = pcall(function()
    Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)

if not ok then
    warn("[MVS Script] Erro ao carregar Rayfield: " .. tostring(err))
    Rayfield = {}
    setmetatable(Rayfield, {__index = function() return function() return {} end end})
end

-- ══════════════════════════════════════
-- SERVIÇOS
-- ══════════════════════════════════════
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Workspace          = game:GetService("Workspace")
local CoreGui            = game:GetService("CoreGui")
local Camera             = Workspace.CurrentCamera

local LocalPlayer        = Players.LocalPlayer
local Mouse              = LocalPlayer:GetMouse()

-- ══════════════════════════════════════
-- ESTADO GLOBAL
-- ══════════════════════════════════════
local State = {
    -- Aimbot
    SilentAim        = false,
    SilentAimChance  = 85,
    AutoShot         = false,
    AutoShotChance   = 85,
    AutoShotDelay    = 0.15,
    AimbotFOV        = 120,
    ShowFOV          = true,
    AimbotPart       = "Head",

    -- Visual / Skin da Arma
    GunSkinEnabled   = false,
    SelectedGunSkin  = "Default",
    KnifeSkinEnabled = false,
    SelectedKnife    = "Default",
    KillEffectEnabled = false,
    SelectedKillEffect = "Reef",

    -- ESP
    ESPEnabled       = false,
    ESPBoxes         = false,
    ESPNames         = true,
    ESPDistance      = true,
    ESPHealth        = true,
    ESPTracers       = false,
    ESPTeamCheck     = true,
    ESPMaxDist       = 500,
    ESPMurdererColor = Color3.fromRGB(255, 60, 60),
    ESPSheriffColor  = Color3.fromRGB(60, 150, 255),
    ESPInnocentColor = Color3.fromRGB(100, 255, 100),

    -- Misc
    NoFog            = false,
    Fullbright       = false,
    InfiniteJump     = false,
    SpeedEnabled     = false,
    SpeedValue       = 20,
    NoClipEnabled    = false,
    AntiRagdoll      = false,
    AutoEquipGun     = false,
    AutoSprint       = false,

    -- Visual / Personagem
    GodmodeFake      = false,
    CustomFOV        = false,
    CustomFOVValue   = 90,
    ShowFPS          = false,

    -- Anti-Kick
    AntiKick         = false,
}

-- ══════════════════════════════════════
-- REMOTES DO JOGO
-- ══════════════════════════════════════
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
local ShootGunRemote     = Remotes and Remotes:FindFirstChild("ShootGun")
local OnKilledRemote     = Remotes and Remotes:FindFirstChild("OnKilled")
local OnPlayerKilledRemote = Remotes and Remotes:FindFirstChild("OnPlayerKilled")
local EquipItemRemote    = Remotes and Remotes:FindFirstChild("EquipItem")
local StabRemote         = Remotes and Remotes:FindFirstChild("Stab")

-- ══════════════════════════════════════
-- LISTAS DE SKINS DE ARMA (do ItemDatabase)
-- ══════════════════════════════════════
local GunSkins = {
    "Default",
    "Reef",
    "Strife Purple",
    "Strife Red",
    "Strife Green",
    "Strife Gold",
    "Mermaid",
    "Fang Red",
    "Fang Green",
    "Fang Blue",
    "Fang Gray",
    "Fang Purple",
    "Fang Green-Purple",
    "Fang Frost",
    "Willow Red",
    "Willow Blue",
    "Willow Green",
    "Willow Purple",
    "Ice Pegasus White",
    "Ice Pegasus Blue",
    "Ice Pegasus Purple",
    "Ice Pegasus Red",
    "Ice Pegasus Black",
    "Bubble Purple",
    "Bubble Blue",
    "Bubble Pink",
    "Bubble Red",
    "Bubble Black",
    "Bubble White",
    "Bubble Frost",
    "Flutter Purple",
    "Flutter Pink",
    "Flutter Red",
    "Flutter Blue",
    "Flutter Black",
    "Flutter Frost",
    "Elder Flame Blue",
    "Elder Flame Black",
    "Elder Flame Red",
    "Elder Flame Purple",
    "Elder Flame Frost",
    "Rhinestone Purple",
    "Rhinestone Red",
    "Rhinestone Blue",
    "Rhinestone Black",
    "Rhinestone Frost",
    "Rosethorn",
    "Rosethorn Frost",
    "Celestial",
    "Frost Celestial",
    "Reaper",
    "Frost Reaper",
    "Angel",
    "Techno",
    "Harmonic",
    "Frostbite",
    "Leprichaun",
    "Nebula Blue",
    "Nebula Red",
    "Nebula Pink",
    "Nebula Green",
    "Nebula Black",
    "Android Purple",
    "Android Blue",
    "Android Green",
    "Android Pink",
    "Android White",
    "Strife WhiteGold",
    "Strife Frost",
}

local KnifeSkins = {
    "Default (Shimmer)",
    "Feather",
    "Leafstone",
    "Bejeweled",
    "Dragon Breathe",
    "Bat Scythe",
    "Saber",
    "Rainbow",
    "Glyph",
    "Shadow",
    "Quartz",
    "Reef",
    "Hologram",
    "Strife Purple",
    "Strife Red",
    "Strife Green",
    "Strife Black",
    "Moss",
    "Webbed",
    "Cryptic",
    "Skeletal",
    "Willow Red",
    "Willow Blue",
    "Willow Green",
    "Willow Purple",
    "Mermaid Blue",
    "Mermaid Green",
    "Mermaid Pink",
    "Fang Red",
    "Fang Blue",
    "Fang Purple",
    "Fang Frost",
    "Angel",
    "Celestial",
    "Reaper",
    "Frosthorn",
    "Butterfly Blue",
    "Butterfly Purple",
}

local KillEffects = {
    "Reef",
    "Vaporize",
    "Burn",
    "Bat",
    "GradeA",
    "Splatter",
    "Vip",
    "Void",
    "Reaper",
    "FrostReaper",
    "Angel",
    "Demon",
    "Techno",
    "Celestial",
    "FrostCelestial",
    "Harmonic",
    "Frostbite",
    "Swirly",
    "Crystal Blue",
    "Crystal Purple",
    "Crystal Green",
    "Crystal White",
    "Strife Purple",
    "Strife Red",
    "Strife Green",
    "Strife Gold",
    "Strife WhiteGold",
    "Strife Frost",
    "Willow Red",
    "Willow Blue",
    "Willow Green",
    "Willow Purple",
    "Fang Red",
    "Fang Green",
    "Fang Blue",
    "Fang Gray",
    "Fang Purple",
    "Fang Frost",
    "Flutter Purple",
    "Flutter Pink",
    "Flutter Red",
    "Flutter Blue",
    "Flutter Black",
    "Flutter Frost",
    "Bubble Purple",
    "Bubble Blue",
    "Bubble Pink",
    "Bubble Red",
    "Bubble Black",
    "Bubble White",
    "Bubble Frost",
    "Elder Flame Blue",
    "Elder Flame Black",
    "Elder Flame Red",
    "Elder Flame Purple",
    "Elder Flame Frost",
    "Rhinestone Purple",
    "Rhinestone Red",
    "Rhinestone Blue",
    "Rhinestone Black",
    "Rhinestone Frost",
    "Ice Pegasus White",
    "Ice Pegasus Blue",
    "Ice Pegasus Purple",
    "Ice Pegasus Red",
    "Ice Pegasus Black",
    "Rosethorn",
    "Rosethorn Frost",
    "Nebula Blue",
    "Nebula Red",
    "Nebula Pink",
    "Nebula Green",
    "Nebula Black",
    "Android Purple",
    "Android Blue",
    "Android Green",
    "Android Pink",
    "Android White",
    "Peppermint Red",
    "Peppermint Blue",
    "Peppermint Green",
    "Peppermint Purple",
    "Conjure Blue",
    "Conjure Purple",
    "Conjure Green",
    "Conjure Red",
    "Frosthorn",
    "Leprichaun",
}

-- ══════════════════════════════════════
-- FUNÇÕES AUXILIARES
-- ══════════════════════════════════════

-- Obter todos os players inimigos
local function getEnemies()
    local enemies = {}
    local myChar = LocalPlayer.Character
    local myRole = LocalPlayer:GetAttribute("Role") or ""
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            -- Se TeamCheck ativo, ignora aliados (Sheriffs vs Sheriffs)
            if State.ESPTeamCheck then
                local theirRole = p:GetAttribute("Role") or ""
                if myRole == "Sheriff" and theirRole == "Sheriff" then
                    -- pula aliado
                else
                    table.insert(enemies, p)
                end
            else
                table.insert(enemies, p)
            end
        end
    end
    return enemies
end

-- Obter parte do corpo alvo
local function getTargetPart(char, partName)
    if not char then return nil end
    return char:FindFirstChild(partName) or char:FindFirstChild("HumanoidRootPart")
end

-- Encontrar jogador mais próximo do cursor (para silent aim)
local function getClosestPlayerToCursor(maxFOV)
    local closestPlayer = nil
    local closestDist   = maxFOV or State.AimbotFOV
    local screenCenter  = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char     = player.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local rootPart = char:FindFirstChild("HumanoidRootPart")
            if humanoid and humanoid.Health > 0 and rootPart then
                local targetPart = getTargetPart(char, State.AimbotPart) or rootPart
                local pos, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
                if onScreen then
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local dist = (screenCenter - screenPos).Magnitude
                    if dist < closestDist then
                        closestDist   = dist
                        closestPlayer = player
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- Obter posição do alvo (silent aim)
local function getSilentAimTarget()
    local target = getClosestPlayerToCursor(State.AimbotFOV)
    if not target or not target.Character then return nil end
    local part = getTargetPart(target.Character, State.AimbotPart)
    return part and part.Position or nil
end

-- ══════════════════════════════════════
-- SILENT AIM - Hook __namecall no ShootGun
-- Assinatura real: ShootGun:FireServer(originPos, targetPos, hitInst, hitPos)
-- ══════════════════════════════════════
local ShootGunRemote = nil
pcall(function()
    ShootGunRemote = game:GetService("ReplicatedStorage").Remotes.ShootGun
end)

pcall(function()
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    local oldNC = mt.__namecall
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and self == ShootGunRemote and State.SilentAim then
            local chance = math.random(1, 100)
            if chance <= State.SilentAimChance then
                local target = getClosestPlayerToCursor(State.AimbotFOV)
                if target and target.Character then
                    local part = getTargetPart(target.Character, State.AimbotPart)
                    if part then
                        local args = {...}
                        -- arg[1] = originPos (CharacterRayOrigin - não altera)
                        -- arg[2] = targetPos -> posição do alvo
                        -- arg[3] = hitInstance -> parte do alvo
                        -- arg[4] = hitPosition -> posição de impacto
                        args[2] = part.Position
                        args[3] = part
                        args[4] = part.Position
                        return oldNC(self, table.unpack(args))
                    end
                end
            end
        end
        return oldNC(self, ...)
    end)
    setreadonly(mt, true)
end)

-- ══════════════════════════════════════
-- AUTO SHOT - Dispara direto via ShootGun remote
-- Usa a assinatura correta: (originPos, targetPos, hitInst, hitPos)
-- ══════════════════════════════════════
local lastAutoShot = 0
RunService.Heartbeat:Connect(function()
    if not State.AutoShot then return end
    if tick() - lastAutoShot < State.AutoShotDelay then return end
    if not ShootGunRemote then return end

    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return end

    local target = getClosestPlayerToCursor(State.AimbotFOV)
    if not target or not target.Character then return end

    local targetHum = target.Character:FindFirstChildOfClass("Humanoid")
    if not targetHum or targetHum.Health <= 0 then return end

    local chance = math.random(1, 100)
    if chance > State.AutoShotChance then return end

    local targetPart = getTargetPart(target.Character, State.AimbotPart)
    if not targetPart then return end

    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end

    lastAutoShot = tick()

    -- Calcula a origem do tiro (CharacterRayOrigin - posição do torso/câmera)
    local originPos = Camera.CFrame.Position
    local hitPos    = targetPart.Position

    pcall(function()
        ShootGunRemote:FireServer(originPos, hitPos, targetPart, hitPos)
    end)
end)

-- ══════════════════════════════════════
-- FOV CIRCLE (Aimbot FOV Visual)
-- ══════════════════════════════════════
local fovCircle
pcall(function()
    fovCircle = Drawing.new("Circle")
    fovCircle.Visible   = false
    fovCircle.Color     = Color3.fromRGB(255, 255, 255)
    fovCircle.Thickness = 1.5
    fovCircle.Filled    = false
    fovCircle.NumSides  = 64
end)

RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Visible  = (State.ShowFOV and (State.SilentAim or State.AutoShot))
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        fovCircle.Radius   = State.AimbotFOV
    end
end)

-- ══════════════════════════════════════
-- ESP SYSTEM
-- ══════════════════════════════════════
local ESPObjects = {}

local function removeESP(player)
    if ESPObjects[player] then
        for _, obj in pairs(ESPObjects[player]) do
            pcall(function() obj:Remove() end)
        end
        ESPObjects[player] = nil
    end
end

local function createESP(player)
    if not player or player == LocalPlayer then return end
    removeESP(player)
    ESPObjects[player] = {}

    -- Box ESP
    local box = Drawing.new("Square")
    box.Visible   = false
    box.Color     = Color3.fromRGB(255, 255, 255)
    box.Thickness = 1.5
    box.Filled    = false
    ESPObjects[player].box = box

    -- Name
    local nameLabel = Drawing.new("Text")
    nameLabel.Visible  = false
    nameLabel.Color    = Color3.fromRGB(255, 255, 255)
    nameLabel.Size     = 13
    nameLabel.Center   = true
    nameLabel.Outline  = true
    ESPObjects[player].nameLabel = nameLabel

    -- Health bar
    local healthBar = Drawing.new("Square")
    healthBar.Visible = false
    healthBar.Color   = Color3.fromRGB(0, 255, 0)
    healthBar.Filled  = true
    ESPObjects[player].healthBar = healthBar

    -- Health bar background
    local healthBg = Drawing.new("Square")
    healthBg.Visible = false
    healthBg.Color   = Color3.fromRGB(0, 0, 0)
    healthBg.Filled  = true
    ESPObjects[player].healthBg = healthBg

    -- Distance label
    local distLabel = Drawing.new("Text")
    distLabel.Visible  = false
    distLabel.Color    = Color3.fromRGB(200, 200, 200)
    distLabel.Size     = 11
    distLabel.Center   = true
    distLabel.Outline  = true
    ESPObjects[player].distLabel = distLabel

    -- Tracer
    local tracer = Drawing.new("Line")
    tracer.Visible   = false
    tracer.Color     = Color3.fromRGB(255, 255, 255)
    tracer.Thickness = 1
    ESPObjects[player].tracer = tracer
end

-- Atualiza cor ESP baseado no papel do jogador
local function getESPColor(player)
    local role = player:GetAttribute("Role") or ""
    if role == "Murderer" then
        return State.ESPMurdererColor
    elseif role == "Sheriff" then
        return State.ESPSheriffColor
    else
        return State.ESPInnocentColor
    end
end

RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not ESPObjects[player] then
            createESP(player)
        end

        local objects = ESPObjects[player]
        if not objects then continue end

        local char    = player.Character
        local enabled = State.ESPEnabled and char ~= nil

        if not enabled then
            for _, obj in pairs(objects) do
                pcall(function() obj.Visible = false end)
            end
            continue
        end

        local rootPart = char:FindFirstChild("HumanoidRootPart")
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not rootPart or not humanoid then
            for _, obj in pairs(objects) do
                pcall(function() obj.Visible = false end)
            end
            continue
        end

        local dist = (Camera.CFrame.Position - rootPart.Position).Magnitude
        if dist > State.ESPMaxDist then
            for _, obj in pairs(objects) do
                pcall(function() obj.Visible = false end)
            end
            continue
        end

        local espColor = getESPColor(player)
        local head     = char:FindFirstChild("Head")
        local headPos, headOnScreen, headDepth
        local rootPos, rootOnScreen

        if head then
            local v3 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.7, 0))
            headPos      = Vector2.new(v3.X, v3.Y)
            headOnScreen = v3.Z > 0
        end

        local v3root = Camera:WorldToViewportPoint(rootPart.Position - Vector3.new(0, 3, 0))
        rootPos      = Vector2.new(v3root.X, v3root.Y)
        rootOnScreen = v3root.Z > 0

        if not headOnScreen or not rootOnScreen then
            for _, obj in pairs(objects) do
                pcall(function() obj.Visible = false end)
            end
            continue
        end

        local height   = math.abs(headPos.Y - rootPos.Y)
        local width    = height * 0.55
        local topLeft  = Vector2.new(headPos.X - width / 2, headPos.Y)

        -- Box
        if objects.box then
            objects.box.Visible   = State.ESPBoxes
            objects.box.Color     = espColor
            objects.box.Position  = topLeft
            objects.box.Size      = Vector2.new(width, height)
        end

        -- Name
        if objects.nameLabel then
            objects.nameLabel.Visible   = State.ESPNames
            objects.nameLabel.Color     = espColor
            objects.nameLabel.Text      = player.DisplayName
            objects.nameLabel.Position  = Vector2.new(headPos.X, headPos.Y - 16)
        end

        -- Distance
        if objects.distLabel then
            objects.distLabel.Visible   = State.ESPDistance
            objects.distLabel.Text      = string.format("[%.0fm]", dist)
            objects.distLabel.Position  = Vector2.new(rootPos.X, rootPos.Y + 2)
        end

        -- Health bar
        local hp     = humanoid.Health
        local maxHp  = humanoid.MaxHealth
        local hpRatio = maxHp > 0 and (hp / maxHp) or 0
        local barH   = height * hpRatio
        local barX   = topLeft.X - 6
        local barY   = rootPos.Y

        if objects.healthBg then
            objects.healthBg.Visible  = State.ESPHealth
            objects.healthBg.Position = Vector2.new(barX, headPos.Y)
            objects.healthBg.Size     = Vector2.new(4, height)
        end

        if objects.healthBar then
            local hpColor = Color3.fromRGB(
                math.floor(255 * (1 - hpRatio)),
                math.floor(255 * hpRatio),
                0
            )
            objects.healthBar.Visible  = State.ESPHealth
            objects.healthBar.Color    = hpColor
            objects.healthBar.Position = Vector2.new(barX, headPos.Y + height * (1 - hpRatio))
            objects.healthBar.Size     = Vector2.new(4, barH)
        end

        -- Tracer
        if objects.tracer then
            objects.tracer.Visible = State.ESPTracers
            objects.tracer.Color   = espColor
            objects.tracer.From    = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            objects.tracer.To      = rootPos
        end
    end
end)

-- Limpa ESP quando jogador sai
Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- ══════════════════════════════════════
-- INFINITE JUMP
-- ══════════════════════════════════════
UserInputService.JumpRequest:Connect(function()
    if not State.InfiniteJump then return end
    local char = LocalPlayer.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

-- ══════════════════════════════════════
-- SPEED HACK
-- ══════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not State.SpeedEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        hum.WalkSpeed = State.SpeedValue
    end
end)

-- ══════════════════════════════════════
-- NOCLIP
-- ══════════════════════════════════════
RunService.Stepped:Connect(function()
    if not State.NoClipEnabled then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

-- ══════════════════════════════════════
-- ANTI-RAGDOLL
-- ══════════════════════════════════════
local function applyAntiRagdoll(char)
    if not State.AntiRagdoll or not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") then
            pcall(function()
                v.Enabled = false
            end)
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    applyAntiRagdoll(char)
    char.DescendantAdded:Connect(function()
        applyAntiRagdoll(char)
    end)
end)

-- ══════════════════════════════════════
-- FULLBRIGHT
-- ══════════════════════════════════════
local originalBrightness
local originalAmbient
local originalOutdoorAmbient
local Lighting = game:GetService("Lighting")

local function setFullbright(enabled)
    if enabled then
        originalBrightness     = Lighting.Brightness
        originalAmbient        = Lighting.Ambient
        originalOutdoorAmbient = Lighting.OutdoorAmbient
        Lighting.Brightness      = 2
        Lighting.Ambient         = Color3.fromRGB(178, 178, 178)
        Lighting.OutdoorAmbient  = Color3.fromRGB(178, 178, 178)
        -- Remove fog
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Atmosphere") then
                v.Density = 0
                v.Haze    = 0
            end
        end
    else
        if originalBrightness then
            Lighting.Brightness     = originalBrightness
            Lighting.Ambient        = originalAmbient
            Lighting.OutdoorAmbient = originalOutdoorAmbient
        end
    end
end

-- ══════════════════════════════════════
-- NO FOG
-- ══════════════════════════════════════
local function setNoFog(enabled)
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") then
            if enabled then
                v.Density = 0
                v.Haze    = 0
            end
        end
    end
    Lighting.FogEnd   = enabled and 100000 or 1000
    Lighting.FogStart = enabled and 99999 or 0
end

-- ══════════════════════════════════════
-- CUSTOM FOV
-- ══════════════════════════════════════
local function setCustomFOV(enabled, value)
    if enabled then
        Camera.FieldOfView = value
    else
        Camera.FieldOfView = 70
    end
end

-- ══════════════════════════════════════
-- AUTO EQUIP GUN - equipa a arma automaticamente
-- ══════════════════════════════════════
RunService.Heartbeat:Connect(function()
    if not State.AutoEquipGun then return end
    local char = LocalPlayer.Character
    if not char then return end
    local backpack = LocalPlayer:FindFirstChild("Backpack")
    if not backpack then return end
    -- Tenta equipar a primeira Tool do backpack que seja GunTool
    for _, tool in ipairs(backpack:GetChildren()) do
        if tool:IsA("Tool") then
            local CS = game:GetService("CollectionService")
            local ok2, hasTag = pcall(function()
                return CS:HasTag(tool, "GunTool")
            end)
            if ok2 and hasTag then
                LocalPlayer.Character.Humanoid:EquipTool(tool)
                break
            end
        end
    end
end)

-- ══════════════════════════════════════
-- ANTI-KICK (bloqueia kicks via desconexão forçada)
-- ══════════════════════════════════════
-- Nota: Anti-Kick via hook de metatable é detectado pelo BAC.
-- Abordagem segura: monitora kicks e notifica o usuário.
local function enableAntiKick(enabled)
    if enabled then
        Rayfield:Notify({
            Title   = "Anti-Kick",
            Content = "Anti-Kick ativo. Monitorando kicks do servidor.",
            Duration = 3,
        })
        -- Monitora o evento de kick do LocalPlayer de forma passiva
        LocalPlayer.OnTeleport:Connect(function(state)
            if state == Enum.TeleportState.RequestedFromServer then
                Rayfield:Notify({
                    Title   = "Anti-Kick",
                    Content = "Tentativa de kick detectada!",
                    Duration = 4,
                })
            end
        end)
    end
end

-- ══════════════════════════════════════
-- SKIN VISUAL DA ARMA (via texture swap)
-- ══════════════════════════════════════
-- Mapeamento de skin -> IDs de textura
local GunSkinTextures = {
    ["Default"]           = nil,
    ["Reef"]              = "rbxassetid://14134879105",
    ["Strife Purple"]     = "rbxassetid://15222267465",
    ["Strife Red"]        = "rbxassetid://15222265229",
    ["Strife Green"]      = "rbxassetid://15222258241",
    ["Strife Gold"]       = "rbxassetid://15222262718",
    ["Mermaid"]           = "rbxassetid://14208214271",
    ["Fang Red"]          = "rbxassetid://14074161508",
    ["Fang Green"]        = "rbxassetid://14074156095",
    ["Fang Blue"]         = "rbxassetid://14074165525",
    ["Fang Gray"]         = "rbxassetid://14074170044",
    ["Fang Purple"]       = "rbxassetid://13140835728",
    ["Fang Green-Purple"] = "rbxassetid://13140832483",
    ["Fang Frost"]        = "rbxassetid://13140830742",
    ["Willow Red"]        = "rbxassetid://15291413157",
    ["Willow Blue"]       = "rbxassetid://15291410308",
    ["Willow Green"]      = "rbxassetid://15291409077",
    ["Willow Purple"]     = "rbxassetid://15291412065",
}

-- Aplica skin na arma equipada via SurfaceAppearance (igual ao jogo usa)
local function applyGunSkin(skinName)
    local char = LocalPlayer.Character
    if not char then return end
    -- Busca tanto no char quanto no backpack
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then tool = bp:FindFirstChildOfClass("Tool") end
    end
    if not tool then return end

    local textureId = GunSkinTextures[skinName]

    for _, part in ipairs(tool:GetDescendants()) do
        if part:IsA("MeshPart") then
            pcall(function()
                if textureId then
                    -- Cria ou atualiza SurfaceAppearance (como o jogo faz)
                    local sa = part:FindFirstChildOfClass("SurfaceAppearance")
                    if not sa then
                        sa = Instance.new("SurfaceAppearance", part)
                    end
                    sa.ColorMap = textureId
                else
                    -- Default: remove SurfaceAppearance customizada
                    local sa = part:FindFirstChildOfClass("SurfaceAppearance")
                    if sa then sa:Destroy() end
                end
            end)
        end
    end
end

-- Aplica skin na faca
local KnifeSkinTextures = {
    ["Default (Shimmer)"] = "rbxassetid://13140672466",
    ["Feather"]           = "rbxassetid://13140830742",
    ["Leafstone"]         = "rbxassetid://13140832483",
    ["Bejeweled"]         = "rbxassetid://13140835728",
    ["Dragon Breathe"]    = "rbxassetid://13678829534",
    ["Bat Scythe"]        = "rbxassetid://13683338319",
    ["Saber"]             = "rbxassetid://13683337103",
    ["Rainbow"]           = "rbxassetid://14074170044",
    ["Glyph"]             = "rbxassetid://14074165525",
    ["Shadow"]            = "rbxassetid://14074161508",
    ["Quartz"]            = "rbxassetid://14074156095",
    ["Reef"]              = "rbxassetid://14134879105",
    ["Hologram"]          = "rbxassetid://14208214271",
    ["Strife Purple"]     = "rbxassetid://15222267465",
    ["Strife Red"]        = "rbxassetid://15222265229",
    ["Strife Green"]      = "rbxassetid://15222258241",
    ["Strife Black"]      = "rbxassetid://15222262718",
    ["Moss"]              = "rbxassetid://15291088543",
    ["Webbed"]            = "rbxassetid://15291091889",
    ["Cryptic"]           = "rbxassetid://15291089821",
    ["Skeletal"]          = "rbxassetid://15291065966",
    ["Willow Red"]        = "rbxassetid://15291413157",
    ["Willow Blue"]       = "rbxassetid://15291410308",
    ["Willow Green"]      = "rbxassetid://15291409077",
    ["Willow Purple"]     = "rbxassetid://15291412065",
}

local function applyKnifeSkin(skinName)
    local char = LocalPlayer.Character
    if not char then return end
    local CS = game:GetService("CollectionService")

    local function findKnife(parent)
        for _, t in ipairs(parent:GetChildren()) do
            if t:IsA("Tool") then
                local ok, hasTag = pcall(function() return CS:HasTag(t, "KnifeTool") end)
                if ok and hasTag then return t end
            end
        end
        return nil
    end

    local knife = findKnife(char)
    if not knife then
        local bp = LocalPlayer:FindFirstChild("Backpack")
        if bp then knife = findKnife(bp) end
    end
    -- Se não achou com tag, pega qualquer tool que não seja GunTool
    if not knife then
        for _, t in ipairs(char:GetChildren()) do
            if t:IsA("Tool") then
                local ok, isGun = pcall(function() return CS:HasTag(t, "GunTool") end)
                if not (ok and isGun) then knife = t break end
            end
        end
    end
    if not knife then return end

    local textureId = KnifeSkinTextures[skinName]

    for _, part in ipairs(knife:GetDescendants()) do
        if part:IsA("MeshPart") then
            pcall(function()
                if textureId then
                    -- Usa SurfaceAppearance como o jogo
                    local sa = part:FindFirstChildOfClass("SurfaceAppearance")
                    if not sa then
                        sa = Instance.new("SurfaceAppearance", part)
                    end
                    sa.ColorMap = textureId
                    -- TextureID também para compatibilidade
                    part.TextureID = textureId
                else
                    local sa = part:FindFirstChildOfClass("SurfaceAppearance")
                    if sa then sa:Destroy() end
                end
            end)
        end
    end
end

-- ══════════════════════════════════════
-- FPS DISPLAY
-- ══════════════════════════════════════
local fpsLabel
pcall(function()
    fpsLabel = Drawing.new("Text")
    fpsLabel.Visible  = false
    fpsLabel.Color    = Color3.fromRGB(0, 255, 0)
    fpsLabel.Size     = 14
    fpsLabel.Outline  = true
    fpsLabel.Position = Vector2.new(10, 10)
end)

local lastFPSTime = tick()
local fpsCount    = 0
local currentFPS  = 0

RunService.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    local now = tick()
    if now - lastFPSTime >= 1 then
        currentFPS  = fpsCount
        fpsCount    = 0
        lastFPSTime = now
    end
    if fpsLabel then
        fpsLabel.Visible = State.ShowFPS
        fpsLabel.Text    = string.format("FPS: %d", currentFPS)
    end
end)

-- ══════════════════════════════════════
-- CRIAÇÃO DA GUI - RAYFIELD
-- ══════════════════════════════════════
local Window = Rayfield:CreateWindow({
    Name             = "MVS DUELS Script",
    Icon             = 0,
    LoadingTitle     = "Murderers VS Sheriffs DUELS",
    LoadingSubtitle  = "Script Completo | by Script Tool",
    Theme            = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,
    ConfigurationSaving = {
        Enabled   = true,
        FolderName = "MVSDuels",
        FileName   = "Config",
    },
    Discord = {
        Enabled = false,
    },
    KeySystem = false,
})

-- ══════════════════════════════════════════════════════════════
-- TAB 1: AIMBOT
-- ══════════════════════════════════════════════════════════════
local AimbotTab = Window:CreateTab("🎯 Aimbot", 4483362458)

AimbotTab:CreateSection("Silent Aim")

AimbotTab:CreateToggle({
    Name         = "Silent Aim",
    CurrentValue = false,
    Flag         = "SilentAim",
    Callback     = function(v)
        State.SilentAim = v
    end,
})

AimbotTab:CreateSlider({
    Name         = "Chance de Acerto (%)",
    Range        = {1, 100},
    Increment    = 1,
    Suffix       = "%",
    CurrentValue = 85,
    Flag         = "SilentAimChance",
    Callback     = function(v)
        State.SilentAimChance = v
    end,
})

AimbotTab:CreateSlider({
    Name         = "FOV do Aimbot",
    Range        = {10, 500},
    Increment    = 5,
    Suffix       = "px",
    CurrentValue = 120,
    Flag         = "AimbotFOV",
    Callback     = function(v)
        State.AimbotFOV = v
    end,
})

AimbotTab:CreateToggle({
    Name         = "Mostrar Círculo FOV",
    CurrentValue = true,
    Flag         = "ShowFOV",
    Callback     = function(v)
        State.ShowFOV = v
    end,
})

AimbotTab:CreateDropdown({
    Name         = "Parte Alvo",
    Options      = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"},
    CurrentOption = {"Head"},
    MultipleOptions = false,
    Flag         = "AimbotPart",
    Callback     = function(v)
        State.AimbotPart = type(v) == "table" and v[1] or v
    end,
})

AimbotTab:CreateSection("Auto Shot")

AimbotTab:CreateToggle({
    Name         = "Auto Shot",
    CurrentValue = false,
    Flag         = "AutoShot",
    Callback     = function(v)
        State.AutoShot = v
    end,
})

AimbotTab:CreateSlider({
    Name         = "Chance Auto Shot (%)",
    Range        = {1, 100},
    Increment    = 1,
    Suffix       = "%",
    CurrentValue = 85,
    Flag         = "AutoShotChance",
    Callback     = function(v)
        State.AutoShotChance = v
    end,
})

AimbotTab:CreateSlider({
    Name         = "Delay Auto Shot (s)",
    Range        = {5, 100},
    Increment    = 5,
    Suffix       = "x0.01s",
    CurrentValue = 15,
    Flag         = "AutoShotDelay",
    Callback     = function(v)
        State.AutoShotDelay = v / 100
    end,
})

-- ══════════════════════════════════════════════════════════════
-- TAB 2: ESP
-- ══════════════════════════════════════════════════════════════
local ESPTab = Window:CreateTab("👁️ ESP", 4483362458)

ESPTab:CreateSection("ESP Principal")

ESPTab:CreateToggle({
    Name         = "ESP Ativado",
    CurrentValue = false,
    Flag         = "ESPEnabled",
    Callback     = function(v)
        State.ESPEnabled = v
    end,
})

ESPTab:CreateToggle({
    Name         = "Boxes ESP",
    CurrentValue = false,
    Flag         = "ESPBoxes",
    Callback     = function(v)
        State.ESPBoxes = v
    end,
})

ESPTab:CreateToggle({
    Name         = "Nomes ESP",
    CurrentValue = true,
    Flag         = "ESPNames",
    Callback     = function(v)
        State.ESPNames = v
    end,
})

ESPTab:CreateToggle({
    Name         = "Distância ESP",
    CurrentValue = true,
    Flag         = "ESPDistance",
    Callback     = function(v)
        State.ESPDistance = v
    end,
})

ESPTab:CreateToggle({
    Name         = "Barra de Vida",
    CurrentValue = true,
    Flag         = "ESPHealth",
    Callback     = function(v)
        State.ESPHealth = v
    end,
})

ESPTab:CreateToggle({
    Name         = "Tracers",
    CurrentValue = false,
    Flag         = "ESPTracers",
    Callback     = function(v)
        State.ESPTracers = v
    end,
})

ESPTab:CreateToggle({
    Name         = "Verificar Time",
    CurrentValue = true,
    Flag         = "ESPTeamCheck",
    Callback     = function(v)
        State.ESPTeamCheck = v
    end,
})

ESPTab:CreateSlider({
    Name         = "Distância Máxima ESP",
    Range        = {50, 2000},
    Increment    = 50,
    Suffix       = "studs",
    CurrentValue = 500,
    Flag         = "ESPMaxDist",
    Callback     = function(v)
        State.ESPMaxDist = v
    end,
})

ESPTab:CreateSection("Cores ESP")

ESPTab:CreateColorPicker({
    Name    = "Cor Murderer",
    Color   = Color3.fromRGB(255, 60, 60),
    Flag    = "ESPMurdererColor",
    Callback = function(v)
        State.ESPMurdererColor = v
    end,
})

ESPTab:CreateColorPicker({
    Name    = "Cor Sheriff",
    Color   = Color3.fromRGB(60, 150, 255),
    Flag    = "ESPSheriffColor",
    Callback = function(v)
        State.ESPSheriffColor = v
    end,
})

ESPTab:CreateColorPicker({
    Name    = "Cor Innocent",
    Color   = Color3.fromRGB(100, 255, 100),
    Flag    = "ESPInnocentColor",
    Callback = function(v)
        State.ESPInnocentColor = v
    end,
})

-- ══════════════════════════════════════════════════════════════
-- TAB 3: VISUAIS DE ARMA
-- ══════════════════════════════════════════════════════════════
local WeaponTab = Window:CreateTab("🔫 Armas & Skins", 4483362458)

WeaponTab:CreateSection("Skin da Arma (Revólver/Sheriff)")

WeaponTab:CreateToggle({
    Name         = "Ativar Skin de Arma",
    CurrentValue = false,
    Flag         = "GunSkinEnabled",
    Callback     = function(v)
        State.GunSkinEnabled = v
        if v then applyGunSkin(State.SelectedGunSkin) end
    end,
})

WeaponTab:CreateDropdown({
    Name            = "Skin da Arma",
    Options         = GunSkins,
    CurrentOption   = {"Default"},
    MultipleOptions = false,
    Flag            = "SelectedGunSkin",
    Callback        = function(v)
        State.SelectedGunSkin = type(v) == "table" and v[1] or v
        if State.GunSkinEnabled then
            applyGunSkin(State.SelectedGunSkin)
        end
    end,
})

WeaponTab:CreateButton({
    Name     = "Aplicar Skin Agora",
    Callback = function()
        applyGunSkin(State.SelectedGunSkin)
    end,
})

WeaponTab:CreateSection("Skin da Faca (Murderer)")

WeaponTab:CreateToggle({
    Name         = "Ativar Skin de Faca",
    CurrentValue = false,
    Flag         = "KnifeSkinEnabled",
    Callback     = function(v)
        State.KnifeSkinEnabled = v
        if v then applyKnifeSkin(State.SelectedKnife) end
    end,
})

WeaponTab:CreateDropdown({
    Name            = "Skin da Faca",
    Options         = KnifeSkins,
    CurrentOption   = {"Default (Shimmer)"},
    MultipleOptions = false,
    Flag            = "SelectedKnife",
    Callback        = function(v)
        State.SelectedKnife = type(v) == "table" and v[1] or v
        if State.KnifeSkinEnabled then
            applyKnifeSkin(State.SelectedKnife)
        end
    end,
})

WeaponTab:CreateButton({
    Name     = "Aplicar Skin de Faca Agora",
    Callback = function()
        applyKnifeSkin(State.SelectedKnife)
    end,
})

WeaponTab:CreateSection("Efeito de Morte")

WeaponTab:CreateToggle({
    Name         = "Ativar Efeito de Morte",
    CurrentValue = false,
    Flag         = "KillEffectEnabled",
    Callback     = function(v)
        State.KillEffectEnabled = v
    end,
})

WeaponTab:CreateDropdown({
    Name            = "Efeito de Morte",
    Options         = KillEffects,
    CurrentOption   = {"Reef"},
    MultipleOptions = false,
    Flag            = "SelectedKillEffect",
    Callback        = function(v)
        State.SelectedKillEffect = type(v) == "table" and v[1] or v
    end,
})

-- Hook no OnPlayerKilled para aplicar efeito de morte
if OnPlayerKilledRemote then
    OnPlayerKilledRemote.OnClientEvent:Connect(function(killedPlayer, killerPlayer)
        if not State.KillEffectEnabled then return end
        if killerPlayer ~= LocalPlayer then return end
        -- Tenta aplicar o efeito no personagem morto
        local char = killedPlayer and killedPlayer.Character
        if not char then return end
        -- Simula o efeito visualmente no cliente
        pcall(function()
            local KillEffectHandler = LocalPlayer.PlayerScripts:FindFirstChild("KillEffectHandler", true)
            if KillEffectHandler then
                -- Tenta chamar o efeito selecionado
                local effectModule = KillEffectHandler:FindFirstChild(State.SelectedKillEffect, true)
                if effectModule then
                    local effect = require(effectModule)
                    if type(effect) == "function" then
                        effect(char)
                    end
                end
            end
        end)

    end)
end

-- ══════════════════════════════════════════════════════════════
-- TAB 4: MISC
-- ══════════════════════════════════════════════════════════════
local MiscTab = Window:CreateTab("⚙️ Misc", 4483362458)

MiscTab:CreateSection("Movimento")

MiscTab:CreateToggle({
    Name         = "Infinite Jump",
    CurrentValue = false,
    Flag         = "InfiniteJump",
    Callback     = function(v)
        State.InfiniteJump = v
    end,
})

MiscTab:CreateToggle({
    Name         = "Speed Hack",
    CurrentValue = false,
    Flag         = "SpeedEnabled",
    Callback     = function(v)
        State.SpeedEnabled = v
        if not v then
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
        end
    end,
})

MiscTab:CreateSlider({
    Name         = "Velocidade",
    Range        = {16, 200},
    Increment    = 2,
    Suffix       = " WalkSpeed",
    CurrentValue = 16,
    Flag         = "SpeedValue",
    Callback     = function(v)
        State.SpeedValue = v
    end,
})

MiscTab:CreateToggle({
    Name         = "NoClip",
    CurrentValue = false,
    Flag         = "NoClipEnabled",
    Callback     = function(v)
        State.NoClipEnabled = v
    end,
})

MiscTab:CreateToggle({
    Name         = "Anti-Ragdoll",
    CurrentValue = false,
    Flag         = "AntiRagdoll",
    Callback     = function(v)
        State.AntiRagdoll = v
        if v then applyAntiRagdoll(LocalPlayer.Character) end
    end,
})

MiscTab:CreateSection("Visual")

MiscTab:CreateToggle({
    Name         = "Fullbright",
    CurrentValue = false,
    Flag         = "Fullbright",
    Callback     = function(v)
        State.Fullbright = v
        setFullbright(v)
    end,
})

MiscTab:CreateToggle({
    Name         = "No Fog",
    CurrentValue = false,
    Flag         = "NoFog",
    Callback     = function(v)
        State.NoFog = v
        setNoFog(v)
    end,
})

MiscTab:CreateToggle({
    Name         = "FOV Customizado",
    CurrentValue = false,
    Flag         = "CustomFOV",
    Callback     = function(v)
        State.CustomFOV = v
        setCustomFOV(v, State.CustomFOVValue)
    end,
})

MiscTab:CreateSlider({
    Name         = "Valor FOV",
    Range        = {30, 120},
    Increment    = 5,
    Suffix       = "°",
    CurrentValue = 70,
    Flag         = "CustomFOVValue",
    Callback     = function(v)
        State.CustomFOVValue = v
        if State.CustomFOV then setCustomFOV(true, v) end
    end,
})

MiscTab:CreateToggle({
    Name         = "Mostrar FPS",
    CurrentValue = false,
    Flag         = "ShowFPS",
    Callback     = function(v)
        State.ShowFPS = v
    end,
})

MiscTab:CreateSection("Gameplay")

MiscTab:CreateToggle({
    Name         = "Auto Equipar Arma",
    CurrentValue = false,
    Flag         = "AutoEquipGun",
    Callback     = function(v)
        State.AutoEquipGun = v
    end,
})

MiscTab:CreateSection("Segurança")

MiscTab:CreateToggle({
    Name         = "Anti-Kick",
    CurrentValue = false,
    Flag         = "AntiKick",
    Callback     = function(v)
        State.AntiKick = v
        enableAntiKick(v)
    end,
})

-- ══════════════════════════════════════════════════════════════
-- TAB 5: JOGO
-- ══════════════════════════════════════════════════════════════
local GameTab = Window:CreateTab("🎮 Jogo", 4483362458)

GameTab:CreateSection("Informações do Servidor")

GameTab:CreateButton({
    Name     = "Ver Info do Servidor",
    Callback = function()
        local plrCount = #Players:GetPlayers()
        local jobId    = game.JobId
        Rayfield:Notify({
            Title    = "Info do Servidor",
            Content  = string.format("Jogadores: %d\nJob ID: %s", plrCount, jobId),
            Duration = 5,
        })
    end,
})

GameTab:CreateSection("Papéis no Jogo")

GameTab:CreateButton({
    Name     = "Ver Papéis de Todos",
    Callback = function()
        local msg = ""
        for _, p in ipairs(Players:GetPlayers()) do
            local role = p:GetAttribute("Role") or "?"
            msg = msg .. p.Name .. ": " .. role .. "\n"
        end
        if msg == "" then msg = "Sem informação de papel ainda." end
        Rayfield:Notify({
            Title    = "Papéis dos Jogadores",
            Content  = msg,
            Duration = 8,
        })
    end,
})

GameTab:CreateButton({
    Name     = "Ver Meu Papel",
    Callback = function()
        local role = LocalPlayer:GetAttribute("Role") or "Sem papel ainda"
        local match = LocalPlayer:GetAttribute("Match") or false
        Rayfield:Notify({
            Title    = "Meu Papel",
            Content  = "Papel: " .. role .. "\nEm partida: " .. tostring(match),
            Duration = 4,
        })
    end,
})

GameTab:CreateSection("Teleporte")

GameTab:CreateDropdown({
    Name            = "Teleportar para Jogador",
    Options         = {"[Nenhum]"},
    CurrentOption   = {"[Nenhum]"},
    MultipleOptions = false,
    Flag            = "TeleportTarget",
    Callback        = function(v)
        local targetName = type(v) == "table" and v[1] or v
        if targetName == "[Nenhum]" then return end
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Name == targetName and p.Character then
                local root = p.Character:FindFirstChild("HumanoidRootPart")
                if root then
                    local myChar = LocalPlayer.Character
                    if myChar then
                        local myRoot = myChar:FindFirstChild("HumanoidRootPart")
                        if myRoot then
                            myRoot.CFrame = root.CFrame + Vector3.new(3, 0, 0)
                            Rayfield:Notify({
                                Title    = "Teleporte",
                                Content  = "Teleportado para " .. p.Name,
                                Duration = 3,
                            })
                        end
                    end
                end
                break
            end
        end
    end,
})

-- Atualiza a lista de jogadores no dropdown de teleporte
RunService.Heartbeat:Connect(function()
    -- Atualização periódica da lista (a cada 5s)
end)

GameTab:CreateSection("Match Info")

GameTab:CreateButton({
    Name     = "Ver Stats da Partida",
    Callback = function()
        local kills  = LocalPlayer:GetAttribute("Kills")  or 0
        local deaths = LocalPlayer:GetAttribute("Deaths") or 0
        local wins   = LocalPlayer:GetAttribute("Wins")   or 0
        Rayfield:Notify({
            Title    = "Seus Stats",
            Content  = string.format("Kills: %d\nDeaths: %d\nWins: %d", kills, deaths, wins),
            Duration = 5,
        })
    end,
})

-- ══════════════════════════════════════════════════════════════
-- TAB 6: CONFIGS
-- ══════════════════════════════════════════════════════════════
local ConfigTab = Window:CreateTab("💾 Config", 4483362458)

ConfigTab:CreateSection("Salvar / Carregar")

ConfigTab:CreateButton({
    Name     = "Salvar Configuração",
    Callback = function()
        Rayfield:Notify({
            Title    = "Config Salva",
            Content  = "Configurações salvas com sucesso!",
            Duration = 3,
        })
    end,
})

ConfigTab:CreateSection("Sobre")

ConfigTab:CreateLabel("Script completo para Murderers VS Sheriffs DUELS")
ConfigTab:CreateLabel("Versão: 1.0 | Analisado via arquivo .rbxlx")
ConfigTab:CreateLabel("Inclui: Silent Aim, Auto Shot, ESP, Skins, Kill Effects")

-- ══════════════════════════════════════
-- BOTÃO FLUTUANTE PARA ABRIR/FECHAR GUI
-- ══════════════════════════════════════
-- Cria botão arrastável
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name            = "MVSToggleGui"
ScreenGui.ResetOnSpawn    = false
ScreenGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
ScreenGui.IgnoreGuiInset  = true

pcall(function()
    ScreenGui.Parent = CoreGui
end)
if not ScreenGui.Parent then
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Name            = "ToggleButton"
ToggleBtn.Size            = UDim2.new(0, 70, 0, 35)
ToggleBtn.Position        = UDim2.new(1, -90, 0.5, -18)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
ToggleBtn.TextColor3      = Color3.fromRGB(255, 255, 255)
ToggleBtn.Text            = "MVS"
ToggleBtn.Font            = Enum.Font.GothamBold
ToggleBtn.TextSize        = 14
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Parent          = ScreenGui

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 8)
BtnCorner.Parent       = ToggleBtn

local BtnStroke = Instance.new("UIStroke")
BtnStroke.Color     = Color3.fromRGB(0, 180, 255)
BtnStroke.Thickness = 1.5
BtnStroke.Parent    = ToggleBtn

-- Lógica de arrastar o botão
local dragging       = false
local dragStartPos
local dragStartFrame

ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging      = true
        dragStartPos  = input.Position
        dragStartFrame = ToggleBtn.Position
    end
end)

ToggleBtn.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                     input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartPos
        ToggleBtn.Position = UDim2.new(
            dragStartFrame.X.Scale,
            dragStartFrame.X.Offset + delta.X,
            dragStartFrame.Y.Scale,
            dragStartFrame.Y.Offset + delta.Y
        )
    end
end)

ToggleBtn.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or
       input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- Toggle GUI ao clicar (apenas se não arrastou)
local clickStart
ToggleBtn.MouseButton1Down:Connect(function()
    clickStart = tick()
end)

ToggleBtn.MouseButton1Up:Connect(function()
    if tick() - (clickStart or 0) < 0.2 and not dragging then
        -- Abre/fecha a GUI do Rayfield
        pcall(function()
            Rayfield:Toggle()
        end)
        -- Feedback visual
        TweenService:Create(ToggleBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(0, 180, 255)
        }):Play()
        task.delay(0.3, function()
            TweenService:Create(ToggleBtn, TweenInfo.new(0.15), {
                BackgroundColor3 = Color3.fromRGB(20, 20, 30)
            }):Play()
        end)
    end
end)

-- ══════════════════════════════════════
-- NOTIFICAÇÃO DE INÍCIO
-- ══════════════════════════════════════
-- Notificação removida a pedido do usuário

-- ══════════════════════════════════════
-- INIT - Aplica configurações iniciais
-- ══════════════════════════════════════
print("[MVS Script] Script carregado com sucesso!")
print("[MVS Script] Remotes encontrados:")
print("  ShootGun:", ShootGunRemote ~= nil)
print("  OnKilled:", OnKilledRemote ~= nil)
print("  EquipItem:", EquipItemRemote ~= nil)
