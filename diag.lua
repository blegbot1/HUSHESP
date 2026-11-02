-- HUSHESP Diagnostic — запусти в инжекторе
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local p = Players.LocalPlayer
local c = p.Character or p.CharacterAdded:Wait()
task.wait(2)

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
print("=== LIGHTING ===")
print("Ambient:", Lighting.Ambient)
print("OutdoorAmbient:", Lighting.OutdoorAmbient)
print("Brightness:", Lighting.Brightness)
print("FogEnd:", Lighting.FogEnd)
print("GlobalShadows:", Lighting.GlobalShadows)
print("=== HUMANOID ===")
local h = c:FindFirstChildOfClass("Humanoid")
if h then print("WalkSpeed:", h.WalkSpeed, "JumpPower:", h.JumpPower, "MaxHealth:", h.MaxHealth) end
print("=== DONE ===")