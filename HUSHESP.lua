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
local Window = Rayfield:CreateWindow({Name='HUSH ESP',LoadingTitle='HUSH ESP',LoadingSubtitle='Open Source',ConfigurationSaving={Enabled=true,FolderName='HUSHESP',FileName='Config'},Discord={Enabled=false},KeySystem=false})

local Settings = {ESP_Players=true,ESP_Monsters=true,ESP_Loot=true,Chams_Players=true,Chams_Monsters=true,Chams_Loot=true,ESP_Radius=300,ShowDistance=true,ShowHealth=true,AutoLoot=false,AutoLootRadius=50,SpeedHack=false,WalkSpeed=50,NoSound=false,Noclip=false,InfiniteStamina=false,Fullbright=false}
local OrigLighting = {Ambient=Lighting.Ambient,OutdoorAmbient=Lighting.OutdoorAmbient,Brightness=Lighting.Brightness,FogEnd=Lighting.FogEnd,GlobalShadows=Lighting.GlobalShadows}
local ESPObjects = {}

local function cleanupESP(t) if ESPObjects[t] then if ESPObjects[t].highlight then ESPObjects[t].highlight:Destroy() end if ESPObjects[t].billboard then ESPObjects[t].billboard:Destroy() end ESPObjects[t]=nil end end
local function createHighlight(p,fc,oc) local hl=Instance.new('Highlight'); hl.FillColor=fc; hl.OutlineColor=oc; hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop; hl.Parent=p; return hl end
local function createBillboard(p,text,col) local bb=Instance.new('BillboardGui'); bb.Size=UDim2.new(0,120,0,40); bb.StudsOffset=Vector3.new(0,4,0); bb.AlwaysOnTop=true; bb.Parent=p; local l=Instance.new('TextLabel'); l.Size=UDim2.new(1,0,1,0); l.BackgroundTransparency=1; l.Text=text; l.TextColor3=col; l.TextStrokeTransparency=0; l.TextStrokeColor3=Color3.new(0,0,0); l.Font=Enum.Font.GothamBold; l.TextSize=13; l.Parent=bb; return bb,l end
local function addESP(t,text,fc,oc,tc,ce) if ESPObjects[t] then if ESPObjects[t].label then ESPObjects[t].label.Text=text end if ESPObjects[t].highlight then ESPObjects[t].highlight.Enabled = ce~=false end return end local hl=createHighlight(t,fc,oc); hl.Enabled=ce~=false; local bb,l=createBillboard(t,text,tc); ESPObjects[t]={highlight=hl,billboard=bb,label=l} end

local LootKeywords={'crate','lockbox','loot','chest','box','container','barrel','supply','cache','stash'}
local function isLootContainer(obj) if not obj:IsA('BasePart') and not obj:IsA('Model') then return false end local name=string.lower(obj.Name) for _,kw in ipairs(LootKeywords) do if string.find(name,kw) then return true end end return false end
local MonsterKeywords={'monster','creature','enemy','hunter','stalker','beast','zombie'}
local function isMonster(obj) if not obj:IsA('Model') then return false end local name=string.lower(obj.Name) for _,kw in ipairs(MonsterKeywords) do if string.find(name,kw) then return true end end local hum=obj:FindFirstChildOfClass('Humanoid') if hum and not Players:GetPlayerFromCharacter(obj) then return true end return false end

local CachedLoot,CachedMonsters,lastScanTime,SCAN_INTERVAL={}, {},0,2
local function scanWorld() CachedLoot={}; CachedMonsters={}; for _,obj in ipairs(Workspace:GetDescendants()) do if isLootContainer(obj) then table.insert(CachedLoot,obj) elseif isMonster(obj) then table.insert(CachedMonsters,obj) end end lastScanTime=tick() end
scanWorld()

