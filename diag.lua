print("HUSH DIAG START")
if not game.Players.LocalPlayer.Character then game.Players.LocalPlayer.CharacterAdded:Wait() end
task.wait(2)
local p = game.Players.LocalPlayer
local c = p.Character
print("Player:", p.Name)
print("Character:", c and c.Name or "nil")
print("Descendants count:", c and #c:GetDescendants() or 0)
local h = c and c:FindFirstChildOfClass("Humanoid")
print("Humanoid:", h and h.Name or "nil")
if h then
    print("WalkSpeed:", h.WalkSpeed)
    print("JumpPower:", h.JumpPower)
end
print("Attributes:")
for k,v in pairs(c:GetAttributes()) do print("  ", k, v) end
print("HUSH DIAG END")