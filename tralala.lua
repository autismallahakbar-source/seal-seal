local PlayerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

local followGui = Instance.new("ScreenGui")
followGui.Name = "SealDevFollow"
followGui.ResetOnSpawn = false
followGui.IgnoreGuiInset = true
followGui.Parent = PlayerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.new(1, 0, 1, 0)
bg.BackgroundColor3 = Color3.fromRGB(15, 15, 20)
bg.BorderSizePixel = 0
bg.Parent = followGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 80)
title.Position = UDim2.new(0, 0, 0.35, 0)
title.BackgroundTransparency = 1
title.Text = "SealDev"
title.TextColor3 = Color3.fromRGB(0, 200, 255)
title.Font = Enum.Font.GothamBlack
title.TextScaled = true
title.Parent = bg

local subtitle = Instance.new("TextLabel")
subtitle.Size = UDim2.new(1, 0, 0, 60)
subtitle.Position = UDim2.new(0, 0, 0.45, 0)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Follow to Tulen228Roblox"
subtitle.TextColor3 = Color3.fromRGB(255, 255, 255)
subtitle.Font = Enum.Font.GothamBold
subtitle.TextScaled = true
subtitle.Parent = bg

local keyHint = Instance.new("TextLabel")
keyHint.Size = UDim2.new(1, 0, 0, 40)
keyHint.Position = UDim2.new(0, 0, 0.55, 0)
keyHint.BackgroundTransparency = 1
keyHint.Text = "Enter key: 1234"
keyHint.TextColor3 = Color3.fromRGB(180, 180, 180)
keyHint.Font = Enum.Font.Gotham
keyHint.TextScaled = true
keyHint.Parent = bg

task.spawn(function()
    task.wait(1.5)
    local TweenService = game:GetService("TweenService")
    local fadeTime = 1.5
    TweenService:Create(bg, TweenInfo.new(fadeTime), { BackgroundTransparency = 1 }):Play()
    for _, obj in ipairs(bg:GetDescendants()) do
        if obj:IsA("TextLabel") then
            TweenService:Create(obj, TweenInfo.new(fadeTime), { TextTransparency = 1 }):Play()
        end
    end
    task.wait(fadeTime)
    followGui:Destroy()
end)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "One Tap Script | by SealDev",
    LoadingTitle = "Loading SealDev Hub...",
    LoadingSubtitle = "Follow to Tulen228Roblox",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "SealDevHub",
        FileName = "Config"
    },
    KeySystem = true,
    KeySettings = {
        Title = "SealDev | Key System",
        Subtitle = "Follow to Tulen228Roblox",
        Note = "Key: 1234",
        FileName = "SealDevKey",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"1234"}
    }
})

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace        = game:GetService("Workspace")
local Camera           = Workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

local Settings = {
    AimbotEnabled    = false,
    FOVRadius        = 100,
    AimPart          = "Head",
    Smoothness       = 0.4,
    TargetNPC        = true,
    WallCheck        = false,
    ESPPlayers       = true,
    ESPNPC           = true,
    ESPColor         = Color3.fromRGB(255, 50, 50),
    SpinEnabled      = false,
    SpinSpeed        = 10,
    FlyEnabled       = false,
    FlySpeed         = 50,
    NoclipEnabled    = false,
    SpeedEnabled     = false,
    SpeedValue       = 100,
    JumpPowerEnabled = false,
    JumpPowerValue   = 100,
}

local fovCircle = Drawing.new("Circle")
fovCircle.Visible   = false
fovCircle.Radius    = Settings.FOVRadius
fovCircle.Thickness = 1
fovCircle.Color     = Color3.fromRGB(0, 255, 255)
fovCircle.Filled    = false

local espBoxes = {}

local function createESPBox(char)
    if espBoxes[char] then return end
    local box = Drawing.new("Square")
    box.Visible      = true
    box.Color        = Settings.ESPColor
    box.Thickness    = 1
    box.Filled       = false
    box.Transparency = 1
    espBoxes[char]   = box
end

