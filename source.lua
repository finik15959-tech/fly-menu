-- Testing GUI Script v1.8.0
-- Design: Dark Minimalism | Black-Purple accent
-- DreamCompany

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer
local SAVE_FILE = "Testing_settings.txt"

-- ================================
-- СЕРИАЛИЗАЦИЯ
-- ================================

local function serialize(data)
    local parts = {}
    for k, v in pairs(data) do
        table.insert(parts, tostring(k) .. "=" .. tostring(v))
    end
    return table.concat(parts, "\n")
end

local function deserialize(raw)
    local result = {}
    for line in raw:gmatch("[^\n]+") do
        local k, v = line:match("^(.-)=(.+)$")
        if k and v then result[k] = v end
    end
    return result
end

local function toKeyCode(str)
    if not str then return nil end
    local name = str:match("Enum%.KeyCode%.(.+)") or str
    local ok, kc = pcall(function() return Enum.KeyCode[name] end)
    return (ok and kc) or nil
end

-- ================================
-- ЦВЕТА ESP
-- ================================

local espColors = {
    normal = {
        outline          = Color3.fromRGB(255, 255, 255),
        fill             = Color3.fromRGB(255, 255, 255),
        fillTransparency = 0.72,
        text             = Color3.fromRGB(255, 255, 255),
    },
    mm2_innocent = {
        outline          = Color3.fromRGB(0, 220, 80),
        fill             = Color3.fromRGB(0, 180, 60),
        fillTransparency = 0.65,
        text             = Color3.fromRGB(80, 255, 140),
    },
    mm2_murderer = {
        outline          = Color3.fromRGB(255, 30, 30),
        fill             = Color3.fromRGB(200, 0, 0),
        fillTransparency = 0.65,
        text             = Color3.fromRGB(255, 100, 100),
    },
    mm2_sheriff = {
        outline          = Color3.fromRGB(60, 140, 255),
        fill             = Color3.fromRGB(30, 80, 220),
        fillTransparency = 0.65,
        text             = Color3.fromRGB(130, 190, 255),
    },
    tg = {
        outline          = Color3.fromRGB(255, 180, 0),
        fill             = Color3.fromRGB(255, 140, 0),
        fillTransparency = 0.72,
        text             = Color3.fromRGB(255, 210, 60),
    },
    yt = {
        outline          = Color3.fromRGB(255, 0, 0),
        fill             = Color3.fromRGB(200, 0, 0),
        fillTransparency = 0.72,
        text             = Color3.fromRGB(255, 80, 80),
    },
    tt = {
        outline          = Color3.fromRGB(30, 30, 30),
        fill             = Color3.fromRGB(10, 10, 10),
        fillTransparency = 0.60,
        text             = Color3.fromRGB(200, 200, 200),
    },
}

-- ================================
-- КОНФИГ
-- ================================

local config = {
    flySpeed          = 50,
    walkSpeed         = 16,
    jumpHeight        = 7,
    followDistance    = 5,
    followHeight      = 3,
    flying            = false,
    following         = false,
    noclip            = false,
    targetPlayer      = nil,
    walkSpeedEnabled  = false,
    jumpHeightEnabled = false,
}

local binds = {
    fly        = Enum.KeyCode.F5,
    noclip     = Enum.KeyCode.F6,
    unfollow   = Enum.KeyCode.F7,
    esp        = Enum.KeyCode.F8,
    menu       = Enum.KeyCode.F9,
    walkSpeed  = Enum.KeyCode.F1,
    jumpHeight = Enum.KeyCode.F2,
}

local function keyName(kc)
    local s = tostring(kc)
    return s:match("KeyCode%.(.+)") or s
end

-- ================================
-- MM2
-- ================================

local MM2_GAME_ID = 142823291

local function isInMM2()
    return game.PlaceId == MM2_GAME_ID
end

local function getMM2Role(player)
    local function getToolName(container)
        if not container then return nil end
        for _, obj in pairs(container:GetChildren()) do
            if obj:IsA("Tool") then
                local n = obj.Name:lower()
                if n == "knife" or n:find("knife") or n:find("blade") then
                    return "mm2_murderer"
                end
                if n == "gun tool" or n == "gun" or n:find("gun") or n:find("revolver") or n:find("sheriff") then
                    return "mm2_sheriff"
                end
            end
        end
        return nil
    end

    local bp = player:FindFirstChildOfClass("Backpack")
    local roleFromBP = getToolName(bp)
    if roleFromBP then return roleFromBP end

    local char = player.Character
    local roleFromChar = getToolName(char)
    if roleFromChar then return roleFromChar end

    local roundActive = false
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= player then
            if getToolName(p:FindFirstChildOfClass("Backpack")) then roundActive = true break end
            if getToolName(p.Character) then roundActive = true break end
        end
    end

    return roundActive and "mm2_innocent" or nil
end

-- ================================
-- ОПРЕДЕЛЕНИЕ ТИПА ИГРОКА
-- Поддерживает любой регистр:
--   tgk_, _tgk, tg_, _tg, yt_, _yt, tt_, _tt
--   и все их варианты (TGK_, _TGK, TG_, _TG, YT_, _YT, TT_, _TT и т.д.)
-- TGK → те же цвета что TG
-- ================================

local function getPlayerType(player)
    local name = player.Name:lower()
    local disp = player.DisplayName:lower()

    local function check(str)
        -- TGK (проверяем ДО TG, иначе "tgk_" сматчится как TG)
        if str:find("^tgk_") or str:find("_tgk$") or str:find("_tgk_") or str == "tgk" then
            return "tg"  -- TGK = те же цвета что TG
        end
        -- TG
        if str:find("^tg_") or str:find("_tg$") or str:find("_tg_") or str == "tg" then
            return "tg"
        end
        -- YT
        if str:find("^yt_") or str:find("_yt$") or str:find("_yt_") or str == "yt" then
            return "yt"
        end
        -- TT
        if str:find("^tt_") or str:find("_tt$") or str:find("_tt_") or str == "tt" then
            return "tt"
        end
        return nil
    end

    return check(name) or check(disp) or "normal"
end

-- ================================
-- GUI — СТИЛЬ: ТЁМНЫЙ МИНИМАЛИЗМ
-- ================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Testing"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Цвета GUI
local C = {
    bg0  = Color3.fromRGB(7,   7,  10),
    bg1  = Color3.fromRGB(14,  14, 20),
    bg2  = Color3.fromRGB(20,  20, 30),
    bg3  = Color3.fromRGB(26,  26, 38),
    bg4  = Color3.fromRGB(32,  32, 46),
    acc  = Color3.fromRGB(124, 58, 237),
    acc2 = Color3.fromRGB(168, 85, 247),
    acc3 = Color3.fromRGB(30,  10, 56),
    acc4 = Color3.fromRGB(45,  16, 96),
    brd  = Color3.fromRGB(37,  37, 53),
    brd2 = Color3.fromRGB(58,  58, 85),
    tx1  = Color3.fromRGB(237, 237, 245),
    tx2  = Color3.fromRGB(136, 136, 160),
    tx3  = Color3.fromRGB(68,  68,  90),
    grn  = Color3.fromRGB(22,  163, 74),
    red  = Color3.fromRGB(153, 27,  27),
    red2 = Color3.fromRGB(220, 38,  38),
}

-- Главный фрейм
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 560, 0, 560)
mainFrame.Position = UDim2.new(0, 20, 0.5, -280)
mainFrame.BackgroundColor3 = C.bg0
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

-- Акцентная линия сверху
local topLine = Instance.new("Frame")
topLine.Size = UDim2.new(1, 0, 0, 2)
topLine.BackgroundColor3 = C.acc
topLine.BorderSizePixel = 0
topLine.ZIndex = 2
topLine.Parent = mainFrame

-- Боковая навигация
local sidebar = Instance.new("Frame")
sidebar.Size = UDim2.new(0, 48, 1, -2)
sidebar.Position = UDim2.new(0, 0, 0, 2)
sidebar.BackgroundColor3 = C.bg1
sidebar.BorderSizePixel = 0
sidebar.Parent = mainFrame

local sideBottomLine = Instance.new("Frame")
sideBottomLine.Size = UDim2.new(0, 1, 1, 0)
sideBottomLine.Position = UDim2.new(1, -1, 0, 0)
sideBottomLine.BackgroundColor3 = C.brd
sideBottomLine.BorderSizePixel = 0
sideBottomLine.Parent = sidebar

-- Логотип в сайдбаре
local logoFrame = Instance.new("Frame")
logoFrame.Size = UDim2.new(0, 24, 0, 24)
logoFrame.Position = UDim2.new(0.5, -12, 0, 10)
logoFrame.BackgroundColor3 = C.acc
logoFrame.BorderSizePixel = 0
logoFrame.Parent = sidebar

local logoInner = Instance.new("Frame")
logoInner.Size = UDim2.new(0, 10, 0, 10)
logoInner.Position = UDim2.new(0, 4, 0, 4)
logoInner.BackgroundColor3 = C.bg1
logoInner.BorderSizePixel = 0
logoInner.Parent = logoFrame

-- Контентная область
local contentArea = Instance.new("Frame")
contentArea.Size = UDim2.new(1, -48, 1, -2)
contentArea.Position = UDim2.new(0, 48, 0, 2)
contentArea.BackgroundColor3 = C.bg0
contentArea.BorderSizePixel = 0
contentArea.ClipsDescendants = true
contentArea.Parent = mainFrame

-- Топбар
local topbar = Instance.new("Frame")
topbar.Size = UDim2.new(1, 0, 0, 34)
topbar.BackgroundColor3 = C.bg1
topbar.BorderSizePixel = 0
topbar.Parent = contentArea

local topbarLine = Instance.new("Frame")
topbarLine.Size = UDim2.new(1, 0, 0, 1)
topbarLine.Position = UDim2.new(0, 0, 1, -1)
topbarLine.BackgroundColor3 = C.brd
topbarLine.BorderSizePixel = 0
topbarLine.Parent = topbar

