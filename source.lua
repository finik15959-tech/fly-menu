-- Testing ClickGUI v2.0
-- Стиль: Nursultan Client (Minecraft) адаптирован под Roblox
-- ЛКМ = вкл/выкл | ПКМ = настройки (бинд + слайдер) | Скролл = прокрутка колонки

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")

local lp = Players.LocalPlayer
local SAVE_FILE = "Testing_v2_settings.txt"

-- ============================================================
-- УТИЛИТЫ
-- ============================================================
local function serialize(t)
    local p={}
    for k,v in pairs(t) do p[#p+1]=tostring(k).."="..tostring(v) end
    return table.concat(p,"\n")
end
local function deserialize(raw)
    local r={}
    for line in raw:gmatch("[^\n]+") do
        local k,v=line:match("^(.-)=(.+)$")
        if k and v then r[k]=v end
    end
    return r
end
local function toKeyCode(str)
    if not str then return nil end
    local name=str:match("Enum%.KeyCode%.(.+)") or str
    local ok,kc=pcall(function() return Enum.KeyCode[name] end)
    return (ok and kc) or nil
end
local function keyName(kc)
    local s=tostring(kc)
    return s:match("KeyCode%.(.+)") or s
end
local function colorToStr(c)
    return math.floor(c.R*255).."_"..math.floor(c.G*255).."_"..math.floor(c.B*255)
end
local function strToColor(s)
    local r,g,b=s:match("(%d+)_(%d+)_(%d+)")
    if r then return Color3.fromRGB(tonumber(r),tonumber(g),tonumber(b)) end
end

-- ============================================================
-- КОНФИГ
-- ============================================================
local config = {
    flySpeed          = 50,
    walkSpeed         = 16,
    jumpHeight        = 7,
    followDistance    = 5,
    followHeight      = 3,
    antiFlingMaxVel   = 200,
    flying            = false,
    following         = false,
    noclip            = false,
    targetPlayer      = nil,
    walkSpeedEnabled  = false,
    jumpHeightEnabled = false,
    antiFlingEnabled  = false,
    espEnabled        = false,
}

local binds = {
    menu       = Enum.KeyCode.F9,
    fly        = Enum.KeyCode.F5,
    noclip     = Enum.KeyCode.F6,
    unfollow   = Enum.KeyCode.F7,
    esp        = Enum.KeyCode.F8,
    walkSpeed  = Enum.KeyCode.F1,
    jumpHeight = Enum.KeyCode.F2,
    antiFling  = Enum.KeyCode.F3,
}

local espColors = {
    normal = { outline=Color3.fromRGB(255,255,255), fill=Color3.fromRGB(255,255,255), fillTransparency=0.72, text=Color3.fromRGB(255,255,255) },
    tg     = { outline=Color3.fromRGB(255,180,0),   fill=Color3.fromRGB(255,140,0),   fillTransparency=0.72, text=Color3.fromRGB(255,210,60) },
    yt     = { outline=Color3.fromRGB(255,0,0),     fill=Color3.fromRGB(200,0,0),     fillTransparency=0.72, text=Color3.fromRGB(255,80,80) },
    tt     = { outline=Color3.fromRGB(30,30,30),    fill=Color3.fromRGB(10,10,10),    fillTransparency=0.60, text=Color3.fromRGB(200,200,200) },
    mm2_innocent = { outline=Color3.fromRGB(0,220,80),  fill=Color3.fromRGB(0,180,60),  fillTransparency=0.65, text=Color3.fromRGB(80,255,140) },
    mm2_murderer = { outline=Color3.fromRGB(255,30,30), fill=Color3.fromRGB(200,0,0),   fillTransparency=0.65, text=Color3.fromRGB(255,100,100) },
    mm2_sheriff  = { outline=Color3.fromRGB(60,140,255),fill=Color3.fromRGB(30,80,220), fillTransparency=0.65, text=Color3.fromRGB(130,190,255) },
}

-- ============================================================
-- MM2
-- ============================================================
local MM2_ID = 142823291
local function isInMM2() return game.PlaceId == MM2_ID end

local function getMM2Role(player)
    local function check(c)
        if not c then return nil end
        for _,o in pairs(c:GetChildren()) do
            if o:IsA("Tool") then
                local n=o.Name:lower()
                if n:find("knife") or n:find("blade") then return "mm2_murderer" end
                if n:find("gun") or n:find("revolver") or n:find("sheriff") then return "mm2_sheriff" end
            end
        end
    end
    local r=check(player:FindFirstChildOfClass("Backpack")) or check(player.Character)
    if r then return r end
    local active=false
    for _,p in pairs(Players:GetPlayers()) do
        if p~=player and (check(p:FindFirstChildOfClass("Backpack")) or check(p.Character)) then active=true break end
    end
    return active and "mm2_innocent" or nil
end

local function getPlayerType(p)
    local n,d=p.Name:lower(),p.DisplayName:lower()
    if n:sub(1,3)=="tg_" or d:sub(1,3)=="tg_" then return "tg" end
    if n:sub(1,3)=="yt_" or d:sub(1,3)=="yt_" then return "yt" end
    if n:sub(1,3)=="tt_" or d:sub(1,3)=="tt_" then return "tt" end
    return "normal"
end

-- ============================================================
-- ESP
-- ============================================================
local espFolder, espPlayerFolders = nil, {}

local function removeESP(player)
    local pf=espPlayerFolders[player.Name]
    if pf and pf.Parent then pf:Destroy() end
    espPlayerFolders[player.Name]=nil
end

local createESP, refreshAllESP

createESP = function(player)
    if player==lp then return end
    if not espFolder or not espFolder.Parent then return end
    removeESP(player)
    local char=player.Character
    if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local ptype = isInMM2() and (getMM2Role(player) or getPlayerType(player)) or getPlayerType(player)
    local colors = espColors[ptype] or espColors.normal

    local pf=Instance.new("Folder")
    pf.Name="PESP_"..player.Name
    pf.Parent=espFolder
    espPlayerFolders[player.Name]=pf

    local hl=Instance.new("Highlight")
    hl.Adornee=char
    hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
    hl.OutlineColor=colors.outline
    hl.FillColor=colors.fill
    hl.FillTransparency=colors.fillTransparency
    hl.Parent=pf

    local bb=Instance.new("BillboardGui")
    bb.Adornee=hrp
    bb.Size=UDim2.new(0,200,0,26)
    bb.StudsOffset=Vector3.new(0,3.5,0)
    bb.AlwaysOnTop=true
    bb.ResetOnSpawn=false
    bb.Parent=pf

    local tag=""
    if ptype=="mm2_murderer" then tag="🔪 "
    elseif ptype=="mm2_sheriff" then tag="🔵 "
    elseif ptype=="mm2_innocent" then tag="🟢 "
    end

    local nl=Instance.new("TextLabel")
    nl.Size=UDim2.new(1,0,1,0)
    nl.BackgroundTransparency=1
    nl.Text=tag..player.DisplayName.." (@"..player.Name..")"
    nl.TextColor3=colors.text
    nl.TextStrokeTransparency=0
    nl.TextStrokeColor3=Color3.new(0,0,0)
    nl.TextSize=13
    nl.Font=Enum.Font.GothamBold
    nl.Parent=bb
end

refreshAllESP = function()
    if not config.espEnabled then return end
    for _,p in pairs(Players:GetPlayers()) do
        if p~=lp then createESP(p) end
    end
end

local function enableESP()
    espFolder=Instance.new("Folder")
    espFolder.Name="TestingESP"
    espFolder.Parent=workspace
    for _,p in pairs(Players:GetPlayers()) do
        if p~=lp then
            createESP(p)
            p.CharacterAdded:Connect(function()
                task.wait(0.3)
                if config.espEnabled then createESP(p) end
            end)
        end
    end
    Players.PlayerAdded:Connect(function(p)
        if not config.espEnabled then return end
        p.CharacterAdded:Connect(function()
            task.wait(0.3)
            if config.espEnabled then createESP(p) end
        end)
        task.wait(0.3)
        if config.espEnabled then createESP(p) end
    end)
    Players.PlayerRemoving:Connect(removeESP)
end

local function disableESP()
    if espFolder and espFolder.Parent then espFolder:Destroy() end
    espFolder=nil
    for k in pairs(espPlayerFolders) do espPlayerFolders[k]=nil end
end

-- MM2 роль-ватчер
do
    local lastRoles={}
    RunService.Heartbeat:Connect(function()
        if not config.espEnabled or not isInMM2() then return end
        for _,p in pairs(Players:GetPlayers()) do
            if p~=lp then
                local role=getMM2Role(p) or "none"
                if lastRoles[p.Name]~=role then
                    lastRoles[p.Name]=role
                    task.spawn(function()
                        task.wait(0.05)
                        if config.espEnabled then createESP(p) end
                    end)
                end
            end
        end
    end)
end

-- ============================================================
-- ПОЛЁТ
-- ============================================================
local bodyVelocity, bodyGyro

local function unfreezeChar()
    local char=lp.Character
    if not char then return end
    local hum=char:FindFirstChildOfClass("Humanoid")
    local hrp=char:FindFirstChild("HumanoidRootPart")
    if hum then hum.PlatformStand=false; hum.AutoRotate=true end
    if hrp then
        for _,v in pairs(hrp:GetChildren()) do
            if v:IsA("BodyVelocity") or v:IsA("BodyGyro") then v:Destroy() end
        end
    end
end

local function enableFly()
    local char=lp.Character
    if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    local hum=char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity=nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro=nil end
    hum.PlatformStand=true; hum.AutoRotate=false
    bodyVelocity=Instance.new("BodyVelocity")
    bodyVelocity.Velocity=Vector3.zero
    bodyVelocity.MaxForce=Vector3.new(1e5,1e5,1e5)
    bodyVelocity.Parent=hrp
    bodyGyro=Instance.new("BodyGyro")
    bodyGyro.MaxTorque=Vector3.new(1e5,1e5,1e5)
    bodyGyro.P=1e4
    bodyGyro.Parent=hrp
    config.flying=true
end

local function disableFly()
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity=nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro=nil end
    config.flying=false
    config.following=false
    config.targetPlayer=nil
    task.delay(0.1,unfreezeChar)
end

RunService.Heartbeat:Connect(function()
    if not config.flying then return end
    local char=lp.Character
    if not char then return end
    local hrp=char:FindFirstChild("HumanoidRootPart")
    if not hrp or not bodyVelocity or not bodyGyro then return end
    if config.following and config.targetPlayer then
        local tc=config.targetPlayer.Character
        local thrp=tc and tc:FindFirstChild("HumanoidRootPart")
        if thrp then
            local diff=(thrp.Position+Vector3.new(0,config.followHeight,0))-hrp.Position
            local dist=diff.Magnitude
            bodyVelocity.Velocity=dist>config.followDistance and diff.Unit*math.clamp(dist*3,5,config.flySpeed*2) or Vector3.zero
            bodyGyro.CFrame=CFrame.new(hrp.Position,thrp.Position)
        end
    else
        local cam=workspace.CurrentCamera
        local move=Vector3.zero
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then move+=cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then move-=cam.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then move-=cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then move+=cam.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.E) then move+=Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move-=Vector3.new(0,1,0) end
        bodyVelocity.Velocity=move.Magnitude>0 and move.Unit*config.flySpeed or Vector3.zero
        bodyGyro.CFrame=cam.CFrame
    end
end)

