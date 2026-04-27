-- Script Local (Colocar dentro de StarterPlayerScripts ou StarterGui)

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

-- Variáveis de configuração
local enabledFlicker = false
local enabledSilentAim = false
local goalPosition = nil
local ball = nil

-- Encontrar o gol (mais preciso)
local function findGoal()
    -- Procura por diferentes nomes possíveis para o gol
    local possibleGoalNames = {"Goal", "Gol", "BlueGoal", "RedGoal", "GoalBlue", "GoalRed", "Poste", "Trave"}
    
    for _, name in pairs(possibleGoalNames) do
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("BasePart") and string.find(string.lower(obj.Name), string.lower(name)) then
                -- Verifica se é do time adversário
                if player.Team then
                    if (player.Team.Name == "Red" and string.find(string.lower(obj.Name), "blue")) or
                       (player.Team.Name == "Blue" and string.find(string.lower(obj.Name), "red")) then
                        goalPosition = obj.Position
                        return
                    end
                else
                    goalPosition = obj.Position
                    return
                end
            end
        end
    end
    
    -- Posição padrão se não encontrar (ajuste conforme seu campo)
    if player.Team and player.Team.Name == "Red" then
        goalPosition = Vector3.new(100, 3, 0) -- Gol do time azul
    else
        goalPosition = Vector3.new(-100, 3, 0) -- Gol do time vermelho
    end
end

-- Encontrar a bola
local function findBall()
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") and (string.find(string.lower(obj.Name), "ball") or 
           string.find(string.lower(obj.Name), "bola") or obj:IsA("Ball")) then
            ball = obj
            return
        end
    end
end

-- Hook no chute do jogador
local function hookKick()
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    
    -- Detectar chute (quando o jogador faz animação de chute)
    local function onAnimationPlayed(animationTrack)
        if enabledSilentAim and ball then
            local animName = animationTrack.Animation.AnimationId
            -- Verifica se é animação de chute
            if string.find(string.lower(animName or ""), "kick") or 
               string.find(string.lower(animName or ""), "chute") then
                
                -- Delay para o chute conectar com a bola
                task.wait(0.1)
                
                if ball and goalPosition then
                    -- Redirecionar a bola
                    local ballPosition = ball.Position
                    local directionToGoal = (goalPosition - ballPosition).Unit
                    
                    -- Calcular força baseada na distância
                    local distance = (goalPosition - ballPosition).Magnitude
                    local power = math.clamp(80 + (distance / 10), 50, 150) -- Força ajustável
                    
                    -- Aplicar força na bola
                    if ball:IsA("BasePart") then
                        -- Método 1: BodyVelocity
                        local bv = ball:FindFirstChildOfClass("BodyVelocity")
                        if not bv then
                            bv = Instance.new("BodyVelocity")
                            bv.MaxForce = Vector3.new(10000, 10000, 10000)
                            bv.Parent = ball
                        end
                        bv.Velocity = directionToGoal * power
                        
                        -- Método 2: Força adicional (garantia)
                        task.wait(0.05)
                        ball.Velocity = directionToGoal * power
                        
                        -- Remover BodyVelocity depois de um tempo
                        task.delay(1, function()
                            if bv and bv.Parent then
                                bv:Destroy()
                            end
                        end)
                    end
                end
            end
        end
    end
    
    if humanoid.AnimationPlayed:Connect then
        humanoid.AnimationPlayed:Connect(onAnimationPlayed)
    end
end

-- Detectar colisão do pé com a bola
local function detectFootHit()
    local character = player.Character
    if not character then return end
    
    -- Encontrar os pés
    local leftFoot = character:FindFirstChild("LeftFoot")
    local rightFoot = character:FindFirstChild("RightFoot")
    
    local function onFootTouched(part)
        if not enabledSilentAim then return end
        if not ball then findBall() end
        if not ball or not goalPosition then return end
        
        -- Verificar se tocou na bola
        if part == ball or part.Parent == ball then
            -- Pequeno delay para garantir que é um chute
            task.wait(0.05)
            
            if ball and ball.Parent then
                local ballPosition = ball.Position
                local directionToGoal = (goalPosition - ballPosition).Unit
                
                -- Força do chute
                local distance = (goalPosition - ballPosition).Magnitude
                local power = math.clamp(70 + (distance / 8), 60, 200)
                
                -- Aplicar força
                local bv = ball:FindFirstChildOfClass("BodyVelocity")
                if not bv then
                    bv = Instance.new("BodyVelocity")
                    bv.MaxForce = Vector3.new(100000, 100000, 100000)
                    bv.Parent = ball
                end
                bv.Velocity = directionToGoal * power
                
                ball.Velocity = directionToGoal * power
                
                -- Limpar após uso
                task.delay(0.5, function()
                    if bv and bv.Parent then
                        bv:Destroy()
                    end
                end)
            end
        end
    end
    
    if leftFoot then
        leftFoot.Touched:Connect(onFootTouched)
    end
    if rightFoot then
        rightFoot.Touched:Connect(onFootTouched)
    end