local pageTitle = Instance.new("TextLabel")
pageTitle.Size = UDim2.new(1, -90, 1, 0)
pageTitle.Position = UDim2.new(0, 12, 0, 0)
pageTitle.BackgroundTransparency = 1
pageTitle.Text = "Полёт / Движение"
pageTitle.TextColor3 = C.tx1
pageTitle.TextSize = 13
pageTitle.Font = Enum.Font.GothamBold
pageTitle.TextXAlignment = Enum.TextXAlignment.Left
pageTitle.Parent = topbar

local verLabel = Instance.new("TextLabel")
verLabel.Size = UDim2.new(0, 70, 0, 20)
verLabel.Position = UDim2.new(1, -78, 0.5, -10)
verLabel.BackgroundColor3 = C.bg3
verLabel.BorderSizePixel = 0
verLabel.Text = "v1.8.0"
verLabel.TextColor3 = C.tx3
verLabel.TextSize = 10
verLabel.Font = Enum.Font.GothamBold
verLabel.TextXAlignment = Enum.TextXAlignment.Center
verLabel.Parent = topbar

-- Скролл-контент
local scrollMain = Instance.new("ScrollingFrame")
scrollMain.Size = UDim2.new(1, 0, 1, -34)
scrollMain.Position = UDim2.new(0, 0, 0, 34)
scrollMain.BackgroundTransparency = 1
scrollMain.BorderSizePixel = 0
scrollMain.ScrollBarThickness = 2
scrollMain.ScrollBarImageColor3 = C.brd2
scrollMain.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollMain.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollMain.Parent = contentArea

local scrollPad = Instance.new("Frame")
scrollPad.Size = UDim2.new(1, -20, 0, 0)
scrollPad.Position = UDim2.new(0, 10, 0, 10)
scrollPad.BackgroundTransparency = 1
scrollPad.AutomaticSize = Enum.AutomaticSize.Y
scrollPad.Parent = scrollMain

local padLayout = Instance.new("UIListLayout")
padLayout.SortOrder = Enum.SortOrder.LayoutOrder
padLayout.Padding = UDim.new(0, 6)
padLayout.Parent = scrollPad

-- ================================
-- UI ХЕЛПЕРЫ
-- ================================

local function makeSectionLabel(text, order)
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 18)
    f.BackgroundTransparency = 1
    f.LayoutOrder = order
    f.Parent = scrollPad

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text = text:upper()
    l.TextColor3 = C.tx3
    l.TextSize = 9
    l.Font = Enum.Font.GothamBold
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.Parent = f
    return f
end

-- Плитка-переключатель (tile toggle)
local function makeTile(labelText, keyText, order, callback)
    local tile = Instance.new("Frame")
    tile.Size = UDim2.new(0.5, -3, 0, 56)
    tile.BackgroundColor3 = C.bg2
    tile.BorderSizePixel = 0
    tile.LayoutOrder = order
    tile.Parent = scrollPad  -- временно, потом в грид

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(1, 0, 0, 2)
    accentBar.Position = UDim2.new(0, 0, 1, -2)
    accentBar.BackgroundColor3 = C.brd
    accentBar.BorderSizePixel = 0
    accentBar.Parent = tile

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 7, 0, 7)
    dot.Position = UDim2.new(1, -14, 0, 10)
    dot.BackgroundColor3 = C.brd2
    dot.BorderSizePixel = 0
    dot.Parent = tile

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 16)
    lbl.Position = UDim2.new(0, 10, 0, 10)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = C.tx2
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = tile

    local keyBadge = Instance.new("TextLabel")
    keyBadge.Size = UDim2.new(0, 30, 0, 14)
    keyBadge.Position = UDim2.new(0, 10, 0, 32)
    keyBadge.BackgroundColor3 = C.bg0
    keyBadge.BorderSizePixel = 0
    keyBadge.Text = keyText
    keyBadge.TextColor3 = C.tx3
    keyBadge.TextSize = 9
    keyBadge.Font = Enum.Font.GothamBold
    keyBadge.TextXAlignment = Enum.TextXAlignment.Center
    keyBadge.Parent = tile

    local state = false
    local function setState(v)
        state = v
        tile.BackgroundColor3 = state and C.acc3 or C.bg2
        accentBar.BackgroundColor3 = state and C.acc2 or C.brd
        dot.BackgroundColor3 = state and C.acc2 or C.brd2
        lbl.TextColor3 = state and C.tx1 or C.tx2
        keyBadge.BackgroundColor3 = state and C.acc4 or C.bg0
        keyBadge.TextColor3 = state and C.acc2 or C.tx3
        if callback then callback(state) end
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = tile
    btn.MouseButton1Click:Connect(function() setState(not state) end)

    return tile, function() setState(not state) end, function(v) setState(v) end
end

-- Грид 2 колонки
local function makeGrid2(order)
    local grid = Instance.new("Frame")
    grid.Size = UDim2.new(1, 0, 0, 56)
    grid.BackgroundTransparency = 1
    grid.LayoutOrder = order
    grid.Parent = scrollPad

    local gl = Instance.new("UIListLayout")
    gl.FillDirection = Enum.FillDirection.Horizontal
    gl.SortOrder = Enum.SortOrder.LayoutOrder
    gl.Padding = UDim.new(0, 6)
    gl.Parent = grid

    return grid
end

-- Слайдер с тогглом
local function makeSlider(params)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, params.withToggle and 82 or 68)
    card.BackgroundColor3 = C.bg2
    card.BorderSizePixel = 0
    card.LayoutOrder = params.order
    card.Parent = scrollPad

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 18)
    lbl.Position = UDim2.new(0, 10, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = params.label
    lbl.TextColor3 = C.tx2
    lbl.TextSize = 11
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = card

    -- Значение
    local valBg = Instance.new("Frame")
    valBg.Size = UDim2.new(0, 46, 0, 18)
    valBg.Position = UDim2.new(1, -54, 0, 5)
    valBg.BackgroundColor3 = params.valBg or C.acc3
    valBg.BorderSizePixel = 0
    valBg.Parent = card

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(1, 0, 1, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(params.initVal)
    valLbl.TextColor3 = params.valColor or C.acc2
    valLbl.TextSize = 11
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextXAlignment = Enum.TextXAlignment.Center
    valLbl.Parent = valBg

    -- Трек
    local trackY = params.withToggle and 50 or 34
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -20, 0, 3)
    track.Position = UDim2.new(0, 10, 0, trackY)
    track.BackgroundColor3 = C.bg0
    track.BorderSizePixel = 0
    track.Parent = card

    local initRel = math.clamp((params.initVal - params.sliderMin) / (params.sliderMax - params.sliderMin), 0, 1)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(initRel, 0, 1, 0)
    fill.BackgroundColor3 = params.fillColor or C.acc
    fill.BorderSizePixel = 0
    fill.Parent = track

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 8, 0, 8)
    thumb.Position = UDim2.new(initRel, -4, 0.5, -4)
    thumb.BackgroundColor3 = C.tx1
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 2
    thumb.Parent = track

    -- Min/max лейблы
    local minL = Instance.new("TextLabel")
    minL.Size = UDim2.new(0, 30, 0, 12)
    minL.Position = UDim2.new(0, 10, 0, trackY + 5)
    minL.BackgroundTransparency = 1
    minL.Text = tostring(params.sliderMin)
    minL.TextColor3 = C.tx3
    minL.TextSize = 9
    minL.Font = Enum.Font.Gotham
    minL.TextXAlignment = Enum.TextXAlignment.Left
    minL.Parent = card

    local maxL = Instance.new("TextLabel")
    maxL.Size = UDim2.new(0, 30, 0, 12)
    maxL.Position = UDim2.new(1, -40, 0, trackY + 5)
    maxL.BackgroundTransparency = 1
    maxL.Text = tostring(params.sliderMax)
    maxL.TextColor3 = C.tx3
    maxL.TextSize = 9
    maxL.Font = Enum.Font.Gotham
    maxL.TextXAlignment = Enum.TextXAlignment.Right
    maxL.Parent = card

    -- Ползунок
    local sliding = false
    local trackBtn = Instance.new("TextButton")
    trackBtn.Size = UDim2.new(1, 0, 0, 24)
    trackBtn.Position = UDim2.new(0, 0, 0, -10)
    trackBtn.BackgroundTransparency = 1
    trackBtn.Text = ""
    trackBtn.ZIndex = 3
    trackBtn.Parent = track

    local currentVal = params.initVal

    local function updateVal(val)
        currentVal = val
        valLbl.Text = tostring(val)
        local rel = math.clamp((val - params.sliderMin) / (params.sliderMax - params.sliderMin), 0, 1)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        thumb.Position = UDim2.new(rel, -4, 0.5, -4)
        if params.onChanged then params.onChanged(val) end
    end

    trackBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            local tp = track.AbsolutePosition.X
            local tw = track.AbsoluteSize.X
            local rel = math.clamp((i.Position.X - tp) / tw, 0, 1)
            updateVal(math.floor(params.sliderMin + (params.sliderMax - params.sliderMin) * rel))
        end
    end)

    -- Тоггл (если нужен)
    local toggleState = false
    local togBg, togCircle

    if params.withToggle then
        togBg = Instance.new("Frame")
        togBg.Size = UDim2.new(0, 26, 0, 14)
        togBg.Position = UDim2.new(0, 10, 0, 30)
        togBg.BackgroundColor3 = C.bg4
        togBg.BorderSizePixel = 0
        togBg.ZIndex = 4
        togBg.Parent = card

        togCircle = Instance.new("Frame")
        togCircle.Size = UDim2.new(0, 10, 0, 10)
        togCircle.Position = UDim2.new(0, 2, 0.5, -5)
        togCircle.BackgroundColor3 = C.tx3
        togCircle.BorderSizePixel = 0
        togCircle.ZIndex = 5
        togCircle.Parent = togBg

        local statusLbl = Instance.new("TextLabel")
        statusLbl.Size = UDim2.new(0, 50, 0, 14)
        statusLbl.Position = UDim2.new(0, 42, 0, 30)
        statusLbl.BackgroundTransparency = 1
        statusLbl.Text = "ВЫКЛ"
        statusLbl.TextColor3 = C.tx3
        statusLbl.TextSize = 9
        statusLbl.Font = Enum.Font.GothamBold
        statusLbl.TextXAlignment = Enum.TextXAlignment.Left
        statusLbl.Parent = card

        local function setTog(v)
            toggleState = v
            TweenService:Create(togBg, TweenInfo.new(0.15), {
                BackgroundColor3 = v and C.acc4 or C.bg4
            }):Play()
            TweenService:Create(togCircle, TweenInfo.new(0.15), {
                Position = v and UDim2.new(0, 14, 0.5, -5) or UDim2.new(0, 2, 0.5, -5),
                BackgroundColor3 = v and C.acc2 or C.tx3
            }):Play()
            statusLbl.Text = v and "ВКЛ" or "ВЫКЛ"
            statusLbl.TextColor3 = v and (params.fillColor or C.acc2) or C.tx3
            if params.onToggle then params.onToggle(v, currentVal) end
        end

        params._setTog = setTog

        local togBtn = Instance.new("TextButton")
        togBtn.Size = UDim2.new(1, 0, 1, 0)
        togBtn.BackgroundTransparency = 1
        togBtn.Text = ""
        togBtn.ZIndex = 6
        togBtn.Parent = togBg
        togBtn.MouseButton1Click:Connect(function() setTog(not toggleState) end)
    end

    return { card = card, valLbl = valLbl, fill = fill, thumb = thumb, updateVal = updateVal }
