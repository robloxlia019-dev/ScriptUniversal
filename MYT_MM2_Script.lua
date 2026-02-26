--[[
    ╔══════════════════════════════════════════════════════════╗
    ║              MYT - Murder Mystery 2 Script               ║
    ║                   by tolopo637883                               ║
    ╚══════════════════════════════════════════════════════════╝
    
    FEATURES:
    - ESP (Murderer / Sheriff / Innocents)
    - Shot Murder (Auto detect + shoot)
    - ESP Murder / Inocente / Sheriff
    - Auto Faca (pessoa mais perta)
    - Double Jump com Boombox/Boombox Dourada
    - GUI Arrastável / Travável / Transparente
    - Slider de fechar (anima e vira botão MYT)
    - Seleção de Idioma (PT/EN/ES)
    - Muitas opções úteis
]]

-- =========================================================
-- SERVICES
-- =========================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- =========================================================
-- TRANSLATIONS
-- =========================================================
local LANG = "PT"

local T = {
    PT = {
        title = "MYT",
        by = "by tolopo637883",
        lang_select = "Selecione o Idioma",
        confirm = "Confirmar",
        esp_tab = "ESP",
        combat_tab = "Combate",
        misc_tab = "Misc",
        esp_murderer = "ESP Assassino",
        esp_sheriff = "ESP Sheriff",
        esp_innocent = "ESP Inocentes",
        esp_boxes = "Caixas ESP",
        esp_names = "Nomes ESP",
        esp_distance = "Distância ESP",
        esp_health = "Saúde ESP",
        esp_tracers = "Tracers ESP",
        esp_coins = "ESP Moedas",
        esp_guns = "ESP Armas",
        shot_murder = "Matar Assassino (Auto)",
        auto_knife = "Faca Auto (+ perto)",
        auto_collect_coins = "Coletar Moedas Auto",
        double_jump = "Double Jump (Boombox)",
        infinite_jump = "Pulo Infinito",
        noclip = "Noclip",
        speed_hack = "Speed Hack",
        speed_value = "Velocidade",
        no_fog = "Remover Neblina",
        fullbright = "Fullbright",
        fps_boost = "FPS Boost",
        anti_ragdoll = "Anti-Ragdoll",
        walkspeed = "WalkSpeed",
        jump_power = "JumpPower",
        reach = "Alcance Faca",
        silent_aim = "Silent Aim",
        anti_aim = "Anti-Aim",
        fov_circle = "Círculo FOV",
        fov_size = "Tamanho FOV",
        hitbox_exp = "Expandir Hitbox",
        hitbox_size = "Tamanho Hitbox",
        close_gui = "Fechar GUI",
        open_gui = "Abrir GUI",
        locked = "Travado",
        unlocked = "Destravar",
        lock_pos = "Travar Posição",
        transparent = "Transparente",
        credits = "by tolopo637883",
        esp_chams = "Chams (Cor Sólida)",
        role_label = "Sua Role: ",
        role_none = "Nenhuma",
        show_roles = "Mostrar Roles",
        auto_win = "Auto Win (Moedas)",
        ghost_esp = "ESP Fantasmas",
        lobby_info = "Info Lobby",
    },
    EN = {
        title = "MYT",
        by = "by tolopo637883",
        lang_select = "Select Language",
        confirm = "Confirm",
        esp_tab = "ESP",
        combat_tab = "Combat",
        misc_tab = "Misc",
        esp_murderer = "Murderer ESP",
        esp_sheriff = "Sheriff ESP",
        esp_innocent = "Innocents ESP",
        esp_boxes = "ESP Boxes",
        esp_names = "ESP Names",
        esp_distance = "ESP Distance",
        esp_health = "ESP Health",
        esp_tracers = "ESP Tracers",
        esp_coins = "Coins ESP",
        esp_guns = "Guns ESP",
        shot_murder = "Shot Murder (Auto)",
        auto_knife = "Auto Knife (Closest)",
        auto_collect_coins = "Auto Collect Coins",
        double_jump = "Double Jump (Boombox)",
        infinite_jump = "Infinite Jump",
        noclip = "Noclip",
        speed_hack = "Speed Hack",
        speed_value = "Speed",
        no_fog = "Remove Fog",
        fullbright = "Fullbright",
        fps_boost = "FPS Boost",
        anti_ragdoll = "Anti-Ragdoll",
        walkspeed = "WalkSpeed",
        jump_power = "JumpPower",
        reach = "Knife Reach",
        silent_aim = "Silent Aim",
        anti_aim = "Anti-Aim",
        fov_circle = "FOV Circle",
        fov_size = "FOV Size",
        hitbox_exp = "Expand Hitbox",
        hitbox_size = "Hitbox Size",
        close_gui = "Close GUI",
        open_gui = "Open GUI",
        locked = "Locked",
        unlocked = "Unlock",
        lock_pos = "Lock Position",
        transparent = "Transparent",
        credits = "by tolopo637883",
        esp_chams = "Chams (Solid Color)",
        role_label = "Your Role: ",
        role_none = "None",
        show_roles = "Show Roles",
        auto_win = "Auto Win (Coins)",
        ghost_esp = "Ghost ESP",
        lobby_info = "Lobby Info",
    },
    ES = {
        title = "MYT",
        by = "by tolopo637883",
        lang_select = "Seleccionar Idioma",
        confirm = "Confirmar",
        esp_tab = "ESP",
        combat_tab = "Combate",
        misc_tab = "Misc",
        esp_murderer = "ESP Asesino",
        esp_sheriff = "ESP Sheriff",
        esp_innocent = "ESP Inocentes",
        esp_boxes = "Cajas ESP",
        esp_names = "Nombres ESP",
        esp_distance = "Distancia ESP",
        esp_health = "Salud ESP",
        esp_tracers = "Tracers ESP",
        esp_coins = "ESP Monedas",
        esp_guns = "ESP Armas",
        shot_murder = "Matar Asesino (Auto)",
        auto_knife = "Cuchillo Auto (+ cerca)",
        auto_collect_coins = "Recoger Monedas Auto",
        double_jump = "Doble Salto (Boombox)",
        infinite_jump = "Salto Infinito",
        noclip = "Noclip",
        speed_hack = "Speed Hack",
        speed_value = "Velocidad",
        no_fog = "Quitar Niebla",
        fullbright = "Fullbright",
        fps_boost = "FPS Boost",
        anti_ragdoll = "Anti-Ragdoll",
        walkspeed = "WalkSpeed",
        jump_power = "JumpPower",
        reach = "Alcance Cuchillo",
        silent_aim = "Silent Aim",
        anti_aim = "Anti-Aim",
        fov_circle = "Círculo FOV",
        fov_size = "Tamaño FOV",
        hitbox_exp = "Expandir Hitbox",
        hitbox_size = "Tamaño Hitbox",
        close_gui = "Cerrar GUI",
        open_gui = "Abrir GUI",
        locked = "Bloqueado",
        unlocked = "Desbloquear",
        lock_pos = "Bloquear Posición",
        transparent = "Transparente",
        credits = "by tolopo637883",
        esp_chams = "Chams (Color Sólido)",
        role_label = "Tu Rol: ",
        role_none = "Ninguno",
        show_roles = "Mostrar Roles",
        auto_win = "Auto Win (Monedas)",
        ghost_esp = "ESP Fantasmas",
        lobby_info = "Info Lobby",
    },
}

local function tr(key)
    return (T[LANG] and T[LANG][key]) or (T["EN"][key]) or key
end

-- =========================================================
-- STATE / TOGGLES
-- =========================================================
local State = {
    ESP_Murderer      = true,
    ESP_Sheriff       = true,
    ESP_Innocent      = true,
    ESP_Boxes         = true,
    ESP_Names         = true,
    ESP_Distance      = true,
    ESP_Health        = false,
    ESP_Tracers       = false,
    ESP_Coins         = false,
    ESP_Guns          = false,
    ESP_Ghosts        = false,
    ESP_Chams         = false,
    ShotMurder        = false,
    AutoKnife         = false,
    AutoCollectCoins  = false,
    DoubleJump        = true,
    InfiniteJump      = false,
    Noclip            = false,
    SpeedHack         = false,
    SpeedValue        = 16,
    NoFog             = false,
    Fullbright        = false,
    FPSBoost          = false,
    AntiRagdoll       = false,
    WalkSpeed         = 16,
    JumpPower         = 50,
    KnifeReach        = 10,
    SilentAim         = false,
    AntiAim           = false,
    FOVCircle         = false,
    FOVSize           = 100,
    HitboxExpand      = false,
    HitboxSize        = 5,
    ShowRoles         = false,
    GuiTransparent    = false,
    GuiLocked         = false,
    GuiPosition       = UDim2.new(0.5, -230, 0.5, -200),
    CurrentRole       = "None",
    IsMinimized       = false,
}