end

-- Detectar quando o personagem é carregado
local function onCharacterAdded(character)
    task.wait(0.5)
    hookKick()
    detectFootHit()
end

-- Função de Flicker (melhorada)
local function flickerEffect()
    local lighting = game:GetService("Lighting")
    
    -- Salvar configurações originais
    local originalSettings = {
        Brightness = lighting.Brightness,
        ClockTime = lighting.ClockTime,
        Ambient = lighting.Ambient,
        OutdoorAmbient = lighting.OutdoorAmbient,
        FogEnd = lighting.FogEnd
    }
    
    -- Duração do efeito
    local duration = 0.8
    local startTime = tick()
    
    while enabledFlicker and (tick() - startTime) < duration do
        -- Flicker aleatório
        lighting.Brightness = originalSettings.Brightness * (0.2 + math.random() * 1.5)
        lighting.Ambient = Color3.new(
            math.random() * 0.8,
            math.random() * 0.8,
            math.random() * 0.8
        )
        
        -- Pausa curta
        task.wait(0.02)
        
        if not enabledFlicker then break end
        
        -- Restaurar parcialmente
        lighting.Brightness = originalSettings.Brightness * (0.5 + math.random() * 0.5)
        task.wait(0.02)
    end
    
    -- Restaurar completamente
    lighting.Brightness = originalSettings.Brightness
    lighting.ClockTime = originalSettings.ClockTime
    lighting.Ambient = originalSettings.Ambient
    lighting.OutdoorAmbient = originalSettings.OutdoorAmbient
    lighting.FogEnd = originalSettings.FogEnd
end

