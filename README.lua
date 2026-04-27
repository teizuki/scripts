--[[
    ClientHandler.lua
    Sistema principal do cliente com UI, ESP e Auto-Ataque
    Interface moderna e responsiva com tema escuro
]]

-- Serviços
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Referências
local LocalPlayer = Players.LocalPlayer
local SystemConfig = require(ReplicatedStorage.Modules.SystemConfig)
local HitboxEvent = ReplicatedStorage:WaitForChild("HitboxEvent")

-- Variáveis do sistema
local espConnections = {}
local autoAttackEnabled = false
local autoAttackConnection = nil
local systemState = {
    esp = SystemConfig.ESP.Enabled,
    hitbox = SystemConfig.Hitbox.Enabled,
    autoAttack = SystemConfig.AutoAttack.Enabled
}

-- ============================================
-- CRIAR UI PRINCIPAL
-- ============================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "MainSystem"
screenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Container principal
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 350, 0, 500)
mainFrame.Position = UDim2.new(0.7, 0, 0.5, -250)
mainFrame.BackgroundColor3 = SystemConfig.UI.ThemeColor
mainFrame.BackgroundTransparency = SystemConfig.UI.Transparency
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui
mainFrame.Active = true
mainFrame.Draggable = true

-- Corner e Stroke
local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = SystemConfig.UI.CornerRadius
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = SystemConfig.UI.AccentColor
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.5
mainStroke.Parent = mainFrame

-- Título
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 40)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "⚔️ SISTEMA DE COMBATE"
titleLabel.TextColor3 = SystemConfig.UI.TextColor
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = mainFrame

-- Layout principal
local mainLayout = Instance.new("UIListLayout")
mainLayout.Parent = mainFrame
mainLayout.SortOrder = Enum.SortOrder.LayoutOrder
mainLayout.Padding = UDim.new(0, 8)

-- ============================================
-- FUNÇÃO PARA CRIAR SEÇÃO
-- ============================================

local function createSection(parent, title, layoutOrder)
    local sectionFrame = Instance.new("Frame")
    sectionFrame.Name = title .. "Section"
    sectionFrame.Size = UDim2.new(1, -20, 0, 120)
    sectionFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    sectionFrame.BackgroundTransparency = 0.3
    sectionFrame.LayoutOrder = layoutOrder
    sectionFrame.Position = UDim2.new(0, 10, 0, 0)
    
    local sectionCorner = Instance.new("UICorner")
    sectionCorner.CornerRadius = UDim.new(0, 6)
    sectionCorner.Parent = sectionFrame
    
    local sectionStroke = Instance.new("UIStroke")
    sectionStroke.Color = Color3.fromRGB(80, 80, 80)
    sectionStroke.Thickness = 1
    sectionStroke.Transparency = 0.7
    sectionStroke.Parent = sectionFrame
    
    local sectionTitle = Instance.new("TextLabel")
    sectionTitle.Size = UDim2.new(1, 0, 0, 25)
    sectionTitle.BackgroundTransparency = 1
    sectionTitle.Text = title
    sectionTitle.TextColor3 = SystemConfig.UI.AccentColor
    sectionTitle.TextSize = 14
    sectionTitle.Font = Enum.Font.GothamSemibold
    sectionTitle.Parent = sectionFrame
    
    sectionFrame.Parent = parent
    return sectionFrame
end

-- ============================================
-- CRIAÇÃO DAS SEÇÕES
-- ============================================

-- Seção ESP
local espSection = createSection(mainFrame, "🔍 PLAYER ESP", 1)
espSection.Size = UDim2.new(1, -20, 0, 90)

-- Toggle ESP
local espToggle = Instance.new("TextButton")
espToggle.Name = "ESPToggle"
espToggle.Size = UDim2.new(0, 80, 0, 30)
espToggle.Position = UDim2.new(0, 10, 0, 30)
espToggle.BackgroundColor3 = systemState.esp and SystemConfig.UI.AccentColor or Color3.fromRGB(100, 100, 100)
espToggle.Text = systemState.esp and "ON" or "OFF"
espToggle.TextColor3 = Color3.new(1, 1, 1)
espToggle.TextSize = 14
espToggle.Font = Enum.Font.GothamBold
espToggle.Parent = espSection