-- =========================================================
-- ESP STORAGE
-- =========================================================
local ESPObjects = {}
local FOVCircleDrawing = nil

-- =========================================================
-- UTILITY FUNCTIONS
-- =========================================================
local function getCharacter(player)
    return player and player.Character
end

local function getRootPart(player)
    local char = getCharacter(player)
    return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

local function getHumanoid(player)
    local char = getCharacter(player)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function isAlive(player)
    local hum = getHumanoid(player)
    return hum and hum.Health > 0
end

local function getRole(player)
    -- MM2 stores role in character attributes or via remote
    local char = getCharacter(player)
    if not char then return "Unknown" end
    -- Try attribute first
    local roleAttr = char:GetAttribute("Role") or player:GetAttribute("Role")
    if roleAttr then return roleAttr end
    -- Try checking for knife/gun tools
    local hasKnife = false
    local hasGun = false
    for _, v in pairs(char:GetChildren()) do
        if v:IsA("Tool") then
            if v:FindFirstChild("KnifeClient") or v.Name:lower():find("knife") then hasKnife = true end
            if v:FindFirstChild("GunLocal") or v.Name:lower():find("gun") then hasGun = true end
        end
    end
    for _, v in pairs(player.Backpack:GetChildren()) do
        if v:IsA("Tool") then
            if v:FindFirstChild("KnifeClient") or v.Name:lower():find("knife") then hasKnife = true end
            if v:FindFirstChild("GunLocal") or v.Name:lower():find("gun") then hasGun = true end
        end
    end
    if hasKnife and not hasGun then return "Murderer" end
    if hasGun then return "Sheriff" end
    return "Innocent"
end

local function getClosestPlayer()
    local localChar = getCharacter(LocalPlayer)
    local localRoot = localChar and localChar:FindFirstChild("HumanoidRootPart")
    if not localRoot then return nil end
    
    local closest, closestDist = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isAlive(p) then
            local root = getRootPart(p)
            if root then
                local dist = (root.Position - localRoot.Position).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = p
                end
            end
        end
    end
    return closest
end

local function worldToViewport(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), onScreen, screenPos.Z
end

local function tween(obj, props, duration, style, direction)
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    local info = TweenInfo.new(duration or 0.3, style, direction)
    TweenService:Create(obj, info, props):Play()
end

-- =========================================================
-- ESP SYSTEM
-- =========================================================
local ROLE_COLORS = {
    Murderer = Color3.fromRGB(255, 60, 60),
    Sheriff  = Color3.fromRGB(60, 160, 255),
    Innocent = Color3.fromRGB(60, 255, 120),
    Unknown  = Color3.fromRGB(200, 200, 200),
    Ghost    = Color3.fromRGB(200, 200, 255),
}

local function createESPForPlayer(player)
    if ESPObjects[player] then return end
    local esp = {}
    
    -- Box (4 lines)
    local function makeLine()
        local d = Drawing.new("Line")
        d.Thickness = 1.5
        d.Visible = false
        return d
    end
    esp.BoxLines = {makeLine(), makeLine(), makeLine(), makeLine()}
    
    -- Name label
    esp.NameLabel = Drawing.new("Text")
    esp.NameLabel.Size = 14
    esp.NameLabel.Center = true
    esp.NameLabel.Outline = true
    esp.NameLabel.Visible = false
    
    -- Distance label
    esp.DistLabel = Drawing.new("Text")
    esp.DistLabel.Size = 12
    esp.DistLabel.Center = true
    esp.DistLabel.Outline = true
    esp.DistLabel.Visible = false
    
    -- Health bar
    esp.HealthBarBg = Drawing.new("Line")
    esp.HealthBarBg.Thickness = 4
    esp.HealthBarBg.Color = Color3.fromRGB(0,0,0)
    esp.HealthBarBg.Visible = false
    
    esp.HealthBar = Drawing.new("Line")
    esp.HealthBar.Thickness = 2.5
    esp.HealthBar.Color = Color3.fromRGB(0, 255, 80)
    esp.HealthBar.Visible = false
    
    -- Tracer
    esp.Tracer = Drawing.new("Line")
    esp.Tracer.Thickness = 1
    esp.Tracer.Visible = false
    
    ESPObjects[player] = esp
end

local function removeESPForPlayer(player)
    local esp = ESPObjects[player]
    if not esp then return end
    for _, line in pairs(esp.BoxLines) do line:Remove() end
    esp.NameLabel:Remove()
    esp.DistLabel:Remove()
    esp.HealthBarBg:Remove()
    esp.HealthBar:Remove()
    esp.Tracer:Remove()
    ESPObjects[player] = nil
end

local function updateESP()
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local char = getCharacter(player)
        local humanoid = getHumanoid(player)
        local rootPart = getRootPart(player)
        
        if not char or not humanoid or not rootPart then
            if ESPObjects[player] then
                for _, line in pairs(ESPObjects[player].BoxLines) do line.Visible = false end
                ESPObjects[player].NameLabel.Visible = false
                ESPObjects[player].DistLabel.Visible = false
                ESPObjects[player].HealthBarBg.Visible = false
                ESPObjects[player].HealthBar.Visible = false
                ESPObjects[player].Tracer.Visible = false
            end
            continue
        end
        
        -- Get role
        local role = getRole(player)
        
        -- Check if should show based on state
        local shouldShow = false
        if role == "Murderer" and State.ESP_Murderer then shouldShow = true end
        if role == "Sheriff" and State.ESP_Sheriff then shouldShow = true end
        if role == "Innocent" and State.ESP_Innocent then shouldShow = true end
        if humanoid.Health <= 0 and State.ESP_Ghosts then shouldShow = true; role = "Ghost" end
        
        if not shouldShow then
            if ESPObjects[player] then
                for _, line in pairs(ESPObjects[player].BoxLines) do line.Visible = false end
                ESPObjects[player].NameLabel.Visible = false
                ESPObjects[player].DistLabel.Visible = false
                ESPObjects[player].HealthBarBg.Visible = false
                ESPObjects[player].HealthBar.Visible = false
                ESPObjects[player].Tracer.Visible = false
            end
            continue
        end
        
        createESPForPlayer(player)
        local esp = ESPObjects[player]
        local color = ROLE_COLORS[role] or ROLE_COLORS.Unknown
        
        -- Calculate screen bounds
        local head = char:FindFirstChild("Head")
        if not head then continue end
        
        local headPos, headOnScreen, headZ = worldToViewport(head.Position + Vector3.new(0, 0.5, 0))
        local feetPos, feetOnScreen = worldToViewport(rootPart.Position - Vector3.new(0, 3, 0))
        
        if not headOnScreen or headZ < 0 then
            for _, line in pairs(esp.BoxLines) do line.Visible = false end
            esp.NameLabel.Visible = false
            esp.DistLabel.Visible = false
            esp.HealthBarBg.Visible = false
            esp.HealthBar.Visible = false
            esp.Tracer.Visible = false
            continue
        end
        
        local height = math.abs(headPos.Y - feetPos.Y)
        local width = height * 0.55
        local cx = headPos.X
        local topY = headPos.Y
        local botY = feetPos.Y
        
        local tl = Vector2.new(cx - width/2, topY)
        local tr = Vector2.new(cx + width/2, topY)
        local bl = Vector2.new(cx - width/2, botY)
        local br = Vector2.new(cx + width/2, botY)
        
        -- Box
        if State.ESP_Boxes then
            local corners = {tl, tr, tr, br, br, bl, bl, tl}
            for i = 1, 4 do
                local line = esp.BoxLines[i]
                line.From = corners[i*2-1]
                line.To = corners[i*2]
                line.Color = color
                line.Visible = true
            end
        else
            for _, line in pairs(esp.BoxLines) do line.Visible = false end
        end
        
        -- Name
        if State.ESP_Names then
            esp.NameLabel.Text = "[" .. role:sub(1,1) .. "] " .. player.Name
            esp.NameLabel.Color = color
            esp.NameLabel.Position = Vector2.new(cx, topY - 18)
            esp.NameLabel.Visible = true
        else
            esp.NameLabel.Visible = false
        end
        
        -- Distance
        if State.ESP_Distance then
            local localRoot = getRootPart(LocalPlayer)
            local dist = localRoot and math.floor((rootPart.Position - localRoot.Position).Magnitude) or 0
            esp.DistLabel.Text = dist .. "m"
            esp.DistLabel.Color = Color3.fromRGB(255,255,255)
            esp.DistLabel.Position = Vector2.new(cx, botY + 2)
            esp.DistLabel.Visible = true
        else
            esp.DistLabel.Visible = false
        end
        
        -- Health bar
        if State.ESP_Health then
            local healthPct = humanoid.Health / humanoid.MaxHealth
            local barHeight = height * healthPct
            local barX = cx - width/2 - 6
            esp.HealthBarBg.From = Vector2.new(barX, topY)
            esp.HealthBarBg.To = Vector2.new(barX, botY)
            esp.HealthBarBg.Visible = true
            esp.HealthBar.From = Vector2.new(barX, botY)
            esp.HealthBar.To = Vector2.new(barX, botY - barHeight)
            local r = 1 - healthPct
            local g = healthPct
            esp.HealthBar.Color = Color3.new(r, g, 0)
            esp.HealthBar.Visible = true
        else
            esp.HealthBarBg.Visible = false
            esp.HealthBar.Visible = false
        end
        
        -- Tracer
        if State.ESP_Tracers then
            esp.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            esp.Tracer.To = Vector2.new(cx, botY)
            esp.Tracer.Color = color
            esp.Tracer.Visible = true
        else
            esp.Tracer.Visible = false
        end
    end
