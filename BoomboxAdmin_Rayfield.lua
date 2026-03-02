-- ╔══════════════════════════════════════════════════════╗
-- ║        BOOMBOX ADMIN - HD Admin Playground           ║
-- ║            Interface por Rayfield UI                 ║
-- ╚══════════════════════════════════════════════════════╝

local RayfieldLoader = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- ════════════════════════════════════
--           CONFIGURAÇÕES
-- ════════════════════════════════════

local Window = RayfieldLoader:CreateWindow({
    Name = "🎵 Boombox Admin",
    LoadingTitle = "Boombox Admin",
    LoadingSubtitle = "HD Admin Playground",
    Theme = "Default",
    DisableRayfieldPrompts = false,
    DisableBuildWarnings = false,
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "BoomboxAdmin",
        FileName = "Config"
    },
    KeySystem = false,
})

-- ════════════════════════════════════
--           VARIÁVEIS
-- ════════════════════════════════════

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

-- Lista de Boomboxes disponíveis (IDs de Asset do Roblox)
local BoomboxList = {
    ["Boombox Clássico"]   = 1372749740,
    ["Boombox Dourado"]    = 1567446678,
    ["Boombox Neon"]       = 2504691897,
    ["Boombox Retro"]      = 1567450439,
    ["Boombox DJ"]         = 6898721803,
    ["Boombox Pixel"]      = 2504706003,
    ["Boombox Chamas"]     = 3016522381,
    ["Boombox Galáctico"]  = 3016529854,
}

local BoomboxNames = {}
for name, _ in pairs(BoomboxList) do
    table.insert(BoomboxNames, name)
end
table.sort(BoomboxNames)

local currentVolume    = 0.5
local currentSongID    = ""
local currentBoombox   = nil
local boomboxEnabled   = false

-- ════════════════════════════════════
--           FUNÇÕES UTILITÁRIAS
-- ════════════════════════════════════

