--[[
    Auto Flick & Silent Aim System
    Roblox Luau - Executor Level 7/8
--]]

local players = game:GetService("Players")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local httpService = game:GetService("HttpService")
local guiService = game:GetService("GuiService")

local localPlayer = players.LocalPlayer
local mouse = localPlayer:GetMouse()

local settings = {
    autoFlick = {
        enabled = true,
        range = 12.5,
        jitterMin = 0.02,
        jitterMax = 0.08,
        height = 3.4
    },
    silentAim = {
        enabled = true,
        hotkey = Enum.KeyCode.LeftShift,
        active = false,
        prediction = true
    },
    esp = {
        enabled = true,
        type = "Box",
        color = Color3.fromRGB(255, 0, 0),
        transparency = 0.5
    },
    curveCompensation = {
        enabled = true,
        strength = 0.75,
        angle = 0
    },
    ui = {
        visible = true,
        position = UDim2.new(0.85, 0, 0.5, -150)
    }
}

local goalCache = {
    position = nil,
    part = nil,
    center = nil
}

local ballCache = {
    instance = nil,
    primaryPart = nil,
    magnitude = math.huge
}

local playerCache = {}
local espInstances = {}

local screenGui
local mainFrame

local function createUI()
    screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AutoFlickUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 320, 0, 450)
    mainFrame.Position = settings.ui.position
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = titleBar
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -40, 1, 0)
    title.Position = UDim2.new(0, 10, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "Auto Flick v2.0"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundTransparency = 1
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 18
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = titleBar
    closeBtn.MouseButton1Click:Connect(function()
        settings.ui.visible = not settings.ui.visible
        mainFrame.Visible = settings.ui.visible
    end)
    
    local scrollContainer = Instance.new("ScrollingFrame")
    scrollContainer.Size = UDim2.new(1, 0, 1, -40)
    scrollContainer.Position = UDim2.new(0, 0, 0, 40)
    scrollContainer.BackgroundTransparency = 1
    scrollContainer.ScrollBarThickness = 4
    scrollContainer.CanvasSize = UDim2.new(0, 0, 0, 600)
    scrollContainer.Parent = mainFrame
    
    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 10)
    layout.Parent = scrollContainer
    
    local function createToggle(titleText, bindVar, bindCategory)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -20, 0, 45)
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        frame.Parent = scrollContainer
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 6)
        frameCorner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -60, 1, 0)
        label.Position = UDim2.new(0, 10, 0, 0)
        label.BackgroundTransparency = 1
        label.Text = titleText
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 50, 0, 30)
        button.Position = UDim2.new(1, -60, 0, 7.5)
        button.BackgroundColor3 = settings[bindCategory][bindVar] and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(244, 67, 54)
        button.Text = settings[bindCategory][bindVar] and "ON" or "OFF"
        button.TextColor3 = Color3.fromRGB(255, 255, 255)
        button.TextSize = 12
        button.Font = Enum.Font.GothamBold
        button.BorderSizePixel = 0
        button.Parent = frame
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 4)
        btnCorner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            settings[bindCategory][bindVar] = not settings[bindCategory][bindVar]
            button.BackgroundColor3 = settings[bindCategory][bindVar] and Color3.fromRGB(76, 175, 80) or Color3.fromRGB(244, 67, 54)
            button.Text = settings[bindCategory][bindVar] and "ON" or "OFF"
        end)
        
        return frame
    end
    
    local function createSlider(titleText, bindVar, bindCategory, minVal, maxVal, decimals)
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(1, -20, 0, 70)
        frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
        frame.BackgroundTransparency = 0.3
        frame.BorderSizePixel = 0
        frame.Parent = scrollContainer
        
        local frameCorner = Instance.new("UICorner")
        frameCorner.CornerRadius = UDim.new(0, 6)
        frameCorner.Parent = frame
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, -20, 0, 25)
        label.Position = UDim2.new(0, 10, 0, 5)
        label.BackgroundTransparency = 1
        label.Text = titleText .. ": " .. tostring(settings[bindCategory][bindVar])
        label.TextColor3 = Color3.fromRGB(220, 220, 220)
        label.TextSize = 14
        label.Font = Enum.Font.Gotham
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.Parent = frame
        
        local slider = Instance.new("TextButton")
        slider.Size = UDim2.new(1, -20, 0, 4)
        slider.Position = UDim2.new(0, 10, 0, 40)
        slider.BackgroundColor3 = Color3.fromRGB(100, 100, 110)
        slider.BackgroundTransparency = 0
        slider.Text = ""
        slider.AutoButtonColor = false
        slider.Parent = frame
        
        local fill = Instance.new("Frame")
        fill.Size = UDim2.new((settings[bindCategory][bindVar] - minVal) / (maxVal - minVal), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(76, 175, 80)
        fill.BackgroundTransparency = 0
        fill.BorderSizePixel = 0
        fill.Parent = slider
        
        local handle = Instance.new("TextButton")
        handle.Size = UDim2.new(0, 16, 0, 16)
        handle.Position = UDim2.new((settings[bindCategory][bindVar] - minVal) / (maxVal - minVal), -8, 0, -6)
        handle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        handle.Text = ""
        handle.AutoButtonColor = false
        handle.Parent = slider
        
        local handleCorner = Instance.new("UICorner")
        handleCorner.CornerRadius = UDim.new(1, 0)
        handleCorner.Parent = handle
        
        local dragging = false
        
        handle.MouseButton1Down:Connect(function()
            dragging = true
        end)
        
        userInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
        
        userInputService.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local mousePos = input.Position.X
                local sliderPos = slider.AbsolutePosition.X
                local width = slider.AbsoluteSize.X
                local percent = math.clamp((mousePos - sliderPos) / width, 0, 1)
                local value = minVal + (maxVal - minVal) * percent
                if decimals == 0 then
                    value = math.floor(value + 0.5)
                else
                    value = tonumber(string.format("%." .. decimals .. "f", value))
                end
                settings[bindCategory][bindVar] = value
                label.Text = titleText .. ": " .. tostring(value)
                fill.Size = UDim2.new(percent, 0, 1, 0)
                handle.Position = UDim2.new(percent, -8, 0, -6)
            end
        end)
        
        return frame
    end
    
    createToggle("Auto Flick", "enabled", "autoFlick")
    createSlider("Flick Range", "range", "autoFlick", 5, 25, 1)
    createSlider("Flick Height", "height", "autoFlick", 0, 8, 1)
    createSlider("Jitter Min", "jitterMin", "autoFlick", 0, 0.1, 3)
    createSlider("Jitter Max", "jitterMax", "autoFlick", 0.05, 0.2, 3)
    
    createToggle("Silent Aim", "enabled", "silentAim")
    createToggle("Curve Compensation", "enabled", "curveCompensation")
    createSlider("Curve Strength", "strength", "curveCompensation", 0, 1.5, 2)
    createSlider("Curve Angle", "angle", "curveCompensation", -3.14, 3.14, 2)
    
    createToggle("Player ESP", "enabled", "esp")
    
    local dragFrame = titleBar
    local draggingUI = false
    local dragStart
    
    dragFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingUI = true
            dragStart = input.Position
        end
    end)
    
    userInputService.InputChanged:Connect(function(input)
        if draggingUI and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(0, mainFrame.AbsolutePosition.X + delta.X, 0, mainFrame.AbsolutePosition.Y + delta.Y)
            dragStart = input.Position
        end
    end)
    
    userInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            draggingUI = false
        end
    end)
