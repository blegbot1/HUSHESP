-- HUSHESP Diagnostic — запусти в инжекторе, результат в файл
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local p = Players.LocalPlayer
local c = p.Character or p.CharacterAdded:Wait()
task.wait(3)

local lines = {}
local function log(s) table.insert(lines, tostring(s)) end

log("=== VALUES ===")
for _,v in ipairs(c:GetDescendants()) do
    if v:IsA("NumberValue") or v:IsA("IntValue") or v:IsA("BoolValue") or v:IsA("StringValue") then
        log(v:GetFullName() .. " = " .. tostring(v.Value))
    end
end
log("=== CHAR ATTRIBUTES ===")
for k,v in pairs(c:GetAttributes()) do log(k .. " = " .. tostring(v)) end
log("=== PLAYER ATTRIBUTES ===")
for k,v in pairs(p:GetAttributes()) do log(k .. " = " .. tostring(v)) end
log("=== LIGHTING ===")
log("Ambient: " .. tostring(Lighting.Ambient))
log("OutdoorAmbient: " .. tostring(Lighting.OutdoorAmbient))
log("Brightness: " .. tostring(Lighting.Brightness))
log("FogEnd: " .. tostring(Lighting.FogEnd))
log("GlobalShadows: " .. tostring(Lighting.GlobalShadows))
log("=== HUMANOID ===")
local h = c:FindFirstChildOfClass("Humanoid")
if h then log("WalkSpeed: " .. h.WalkSpeed .. " JumpPower: " .. h.JumpPower .. " MaxHealth: " .. h.MaxHealth) end
log("=== DONE ===")

local result = table.concat(lines, "\n")
pcall(function() writefile("hush_diag.txt", result) end)
warn(result)