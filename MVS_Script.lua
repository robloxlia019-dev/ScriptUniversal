-- ============================================================
--  MURDERER VS SHERIFF — Script by MYT
--  Rayfield UI | Cheats, ESP, Auto, QoL
-- ============================================================

-- Load Rayfield
local success, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not success then
    warn("[MVS] Falha ao carregar Rayfield:", Rayfield)
    return
end

-- ============================================================
-- SERVICES & GLOBALS
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP       = Players.LocalPlayer
local LPChar   = LP.Character or LP.CharacterAdded:Wait()
local Camera   = workspace.CurrentCamera

-- ============================================================
-- STATE
-- ============================================================
local State = {
    -- ESP
    espEnabled    = false,
    espBoxes      = true,
    espNames      = true,
    espDist       = true,
    espMaxDist    = 1000,

    -- Auto
    autoKnife     = false,
    autoShoot     = false,
    autoKnifeDelay= 0.1,
    autoShootDelay= 0.15,
    silentAim     = false,

    -- Movement
    speedEnabled  = false,
    speedValue    = 25,
    jumpEnabled   = false,
    jumpValue     = 80,
    flyEnabled    = false,
    flySpeed      = 50,
    noclip        = false,

    -- Visual
    fullbright    = false,
    fovValue      = 70,
    alwaysDay     = false,

    -- QoL
    antiAfk       = true,
    autoVote      = false,
    spamMsg       = false,
    spamText      = "gg",

    -- Role tracking
    myRole        = "Unknown",
}

-- Drawing objects table
local Drawings = {}
local FlyCon = nil
local FlyBP = nil
local FlyGyr = nil

-- ============================================================
-- HELPERS
-- ============================================================
local function getChar(player)
    return player and player.Character
end

local function getRootPart(player)
    local char = getChar(player)
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getMyRoot()
    local char = LP.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function worldToViewport(pos)
    local screenPos, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(screenPos.X, screenPos.Y), screenPos.Z, onScreen
end

local function getMagnitude(a, b)
    return (a - b).Magnitude
end

