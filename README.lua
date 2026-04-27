--[[
   vein
--]]

local players = game:GetService("Players")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local httpService = game:GetService("HttpService")

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
    characterSize = {
        enabled = true,
        scale = 2.5
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

local function manipulateCharacterSize()
    if not settings.characterSize.enabled then return end
    
    local character = localPlayer.Character
    if not character then return end
    
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            local originalSize = part.Size
            part.Size = originalSize * settings.characterSize.scale
            part.CustomPhysicalProperties = PhysicalProperties.new(part.Material, part.CustomPhysicalProperties.Density, part.CustomPhysicalProperties.Friction, 0.1)
        end
    end
    
    local humanoidRoot = character:FindFirstChild("HumanoidRootPart")
    if humanoidRoot then
        local touchInterest = humanoidRoot:FindFirstChild("TouchInterest")
        if touchInterest then
            touchInterest:Destroy()
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
            local keyCode = Enum.KeyCode[keyToPress.Name] or keyToPress
            userInputService:SetKeyDown(keyCode)
            task.wait(0.016)
            userInputService:SetKeyUp(keyCode)
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
        characterSize = settings.characterSize,
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
        end
    end)
    
    userInputService.InputEnded:Connect(function(input, gameProcessed)
        if input.KeyCode == settings.silentAim.hotkey then
            settings.silentAim.active = false
        end
    end)
end

local function initializeCharacter()
    localPlayer.CharacterAdded:Connect(function(character)
        task.wait(0.5)
        manipulateCharacterSize()
    end)
    
    if localPlayer.Character then
        manipulateCharacterSize()
    end
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
            local screenPoint = camera:WorldToScreenPoint(goalCache.center or goalCache.part.Position)
            if screenPoint.Z > 0 then
                mouse.TargetFilter = goalCache.part
            end
        end
    end)
end

local camera = workspace.CurrentCamera
camera:GetPropertyChangedSignal("FieldOfView"):Connect(function()
    if settings.silentAim.active then
        camera.FieldOfView = 70
    end
end)

loadConfig()
findGoal()
findBall()
setupKeybinds()
initializeCharacter()
startLoop()

getgenv().AutoFlick = {
    setRange = function(range) settings.autoFlick.range = range end,
    setHeight = function(height) settings.autoFlick.height = height end,
    setCurveStrength = function(strength) settings.curveCompensation.strength = strength end,
    setCurveAngle = function(angle) settings.curveCompensation.angle = angle end,
    save = saveConfig,
    reload = loadConfig
}