end

-- Строка цвета ESP
local function makeColorRow(labelText, order, getColor, setColor, onChange)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundColor3 = C.bg2
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.Parent = scrollPad

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 10, 0, 10)
    dot.Position = UDim2.new(0, 10, 0.5, -5)
    dot.BackgroundColor3 = getColor()
    dot.BorderSizePixel = 0
    dot.Parent = row

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0, 100, 1, 0)
    lbl.Position = UDim2.new(0, 26, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = C.tx2
    lbl.TextSize = 10
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local c = getColor()
    local rVal = math.floor(c.R * 255)
    local gVal = math.floor(c.G * 255)
    local bVal = math.floor(c.B * 255)

    local function makeRGBBox(initVal, xOff)
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(0, 36, 0, 22)
        bg.Position = UDim2.new(0, xOff, 0.5, -11)
        bg.BackgroundColor3 = C.bg0
        bg.BorderSizePixel = 0
        bg.Parent = row

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -4, 1, 0)
        box.Position = UDim2.new(0, 2, 0, 0)
        box.BackgroundTransparency = 1
        box.Text = tostring(initVal)
        box.TextColor3 = C.tx2
        box.TextSize = 11
        box.Font = Enum.Font.GothamBold
        box.TextXAlignment = Enum.TextXAlignment.Center
        box.ClearTextOnFocus = false
        box.Parent = bg
        return box
    end

    local rBox = makeRGBBox(rVal, 130)
    local gBox = makeRGBBox(gVal, 170)
    local bBox = makeRGBBox(bVal, 210)

    local function applyColor()
        local r = math.clamp(tonumber(rBox.Text) or 0, 0, 255)
        local g = math.clamp(tonumber(gBox.Text) or 0, 0, 255)
        local b = math.clamp(tonumber(bBox.Text) or 0, 0, 255)
        rBox.Text, gBox.Text, bBox.Text = tostring(r), tostring(g), tostring(b)
        local newColor = Color3.fromRGB(r, g, b)
        setColor(newColor)
        dot.BackgroundColor3 = newColor
        if onChange then onChange() end
    end

    rBox.FocusLost:Connect(applyColor)
    gBox.FocusLost:Connect(applyColor)
    bBox.FocusLost:Connect(applyColor)
end

-- ================================
-- НАВИГАЦИЯ (боковое меню)
-- ================================

local pages = {}
local sideIcons = {}
local currentPage = nil

local navItems = {
    { key = "fly",    icon = "✈", title = "Полёт / Движение"    },
    { key = "esp",    icon = "👁", title = "ESP"                 },
    { key = "follow", icon = "◎", title = "Преследование"        },
    { key = "binds",  icon = "⌨", title = "Бинды"               },
    { key = "save",   icon = "💾", title = "Сохранить / Загрузить"},
}

-- Создаём страницы (Frame) и иконки сайдбара
-- Страницы будут дочерними для scrollPad, показываем/скрываем через Visible
-- (AutomaticCanvasSize Y подхватит только видимое)
-- Вместо этого используем отдельные ScrollingFrame на каждую страницу — проще

-- Убираем scrollMain, делаем переключаемые страницы
scrollMain:Destroy()
padLayout:Destroy()
scrollPad:Destroy()

-- Создаём контейнер страниц
local pagesContainer = Instance.new("Frame")
pagesContainer.Size = UDim2.new(1, 0, 1, -34)
pagesContainer.Position = UDim2.new(0, 0, 0, 34)
pagesContainer.BackgroundTransparency = 1
pagesContainer.ClipsDescendants = true
pagesContainer.Parent = contentArea

local function makePage(key)
    local sf = Instance.new("ScrollingFrame")
    sf.Size = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel = 0
    sf.ScrollBarThickness = 2
    sf.ScrollBarImageColor3 = C.brd2
    sf.CanvasSize = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Visible = false
    sf.Parent = pagesContainer

    local pad = Instance.new("Frame")
    pad.Size = UDim2.new(1, -20, 0, 0)
    pad.Position = UDim2.new(0, 10, 0, 10)
    pad.BackgroundTransparency = 1
    pad.AutomaticSize = Enum.AutomaticSize.Y
    pad.Parent = sf

    local layout = Instance.new("UIListLayout")
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 6)
    layout.Parent = pad

    local bottomPad = Instance.new("Frame")
    bottomPad.Size = UDim2.new(1, 0, 0, 10)
    bottomPad.BackgroundTransparency = 1
    bottomPad.LayoutOrder = 9999
    bottomPad.Parent = pad

    pages[key] = { sf = sf, pad = pad }
    return pad
end

local function switchPage(key)
    for k, p in pairs(pages) do
        p.sf.Visible = (k == key)
    end
    for _, item in ipairs(navItems) do
        local ic = sideIcons[item.key]
        if ic then
            if item.key == key then
                ic.frame.BackgroundColor3 = C.acc3
                ic.bar.BackgroundColor3 = C.acc2
                ic.label.TextColor3 = C.acc2
            else
                ic.frame.BackgroundColor3 = C.bg1
                ic.bar.BackgroundColor3 = C.bg1
                ic.label.TextColor3 = C.tx3
            end
        end
    end
    for _, item in ipairs(navItems) do
        if item.key == key then
            pageTitle.Text = item.title
            break
        end
    end
    currentPage = key
end

-- Создаём иконки навигации
local iconY = 46
for _, item in ipairs(navItems) do
    local iconFrame = Instance.new("Frame")
    iconFrame.Size = UDim2.new(0, 48, 0, 40)
    iconFrame.Position = UDim2.new(0, 0, 0, iconY)
    iconFrame.BackgroundColor3 = C.bg1
    iconFrame.BorderSizePixel = 0
    iconFrame.Parent = sidebar

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 2, 1, 0)
    accentBar.BackgroundColor3 = C.bg1
    accentBar.BorderSizePixel = 0
    accentBar.Parent = iconFrame

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = item.icon
    iconLabel.TextColor3 = C.tx3
    iconLabel.TextSize = 16
    iconLabel.Font = Enum.Font.Gotham
    iconLabel.Parent = iconFrame

    local divLine = Instance.new("Frame")
    divLine.Size = UDim2.new(0, 28, 0, 1)
    divLine.Position = UDim2.new(0.5, -14, 1, -1)
    divLine.BackgroundColor3 = C.brd
    divLine.BorderSizePixel = 0
    divLine.Parent = iconFrame

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = iconFrame
    btn.MouseButton1Click:Connect(function() switchPage(item.key) end)

    sideIcons[item.key] = { frame = iconFrame, bar = accentBar, label = iconLabel }
    iconY = iconY + 40
end

-- ================================
-- СТРАНИЦА: ПОЛЁТ / ДВИЖЕНИЕ
-- ================================

local flyPad = makePage("fly")

-- Приветствие
local greetCard = Instance.new("Frame")
greetCard.Size = UDim2.new(1, 0, 0, 40)
greetCard.BackgroundColor3 = C.bg2
greetCard.BorderSizePixel = 0
greetCard.LayoutOrder = 0
greetCard.Parent = flyPad

local accentLeft = Instance.new("Frame")
accentLeft.Size = UDim2.new(0, 2, 1, 0)
accentLeft.BackgroundColor3 = C.acc
accentLeft.BorderSizePixel = 0
accentLeft.Parent = greetCard

local greetLbl = Instance.new("TextLabel")
greetLbl.Size = UDim2.new(1, -60, 1, 0)
greetLbl.Position = UDim2.new(0, 10, 0, 0)
greetLbl.BackgroundTransparency = 1
greetLbl.Text = "Привет, " .. localPlayer.DisplayName
greetLbl.TextColor3 = C.tx1
greetLbl.TextSize = 13
greetLbl.Font = Enum.Font.GothamBold
greetLbl.TextXAlignment = Enum.TextXAlignment.Left
greetLbl.Parent = greetCard

local onlineBadge = Instance.new("Frame")
onlineBadge.Size = UDim2.new(0, 48, 0, 16)
onlineBadge.Position = UDim2.new(1, -56, 0.5, -8)
onlineBadge.BackgroundColor3 = Color3.fromRGB(13, 92, 46)
onlineBadge.BorderSizePixel = 0
onlineBadge.Parent = greetCard

local onlineLbl = Instance.new("TextLabel")
onlineLbl.Size = UDim2.new(1, 0, 1, 0)
onlineLbl.BackgroundTransparency = 1
onlineLbl.Text = "ONLINE"
onlineLbl.TextColor3 = Color3.fromRGB(74, 222, 128)
onlineLbl.TextSize = 9
onlineLbl.Font = Enum.Font.GothamBold
onlineLbl.Parent = onlineBadge

-- Секция кнопок
local secFly1 = Instance.new("TextLabel")
secFly1.Size = UDim2.new(1, 0, 0, 16)
secFly1.BackgroundTransparency = 1
secFly1.Text = "ОСНОВНЫЕ ФУНКЦИИ"
secFly1.TextColor3 = C.tx3
secFly1.TextSize = 9
secFly1.Font = Enum.Font.GothamBold
secFly1.TextXAlignment = Enum.TextXAlignment.Left
secFly1.LayoutOrder = 1
secFly1.Parent = flyPad