local function detectRole()
    local char = LP.Character
    local bp = LP:FindFirstChild("Backpack")
    local function checkTools(parent)
        if not parent then return nil end
        for _, tool in ipairs(parent:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("revolver") or n:find("gun") or n:find("pistol") then return "Sheriff" end
                if n:find("knife") or n:find("blade") then return "Murderer" end
            end
        end
        return nil
    end
    local r = checkTools(char) or checkTools(bp)
    State.myRole = r or "Innocent"
    return State.myRole
end

local function getPlayerRole(player)
    local char = getChar(player)
    local bp = player:FindFirstChild("Backpack")
    local function checkTools(parent)
        if not parent then return nil end
        for _, tool in ipairs(parent:GetChildren()) do
            if tool:IsA("Tool") then
                local n = tool.Name:lower()
                if n:find("revolver") or n:find("gun") or n:find("pistol") then return "Sheriff" end
                if n:find("knife") or n:find("blade") then return "Murderer" end
            end
        end
        return nil
    end
    return checkTools(char) or checkTools(bp) or "Innocent"
end

local function roleColor(role)
    if role == "Murderer" then return Color3.fromRGB(255, 60, 60)
    elseif role == "Sheriff" then return Color3.fromRGB(60, 160, 255)
    else return Color3.fromRGB(100, 255, 100)
    end
end

-- ============================================================
-- ESP SYSTEM
-- ============================================================
local function newDrawing(drawType, props)
    local d = Drawing.new(drawType)
    for k, v in pairs(props) do d[k] = v end
    return d
end

local function removeESP(player)
    if Drawings[player] then
        for _, d in pairs(Drawings[player]) do
            pcall(function() d:Remove() end)
        end
        Drawings[player] = nil
    end
end

local function createESP(player)
    if player == LP then return end
    removeESP(player)
    Drawings[player] = {
        box  = newDrawing("Square", { Visible=false, Thickness=2, Filled=false, Color=Color3.fromRGB(255,255,255) }),
        name = newDrawing("Text",   { Visible=false, Size=14, Center=true, Outline=true, Color=Color3.fromRGB(255,255,255), OutlineColor=Color3.fromRGB(0,0,0) }),
        dist = newDrawing("Text",   { Visible=false, Size=12, Center=true, Outline=true, Color=Color3.fromRGB(200,200,200), OutlineColor=Color3.fromRGB(0,0,0) }),
    }
end

local function updateESP()
    local myRoot = getMyRoot()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LP then continue end

        local char = getChar(player)
        local root = getRootPart(player)

        if not char or not root then
            if Drawings[player] then
                for _, d in pairs(Drawings[player]) do pcall(function() d.Visible = false end) end
            end
            continue
        end

        if not Drawings[player] then createESP(player) end
        local d = Drawings[player]
        if not d then continue end

        if not State.espEnabled then
            for _, draw in pairs(d) do pcall(function() draw.Visible = false end) end
            continue
        end

        local dist = myRoot and getMagnitude(myRoot.Position, root.Position) or 999999
        if dist > State.espMaxDist then
            for _, draw in pairs(d) do pcall(function() draw.Visible = false end) end
            continue
        end

        local role = getPlayerRole(player)
        local color = roleColor(role)
        local screenPos, depth, onScreen = worldToViewport(root.Position)

        if not onScreen or depth <= 0 then
            for _, draw in pairs(d) do pcall(function() draw.Visible = false end) end
            continue
        end

        local scale = 1 / depth * 1000
        local bW = scale * 1.5
        local bH = scale * 5

        if State.espBoxes then
            d.box.Position = Vector2.new(screenPos.X - bW/2, screenPos.Y - bH/2)
            d.box.Size = Vector2.new(bW, bH)
            d.box.Color = color
            d.box.Visible = true
        else
            d.box.Visible = false
        end

        if State.espNames then
            local label = player.DisplayName
            if role ~= "Innocent" then label = "[" .. role .. "] " .. label end
            d.name.Position = Vector2.new(screenPos.X, screenPos.Y - bH/2 - 16)
            d.name.Text = label
            d.name.Color = color
            d.name.Visible = true
        else
            d.name.Visible = false
        end

        if State.espDist then
            d.dist.Position = Vector2.new(screenPos.X, screenPos.Y + bH/2 + 2)
            d.dist.Text = math.floor(dist) .. "m"
            d.dist.Color = Color3.fromRGB(200, 200, 200)
            d.dist.Visible = true
        else
            d.dist.Visible = false
        end
    end
end

for _, p in ipairs(Players:GetPlayers()) do createESP(p) end
Players.PlayerAdded:Connect(function(p) task.wait(1); createESP(p) end)
Players.PlayerRemoving:Connect(removeESP)

-- ============================================================
-- NEAREST PLAYER
-- ============================================================
local function getNearestPlayer()
    local myRoot = getMyRoot()
    if not myRoot then return nil end
    local nearest, nearestDist = nil, math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LP then continue end
        local root = getRootPart(p)
        if not root then continue end
        local char = getChar(p)
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end
        local d = getMagnitude(myRoot.Position, root.Position)
        if d < nearestDist then nearestDist = d; nearest = p end
    end
    return nearest
end

-- ============================================================
-- AUTO KNIFE
-- ============================================================
local autoKnifeRunning = false
local function startAutoKnife()
    if autoKnifeRunning then return end
    autoKnifeRunning = true
    task.spawn(function()
        while autoKnifeRunning and State.autoKnife do
            pcall(function()
                local target = getNearestPlayer()
                if target then
                    local char = getChar(LP)
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    if tool and tool.Name:lower():find("knife") then
                        local targetRoot = getRootPart(target)
                        if targetRoot then
                            local handle = tool:FindFirstChild("Handle")
                            if handle then
                                local orig = handle.CFrame
                                handle.CFrame = targetRoot.CFrame
                                task.wait(0.05)
                                handle.CFrame = orig
                            end
                        end
                        local re = tool:FindFirstChildOfClass("RemoteEvent")
                        if re then re:FireServer() end
                    end
                end
            end)
            task.wait(State.autoKnifeDelay)
        end
        autoKnifeRunning = false
    end)
end

-- ============================================================
-- AUTO SHOOT
-- ============================================================
local autoShootRunning = false
local function startAutoShoot()
    if autoShootRunning then return end
    autoShootRunning = true
    task.spawn(function()
        while autoShootRunning and State.autoShoot do
            pcall(function()
                local target = getNearestPlayer()
                if target then
                    local char = getChar(LP)
                    local tool = char and char:FindFirstChildOfClass("Tool")
                    if tool and (tool.Name:lower():find("revolver") or tool.Name:lower():find("gun")) then
                        local targetRoot = getRootPart(target)
                        if targetRoot then
                            -- Try Events remote
                            local events = ReplicatedStorage:FindFirstChild("Events")
                            if events then
                                local revRE = events:FindFirstChild("Revolver")
                                if revRE then
                                    pcall(function() revRE:FireServer(targetRoot.Position) end)
                                end
                            end
                            -- Try tool's own RE
                            local toolRE = tool:FindFirstChildOfClass("RemoteEvent")
                            if toolRE then
                                pcall(function() toolRE:FireServer(targetRoot.CFrame) end)
                            end
                        end
                    end
                end
            end)
            task.wait(State.autoShootDelay)
        end
        autoShootRunning = false
    end)
end

-- ============================================================
-- SILENT AIM
-- ============================================================
local silentAimOldMT = nil
local function enableSilentAim()
    pcall(function()
        local mt = getrawmetatable(game)
        setreadonly(mt, false)
        silentAimOldMT = mt.__index
        mt.__index = newcclosure(function(self, key)
            if self == LP:GetMouse() then
                local target = getNearestPlayer()
                if target then
                    local root = getRootPart(target)
                    if root then
                        if key == "Hit" then return CFrame.new(root.Position) end
                        if key == "UnitRay" then
                            return Ray.new(Camera.CFrame.Position, (root.Position - Camera.CFrame.Position).Unit * 1000)
                        end
                    end
                end
            end
            return silentAimOldMT(self, key)
        end)
        setreadonly(mt, true)
    end)
end

local function disableSilentAim()
    pcall(function()
        if silentAimOldMT then
            local mt = getrawmetatable(game)
            setreadonly(mt, false)
            mt.__index = silentAimOldMT
            setreadonly(mt, true)
            silentAimOldMT = nil
        end
    end)
end

-- ============================================================
-- SPEED / JUMP
-- ============================================================
LP.CharacterAdded:Connect(function(char)
    LPChar = char
    char:WaitForChild("Humanoid").WalkSpeed = State.speedEnabled and State.speedValue or 16
    char:WaitForChild("Humanoid").JumpPower = State.jumpEnabled and State.jumpValue or 50
end)

-- ============================================================
-- FLY
-- ============================================================
local function enableFly()
    local char = LP.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not root or not hum then return end
    hum.PlatformStand = true

    FlyBP = Instance.new("BodyPosition")
    FlyBP.MaxForce = Vector3.new(1e9, 1e9, 1e9)
    FlyBP.P = 1e5; FlyBP.D = 500
    FlyBP.Position = root.Position
    FlyBP.Parent = root

    FlyGyr = Instance.new("BodyGyro")
    FlyGyr.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
    FlyGyr.P = 1e4; FlyGyr.D = 400
    FlyGyr.CFrame = Camera.CFrame
    FlyGyr.Parent = root

    FlyCon = RunService.RenderStepped:Connect(function()
        if not State.flyEnabled or not FlyBP or not FlyGyr then
            if FlyCon then FlyCon:Disconnect(); FlyCon = nil end
            if FlyBP then FlyBP:Destroy(); FlyBP = nil end
            if FlyGyr then FlyGyr:Destroy(); FlyGyr = nil end
            if hum then hum.PlatformStand = false end
            return
        end
        local mv = Vector3.new()
        local spd = State.flySpeed
        local cf = Camera.CFrame
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then mv = mv + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then mv = mv - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then mv = mv - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then mv = mv + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then mv = mv + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then mv = mv - Vector3.new(0,1,0) end
        if mv.Magnitude > 0 then mv = mv.Unit end
        FlyBP.Position = root.Position + mv * spd * 0.1
        FlyGyr.CFrame = cf
    end)
end

local function disableFly()
    State.flyEnabled = false
    if FlyCon then FlyCon:Disconnect(); FlyCon = nil end
    if FlyBP then pcall(function() FlyBP:Destroy() end); FlyBP = nil end
    if FlyGyr then pcall(function() FlyGyr:Destroy() end); FlyGyr = nil end
    local char = LP.Character
    if char then
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
end

-- ============================================================
-- NOCLIP
-- ============================================================
local noclipCon = nil
local function enableNoclip()
    if noclipCon then return end
    noclipCon = RunService.Stepped:Connect(function()
        if not State.noclip then
            noclipCon:Disconnect(); noclipCon = nil; return
        end
        local char = LP.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = false
                end
            end
        end
    end)
end

-- ============================================================
-- ANTI AFK
-- ============================================================
local antiAfkCon = nil
local function startAntiAfk()
    if antiAfkCon then return end
    local VU = game:GetService("VirtualUser")
    antiAfkCon = LP.Idled:Connect(function()
        VU:CaptureController()
        VU:ClickButton2(Vector2.new())
    end)
end
local function stopAntiAfk()
    if antiAfkCon then antiAfkCon:Disconnect(); antiAfkCon = nil end
end
startAntiAfk()

-- ============================================================
-- FULLBRIGHT
-- ============================================================
local Lighting = game:GetService("Lighting")
local origLighting = {}
local function enableFullbright()
    origLighting = {
        Brightness    = Lighting.Brightness,
        ClockTime     = Lighting.ClockTime,
        FogEnd        = Lighting.FogEnd,
        GlobalShadows = Lighting.GlobalShadows,
        Ambient       = Lighting.Ambient,
    }
    Lighting.Brightness = 2
    Lighting.ClockTime = 14
    Lighting.FogEnd = 100000
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = false
        end
    end
end
local function disableFullbright()
    for k, v in pairs(origLighting) do Lighting[k] = v end
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") then
            v.Enabled = true
        end
    end
end

-- ============================================================
-- AUTO VOTE
-- ============================================================
local function setupAutoVote()
    local events = ReplicatedStorage:FindFirstChild("Events")
    if not events then return end
    local vBegun = events:FindFirstChild("VotingBegun")
    if not vBegun then return end
    vBegun.OnClientEvent:Connect(function(maps)
        if not State.autoVote then return end
        task.wait(math.random(1,3))
        local voted = events:FindFirstChild("Voted")
        if voted and maps and #maps > 0 then
            local pick = maps[math.random(1, #maps)]
            pcall(function() voted:FireServer(pick) end)
        end
    end)
end
pcall(setupAutoVote)

-- ============================================================
-- SPAM MSG
-- ============================================================
local spamRunning = false
local function startSpam()
    if spamRunning then return end
    spamRunning = true
    task.spawn(function()
        while spamRunning and State.spamMsg do
            pcall(function()
                local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
                if chatEvents then
                    local sayMsg = chatEvents:FindFirstChild("SayMessageRequest")
                    if sayMsg then sayMsg:FireServer(State.spamText, "All") end
                end
            end)
            task.wait(3)
        end
        spamRunning = false
    end)
end

-- ============================================================
-- STATS
-- ============================================================
local function getMyStats()
    local ls = LP:FindFirstChild("leaderstats")
    local os_ = LP:FindFirstChild("otherstats")
    local wins    = ls and ls:FindFirstChild("Wins") and ls.Wins.Value or 0
    local kills   = ls and ls:FindFirstChild("Kills") and ls.Kills.Value or 0
    local loses   = os_ and os_:FindFirstChild("Loses") and os_.Loses.Value or 0
    local matches = os_ and os_:FindFirstChild("Matches") and os_.Matches.Value or 0
    local money   = os_ and os_:FindFirstChild("Money") and os_.Money.Value or 0
    local wr = matches > 0 and math.round(wins / matches * 100) or 0
    return { wins=wins, kills=kills, loses=loses, matches=matches, money=money, winrate=wr }
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
RunService.RenderStepped:Connect(function()
    updateESP()
    if State.speedEnabled then
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = State.speedValue end
        end
    end
    if State.jumpEnabled then
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpPower = State.jumpValue end
        end
    end
    if State.alwaysDay then
        Lighting.ClockTime = 14
    end
end)

-- ============================================================
-- RAYFIELD UI
-- ============================================================
local Window = Rayfield:CreateWindow({
    Name            = "MVS Script • MYT",
    LoadingTitle    = "Murderer VS Sheriff",
    LoadingSubtitle = "Script por MYT",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "MYT_Scripts",
        FileName = "MVS_Config"
    },
    KeySystem = false,
})

-- ============================================================
-- TAB: ESP
-- ============================================================
local tabESP = Window:CreateTab("👁️  ESP", 4483362458)

tabESP:CreateToggle({
    Name = "ESP Ativado",
    CurrentValue = false,
    Flag = "espEnabled",
    Callback = function(val) State.espEnabled = val end,
})

tabESP:CreateToggle({
    Name = "Mostrar Boxes",
    CurrentValue = true,
    Flag = "espBoxes",
    Callback = function(val) State.espBoxes = val end,
})

tabESP:CreateToggle({
    Name = "Mostrar Nomes & Role",
    CurrentValue = true,
    Flag = "espNames",
    Callback = function(val) State.espNames = val end,
})

tabESP:CreateToggle({
    Name = "Mostrar Distância",
    CurrentValue = true,
    Flag = "espDist",
    Callback = function(val) State.espDist = val end,
})

tabESP:CreateSlider({
    Name = "Distância Máxima",
    Range = {50, 2000},
    Increment = 50,
    Suffix = "m",
    CurrentValue = 1000,
    Flag = "espMaxDist",
    Callback = function(val) State.espMaxDist = val end,
})

tabESP:CreateSection("Legenda")
tabESP:CreateLabel("🔴 Vermelho = Murderer  |  🔵 Azul = Sheriff  |  🟢 Verde = Inocente")

-- ============================================================
-- TAB: COMBATE
-- ============================================================
local tabCombat = Window:CreateTab("⚔️  Combate", 4483362458)

tabCombat:CreateSection("Auto Knife — Murderer")

tabCombat:CreateToggle({
    Name = "Auto Knife",
    CurrentValue = false,
    Flag = "autoKnife",
    Callback = function(val)
        State.autoKnife = val
        if val then startAutoKnife() end
    end,
})

tabCombat:CreateSlider({
    Name = "Delay do Auto Knife",
    Range = {0.05, 2},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0.1,
    Flag = "autoKnifeDelay",
    Callback = function(val) State.autoKnifeDelay = val end,
})

tabCombat:CreateSection("Auto Shoot — Sheriff")

tabCombat:CreateToggle({
    Name = "Auto Shoot",
    CurrentValue = false,
    Flag = "autoShoot",
    Callback = function(val)
        State.autoShoot = val
        if val then startAutoShoot() end
    end,
})

tabCombat:CreateSlider({
    Name = "Delay do Auto Shoot",
    Range = {0.05, 2},
    Increment = 0.05,
    Suffix = "s",
    CurrentValue = 0.15,
    Flag = "autoShootDelay",
    Callback = function(val) State.autoShootDelay = val end,
})

tabCombat:CreateSection("Mira")

tabCombat:CreateToggle({
    Name = "Silent Aim",
    CurrentValue = false,
    Flag = "silentAim",
    Callback = function(val)
        State.silentAim = val
        if val then pcall(enableSilentAim) else pcall(disableSilentAim) end
    end,
})

tabCombat:CreateButton({
    Name = "🎭 Detectar Meu Role",
    Callback = function()
        local role = detectRole()
        Rayfield:Notify({
            Title = "Role Detectado",
            Content = "Você é: " .. role,
            Duration = 4,
        })
    end,
})

tabCombat:CreateButton({
    Name = "🔪 Equipar Faca",
    Callback = function()
        local bp = LP:FindFirstChild("Backpack")
        if bp then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") and tool.Name:lower():find("knife") then
                    tool.Parent = LP.Character
                    Rayfield:Notify({ Title = "Equipado", Content = "Faca equipada!", Duration = 2 })
                    return
                end
            end
        end
        Rayfield:Notify({ Title = "Sem Faca", Content = "Nenhuma faca no backpack.", Duration = 2 })
    end,
})

tabCombat:CreateButton({
    Name = "🔫 Equipar Revólver",
    Callback = function()
        local bp = LP:FindFirstChild("Backpack")
        if bp then
            for _, tool in ipairs(bp:GetChildren()) do
                if tool:IsA("Tool") and (tool.Name:lower():find("revolver") or tool.Name:lower():find("gun")) then
                    tool.Parent = LP.Character
                    Rayfield:Notify({ Title = "Equipado", Content = "Revólver equipado!", Duration = 2 })
                    return
                end
            end
        end
        Rayfield:Notify({ Title = "Sem Revólver", Content = "Nenhum revólver no backpack.", Duration = 2 })
    end,
})

-- ============================================================
-- TAB: MOVIMENTO
-- ============================================================
local tabMove = Window:CreateTab("🏃  Movimento", 4483362458)

tabMove:CreateToggle({
    Name = "Speed Hack",
    CurrentValue = false,
    Flag = "speedEnabled",
    Callback = function(val)
        State.speedEnabled = val
        if not val then
            local char = LP.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = 16 end
            end
        end
    end,
})

tabMove:CreateSlider({
    Name = "Velocidade",
    Range = {16, 200},
    Increment = 1,
    CurrentValue = 25,
    Flag = "speedValue",
    Callback = function(val) State.speedValue = val end,
})

tabMove:CreateToggle({
    Name = "Jump Hack",
    CurrentValue = false,
    Flag = "jumpEnabled",
    Callback = function(val)
        State.jumpEnabled = val
        if not val then
            local char = LP.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then hum.JumpPower = 50 end
            end
        end
    end,
})

tabMove:CreateSlider({
    Name = "Poder de Pulo",
    Range = {50, 500},
    Increment = 5,
    CurrentValue = 80,
    Flag = "jumpValue",
    Callback = function(val) State.jumpValue = val end,
})

tabMove:CreateSection("Fly  (WASD + Space / Ctrl)")

tabMove:CreateToggle({
    Name = "Fly",
    CurrentValue = false,
    Flag = "flyEnabled",
    Callback = function(val)
        State.flyEnabled = val
        if val then enableFly() else disableFly() end
    end,
})

tabMove:CreateSlider({
    Name = "Velocidade do Fly",
    Range = {5, 200},
    Increment = 5,
    CurrentValue = 50,
    Flag = "flySpeed",
    Callback = function(val) State.flySpeed = val end,
})

tabMove:CreateSection("Noclip")

tabMove:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "noclip",
    Callback = function(val)
        State.noclip = val
        if val then enableNoclip() end
    end,
})