local espToggleCorner = Instance.new("UICorner")
espToggleCorner.CornerRadius = UDim.new(0, 15)
espToggleCorner.Parent = espToggle

-- Raio ESP
local radiusLabel = Instance.new("TextLabel")
radiusLabel.Size = UDim2.new(0, 120, 0, 20)
radiusLabel.Position = UDim2.new(0, 100, 0, 30)
radiusLabel.BackgroundTransparency = 1
radiusLabel.Text = "Raio: " .. SystemConfig.ESP.MaxDistance .. "m"
radiusLabel.TextColor3 = SystemConfig.UI.TextColor
radiusLabel.TextSize = 12
radiusLabel.Parent = espSection

local radiusSlider = Instance.new("TextBox")
radiusSlider.Size = UDim2.new(0, 60, 0, 25)
radiusSlider.Position = UDim2.new(0, 260, 0, 30)
radiusSlider.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
radiusSlider.Text = tostring(SystemConfig.ESP.MaxDistance)
radiusSlider.TextColor3 = Color3.new(1, 1, 1)
radiusSlider.TextSize = 12
radiusSlider.PlaceholderText = "Distância"
radiusSlider.Parent = espSection

local radiusCorner = Instance.new("UICorner")
radiusCorner.CornerRadius = UDim.new(0, 5)
radiusCorner.Parent = radiusSlider

-- Seção Hitbox
local hitboxSection = createSection(mainFrame, "🎯 HITBOX CUSTOM", 2)
hitboxSection.Size = UDim2.new(1, -20, 0, 100)

-- Toggle Hitbox
local hitboxToggle = Instance.new("TextButton")
hitboxToggle.Name = "HitboxToggle"
hitboxToggle.Size = UDim2.new(0, 80, 0, 30)
hitboxToggle.Position = UDim2.new(0, 10, 0, 30)
hitboxToggle.BackgroundColor3 = systemState.hitbox and SystemConfig.UI.AccentColor or Color3.fromRGB(100, 100, 100)
hitboxToggle.Text = systemState.hitbox and "ON" or "OFF"
hitboxToggle.TextColor3 = Color3.new(1, 1, 1)
hitboxToggle.TextSize = 14
hitboxToggle.Font = Enum.Font.GothamBold
hitboxToggle.Parent = hitboxSection

local hitboxToggleCorner = Instance.new("UICorner")
hitboxToggleCorner.CornerRadius = UDim.new(0, 15)
hitboxToggleCorner.Parent = hitboxToggle

-- Sliders de escala
for i, axis in ipairs({"X", "Y", "Z"}) do
    local axisLabel = Instance.new("TextLabel")
    axisLabel.Size = UDim2.new(0, 30, 0, 20)
    axisLabel.Position = UDim2.new(0, 10 + (i - 1) * 100, 0, 70)
    axisLabel.BackgroundTransparency = 1
    axisLabel.Text = axis .. ":"
    axisLabel.TextColor3 = SystemConfig.UI.TextColor
    axisLabel.TextSize = 12
    axisLabel.Parent = hitboxSection
    
    local axisSlider = Instance.new("TextBox")
    axisSlider.Name = axis .. "Slider"
    axisSlider.Size = UDim2.new(0, 45, 0, 25)
    axisSlider.Position = UDim2.new(0, 35 + (i - 1) * 100, 0, 68)
    axisSlider.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    axisSlider.Text = "1.0"
    axisSlider.TextColor3 = Color3.new(1, 1, 1)
    axisSlider.TextSize = 12
    axisSlider.Parent = hitboxSection
    
    local axisCorner = Instance.new("UICorner")
    axisCorner.CornerRadius = UDim.new(0, 5)
    axisCorner.Parent = axisSlider
end

-- Seção Auto-Ataque
local autoAttackSection = createSection(mainFrame, "⚡ AUTO ATAQUE", 3)
autoAttackSection.Size = UDim2.new(1, -20, 0, 90)

