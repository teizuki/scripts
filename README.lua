-- ============================================
-- LOCKED 2 - Football Hub (Xeno Compatível)
-- ============================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualUser = game:GetService("VirtualUser")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- ========== CONFIGURAÇÕES ==========
local Settings = {
    AutoPickCF = false,
    AutoFlow = false,
    InfiniteStamina = false,
    MaxKickPower = false,
    KickPowerOverride = false,
    KickPowerValue = 100,
    AutoDribble = false,
    AntiAnkleBreak = false,
    SuperSlide = false,
    SpeedBoost = false,
    BoostValue = 24,
    FlowReroller = false,
}

-- ========== FUNÇÕES PRINCIPAIS ==========

-- 1. AUTO PICK CF (Clica na posição desejada)
local function AutoPickCFFeature()
    spawn(function()
        while Settings.AutoPickCF and task.wait(0.5) do
            -- Procura a GUI de seleção de posição
            local playerGui = LocalPlayer:WaitForChild("PlayerGui")
            
            -- Tenta encontrar botões de posição (nomes comuns)
            local possibleNames = {"CF", "CenterForward", "PositionCF", "Striker", "Atacante"}
            
            for _, name in pairs(possibleNames) do
                local button = playerGui:FindFirstChild(name, true)
                if button and button:IsA("TextButton") then
                    button:Fire()
                    print("[✓] Auto Pick CF - Posição selecionada")
                    break
                end
            end
            
            -- Alternativa: Simula clique na posição da tela (ajuste as coordenadas)
            -- VirtualInputManager:SendMouseButtonEvent(500, 300, 0, true, game, 0)
            -- task.wait(0.05)
            -- VirtualInputManager:SendMouseButtonEvent(500, 300, 0, false, game, 0)
        end
    end)
end

-- 2. AUTO FLOW (Ativa Flow apertando G automaticamente)
local function AutoFlowFeature()
    spawn(function()
        while Settings.AutoFlow and task.wait(5) do -- A cada 5 segundos tenta ativar
            -- Simula apertar a tecla G
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.G, false, game)
            task.wait(0.05)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.G, false, game)
            print("[✓] Auto Flow - Flow ativado")
        end
    end)
end

-- 3. INFINITE STAMINA (Barra amarela infinita)
local function InfiniteStaminaFeature()
    spawn(function()
        while Settings.InfiniteStamina and task.wait(0.1) do
            -- Método 1: Achar barra de stamina e congelar
            local staminaBar = LocalPlayer.PlayerGui:FindFirstChild("StaminaBar", true)
            if staminaBar and staminaBar:FindFirstChild("Value") then
                staminaBar.Value.Value = 100
            end
            
            -- Método 2: Achar variável de stamina
            local staminaValue = LocalPlayer:FindFirstChild("Stamina")
            if staminaValue then
                staminaValue.Value = 100
            end
            
            -- Método 3: Achar leaderstats
            local leaderstats = LocalPlayer:FindFirstChild("leaderstats")
            if leaderstats then
                local stamina = leaderstats:FindFirstChild("Stamina")
                if stamina then stamina.Value = 100 end
                local energy = leaderstats:FindFirstChild("Energy")
                if energy then energy.Value = 100 end
            end
            
            -- Método 4: Impedir que a stamina diminua (hook no evento)
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    -- Remove o debuff de stamina baixa
                    local staminaDebuff = character:FindFirstChild("StaminaDebuff")
                    if staminaDebuff then staminaDebuff:Destroy() end
                end
            end
        end
    end)
end

-- 4. RECARGA RÁPIDA (Apertar V instantâneo sem ficar parado)
local function FastReloadFeature()
    local function QuickReload()
        if LocalPlayer.Character then
            -- Simula apertar V sem travar o personagem
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.V, false, game)
            task.wait(0.01)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.V, false, game)
            
            -- Tenta cancelar a animação de parada
            task.wait(0.05)
            local humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Freefall then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end
    
    -- Recarrega automaticamente quando stamina baixa
    spawn(function()
        while Settings.InfiniteStamina and task.wait(0.5) do
            local stamina = LocalPlayer:FindFirstChild("Stamina") or 
                           (LocalPlayer:FindFirstChild("leaderstats") and LocalPlayer.leaderstats:FindFirstChild("Stamina"))
            if stamina and stamina.Value < 30 then
                QuickReload()
                print("[✓] Auto Recarga - Stamina recarregada")
            end
        end
    end)
end

