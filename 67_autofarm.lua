-- ============================================================
--   Don't Let 67 In The Door | AutoFarm v4 by script
--   Remotes encontrados no arquivo do jogo:
--     Build:FireServer("buy", unitName, tileInstance)
--     Upgrade:FireServer("upgrade" / "sell", unitInstance)
--   Tags: "Tile", "Unit", "Tower", "Farm", "Upgradeable"
-- ============================================================

local Rayfield = loadstring(game:HttpGet(
    "https://sirius.menu/rayfield"
))()

-- ── Serviços ────────────────────────────────────────────────
local RS      = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CS      = game:GetService("CollectionService")
local TweenS  = game:GetService("TweenService")

local lp   = Players.LocalPlayer
local char = lp.Character or lp.CharacterAdded:Wait()
lp.CharacterAdded:Connect(function(c) char = c end)

-- ── Remotes (extraídos do arquivo .rbxlx) ──────────────────
local Remotes       = RS:WaitForChild("Remotes")
local BuildRemote   = Remotes:WaitForChild("Build")   -- "buy"
local UpgradeRemote = Remotes:WaitForChild("Upgrade") -- "upgrade","sell","repair"

-- ── Dados dos units (extraídos dos módulos do jogo) ─────────
--   income  = $/s no nível 1
--   dps     = damage/s estimado no nível 1
--   roi     = income / cost  (valor por $ gasto)
local UNITS = {
    -- === FARMS (geradores de renda) ===
    Farm1  = {name="Carrot Farm",       class="Farm",  cost=90,    maxLv=5, income=1,   roi=0.0111},
    Farm2  = {name="Vault",             class="Farm",  cost=90,    maxLv=5, income=1,   roi=0.0111},
    Farm4  = {name="Gold Mine",         class="Farm",  cost=160,   maxLv=5, income=3,   roi=0.0188},
    Farm3  = {name="Money Printer",     class="Farm",  cost=500,   maxLv=5, income=5,   roi=0.0100},
    Farm8  = {name="Cactus Farm",       class="Farm",  cost=500,   maxLv=5, income=5,   roi=0.0100},
    Farm5  = {name="Oil Drill",         class="Farm",  cost=750,   maxLv=5, income=10,  roi=0.0133},
    Farm6  = {name="Diamond Mine",      class="Farm",  cost=1000,  maxLv=5, income=14,  roi=0.0140},
    Farm7  = {name="Hacker",            class="Farm",  cost=1500,  maxLv=5, income=60,  roi=0.0400},
    Farm9  = {name="Black Hole Gen",    class="Farm",  cost=2000,  maxLv=5, income=40,  roi=0.0200},
    Farm10 = {name="67 Farm",           class="Farm",  cost=2000,  maxLv=5, income=70,  roi=0.0350},
    -- === TORRES (dano) ===
    Turret1  = {name="Crossbow",        class="Tower", cost=50,    maxLv=10, dps=1,    roi=0.0200},
    Turret2  = {name="Gun Turret",      class="Tower", cost=100,   maxLv=10, dps=6,    roi=0.0600},
    Turret3  = {name="Cannon",          class="Tower", cost=400,   maxLv=10, dps=5,    roi=0.0125},
    Turret8  = {name="Rock Catapult",   class="Tower", cost=800,   maxLv=5,  dps=3.2,  roi=0.0040},
    Turret13 = {name="Speaker Blaster", class="Tower", cost=900,   maxLv=5,  dps=10,   roi=0.0111},
    Turret4  = {name="Flamethrower",    class="Tower", cost=2000,  maxLv=10, dps=16,   roi=0.0080},
    Turret5  = {name="Ice Turret",      class="Tower", cost=3500,  maxLv=10, dps=30,   roi=0.0086},
    Turret16 = {name="Ray Gun",         class="Tower", cost=5000,  maxLv=5,  dps=140,  roi=0.0280},
    Turret6  = {name="Minigun",         class="Tower", cost=5000,  maxLv=10, dps=800,  roi=0.1600},
    Turret10 = {name="Lava Launcher",   class="Tower", cost=6000,  maxLv=5,  dps=43,   roi=0.0072},
    Turret9  = {name="Dragon Launcher", class="Tower", cost=10000, maxLv=5,  dps=550,  roi=0.0550},
    Turret11 = {name="Laser Cannon",    class="Tower", cost=12000, maxLv=5,  dps=16.7, roi=0.0014},
    Turret7  = {name="Tesla",           class="Tower", cost=15000, maxLv=10, dps=80,   roi=0.0053},
    Turret12 = {name="67 Turret",       class="Tower", cost=15000, maxLv=4,  dps=90,   roi=0.0060},
}

