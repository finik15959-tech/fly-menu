-- DreamCheats GUI Script v1.6.0
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer

local SAVE_FILE = "DreamCheats_settings.txt"

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

-- === НАСТРОЙКИ ЦВЕТОВ ESP ===
local espColors = {
    normal = {
        outline = Color3.fromRGB(255, 255, 255),
        fill    = Color3.fromRGB(255, 255, 255),
        fillTransparency = 1,
        text    = Color3.fromRGB(255, 255, 255),
    },
    tg = {
        outline = Color3.fromRGB(255, 180, 0),
        fill    = Color3.fromRGB(255, 140, 0),
        fillTransparency = 0.72,
        text    = Color3.fromRGB(255, 210, 60),
    },
}

local config = {
    flySpeed           = 50,
    walkSpeed          = 16,
    jumpHeight         = 7,
    followDistance     = 5,
    followHeight       = 3,
    flying             = false,
    following          = false,
    noclip             = false,
    targetPlayer       = nil,
    walkSpeedEnabled   = false,
    jumpHeightEnabled  = false,
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

-- Проверка TG по Name И DisplayName
local function isTGPlayer(player)
    local nameLow = player.Name:lower()
    local dispLow = player.DisplayName:lower()
    return nameLow:find("tg_", 1, true) ~= nil
        or dispLow:find("tg_", 1, true) ~= nil
end

-- === GUI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DreamCheats"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 680)
mainFrame.Position = UDim2.new(0, 20, 0.5, -340)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local shadow = Instance.new("ImageLabel")
shadow.Size = UDim2.new(1, 20, 1, 20)
shadow.Position = UDim2.new(0, -10, 0, -10)
shadow.BackgroundTransparency = 1
shadow.Image = "rbxassetid://5554236805"
shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
shadow.ImageTransparency = 0.6
shadow.ScaleType = Enum.ScaleType.Slice
shadow.SliceCenter = Rect.new(23, 23, 277, 277)
shadow.ZIndex = 0
shadow.Parent = mainFrame

local header = Instance.new("Frame")
header.Size = UDim2.new(1, 0, 0, 45)
header.BackgroundColor3 = Color3.fromRGB(100, 60, 220)
header.BorderSizePixel = 0
header.Parent = mainFrame
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local fix = Instance.new("Frame")
fix.Size = UDim2.new(1, 0, 0.5, 0)
fix.Position = UDim2.new(0, 0, 0.5, 0)
fix.BackgroundColor3 = Color3.fromRGB(100, 60, 220)
fix.BorderSizePixel = 0
fix.Parent = header

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -10, 1, 0)
title.Position = UDim2.new(0, 10, 0, 0)
title.BackgroundTransparency = 1
title.Text = "💤  DreamCheats"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local dragging, dragStart, startPos
header.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)

local scrollContent = Instance.new("ScrollingFrame")
scrollContent.Size = UDim2.new(1, 0, 1, -45)
scrollContent.Position = UDim2.new(0, 0, 0, 45)
scrollContent.BackgroundTransparency = 1
scrollContent.BorderSizePixel = 0
scrollContent.ScrollBarThickness = 0
scrollContent.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollContent.AutomaticCanvasSize = Enum.AutomaticSize.Y
scrollContent.Parent = mainFrame

local content = Instance.new("Frame")
content.Size = UDim2.new(1, -20, 0, 0)
content.Position = UDim2.new(0, 10, 0, 8)
content.BackgroundTransparency = 1
content.AutomaticSize = Enum.AutomaticSize.Y
content.Parent = scrollContent

local layout = Instance.new("UIListLayout")
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 8)
layout.Parent = content

local bottomPad = Instance.new("Frame")
bottomPad.Size = UDim2.new(1, 0, 0, 8)
bottomPad.BackgroundTransparency = 1
bottomPad.LayoutOrder = 999
bottomPad.Parent = content

-- === UI ФУНКЦИИ ===
local function makeLabel(text, parent, order)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 0, 18)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = Color3.fromRGB(160, 160, 180)
    l.TextSize = 13
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.LayoutOrder = order or 0
    l.Parent = parent
    return l
end