end

local function findGoal()
    for _, obj in pairs(workspace:GetDescendants()) do
        local name = obj.Name:lower()
        if (name:find("goal") or name:find("net") or name:find("detection")) and obj:IsA("BasePart") then
            goalCache.part = obj
            goalCache.position = obj.Position
            goalCache.center = obj.CFrame.Position + (obj.Size / 2)
            return true
        end
    end
    return false
end

local function findBall()
    for _, obj in pairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("ball") or obj:IsA("MeshPart") and obj.Size.magnitude < 5) then
            ballCache.instance = obj
            ballCache.primaryPart = obj
            return true
        end
    end
    return false
end

local function getAllPlayers()
    local list = {}
    for _, player in pairs(players:GetPlayers()) do
        if player ~= localPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            table.insert(list, player)
        end
    end
    return list
end

local function createESP(player)
    if not settings.esp.enabled then return end
    
    local character = player.Character
    if not character then return end
    
    local highlight = Instance.new("Highlight")
    highlight.FillColor = settings.esp.color
    highlight.FillTransparency = settings.esp.transparency
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0
    highlight.Adornee = character
    highlight.Parent = character
    
    espInstances[player] = highlight
end

local function updateESP()
    for _, player in pairs(getAllPlayers()) do
        if not espInstances[player] then
            createESP(player)
        end
    end
    
    for player, esp in pairs(espInstances) do
        if not player.Character or player.Character.Parent == nil then
            esp:Destroy()
            espInstances[player] = nil
        end
    end