-- Грид плиток
local function addTileGrid(items, startOrder, parent)
    local rows = math.ceil(#items / 2)
    for row = 1, rows do
        local gridRow = Instance.new("Frame")
        gridRow.Size = UDim2.new(1, 0, 0, 56)
        gridRow.BackgroundTransparency = 1
        gridRow.LayoutOrder = startOrder + row
        gridRow.Parent = parent

        local gl = Instance.new("UIListLayout")
        gl.FillDirection = Enum.FillDirection.Horizontal
        gl.SortOrder = Enum.SortOrder.LayoutOrder
        gl.Padding = UDim.new(0, 6)
        gl.Parent = gridRow

        for col = 1, 2 do
            local idx = (row - 1) * 2 + col
            local item = items[idx]

            local tile = Instance.new("Frame")
            tile.Size = UDim2.new(0.5, -3, 1, 0)
            tile.BackgroundColor3 = C.bg2
            tile.BorderSizePixel = 0
            tile.LayoutOrder = col
            tile.Parent = gridRow

            if item then
                local aBar = Instance.new("Frame")
                aBar.Size = UDim2.new(1, 0, 0, 2)
                aBar.Position = UDim2.new(0, 0, 1, -2)
                aBar.BackgroundColor3 = C.brd
                aBar.BorderSizePixel = 0
                aBar.Parent = tile

                local tdot = Instance.new("Frame")
                tdot.Size = UDim2.new(0, 7, 0, 7)
                tdot.Position = UDim2.new(1, -14, 0, 10)
                tdot.BackgroundColor3 = C.brd2
                tdot.BorderSizePixel = 0
                tdot.Parent = tile

                local tlbl = Instance.new("TextLabel")
                tlbl.Size = UDim2.new(1, -12, 0, 16)
                tlbl.Position = UDim2.new(0, 10, 0, 10)
                tlbl.BackgroundTransparency = 1
                tlbl.Text = item.label
                tlbl.TextColor3 = C.tx2
                tlbl.TextSize = 11
                tlbl.Font = Enum.Font.Gotham
                tlbl.TextXAlignment = Enum.TextXAlignment.Left
                tlbl.Parent = tile

                local tkbg = Instance.new("Frame")
                tkbg.Size = UDim2.new(0, 30, 0, 14)
                tkbg.Position = UDim2.new(0, 10, 0, 32)
                tkbg.BackgroundColor3 = C.bg0
                tkbg.BorderSizePixel = 0
                tkbg.Parent = tile

                local tkl = Instance.new("TextLabel")
                tkl.Size = UDim2.new(1, 0, 1, 0)
                tkl.BackgroundTransparency = 1
                tkl.Text = item.key
                tkl.TextColor3 = C.tx3
                tkl.TextSize = 9
                tkl.Font = Enum.Font.GothamBold
                tkl.Parent = tkbg

                local tstate = false
                local function setTState(v)
                    tstate = v
                    tile.BackgroundColor3 = v and C.acc3 or C.bg2
                    aBar.BackgroundColor3 = v and C.acc2 or C.brd
                    tdot.BackgroundColor3 = v and C.acc2 or C.brd2
                    tlbl.TextColor3 = v and C.tx1 or C.tx2
                    tkbg.BackgroundColor3 = v and C.acc4 or C.bg0
                    tkl.TextColor3 = v and C.acc2 or C.tx3
                    if item.callback then item.callback(v) end
                end
                item.setState = setTState
                item.toggle = function() setTState(not tstate) end

                local tbtn = Instance.new("TextButton")
                tbtn.Size = UDim2.new(1, 0, 1, 0)
                tbtn.BackgroundTransparency = 1
                tbtn.Text = ""
                tbtn.Parent = tile
                tbtn.MouseButton1Click:Connect(function() setTState(not tstate) end)
            end
        end
    end
end

local flyToggleFn, noclipToggleFn

local flyItems = {
    { label = "Полёт",     key = keyName(binds.fly),    callback = function(v) if v then enableFly() else disableFly() end end },
    { label = "Ноуклип",   key = keyName(binds.noclip), callback = function(v) config.noclip = v
        if not v then
            local ch = localPlayer.Character
            if ch then for _, p in pairs(ch:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = true end end end
        end
    end },
    { label = "WalkSpeed", key = keyName(binds.walkSpeed),  callback = function(v) if _G.setWalkToggle then _G.setWalkToggle(v) end end },
    { label = "JumpHeight",key = keyName(binds.jumpHeight), callback = function(v) if _G.setJumpToggle then _G.setJumpToggle(v) end end },
}
addTileGrid(flyItems, 2, flyPad)

-- Слайдеры скоростей
local secFly2 = Instance.new("TextLabel")
secFly2.Size = UDim2.new(1, 0, 0, 16)
secFly2.BackgroundTransparency = 1
secFly2.Text = "СКОРОСТИ"
secFly2.TextColor3 = C.tx3
secFly2.TextSize = 9
secFly2.Font = Enum.Font.GothamBold
secFly2.TextXAlignment = Enum.TextXAlignment.Left
secFly2.LayoutOrder = 10
secFly2.Parent = flyPad

local flySlider = makeSlider({
    label = "Скорость полёта", order = 11, sliderMin = 10, sliderMax = 200,
    initVal = config.flySpeed, fillColor = C.acc, valBg = C.acc3, valColor = C.acc2,
    withToggle = false,
    onChanged = function(v) config.flySpeed = v end,
})
flySlider.card.LayoutOrder = 11
flySlider.card.Parent = flyPad

local wsSlider = makeSlider({
    label = "Скорость ходьбы", order = 12, sliderMin = 8, sliderMax = 100,
    initVal = config.walkSpeed, fillColor = C.grn,
    valBg = Color3.fromRGB(13, 92, 46), valColor = Color3.fromRGB(74, 222, 128),
    withToggle = true,
    onChanged = function(v)
        config.walkSpeed = v
        if config.walkSpeedEnabled then
            local ch = localPlayer.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = v end
        end
    end,
    onToggle = function(v, val)
        config.walkSpeedEnabled = v
        local ch = localPlayer.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v and val or 16 end
    end,
})
wsSlider.card.LayoutOrder = 12
wsSlider.card.Parent = flyPad
_G.setWalkToggle = wsSlider.card._setTog or function() end

local jhSlider = makeSlider({
    label = "Высота прыжка", order = 13, sliderMin = 0, sliderMax = 100,
    initVal = config.jumpHeight, fillColor = Color3.fromRGB(161, 98, 7),
    valBg = Color3.fromRGB(28, 18, 0), valColor = Color3.fromRGB(251, 191, 36),
    withToggle = true,
    onChanged = function(v)
        config.jumpHeight = v
        if config.jumpHeightEnabled then
            local ch = localPlayer.Character
            local hum = ch and ch:FindFirstChildOfClass("Humanoid")
            if hum then hum.JumpHeight = v; hum.JumpPower = v end
        end
    end,
    onToggle = function(v, val)
        config.jumpHeightEnabled = v
        local ch = localPlayer.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpHeight = v and val or 7; hum.JumpPower = v and val or 7 end
    end,
})
jhSlider.card.LayoutOrder = 13
jhSlider.card.Parent = flyPad

-- ================================
-- СТРАНИЦА: ESP
-- ================================

local espPad = makePage("esp")

local espEnabled = false
local espFolder = nil
local espPlayerFolders = {}

-- Состояние ESP
local espSecState = Instance.new("TextLabel")
espSecState.Size = UDim2.new(1, 0, 0, 16)
espSecState.BackgroundTransparency = 1
espSecState.Text = "СОСТОЯНИЕ"
espSecState.TextColor3 = C.tx3
espSecState.TextSize = 9
espSecState.Font = Enum.Font.GothamBold
espSecState.TextXAlignment = Enum.TextXAlignment.Left
espSecState.LayoutOrder = 0
espSecState.Parent = espPad

local espToggleFn = function() end
local espItems = {
    { label = "ESP включён", key = keyName(binds.esp), callback = function(v)
        espEnabled = v
        if v then enableESP() else disableESP() end
    end },
    { label = "Показ ников", key = "—", callback = function(v) end },
}
addTileGrid(espItems, 1, espPad)

-- MM2 роли
local mm2SecLbl = Instance.new("TextLabel")
mm2SecLbl.Size = UDim2.new(1, 0, 0, 16)
mm2SecLbl.BackgroundTransparency = 1
mm2SecLbl.Text = "РОЛИ MM2"
mm2SecLbl.TextColor3 = C.tx3
mm2SecLbl.TextSize = 9
mm2SecLbl.Font = Enum.Font.GothamBold
mm2SecLbl.TextXAlignment = Enum.TextXAlignment.Left
mm2SecLbl.LayoutOrder = 5
mm2SecLbl.Parent = espPad

local mm2Grid = Instance.new("Frame")
mm2Grid.Size = UDim2.new(1, 0, 0, 32)
mm2Grid.BackgroundTransparency = 1
mm2Grid.LayoutOrder = 6
mm2Grid.Parent = espPad

local mm2GL = Instance.new("UIListLayout")
mm2GL.FillDirection = Enum.FillDirection.Horizontal
mm2GL.SortOrder = Enum.SortOrder.LayoutOrder
mm2GL.Padding = UDim.new(0, 6)
mm2GL.Parent = mm2Grid

local mm2Roles = {
    { label = "убийца",    color = Color3.fromRGB(255, 30, 30)  },
    { label = "шериф",     color = Color3.fromRGB(60, 140, 255) },
    { label = "невинный",  color = Color3.fromRGB(0, 220, 80)   },
}
for i, r in ipairs(mm2Roles) do
    local rf = Instance.new("Frame")
    rf.Size = UDim2.new(0, 1, 1, 0)  -- будет расширен флексом
    rf.BackgroundColor3 = C.bg2
    rf.BorderSizePixel = 0
    rf.LayoutOrder = i
    rf.AutomaticSize = Enum.AutomaticSize.None
    rf.Parent = mm2Grid

    -- Ставим нормальный размер
    rf.Size = UDim2.new(0.333, -4, 1, 0)

    local rdot = Instance.new("Frame")
    rdot.Size = UDim2.new(0, 8, 0, 8)
    rdot.Position = UDim2.new(0, 8, 0.5, -4)
    rdot.BackgroundColor3 = r.color
    rdot.BorderSizePixel = 0
    rdot.Parent = rf

    local rlbl = Instance.new("TextLabel")
    rlbl.Size = UDim2.new(1, -24, 1, 0)
    rlbl.Position = UDim2.new(0, 22, 0, 0)
    rlbl.BackgroundTransparency = 1
    rlbl.Text = r.label
    rlbl.TextColor3 = C.tx2
    rlbl.TextSize = 10
    rlbl.Font = Enum.Font.Gotham
    rlbl.TextXAlignment = Enum.TextXAlignment.Left
    rlbl.Parent = rf
end

-- Цвета ESP
local espColorOrder = 10

local function espColorSection(title, colorKey)
    local hdr = Instance.new("Frame")
    hdr.Size = UDim2.new(1, 0, 0, 24)
    hdr.BackgroundColor3 = C.bg3
    hdr.BorderSizePixel = 0
    hdr.LayoutOrder = espColorOrder
    hdr.Parent = espPad
    espColorOrder = espColorOrder + 1

    local acl = Instance.new("Frame")
    acl.Size = UDim2.new(0, 2, 1, 0)
    acl.BackgroundColor3 = C.acc
    acl.BorderSizePixel = 0
    acl.Parent = hdr

    local hl = Instance.new("TextLabel")
    hl.Size = UDim2.new(1, -10, 1, 0)
    hl.Position = UDim2.new(0, 10, 0, 0)
    hl.BackgroundTransparency = 1
    hl.Text = title
    hl.TextColor3 = C.tx2
    hl.TextSize = 10
    hl.Font = Enum.Font.GothamBold
    hl.TextXAlignment = Enum.TextXAlignment.Left
    hl.Parent = hdr

    local rows = {
        { label = "контур",  getF = function() return espColors[colorKey].outline end, setF = function(c) espColors[colorKey].outline = c end },
        { label = "заливка", getF = function() return espColors[colorKey].fill    end, setF = function(c) espColors[colorKey].fill    = c end },
        { label = "текст",   getF = function() return espColors[colorKey].text    end, setF = function(c) espColors[colorKey].text    = c end },
    }
    for _, row in ipairs(rows) do
        makeColorRow(row.label, espColorOrder, row.getF, row.setF, function()
            if espEnabled then refreshAllESP() end
        end)
        espColorOrder = espColorOrder + 1
    end
end

local espSecColors = Instance.new("TextLabel")
espSecColors.Size = UDim2.new(1, 0, 0, 16)
espSecColors.BackgroundTransparency = 1
espSecColors.Text = "ЦВЕТА ESP"
espSecColors.TextColor3 = C.tx3
espSecColors.TextSize = 9
espSecColors.Font = Enum.Font.GothamBold
espSecColors.TextXAlignment = Enum.TextXAlignment.Left
espSecColors.LayoutOrder = 9
espSecColors.Parent = espPad

espColorSection("Обычный игрок",  "normal")
espColorSection("MM2 — убийца",   "mm2_murderer")
espColorSection("MM2 — шериф",    "mm2_sheriff")
espColorSection("MM2 — невинный", "mm2_innocent")
espColorSection("TG / TGK",       "tg")
espColorSection("YT",             "yt")
espColorSection("TT",             "tt")

-- ================================
-- СТРАНИЦА: ПРЕСЛЕДОВАНИЕ
-- ================================

local followPad = makePage("follow")

local followSecLbl = Instance.new("TextLabel")
followSecLbl.Size = UDim2.new(1, 0, 0, 16)
followSecLbl.BackgroundTransparency = 1
followSecLbl.Text = "ПОИСК ИГРОКА"
followSecLbl.TextColor3 = C.tx3
followSecLbl.TextSize = 9
followSecLbl.Font = Enum.Font.GothamBold
followSecLbl.TextXAlignment = Enum.TextXAlignment.Left
followSecLbl.LayoutOrder = 0
followSecLbl.Parent = followPad

-- Поиск
local searchCard = Instance.new("Frame")
searchCard.Size = UDim2.new(1, 0, 0, 34)
searchCard.BackgroundColor3 = C.bg2
searchCard.BorderSizePixel = 0
searchCard.LayoutOrder = 1
searchCard.Parent = followPad

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -16, 1, -8)
searchBox.Position = UDim2.new(0, 8, 0, 4)
searchBox.BackgroundTransparency = 1
searchBox.Text = ""
searchBox.PlaceholderText = "Поиск по нику..."
searchBox.PlaceholderColor3 = C.tx3
searchBox.TextColor3 = C.tx2
searchBox.TextSize = 12
searchBox.Font = Enum.Font.Gotham
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchCard

-- Список игроков
local playerListFrame = Instance.new("Frame")
playerListFrame.Size = UDim2.new(1, 0, 0, 120)
playerListFrame.BackgroundColor3 = C.bg2
playerListFrame.BorderSizePixel = 0
playerListFrame.LayoutOrder = 2
playerListFrame.Parent = followPad

local playerScroll = Instance.new("ScrollingFrame")
playerScroll.Size = UDim2.new(1, -6, 1, -6)
playerScroll.Position = UDim2.new(0, 3, 0, 3)
playerScroll.BackgroundTransparency = 1
playerScroll.BorderSizePixel = 0
playerScroll.ScrollBarThickness = 2
playerScroll.ScrollBarImageColor3 = C.brd2
playerScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
playerScroll.Parent = playerListFrame

local playerLayout = Instance.new("UIListLayout")
playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerLayout.Padding = UDim.new(0, 2)
playerLayout.Parent = playerScroll

-- Управление следованием
local followSecLbl2 = Instance.new("TextLabel")
followSecLbl2.Size = UDim2.new(1, 0, 0, 16)
followSecLbl2.BackgroundTransparency = 1
followSecLbl2.Text = "УПРАВЛЕНИЕ"
followSecLbl2.TextColor3 = C.tx3
followSecLbl2.TextSize = 9
followSecLbl2.Font = Enum.Font.GothamBold
followSecLbl2.TextXAlignment = Enum.TextXAlignment.Left
followSecLbl2.LayoutOrder = 3
followSecLbl2.Parent = followPad

-- Кнопка остановить
local stopCard = Instance.new("Frame")
stopCard.Size = UDim2.new(1, 0, 0, 42)
stopCard.BackgroundColor3 = C.bg2
stopCard.BorderSizePixel = 0
stopCard.LayoutOrder = 4
stopCard.Parent = followPad

local stopAccent = Instance.new("Frame")
stopAccent.Size = UDim2.new(0, 2, 1, 0)
stopAccent.BackgroundColor3 = C.red
stopAccent.BorderSizePixel = 0
stopAccent.Parent = stopCard

local stopLbl = Instance.new("TextLabel")
stopLbl.Size = UDim2.new(1, -10, 1, 0)
stopLbl.Position = UDim2.new(0, 10, 0, 0)
stopLbl.BackgroundTransparency = 1
stopLbl.Text = "Остановить преследование"
stopLbl.TextColor3 = C.red2
stopLbl.TextSize = 12
stopLbl.Font = Enum.Font.GothamBold
stopLbl.TextXAlignment = Enum.TextXAlignment.Left
stopLbl.Parent = stopCard

-- Слайдеры следования
local followSliders = Instance.new("TextLabel")
followSliders.Size = UDim2.new(1, 0, 0, 16)
followSliders.BackgroundTransparency = 1
followSliders.Text = "НАСТРОЙКИ СЛЕДОВАНИЯ"
followSliders.TextColor3 = C.tx3
followSliders.TextSize = 9
followSliders.Font = Enum.Font.GothamBold
followSliders.TextXAlignment = Enum.TextXAlignment.Left
followSliders.LayoutOrder = 5
followSliders.Parent = followPad

local distSlider = makeSlider({
    label = "Дистанция следования", order = 6, sliderMin = 1, sliderMax = 20,
    initVal = config.followDistance, fillColor = C.acc, valBg = C.acc3, valColor = C.acc2,
    withToggle = false,
    onChanged = function(v) config.followDistance = v end,
})
distSlider.card.LayoutOrder = 6
distSlider.card.Parent = followPad

local heightSlider = makeSlider({
    label = "Высота над целью", order = 7, sliderMin = 0, sliderMax = 15,
    initVal = config.followHeight, fillColor = C.acc, valBg = C.acc3, valColor = C.acc2,
    withToggle = false,
    onChanged = function(v) config.followHeight = v end,
})
heightSlider.card.LayoutOrder = 7
heightSlider.card.Parent = followPad

local selectedBtn = nil
local searchQuery = ""

local function refreshPlayers()
    for _, c in pairs(playerScroll:GetChildren()) do
        if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
    end
    selectedBtn = nil
    local count = 0
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            local searchTarget = (p.DisplayName .. " " .. p.Name):lower()
            if searchQuery == "" or searchTarget:find(searchQuery:lower(), 1, true) then
                count += 1
                local ptype = getPlayerType(p)
                local badgeText = ptype == "tg" and "TG" or ptype == "yt" and "YT" or ptype == "tt" and "TT" or "—"

                local pItem = Instance.new("Frame")
                pItem.Size = UDim2.new(1, -4, 0, 28)
                pItem.BackgroundColor3 = C.bg3
                pItem.BorderSizePixel = 0
                pItem.LayoutOrder = count
                pItem.Parent = playerScroll

                if config.targetPlayer == p then
                    pItem.BackgroundColor3 = C.acc3
                    selectedBtn = pItem
                end

                local pAccent = Instance.new("Frame")
                pAccent.Size = UDim2.new(0, 2, 1, 0)
                pAccent.BackgroundColor3 = config.targetPlayer == p and C.acc2 or C.brd
                pAccent.BorderSizePixel = 0
                pAccent.Parent = pItem

                local pNameLbl = Instance.new("TextLabel")
                pNameLbl.Size = UDim2.new(1, -50, 1, 0)
                pNameLbl.Position = UDim2.new(0, 8, 0, 0)
                pNameLbl.BackgroundTransparency = 1
                pNameLbl.Text = p.DisplayName .. " (@" .. p.Name .. ")"
                pNameLbl.TextColor3 = config.targetPlayer == p and C.tx1 or C.tx2
                pNameLbl.TextSize = 11
                pNameLbl.Font = Enum.Font.Gotham
                pNameLbl.TextXAlignment = Enum.TextXAlignment.Left
                pNameLbl.TextTruncate = Enum.TextTruncate.AtEnd
                pNameLbl.Parent = pItem

                if badgeText ~= "—" then
                    local badge = Instance.new("Frame")
                    badge.Size = UDim2.new(0, 26, 0, 14)
                    badge.Position = UDim2.new(1, -30, 0.5, -7)
                    badge.BackgroundColor3 = ptype == "tg" and Color3.fromRGB(28, 18, 0)
                        or ptype == "yt" and Color3.fromRGB(28, 0, 0)
                        or Color3.fromRGB(10, 10, 14)
                    badge.BorderSizePixel = 0
                    badge.Parent = pItem

                    local badgeLbl = Instance.new("TextLabel")
                    badgeLbl.Size = UDim2.new(1, 0, 1, 0)
                    badgeLbl.BackgroundTransparency = 1
                    badgeLbl.Text = badgeText
                    badgeLbl.TextColor3 = ptype == "tg" and Color3.fromRGB(202, 138, 4)
                        or ptype == "yt" and Color3.fromRGB(220, 38, 38)
                        or Color3.fromRGB(180, 180, 180)
                    badgeLbl.TextSize = 9
                    badgeLbl.Font = Enum.Font.GothamBold
                    badgeLbl.Parent = badge
                end

                local pBtn = Instance.new("TextButton")
                pBtn.Size = UDim2.new(1, 0, 1, 0)
                pBtn.BackgroundTransparency = 1
                pBtn.Text = ""
                pBtn.Parent = pItem
                pBtn.MouseButton1Click:Connect(function()
                    for _, c in pairs(playerScroll:GetChildren()) do
                        if c:IsA("Frame") then
                            c.BackgroundColor3 = C.bg3
                            local acc = c:FindFirstChildOfClass("Frame")
                            if acc then acc.BackgroundColor3 = C.brd end
                            local nl = c:FindFirstChildOfClass("TextLabel")
                            if nl then nl.TextColor3 = C.tx2 end
                        end
                    end
                    pItem.BackgroundColor3 = C.acc3
                    pAccent.BackgroundColor3 = C.acc2
                    pNameLbl.TextColor3 = C.tx1
                    selectedBtn = pItem
                    config.targetPlayer = p
                    config.following = true
                    if not config.flying then enableFly() end
                end)
            end
        end
    end
    playerScroll.CanvasSize = UDim2.new(0, 0, 0, count * 30)
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchQuery = searchBox.Text
    refreshPlayers()
end)
refreshPlayers()
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(function() task.wait(0.1) refreshPlayers() end)

