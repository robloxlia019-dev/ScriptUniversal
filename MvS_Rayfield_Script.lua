-- ============================================================
--   Murderers vs Sheriffs — Script Completo com Rayfield UI
--   Recursos: Trocar Arma/Faca, Favoritos, Busca Inteligente
-- ============================================================

-- Carrega Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ============================================================
-- CONFIGURAÇÕES GERAIS
-- ============================================================

local HttpService = game:GetService("HttpService")
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- Salva favoritos no SaveManager do Rayfield (ou simula com table)
local Favorites = {}
local SelectedGun   = "Default"
local SelectedKnife = "Default"

-- ============================================================
-- LISTA DE ARMAS E FACAS
-- (Adapte os nomes conforme os IDs reais do jogo)
-- ============================================================

local Guns = {
    "Default",
    "Revolver",
    "Desert Eagle",
    "AK-47",
    "M4A1",
    "Shotgun",
    "Sniper Rifle",
    "SMG",
    "Minigun",
    "Golden Gun",
    "Laser Pistol",
    "Dual Pistols",
    "Crossbow",
    "Flamethrower",
    "Rocket Launcher",
}

local Knives = {
    "Default",
    "Katana",
    "Butterfly Knife",
    "Machete",
    "Kunai",
    "Dagger",
    "Scythe",
    "Sword",
    "Trident",
    "Ice Knife",
    "Fire Blade",
    "Golden Knife",
    "Neon Blade",
    "Diamond Dagger",
    "Bone Knife",
}

-- ============================================================
-- FUNÇÕES UTILITÁRIAS
-- ============================================================

local function notify(title, content, dur)
    Rayfield:Notify({
        Title    = title,
        Content  = content,
        Duration = dur or 3,
        Image    = 4483362458,
    })
end

-- Aplica arma ao personagem (tenta via RemoteEvent ou substituição direta)
local function applyGun(gunName)
    SelectedGun = gunName
    -- Tenta RemoteEvent comum em jogos MvS
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        or game:GetService("ReplicatedStorage"):FindFirstChild("Events")
    if remotes then
        local evt = remotes:FindFirstChild("ChangeGun")
            or remotes:FindFirstChild("SetGun")
            or remotes:FindFirstChild("GunChange")
        if evt then
            pcall(function() evt:FireServer(gunName) end)
        end
    end
    -- Substitui no backpack se existir
    local char    = LocalPlayer.Character
    local backpack = LocalPlayer.Backpack
    if char or backpack then
        for _, item in ipairs((backpack and backpack:GetChildren() or {})) do
            if item:IsA("Tool") and item.Name:lower():find("gun") or
               item:IsA("Tool") and item.Name:lower():find("pistol") or
               item:IsA("Tool") and item.Name:lower():find("rifle") then
                item.Name = gunName
            end
        end
    end
    notify("🔫 Arma Aplicada", "Arma definida para: " .. gunName)
end

local function applyKnife(knifeName)
    SelectedKnife = knifeName
    local remotes = game:GetService("ReplicatedStorage"):FindFirstChild("Remotes")
        or game:GetService("ReplicatedStorage"):FindFirstChild("Events")
    if remotes then
        local evt = remotes:FindFirstChild("ChangeKnife")
            or remotes:FindFirstChild("SetKnife")
            or remotes:FindFirstChild("KnifeChange")
        if evt then
            pcall(function() evt:FireServer(knifeName) end)
        end
    end
    local backpack = LocalPlayer.Backpack
    if backpack then
        for _, item in ipairs(backpack:GetChildren()) do
            if item:IsA("Tool") and (
               item.Name:lower():find("knife") or
               item.Name:lower():find("blade") or
               item.Name:lower():find("sword")) then
                item.Name = knifeName
            end
        end
    end
    notify("🔪 Faca Aplicada", "Faca definida para: " .. knifeName)
end

local function addFavorite(category, name)
    local key = category .. ":" .. name
    if not Favorites[key] then
        Favorites[key] = { category = category, name = name }
        notify("⭐ Favorito Adicionado", name .. " adicionado aos favoritos!")
        return true
    end
    return false
end

local function removeFavorite(category, name)
    local key = category .. ":" .. name
    if Favorites[key] then
        Favorites[key] = nil
        notify("🗑️ Favorito Removido", name .. " removido dos favoritos.")
        return true
    end
    return false
end

local function isFavorite(category, name)
    return Favorites[category .. ":" .. name] ~= nil
end

-- ============================================================
-- CRIA JANELA RAYFIELD
-- ============================================================

local Window = Rayfield:CreateWindow({
    Name             = "MvS Script  |  by Script Hub",
    Icon             = 0,
    LoadingTitle     = "Murderers vs Sheriffs",
    LoadingSubtitle  = "Carregando recursos...",
    Theme            = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings   = false,

    KeySystem = false,
})

-- ============================================================
-- ABA 1: ARMAS (GUNS)
-- ============================================================