-- НОУКЛИП
RunService.Stepped:Connect(function()
    if not config.noclip then return end
    local char=lp.Character
    if not char then return end
    for _,p in pairs(char:GetDescendants()) do
        if p:IsA("BasePart") and p.CanCollide then p.CanCollide=false end
    end
end)

-- АНТИФЛИНГ
local antiFlingConn
local function enableAntiFling()
    if antiFlingConn then antiFlingConn:Disconnect() antiFlingConn=nil end
    antiFlingConn=RunService.Heartbeat:Connect(function()
        if not config.antiFlingEnabled or config.flying then return end
        local char=lp.Character
        local hrp=char and char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local vel=hrp.AssemblyLinearVelocity
        if vel.Magnitude>config.antiFlingMaxVel then
            hrp.AssemblyLinearVelocity=vel.Unit*config.antiFlingMaxVel
        end
        if hrp.AssemblyAngularVelocity.Magnitude>20 then
            hrp.AssemblyAngularVelocity=Vector3.zero
        end
    end)
end
local function disableAntiFling()
    if antiFlingConn then antiFlingConn:Disconnect() antiFlingConn=nil end
end

lp.CharacterAdded:Connect(function()
    task.wait(1)
    if config.antiFlingEnabled then enableAntiFling() end
    local char=lp.Character or lp.CharacterAdded:Wait()
    local hum=char:WaitForChild("Humanoid",5)
    if hum then
        if config.walkSpeedEnabled then hum.WalkSpeed=config.walkSpeed end
        if config.jumpHeightEnabled then hum.JumpHeight=config.jumpHeight; hum.JumpPower=config.jumpHeight end
    end
end)