local function getNearestLootContainer() local char=LocalPlayer.Character if not char or not char:FindFirstChild('HumanoidRootPart') then return nil,math.huge end local hrp=char.HumanoidRootPart local nearest,nd=nil,math.huge for _,obj in ipairs(CachedLoot) do if obj and obj.Parent then local pos=nil if obj:IsA('Model') then pos=obj:GetPivot().Position elseif obj:IsA('BasePart') then pos=obj.Position end if pos then local d=(pos-hrp.Position).Magnitude if d<nd then nd=d; nearest=obj end end end end return nearest,nd end
local function teleportToExit() local char=LocalPlayer.Character if not char or not char:FindFirstChild('HumanoidRootPart') then return end local hrp=char.HumanoidRootPart local nearest,nd=nil,math.huge for _,obj in ipairs(Workspace:GetDescendants()) do local name=string.lower(obj.Name) if string.find(name,'exit') or string.find(name,'door') or string.find(name,'escape') then local pos=nil if obj:IsA('BasePart') then pos=obj.Position elseif obj:IsA('Model') then pos=obj:GetPivot().Position end if pos then local d=(pos-hrp.Position).Magnitude if d<nd then nd=d; nearest=pos end end end end if nearest then hrp.CFrame=CFrame.new(nearest+Vector3.new(0,3,0)) end end

local function autoLoot() if not Settings.AutoLoot then return end local char=LocalPlayer.Character if not char or not char:FindFirstChild('HumanoidRootPart') then return end local hrp=char.HumanoidRootPart local c,d=getNearestLootContainer() if c and d and d<=Settings.AutoLootRadius and c.Parent then local pos=nil if c:IsA('Model') then pos=c:GetPivot().Position elseif c:IsA('BasePart') then pos=c.Position end if pos then hrp.CFrame=CFrame.new(pos+Vector3.new(0,3,0)) for _,desc in ipairs(c:GetDescendants()) do if desc:IsA('ProximityPrompt') then pcall(function() desc:InputHoldBegin(); task.wait(0.1); desc:InputHoldEnd() end) elseif desc:IsA('ClickDetector') then pcall(function() fireclickdetector(desc) end) end end end end end
local function applySpeed() local char=LocalPlayer.Character if not char then return end local hum=char:FindFirstChildOfClass('Humanoid') if hum then if Settings.SpeedHack then hum.WalkSpeed = Settings.WalkSpeed else hum.WalkSpeed = 12 end end end
local function applyNoSound() local char=LocalPlayer.Character if not char then return end for _,desc in ipairs(char:GetDescendants()) do if desc:IsA('Sound') then desc.Volume = Settings.NoSound and 0 or 1 end end end
local NoclipConn; local function toggleNoclip() Settings.Noclip = not Settings.Noclip if Settings.Noclip then NoclipConn = RunService.Stepped:Connect(function() local char=LocalPlayer.Character if char then for _,part in ipairs(char:GetDescendants()) do if part:IsA('BasePart') then part.CanCollide=false end end end end) else if NoclipConn then NoclipConn:Disconnect() end local char=LocalPlayer.Character if char then for _,part in ipairs(char:GetDescendants()) do if part:IsA('BasePart') then part.CanCollide=true end end end end end
local function infiniteStamina() local char=LocalPlayer.Character if not char then return end for _,v in ipairs(char:GetDescendants()) do if v:IsA('NumberValue') or v:IsA('IntValue') then local name=string.lower(v.Name) if string.find(name,'stamina') or string.find(name,'energy') or string.find(name,'breath') or string.find(name,'sprint') then v.Value=100 end end end for _,attr in ipairs({'Stamina','stamina','Energy','energy','Sprint','sprint'}) do local val=char:GetAttribute(attr) if val~=nil then pcall(function() char:SetAttribute(attr,100) end) end end end
local function applyFullbright() if Settings.Fullbright then Lighting.Ambient=Color3.new(1,1,1); Lighting.OutdoorAmbient=Color3.new(1,1,1); Lighting.Brightness=2; Lighting.FogEnd=100000; Lighting.GlobalShadows=false else Lighting.Ambient=OrigLighting.Ambient; Lighting.OutdoorAmbient=OrigLighting.OutdoorAmbient; Lighting.Brightness=OrigLighting.Brightness; Lighting.FogEnd=OrigLighting.FogEnd; Lighting.GlobalShadows=OrigLighting.GlobalShadows end end