tabMove:CreateSection("Teleporte")

tabMove:CreateButton({
    Name = "📍 Teleportar ao Jogador Mais Perto",
    Callback = function()
        local target = getNearestPlayer()
        if target then
            local char = LP.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local targetRoot = getRootPart(target)
            if root and targetRoot then
                root.CFrame = targetRoot.CFrame + Vector3.new(2, 0, 0)
                Rayfield:Notify({ Title = "Teleport", Content = "Tp para: " .. target.Name, Duration = 2 })
            end
        else
            Rayfield:Notify({ Title = "Nenhum Alvo", Content = "Nenhum jogador encontrado.", Duration = 2 })
        end
    end,
})

tabMove:CreateButton({
    Name = "🏁 Teleportar ao Spawn",
    Callback = function()
        local char = LP.Character
        if char then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                local spawn = workspace:FindFirstChildOfClass("SpawnLocation")
                if spawn then
                    root.CFrame = spawn.CFrame + Vector3.new(0, 5, 0)
                else
                    root.CFrame = CFrame.new(0, 10, 0)
                end
            end
        end
    end,
})

-- ============================================================
-- TAB: VISUAL
-- ============================================================
local tabVisual = Window:CreateTab("🎨  Visual", 4483362458)

tabVisual:CreateToggle({
    Name = "Fullbright",
    CurrentValue = false,
    Flag = "fullbright",
    Callback = function(val)
        State.fullbright = val
        if val then enableFullbright() else disableFullbright() end
    end,
})

