-- ============================================================
--  HUSH ESP — LOADER
--
--  ОДНА СТРОКА ДЛЯ ЗАПУСКА:
--  loadstring(game:HttpGet("https://raw.githubusercontent.com/blegbot1/HUSHESP/main/HUSHESP.lua",true))()
-- ============================================================

local URL = "https://raw.githubusercontent.com/blegbot1/HUSHESP/main/HUSHESP.lua"

local g = getgenv()
local now = os.clock()
if g.HE_LOADED_AT and (now - g.HE_LOADED_AT) < 5 then
    warn("[HE] только что запущен, подожди 5 сек")
    return
end
g.HE_LOADED_AT = now

print("[HE] загрузка:", URL)

local ok, err = pcall(function()
    local src = game:HttpGet(URL, true)
    if type(src) ~= "string" or #src < 100 then
        error("пустой или битый ответ")
    end
    local chunk = loadstring(src, "HUSHESP")
    if not chunk then error("loadstring вернул nil — синтаксис сломан") end
    chunk()
end)

if not ok then
    g.HE_LOADED_AT = nil
    warn("[HE] ошибка загрузки:", err)
    error("[HE] не удалось загрузить скрипт: " .. tostring(err))
end

print("[HE] готово")
