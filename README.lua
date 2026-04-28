--[[
    Advanced Soccer Automation System
    Features: Auto CF, Flow State, Stamina, Offensive & Movement Utilities
]]

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Player Variables
local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart")

-- Configuration System
local ConfigManager = {
    Profiles = {},
    CurrentProfile = "Default",
    AutoLoad = true,
    
    DefaultSettings = {
        -- Automation
        AutoPickCF = true,
        AutoFlow = true,
        InfiniteStamina = true,
        
        -- Offensive
        MaxKickPower = true,
        KickPowerOverride = 100, -- 0-100%
        AutoDribble = true,
        BallMagnet = true,
        SilentAimRiptide = true,
        
        -- Movement
        AntiAnkleBreak = true,
        SuperSlide = true,
        SpeedBoost = 5, -- Additional WalkSpeed
        FlowReroller = {
            Enabled = false,
            AutoMode = true,
            SelectedColor = "Rainbow",
            CustomColor = Color3.fromRGB(255, 0, 0)
        },
        
        -- System
        ServerHopExec = true
    }
}

-- State Variables
local Ball = nil
local FlowActive = false
local IsSliding = false
local OriginalWalkSpeed = 16
local ConnectionPool = {}

-- Utility Functions
local function safeFindChild(parent, name)
    local obj = parent:FindFirstChild(name)
    return obj ~= nil
end

local function getBall()
    local workspace = game:GetService("Workspace")
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("ball") or obj:GetAttribute("IsBall")) then
            return obj
        end
    end
    return nil
end

-- Configuration Manager
function ConfigManager.Save(name)
    ConfigManager.Profiles[name] = ConfigManager.DefaultSettings
    writefile("FootballProfiles.json", HttpService:JSONEncode(ConfigManager.Profiles))
end

function ConfigManager.Load(name)
    local success, data = pcall(function()
        return readfile("FootballProfiles.json")
    end)
    if success then
        ConfigManager.Profiles = HttpService:JSONDecode(data)
        if ConfigManager.Profiles[name] then
            ConfigManager.DefaultSettings = ConfigManager.Profiles[name]
            ConfigManager.CurrentProfile = name
        end
    end
end

function ConfigManager.AutoLoadProfile()
    if ConfigManager.AutoLoad and ConfigManager.Profiles[ConfigManager.CurrentProfile] then
        ConfigManager.DefaultSettings = ConfigManager.Profiles[ConfigManager.CurrentProfile]
    end
end

-- Automation Systems
local Automation = {}

function Automation.AutoPickCF()
    if not ConfigManager.DefaultSettings.AutoPickCF then return end
    
    spawn(function()
        while ConfigManager.DefaultSettings.AutoPickCF do
            wait(0.1)
            
            -- Try to claim center forward position
            pcall(function()
                local args = {
                    [1] = "CF", -- Center Forward
                    [2] = true
                }
                
                -- Attempt different remote names
                local remotes = {
                    "SetPosition",
                    "ClaimPosition",
                    "SelectRole",
                    "ChoosePosition"
                }
                
                for _, remoteName in ipairs(remotes) do
                    local remote = ReplicatedStorage:FindFirstChild(remoteName)
                    if remote then
                        remote:FireServer(unpack(args))
                        break
                    end
                end
            end)
        end
    end)
end

function Automation.AutoFlow()
    if not ConfigManager.DefaultSettings.AutoFlow then return end
    
    spawn(function()
        while ConfigManager.DefaultSettings.AutoFlow do
            wait(0.5)
            
            if not FlowActive then
                pcall(function()
                    local flowRemote = ReplicatedStorage:FindFirstChild("ActivateFlow")
                    if flowRemote then
                        flowRemote:FireServer()
                        FlowActive = true
                    end
                end)
            end
        end
    end)
end

function Automation.InfiniteStamina()
    if not ConfigManager.DefaultSettings.InfiniteStamina then return end
    
    spawn(function()
        while ConfigManager.DefaultSettings.InfiniteStamina do
            wait(0.1)
            
            pcall(function()
                if Humanoid then
                    Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, true)
                    -- Keep stamina/energy full
                    if Character:FindFirstChild("Stamina") then
                        Character.Stamina.Value = 100
                    end
                    if Character:FindFirstChild("Energy") then
                        Character.Energy.Value = 100
                    end
                end
            end)
        end
    end)
end

-- Offensive Systems
local Offensive = {}

function Offensive.MaxKickPower()
    if not ConfigManager.DefaultSettings.MaxKickPower then return end
    
    -- Hook into kick remote
    pcall(function()
        local kickRemote = ReplicatedStorage:FindFirstChild("KickBall")
        if kickRemote then
            local oldNamecall
            oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
                local args = {...}
                local method = getnamecallmethod()
                
                if method == "FireServer" and self == kickRemote then
                    -- Override kick power
                    args[1] = ConfigManager.DefaultSettings.KickPowerOverride / 100
                end
                
                return oldNamecall(self, unpack(args))
            end)
        end
    end)
end