end

-- Clean up ESP for removed players
Players.PlayerRemoving:Connect(function(player)
    removeESPForPlayer(player)
end)

-- =========================================================
-- DOUBLE JUMP WITH BOOMBOX
-- =========================================================
local doubleJumpUsed = false
local wasInAir = false

local function hasBoombox(player)
    local char = getCharacter(player)
    if not char then return false end
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") then
            local name = tool.Name:lower()
            if name:find("boombox") or name:find("radio") then
                return true, tool
            end
        end
    end
    return false
end

local function doDoubleJump()
    if not State.DoubleJump then return end
    local char = getCharacter(LocalPlayer)
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    
    -- Must be in air
    local onGround = (rootPart.Velocity.Y < 0.1 and rootPart.Velocity.Y > -1)
    if onGround then
        doubleJumpUsed = false
        return
    end
    
    -- Must have boombox
    local hasBomb, boomboxTool = hasBoombox(LocalPlayer)
    if not hasBomb then return end
    
    if not doubleJumpUsed then
        doubleJumpUsed = true
        -- Launch forward + upward
        local lookDir = humanoid.MoveDirection
        if lookDir.Magnitude < 0.1 then
            lookDir = rootPart.CFrame.LookVector
        end
        rootPart.Velocity = Vector3.new(
            lookDir.X * 30,
            55, -- upward boost
            lookDir.Z * 30
        )
    end
end

UserInputService.JumpRequest:Connect(function()
    local char = getCharacter(LocalPlayer)
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    local rootPart = char:FindFirstChild("HumanoidRootPart")
    if not rootPart then return end
    
    local isOnGround = (humanoid.FloorMaterial ~= Enum.Material.Air)
    
    if isOnGround then
        doubleJumpUsed = false
    else
        doDoubleJump()
    end
    
    if State.InfiniteJump then
        humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- =========================================================
-- SHOT MURDER (Auto shoot murderer)
-- =========================================================
local function doShotMurder()
    if not State.ShotMurder then return end
    local char = getCharacter(LocalPlayer)
    if not char then return end
    -- Find local gun in character or backpack
    local gun = nil
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and (tool:FindFirstChild("GunLocal") or tool.Name:lower():find("gun")) then
            gun = tool
            break
        end
    end
    if not gun then
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool:FindFirstChild("GunLocal") or tool.Name:lower():find("gun")) then
                -- Equip it
                tool.Parent = char
                gun = tool
                break
            end
        end
    end
    if not gun then return end
    
    -- Find murderer
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isAlive(p) then
            local role = getRole(p)
            if role == "Murderer" then
                local rootPart = getRootPart(p)
                local localRoot = getRootPart(LocalPlayer)
                if rootPart and localRoot then
                    local dist = (rootPart.Position - localRoot.Position).Magnitude
                    if dist < 200 then
                        -- Aim and fire
                        local activateEvent = gun:FindFirstChild("Activate") or gun:FindFirstChild("RemoteEvent")
                        if gun.Activated then
                            -- Fire through remote
                            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
                            if remote then
                                local gameplayRemote = remote:FindFirstChild("Gameplay")
                                if gameplayRemote then
                                    local shootRemote = gameplayRemote:FindFirstChild("Shoot")
                                    if shootRemote then
                                        shootRemote:FireServer(p.Name)
                                    end
                                end
                            end
                        end
                        break
                    end
                end
            end
        end
    end
end

-- =========================================================
-- AUTO KNIFE (closest player)
-- =========================================================
local function doAutoKnife()
    if not State.AutoKnife then return end
    local char = getCharacter(LocalPlayer)
    if not char then return end
    
    -- Find knife
    local knife = nil
    for _, tool in pairs(char:GetChildren()) do
        if tool:IsA("Tool") and (tool:FindFirstChild("KnifeClient") or tool.Name:lower():find("knife")) then
            knife = tool
            break
        end
    end
    if not knife then
        for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
            if tool:IsA("Tool") and (tool:FindFirstChild("KnifeClient") or tool.Name:lower():find("knife")) then
                tool.Parent = char
                knife = tool
                break
            end
        end
    end
    if not knife then return end
    
    local closest = getClosestPlayer()
    if not closest then return end
    
    local closestRoot = getRootPart(closest)
    local localRoot = getRootPart(LocalPlayer)
    if not closestRoot or not localRoot then return end
    
    local dist = (closestRoot.Position - localRoot.Position).Magnitude
    if dist <= State.KnifeReach then
        -- Throw knife via remote
        local remote = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        if remote then
            local gameplayRemote = remote:FindFirstChild("Gameplay")
            if gameplayRemote then
                local throwRemote = gameplayRemote:FindFirstChild("ThrowKnife") or gameplayRemote:FindFirstChild("Knife")
                if throwRemote then
                    throwRemote:FireServer(closest.Name, closestRoot.Position)
                end
            end
        end
    end
end

-- =========================================================
-- AUTO COLLECT COINS
-- =========================================================
local function doAutoCollectCoins()
    if not State.AutoCollectCoins then return end
    local char = getCharacter(LocalPlayer)
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Part") or obj:IsA("MeshPart") then
            local name = obj.Name:lower()
            if name:find("coin") or name:find("bag") then
                local dist = (obj.Position - root.Position).Magnitude
                if dist < 50 then
                    -- Touch the coin
                    local tween = TweenService:Create(root, TweenInfo.new(0.1), {CFrame = CFrame.new(obj.Position)})
                    tween:Play()
                    break
                end
            end
        end
    end
end

