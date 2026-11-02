print("HUSH DIAG START")
warn("HUSH DIAG WARN")
local ok, err = pcall(function()
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    print("Player:", p.Name)
    local c = p.Character
    print("Character:", c and c.Name or "nil")
end)
if not ok then warn("ERROR:", err) end
print("HUSH DIAG END")