-- ============================================================
-- ClickGUI
-- ============================================================
local screenGui=Instance.new("ScreenGui")
screenGui.Name="TestingClickGUI"
screenGui.ResetOnSpawn=false
screenGui.IgnoreGuiInset=true
screenGui.Parent=game.CoreGui

local guiVisible=true

-- Цвета темы
local BG         = Color3.fromRGB(25,28,45)
local BG_COL     = Color3.fromRGB(18,20,35)
local BG_ROW     = Color3.fromRGB(30,33,52)
local BG_ROW_HOV = Color3.fromRGB(40,44,65)
local BG_ON      = Color3.fromRGB(35,30,60)
local ACCENT     = Color3.fromRGB(124,92,252)
local ACCENT2    = Color3.fromRGB(160,130,255)
local TEXT_PRI   = Color3.fromRGB(240,238,255)
local TEXT_SEC   = Color3.fromRGB(160,158,200)
local TEXT_DIM   = Color3.fromRGB(90,88,130)
local DIVIDER    = Color3.fromRGB(38,40,60)

-- Шрифты
local FONT_REG  = Enum.Font.Gotham
local FONT_BOLD = Enum.Font.GothamBold

-- Хелперы UI
local function corner(p,r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 8); return c end
local function pad(p,t,b,l,r) local c=Instance.new("UIPadding",p); c.PaddingTop=UDim.new(0,t or 0); c.PaddingBottom=UDim.new(0,b or 0); c.PaddingLeft=UDim.new(0,l or 0); c.PaddingRight=UDim.new(0,r or 0); return c end
local function listLayout(p,gap,dir)
    local l=Instance.new("UIListLayout",p)
    l.Padding=UDim.new(0,gap or 0)
    l.SortOrder=Enum.SortOrder.LayoutOrder
    l.FillDirection=dir or Enum.FillDirection.Vertical
    return l
end

local function makeFrame(parent,size,pos,bg,order)
    local f=Instance.new("Frame")
    f.Size=size or UDim2.new(1,0,0,30)
    f.Position=pos or UDim2.new(0,0,0,0)
    f.BackgroundColor3=bg or BG
    f.BorderSizePixel=0
    f.LayoutOrder=order or 0
    f.Parent=parent
    return f
end

local function makeLabel(parent,text,size,color,font,xa,order)
    local l=Instance.new("TextLabel")
    l.Size=size or UDim2.new(1,0,1,0)
    l.BackgroundTransparency=1
    l.Text=text or ""
    l.TextColor3=color or TEXT_PRI
    l.TextSize=font and font==FONT_BOLD and 13 or 12
    l.Font=font or FONT_REG
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.LayoutOrder=order or 0
    l.Parent=parent
    return l
end

local function makeBtn(parent,size,pos,bg,text,textColor,textSize,font,order)
    local b=Instance.new("TextButton")
    b.Size=size or UDim2.new(1,0,1,0)
    b.Position=pos or UDim2.new(0,0,0,0)
    b.BackgroundColor3=bg or BG_ROW
    b.BorderSizePixel=0
    b.Text=text or ""
    b.TextColor3=textColor or TEXT_PRI
    b.TextSize=textSize or 13
    b.Font=font or FONT_REG
    b.AutoButtonColor=false
    b.LayoutOrder=order or 0
    b.Parent=parent
    return b
end

-- ============================================================
-- КОНТЕЙНЕР КОЛОНОК
-- ============================================================
local holder=makeFrame(screenGui, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.new(0,0,0))
holder.BackgroundTransparency=1
holder.Name="Holder"

local colHolder=makeFrame(holder, UDim2.new(0,0,0,0), UDim2.new(0,16,0,16), Color3.new(0,0,0))
colHolder.BackgroundTransparency=1
colHolder.AutomaticSize=Enum.AutomaticSize.XY
listLayout(colHolder, 10, Enum.FillDirection.Horizontal)

