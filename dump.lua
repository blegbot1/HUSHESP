-- HUSHESP Full Game Dumper — копирует в буфер обмена
local ok, err = pcall(function()
    local Players = game:GetService("Players")
    local p = Players.LocalPlayer
    if not p.Character then p.CharacterAdded:Wait() end
    task.wait(2)

    local lines = {}
    local function log(s) table.insert(lines, s) end

    local function dump(obj, depth)
        depth = depth or 0
        if depth > 5 then return end
        local indent = string.rep("  ", depth)
        local info = obj.ClassName .. " | " .. obj.Name
        if obj:IsA("ValueBase") then info = info .. " = " .. tostring(obj.Value) end
        if obj:IsA("BasePart") then info = info .. " | Pos:" .. tostring(obj.Position) .. " CanCollide:" .. tostring(obj.CanCollide) end
        if obj:IsA("Humanoid") then info = info .. " | WS:" .. obj.WalkSpeed .. " JP:" .. obj.JumpPower .. " HP:" .. obj.Health .. "/" .. obj.MaxHealth end
        log(indent .. info)
        for _, child in ipairs(obj:GetChildren()) do
            dump(child, depth + 1)
        end
    end

    for _, svc in ipairs({"Workspace", "Players", "ReplicatedStorage", "Lighting"}) do
        local s = game:GetService(svc)
        if s then
            log("===== " .. svc .. " =====")
            dump(s, 0)
        end
    end

    log("===== PLAYER ATTRIBUTES =====")
    for _, pl in ipairs(Players:GetPlayers()) do
        log(pl.Name)
        for k, v in pairs(pl:GetAttributes()) do
            log("  " .. k .. " = " .. tostring(v))
        end
        if pl.Character then
            log("  CHAR ATTRIBUTES:")
            for k, v in pairs(pl.Character:GetAttributes()) do
                log("    " .. k .. " = " .. tostring(v))
            end
        end
    end
    log("===== DONE =====")

    local result = table.concat(lines, "\n")
    if setclipboard then
        setclipboard(result)
        print("COPIED TO CLIPBOARD! Lines: " .. #lines)
    else
        print(result)
    end
end)
if not ok then warn("DUMP ERROR: " .. tostring(err)) end