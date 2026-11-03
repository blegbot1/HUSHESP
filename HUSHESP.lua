-- ============================================================
-- HUSH ESP — cleaner, readable version
-- ESP + чэмсы для игроков, монстров, лута (включая WorldFinds) и машин
-- Стамина, фуллбрит, скорость — в движении.
-- ============================================================

-- ─── Сервисы ───────────────────────────────────────────────
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')
local Lighting = game:GetService('Lighting')
local UserInputService = game:GetService('UserInputService')

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Ждём появления персонажа перед стартом
if not LocalPlayer.Character then
	LocalPlayer.CharacterAdded:Wait()
end
task.wait(2)

-- ─── Интерфейс (Rayfield) ──────────────────────────────────
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local VERSION = '2.20'
local Window = Rayfield:CreateWindow({
	Name = 'HUSH ESP v' .. VERSION,
	LoadingTitle = 'HUSH ESP',
	LoadingSubtitle = 'Open Source',
	ConfigurationSaving = {Enabled = true, FolderName = 'HUSHESP', FileName = 'Config'},
	Discord = {Enabled = false},
	KeySystem = false
})

-- ─── Настройки ─────────────────────────────────────────────
local Settings = {
	ESP_Players = true,
	ESP_Monsters = true,
	ESP_Loot = true,
	ESP_Cars = true,
	Chams_Players = true,
	Chams_Monsters = true,
	Chams_Loot = true,
	Chams_Cars = true,
	ShowDistance = true,
	ShowHealth = true,
	SpeedHack = false,
	WalkSpeed = 50,
	InfiniteStamina = false,
	Fullbright = false
}

-- ─── Исходный свет (для сброса при выключении фуллбрита) ────
local OrigLighting = {
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	Brightness = Lighting.Brightness,
	FogEnd = Lighting.FogEnd,
	GlobalShadows = Lighting.GlobalShadows
}

-- ─── Активные ESP-объекты ──────────────────────────────────
local ESPObjects = {}

-- Удаление ESP у цели
local function cleanupESP(target)
	if ESPObjects[target] then
		if ESPObjects[target].highlight then
			ESPObjects[target].highlight:Destroy()
		end
		if ESPObjects[target].billboard then
			ESPObjects[target].billboard:Destroy()
		end
		ESPObjects[target] = nil
	end
end

-- Создание подсветки (Highlight). Адорни — модель, если цель — её часть, иначе сама цель.
local function createHighlight(part, fillColor, outlineColor)
	local highlight = Instance.new('Highlight')
	highlight.FillColor = fillColor
	highlight.OutlineColor = outlineColor
	highlight.FillTransparency = 0.5
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

	if part and part.Parent and part.Parent:IsA('Model') then
		highlight.Adornee = part.Parent
		highlight.Parent = part.Parent
	else
		highlight.Adornee = part
		highlight.Parent = part
	end

	return highlight
end