-- ============================================================
-- ФАБРИКА КОЛОНКИ
-- ============================================================
local COL_WIDTH = 200
local ROW_H = 34

local listeningBind = nil  -- {keyEl, bindKey}

local function makeColumn(title, icon)
    local col = makeFrame(colHolder, UDim2.new(0,COL_WIDTH,0,0), nil, BG_COL)
    col.AutomaticSize=Enum.AutomaticSize.Y
    col.ClipsDescendants=true
    corner(col, 14)

    -- Заголовок
    local head=makeFrame(col, UDim2.new(1,0,0,42), nil, BG_COL)
    head.ZIndex=2
    pad(head,0,0,14,14)

    local row=makeFrame(head, UDim2.new(1,0,1,0), nil, Color3.new(0,0,0))
    row.BackgroundTransparency=1
    local rowL=listLayout(row,0,Enum.FillDirection.Horizontal)

    local icLbl=makeLabel(row, icon, UDim2.new(0,24,1,0), ACCENT, FONT_BOLD)
    icLbl.TextSize=16
    local titLbl=makeLabel(row, title, UDim2.new(1,-24,1,0), TEXT_PRI, FONT_BOLD)
    titLbl.TextSize=14

    -- Линия-разделитель
    local div=makeFrame(col, UDim2.new(1,0,0,1), nil, DIVIDER)
    div.LayoutOrder=1

    -- Скроллинг-контент
    local scroll=Instance.new("ScrollingFrame")
    scroll.Size=UDim2.new(1,0,0,0)
    scroll.AutomaticSize=Enum.AutomaticSize.Y
    scroll.BackgroundTransparency=1
    scroll.BorderSizePixel=0
    scroll.ScrollBarThickness=2
    scroll.ScrollBarImageColor3=ACCENT
    scroll.CanvasSize=UDim2.new(0,0,0,0)
    scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    scroll.LayoutOrder=2
    scroll.Parent=col
    listLayout(scroll, 1)

    -- Перетаскивание колонки
    local dragging,dragStart,startPos=false,nil,nil
    head.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then
            dragging=true; dragStart=inp.Position; startPos=col.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType==Enum.UserInputType.MouseMovement then
            local d=inp.Position-dragStart
            col.Position=UDim2.new(startPos.X.Scale, startPos.X.Offset+d.X, startPos.Y.Scale, startPos.Y.Offset+d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
    end)

    return col, scroll
end

-- ============================================================
-- РЯД МОДУЛЯ
-- ============================================================
-- returns: rowFrame
-- onToggle(state) вызывается при вкл/выкл
-- openSettings(scrollFrame) вставляет настройки ниже

local function makeModule(scroll, label, bindKey, initState, onToggle, buildSettings, order)
    local state = initState or false

    -- Фрейм ряда
    local rowF = makeFrame(scroll, UDim2.new(1,0,0,ROW_H), nil, state and BG_ON or BG_COL)
    rowF.LayoutOrder = order or 0
    rowF.ClipsDescendants = false

    -- Акцент-линия слева (видна когда вкл)
    local accentBar = makeFrame(rowF, UDim2.new(0,3,1,0), UDim2.new(0,0,0,0), ACCENT)
    accentBar.Visible = state
    corner(accentBar, 0)

    -- Кнопка-оверлей на весь ряд
    local rowBtn = makeBtn(rowF, UDim2.new(1,0,1,0), UDim2.new(0,0,0,0), Color3.new(0,0,0), "", TEXT_PRI, 13, FONT_REG)
    rowBtn.BackgroundTransparency = 1
    rowBtn.ZIndex = 3

    -- Лейбл
    local lbl = makeLabel(rowF, label, UDim2.new(1,-60,1,0), state and TEXT_PRI or TEXT_SEC, state and FONT_BOLD or FONT_REG)
    lbl.Position = UDim2.new(0,14,0,0)
    lbl.TextSize = 13

    -- Галочка
    local chk = makeLabel(rowF, "✓", UDim2.new(0,20,1,0), ACCENT2, FONT_BOLD)
    chk.Position = UDim2.new(1,-30,0,0)
    chk.TextXAlignment = Enum.TextXAlignment.Right
    chk.Visible = state
    chk.TextSize = 13

    -- Панель настроек (раскрывается при ПКМ)
    local settingsFrame = makeFrame(scroll, UDim2.new(1,0,0,0), nil, BG_COL)
    settingsFrame.AutomaticSize = Enum.AutomaticSize.Y
    settingsFrame.LayoutOrder = (order or 0) + 0.5
    settingsFrame.Visible = false
    settingsFrame.ClipsDescendants = false
    listLayout(settingsFrame, 0)

    local settingsOpen = false

    local function setToggleState(newState)
        state = newState
        rowF.BackgroundColor3 = state and BG_ON or BG_COL
        accentBar.Visible = state
        chk.Visible = state
        lbl.TextColor3 = state and TEXT_PRI or TEXT_SEC
        lbl.Font = state and FONT_BOLD or FONT_REG
        onToggle(state)
    end

    local function openSettings()
        settingsOpen = not settingsOpen
        if settingsOpen then
            -- Очищаем и строим
            for _,c in pairs(settingsFrame:GetChildren()) do
                if not c:IsA("UIListLayout") then c:Destroy() end
            end
            buildSettings(settingsFrame, bindKey)
            settingsFrame.Visible = true
        else
            settingsFrame.Visible = false
        end
    end

    -- ЛКМ = вкл/выкл
    rowBtn.MouseButton1Click:Connect(function()
        setToggleState(not state)
    end)

    -- ПКМ = настройки
    rowBtn.MouseButton2Click:Connect(function()
        openSettings()
    end)

    -- Hover
    rowBtn.MouseEnter:Connect(function()
        TweenService:Create(rowF, TweenInfo.new(0.1), {BackgroundColor3 = state and Color3.fromRGB(45,40,75) or BG_ROW_HOV}):Play()
    end)
    rowBtn.MouseLeave:Connect(function()
        TweenService:Create(rowF, TweenInfo.new(0.1), {BackgroundColor3 = state and BG_ON or BG_COL}):Play()
    end)

    return {
        setState = setToggleState,
        getState = function() return state end,
    }