local function makeToggle(labelText, order, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 36)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.Parent = content
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(220, 220, 240)
    lbl.TextSize = 14
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 40, 0, 22)
    toggleBg.Position = UDim2.new(1, -50, 0.5, -11)
    toggleBg.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = frame
    Instance.new("UICorner", toggleBg).CornerRadius = UDim.new(1, 0)

    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = UDim2.new(0, 3, 0.5, -8)
    circle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    circle.BorderSizePixel = 0
    circle.Parent = toggleBg
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)

    local state = false
    local function setState(newState)
        state = newState
        TweenService:Create(toggleBg, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Color3.fromRGB(100, 60, 220) or Color3.fromRGB(60, 60, 80)
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {
            Position = state and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
        callback(state)
    end

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = frame
    btn.MouseButton1Click:Connect(function() setState(not state) end)

    return frame, function() setState(not state) end
end

-- === СЛАЙДЕРЫ ===
local speedInputBox
local sliderFill, sliderThumb

local function makeSliderControl(params)
    local SLIDER_MIN = params.sliderMin
    local SLIDER_MAX = params.sliderMax
    local INPUT_MAX  = params.inputMax

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = params.order
    frame.Parent = content
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 22)
    lbl.Position = UDim2.new(0, 12, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = params.label
    lbl.TextColor3 = Color3.fromRGB(220, 220, 240)
    lbl.TextSize = 14
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(0, 72, 0, 24)
    inputFrame.Position = UDim2.new(1, -82, 0, 4)
    inputFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = frame
    Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 6)

    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(1, -8, 1, 0)
    inputBox.Position = UDim2.new(0, 4, 0, 0)
    inputBox.BackgroundTransparency = 1
    inputBox.BorderSizePixel = 0
    inputBox.Text = tostring(params.initVal)
    inputBox.PlaceholderText = tostring(SLIDER_MIN).."-"..tostring(INPUT_MAX)
    inputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
    inputBox.TextColor3 = params.accentColor
    inputBox.TextSize = 13
    inputBox.Font = Enum.Font.GothamBold
    inputBox.TextXAlignment = Enum.TextXAlignment.Center
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = inputFrame

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 56)
    track.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    track.BorderSizePixel = 0
    track.Parent = frame
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    local initRel = math.clamp((params.initVal - SLIDER_MIN) / (SLIDER_MAX - SLIDER_MIN), 0, 1)
    fill.Size = UDim2.new(initRel, 0, 1, 0)
    fill.BackgroundColor3 = params.accentColor
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.Position = UDim2.new(initRel, -7, 0.5, -7)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 2
    thumb.Parent = track
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    local minLbl = Instance.new("TextLabel")
    minLbl.Size = UDim2.new(0, 30, 0, 14)
    minLbl.Position = UDim2.new(0, 12, 0, 63)
    minLbl.BackgroundTransparency = 1
    minLbl.Text = tostring(SLIDER_MIN)
    minLbl.TextColor3 = Color3.fromRGB(100, 100, 120)
    minLbl.TextSize = 11
    minLbl.Font = Enum.Font.Gotham
    minLbl.TextXAlignment = Enum.TextXAlignment.Left
    minLbl.Parent = frame

    local maxLbl = Instance.new("TextLabel")
    maxLbl.Size = UDim2.new(0, 30, 0, 14)
    maxLbl.Position = UDim2.new(1, -42, 0, 63)
    maxLbl.BackgroundTransparency = 1
    maxLbl.Text = tostring(SLIDER_MAX)
    maxLbl.TextColor3 = Color3.fromRGB(100, 100, 120)
    maxLbl.TextSize = 11
    maxLbl.Font = Enum.Font.Gotham
    maxLbl.TextXAlignment = Enum.TextXAlignment.Right
    maxLbl.Parent = frame

    local function updateVisual(val)
        local rel = math.clamp((val - SLIDER_MIN) / (SLIDER_MAX - SLIDER_MIN), 0, 1)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        thumb.Position = UDim2.new(rel, -7, 0.5, -7)
    end

    local sliding = false
    local trackBtn = Instance.new("TextButton")
    trackBtn.Size = UDim2.new(1, 0, 0, 30)
    trackBtn.Position = UDim2.new(0, 0, 0, -12)
    trackBtn.BackgroundTransparency = 1
    trackBtn.Text = ""
    trackBtn.ZIndex = 3
    trackBtn.Parent = track

    trackBtn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then sliding = false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType == Enum.UserInputType.MouseMovement then
            local trackPos = track.AbsolutePosition.X
            local trackWidth = track.AbsoluteSize.X
            local rel = math.clamp((i.Position.X - trackPos) / trackWidth, 0, 1)
            local val = math.floor(SLIDER_MIN + (SLIDER_MAX - SLIDER_MIN) * rel)
            inputBox.Text = tostring(val)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            thumb.Position = UDim2.new(rel, -7, 0.5, -7)
            params.onChanged(val)
        end
    end)

    inputBox.FocusLost:Connect(function()
        local val = tonumber(inputBox.Text)
        if val then
            val = math.clamp(math.floor(val), 1, INPUT_MAX)
            inputBox.Text = tostring(val)
            updateVisual(val)
            params.onChanged(val)
        else
            inputBox.Text = tostring(params.initVal)
        end
    end)

    return { inputBox = inputBox, fill = fill, thumb = thumb, updateVisual = updateVisual }
end

local function makeSpeedControl(order)
    local s = makeSliderControl({
        label       = "Скорость полёта",
        order       = order,
        sliderMin   = 10,
        sliderMax   = 200,
        inputMax    = 500,
        initVal     = config.flySpeed,
        accentColor = Color3.fromRGB(100, 60, 220),
        onChanged   = function(val) config.flySpeed = val end,
    })
    speedInputBox = s.inputBox
    sliderFill    = s.fill
    sliderThumb   = s.thumb
end

-- === ПОЛЁТ ===
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

local function enableFly()
    local char = localPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end

    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
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

local function disableFly()
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
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

-- === МЕНЮ ===
local menuVisible = true

local function toggleMenu()
    menuVisible = not menuVisible
    if menuVisible then
        mainFrame.Visible = true
        mainFrame.Size = UDim2.new(0, 0, 0, 0)
        TweenService:Create(mainFrame, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 280, 0, 680),
        }):Play()
    else
        TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
        }):Play()
        task.delay(0.21, function() mainFrame.Visible = false end)
    end
end

-- === ESP ===
local espEnabled = false
local espFolder = nil
local espPlayerFolders = {}

local function removeESP(player)
    local pf = espPlayerFolders[player.Name]
    if pf and pf.Parent then pf:Destroy() end
    espPlayerFolders[player.Name] = nil