-- =========================================================
-- NOCLIP
-- =========================================================
RunService.Stepped:Connect(function()
    if State.Noclip then
        local char = getCharacter(LocalPlayer)
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

-- =========================================================
-- SPEED HACK / WALKSPEED / JUMPPOWER
-- =========================================================
local function applyMovement()
    local char = getCharacter(LocalPlayer)
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    if State.SpeedHack then
        humanoid.WalkSpeed = State.SpeedValue
    else
        humanoid.WalkSpeed = State.WalkSpeed
    end
    humanoid.JumpPower = State.JumpPower
end

-- =========================================================
-- FOG / FULLBRIGHT
-- =========================================================
local function applyFog()
    local lighting = game:GetService("Lighting")
    if State.NoFog then
        lighting.FogEnd = 100000
        lighting.FogStart = 100000
    end
    if State.Fullbright then
        lighting.Brightness = 5
        lighting.ClockTime = 14
        lighting.Ambient = Color3.fromRGB(255,255,255)
        lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
    end
end

-- =========================================================
-- HITBOX EXPAND
-- =========================================================
local function applyHitbox()
    if not State.HitboxExpand then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = getCharacter(player)
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    root.Size = Vector3.new(State.HitboxSize, State.HitboxSize, State.HitboxSize)
                end
            end
        end
    end
end

-- =========================================================
-- FOV CIRCLE
-- =========================================================
local function updateFOVCircle()
    if not FOVCircleDrawing then
        FOVCircleDrawing = Drawing.new("Circle")
        FOVCircleDrawing.Filled = false
        FOVCircleDrawing.Thickness = 1.5
        FOVCircleDrawing.Color = Color3.fromRGB(255, 255, 255)
        FOVCircleDrawing.NumSides = 64
    end
    if State.FOVCircle then
        FOVCircleDrawing.Position = Camera.ViewportSize / 2
        FOVCircleDrawing.Radius = State.FOVSize
        FOVCircleDrawing.Visible = true
    else
        FOVCircleDrawing.Visible = false
    end
end

-- =========================================================
-- SILENT AIM
-- =========================================================
local function getSilentAimTarget()
    if not State.SilentAim then return nil end
    local closestPlayer = nil
    local closestDist = State.FOVSize
    
    local center = Camera.ViewportSize / 2
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isAlive(p) then
            local head = p.Character and p.Character:FindFirstChild("Head")
            if head then
                local screenPos, onScreen = worldToViewport(head.Position)
                if onScreen then
                    local dist = (screenPos - center).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestPlayer = p
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- =========================================================
-- ANTI-RAGDOLL
-- =========================================================
local function applyAntiRagdoll()
    if not State.AntiRagdoll then return end
    local char = getCharacter(LocalPlayer)
    if not char then return end
    for _, v in pairs(char:GetDescendants()) do
        if v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint") then
            v.Enabled = false
        end
    end
end

-- =========================================================
-- ROLE DETECTION (local player)
-- =========================================================
local function detectLocalRole()
    local role = "None"
    local char = getCharacter(LocalPlayer)
    if char then
        -- Check for knife
        for _, tool in pairs(char:GetChildren()) do
            if tool:IsA("Tool") and (tool:FindFirstChild("KnifeClient") or tool.Name:lower():find("knife")) then
                role = "Assassino/Murderer"
                break
            end
            if tool:IsA("Tool") and (tool:FindFirstChild("GunLocal") or tool.Name:lower():find("gun")) then
                role = "Sheriff"
                break
            end
        end
        if role == "None" then
            for _, tool in pairs(LocalPlayer.Backpack:GetChildren()) do
                if tool:IsA("Tool") and (tool:FindFirstChild("KnifeClient") or tool.Name:lower():find("knife")) then
                    role = "Assassino/Murderer"
                    break
                end
                if tool:IsA("Tool") and (tool:FindFirstChild("GunLocal") or tool.Name:lower():find("gun")) then
                    role = "Sheriff"
                    break
                end
            end
        end
        if role == "None" then role = "Inocente/Innocent" end
    end
    State.CurrentRole = role
end

-- =========================================================
-- MAIN LOOP
-- =========================================================
RunService.RenderStepped:Connect(function()
    updateESP()
    updateFOVCircle()
    applyFog()
    applyMovement()
    applyHitbox()
    applyAntiRagdoll()
    detectLocalRole()
end)

-- Slower tasks
local slowTimer = 0
RunService.Heartbeat:Connect(function(dt)
    slowTimer = slowTimer + dt
    if slowTimer >= 0.1 then
        slowTimer = 0
        doShotMurder()
        doAutoKnife()
        doAutoCollectCoins()
    end
end)

-- =========================================================
--
--  GUI SYSTEM
--
-- =========================================================

-- Remove existing GUI
local existingGui = PlayerGui:FindFirstChild("MYT_GUI")
if existingGui then existingGui:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "MYT_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = PlayerGui

-- =========================================================
-- SAVED LANGUAGE (persiste entre execuções via _G)
-- =========================================================
if _G.MYT_LANG then
    LANG = _G.MYT_LANG
end

-- Forward declaration do MainGui (será criado após LangScreen)
local MainGui

-- =========================================================
-- LANGUAGE SELECTION SCREEN
-- =========================================================
local LangScreen = Instance.new("Frame")
LangScreen.Name = "LangScreen"
LangScreen.Size = UDim2.new(0, 320, 0, 260)
LangScreen.Position = UDim2.new(0.5, -160, 0.5, -130)
LangScreen.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
LangScreen.BorderSizePixel = 0
LangScreen.ZIndex = 100
LangScreen.Parent = ScreenGui

do
    local corner = Instance.new("UICorner", LangScreen)
    corner.CornerRadius = UDim.new(0, 12)
    
    local stroke = Instance.new("UIStroke", LangScreen)
    stroke.Color = Color3.fromRGB(100, 80, 200)
    stroke.Thickness = 2
    
    -- Gradient background
    local grad = Instance.new("UIGradient", LangScreen)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 8, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 20, 40)),
    })
    grad.Rotation = 135
    
    -- Title
    local titleLbl = Instance.new("TextLabel", LangScreen)
    titleLbl.Size = UDim2.new(1, 0, 0, 50)
    titleLbl.Position = UDim2.new(0, 0, 0, 0)
    titleLbl.BackgroundTransparency = 1
    titleLbl.Text = "MYT"
    titleLbl.TextColor3 = Color3.fromRGB(180, 130, 255)
    titleLbl.TextSize = 32
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.ZIndex = 101
    
    local subLbl = Instance.new("TextLabel", LangScreen)
    subLbl.Size = UDim2.new(1, 0, 0, 25)
    subLbl.Position = UDim2.new(0, 0, 0, 40)
    subLbl.BackgroundTransparency = 1
    subLbl.Text = "Selecione o Idioma / Select Language / Seleccionar Idioma"
    subLbl.TextColor3 = Color3.fromRGB(150, 150, 200)
    subLbl.TextSize = 10
    subLbl.Font = Enum.Font.Gotham
    subLbl.ZIndex = 101
    
    local function makeLangBtn(text, lang, yPos, colorFrom, colorTo)
        local btn = Instance.new("TextButton", LangScreen)
        btn.Size = UDim2.new(0.8, 0, 0, 48)
        btn.Position = UDim2.new(0.1, 0, 0, yPos)
        btn.BackgroundColor3 = colorFrom
        btn.Text = text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 15
        btn.Font = Enum.Font.GothamSemibold
        btn.ZIndex = 101
        btn.AutoButtonColor = false
        
        local btnCorner = Instance.new("UICorner", btn)
        btnCorner.CornerRadius = UDim.new(0, 8)
        
        local btnGrad = Instance.new("UIGradient", btn)
        btnGrad.Color = ColorSequence.new(colorFrom, colorTo)
        btnGrad.Rotation = 90
        
        local icon = Instance.new("TextLabel", btn)
        icon.Size = UDim2.new(0.15, 0, 1, 0)
        icon.BackgroundTransparency = 1
        icon.Text = "🌐"
        icon.TextSize = 20
        icon.ZIndex = 102
        
        btn.MouseEnter:Connect(function()
            tween(btn, {BackgroundTransparency = 0.2}, 0.15)
        end)
        btn.MouseLeave:Connect(function()
            tween(btn, {BackgroundTransparency = 0}, 0.15)
        end)
        
        btn.MouseButton1Click:Connect(function()
            LANG = lang
            _G.MYT_LANG = lang
            LangScreen.Visible = false
            local gui = PlayerGui:FindFirstChild("MYT_GUI")
            local mg = gui and gui:FindFirstChild("MainGui")
            if mg then
                mg.Visible = true
                mg.Position = UDim2.new(0.5, -230, 2, 0)
                tween(mg, {Position = State.GuiPosition}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
            end
        end)
        
        return btn
    end
    
    makeLangBtn("🇧🇷  Português (BR)", "PT", 75, Color3.fromRGB(0, 130, 50), Color3.fromRGB(0, 180, 80))
    makeLangBtn("🇺🇸  English", "EN", 135, Color3.fromRGB(30, 80, 180), Color3.fromRGB(50, 130, 220))
    makeLangBtn("🇪🇸  Español", "ES", 195, Color3.fromRGB(180, 30, 30), Color3.fromRGB(220, 60, 60))
end

-- =========================================================
-- MAIN GUI
-- =========================================================
MainGui = Instance.new("Frame")
MainGui.Name = "MainGui"
MainGui.Size = UDim2.new(0, 460, 0, 420)
MainGui.Position = UDim2.new(0.5, -230, 2, 0) -- starts off screen
MainGui.BackgroundColor3 = Color3.fromRGB(8, 8, 18)
MainGui.BorderSizePixel = 0
MainGui.Visible = false
MainGui.ZIndex = 10
MainGui.Active = true
MainGui.Parent = ScreenGui

do
    local corner = Instance.new("UICorner", MainGui)
    corner.CornerRadius = UDim.new(0, 14)
    
    local stroke = Instance.new("UIStroke", MainGui)
    stroke.Color = Color3.fromRGB(120, 80, 220)
    stroke.Thickness = 1.5
    
    local grad = Instance.new("UIGradient", MainGui)
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(10, 6, 28)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 14, 32)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(6, 20, 36)),
    })
    grad.Rotation = 135
end

-- =========================================================
-- TITLE BAR (draggable)
-- =========================================================
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Size = UDim2.new(1, 0, 0, 44)
TitleBar.BackgroundColor3 = Color3.fromRGB(14, 10, 38)
TitleBar.BorderSizePixel = 0
TitleBar.ZIndex = 11
TitleBar.Parent = MainGui