-- 5. MAX KICK POWER (Chute M2 com força máxima)
local function MaxKickPowerFeature()
    spawn(function()
        while Settings.MaxKickPower and task.wait() do
            -- Hook no evento do mouse
            local oldButtonDown = Mouse.Button1Down
            Mouse.Button1Down = function(self, ...)
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                    -- Simula segurar e soltar M2 com força máxima
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 2) -- Botão direito
                    task.wait(0.5) -- Segura por 0.5s (tempo suficiente pra carga máxima)
                    VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 2)
                    return
                end
                if oldButtonDown then oldButtonDown(self, ...) end
            end
        end
    end)
end

-- 6. KICK POWER OVERRIDE (Força personalizada do chute)
local function KickPowerOverrideFeature()
    spawn(function()
        while Settings.KickPowerOverride and task.wait() do
            -- Procura a barra de força na interface
            local powerBar = LocalPlayer.PlayerGui:FindFirstChild("PowerBar", true)
            if powerBar then
                -- Modifica diretamente o valor da barra
                if powerBar:FindFirstChild("Value") then
                    powerBar.Value.Value = Settings.KickPowerValue
                elseif powerBar:FindFirstChild("Bar") then
                    powerBar.Bar.Size = UDim2.new(Settings.KickPowerValue / 100, 0, 1, 0)
                end
            end
        end
    end)
end

-- 7. AUTO DRIBBLE (Mantém a bola sem clicar manualmente)
local function AutoDribbleFeature()
    local isDribbling = false
    spawn(function()
        while Settings.AutoDribble and task.wait(0.05) do
            local character = LocalPlayer.Character
            local ball = workspace:FindFirstChild("Ball") or workspace:FindFirstChild("SoccerBall")
            
            if character and ball then
                local distance = (ball.Position - character.HumanoidRootPart.Position).Magnitude
                
                if distance < 8 then
                    if not isDribbling then
                        isDribbling = true
                        -- Aperta o botão de dribble (geralmente E ou Q)
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
                    end
                else
                    if isDribbling then
                        isDribbling = false
                        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
                    end
                end
            end
        end
    end)
end

-- 8. ANTI-ANKLE BREAK (Imunidade a quedas)
local function AntiAnkleBreakFeature()
    spawn(function()
        while Settings.AntiAnkleBreak and task.wait(0.1) do
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    -- Desabilita estados de queda
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.Stunned, false)
                    humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                    
                    -- Se estiver caído, levanta instantaneamente
                    local currentState = humanoid:GetState()
                    if currentState == Enum.HumanoidStateType.FallingDown or 
                       currentState == Enum.HumanoidStateType.Stunned then
                        humanoid:ChangeState(Enum.HumanoidStateType.RunningNoFriction)
                    end
                end
            end
        end
    end)
end

-- 9. SUPER SLIDE (Deslize infinito)
local function SuperSlideFeature()
    spawn(function()
        while Settings.SuperSlide and task.wait() do
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                local character = LocalPlayer.Character
                local humanoid = character and character:FindFirstChild("Humanoid")
                local rootPart = character and character:FindFirstChild("HumanoidRootPart")
                
                if humanoid and rootPart then
                    -- Força o deslize a continuar
                    local direction = rootPart.CFrame.LookVector
                    rootPart.Velocity = Vector3.new(direction.X * 60, rootPart.Velocity.Y, direction.Z * 60)
                    humanoid.PlatformStand = false
                end
            end
        end
    end)
end

-- 10. SPEED BOOST (Velocidade aumentada)
local function SpeedBoostFeature()
    spawn(function()
        while Settings.SpeedBoost and task.wait(0.1) do
            local character = LocalPlayer.Character
            if character then
                local humanoid = character:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = Settings.BoostValue
                end
            end
        end
    end)
end