end

local function createESP(player)
    if player == localPlayer then return end
    if not espFolder or not espFolder.Parent then return end
    removeESP(player)

    local char = player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local tg = isTGPlayer(player)
    local colors = tg and espColors.tg or espColors.normal

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

    -- BillboardGui: DisplayName (@username)
    local bb = Instance.new("BillboardGui")
    bb.Name = "BB_" .. player.Name
    bb.Adornee = hrp
    bb.Size = UDim2.new(0, 180, 0, 26)
    bb.StudsOffset = Vector3.new(0, 3.5, 0)
    bb.AlwaysOnTop = true
    bb.ResetOnSpawn = false
    bb.Parent = pFolder

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 1, 0)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.DisplayName .. " (@" .. player.Name .. ")"
    nameLabel.TextColor3 = colors.text
    nameLabel.TextStrokeTransparency = 0
    nameLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.Parent = bb
end

local function refreshAllESP()
    if not espEnabled then return end
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            createESP(p)
        end
    end
end

local function enableESP()
    espFolder = Instance.new("Folder")
    espFolder.Name = "DreamCheatsESP"
    espFolder.Parent = workspace

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            createESP(p)
            p.CharacterAdded:Connect(function()
                task.wait(0.3)
                if espEnabled then createESP(p) end
            end)
        end
    end

    Players.PlayerAdded:Connect(function(p)
        if not espEnabled then return end
        p.CharacterAdded:Connect(function()
            task.wait(0.3)
            if espEnabled then createESP(p) end
        end)
    end)

    Players.PlayerRemoving:Connect(function(p)
        removeESP(p)
    end)
end

local function disableESP()
    if espFolder and espFolder.Parent then espFolder:Destroy() end
    espFolder = nil
    for k in pairs(espPlayerFolders) do espPlayerFolders[k] = nil end
end

-- === UI ЭЛЕМЕНТЫ ===
local espToggle = function() end

local greetFrame = Instance.new("Frame")
greetFrame.Size = UDim2.new(1, 0, 0, 36)
greetFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
greetFrame.BorderSizePixel = 0
greetFrame.LayoutOrder = 0
greetFrame.Parent = content
Instance.new("UICorner", greetFrame).CornerRadius = UDim.new(0, 8)

local greetLabel = Instance.new("TextLabel")
greetLabel.Size = UDim2.new(1, -12, 1, 0)
greetLabel.Position = UDim2.new(0, 12, 0, 0)
greetLabel.BackgroundTransparency = 1
greetLabel.Text = "👋  Привет, " .. localPlayer.DisplayName .. "!"
greetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
greetLabel.TextSize = 14
greetLabel.Font = Enum.Font.GothamBold
greetLabel.TextXAlignment = Enum.TextXAlignment.Left
greetLabel.Parent = greetFrame

makeLabel("— Функционал", content, 1)

local _, flyToggle = makeToggle("Включить полёт", 2, function(state)
    if state then enableFly() else disableFly() end
end)

local _, noclipToggle = makeToggle("Ноуклип", 3, function(state)
    config.noclip = state
    if not state then
        local char = localPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end)

local _ef, _espFn = makeToggle("ESP (бокс + ник)", 4, function(state)
    espEnabled = state
    if state then enableESP() else disableESP() end
end)
espToggle = _espFn

makeSpeedControl(5)