function Offensive.AutoDribble()
    if not ConfigManager.DefaultSettings.AutoDribble then return end
    
    spawn(function()
        while ConfigManager.DefaultSettings.AutoDribble do
            wait(0.05)
            
            Ball = getBall()
            if Ball and (Ball.Position - RootPart.Position).Magnitude < 10 then
                -- Auto dribble logic
                pcall(function()
                    local dribbleRemote = ReplicatedStorage:FindFirstChild("Dribble")
                    if dribbleRemote then
                        dribbleRemote:FireServer(Ball)
                    end
                end)
            end
        end
    end)
end

function Offensive.BallMagnet()
    if not ConfigManager.DefaultSettings.BallMagnet then return end
    
    spawn(function()
        while ConfigManager.DefaultSettings.BallMagnet do
            wait(0.01)
            
            Ball = getBall()
            if Ball and RootPart then
                local distance = (Ball.Position - RootPart.Position).Magnitude
                if distance < 15 and distance > 2 then
                    -- Pull ball towards player
                    local direction = (RootPart.Position - Ball.Position).unit
                    Ball.Velocity = direction * (distance * 5)
                end
            end
        end
    end)
end

function Offensive.SilentAimRiptide()
    if not ConfigManager.DefaultSettings.SilentAimRiptide then return end
    
    spawn(function()
        while ConfigManager.DefaultSettings.SilentAimRiptide do
            wait(0.01)
            
            -- Curve shot with 100% accuracy
            Ball = getBall()
            if Ball and RootPart then
                pcall(function()
                    -- Find goal
                    local goal = workspace:FindFirstChild("Goal", true)
                    if goal then
                        -- Calculate curve trajectory
                        local target = goal.Position
                        local current = Ball.Position
                        local curve = Vector3.new(0, 5, 0) -- Upward curve
                        
                        -- Apply riptide effect
                        local riptideRemote = ReplicatedStorage:FindFirstChild("RiptideShot")
                        if riptideRemote then
                            riptideRemote:FireServer(target, curve)
                        end
                    end
                end)
            end
        end
    end)
end

-- Movement Systems
local Movement = {}

function Movement.AntiAnkleBreak()
    if not ConfigManager.DefaultSettings.AntiAnkleBreak then return end
    
    spawn(function()
        while ConfigManager.DefaultSettings.AntiAnkleBreak do
            wait(0.01)
            
            pcall(function()
                -- Prevent character ragdoll
                if Humanoid then
                    Humanoid.PlatformStand = false
                    Humanoid.AutoRotate = true
                end
                
                -- Remove any "ankle break" animations or effects
                if Character:FindFirstChild("AnkleBreak") then
                    Character.AnkleBreak:Destroy()
                end
            end)
        end
    end)
end

function Movement.SuperSlide()
    if not ConfigManager.DefaultSettings.SuperSlide then return end
    
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.C then -- C to slide
            IsSliding = true
            
            spawn(function()
                while IsSliding do
                    wait(0.01)
                    pcall(function()
                        if RootPart then
                            local direction = RootPart.CFrame.LookVector
                            RootPart.Velocity = direction * 100 -- Infinite slide
                        end
                    end)
                end
            end)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.C then
            IsSliding = false
        end
    end)
end

function Movement.SpeedBoost()
    if not ConfigManager.DefaultSettings.SpeedBoost > 0 then return end
    
    spawn(function()
        while true do
            wait(0.1)
            
            pcall(function()
                if Humanoid then
                    Humanoid.WalkSpeed = OriginalWalkSpeed + ConfigManager.DefaultSettings.SpeedBoost
                end
            end)
        end
    end)
end