do
    local corner = Instance.new("UICorner", TitleBar)
    corner.CornerRadius = UDim.new(0, 14)
    
    local grad = Instance.new("UIGradient", TitleBar)
    grad.Color = ColorSequence.new(
        Color3.fromRGB(80, 40, 180),
        Color3.fromRGB(20, 60, 160)
    )
    grad.Rotation = 90
    
    -- Title text
    local titleText = Instance.new("TextLabel", TitleBar)
    titleText.Size = UDim2.new(0, 100, 1, 0)
    titleText.Position = UDim2.new(0, 12, 0, 0)
    titleText.BackgroundTransparency = 1
    titleText.Text = "MYT"
    titleText.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleText.TextSize = 20
    titleText.Font = Enum.Font.GothamBold
    titleText.TextXAlignment = Enum.TextXAlignment.Left
    titleText.ZIndex = 12
    
    -- Credits
    local creditsText = Instance.new("TextLabel", TitleBar)
    creditsText.Size = UDim2.new(0, 200, 1, 0)
    creditsText.Position = UDim2.new(0, 55, 0, 0)
    creditsText.BackgroundTransparency = 1
    creditsText.Text = "by tolopo637883"
    creditsText.TextColor3 = Color3.fromRGB(180, 140, 255)
    creditsText.TextSize = 11
    creditsText.Font = Enum.Font.Gotham
    creditsText.TextXAlignment = Enum.TextXAlignment.Left
    creditsText.ZIndex = 12
    
    -- Role badge
    local roleBadge = Instance.new("TextLabel", TitleBar)
    roleBadge.Name = "RoleBadge"
    roleBadge.Size = UDim2.new(0, 140, 0, 24)
    roleBadge.Position = UDim2.new(0.5, -70, 0.5, -12)
    roleBadge.BackgroundColor3 = Color3.fromRGB(30, 30, 60)
    roleBadge.Text = "Role: None"
    roleBadge.TextColor3 = Color3.fromRGB(200, 200, 255)
    roleBadge.TextSize = 11
    roleBadge.Font = Enum.Font.GothamSemibold
    roleBadge.ZIndex = 12
    
    local rbCorner = Instance.new("UICorner", roleBadge)
    rbCorner.CornerRadius = UDim.new(0, 6)
    
    -- Update role badge every 2s
    task.spawn(function()
        while true do
            task.wait(1)
            detectLocalRole()
            local roleColors = {
                ["Assassino/Murderer"] = Color3.fromRGB(255, 80, 80),
                ["Sheriff"] = Color3.fromRGB(80, 160, 255),
                ["Inocente/Innocent"] = Color3.fromRGB(80, 220, 120),
                ["None"] = Color3.fromRGB(150, 150, 200),
            }
            roleBadge.Text = "Role: " .. State.CurrentRole:gsub("/.*", "")
            roleBadge.TextColor3 = roleColors[State.CurrentRole] or Color3.fromRGB(200, 200, 255)
        end
    end)
    
    -- Minimize / close button (slider-style)
    local MinimizeBtn = Instance.new("TextButton", TitleBar)
    MinimizeBtn.Name = "MinimizeBtn"
    MinimizeBtn.Size = UDim2.new(0, 76, 0, 26)
    MinimizeBtn.Position = UDim2.new(1, -84, 0.5, -13)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 200)
    MinimizeBtn.Text = "MYT ▼"
    MinimizeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    MinimizeBtn.TextSize = 12
    MinimizeBtn.Font = Enum.Font.GothamBold
    MinimizeBtn.ZIndex = 13
    MinimizeBtn.AutoButtonColor = false
    
    local minCorner = Instance.new("UICorner", MinimizeBtn)
    minCorner.CornerRadius = UDim.new(0, 6)
    
    MinimizeBtn.MouseEnter:Connect(function()
        tween(MinimizeBtn, {BackgroundColor3 = Color3.fromRGB(140, 80, 255)}, 0.15)
    end)
    MinimizeBtn.MouseLeave:Connect(function()
        tween(MinimizeBtn, {BackgroundColor3 = Color3.fromRGB(100, 60, 200)}, 0.15)
    end)
    
    -- Lock button
    local LockBtn = Instance.new("TextButton", TitleBar)
    LockBtn.Name = "LockBtn"
    LockBtn.Size = UDim2.new(0, 28, 0, 26)
    LockBtn.Position = UDim2.new(1, -30, 0.5, -13)
    LockBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
    LockBtn.Text = "🔓"
    LockBtn.TextSize = 14
    LockBtn.ZIndex = 13
    LockBtn.AutoButtonColor = false
    
    local lockCorner = Instance.new("UICorner", LockBtn)
    lockCorner.CornerRadius = UDim.new(0, 6)
    
    LockBtn.MouseButton1Click:Connect(function()
        State.GuiLocked = not State.GuiLocked
        LockBtn.Text = State.GuiLocked and "🔒" or "🔓"
        LockBtn.BackgroundColor3 = State.GuiLocked and Color3.fromRGB(200, 50, 50) or Color3.fromRGB(40, 40, 80)
    end)
end

-- =========================================================
-- MINI BUTTON (when minimized)
-- =========================================================
local MiniBtn = Instance.new("TextButton")
MiniBtn.Name = "MiniBtn"
MiniBtn.Size = UDim2.new(0, 60, 0, 60)
MiniBtn.Position = UDim2.new(0, 20, 0.5, -30)
MiniBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 180)
MiniBtn.Text = "MYT"
MiniBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
MiniBtn.TextSize = 14
MiniBtn.Font = Enum.Font.GothamBold
MiniBtn.Visible = false
MiniBtn.ZIndex = 50
MiniBtn.Active = true
MiniBtn.Parent = ScreenGui

