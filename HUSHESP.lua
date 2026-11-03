-- HUSH ESP optimized
local Players = game:GetService('Players')
local RunService = game:GetService('RunService')
local Workspace = game:GetService('Workspace')
local Lighting = game:GetService('Lighting')
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
if not LocalPlayer.Character then LocalPlayer.CharacterAdded:Wait() end
task.wait(2)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local VERSION = "2.14"
local Window = Rayfield:CreateWindow({Name='HUSH ESP v'..VERSION,LoadingTitle='HUSH ESP',LoadingSubtitle='Open Source',ConfigurationSaving={Enabled=true,FolderName='HUSHESP',FileName='Config'},Discord={Enabled=false},KeySystem=false})

local Settings = {ESP_Players=true,ESP_Monsters=true,ESP_Loot=true,Chams_Players=true,Chams_Monsters=true,Chams_Loot=true,ShowDistance=true,ShowHealth=true,SpeedHack=false,WalkSpeed=50,InfiniteStamina=false,Fullbright=false}
local OrigLighting = {Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,Brightness=Lighting.Brightness,FogEnd=Lighting.FogEnd,GlobalShadows=Lighting.GlobalShadows}
local ESPObjects = {}

local function cleanupESP(t) if ESPObjects[t] then if ESPObjects[t].highlight then ESPObjects[t].highlight:Destroy() end if ESPObjects[t].billboard then ESPObjects[t].billboard:Destroy() end ESPObjects[t]=nil end end
local function createHighlight(p,fc,oc) local hl=Instance.new('Highlight'); hl.FillColor=fc; hl.OutlineColor=oc; hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; if p and p.Parent and p.Parent:IsA('Model') then hl.Adornee=p.Parent; hl.Parent=p.Parent else hl.Adornee=p; hl.Parent=p end; return hl end
local function createBillboard(p,text,col) local bb=Instance.new('BillboardGui'); bb.Size=UDim2.new(0,120,0,40); bb.StudsOffset=Vector3.new(0,4,0); bb.AlwaysOnTop=true; bb.Parent=p; local l=Instance.new('TextLabel'); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.Text=text; l.TextColor3=col; l.TextStrokeTransparency=0; l.TextStrokeColor3=Color3.new(0,0,0); l.Font=Enum.Font.GothamBold; l.TextSize=13; l.Parent=bb; return bb,l end
local function addESP(t,text,fc,oc,tc,ce) if ESPObjects[t] then if ESPObjects[t].label then ESPObjects[t].label.Text=text end if ESPObjects[t].highlight then ESPObjects[t].highlight.Enabled = ce~=false; ESPObjects[t].highlight.Adornee=t end return end local hl=createHighlight(t,fc,oc); hl.Enabled=ce~=false; local bb,l=createBillboard(t,text,tc); ESPObjects[t]={highlight=hl,billboard=bb,label=l} end

local LootKeywords={'fridge','cabinet','dresser','toolbox','lockbox'}
local function hasSearchPrompt(obj)
    if obj:IsA('ProximityPrompt') then return obj.Name=='SearchPrompt' end
    if obj:IsA('BasePart') or obj:IsA('Model') then
        for _,d in ipairs(obj:GetDescendants()) do
            if d:IsA('ProximityPrompt') and d.Name=='SearchPrompt' then return true end
        end
    end
    return false
end
local function isLootContainer(obj)
    if not obj:IsA('BasePart') and not obj:IsA('Model') then return false end
    if hasSearchPrompt(obj) then return true end
    local name=string.lower(obj.Name)
    for _,kw in ipairs(LootKeywords) do
        if string.find(name,kw) then return true end
    end
    return false
end
local MonsterKeywords={'monster','creature','enemy','hunter','stalker','beast','zombie'}
local function isMonster(obj) if not obj:IsA('Model') then return false end local name=string.lower(obj.Name) for _,kw in ipairs(MonsterKeywords) do if string.find(name,kw) then return true end end local hum=obj:FindFirstChildOfClass('Humanoid') if hum and not Players:GetPlayerFromCharacter(obj) then return true end return false end