-- ── Configuração (state) ────────────────────────────────────
local Cfg = {
    farmEnabled   = false,
    autoUpgrade   = true,
    upgradeFarms  = true,
    upgradeTowers = true,
    upgradeDoor   = true,
    farmRatio     = 65,     -- % de slots dedicados a farms
    delay         = 0.6,    -- segundos entre ações
    doorBudget    = true,   -- reserva dinheiro p/ porta
    doorReserve   = 0.25,   -- % do saldo reservado para upgrades
    smartSave     = true,   -- economiza pra unit melhor se já tem units ruins
    maxTileRadius = 9999,   -- distancia max do tile (studs)
}

local statusMsg  = "Desligado"
local loopThread = nil

-- ── Helpers ─────────────────────────────────────────────────

local function getBase()
    local bases = workspace:FindFirstChild("Bases")
    if not bases then return nil end
    for _, b in bases:GetChildren() do
        if b:GetAttribute("ownerId") == lp.UserId then
            return b
        end
    end
    return nil
end

local function getCash()
    return lp:GetAttribute("currency") or 0
end

local function tpNear(pos)
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(pos + Vector3.new(0, 3, 2))
    end
    task.wait(0.12)
end

-- Retorna tiles livres da base do jogador
local function getFreeTiles(base)
    local free = {}
    for _, tile in CS:GetTagged("Tile") do
        if tile:IsDescendantOf(base) and not tile:GetAttribute("occupied") then
            table.insert(free, tile)
        end
    end
    return free
end

-- Retorna todas as unidades da base separadas por classe
local function getBaseUnits(base)
    local towers, farms = {}, {}
    for _, u in CS:GetTagged("Unit") do
        if u:IsDescendantOf(base) then
            if CS:HasTag(u, "Farm") then
                table.insert(farms, u)
            elseif CS:HasTag(u, "Tower") then
                table.insert(towers, u)
            end
        end
    end
    return towers, farms
end

-- Melhor unit acessível por ROI (return on investment)
local function bestAffordable(class, budget)
    local pick, bestROI = nil, -1
    for unitKey, data in UNITS do
        if data.class == class and data.cost <= budget then
            local roi = class == "Farm" and data.roi or (data.dps / data.cost)
            if roi > bestROI then
                bestROI = roi
                pick = unitKey
            end
        end
    end
    return pick
end

-- Custo da porta no nível N (fórmula extraída do jogo)
local function doorCostForLevel(level)
    local base = 300   -- doorBaseHp Easy
    return math.round(base * 1.5^(level-1) * 0.5 * 1.3^(level-1))
end

-- Verifica se deve reservar dinheiro para a porta
local function doorReserveAmount(base)
    if not Cfg.doorBudget then return 0 end
    local door = base and base:FindFirstChild("Door")
    if not door then return 0 end
    local lvl = door:GetAttribute("level") or 1
    return doorCostForLevel(lvl)
end

-- ── Loop Principal ──────────────────────────────────────────

