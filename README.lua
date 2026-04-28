--[[
    SCRIPT NAME: Football Ultimate Hub
    VERSION: 1.0
    WARNING: This is for educational purposes only
--]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local PlayerGui = Player:WaitForChild("PlayerGui")

-- Services for remote detection
local Remotes = ReplicatedStorage:FindFirstChild("Remotes") or ReplicatedStorage:FindFirstChild("Network")

-- Configuration Storage
local Settings = {
    -- UI Automation
    AutoPickCF = false,
    AutoFlow = false,
    InfiniteStamina = false,
    
    -- Offensive
    MaxKickPower = false,
    KickPowerOverride = false,
    KickPowerValue = 100,
    AutoDribble = false,
    BallMagnet = false,
    SilentAimRiptide = false,
    
    -- Movement
    AntiAnkleBreak = false,
    SuperSlide = false,
    SpeedBoost = false,
    BoostValue = 24,
    FlowReroller = false,
    FlowColor = "Default",
    
    -- System
    AutoLoad = true,
    ServerHopExec = true
}

-- Profile System
local Profiles = {
    ["Default"] = {
        AutoPickCF = false, AutoFlow = false, InfiniteStamina = false,
        MaxKickPower = false, KickPowerOverride = false, KickPowerValue = 100,
        AutoDribble = false, BallMagnet = false, SilentAimRiptide = false,
        AntiAnkleBreak = false, SuperSlide = false, SpeedBoost = false,
        BoostValue =24, FlowReroller = false, FlowColor = "Default"
    },
    ["Tryhard"] = {
        AutoPickCF = true, AutoFlow = true, InfiniteStamina = true,
        MaxKickPower = true, KickPowerOverride = true, KickPowerValue = 100,
        AutoDribble = true, BallMagnet = true, SilentAimRiptide = true,
        AntiAnkleBreak = true, SuperSlide = true, SpeedBoost = true,
        BoostValue = 32, FlowReroller = true, FlowColor = "Blue"
    },
    ["Goalkeeper"] = {
        AutoPickCF = false, AutoFlow = false, InfiniteStamina = true,
        MaxKickPower = false, KickPowerOverride = false, KickPowerValue = 80,
        AutoDribble = false, BallMagnet = true, SilentAimRiptide = false,
        AntiAnkleBreak = true, SuperSlide = true, SpeedBoost = false,
        BoostValue = 20, FlowReroller = false, FlowColor = "Default"
    }
}

local CurrentProfile = "Default"

-- Utility Functions
local function SaveProfile()
    local profileData = {}
    for key, value in pairs(Settings) do
        profileData[key] = value
    end
    writefile("FootballHub_Profile_" .. CurrentProfile .. ".json", game:GetService("HttpService"):JSONEncode(profileData))
end

local function LoadProfile(name)
    if Profiles[name] then
        for key, value in pairs(Profiles[name]) do
            Settings[key] = value
        end
        CurrentProfile = name
        print("[Football Hub] Loaded profile: " .. name)
        return true
    end
    return false
end

-- UI Automation Features
local function AutoPickCFFeature()
    spawn(function()
        while Settings.AutoPickCF and task.wait(0.5) do
            -- Find Center Forward position button
            local positionButton = PlayerGui:FindFirstChild("PositionSelect", true)
            if positionButton and positionButton:FindFirstChild("CF") then
                local cfButton = positionButton.CF
                if cfButton and cfButton.Visible then
                    cfButton:Fire()
                    print("[Auto Pick CF] Claimed Center Forward position")
                end
            end
            
            -- Alternative: Find Team Select screen
            local teamSelect = PlayerGui:FindFirstChild("TeamSelect", true)
            if teamSelect and teamSelect:FindFirstChild("RedTeam") then
                -- Join attacking team if available
                local redButton = teamSelect.RedTeam
                if redButton then redButton:Fire() end
            end
        end
    end)
end

local function AutoFlowFeature()
    spawn(function()
        while Settings.AutoFlow and task.wait(2) do
            -- Find Flow ability button
            local abilityBar = PlayerGui:FindFirstChild("AbilityBar", true)
            if abilityBar then
                local flowButton = abilityBar:FindFirstChild("Flow")
                if flowButton and flowButton.Visible then
                    flowButton:Fire()
                    print("[Auto Flow] Reactivated Flow state")
                end
            end
            
            -- Alternative remote call
            local flowRemote = Remotes and Remotes:FindFirstChild("ActivateFlow")
            if flowRemote then
                flowRemote:FireServer()
            end
        end
    end)
end

local function InfiniteStaminaFeature()
    spawn(function()
        while Settings.InfiniteStamina and task.wait(0.1) do
            -- Method 1: Bypass stamina value
            local staminaValue = Player:FindFirstChild("Stamina")
            if staminaValue then
                staminaValue.Value = 100
            end
            
            -- Method 2: Intercept stamina drain
            local staminaStat = Player:FindFirstChild("leaderstats") and Player.leaderstats:FindFirstChild("Stamina")
            if staminaStat then
                staminaStat.Value = 100
            end
            
            -- Method 3: Prevent sprint fatigue
            if Character and Character:FindFirstChild("Humanoid") then
                local humanoid = Character.Humanoid
                if humanoid:GetState() == Enum.HumanoidStateType.Running then
                    humanoid:ChangeState(Enum.HumanoidStateType.RunningNoFriction)
                end
            end
        end
    end)
end

-- Offensive Features
local function MaxKickPowerFeature()
    spawn(function()
        while Settings.MaxKickPower and task.wait() do
            -- Hook into kick requests
            local kickRemote = Remotes and (Remotes:FindFirstChild("RequestKick") or Remotes:FindFirstChild("Kick"))
            if kickRemote then
                local oldFire = kickRemote.FireServer
                kickRemote.FireServer = function(self, ...)
                    local args = {...}
                    args[1] = 100 -- Max power
                    oldFire(self, unpack(args))
                end
            end
            
            -- Find kick power slider
            local kickUI = PlayerGui:FindFirstChild("KickUI", true)
            if kickUI then
                local powerBar = kickUI:FindFirstChild("PowerBar")
                if powerBar then
                    powerBar.Value = 100
                end
            end
        end
    end)
end

local function KickPowerOverrideFeature()
    spawn(function()
        while Settings.KickPowerOverride and task.wait() do
            local kickRemote = Remotes and Remotes:FindFirstChild("Kick")
            if kickRemote then
                local oldFire = kickRemote.FireServer
                kickRemote.FireServer = function(self, power, ...)
                    oldFire(self, Settings.KickPowerValue, ...)
                end
            end
        end
    end)
end

local function AutoDribbleFeature()
    local isDribbling = false
    spawn(function()
        while Settings.AutoDribble and task.wait(0.05) do
            -- Check if player has ball
            local ball = workspace:FindFirstChild("Ball")
            if ball and (ball.Position - Character.HumanoidRootPart.Position).Magnitude < 8 then
                if not isDribbling then
                    isDribbling = true
                    -- Hold dribble button
                    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    task.wait(0.1)
                end
            else
                if isDribbling then
                    isDribbling = false
                    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                end
            end
        end
    end)
end

local function BallMagnetFeature()
    spawn(function()
        while Settings.BallMagnet and task.wait() do
            local ball = workspace:FindFirstChild("Ball")
            if ball and Character and Character:FindFirstChild("HumanoidRootPart") then
                -- Expand ball hitbox by modifying its size
                if ball:FindFirstChild("TouchInterest") then
                    local touchInterest = ball.TouchInterest
                    -- Increase attraction range
                    for _, part in pairs(Character:GetDescendants()) do
                        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                            local distance = (ball.Position - part.Position).Magnitude
                            if distance < 12 then -- Increased from normal 4-5
                                -- Simulate ball touch
                                local remote = Remotes and Remotes:FindFirstChild("BallTouch")
                                if remote then
                                    remote:FireServer(ball)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)
end

local function SilentAimRiptideFeature()
    spawn(function()
        while Settings.SilentAimRiptide and task.wait(0.016) do
            -- Curve shot calculation
            local function CalculateCurve(targetPos)
                local goalPos = workspace:FindFirstChild("Goal") and workspace.Goal.Position or Vector3.new(0, 2, 50)
                local direction = (goalPos - targetPos).Unit
                -- Add curve offset
                local curve = Vector3.new(direction.Z * 1.5, direction.Y * 0.5, -direction.X * 1.5)
                return targetPos + curve
            end
            
            -- Hook into shot direction
            local shotRemote = Remotes and Remotes:FindFirstChild("Shoot")
            if shotRemote then
                local oldFire = shotRemote.FireServer
                shotRemote.FireServer = function(self, direction, ...)
                    local curved = CalculateCurve(direction)
                    oldFire(self, curved, ...)
                end
            end
        end
    })
