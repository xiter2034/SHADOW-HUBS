-- =============================================
--  SHADOW HUB - AutoFarm Script
--  Blox Fruits | Roblox
--  Compatível: World 1, 2 e 3
-- =============================================

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- =============================================
--  Configurações Globais
-- =============================================

local CONFIG = {
    DEBUG          = true,
    FARM_DELAY     = 0.1,
    TELEPORT_RANGE = 10000,
}

-- =============================================
--  Estado Global
-- =============================================

_G.AutoFarm          = false
_G.AutoQuest         = true
_G.AutoTeleport      = true
_G.AutoAttack        = true
_G.AutoLevelUp       = true
_G.AutoPortal        = false
_G.AutoFarmState     = { active = false, currentQuest = nil }

-- =============================================
--  Logger
-- =============================================

local Logger = {}
local LogCallback = nil -- será conectado à UI

function Logger.info(msg)
    if CONFIG.DEBUG then
        print(string.format("[SHADOW HUB] [INFO] %s", msg))
    end
    if LogCallback then LogCallback("INFO", msg) end
end

function Logger.warn(msg)
    warn(string.format("[SHADOW HUB] [WARN] %s", msg))
    if LogCallback then LogCallback("WARN", msg) end
end

function Logger.error(msg)
    warn(string.format("[SHADOW HUB] [ERROR] %s", msg))
    if LogCallback then LogCallback("ERROR", msg) end
end

function Logger.ok(msg)
    if CONFIG.DEBUG then
        print(string.format("[SHADOW HUB] [OK] %s", msg))
    end
    if LogCallback then LogCallback("OK", msg) end
end

-- =============================================
--  Detecção de Mundo
-- =============================================

local WORLD_IDS = {
    [2753915549] = 1,
    [4442272183] = 2,
    [7449423635] = 3,
}

local currentWorld = WORLD_IDS[game.PlaceId] or 1

Logger.info("Mundo detectado: " .. currentWorld)

-- =============================================
--  Estrutura de Quest
-- =============================================

local function Quest(minLevel, maxLevel, monsterKey, levelQuest, questName, monsterName, questCFrame, monsterCFrame, entrance)
    return {
        minLevel      = minLevel,
        maxLevel      = maxLevel,
        monsterKey    = monsterKey,
        levelQuest    = levelQuest,
        questName     = questName,
        monsterName   = monsterName,
        questCFrame   = questCFrame,
        monsterCFrame = monsterCFrame,
        entrance      = entrance,
    }
end

-- =============================================
--  Dados de Quests
-- =============================================