-- WalkSpeed
do
    local s = makeSliderControl({
        label       = "Скорость ходьбы",
        order       = 6,
        sliderMin   = 8,
        sliderMax   = 100,
        inputMax    = 300,
        initVal     = config.walkSpeed,
        accentColor = Color3.fromRGB(60, 180, 120),
        onChanged   = function(val)
            config.walkSpeed = val
            if config.walkSpeedEnabled then
                local char = localPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed = val end
            end
        end,
    })

    local sliderFrame = s.inputBox.Parent.Parent

    local wToggleBg = Instance.new("Frame")
    wToggleBg.Size = UDim2.new(0, 40, 0, 22)
    wToggleBg.Position = UDim2.new(0, 12, 0, 28)
    wToggleBg.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    wToggleBg.BorderSizePixel = 0
    wToggleBg.ZIndex = 4
    wToggleBg.Parent = sliderFrame
    Instance.new("UICorner", wToggleBg).CornerRadius = UDim.new(1, 0)

    local wCircle = Instance.new("Frame")
    wCircle.Size = UDim2.new(0, 16, 0, 16)
    wCircle.Position = UDim2.new(0, 3, 0.5, -8)
    wCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    wCircle.BorderSizePixel = 0
    wCircle.ZIndex = 5
    wCircle.Parent = wToggleBg
    Instance.new("UICorner", wCircle).CornerRadius = UDim.new(1, 0)

    local wStatusLbl = Instance.new("TextLabel")
    wStatusLbl.Size = UDim2.new(0, 60, 0, 22)
    wStatusLbl.Position = UDim2.new(0, 56, 0, 28)
    wStatusLbl.BackgroundTransparency = 1
    wStatusLbl.Text = "Выкл"
    wStatusLbl.TextColor3 = Color3.fromRGB(140, 140, 160)
    wStatusLbl.TextSize = 12
    wStatusLbl.Font = Enum.Font.GothamBold
    wStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
    wStatusLbl.ZIndex = 4
    wStatusLbl.Parent = sliderFrame

    local function setWalkToggle(state)
        config.walkSpeedEnabled = state
        TweenService:Create(wToggleBg, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Color3.fromRGB(60, 180, 120) or Color3.fromRGB(60, 60, 80)
        }):Play()
        TweenService:Create(wCircle, TweenInfo.new(0.2), {
            Position = state and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
        wStatusLbl.Text = state and "Вкл" or "Выкл"
        wStatusLbl.TextColor3 = state and Color3.fromRGB(60, 180, 120) or Color3.fromRGB(140, 140, 160)
        local char = localPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = state and config.walkSpeed or 16 end
    end

    _G.setWalkToggle = setWalkToggle

    local wBtn = Instance.new("TextButton")
    wBtn.Size = UDim2.new(0, 40, 0, 22)
    wBtn.Position = UDim2.new(0, 0, 0, 0)
    wBtn.BackgroundTransparency = 1
    wBtn.Text = ""
    wBtn.ZIndex = 6
    wBtn.Parent = wToggleBg
    wBtn.MouseButton1Click:Connect(function() setWalkToggle(not config.walkSpeedEnabled) end)

    localPlayer.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum and config.walkSpeedEnabled then hum.WalkSpeed = config.walkSpeed end
    end)
end

-- JumpHeight
do
    local s = makeSliderControl({
        label       = "Высота прыжка",
        order       = 7,
        sliderMin   = 0,
        sliderMax   = 100,
        inputMax    = 300,
        initVal     = config.jumpHeight,
        accentColor = Color3.fromRGB(220, 140, 40),
        onChanged   = function(val)
            config.jumpHeight = val
            if config.jumpHeightEnabled then
                local char = localPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.JumpHeight = val; hum.JumpPower = val end
            end
        end,
    })

    local sliderFrame = s.inputBox.Parent.Parent

    local jToggleBg = Instance.new("Frame")
    jToggleBg.Size = UDim2.new(0, 40, 0, 22)
    jToggleBg.Position = UDim2.new(0, 12, 0, 28)
    jToggleBg.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    jToggleBg.BorderSizePixel = 0
    jToggleBg.ZIndex = 4
    jToggleBg.Parent = sliderFrame
    Instance.new("UICorner", jToggleBg).CornerRadius = UDim.new(1, 0)

    local jCircle = Instance.new("Frame")
    jCircle.Size = UDim2.new(0, 16, 0, 16)
    jCircle.Position = UDim2.new(0, 3, 0.5, -8)
    jCircle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    jCircle.BorderSizePixel = 0
    jCircle.ZIndex = 5
    jCircle.Parent = jToggleBg
    Instance.new("UICorner", jCircle).CornerRadius = UDim.new(1, 0)

    local jStatusLbl = Instance.new("TextLabel")
    jStatusLbl.Size = UDim2.new(0, 60, 0, 22)
    jStatusLbl.Position = UDim2.new(0, 56, 0, 28)
    jStatusLbl.BackgroundTransparency = 1
    jStatusLbl.Text = "Выкл"
    jStatusLbl.TextColor3 = Color3.fromRGB(140, 140, 160)
    jStatusLbl.TextSize = 12
    jStatusLbl.Font = Enum.Font.GothamBold
    jStatusLbl.TextXAlignment = Enum.TextXAlignment.Left
    jStatusLbl.ZIndex = 4
    jStatusLbl.Parent = sliderFrame

    local function setJumpToggle(state)
        config.jumpHeightEnabled = state
        TweenService:Create(jToggleBg, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Color3.fromRGB(220, 140, 40) or Color3.fromRGB(60, 60, 80)
        }):Play()
        TweenService:Create(jCircle, TweenInfo.new(0.2), {
            Position = state and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
        jStatusLbl.Text = state and "Вкл" or "Выкл"
        jStatusLbl.TextColor3 = state and Color3.fromRGB(220, 140, 40) or Color3.fromRGB(140, 140, 160)
        local char = localPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.JumpHeight = state and config.jumpHeight or 7
            hum.JumpPower  = state and config.jumpHeight or 7
        end
    end

    _G.setJumpToggle = setJumpToggle

    local jBtn = Instance.new("TextButton")
    jBtn.Size = UDim2.new(0, 40, 0, 22)
    jBtn.Position = UDim2.new(0, 0, 0, 0)
    jBtn.BackgroundTransparency = 1
    jBtn.Text = ""
    jBtn.ZIndex = 6
    jBtn.Parent = jToggleBg
    jBtn.MouseButton1Click:Connect(function() setJumpToggle(not config.jumpHeightEnabled) end)

    localPlayer.CharacterAdded:Connect(function(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if hum and config.jumpHeightEnabled then
            hum.JumpHeight = config.jumpHeight
            hum.JumpPower  = config.jumpHeight
        end
    end)
end

-- ===============================
-- === СЕКЦИЯ ЦВЕТОВ ESP ===
-- ===============================

makeLabel("— Цвета ESP", content, 15)

-- Вспомогательная функция: создаёт строку с RGB полями
local function makeColorRow(labelText, order, getColor, setColor, onChange)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 46)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.Parent = content
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    -- Подпись
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 20)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(200, 200, 220)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    -- Превью цвета
    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 22, 0, 22)
    preview.Position = UDim2.new(1, -28, 0, 12)
    preview.BackgroundColor3 = getColor()
    preview.BorderSizePixel = 0
    preview.Parent = frame
    Instance.new("UICorner", preview).CornerRadius = UDim.new(0, 4)

    -- Три поля R G B
    local c = getColor()
    local rVal = math.floor(c.R * 255)
    local gVal = math.floor(c.G * 255)
    local bVal = math.floor(c.B * 255)

    local function makeRGBBox(placeholder, initVal, xOffset)
        local bg = Instance.new("Frame")
        bg.Size = UDim2.new(0, 46, 0, 20)
        bg.Position = UDim2.new(0, xOffset, 0, 22)
        bg.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
        bg.BorderSizePixel = 0
        bg.Parent = frame
        Instance.new("UICorner", bg).CornerRadius = UDim.new(0, 5)

        local box = Instance.new("TextBox")
        box.Size = UDim2.new(1, -6, 1, 0)
        box.Position = UDim2.new(0, 3, 0, 0)
        box.BackgroundTransparency = 1
        box.Text = tostring(initVal)
        box.PlaceholderText = placeholder
        box.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
        box.TextColor3 = Color3.fromRGB(220, 220, 240)
        box.TextSize = 12
        box.Font = Enum.Font.GothamBold
        box.TextXAlignment = Enum.TextXAlignment.Center
        box.ClearTextOnFocus = false
        box.Parent = bg
        return box
    end

    local rBox = makeRGBBox("R", rVal, 10)
    local gBox = makeRGBBox("G", gVal, 62)
    local bBox = makeRGBBox("B", bVal, 114)

    -- Метки R G B
    for i, lbTxt in ipairs({"R", "G", "B"}) do
        local ml = Instance.new("TextLabel")
        ml.Size = UDim2.new(0, 12, 0, 20)
        ml.Position = UDim2.new(0, 10 + (i-1)*52 - 2, 0, 22)
        ml.BackgroundTransparency = 1
        ml.Text = lbTxt
        ml.TextColor3 = Color3.fromRGB(140, 140, 180)
        ml.TextSize = 10
        ml.Font = Enum.Font.GothamBold
        ml.Parent = frame
    end

    local function applyColor()
        local r = math.clamp(tonumber(rBox.Text) or 0, 0, 255)
        local g = math.clamp(tonumber(gBox.Text) or 0, 0, 255)
        local b = math.clamp(tonumber(bBox.Text) or 0, 0, 255)
        rBox.Text = tostring(r)
        gBox.Text = tostring(g)
        bBox.Text = tostring(b)
        local newColor = Color3.fromRGB(r, g, b)
        setColor(newColor)
        preview.BackgroundColor3 = newColor
        if onChange then onChange() end
    end

    rBox.FocusLost:Connect(applyColor)
    gBox.FocusLost:Connect(applyColor)
    bBox.FocusLost:Connect(applyColor)