do
    local mbCorner = Instance.new("UICorner", MiniBtn)
    mbCorner.CornerRadius = UDim.new(0, 10)
    
    local mbStroke = Instance.new("UIStroke", MiniBtn)
    mbStroke.Color = Color3.fromRGB(160, 100, 255)
    mbStroke.Thickness = 2
    
    local mbGrad = Instance.new("UIGradient", MiniBtn)
    mbGrad.Color = ColorSequence.new(
        Color3.fromRGB(120, 60, 220),
        Color3.fromRGB(40, 20, 120)
    )
    mbGrad.Rotation = 135
    
    -- Pulse animation
    task.spawn(function()
        while true do
            if MiniBtn.Visible then
                tween(MiniBtn, {BackgroundTransparency = 0.3}, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(0.8)
                tween(MiniBtn, {BackgroundTransparency = 0}, 0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                task.wait(0.8)
            else
                task.wait(0.5)
            end
        end
    end)
end

-- Draggable for MiniBtn
do
    local dragging = false
    local dragStart = nil
    local startPos = nil
    
    MiniBtn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = MiniBtn.Position
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            MiniBtn.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- =========================================================
-- MINIMIZE / MAXIMIZE LOGIC
-- =========================================================
local function minimizeGUI()
    State.IsMinimized = true
    -- Animate all content out
    tween(MainGui, {
        Size = UDim2.new(0, 460, 0, 0),
        Position = UDim2.new(
            MainGui.Position.X.Scale,
            MainGui.Position.X.Offset,
            MainGui.Position.Y.Scale,
            MainGui.Position.Y.Offset + 210
        )
    }, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In)
    task.delay(0.4, function()
        MainGui.Visible = false
        MiniBtn.Visible = true
        tween(MiniBtn, {Size = UDim2.new(0, 60, 0, 60)}, 0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    end)
end

local function maximizeGUI()
    State.IsMinimized = false
    MiniBtn.Visible = false
    MainGui.Visible = true
    MainGui.Size = UDim2.new(0, 460, 0, 0)
    tween(MainGui, {Size = UDim2.new(0, 460, 0, 420)}, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

local titleBar = MainGui:FindFirstChild("TitleBar")
if titleBar then
    local minBtn = titleBar:FindFirstChild("MinimizeBtn")
    if minBtn then
        minBtn.MouseButton1Click:Connect(minimizeGUI)
    end
end

MiniBtn.MouseButton1Click:Connect(maximizeGUI)

-- =========================================================
-- DRAG SYSTEM for MainGui
-- =========================================================
do
    local dragging = false
    local dragInput = nil
    local dragStart = nil
    local startPos = nil
    
    local titleBar = MainGui:FindFirstChild("TitleBar")
    if titleBar then
        titleBar.InputBegan:Connect(function(input)
            if State.GuiLocked then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = MainGui.Position
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                        State.GuiPosition = MainGui.Position
                    end
                end)
            end
        end)
        
        titleBar.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                dragInput = input
            end
        end)
    end
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and dragInput and input == dragInput then
            local delta = input.Position - dragStart
            MainGui.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- =========================================================
-- CONTENT AREA
-- =========================================================
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "ContentFrame"
ContentFrame.Size = UDim2.new(1, 0, 1, -44)
ContentFrame.Position = UDim2.new(0, 0, 0, 44)
ContentFrame.BackgroundTransparency = 1
ContentFrame.ZIndex = 11
ContentFrame.Parent = MainGui

-- TAB BAR
local TabBar = Instance.new("Frame")
TabBar.Name = "TabBar"
TabBar.Size = UDim2.new(1, -20, 0, 36)
TabBar.Position = UDim2.new(0, 10, 0, 6)
TabBar.BackgroundColor3 = Color3.fromRGB(14, 10, 32)
TabBar.BorderSizePixel = 0
TabBar.ZIndex = 12
TabBar.Parent = ContentFrame

local tabCorner = Instance.new("UICorner", TabBar)
tabCorner.CornerRadius = UDim.new(0, 8)

local tabLayout = Instance.new("UIListLayout", TabBar)
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
tabLayout.Padding = UDim.new(0, 4)

-- SCROLL AREA
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Name = "ScrollFrame"
ScrollFrame.Size = UDim2.new(1, -12, 1, -50)
ScrollFrame.Position = UDim2.new(0, 6, 0, 46)
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 4
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 60, 200)
ScrollFrame.ZIndex = 12
ScrollFrame.Parent = ContentFrame
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ScrollFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y

local scrollLayout = Instance.new("UIListLayout", ScrollFrame)
scrollLayout.Padding = UDim.new(0, 4)
scrollLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

local scrollPad = Instance.new("UIPadding", ScrollFrame)
scrollPad.PaddingTop = UDim.new(0, 4)
scrollPad.PaddingBottom = UDim.new(0, 8)

-- =========================================================
-- TAB SYSTEM
-- =========================================================
local tabs = {}
local tabPages = {}
local currentTab = nil

local function createTab(name, icon)
    local btn = Instance.new("TextButton", TabBar)
    btn.Size = UDim2.new(0, 120, 1, -6)
    btn.BackgroundColor3 = Color3.fromRGB(20, 14, 50)
    btn.Text = icon .. "  " .. name
    btn.TextColor3 = Color3.fromRGB(180, 180, 220)
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamSemibold
    btn.ZIndex = 13
    btn.AutoButtonColor = false
    
    local btnCorner = Instance.new("UICorner", btn)
    btnCorner.CornerRadius = UDim.new(0, 6)
    
    local page = Instance.new("Frame")
    page.Name = "Page_" .. name
    page.Size = UDim2.new(1, 0, 0, 0)
    page.BackgroundTransparency = 1
    page.AutomaticSize = Enum.AutomaticSize.Y
    page.Visible = false
    page.ZIndex = 12
    page.Parent = ScrollFrame
    
    local pageLayout = Instance.new("UIListLayout", page)
    pageLayout.Padding = UDim.new(0, 4)
    pageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    
    tabs[name] = btn
    tabPages[name] = page
    
    btn.MouseButton1Click:Connect(function()
        for tName, tBtn in pairs(tabs) do
            tween(tBtn, {BackgroundColor3 = Color3.fromRGB(20, 14, 50)}, 0.15)
            tBtn.TextColor3 = Color3.fromRGB(180, 180, 220)
            tabPages[tName].Visible = false
        end
        tween(btn, {BackgroundColor3 = Color3.fromRGB(90, 50, 180)}, 0.2)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        page.Visible = true
        currentTab = name
    end)
    
    return btn, page
end

-- Create tabs
local espTab, espPage = createTab("ESP", "👁")
local combatTab, combatPage = createTab("Combate", "⚔")
local miscTab, miscPage = createTab("Misc", "⚙")

-- =========================================================
-- WIDGET BUILDERS
-- =========================================================
local function createToggle(parent, labelKey, stateKey, color, hotKey)
    color = color or Color3.fromRGB(90, 50, 180)
    
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(0.96, 0, 0, 40)
    container.BackgroundColor3 = Color3.fromRGB(16, 12, 36)
    container.BorderSizePixel = 0
    container.ZIndex = 13
    
    local cCorner = Instance.new("UICorner", container)
    cCorner.CornerRadius = UDim.new(0, 8)
    
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1, -60, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = tr(labelKey)
    label.TextColor3 = Color3.fromRGB(200, 200, 240)
    label.TextSize = 13
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.ZIndex = 14
    
    if hotKey then
        local hkLabel = Instance.new("TextLabel", container)
        hkLabel.Size = UDim2.new(0, 30, 1, 0)
        hkLabel.Position = UDim2.new(0, label.Position.X.Offset + 200, 0, 0)
        hkLabel.BackgroundColor3 = Color3.fromRGB(30, 20, 60)
        hkLabel.Text = hotKey
        hkLabel.TextColor3 = Color3.fromRGB(150, 120, 200)
        hkLabel.TextSize = 9
        hkLabel.Font = Enum.Font.Code
        hkLabel.ZIndex = 14
        local hkCorner = Instance.new("UICorner", hkLabel)
        hkCorner.CornerRadius = UDim.new(0, 4)
    end
    
    -- Toggle switch
    local switchBg = Instance.new("Frame", container)
    switchBg.Size = UDim2.new(0, 44, 0, 22)
    switchBg.Position = UDim2.new(1, -54, 0.5, -11)
    switchBg.BackgroundColor3 = Color3.fromRGB(30, 24, 60)
    switchBg.BorderSizePixel = 0
    switchBg.ZIndex = 14
    
    local switchCorner = Instance.new("UICorner", switchBg)
    switchCorner.CornerRadius = UDim.new(0, 11)
    
    local switchKnob = Instance.new("Frame", switchBg)
    switchKnob.Size = UDim2.new(0, 18, 0, 18)
    switchKnob.Position = State[stateKey] and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
    switchKnob.BackgroundColor3 = State[stateKey] and color or Color3.fromRGB(80, 80, 100)
    switchKnob.BorderSizePixel = 0
    switchKnob.ZIndex = 15
    
    local knobCorner = Instance.new("UICorner", switchKnob)
    knobCorner.CornerRadius = UDim.new(0, 9)
    
    if State[stateKey] then
        tween(switchBg, {BackgroundColor3 = Color3.fromRGB(
            math.floor(color.R * 80),
            math.floor(color.G * 80),
            math.floor(color.B * 80)
        )}, 0)
    end
    
    local clickBtn = Instance.new("TextButton", container)
    clickBtn.Size = UDim2.new(1, 0, 1, 0)
    clickBtn.BackgroundTransparency = 1
    clickBtn.Text = ""
    clickBtn.ZIndex = 16
    clickBtn.AutoButtonColor = false
    
    clickBtn.MouseButton1Click:Connect(function()
        State[stateKey] = not State[stateKey]
        local isOn = State[stateKey]
        tween(switchKnob, {
            Position = isOn and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9),
            BackgroundColor3 = isOn and color or Color3.fromRGB(80, 80, 100)
        }, 0.2, Enum.EasingStyle.Back)
        tween(switchBg, {
            BackgroundColor3 = isOn 
                and Color3.fromRGB(math.floor(color.R*255*0.3), math.floor(color.G*255*0.3), math.floor(color.B*255*0.3))
                or Color3.fromRGB(30, 24, 60)
        }, 0.2)
    end)
    
    clickBtn.MouseEnter:Connect(function()
        tween(container, {BackgroundColor3 = Color3.fromRGB(22, 16, 48)}, 0.1)
    end)
    clickBtn.MouseLeave:Connect(function()
        tween(container, {BackgroundColor3 = Color3.fromRGB(16, 12, 36)}, 0.1)
    end)
    
    return container
end

