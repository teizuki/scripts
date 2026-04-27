--[[
    Script Desofuscado
    Interface Gráfica (GUI) com múltiplas abas para um executor Roblox.
--]]

local Player = game:GetService("Players").LocalPlayer
local Mouse = Player:GetMouse()
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

-- Variáveis Globais e Estados
local screenGui = Instance.new("ScreenGui")
local mainFrame = Instance.new("Frame")
local tabHolder = Instance.new("Frame")
local topBar = Instance.new("Frame")
local titleLabel = Instance.new("TextLabel")
local closeButton = Instance.new("TextButton")
local minimizeButton = Instance.new("TextButton")
local dragButton = Instance.new("TextButton")
local tabsFrame = Instance.new("Frame")
local contentFrame = Instance.new("Frame")

local dragging = false
local dragInput
local dragStart
local startPos

-- Estados das funções (toggles)
local noclipEnabled = false
local flyEnabled = false
local speedEnabled = false
local espEnabled = false
local highlightEnabled = false
local infiniteJump = false
local fovChangerEnabled = false
local cFrameSaver = false
local savedCFrame = nil

-- Valores padrão
local walkSpeedValue = 16
local jumpPowerValue = 50
local flySpeed = 1
local hitboxMultiplier = 1
local fovValue = 70
local customFov = 70
local fovTween = nil

-- Listas e Caches
local espList = {}
local highlightList = {}
local loopBringList = {}
local savedPositions = {}
local waypoints = {}

-- Função para criar GUI (Janela Principal)
local function CreateMainGUI()
    screenGui.Name = "KrnlHub"
    screenGui.Parent = CoreGui
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.ResetOnSpawn = false

    mainFrame.Name = "Main"
    mainFrame.Parent = screenGui
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    mainFrame.BorderColor3 = Color3.fromRGB(20, 20, 25)
    mainFrame.BorderSizePixel = 1
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    mainFrame.Size = UDim2.new(0, 600, 0, 400)
    mainFrame.Active = true
    mainFrame.Draggable = false
    mainFrame.ClipsDescendants = false

    -- Top Bar (para arrastar)
    topBar.Name = "TopBar"
    topBar.Parent = mainFrame
    topBar.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    topBar.BorderSizePixel = 0
    topBar.Size = UDim2.new(1, 0, 0, 30)

    titleLabel.Name = "Title"
    titleLabel.Parent = topBar
    titleLabel.BackgroundTransparency = 1
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.Size = UDim2.new(0, 200, 1, 0)
    titleLabel.Font = Enum.Font.GothamSemibold
    titleLabel.Text = "Krnl Hub V1.0"
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left

    closeButton.Name = "Close"
    closeButton.Parent = topBar
    closeButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
    closeButton.Position = UDim2.new(1, -25, 0, 5)
    closeButton.Size = UDim2.new(0, 20, 0, 20)
    closeButton.Font = Enum.Font.GothamBold
    closeButton.Text = "X"
    closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeButton.TextSize = 14
    closeButton.BorderSizePixel = 0

    minimizeButton.Name = "Minimize"
    minimizeButton.Parent = topBar
    minimizeButton.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    minimizeButton.Position = UDim2.new(1, -50, 0, 5)
    minimizeButton.Size = UDim2.new(0, 20, 0, 20)
    minimizeButton.Font = Enum.Font.GothamBold
    minimizeButton.Text = "-"
    minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    minimizeButton.TextSize = 20
    minimizeButton.BorderSizePixel = 0

    dragButton.Name = "Drag"
    dragButton.Parent = topBar
    dragButton.BackgroundTransparency = 1
    dragButton.Size = UDim2.new(1, -75, 1, 0)
    dragButton.Text = ""

    -- Ações dos botões
    closeButton.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    minimizeButton.MouseButton1Click:Connect(function()
        mainFrame.Visible = not mainFrame.Visible
    end)

    -- Lógica para arrastar a janela
    dragButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    dragButton.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    -- Tabs (Aba principal)
    tabHolder.Name = "TabHolder"
    tabHolder.Parent = mainFrame
    tabHolder.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    tabHolder.BorderSizePixel = 0
    tabHolder.Position = UDim2.new(0, 0, 0, 30)
    tabHolder.Size = UDim2.new(0, 150, 1, -30)

    contentFrame.Name = "Content"
    contentFrame.Parent = mainFrame
    contentFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    contentFrame.BorderSizePixel = 0
    contentFrame.Position = UDim2.new(0, 150, 0, 30)
    contentFrame.Size = UDim2.new(1, -150, 1, -30)

    return screenGui, mainFrame, tabHolder, contentFrame