function Movement.FlowReroller()
    local config = ConfigManager.DefaultSettings.FlowReroller
    if not config.Enabled then return end
    
    spawn(function()
        local colors = {"Red", "Blue", "Green", "Purple", "Gold", "Rainbow"}
        local colorIndex = 1
        
        while config.Enabled do
            wait(0.5)
            
            if config.AutoMode then
                pcall(function()
                    local flowRemote = ReplicatedStorage:FindFirstChild("SetFlowColor")
                    if flowRemote then
                        if config.SelectedColor == "Rainbow" then
                            flowRemote:FireServer(colors[colorIndex])
                            colorIndex = (colorIndex % #colors) + 1
                        else
                            flowRemote:FireServer(config.SelectedColor)
                        end
                    end
                end)
            end
        end
    end)
end

-- Server Hop System
local System = {}

function System.ServerHopExec()
    if not ConfigManager.DefaultSettings.ServerHopExec then return end
    
    -- Detect teleport/server hop
    LocalPlayer.OnTeleport:Connect(function(State)
        if State == Enum.TeleportState.InProgress then
            -- Save current settings
            ConfigManager.Save("LastSession")
        end
    end)
    
    -- Re-run script after server hop
    LocalPlayer.CharacterAdded:Connect(function(char)
        Character = char
        Humanoid = char:WaitForChild("Humanoid")
        RootPart = char:WaitForChild("HumanoidRootPart")
        
        -- Re-load settings
        ConfigManager.AutoLoadProfile()
        
        -- Restart all features
        StartAllFeatures()
    end)
end

-- GUI Setup
local function CreateGUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "FootballHub"
    ScreenGui.Parent = game:GetService("CoreGui")
    
    local MainFrame = Instance.new("Frame")
    MainFrame.Size = UDim2.new(0, 300, 0, 500)
    MainFrame.Position = UDim2.new(0.5, -150, 0.5, -250)
    MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    Title.Text = "Football Automation Hub"
    Title.TextColor3 = Color3.fromRGB(255, 255, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.Parent = MainFrame
    
    local ScrollFrame = Instance.new("ScrollingFrame")
    ScrollFrame.Size = UDim2.new(1, 0, 1, -40)
    ScrollFrame.Position = UDim2.new(0, 0, 0, 40)
    ScrollFrame.BackgroundTransparency = 1
    ScrollFrame.Parent = MainFrame
    
    local function CreateToggle(text, yPos, callback)
        local ToggleButton = Instance.new("TextButton")
        ToggleButton.Size = UDim2.new(1, -20, 0, 30)
        ToggleButton.Position = UDim2.new(0, 10, 0, yPos)
        ToggleButton.Text = text .. ": ON"
        ToggleButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        ToggleButton.Parent = ScrollFrame
        
        local toggled = true
        ToggleButton.MouseButton1Click:Connect(function()
            toggled = not toggled
            ToggleButton.Text = text .. (toggled and ": ON" or ": OFF")
            ToggleButton.BackgroundColor3 = toggled and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
            callback(toggled)
        end)
    end
    
    -- Create all toggles
    local yOffset = 10
    CreateToggle("Auto Pick CF", yOffset, function(val) ConfigManager.DefaultSettings.AutoPickCF = val end)
    yOffset = yOffset + 35
    CreateToggle("Auto Flow", yOffset, function(val) ConfigManager.DefaultSettings.AutoFlow = val end)
    yOffset = yOffset + 35
    CreateToggle("Infinite Stamina", yOffset, function(val) ConfigManager.DefaultSettings.InfiniteStamina = val end)
    yOffset = yOffset + 35
    CreateToggle("Max Kick Power", yOffset, function(val) ConfigManager.DefaultSettings.MaxKickPower = val end)
    yOffset = yOffset + 35
    CreateToggle("Auto Dribble", yOffset, function(val) ConfigManager.DefaultSettings.AutoDribble = val end)
    yOffset = yOffset + 35
    CreateToggle("Ball Magnet", yOffset, function(val) ConfigManager.DefaultSettings.BallMagnet = val end)
    yOffset = yOffset + 35
    CreateToggle("Silent Aim Riptide", yOffset, function(val) ConfigManager.DefaultSettings.SilentAimRiptide = val end)
    yOffset = yOffset + 35
    CreateToggle("Anti-Ankle Break", yOffset, function(val) ConfigManager.DefaultSettings.AntiAnkleBreak = val end)
    yOffset = yOffset + 35
    CreateToggle("Super Slide", yOffset, function(val) ConfigManager.DefaultSettings.SuperSlide = val end)
    
    -- Speed Boost Slider
    local SpeedLabel = Instance.new("TextLabel")
    SpeedLabel.Size = UDim2.new(1, -20, 0, 20)
    SpeedLabel.Position = UDim2.new(0, 10, 0, yOffset + 35)
    SpeedLabel.Text = "Speed Boost: " .. ConfigManager.DefaultSettings.SpeedBoost
    SpeedLabel.BackgroundTransparency = 1
    SpeedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    SpeedLabel.Parent = ScrollFrame
    
    local SpeedSlider = Instance.new("TextBox")
    SpeedSlider.Size = UDim2.new(0.5, 0, 0, 25)
    SpeedSlider.Position = UDim2.new(0, 10, 0, yOffset + 60)
    SpeedSlider.Text = tostring(ConfigManager.DefaultSettings.SpeedBoost)
    SpeedSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    SpeedSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
    SpeedSlider.Parent = ScrollFrame
    SpeedSlider.FocusLost:Connect(function()
        local value = tonumber(SpeedSlider.Text)
        if value then
            ConfigManager.DefaultSettings.SpeedBoost = math.clamp(value, 0, 50)
            SpeedLabel.Text = "Speed Boost: " .. ConfigManager.DefaultSettings.SpeedBoost
        end
    end)
end

-- Main Initialization
function StartAllFeatures()
    Automation.AutoPickCF()
    Automation.AutoFlow()
    Automation.InfiniteStamina()
    Offensive.MaxKickPower()
    Offensive.AutoDribble()
    Offensive.BallMagnet()
    Offensive.SilentAimRiptide()
    Movement.AntiAnkleBreak()
    Movement.SuperSlide()
    Movement.SpeedBoost()
    Movement.FlowReroller()
    System.ServerHopExec()
end

-- Start the system
CreateGUI()
ConfigManager.AutoLoadProfile()
StartAllFeatures()

-- Cleanup on script end
game:GetService("RunService").Heartbeat:Connect(function()
    if not LocalPlayer or not LocalPlayer.Parent then
        -- Player left, save settings
        ConfigManager.Save("LastSession")
    end
end)

print("Football Automation System Loaded Successfully!")
print("Press 'C' for Super Slide")
print("All features are now active")