local doStopFollow
stopCard.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        if doStopFollow then doStopFollow() end
    end
end)

doStopFollow = function()
    config.following = false
    config.targetPlayer = nil
    for _, c in pairs(playerScroll:GetChildren()) do
        if c:IsA("Frame") then
            c.BackgroundColor3 = C.bg3
            local acc = c:FindFirstChild("Frame")
            if acc then acc.BackgroundColor3 = C.brd end
        end
    end
    selectedBtn = nil
    if not config.flying then task.delay(0.1, unfreezeChar) end
end

-- ================================
-- СТРАНИЦА: БИНДЫ
-- ================================

local bindsPad = makePage("binds")

local bindsSecLbl = Instance.new("TextLabel")
bindsSecLbl.Size = UDim2.new(1, 0, 0, 16)
bindsSecLbl.BackgroundTransparency = 1
bindsSecLbl.Text = "ГОРЯЧИЕ КЛАВИШИ"
bindsSecLbl.TextColor3 = C.tx3
bindsSecLbl.TextSize = 9
bindsSecLbl.Font = Enum.Font.GothamBold
bindsSecLbl.TextXAlignment = Enum.TextXAlignment.Left
bindsSecLbl.LayoutOrder = 0
bindsSecLbl.Parent = bindsPad

local hintLbl = Instance.new("TextLabel")
hintLbl.Size = UDim2.new(1, 0, 0, 14)
hintLbl.BackgroundTransparency = 1
hintLbl.Text = "нажмите на плитку чтобы изменить бинд"
hintLbl.TextColor3 = C.tx3
hintLbl.TextSize = 10
hintLbl.Font = Enum.Font.Gotham
hintLbl.TextXAlignment = Enum.TextXAlignment.Left
hintLbl.LayoutOrder = 20
hintLbl.Parent = bindsPad