end

-- Função para criar botões e abas dinamicamente
local function CreateTab(name, parent)
    local tabButton = Instance.new("TextButton")
    tabButton.Name = name.."Tab"
    tabButton.Parent = parent
    tabButton.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
    tabButton.BorderSizePixel = 0
    tabButton.Size = UDim2.new(1, 0, 0, 35)
    tabButton.Font = Enum.Font.GothamSemibold
    tabButton.Text = name
    tabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
    tabButton.TextSize = 14

    local tabContent = Instance.new("ScrollingFrame")
    tabContent.Name = name.."Content"
    tabContent.Parent = contentFrame
    tabContent.BackgroundTransparency = 1
    tabContent.BorderSizePixel = 0
    tabContent.Size = UDim2.new(1, 0, 1, 0)
    tabContent.ScrollBarThickness = 6
    tabContent.Visible = false
    tabContent.CanvasSize = UDim2.new(0, 0, 0, 0)

    local uiList = Instance.new("UIListLayout")
    uiList.Parent = tabContent
    uiList.SortOrder = Enum.SortOrder.LayoutOrder
    uiList.Padding = UDim.new(0, 5)

    tabButton.MouseButton1Click:Connect(function()
        for _, child in pairs(contentFrame:GetChildren()) do
            if child:IsA("ScrollingFrame") then
                child.Visible = false
            end
        end
        for _, child in pairs(parent:GetChildren()) do
            if child:IsA("TextButton") then
                child.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
                child.TextColor3 = Color3.fromRGB(200, 200, 200)
            end
        end
        tabButton.BackgroundColor3 = Color3.fromRGB(60, 60, 65)
        tabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
        tabContent.Visible = true
    end)

    return tabContent
end

local function CreateButton(parent, text, callback, order)
    local button = Instance.new("TextButton")
    button.Parent = parent
    button.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
    button.BorderSizePixel = 0
    button.Size = UDim2.new(1, -10, 0, 30)
    button.Position = UDim2.new(0, 5, 0, 0)
    button.Font = Enum.Font.Gotham
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 13
    button.LayoutOrder = order

    button.MouseButton1Click:Connect(callback)
    return button
end

local function CreateToggle(parent, text, callback, order, initialState)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, -10, 0, 30)
    frame.LayoutOrder = order

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(0.7, 0, 1, 0)
    label.Font = Enum.Font.Gotham
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left

    local toggleButton = Instance.new("TextButton")
    toggleButton.Parent = frame
    toggleButton.Position = UDim2.new(0.7, 0, 0.5, -12)
    toggleButton.Size = UDim2.new(0, 50, 0, 24)
    toggleButton.BackgroundColor3 = initialState and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(150, 50, 50)
    toggleButton.BorderSizePixel = 0
    toggleButton.Font = Enum.Font.GothamBold
    toggleButton.Text = initialState and "ON" or "OFF"
    toggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    toggleButton.TextSize = 12

    local state = initialState

    toggleButton.MouseButton1Click:Connect(function()
        state = not state
        toggleButton.BackgroundColor3 = state and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(150, 50, 50)
        toggleButton.Text = state and "ON" or "OFF"
        callback(state)
    end)

    return frame, function() return state end
end