end

-- Обычные игроки — цвет контура
makeColorRow("Обычный — контур", 16,
    function() return espColors.normal.outline end,
    function(c) espColors.normal.outline = c end,
    refreshAllESP
)

-- Обычные игроки — цвет текста
makeColorRow("Обычный — текст ника", 17,
    function() return espColors.normal.text end,
    function(c) espColors.normal.text = c end,
    refreshAllESP
)

-- TG игроки — цвет контура
makeColorRow("TG — контур", 18,
    function() return espColors.tg.outline end,
    function(c) espColors.tg.outline = c end,
    refreshAllESP
)

-- TG игроки — цвет заливки
makeColorRow("TG — заливка", 19,
    function() return espColors.tg.fill end,
    function(c) espColors.tg.fill = c end,
    refreshAllESP
)

-- TG игроки — цвет текста
makeColorRow("TG — текст ника", 20,
    function() return espColors.tg.text end,
    function(c) espColors.tg.text = c end,
    refreshAllESP
)

-- ===============================
-- === СЕКЦИЯ ПРЕСЛЕДОВАНИЯ ===
-- ===============================

makeLabel("— Преследование", content, 21)

local searchFrame = Instance.new("Frame")
searchFrame.Size = UDim2.new(1, 0, 0, 36)
searchFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
searchFrame.BorderSizePixel = 0
searchFrame.LayoutOrder = 22
searchFrame.Parent = content
Instance.new("UICorner", searchFrame).CornerRadius = UDim.new(0, 8)

local searchIcon = Instance.new("TextLabel")
searchIcon.Size = UDim2.new(0, 28, 1, 0)
searchIcon.Position = UDim2.new(0, 6, 0, 0)
searchIcon.BackgroundTransparency = 1
searchIcon.Text = "🔍"
searchIcon.TextSize = 14
searchIcon.Font = Enum.Font.Gotham
searchIcon.Parent = searchFrame

local searchBox = Instance.new("TextBox")
searchBox.Size = UDim2.new(1, -36, 1, -8)
searchBox.Position = UDim2.new(0, 30, 0, 4)
searchBox.BackgroundTransparency = 1
searchBox.BorderSizePixel = 0
searchBox.Text = ""
searchBox.PlaceholderText = "Поиск по нику или дисплей-нику..."
searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
searchBox.TextColor3 = Color3.fromRGB(220, 220, 240)
searchBox.TextSize = 13
searchBox.Font = Enum.Font.Gotham
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchFrame

local playersFrame = Instance.new("Frame")
playersFrame.Size = UDim2.new(1, 0, 0, 120)
playersFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
playersFrame.BorderSizePixel = 0
playersFrame.LayoutOrder = 23
playersFrame.Parent = content
Instance.new("UICorner", playersFrame).CornerRadius = UDim.new(0, 8)

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -8, 1, -8)
scrollFrame.Position = UDim2.new(0, 4, 0, 4)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 3
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 60, 220)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = playersFrame