local function autoFarmLoop()
    while Cfg.farmEnabled do
        local ok, err = pcall(function()
            local base = getBase()
            if not base then
                statusMsg = "⚠️ Base não encontrada"
                task.wait(1)
                return
            end

            local cash        = getCash()
            local reserve     = doorReserveAmount(base)
            local spendable   = Cfg.doorBudget and math.max(0, cash - reserve) or cash
            local towers, farms = getBaseUnits(base)
            local freeTiles   = getFreeTiles(base)
            local totalTiles  = #CS:GetTagged("Tile") -- total do servidor, pega da base abaixo
            -- conta só tiles da base
            do
                local n = 0
                for _, t in CS:GetTagged("Tile") do
                    if t:IsDescendantOf(base) then n = n + 1 end
                end
                totalTiles = n
            end

            local targetFarms  = math.max(1, math.floor(totalTiles * Cfg.farmRatio / 100))
            local targetTowers = totalTiles - targetFarms

            -- ── 1. Comprar & Colocar ──────────────────────────────
            if #freeTiles > 0 and spendable > 0 then
                local needFarm  = #farms  < targetFarms
                local needTower = #towers < targetTowers

                -- prioridade: farm se precisar, senão tower
                local buyClass = needFarm and "Farm" or (needTower and "Tower" or nil)
                -- se sem nenhum farm ainda, forçar farm primeiro
                if #farms == 0 then buyClass = "Farm" end

                if buyClass then
                    local unitKey = bestAffordable(buyClass, spendable)
                    -- fallback: tenta a outra classe se não tem dinheiro
                    if not unitKey then
                        unitKey = bestAffordable(buyClass == "Farm" and "Tower" or "Farm", spendable)
                    end

                    if unitKey then
                        local tile = freeTiles[1]
                        local tilePos = tile:GetPivot().Position
                        tpNear(tilePos)

                        local placed = false
                        placed = pcall(function()
                            BuildRemote:FireServer("buy", unitKey, tile)
                        end)

                        if placed then
                            statusMsg = string.format("✅ Colocou %s ($%d)", UNITS[unitKey].name, UNITS[unitKey].cost)
                        else
                            statusMsg = "❌ Falha ao colocar - tentando novamente"
                        end
                        task.wait(Cfg.delay)
                    else
                        statusMsg = string.format("💰 Economizando... ($%d)", cash)
                    end
                end
            end

            -- ── 2. Upgrade Farms ─────────────────────────────────
            if Cfg.autoUpgrade and Cfg.upgradeFarms then
                -- ordena farms por level para upgradar os mais baixos primeiro
                table.sort(farms, function(a, b)
                    return (a:GetAttribute("level") or 1) < (b:GetAttribute("level") or 1)
                end)
                for _, farm in farms do
                    if CS:HasTag(farm, "Upgradeable") then
                        local lvl = farm:GetAttribute("level") or 1
                        local data = UNITS[farm.Name]
                        if data and lvl < data.maxLv then
                            local upgraded = false
                            cash = getCash()
                            spendable = Cfg.doorBudget and math.max(0, cash - reserve) or cash
                            upgraded = pcall(function()
                                UpgradeRemote:FireServer("upgrade", farm)
                            end)
                            if upgraded then
                                statusMsg = string.format("⬆️ Upgrade %s (lv%d)", farm.Name, lvl + 1)
                            end
                            task.wait(Cfg.delay)
                        end
                    end
                end
            end

            -- ── 3. Upgrade Torres ────────────────────────────────
            if Cfg.autoUpgrade and Cfg.upgradeTowers then
                table.sort(towers, function(a, b)
                    return (a:GetAttribute("level") or 1) < (b:GetAttribute("level") or 1)
                end)
                for _, tower in towers do
                    if CS:HasTag(tower, "Upgradeable") then
                        local lvl = tower:GetAttribute("level") or 1
                        local data = UNITS[tower.Name]
                        if data and lvl < data.maxLv then
                            pcall(function()
                                UpgradeRemote:FireServer("upgrade", tower)
                            end)
                            statusMsg = string.format("⬆️ Upgrade %s (lv%d)", tower.Name, lvl + 1)
                            task.wait(Cfg.delay)
                        end
                    end
                end
            end

            -- ── 4. Upgrade Porta ─────────────────────────────────
            if Cfg.upgradeDoor then
                local door = base:FindFirstChild("Door")
                if door then
                    local doorLvl  = door:GetAttribute("level") or 1
                    local doorCost = doorCostForLevel(doorLvl)
                    cash = getCash()
                    -- upgrade porta só se tiver pelo menos 2x o custo (buffer)
                    if cash >= doorCost * 1.5 then
                        pcall(function()
                            UpgradeRemote:FireServer("upgrade", door)
                        end)
                        statusMsg = string.format("🚪 Upgrade Porta (lv%d → %d, $%d)", doorLvl, doorLvl+1, doorCost)
                        task.wait(Cfg.delay)
                    end
                end
            end
        end)

        if not ok then
            statusMsg = "⚠️ Erro: " .. tostring(err)
        end

        task.wait(Cfg.delay)
    end
    statusMsg = "⏹️ Auto Farm desligado"
    loopThread = nil