local function createSlider(parent, labelKey, stateKey, minVal, maxVal, suffix)
    suffix = suffix or ""
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(0.96, 0, 0, 56)
    container.BackgroundColor3 = Color3.fromRGB(16, 12, 36)
    container.BorderSizePixel = 0
    container.ZIndex = 13
    
    local cCorner = Instance.new("UICorner", container)
    cCorner.CornerRadius = UDim.new(0, 8)
    
    local labelText = Instance.new("TextLabel", container)
    labelText.Size = UDim2.new(0.6, 0, 0, 22)
    labelText.Position = UDim2.new(0, 12, 0, 4)
    labelText.BackgroundTransparency = 1
    labelText.Text = tr(labelKey)
    labelText.TextColor3 = Color3.fromRGB(200, 200, 240)
    labelText.TextSize = 12
    labelText.Font = Enum.Font.Gotham
    labelText.TextXAlignment = Enum.TextXAlignment.Left
    labelText.ZIndex = 14
    
    local valueText = Instance.new("TextLabel", container)
    valueText.Size = UDim2.new(0.35, 0, 0, 22)
    valueText.Position = UDim2.new(0.65, -12, 0, 4)
    valueText.BackgroundTransparency = 1
    valueText.Text = tostring(State[stateKey]) .. suffix
    valueText.TextColor3 = Color3.fromRGB(140, 100, 255)
    valueText.TextSize = 12
    valueText.Font = Enum.Font.GothamBold
    valueText.TextXAlignment = Enum.TextXAlignment.Right
    valueText.ZIndex = 14
    
    local sliderBg = Instance.new("Frame", container)
    sliderBg.Size = UDim2.new(1, -24, 0, 8)
    sliderBg.Position = UDim2.new(0, 12, 0, 34)
    sliderBg.BackgroundColor3 = Color3.fromRGB(30, 22, 60)
    sliderBg.BorderSizePixel = 0
    sliderBg.ZIndex = 14
    
    local sliderBgCorner = Instance.new("UICorner", sliderBg)
    sliderBgCorner.CornerRadius = UDim.new(0, 4)
    
    local pct = (State[stateKey] - minVal) / (maxVal - minVal)
    
    local sliderFill = Instance.new("Frame", sliderBg)
    sliderFill.Size = UDim2.new(pct, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(120, 60, 220)
    sliderFill.BorderSizePixel = 0
    sliderFill.ZIndex = 15
    
    local fillCorner = Instance.new("UICorner", sliderFill)
    fillCorner.CornerRadius = UDim.new(0, 4)
    
    local fillGrad = Instance.new("UIGradient", sliderFill)
    fillGrad.Color = ColorSequence.new(
        Color3.fromRGB(160, 80, 255),
        Color3.fromRGB(80, 40, 180)
    )
    fillGrad.Rotation = 90
    
    local knob = Instance.new("Frame", sliderBg)
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.Position = UDim2.new(pct, -7, 0.5, -7)
    knob.BackgroundColor3 = Color3.fromRGB(200, 150, 255)
    knob.ZIndex = 16
    
    local knobCorner = Instance.new("UICorner", knob)
    knobCorner.CornerRadius = UDim.new(0, 7)
    
    local isDragging = false
    
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = true
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            isDragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relX = input.Position.X - sliderBg.AbsolutePosition.X
            local fraction = math.clamp(relX / sliderBg.AbsoluteSize.X, 0, 1)
            local value = math.floor(minVal + (maxVal - minVal) * fraction)
            State[stateKey] = value
            valueText.Text = tostring(value) .. suffix
            sliderFill.Size = UDim2.new(fraction, 0, 1, 0)
            knob.Position = UDim2.new(fraction, -7, 0.5, -7)
        end
    end)
    
    return container
end

