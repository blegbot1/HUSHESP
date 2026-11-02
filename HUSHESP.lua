-- ============================================================
--  HUSH ESP — Main Script (Rayfield UI)
--  Game: HUSH: They can hear. (BETA)
--  Place: 133927229860262
--  Open source — no keys, no owners, no credits
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ===== Rayfield =====
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "HUSH ESP",
    LoadingTitle = "HUSH ESP",
    LoadingSubtitle = "Open Source",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "HUSHESP",
        FileName = "Config"
    },
    Discord = { Enabled = false },
    KeySystem = false,
})

-- ===== Settings =====
local Settings = {
    ESP_Players = true,
    ESP_Monsters = true,
    ESP_Loot = true,
    Chams_Players = true,
    Chams_Monsters = true,
    Chams_Loot = true,
    ESP_Radius = 300,
    ShowDistance = true,
    ShowHealth = true,
    AutoLoot = false,
    AutoLootRadius = 50,
    SpeedHack = false,
    WalkSpeed = 50,
    NoSound = false,
    Noclip = false,
    InfiniteStamina = false,
    Fullbright = false,
}

-- ===== Original lighting values =====
local OrigLighting = {
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Brightness = Lighting.Brightness,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
}

-- ===== ESP Storage =====
local ESPObjects = {}

local function cleanupESP(target)
    if ESPObjects[target] then
        if ESPObjects[target].highlight then ESPObjects[target].highlight:Destroy() end
        if ESPObjects[target].billboard then ESPObjects[target].billboard:Destroy() end
        ESPObjects[target] = nil
    end
end

local function createHighlight(parent, fillColor, outlineColor)
    local hl = Instance.new("Highlight")
    hl.FillColor = fillColor
    hl.OutlineColor = outlineColor
    hl.FillTransparency = 0.5
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Parent = parent
    return hl
end

local function createBillboard(parent, text, color)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 120, 0, 40)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.TextStrokeColor3 = Color3.new(0, 0, 0)
    label.Font = Enum.Font.GothamBold
    label.TextSize = 13
    label.Parent = bb
    return bb, label
end

local function addESP(target, text, fillColor, outlineColor, textColor, chamsEnabled)
    if ESPObjects[target] then
        if ESPObjects[target].label then
            ESPObjects[target].label.Text = text
        end
        if ESPObjects[target].highlight then
            ESPObjects[target].highlight.Enabled = chamsEnabled ~= false
        end
        return
    end
    local hl = createHighlight(target, fillColor, outlineColor)
    hl.Enabled = chamsEnabled ~= false
    local bb, label = createBillboard(target, text, textColor)
    ESPObjects[target] = { highlight = hl, billboard = bb, label = label }
end

-- ===== Loot containers =====
local LootKeywords = {"crate", "lockbox", "loot", "chest", "box", "container", "barrel", "supply", "cache", "stash"}

local function isLootContainer(obj)
    if not obj:IsA("BasePart") and not obj:IsA("Model") then return false end
    local name = obj.Name:lower()
    for _, kw in ipairs(LootKeywords) do
        if name:find(kw) then return true end
    end
    return false
end

local function getNearestLootContainer()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil, math.huge end
    local hrp = char.HumanoidRootPart
    local nearest, nearestDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if isLootContainer(obj) then
            local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
            local dist = (pos - hrp.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = obj
            end
        end
    end
    return nearest, nearestDist
end

-- ===== Auto-loot =====
local function autoLoot()
    if not Settings.AutoLoot then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return end
    local hrp = char.HumanoidRootPart
    local container, dist = getNearestLootContainer()
    if container and dist and dist <= Settings.AutoLootRadius then
        local pos = container:IsA("Model") and container:GetPivot().Position or container.Position
        hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        for _, desc in ipairs(container:GetDescendants()) do
            if desc:IsA("ProximityPrompt") then
                desc:InputHoldBegin()
                task.wait(0.1)
                desc:InputHoldEnd()
            elseif desc:IsA("ClickDetector") then
                fireclickdetector(desc)
            end
        end
    end
end

-- ===== Speed =====
local function applySpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = Settings.SpeedHack and Settings.WalkSpeed or 16
    end
end

-- ===== No sound =====
local function applyNoSound()
    local char = LocalPlayer.Character
    if not char then return end
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("Sound") then
            desc.Volume = Settings.NoSound and 0 or 1
        end
    end
end

-- ===== Noclip =====
local NoclipConn
local function toggleNoclip()
    Settings.Noclip = not Settings.Noclip
    if Settings.Noclip then
        NoclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then part.CanCollide = false end
                end
            end
        end)
    else
        if NoclipConn then NoclipConn:Disconnect() end
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then part.CanCollide = true end
            end
        end
    end