local function GetBoombox()
    if Character then
        for _, tool in ipairs(Character:GetChildren()) do
            if tool:IsA("Tool") and tool:FindFirstChildWhichIsA("Sound") then
                return tool
            end
        end
    end
    for _, tool in ipairs(LocalPlayer.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChildWhichIsA("Sound") then
            return tool
        end
    end
    return nil
end

local function GetBoomboxSound()
    local boombox = GetBoombox()
    if boombox then
        return boombox:FindFirstChildWhichIsA("Sound")
    end
    return nil
end

local function Notify(title, content, duration)
    RayfieldLoader:Notify({
        Title   = title,
        Content = content,
        Duration = duration or 3,
        Image   = 4483362458,
        Actions = {},
    })
end

local function ApplyVolume(vol)
    local sound = GetBoomboxSound()
    if sound then
        sound.Volume = vol
        Notify("🔊 Volume", "Volume ajustado para: " .. math.floor(vol * 100) .. "%", 2)
    else
        Notify("⚠️ Aviso", "Nenhuma Boombox encontrada equipada!", 3)
    end
end

local function PlaySong(songId)
    local sound = GetBoomboxSound()
    if sound then
        sound.SoundId = "rbxassetid://" .. tostring(songId)
        sound:Play()
        Notify("🎵 Música", "Tocando ID: " .. tostring(songId), 3)
    else
        Notify("⚠️ Aviso", "Equipe uma Boombox primeiro!", 3)
    end
end

local function StopSong()
    local sound = GetBoomboxSound()
    if sound then
        sound:Stop()
        Notify("⏹️ Parado", "Música pausada.", 2)
    end
end

local function EquipBoombox(assetId)
    -- Tenta dar o gear via HD Admin (se tiver permissão) ou insere diretamente
    local tool = game:GetObjects("rbxassetid://" .. tostring(assetId))
    if tool and tool[1] then
        tool[1].Parent = LocalPlayer.Backpack
        wait(0.3)
        -- Auto-equipa
        LocalPlayer.Character.Humanoid:EquipTool(tool[1])
        Notify("🎒 Boombox", "Boombox equipada com sucesso!", 3)
    else
        Notify("❌ Erro", "Não foi possível carregar esta Boombox.", 3)
    end
end

-- ════════════════════════════════════
--           ABAS DA UI
-- ════════════════════════════════════

-- ─── ABA: MÚSICA ───
local MusicTab = Window:CreateTab("🎵 Música", 4483362458)

MusicTab:CreateSection("Controle de Música")

MusicTab:CreateInput({
    Name        = "ID da Música",
    Placeholder = "Ex: 142376088",
    RemoveOnFocus = false,
    Callback = function(value)
        currentSongID = value
    end,
})

MusicTab:CreateButton({
    Name     = "▶️  Tocar Música",
    Callback = function()
        if currentSongID ~= "" then
            PlaySong(currentSongID)
        else
            Notify("⚠️ Aviso", "Insira um ID de música válido!", 3)
        end
    end,
})

MusicTab:CreateButton({
    Name     = "⏹️  Parar Música",
    Callback = function()
        StopSong()
    end,
})

MusicTab:CreateSection("Volume")

MusicTab:CreateSlider({
    Name    = "Volume da Boombox",
    Range   = {0, 100},
    Increment = 1,
    Suffix  = "%",
    CurrentValue = 50,
    Flag    = "VolumeSlider",
    Callback = function(value)
        currentVolume = value / 100
        ApplyVolume(currentVolume)
    end,
})

MusicTab:CreateButton({
    Name     = "🔇  Mutar Boombox",
    Callback = function()
        local sound = GetBoomboxSound()
        if sound then
            sound.Volume = 0
            Notify("🔇 Mutado", "Boombox mutada.", 2)
        end
    end,
})

MusicTab:CreateButton({
    Name     = "🔊  Desmutar Boombox",
    Callback = function()
        ApplyVolume(currentVolume)
    end,
})

-- ─── ABA: BOOMBOX ───
local BoomboxTab = Window:CreateTab("🎒 Boombox", 4483362458)

BoomboxTab:CreateSection("Trocar Boombox")

BoomboxTab:CreateDropdown({
    Name    = "Selecionar Boombox",
    Options = BoomboxNames,
    CurrentOption = BoomboxNames[1],
    Flag    = "BoomboxDropdown",
    Callback = function(option)
        local assetId = BoomboxList[option]
        if assetId then
            Notify("📦 Carregando", "Equipando: " .. option, 2)
            EquipBoombox(assetId)
        end
    end,
})

BoomboxTab:CreateSection("ID Personalizado")

local customBoomboxID = ""
BoomboxTab:CreateInput({
    Name        = "ID de Asset Personalizado",
    Placeholder = "Ex: 1372749740",
    RemoveOnFocus = false,
    Callback = function(value)
        customBoomboxID = value
    end,
})

BoomboxTab:CreateButton({
    Name     = "🔄  Equipar Boombox Personalizada",
    Callback = function()
        if customBoomboxID ~= "" then
            Notify("📦 Carregando", "Equipando asset: " .. customBoomboxID, 2)
            EquipBoombox(customBoomboxID)
        else
            Notify("⚠️ Aviso", "Insira um ID de asset válido!", 3)
        end
    end,
})

BoomboxTab:CreateSection("Gerenciar")

BoomboxTab:CreateButton({
    Name     = "🗑️  Remover Boombox Atual",
    Callback = function()
        local boombox = GetBoombox()
        if boombox then
            boombox:Destroy()
            Notify("🗑️ Removida", "Boombox removida.", 2)
        else
            Notify("⚠️ Aviso", "Nenhuma Boombox encontrada.", 3)
        end
    end,
})

-- ─── ABA: EFEITOS ───
local FXTab = Window:CreateTab("✨ Efeitos", 4483362458)

FXTab:CreateSection("Efeitos de Pitch")

FXTab:CreateSlider({
    Name     = "Pitch da Música",
    Range    = {10, 300},
    Increment = 5,
    Suffix   = "%",
    CurrentValue = 100,
    Flag     = "PitchSlider",
    Callback = function(value)
        local sound = GetBoomboxSound()
        if sound then
            -- Aplica EqualizerSoundEffect ou PitchShiftSoundEffect se disponível
            local pitch = sound:FindFirstChildOfClass("PitchShiftSoundEffect")
            if not pitch then
                pitch = Instance.new("PitchShiftSoundEffect")
                pitch.Parent = sound
            end
            pitch.Octave = value / 100
            Notify("🎚️ Pitch", "Pitch: " .. value .. "%", 2)
        end
    end,
})

FxToggle = false
FXTab:CreateToggle({
    Name   = "🔁 Loop de Música",
    CurrentValue = false,
    Flag   = "LoopToggle",
    Callback = function(value)
        local sound = GetBoomboxSound()
        if sound then
            sound.Looped = value
            Notify("🔁 Loop", value and "Loop ativado!" or "Loop desativado.", 2)
        end
    end,
})

FXTab:CreateToggle({
    Name   = "🌊 Reverb",
    CurrentValue = false,
    Flag   = "ReverbToggle",
    Callback = function(value)
        local sound = GetBoomboxSound()
        if sound then
            local reverb = sound:FindFirstChildOfClass("ReverbSoundEffect")
            if value then
                if not reverb then
                    reverb = Instance.new("ReverbSoundEffect")
                    reverb.WetLevel  = -1
                    reverb.DryLevel  = 0
                    reverb.DecayTime = 1.5
                    reverb.Parent    = sound
                end
            else
                if reverb then reverb:Destroy() end
            end
            Notify("🌊 Reverb", value and "Reverb ativado!" or "Reverb removido.", 2)
        end
    end,
})

FXTab:CreateToggle({
    Name   = "⚡ Distorção",
    CurrentValue = false,
    Flag   = "DistortToggle",
    Callback = function(value)
        local sound = GetBoomboxSound()
        if sound then
            local dist = sound:FindFirstChildOfClass("DistortionSoundEffect")
            if value then
                if not dist then
                    dist = Instance.new("DistortionSoundEffect")
                    dist.Level  = 0.6
                    dist.Parent = sound
                end
            else
                if dist then dist:Destroy() end
            end
            Notify("⚡ Distorção", value and "Distorção ativada!" or "Distorção removida.", 2)
        end
    end,
})

-- ─── ABA: INFO ───
local InfoTab = Window:CreateTab("ℹ️ Info", 4483362458)

InfoTab:CreateSection("Status Atual")

InfoTab:CreateButton({
    Name     = "📊  Ver Info da Boombox",
    Callback = function()
        local sound = GetBoomboxSound()
        if sound then
            local info = string.format(
                "SoundID: %s\nVolume: %.0f%%\nTocando: %s\nLoop: %s",
                tostring(sound.SoundId),
                sound.Volume * 100,
                tostring(sound.IsPlaying),
                tostring(sound.Looped)
            )
            Notify("📊 Boombox Info", info, 6)
        else
            Notify("⚠️ Aviso", "Nenhuma Boombox equipada!", 3)
        end
    end,
})

InfoTab:CreateSection("Sobre")

InfoTab:CreateLabel("Boombox Admin v1.0")
InfoTab:CreateLabel("Feito para HD Admin Playground")
InfoTab:CreateLabel("Interface: Rayfield UI")

-- ════════════════════════════════════
--     INICIALIZAÇÃO
-- ════════════════════════════════════

RayfieldLoader:LoadConfiguration()

Notify("✅ Carregado", "Boombox Admin pronto! Equipe uma Boombox para começar.", 4)
