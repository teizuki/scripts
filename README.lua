-- Hunter x Enter | Auto Meditação + UI
-- Executor: Xeno

local Players    = game:GetService("Players")
local VIM        = game:GetService("VirtualInputManager")

local lp         = Players.LocalPlayer
local gui        = lp:WaitForChild("PlayerGui")

local SCAN_DELAY = 0.05
local COOLDOWN   = 0.35
local toggled    = false  -- começa OFF, usuário liga pelo botão
local lastKey    = nil
local lastTime   = 0

local keyMap = {}
for i = 65, 90 do
    local char = string.char(i)
    keyMap[char] = Enum.KeyCode[char]
end

local function pressKey(keyCode)
    VIM:SendKeyEvent(true,  keyCode, false, game)
    task.wait(0.05)
    VIM:SendKeyEvent(false, keyCode, false, game)
end

-- ── UI ───────────────────────────────────────────────────────────────────────
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "TeiUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = gui

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 180, 0, 90)
main.Position = UDim2.new(0, 20, 0.5, -45)
main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
main.BorderSizePixel = 0
main.Active = true
main.Draggable = true
main.Parent = screenGui

Instance.new("UICorner", main).CornerRadius = UDim.new(0, 6)

local stroke = Instance.new("UIStroke", main)
stroke.Color = Color3.fromRGB(50, 50, 50)
stroke.Thickness = 1

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundTransparency = 1
title.Text = "./tei"
title.TextColor3 = Color3.fromRGB(200, 200, 200)
title.Font = Enum.Font.Gotham
title.TextSize = 13
title.Parent = main

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, 0, 0, 1)
divider.Position = UDim2.new(0, 0, 0, 30)
divider.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
divider.BorderSizePixel = 0
divider.Parent = main

local btn = Instance.new("TextButton")
btn.Size = UDim2.new(1, -24, 0, 32)
btn.Position = UDim2.new(0, 12, 0, 42)
btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
btn.Text = "meditação - OFF"
btn.TextColor3 = Color3.fromRGB(220, 80, 80)
btn.Font = Enum.Font.Gotham
btn.TextSize = 12
btn.BorderSizePixel = 0
btn.Parent = main

Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

local function updateBtn()
    if toggled then
        btn.Text = "meditação - ON"
        btn.TextColor3 = Color3.fromRGB(100, 220, 100)
    else
        btn.Text = "meditação - OFF"
        btn.TextColor3 = Color3.fromRGB(220, 80, 80)
    end
end

btn.MouseButton1Click:Connect(function()
    toggled = not toggled
    updateBtn()
    -- aperta M para entrar ou sair da meditação em sincronia com o botão
    task.wait(0.1)
    pressKey(Enum.KeyCode.M)
    print("[HxE] " .. (toggled and "ON — entrando em meditacao" or "OFF — saindo de meditacao"))
end)
-- ─────────────────────────────────────────────────────────────────────────────

local meditationUI = gui:WaitForChild("MeditationUI", 10)
if not meditationUI then
    print("[HxE] MeditationUI nao encontrada")
    return
end

local keyLabel = meditationUI:WaitForChild("KeyFrame"):WaitForChild("KeyLabel")

print("[HxE] pronto — clique o botao para iniciar")

task.spawn(function()
    while true do
        task.wait(SCAN_DELAY)
        if not toggled then continue end
        if not keyLabel.Visible then continue end

        local letter = string.match(keyLabel.Text, "^(%u)$")
        local now    = tick()

        if letter and keyMap[letter] and (letter ~= lastKey or now - lastTime > COOLDOWN) then
            print("[HxE] -> " .. letter)
            pressKey(keyMap[letter])
            lastKey  = letter
            lastTime = now
        end
    end
end)