local TabGuns = Window:CreateTab("🔫  Armas", 4483362458)

TabGuns:CreateSection("Selecionar Arma")

-- Dropdown com todas as armas
TabGuns:CreateDropdown({
    Name        = "Escolher Arma",
    Options     = Guns,
    CurrentOption = {"Default"},
    Flag        = "SelectedGun",
    MultipleOptions = false,
    Callback    = function(selected)
        applyGun(selected[1] or selected)
    end,
})

TabGuns:CreateButton({
    Name     = "✅ Aplicar Arma Selecionada",
    Callback = function()
        applyGun(SelectedGun)
    end,
})

TabGuns:CreateSection("Favoritos de Armas")

TabGuns:CreateButton({
    Name     = "⭐ Favoritar Arma Atual",
    Callback = function()
        addFavorite("Gun", SelectedGun)
    end,
})

-- Dropdown dinâmico de favoritos de armas
local favGunOptions = {"(Nenhum favorito ainda)"}
local FavGunDropdown = TabGuns:CreateDropdown({
    Name            = "Favoritos - Armas",
    Options         = favGunOptions,
    CurrentOption   = {favGunOptions[1]},
    Flag            = "FavGun",
    MultipleOptions = false,
    Callback        = function(selected)
        local s = selected[1] or selected
        if s ~= "(Nenhum favorito ainda)" then
            applyGun(s)
        end
    end,
})

TabGuns:CreateButton({
    Name     = "🔄 Atualizar Lista de Favoritos (Armas)",
    Callback = function()
        local list = {}
        for k, v in pairs(Favorites) do
            if v.category == "Gun" then
                table.insert(list, v.name)
            end
        end
        if #list == 0 then list = {"(Nenhum favorito ainda)"} end
        FavGunDropdown:Set(list[1])
        notify("🔄 Atualizado", "Lista de favoritos de armas atualizada!")
    end,
})

TabGuns:CreateButton({
    Name     = "🗑️ Remover Arma dos Favoritos",
    Callback = function()
        removeFavorite("Gun", SelectedGun)
    end,
})

-- ============================================================
-- ABA 2: FACAS (KNIVES)
-- ============================================================

local TabKnives = Window:CreateTab("🔪  Facas", 4483362458)

TabKnives:CreateSection("Selecionar Faca")

TabKnives:CreateDropdown({
    Name        = "Escolher Faca",
    Options     = Knives,
    CurrentOption = {"Default"},
    Flag        = "SelectedKnife",
    MultipleOptions = false,
    Callback    = function(selected)
        applyKnife(selected[1] or selected)
    end,
})

TabKnives:CreateButton({
    Name     = "✅ Aplicar Faca Selecionada",
    Callback = function()
        applyKnife(SelectedKnife)
    end,
})

TabKnives:CreateSection("Favoritos de Facas")

TabKnives:CreateButton({
    Name     = "⭐ Favoritar Faca Atual",
    Callback = function()
        addFavorite("Knife", SelectedKnife)
    end,
})

local favKnifeOptions = {"(Nenhum favorito ainda)"}
local FavKnifeDropdown = TabKnives:CreateDropdown({
    Name            = "Favoritos - Facas",
    Options         = favKnifeOptions,
    CurrentOption   = {favKnifeOptions[1]},
    Flag            = "FavKnife",
    MultipleOptions = false,
    Callback        = function(selected)
        local s = selected[1] or selected
        if s ~= "(Nenhum favorito ainda)" then
            applyKnife(s)
        end
    end,
})

TabKnives:CreateButton({
    Name     = "🔄 Atualizar Lista de Favoritos (Facas)",
    Callback = function()
        local list = {}
        for k, v in pairs(Favorites) do
            if v.category == "Knife" then
                table.insert(list, v.name)
            end
        end
        if #list == 0 then list = {"(Nenhum favorito ainda)"} end
        FavKnifeDropdown:Set(list[1])
        notify("🔄 Atualizado", "Lista de favoritos de facas atualizada!")
    end,
})

TabKnives:CreateButton({
    Name     = "🗑️ Remover Faca dos Favoritos",
    Callback = function()
        removeFavorite("Knife", SelectedKnife)
    end,
})

-- ============================================================
-- ABA 3: BUSCA INTELIGENTE
-- (Usa o SearchBar nativo do Rayfield)
-- ============================================================

local TabSearch = Window:CreateTab("🔍  Busca", 4483362458)

TabSearch:CreateSection("Busca Inteligente de Itens")

-- O Rayfield tem busca nativa no topo da janela ao pressionar Ctrl+F ou no header.
-- Aqui também criamos uma busca manual customizada com Input:

local searchResults = {}

