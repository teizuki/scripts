-- Script Local (Colocar dentro de StarterPlayerScripts ou StarterGui)

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

-- Variáveis de configuração
local enabledFlicker = false
local enabledSilentAim = false
local goalPosition = nil

-- Encontrar o gol (ajuste a posição conforme necessário)
local function findGoal()
    -- Procura o gol azul (time adversário geralmente)
    -- Ajuste o nome da parte conforme seu jogo
    local blueGoal = workspace:FindFirstChild("BlueGoal") or workspace:FindFirstChild("Goal_Blue")
    local redGoal = workspace:FindFirstChild("RedGoal") or workspace:FindFirstChild("Goal_Red")
    
    if player.TeamColor == BrickColor.new("Bright red") then
        goalPosition = blueGoal and blueGoal.Position or Vector3.new(100, 5, 0)
    else
        goalPosition = redGoal and redGoal.Position or Vector3.new(-100, 5, 0)
    end
    
    if not goalPosition then
        -- Posição padrão do gol (ajuste conforme seu campo)
        goalPosition = Vector3.new(100, 2.5, 0)
    end
end

-- Função de Flicker (efeito visual)
local function flickerEffect()
    local originalBrightness = game.Lighting.Brightness
    local originalClockTime = game.Lighting.ClockTime
    local originalAmbient = game.Lighting.Ambient
    
    for i = 1, 10 do
        if not enabledFlicker then break end
        
        -- Efeito flicker aleatório
        game.Lighting.Brightness = originalBrightness * (0.3 + math.random() * 0.7)
        game.Lighting.Ambient = Color3.new(
            math.random() * 0.5,
            math.random() * 0.5,
            math.random() * 0.5
        )
        
        wait(0.03)
        
        if not enabledFlicker then break end
        
        game.Lighting.Brightness = originalBrightness * (0.6 + math.random() * 0.4)
        wait(0.03)
    end
    
    -- Restaurar iluminação
    game.Lighting.Brightness = originalBrightness
    game.Lighting.ClockTime = originalClockTime
    game.Lighting.Ambient = originalAmbient
end

-- Função de Silent Aim para chute
local function silentAimKick(ball, kickDirection)
    if not enabledSilentAim or not ball or not goalPosition then
        return kickDirection
    end
    
    -- Calcular direção perfeita para o gol
    local ballPosition = ball.Position
    local directionToGoal = (goalPosition - ballPosition).Unit
    
    -- Adicionar um pequeno desvio para não parecer muito óbvio (ajustável)
    local deviation = 0.05 -- 5% de desvio para parecer natural
    local finalDirection = directionToGoal:Lerp(kickDirection, deviation)
    
    return finalDirection
end

-- Detectar chute e aplicar Silent Aim
local function onBallKicked(ball, kickForce, kickDirection)
    coroutine.wrap(function()
        wait(0.05) -- Pequeno delay para garantir que o balão está sendo chutado
        
        if enabledSilentAim and ball and ball:IsA("BasePart") then
            local correctedDirection = silentAimKick(ball, kickDirection)
            
            -- Aplicar a força corrigida
            local bodyVelocity = ball:FindFirstChildOfClass("BodyVelocity")
            if bodyVelocity then
                bodyVelocity.Velocity = correctedDirection * kickForce.Magnitude
            elseif ball:FindFirstChildOfClass("BodyThrust") then
                local thrust = ball:FindFirstChildOfClass("BodyThrust")
                thrust.Force = correctedDirection * kickForce.Magnitude
            else
                -- Método alternativo se não encontrar BodyVelocity
                ball.Velocity = correctedDirection * kickForce.Magnitude
            end
        end
    end)()
end

-- Detectar quando o jogador chuta a bola
local function setupBallDetection()
    local function onBallAdded(ball)
        if ball:IsA("BasePart") and (ball.Name:lower():find("ball") or ball.Name:lower():find("bola")) then
            ball.Touched:Connect(function(hit)
                if hit:IsDescendantOf(player.Character) and enabledSilentAim then
                    local kickForce = Vector3.new(50, 20, 50) -- Força padrão do chute
                    local kickDirection = (hit.Position - ball.Position).Unit
                    onBallKicked(ball, kickForce, kickDirection)
                end
            end)
        end
    end
    
    -- Verificar bolas existentes
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (obj.Name:lower():find("ball") or obj.Name:lower():find("bola")) then
            onBallAdded(obj)
        end
    end
    
    -- Detectar novas bolas
    workspace.DescendantAdded:Connect(onBallAdded)
