-- Flight + Follow GUI Script
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local localPlayer = Players.LocalPlayer

-- === НАСТРОЙКИ ===
local config = {
    flySpeed = 50,
    followDistance = 5,
    followHeight = 3,
    flying = false,
    following = false,
    noclip = false,
    targetPlayer = nil
}

-- === СОЗДАНИЕ GUI ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "FlyMenu"
screenGui.ResetOnSpawn = false
screenGui.Parent = game.CoreGui

-- Главное окно
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 530)
mainFrame.Position = UDim2.new(0, 20, 0.5, -265)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

-- Тень
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

-- Шапка
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
title.Text = "✈  Fly Menu"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 18
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

-- Drag окна
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

-- Скроллируемый контент
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

-- === ФУНКЦИИ UI ===
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
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = frame

    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(toggleBg, TweenInfo.new(0.2), {
            BackgroundColor3 = state and Color3.fromRGB(100, 60, 220) or Color3.fromRGB(60, 60, 80)
        }):Play()
        TweenService:Create(circle, TweenInfo.new(0.2), {
            Position = state and UDim2.new(0, 21, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        }):Play()
        callback(state)
    end)

    return frame
end

-- === СЛАЙДЕР + ПОЛЕ ВВОДА ===
local sliderFill, sliderThumb, sliderValLbl, speedInputBox

local function makeSpeedControl(order)
    local SLIDER_MIN = 10
    local SLIDER_MAX = 200
    local INPUT_MAX = 500

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 80)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
    frame.BorderSizePixel = 0
    frame.LayoutOrder = order
    frame.Parent = content
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    -- Заголовок
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -12, 0, 22)
    lbl.Position = UDim2.new(0, 12, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = "Скорость полёта"
    lbl.TextColor3 = Color3.fromRGB(220, 220, 240)
    lbl.TextSize = 14
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame

    -- Поле ввода (до 500)
    local inputFrame = Instance.new("Frame")
    inputFrame.Size = UDim2.new(0, 72, 0, 24)
    inputFrame.Position = UDim2.new(1, -82, 0, 4)
    inputFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
    inputFrame.BorderSizePixel = 0
    inputFrame.Parent = frame
    Instance.new("UICorner", inputFrame).CornerRadius = UDim.new(0, 6)

    speedInputBox = Instance.new("TextBox")
    speedInputBox.Size = UDim2.new(1, -8, 1, 0)
    speedInputBox.Position = UDim2.new(0, 4, 0, 0)
    speedInputBox.BackgroundTransparency = 1
    speedInputBox.BorderSizePixel = 0
    speedInputBox.Text = tostring(config.flySpeed)
    speedInputBox.PlaceholderText = "10-500"
    speedInputBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
    speedInputBox.TextColor3 = Color3.fromRGB(100, 60, 220)
    speedInputBox.TextSize = 13
    speedInputBox.Font = Enum.Font.GothamBold
    speedInputBox.TextXAlignment = Enum.TextXAlignment.Center
    speedInputBox.ClearTextOnFocus = false
    speedInputBox.Parent = inputFrame

    -- Полоска (до 200)
    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 6)
    track.Position = UDim2.new(0, 12, 0, 56)
    track.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    track.BorderSizePixel = 0
    track.Parent = frame
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    local initRel = (config.flySpeed - SLIDER_MIN) / (SLIDER_MAX - SLIDER_MIN)
    fill.Size = UDim2.new(math.clamp(initRel, 0, 1), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 60, 220)
    fill.BorderSizePixel = 0
    fill.Parent = track
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
    sliderFill = fill

    local thumb = Instance.new("Frame")
    thumb.Size = UDim2.new(0, 14, 0, 14)
    thumb.Position = UDim2.new(math.clamp(initRel, 0, 1), -7, 0.5, -7)
    thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    thumb.BorderSizePixel = 0
    thumb.ZIndex = 2
    thumb.Parent = track
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)
    sliderThumb = thumb

    -- Подписи мин/макс под полоской
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

    -- Обновление слайдера из значения
    local function updateSliderVisual(val)
        local rel = math.clamp((val - SLIDER_MIN) / (SLIDER_MAX - SLIDER_MIN), 0, 1)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        thumb.Position = UDim2.new(rel, -7, 0.5, -7)
    end

    -- Слайдер -> обновляет поле и скорость
    local sliding = false
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 30)
    btn.Position = UDim2.new(0, 0, 0, -12)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 3
    btn.Parent = track

    btn.InputBegan:Connect(function(i)
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
            config.flySpeed = val
            speedInputBox.Text = tostring(val)
            fill.Size = UDim2.new(rel, 0, 1, 0)
            thumb.Position = UDim2.new(rel, -7, 0.5, -7)
        end
    end)

    -- Поле ввода -> обновляет слайдер и скорость
    speedInputBox.FocusLost:Connect(function()
        local val = tonumber(speedInputBox.Text)
        if val then
            val = math.clamp(math.floor(val), 1, INPUT_MAX)
            config.flySpeed = val
            speedInputBox.Text = tostring(val)
            updateSliderVisual(val)
        else
            speedInputBox.Text = tostring(config.flySpeed)
        end
    end)