local playerLayout = Instance.new("UIListLayout")
playerLayout.SortOrder = Enum.SortOrder.LayoutOrder
playerLayout.Padding = UDim.new(0, 4)
playerLayout.Parent = scrollFrame

local selectedBtn = nil
local searchQuery = ""

local function refreshPlayers()
    for _, c in pairs(scrollFrame:GetChildren()) do
        if c:IsA("TextButton") then c:Destroy() end
    end
    selectedBtn = nil
    local count = 0

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= localPlayer then
            local displayName = p.DisplayName
            local userName    = p.Name
            local searchTarget = (displayName .. " " .. userName):lower()

            if searchQuery == "" or searchTarget:find(searchQuery:lower(), 1, true) then
                count += 1
                local tg = isTGPlayer(p)
                local icon = tg and "📡" or "👤"

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -6, 0, 30)
                btn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
                btn.BorderSizePixel = 0
                btn.Text = "  " .. icon .. "  " .. displayName .. " (@" .. userName .. ")"
                btn.TextColor3 = tg and Color3.fromRGB(255, 210, 80) or Color3.fromRGB(220, 220, 240)
                btn.TextSize = 12
                btn.Font = Enum.Font.Gotham
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.TextTruncate = Enum.TextTruncate.AtEnd
                btn.Parent = scrollFrame
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

                if config.targetPlayer == p then
                    btn.BackgroundColor3 = Color3.fromRGB(100, 60, 220)
                    selectedBtn = btn
                end

                btn.MouseButton1Click:Connect(function()
                    if selectedBtn then
                        TweenService:Create(selectedBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45, 45, 65)}):Play()
                    end
                    config.targetPlayer = p
                    config.following = true
                    if not config.flying then enableFly() end
                    TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(100, 60, 220)}):Play()
                    selectedBtn = btn
                end)
            end
        end
    end
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, count * 34)
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchQuery = searchBox.Text
    refreshPlayers()
end)
refreshPlayers()
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(function() task.wait(0.1) refreshPlayers() end)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, 0, 0, 32)
stopBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
stopBtn.BorderSizePixel = 0
stopBtn.Text = "Остановить преследование"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.TextSize = 13
stopBtn.Font = Enum.Font.GothamBold
stopBtn.LayoutOrder = 24
stopBtn.Parent = content
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

local function doStopFollow()
    config.following = false
    config.targetPlayer = nil
    if selectedBtn then
        TweenService:Create(selectedBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45, 45, 65)}):Play()
        selectedBtn = nil
    end
    if not config.flying then task.delay(0.1, unfreezeChar) end
end

stopBtn.MouseButton1Click:Connect(doStopFollow)

-- ===============================
-- === СЕКЦИЯ БИНДОВ ===
-- ===============================

makeLabel("— Бинды", content, 25)

local listeningFor = nil
local bindKeyLabels = {}

local bindsContainer = Instance.new("Frame")
bindsContainer.Size = UDim2.new(1, 0, 0, 272)
bindsContainer.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
bindsContainer.BorderSizePixel = 0
bindsContainer.LayoutOrder = 26
bindsContainer.Parent = content
Instance.new("UICorner", bindsContainer).CornerRadius = UDim.new(0, 8)

local bindsInnerLayout = Instance.new("UIListLayout")
bindsInnerLayout.SortOrder = Enum.SortOrder.LayoutOrder
bindsInnerLayout.Padding = UDim.new(0, 0)
bindsInnerLayout.Parent = bindsContainer

local bindRows = {
    { key = "fly",        icon = "✈",  label = "Полёт",                  order = 1 },
    { key = "noclip",     icon = "👻", label = "Ноуклип",                order = 2 },
    { key = "unfollow",   icon = "🚫", label = "Отменить преследование",  order = 3 },
    { key = "esp",        icon = "👁",  label = "ESP",                    order = 4 },
    { key = "menu",       icon = "📋", label = "Открыть/закрыть меню",   order = 5 },
    { key = "walkSpeed",  icon = "🏃", label = "WalkSpeed вкл/выкл",     order = 6 },
    { key = "jumpHeight", icon = "⬆",  label = "JumpHeight вкл/выкл",    order = 7 },
}