end

-- ============================================================
-- СТРОИТЕЛЬ НАСТРОЕК
-- ============================================================
local function makeDividerInSettings(parent, order)
    local d=makeFrame(parent, UDim2.new(1,0,0,1), nil, DIVIDER)
    d.LayoutOrder=order or 0
end

local function makeSectionLabel(parent, text, order)
    local f=makeFrame(parent, UDim2.new(1,0,0,24), nil, BG_COL)
    f.LayoutOrder=order or 0
    pad(f,0,0,14,0)
    local l=makeLabel(f, text, UDim2.new(1,0,1,0), TEXT_DIM, FONT_BOLD)
    l.TextSize=10
end

-- Строка бинда
local function makeBindRow(parent, labelText, currentKey, onChanged, order)
    local f=makeFrame(parent, UDim2.new(1,0,0,36), nil, BG_COL)
    f.LayoutOrder=order or 0
    pad(f,0,0,14,12)

    local lbl=makeLabel(f, labelText, UDim2.new(1,-80,1,0), TEXT_SEC, FONT_REG)
    lbl.TextSize=12

    local keyF=makeFrame(f, UDim2.new(0,64,0,24), UDim2.new(1,-64,0.5,-12), Color3.fromRGB(45,40,75))
    corner(keyF,6)

    local keyLbl=makeLabel(keyF, keyName(currentKey), UDim2.new(1,0,1,0), ACCENT2, FONT_BOLD, Enum.TextXAlignment.Center)
    keyLbl.TextSize=11

    local keyBtn=makeBtn(keyF, UDim2.new(1,0,1,0), nil, Color3.new(0,0,0), "", TEXT_PRI, 11, FONT_BOLD)
    keyBtn.BackgroundTransparency=1
    keyBtn.ZIndex=5

    local listening=false
    keyBtn.MouseButton1Click:Connect(function()
        if listeningBind then
            listeningBind.el.Text=keyName(listeningBind.kc)
            listeningBind.el.TextColor3=ACCENT2
            TweenService:Create(listeningBind.bg, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(45,40,75)}):Play()
        end
        listeningBind={el=keyLbl, bg=keyF, kc=currentKey, cb=onChanged}
        keyLbl.Text="..."
        keyLbl.TextColor3=Color3.fromRGB(255,200,60)
        TweenService:Create(keyF, TweenInfo.new(0.1), {BackgroundColor3=Color3.fromRGB(80,60,20)}):Play()
    end)

    return keyLbl
end

-- Слайдер
local function makeSliderRow(parent, labelText, min, max, initVal, onChanged, order)
    local f=makeFrame(parent, UDim2.new(1,0,0,54), nil, BG_COL)
    f.LayoutOrder=order or 0
    pad(f,8,8,14,14)

    local topRow=makeFrame(f, UDim2.new(1,0,0,16), nil, Color3.new(0,0,0))
    topRow.BackgroundTransparency=1
    local lbl=makeLabel(topRow, labelText, UDim2.new(1,-40,1,0), TEXT_SEC, FONT_REG)
    lbl.TextSize=12
    local valLbl=makeLabel(topRow, tostring(initVal), UDim2.new(0,36,1,0), ACCENT2, FONT_BOLD, Enum.TextXAlignment.Right)
    valLbl.Position=UDim2.new(1,-36,0,0)
    valLbl.TextSize=12

    local trackF=makeFrame(f, UDim2.new(1,0,0,4), UDim2.new(0,0,1,-4), Color3.fromRGB(45,42,70))
    corner(trackF,2)

    local rel=math.clamp((initVal-min)/(max-min),0,1)
    local fillF=makeFrame(trackF, UDim2.new(rel,0,1,0), nil, ACCENT)
    corner(fillF,2)

    local thumbF=makeFrame(trackF, UDim2.new(0,12,0,12), UDim2.new(rel,-6,0.5,-6), Color3.fromRGB(220,210,255))
    corner(thumbF,6)
    thumbF.ZIndex=3

    local sliding=false
    local trackBtn=makeBtn(trackF, UDim2.new(1,0,0,24), UDim2.new(0,0,0.5,-12), Color3.new(0,0,0), "", TEXT_PRI, 12, FONT_REG)
    trackBtn.BackgroundTransparency=1
    trackBtn.ZIndex=4

    trackBtn.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=true end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then sliding=false end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if sliding and i.UserInputType==Enum.UserInputType.MouseMovement then
            local tr=trackF.AbsolutePosition.X
            local tw=trackF.AbsoluteSize.X
            local r=math.clamp((i.Position.X-tr)/tw,0,1)
            local val=math.floor(min+(max-min)*r)
            fillF.Size=UDim2.new(r,0,1,0)
            thumbF.Position=UDim2.new(r,-6,0.5,-6)
            valLbl.Text=tostring(val)
            onChanged(val)
        end
    end)

    return valLbl
end