local function removeESPBox(char)
    if espBoxes[char] then
        espBoxes[char]:Remove()
        espBoxes[char] = nil
    end
end

local function clearAllESP()
    for char, box in pairs(espBoxes) do
        box:Remove()
    end
    espBoxes = {}
end

local targetCache = {}
local lastCacheUpdate = 0
local CACHE_INTERVAL = 0.5

local function isValidTarget(hum)
    if not hum or not hum.Parent then return false end
    local char = hum.Parent
    if char == LocalPlayer.Character then return false end
    if hum.Health <= 0 then return false end
    if not char:FindFirstChild("HumanoidRootPart") then return false end
    if not char:FindFirstChild("Head") then return false end
    return true, char
end

local function rebuildCache()
    local newCache = {}

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if isValidTarget(hum) then
                table.insert(newCache, { char = player.Character, hum = hum, isNPC = false })
            end
        end
    end

    if Settings.TargetNPC then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Humanoid") then
                local char = obj.Parent
                if char and char:IsA("Model") and not Players:GetPlayerFromCharacter(char) then
                    if isValidTarget(obj) then
                        table.insert(newCache, { char = char, hum = obj, isNPC = true })
                    end
                end
            end
        end
    end

    targetCache = newCache
end

local function getCache()
    local now = tick()
    if now - lastCacheUpdate >= CACHE_INTERVAL then
        lastCacheUpdate = now
        rebuildCache()
    end
    return targetCache
end

local function hasLineOfSight(targetPart)
    local myChar = LocalPlayer.Character
    if not myChar then return false end
    local myHead = myChar:FindFirstChild("Head")
    if not myHead then return false end

    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = {myChar, targetPart.Parent}

    local dir    = targetPart.Position - myHead.Position
    local result = Workspace:Raycast(myHead.Position, dir, rayParams)
    return result == nil
end

local function getClosestTarget()
    local closest      = nil
    local shortestDist = Settings.FOVRadius
    local center       = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    for _, t in ipairs(getCache()) do
        local part = t.char:FindFirstChild(Settings.AimPart)
        if part then
            local skip = false
            if Settings.WallCheck and not hasLineOfSight(part) then
                skip = true
            end

            if not skip then
                local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
                if onScreen then
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local dist = (screenPos - center).Magnitude
                    if dist < shortestDist then
                        shortestDist = dist
                        closest = part
                    end
                end
            end
        end
    end
    return closest
end

local function updateESP()
    if not (Settings.ESPPlayers or Settings.ESPNPC) then
        clearAllESP()
        return
    end

    local activeChars = {}

    for _, t in ipairs(getCache()) do
        local char = t.char
        if (t.isNPC and Settings.ESPNPC) or (not t.isNPC and Settings.ESPPlayers) then
            activeChars[char] = true

            local root = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            if root and head then
                local topPos    = head.Position + Vector3.new(0, 0.5, 0)
                local bottomPos = root.Position - Vector3.new(0, 3, 0)

                local topPoint,    topOnScreen    = Camera:WorldToViewportPoint(topPos)
                local bottomPoint, bottomOnScreen = Camera:WorldToViewportPoint(bottomPos)

                if topOnScreen and bottomOnScreen then
                    local box = espBoxes[char]
                    if not box then
                        createESPBox(char)
                        box = espBoxes[char]
                    end

                    local height = math.abs(topPoint.Y - bottomPoint.Y)
                    local width  = height * 0.55
                    box.Size     = Vector2.new(width, height)
                    box.Position = Vector2.new(topPoint.X - width / 2, topPoint.Y)
                    box.Color    = Settings.ESPColor
                    box.Visible  = true
                else
                    local box = espBoxes[char]
                    if box then box.Visible = false end
                end
            end
        end
    end

    for char, box in pairs(espBoxes) do
        if not activeChars[char] then
            removeESPBox(char)
        end
    end
end

local spinMotor = nil