local function createSection(parent, title)
    local section = Instance.new("Frame", parent)
    section.Size = UDim2.new(0.96, 0, 0, 26)
    section.BackgroundTransparency = 1
    section.ZIndex = 13
    
    local line = Instance.new("Frame", section)
    line.Size = UDim2.new(0.35, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = Color3.fromRGB(60, 40, 120)
    line.BorderSizePixel = 0
    line.ZIndex = 14
    
    local line2 = Instance.new("Frame", section)
    line2.Size = UDim2.new(0.35, 0, 0, 1)
    line2.Position = UDim2.new(0.65, 0, 0.5, 0)
    line2.BackgroundColor3 = Color3.fromRGB(60, 40, 120)
    line2.BorderSizePixel = 0
    line2.ZIndex = 14
    
    local lbl = Instance.new("TextLabel", section)
    lbl.Size = UDim2.new(0.3, 0, 1, 0)
    lbl.Position = UDim2.new(0.35, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.TextColor3 = Color3.fromRGB(140, 100, 220)
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.ZIndex = 14
    
    return section
end

-- =========================================================
-- BUILD ESP PAGE
-- =========================================================
do
    createSection(espPage, "── Roles ──")
    createToggle(espPage, "esp_murderer", "ESP_Murderer", Color3.fromRGB(255, 60, 60))
    createToggle(espPage, "esp_sheriff", "ESP_Sheriff", Color3.fromRGB(60, 160, 255))
    createToggle(espPage, "esp_innocent", "ESP_Innocent", Color3.fromRGB(60, 220, 120))
    createToggle(espPage, "ghost_esp", "ESP_Ghosts", Color3.fromRGB(200, 180, 255))
    
    createSection(espPage, "── Visual ──")
    createToggle(espPage, "esp_boxes", "ESP_Boxes", Color3.fromRGB(120, 80, 220))
    createToggle(espPage, "esp_names", "ESP_Names", Color3.fromRGB(120, 80, 220))
    createToggle(espPage, "esp_distance", "ESP_Distance", Color3.fromRGB(120, 80, 220))
    createToggle(espPage, "esp_health", "ESP_Health", Color3.fromRGB(80, 220, 80))
    createToggle(espPage, "esp_tracers", "ESP_Tracers", Color3.fromRGB(220, 160, 60))
    createToggle(espPage, "esp_chams", "ESP_Chams", Color3.fromRGB(220, 100, 60))
    
    createSection(espPage, "── Itens ──")
    createToggle(espPage, "esp_coins", "ESP_Coins", Color3.fromRGB(255, 200, 0))
    createToggle(espPage, "esp_guns", "ESP_Guns", Color3.fromRGB(255, 120, 0))
end

-- =========================================================
-- BUILD COMBAT PAGE
-- =========================================================
do
    createSection(combatPage, "── Assassino ──")
    createToggle(combatPage, "shot_murder", "ShotMurder", Color3.fromRGB(255, 60, 60))
    createToggle(combatPage, "auto_knife", "AutoKnife", Color3.fromRGB(255, 80, 80))
    createSlider(combatPage, "reach", "KnifeReach", 5, 50, "m")
    
    createSection(combatPage, "── Mira ──")
    createToggle(combatPage, "silent_aim", "SilentAim", Color3.fromRGB(255, 160, 0))
    createToggle(combatPage, "fov_circle", "FOVCircle", Color3.fromRGB(200, 200, 255))
    createSlider(combatPage, "fov_size", "FOVSize", 20, 400, "px")
    createToggle(combatPage, "hitbox_exp", "HitboxExpand", Color3.fromRGB(255, 100, 0))
    createSlider(combatPage, "hitbox_size", "HitboxSize", 2, 20, "u")
    
    createSection(combatPage, "── Movimento ──")
    createToggle(combatPage, "double_jump", "DoubleJump", Color3.fromRGB(100, 220, 255))
    createToggle(combatPage, "infinite_jump", "InfiniteJump", Color3.fromRGB(80, 200, 255))
    createToggle(combatPage, "noclip", "Noclip", Color3.fromRGB(255, 180, 0))
    createToggle(combatPage, "speed_hack", "SpeedHack", Color3.fromRGB(100, 255, 160))
    createSlider(combatPage, "speed_value", "SpeedValue", 4, 100, " ws")
    createSlider(combatPage, "walkspeed", "WalkSpeed", 8, 50, " ws")
    createSlider(combatPage, "jump_power", "JumpPower", 20, 150, " jp")
end

-- =========================================================
-- BUILD MISC PAGE
-- =========================================================
do
    createSection(miscPage, "── Visual ──")
    createToggle(miscPage, "no_fog", "NoFog", Color3.fromRGB(180, 220, 255))
    createToggle(miscPage, "fullbright", "Fullbright", Color3.fromRGB(255, 240, 100))
    createToggle(miscPage, "fps_boost", "FPSBoost", Color3.fromRGB(100, 255, 100))
    createToggle(miscPage, "anti_ragdoll", "AntiRagdoll", Color3.fromRGB(255, 120, 60))
    
    createSection(miscPage, "── Gameplay ──")
    createToggle(miscPage, "auto_collect_coins", "AutoCollectCoins", Color3.fromRGB(255, 200, 0))
    createToggle(miscPage, "show_roles", "ShowRoles", Color3.fromRGB(180, 140, 255))
    
    createSection(miscPage, "── GUI ──")
    
    -- Transparent toggle (special)
    local transContainer = Instance.new("Frame", miscPage)
    transContainer.Size = UDim2.new(0.96, 0, 0, 40)
    transContainer.BackgroundColor3 = Color3.fromRGB(16, 12, 36)
    transContainer.BorderSizePixel = 0
    transContainer.ZIndex = 13
    local transCorner = Instance.new("UICorner", transContainer)
    transCorner.CornerRadius = UDim.new(0, 8)
    
    local transLabel = Instance.new("TextLabel", transContainer)
    transLabel.Size = UDim2.new(0.6, 0, 1, 0)
    transLabel.Position = UDim2.new(0, 12, 0, 0)
    transLabel.BackgroundTransparency = 1
    transLabel.Text = tr("transparent")
    transLabel.TextColor3 = Color3.fromRGB(200, 200, 240)
    transLabel.TextSize = 13
    transLabel.Font = Enum.Font.Gotham
    transLabel.TextXAlignment = Enum.TextXAlignment.Left
    transLabel.ZIndex = 14
    
    local transBtn = Instance.new("TextButton", transContainer)
    transBtn.Size = UDim2.new(0, 80, 0, 26)
    transBtn.Position = UDim2.new(1, -90, 0.5, -13)
    transBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 80)
    transBtn.Text = "OFF"
    transBtn.TextColor3 = Color3.fromRGB(200, 160, 255)
    transBtn.TextSize = 12
    transBtn.Font = Enum.Font.GothamBold
    transBtn.ZIndex = 14
    
    local transBtnCorner = Instance.new("UICorner", transBtn)
    transBtnCorner.CornerRadius = UDim.new(0, 6)
    
    transBtn.MouseButton1Click:Connect(function()
        State.GuiTransparent = not State.GuiTransparent
        if State.GuiTransparent then
            tween(MainGui, {BackgroundTransparency = 0.6}, 0.3)
            tween(TitleBar, {BackgroundTransparency = 0.6}, 0.3)
            transBtn.Text = "ON"
            transBtn.BackgroundColor3 = Color3.fromRGB(80, 50, 160)
        else
            tween(MainGui, {BackgroundTransparency = 0}, 0.3)
            tween(TitleBar, {BackgroundTransparency = 0}, 0.3)
            transBtn.Text = "OFF"
            transBtn.BackgroundColor3 = Color3.fromRGB(40, 30, 80)
        end
    end)
    
    -- Credits bottom
    local credFrame = Instance.new("Frame", miscPage)
    credFrame.Size = UDim2.new(0.96, 0, 0, 50)
    credFrame.BackgroundColor3 = Color3.fromRGB(12, 8, 30)
    credFrame.BorderSizePixel = 0
    credFrame.ZIndex = 13
    local credCorner = Instance.new("UICorner", credFrame)
    credCorner.CornerRadius = UDim.new(0, 8)
    
    local credGrad = Instance.new("UIGradient", credFrame)
    credGrad.Color = ColorSequence.new(
        Color3.fromRGB(40, 20, 100),
        Color3.fromRGB(10, 8, 30)
    )
    credGrad.Rotation = 90
    
    local credText = Instance.new("TextLabel", credFrame)
    credText.Size = UDim2.new(1, 0, 1, 0)
    credText.BackgroundTransparency = 1
    credText.Text = "MYT Script\nby tolopo637883"
    credText.TextColor3 = Color3.fromRGB(180, 140, 255)
    credText.TextSize = 13
    credText.Font = Enum.Font.GothamBold
    credText.ZIndex = 14
    
    -- Animate credits color
    task.spawn(function()
        local hue = 0
        while true do
            task.wait(0.05)
            hue = (hue + 1) % 360
            credText.TextColor3 = Color3.fromHSV(hue/360, 0.6, 1)
        end
    end)
end

-- =========================================================
-- FPS BOOST
-- =========================================================
task.spawn(function()
    while true do
        task.wait(1)
        if State.FPSBoost then
            local lighting = game:GetService("Lighting")
            lighting.GlobalShadows = false
            for _, v in pairs(Workspace:GetDescendants()) do
                if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                    v.Enabled = false
                end
            end
        end
    end
end)

-- =========================================================
-- COIN ESP (part of the ESP loop)
-- =========================================================
local coinDrawings = {}

RunService.RenderStepped:Connect(function()
    -- Clear old coin drawings
    for k, d in pairs(coinDrawings) do
        if not d.obj or not d.obj.Parent then
            d.label:Remove()
            coinDrawings[k] = nil
        end
    end
    
    if not State.ESP_Coins then
        for _, d in pairs(coinDrawings) do
            d.label.Visible = false
        end
        return
    end
    
    for _, obj in pairs(Workspace:GetDescendants()) do
        if (obj:IsA("Part") or obj:IsA("MeshPart")) and (obj.Name:lower():find("coin") or obj.Name:lower():find("bag")) then
            local pos, onScreen, z = worldToViewport(obj.Position)
            if onScreen and z > 0 then
                local key = obj:GetFullName()
                if not coinDrawings[key] then
                    local lbl = Drawing.new("Text")
                    lbl.Size = 12
                    lbl.Center = true
                    lbl.Outline = true
                    lbl.Color = Color3.fromRGB(255, 200, 0)
                    coinDrawings[key] = {label = lbl, obj = obj}
                end
                coinDrawings[key].label.Text = "💰"
                coinDrawings[key].label.Position = pos
                coinDrawings[key].label.Visible = true
            elseif coinDrawings[obj:GetFullName()] then
                coinDrawings[obj:GetFullName()].label.Visible = false
            end
        end
    end
end)

-- =========================================================
-- KEYBINDS
-- =========================================================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        if State.IsMinimized then
            maximizeGUI()
        else
            minimizeGUI()
        end
    end
    if input.KeyCode == Enum.KeyCode.Delete then
        State.ShotMurder = not State.ShotMurder
    end
    if input.KeyCode == Enum.KeyCode.End then
        State.AutoKnife = not State.AutoKnife
    end
end)

-- =========================================================
-- AUTO-SELECT FIRST TAB
-- =========================================================
espTab:activate()
do
    for tName, tBtn in pairs(tabs) do
        tabPages[tName].Visible = false
    end
    tween(espTab, {BackgroundColor3 = Color3.fromRGB(90, 50, 180)}, 0.2)
    espTab.TextColor3 = Color3.fromRGB(255, 255, 255)
    espPage.Visible = true
    currentTab = "ESP"
end

-- =========================================================
-- ANIMATE LANGUAGE SCREEN IN (ou pula se já tem idioma salvo)
-- =========================================================
if _G.MYT_LANG then
    -- Idioma já salvo, pula a tela de seleção
    LangScreen.Visible = false
    MainGui.Visible = true
    MainGui.Position = UDim2.new(0.5, -230, 2, 0)
    tween(MainGui, {Position = State.GuiPosition}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
else
    LangScreen.Position = UDim2.new(0.5, -160, 2, 0)
    LangScreen.Visible = true
    tween(LangScreen, {Position = UDim2.new(0.5, -160, 0.5, -130)}, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- =========================================================
-- CHAMS (solid color through walls)
-- =========================================================
RunService.RenderStepped:Connect(function()
    if not State.ESP_Chams then return end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            if not char then continue end
            local role = getRole(player)
            local chamColor = ROLE_COLORS[role] or ROLE_COLORS.Unknown
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Material = Enum.Material.Neon
                    part.Color = chamColor
                    part.CastShadow = false
                end
            end
        end
    end
end)

-- =========================================================
-- SHOW ROLES ABOVE HEADS (BillboardGui style via Drawing)
-- =========================================================
local roleLabels = {}

RunService.RenderStepped:Connect(function()
    if not State.ShowRoles then
        for _, d in pairs(roleLabels) do d.Visible = false end
        return
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        if not head then continue end
        
        local role = getRole(player)
        local color = ROLE_COLORS[role] or ROLE_COLORS.Unknown
        local pos, onScreen, z = worldToViewport(head.Position + Vector3.new(0, 2.5, 0))
        
        if not roleLabels[player] then
            local d = Drawing.new("Text")
            d.Size = 13
            d.Center = true
            d.Outline = true
            d.Font = 2
            roleLabels[player] = d
        end
        
        if onScreen and z > 0 then
            roleLabels[player].Text = "[ " .. role .. " ]"
            roleLabels[player].Color = color
            roleLabels[player].Position = pos
            roleLabels[player].Visible = true
        else
            roleLabels[player].Visible = false
        end
    end
end)

Players.PlayerRemoving:Connect(function(p)
    if roleLabels[p] then
        roleLabels[p]:Remove()
        roleLabels[p] = nil
    end
end)

print("[MYT] Script carregado com sucesso! by tolopo637883")
print("[MYT] INSERT = Abrir/Fechar GUI")
print("[MYT] DELETE = Toggle Shot Murder")
print("[MYT] END = Toggle Auto Knife")
