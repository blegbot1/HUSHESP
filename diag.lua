print("HUSH DIAG START")
warn("HUSH DIAG WARN")
if not game.Players.LocalPlayer.Character then game.Players.LocalPlayer.CharacterAdded:Wait() end
task.wait(2)
local p = game.Players.LocalPlayer
local c = p.Character
print("Player:", p.Name)
print("Character:", c and c.Name or "nil")
if c then
    print("=== VALUES ===")
    for _,v in ipairs(c:GetDescendants()) do
        if v:IsA("NumberValue") or v:IsA("IntValue") or v:IsA("BoolValue") or v:IsA("StringValue") then
            print(v:GetFullName(), "=", v.Value)
        end
    end
    print("=== CHAR ATTRIBUTES ===")
    for k,v in pairs(c:GetAttributes()) do print(k, "=", v) end
    print("=== PLAYER ATTRIBUTES ===")
    for k,v in pairs(p:GetAttributes()) do print(k, "=", v) end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h then print("WalkSpeed:", h.WalkSpeed, "JumpPower:", h.JumpPower, "MaxHealth:", h.MaxHealth) end
    print("=== DONE ===")
end