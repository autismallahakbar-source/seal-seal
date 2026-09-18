local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Knife Duels | saasfd",
    LoadingTitle = "Knife Duels",
    LoadingSubtitle = "by seal",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "KnifeDuels_saasfd",
        FileName = "Config"
    },
    KeySystem = false,
})

local MainTab = Window:CreateTab(" Aimbot", nil)
local ESPTab = Window:CreateTab(" ESP", nil)
local ChecksTab = Window:CreateTab(" Checks", nil)
local SettingsTab = Window:CreateTab( Settings", nil)

-- ===== ANA DEĞİŞKENLER =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Varsayılan ayarlar
local FOVRadius = 130
local Smoothness = 0.12
local AimbotEnabled = true
local ESPEnabled = true
local AimMode = "Always On"
local WallCheck = false

-- FOV Dairesi
local FOVCircle = Drawing.new("Circle")
FOVCircle.Visible = false
FOVCircle.Radius = FOVRadius
FOVCircle.Thickness = 2
FOVCircle.Color = Color3.fromRGB(0, 255, 255)
FOVCircle.Filled = false
FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

-- ESP Kutuları
local ESPBoxes = {}

-- ===== ESP FONKSİYONLARI =====
local function createESP(player)
    if player == LocalPlayer then return end
    if ESPBoxes[player] then return end

    local box = Drawing.new("Square")
    box.Visible = true
    box.Color = Color3.fromRGB(255, 50, 50)
    box.Thickness = 2
    box.Filled = false
    box.Transparency = 0.5
    ESPBoxes[player] = box
end

local function updateESP()
    for player, box in pairs(ESPBoxes) do
        local char = player.Character
        if not char or not char.PrimaryPart then
            box.Visible = false
            continue
        end

        local root = char.PrimaryPart
        local pos = root.Position
        local size = root.Size

        local head = char:FindFirstChild("Head")
        local topPos = head and head.Position or pos + Vector3.new(0, 2, 0)
        local bottomPos = pos - Vector3.new(0, size.Y / 2, 0)
        local topPoint, topOnScreen = Camera:WorldToViewportPoint(topPos + Vector3.new(0, 1, 0))
        local bottomPoint, bottomOnScreen = Camera:WorldToViewportPoint(bottomPos)

        if not topOnScreen or not bottomOnScreen then
            box.Visible = false
            continue
        end

        local height = topPoint.Y - bottomPoint.Y
        local width = height * 0.5

        box.Size = Vector2.new(width, height)
        box.Position = Vector2.new(topPoint.X - width/2, topPoint.Y - height)
        box.Visible = true
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        createESP(player)
    end)
    if player.Character then createESP(player) end
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        createESP(player)
    end
end

-- ===== WALL CHECK =====
local function hasLineOfSight(targetPart)
    local char = LocalPlayer.Character
    if not char then return false end
    local myHead = char:FindFirstChild("Head")
    if not myHead then return false end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {char, targetPart.Parent}

    local direction = targetPart.Position - myHead.Position
    local result = Workspace:Raycast(myHead.Position, direction, rayParams)

    return result == nil
end

-- ===== AIMBOT =====
local function getClosestEnemy()
    local closest = nil
    local shortestDist = FOVRadius
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if not char then continue end
        local head = char:FindFirstChild("Head")
        if not head then continue end

        -- WALL CHECK
        if WallCheck then
            if not hasLineOfSight(head) then continue end
        end

        local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(headPos.X, headPos.Y) - center).Magnitude
        if dist < shortestDist then
            shortestDist = dist
            closest = head
        end
    end
    return closest
end

-- MB2 kontrolü
local isHoldingMB2 = false
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isHoldingMB2 = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        isHoldingMB2 = false
    end
end)