end

-- ===== Infinite stamina =====
local function infiniteStamina()
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local name = v.Name:lower()
            if name:find("stamina") or name:find("energy") or name:find("breath") or name:find("sprint") then
                v.Value = 100
            end
        end
    end
    -- also check attributes
    for _, attr in ipairs({"Stamina", "stamina", "Energy", "energy", "Sprint", "sprint"}) do
        local val = char:GetAttribute(attr)
        if val ~= nil then
            char:SetAttribute(attr, 100)
        end
    end
end

-- ===== Fullbright =====
local function applyFullbright()
    if Settings.Fullbright then
        Lighting.Ambient = Color3.new(1, 1, 1)
        Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
        Lighting.Brightness = 2
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
    else
        Lighting.Ambient = OrigLighting.Ambient
        Lighting.OutdoorAmbient = OrigLighting.OutdoorAmbient
        Lighting.Brightness = OrigLighting.Brightness
        Lighting.FogEnd = OrigLighting.FogEnd
        Lighting.GlobalShadows = OrigLighting.GlobalShadows
    end
end

-- ===== Monster detection =====
local MonsterKeywords = {"monster", "creature", "enemy", "hunter", "stalker", "beast", "zombie"}

local function isMonster(obj)
    if not obj:IsA("Model") then return false end
    local name = obj.Name:lower()
    for _, kw in ipairs(MonsterKeywords) do
        if name:find(kw) then return true end
    end
    local hum = obj:FindFirstChildOfClass("Humanoid")
    if hum and not Players:GetPlayerFromCharacter(obj) then
        return true
    end
    return false
end

-- ===== Main loop =====
RunService.Heartbeat:Connect(function()
    -- Clean up destroyed ESP targets
    for target, data in pairs(ESPObjects) do
        if not target or not target.Parent then
            cleanupESP(target)
        end
    end

    local charPos = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character.HumanoidRootPart.Position

    -- Players ESP
    if Settings.ESP_Players then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local hrp = p.Character.HumanoidRootPart
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local text = p.Name
                if Settings.ShowDistance and charPos then
                    text = text .. " [" .. math.floor((hrp.Position - charPos).Magnitude) .. "m]"
                end
                if Settings.ShowHealth and hum then
                    text = text .. " HP:" .. math.floor(hum.Health)
                end
                addESP(hrp, text, Color3.fromRGB(0, 255, 100), Color3.fromRGB(0, 200, 80), Color3.fromRGB(0, 255, 100), Settings.Chams_Players)
            end
        end
    else
        -- remove player ESP
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                cleanupESP(p.Character.HumanoidRootPart)
            end
        end
    end

    -- Monsters ESP
    if Settings.ESP_Monsters then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isMonster(obj) and obj:FindFirstChild("HumanoidRootPart") then
                local hrp = obj.HumanoidRootPart
                if charPos and (hrp.Position - charPos).Magnitude > Settings.ESP_Radius then
                    cleanupESP(hrp)
                else
                    local text = "MONSTER"
                    if Settings.ShowDistance and charPos then
                        text = text .. " [" .. math.floor((hrp.Position - charPos).Magnitude) .. "m]"
                    end
                    addESP(hrp, text, Color3.fromRGB(255, 50, 50), Color3.fromRGB(200, 0, 0), Color3.fromRGB(255, 80, 80), Settings.Chams_Monsters)
                end
            end
        end
    else
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isMonster(obj) and obj:FindFirstChild("HumanoidRootPart") then
                cleanupESP(obj.HumanoidRootPart)
            end
        end
    end

    -- Loot ESP
    if Settings.ESP_Loot then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isLootContainer(obj) then
                local target = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
                if target and target:IsA("BasePart") then
                    if charPos and (target.Position - charPos).Magnitude > Settings.ESP_Radius then
                        cleanupESP(target)
                    else
                        local text = "LOOT"
                        if Settings.ShowDistance and charPos then
                            text = text .. " [" .. math.floor((target.Position - charPos).Magnitude) .. "m]"
                        end
                        addESP(target, text, Color3.fromRGB(255, 220, 0), Color3.fromRGB(200, 180, 0), Color3.fromRGB(255, 240, 100), Settings.Chams_Loot)
                    end
                end
            end
        end
    else
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isLootContainer(obj) then
                local target = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
                if target then cleanupESP(target) end
            end
        end
    end

    -- Auto-loot
    autoLoot()

    -- Speed (every frame to override game resets)
    applySpeed()

    -- No sound
    if Settings.NoSound then
        applyNoSound()
    end

    -- Infinite stamina
    if Settings.InfiniteStamina then
        infiniteStamina()
    end

    -- Fullbright
    applyFullbright()
end)