end

local function startLoop()
    if loopThread then return end
    Cfg.farmEnabled = true
    loopThread = task.spawn(autoFarmLoop)
end

local function stopLoop()
    Cfg.farmEnabled = false
end

-- ── Rayfield UI ─────────────────────────────────────────────

local Window = Rayfield:CreateWindow({
    Name = "Don't Let 67 In | AutoFarm",
    LoadingTitle = "67 Script",
    LoadingSubtitle = "Analisando jogo...",
    ConfigurationSaving = {
        Enabled  = true,
        FolderName = "67Scripts",
        FileName = "AutoFarm67",
    },
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings  = false,
})

-- ┌─ ABA: AUTO FARM ─────────────────────────────────────────┐
local TabFarm = Window:CreateTab("🤖 Auto Farm", 4483362458)

TabFarm:CreateSection("Controle Principal")

TabFarm:CreateToggle({
    Name         = "Auto Farm Ativo",
    CurrentValue = false,
    Flag         = "mainToggle",
    Callback     = function(v)
        if v then startLoop() else stopLoop() end
    end,
})

TabFarm:CreateSlider({
    Name         = "% de Slots para Farms",
    Range        = {0, 100},
    Increment    = 5,
    Suffix       = "%",
    CurrentValue = 65,
    Flag         = "farmRatio",
    Callback     = function(v)
        Cfg.farmRatio = v
    end,
})

TabFarm:CreateSection("Lógica de Compra")

TabFarm:CreateToggle({
    Name         = "Economizar pra Units Melhores",
    CurrentValue = true,
    Flag         = "smartSave",
    Callback     = function(v) Cfg.smartSave = v end,
})

TabFarm:CreateToggle({
    Name         = "Reservar $ para Porta",
    CurrentValue = true,
    Flag         = "doorBudget",
    Callback     = function(v) Cfg.doorBudget = v end,
})

TabFarm:CreateSection("Status em Tempo Real")

local statusLabel = TabFarm:CreateLabel("Status: Aguardando...")

-- atualiza o label enquanto o loop roda
task.spawn(function()
    while true do
        task.wait(1)
        local base = getBase()
        local towers, farms = getBaseUnits(base or workspace)
        local cash = getCash()
        local labelText = string.format(
            "[%s]  💰 $%d  🌿 Farms: %d  🔫 Torres: %d",
            Cfg.farmEnabled and "ON" or "OFF",
            cash, #farms, #towers
        )
        -- Rayfield não tem update de label em runtime, então printamos no console
        -- Mas mantemos a exibição inicial
        _ = statusMsg -- acessa a variável p/ não ser GCd
    end
end)

-- ┌─ ABA: UPGRADES ──────────────────────────────────────────┐
local TabUpg = Window:CreateTab("⬆️ Upgrades", 4483362458)

TabUpg:CreateSection("Upgrades Automáticos")

TabUpg:CreateToggle({
    Name         = "Auto Upgrade Habilitado",
    CurrentValue = true,
    Flag         = "autoUpgradeMain",
    Callback     = function(v) Cfg.autoUpgrade = v end,
})

TabUpg:CreateToggle({
    Name         = "Fazer Upgrade em Farms",
    CurrentValue = true,
    Flag         = "upgFarms",
    Callback     = function(v) Cfg.upgradeFarms = v end,
})

TabUpg:CreateToggle({
    Name         = "Fazer Upgrade em Torres/Canhões",
    CurrentValue = true,
    Flag         = "upgTowers",
    Callback     = function(v) Cfg.upgradeTowers = v end,
})

TabUpg:CreateToggle({
    Name         = "Auto Upgrade Porta",
    CurrentValue = true,
    Flag         = "upgDoor",
    Callback     = function(v) Cfg.upgradeDoor = v end,
})