tabVisual:CreateToggle({
    Name = "Sempre Dia",
    CurrentValue = false,
    Flag = "alwaysDay",
    Callback = function(val) State.alwaysDay = val end,
})

tabVisual:CreateSlider({
    Name = "Campo de Visão (FOV)",
    Range = {40, 120},
    Increment = 1,
    CurrentValue = 70,
    Flag = "fovValue",
    Callback = function(val)
        State.fovValue = val
        Camera.FieldOfView = val
    end,
})

tabVisual:CreateButton({
    Name = "🔄 Reset Visual",
    Callback = function()
        Camera.FieldOfView = 70
        if State.fullbright then disableFullbright() end
        State.fullbright = false
        State.alwaysDay = false
        Rayfield:Notify({ Title = "Visual Resetado", Content = "Tudo voltou ao normal.", Duration = 2 })
    end,
})

-- ============================================================
-- TAB: QoL
-- ============================================================
local tabQoL = Window:CreateTab("🛠️  QoL", 4483362458)

tabQoL:CreateSection("Jogo")

tabQoL:CreateToggle({
    Name = "Anti AFK",
    CurrentValue = true,
    Flag = "antiAfk",
    Callback = function(val)
        State.antiAfk = val
        if val then startAntiAfk() else stopAntiAfk() end
    end,
})