local QUEST_DATA = {
    [1] = {
        Quest(1,   9,   "Bandit",              1, "BanditQuest1",    "Bandit",
            CFrame.new(1059.37195, 15.4495068, 1550.4231, 0.939700544, 0, -0.341998369, 0, 1, 0, 0.341998369, 0, 0.939700544),
            CFrame.new(1045.962646, 27.002508, 1560.820312)),
        Quest(10,  14,  "Monkey",              1, "JungleQuest",     "Monkey",
            CFrame.new(-1598.08911, 35.5501175, 153.377838, 0, 0, 1, 0, 1, 0, -1, 0, 0),
            CFrame.new(-1448.518066, 67.853012, 11.465796)),
        Quest(15,  29,  "Gorilla",             2, "JungleQuest",     "Gorilla",
            CFrame.new(-1598.08911, 35.5501175, 153.377838, 0, 0, 1, 0, 1, 0, -1, 0, 0),
            CFrame.new(-1129.883666, 40.463546, -525.423706)),
        Quest(30,  39,  "Pirate",              1, "BuggyQuest1",     "Pirate",
            CFrame.new(-1141.07483, 4.10001802, 3831.5498, 0.965929627, 0, -0.258804798, 0, 1, 0, 0.258804798, 0, 0.965929627),
            CFrame.new(-1103.513427, 13.752052, 3896.091064)),
        Quest(40,  59,  "Brute",               2, "BuggyQuest1",     "Brute",
            CFrame.new(-1141.07483, 4.10001802, 3831.5498, 0.965929627, 0, -0.258804798, 0, 1, 0, 0.258804798, 0, 0.965929627),
            CFrame.new(-1140.083740, 14.809885, 4322.921386)),
        Quest(60,  74,  "Desert Bandit",       1, "DesertQuest",     "Desert Bandit",
            CFrame.new(894.488647, 5.14000702, 4392.43359, 0.819155693, 0, -0.573571265, 0, 1, 0, 0.573571265, 0, 0.819155693),
            CFrame.new(924.799804, 6.448674, 4481.585937)),
        Quest(75,  89,  "Desert Officer",      2, "DesertQuest",     "Desert Officer",
            CFrame.new(894.488647, 5.14000702, 4392.43359, 0.819155693, 0, -0.573571265, 0, 1, 0, 0.573571265, 0, 0.819155693),
            CFrame.new(1608.282226, 8.614224, 4371.007324)),
        Quest(90,  99,  "Snow Bandit",         1, "SnowQuest",       "Snow Bandit",
            CFrame.new(1389.74451, 88.1519318, -1298.90796, -0.342042685, 0, 0.939684391, 0, 1, 0, -0.939684391, 0, -0.342042685),
            CFrame.new(1354.347900, 87.272773, -1393.946533)),
        Quest(100, 119, "Snowman",             2, "SnowQuest",       "Snowman",
            CFrame.new(1389.74451, 88.1519318, -1298.90796, -0.342042685, 0, 0.939684391, 0, 1, 0, -0.939684391, 0, -0.342042685),
            CFrame.new(1201.641235, 144.579589, -1550.067016)),
        Quest(120, 149, "Chief Petty Officer", 1, "MarineQuest2",    "Chief Petty Officer",
            CFrame.new(-5039.58643, 27.3500385, 4324.68018, 0, 0, -1, 0, 1, 0, 1, 0, 0),
            CFrame.new(-4881.230957, 22.652044, 4273.752441)),
        Quest(150, 174, "Sky Bandit",          1, "SkyQuest",        "Sky Bandit",
            CFrame.new(-4839.53027, 716.368591, -2619.44165, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268),
            CFrame.new(-4953.207031, 295.744201, -2899.229003)),
        Quest(175, 189, "Dark Master",         2, "SkyQuest",        "Dark Master",
            CFrame.new(-4839.53027, 716.368591, -2619.44165, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268),
            CFrame.new(-5259.844726, 391.397674, -2229.035400)),
        Quest(190, 209, "Prisoner",            1, "PrisonerQuest",   "Prisoner",
            CFrame.new(5308.93115, 1.65517521, 475.120514, -0.0894274712, 0, -0.995993316, 0, 1, 0, 0.995993316, 0, -0.0894274712),
            CFrame.new(5098.973632, -0.320405, 474.237335)),
        Quest(210, 249, "Dangerous Prisoner",  2, "PrisonerQuest",   "Dangerous Prisoner",
            CFrame.new(5308.93115, 1.65517521, 475.120514, -0.0894274712, 0, -0.995993316, 0, 1, 0, 0.995993316, 0, -0.0894274712),
            CFrame.new(5654.563476, 15.633401, 866.299194)),
        Quest(250, 274, "Toga Warrior",        1, "ColosseumQuest",  "Toga Warrior",
            CFrame.new(-1580.04663, 6.35000277, -2986.47534, -0.515037298, 0, -0.857167721, 0, 1, 0, 0.857167721, 0, -0.515037298),
            CFrame.new(-1820.214843, 51.683856, -2740.665039)),
        Quest(275, 299, "Gladiator",           2, "ColosseumQuest",  "Gladiator",
            CFrame.new(-1580.04663, 6.35000277, -2986.47534, -0.515037298, 0, -0.857167721, 0, 1, 0, 0.857167721, 0, -0.515037298),
            CFrame.new(-1292.838134, 56.380882, -3339.031494)),
        Quest(300, 324, "Military Soldier",    1, "MagmaQuest",      "Military Soldier",
            CFrame.new(-5313.37012, 10.9500084, 8515.29395, -0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, -0.499959469),
            CFrame.new(-5411.164550, 11.081554, 8454.292968)),
        Quest(325, 374, "Military Spy",        2, "MagmaQuest",      "Military Spy",
            CFrame.new(-5313.37012, 10.9500084, 8515.29395, -0.499959469, 0, 0.866048813, 0, 1, 0, -0.866048813, 0, -0.499959469),
            CFrame.new(-5802.868164, 86.262413, 8828.859375)),
        Quest(375, 399, "Fishman Warrior",     1, "FishmanQuest",    "Fishman Warrior",
            CFrame.new(61122.65234375, 18.497442, 1569.399780),
            CFrame.new(60878.300781, 18.482830, 1543.757446),
            Vector3.new(61163.8515625, 11.6796875, 1819.7841796875)),
        Quest(400, 449, "Fishman Commando",    2, "FishmanQuest",    "Fishman Commando",
            CFrame.new(61122.65234375, 18.497442, 1569.399780),
            CFrame.new(61922.632812, 18.482830, 1493.934326),
            Vector3.new(61163.8515625, 11.6796875, 1819.7841796875)),
        Quest(450, 474, "God's Guard",         1, "SkyExp1Quest",    "God's Guard",
            CFrame.new(-4721.88867, 843.874695, -1949.96643, 0.996191859, 0, -0.0871884301, 0, 1, 0, 0.0871884301, 0, 0.996191859),
            CFrame.new(-4710.042968, 845.276977, -1927.307983),
            Vector3.new(-4607.82275, 872.54248, -1667.55688)),
        Quest(475, 524, "Shanda",              2, "SkyExp1Quest",    "Shanda",
            CFrame.new(-7859.09814, 5544.19043, -381.476196, -0.422592998, 0, 0.906319618, 0, 1, 0, -0.906319618, 0, -0.422592998),
            CFrame.new(-7678.489746, 5566.403808, -497.215606),
            Vector3.new(-7894.6176757813, 5547.1416015625, -380.29119873047)),
        Quest(525, 549, "Royal Squad",         1, "SkyExp2Quest",    "Royal Squad",
            CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0),
            CFrame.new(-7624.252441, 5658.133300, -1467.354248)),
        Quest(550, 624, "Royal Soldier",       2, "SkyExp2Quest",    "Royal Soldier",
            CFrame.new(-7906.81592, 5634.6626, -1411.99194, 0, 0, -1, 0, 1, 0, 1, 0, 0),
            CFrame.new(-7836.753417, 5645.664062, -1790.623657)),
        Quest(625, 649, "Galley Pirate",       1, "FountainQuest",   "Galley Pirate",
            CFrame.new(5259.81982, 37.3500175, 4050.0293, 0.087131381, 0, 0.996196866, 0, 1, 0, -0.996196866, 0, 0.087131381),
            CFrame.new(5551.021972, 78.901351, 3930.412841)),
        Quest(650, math.huge, "Galley Captain",2, "FountainQuest",   "Galley Captain",
            CFrame.new(5259.81982, 37.3500175, 4050.0293, 0.087131381, 0, 0.996196866, 0, 1, 0, -0.996196866, 0, 0.087131381),
            CFrame.new(5441.951660, 42.502059, 4950.09375)),
    },
    [2] = {
        Quest(700,  724,  "Raider",            1, "Area1Quest",        "Raider",
            CFrame.new(-429.543518, 71.7699966, 1836.18188, -0.22495985, 0, -0.974368095, 0, 1, 0, 0.974368095, 0, -0.22495985),
            CFrame.new(-728.326721, 52.779319, 2345.770507)),
        Quest(725,  774,  "Mercenary",         2, "Area1Quest",        "Mercenary",
            CFrame.new(-429.543518, 71.7699966, 1836.18188, -0.22495985, 0, -0.974368095, 0, 1, 0, 0.974368095, 0, -0.22495985),
            CFrame.new(-1004.324401, 80.158866, 1424.619384)),
        Quest(775,  799,  "Swan Pirate",       1, "Area2Quest",        "Swan Pirate",
            CFrame.new(638.43811, 71.769989, 918.282898, 0.139203906, 0, 0.99026376, 0, 1, 0, -0.99026376, 0, 0.139203906),
            CFrame.new(1068.664306, 137.614288, 1322.106079)),
        Quest(800,  874,  "Factory Staff",     2, "Area2Quest",        "Factory Staff",
            CFrame.new(632.698608, 73.1055908, 918.666321, -0.0319722369, 0, -0.999488771, 0, 1, 0, 0.999488771, 0, -0.0319722369),
            CFrame.new(73.078674, 81.863441, -27.470672)),
        Quest(875,  899,  "Marine Lieutenant", 1, "MarineQuest3",      "Marine Lieutenant",
            CFrame.new(-2440.79639, 71.7140732, -3216.06812, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268),
            CFrame.new(-2821.372314, 75.897277, -3070.089111)),
        Quest(900,  949,  "Marine Captain",    2, "MarineQuest3",      "Marine Captain",
            CFrame.new(-2440.79639, 71.7140732, -3216.06812, 0.866007268, 0, 0.500031412, 0, 1, 0, -0.500031412, 0, 0.866007268),
            CFrame.new(-1861.231079, 80.176582, -3254.697509)),
        Quest(950,  974,  "Zombie",            1, "ZombieQuest",       "Zombie",
            CFrame.new(-5497.06152, 47.5923004, -795.237061, -0.29242146, 0, -0.95628953, 0, 1, 0, 0.95628953, 0, -0.29242146),
            CFrame.new(-5657.776855, 78.969734, -928.687011)),
        Quest(975,  999,  "Vampire",           2, "ZombieQuest",       "Vampire",
            CFrame.new(-5497.06152, 47.5923004, -795.237061, -0.29242146, 0, -0.95628953, 0, 1, 0, 0.95628953, 0, -0.29242146),
            CFrame.new(-6037.667968, 32.184638, -1340.659790)),
        Quest(1000, 1049, "Snow Trooper",      1, "SnowMountainQuest", "Snow Trooper",
            CFrame.new(609.858826, 400.119904, -5372.25928, -0.374604106, 0, 0.92718488, 0, 1, 0, -0.92718488, 0, -0.374604106),
            CFrame.new(549.147338, 427.387054, -5563.698730)),
        Quest(1050, 1099, "Winter Warrior",    2, "SnowMountainQuest", "Winter Warrior",
            CFrame.new(609.858826, 400.119904, -5372.25928, -0.374604106, 0, 0.92718488, 0, 1, 0, -0.92718488, 0, -0.374604106),
            CFrame.new(1142.745117, 475.639801, -5199.416503)),
        Quest(1100, 1124, "Lab Subordinate",   1, "IceSideQuest",      "Lab Subordinate",
            CFrame.new(-6064.06885, 15.2422857, -4902.97852, 0.453972578, 0, -0.891015649, 0, 1, 0, 0.891015649, 0, 0.453972578),
            CFrame.new(-5707.471679, 15.951709, -4513.392089)),
        Quest(1125, 1174, "Horned Warrior",    2, "IceSideQuest",      "Horned Warrior",
            CFrame.new(-6064.06885, 15.2422857, -4902.97852, 0.453972578, 0, -0.891015649, 0, 1, 0, 0.891015649, 0, 0.453972578),
            CFrame.new(-6341.366699, 15.951770, -5723.162109)),
        Quest(1175, 1199, "Magma Ninja",       1, "FireSideQuest",     "Magma Ninja",
            CFrame.new(-5428.03174, 15.0622921, -5299.43457, -0.882952213, 0, 0.469463557, 0, 1, 0, -0.469463557, 0, -0.882952213),
            CFrame.new(-5449.672851, 76.658744, -5808.200683)),
        Quest(1200, 1249, "Lava Pirate",       2, "FireSideQuest",     "Lava Pirate",
            CFrame.new(-5428.03174, 15.0622921, -5299.43457, -0.882952213, 0, 0.469463557, 0, 1, 0, -0.469463557, 0, -0.882952213),
            CFrame.new(-5213.331542, 49.737880, -4701.451171)),
        Quest(1250, 1274, "Ship Deckhand",     1, "ShipQuest1",        "Ship Deckhand",
            CFrame.new(1037.80127, 125.092171, 32911.6016),
            CFrame.new(1212.011108, 150.792053, 33059.246093),
            Vector3.new(923.21252441406, 126.9760055542, 32852.83203125)),
        Quest(1275, 1299, "Ship Engineer",     2, "ShipQuest1",        "Ship Engineer",
            CFrame.new(1037.80127, 125.092171, 32911.6016),
            CFrame.new(919.478637, 43.544013, 32779.96875),
            Vector3.new(923.21252441406, 126.9760055542, 32852.83203125)),
    },
    [3] = {
        -- Third Sea: adicione quests aqui
    },
}