local listeningFor = nil
local bindKeyLabels = {}

local bindRowData = {
    { key = "fly",        label = "Полёт"                  },
    { key = "noclip",     label = "Ноуклип"                },
    { key = "unfollow",   label = "Отменить преследование" },
    { key = "esp",        label = "ESP"                    },
    { key = "menu",       label = "Меню"                   },
    { key = "walkSpeed",  label = "WalkSpeed"              },
    { key = "jumpHeight", label = "JumpHeight"             },
}

local bindGrid = Instance.new("Frame")
bindGrid.Size = UDim2.new(1, 0, 0, math.ceil(#bindRowData / 2) * 62)
bindGrid.BackgroundTransparency = 1
bindGrid.LayoutOrder = 1
bindGrid.Parent = bindsPad

local bindGL = Instance.new("UIGridLayout")
bindGL.CellSize = UDim2.new(0.5, -3, 0, 58)
bindGL.CellPadding = UDim2.new(0, 6, 0, 6)
bindGL.SortOrder = Enum.SortOrder.LayoutOrder
bindGL.Parent = bindGrid

for i, bd in ipairs(bindRowData) do
    local cell = Instance.new("Frame")
    cell.BackgroundColor3 = C.bg2
    cell.BorderSizePixel = 0
    cell.LayoutOrder = i
    cell.Parent = bindGrid

    local bAccent = Instance.new("Frame")
    bAccent.Size = UDim2.new(1, 0, 0, 2)
    bAccent.Position = UDim2.new(0, 0, 1, -2)
    bAccent.BackgroundColor3 = C.brd
    bAccent.BorderSizePixel = 0
    bAccent.Parent = cell

    local bLbl = Instance.new("TextLabel")
    bLbl.Size = UDim2.new(1, -12, 0, 16)
    bLbl.Position = UDim2.new(0, 10, 0, 8)
    bLbl.BackgroundTransparency = 1
    bLbl.Text = bd.label
    bLbl.TextColor3 = C.tx2
    bLbl.TextSize = 10
    bLbl.Font = Enum.Font.Gotham
    bLbl.TextXAlignment = Enum.TextXAlignment.Left
    bLbl.Parent = cell

    local keyBg = Instance.new("Frame")
    keyBg.Size = UDim2.new(0, 40, 0, 18)
    keyBg.Position = UDim2.new(0, 10, 0, 30)
    keyBg.BackgroundColor3 = C.acc4
    keyBg.BorderSizePixel = 0
    keyBg.Parent = cell

    local keyLbl = Instance.new("TextLabel")
    keyLbl.Size = UDim2.new(1, 0, 1, 0)
    keyLbl.BackgroundTransparency = 1
    keyLbl.Text = keyName(binds[bd.key])
    keyLbl.TextColor3 = C.acc2
    keyLbl.TextSize = 11
    keyLbl.Font = Enum.Font.GothamBold
    keyLbl.Parent = keyBg

    bindKeyLabels[bd.key] = { lbl = keyLbl, bg = keyBg, accent = bAccent }

    local bBtn = Instance.new("TextButton")
    bBtn.Size = UDim2.new(1, 0, 1, 0)
    bBtn.BackgroundTransparency = 1
    bBtn.Text = ""
    bBtn.Parent = cell
    bBtn.MouseButton1Click:Connect(function()
        if listeningFor == bd.key then
            listeningFor = nil
            keyLbl.Text = keyName(binds[bd.key])
            keyBg.BackgroundColor3 = C.acc4
            keyLbl.TextColor3 = C.acc2
            bAccent.BackgroundColor3 = C.brd
            hintLbl.Text = "нажмите на плитку чтобы изменить бинд"
        else
            if listeningFor then
                local old = bindKeyLabels[listeningFor]
                if old then
                    old.lbl.Text = keyName(binds[listeningFor])
                    old.bg.BackgroundColor3 = C.acc4
                    old.lbl.TextColor3 = C.acc2
                    old.accent.BackgroundColor3 = C.brd
                end
            end
            listeningFor = bd.key
            keyLbl.Text = "..."
            keyBg.BackgroundColor3 = Color3.fromRGB(28, 18, 0)
            keyLbl.TextColor3 = Color3.fromRGB(251, 191, 36)
            bAccent.BackgroundColor3 = Color3.fromRGB(251, 191, 36)
            hintLbl.Text = "нажмите любую клавишу..."
        end
    end)
end

-- ================================
-- СТРАНИЦА: СОХРАНИТЬ / ЗАГРУЗИТЬ
-- ================================

local savePad = makePage("save")

local saveSecLbl = Instance.new("TextLabel")
saveSecLbl.Size = UDim2.new(1, 0, 0, 16)
saveSecLbl.BackgroundTransparency = 1
saveSecLbl.Text = "УПРАВЛЕНИЕ НАСТРОЙКАМИ"
saveSecLbl.TextColor3 = C.tx3
saveSecLbl.TextSize = 9
saveSecLbl.Font = Enum.Font.GothamBold
saveSecLbl.TextXAlignment = Enum.TextXAlignment.Left
saveSecLbl.LayoutOrder = 0
saveSecLbl.Parent = savePad

-- Кнопки сохранения (плитки 2 колонки)
local saveBtnsGrid = Instance.new("Frame")
saveBtnsGrid.Size = UDim2.new(1, 0, 0, 62)
saveBtnsGrid.BackgroundTransparency = 1
saveBtnsGrid.LayoutOrder = 1
saveBtnsGrid.Parent = savePad

local saveGL = Instance.new("UIListLayout")
saveGL.FillDirection = Enum.FillDirection.Horizontal
saveGL.SortOrder = Enum.SortOrder.LayoutOrder
saveGL.Padding = UDim.new(0, 6)
saveGL.Parent = saveBtnsGrid

local function makeSaveBtn(labelText, iconText, accentColor, order)
    local btn = Instance.new("Frame")
    btn.Size = UDim2.new(0.5, -3, 1, 0)
    btn.BackgroundColor3 = C.bg2
    btn.BorderSizePixel = 0
    btn.LayoutOrder = order
    btn.Parent = saveBtnsGrid

    local bAccent = Instance.new("Frame")
    bAccent.Size = UDim2.new(1, 0, 0, 2)
    bAccent.Position = UDim2.new(0, 0, 1, -2)
    bAccent.BackgroundColor3 = accentColor
    bAccent.BorderSizePixel = 0
    bAccent.Parent = btn

    local ico = Instance.new("TextLabel")
    ico.Size = UDim2.new(1, 0, 0, 24)
    ico.Position = UDim2.new(0, 0, 0, 8)
    ico.BackgroundTransparency = 1
    ico.Text = iconText
    ico.TextColor3 = accentColor
    ico.TextSize = 18
    ico.Font = Enum.Font.Gotham
    ico.Parent = btn

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 14)
    lbl.Position = UDim2.new(0, 0, 0, 36)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = accentColor
    lbl.TextSize = 9
    lbl.Font = Enum.Font.GothamBold
    lbl.Parent = btn

    local tbtn = Instance.new("TextButton")
    tbtn.Size = UDim2.new(1, 0, 1, 0)
    tbtn.BackgroundTransparency = 1
    tbtn.Text = ""
    tbtn.Parent = btn

    return btn, tbtn
end

local saveCard, saveTBtn = makeSaveBtn("СОХРАНИТЬ", "💾", C.grn, 1)
local loadCard, loadTBtn = makeSaveBtn("ЗАГРУЗИТЬ", "📂", C.acc2, 2)

local saveStatusLbl = Instance.new("TextLabel")
saveStatusLbl.Size = UDim2.new(1, 0, 0, 14)
saveStatusLbl.BackgroundTransparency = 1
saveStatusLbl.Text = ""
saveStatusLbl.TextColor3 = C.grn
saveStatusLbl.TextSize = 10
saveStatusLbl.Font = Enum.Font.GothamBold
saveStatusLbl.TextXAlignment = Enum.TextXAlignment.Center
saveStatusLbl.LayoutOrder = 2
saveStatusLbl.Parent = savePad

local function showStatus(msg, isErr)
    saveStatusLbl.Text = msg
    saveStatusLbl.TextColor3 = isErr and C.red2 or C.grn
    task.delay(2.5, function() saveStatusLbl.Text = "" end)
end

-- Инфо
local infoSecLbl = Instance.new("TextLabel")
infoSecLbl.Size = UDim2.new(1, 0, 0, 16)
infoSecLbl.BackgroundTransparency = 1
infoSecLbl.Text = "ИНФОРМАЦИЯ"
infoSecLbl.TextColor3 = C.tx3
infoSecLbl.TextSize = 9
infoSecLbl.Font = Enum.Font.GothamBold
infoSecLbl.TextXAlignment = Enum.TextXAlignment.Left
infoSecLbl.LayoutOrder = 3
infoSecLbl.Parent = savePad

local infoCard = Instance.new("Frame")
infoCard.Size = UDim2.new(1, 0, 0, 60)
infoCard.BackgroundColor3 = C.acc3
infoCard.BorderSizePixel = 0
infoCard.LayoutOrder = 4
infoCard.Parent = savePad

local infoAccent = Instance.new("Frame")
infoAccent.Size = UDim2.new(0, 2, 1, 0)
infoAccent.BackgroundColor3 = C.acc2
infoAccent.BorderSizePixel = 0
infoAccent.Parent = infoCard

local infoBrand = Instance.new("TextLabel")
infoBrand.Size = UDim2.new(1, -10, 0, 16)
infoBrand.Position = UDim2.new(0, 10, 0, 6)
infoBrand.BackgroundTransparency = 1
infoBrand.Text = "DREAMCOMPANY"
infoBrand.TextColor3 = C.acc2
infoBrand.TextSize = 10
infoBrand.Font = Enum.Font.GothamBold
infoBrand.TextXAlignment = Enum.TextXAlignment.Left
infoBrand.Parent = infoCard

local infoVer = Instance.new("TextLabel")
infoVer.Size = UDim2.new(1, -10, 0, 14)
infoVer.Position = UDim2.new(0, 10, 0, 24)
infoVer.BackgroundTransparency = 1
infoVer.Text = "Testing GUI v1.8.0"
infoVer.TextColor3 = C.tx2
infoVer.TextSize = 12
infoVer.Font = Enum.Font.GothamBold
infoVer.TextXAlignment = Enum.TextXAlignment.Left
infoVer.Parent = infoCard

local infoSub = Instance.new("TextLabel")
infoSub.Size = UDim2.new(1, -10, 0, 12)
infoSub.Position = UDim2.new(0, 10, 0, 40)
infoSub.BackgroundTransparency = 1
infoSub.Text = "Fly · Noclip · ESP (TG/TGK/YT/TT/MM2) · Follow"
infoSub.TextColor3 = C.tx3
infoSub.TextSize = 10
infoSub.Font = Enum.Font.Gotham
infoSub.TextXAlignment = Enum.TextXAlignment.Left
infoSub.Parent = infoCard

-- ================================
-- ПОЛЁТ
-- ================================

local bodyVelocity, bodyGyro

local function unfreezeChar()
    local char = localPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hum then hum.PlatformStand = false; hum.AutoRotate = true end
    if hrp then
        for _, v in pairs(hrp:GetChildren()) do
            if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
        end
    end
end

function enableFly()
    local char = localPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
    for _, v in pairs(hrp:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
    end

    hum.PlatformStand = true
    hum.AutoRotate = false

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bodyVelocity.Parent = hrp

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
    bodyGyro.P = 1e4
    bodyGyro.Parent = hrp

    config.flying = true
end

function disableFly()
    if bodyVelocity then bodyVelocity:Destroy(); bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy(); bodyGyro = nil end
    config.flying = false
    config.following = false
    config.targetPlayer = nil
    task.delay(0.1, unfreezeChar)
end

RunService.Stepped:Connect(function()
    if not config.noclip then return end
    local char = localPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end
    end
end)

RunService.Heartbeat:Connect(function()
    if not config.flying then return end
    local char = localPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp or not bodyVelocity or not bodyGyro then return end

    if config.following and config.targetPlayer then
        local tc = config.targetPlayer.Character
        local thrp = tc and tc:FindFirstChild("HumanoidRootPart")
        if thrp then
            local targetPos = thrp.Position + Vector3.new(0, config.followHeight, 0)
            local diff = targetPos - hrp.Position
            local dist = diff.Magnitude
            if dist > config.followDistance then
                bodyVelocity.Velocity = diff.Unit * math.clamp(dist * 3, 5, config.flySpeed * 2)
            else
                bodyVelocity.Velocity = Vector3.zero
            end
            bodyGyro.CFrame = CFrame.new(hrp.Position, thrp.Position)
        end
    else
        local cam = workspace.CurrentCamera
        local move = Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move += cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move -= cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move -= cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move += cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then move += Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move -= Vector3.new(0, 1, 0) end
        bodyVelocity.Velocity = move.Magnitude > 0 and move.Unit * config.flySpeed or Vector3.zero
        bodyGyro.CFrame = cam.CFrame
    end
end)

-- ================================
-- ESP ЛОГИКА
-- ================================

local function removeESP(player)
    local pf = espPlayerFolders[player.Name]
    if pf and pf.Parent then pf:Destroy() end
    espPlayerFolders[player.Name] = nil
end

local createESP
local refreshAllESP

createESP = function(player)
    if player == localPlayer then return end
    if not espFolder or not espFolder.Parent then return end
    removeESP(player)

    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local ptype
    if isInMM2() then
        ptype = getMM2Role(player) or getPlayerType(player)
    else
        ptype = getPlayerType(player)
    end
    local colors = espColors[ptype] or espColors.normal

    local pFolder = Instance.new("Folder")
    pFolder.Name = "PESP_" .. player.Name
    pFolder.Parent = espFolder
    espPlayerFolders[player.Name] = pFolder

    local hl = Instance.new("Highlight")
    hl.Adornee = char
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.OutlineColor = colors.outline
    hl.OutlineTransparency = 0
    hl.FillColor = colors.fill
    hl.FillTransparency = colors.fillTransparency
    hl.Parent = pFolder

    local bb = Instance.new("BillboardGui")
    bb.Name = "BB_" .. player.Name
    bb.Adornee = hrp
    bb.Size = UDim2.new(0, 200, 0, 26)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.ResetOnSpawn = false
    bb.Parent = pFolder

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    local roleTag = ""
    if isInMM2() then
        if ptype == "mm2_murderer" then roleTag = "[НОЖ] "
        elseif ptype == "mm2_sheriff" then roleTag = "[ПИСТ] "
        elseif ptype == "mm2_innocent" then roleTag = "[ИНН] "
        end
    end
    nameLabel.Text = roleTag .. player.DisplayName .. " (@" .. player.Name .. ")"
    nameLabel.TextColor3 = colors.text
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = bb
end

refreshAllESP = function()
    if not espEnabled then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= localPlayer then createESP(p) end
    end
end

local function hookPlayerESP(p)
    p.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        if espEnabled then createESP(p) end
        if isInMM2() then
            char.ChildAdded:Connect(function()
                task.wait(0.1)
                if espEnabled then createESP(p) end
            end)
            char.ChildRemoved:Connect(function()
                task.wait(0.1)
                if espEnabled then createESP(p) end
            end)
        end
    end)
    if isInMM2() then
        local function hookBackpack(bp)
            if not bp then return end
            bp.ChildAdded:Connect(function()
                task.wait(0.1)
                if espEnabled then createESP(p) end
            end)
            bp.ChildRemoved:Connect(function()
                task.wait(0.1)
                if espEnabled then createESP(p) end
            end)
        end
        local bp = p:FindFirstChildOfClass("Backpack")
        hookBackpack(bp)
        p.ChildAdded:Connect(function(child)
            if child:IsA("Backpack") then hookBackpack(child) end
        end)
        p:GetPropertyChangedSignal("Team"):Connect(function()
            task.wait(0.05)
            if espEnabled then createESP(p) end
        end)
    end
end

function enableESP()
    espFolder = Instance.new("Folder")
    espFolder.Name = "TestingESP"
    espFolder.Parent = workspace
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            createESP(p)
            hookPlayerESP(p)
        end
    end
    Players.PlayerAdded:Connect(function(p)
        if not espEnabled then return end
        hookPlayerESP(p)
        task.wait(0.3)
        if espEnabled then createESP(p) end
    end)
    Players.PlayerRemoving:Connect(function(p) removeESP(p) end)
end

function disableESP()
    if espFolder and espFolder.Parent then espFolder:Destroy() end
    espFolder = nil
    for k in pairs(espPlayerFolders) do espPlayerFolders[k] = nil end
end

-- MM2 авто-обновление ролей
do
    local lastRoles = {}
    RunService.Heartbeat:Connect(function()
        if not espEnabled or not isInMM2() then return end
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= localPlayer then
                local role = getMM2Role(p) or "none"
                if lastRoles[p.Name] ~= role then
                    lastRoles[p.Name] = role
                    task.spawn(function()
                        task.wait(0.05)
                        if espEnabled then createESP(p) end
                    end)
                end
            end
        end
    end)
end

-- ================================
-- СОХРАНЕНИЕ / ЗАГРУЗКА
-- ================================

local function colorToStr(c)
    return math.floor(c.R*255).."_"..math.floor(c.G*255).."_"..math.floor(c.B*255)
end
local function strToColor(s)
    local r,g,b = s:match("(%d+)_(%d+)_(%d+)")
    if r then return Color3.fromRGB(tonumber(r),tonumber(g),tonumber(b)) end
    return nil
end

local function serializeSettings()
    return {
        flySpeed              = config.flySpeed,
        bindFly               = tostring(binds.fly),
        bindNoclip            = tostring(binds.noclip),
        bindUnfollow          = tostring(binds.unfollow),
        bindEsp               = tostring(binds.esp),
        bindMenu              = tostring(binds.menu),
        bindWalkSpeed         = tostring(binds.walkSpeed),
        bindJumpHeight        = tostring(binds.jumpHeight),
        espNormalOutline      = colorToStr(espColors.normal.outline),
        espNormalFill         = colorToStr(espColors.normal.fill),
        espNormalText         = colorToStr(espColors.normal.text),
        espTgOutline          = colorToStr(espColors.tg.outline),
        espTgFill             = colorToStr(espColors.tg.fill),
        espTgText             = colorToStr(espColors.tg.text),
        espYtOutline          = colorToStr(espColors.yt.outline),
        espYtFill             = colorToStr(espColors.yt.fill),
        espYtText             = colorToStr(espColors.yt.text),
        espTtOutline          = colorToStr(espColors.tt.outline),
        espTtFill             = colorToStr(espColors.tt.fill),
        espTtText             = colorToStr(espColors.tt.text),
    }
end

saveTBtn.MouseButton1Click:Connect(function()
    local ok = pcall(function()
        writefile(SAVE_FILE, serialize(serializeSettings()))
    end)
    if ok then
        showStatus("✔ Настройки сохранены!", false)
        TweenService:Create(saveCard, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(13, 92, 46)}):Play()
        task.delay(0.3, function()
            TweenService:Create(saveCard, TweenInfo.new(0.2), {BackgroundColor3 = C.bg2}):Play()
        end)
    else
        showStatus("✘ Ошибка сохранения", true)
    end
end)