-- Тогл-строка
local function makeToggleRow(parent, labelText, initVal, onChanged, order)
    local f=makeFrame(parent, UDim2.new(1,0,0,34), nil, BG_COL)
    f.LayoutOrder=order or 0
    pad(f,0,0,14,12)

    local lbl=makeLabel(f, labelText, UDim2.new(1,-60,1,0), TEXT_SEC, FONT_REG)
    lbl.TextSize=12

    local pillF=makeFrame(f, UDim2.new(0,36,0,20), UDim2.new(1,-48,0.5,-10), initVal and Color3.fromRGB(80,60,180) or Color3.fromRGB(45,42,70))
    corner(pillF,10)

    local circF=makeFrame(pillF, UDim2.new(0,14,0,14), initVal and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7), Color3.fromRGB(220,215,255))
    corner(circF,7)

    local state=initVal
    local btn=makeBtn(f, UDim2.new(1,0,1,0), nil, Color3.new(0,0,0), "", TEXT_PRI, 12, FONT_REG)
    btn.BackgroundTransparency=1
    btn.ZIndex=4

    btn.MouseButton1Click:Connect(function()
        state=not state
        TweenService:Create(pillF,TweenInfo.new(0.15),{BackgroundColor3=state and Color3.fromRGB(80,60,180) or Color3.fromRGB(45,42,70)}):Play()
        TweenService:Create(circF,TweenInfo.new(0.15),{Position=state and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)}):Play()
        onChanged(state)
    end)
end

-- ============================================================
-- КОЛОНКИ
-- ============================================================

-- ---- MOVEMENT ----
local movCol, movScroll = makeColumn("Movement","✈")

-- Fly
makeModule(movScroll, "Fly", "fly", false,
    function(s)
        config.flying=s
        if s then enableFly() else disableFly() end
    end,
    function(sf, bk)
        makeSectionLabel(sf,"BIND",1)
        makeBindRow(sf,"Вкл / Выкл",binds.fly,function(kc) binds.fly=kc end,2)
        makeDividerInSettings(sf,3)
        makeSectionLabel(sf,"НАСТРОЙКИ",4)
        makeSliderRow(sf,"Скорость полёта",10,200,config.flySpeed,function(v) config.flySpeed=v end,5)
        makeSliderRow(sf,"Высота следования",1,20,config.followHeight,function(v) config.followHeight=v end,6)
        makeDividerInSettings(sf,7)
        makeToggleRow(sf,"Follow mode",config.following,function(s)
            config.following=s
            if s and not config.flying then enableFly() end
        end,8)
    end,
1)

-- Noclip
makeModule(movScroll, "Noclip", "noclip", false,
    function(s)
        config.noclip=s
        if not s then
            local char=lp.Character
            if char then
                for _,p in pairs(char:GetDescendants()) do
                    if p:IsA("BasePart") then p.CanCollide=true end
                end
            end
        end
    end,
    function(sf, bk)
        makeSectionLabel(sf,"BIND",1)
        makeBindRow(sf,"Вкл / Выкл",binds.noclip,function(kc) binds.noclip=kc end,2)
    end,
2)

-- Walk Speed
local walkMod = makeModule(movScroll, "Walk Speed", "walkSpeed", false,
    function(s)
        config.walkSpeedEnabled=s
        local char=lp.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed=s and config.walkSpeed or 16 end
    end,
    function(sf, bk)
        makeSectionLabel(sf,"BIND",1)
        makeBindRow(sf,"Вкл / Выкл",binds.walkSpeed,function(kc) binds.walkSpeed=kc end,2)
        makeDividerInSettings(sf,3)
        makeSectionLabel(sf,"СКОРОСТЬ",4)
        makeSliderRow(sf,"Walk Speed",8,100,config.walkSpeed,function(v)
            config.walkSpeed=v
            if config.walkSpeedEnabled then
                local char=lp.Character
                local hum=char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.WalkSpeed=v end
            end
        end,5)
    end,
3)

-- Jump Height
local jumpMod = makeModule(movScroll, "Jump Height", "jumpHeight", false,
    function(s)
        config.jumpHeightEnabled=s
        local char=lp.Character
        local hum=char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpHeight=s and config.jumpHeight or 7; hum.JumpPower=s and config.jumpHeight or 7 end
    end,
    function(sf, bk)
        makeSectionLabel(sf,"BIND",1)
        makeBindRow(sf,"Вкл / Выкл",binds.jumpHeight,function(kc) binds.jumpHeight=kc end,2)
        makeDividerInSettings(sf,3)
        makeSectionLabel(sf,"ВЫСОТА",4)
        makeSliderRow(sf,"Jump Height",0,100,config.jumpHeight,function(v)
            config.jumpHeight=v
            if config.jumpHeightEnabled then
                local char=lp.Character
                local hum=char and char:FindFirstChildOfClass("Humanoid")
                if hum then hum.JumpHeight=v; hum.JumpPower=v end
            end
        end,5)
    end,
4)

-- Anti Fling
makeModule(movScroll, "Anti Fling", "antiFling", false,
    function(s)
        config.antiFlingEnabled=s
        if s then enableAntiFling() else disableAntiFling() end
    end,
    function(sf, bk)
        makeSectionLabel(sf,"BIND",1)
        makeBindRow(sf,"Вкл / Выкл",binds.antiFling,function(kc) binds.antiFling=kc end,2)
        makeDividerInSettings(sf,3)
        makeSectionLabel(sf,"ПОРОГ",4)
        makeSliderRow(sf,"Макс. скорость",50,500,config.antiFlingMaxVel,function(v) config.antiFlingMaxVel=v end,5)
    end,
5)

-- ---- VISUALS ----
local visCol, visScroll = makeColumn("Visuals","👁")

-- ESP
makeModule(visScroll, "ESP", "esp", false,
    function(s)
        config.espEnabled=s
        if s then enableESP() else disableESP() end
    end,
    function(sf, bk)
        makeSectionLabel(sf,"BIND",1)
        makeBindRow(sf,"Вкл / Выкл",binds.esp,function(kc) binds.esp=kc end,2)
        makeDividerInSettings(sf,3)
        makeSectionLabel(sf,"MM2 РОЛИ",4)
        makeToggleRow(sf,"Авто-определение",true,function(s) end,5)
    end,
1)