tabQoL:CreateToggle({
    Name = "Auto Votar (mapa aleatório)",
    CurrentValue = false,
    Flag = "autoVote",
    Callback = function(val) State.autoVote = val end,
})

tabQoL:CreateSection("Chat Spam")

tabQoL:CreateInput({
    Name = "Mensagem do Spam",
    PlaceholderText = "Digite aqui...",
    RemoveTextAfterFocusLost = false,
    Flag = "spamText",
    Callback = function(val) if val and val ~= "" then State.spamText = val end end,
})

tabQoL:CreateToggle({
    Name = "Spam de Mensagem (a cada 3s)",
    CurrentValue = false,
    Flag = "spamMsg",
    Callback = function(val)
        State.spamMsg = val
        if val then startSpam() end
    end,
})

-- ============================================================
-- TAB: STATS
-- ============================================================
local tabStats = Window:CreateTab("📊  Stats", 4483362458)

local statsLabel = tabStats:CreateParagraph({
    Title = "Suas Estatísticas",
    Content = "Clique em Atualizar para carregar.",
})

local function refreshStats()
    local st = getMyStats()
    local role = detectRole()
    local roleIcon = role == "Murderer" and "🔪" or role == "Sheriff" and "🔫" or "👤"
    statsLabel:Set({
        Title = "📊 " .. LP.DisplayName .. " (@" .. LP.Name .. ")",
        Content = table.concat({
            "🏆 Wins: " .. tostring(st.wins),
            "💀 Kills: " .. tostring(st.kills),
            "❌ Loses: " .. tostring(st.loses),
            "🎮 Partidas: " .. tostring(st.matches),
            "📈 Win Rate: " .. tostring(st.winrate) .. "%",
            "💰 Money: $" .. tostring(st.money),
            roleIcon .. " Role: " .. role,
        }, "\n")
    })