-- 11. FLOW REROLLER (Rolar cores do Flow)
local function FlowRerollerFeature()
    local flowColors = {"Red", "Blue", "Green", "Yellow", "Purple", "Orange"}
    local currentIndex = 1
    
    -- Auto reroll a cada 10 segundos
    spawn(function()
        while Settings.FlowReroller and task.wait(10) do
            currentIndex = (currentIndex % #flowColors) + 1
            -- Tenta encontrar remote de troca de cor
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("ChangeFlowColor")
            if remote then
                remote:FireServer(flowColors[currentIndex])
            end
            print("[✓] Flow Reroller - Cor alterada para " .. flowColors[currentIndex])
        end
    end)
    
    -- Manual: Aperte R para rerollar
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.KeyCode == Enum.KeyCode.R and Settings.FlowReroller then
            currentIndex = (currentIndex % #flowColors) + 1
            local remote = game:GetService("ReplicatedStorage"):FindFirstChild("ChangeFlowColor")
            if remote then
                remote:FireServer(flowColors[currentIndex])
            end
        end
    end)
end

-- ========== INTERFACE SIMPLES ==========
local function CreateSimpleGUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Locked2Hub"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 300, 0, 400)
    mainFrame.Position = UDim2.new(0, 10, 0.5, -200)
    mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(255, 100, 0)
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Text = "⚽ LOCKED 2 HUB ⚽"
    title.TextColor3 = Color3.fromRGB(255, 150, 0)
    title.BackgroundTransparency = 1
    title.TextScaled = true
    title.Parent = mainFrame
    
    local yPos = 50
    local toggles = {
        {"Auto Pick CF", "AutoPickCF"},
        {"Auto Flow", "AutoFlow"},
        {"Infinite Stamina", "InfiniteStamina"},
        {"Max Kick Power", "MaxKickPower"},
        {"Kick Power Override", "KickPowerOverride"},
        {"Auto Dribble", "AutoDribble"},
        {"Anti-Ankle Break", "AntiAnkleBreak"},
        {"Super Slide", "SuperSlide"},
        {"Speed Boost", "SpeedBoost"},
        {"Flow Reroller", "FlowReroller"}
    }
    
    for _, toggleInfo in ipairs(toggles) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.9, 0, 0, 35)
        btn.Position = UDim2.new(0.05, 0, 0, yPos)
        btn.Text = toggleInfo[1] .. ": OFF"
        btn.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.Parent = mainFrame
        
        local settingName = toggleInfo[2]
        btn.MouseButton1Click:Connect(function()
            Settings[settingName] = not Settings[settingName]
            btn.Text = toggleInfo[1] .. ": " .. (Settings[settingName] and "✅ ON" or "❌ OFF")
            btn.BackgroundColor3 = Settings[settingName] and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(40, 40, 50)
        end)
        
        yPos = yPos + 40
    end
    
    -- Slider de velocidade
    local speedLabel = Instance.new("TextLabel")
    speedLabel.Size = UDim2.new(0.9, 0, 0, 20)
    speedLabel.Position = UDim2.new(0.05, 0, 0, yPos)
    speedLabel.Text = "Speed Boost: " .. Settings.BoostValue
    speedLabel.BackgroundTransparency = 1
    speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    speedLabel.Parent = mainFrame
    yPos = yPos + 25
    
    local speedSlider = Instance.new("TextBox")
    speedSlider.Size = UDim2.new(0.9, 0, 0, 30)
    speedSlider.Position = UDim2.new(0.05, 0, 0, yPos)
    speedSlider.Text = tostring(Settings.BoostValue)
    speedSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    speedSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
    speedSlider.Parent = mainFrame
    
    speedSlider.FocusLost:Connect(function()
        local val = tonumber(speedSlider.Text)
        if val then
            Settings.BoostValue = math.clamp(val, 16, 50)
            speedSlider.Text = tostring(Settings.BoostValue)
            speedLabel.Text = "Speed Boost: " .. Settings.BoostValue
        end
    end)
    yPos = yPos + 45
    
    -- Slider de força do chute
    local powerLabel = Instance.new("TextLabel")
    powerLabel.Size = UDim2.new(0.9, 0, 0, 20)
    powerLabel.Position = UDim2.new(0.05, 0, 0, yPos)
    powerLabel.Text = "Kick Power: " .. Settings.KickPowerValue
    powerLabel.BackgroundTransparency = 1
    powerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    powerLabel.Parent = mainFrame
    yPos = yPos + 25
    
    local powerSlider = Instance.new("TextBox")
    powerSlider.Size = UDim2.new(0.9, 0, 0, 30)
    powerSlider.Position = UDim2.new(0.05, 0, 0, yPos)
    powerSlider.Text = tostring(Settings.KickPowerValue)
    powerSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    powerSlider.TextColor3 = Color3.fromRGB(255, 255, 255)
    powerSlider.Parent = mainFrame
    
    powerSlider.FocusLost:Connect(function()
        local val = tonumber(powerSlider.Text)
        if val then
            Settings.KickPowerValue = math.clamp(val, 1, 100)
            powerSlider.Text = tostring(Settings.KickPowerValue)
            powerLabel.Text = "Kick Power: " .. Settings.KickPowerValue
        end
    end)
end

-- ========== INICIAR TUDO ==========
print("[LOCKED 2 HUB] Carregando...")

-- Inicia todas as features
AutoPickCFFeature()
AutoFlowFeature()
InfiniteStaminaFeature()
FastReloadFeature()
MaxKickPowerFeature()
KickPowerOverrideFeature()
AutoDribbleFeature()
AntiAnkleBreakFeature()
SuperSlideFeature()
SpeedBoostFeature()
FlowRerollerFeature()

-- Cria a interface
CreateSimpleGUI()

print("[LOCKED 2 HUB] Pronto! Use o menu na tela para ativar as funções")
print("[LOCKED 2 HUB] Flow Reroller: Aperte R para trocar cor do Flow")