end

-- === ПОЛЁТ ЛОГИКА ===
local bodyVelocity, bodyGyro

local function unfreezeChar()
    local char = localPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hum then
        hum.PlatformStand = false
        hum.AutoRotate = true
    end
    if hrp then
        for _, v in pairs(hrp:GetChildren()) do
            if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then
                v:Destroy()
            end
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
        if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then
            v:Destroy()
        end
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
    task.delay(0.1, function()
        unfreezeChar()
    end)
end

-- === НОУКЛИП ЛОГИКА ===
RunService.Stepped:Connect(function()
    if not config.noclip then return end
    local char = localPlayer.Character
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") and part.CanCollide then
            part.CanCollide = false
        end
    end
end)

-- === HEARTBEAT ===
RunService.Heartbeat:Connect(function(dt)
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
                local speed = math.clamp(dist * 3, 5, config.flySpeed * 2)
                bodyVelocity.Velocity = diff.Unit * speed
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

-- === UI ЭЛЕМЕНТЫ ===

-- Приветствие
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
greetLabel.Text = "👋  Привет, " .. localPlayer.Name .. "!"
greetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
greetLabel.TextSize = 14
greetLabel.Font = Enum.Font.GothamBold
greetLabel.TextXAlignment = Enum.TextXAlignment.Left
greetLabel.Parent = greetFrame

makeLabel("— Полёт", content, 1)

makeToggle("Включить полёт", 2, function(state)
    if state then enableFly() else disableFly() end
end)

makeToggle("Ноуклип", 3, function(state)
    config.noclip = state
    if not state then
        local char = localPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
end)

makeSpeedControl(4)

makeLabel("— Преследование", content, 5)

-- Поле поиска игрока
local searchFrame = Instance.new("Frame")
searchFrame.Size = UDim2.new(1, 0, 0, 36)
searchFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
searchFrame.BorderSizePixel = 0
searchFrame.LayoutOrder = 6
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
searchBox.PlaceholderText = "Поиск игрока..."
searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 120)
searchBox.TextColor3 = Color3.fromRGB(220, 220, 240)
searchBox.TextSize = 13
searchBox.Font = Enum.Font.Gotham
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.ClearTextOnFocus = false
searchBox.Parent = searchFrame

-- Список игроков
local playersFrame = Instance.new("Frame")
playersFrame.Size = UDim2.new(1, 0, 0, 120)
playersFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
playersFrame.BorderSizePixel = 0
playersFrame.LayoutOrder = 7
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
            local name = p.Name:lower()
            if searchQuery == "" or name:find(searchQuery:lower(), 1, true) then
                count += 1
                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(1, -6, 0, 28)
                btn.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
                btn.BorderSizePixel = 0
                btn.Text = "  👤 " .. p.Name
                btn.TextColor3 = Color3.fromRGB(220, 220, 240)
                btn.TextSize = 13
                btn.Font = Enum.Font.Gotham
                btn.TextXAlignment = Enum.TextXAlignment.Left
                btn.Parent = scrollFrame
                Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

                if config.targetPlayer == p then
                    btn.BackgroundColor3 = Color3.fromRGB(100, 60, 220)
                    selectedBtn = btn
                end

                btn.MouseButton1Click:Connect(function()
                    if selectedBtn then
                        TweenService:Create(selectedBtn, TweenInfo.new(0.15), {
                            BackgroundColor3 = Color3.fromRGB(45, 45, 65)
                        }):Play()
                    end
                    config.targetPlayer = p
                    config.following = true
                    if not config.flying then enableFly() end
                    TweenService:Create(btn, TweenInfo.new(0.15), {
                        BackgroundColor3 = Color3.fromRGB(100, 60, 220)
                    }):Play()
                    selectedBtn = btn
                end)
            end
        end
    end
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, count * 32)
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    searchQuery = searchBox.Text
    refreshPlayers()
end)

refreshPlayers()
Players.PlayerAdded:Connect(refreshPlayers)
Players.PlayerRemoving:Connect(function()
    task.wait(0.1)
    refreshPlayers()
end)

-- Кнопка остановить преследование
local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(1, 0, 0, 32)
stopBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50)
stopBtn.BorderSizePixel = 0
stopBtn.Text = "Остановить преследование"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.TextSize = 13
stopBtn.Font = Enum.Font.GothamBold
stopBtn.LayoutOrder = 8
stopBtn.Parent = content
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 8)

stopBtn.MouseButton1Click:Connect(function()
    config.following = false
    config.targetPlayer = nil
    if selectedBtn then
        TweenService:Create(selectedBtn, TweenInfo.new(0.15), {
            BackgroundColor3 = Color3.fromRGB(45, 45, 65)
        }):Play()
        selectedBtn = nil
    end
    if not config.flying then
        task.delay(0.1, function()
            unfreezeChar()
        end)
    end
end)

print("✈ Fly Menu загружен!")