-- Toggle Auto-Ataque
local autoAttackToggle = Instance.new("TextButton")
autoAttackToggle.Name = "AutoAttackToggle"
autoAttackToggle.Size = UDim2.new(0, 80, 0, 30)
autoAttackToggle.Position = UDim2.new(0, 10, 0, 30)
autoAttackToggle.BackgroundColor3 = systemState.autoAttack and SystemConfig.UI.AccentColor or Color3.fromRGB(100, 100, 100)
autoAttackToggle.Text = systemState.autoAttack and "ON" or "OFF"
autoAttackToggle.TextColor3 = Color3.new(1, 1, 1)
autoAttackToggle.TextSize = 14
autoAttackToggle.Font = Enum.Font.GothamBold
autoAttackToggle.Parent = autoAttackSection

local autoAttackToggleCorner = Instance.new("UICorner")
autoAttackToggleCorner.CornerRadius = UDim.new(0, 15)
autoAttackToggleCorner.Parent = autoAttackToggle

-- Intervalo
local intervalLabel = Instance.new("TextLabel")
intervalLabel.Size = UDim2.new(0, 120, 0, 20)
intervalLabel.Position = UDim2.new(0, 100, 0, 30)
intervalLabel.BackgroundTransparency = 1
intervalLabel.Text = "Intervalo: " .. SystemConfig.AutoAttack.Interval .. "s"
intervalLabel.TextColor3 = SystemConfig.UI.TextColor
intervalLabel.TextSize = 12
intervalLabel.Parent = autoAttackSection

local intervalSlider = Instance.new("TextBox")
intervalSlider.Size = UDim2.new(0, 60, 0, 25)
intervalSlider.Position = UDim2.new(0, 260, 0, 30)
intervalSlider.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
intervalSlider.Text = tostring(SystemConfig.AutoAttack.Interval)
intervalSlider.TextColor3 = Color3.new(1, 1, 1)
intervalSlider.TextSize = 12
intervalSlider.PlaceholderText = "Segundos"
intervalSlider.Parent = autoAttackSection

local intervalCorner = Instance.new("UICorner")
intervalCorner.CornerRadius = UDim.new(0, 5)
intervalCorner.Parent = intervalSlider

-- ============================================
-- SISTEMA ESP
-- ============================================

-- Criar BillboardGuis para ESP
local espBillboards = {}

local function createESPBillboard(player)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "ESP_" .. player.Name
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.MaxDistance = SystemConfig.ESP.MaxDistance
    
    -- Fundo
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.5
    bg.Parent = billboard
    
    local bgCorner = Instance.new("UICorner")
    bgCorner.CornerRadius = UDim.new(0, 4)
    bgCorner.Parent = bg
    
    -- Nome
    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, 0, 0, 15)
    nameLabel.Position = UDim2.new(0, 5, 0, 5)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.Name
    nameLabel.TextColor3 = Color3.new(1, 1, 1)
    nameLabel.TextSize = 12
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = bg
    
    -- Barra de vida
    local healthBar = Instance.new("Frame")
    healthBar.Size = UDim2.new(1, -10, 0, 8)
    healthBar.Position = UDim2.new(0, 5, 0, 25)
    healthBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    healthBar.Parent = bg
    
    local healthBarCorner = Instance.new("UICorner")
    healthBarCorner.CornerRadius = UDim.new(0, 3)
    healthBarCorner.Parent = healthBar
    
    local healthFill = Instance.new("Frame")
    healthFill.Size = UDim2.new(1, 0, 1, 0)
    healthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
    healthFill.Parent = healthBar
    
    local healthFillCorner = Instance.new("UICorner")
    healthFillCorner.CornerRadius = UDim.new(0, 3)
    healthFillCorner.Parent = healthFill
    
    -- Distância
    local distanceLabel = Instance.new("TextLabel")
    distanceLabel.Size = UDim2.new(1, 0, 0, 15)
    distanceLabel.Position = UDim2.new(0, 5, 0, 38)
    distanceLabel.BackgroundTransparency = 1
    distanceLabel.Text = "0m"
    distanceLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    distanceLabel.TextSize = 11
    distanceLabel.TextXAlignment = Enum.TextXAlignment.Left
    distanceLabel.Parent = bg
    
    return billboard, nameLabel, healthFill, distanceLabel