end

-- Movement Features
local function AntiAnkleBreakFeature()
    spawn(function()
        while Settings.AntiAnkleBreak and task.wait() do
            if Character then
                -- Prevent stun/dropped states
                local humanoid = Character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.Stunned, false)
                    
                    -- Auto-recover from knocked states
                    if humanoid:GetState() == Enum.HumanoidStateType.FallingDown or 
                       humanoid:GetState() == Enum.HumanoidStateType.Stunned then
                        humanoid:ChangeState(Enum.HumanoidStateType.Running)
                    end
                end
                
                -- Fix root part constraints
                local rootPart = Character:FindFirstChild("HumanoidRootPart")
                if rootPart then
                    rootPart.Velocity = rootPart.Velocity * 0.9 -- Reduce fall impact
                end
            end
        end
    end)
end

local function SuperSlideFeature()
    spawn(function()
        while Settings.SuperSlide and task.wait() do
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then -- Slide button
                local humanoid = Character and Character:FindFirstChild("Humanoid")
                local rootPart = Character and Character:FindFirstChild("HumanoidRootPart")
                
                if humanoid and rootPart then
                    -- Extended slide velocity
                    local slideVelocity = rootPart.CFrame.LookVector * 80
                    rootPart.Velocity = slideVelocity
                    
                    -- Keep sliding infinitely
                    humanoid.PlatformStand = false
                    task.wait(0.5) -- Slide duration
                end
            end
        end
    end)