local CachedLoot,CachedMonsters,lastScanTime,SCAN_INTERVAL,lastESPUpdate={}, {},0,5,0
local function scanWorld() CachedLoot={}; CachedMonsters={}; for _,obj in ipairs(Workspace:GetDescendants()) do if obj:IsA('ProximityPrompt') and obj.Name=='SearchPrompt' then local p=obj.Parent if p and (p:IsA('BasePart') or p:IsA('Model')) then table.insert(CachedLoot,p) end elseif isMonster(obj) then table.insert(CachedMonsters,obj) end end lastScanTime=tick() end
scanWorld()

local function getNearestLootContainer() local char=LocalPlayer.Character if not char or not char:FindFirstChild('HumanoidRootPart') then return nil,math.huge end local hrp=char.HumanoidRootPart local nearest,nd=nil,math.huge for _,obj in ipairs(CachedLoot) do if obj and obj.Parent then local pos=nil if obj:IsA('Model') then pos=obj:GetPivot().Position elseif obj:IsA('BasePart') then pos=obj.Position end if pos then local d=(pos-hrp.Position).Magnitude if d<nd then nd=d; nearest=obj end end end end return nearest,nd end
local function teleportToExit() local char=LocalPlayer.Character if not char or not char:FindFirstChild('HumanoidRootPart') then return end local hrp=char.HumanoidRootPart local nearest,nd=nil,math.huge for _,obj in ipairs(Workspace:GetDescendants()) do local name=string.lower(obj.Name) if string.find(name,'exit') or string.find(name,'door') or string.find(name,'escape') then local pos=nil if obj:IsA('BasePart') then pos=obj.Position elseif obj:IsA('Model') then pos=obj:GetPivot().Position end if pos then local d=(pos-hrp.Position).Magnitude if d<nd then nd=d; nearest=pos end end end end if nearest then hrp.CFrame=CFrame.new(nearest+Vector3.new(0,3,0)) end end