local function startSpin()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local old = hrp:FindFirstChild("SealDevSpinMotor")
    if old then old:Destroy() end

    spinMotor                 = Instance.new("BodyAngularVelocity")
    spinMotor.Name            = "SealDevSpinMotor"
    spinMotor.Parent          = hrp
    spinMotor.MaxTorque       = Vector3.new(0, math.huge, 0)
    spinMotor.P               = 10000
    spinMotor.AngularVelocity = Vector3.new(0, Settings.SpinSpeed * math.pi * 2, 0)
end

local function updateSpin()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    if not spinMotor or spinMotor.Parent ~= hrp then
        startSpin()
        return
    end

    spinMotor.AngularVelocity = Vector3.new(0, Settings.SpinSpeed * math.pi * 2, 0)
end

local function stopSpin()
    if spinMotor then
        spinMotor:Destroy()
        spinMotor = nil
    end
    local char = LocalPlayer.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local m = hrp:FindFirstChild("SealDevSpinMotor")
            if m then m:Destroy() end
            hrp.RotVelocity = Vector3.new(0, 0, 0)
        end
    end
end

local flyBodyVelocity = nil

local function startFly()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then humanoid.PlatformStand = true end

    if flyBodyVelocity then flyBodyVelocity:Destroy() end

    flyBodyVelocity          = Instance.new("BodyVelocity")
    flyBodyVelocity.Parent   = hrp
    flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    flyBodyVelocity.P        = 1250
end

local function stopFly()
    if flyBodyVelocity then
        flyBodyVelocity:Destroy()
        flyBodyVelocity = nil
    end
    local char = LocalPlayer.Character
    if char then
        local humanoid = char:FindFirstChild("Humanoid")
        if humanoid then humanoid.PlatformStand = false end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then hrp.Velocity = Vector3.new(0, 0, 0) end
    end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.E then
        Settings.AimbotEnabled = not Settings.AimbotEnabled
        Rayfield:Notify({
            Title    = "Aimbot",
            Content  = Settings.AimbotEnabled and "Enabled [E]" or "Disabled [E]",
            Duration = 2
        })
    end
end)

RunService.RenderStepped:Connect(function()
    if Settings.AimbotEnabled then
        fovCircle.Visible  = true
        fovCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    else
        fovCircle.Visible = false
    end

    if Settings.AimbotEnabled then
        local target = getClosestTarget()
        if target then
            local currentCF = Camera.CFrame
            local targetCF  = CFrame.new(currentCF.Position, target.Position)
            Camera.CFrame   = currentCF:Lerp(targetCF, Settings.Smoothness)
        end
    end

    updateESP()

    if Settings.SpinEnabled then
        updateSpin()
    end

    if Settings.FlyEnabled then
        local char = LocalPlayer.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                if not flyBodyVelocity or flyBodyVelocity.Parent ~= hrp then
                    startFly()
                end

                if flyBodyVelocity then
                    local camCF   = Camera.CFrame
                    local camLook = camCF.LookVector.Unit
                    local right   = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit

                    local move = Vector3.new(0, 0, 0)
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camLook end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - camLook end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - right end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + right end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.new(0, 1, 0) end

                    if move.Magnitude > 0 then move = move.Unit * Settings.FlySpeed end

                    hrp.Velocity    = Vector3.new(0, 0, 0)
                    hrp.RotVelocity = Vector3.new(0, 0, 0)
                    flyBodyVelocity.Velocity = move
                end
            end
        end
    end

    if Settings.NoclipEnabled then
        local char = LocalPlayer.Character
        if char then
            for _, part in pairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = false end
            end
        end
    end
end)

RunService.Stepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if Settings.SpeedEnabled then
        humanoid.WalkSpeed = Settings.SpeedValue
    end

    if Settings.JumpPowerEnabled then
        humanoid.UseJumpPower = true
        humanoid.JumpPower    = Settings.JumpPowerValue
    end
end)

local MainTab     = Window:CreateTab("Main", nil)
local ESPTab      = Window:CreateTab("ESP", nil)
local SpinTab     = Window:CreateTab("Spin", nil)
local MovementTab = Window:CreateTab("Movement", nil)