end

local function calculateTrajectory(ballPos, goalPos, curveStrength, verticalHeight)
    local direction = (goalPos - ballPos).Unit
    local distance = (goalPos - ballPos).Magnitude
    
    local horizontalVector = Vector3.new(direction.X, 0, direction.Z).Unit
    local verticalVector = Vector3.new(0, verticalHeight, 0)
    
    local curveOffset = Vector3.new(
        math.sin(settings.curveCompensation.angle) * curveStrength,
        0,
        math.cos(settings.curveCompensation.angle) * curveStrength
    )
    
    local predictedPos = goalPos + (curveOffset * distance * 0.15)
    local finalDirection = (predictedPos - ballPos).Unit
    
    local resultVector = (finalDirection * 85) + (verticalVector * 35)
    
    if settings.curveCompensation.enabled then
        local curveCorrection = Vector3.new(
            -curveOffset.X * settings.curveCompensation.strength * distance * 0.08,
            verticalHeight * 0.5,
            -curveOffset.Z * settings.curveCompensation.strength * distance * 0.08
        )
        resultVector = resultVector + curveCorrection
    end
    
    return resultVector
end

local originalFireServer
local hookActive = false

local function setupSilentAim()
    if hookActive then return end
    
    originalFireServer = originalFireServer or game:GetService("ReplicatedStorage").FireServer
    
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    
    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}
        
        if method == "FireServer" and settings.silentAim.enabled and settings.silentAim.active then
            local argsString = string.dump(args)
            
            if argsString:find("kick") or argsString:find("shoot") or argsString:find("curve") then
                local ball = ballCache.primaryPart
                local goal = goalCache.part
                
                if ball and goal then
                    local ballPos = ball.Position
                    local goalPos = goalCache.center or goal.Position
                    
                    local trajectory = calculateTrajectory(
                        ballPos,
                        goalPos,
                        settings.curveCompensation.strength,
                        settings.autoFlick.height
                    )
                    
                    for i = 1, #args do
                        if type(args[i]) == "Vector3" then
                            args[i] = trajectory
                        elseif type(args[i]) == "CFrame" then
                            args[i] = CFrame.new(trajectory)
                        elseif type(args[i]) == "table" and args[i].Position then
                            args[i].Position = trajectory
                        end
                    end
                end
            end
        end
        
        return oldNamecall(self, unpack(args))
    end)
    setreadonly(mt, true)
    hookActive = true
end