local function applyLoadedSettings()
    local ok, raw = pcall(function()
        if isfile(SAVE_FILE) then return readfile(SAVE_FILE) end
    end)
    if not ok or not raw then showStatus("✘ Файл не найден", true) return end
    local result = deserialize(raw)

    local spd = tonumber(result.flySpeed)
    if spd then
        config.flySpeed = math.clamp(math.floor(spd), 1, 500)
        flySlider.valLbl.Text = tostring(config.flySpeed)
        local rel = math.clamp((config.flySpeed - 10) / (200 - 10), 0, 1)
        flySlider.fill.Size = UDim2.new(rel, 0, 1, 0)
        flySlider.thumb.Position = UDim2.new(rel, -4, 0.5, -4)
    end

    local bindFields = {
        {field="bindFly",key="fly"},{field="bindNoclip",key="noclip"},
        {field="bindUnfollow",key="unfollow"},{field="bindEsp",key="esp"},
        {field="bindMenu",key="menu"},{field="bindWalkSpeed",key="walkSpeed"},
        {field="bindJumpHeight",key="jumpHeight"},
    }
    for _, b in ipairs(bindFields) do
        local kc = toKeyCode(result[b.field])
        if kc then
            binds[b.key] = kc
            local bl = bindKeyLabels[b.key]
            if bl then bl.lbl.Text = keyName(kc) end
        end
    end

    local colorFields = {
        {field="espNormalOutline",tbl=espColors.normal,key="outline"},
        {field="espNormalFill",   tbl=espColors.normal,key="fill"},
        {field="espNormalText",   tbl=espColors.normal,key="text"},
        {field="espTgOutline",    tbl=espColors.tg,    key="outline"},
        {field="espTgFill",       tbl=espColors.tg,    key="fill"},
        {field="espTgText",       tbl=espColors.tg,    key="text"},
        {field="espYtOutline",    tbl=espColors.yt,    key="outline"},
        {field="espYtFill",       tbl=espColors.yt,    key="fill"},
        {field="espYtText",       tbl=espColors.yt,    key="text"},
        {field="espTtOutline",    tbl=espColors.tt,    key="outline"},
        {field="espTtFill",       tbl=espColors.tt,    key="fill"},
        {field="espTtText",       tbl=espColors.tt,    key="text"},
    }
    for _, cf in ipairs(colorFields) do
        if result[cf.field] then
            local c = strToColor(result[cf.field])
            if c then cf.tbl[cf.key] = c end
        end
    end
    if espEnabled then refreshAllESP() end
    showStatus("✔ Настройки загружены!", false)