local function makeBindRow(data)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 38)
    row.BackgroundTransparency = 1
    row.BorderSizePixel = 0
    row.LayoutOrder = data.order
    row.Parent = bindsContainer

    local iconLbl = Instance.new("TextLabel")
    iconLbl.Size = UDim2.new(0, 24, 1, 0)
    iconLbl.Position = UDim2.new(0, 10, 0, 0)
    iconLbl.BackgroundTransparency = 1
    iconLbl.Text = data.icon
    iconLbl.TextSize = 14
    iconLbl.Font = Enum.Font.Gotham
    iconLbl.TextColor3 = Color3.fromRGB(200, 200, 220)
    iconLbl.TextXAlignment = Enum.TextXAlignment.Left
    iconLbl.Parent = row

    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size = UDim2.new(1, -110, 1, 0)
    nameLbl.Position = UDim2.new(0, 36, 0, 0)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text = data.label
    nameLbl.TextSize = 13
    nameLbl.Font = Enum.Font.Gotham
    nameLbl.TextColor3 = Color3.fromRGB(200, 200, 220)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.Parent = row

    local keyBtn = Instance.new("TextButton")
    keyBtn.Size = UDim2.new(0, 54, 0, 24)
    keyBtn.Position = UDim2.new(1, -64, 0.5, -12)
    keyBtn.BackgroundColor3 = Color3.fromRGB(100, 60, 220)
    keyBtn.BorderSizePixel = 0
    keyBtn.Text = keyName(binds[data.key])
    keyBtn.TextSize = 12
    keyBtn.Font = Enum.Font.GothamBold
    keyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    keyBtn.Parent = row
    Instance.new("UICorner", keyBtn).CornerRadius = UDim.new(0, 6)

    bindKeyLabels[data.key] = keyBtn

    keyBtn.MouseButton1Click:Connect(function()
        if listeningFor == data.key then
            listeningFor = nil
            keyBtn.Text = keyName(binds[data.key])
            TweenService:Create(keyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(100, 60, 220)}):Play()
        else
            if listeningFor then
                local oldBtn = bindKeyLabels[listeningFor]
                if oldBtn then
                    oldBtn.Text = keyName(binds[listeningFor])
                    TweenService:Create(oldBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(100, 60, 220)}):Play()
                end
            end
            listeningFor = data.key
            keyBtn.Text = "..."
            TweenService:Create(keyBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(220, 160, 30)}):Play()
        end
    end)

    if data.order < #bindRows then
        local div = Instance.new("Frame")
        div.Size = UDim2.new(1, -20, 0, 1)
        div.Position = UDim2.new(0, 10, 1, -1)
        div.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
        div.BorderSizePixel = 0
        div.Parent = row
    end
end

for _, rd in ipairs(bindRows) do
    makeBindRow(rd)
end

local hintLbl = Instance.new("TextLabel")
hintLbl.Size = UDim2.new(1, 0, 0, 18)
hintLbl.BackgroundTransparency = 1
hintLbl.Text = "Нажмите на клавишу, чтобы изменить бинд"
hintLbl.TextColor3 = Color3.fromRGB(110, 110, 140)
hintLbl.TextSize = 11
hintLbl.Font = Enum.Font.Gotham
hintLbl.TextXAlignment = Enum.TextXAlignment.Center
hintLbl.LayoutOrder = 27
hintLbl.Parent = content

-- ===============================
-- === SAVE / LOAD ===
-- ===============================

local saveStatusLbl = Instance.new("TextLabel")
saveStatusLbl.Size = UDim2.new(1, 0, 0, 16)
saveStatusLbl.BackgroundTransparency = 1
saveStatusLbl.Text = ""
saveStatusLbl.TextColor3 = Color3.fromRGB(100, 220, 130)
saveStatusLbl.TextSize = 11
saveStatusLbl.Font = Enum.Font.GothamBold
saveStatusLbl.TextXAlignment = Enum.TextXAlignment.Center
saveStatusLbl.LayoutOrder = 115
saveStatusLbl.Parent = content

local function showStatus(msg, isError)
    saveStatusLbl.Text = msg
    saveStatusLbl.TextColor3 = isError and Color3.fromRGB(220, 80, 80) or Color3.fromRGB(100, 220, 130)
    task.delay(2.5, function() saveStatusLbl.Text = "" end)
end

local saveBtnsFrame = Instance.new("Frame")
saveBtnsFrame.Size = UDim2.new(1, 0, 0, 36)
saveBtnsFrame.BackgroundTransparency = 1
saveBtnsFrame.BorderSizePixel = 0
saveBtnsFrame.LayoutOrder = 116
saveBtnsFrame.Parent = content

local saveBtn = Instance.new("TextButton")
saveBtn.Size = UDim2.new(0.48, 0, 1, 0)
saveBtn.Position = UDim2.new(0, 0, 0, 0)
saveBtn.BackgroundColor3 = Color3.fromRGB(60, 160, 90)
saveBtn.BorderSizePixel = 0
saveBtn.Text = "💾  Сохранить"
saveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
saveBtn.TextSize = 13
saveBtn.Font = Enum.Font.GothamBold
saveBtn.Parent = saveBtnsFrame
Instance.new("UICorner", saveBtn).CornerRadius = UDim.new(0, 8)

local loadBtn = Instance.new("TextButton")
loadBtn.Size = UDim2.new(0.48, 0, 1, 0)
loadBtn.Position = UDim2.new(0.52, 0, 0, 0)
loadBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 200)
loadBtn.BorderSizePixel = 0
loadBtn.Text = "📂  Загрузить"
loadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loadBtn.TextSize = 13
loadBtn.Font = Enum.Font.GothamBold
loadBtn.Parent = saveBtnsFrame
Instance.new("UICorner", loadBtn).CornerRadius = UDim.new(0, 8)

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
        espNormalText         = colorToStr(espColors.normal.text),
        espTgOutline          = colorToStr(espColors.tg.outline),
        espTgFill             = colorToStr(espColors.tg.fill),
        espTgText             = colorToStr(espColors.tg.text),
    }
end