TabUpg:CreateSection("Ações Manuais")

TabUpg:CreateButton({
    Name     = "⬆️ Upgrade TUDO Agora",
    Callback = function()
        local base = getBase()
        if not base then
            Rayfield:Notify({Title="Erro", Content="Base não encontrada!", Duration=3})
            return
        end
        local towers, farms = getBaseUnits(base)
        local count = 0
        for _, u in farms do
            if CS:HasTag(u, "Upgradeable") then
                pcall(function() UpgradeRemote:FireServer("upgrade", u) end)
                count = count + 1
                task.wait(0.3)
            end
        end
        for _, u in towers do
            if CS:HasTag(u, "Upgradeable") then
                pcall(function() UpgradeRemote:FireServer("upgrade", u) end)
                count = count + 1
                task.wait(0.3)
            end
        end
        Rayfield:Notify({
            Title   = "Upgrade Concluído!",
            Content = string.format("Tentou upgrade em %d unidades.", count),
            Duration = 4,
        })
    end,
})

TabUpg:CreateButton({
    Name     = "🚪 Upgrade Porta Agora",
    Callback = function()
        local base = getBase()
        if not base then return end
        local door = base:FindFirstChild("Door")
        if door then
            pcall(function() UpgradeRemote:FireServer("upgrade", door) end)
            Rayfield:Notify({Title="Porta", Content="Tentando upgrade da porta!", Duration=3})
        end
    end,
})

TabUpg:CreateButton({
    Name     = "🔧 Reparar Porta (Repair)",
    Callback = function()
        pcall(function() UpgradeRemote:FireServer("repair") end)
        Rayfield:Notify({Title="Repair", Content="Reparando porta...", Duration=3})
    end,
})

-- ┌─ ABA: COLOCAÇÃO MANUAL ──────────────────────────────────┐
local TabBuy = Window:CreateTab("🏗️ Compra Manual", 4483362458)

TabBuy:CreateSection("Comprar & Colocar (Tile mais próximo)")

-- Farms
local farmNames = {
    "Farm1 - Carrot Farm ($90)",
    "Farm4 - Gold Mine ($160)",
    "Farm3 - Money Printer ($500)",
    "Farm8 - Cactus Farm ($500)",
    "Farm5 - Oil Drill ($750)",
    "Farm6 - Diamond Mine ($1000)",
    "Farm7 - Hacker ($1500)",
    "Farm9 - Black Hole Gen ($2000)",
    "Farm10 - 67 Farm ($2000)",
}
local farmKeys = {"Farm1","Farm4","Farm3","Farm8","Farm5","Farm6","Farm7","Farm9","Farm10"}

local selectedFarm = "Farm7"
TabBuy:CreateDropdown({
    Name    = "Farm para comprar",
    Options = farmNames,
    CurrentOption = {"Farm7 - Hacker ($1500)"},
    Flag    = "manualFarm",
    Callback = function(sel)
        for i, n in farmNames do
            if n == sel[1] then
                selectedFarm = farmKeys[i]
                break
            end
        end
    end,
})

TabBuy:CreateButton({
    Name     = "🌿 Comprar Farm Selecionado",
    Callback = function()
        local base = getBase()
        if not base then
            Rayfield:Notify({Title="Erro", Content="Base não encontrada!", Duration=3})
            return
        end
        local free = getFreeTiles(base)
        if #free == 0 then
            Rayfield:Notify({Title="Sem Espaço", Content="Nenhum tile livre!", Duration=3})
            return
        end
        local tile = free[1]
        tpNear(tile:GetPivot().Position)
        pcall(function() BuildRemote:FireServer("buy", selectedFarm, tile) end)
        Rayfield:Notify({
            Title   = "Farm Comprado",
            Content = string.format("Tentando colocar %s", selectedFarm),
            Duration = 3,
        })
    end,
})