local function autoFlickCheck()
    if not settings.autoFlick.enabled then return end
    
    local ball = ballCache.primaryPart
    local character = localPlayer.Character
    
    if not ball or not character then return end
    
    local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRoot then return end
    
    local distance = (humanoidRoot.Position - ball.Position).Magnitude
    
    if distance <= settings.autoFlick.range then
        local jitter = math.random() * (settings.autoFlick.jitterMax - settings.autoFlick.jitterMin) + settings.autoFlick.jitterMin
        task.wait(jitter)
        
        local keyToPress = settings.silentAim.hotkey
        if keyToPress then
            userInputService:SetKeyDown(keyToPress)
            task.wait(0.016)
            userInputService:SetKeyUp(keyToPress)
        end
        
        local remoteEvents = replicatedStorage:GetDescendants()
        for _, remote in pairs(remoteEvents) do
            if remote:IsA("RemoteEvent") and (remote.Name:lower():find("kick") or remote.Name:lower():find("shoot")) then
                remote:FireServer(calculateTrajectory(
                    ball.Position,
                    goalCache.center or (goalCache.part and goalCache.part.Position) or ball.Position + Vector3.new(0, settings.autoFlick.height, 0),
                    settings.curveCompensation.strength,
                    settings.autoFlick.height
                ))
            end
        end
    end
end

local function updateBallTracking()
    if not ballCache.instance then
        findBall()
    else
        ballCache.magnitude = ballCache.primaryPart and (localPlayer.Character and localPlayer.Character:FindFirstChild("HumanoidRootPart") and (localPlayer.Character.HumanoidRootPart.Position - ballCache.primaryPart.Position).Magnitude or math.huge) or math.huge
    end
end

local function updateGoalTracking()
    if not goalCache.part then
        findGoal()
    end
end

local function saveConfig()
    local configData = {
        autoFlick = settings.autoFlick,
        silentAim = settings.silentAim,
        esp = settings.esp,
        curveCompensation = settings.curveCompensation
    }
    
    local json = httpService:JSONEncode(configData)
    writefile("AutoFlick_Config.json", json)
end

local function loadConfig()
    if isfile("AutoFlick_Config.json") then
        local json = readfile("AutoFlick_Config.json")
        local data = httpService:JSONDecode(json)
        
        for k, v in pairs(data) do
            if settings[k] then
                for k2, v2 in pairs(v) do
                    settings[k][k2] = v2
                end
            end
        end
    end
end

local function setupKeybinds()
    userInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == settings.silentAim.hotkey then
            settings.silentAim.active = true
        elseif input.KeyCode == Enum.KeyCode.RightShift then
            settings.autoFlick.enabled = not settings.autoFlick.enabled
        elseif input.KeyCode == Enum.KeyCode.RightControl then
            settings.esp.enabled = not settings.esp.enabled
            if not settings.esp.enabled then
                for _, esp in pairs(espInstances) do
                    esp:Destroy()
                end
                table.clear(espInstances)
            end
        elseif input.KeyCode == Enum.KeyCode.Insert then
            settings.ui.visible = not settings.ui.visible
            if mainFrame then
                mainFrame.Visible = settings.ui.visible
            end
        end
    end)
    
    userInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.KeyCode == settings.silentAim.hotkey then
            settings.silentAim.active = false
        end
    end)
end

local function startLoop()
    runService.Heartbeat:Connect(function(deltaTime)
        updateBallTracking()
        updateGoalTracking()
        
        if settings.autoFlick.enabled then
            autoFlickCheck()
        end
        
        if settings.esp.enabled then
            updateESP()
        end
        
        if settings.silentAim.enabled then
            setupSilentAim()
        end
    end)
    
    runService.RenderStepped:Connect(function()
        if settings.silentAim.active and goalCache.part and mouse then
            local camera = workspace.CurrentCamera
            local screenPoint = camera:WorldToScreenPoint(goalCache.center or goalCache.part.Position)
            if screenPoint.Z > 0 then
                mouse.TargetFilter = goalCache.part
            end
        end
    end)
end

local camera = workspace.CurrentCamera
if camera then
    camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
        if settings.silentAim.active then
            camera.FieldOfView = 70
        end
    end)
end

loadConfig()
findGoal()
findBall()
setupKeybinds()
createUI()
startLoop()

getgenv().AutoFlick = {
    setRange = function(range) settings.autoFlick.range = range end,
    setHeight = function(height) settings.autoFlick.height = height end,
    setCurveStrength = function(strength) settings.curveCompensation.strength = strength end,
    setCurveAngle = function(angle) settings.curveCompensation.angle = angle end,
    save = saveConfig,
    reload = loadConfig
}