saveBtn.MouseButton1Click:Connect(function()
    local ok, err = pcall(function()
        writefile(SAVE_FILE, serialize(serializeSettings()))
    end)
    if ok then
        TweenService:Create(saveBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 200, 100)}):Play()
        task.delay(0.3, function()
            TweenService:Create(saveBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 160, 90)}):Play()
        end)
        showStatus("✔ Настройки сохранены!", false)
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
        if speedInputBox then speedInputBox.Text = tostring(config.flySpeed) end
        if sliderFill and sliderThumb then
            local rel = math.clamp((config.flySpeed - 10) / (200 - 10), 0, 1)
            sliderFill.Size = UDim2.new(rel, 0, 1, 0)
            sliderThumb.Position = UDim2.new(rel, -7, 0.5, -7)
        end
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
            local btn = bindKeyLabels[b.key]
            if btn then btn.Text = keyName(kc) end
        end
    end

    -- Загрузка цветов ESP
    local colorFields = {
        {field="espNormalOutline", tbl=espColors.normal, key="outline"},
        {field="espNormalText",    tbl=espColors.normal, key="text"},
        {field="espTgOutline",     tbl=espColors.tg,     key="outline"},
        {field="espTgFill",        tbl=espColors.tg,     key="fill"},
        {field="espTgText",        tbl=espColors.tg,     key="text"},
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

loadBtn.MouseButton1Click:Connect(function()
    TweenService:Create(loadBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(40, 130, 255)}):Play()
    task.delay(0.3, function()
        TweenService:Create(loadBtn, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(60, 100, 200)}):Play()
    end)
    applyLoadedSettings()
end)

-- ===============================
-- === ВЕРСИЯ + ПОДПИСЬ ===
-- ===============================

local versionFrame = Instance.new("Frame")
versionFrame.Size = UDim2.new(1, 0, 0, 22)
versionFrame.BackgroundTransparency = 1
versionFrame.BorderSizePixel = 0
versionFrame.LayoutOrder = 119
versionFrame.Parent = content

local versionLabel = Instance.new("TextLabel")
versionLabel.Size = UDim2.new(1, 0, 1, 0)
versionLabel.BackgroundTransparency = 1
versionLabel.Text = "v1.7.0"
versionLabel.TextColor3 = Color3.fromRGB(100, 100, 130)
versionLabel.TextSize = 11
versionLabel.Font = Enum.Font.GothamBold
versionLabel.TextXAlignment = Enum.TextXAlignment.Center
versionLabel.Parent = versionFrame

local creditsFrame = Instance.new("Frame")
creditsFrame.Size = UDim2.new(1, 0, 0, 34)
creditsFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
creditsFrame.BorderSizePixel = 0
creditsFrame.LayoutOrder = 120
creditsFrame.Parent = content
Instance.new("UICorner", creditsFrame).CornerRadius = UDim.new(0, 8)

local accentLine = Instance.new("Frame")
accentLine.Size = UDim2.new(1, -20, 0, 2)
accentLine.Position = UDim2.new(0, 10, 0, 0)
accentLine.BackgroundColor3 = Color3.fromRGB(100, 60, 220)
accentLine.BorderSizePixel = 0
accentLine.Parent = creditsFrame
Instance.new("UICorner", accentLine).CornerRadius = UDim.new(1, 0)

local creditsLabel = Instance.new("TextLabel")
creditsLabel.Size = UDim2.new(1, -12, 1, 0)
creditsLabel.Position = UDim2.new(0, 6, 0, 0)
creditsLabel.BackgroundTransparency = 1
creditsLabel.Text = "💜  Благодарим вас от DreamCompany"
creditsLabel.TextColor3 = Color3.fromRGB(160, 140, 210)
creditsLabel.TextSize = 12
creditsLabel.Font = Enum.Font.GothamBold
creditsLabel.TextXAlignment = Enum.TextXAlignment.Center
creditsLabel.Parent = creditsFrame

-- ===============================
-- === ОБРАБОТКА КЛАВИШ ===
-- ===============================

local blockedKeys = {
    [Enum.KeyCode.Escape]    = true,
    [Enum.KeyCode.Return]    = true,
    [Enum.KeyCode.Tab]       = true,
    [Enum.KeyCode.Backspace] = true,
    [Enum.KeyCode.Delete]    = true,
    [Enum.KeyCode.Unknown]   = true,
}

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if listeningFor then
        local kc = input.KeyCode
        if kc == Enum.KeyCode.Escape then
            local btn = bindKeyLabels[listeningFor]
            if btn then
                btn.Text = keyName(binds[listeningFor])
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(100, 60, 220)}):Play()
            end
            listeningFor = nil
        elseif not blockedKeys[kc] and kc ~= Enum.KeyCode.Unknown then
            binds[listeningFor] = kc
            local btn = bindKeyLabels[listeningFor]
            if btn then
                btn.Text = keyName(kc)
                TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(100, 60, 220)}):Play()
            end
            listeningFor = nil
        end
        return
    end

    if input.KeyCode == binds.menu then toggleMenu() return end
    if input.KeyCode == binds.unfollow then doStopFollow() return end
    if input.KeyCode == binds.esp then espToggle() return end

    if gameProcessed then return end

    if input.KeyCode == binds.fly then
        flyToggle()
    elseif input.KeyCode == binds.noclip then
        noclipToggle()
    elseif input.KeyCode == binds.walkSpeed then
        if _G.setWalkToggle then _G.setWalkToggle(not config.walkSpeedEnabled) end
    elseif input.KeyCode == binds.jumpHeight then
        if _G.setJumpToggle then _G.setJumpToggle(not config.jumpHeightEnabled) end
    end
end)

print("💤 DreamCheats v1.7.0 | TG по Name+DisplayName | RGB настройка цветов ESP | DisplayName (@name) везде")