-- ===== Rayfield UI =====
local MainTab = Window:CreateTab("ESP", 4483362458)
MainTab:CreateToggle({ Name = "Player ESP", CurrentValue = true, Flag = "ESP_Players", Callback = function(v) Settings.ESP_Players = v end })
MainTab:CreateToggle({ Name = "Player Chams", CurrentValue = true, Flag = "Chams_Players", Callback = function(v) Settings.Chams_Players = v end })
MainTab:CreateToggle({ Name = "Monster ESP", CurrentValue = true, Flag = "ESP_Monsters", Callback = function(v) Settings.ESP_Monsters = v end })
MainTab:CreateToggle({ Name = "Monster Chams", CurrentValue = true, Flag = "Chams_Monsters", Callback = function(v) Settings.Chams_Monsters = v end })
MainTab:CreateToggle({ Name = "Loot ESP", CurrentValue = true, Flag = "ESP_Loot", Callback = function(v) Settings.ESP_Loot = v end })
MainTab:CreateToggle({ Name = "Loot Chams", CurrentValue = true, Flag = "Chams_Loot", Callback = function(v) Settings.Chams_Loot = v end })
MainTab:CreateSlider({ Name = "ESP Radius", Range = {50, 500}, Increment = 10, Suffix = "studs", CurrentValue = 300, Flag = "ESP_Radius", Callback = function(v) Settings.ESP_Radius = v end })
MainTab:CreateToggle({ Name = "Show Distance", CurrentValue = true, Flag = "ShowDistance", Callback = function(v) Settings.ShowDistance = v end })
MainTab:CreateToggle({ Name = "Show Health", CurrentValue = true, Flag = "ShowHealth", Callback = function(v) Settings.ShowHealth = v end })

local LootTab = Window:CreateTab("Loot", 4483362458)
LootTab:CreateToggle({ Name = "Auto Loot", CurrentValue = false, Flag = "AutoLoot", Callback = function(v) Settings.AutoLoot = v end })
LootTab:CreateSlider({ Name = "Loot Radius", Range = {10, 200}, Increment = 5, Suffix = "studs", CurrentValue = 50, Flag = "AutoLootRadius", Callback = function(v) Settings.AutoLootRadius = v end })
LootTab:CreateButton({ Name = "Teleport to Nearest Loot", Callback = function()
    local container, dist = getNearestLootContainer()
    if container then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = container:IsA("Model") and container:GetPivot().Position or container.Position
            char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
        end
    end
end })

local MoveTab = Window:CreateTab("Movement", 4483362458)
MoveTab:CreateToggle({ Name = "Speed Hack", CurrentValue = false, Flag = "SpeedHack", Callback = function(v) Settings.SpeedHack = v end })
MoveTab:CreateSlider({ Name = "Walk Speed", Range = {16, 200}, Increment = 1, Suffix = "ws", CurrentValue = 50, Flag = "WalkSpeed", Callback = function(v) Settings.WalkSpeed = v end })
MoveTab:CreateToggle({ Name = "Noclip", CurrentValue = false, Flag = "Noclip", Callback = function(v)
    if v ~= Settings.Noclip then toggleNoclip() end
end })
MoveTab:CreateToggle({ Name = "No Sound (mute footsteps)", CurrentValue = false, Flag = "NoSound", Callback = function(v) Settings.NoSound = v end })
MoveTab:CreateToggle({ Name = "Infinite Stamina", CurrentValue = false, Flag = "InfiniteStamina", Callback = function(v) Settings.InfiniteStamina = v end })
MoveTab:CreateToggle({ Name = "Fullbright", CurrentValue = false, Flag = "Fullbright", Callback = function(v) Settings.Fullbright = v; applyFullbright() end })

local VisualTab = Window:CreateTab("Visual", 4483362458)
VisualTab:CreateButton({ Name = "Teleport to Nearest Exit", Callback = teleportToExit })

-- ===== Character respawn =====
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    applySpeed()
    applyNoSound()
end)

print("[HUSHESP] ready — Rayfield loaded")
Rayfield:Notify({ Title = "HUSH ESP", Content = "Loaded successfully", Duration = 3 })