-- Criar UI interativa
local function createUI()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LockedGUI"
    screenGui.Parent = player.PlayerGui
    screenGui.ResetOnSpawn = false
    
    -- Frame principal
    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 260, 0, 180)
    mainFrame.Position = UDim2.new(0, 10, 1, -190)
    mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    mainFrame.BackgroundTransparency = 0.05
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = screenGui
    
    -- Sombra
    local shadow = Instance.new("Frame")
    shadow.Size = UDim2.new(1, 10, 1, 10)
    shadow.Position = UDim2.new(0, -5, 0, -5)
    shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    shadow.BackgroundTransparency = 0.5
    shadow.BorderSizePixel = 0
    shadow.ZIndex = -1
    shadow.Parent = mainFrame
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = mainFrame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 35)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    title.Text = "⚽ LOCKED | AIM ASSIST"
    title.TextColor3 = Color3.fromRGB(255, 220, 100)
    title.TextSize = 16
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 10)
    titleCorner.Parent = title
    
    -- Botão Flicker
    local flickerButton = Instance.new("TextButton")
    flickerButton.Size = UDim2.new(0, 230, 0, 45)
    flickerButton.Position = UDim2.new(0.5, -115, 0, 50)
    flickerButton.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    flickerButton.Text = "⚡ FLICKER: OFF"
    flickerButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    flickerButton.TextSize = 15
    flickerButton.Font = Enum.Font.GothamSemibold
    flickerButton.AutoButtonColor = false
    flickerButton.Parent = mainFrame
    
    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 6)
    buttonCorner.Parent = flickerButton
    
    -- Botão Silent Aim
    local silentButton = Instance.new("TextButton")
    silentButton.Size = UDim2.new(0, 230, 0, 45)
    silentButton.Position = UDim2.new(0.5, -115, 0, 105)
    silentButton.BackgroundColor3 = Color3.fromRGB(50, 50, 65)
    silentButton.Text = "🎯 SILENT AIM: OFF"
    silentButton.TextColor3 = Color3.fromRGB(220, 220, 220)
    silentButton.TextSize = 15
    silentButton.Font = Enum.Font.GothamSemibold
    silentButton.AutoButtonColor = false
    silentButton.Parent = mainFrame
    
    local silentCorner = Instance.new("UICorner")
    silentCorner.CornerRadius = UDim.new(0, 6)
    silentCorner.Parent = silentButton
    
    -- Status text
    local statusLabel = Instance.new("TextLabel")
    statusLabel.Size = UDim2.new(1, 0, 0, 30)
    statusLabel.Position = UDim2.new(0, 0, 1, -30)
    statusLabel.BackgroundTransparency = 1
    statusLabel.Text = "✅ Sistema pronto"
    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    statusLabel.TextSize = 12
    statusLabel.Font = Enum.Font.Gotham
    statusLabel.Parent = mainFrame
    
    -- Efeitos hover
    local function onHover(button, hover)
        button.BackgroundColor3 = hover and Color3.fromRGB(65, 65, 85) or Color3.fromRGB(50, 50, 65)
    end
    
    flickerButton.MouseEnter:Connect(function() onHover(flickerButton, true) end)
    flickerButton.MouseLeave:Connect(function() onHover(flickerButton, false) end)
    silentButton.MouseEnter:Connect(function() onHover(silentButton, true) end)
    silentButton.MouseLeave:Connect(function() onHover(silentButton, false) end)
    
    -- Botão flicker
    flickerButton.MouseButton1Click:Connect(function()
        enabledFlicker = not enabledFlicker
        flickerButton.Text = enabledFlicker and "⚡ FLICKER: ON" or "⚡ FLICKER: OFF"
        flickerButton.BackgroundColor3 = enabledFlicker and Color3.fromRGB(80, 130, 80) or Color3.fromRGB(50, 50, 65)
        
        if enabledFlicker then
            statusLabel.Text = "✨ FLICKER ativado!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            coroutine.wrap(flickerEffect)()
        else
            statusLabel.Text = "⚫ FLICKER desativado"
            statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            task.delay(1.5, function()
                if not enabledFlicker then
                    statusLabel.Text = "✅ Sistema pronto"
                    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                end
            end)
        end
    end)
    
    -- Botão silent aim
    silentButton.MouseButton1Click:Connect(function()
        enabledSilentAim = not enabledSilentAim
        silentButton.Text = enabledSilentAim and "🎯 SILENT AIM: ON" or "🎯 SILENT AIM: OFF"
        silentButton.BackgroundColor3 = enabledSilentAim and Color3.fromRGB(80, 130, 80) or Color3.fromRGB(50, 50, 65)
        
        if enabledSilentAim then
            statusLabel.Text = "🎯 SILENT AIM ativo - Bolas vão direto ao gol!"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            task.delay(2, function()
                if enabledSilentAim then
                    statusLabel.Text = "✅ Sistema pronto"
                    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                end
            end)
        else
            statusLabel.Text = "🎯 SILENT AIM desativado"
            statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
            task.delay(1.5, function()
                if not enabledSilentAim then
                    statusLabel.Text = "✅ Sistema pronto"
                    statusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
                end
            end)
        end
    end)
    
    -- Implementar drag
    local dragging = false
    local dragStart, startPos
    
    local function updateDrag(input)
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    
    title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            
            local connection
            connection = userInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
                    updateDrag(input)
                end
            end)
            
            userInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end)
end

-- Inicialização
local function init()
    findBall()
    findGoal()
    createUI()
    
    -- Monitorar bola em tempo real
    task.spawn(function()
        while true do
            task.wait(0.5)
            if not ball or not ball.Parent then
                findBall()
            end
            findGoal() -- Atualizar posição do gol
        end
    end)
    
    -- Detectar quando personagem entrar
    if player.Character then
        onCharacterAdded(player.Character)
    end
    player.CharacterAdded:Connect(onCharacterAdded)
    
    print("✅ LOCKED Script Carregado!")
    print("⚡ Flicker: Efeito de luz piscante")
    print("🎯 Silent Aim: Chutes vão direto ao gol")
end

-- Executar
init()

-- Força do chute (linha ~100)
local power = math.clamp(80 + (distance / 10), 50, 150)

-- Se quiser força máxima sempre:
local power = 150 -- Força fixa

-- Adicione isso no início do script para debug
local function debugLog(msg)
    warn("[LOCKED] " .. msg)
end

-- E adicione dentro do onFootTouched:
debugLog("Chute detectado! Bola: " .. tostring(ball and ball.Name))
debugLog("Gol posição: " .. tostring(goalPosition))
debugLog("Direção: " .. tostring(directionToGoal))
