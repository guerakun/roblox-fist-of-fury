-- Nightfall District: authored, deterministic city built entirely with native Roblox geometry.
-- Forward is +X. The camera looks from +Z. Combat floor top is Y=0.
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local WorldBuilder = {}

local C = {
	ink = Color3.fromRGB(16, 22, 36), asphalt = Color3.fromRGB(31, 39, 51),
	concrete = Color3.fromRGB(69, 76, 88), silver = Color3.fromRGB(113, 137, 152),
	cyan = Color3.fromRGB(53, 224, 241), amber = Color3.fromRGB(255, 173, 70),
	red = Color3.fromRGB(242, 49, 85), white = Color3.fromRGB(222, 235, 233),
	blue = Color3.fromRGB(31, 68, 110), purple = Color3.fromRGB(129, 81, 208),
}

function WorldBuilder.Build()
	local existing = workspace:FindFirstChild("NightfallCity")
	if existing then existing:Destroy() end
	local city = Instance.new("Model")
	city.Name = "NightfallCity"
	city.Parent = workspace
	local random = Random.new(7319)
	local function folder(name)
		local f = Instance.new("Folder"); f.Name = name; f.Parent = city; return f
	end
	local streets, architecture, details, gates = folder("Streets"), folder("Architecture"), folder("StreetDetails"), folder("Gates")
	local function part(name, size, position, color, parent, material, collidable)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Position = name, size, position
		p.Anchored = true
		p.Color = color or C.ink
		p.Material = material or Enum.Material.SmoothPlastic
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.CanCollide = collidable == true
		p.CanTouch = collidable == true
		p.CastShadow = material ~= Enum.Material.Neon
		p.Parent = parent or details
		return p
	end
	local function sign(name, words, x, y, z, w, h, background, ink)
		local panel = part(name, Vector3.new(w, h, .35), Vector3.new(x, y, z), background, architecture)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Back; gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 32; gui.LightInfluence = 0; gui.MaxDistance = 230; gui.Parent = panel
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(.94, .88); label.Position = UDim2.fromScale(.03, .06)
		label.BackgroundTransparency = 1; label.Text = words; label.TextColor3 = ink or C.white
		label.Font = Enum.Font.GothamBold; label.TextScaled = true; label.TextWrapped = true; label.Parent = gui
		return panel
	end
	local function glow(name, size, pos, color, parent)
		return part(name, size, pos, color, parent, Enum.Material.Neon)
	end
	local function pointLight(host, color, brightness, range)
		local l = Instance.new("PointLight"); l.Color = color; l.Brightness = brightness
		l.Range = range; l.Shadows = false; l.Parent = host
	end
	local function beam(name, a, b, thickness, color, parent)
		local p = part(name, Vector3.new(thickness, thickness, (a-b).Magnitude), (a+b)/2, color, parent, Enum.Material.Metal)
		p.CFrame = CFrame.lookAt((a+b)/2, b); return p
	end

	-- Clear visibility takes priority over pitch-black atmosphere and excessive bloom.
	Lighting.ClockTime = 0.25
	Lighting.ExposureCompensation = 0.1
	Lighting.Brightness = 2.4
	Lighting.Ambient = Color3.fromRGB(126, 137, 158)
	Lighting.OutdoorAmbient = Color3.fromRGB(76, 87, 113)
	Lighting.ColorShift_Top = Color3.fromRGB(163, 192, 221)
	Lighting.EnvironmentDiffuseScale = .65
	Lighting.EnvironmentSpecularScale = .8
	for _, name in ipairs({"NightfallAtmosphere", "NightfallBloom", "NightfallGrade"}) do
		local old = Lighting:FindFirstChild(name); if old then old:Destroy() end
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "NightfallAtmosphere"; atmosphere.Density = .24; atmosphere.Offset = .1
	atmosphere.Color = Color3.fromRGB(109, 133, 173); atmosphere.Decay = Color3.fromRGB(35, 43, 70)
	atmosphere.Glare = .08; atmosphere.Haze = 1.3; atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "NightfallBloom"; bloom.Intensity = .14; bloom.Size = 28; bloom.Threshold = 1.1; bloom.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "NightfallGrade"; grade.Contrast = .08; grade.Saturation = -.08
	grade.TintColor = Color3.fromRGB(226, 237, 255); grade.Parent = Lighting

	part("CityFoundation", Vector3.new(1100, 7, 400), Vector3.new(270, -5.6, -30), C.ink, streets, Enum.Material.Asphalt, false)
	part("ContinuousCombatFloor", Vector3.new(560, 2, 30), Vector3.new(270, -1, 0), C.asphalt, streets, Enum.Material.Concrete, true)
	for x = -6, 546, 12 do
		part("PavementJoint", Vector3.new(.07, .018, 28), Vector3.new(x, .014, 0), C.ink, streets)
	end
	for _, z in ipairs({-15.5, 15.5}) do
		part("RaisedCurb", Vector3.new(560, .7, 2), Vector3.new(270, .25, z), C.concrete, streets, Enum.Material.Concrete, true)
		local edge = part("LaneBoundary", Vector3.new(562, 48, 1), Vector3.new(270, 23, z), C.ink, streets, nil, true)
		edge.Transparency = 1; edge.CastShadow = false
		for x = -6, 546, 12 do
			part("SafetyBollard", Vector3.new(.5, 2.6, .5), Vector3.new(x, 1.65, z), C.silver, details, Enum.Material.Metal)
			glow("BollardCap", Vector3.new(.54, .17, .54), Vector3.new(x, 3, z), z < 0 and C.cyan or C.amber)
			beam("GuardRail", Vector3.new(x, 2.3, z), Vector3.new(x+12, 2.3, z), .2, C.silver)
		end
	end
	local start = part("RouteEntranceStop", Vector3.new(2, 50, 32), Vector3.new(-9, 23, 0), C.ink, streets, nil, true)
	start.Transparency = 1
	-- The encounter system owns these single parts, including their collision and visibility.
	for index = 1, 3 do
		local gate = part("Gate"..index, Vector3.new(1, 36, 30), Vector3.new(index*180, 17, 0), C.red, gates, Enum.Material.ForceField, true)
		gate.Transparency = .65; gate:SetAttribute("Stage", index)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "NightfallSpawn"; spawn.Size = Vector3.new(7, 1, 7); spawn.Position = Vector3.new(14, 3, 0)
	spawn.Anchored = true; spawn.Transparency = 1; spawn.CanCollide = false; spawn.Neutral = true
	spawn.Duration = 0; spawn.Parent = city

	-- Distant silhouettes, roof crowns and selective lit windows give the skyline three depths.
	for x = -20, 560, 36 do
		local h, w = random:NextInteger(57, 112), random:NextInteger(22, 33)
		part("DistantTower", Vector3.new(w, h, 23), Vector3.new(x, h/2-2, -72), C.ink, architecture)
		part("RoofCrown", Vector3.new(w+1, 1.5, 25), Vector3.new(x, h-2, -72), C.blue, architecture)
		for wy = 12, h-8, 9 do
			for wx = -w/2+4, w/2-3, 7 do
				if random:NextNumber() > .34 then
					local lit = part("SkylineWindow", Vector3.new(2.7, 3.8, .15), Vector3.new(x+wx, wy, -60.4), C.blue, architecture)
					if random:NextNumber() > .8 then lit.Color = C.amber; lit.Material = Enum.Material.Neon end
				end
			end
		end
	end

	local function building(x, width, height, accent, name)
		local facade = Color3.fromRGB(random:NextInteger(38, 56), random:NextInteger(44, 61), random:NextInteger(61, 82))
		part(name, Vector3.new(width, height, 17), Vector3.new(x, height/2, -30), facade, architecture)
		part("StonePlinth", Vector3.new(width+.7, .7, 18), Vector3.new(x, .4, -29.7), C.silver, architecture)
		part("RoofLip", Vector3.new(width+1, .8, 18), Vector3.new(x, height, -30), C.concrete, architecture)
		for _, dx in ipairs({-width/2+.45, width/2-.45}) do
			part("FacadePilaster", Vector3.new(.55, height, .6), Vector3.new(x+dx, height/2, -21.2), C.concrete, architecture)
		end
		for y = 15, height-3, 8 do
			part("FloorCornice", Vector3.new(width, .32, .7), Vector3.new(x, y-3, -21.1), C.silver, architecture)
			for dx = -width/2+3.5, width/2-2, 5.5 do
				part("WindowFrame", Vector3.new(4.2, 5.4, .3), Vector3.new(x+dx, y, -21.25), C.ink, architecture)
				local lit = random:NextNumber() > .48
				part("OfficeGlass", Vector3.new(3.7, 4.8, .2), Vector3.new(x+dx, y, -21.02), lit and Color3.fromRGB(91, 124, 153) or C.blue, architecture, lit and Enum.Material.Neon or Enum.Material.Glass)
				part("WindowMullion", Vector3.new(.12, 4.8, .2), Vector3.new(x+dx, y, -20.85), C.ink, architecture)
			end
		end
		for dx = -width/2+3, width/2-2, 5 do
			part("ShopWindow", Vector3.new(4.4, 6.4, .3), Vector3.new(x+dx, 4, -21.05), C.blue, architecture, Enum.Material.Glass)
			glow("DisplayFootlight", Vector3.new(4.3, .2, .4), Vector3.new(x+dx, .85, -20.7), accent)
		end
		part("ShopCanopy", Vector3.new(width, .65, 4.5), Vector3.new(x, 8, -19.8), C.ink, architecture)
		glow("CanopyEdge", Vector3.new(width, .15, .25), Vector3.new(x, 8, -17.5), accent)
		return facade
	end

	-- I: crossing. Billboard canyon, striped pedestrian crossing and disrupted traffic.
	local first = {{13,25,52},{42,30,65},{75,29,44},{109,30,76},{145,33,53},{173,20,63}}
	for i, b in ipairs(first) do building(b[1],b[2],b[3], i%2==0 and C.amber or C.cyan,"CrossingBuilding"..i) end
	sign("DistrictMarquee", "渋谷\nSHIBUYA / NIGHTFALL", 75, 34, -20.3, 27, 12, C.ink, C.cyan)
	sign("EmergencyScreen", "21:31\nSTAY TOGETHER", 43, 43, -20.2, 27, 17, C.red, C.white)
	sign("CinemaBoard", "映画\nMIDNIGHT\nCINEMA", 109, 49, -20.2, 22, 24, C.purple, C.white)
	sign("CrossingWayfinding", "01  /  SCRAMBLE CROSSING   →", 104, 10, -17, 35, 2.4, C.ink, C.cyan)
	sign("NoodleShop", "らーめん    RAMEN", 16, 10.2, -20.1, 23, 3.5, C.amber, C.ink)
	sign("NightMarket", "コンビニ  /  OPEN 24H", 145, 10.2, -20.1, 30, 3.5, C.cyan, C.ink)
	for x = 52, 94, 6 do
		part("CrosswalkStripe", Vector3.new(3.7, .045, 25), Vector3.new(x, .032, 0), C.white, streets)
	end
	for x = 0, 530, 20 do
		if x < 45 or x > 101 then
			part("RoadDash", Vector3.new(7, .035, .28), Vector3.new(x, .025, 0), C.amber, streets)
		end
	end
	local function lamp(x, color)
		part("StreetlightPole", Vector3.new(.45, 15, .45), Vector3.new(x, 7.5, -14.8), C.silver, details, Enum.Material.Metal)
		part("StreetlightArm", Vector3.new(.45, .35, 4), Vector3.new(x, 15, -13), C.silver, details, Enum.Material.Metal)
		local light = glow("Streetlight", Vector3.new(1.6, .2, 3), Vector3.new(x, 14.7, -11.5), color)
		pointLight(light, color, 1.5, 28)
	end
	for x = 8, 532, 43 do lamp(x, x < 180 and C.cyan or x < 360 and C.amber or C.white) end
	part("TrafficSignalPost", Vector3.new(.45, 12, .45), Vector3.new(95, 6, -15), C.silver, details, Enum.Material.Metal)
	part("TrafficSignalBox", Vector3.new(2.2, 5.5, 1.1), Vector3.new(95, 12, -15), C.ink)
	for i, color in ipairs({C.red,C.amber,C.cyan}) do
		local bulb = glow("TrafficBulb",Vector3.new(1.1,1.1,.3),Vector3.new(95,14-i*1.4,-14.3),color)
		bulb.Shape = Enum.PartType.Ball
	end

	-- II: compressed shopping arcade. Individual storefronts, awnings, lanterns and overhead frames.
	local shops = {"古書 / BOOKS", "月 / MOON TEA", "ゲーム / ARCADE", "薬 / PHARMACY", "焼鳥 / YAKITORI", "音楽 / RECORDS"}
	for i = 1, 6 do
		local x = 194+(i-1)*28
		building(x,26,random:NextInteger(30,43),i%2==0 and C.cyan or C.amber,"ArcadeShop"..i)
		sign("ShopIdentity",shops[i],x,10,-20.2,24,3.2,i%2==0 and C.blue or C.red,C.white)
		for dx = -11, 11, 4 do
			part("AwningStripe",Vector3.new(2.1,.25,4),Vector3.new(x+dx,7.55,-18.7),C.amber,architecture)
		end
		for row = 1, 5 do
			part("RollerShutterSlat",Vector3.new(7,.13,.25),Vector3.new(x+7,1+row,-20.7),C.silver,architecture)
		end
		sign("BladeSign", i%2==0 and "商\n店\n街" or "夜\n市",x+10,20,-19.5,3.4,12,C.ink,i%2==0 and C.cyan or C.amber)
	end
	for x = 184, 352, 28 do
		part("ArcadeRearColumn",Vector3.new(.5,20,.5),Vector3.new(x,10,-16.3),C.blue,architecture)
		beam("ArcadeRoofRib",Vector3.new(x,20,-17),Vector3.new(x,23,-4),.35,C.silver,architecture)
		beam("ArcadeRoofSpine",Vector3.new(x,23,-4),Vector3.new(math.min(x+28,360),23,-4),.35,C.silver,architecture)
		beam("LanternWire",Vector3.new(x,17,-17),Vector3.new(x+23,17,-17),.06,C.ink)
		for dx = 4, 24, 8 do
			part("LanternCord",Vector3.new(.06,2,.06),Vector3.new(x+dx,16,-17),C.ink)
			local lantern = glow("PaperLantern",Vector3.new(1.6,2.4,1.6),Vector3.new(x+dx,14.7,-17),C.amber)
			lantern.Shape = Enum.PartType.Ball
			part("LanternCap",Vector3.new(1,.15,1),Vector3.new(x+dx,15.8,-17),C.red)
		end
	end
	sign("ArcadeEntry", "02   道玄坂 / DOGENZAKA ARCADE", 230, 24, -18, 54, 4.2, C.ink, C.amber)

	-- III: station apron. Platform and stairs are behind the playable lane, never a navigation trap.
	part("StationMainHall",Vector3.new(172,36,28),Vector3.new(450,18,-35),C.concrete,architecture)
	part("StationGlassBand",Vector3.new(168,12,.4),Vector3.new(450,24,-20.6),C.blue,architecture,Enum.Material.Glass)
	for x = 368, 532, 12 do
		part("StationMullion",Vector3.new(.6,13,.5),Vector3.new(x,24,-20.1),C.silver,architecture)
		part("StationSupport",Vector3.new(1.4,18,2),Vector3.new(x,9,-20.2),C.ink,architecture)
	end
	part("StationCanopy",Vector3.new(176,.7,11),Vector3.new(450,16,-18),C.ink,architecture)
	glow("StationCanopyLight",Vector3.new(173,.2,.3),Vector3.new(450,15.6,-12.5),C.cyan)
	sign("StationMainIdentity","渋谷駅  /  SHIBUYA STATION",450,33,-20,136,5,C.ink,C.white)
	sign("StationRoute","03  /  LAST TRAIN     →     EXIT 13",455,13,-12.2,74,3,C.ink,C.cyan)
	sign("StationExitNumber","13\nEXIT",383,9,-19,7,8,C.amber,C.ink)
	for step = 1, 8 do
		part("StationStair",Vector3.new(18,step*.55,1.3),Vector3.new(398,step*.275,-17-step*1.3),C.silver,architecture)
	end
	beam("StairHandrailLeft",Vector3.new(388.5,3,-18),Vector3.new(388.5,7,-28),.22,C.cyan)
	beam("StairHandrailRight",Vector3.new(407.5,3,-18),Vector3.new(407.5,7,-28),.22,C.cyan)
	part("Platform",Vector3.new(111,3,11),Vector3.new(477,1.5,-27),C.concrete,architecture)
	glow("PlatformTactileStrip",Vector3.new(108,.08,.9),Vector3.new(477,3.06,-21.7),C.amber)
	part("TrainBody",Vector3.new(82,9,8),Vector3.new(481,8,-32),C.silver,architecture,Enum.Material.Metal)
	part("TrainLivery",Vector3.new(82,1,.25),Vector3.new(481,6,-27.8),C.cyan,architecture)
	for x = 446, 513, 10 do
		part("TrainWindow",Vector3.new(6,3,.3),Vector3.new(x,9,-27.7),C.ink,architecture,Enum.Material.Glass)
		glow("TrainCeilingLight",Vector3.new(5,.12,.2),Vector3.new(x,10.5,-27.4),C.white)
	end
	sign("DepartureBoard","SERVICE SUSPENDED\nすべての運行を見合わせています",470,20,-19.8,34,5,C.ink,C.amber)

	-- The curtain is scenic at the far BACK; all forward locking belongs to Gate3.
	local curtain = part("StationCurseCurtain",Vector3.new(42,28,.6),Vector3.new(511,14,-19.3),C.purple,architecture,Enum.Material.ForceField)
	curtain.Transparency = .34
	for x = 492, 530, 3.8 do
		local slash = glow("CurtainSeam",Vector3.new(.09,random:NextInteger(12,25),.1),Vector3.new(x,14,-18.8),C.red)
		slash.CFrame *= CFrame.Angles(0,0,math.rad(random:NextInteger(-13,13)))
	end
	sign("CurtainSeal","帳\nBREAK THE SEAL",510,18,-18.6,17,9,C.ink,C.red)

	-- Street dressing stays outside the main central combat lane, with destructible metadata.
	local function vending(x, accent)
		local body = part("VendingMachine",Vector3.new(3.4,6,2.2),Vector3.new(x,3,-12.1),C.blue)
		body:SetAttribute("Destructible",true); body:SetAttribute("Health",40); body:SetAttribute("PropKind","Vending")
		CollectionService:AddTag(body,"Destructible")
		part("VendingGlass",Vector3.new(2.7,3.4,.18),Vector3.new(x,3.8,-10.9),C.ink)
		for y = 2.7, 4.8, 1 do
			for dx = -.8, .8, .8 do
				glow("DrinkBottle",Vector3.new(.4,.65,.2),Vector3.new(x+dx,y,-10.7),accent)
			end
		end
		part("VendingSlot",Vector3.new(1.8,.5,.2),Vector3.new(x,1,-10.8),C.ink)
	end
	for _, x in ipairs({33,129,215,303,426}) do vending(x,x%2==0 and C.cyan or C.amber) end
	for _, x in ipairs({25,115,166,203,281,336,380,443,528}) do
		local prop = part("StreetUtilityBox",Vector3.new(2,2.8,1.7),Vector3.new(x,1.4,11.8),C.concrete)
		prop:SetAttribute("Destructible",true); prop:SetAttribute("Health",25); prop:SetAttribute("PropKind","Utility")
		CollectionService:AddTag(prop,"Destructible")
		for y = 1, 2.1, .3 do part("UtilityVent",Vector3.new(1.4,.09,.1),Vector3.new(x,y,12.7),C.ink) end
		glow("UtilityIndicator",Vector3.new(.18,.18,.1),Vector3.new(x+.55,2.45,12.7),C.amber)
	end
	for _, x in ipairs({44,151,246,323,412,480}) do
		part("BenchSeat",Vector3.new(6,.35,1.7),Vector3.new(x,1.5,-12.2),C.concrete)
		part("BenchBack",Vector3.new(6,1.3,.25),Vector3.new(x,2.2,-12.9),C.blue)
		for _, dx in ipairs({-2,2}) do part("BenchLeg",Vector3.new(.25,1.4,1.4),Vector3.new(x+dx,.7,-12.2),C.silver) end
	end
	for x = 5, 530, 17 do
		local wet = part("RainReflection",Vector3.new(random:NextNumber(2,6),.012,random:NextNumber(.3,1.2)),Vector3.new(x,.015,random:NextNumber(-10,10)),x<180 and C.cyan or x<360 and C.amber or C.purple,streets,Enum.Material.Glass)
		wet.Transparency = .75; wet.Reflectance = .12
	end
	for _, x in ipairs({170,350,534}) do
		for z = -11, 11, 5.5 do
			local arrow = part("ForwardChevron",Vector3.new(.2,.04,2.6),Vector3.new(x,.035,z),C.amber,streets)
			arrow.CFrame *= CFrame.Angles(0,math.rad(40),0)
			local other = arrow:Clone(); other.Position += Vector3.new(0,0,1.8); other.CFrame *= CFrame.Angles(0,math.rad(-80),0); other.Parent = streets
		end
	end
	city:SetAttribute("RouteLength",540)
	city:SetAttribute("BuildVersion","Nightfall-1")
	return city
end

return WorldBuilder