-- ---- PLAYER ----
local plCol, plScroll = makeColumn("Player","👤")

-- Follow (выбор игрока)
do
    local searchQuery=""
    local selectedBtn=nil

    local headerF=makeFrame(plScroll, UDim2.new(1,0,0,36), nil, BG_COL)
    headerF.LayoutOrder=0
    pad(headerF,6,6,10,10)

    local searchBox=Instance.new("TextBox")
    searchBox.Size=UDim2.new(1,0,1,0)
    searchBox.BackgroundColor3=Color3.fromRGB(35,32,58)
    searchBox.BorderSizePixel=0
    searchBox.PlaceholderText="Поиск игрока..."
    searchBox.PlaceholderColor3=TEXT_DIM
    searchBox.TextColor3=TEXT_PRI
    searchBox.TextSize=12
    searchBox.Font=FONT_REG
    searchBox.Text=""
    searchBox.ClearTextOnFocus=false
    searchBox.Parent=headerF
    corner(searchBox,6)
    pad(searchBox,0,0,8,8)

    local listF=makeFrame(plScroll, UDim2.new(1,0,0,0), nil, BG_COL)
    listF.AutomaticSize=Enum.AutomaticSize.Y
    listF.LayoutOrder=1
    listLayout(listF,1)

    local function refreshPlayers()
        for _,c in pairs(listF:GetChildren()) do
            if c:IsA("TextButton") or c:IsA("Frame") then c:Destroy() end
        end
        selectedBtn=nil
        local q=searchQuery:lower()
        for _,p in pairs(Players:GetPlayers()) do
            if p~=lp then
                local dn=p.DisplayName:lower()
                local un=p.Name:lower()
                if q=="" or dn:find(q,1,true) or un:find(q,1,true) then
                    local ptype=getPlayerType(p)
                    local icon= ptype=="tg" and "📡" or ptype=="yt" and "▶" or ptype=="tt" and "♪" or "●"
                    local clr = ptype=="tg" and Color3.fromRGB(255,200,60) or ptype=="yt" and Color3.fromRGB(255,100,100) or TEXT_SEC

                    local btn=makeBtn(listF, UDim2.new(1,0,0,32), nil, BG_COL, "", TEXT_PRI, 12, FONT_REG)
                    pad(btn,0,0,14,10)
                    btn.AutomaticSize=Enum.AutomaticSize.None

                    local iconL=makeLabel(btn, icon, UDim2.new(0,18,1,0), clr, FONT_BOLD)
                    iconL.TextSize=10

                    local nameL=makeLabel(btn, p.DisplayName.." (@"..p.Name..")", UDim2.new(1,-28,1,0), TEXT_SEC, FONT_REG)
                    nameL.Position=UDim2.new(0,22,0,0)
                    nameL.TextSize=11
                    nameL.TextTruncate=Enum.TextTruncate.AtEnd

                    if config.targetPlayer==p then
                        btn.BackgroundColor3=BG_ON
                        nameL.TextColor3=TEXT_PRI
                        selectedBtn=btn
                    end

                    btn.MouseButton1Click:Connect(function()
                        if selectedBtn then
                            TweenService:Create(selectedBtn,TweenInfo.new(0.1),{BackgroundColor3=BG_COL}):Play()
                        end
                        config.targetPlayer=p
                        config.following=true
                        if not config.flying then enableFly() end
                        TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=BG_ON}):Play()
                        nameL.TextColor3=TEXT_PRI
                        selectedBtn=btn
                    end)

                    btn.MouseEnter:Connect(function()
                        if selectedBtn~=btn then
                            TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=BG_ROW_HOV}):Play()
                        end
                    end)
                    btn.MouseLeave:Connect(function()
                        if selectedBtn~=btn then
                            TweenService:Create(btn,TweenInfo.new(0.1),{BackgroundColor3=BG_COL}):Play()
                        end
                    end)
                end
            end
        end
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        searchQuery=searchBox.Text
        refreshPlayers()
    end)
    refreshPlayers()
    Players.PlayerAdded:Connect(refreshPlayers)
    Players.PlayerRemoving:Connect(function() task.wait(0.1) refreshPlayers() end)

    -- Кнопка стоп
    local stopF=makeFrame(plScroll, UDim2.new(1,0,0,34), nil, BG_COL)
    stopF.LayoutOrder=2
    pad(stopF,5,5,10,10)

    local stopBtn=makeBtn(stopF, UDim2.new(1,0,1,0), nil, Color3.fromRGB(120,35,35), "✕  Стоп", Color3.fromRGB(255,180,180), 12, FONT_BOLD)
    corner(stopBtn,6)
    stopBtn.MouseButton1Click:Connect(function()
        config.following=false
        config.targetPlayer=nil
        if selectedBtn then
            TweenService:Create(selectedBtn,TweenInfo.new(0.1),{BackgroundColor3=BG_COL}):Play()
            selectedBtn=nil
        end
    end)
end

-- ---- OTHER / CONFIG ----
local othCol, othScroll = makeColumn("Config","⚙")

-- Menu bind
makeModule(othScroll, "Menu (ClickGUI)", "menu", true,
    function(s) end,
    function(sf, bk)
        makeSectionLabel(sf,"BIND",1)
        makeBindRow(sf,"Открыть / Закрыть",binds.menu,function(kc) binds.menu=kc end,2)
    end,
1)

