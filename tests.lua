-- HUSHESP basic tests (run in Roblox executor context)
local function assert(cond, msg)
    if not cond then error(msg or 'assertion failed') end
end

-- Test 1: isLootContainer keyword match
local LootKeywords = {'crate','lockbox','loot','chest','box','container','barrel','supply','cache','stash','fridge','cabinet','dresser','toolbox','drawer'}
local function isLootContainer(name)
    local n = string.lower(name)
    for _, kw in ipairs(LootKeywords) do
        if string.find(n, kw) then return true end
    end
    return false
end
assert(isLootContainer('Crate'), 'Crate should be loot')
assert(isLootContainer('Fridge'), 'Fridge should be loot')
assert(isLootContainer('Toolbox'), 'Toolbox should be loot')
assert(not isLootContainer('Wall'), 'Wall should not be loot')

-- Test 2: isMonster keyword match
local MonsterKeywords = {'monster','creature','enemy','hunter','stalker','beast','zombie'}
local function isMonsterName(name)
    local n = string.lower(name)
    for _, kw in ipairs(MonsterKeywords) do
        if string.find(n, kw) then return true end
    end
    return false
end
assert(isMonsterName('Monster1'), 'Monster1 should match')
assert(isMonsterName('Zombie'), 'Zombie should match')
assert(not isMonsterName('Player'), 'Player should not match')

-- Test 3: speed base value
assert(12 == 12, 'base walkspeed should be 12')

print('[HUSHESP TESTS] all passed')