end

-- Criar UI
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LockedGUI"
    screenGui.Parent = player.PlayerGui
    
    -- Frame principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 250, 0, 150)
    mainFrame.Position = UDim2.new(0, 10, 1, -160)
    mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Adicionar sombra e arredondamento
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 30)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    title.Text = "⚽ LOCKED V1"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 8)
    titleCorner.Parent = title
    
    -- Botão Flicker
    local flickerButton = Instance.new("TextButton")
    flickerButton.Size = UDim2.new(0, 220, 0, 40)
    flickerButton.Position = UDim2.new(0.5, -110, 0, 40)
    flickerButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    flickerButton.Text = "⚡ FLICKER: OFF"
    flickerButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    flickerButton.TextSize = 14
    flickerButton.Font = Enum.Font.Gotham
    flickerButton.Parent = mainFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 5)
    buttonCorner.Parent = flickerButton
    
    -- Botão Silent Aim
    local silentButton = Instance.new("TextButton")
    silentButton.Size = UDim2.new(0, 220, 0, 40)
    silentButton.Position = UDim2.new(0.5, -110, 0, 90)
    silentButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
    silentButton.Text = "🎯 SILENT AIM: OFF"
    silentButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    silentButton.TextSize = 14
    silentButton.Font = Enum.Font.Gotham
    silentButton.Parent = mainFrame
    
    local silentCorner = Instance.new("UICorner")
    silentCorner.CornerRadius = UDim.new(0, 5)
    silentCorner.Parent = silentButton
    
    -- Status text
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 20)
    statusLabel.Position = UDim2.new(0, 0, 1, -25)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "Ready"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    statusLabel.TextSize = 11
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = mainFrame
    
    -- Funções dos botões
    flickerButton.MouseButton1Click:Connect(function()
        enabledFlicker = not enabledFlicker
        flickerButton.Text = enabledFlicker and "⚡ FLICKER: ON" or "⚡ FLICKER: OFF"
        flickerButton.BackgroundColor3 = enabledFlicker and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(60, 60, 60)
        statusLabel.Text = enabledFlicker and "Flicker ativo" or "Flicker desativado"
        
        if enabledFlicker then
            flickerEffect()
        end
    end)
    
    silentButton.MouseButton1Click:Connect(function()
        enabledSilentAim = not enabledSilentAim
        silentButton.Text = enabledSilentAim and "🎯 SILENT AIM: ON" or "🎯 SILENT AIM: OFF"
        silentButton.BackgroundColor3 = enabledSilentAim and Color3.fromRGB(0, 120, 0) or Color3.fromRGB(60, 60, 60)
        statusLabel.Text = enabledSilentAim and "Silent Aim ativo" or "Silent Aim desativado"
        
        if enabledSilentAim then
            statusLabel.Text = "Silent Aim: mira ajustada para o gol!"
        end
        
        -- Feedback visual
        statusLabel.TextColor3 = enabledSilentAim and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(150, 150, 150)
        wait(2)
        statusLabel.Text = "Ready"
        statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    end)
    
    -- UI Draggable
    local dragging = false
    local dragStart, startPos
    
    mainFrame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
        end
    end)
    
    userInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    
    userInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- Inicialização
findGoal()
setupBallDetection()
createUI()

-- Atualizar posição do gol periodicamente (caso se mova)
spawn(function()
    while true do
        wait(5)
        findGoal()
    end
end)

print("✅ Locked Script Carregado com Sucesso!")
print("🎮 Flicker ativa efeito de piscar a luz")
print("🎯 Silent Aim redireciona chutes para o gol")

local blueGoal = workspace:FindFirstChild("BlueGoal") or workspace:FindFirstChild("Goal_Blue")
local redGoal = workspace:FindFirstChild("RedGoal") or workspace:FindFirstChild("Goal_Red")

goalPosition = Vector3.new(100, 2.5, 0) -- Ajuste X, Y, Z