-- Создание надписи над целью (BillboardGui + TextLabel)
local function createBillboard(part, text, color)
	local billboard = Instance.new('BillboardGui')
	billboard.Size = UDim2.new(0, 120, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 4, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = part

	local label = Instance.new('TextLabel')
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color
	label.TextStrokeTransparency = 0
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.Parent = billboard

	return billboard, label
end

-- Добавить/обновить ESP для цели (надпись + подсветка)
local function addESP(target, text, fillColor, outlineColor, textColor, chamsEnabled)
	if ESPObjects[target] then
		-- Обновляем текст только если изменился (экономия)
		if ESPObjects[target].label and ESPObjects[target].label.Text ~= text then
			ESPObjects[target].label.Text = text
		end
		-- Поддерживаем актуальный Адорни и включение чэмсов
		if ESPObjects[target].highlight then
			ESPObjects[target].highlight.Enabled = chamsEnabled ~= false
			if target and target.Parent and target.Parent:IsA('Model') then
				ESPObjects[target].highlight.Adornee = target.Parent
			else
				ESPObjects[target].highlight.Adornee = target
			end
		end
		return
	end

	local highlight = createHighlight(target, fillColor, outlineColor)
	highlight.Enabled = chamsEnabled ~= false

	local billboard, label = createBillboard(target, text, textColor)
	ESPObjects[target] = {
		highlight = highlight,
		billboard = billboard,
		label = label
	}
end

-- ─── Ключевые слова для распознавания объектов ─────────────
local LootKeywords = {
	'fridge', 'cabinet', 'dresser', 'toolbox', 'lockbox',
	'chest', 'safe', 'crate', 'box', 'bag', 'suitcase'
}
local CarKeywords = {
	'car', 'vehicle', 'truck', 'jeep', 'sedan', 'bike', 'motorcycle',
	'humvee', 'van', 'suv', 'taxi', 'bus', 'minivan', 'pickup',
	'coupe', 'hatchback', 'convertible', 'muscle', 'sport', 'atv',
	'quad', 'golf cart', 'limousine', 'chopper', 'cruiser', 'phantom', 'super'
}
local MonsterKeywords = {
	'monster', 'creature', 'enemy', 'hunter', 'stalker', 'beast', 'zombie', 'watcher'
}

-- Есть ли просьба поиска (Prompt 'SearchPrompt')
local function hasSearchPrompt(object)
	if object:IsA('ProximityPrompt') then
		return object.Name == 'SearchPrompt'
	end

	if object:IsA('BasePart') or object:IsA('Model') then
		for _, descendant in ipairs(object:GetDescendants()) do
			if descendant:IsA('ProximityPrompt') and descendant.Name == 'SearchPrompt' then
				return true
			end
		end
	end

	return false
end

-- Ящик/контейнер лута
local function isLootContainer(object)
	if not object:IsA('BasePart') and not object:IsA('Model') then
		return false
	end

	if hasSearchPrompt(object) then
		return true
	end

	local name = string.lower(object.Name)
	for _, keyword in ipairs(LootKeywords) do
		if string.find(name, keyword) then
			return true
		end
	end

	return false
end

-- Машина (по VehicleSeat или по имени)
local function isCar(object)
	if not object:IsA('BasePart') and not object:IsA('Model') then
		return false
	end

	if object:FindFirstChildWhichIsA('VehicleSeat', true) then
		return true
	end

	local name = string.lower(object.Name)
	for _, keyword in ipairs(CarKeywords) do
		if string.find(name, keyword) then
			return true
		end
	end

	return false
end

-- Монстр (модель с именем-ключевиком или гуманоидом без игрока)
local function isMonster(object)
	if not object:IsA('Model') then
		return false
	end

	local name = string.lower(object.Name)
	for _, keyword in ipairs(MonsterKeywords) do
		if string.find(name, keyword) then
			return true
		end
	end

	local humanoid = object:FindFirstChildOfClass('Humanoid')
	if humanoid and not Players:GetPlayerFromCharacter(object) then
		return true
	end

	return false
end

-- ─── Кэш объектов мира ─────────────────────────────────────
local CachedLoot = {}
local CachedMonsters = {}
local CachedCars = {}

local lastScanTime = 0
local SCAN_INTERVAL = 5
local lastESPUpdate = 0
local ESP_UPDATE_INTERVAL = 0.5

-- Сканирование мира: наполняем кэши лута, монстров, машин
-- WorldFinds — предметы, выброшенные/выроненные игроками (лут + чэмсы)
local function scanWorld()
	CachedLoot = {}
	CachedMonsters = {}
	CachedCars = {}

	local worldFinds = Workspace:FindFirstChild('WorldFinds')

	for _, object in ipairs(Workspace:GetDescendants()) do
		-- Контейнер с кнопкой поиска
		if object:IsA('ProximityPrompt') and object.Name == 'SearchPrompt' then
			local parent = object.Parent
			if parent and (parent:IsA('BasePart') or parent:IsA('Model')) then
				table.insert(CachedLoot, parent)
			end
		-- Монстр
		elseif isMonster(object) then
			table.insert(CachedMonsters, object)
		-- Машина
		elseif isCar(object) then
			table.insert(CachedCars, object)
		-- Предмет из WorldFinds (выброшенное/выроненное)
		elseif worldFinds and object:IsDescendantOf(worldFinds) and object:IsA('BasePart') then
			table.insert(CachedLoot, object)
		-- Выход / дверь / спасение
		elseif object:IsA('BasePart') then
			local name = string.lower(object.Name)
			if string.find(name, 'exit') or string.find(name, 'door') or string.find(name, 'escape')
			   or string.find(name, 'boat dock') or string.find(name, 'farm track')
			   or string.find(name, 'helipad') or string.find(name, 'north gate')
			   or string.find(name, 'old town drain') or string.find(name, 'rail tunnel') then
				table.insert(CachedLoot, object)
			end
		end
	end

	lastScanTime = tick()
end

scanWorld()

-- ─── Ближайший контейнер лута ──────────────────────────────
local function getNearestLootContainer()
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild('HumanoidRootPart') then
		return nil, math.huge
	end

	local rootPart = character.HumanoidRootPart
	local nearest = nil
	local nearestDistance = math.huge

	for _, object in ipairs(CachedLoot) do
		if object and object.Parent then
			local position = nil
			if object:IsA('Model') then
				position = object:GetPivot().Position
			elseif object:IsA('BasePart') then
				position = object.Position
			end

			if position then
				local distance = (position - rootPart.Position).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearest = object
				end
			end
		end
	end

	return nearest, nearestDistance
end

-- ─── Телепорт к выходу ─────────────────────────────────────
local function teleportToExit()
	local character = LocalPlayer.Character
	if not character or not character:FindFirstChild('HumanoidRootPart') then
		return
	end

	local rootPart = character.HumanoidRootPart
	local nearestPosition = nil
	local nearestDistance = math.huge

	for _, object in ipairs(Workspace:GetDescendants()) do
		local name = string.lower(object.Name)
		if string.find(name, 'exit') or string.find(name, 'door') or string.find(name, 'escape')
		   or string.find(name, 'boat dock') or string.find(name, 'farm track')
		   or string.find(name, 'helipad') or string.find(name, 'north gate')
		   or string.find(name, 'old town drain') or string.find(name, 'rail tunnel') then
			local position = nil
			if object:IsA('BasePart') then
				position = object.Position
			elseif object:IsA('Model') then
				position = object:GetPivot().Position
			end

			if position then
				local distance = (position - rootPart.Position).Magnitude
				if distance < nearestDistance then
					nearestDistance = distance
					nearestPosition = position
				end
			end
		end
	end

	if nearestPosition then
		rootPart.CFrame = CFrame.new(nearestPosition + Vector3.new(0, 3, 0))
	end
end

-- ─── Скорость ( телепорт по оси XZ ) ───────────────────────
local function applySpeed()
	local character = LocalPlayer.Character
	if not character then
		return
	end

	local humanoid = character:FindFirstChildOfClass('Humanoid')
	if humanoid then
		if Settings.SpeedHack then
			humanoid.WalkSpeed = 16
		else
			humanoid.WalkSpeed = 12
		end
	end
end

RunService.RenderStepped:Connect(function(deltaTime)
	if not Settings.SpeedHack then
		return
	end

	local character = LocalPlayer.Character
	if not character then
		return
	end

	local rootPart = character:FindFirstChild('HumanoidRootPart')
	local humanoid = character:FindFirstChildOfClass('Humanoid')
	if not rootPart or not humanoid then
		return
	end

	local moveDirection = humanoid.MoveDirection
	if moveDirection.Magnitude > 0 then
		local direction = Vector3.new(moveDirection.X, 0, moveDirection.Z).Unit
		rootPart.CFrame = rootPart.CFrame + direction * Settings.WalkSpeed * 8 * deltaTime
	end
end)

-- ─── Стабина: патч модуля Breath и сборщик мусора ───────────
local function patchTableForStamina(tableValue, seenTables)
	if type(tableValue) ~= 'table' or seenTables[tableValue] then
		return
	end

	seenTables[tableValue] = true

	for key, value in pairs(tableValue) do
		if type(value) == 'number' then
			local lowerKey = string.lower(tostring(key))
			if lowerKey:find('stamina') or lowerKey:find('breath') or lowerKey:find('energy')
			   or lowerKey:find('sprint') or lowerKey:find('fatigue') then
				pcall(function()
					tableValue[key] = math.huge
				end)
			end
		elseif type(value) == 'function' then
			if string.lower(tostring(key)) == 'staminamax' then
				pcall(function()
					hookfunction(value, function()
						return math.huge
					end)
				end)
			end
		elseif type(value) == 'table' then
			patchTableForStamina(value, seenTables)
		end
	end
end

-- Патч модуля Breath из PlayerScripts.Client.Breath
local function patchBreathModule()
	local playerScripts = LocalPlayer:FindFirstChild('PlayerScripts')
	local clientFolder = playerScripts and playerScripts:FindFirstChild('Client')
	local breathModule = clientFolder and clientFolder:FindFirstChild('Breath')

	if breathModule and breathModule:IsA('ModuleScript') then
		local ok, module = pcall(require, breathModule)
		if ok and type(module) == 'table' then
			patchTableForStamina(module, {})

			pcall(function()
				if type(module.run) == 'function' then
					hookfunction(module.run, function()
						return
					end)
				end
				if type(module.stop) == 'function' then
					hookfunction(module.stop, function()
						return
					end)
				end
				if type(module.isRunning) == 'function' then
					hookfunction(module.isRunning, function()
						return true
					end)
				end
			end)

			for _, value in pairs(module) do
				if type(value) == 'function' then
					for index = 1, 100 do
						local success, upvalue = pcall(debug.getupvalue, value, index)
						if not success or upvalue == nil then
							break
						end
						if type(upvalue) == 'table' then
							patchTableForStamina(upvalue, {})
						end
					end
				end
			end
		end
	end
end

-- Патч всех замыканий/таблиц из GC со стабиной
local function patchAllGC()
	if not getgc then
		return
	end

	for _, object in ipairs(getgc(true)) do
		if type(object) == 'table' then
			for key, value in pairs(object) do
				if type(value) == 'number' then
					local lowerKey = string.lower(tostring(key))
					if lowerKey:find('stamina') or lowerKey:find('breath') or lowerKey:find('energy')
					   or lowerKey:find('sprint') or lowerKey:find('fatigue') then
						pcall(function()
							object[key] = math.huge
						end)
					end
				elseif type(value) == 'function' then
					local lowerKey = string.lower(tostring(key))
					if lowerKey:find('staminamax') then
						pcall(function()
							hookfunction(value, function()
								return math.huge
							end)
						end)
					end
				end
			end
		elseif type(object) == 'function' then
			for index = 1, 100 do
				local success, upvalue = pcall(debug.getupvalue, object, index)
				if not success or upvalue == nil then
					break
				end
				if type(upvalue) == 'table' then
					patchTableForStamina(upvalue, {})
					for k, v in pairs(upvalue) do
						if type(v) == 'function' then
							local lowerKey = string.lower(tostring(k))
							if lowerKey:find('staminamax') then
								pcall(function()
									hookfunction(v, function()
										return math.huge
									end)
								end)
							elseif lowerKey:find('addstamina') then
								pcall(function()
									hookfunction(v, function()
										return
									end)
								end)
							end
						end
					end
				end
			end
		end
	end
end

-- Комплексная бесконечная стабина
local function infiniteStamina()
	local targets = {LocalPlayer.Character, LocalPlayer}

	for _, target in ipairs(targets) do
		if target then
			for _, value in ipairs(target:GetDescendants()) do
				if value:IsA('NumberValue') or value:IsA('IntValue') then
					local name = string.lower(value.Name)
					if string.find(name, 'stamina') or string.find(name, 'energy')
					   or string.find(name, 'breath') or string.find(name, 'sprint')
					   or string.find(name, 'fatigue') then
						value.Value = math.huge
					end
				end
			end

			for _, attributeName in ipairs({
				'Stamina', 'stamina', 'Energy', 'energy',
				'Sprint', 'sprint', 'Fatigue', 'fatigue',
				'Breath', 'breath'
			}) do
				local attributeValue = target:GetAttribute(attributeName)
				if attributeValue ~= nil then
					pcall(function()
						target:SetAttribute(attributeName, math.huge)
					end)
				end
			end
		end
	end

	patchBreathModule()
	patchAllGC()
end

-- ─── Фуллбрит ──────────────────────────────────────────────
local function applyFullbright()
	if Settings.Fullbright then
		Lighting.Ambient = Color3.new(1, 1, 1)
		Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
		Lighting.Brightness = 20
		Lighting.FogEnd = 100000
		Lighting.GlobalShadows = false

		for _, object in ipairs(Lighting:GetDescendants()) do
			if object:IsA('ColorCorrectionEffect') or object:IsA('BlurEffect')
			   or object:IsA('BloomEffect') or object:IsA('DepthOfFieldEffect')
			   or object:IsA('SunRaysEffect') then
				if object:GetAttribute('HUSHESP_Enabled') == nil then
					object:SetAttribute('HUSHESP_Enabled', object.Enabled)
				end
				object.Enabled = false
			elseif object:IsA('Atmosphere') then
				if object:GetAttribute('HUSHESP_Density') == nil then
					object:SetAttribute('HUSHESP_Density', object.Density)
					object:SetAttribute('HUSHESP_Glare', object.Glare)
					object:SetAttribute('HUSHESP_Haze', object.Haze)
				end
				object.Density = 0
				object.Glare = 0
				object.Haze = 0
			end
		end
	else
		Lighting.Ambient = OrigLighting.Ambient
		Lighting.OutdoorAmbient = OrigLighting.OutdoorAmbient
		Lighting.Brightness = OrigLighting.Brightness
		Lighting.FogEnd = OrigLighting.FogEnd
		Lighting.GlobalShadows = OrigLighting.GlobalShadows

		for _, object in ipairs(Lighting:GetDescendants()) do
			local enabled = object:GetAttribute('HUSHESP_Enabled')
			if enabled ~= nil then
				object.Enabled = enabled
				object:SetAttribute('HUSHESP_Enabled', nil)
			end

			local density = object:GetAttribute('HUSHESP_Density')
			if density ~= nil then
				object.Density = density
				object.Glare = object:GetAttribute('HUSHESP_Glare')
				object.Haze = object:GetAttribute('HUSHESP_Haze')
				object:SetAttribute('HUSHESP_Density', nil)
				object:SetAttribute('HUSHESP_Glare', nil)
				object:SetAttribute('HUSHESP_Haze', nil)
			end
		end
	end
end

-- ─── Главный цикл (Heartbeat): ESP + чэмсы + движение + стабина + свет ───
RunService.Heartbeat:Connect(function()
	-- Чистим мёртвые цели
	for target in pairs(ESPObjects) do
		if not target or not target.Parent then
			cleanupESP(target)
		end
	end

	local charPos = nil
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then
		charPos = LocalPlayer.Character.HumanoidRootPart.Position
	end

	-- Пересканирование мира раз в 5 сек
	if tick() - lastScanTime >= SCAN_INTERVAL then
		scanWorld()
	end

	-- Обновление надписей и чэмсов раз в 0.5 сек
	if tick() - lastESPUpdate >= ESP_UPDATE_INTERVAL then
		lastESPUpdate = tick()

		-- Игроки
		if Settings.ESP_Players then
			for _, player in ipairs(Players:GetPlayers()) do
				if player ~= LocalPlayer and player.Character
				   and player.Character:FindFirstChild('HumanoidRootPart') then
					local hrp = player.Character.HumanoidRootPart
					local humanoid = player.Character:FindFirstChildOfClass('Humanoid')
					local text = player.Name
					if Settings.ShowDistance and charPos then
						text = text .. ' [' .. math.floor((hrp.Position - charPos).Magnitude) .. 'm]'
					end
					if Settings.ShowHealth and humanoid then
						text = text .. ' HP:' .. math.floor(humanoid.Health)
					end
					addESP(hrp, text,
						Color3.fromRGB(0, 255, 100), Color3.fromRGB(0, 200, 80),
						Color3.fromRGB(0, 255, 100), Settings.Chams_Players)
				end
			end
		else
			for _, player in ipairs(Players:GetPlayers()) do
				if player.Character and player.Character:FindFirstChild('HumanoidRootPart') then
					cleanupESP(player.Character.HumanoidRootPart)
				end
			end
		end

		-- Монстры (чэмсы на всю модель через HRP)
		if Settings.ESP_Monsters then
			for _, object in ipairs(CachedMonsters) do
				if object and object.Parent and object:FindFirstChild('HumanoidRootPart') then
					local hrp = object.HumanoidRootPart
					local text = 'MONSTER'
					if Settings.ShowDistance and charPos then
						text = text .. ' [' .. math.floor((hrp.Position - charPos).Magnitude) .. 'm]'
					end
					addESP(hrp, text,
						Color3.fromRGB(255, 50, 50), Color3.fromRGB(200, 0, 0),
						Color3.fromRGB(255, 80, 80), Settings.Chams_Monsters)
				end
			end
		else
			for _, object in ipairs(CachedMonsters) do
				if object and object.Parent and object:FindFirstChild('HumanoidRootPart') then
					cleanupESP(object.HumanoidRootPart)
				end
			end
		end

		-- Лут (контейнеры + WorldFinds + выходы)
		if Settings.ESP_Loot then
			for _, object in ipairs(CachedLoot) do
				if object and object.Parent then
					local target = nil
					if object:IsA('Model') then
						target = object:FindFirstChildWhichIsA('BasePart')
					elseif object:IsA('BasePart') then
						target = object
					end

					if target and target:IsA('BasePart') then
						local text = 'LOOT'
						if Settings.ShowDistance and charPos then
							text = text .. ' [' .. math.floor((target.Position - charPos).Magnitude) .. 'm]'
						end
						addESP(target, text,
							Color3.fromRGB(255, 220, 0), Color3.fromRGB(200, 180, 0),
							Color3.fromRGB(255, 240, 100), Settings.Chams_Loot)
					end
				end
			end
		else
			for _, object in ipairs(CachedLoot) do
				if object and object.Parent then
					local target = nil
					if object:IsA('Model') then
						target = object:FindFirstChildWhichIsA('BasePart')
					elseif object:IsA('BasePart') then
						target = object
					end
					if target then
						cleanupESP(target)
					end
				end
			end
		end

		-- Машины
		if Settings.ESP_Cars then
			for _, object in ipairs(CachedCars) do
				if object and object.Parent then
					local target = nil
					if object:IsA('Model') then
						target = object:FindFirstChildWhichIsA('BasePart')
					elseif object:IsA('BasePart') then
						target = object
					end

					if target and target:IsA('BasePart') then
						local text = 'CAR'
						if Settings.ShowDistance and charPos then
							text = text .. ' [' .. math.floor((target.Position - charPos).Magnitude) .. 'm]'
						end
						addESP(target, text,
							Color3.fromRGB(0, 170, 255), Color3.fromRGB(0, 120, 220),
							Color3.fromRGB(120, 220, 255), Settings.Chams_Cars)
					end
				end
			end
		else
			for _, object in ipairs(CachedCars) do
				if object and object.Parent then
					local target = nil
					if object:IsA('Model') then
						target = object:FindFirstChildWhichIsA('BasePart')
					elseif object:IsA('BasePart') then
						target = object
					end
					if target then
						cleanupESP(target)
					end
				end
			end
		end
	end

	applySpeed()
	if Settings.InfiniteStamina then
		infiniteStamina()
	end
	applyFullbright()
end)

-- ─── Меню ──────────────────────────────────────────────────
local MainTab = Window:CreateTab('ESP', 4483362458)
MainTab:CreateToggle({Name = 'Player ESP', CurrentValue = true, Flag = 'ESP_Players',
	Callback = function(value) Settings.ESP_Players = value end})
MainTab:CreateToggle({Name = 'Player Chams', CurrentValue = true, Flag = 'Chams_Players',
	Callback = function(value) Settings.Chams_Players = value end})
MainTab:CreateToggle({Name = 'Monster ESP', CurrentValue = true, Flag = 'ESP_Monsters',
	Callback = function(value) Settings.ESP_Monsters = value end})
MainTab:CreateToggle({Name = 'Monster Chams', CurrentValue = true, Flag = 'Chams_Monsters',
	Callback = function(value) Settings.Chams_Monsters = value end})
MainTab:CreateToggle({Name = 'Loot ESP', CurrentValue = true, Flag = 'ESP_Loot',
	Callback = function(value) Settings.ESP_Loot = value end})
MainTab:CreateToggle({Name = 'Loot Chams', CurrentValue = true, Flag = 'Chams_Loot',
	Callback = function(value) Settings.Chams_Loot = value end})
MainTab:CreateToggle({Name = 'Car ESP', CurrentValue = true, Flag = 'ESP_Cars',
	Callback = function(value) Settings.ESP_Cars = value end})
MainTab:CreateToggle({Name = 'Car Chams', CurrentValue = true, Flag = 'Chams_Cars',
	Callback = function(value) Settings.Chams_Cars = value end})
MainTab:CreateToggle({Name = 'Show Distance', CurrentValue = true, Flag = 'ShowDistance',
	Callback = function(value) Settings.ShowDistance = value end})
MainTab:CreateToggle({Name = 'Show Health', CurrentValue = true, Flag = 'ShowHealth',
	Callback = function(value) Settings.ShowHealth = value end})

local MoveTab = Window:CreateTab('Movement', 4483362458)
MoveTab:CreateToggle({Name = 'Speed Hack', CurrentValue = false, Flag = 'SpeedHack',
	Callback = function(value) Settings.SpeedHack = value end})
MoveTab:CreateSlider({Name = 'Speed Multiplier', Range = {1, 5}, Increment = 1, Suffix = 'x',
	CurrentValue = 2, Flag = 'WalkSpeed', Callback = function(value) Settings.WalkSpeed = value end})
MoveTab:CreateToggle({Name = 'Infinite Stamina', CurrentValue = false, Flag = 'InfiniteStamina',
	Callback = function(value) Settings.InfiniteStamina = value end})
MoveTab:CreateToggle({Name = 'Fullbright', CurrentValue = false, Flag = 'Fullbright',
	Callback = function(value)
		Settings.Fullbright = value
		applyFullbright()
	end})

-- ─── Персонаж появился заново — применить скорость ─────────
LocalPlayer.CharacterAdded:Connect(function(character)
	task.wait(1)
	applySpeed()
end)

-- ─── Диагностика FPS/ESP (раз в 5 сек) ─────────────────────
local LastDelta = 0
RunService.Heartbeat:Connect(function(deltaTime)
	LastDelta = deltaTime
end)

task.spawn(function()
	while true do
		task.wait(5)
		local espCount = 0
		for _ in pairs(ESPObjects) do
			espCount = espCount + 1
		end

		local lootCount = 0
		for _, object in ipairs(CachedLoot) do
			if object and object.Parent then
				lootCount = lootCount + 1
			end
		end

		local monsterCount = 0
		for _, object in ipairs(CachedMonsters) do
			if object and object.Parent then
				monsterCount = monsterCount + 1
			end
		end

		local carCount = 0
		for _, object in ipairs(CachedCars) do
			if object and object.Parent then
				carCount = carCount + 1
			end
		end

		local fps = LastDelta > 0 and (1 / LastDelta) or 0
		warn(string.format('[HUSHESP DIAG] ESP=%d Loot=%d Monsters=%d Cars=%d FPS=%.1f',
			espCount, lootCount, monsterCount, carCount, fps))
	end
end)

-- ─── Управление: K — скрыть/показать меню ──────────────────
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	if input.KeyCode == Enum.KeyCode.K then
		pcall(function()
			Window:Toggle()
		end)
	end
end)

print('[HUSHESP] ready — Rayfield loaded (K to toggle)')
Rayfield:Notify({Title = 'HUSH ESP', Content = 'Loaded successfully', Duration = 3})