end

-- Atualizar ESP
local function updateESP()
    if not systemState.esp then return end
    
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local localPosition = character.HumanoidRootPart.Position
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local playerCharacter = player.Character
        if not playerCharacter or not playerCharacter:FindFirstChild("HumanoidRootPart") then continue end
        
        local distance = (playerCharacter.HumanoidRootPart.Position - localPosition).Magnitude
        
        -- Verificar distância
        if distance <= SystemConfig.ESP.MaxDistance then
            -- Criar ou atualizar Billboard
            if not espBillboards[player.UserId] then
                local billboard, nameLabel, healthFill, distanceLabel = createESPBillboard(player)
                billboard.Parent = playerCharacter:WaitForChild("Head")
                espBillboards[player.UserId] = {
                    Billboard = billboard,
                    NameLabel = nameLabel,
                    HealthFill = healthFill,
                    DistanceLabel = distanceLabel
                }
            end
            
            -- Atualizar dados
            local espData = espBillboards[player.UserId]
            if espData and espData.Billboard.Parent then
                -- Atualizar vida
                local humanoid = playerCharacter:FindFirstChild("Humanoid")
                if humanoid then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    espData.HealthFill.Size = UDim2.new(healthPercent, 0, 1, 0)
                    
                    -- Mudar cor baseado na vida
                    if healthPercent > 0.6 then
                        espData.HealthFill.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
                    elseif healthPercent > 0.3 then
                        espData.HealthFill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
                    else
                        espData.HealthFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
                    end
                end
                
                -- Atualizar distância
                espData.DistanceLabel.Text = string.format("%.1fm", distance)
            end
        else
            -- Remover ESP se muito longe
            if espBillboards[player.UserId] then
                espBillboards[player.UserId].Billboard:Destroy()
                espBillboards[player.UserId] = nil
            end
        end
    end
    
    -- Limpar ESPs de jogadores que saíram
    for userId, espData in pairs(espBillboards) do
        local player = Players:GetPlayerByUserId(userId)
        if not player then
            espData.Billboard:Destroy()
            espBillboards[userId] = nil
        end
    end
end

-- ============================================
-- SISTEMA DE AUTO ATAQUE
-- ============================================

local function findNearestEnemy()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return nil end
    
    local localPosition = character.HumanoidRootPart.Position
    local nearestEnemy = nil
    local nearestDistance = SystemConfig.ESP.MaxDistance
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local enemyCharacter = player.Character
        if not enemyCharacter or not enemyCharacter:FindFirstChild("HumanoidRootPart") then continue end
        if not enemyCharacter:FindFirstChild("Humanoid") then continue end
        if enemyCharacter.Humanoid.Health <= 0 then continue end
        
        local distance = (enemyCharacter.HumanoidRootPart.Position - localPosition).Magnitude
        if distance < nearestDistance then
            nearestDistance = distance
            nearestEnemy = enemyCharacter
        end
    end
    
    return nearestEnemy
end

local function performAttack(target)
    if not target or not target:FindFirstChild("Humanoid") then return end
    
    -- Simular ataque (clique do mouse)
    -- Em um jogo real, isso ativaria a ferramenta ou sistema de combate
    local humanoid = target.Humanoid
    
    -- Sistema de dano local (para demonstração)
    -- Em produção, isso seria substituído pelo sistema de dano do jogo
    local damage = SystemConfig.AutoAttack.Damage
    humanoid:TakeDamage(damage)
    
    -- Feedback visual
    local character = LocalPlayer.Character
    if character and character:FindFirstChild("Humanoid") then
        -- Pequena animação ou efeito
        local humanoidLocal = character.Humanoid
        local animator = humanoidLocal:FindFirstChild("Animator") or humanoidLocal:WaitForChild("Animator")
        -- Aqui você poderia carregar e tocar uma animação de ataque
    end
    
    -- Efeito de hit
    if target:FindFirstChild("Head") then
        local hitEffect = Instance.new("ParticleEmitter")
        hitEffect.Texture = "rbxassetid://null"
        hitEffect.Rate = 0
        hitEffect.Parent = target.Head
        
        -- Emitir partículas
        for i = 1, 5 do
            task.wait(0.05)
            hitEffect:Emit(1)
        end
        
        task.wait(0.2)
        hitEffect:Destroy()
    end