-- Unfollow bind
makeModule(othScroll, "Unfollow", "unfollow", false,
    function(s)
        config.following=false
        config.targetPlayer=nil
    end,
    function(sf, bk)
        makeSectionLabel(sf,"BIND",1)
        makeBindRow(sf,"Остановить преследование",binds.unfollow,function(kc) binds.unfollow=kc end,2)
    end,
2)

-- Save / Load
do
    local savF=makeFrame(othScroll, UDim2.new(1,0,0,36), nil, BG_COL)
    savF.LayoutOrder=10
    pad(savF,5,5,8,8)

    local row=makeFrame(savF, UDim2.new(1,0,1,0), nil, Color3.new(0,0,0))
    row.BackgroundTransparency=1
    listLayout(row,6,Enum.FillDirection.Horizontal)

    local saveBtn=makeBtn(row, UDim2.new(0.5,-3,1,0), nil, Color3.fromRGB(30,90,55), "💾 Сохранить", Color3.fromRGB(100,255,160), 11, FONT_BOLD)
    corner(saveBtn,6)
    local loadBtn=makeBtn(row, UDim2.new(0.5,-3,1,0), nil, Color3.fromRGB(25,50,110), "📂 Загрузить", Color3.fromRGB(100,160,255), 11, FONT_BOLD)
    corner(loadBtn,6)

    local statusL=makeLabel(othScroll, "", UDim2.new(1,0,0,18), Color3.fromRGB(100,220,130), FONT_BOLD, Enum.TextXAlignment.Center)
    statusL.LayoutOrder=11
    statusL.TextSize=11

    local function showStatus(msg,err)
        statusL.Text=msg
        statusL.TextColor3=err and Color3.fromRGB(255,100,100) or Color3.fromRGB(100,220,130)
        task.delay(2.5,function() statusL.Text="" end)
    end

    local function getSettings()
        local t={flySpeed=config.flySpeed,walkSpeed=config.walkSpeed,jumpHeight=config.jumpHeight,antiFlingMaxVel=config.antiFlingMaxVel}
        for k,v in pairs(binds) do t["bind_"..k]=tostring(v) end
        for ptype,cols in pairs(espColors) do
            for ch,c in pairs(cols) do
                if type(c)=="userdata" then t["esp_"..ptype.."_"..ch]=colorToStr(c) end
            end
        end
        return t
    end

    saveBtn.MouseButton1Click:Connect(function()
        local ok=pcall(function() writefile(SAVE_FILE,serialize(getSettings())) end)
        showStatus(ok and "✔ Сохранено!" or "✘ Ошибка",not ok)
    end)

    loadBtn.MouseButton1Click:Connect(function()
        local ok,raw=pcall(function() return isfile(SAVE_FILE) and readfile(SAVE_FILE) end)
        if not ok or not raw then showStatus("✘ Файл не найден",true) return end
        local d=deserialize(raw)
        if tonumber(d.flySpeed) then config.flySpeed=math.clamp(math.floor(tonumber(d.flySpeed)),1,500) end
        if tonumber(d.walkSpeed) then config.walkSpeed=math.clamp(math.floor(tonumber(d.walkSpeed)),1,300) end
        if tonumber(d.jumpHeight) then config.jumpHeight=math.clamp(math.floor(tonumber(d.jumpHeight)),0,300) end
        if tonumber(d.antiFlingMaxVel) then config.antiFlingMaxVel=math.clamp(math.floor(tonumber(d.antiFlingMaxVel)),50,1000) end
        for k in pairs(binds) do
            local kc=toKeyCode(d["bind_"..k])
            if kc then binds[k]=kc end
        end
        for ptype,cols in pairs(espColors) do
            for ch,c in pairs(cols) do
                if type(c)=="userdata" then
                    local nc=strToColor(d["esp_"..ptype.."_"..ch] or "")
                    if nc then espColors[ptype][ch]=nc end
                end
            end
        end
        if config.espEnabled then refreshAllESP() end
        showStatus("✔ Загружено!")
    end)

    -- Версия
    local verL=makeLabel(othScroll,"💜 Testing v2.0  |  DreamCompany",UDim2.new(1,0,0,28),TEXT_DIM,FONT_BOLD,Enum.TextXAlignment.Center)
    verL.LayoutOrder=20
    verL.TextSize=10
end

-- ============================================================
-- ОБРАБОТКА КЛАВИШ
-- ============================================================
local blockedKeys={
    [Enum.KeyCode.Escape]=true,[Enum.KeyCode.Return]=true,
    [Enum.KeyCode.Tab]=true,[Enum.KeyCode.Backspace]=true,
    [Enum.KeyCode.Delete]=true,[Enum.KeyCode.Unknown]=true,
}

UserInputService.InputBegan:Connect(function(input, gp)
    -- Смена бинда
    if listeningBind then
        local kc=input.KeyCode
        if kc==Enum.KeyCode.Escape then
            listeningBind.el.Text=keyName(listeningBind.kc)
            listeningBind.el.TextColor3=ACCENT2
            TweenService:Create(listeningBind.bg,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(45,40,75)}):Play()
            listeningBind=nil
        elseif not blockedKeys[kc] and kc~=Enum.KeyCode.Unknown then
            listeningBind.kc=kc
            listeningBind.el.Text=keyName(kc)
            listeningBind.el.TextColor3=ACCENT2
            TweenService:Create(listeningBind.bg,TweenInfo.new(0.1),{BackgroundColor3=Color3.fromRGB(45,40,75)}):Play()
            if listeningBind.cb then listeningBind.cb(kc) end
            listeningBind=nil
        end
        return
    end

    -- Горячие клавиши
    if input.KeyCode==binds.menu then
        guiVisible=not guiVisible
        holder.Visible=guiVisible
        return
    end

    if gp then return end
end)

print("💤 Testing ClickGUI v2.0 loaded | "..keyName(binds.menu).." — открыть меню")