-- Ana döngü
RunService.RenderStepped:Connect(function()
    if ESPEnabled then
        updateESP()
    else
        for _, box in pairs(ESPBoxes) do
            box.Visible = false
        end
    end

    if not AimbotEnabled then
        FOVCircle.Visible = false
        return
    end

    FOVCircle.Visible = true

    local shouldAim = false
    if AimMode == "Always On" then
        shouldAim = true
    elseif AimMode == "Hold (MB2)" then
        shouldAim = isHoldingMB2
    end

    if not shouldAim then return end

    local targetHead = getClosestEnemy()
    if targetHead then
        local lookAt = targetHead.Position
        local currentCF = Camera.CFrame
        local targetCF = CFrame.new(currentCF.Position, lookAt)
        Camera.CFrame = currentCF:Lerp(targetCF, Smoothness)
    end
end)

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
end)

-- ===== GUI ELEMANLARI =====

-- Aimbot Tab
local aimSection = MainTab:CreateSection("Aimbot Controls")

MainTab:CreateToggle({
    Name = "Enable Aimbot",
    CurrentValue = true,
    Flag = "aimbot_enabled",
    Callback = function(Value)
        AimbotEnabled = Value
        if not Value then
            FOVCircle.Visible = false
        end
    end
})

MainTab:CreateDropdown({
    Name = "Aimbot Mode",
    Options = {"Always On", "Hold (MB2)"},
    CurrentOption = {"Always On"},
    Flag = "aim_mode",
    Callback = function(Option)
        AimMode = Option
    end
})

MainTab:CreateSlider({
    Name = "FOV Radius",
    Range = {50, 300},
    Increment = 5,
    Suffix = "px",
    CurrentValue = 130,
    Flag = "fov_radius",
    Callback = function(Value)
        FOVRadius = Value
        FOVCircle.Radius = Value
    end
})

MainTab:CreateSlider({
    Name = "Smoothness",
    Range = {0.01, 1.0},
    Increment = 0.01,
    Suffix = "",
    CurrentValue = 0.12,
    Flag = "smoothness",
    Callback = function(Value)
        Smoothness = Value
    end
})

-- ESP Tab
local espSection = ESPTab:CreateSection("ESP Controls")

ESPTab:CreateToggle({
    Name = "Enable ESP Boxes",
    CurrentValue = true,
    Flag = "esp_enabled",
    Callback = function(Value)
        ESPEnabled = Value
        if not Value then
            for _, box in pairs(ESPBoxes) do
                box.Visible = false
            end
        end
    end
})

ESPTab:CreateSlider({
    Name = "ESP Box Color (Red)",
    Range = {0, 255},
    Increment = 5,
    Suffix = "",
    CurrentValue = 255,
    Flag = "esp_color_r",
    Callback = function(Value)
        for _, box in pairs(ESPBoxes) do
            box.Color = Color3.fromRGB(Value, 50, 50)
        end
    end
})

ESPTab:CreateSlider({
    Name = "ESP Box Transparency",
    Range = {0, 1},
    Increment = 0.05,
    Suffix = "",
    CurrentValue = 0.5,
    Flag = "esp_transparency",
    Callback = function(Value)
        for _, box in pairs(ESPBoxes) do
            box.Transparency = Value
        end
    end
})

-- Checks Tab
local checksSection = ChecksTab:CreateSection("Target Checks")

ChecksTab:CreateToggle({
    Name = "Wall Check",
    CurrentValue = false,
    Flag = "wall_check",
    Callback = function(Value)
        WallCheck = Value
    end
})

-- Settings Tab
local infoSection = SettingsTab:CreateSection("Info")
SettingsTab:CreateLabel("Made by saasfd")
SettingsTab:CreateLabel("Knife Duels Aimbot + ESP")
SettingsTab:CreateLabel("Version 1.0")

-- Rayfield Bildirimi
Rayfield:Notify({
    Title = "Knife Duels Loaded",
    Content = "by saasfd | Aimbot + ESP ready",
    Duration = 4,
})