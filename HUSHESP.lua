-- ============================================================
--  HUSH ESP — Main Script (starter baseplate)
--  Game: HUSH: They can hear. (BETA)
--  Place: 133927229860262
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

print("[HUSHESP] loaded")

-- Starter: ESP skeleton
local function createESP(player)
    -- placeholder
end

for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        createESP(p)
    end
end

Players.PlayerAdded:Connect(function(p)
    createESP(p)
end)

print("[HUSHESP] ready")