RunService.Heartbeat:Connect(function()
    for target in pairs(ESPObjects) do if not target or not target.Parent then cleanupESP(target) end end
    local charPos=nil if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild('HumanoidRootPart') then charPos=LocalPlayer.Character.HumanoidRootPart.Position end
    if tick()-lastScanTime>=SCAN_INTERVAL then scanWorld() end
    if Settings.ESP_Players then for _,p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character and p.Character:FindFirstChild('HumanoidRootPart') then local hrp=p.Character.HumanoidRootPart if charPos and (hrp.Position-charPos).Magnitude>Settings.ESP_Radius then cleanupESP(hrp) else local hum=p.Character:FindFirstChildOfClass('Humanoid') local text=p.Name if Settings.ShowDistance and charPos then text=text..' ['..math.floor((hrp.Position-charPos).Magnitude)..'m]' end if Settings.ShowHealth and hum then text=text..' HP:'..math.floor(hum.Health) end addESP(hrp,text,Color3.fromRGB(0,255,100),Color3.fromRGB(0,200,80),Color3.fromRGB(0,255,100),Settings.Chams_Players) end end end else for _,p in ipairs(Players:GetPlayers()) do if p.Character and p.Character:FindFirstChild('HumanoidRootPart') then cleanupESP(p.Character.HumanoidRootPart) end end end
    if Settings.ESP_Monsters then for _,obj in ipairs(CachedMonsters) do if obj and obj.Parent and obj:FindFirstChild('HumanoidRootPart') then local hrp=obj.HumanoidRootPart if charPos and (hrp.Position-charPos).Magnitude>Settings.ESP_Radius then cleanupESP(hrp) else local text='MONSTER' if Settings.ShowDistance and charPos then text=text..' ['..math.floor((hrp.Position-charPos).Magnitude)..'m]' end addESP(hrp,text,Color3.fromRGB(255,50,50),Color3.fromRGB(200,0,0),Color3.fromRGB(255,80,80),Settings.Chams_Monsters) end end end else for _,obj in ipairs(CachedMonsters) do if obj and obj.Parent and obj:FindFirstChild('HumanoidRootPart') then cleanupESP(obj.HumanoidRootPart) end end end
    if Settings.ESP_Loot then for _,obj in ipairs(CachedLoot) do if obj and obj.Parent then local target=nil if obj:IsA('Model') then target=obj:FindFirstChildWhichIsA('BasePart') elseif obj:IsA('BasePart') then target=obj end if target and target:IsA('BasePart') then if charPos and (target.Position-charPos).Magnitude>Settings.ESP_Radius then cleanupESP(target) else local text='LOOT' if Settings.ShowDistance and charPos then text=text..' ['..math.floor((target.Position-charPos).Magnitude)..'m]' end addESP(target,text,Color3.fromRGB(255,220,0),Color3.fromRGB(200,180,0),Color3.fromRGB(255,240,100),Settings.Chams_Loot) end end end end else for _,obj in ipairs(CachedLoot) do if obj and obj.Parent then local target=nil if obj:IsA('Model') then target=obj:FindFirstChildWhichIsA('BasePart') elseif obj:IsA('BasePart') then target=obj end if target then cleanupESP(target) end end end end
    autoLoot(); applySpeed(); if Settings.NoSound then applyNoSound() end if Settings.InfiniteStamina then infiniteStamina() end applyFullbright()
end)