local function CreateSlider(parent, text, min, max, default, callback, order)
    local frame = Instance.new("Frame")
    frame.Parent = parent
    frame.BackgroundTransparency = 1
    frame.Size = UDim2.new(1, -10, 0, 50)
    frame.LayoutOrder = order

    local label = Instance.new("TextLabel")
    label.Parent = frame
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, 0, 0, 20)
    label.Font = Enum.Font.Gotham
    label.Text = text .. ": " .. tostring(default)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left

    local slider = Instance.new("Frame")
    slider.Parent = frame
    slider.Position = UDim2.new(0, 0, 0, 25)
    slider.Size = UDim2.new(1, 0, 0, 4)
    slider.BackgroundColor3 = Color3.fromRGB(70, 70, 75)

    local fill = Instance.new("Frame")
    fill.Parent = slider
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    fill.BorderSizePixel = 0

    local drag = Instance.new("TextButton")
    drag.Parent = slider
    drag.Position = UDim2.new((default - min) / (max - min), -10, 0.5, -10)
    drag.Size = UDim2.new(0, 20, 0, 20)
    drag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    drag.Text = ""
    drag.BorderSizePixel = 0

    local value = default

    local function update(val)
        val = math.clamp(val, min, max)
        value = val
        fill.Size = UDim2.new((val - min) / (max - min), 0, 1, 0)
        drag.Position = UDim2.new((val - min) / (max - min), -10, 0.5, -10)
        label.Text = text .. ": " .. string.format("%.1f", val)
        callback(val)
    end

    drag.MouseButton1Down:Connect(function()
        local mouse = Player:GetMouse()
        local connection
        connection = mouse.Move:Connect(function()
            local x = math.clamp((mouse.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            update(min + (max - min) * x)
        end)
        mouse.Button1Up:Connect(function()
            connection:Disconnect()
        end)
    end)

    update(value)
    return frame
end

-- Funções principais (Noclip, Fly, ESP, etc.)
local function SetupNoclip(state)
    noclipEnabled = state
    if state then
        local runServiceConnection
        runServiceConnection = RunService.Stepped:Connect(function()
            if noclipEnabled and Player.Character and Player.Character:FindFirstChild("Humanoid") then
                for _, part in ipairs(Player.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.CanCollide then
                        part.CanCollide = false
                    end
                end
            end
        end)
        return runServiceConnection
    end
end

local function SetupFly(state)
    flyEnabled = state
    if state then
        local bodyVelocity = Instance.new("BodyVelocity")
        local bodyGyro = Instance.new("BodyGyro")
        local humanoid = Player.Character and Player.Character:FindFirstChild("Humanoid")
        local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        
        if not humanoid or not rootPart then return end
        
        bodyVelocity.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
        bodyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
        bodyGyro.CFrame = rootPart.CFrame
        bodyGyro.Parent = rootPart
        bodyVelocity.Parent = rootPart
        
        humanoid.PlatformStand = true
        
        local connection
        connection = RunService.RenderStepped:Connect(function()
            if not flyEnabled or not Player.Character or not rootPart then
                if connection then connection:Disconnect() end
                if bodyVelocity then bodyVelocity:Destroy() end
                if bodyGyro then bodyGyro:Destroy() end
                if humanoid then humanoid.PlatformStand = false end
                return
            end
            
            local camera = workspace.CurrentCamera
            local forward = camera.CFrame.LookVector
            local right = camera.CFrame.RightVector
            local up = camera.CFrame.UpVector
            
            local moveDirection = Vector3.new(0, 0, 0)
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - forward end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + right end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - right end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + up end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then moveDirection = moveDirection - up end
            
            bodyVelocity.Velocity = moveDirection * flySpeed
            bodyGyro.CFrame = camera.CFrame
        end)
    else
        -- Cleanup fly
        local rootPart = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
        local humanoid = Player.Character and Player.Character:FindFirstChild("Humanoid")
        if rootPart then
            local bv = rootPart:FindFirstChildWhichIsA("BodyVelocity")
            local bg = rootPart:FindFirstChildWhichIsA("BodyGyro")
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end
        if humanoid then humanoid.PlatformStand = false end
    end
end

local function SetupSpeed(state, value)
    speedEnabled = state
    walkSpeedValue = value
    if state and Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.WalkSpeed = walkSpeedValue
    elseif not state and Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.WalkSpeed = 16
    end
end

local function SetupJumpPower(state, value)
    jumpPowerValue = value
    if state and Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.JumpPower = jumpPowerValue
    elseif not state and Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.JumpPower = 50
    end
end

local function InfiniteJump(state)
    infiniteJump = state
    local connection
    if state then
        connection = UserInputService.JumpRequest:Connect(function()
            if infiniteJump and Player.Character and Player.Character:FindFirstChild("Humanoid") then
                Player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
        end)
        return connection
    end
end

local function TeleportToPlayer(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame = targetPlayer.Character.HumanoidRootPart.CFrame
    end
end

local function BringPlayer(targetPlayer)
    if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        targetPlayer.Character.HumanoidRootPart.CFrame = Player.Character.HumanoidRootPart.CFrame
    end
end

local function SetupESP(state)
    espEnabled = state
    if state then
        local function createESP(player)
            if player == Player then return end
            local highlight = Instance.new("Highlight")
            highlight.Name = "ESP_Highlight"
            highlight.FillTransparency = 0.8
            highlight.OutlineTransparency = 0.3
            highlight.Adornee = player.Character
            highlight.Parent = player.Character
            highlightList[player] = highlight
        end
        
        local function removeESP(player)
            if highlightList[player] then
                highlightList[player]:Destroy()
                highlightList[player] = nil
            end
        end
        
        for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
            createESP(player)
        end
        
        game:GetService("Players").PlayerAdded:Connect(createESP)
        game:GetService("Players").PlayerRemoving:Connect(removeESP)
    else
        for _, highlight in pairs(highlightList) do
            if highlight then highlight:Destroy() end
        end
        highlightList = {}
    end
end

local function ServerHop()
    local servers = {}
    for _, v in ipairs(game:GetService("HttpService"):JSONDecode(game:HttpGetAsync("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?limit=100")).data) do
        if v.playing < v.maxPlayers and v.id ~= game.JobId then
            table.insert(servers, v.id)
        end
    end
    if #servers > 0 then
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, servers[math.random(1, #servers)], Player)
    end
end

local function Rejoin()
    game:GetService("TeleportService"):Teleport(game.PlaceId, Player)
end

-- Configuração da GUI e criação dos elementos
CreateMainGUI()
local mainTabs = tabHolder
local mainContent = contentFrame

-- Criando as Abas
local mainTab = CreateTab("Main", mainTabs)
local playersTab = CreateTab("Players", mainTabs)
local visualsTab = CreateTab("Visuals", mainTabs)
local worldTab = CreateTab("World", mainTabs)
local settingsTab = CreateTab("Settings", mainTabs)

-- Preenchendo a Aba Main
CreateButton(mainTab, "Infinite Yield (FE)", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))()
end, 1)

CreateButton(mainTab, "Cmd-X", function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/CMD-X/CMD-X/master/Source", true))()
end, 2)

CreateButton(mainTab, "Save CFrame", function()
    if Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        savedCFrame = Player.Character.HumanoidRootPart.CFrame
        print("CFrame salvo!")
    end
end, 3)

CreateButton(mainTab, "Load CFrame", function()
    if savedCFrame and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.CFrame = savedCFrame
        print("CFrame carregado!")
    end
end, 4)

CreateButton(mainTab, "Server Hop", ServerHop, 5)
CreateButton(mainTab, "Rejoin", Rejoin, 6)

-- Preenchendo a Aba Players
local playerList = Instance.new("ScrollingFrame")
playerList.Parent = playersTab
playerList.Size = UDim2.new(1, 0, 0.6, 0)
playerList.BackgroundTransparency = 1
playerList.BorderSizePixel = 0
playerList.CanvasSize = UDim2.new(0, 0, 0, 0)

local playerListLayout = Instance.new("UIListLayout")
playerListLayout.Parent = playerList
playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local function RefreshPlayerList()
    for _, child in ipairs(playerList:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    local y = 0
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= Player then
            local button = Instance.new("TextButton")
            button.Parent = playerList
            button.Size = UDim2.new(1, -10, 0, 30)
            button.Position = UDim2.new(0, 5, 0, y)
            button.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
            button.Text = player.Name
            button.Font = Enum.Font.Gotham
            button.TextColor3 = Color3.fromRGB(255, 255, 255)
            button.TextSize = 13
            button.BorderSizePixel = 0
            y = y + 35
            
            local menu = Instance.new("Frame")
            menu.Parent = button
            menu.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
            menu.BorderSizePixel = 0
            menu.Position = UDim2.new(1, 0, 0, 0)
            menu.Size = UDim2.new(0, 100, 0, 90)
            menu.Visible = false
            menu.ZIndex = 2
            
            local tpButton = Instance.new("TextButton")
            tpButton.Parent = menu
            tpButton.Size = UDim2.new(1, 0, 0, 30)
            tpButton.Text = "Teleport"
            tpButton.Font = Enum.Font.Gotham
            tpButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            tpButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            tpButton.BorderSizePixel = 0
            tpButton.MouseButton1Click:Connect(function()
                TeleportToPlayer(player)
                menu.Visible = false
            end)
            
            local bringButton = Instance.new("TextButton")
            bringButton.Parent = menu
            bringButton.Position = UDim2.new(0, 0, 0, 30)
            bringButton.Size = UDim2.new(1, 0, 0, 30)
            bringButton.Text = "Bring"
            bringButton.Font = Enum.Font.Gotham
            bringButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            bringButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            bringButton.BorderSizePixel = 0
            bringButton.MouseButton1Click:Connect(function()
                BringPlayer(player)
                menu.Visible = false
            end)
            
            local loopBringButton = Instance.new("TextButton")
            loopBringButton.Parent = menu
            loopBringButton.Position = UDim2.new(0, 0, 0, 60)
            loopBringButton.Size = UDim2.new(1, 0, 0, 30)
            loopBringButton.Text = "Loop Bring"
            loopBringButton.Font = Enum.Font.Gotham
            loopBringButton.TextColor3 = Color3.fromRGB(255, 255, 255)
            loopBringButton.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
            loopBringButton.BorderSizePixel = 0
            loopBringButton.MouseButton1Click:Connect(function()
                if loopBringList[player] then
                    loopBringList[player] = false
                    loopBringButton.Text = "Loop Bring"
                else
                    loopBringList[player] = true
                    loopBringButton.Text = "Stop Loop"
                    coroutine.wrap(function()
                        while loopBringList[player] and player and player.Character do
                            BringPlayer(player)
                            wait(0.5)
                        end
                    end)()
                end
                menu.Visible = false
            end)
            
            button.MouseButton1Click:Connect(function()
                menu.Visible = not menu.Visible
            end)
        end
    end
    playerList.CanvasSize = UDim2.new(0, 0, 0, y)
end

CreateButton(playersTab, "Refresh Players", RefreshPlayerList, 1)

-- Preenchendo a Aba Visuals
CreateToggle(visualsTab, "Highlight Players", function(state)
    SetupESP(state)
end, 1, false)

CreateToggle(visualsTab, "Noclip", function(state)
    SetupNoclip(state)
end, 2, false)

CreateToggle(visualsTab, "Fly", function(state)
    SetupFly(state)
end, 3, false)

CreateSlider(visualsTab, "Fly Speed", 1, 100, 10, function(value)
    flySpeed = value
end, 4)

CreateToggle(visualsTab, "Speed", function(state)
    SetupSpeed(state, walkSpeedValue)
end, 5, false)

CreateSlider(visualsTab, "Walk Speed", 16, 500, 100, function(value)
    walkSpeedValue = value
    if speedEnabled and Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.WalkSpeed = walkSpeedValue
    end
end, 6)

CreateToggle(visualsTab, "Jump Power", function(state)
    SetupJumpPower(state, jumpPowerValue)
end, 7, false)

CreateSlider(visualsTab, "Jump Power Value", 50, 500, 200, function(value)
    jumpPowerValue = value
    if infiniteJump and Player.Character and Player.Character:FindFirstChild("Humanoid") then
        Player.Character.Humanoid.JumpPower = jumpPowerValue
    end
end, 8)

CreateToggle(visualsTab, "Infinite Jump", function(state)
    InfiniteJump(state)
end, 9, false)

CreateToggle(visualsTab, "Hitbox Extender", function(state)
    hitboxMultiplier = state and 5 or 1
    if Player.Character then
        for _, part in ipairs(Player.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.Size = part.Size * hitboxMultiplier
            end
        end
    end
end, 10, false)

CreateSlider(visualsTab, "Hitbox Size", 1, 10, 1, function(value)
    hitboxMultiplier = value
    if Player.Character then
        for _, part in ipairs(Player.Character:GetChildren()) do
            if part:IsA("BasePart") then
                part.Size = part.Size * hitboxMultiplier
            end
        end
    end
end, 11)

-- Preenchendo a Aba World
CreateButton(worldTab, "Kick All", function()
    for _, player in ipairs(game:GetService("Players"):GetPlayers()) do
        if player ~= Player then
            player:Kick("You were kicked by an admin.")
        end
    end
end, 1)

CreateButton(worldTab, "Clear Tools", function()
    if Player.Backpack then
        for _, tool in ipairs(Player.Backpack:GetChildren()) do
            tool:Destroy()
        end
    end
    if Player.Character then
        for _, tool in ipairs(Player.Character:GetChildren()) do
            if tool:IsA("Tool") then
                tool:Destroy()
            end
        end
    end
end, 2)

CreateButton(worldTab, "Loop Delete Parts", function()
    coroutine.wrap(function()
        while true do
            for _, v in ipairs(workspace:GetDescendants()) do
                if v:IsA("BasePart") and v.Name ~= "Baseplate" and not v:IsDescendantOf(Player.Character) then
                    v:Destroy()
                end
            end
            wait(1)
        end
    end)()
end, 3)

-- Preenchendo a Aba Settings
CreateButton(settingsTab, "Destroy GUI", function()
    screenGui:Destroy()
end, 1)

CreateSlider(settingsTab, "FOV Changer", 70, 120, 70, function(value)
    customFov = value
    if game:GetService("Players").LocalPlayer.CameraMinZoomDistance then
        fovChangerEnabled = true
        local camera = workspace.CurrentCamera
        if fovTween then fovTween:Cancel() end
        fovTween = TweenService:Create(camera, TweenInfo.new(0.5), {FieldOfView = customFov})
        fovTween:Play()
    end
end, 2)

-- Inicialização
RefreshPlayerList()
game:GetService("Players").PlayerAdded:Connect(RefreshPlayerList)
game:GetService("Players").PlayerRemoving:Connect(RefreshPlayerList)