local SearchInput = TabSearch:CreateInput({
    Name        = "🔍 Buscar Arma ou Faca",
    PlaceholderText = "Digite o nome (ex: Katana, AK-47...)",
    RemoveTextAfterFocusLost = false,
    Flag        = "SearchQuery",
    Callback    = function(text)
        searchResults = {}
        local query = text:lower()

        -- Busca em armas
        for _, gun in ipairs(Guns) do
            if gun:lower():find(query) then
                table.insert(searchResults, {type="Gun", name=gun})
            end
        end
        -- Busca em facas
        for _, knife in ipairs(Knives) do
            if knife:lower():find(query) then
                table.insert(searchResults, {type="Knife", name=knife})
            end
        end

        if #searchResults == 0 then
            notify("🔍 Busca", "Nenhum resultado para: " .. text, 2)
        else
            local msg = ""
            for _, r in ipairs(searchResults) do
                msg = msg .. "[" .. r.type .. "] " .. r.name .. "\n"
            end
            notify("🔍 " .. #searchResults .. " Resultado(s)", msg, 5)
        end
    end,
})

TabSearch:CreateSection("Aplicar Resultado da Busca")

TabSearch:CreateButton({
    Name     = "✅ Aplicar 1º Resultado da Busca",
    Callback = function()
        if #searchResults > 0 then
            local r = searchResults[1]
            if r.type == "Gun" then
                applyGun(r.name)
            else
                applyKnife(r.name)
            end
        else
            notify("⚠️ Aviso", "Faça uma busca primeiro!", 2)
        end
    end,
})

TabSearch:CreateButton({
    Name     = "⭐ Favoritar 1º Resultado da Busca",
    Callback = function()
        if #searchResults > 0 then
            local r = searchResults[1]
            addFavorite(r.type, r.name)
        else
            notify("⚠️ Aviso", "Faça uma busca primeiro!", 2)
        end
    end,
})

TabSearch:CreateSection("Busca Rápida por Categoria")

TabSearch:CreateDropdown({
    Name        = "Filtrar por Categoria",
    Options     = {"Tudo", "Apenas Armas", "Apenas Facas"},
    CurrentOption = {"Tudo"},
    Flag        = "SearchCategory",
    MultipleOptions = false,
    Callback    = function(selected)
        notify("📂 Filtro", "Filtro definido: " .. (selected[1] or selected), 2)
    end,
})

-- ============================================================
-- ABA 4: CONFIGURAÇÕES
-- ============================================================

local TabConfig = Window:CreateTab("⚙️  Config", 4483362458)

TabConfig:CreateSection("Auto-Aplicar ao Respawn")

local autoApply = false

TabConfig:CreateToggle({
    Name    = "Auto-aplicar Arma/Faca ao Respawn",
    CurrentValue = false,
    Flag    = "AutoApply",
    Callback = function(val)
        autoApply = val
        if val then
            notify("♻️ Auto-Apply", "Será aplicado automaticamente ao respawnar!", 3)
        end
    end,
})

-- Conexão de respawn
LocalPlayer.CharacterAdded:Connect(function()
    if autoApply then
        task.wait(2) -- espera o personagem carregar
        if SelectedGun ~= "Default" then applyGun(SelectedGun) end
        if SelectedKnife ~= "Default" then applyKnife(SelectedKnife) end
    end
end)

TabConfig:CreateSection("Informações")

TabConfig:CreateLabel("Script: MvS Rayfield v1.0")
TabConfig:CreateLabel("Use Ctrl+F para busca nativa do Rayfield")
TabConfig:CreateLabel("Os favoritos ficam salvos na sessão atual")

TabConfig:CreateSection("Sobre o Script")

TabConfig:CreateParagraph({
    Title   = "Como Usar",
    Content = "1. Vá na aba Armas ou Facas\n2. Escolha pelo dropdown\n3. Clique em Aplicar\n4. Use ⭐ para favoritar\n5. Use a aba Busca para encontrar rápido\n6. Ative Auto-Apply para respawn automático",
})

-- ============================================================
-- RAYFIELD SAVE MANAGER & THEME (opcional mas recomendado)
-- ============================================================

local SaveManager  = loadstring(game:HttpGet('https://raw.githubusercontent.com/ocram02/srius-ports/refs/heads/main/Addons/SaveManager.lua'))()
local InterfaceManager = loadstring(game:HttpGet('https://raw.githubusercontent.com/ocram02/srius-ports/refs/heads/main/Addons/InterfaceManager.lua'))()

SaveManager:SetRayfield(Rayfield)
SaveManager:SetFolder("MvS_RayfieldScript")
InterfaceManager:SetRayfield(Rayfield)
InterfaceManager:BuildInterfaceSection(TabConfig)
SaveManager:BuildConfigSection(TabConfig)

SaveManager:LoadAutoloadConfig()

-- ============================================================
-- NOTIFICAÇÃO DE BOAS-VINDAS
-- ============================================================

task.wait(1)
notify(
    "✅ MvS Script Carregado!",
    "Troca de Arma/Faca, Favoritos e Busca Inteligente prontos!",
    5
)