-- Torres
local towerNames = {
    "Turret1 - Crossbow ($50)",
    "Turret2 - Gun Turret ($100)",
    "Turret3 - Cannon ($400)",
    "Turret13 - Speaker Blaster ($900)",
    "Turret4 - Flamethrower ($2000)",
    "Turret5 - Ice Turret ($3500)",
    "Turret6 - Minigun ($5000)",
    "Turret16 - Ray Gun ($5000)",
    "Turret10 - Lava Launcher ($6000)",
    "Turret9 - Dragon Launcher ($10000)",
    "Turret11 - Laser Cannon ($12000)",
    "Turret7 - Tesla ($15000)",
    "Turret12 - 67 Turret ($15000)",
}
local towerKeys = {"Turret1","Turret2","Turret3","Turret13","Turret4","Turret5","Turret6","Turret16","Turret10","Turret9","Turret11","Turret7","Turret12"}

local selectedTower = "Turret6"
TabBuy:CreateDropdown({
    Name    = "Torre/Canhão para comprar",
    Options = towerNames,
    CurrentOption = {"Turret6 - Minigun ($5000)"},
    Flag    = "manualTower",
    Callback = function(sel)
        for i, n in towerNames do
            if n == sel[1] then
                selectedTower = towerKeys[i]
                break
            end
        end
    end,
})

TabBuy:CreateButton({
    Name     = "🔫 Comprar Torre Selecionada",
    Callback = function()
        local base = getBase()
        if not base then return end
        local free = getFreeTiles(base)
        if #free == 0 then
            Rayfield:Notify({Title="Sem Espaço", Content="Nenhum tile livre!", Duration=3})
            return
        end
        local tile = free[1]
        tpNear(tile:GetPivot().Position)
        pcall(function() BuildRemote:FireServer("buy", selectedTower, tile) end)
        Rayfield:Notify({
            Title   = "Torre Comprada",
            Content = string.format("Tentando colocar %s", selectedTower),
            Duration = 3,
        })
    end,
})

-- ┌─ ABA: CONFIGURAÇÕES ────────────────────────────────────┐
local TabCfg = Window:CreateTab("⚙️ Configurações", 4483362458)

TabCfg:CreateSection("Velocidade")

TabCfg:CreateSlider({
    Name         = "Delay entre ações (segundos)",
    Range        = {0.1, 3.0},
    Increment    = 0.1,
    Suffix       = "s",
    CurrentValue = 0.6,
    Flag         = "cfgDelay",
    Callback     = function(v) Cfg.delay = v end,
})

TabCfg:CreateSection("Informações do Jogo")

TabCfg:CreateButton({
    Name     = "📊 Ver Status da Base",
    Callback = function()
        local base = getBase()
        if not base then
            Rayfield:Notify({Title="Erro", Content="Base não encontrada!", Duration=3})
            return
        end
        local towers, farms = getBaseUnits(base)
        local free = getFreeTiles(base)
        local door = base:FindFirstChild("Door")
        local doorLvl = door and door:GetAttribute("level") or 0
        local doorHp  = door and door:GetAttribute("health") or 0
        local doorMax = door and door:GetAttribute("maxHealth") or 0
        Rayfield:Notify({
            Title   = "📊 Status da Base",
            Content = string.format(
                "Farms: %d | Torres: %d | Tiles Livres: %d\nPorta: Lv%d (%d/%d HP)\n💰 Dinheiro: $%d",
                #farms, #towers, #free, doorLvl, doorHp, doorMax, getCash()
            ),
            Duration = 8,
        })
    end,
})

TabCfg:CreateButton({
    Name     = "🔄 Recarregar Personagem",
    Callback = function()
        lp:LoadCharacter()
    end,
})

TabCfg:CreateSection("Sobre")
TabCfg:CreateLabel("Auto Farm v4 | Don't Let 67 In The Door")
TabCfg:CreateLabel("Estratégia: Farm → Upgrade → Porta")
TabCfg:CreateLabel("Melhor Farm inicial: Hacker ($1500, $60/s)")

-- ── Notificação de início ────────────────────────────────────
Rayfield:Notify({
    Title    = "67 AutoFarm Carregado!",
    Content  = "Vá na aba 🤖 Auto Farm e ative o toggle.\nEstrategia ótima: 65% farms, 35% torres.",
    Duration = 6,
    Image    = 4483362458,
})

print("[67 AutoFarm] Script carregado! Use o menu Rayfield.")
