-- ============================================================
--  HUSH ESP — Main Script
--  Game: HUSH: They can hear. (BETA)
--  Place: 133927229860262
--  Open source — no keys, no owners, no credits
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- ===== Settings =====
local Settings = {
    ESP_Players = true,
    ESP_Monsters = true,
    ESP_Loot = true,
    AutoLoot = false,
    AutoLootRadius = 50,
    SpeedHack = false,
    WalkSpeed = 50,
    NoSound = false,
    AutoSell = false,
    InfiniteStamina = false,
}

-- ===== ESP =====
local ESPObjects = {}

local function createBillboard(parent, text, color)
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 100, 0, 30)
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.AlwaysOnTop = true
    bb.Parent = parent
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = color
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.GothamBold
    label.TextSize = 12
    label.Parent = bb
    return bb
end

local function addESP(obj, text, color)
    if ESPObjects[obj] then return end
    local bb = createBillboard(obj, text, color)
    ESPObjects[obj] = bb
end

local function removeESP(obj)
    if ESPObjects[obj] then
        ESPObjects[obj]:Destroy()
        ESPObjects[obj] = nil
    end
end

-- ===== Loot containers detection =====
local LootKeywords = {"crate", "lockbox", "loot", "chest", "box", "container", "barrel", "supply"}

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
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
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
        -- try to trigger proximity prompt or click detector
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

-- ===== Speed hack =====
local function applySpeed()
    local char = LocalPlayer.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.WalkSpeed = Settings.SpeedHack and Settings.WalkSpeed or 16
    end
end

-- ===== No sound (mute footsteps) =====
local function applyNoSound()
    local char = LocalPlayer.Character
    if not char then return end
    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("Sound") then
            desc.Volume = Settings.NoSound and 0 or 1
        end
    end
end

-- ===== Monster detection =====
local MonsterKeywords = {"monster", "creature", "enemy", "hunter", "stalker", "beast"}

local function isMonster(obj)
    if not obj:IsA("Model") then return false end
    local name = obj.Name:lower()
    for _, kw in ipairs(MonsterKeywords) do
        if name:find(kw) then return true end
    end
    -- check for humanoid without player
    local hum = obj:FindFirstChildOfClass("Humanoid")
    if hum and not Players:GetPlayerFromCharacter(obj) then
        return true
    end
    return false
end

-- ===== Main loop =====
RunService.Heartbeat:Connect(function()
    -- Update ESP
    if Settings.ESP_Players then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                addESP(p.Character.HumanoidRootPart, p.Name, Color3.fromRGB(0, 255, 0))
            end
        end
    end

    if Settings.ESP_Monsters then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isMonster(obj) and obj:FindFirstChild("HumanoidRootPart") then
                addESP(obj.HumanoidRootPart, "MONSTER", Color3.fromRGB(255, 0, 0))
            end
        end
    end

    if Settings.ESP_Loot then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if isLootContainer(obj) then
                local target = obj:IsA("Model") and obj:FindFirstChildWhichIsA("BasePart") or obj
                if target then
                    addESP(target, "LOOT", Color3.fromRGB(255, 255, 0))
                end
            end
        end
    end

    -- Auto-loot
    if Settings.AutoLoot then
        autoLoot()
    end

    -- Speed
    applySpeed()

    -- Infinite stamina
    if Settings.InfiniteStamina then
        infiniteStamina()
    end
end)

-- ===== Noclip =====
local NoclipEnabled = false
local NoclipConn
local function toggleNoclip()
    NoclipEnabled = not NoclipEnabled
    if NoclipEnabled then
        NoclipConn = RunService.Stepped:Connect(function()
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
    else
        if NoclipConn then NoclipConn:Disconnect() end
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end
    end
    print("[HUSHESP] Noclip:", NoclipEnabled)
end

-- ===== Teleport to nearest exit =====
local ExitKeywords = {"exit", "door", "gate", "escape", "sewer", "manhole"}
local function getNearestExit()
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("HumanoidRootPart") then return nil end
    local hrp = char.HumanoidRootPart
    local nearest, nearestDist = nil, math.huge
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local name = obj.Name:lower()
            for _, kw in ipairs(ExitKeywords) do
                if name:find(kw) then
                    local pos = obj:IsA("Model") and obj:GetPivot().Position or obj.Position
                    local dist = (pos - hrp.Position).Magnitude
                    if dist < nearestDist then
                        nearestDist = dist
                        nearest = obj
                    end
                    break
                end
            end
        end
    end
    return nearest, nearestDist
end

local function teleportToExit()
    local exit, dist = getNearestExit()
    if exit then
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local pos = exit:IsA("Model") and exit:GetPivot().Position or exit.Position
            char.HumanoidRootPart.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
            print("[HUSHESP] Teleported to exit")
        end
    else
        print("[HUSHESP] No exit found")
    end
end

-- ===== Infinite stamina (if game uses stamina) =====
local function infiniteStamina()
    local char = LocalPlayer.Character
    if not char then return end
    for _, v in ipairs(char:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") then
            local name = v.Name:lower()
            if name:find("stamina") or name:find("energy") or name:find("breath") then
                v.Value = 100
            end
        end
    end
end

-- ===== Keybinds =====
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.L then
        Settings.AutoLoot = not Settings.AutoLoot
        print("[HUSHESP] AutoLoot:", Settings.AutoLoot)
    elseif input.KeyCode == Enum.KeyCode.M then
        Settings.NoSound = not Settings.NoSound
        print("[HUSHESP] NoSound:", Settings.NoSound)
    elseif input.KeyCode == Enum.KeyCode.K then
        Settings.SpeedHack = not Settings.SpeedHack
        print("[HUSHESP] SpeedHack:", Settings.SpeedHack)
    elseif input.KeyCode == Enum.KeyCode.N then
        toggleNoclip()
    elseif input.KeyCode == Enum.KeyCode.E then
        teleportToExit()
    elseif input.KeyCode == Enum.KeyCode.S then
        Settings.InfiniteStamina = not (Settings.InfiniteStamina or false)
        print("[HUSHESP] InfiniteStamina:", Settings.InfiniteStamina)
    end
end)

-- ===== Character respawn =====
LocalPlayer.CharacterAdded:Connect(function(char)
    task.wait(1)
    applySpeed()
    applyNoSound()
end)

print("[HUSHESP] ready")
print("[HUSHESP] L=AutoLoot | M=NoSound | K=SpeedHack | N=Noclip | E=ExitTP | S=Stamina")