local function applySpeed() local char=LocalPlayer.Character if not char then return end local hum=char:FindFirstChildOfClass('Humanoid') local hrp=char:FindFirstChild('HumanoidRootPart') if hum then if Settings.SpeedHack then hum.WalkSpeed = Settings.WalkSpeed else hum.WalkSpeed = 12 end end end
RunService.RenderStepped:Connect(function(dt) if Settings.SpeedHack then local char=LocalPlayer.Character if char then local hrp=char:FindFirstChild('HumanoidRootPart') local hum=char:FindFirstChildOfClass('Humanoid') if hrp and hum then local move=hum.MoveDirection if move.Magnitude>0 then local dir=Vector3.new(move.X,0,move.Z).Unit hrp.CFrame=hrp.CFrame + dir*Settings.WalkSpeed*dt*2 end end end end end)
local function patchTableForStamina(t, seen) if type(t)~='table' or seen[t] then return end seen[t]=true for k,v in pairs(t) do if type(v)=='number' then local lk=string.lower(tostring(k)) if lk:find('stamina') or lk:find('breath') or lk:find('energy') or lk:find('sprint') or lk:find('fatigue') then pcall(function() t[k]=math.huge end) end elseif type(v)=='table' then patchTableForStamina(v, seen) end end end
local function patchBreathModule() local ps=LocalPlayer:FindFirstChild('PlayerScripts') local client=ps and ps:FindFirstChild('Client') local breath=client and client:FindFirstChild('Breath') if breath and breath:IsA('ModuleScript') then local ok,mod=pcall(require,breath) if ok and type(mod)=='table' then patchTableForStamina(mod,{}) pcall(function() if type(mod.run)=='function' then hookfunction(mod.run,function(...) return end) end if type(mod.stop)=='function' then hookfunction(mod.stop,function(...) return end) end if type(mod.isRunning)=='function' then hookfunction(mod.isRunning,function(...) return true end) end end) for _,fn in pairs(mod) do if type(fn)=='function' then for i=1,100 do local ok,val=pcall(debug.getupvalue,fn,i) if not ok or val==nil then break end if type(val)=='number' then elseif type(val)=='table' then patchTableForStamina(val,{}) end end end end end end end
local staminaPatched=false local function patchAllGC() if staminaPatched then return end staminaPatched=true if not getgc then return end for _,obj in ipairs(getgc(true)) do if type(obj)=='table' then for k,v in pairs(obj) do if type(v)=='number' then local lk=string.lower(tostring(k)) if lk:find('stamina') or lk:find('breath') or lk:find('energy') or lk:find('sprint') or lk:find('fatigue') then pcall(function() obj[k]=math.huge end) end end end elseif type(obj)=='function' then for i=1,100 do local ok,val=pcall(debug.getupvalue,obj,i) if not ok or val==nil then break end if type(val)=='table' then patchTableForStamina(val,{}) end end end end end local function infiniteStamina() local targets={LocalPlayer.Character,LocalPlayer} for _,t in ipairs(targets) do if t then for _,v in ipairs(t:GetDescendants()) do if v:IsA('NumberValue') or v:IsA('IntValue') then local name=string.lower(v.Name) if string.find(name,'stamina') or string.find(name,'energy') or string.find(name,'breath') or string.find(name,'sprint') or string.find(name,'fatigue') then v.Value=math.huge end end end for _,attr in ipairs({'Stamina','stamina','Energy','energy','Sprint','sprint','Fatigue','fatigue','Breath','breath'}) do local val=t:GetAttribute(attr) if val~=nil then pcall(function() t:SetAttribute(attr,math.huge) end) end end end end patchBreathModule(); patchAllGC() end
local function applyFullbright() if Settings.Fullbright then Lighting.Ambient=Color3.new(1,1,1); Lighting.OutdoorAmbient=Color3.new(1,1,1); Lighting.Brightness=20; Lighting.FogEnd=100000; Lighting.GlobalShadows=false for _,v in ipairs(Lighting:GetDescendants()) do if v:IsA('ColorCorrectionEffect') or v:IsA('BlurEffect') or v:IsA('BloomEffect') or v:IsA('DepthOfFieldEffect') or v:IsA('SunRaysEffect') then if v:GetAttribute('HUSHESP_Enabled')==nil then v:SetAttribute('HUSHESP_Enabled',v.Enabled) end v.Enabled=false elseif v:IsA('Atmosphere') then if v:GetAttribute('HUSHESP_Density')==nil then v:SetAttribute('HUSHESP_Density',v.Density); v:SetAttribute('HUSHESP_Glare',v.Glare); v:SetAttribute('HUSHESP_Haze',v.Haze) end v.Density=0; v.Glare=0; v.Haze=0 end end else Lighting.Ambient=OrigLighting.Ambient; Lighting.OutdoorAmbient=OrigLighting.OutdoorAmbient; Lighting.Brightness=OrigLighting.Brightness; Lighting.FogEnd=OrigLighting.FogEnd; Lighting.GlobalShadows=OrigLighting.GlobalShadows for _,v in ipairs(Lighting:GetDescendants()) do local enabled=v:GetAttribute('HUSHESP_Enabled') if enabled~=nil then v.Enabled=enabled; v:SetAttribute('HUSHESP_Enabled',nil) end local density=v:GetAttribute('HUSHESP_Density') if density~=nil then v.Density=density; v.Glare=v:GetAttribute('HUSHESP_Glare'); v.Haze=v:GetAttribute('HUSHESP_Haze'); v:SetAttribute('HUSHESP_Density',nil); v:SetAttribute('HUSHESP_Glare',nil); v:SetAttribute('HUSHESP_Haze',nil) end end end end