end

tabStats:CreateButton({
    Name = "🔄 Atualizar Stats",
    Callback = refreshStats,
})

tabStats:CreateSection("Jogadores na Partida")

tabStats:CreateButton({
    Name = "📋 Listar Todos os Jogadores",
    Callback = function()
        local list = {}
        for _, p in ipairs(Players:GetPlayers()) do
            local role = getPlayerRole(p)
            local icon = role == "Murderer" and "🔪" or role == "Sheriff" and "🔫" or "👤"
            table.insert(list, icon .. " " .. p.Name)
        end
        Rayfield:Notify({
            Title = "Jogadores (" .. #list .. "/" .. #Players:GetPlayers() .. ")",
            Content = table.concat(list, "\n"),
            Duration = 8,
        })
    end,
})

tabStats:CreateButton({
    Name = "🗺️ Ver Partidas em Andamento",
    Callback = function()
        local running = workspace:FindFirstChild("RunningRounds")
        if not running then
            Rayfield:Notify({ Title = "Erro", Content = "RunningRounds não encontrado.", Duration = 3 })
            return
        end
        local rounds = running:GetChildren()
        if #rounds == 0 then
            Rayfield:Notify({ Title = "Nenhuma Partida", Content = "Nenhuma partida em andamento.", Duration = 3 })
            return
        end
        local info = {}
        for _, r in ipairs(rounds) do
            local players = r:FindFirstChild("Players")
            local count = players and #players:GetChildren() or 0
            table.insert(info, "⚔️ " .. r.Name .. " | " .. count .. " jogadores")
        end
        Rayfield:Notify({
            Title = "Partidas (" .. #rounds .. ")",
            Content = table.concat(info, "\n"),
            Duration = 6,
        })
    end,
})