-- =============================================
--  Helpers
-- =============================================

local function getCharacter()
    local char = LocalPlayer.Character
    if not char then return nil, nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil, nil end
    return char, hrp
end

local function getPlayerLevel()
    local data = LocalPlayer:FindFirstChild("Data")
    if not data then return nil end
    local levelVal = data:FindFirstChild("Level")
    if not levelVal then return nil end
    return levelVal.Value
end

local function requestEntranceIfNeeded(questCFrame, entrance)
    if not entrance then return end
    local _, hrp = getCharacter()
    if not hrp then return end
    local dist = (questCFrame.Position - hrp.Position).Magnitude
    if dist > CONFIG.TELEPORT_RANGE then
        pcall(function()
            ReplicatedStorage.Remotes.CommF_:InvokeServer("requestEntrance", entrance)
        end)
    end
end

local function findQuestByLevel(quests, level)
    local lo, hi = 1, #quests
    while lo <= hi do
        local mid = math.floor((lo + hi) / 2)
        local q = quests[mid]
        if level < q.minLevel then
            hi = mid - 1
        elseif level > q.maxLevel then
            lo = mid + 1
        else
            return q
        end
    end
    return nil
end

-- =============================================
--  CheckQuest
-- =============================================

function CheckQuest()
    local level = getPlayerLevel()
    if not level then return end

    local worldQuests = QUEST_DATA[currentWorld]
    if not worldQuests or #worldQuests == 0 then
        Logger.warn("Nenhuma quest para o mundo " .. currentWorld)
        return
    end

    local quest = findQuestByLevel(worldQuests, level)
    if not quest then
        Logger.warn("Nenhuma quest para nivel " .. level)
        return
    end

    if _G.AutoFarmState.currentQuest == quest.questName then return end
    _G.AutoFarmState.currentQuest = quest.questName

    Mon         = quest.monsterKey
    LevelQuest  = quest.levelQuest
    NameQuest   = quest.questName
    NameMon     = quest.monsterName
    CFrameQuest = quest.questCFrame
    CFrameMon   = quest.monsterCFrame

    Logger.info(string.format("Quest: [%d-%d] %s | %s", quest.minLevel, quest.maxLevel, quest.monsterName, quest.questName))

    if _G.AutoFarm then
        requestEntranceIfNeeded(quest.questCFrame, quest.entrance)
    end