RunService.Heartbeat:Connect(function()
    for target in pairs(ESPObjects) do if not target or not target.Parent then cleanupESP(target) end end
    local charPos=nil if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then charPos=LocalPlayer.Character.HumanoidRootPart.Position end
    if tick()-lastScanTime>=SCAN_INTERVAL then scanWorld() end
    if tick()-lastESPUpdate>=0.5 then lastESPUpdate=tick() if Settings.ESP_Players then for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character and p.Character:FindFirstChild('HumanoidRootPart') then local hrp=p.Character.HumanoidRootPart local hum=p.Character:FindFirstChildOfClass('Humanoid') local text=p.Name if Settings.ShowDistance and charPos then text=text..' ['..math.floor((hrp.Position-charPos).Magnitude)..'m]' end if Settings.ShowHealth and hum then text=text..' HP:'..math.floor(hum.Health) end addESP(hrp,text,Color3.fromRGB(0,255,100),Color3.fromRGB(0,200,80),Color3.fromRGB(0,255,100),Settings.Chams_Players) end end else for _,p in ipairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild('HumanoidRootPart') then cleanupESP(p.Character.HumanoidRootPart) end end end
    if Settings.ESP_Monsters then for _,obj in ipairs(CachedMonsters) do if obj and obj.Parent and obj:FindFirstChild('HumanoidRootPart') then local hrp=obj.HumanoidRootPart local text='MONSTER' if Settings.ShowDistance and charPos then text=text..' ['..math.floor((hrp.Position-charPos).Magnitude)..'m]' end addESP(hrp,text,Color3.fromRGB(255,50,50),Color3.fromRGB(200,0,0),Color3.fromRGB(255,80,80),Settings.Chams_Monsters) end end else for _,obj in ipairs(CachedMonsters) do if obj and obj.Parent and obj:FindFirstChild('HumanoidRootPart') then cleanupESP(obj.HumanoidRootPart) end end end
    if Settings.ESP_Loot then for _,obj in ipairs(CachedLoot) do if obj and obj.Parent then local target=nil if obj:IsA('Model') then target=obj:FindFirstChildWhichIsA('BasePart') elseif obj:IsA('BasePart') then target=obj end if target and target:IsA('BasePart') then local text='LOOT' if Settings.ShowDistance and charPos then text=text..' ['..math.floor((target.Position-charPos).Magnitude)..'m]' end addESP(target,text,Color3.fromRGB(255,220,0),Color3.fromRGB(200,180,0),Color3.fromRGB(255,240,100),Settings.Chams_Loot) end end end else for _,obj in ipairs(CachedLoot) do if obj and obj.Parent then local target=nil if obj:IsA('Model') then target=obj:FindFirstChildWhichIsA('BasePart') elseif obj:IsA('BasePart') then target=obj end if target then cleanupESP(target) end end end end end
    applySpeed(); if Settings.InfiniteStamina then infiniteStamina() end applyFullbright()
end)