MainTab:CreateToggle({
    Name         = "Aimbot [E]",
    CurrentValue = false,
    Flag         = "AimbotEnabled",
    Callback     = function(Value) Settings.AimbotEnabled = Value end
})

MainTab:CreateToggle({
    Name         = "Aim at NPCs",
    CurrentValue = true,
    Flag         = "TargetNPC",
    Callback     = function(Value) Settings.TargetNPC = Value end
})

MainTab:CreateToggle({
    Name         = "Wall Check",
    CurrentValue = false,
    Flag         = "WallCheck",
    Callback     = function(Value) Settings.WallCheck = Value end
})

MainTab:CreateSlider({
    Name         = "FOV Radius",
    Range        = {20, 400},
    Increment    = 5,
    Suffix       = "px",
    CurrentValue = 100,
    Flag         = "FOVRadius",
    Callback     = function(Value)
        Settings.FOVRadius = Value
        fovCircle.Radius   = Value
    end
})

MainTab:CreateSlider({
    Name         = "Smoothness",
    Range        = {0.01, 1.0},
    Increment    = 0.01,
    Suffix       = "",
    CurrentValue = 0.4,
    Flag         = "Smoothness",
    Callback     = function(Value) Settings.Smoothness = Value end
})

ESPTab:CreateToggle({
    Name         = "ESP Players",
    CurrentValue = true,
    Flag         = "ESPPlayers",
    Callback     = function(Value) Settings.ESPPlayers = Value end
})

ESPTab:CreateToggle({
    Name         = "ESP NPCs",
    CurrentValue = true,
    Flag         = "ESPNPC",
    Callback     = function(Value) Settings.ESPNPC = Value end
})

SpinTab:CreateToggle({
    Name         = "Spin",
    CurrentValue = false,
    Flag         = "SpinEnabled",
    Callback     = function(Value)
        Settings.SpinEnabled = Value
        if Value then startSpin() else stopSpin() end
    end
})

SpinTab:CreateSlider({
    Name         = "Spin Speed",
    Range        = {1, 50},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 10,
    Flag         = "SpinSpeed",
    Callback     = function(Value) Settings.SpinSpeed = Value end
})

MovementTab:CreateToggle({
    Name         = "Fly",
    CurrentValue = false,
    Flag         = "FlyEnabled",
    Callback     = function(Value)
        Settings.FlyEnabled = Value
        if Value then startFly() else stopFly() end
    end
})

MovementTab:CreateSlider({
    Name         = "Fly Speed",
    Range        = {10, 200},
    Increment    = 5,
    CurrentValue = 50,
    Flag         = "FlySpeed",
    Callback     = function(Value) Settings.FlySpeed = Value end
})

MovementTab:CreateToggle({
    Name         = "Noclip",
    CurrentValue = false,
    Flag         = "NoclipEnabled",
    Callback     = function(Value)
        Settings.NoclipEnabled = Value
        if not Value then
            local char = LocalPlayer.Character
            if char then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = true end
                end
            end
        end
    end
})

MovementTab:CreateToggle({
    Name         = "Speed",
    CurrentValue = false,
    Flag         = "SpeedEnabled",
    Callback     = function(Value) Settings.SpeedEnabled = Value end
})

MovementTab:CreateSlider({
    Name         = "Speed Value",
    Range        = {16, 300},
    Increment    = 5,
    CurrentValue = 100,
    Flag         = "SpeedValue",
    Callback     = function(Value) Settings.SpeedValue = Value end
})

MovementTab:CreateToggle({
    Name         = "Jump Power",
    CurrentValue = false,
    Flag         = "JumpPowerEnabled",
    Callback     = function(Value) Settings.JumpPowerEnabled = Value end
})

MovementTab:CreateSlider({
    Name         = "Jump Power Value",
    Range        = {50, 300},
    Increment    = 10,
    CurrentValue = 100,
    Flag         = "JumpPowerValue",
    Callback     = function(Value) Settings.JumpPowerValue = Value end
})