local MainTab=Window:CreateTab('ESP',4483362458)
MainTab:CreateToggle({Name='Player ESP',CurrentValue=true,Flag='ESP_Players',Callback=function(v)Settings.ESP_Players=v end})
MainTab:CreateToggle({Name='Player Chams',CurrentValue=true,Flag='Chams_Players',Callback=function(v)Settings.Chams_Players=v end})
MainTab:CreateToggle({Name='Monster ESP',CurrentValue=true,Flag='ESP_Monsters',Callback=function(v)Settings.ESP_Monsters=v end})
MainTab:CreateToggle({Name='Monster Chams',CurrentValue=true,Flag='Chams_Monsters',Callback=function(v)Settings.Chams_Monsters=v end})
MainTab:CreateToggle({Name='Loot ESP',CurrentValue=true,Flag='ESP_Loot',Callback=function(v)Settings.ESP_Loot=v end})
MainTab:CreateToggle({Name='Loot Chams',CurrentValue=true,Flag='Chams_Loot',Callback=function(v)Settings.Chams_Loot=v end})
MainTab:CreateSlider({Name='ESP Radius',Range={50,500},Increment=10,Suffix='studs',CurrentValue=300,Flag='ESP_Radius',Callback=function(v)Settings.ESP_Radius=v end})
MainTab:CreateToggle({Name='Show Distance',CurrentValue=true,Flag='ShowDistance',Callback=function(v)Settings.ShowDistance=v end})
MainTab:CreateToggle({Name='Show Health',CurrentValue=true,Flag='ShowHealth',Callback=function(v)Settings.ShowHealth=v end})
local LootTab=Window:CreateTab('Loot',4483362458)
LootTab:CreateToggle({Name='Auto Loot',CurrentValue=false,Flag='AutoLoot',Callback=function(v)Settings.AutoLoot=v end})
LootTab:CreateSlider({Name='Loot Radius',Range={10,200},Increment=5,Suffix='studs',CurrentValue=50,Flag='AutoLootRadius',Callback=function(v)Settings.AutoLootRadius=v end})
LootTab:CreateButton({Name='Teleport to Nearest Loot',Callback=function() local c=getNearestLootContainer() if c then local char=LocalPlayer.Character if char and char:FindFirstChild('HumanoidRootPart') then local pos=nil if c:IsA('Model') then pos=c:GetPivot().Position elseif c:IsA('BasePart') then pos=c.Position end if pos then char.HumanoidRootPart.CFrame=CFrame.new(pos+Vector3.new(0,3,0)) end end end end})
local MoveTab=Window:CreateTab('Movement',4483362458)
MoveTab:CreateToggle({Name='Speed Hack',CurrentValue=false,Flag='SpeedHack',Callback=function(v)Settings.SpeedHack=v end})
MoveTab:CreateSlider({Name='Walk Speed',Range={16,200},Increment=1,Suffix='ws',CurrentValue=50,Flag='WalkSpeed',Callback=function(v)Settings.WalkSpeed=v end})
MoveTab:CreateToggle({Name='Noclip',CurrentValue=false,Flag='Noclip',Callback=function(v) if v~=Settings.Noclip then toggleNoclip() end end})
MoveTab:CreateToggle({Name='No Sound (mute footsteps)',CurrentValue=false,Flag='NoSound',Callback=function(v)Settings.NoSound=v end})
MoveTab:CreateToggle({Name='Infinite Stamina',CurrentValue=false,Flag='InfiniteStamina',Callback=function(v)Settings.InfiniteStamina=v end})
MoveTab:CreateToggle({Name='Fullbright',CurrentValue=false,Flag='Fullbright',Callback=function(v)Settings.Fullbright=v; applyFullbright() end})
local VisualTab=Window:CreateTab('Visual',4483362458)
VisualTab:CreateButton({Name='Teleport to Nearest Exit',Callback=teleportToExit})
LocalPlayer.CharacterAdded:Connect(function(char) task.wait(1); applySpeed(); applyNoSound() end)
local LastDelta=0; RunService.Heartbeat:Connect(function(dt) LastDelta=dt end)
task.spawn(function() while true do task.wait(5) local ec=0 for _ in pairs(ESPObjects) do ec=ec+1 end local lc,mc=0,0 for _,o in ipairs(CachedLoot) do if o and o.Parent then lc=lc+1 end end for _,o in ipairs(CachedMonsters) do if o and o.Parent then mc=mc+1 end end local fps=LastDelta>0 and (1/LastDelta) or 0 warn(string.format('[HUSHESP DIAG] ESP=%d Loot=%d Monsters=%d FPS=%.1f',ec,lc,mc,fps)) end end)
print('[HUSHESP] ready — Rayfield loaded'); Rayfield:Notify({Title='HUSH ESP',Content='Loaded successfully',Duration=3})