end

local function toggleAutoAttack()
    if autoAttackEnabled then
        -- Desativar
        autoAttackEnabled = false
        if autoAttackConnection then
            autoAttackConnection:Disconnect()
            autoAttackConnection = nil
        end
        print("Auto-Ataque desativado")
    else
        -- Ativar
        autoAttackEnabled = true
        autoAttackConnection = RunService.Heartbeat:Connect(function()
            -- Verificar intervalo
            if not autoAttackEnabled then return end
            
            local nearestEnemy = findNearestEnemy()
            if nearestEnemy then
                performAttack(nearestEnemy)
                task.wait(SystemConfig.AutoAttack.Interval)
            end
        end)
        print("Auto-Ataque ativado")
    end
end

-- ============================================
-- EVENTOS DOS BOTÕES
-- ============================================

-- Toggle ESP
espToggle.MouseButton1Click:Connect(function()
    systemState.esp = not systemState.esp
    SystemConfig.ESP.Enabled = systemState.esp
    
    -- Atualizar UI
    espToggle.BackgroundColor3 = systemState.esp and SystemConfig.UI.AccentColor or Color3.fromRGB(100, 100, 100)
    espToggle.Text = systemState.esp and "ON" or "OFF"
    
    -- Tween animation
    local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(espToggle, tweenInfo, {
        Size = UDim2.new(0, 85, 0, 32)
    })
    tween:Play()
    
    task.wait(0.3)
    
    local tweenBack = TweenService:Create(espToggle, tweenInfo, {
        Size = UDim2.new(0, 80, 0, 30)
    })
    tweenBack:Play()
    
    if not systemState.esp then
        -- Limpar ESPs
        for _, espData in pairs(espBillboards) do
            espData.Billboard:Destroy()
        end
        espBillboards = {}
    end
end)

-- Toggle Hitbox
hitboxToggle.MouseButton1Click:Connect(function()
    systemState.hitbox = not systemState.hitbox
    SystemConfig.Hitbox.Enabled = systemState.hitbox
    
    -- Atualizar UI
    hitboxToggle.BackgroundColor3 = systemState.hitbox and SystemConfig.UI.AccentColor or Color3.fromRGB(100, 100, 100)
    hitboxToggle.Text = systemState.hitbox and "ON" or "OFF"
    
    -- Enviar para servidor
    if systemState.hitbox then
        local scaleX = tonumber(hitboxSection:FindFirstChild("XSlider").Text) or 1.0
        local scaleY = tonumber(hitboxSection:FindFirstChild("YSlider").Text) or 1.0
        local scaleZ = tonumber(hitboxSection:FindFirstChild("ZSlider").Text) or 1.0
        
        HitboxEvent:FireServer("UpdateHitbox", {
            ScaleX = scaleX,
            ScaleY = scaleY,
            ScaleZ = scaleZ
        })
    else
        HitboxEvent:FireServer("DisableHitbox")
    end
end)

-- Toggle Auto-Ataque
autoAttackToggle.MouseButton1Click:Connect(function()
    systemState.autoAttack = not systemState.autoAttack
    SystemConfig.AutoAttack.Enabled = systemState.autoAttack
    
    -- Atualizar UI
    autoAttackToggle.BackgroundColor3 = systemState.autoAttack and SystemConfig.UI.AccentColor or Color3.fromRGB(100, 100, 100)
    autoAttackToggle.Text = systemState.autoAttack and "ON" or "OFF"
    
    -- Ativar/desativar sistema
    toggleAutoAttack()
end)