end

-- =============================================
--  Loop Heartbeat
-- =============================================

local lastLevel = nil
RunService.Heartbeat:Connect(function()
    if not _G.AutoFarm then return end
    local level = getPlayerLevel()
    if level and level ~= lastLevel then
        lastLevel = level
        CheckQuest()
    end
end)

-- =============================================
--  UI - SHADOW HUB
-- =============================================

-- Remove UI antiga se existir
if CoreGui:FindFirstChild("ShadowHub") then
    CoreGui:FindFirstChild("ShadowHub"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ShadowHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = CoreGui

-- =============================================
--  Cores e Estilo
-- =============================================

local C = {
    bg         = Color3.fromRGB(10,  12,  16),
    panel      = Color3.fromRGB(15,  19,  24),
    border     = Color3.fromRGB(30,  37,  48),
    accent     = Color3.fromRGB(0,   212, 255),
    accent2    = Color3.fromRGB(124, 58,  237),
    green      = Color3.fromRGB(0,   255, 136),
    red        = Color3.fromRGB(255, 59,  92),
    yellow     = Color3.fromRGB(255, 193, 7),
    text       = Color3.fromRGB(200, 214, 232),
    muted      = Color3.fromRGB(74,  85,  104),
    white      = Color3.fromRGB(255, 255, 255),
    transparent = Color3.fromRGB(0,  0,   0),
}

-- =============================================
--  Utilidades de criação
-- =============================================

local function make(cls, props, parent)
    local obj = Instance.new(cls)
    for k, v in pairs(props) do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

local function makeFrame(props, parent)
    props.BackgroundColor3 = props.BackgroundColor3 or C.transparent
    props.BorderSizePixel  = props.BorderSizePixel  or 0
    return make("Frame", props, parent)
end

local function makeLabel(props, parent)
    props.BackgroundTransparency = 1
    props.TextColor3  = props.TextColor3 or C.text
    props.Font        = props.Font or Enum.Font.GothamBold
    props.TextSize    = props.TextSize or 13
    props.RichText    = true
    return make("TextLabel", props, parent)
end

local function makeButton(props, parent)
    props.BackgroundColor3   = props.BackgroundColor3 or C.border
    props.BorderSizePixel    = 0
    props.Font               = props.Font or Enum.Font.GothamBold
    props.TextColor3         = props.TextColor3 or C.text
    props.TextSize           = props.TextSize or 13
    props.AutoButtonColor    = false
    return make("TextButton", props, parent)
end

local function corner(r, parent)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = parent
    return c
end

local function stroke(color, thick, parent)
    local s = Instance.new("UIStroke")
    s.Color     = color or C.border
    s.Thickness = thick or 1
    s.Parent    = parent
    return s
end

local function padding(t, b, l, r, parent)
    local p = Instance.new("UIPadding")
    p.PaddingTop    = UDim.new(0, t or 0)
    p.PaddingBottom = UDim.new(0, b or 0)
    p.PaddingLeft   = UDim.new(0, l or 0)
    p.PaddingRight  = UDim.new(0, r or 0)
    p.Parent = parent
    return p
end

-- =============================================
--  Janela Principal
-- =============================================

local Main = makeFrame({
    Size            = UDim2.new(0, 480, 0, 400),
    Position        = UDim2.new(0.5, -240, 0.5, -200),
    BackgroundColor3 = C.bg,
    ClipsDescendants = true,
}, ScreenGui)
corner(10, Main)
stroke(C.border, 1, Main)

-- Linha topo colorida
local TopLine = makeFrame({
    Size            = UDim2.new(1, 0, 0, 2),
    BackgroundColor3 = C.accent,
}, Main)

-- =============================================
--  Header
-- =============================================

local Header = makeFrame({
    Size            = UDim2.new(1, 0, 0, 50),
    Position        = UDim2.new(0, 0, 0, 2),
    BackgroundColor3 = C.panel,
}, Main)

-- Ícone
local IconBox = makeFrame({
    Size            = UDim2.new(0, 34, 0, 34),
    Position        = UDim2.new(0, 12, 0.5, -17),
    BackgroundColor3 = C.accent2,
}, Header)
corner(8, IconBox)
stroke(C.accent, 1, IconBox)
makeLabel({
    Size     = UDim2.new(1, 0, 1, 0),
    Text     = "◈",
    TextSize = 18,
    TextColor3 = C.white,
    Font     = Enum.Font.GothamBold,
}, IconBox)

-- Título
makeLabel({
    Size       = UDim2.new(0, 160, 0, 20),
    Position   = UDim2.new(0, 54, 0, 8),
    Text       = "<font color='#00d4ff'>SHADOW</font> HUB",
    TextSize   = 17,
    TextColor3 = C.white,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

makeLabel({
    Size       = UDim2.new(0, 160, 0, 14),
    Position   = UDim2.new(0, 54, 0, 30),
    Text       = "BLOX FRUITS  v2.0",
    TextSize   = 10,
    TextColor3 = C.muted,
    Font       = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

-- Status dot + texto
local StatusDot = makeFrame({
    Size            = UDim2.new(0, 8, 0, 8),
    Position        = UDim2.new(1, -90, 0.5, -4),
    BackgroundColor3 = C.muted,
}, Header)
corner(4, StatusDot)

local StatusTxt = makeLabel({
    Size       = UDim2.new(0, 70, 0, 18),
    Position   = UDim2.new(1, -78, 0.5, -9),
    Text       = "INATIVO",
    TextSize   = 11,
    TextColor3 = C.muted,
    Font       = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Header)

-- Botão fechar
local CloseBtn = makeButton({
    Size            = UDim2.new(0, 26, 0, 26),
    Position        = UDim2.new(1, -36, 0.5, -13),
    Text            = "✕",
    TextSize        = 13,
    BackgroundColor3 = Color3.fromRGB(40, 20, 25),
    TextColor3      = C.red,
}, Header)
corner(6, CloseBtn)
CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
end)

-- =============================================
--  Sidebar (nav)
-- =============================================

local Sidebar = makeFrame({
    Size            = UDim2.new(0, 120, 1, -52),
    Position        = UDim2.new(0, 0, 0, 52),
    BackgroundColor3 = C.panel,
}, Main)
stroke(C.border, 1, Sidebar)

local NavList = make("UIListLayout", {
    SortOrder       = Enum.SortOrder.LayoutOrder,
    FillDirection   = Enum.FillDirection.Vertical,
    Padding         = UDim.new(0, 2),
    Parent          = Sidebar,
})
padding(8, 0, 0, 0, Sidebar)

-- =============================================
--  Content Area
-- =============================================

local Content = makeFrame({
    Size     = UDim2.new(1, -120, 1, -52),
    Position = UDim2.new(0, 120, 0, 52),
}, Main)
padding(14, 14, 14, 14, Content)

-- =============================================
--  Tabs (páginas)
-- =============================================

local tabs = {}
local navBtns = {}
local activeTab = nil

local function createTab(name)
    local f = makeFrame({ Size = UDim2.new(1, 0, 1, 0), Visible = false }, Content)
    tabs[name] = f
    return f
end

local function switchTab(name)
    for k, f in pairs(tabs) do f.Visible = false end
    for k, b in pairs(navBtns) do
        b.BackgroundColor3 = C.panel
        b.TextColor3       = C.muted
    end
    if tabs[name] then tabs[name].Visible = true end
    if navBtns[name] then
        navBtns[name].BackgroundColor3 = Color3.fromRGB(18, 28, 38)
        navBtns[name].TextColor3       = C.accent
    end
    activeTab = name
end

local NAV_ITEMS = {
    { name = "farm",   icon = "⚔", label = "AutoFarm",  order = 1 },
    { name = "quests", icon = "📋", label = "Quests",    order = 2 },
    { name = "config", icon = "⚙", label = "Config",    order = 3 },
    { name = "logs",   icon = "🖥", label = "Logs",      order = 4 },
    { name = "status", icon = "📊", label = "Status",    order = 5 },
}

for _, item in ipairs(NAV_ITEMS) do
    local btn = makeButton({
        Size            = UDim2.new(1, -4, 0, 36),
        BackgroundColor3 = C.panel,
        TextColor3      = C.muted,
        Text            = item.icon .. "  " .. item.label,
        TextSize        = 12,
        Font            = Enum.Font.GothamBold,
        TextXAlignment  = Enum.TextXAlignment.Left,
        LayoutOrder     = item.order,
    }, Sidebar)
    padding(0, 0, 10, 0, btn)
    corner(6, btn)

    local leftBar = makeFrame({
        Size            = UDim2.new(0, 2, 1, 0),
        BackgroundColor3 = C.accent,
        Visible         = false,
    }, btn)

    btn.MouseButton1Click:Connect(function()
        switchTab(item.name)
        for _, b in pairs(navBtns) do
            local lb = b:FindFirstChildOfClass("Frame")
            if lb then lb.Visible = false end
        end
        leftBar.Visible = true
    end)

    navBtns[item.name] = btn
    createTab(item.name)
end

-- =============================================
--  Toggle Helper
-- =============================================

local function makeToggle(parent, yPos, labelText, subText, initialValue, onChange)
    local row = makeFrame({
        Size            = UDim2.new(1, 0, 0, 44),
        Position        = UDim2.new(0, 0, 0, yPos),
        BackgroundColor3 = C.panel,
    }, parent)
    corner(6, row)
    stroke(C.border, 1, row)
    padding(0, 0, 10, 10, row)

    makeLabel({
        Size       = UDim2.new(1, -60, 0, 18),
        Position   = UDim2.new(0, 0, 0, 5),
        Text       = labelText,
        TextSize   = 13,
        TextColor3 = C.white,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    makeLabel({
        Size       = UDim2.new(1, -60, 0, 14),
        Position   = UDim2.new(0, 0, 0, 24),
        Text       = subText,
        TextSize   = 10,
        TextColor3 = C.muted,
        Font       = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    -- Toggle visual
    local track = makeFrame({
        Size            = UDim2.new(0, 40, 0, 22),
        Position        = UDim2.new(1, -44, 0.5, -11),
        BackgroundColor3 = initialValue and Color3.fromRGB(0, 50, 60) or C.border,
    }, row)
    corner(11, track)
    stroke(initialValue and C.accent or C.muted, 1, track)

    local knob = makeFrame({
        Size            = UDim2.new(0, 14, 0, 14),
        Position        = initialValue and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
        BackgroundColor3 = initialValue and C.accent or C.muted,
    }, track)
    corner(7, knob)

    local state = initialValue
    track.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        state = not state
        local tw = TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = state and C.accent or C.muted,
        })
        tw:Play()
        TweenService:Create(track, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(0, 50, 60) or C.border,
        }):Play()
        local s = Instance.new("UIStroke")
        s.Color     = state and C.accent or C.muted
        s.Thickness = 1
        s.Parent    = track
        if onChange then onChange(state) end
    end)

    return row, function() return state end
end

-- =============================================
--  TAB: AUTOFARM
-- =============================================

local farmTab = tabs["farm"]

-- Master toggle (destacado)
local masterRow = makeFrame({
    Size            = UDim2.new(1, 0, 0, 52),
    BackgroundColor3 = Color3.fromRGB(0, 30, 40),
}, farmTab)
corner(8, masterRow)
stroke(Color3.fromRGB(0, 80, 100), 1, masterRow)
padding(0, 0, 12, 12, masterRow)

makeLabel({
    Size       = UDim2.new(1, -60, 0, 20),
    Position   = UDim2.new(0, 0, 0, 7),
    Text       = "⚡  AutoFarm Principal",
    TextSize   = 14,
    TextColor3 = C.white,
    TextXAlignment = Enum.TextXAlignment.Left,
}, masterRow)

local masterSubLbl = makeLabel({
    Size       = UDim2.new(1, -60, 0, 14),
    Position   = UDim2.new(0, 0, 0, 30),
    Text       = "_G.AutoFarm = false",
    TextSize   = 10,
    TextColor3 = C.muted,
    Font       = Enum.Font.Code,
    TextXAlignment = Enum.TextXAlignment.Left,
}, masterRow)

-- Master knob
local mTrack = makeFrame({
    Size            = UDim2.new(0, 44, 0, 24),
    Position        = UDim2.new(1, -48, 0.5, -12),
    BackgroundColor3 = C.border,
}, masterRow)
corner(12, mTrack)
stroke(C.muted, 1, mTrack)

local mKnob = makeFrame({
    Size            = UDim2.new(0, 16, 0, 16),
    Position        = UDim2.new(0, 4, 0.5, -8),
    BackgroundColor3 = C.muted,
}, mTrack)
corner(8, mKnob)

local masterState = false
mTrack.InputBegan:Connect(function(inp)
    if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
    masterState = not masterState
    _G.AutoFarm = masterState
    _G.AutoFarmState.active = masterState

    TweenService:Create(mKnob, TweenInfo.new(0.15), {
        Position        = masterState and UDim2.new(1, -20, 0.5, -8) or UDim2.new(0, 4, 0.5, -8),
        BackgroundColor3 = masterState and C.accent or C.muted,
    }):Play()
    TweenService:Create(mTrack, TweenInfo.new(0.15), {
        BackgroundColor3 = masterState and Color3.fromRGB(0, 50, 60) or C.border,
    }):Play()

    StatusDot.BackgroundColor3 = masterState and C.green or C.muted
    StatusTxt.Text             = masterState and "ATIVO" or "INATIVO"
    StatusTxt.TextColor3       = masterState and C.green or C.muted
    masterSubLbl.Text          = masterState and "_G.AutoFarm = true" or "_G.AutoFarm = false"

    if masterState then
        Logger.ok("AutoFarm ATIVADO")
        CheckQuest()
    else
        Logger.warn("AutoFarm DESATIVADO")
    end
end)

-- Sub-toggles
local subToggles = {
    { label = "Auto Quest",   sub = "Pega quest automático",    key = "_G.AutoQuest",    def = true  },
    { label = "Teleport",     sub = "Teleporta ao monstro",     key = "_G.AutoTeleport", def = true  },
    { label = "Auto Atacar",  sub = "Ataque automático",        key = "_G.AutoAttack",   def = true  },
    { label = "Level Up",     sub = "Detecta mudança de nível", key = "_G.AutoLevelUp",  def = true  },
    { label = "Portal Entry", sub = "Entra em portais",         key = "_G.AutoPortal",   def = false },
    { label = "Debug Log",    sub = "CONFIG.DEBUG",             key = "DEBUG",           def = true  },
}

local subScroll = make("ScrollingFrame", {
    Size            = UDim2.new(1, 0, 1, -60),
    Position        = UDim2.new(0, 0, 0, 58),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.muted,
    CanvasSize      = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent          = farmTab,
})

local subList = make("UIListLayout", {
    SortOrder     = Enum.SortOrder.LayoutOrder,
    Padding       = UDim.new(0, 6),
    Parent        = subScroll,
})

for i, t in ipairs(subToggles) do
    local row = makeFrame({
        Size            = UDim2.new(1, 0, 0, 44),
        BackgroundColor3 = C.panel,
        LayoutOrder     = i,
    }, subScroll)
    corner(6, row)
    stroke(C.border, 1, row)
    padding(0, 0, 10, 10, row)

    makeLabel({
        Size       = UDim2.new(1, -60, 0, 18),
        Position   = UDim2.new(0, 0, 0, 5),
        Text       = t.label,
        TextSize   = 12,
        TextColor3 = C.white,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    makeLabel({
        Size       = UDim2.new(1, -60, 0, 14),
        Position   = UDim2.new(0, 0, 0, 24),
        Text       = t.sub,
        TextSize   = 10,
        TextColor3 = C.muted,
        Font       = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local trk = makeFrame({
        Size            = UDim2.new(0, 40, 0, 22),
        Position        = UDim2.new(1, -44, 0.5, -11),
        BackgroundColor3 = t.def and Color3.fromRGB(0, 50, 60) or C.border,
    }, row)
    corner(11, trk)
    stroke(t.def and C.accent or C.muted, 1, trk)

    local knob = makeFrame({
        Size            = UDim2.new(0, 14, 0, 14),
        Position        = t.def and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
        BackgroundColor3 = t.def and C.accent or C.muted,
    }, trk)
    corner(7, knob)

    local state = t.def
    local key   = t.key
    trk.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        state = not state
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position        = state and UDim2.new(1, -17, 0.5, -7) or UDim2.new(0, 3, 0.5, -7),
            BackgroundColor3 = state and C.accent or C.muted,
        }):Play()
        TweenService:Create(trk, TweenInfo.new(0.15), {
            BackgroundColor3 = state and Color3.fromRGB(0, 50, 60) or C.border,
        }):Play()

        if key == "DEBUG" then
            CONFIG.DEBUG = state
        else
            -- seta _G dinamicamente
            local varName = key:gsub("_G%.", "")
            _G[varName] = state
        end
        Logger.info((state and "Ativado: " or "Desativado: ") .. t.label)
    end)
end

-- =============================================
--  TAB: QUESTS
-- =============================================

local questTab = tabs["quests"]

local qFields = {
    { label = "Quest NPC",    key = "qNpc"     },
    { label = "Monstro",      key = "qMon"     },
    { label = "Faixa Nível",  key = "qRange"   },
    { label = "Nível Quest",  key = "qLvl"     },
    { label = "Mundo",        key = "qWorld"   },
}

local qLabels = {}
local qList = make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = questTab })

for i, f in ipairs(qFields) do
    local row = makeFrame({ Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = C.panel, LayoutOrder = i }, questTab)
    corner(6, row)
    stroke(C.border, 1, row)
    padding(0, 0, 10, 10, row)

    makeLabel({
        Size       = UDim2.new(0.5, 0, 1, 0),
        Text       = f.label,
        TextSize   = 12,
        TextColor3 = C.muted,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local val = makeLabel({
        Size       = UDim2.new(0.5, 0, 1, 0),
        Position   = UDim2.new(0.5, 0, 0, 0),
        Text       = "—",
        TextSize   = 12,
        TextColor3 = C.accent,
        Font       = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)
    qLabels[f.key] = val
end

local function updateQuestTab()
    local level = getPlayerLevel() or 1
    local worldQ = QUEST_DATA[currentWorld]
    if not worldQ then return end
    local q = findQuestByLevel(worldQ, level)
    if q then
        qLabels["qNpc"].Text   = q.questName
        qLabels["qMon"].Text   = q.monsterName
        qLabels["qRange"].Text = q.minLevel .. " – " .. (q.maxLevel == math.huge and "∞" or q.maxLevel)
        qLabels["qLvl"].Text   = "Nível " .. q.levelQuest
        qLabels["qWorld"].Text = "Mundo " .. currentWorld
    else
        for _, lbl in pairs(qLabels) do lbl.Text = "—" end
    end
end

-- =============================================
--  TAB: CONFIG
-- =============================================

local configTab = tabs["config"]
local cfgList = make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = configTab })

local function makeConfigInput(parent, order, label, sublabel, default, onChange)
    local row = makeFrame({ Size = UDim2.new(1, 0, 0, 48), BackgroundColor3 = C.panel, LayoutOrder = order }, parent)
    corner(6, row)
    stroke(C.border, 1, row)
    padding(0, 0, 10, 10, row)

    makeLabel({
        Size       = UDim2.new(0.6, 0, 0, 18),
        Position   = UDim2.new(0, 0, 0, 7),
        Text       = label,
        TextSize   = 12,
        TextColor3 = C.white,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)
    makeLabel({
        Size       = UDim2.new(0.6, 0, 0, 14),
        Position   = UDim2.new(0, 0, 0, 27),
        Text       = sublabel,
        TextSize   = 10,
        TextColor3 = C.muted,
        Font       = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local box = make("TextBox", {
        Size            = UDim2.new(0, 90, 0, 28),
        Position        = UDim2.new(1, -94, 0.5, -14),
        BackgroundColor3 = C.bg,
        TextColor3      = C.accent,
        Font            = Enum.Font.Code,
        TextSize        = 12,
        Text            = tostring(default),
        PlaceholderText = tostring(default),
        ClearTextOnFocus = false,
        BorderSizePixel = 0,
        Parent          = row,
    })
    corner(6, box)
    stroke(C.border, 1, box)
    box.FocusLost:Connect(function()
        if onChange then onChange(box.Text) end
    end)
    return box
end

makeConfigInput(configTab, 1, "Farm Delay (s)", "Delay entre ações", CONFIG.FARM_DELAY, function(v)
    local n = tonumber(v)
    if n then
        CONFIG.FARM_DELAY = n
        Logger.info("Farm Delay: " .. n)
    end
end)

makeConfigInput(configTab, 2, "Teleport Range", "Distância p/ portal", CONFIG.TELEPORT_RANGE, function(v)
    local n = tonumber(v)
    if n then
        CONFIG.TELEPORT_RANGE = n
        Logger.info("Teleport Range: " .. n)
    end
end)

-- =============================================
--  TAB: LOGS
-- =============================================

local logTab = tabs["logs"]

local logHeader = makeFrame({ Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1 }, logTab)

makeLabel({
    Size       = UDim2.new(0.5, 0, 1, 0),
    Text       = "Console Output",
    TextSize   = 13,
    TextColor3 = C.white,
    TextXAlignment = Enum.TextXAlignment.Left,
}, logHeader)

local clearBtn = makeButton({
    Size            = UDim2.new(0, 70, 0, 22),
    Position        = UDim2.new(1, -70, 0.5, -11),
    Text            = "🗑 Limpar",
    TextSize        = 11,
    BackgroundColor3 = C.border,
    TextColor3      = C.muted,
}, logHeader)
corner(6, clearBtn)

local logScroll = make("ScrollingFrame", {
    Size            = UDim2.new(1, 0, 1, -34),
    Position        = UDim2.new(0, 0, 0, 34),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = C.muted,
    CanvasSize      = UDim2.new(0, 0, 0, 0),
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
    Parent          = logTab,
})
corner(6, logScroll)
stroke(C.border, 1, logScroll)
padding(6, 6, 8, 8, logScroll)

local logListLayout = make("UIListLayout", {
    SortOrder = Enum.SortOrder.LayoutOrder,
    Padding   = UDim.new(0, 2),
    Parent    = logScroll,
})

local logCount = 0

local LOG_COLORS = {
    INFO  = C.accent,
    WARN  = C.yellow,
    ERROR = C.red,
    OK    = C.green,
}

local function addLog(level, msg)
    logCount = logCount + 1
    local t = os.date("[%H:%M:%S]")
    local color = LOG_COLORS[level] or C.text
    local lbl = makeLabel({
        Size       = UDim2.new(1, 0, 0, 16),
        Text       = string.format('<font color="#%02x%02x%02x">%s</font> <font color="#4a5568">%s</font> %s',
            math.floor(color.R*255), math.floor(color.G*255), math.floor(color.B*255),
            level, t, msg),
        TextSize   = 10,
        Font       = Enum.Font.Code,
        TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left,
        LayoutOrder = logCount,
    }, logScroll)
    task.delay(0.05, function()
        logScroll.CanvasPosition = Vector2.new(0, math.huge)
    end)
end

LogCallback = addLog

clearBtn.MouseButton1Click:Connect(function()
    for _, c in ipairs(logScroll:GetChildren()) do
        if c:IsA("TextLabel") then c:Destroy() end
    end
    logCount = 0
    addLog("INFO", "Logs limpos.")
end)

-- =============================================
--  TAB: STATUS
-- =============================================

local statusTab = tabs["status"]

local statItems = {
    { key = "sFarm",      label = "AutoFarm",    value = "DESLIGADO", color = C.muted  },
    { key = "sQuest",     label = "Auto Quest",  value = "LIGADO",    color = C.green  },
    { key = "sTeleport",  label = "Teleport",    value = "LIGADO",    color = C.green  },
    { key = "sAttack",    label = "Auto Atacar", value = "LIGADO",    color = C.green  },
    { key = "sPortal",    label = "Portal Entry",value = "DESLIGADO", color = C.muted  },
    { key = "sWorld",     label = "Mundo",       value = "Mundo " .. currentWorld, color = C.accent },
}

local statLabels = {}
local stList = make("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6), Parent = statusTab })

for i, s in ipairs(statItems) do
    local row = makeFrame({ Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.panel, LayoutOrder = i }, statusTab)
    corner(6, row)
    stroke(C.border, 1, row)
    padding(0, 0, 10, 10, row)

    makeLabel({
        Size       = UDim2.new(0.55, 0, 1, 0),
        Text       = s.label,
        TextSize   = 12,
        TextColor3 = C.text,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, row)

    local val = makeLabel({
        Size       = UDim2.new(0.45, 0, 1, 0),
        Position   = UDim2.new(0.55, 0, 0, 0),
        Text       = s.value,
        TextSize   = 11,
        Font       = Enum.Font.Code,
        TextColor3 = s.color,
        TextXAlignment = Enum.TextXAlignment.Right,
    }, row)
    statLabels[s.key] = val
end

-- =============================================
--  Drag da janela
-- =============================================

local dragging, dragStart, startPos
Header.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging  = true
        dragStart = inp.Position
        startPos  = Main.Position
    end
end)
UserInputService.InputChanged:Connect(function(inp)
    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = inp.Position - dragStart
        Main.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

-- =============================================
--  Footer
-- =============================================

local Footer = makeFrame({
    Size            = UDim2.new(1, 0, 0, 22),
    Position        = UDim2.new(0, 0, 1, -22),
    BackgroundColor3 = C.panel,
}, Main)
stroke(C.border, 1, Footer)
padding(0, 0, 12, 12, Footer)

makeLabel({
    Size       = UDim2.new(0.5, 0, 1, 0),
    Text       = "<font color='#00d4ff'>SHADOW HUB</font>  —  Blox Fruits",
    TextSize   = 10,
    Font       = Enum.Font.Code,
    TextColor3 = C.muted,
    TextXAlignment = Enum.TextXAlignment.Left,
}, Footer)

local lvlLbl = makeLabel({
    Size       = UDim2.new(0.5, 0, 1, 0),
    Position   = UDim2.new(0.5, 0, 0, 0),
    Text       = "LVL 1  |  MUNDO " .. currentWorld,
    TextSize   = 10,
    Font       = Enum.Font.Code,
    TextColor3 = C.muted,
    TextXAlignment = Enum.TextXAlignment.Right,
}, Footer)

-- =============================================
--  Atualização periódica da UI
-- =============================================

task.spawn(function()
    while task.wait(1) do
        local level = getPlayerLevel()
        if level then
            lvlLbl.Text = "LVL " .. level .. "  |  MUNDO " .. currentWorld
        end

        -- Atualiza status tab
        statLabels["sFarm"].Text      = _G.AutoFarm and "LIGADO" or "DESLIGADO"
        statLabels["sFarm"].TextColor3 = _G.AutoFarm and C.green or C.muted
        statLabels["sQuest"].Text      = _G.AutoQuest and "LIGADO" or "DESLIGADO"
        statLabels["sQuest"].TextColor3 = _G.AutoQuest and C.green or C.muted
        statLabels["sTeleport"].Text   = _G.AutoTeleport and "LIGADO" or "DESLIGADO"
        statLabels["sTeleport"].TextColor3 = _G.AutoTeleport and C.green or C.muted
        statLabels["sAttack"].Text     = _G.AutoAttack and "LIGADO" or "DESLIGADO"
        statLabels["sAttack"].TextColor3 = _G.AutoAttack and C.green or C.muted
        statLabels["sPortal"].Text     = _G.AutoPortal and "LIGADO" or "DESLIGADO"
        statLabels["sPortal"].TextColor3 = _G.AutoPortal and C.green or C.muted

        -- Atualiza quest tab
        updateQuestTab()
    end
end)

-- =============================================
--  Inicialização
-- =============================================

switchTab("farm")

addLog("OK",   "SHADOW HUB v2.0 carregado!")
addLog("INFO", "Mundo detectado: " .. currentWorld)
addLog("WARN", "Ative o AutoFarm para iniciar.")

Logger.info("SHADOW HUB iniciado! Mundo " .. currentWorld)
CheckQuest()