local MainTab=Window:CreateTab('ESP',4483362458)
MainTab:CreateToggle({Name='Player ESP',CurrentValue=true,Flag='ESP_Players',Callback=function(v)Settings.ESP_Players=v end})
MainTab:CreateToggle({Name='Player Chams',CurrentValue=true,Flag='Chams_Players',Callback=function(v)Settings.Chams_Players=v end})
MainTab:CreateToggle({Name='Monster ESP',CurrentValue=true,Flag='ESP_Monsters',Callback=function(v)Settings.ESP_Monsters=v end})
MainTab:CreateToggle({Name='Monster Chams',CurrentValue=true,Flag='Chams_Monsters',Callback=function(v)Settings.Chams_Monsters=v end})
MainTab:CreateToggle({Name='Loot ESP',CurrentValue=true,Flag='ESP_Loot',Callback=function(v)Settings.ESP_Loot=v end})
MainTab:CreateToggle({Name='Loot Chams',CurrentValue=true,Flag='Chams_Loot',Callback=function(v)Settings.Chams_Loot=v end})
MainTab:CreateToggle({Name='Show Distance',CurrentValue=true,Flag='ShowDistance',Callback=function(v)Settings.ShowDistance=v end})
MainTab:CreateToggle({Name='Show Health',CurrentValue=true,Flag='ShowHealth',Callback=function(v)Settings.ShowHealth=v end})
local MoveTab=Window:CreateTab('Movement',4483362458)
MoveTab:CreateToggle({Name='Speed Hack',CurrentValue=false,Flag='SpeedHack',Callback=function(v)Settings.SpeedHack=v end})
MoveTab:CreateSlider({Name='Walk Speed',Range={16,200},Increment=1,Suffix='ws',CurrentValue=50,Flag='WalkSpeed',Callback=function(v)Settings.WalkSpeed=v end})
MoveTab:CreateToggle({Name='Infinite Stamina',CurrentValue=false,Flag='InfiniteStamina',Callback=function(v)Settings.InfiniteStamina=v end})
MoveTab:CreateToggle({Name='Fullbright',CurrentValue=false,Flag='Fullbright',Callback=function(v)Settings.Fullbright=v; applyFullbright() end})
LocalPlayer.CharacterAdded:Connect(function(char) task.wait(1); applySpeed() end)
local LastDelta=0; RunService.Heartbeat:Connect(function(dt) LastDelta=dt end)
task.spawn(function() while true do task.wait(5) local ec=0 for _ in pairs(ESPObjects) do ec=ec+1 end local lc,mc=0,0 for _,o in ipairs(CachedLoot) do if o and o.Parent then lc=lc+1 end end for _,o in ipairs(CachedMonsters) do if o and o.Parent then mc=mc+1 end end local fps=LastDelta>0 and (1/LastDelta) or 0 warn(string.format('[HUSHESP DIAG] ESP=%d Loot=%d Monsters=%d FPS=%.1f',ec,lc,mc,fps)) end end)
local UserInputService = game:GetService('UserInputService')
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.K then
        pcall(function() Window:Toggle() end)
    end
end)
task.spawn(function() task.wait(3) local ps=LocalPlayer:FindFirstChild('PlayerScripts') local client=ps and ps:FindFirstChild('Client') local breath=client and client:FindFirstChild('Breath') if breath and breath:IsA('ModuleScript') then local ok,mod=pcall(require,breath) if ok then print('[HUSHESP Breath] type',typeof(mod)) if type(mod)=='table' then for k,v in pairs(mod) do print('[HUSHESP Breath] key',k,typeof(v)) end for _,fn in pairs(mod) do if type(fn)=='function' then for i=1,100 do local ok,val=pcall(debug.getupvalue,fn,i) if not ok or val==nil then break end print('[HUSHESP Breath upvalue]',i,typeof(val),tostring(val)) if type(val)=='table' then local function dumpTable(t,prefix,depth) if depth>2 then return end for k,v in pairs(t) do print('[HUSHESP Breath table]',prefix..'.'..tostring(k),typeof(v),tostring(v)) if type(v)=='table' then dumpTable(v,prefix..'.'..tostring(k),depth+1) end end end dumpTable(val,'upvalue'..i,1) end end end end end end end local breathRemote=nil for _,v in ipairs(game:GetDescendants()) do if v.Name=='Breath' and v:IsA('RemoteEvent') then breathRemote=v break end end if breathRemote then local oldFire local ok,err=pcall(function() oldFire=hookfunction(breathRemote.FireServer,function(self,...) print('[HUSHESP Breath remote]',...) return oldFire(self,...) end) end) if not ok then print('[HUSHESP Breath hook failed]',err) end pcall(function() breathRemote.OnClientEvent:Connect(function(...) print('[HUSHESP Breath remote in]',...) end) end) end end)