-- ============================================================
-- TAB: MISC
-- ============================================================
local tabMisc = Window:CreateTab("⚙️  Misc", 4483362458)

tabMisc:CreateSection("Info")
tabMisc:CreateLabel("🎮 Jogo: Murderer VS Sheriff")
tabMisc:CreateLabel("✍️ Script por: MYT")
tabMisc:CreateLabel("🖥️ UI: Rayfield Library")

tabMisc:CreateSection("Utilitários")

tabMisc:CreateButton({
    Name = "📋 Copiar Place ID",
    Callback = function()
        pcall(function() setclipboard(tostring(game.PlaceId)) end)
        Rayfield:Notify({ Title = "Copiado!", Content = "Place ID: " .. tostring(game.PlaceId), Duration = 3 })
    end,
})

tabMisc:CreateButton({
    Name = "🔄 Rejoin",
    Callback = function()
        local TS = game:GetService("TeleportService")
        TS:Teleport(game.PlaceId, LP)
    end,
})

tabMisc:CreateButton({
    Name = "🚪 Sair do Servidor",
    Callback = function()
        LP:Kick("MVS Script — Saiu voluntariamente.")
    end,
})

tabMisc:CreateSection("Danger Zone")

tabMisc:CreateButton({
    Name = "💥 Delete Personagem (local)",
    Callback = function()
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum.Health = 0 end
        end
        Rayfield:Notify({ Title = "Feito", Content = "Personagem morreu.", Duration = 2 })
    end,
})

-- ============================================================
-- NOTIFICAÇÃO INICIAL
-- ============================================================
task.spawn(function()
    task.wait(1.5)
    local role = detectRole()
    Rayfield:Notify({
        Title = "MVS Script Ativo!",
        Content = "Bem-vindo, " .. LP.DisplayName .. "!\nRole: " .. role,
        Duration = 5,
    })
    task.wait(2)
    refreshStats()
end)

print("[MVS Script] Carregado — by MYT")