end

loadTBtn.MouseButton1Click:Connect(function()
    TweenService:Create(loadCard, TweenInfo.new(0.1), {BackgroundColor3 = C.acc3}):Play()
    task.delay(0.3, function()
        TweenService:Create(loadCard, TweenInfo.new(0.2), {BackgroundColor3 = C.bg2}):Play()
    end)
    applyLoadedSettings()
end)

-- ================================
-- ВВОД С КЛАВИАТУРЫ
-- ================================

local menuVisible = true

local function toggleMenu()
    menuVisible = not menuVisible
    if menuVisible then
        mainFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(mainFrame, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 560, 0, 560)
        }):Play()
    else
        TweenService:Create(mainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        task.delay(0.2, function() mainFrame.Visible = false end)
    end
end

local blockedKeys = {
    [Enum.KeyCode.Escape]=true,[Enum.KeyCode.Return]=true,
    [Enum.KeyCode.Tab]=true,[Enum.KeyCode.Backspace]=true,
    [Enum.KeyCode.Delete]=true,[Enum.KeyCode.Unknown]=true,
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if listeningFor then
        local kc = input.KeyCode
        if kc == Enum.KeyCode.Escape then
            local bl = bindKeyLabels[listeningFor]
            if bl then
                bl.lbl.Text = keyName(binds[listeningFor])
                bl.bg.BackgroundColor3 = C.acc4
                bl.lbl.TextColor3 = C.acc2
                bl.accent.BackgroundColor3 = C.brd
            end
            listeningFor = nil
            hintLbl.Text = "нажмите на плитку чтобы изменить бинд"
        elseif not blockedKeys[kc] then
            binds[listeningFor] = kc
            local bl = bindKeyLabels[listeningFor]
            if bl then
                bl.lbl.Text = keyName(kc)
                bl.bg.BackgroundColor3 = C.acc4
                bl.lbl.TextColor3 = C.acc2
                bl.accent.BackgroundColor3 = C.brd
            end
            listeningFor = nil
            hintLbl.Text = "бинд сохранён"
            task.delay(1.5, function() hintLbl.Text = "нажмите на плитку чтобы изменить бинд" end)
        end
        return
    end

    if input.KeyCode == binds.menu    then toggleMenu() return end
    if input.KeyCode == binds.unfollow then doStopFollow() return end
    if input.KeyCode == binds.esp     then
        -- переключаем ESP тайл
        espEnabled = not espEnabled
        if espEnabled then enableESP() else disableESP() end
        return
    end

    if gameProcessed then return end

    if input.KeyCode == binds.fly    then
        config.flying = not config.flying
        if config.flying then enableFly() else disableFly() end
    elseif input.KeyCode == binds.noclip then
        config.noclip = not config.noclip
        if not config.noclip then
            local char = localPlayer.Character
            if char then
                for _, p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide = true end
                end
            end
        end
    elseif input.KeyCode == binds.walkSpeed then
        if _G.setWalkToggle then _G.setWalkToggle(not config.walkSpeedEnabled) end
    elseif input.KeyCode == binds.jumpHeight then
        if _G.setJumpToggle then _G.setJumpToggle(not config.jumpHeightEnabled) end
    end
end)

-- ================================
-- ПЕРЕТАСКИВАНИЕ
-- ================================

local dragging, dragStart, startPos
topbar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

-- ================================
-- ВОССТАНОВЛЕНИЕ СКОРОСТЕЙ при спавне
-- ================================

localPlayer.CharacterAdded:Connect(function(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if hum then
        if config.walkSpeedEnabled then hum.WalkSpeed = config.walkSpeed end
        if config.jumpHeightEnabled then
            hum.JumpHeight = config.jumpHeight
            hum.JumpPower  = config.jumpHeight
        end
    end
end)

-- ================================
-- СТАРТ
-- ================================

switchPage("fly")

print("💤 Testing v1.8.0 loaded | TG/TGK/YT/TT ESP | MM2 роли | Dark UI")
