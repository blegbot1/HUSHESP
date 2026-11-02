-- HUSHESP Full Game Dumper — копирует структуру игры в консоль
local Players = game:GetService("Players")
local p = Players.LocalPlayer
if not p.Character then p.CharacterAdded:Wait() end
task.wait(2)

local function dump(obj, depth)
    depth = depth or 0
    if depth > 6 then return end
    local indent = string.rep("  ", depth)
    local info = obj.ClassName .. " | " .. obj.Name
    -- print value properties
    if obj:IsA("ValueBase") then info = info .. " = " .. tostring(obj.Value) end
    if obj:IsA("BasePart") then info = info .. " | Pos:" .. tostring(obj.Position) .. " CanCollide:" .. tostring(obj.CanCollide) end
    if obj:IsA("Humanoid") then info = info .. " | WS:" .. obj.WalkSpeed .. " JP:" .. obj.JumpPower .. " HP:" .. obj.Health .. "/" .. obj.MaxHealth end
    print(indent .. info)
    for _, child in ipairs(obj:GetChildren()) do
        dump(child, depth + 1)
    end
end

-- Dump services
for _, svc in ipairs({"Workspace", "Players", "ReplicatedStorage", "ServerStorage", "Lighting", "StarterGui", "StarterPack", "StarterPlayer"}) do
    local s = game:GetService(svc)
    if s then
        print("===== " .. svc .. " =====")
        dump(s, 0)
    end
end

-- Dump attributes of all players
print("===== PLAYER ATTRIBUTES =====")
for _, pl in ipairs(Players:GetPlayers()) do
    print(pl.Name)
    for k, v in pairs(pl:GetAttributes()) do
        print("  " .. k .. " = " .. tostring(v))
    end
    if pl.Character then
        print("  CHAR ATTRIBUTES:")
        for k, v in pairs(pl.Character:GetAttributes()) do
            print("    " .. k .. " = " .. tostring(v))
        end
    end
end

print("===== DONE =====")