-- Atualizar raio ESP
radiusSlider.FocusLost:Connect(function(enterPressed)
    local newRadius = tonumber(radiusSlider.Text) or SystemConfig.ESP.MaxDistance
    newRadius = math.clamp(newRadius, 10, 500)
    SystemConfig.ESP.MaxDistance = newRadius
    radiusSlider.Text = tostring(newRadius)
    radiusLabel.Text = "Raio: " .. newRadius .. "m"
end)

-- Atualizar intervalo do Auto-Ataque
intervalSlider.FocusLost:Connect(function(enterPressed)
    local newInterval = tonumber(intervalSlider.Text) or SystemConfig.AutoAttack.Interval
    newInterval = math.clamp(newInterval, 0.1, 2.0)
    SystemConfig.AutoAttack.Interval = newInterval
    intervalSlider.Text = tostring(newInterval)
    intervalLabel.Text = "Intervalo: " .. string.format("%.1f", newInterval) .. "s"
end)

-- Atualizar escalas da hitbox
for _, axisName in ipairs({"X", "Y", "Z"}) do
    local slider = hitboxSection:FindFirstChild(axisName .. "Slider")
    if slider then
        slider.FocusLost:Connect(function()
            local value = tonumber(slider.Text) or 1.0
            value = math.clamp(value, 0.5, 2.5)
            slider.Text = string.format("%.1f", value)
            
            -- Se hitbox estiver ativa, atualizar
            if systemState.hitbox then
                local scaleX = tonumber(hitboxSection:FindFirstChild("XSlider").Text) or 1.0
                local scaleY = tonumber(hitboxSection:FindFirstChild("YSlider").Text) or 1.0
                local scaleZ = tonumber(hitboxSection:FindFirstChild("ZSlider").Text) or 1.0
                
                HitboxEvent:FireServer("UpdateHitbox", {
                    ScaleX = scaleX,
                    ScaleY = scaleY,
                    ScaleZ = scaleZ
                })
            end
        end)
    end
end

-- ============================================
-- LOOP PRINCIPAL DE ATUALIZAÇÃO
-- ============================================

-- Atualização otimizada do ESP
local lastESPUpdate = 0
RunService.Heartbeat:Connect(function(deltaTime)
    lastESPUpdate = lastESPUpdate + deltaTime
    
    -- Atualizar ESP com rate limit
    if lastESPUpdate >= SystemConfig.ESP.UpdateRate then
        lastESPUpdate = 0
        if systemState.esp then
            updateESP()
        end
    end
end)

-- Limpar quando jogador sair
Players.PlayerRemoving:Connect(function(player)
    if espBillboards[player.UserId] then
        espBillboards[player.UserId].Billboard:Destroy()
        espBillboards[player.UserId] = nil
    end
end)

-- Resetar quando personagem renascer
LocalPlayer.CharacterAdded:Connect(function(character)
    for _, espData in pairs(espBillboards) do
        espData.Billboard:Destroy()
    end
    espBillboards = {}
    
    -- Reaplicar hitbox se estava ativa
    if systemState.hitbox then
        HitboxEvent:FireServer("DisableHitbox")
        task.wait(0.5)
        
        local scaleX = tonumber(hitboxSection:FindFirstChild("XSlider").Text) or 1.0
        local scaleY = tonumber(hitboxSection:FindFirstChild("YSlider").Text) or 1.0
        local scaleZ = tonumber(hitboxSection:FindFirstChild("ZSlider").Text) or 1.0
        
        HitboxEvent:FireServer("UpdateHitbox", {
            ScaleX = scaleX,
            ScaleY = scaleY,
            ScaleZ = scaleZ
        })
    end
end)

-- ============================================
-- ANIMAÇÃO INICIAL DA UI
-- ============================================

-- Animação de entrada suave
local startPosition = mainFrame.Position
mainFrame.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset, 0, -500)

local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local entranceTween = TweenService:Create(mainFrame, tweenInfo, {
    Position = startPosition
})
entranceTween:Play()

print("Sistema do Cliente inicializado com sucesso!")