end

local function SpeedBoostFeature()
    spawn(function()
        while Settings.SpeedBoost and task.wait(0.1) do
            if Character and Character:FindFirstChild("Humanoid") then
                local humanoid = Character.Humanoid
                -- Override walkspeed
                humanoid.WalkSpeed = Settings.BoostValue
                
                -- Also modify sprint speed if applicable
                local sprintBoost = Player:FindFirstChild("SprintSpeed")
                if sprintBoost then
                    sprintBoost.Value = Settings.BoostValue * 1.5
                end
            end
        end
    end)
end

local function FlowRerollerFeature()
    local flowColors = {"Red", "Blue", "Green", "Yellow", "Purple", "Orange", "Default"}
    local currentColorIndex = 1
    
    spawn(function()
        while Settings.FlowReroller and task.wait(5) do -- Auto reroll every 5 seconds
            local flowRemote = Remotes and Remotes:FindFirstChild("ChangeFlowColor")
            if flowRemote then
                currentColorIndex = (currentColorIndex % #flowColors) + 1
                local selectedColor = flowColors[currentColorIndex]
                flowRemote:FireServer(selectedColor)
                print("[Flow Reroller] Changed to " .. selectedColor)
            end
        end
    end)
    
    -- Manual reroll binding
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.R and Settings.FlowReroller then
            local flowRemote = Remotes and Remotes:FindFirstChild("ChangeFlowColor")
            if flowRemote then
                currentColorIndex = (currentColorIndex % #flowColors) + 1
                flowRemote:FireServer(flowColors[currentColorIndex])
                print("[Flow Reroller] Manual reroll to " .. flowColors[currentColorIndex])
            end
        end
    end)
end

-- Server Hop Exec Feature
local function ServerHopExecFeature()
    if not Settings.ServerHopExec then return end
    
    local function OnTeleport()
        task.wait(3)
        print("[Football Hub] Teleport detected - reloading settings")
        LoadProfile(CurrentProfile)
        -- Re-initialize all features
        AutoPickCFFeature()
        AutoFlowFeature()
        InfiniteStaminaFeature()
        MaxKickPowerFeature()
        KickPowerOverrideFeature()
        AutoDribbleFeature()
        BallMagnetFeature()
        SilentAimRiptideFeature()
        AntiAnkleBreakFeature()
        SuperSlideFeature()
        SpeedBoostFeature()
        FlowRerollerFeature()
    end
    
    Player.OnTeleport:Connect(OnTeleport)
end

-- GUI Creation
local function CreateGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "FootballHubGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 350, 0, 500)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -250)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 2
    mainFrame.BorderColor3 = Color3.fromRGB(0, 255, 200)
    mainFrame.Parent = screenGui
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "⚽ FOOTBALL ULTIMATE HUB ⚽"
    title.TextColor3 = Color3.fromRGB(0, 255, 200)
    title.BackgroundTransparency = 1
    title.TextScaled = true
    title.Parent = mainFrame
    
    -- Tab buttons
    local tabs = {"UI", "OFFENSIVE", "MOVEMENT", "PROFILES"}
    local currentTab = "UI"
    
    -- Function to create toggle button
    local function CreateToggle(parent, text, settingName, yPos)
        local toggle = Instance.new("TextButton")
        toggle.Size = UDim2.new(0.9, 0, 0, 30)
        toggle.Position = UDim2.new(0.05, 0, 0, yPos)
        toggle.Text = text .. ": OFF"
        toggle.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
        toggle.TextColor3 = Color3.fromRGB(255, 255, 255)
        toggle.Parent = parent
        
        local function UpdateToggle()
            toggle.Text = text .. ": " .. (Settings[settingName] and "✅ ON" or "❌ OFF")
            toggle.BackgroundColor3 = Settings[settingName] and Color3.fromRGB(0, 150, 100) or Color3.fromRGB(50, 50, 60)
        end
        
        toggle.MouseButton1Click:Connect(function()
            Settings[settingName] = not Settings[settingName]
            UpdateToggle()
            SaveProfile()
        end)
        
        UpdateToggle()
        return toggle
    end
    
    -- UI Automation Tab
    local uiTab = Instance.new("ScrollingFrame")
    uiTab.Size = UDim2.new(1, 0, 1, -50)
    uiTab.Position = UDim2.new(0, 0, 0, 50)
    uiTab.BackgroundTransparency = 1
    uiTab.Visible = true
    uiTab.Parent = mainFrame
    
    local yOffset = 10
    CreateToggle(uiTab, "Auto Pick CF", "AutoPickCF", yOffset); yOffset = yOffset + 35
    CreateToggle(uiTab, "Auto Flow", "AutoFlow", yOffset); yOffset = yOffset + 35
    CreateToggle(uiTab, "Infinite Stamina", "InfiniteStamina", yOffset); yOffset = yOffset + 35
    
    -- Offensive Tab
    local offTab = Instance.new("ScrollingFrame")
    offTab.Size = UDim2.new(1, 0, 1, -50)
    offTab.Position = UDim2.new(0, 0, 0, 50)
    offTab.BackgroundTransparency = 1
    offTab.Visible = false
    offTab.Parent = mainFrame
    
    yOffset = 10
    CreateToggle(offTab, "Max Kick Power", "MaxKickPower", yOffset); yOffset = yOffset + 35
    CreateToggle(offTab, "Kick Power Override", "KickPowerOverride", yOffset); yOffset = yOffset + 35
    
    -- Kick power slider
    local sliderLabel = Instance.new("TextLabel")
    sliderLabel.Size = UDim2.new(0.9, 0, 0, 25)
    sliderLabel.Position = UDim2.new(0.05, 0, 0, yOffset)
    sliderLabel.Text = "Power Value: " .. Settings.KickPowerValue
    sliderLabel.BackgroundTransparency = 1
    sliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    sliderLabel.Parent = offTab
    yOffset = yOffset + 25
    
    local slider = Instance.new("TextBox")
    slider.Size = UDim2.new(0.9, 0, 0, 30)
    slider.Position = UDim2.new(0.05, 0, 0, yOffset)
    slider.PlaceholderText = "1-100"
    slider.Text = tostring(Settings.KickPowerValue)
    slider.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    slider.TextColor3 = Color3.fromRGB(255, 255, 255)
    slider.Parent = offTab
    
    slider.FocusLost:Connect(function()
        local val = tonumber(slider.Text)
        if val then
            Settings.KickPowerValue = math.clamp(val, 1, 100)
            slider.Text = tostring(Settings.KickPowerValue)
            sliderLabel.Text = "Power Value: " .. Settings.KickPowerValue
            SaveProfile()
        end
    end)
    yOffset = yOffset + 40
    
    CreateToggle(offTab, "Auto Dribble", "AutoDribble", yOffset); yOffset = yOffset + 35
    CreateToggle(offTab, "Ball Magnet", "BallMagnet", yOffset); yOffset = yOffset + 35
    CreateToggle(offTab, "Silent Aim Riptide", "SilentAimRiptide", yOffset); yOffset = yOffset + 35
    
    -- Movement Tab
    local movTab = Instance.new("ScrollingFrame")
    movTab.Size = UDim2.new(1, 0, 1, -50)
    movTab.Position = UDim2.new(0, 0, 0, 50)
    movTab.BackgroundTransparency = 1
    movTab.Visible = false
    movTab.Parent = mainFrame
    
    yOffset = 10
    CreateToggle(movTab, "Anti-Ankle Break", "AntiAnkleBreak", yOffset); yOffset = yOffset + 35
    CreateToggle(movTab, "Super Slide", "SuperSlide", yOffset); yOffset = yOffset + 35
    CreateToggle(movTab, "Speed Boost", "SpeedBoost", yOffset); yOffset = yOffset + 35
    
    local boostLabel = Instance.new("TextLabel")
    boostLabel.Size = UDim2.new(0.9, 0, 0, 25)
    boostLabel.Position = UDim2.new(0.05, 0, 0, yOffset)
    boostLabel.Text = "Boost Speed: " .. Settings.BoostValue
    boostLabel.BackgroundTransparency = 1
    boostLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    boostLabel.Parent = movTab
    yOffset = yOffset + 25
    
    local boostSlider = Instance.new("TextBox")
    boostSlider.Size = UDim2.new(0.9, 0, 0, 30)
    boostSlider.Position = UDim2.new(0.05, 0, 0, yOffset)
    boostSlider.PlaceholderText = "16-50"
    boostSlider.Text = tostring(Settings.BoostValue)
    boostSlider.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    boostSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
    boostSlider.Parent = movTab
    
    boostSlider.FocusLost:Connect(function()
        local val = tonumber(boostSlider.Text)
        if val then
            Settings.BoostValue = math.clamp(val, 16, 50)
            boostSlider.Text = tostring(Settings.BoostValue)
            boostLabel.Text = "Boost Speed: " .. Settings.BoostValue
            SaveProfile()
        end
    end)
    yOffset = yOffset + 40
    
    CreateToggle(movTab, "Flow Reroller", "FlowReroller", yOffset); yOffset = yOffset + 35
    
    -- Profiles Tab
    local profTab = Instance.new("ScrollingFrame")
    profTab.Size = UDim2.new(1, 0, 1, -50)
    profTab.Position = UDim2.new(0, 0, 0, 50)
    profTab.BackgroundTransparency = 1
    profTab.Visible = false
    profTab.Parent = mainFrame
    
    yOffset = 10
    for name, _ in pairs(Profiles) do
        local profileBtn = Instance.new("TextButton")
        profileBtn.Size = UDim2.new(0.9, 0, 0, 35)
        profileBtn.Position = UDim2.new(0.05, 0, 0, yOffset)
        profileBtn.Text = "📁 " .. name
        profileBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        profileBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        profileBtn.Parent = profTab
        
        profileBtn.MouseButton1Click:Connect(function()
            LoadProfile(name)
            -- Refresh all toggles
            for _, tab in pairs({uiTab, offTab, movTab}) do
                for _, btn in pairs(tab:GetChildren()) do
                    if btn:IsA("TextButton") then
                        btn.Text = btn.Text:gsub("✅|❌", "") .. (Settings[btn:GetAttribute("Setting")] and "✅ ON" or "❌ OFF")
                    end
                end
            end
        end)
        
        yOffset = yOffset + 40
    end
    
    -- Tab switching
    local function SetupTabs()
        local tabButtons = {}
        for i, tabName in pairs(tabs) do
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(0.25, 0, 0, 30)
            btn.Position = UDim2.new((i-1) * 0.25, 0, 0, 40)
            btn.Text = tabName
            btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Parent = mainFrame
            
            btn.MouseButton1Click:Connect(function()
                uiTab.Visible = (tabName == "UI")
                offTab.Visible = (tabName == "OFFENSIVE")
                movTab.Visible = (tabName == "MOVEMENT")
                profTab.Visible = (tabName == "PROFILES")
            end)
        end
    end
    
    SetupTabs()
end

-- Initialize all features
local function Initialize()
    print("[Football Hub] Initializing...")
    
    -- Load last profile
    if Settings.AutoLoad then
        LoadProfile("Tryhard")
    end
    
    -- Start all features
    AutoPickCFFeature()
    AutoFlowFeature()
    InfiniteStaminaFeature()
    MaxKickPowerFeature()
    KickPowerOverrideFeature()
    AutoDribbleFeature()
    BallMagnetFeature()
    SilentAimRiptideFeature()
    AntiAnkleBreakFeature()
    SuperSlideFeature()
    SpeedBoostFeature()
    FlowRerollerFeature()
    ServerHopExecFeature()
    
    -- Create GUI
    CreateGUI()
    
    print("[Football Hub] Loaded successfully!")
end

-- Start the script
Initialize()

-- Character respawn handler
Player.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid = Character:WaitForChild("Humanoid")
    task.wait(1)
    -- Reapply speed boost on respawn
    if Settings.SpeedBoost and Humanoid then
        Humanoid.WalkSpeed = Settings.BoostValue
    end
end)
