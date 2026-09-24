-- Nightfall District: authored, deterministic city built entirely with native Roblox geometry.
-- Forward is +X. The camera looks from +Z. Combat floor top is Y=0.
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")
local Config = require(game.ReplicatedStorage.Nightfall.Shared.Config)
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
		-- Visual geometry cannot consume server combat spatial-query results.
		p.CanQuery = collidable == true
		p.CastShadow = material ~= Enum.Material.Neon
		p.Parent = parent or details
		return p
	end
	local function sign(name, words, x, y, z, w, h, background, ink)
		local panel = part(name, Vector3.new(w, h, .35), Vector3.new(x, y, z), background, architecture)
		local gui = Instance.new("SurfaceGui")
		gui.Face = Enum.NormalId.Back; gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 32; gui.LightInfluence = 0; gui.MaxDistance = 320; gui.Parent = panel
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
	local function destructible(name, kind, health)
		local assembly = Instance.new("Model")
		assembly.Name = name
		assembly:SetAttribute("Destructible", true)
		assembly:SetAttribute("PropKind", kind)
		assembly:SetAttribute("Health", health)
		assembly:SetAttribute("Broken", false)
		assembly.Parent = details
		CollectionService:AddTag(assembly, "Destructible")
		return assembly
	end
	local function beam(name, a, b, thickness, color, parent)
		local p = part(name, Vector3.new(thickness, thickness, (a-b).Magnitude), (a+b)/2, color, parent, Enum.Material.Metal)
		p.CFrame = CFrame.lookAt((a+b)/2, b); return p
	end

	local function tube(name, a, b, diameter, color, parent, material)
		local p = part(name, Vector3.new((a-b).Magnitude, diameter, diameter), (a+b)/2, color, parent, material or Enum.Material.Metal)
		p.Shape = Enum.PartType.Cylinder
		p.CFrame = CFrame.lookAt((a+b)/2, b) * CFrame.Angles(0, math.pi/2, 0)
		return p
	end
	local function hazardStripe(x, y, z, width, parent)
		part("HazardBacking",Vector3.new(width,.8,.15),Vector3.new(x,y,z),C.ink,parent)
		for dx = -width/2+.6, width/2-.4, 1.5 do
			local stripe = part("WarningStripe",Vector3.new(.45,.85,.18),Vector3.new(x+dx,y,z+.1),C.amber,parent)
			stripe.CFrame *= CFrame.Angles(0,0,math.rad(-28))
		end
	end
	local function steam(name, position, color)
		local anchor = part(name,Vector3.one*.15,position,C.ink,details)
		anchor.Transparency=1; anchor.CanQuery=false
		local attachment=Instance.new("Attachment",anchor)
		local smoke=Instance.new("ParticleEmitter",attachment)
		smoke.Texture="rbxasset://textures/particles/smoke_main.dds"
		smoke.Color=ColorSequence.new(color)
		smoke.Rate=3; smoke.Lifetime=NumberRange.new(1.5,2.5); smoke.Speed=NumberRange.new(1,2)
		smoke.Size=NumberSequence.new({NumberSequenceKeypoint.new(0,.4),NumberSequenceKeypoint.new(1,3.5)})
		smoke.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(.2,.78),NumberSequenceKeypoint.new(1,1)})
		smoke.SpreadAngle=Vector2.new(18,18); smoke.Acceleration=Vector3.new(0,1,0)
	end

	-- Clear visibility takes priority over pitch-black atmosphere and excessive bloom.
	Lighting.ClockTime = 0.25
	Lighting.ExposureCompensation = 0
	Lighting.Brightness = 1.85
	Lighting.Ambient = Color3.fromRGB(84, 90, 106)
	Lighting.OutdoorAmbient = Color3.fromRGB(96, 102, 118)
	Lighting.ColorShift_Top = Color3.new(0, 0, 0)
	Lighting.ColorShift_Bottom = Color3.new(0, 0, 0)
	-- Night hue comes from modest ambient and local practicals, preserving hero albedo.
	Lighting.EnvironmentDiffuseScale = .55
	Lighting.EnvironmentSpecularScale = .45
	for _, name in ipairs({"NightfallAtmosphere", "NightfallBloom", "NightfallGrade"}) do
		local old = Lighting:FindFirstChild(name); if old then old:Destroy() end
	end
	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "NightfallAtmosphere"; atmosphere.Density = .24; atmosphere.Offset = .1
	atmosphere.Color = Color3.fromRGB(109, 133, 173); atmosphere.Decay = Color3.fromRGB(35, 43, 70)
	atmosphere.Glare = .08; atmosphere.Haze = 1.3; atmosphere.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "NightfallBloom"; bloom.Intensity = .1; bloom.Size = 24; bloom.Threshold = 1.3; bloom.Parent = Lighting
	local grade = Instance.new("ColorCorrectionEffect")
	grade.Name = "NightfallGrade"; grade.Contrast = .04; grade.Saturation = 0
	grade.TintColor = Color3.fromRGB(250, 251, 255); grade.Parent = Lighting

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
	for x = -20, 176, 36 do
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
	sign("DistrictMarquee", "ASHGATE\nCROSSING / NIGHTFALL", 75, 34, -20.3, 27, 12, C.ink, C.cyan)
	sign("EmergencyScreen", "21:31\nSTAY TOGETHER", 43, 43, -20.2, 27, 17, C.red, C.white)
	sign("CinemaBoard", "映画\nMIDNIGHT\nCINEMA", 109, 49, -20.2, 22, 24, C.purple, C.white)
	sign("CrossingWayfinding", "01  /  SCRAMBLE CROSSING   →", 104, 10, -17, 35, 2.4, C.ink, C.cyan)
	sign("NoodleShop", "らーめん    RAMEN", 16, 10.2, -20.1, 23, 3.5, C.amber, C.ink)
	sign("NightMarket", "コンビニ  /  OPEN 24H", 145, 10.2, -20.1, 30, 3.5, C.cyan, C.ink)
	for x = 52, 94, 6 do
		part("CrosswalkStripe", Vector3.new(3.7, .045, 25), Vector3.new(x, .032, 0), C.white, streets)
	end
	for x = 0, 170, 20 do
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
	for x = 8, 177, 43 do lamp(x, C.cyan) end
	local traffic = destructible("CrossingSignalAssembly", "TrafficSignal", 35)
	traffic.PrimaryPart = part("TrafficSignalPost", Vector3.new(.45, 12, .45), Vector3.new(75, 6, -15), C.silver, traffic, Enum.Material.Metal)
	part("TrafficSignalBox", Vector3.new(2.2, 5.5, 1.1), Vector3.new(75, 12, -15), C.ink, traffic)
	for i, color in ipairs({C.red,C.amber,C.cyan}) do
		local bulb = glow("TrafficBulb",Vector3.new(1.1,1.1,.3),Vector3.new(75,14-i*1.4,-14.3),color,traffic)
		bulb.Shape = Enum.PartType.Ball
	end

	-- II: a cutaway abandoned station. The roof never covers the foreground camera sightline.
	local stationBlue = Color3.fromRGB(37,68,79)
	local oldTile = Color3.fromRGB(99,113,116)
	local rust = Color3.fromRGB(98,62,48)
	part("StationLaneSurface",Vector3.new(178,.045,28),Vector3.new(270,.015,0),oldTile,streets,Enum.Material.Concrete)
	for x=184,356,8 do
		part("PlatformTileJoint",Vector3.new(.055,.025,28),Vector3.new(x,.052,0),C.ink,streets)
	end
	for z=-12,12,6 do
		part("PlatformTileJoint",Vector3.new(178,.025,.055),Vector3.new(270,.052,z),C.ink,streets)
	end
	part("TactilePlatformLine",Vector3.new(176,.055,1.2),Vector3.new(270,.065,-12.9),C.amber,streets)
	for x=187,354,7 do
		part("TactileSegment",Vector3.new(.12,.03,1.25),Vector3.new(x,.1,-12.9),rust,streets)
	end
	part("StationBackWall",Vector3.new(178,37,2),Vector3.new(270,17,-48),stationBlue,architecture,Enum.Material.Concrete)
	part("StationDado",Vector3.new(178,8,1),Vector3.new(270,3,-46.6),oldTile,architecture,Enum.Material.Concrete)
	part("StationBackPlatform",Vector3.new(174,2.4,12),Vector3.new(270,1.2,-39),C.concrete,architecture,Enum.Material.Concrete)
	for x=184,356,14 do
		part("StationWallTileJoint",Vector3.new(.08,8,.15),Vector3.new(x,3,-46),stationBlue,architecture)
		part("StationPier",Vector3.new(1.5,29,2.5),Vector3.new(x,14.5,-21),C.concrete,architecture,Enum.Material.Concrete)
		part("StationPierBase",Vector3.new(2.1,1.2,3.1),Vector3.new(x,.6,-21),stationBlue,architecture)
		part("PierTileBand",Vector3.new(1.6,2.2,2.6),Vector3.new(x,4.5,-21),stationBlue,architecture)
		beam("StationRoofTruss",Vector3.new(x,29,-20),Vector3.new(x,35,-36),.6,C.silver,architecture)
		beam("StationRoofTruss",Vector3.new(x,35,-36),Vector3.new(x,29,-48),.6,C.silver,architecture)
		beam("StationRoofTie",Vector3.new(x,27,-21),Vector3.new(x,27,-48),.35,C.silver,architecture)
	end
	for _,z in ipairs({-22,-35,-46}) do
		beam("StationLongitudinalBeam",Vector3.new(180,29,z),Vector3.new(360,29,z),.65,C.ink,architecture)
	end
	-- Partial roof strips imply a tunnel while leaving the player view completely open.
	part("StationRearRoof",Vector3.new(178,.5,10),Vector3.new(270,32,-44),C.ink,architecture,Enum.Material.Metal)
	for x=196,350,28 do
		part("BrokenRoofPane",Vector3.new(11,.16,8),Vector3.new(x,32,-31),stationBlue,architecture,Enum.Material.Glass).Transparency=.45
	end
	for x=190,350,32 do
		local fixture=glow("FluorescentTube",Vector3.new(10,.18,.5),Vector3.new(x,14,-18.5),C.cyan)
		part("FluorescentBracket",Vector3.new(11,.4,1),Vector3.new(x,14.25,-18.5),C.ink)
		pointLight(fixture,C.cyan,.9,29)
	end
	-- Rails and sleepers occupy the rear track bed, not the lane.
	part("TrackBallast",Vector3.new(177,1,11),Vector3.new(270,-.2,-28),C.ink,architecture,Enum.Material.Slate)
	for x=184,358,5 do part("RailSleeper",Vector3.new(1.5,.3,9),Vector3.new(x,.35,-28),rust,architecture,Enum.Material.Wood) end
	for _,z in ipairs({-25.1,-30.9}) do
		part("TrackRail",Vector3.new(179,.35,.35),Vector3.new(270,.6,z),C.silver,architecture,Enum.Material.Metal)
	end
	local function abandonedCar(x,length,derailed)
		local train=Instance.new("Model");train.Name="AbandonedMetroCar";train.Parent=architecture
		part("TrainUnderframe",Vector3.new(length,1.6,7),Vector3.new(x,2.3,-28),C.ink,train,Enum.Material.Metal)
		part("TrainBody",Vector3.new(length,8.4,8),Vector3.new(x,7.2,-28),oldTile,train,Enum.Material.Metal)
		part("TrainRoof",Vector3.new(length+.3,.55,8.5),Vector3.new(x,11.6,-28),C.silver,train,Enum.Material.Metal)
		part("TrainLivery",Vector3.new(length,.9,.2),Vector3.new(x,4.7,-23.85),stationBlue,train)
		for dx=-length/2+4,length/2-3,8 do
			part("TrainWindowFrame",Vector3.new(5.4,3.3,.3),Vector3.new(x+dx,8.1,-23.8),C.ink,train)
			part("TrainWindow",Vector3.new(4.8,2.8,.15),Vector3.new(x+dx,8.1,-23.55),C.blue,train,Enum.Material.Glass)
			beam("BrokenGlassCrack",Vector3.new(x+dx-1.5,7,-23.4),Vector3.new(x+dx+.4,9.2,-23.4),.055,C.silver,train)
		end
		for _,dx in ipairs({-length*.23,length*.23}) do
			part("MetroDoorRecess",Vector3.new(5.3,6.6,.25),Vector3.new(x+dx,6.8,-23.4),C.ink,train)
			part("MetroDoorLeaf",Vector3.new(2.1,6.2,.2),Vector3.new(x+dx+1.5,6.8,-23.2),C.concrete,train)
			part("MetroDoorWindow",Vector3.new(1.4,2.5,.15),Vector3.new(x+dx+1.5,8.3,-23),stationBlue,train)
		end
		for _,dx in ipairs({-length*.32,length*.32}) do
			tube("WheelAxle",Vector3.new(x+dx,1.6,-23.6),Vector3.new(x+dx,1.6,-32.4),1.1,C.ink,train)
		end
		if derailed then train:PivotTo(train:GetPivot()*CFrame.Angles(0,0,math.rad(-3))) end
	end
	abandonedCar(227,64,false)
	abandonedCar(315,61,true)
	-- Ticket gate and stairs are scenic behind the combat band.
	for x=187,207,5 do
		part("TicketGate",Vector3.new(2.3,3.8,5),Vector3.new(x,1.9,-17.6),C.silver,architecture,Enum.Material.Metal)
		glow("TicketReader",Vector3.new(1.2,.12,.8),Vector3.new(x,3.86,-16.4),C.red)
	end
	for step=1,9 do
		part("StationStair",Vector3.new(14,step*.5,1.2),Vector3.new(281,step*.25,-17-step*1.2),C.silver,architecture)
	end
	beam("StationHandrail",Vector3.new(273.6,3,-17),Vector3.new(273.6,7,-28),.2,C.silver)
	beam("StationHandrail",Vector3.new(288.4,3,-17),Vector3.new(288.4,7,-28),.2,C.silver)
	sign("StationChapter","02 / ABANDONED STATION",211,20,-18,52,4,C.ink,C.cyan)
	sign("StationExit13","13\nEXIT CLOSED",190,9,-16.1,8,6,C.amber,C.ink)
	sign("StationSuspended","ASHGATE TRANSIT\nALL SERVICES SUSPENDED",269,22,-20,46,6,C.ink,C.white)
	sign("PlatformNumber","04\nLAST DEPARTURE",316,17,-18,15,7,C.ink,C.cyan)
	sign("StationRoute","MAINTENANCE ACCESS →  INDUSTRIAL LINE",321,12,-17.5,43,2.5,stationBlue,C.white)
	-- A clock stopped at the evacuation time and a torn timetable imply sudden abandonment.
	local clockFace=part("StationClock",Vector3.new(.3,4.8,4.8),Vector3.new(255,18,-17.7),C.white,architecture)
	clockFace.Shape=Enum.PartType.Cylinder;clockFace.CFrame*=CFrame.Angles(0,math.pi/2,0)
	beam("ClockMinute",Vector3.new(255,18,-17.4),Vector3.new(255,16.2,-17.4),.12,C.ink)
	beam("ClockHour",Vector3.new(255,18,-17.4),Vector3.new(253.6,18.3,-17.4),.18,C.ink)
	steam("StationPipeLeak",Vector3.new(270,1,-20),C.silver)

	-- III: abandoned industrial works. Sawtooth roof, gantry, boilers and a furnace destination.
	local factorySteel=Color3.fromRGB(69,74,74)
	local factoryRust=Color3.fromRGB(116,70,48)
	local factoryFloor=Color3.fromRGB(66,65,62)
	part("FactoryLaneSurface",Vector3.new(178,.045,28),Vector3.new(450,.015,0),factoryFloor,streets,Enum.Material.Concrete)
	part("FactoryRearWall",Vector3.new(180,32,2),Vector3.new(450,15,-47),factoryRust,architecture,Enum.Material.CorrodedMetal)
	part("FactoryWallBase",Vector3.new(180,5,3),Vector3.new(450,2,-46),C.concrete,architecture,Enum.Material.Concrete)
	for x=365,538,8 do
		part("CorrugatedWallRib",Vector3.new(.2,25,.6),Vector3.new(x,18,-45.8),factorySteel,architecture,Enum.Material.Metal)
	end
	for x=369,535,24 do
		part("FactoryIBeam",Vector3.new(1.1,33,1.7),Vector3.new(x,16,-19),C.ink,architecture,Enum.Material.Metal)
		for _,z in ipairs({-18.1,-19.9}) do part("IBeamFlange",Vector3.new(2.2,33,.2),Vector3.new(x,16,z),factorySteel,architecture,Enum.Material.Metal) end
		part("ColumnFoot",Vector3.new(3,1,3.5),Vector3.new(x,.5,-19),C.concrete,architecture)
		hazardStripe(x,4,-17.9,2)
		beam("SawtoothTruss",Vector3.new(x,31,-19),Vector3.new(x,39,-37),.65,factorySteel,architecture)
		beam("SawtoothTruss",Vector3.new(x,39,-37),Vector3.new(x,31,-47),.65,factorySteel,architecture)
		beam("FactoryRoofTie",Vector3.new(x,29,-19),Vector3.new(x,29,-47),.4,factorySteel,architecture)
		part("FactoryClerestory",Vector3.new(18,5,.3),Vector3.new(x+8,30,-45.7),C.blue,architecture,Enum.Material.Glass)
		for dx=1,16,5 do part("ClerestoryMullion",Vector3.new(.15,5,.35),Vector3.new(x+dx,30,-45.4),C.ink,architecture) end
	end
	beam("GantryFrontTrack",Vector3.new(363,27,-19),Vector3.new(537,27,-19),.7,C.amber,architecture)
	beam("GantryBackTrack",Vector3.new(363,27,-40),Vector3.new(537,27,-40),.7,C.amber,architecture)
	part("OverheadCrane",Vector3.new(6,2.5,24),Vector3.new(460,27,-29.5),factoryRust,architecture,Enum.Material.Metal)
	hazardStripe(460,27,-17.3,6)
	tube("CraneCable",Vector3.new(460,26,-24),Vector3.new(460,16,-24),.08,C.silver)
	beam("CraneHookStem",Vector3.new(460,16,-24),Vector3.new(460,14.5,-24),.45,factorySteel)
	beam("CraneHookJaw",Vector3.new(460,14.5,-24),Vector3.new(461.7,14,-24),.45,factorySteel)
	beam("CraneHookTip",Vector3.new(461.7,14,-24),Vector3.new(462.3,15.2,-24),.45,factorySteel)
	-- Service catwalk spans the machinery at the rear, with its own visual railing and staircase.
	part("RearServiceCatwalk",Vector3.new(106,.7,5),Vector3.new(424,13,-38),factorySteel,architecture,Enum.Material.DiamondPlate)
	for x=373,475,8 do
		part("CatwalkPost",Vector3.new(.17,2.7,.17),Vector3.new(x,14.7,-35.6),C.amber)
	end
	beam("CatwalkRail",Vector3.new(371,16,-35.6),Vector3.new(477,16,-35.6),.17,C.amber)
	for step=1,12 do
		part("SteelServiceStair",Vector3.new(1.2,.35,4),Vector3.new(369+step*1.2,step,-31),factorySteel,architecture,Enum.Material.DiamondPlate)
	end
	beam("StairRail",Vector3.new(370,3,-28.8),Vector3.new(384,15,-28.8),.15,C.amber)
	local function tank(x,radius,height)
		tube("PressureTank",Vector3.new(x,1,-28),Vector3.new(x,height,-28),radius*2,factorySteel,architecture)
		for _,y in ipairs({2,height*.5,height-1}) do
			tube("TankBand",Vector3.new(x,y-.18,-28),Vector3.new(x,y+.18,-28),radius*2+.35,C.silver,architecture)
		end
		tube("TankOutlet",Vector3.new(x+radius,4,-28),Vector3.new(x+radius+3,4,-28),.8,factoryRust,architecture)
		tube("TankValve",Vector3.new(x+radius+2,4,-27.5),Vector3.new(x+radius+2,4,-26.8),2,C.red,architecture)
		part("TankMeter",Vector3.new(1.6,1.2,.3),Vector3.new(x,8,-28+radius+.1),C.ink,architecture)
		glow("MeterReading",Vector3.new(1,.09,.1),Vector3.new(x,8,-28+radius+.3),C.amber)
	end
	tank(394,4,18); tank(414,3.3,15)
	tube("SteamHeader",Vector3.new(367,20,-22),Vector3.new(472,20,-22),1.1,factoryRust,architecture)
	for x=388,456,34 do
		tube("SteamDrop",Vector3.new(x,20,-22),Vector3.new(x,5,-22),.65,factoryRust,architecture)
		for y=6,19,4 do tube("PipeClamp",Vector3.new(x,y-.12,-22),Vector3.new(x,y+.12,-22),.95,C.silver,architecture) end
	end
	part("AssemblyConveyor",Vector3.new(41,2,7),Vector3.new(444,2,-26),C.ink,architecture,Enum.Material.Metal)
	for x=425,463,2.8 do tube("ConveyorRoller",Vector3.new(x,3.2,-22.5),Vector3.new(x,3.2,-29.5),.5,C.silver,architecture) end
	hazardStripe(444,2,-22.2,40)
	for _,x in ipairs({430,444,459}) do part("UnfinishedMachineHousing",Vector3.new(5,3,4),Vector3.new(x,5,-26),factoryRust,architecture,Enum.Material.CorrodedMetal) end
	-- Furnace is a strong round silhouette with an emissive core, rather than a generic box boss wall.
	part("FurnaceFoundation",Vector3.new(36,2,15),Vector3.new(505,1,-29),C.concrete,architecture)
	tube("FurnaceChamber",Vector3.new(505,12,-36),Vector3.new(505,12,-23),22,factorySteel,architecture)
	tube("FurnaceMouthRim",Vector3.new(505,12,-23.2),Vector3.new(505,12,-22.2),19,C.ink,architecture)
	tube("FurnaceMouth",Vector3.new(505,12,-22.1),Vector3.new(505,12,-21.9),16,Color3.fromRGB(255,102,35),architecture,Enum.Material.Neon)
	tube("FurnaceCore",Vector3.new(505,12,-21.8),Vector3.new(505,12,-21.6),11,C.amber,architecture,Enum.Material.Neon)
	for _,dx in ipairs({-6,-3,0,3,6}) do
		part("FurnaceGrate",Vector3.new(.6,16,.5),Vector3.new(505+dx,12,-21.2),C.ink,architecture,Enum.Material.Metal)
	end
	local furnaceLight=glow("FurnaceLightSource",Vector3.one*.3,Vector3.new(505,9,-18.5),C.amber)
	furnaceLight.Transparency=1;pointLight(furnaceLight,C.amber,2.1,44)
	tube("FurnaceFlue",Vector3.new(505,22,-30),Vector3.new(505,52,-30),4,factoryRust,architecture)
	for y=27,51,8 do tube("FlueBand",Vector3.new(505,y-.2,-30),Vector3.new(505,y+.2,-30),4.4,C.ink,architecture) end
	steam("SteamRelease",Vector3.new(431,4,-20),C.silver)
	steam("FurnaceExhaust",Vector3.new(505,53,-30),Color3.fromRGB(106,96,94))
	for _,x in ipairs({378,426,474,528}) do
		local lamp=glow("FactoryWorkLight",Vector3.new(4,.25,1.4),Vector3.new(x,15,-16.8),C.amber)
		pointLight(lamp,C.amber,.85,29)
	end
	sign("FactoryChapter","03 / ABANDONED FACTORY",395,23,-18,57,4,C.ink,C.amber)
	sign("FactoryName","黒鉄 / KUROGANE WORKS",447,34,-20,73,6,C.ink,C.white)
	sign("FurnaceWarning","FURNACE 03\nPRESSURE CRITICAL",505,26,-20,26,5,C.red,C.white)
	sign("FactoryExit","EMERGENCY CUT-OFF →",518,5,-17,24,2.5,C.ink,C.amber)
	for x=368,535,12 do
		for _,z in ipairs({-11.5,11.5}) do
			part("FactorySafetyDash",Vector3.new(6,.045,.4),Vector3.new(x,.065,z),C.amber,streets)
		end
	end

	-- Second composition pass: depth layers, asymmetry and abandonment beyond the safe lane.
	local moss=Color3.fromRGB(42,69,54)
	local grime=Color3.fromRGB(40,46,44)
	local backConcrete=Color3.fromRGB(50,64,74)
	local function fracture(x,y,z,width,height,color,parent)
		-- Three connected, fine fractures read as damage without dense tile-by-tile geometry.
		local a=Vector3.new(x-width*.4,y+height*.45,z)
		local b=Vector3.new(x+width*.12,y+height*.06,z)
		local c=Vector3.new(x-width*.08,y-height*.16,z)
		local d=Vector3.new(x+width*.32,y-height*.46,z)
		beam("SurfaceFracture",a,b,.075,color,parent)
		beam("SurfaceFracture",b,c,.075,color,parent)
		beam("SurfaceFracture",c,d,.075,color,parent)
	end
	local function ivy(x,y,z,length)
		beam("HangingVine",Vector3.new(x,y,z),Vector3.new(x+.8,y-length,z+.15),.075,moss)
		for index=0,4 do
			local leaf=part("IvyCluster",Vector3.new(1.1,.65,.18),Vector3.new(x+(index%2==0 and -.35 or .65),y-index*length/5,z+.2),moss,details)
			leaf.CFrame*=CFrame.Angles(0,0,index%2==0 and -.35 or .4)
		end
	end
	local function rubblePile(x,z,color)
		for index=1,5 do
			local rock=part("StaticRubble",Vector3.new(random:NextNumber(.6,1.8),random:NextNumber(.3,.85),random:NextNumber(.5,1.4)),Vector3.new(x+random:NextNumber(-2,2),.35,z+random:NextNumber(-1,1)),color,details,Enum.Material.Concrete)
			rock.CFrame*=CFrame.Angles(random:NextNumber(-.3,.3),random:NextNumber(-2,2),random:NextNumber(-.3,.3))
		end
	end
	-- Street remnants beyond the station roof show that this is a city terminal, not a floating diorama.
	part("StationRetainingStructure",Vector3.new(177,47,7),Vector3.new(271,26,-62),backConcrete,architecture,Enum.Material.Concrete)
	for x=190,350,32 do
		part("RetainingButtress",Vector3.new(3,52,9),Vector3.new(x,27,-60),C.concrete,architecture,Enum.Material.Concrete)
		part("RetainingInset",Vector3.new(22,23,.2),Vector3.new(x+12,29,-58.2),C.ink,architecture)
		for y=21,39,6 do part("VentLouvers",Vector3.new(20,.35,.55),Vector3.new(x+12,y,-57.8),backConcrete,architecture,Enum.Material.Metal) end
	end
	part("ElevatedStreetDeck",Vector3.new(190,2.7,20),Vector3.new(270,53,-66),C.concrete,architecture,Enum.Material.Concrete)
	beam("ElevatedStreetEdge",Vector3.new(175,55,-55.5),Vector3.new(365,55,-55.5),.6,C.silver,architecture)
	for x=180,360,20 do part("ElevatedStreetFencePost",Vector3.new(.15,3,.15),Vector3.new(x,56,-55.5),C.silver,architecture) end
	beam("ElevatedStreetFence",Vector3.new(175,57.5,-55.5),Vector3.new(365,57.5,-55.5),.12,C.silver,architecture)
	for index,spec in ipairs({{204,24,75},{249,27,89},{296,19,68},{339,29,81}}) do
		local x,w,h=spec[1],spec[2],spec[3]
		part("StationRearServiceTower",Vector3.new(w,h,18),Vector3.new(x,h/2,-89),index%2==0 and C.ink or backConcrete,architecture)
		part("ServiceTowerRoof",Vector3.new(w+1,1,20),Vector3.new(x,h,-89),C.concrete,architecture)
		for y=59,h-5,12 do
			for dx=-w/2+5,w/2-3,10 do
				part("DistantServiceWindow",Vector3.new(3.5,4,.1),Vector3.new(x+dx,y,-79.8),index==2 and C.blue or C.concrete,architecture)
			end
		end
	end
	-- A broken roof bay and angled panels interrupt the perfectly repeated platform structure.
	local collapsed=part("CollapsedRoofSheet",Vector3.new(19,.4,8),Vector3.new(296,6.5,-35),stationBlue,architecture,Enum.Material.Metal)
	collapsed.CFrame*=CFrame.Angles(math.rad(24),math.rad(-8),math.rad(29))
	beam("BrokenRoofBrace",Vector3.new(288,26,-27),Vector3.new(299,9,-34),.35,C.silver,architecture)
	beam("HangingPowerCable",Vector3.new(298,28,-22),Vector3.new(300,20,-19),.07,C.ink)
	beam("HangingPowerCable",Vector3.new(300,20,-19),Vector3.new(297,16,-20),.07,C.ink)
	for _,x in ipairs({191,230,278,323,350}) do
		local streak=part("WaterDamage",Vector3.new(random:NextNumber(1.6,3.4),random:NextNumber(7,14),.09),Vector3.new(x,19,-46.35),grime,architecture)
		streak.Transparency=.2
		fracture(x,9,-45.95,4,7,grime,architecture)
	end
	for _,x in ipairs({199,239,284,331,349}) do ivy(x,28,-20,random:NextNumber(4,8)) end
	for _,x in ipairs({210,276,300,340}) do rubblePile(x,-18.4,C.concrete) end
	for _,x in ipairs({230,273,325}) do
		local tile=part("LiftedPlatformTile",Vector3.new(2,.2,1.5),Vector3.new(x,.15,-11.2),C.concrete,details)
		tile.CFrame*=CFrame.Angles(.07,.4,.06)
		beam("TileCrack",Vector3.new(x+.8,.09,-10.5),Vector3.new(x+3,.09,-9.6),.035,grime,details)
	end
	-- Painted emergency patches and a few warm practicals break the monochromatic blue hall.
	for _,x in ipairs({202,278,339}) do
		local beacon=glow("EmergencyBulkhead",Vector3.new(1.1,.75,.3),Vector3.new(x,6,-17),C.amber)
		part("BulkheadCage",Vector3.new(.08,.95,.45),Vector3.new(x,6,-16.9),C.ink)
		pointLight(beacon,C.amber,.9,17)
	end
	part("DiscardedMaintenanceCart",Vector3.new(6,1.7,3),Vector3.new(351,1.6,-18.2),C.concrete,architecture,Enum.Material.Metal)
	for _,dx in ipairs({-2,2}) do tube("MaintenanceCartWheel",Vector3.new(351+dx,.6,-16.3),Vector3.new(351+dx,.6,-16),1,C.ink,architecture) end
	-- Far industrial massing: three heights and silhouettes above the nearer factory wall.
	for index,spec in ipairs({{379,54,6},{438,72,5},{529,62,7}}) do
		local x,height,diameter=spec[1],spec[2],spec[3]
		tube("DistantSmokestack",Vector3.new(x,0,-71),Vector3.new(x,height,-71),diameter,index==2 and factoryRust or backConcrete,architecture)
		for y=18,height-3,16 do tube("StackReinforcement",Vector3.new(x,y-.4,-71),Vector3.new(x,y+.4,-71),diameter+.7,C.ink,architecture) end
		local beacon=glow("StackSafetyBeacon",Vector3.one*.65,Vector3.new(x,height+.5,-71),C.red)
		beacon.Shape=Enum.PartType.Ball
	end
	part("LoadingTower",Vector3.new(27,52,21),Vector3.new(386,25,-65),backConcrete,architecture,Enum.Material.Concrete)
	for y=11,47,12 do
		part("LoadingTowerFloor",Vector3.new(29,.6,22),Vector3.new(386,y,-65),C.ink,architecture)
		for x=378,396,6 do
			part("LoadingTowerWindow",Vector3.new(3.5,6,.2),Vector3.new(x,y+4,-54.3),C.blue,architecture,Enum.Material.Glass)
		end
	end
	part("LoadingTowerCap",Vector3.new(30,2,24),Vector3.new(386,52,-65),C.concrete,architecture)
	for _,x in ipairs({425,446}) do
		tube("RearStorageSilo",Vector3.new(x,0,-67),Vector3.new(x,46,-67),14,factorySteel,architecture)
		for y=10,44,11 do tube("SiloBand",Vector3.new(x,y-.2,-67),Vector3.new(x,y+.2,-67),14.5,C.ink,architecture) end
	end
	beam("ElevatedConveyorHousing",Vector3.new(393,42,-56),Vector3.new(480,31,-56),3.8,factoryRust,architecture)
	for x=402,472,14 do beam("ElevatedConveyorSupport",Vector3.new(x,0,-56),Vector3.new(x,38-(x-402)*.125,-56),.6,C.ink,architecture) end
	-- A smaller service annex offsets the tall loading tower at the opposite end.
	part("FactoryControlAnnex",Vector3.new(28,24,18),Vector3.new(524,35,-56),C.ink,architecture)
	for x=514,534,5 do part("ControlRoomWindow",Vector3.new(3.7,6,.25),Vector3.new(x,38,-46.8),C.blue,architecture,Enum.Material.Glass) end
	part("ControlRoomAwning",Vector3.new(30,.65,4),Vector3.new(524,42,-47),factorySteel,architecture)
	-- Angled wreckage, repaired wall patches and oil-dark vertical grime break up the brown slab.
	for _,x in ipairs({379,421,462,532}) do
		local patch=part("SteelWallRepair",Vector3.new(8,10,.2),Vector3.new(x,13,-45.1),x==421 and C.ink or factorySteel,architecture,Enum.Material.Metal)
		patch.CFrame*=CFrame.Angles(0,0,math.rad(random:NextNumber(-6,6)))
		for _,dx in ipairs({-3.6,3.6}) do for _,y in ipairs({8.7,17.3}) do
			part("RepairBolt",Vector3.new(.22,.22,.18),Vector3.new(x+dx,y,-44.8),C.silver,architecture)
		end end
	end
	for _,x in ipairs({370,405,451,481,520}) do
		local scar=part("FactoryGrime",Vector3.new(3.4,19,.12),Vector3.new(x,14,-45.7),grime,architecture)
		scar.Transparency=.22
	end
	for index=1,5 do
		local sheet=part("CollapsedSheetMetal",Vector3.new(7,.2,4),Vector3.new(469+index*1.3,1+index*.2,-34+index*.8),index%2==0 and factoryRust or factorySteel,architecture,Enum.Material.CorrodedMetal)
		sheet.CFrame*=CFrame.Angles(random:NextNumber(-.2,.5),random:NextNumber(-.8,.8),random:NextNumber(-.4,.4))
	end
	for _,x in ipairs({386,434,467,527}) do rubblePile(x,-19.5,factorySteel) end
	for _,x in ipairs({374,467}) do ivy(x,17,-18.5,6) end
	-- Blue maintenance lamps provide complementary edge light against amber furnace illumination.
	for _,x in ipairs({404,456}) do
		local light=glow("MaintenanceTaskLight",Vector3.new(2,.2,.4),Vector3.new(x,9,-18),C.cyan)
		pointLight(light,C.cyan,.65,19)
	end
	-- Foreground apron sits below the lane and frames the route without obscuring fighters.
	for stage=2,3 do
		local x=(stage-1)*180+90
		part("ForegroundServiceApron",Vector3.new(178,.6,9),Vector3.new(x,-.85,22),stage==2 and backConcrete or factoryFloor,architecture,Enum.Material.Concrete)
		for gx=x-75,x+75,30 do
			part("DrainGrate",Vector3.new(6,.05,2.6),Vector3.new(gx,-.52,20),C.ink,details)
			for dx=-2.4,2.4,1.6 do part("DrainBar",Vector3.new(.1,.06,2.4),Vector3.new(gx+dx,-.48,20),C.silver,details) end
		end
	end

	-- Six authored confrontation landmarks match the encounter director's spawn anchors.
	local landmarkFolder=folder("EncounterLandmarks")
	local function landmark(name,stage,role,x,title,accent)
		local model=Instance.new("Model");model.Name=name;model.Parent=landmarkFolder
		model:SetAttribute("Stage",stage);model:SetAttribute("Role",role);model:SetAttribute("EnemyKind",name == "CrosswalkExecutioner" and "Executioner" or name);model:SetAttribute("SpawnX",x)
		local anchor=part("SpawnAnchor",Vector3.one,Vector3.new(x,3,0),accent,model)
		anchor.Transparency=1;anchor.CanQuery=false;model.PrimaryPart=anchor
		-- Landmark marks use muted painted corner brackets, not red attack-like warning fills.
		for _,dx in ipairs({-10,10}) do
			for _,z in ipairs({-9,9}) do
				part("ArenaCorner",Vector3.new(2,.035,.14),Vector3.new(x+dx,.08,z),C.silver,model)
				part("ArenaCorner",Vector3.new(.14,.035,2),Vector3.new(x+dx,.08,z),C.silver,model)
			end
		end
		sign(name.."Landmark",title,x,8,-16.5,26,2.6,C.ink,accent)
		return model
	end
	landmark("CrosswalkExecutioner",1,"Miniboss",75,"CROSSWALK / NO SIGNAL",C.cyan)
	landmark("SirenMarshal",1,"Boss",135,"POLICE CORDON / EVACUATE",C.red)
	landmark("PlatformWidow",2,"Miniboss",255,"PLATFORM 04 / NO ARRIVALS",C.cyan)
	landmark("LastConductor",2,"Boss",315,"LAST DEPARTURE / 23:59",C.cyan)
	landmark("FurnaceHound",3,"Miniboss",435,"ASSEMBLY LINE / LOCKOUT",C.amber)
	landmark("KilnSovereign",3,"Boss",495,"KILN 03 / CORE BREACH",C.amber)
	-- City boss landmark: an abandoned armored response van and low police cordon.
	local van=Instance.new("Model");van.Name="AbandonedResponseVan";van.Parent=architecture
	part("ResponseChassis",Vector3.new(16,1.5,6),Vector3.new(135,1.7,-18),C.ink,van,Enum.Material.Metal)
	part("ResponseBody",Vector3.new(11,4.7,5.8),Vector3.new(132.5,4.6,-18),C.blue,van,Enum.Material.Metal)
	part("ResponseCab",Vector3.new(5,4,5.8),Vector3.new(140,4.2,-18),C.concrete,van,Enum.Material.Metal)
	part("ResponseSideStripe",Vector3.new(15,.8,.15),Vector3.new(135,3.7,-14.99),C.white,van)
	part("ResponseSideWindow",Vector3.new(3.3,1.7,.2),Vector3.new(140,5.1,-14.9),C.ink,van,Enum.Material.Glass)
	part("ResponseWindshield",Vector3.new(.2,1.7,4.4),Vector3.new(142.6,5.1,-18),C.blue,van,Enum.Material.Glass)
	part("ResponseDoorSeam",Vector3.new(.07,3.1,.17),Vector3.new(137.3,4,-14.8),C.ink,van)
	part("ResponseHandle",Vector3.new(.8,.12,.15),Vector3.new(138.2,4.1,-14.7),C.silver,van)
	for _,x in ipairs({129.5,140}) do
		for _,z in ipairs({-14.8,-21.2}) do
			tube("ResponseTire",Vector3.new(x,1.5,z-.35),Vector3.new(x,1.5,z+.35),2.6,C.ink,van)
			tube("ResponseHub",Vector3.new(x,1.5,z+.36),Vector3.new(x,1.5,z+.4),1.3,C.silver,van)
		end
	end
	part("SirenBase",Vector3.new(4,.3,1.3),Vector3.new(138,6.3,-18),C.ink,van)
	glow("SirenRed",Vector3.new(1.8,.45,1.1),Vector3.new(137,6.65,-18),C.red,van)
	glow("SirenCyan",Vector3.new(1.8,.45,1.1),Vector3.new(139,6.65,-18),C.cyan,van)
	-- Six subtle overhead station cable runs and the conductor's broken signal tower.
	for _,z in ipairs({-17.8,-18.2,-18.6}) do
		beam("StationCable",Vector3.new(187,12.8,z),Vector3.new(354,12.8,z),.045,C.ink)
	end
	tube("ConductorSignalPost",Vector3.new(333,0,-17.3),Vector3.new(333,12,-17.3),.35,C.silver)
	part("ConductorSignalBox",Vector3.new(2.8,5.2,1),Vector3.new(333,12,-17.3),C.ink)
	for i=1,3 do
		local eye=glow("DeadRailSignal",Vector3.one*.8,Vector3.new(333,14-i*1.4,-16.7),i==1 and C.red or stationBlue)
		eye.Shape=Enum.PartType.Ball
	end
	-- Distinctive station litter: split suitcases, dropped tickets and a shuttered kiosk.
	for _,x in ipairs({220,264,294,337}) do
		local luggage=destructible("LostLuggage_"..x,"Luggage",12)
		luggage.PrimaryPart=part("SuitcaseBody",Vector3.new(2.6,2.2,1.2),Vector3.new(x,1.1,11.8),x%2==0 and C.blue or rust,luggage)
		part("SuitcaseBand",Vector3.new(.18,2.25,1.25),Vector3.new(x,1.1,11.8),C.silver,luggage)
		beam("SuitcaseHandle",Vector3.new(x-.5,2.5,11.8),Vector3.new(x+.5,2.5,11.8),.13,C.ink,luggage)
		for _,dx in ipairs({-.85,.85}) do part("SuitcaseWheel",Vector3.new(.3,.3,.3),Vector3.new(x+dx,.16,12.3),C.ink,luggage) end
	end
	part("ShutteredKiosk",Vector3.new(12,9,5),Vector3.new(268,4.5,-18.5),stationBlue,architecture)
	for y=1,7.5,.55 do part("KioskShutter",Vector3.new(10,.15,.2),Vector3.new(268,y,-15.8),C.concrete,architecture) end
	sign("KioskNotice","売店 / CLOSED",268,8.4,-15.7,10,1.3,C.ink,C.white)
	-- Small loose material lives at the lane edge; no collidable rubble obstructs recovery.
	for index=1,26 do
		local x=random:NextNumber(187,353)
		local paper=part("AbandonedTicket",Vector3.new(.4,.018,.75),Vector3.new(x,.085,index%2==0 and 10.5 or -10.5),C.white,details)
		paper.CFrame*=CFrame.Angles(0,random:NextNumber(-math.pi,math.pi),0)
	end
	-- Factory prop family: striped drums and shipping crates (full breakable assemblies).
	for _,x in ipairs({382,407,446,469,522}) do
		local drum=destructible("ChemicalDrum_"..x,"Drum",25)
		drum.PrimaryPart=tube("DrumBody",Vector3.new(x,.15,11.8),Vector3.new(x,3.2,11.8),2.4,factoryRust,drum)
		for _,y in ipairs({.35,1.7,3}) do tube("DrumBand",Vector3.new(x,y-.08,11.8),Vector3.new(x,y+.08,11.8),2.5,C.ink,drum) end
		part("DrumWarning",Vector3.new(.75,.75,.08),Vector3.new(x,2.2,13.05),C.amber,drum)
	end
	for _,x in ipairs({372,420,456,532}) do
		local crate=destructible("ShippingCrate_"..x,"Crate",25)
		crate.PrimaryPart=part("CrateBody",Vector3.new(4.2,3.7,3),Vector3.new(x,1.85,-12.1),factoryRust,crate,Enum.Material.WoodPlanks)
		for _,dx in ipairs({-1.7,1.7}) do part("CrateSteelBand",Vector3.new(.25,3.9,3.1),Vector3.new(x+dx,1.85,-12.1),C.ink,crate,Enum.Material.Metal) end
		beam("CrateBrace",Vector3.new(x-1.8,.3,-10.5),Vector3.new(x+1.8,3.4,-10.5),.2,C.silver,crate)
	end
	-- Local floor scuffs suggest abandoned work without giving false damage telegraphs.
	for _,x in ipairs({393,433,486,515}) do
		local stain=part("OilScuff",Vector3.new(5,.012,2.4),Vector3.new(x,.065,8.3),C.ink,streets)
		stain.Transparency=.48;stain.CFrame*=CFrame.Angles(0,.3,0)
	end

	-- Whole assemblies break/restore together; structural floor and gates are never tagged.
	local function vending(x, accent)
		local assembly = destructible("VendingAssembly_"..x, "Vending", 40)
		assembly.PrimaryPart = part("VendingMachine",Vector3.new(3.4,6,2.2),Vector3.new(x,3,-12.1),C.blue,assembly)
		part("VendingGlass",Vector3.new(2.7,3.4,.18),Vector3.new(x,3.8,-10.9),C.ink,assembly)
		for y = 2.7, 4.8, 1 do
			for dx = -.8, .8, .8 do
				glow("DrinkBottle",Vector3.new(.4,.65,.2),Vector3.new(x+dx,y,-10.7),accent,assembly)
			end
		end
		part("VendingSlot",Vector3.new(1.8,.5,.2),Vector3.new(x,1,-10.8),C.ink,assembly)
	end
	for _, x in ipairs({33,129,215,303,347}) do vending(x,x%2==0 and C.cyan or C.amber) end
	for _, x in ipairs({25,115,166,203,281,336,380,443,528}) do
		local assembly = destructible("UtilityAssembly_"..x, "Utility", 25)
		assembly.PrimaryPart = part("StreetUtilityBox",Vector3.new(2,2.8,1.7),Vector3.new(x,1.4,11.8),C.concrete,assembly)
		for y = 1, 2.1, .3 do part("UtilityVent",Vector3.new(1.4,.09,.1),Vector3.new(x,y,12.7),C.ink,assembly) end
		glow("UtilityIndicator",Vector3.new(.18,.18,.1),Vector3.new(x+.55,2.45,12.7),C.amber,assembly)
	end
	for _, x in ipairs({44,151,246,323,412,480}) do
		local assembly = destructible("BenchAssembly_"..x, "Bench", 25)
		assembly.PrimaryPart = part("BenchSeat",Vector3.new(6,.35,1.7),Vector3.new(x,1.5,-12.2),C.concrete,assembly)
		part("BenchBack",Vector3.new(6,1.3,.25),Vector3.new(x,2.2,-12.9),C.blue,assembly)
		for _, dx in ipairs({-2,2}) do part("BenchLeg",Vector3.new(.25,1.4,1.4),Vector3.new(x+dx,.7,-12.2),C.silver,assembly) end
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
	-- Authored entrance anchors use floor coordinates: Combat adds the rig's root height.
	-- The director may adjust side anchors relative to the party within server bounds.
	local entryMarkers, entryScenery = folder("EnemyEntries"), folder("EnemyEntryScenery")
	entryMarkers:SetAttribute("SchemaVersion", 1)
	for stageIndex, stage in ipairs(Config.Stages) do
		for waveIndex, wave in ipairs(stage.Waves) do
			local entryName = "Stage"..stageIndex.."_Wave"..waveIndex
			local group = Instance.new("Folder")
			group.Name, group.Parent = entryName, entryMarkers
			group:SetAttribute("Stage", stageIndex)
			group:SetAttribute("Wave", waveIndex)
			group:SetAttribute("WaveCenterX", wave.SpawnX)
			local center = math.clamp(wave.SpawnX, stage.MinX+6, stage.MaxX-6)
			local dropX = math.clamp(center+8, stage.MinX+6, stage.MaxX-6)
			local positions = {
				Left = Vector3.new(math.clamp(center-24, stage.MinX+6, stage.MaxX-6),0,-7),
				Right = Vector3.new(math.clamp(center+24, stage.MinX+6, stage.MaxX-6),0,7),
				Door = Vector3.new(center,0,-12),
				Drop = Vector3.new(dropX,14,-7),
			}
			for _, kind in ipairs({"Left", "Right", "Door", "Drop"}) do
				local marker = part(kind, Vector3.one*.5, positions[kind], C.cyan, group)
				marker.Transparency, marker.CastShadow = 1, false
				marker:SetAttribute("EntryKind", kind)
				if kind == "Drop" then marker:SetAttribute("LandingPosition", Vector3.new(dropX,0,-7)) end
			end
			-- A shallow service doorway sits behind the -14 lane boundary. It cannot
			-- block movement or damage queries and uses no attack-like floor glow.
			local doorway = Instance.new("Model")
			doorway.Name, doorway.Parent = entryName, entryScenery
			doorway:SetAttribute("Stage", stageIndex)
			doorway:SetAttribute("Wave", waveIndex)
			doorway:SetAttribute("EntryKind", "Door")
			local trim = stageIndex == 2 and C.cyan or C.amber
			part("ServiceDoorRecess",Vector3.new(6.4,8,.3),Vector3.new(center,4,-15.25),C.ink,doorway)
			for _, dx in ipairs({-3.5,3.5}) do
				part("ServiceDoorJamb",Vector3.new(.6,8.5,.6),Vector3.new(center+dx,4.25,-14.85),C.silver,doorway,Enum.Material.Metal)
			end
			part("ServiceDoorLintel",Vector3.new(7.6,.6,.6),Vector3.new(center,8.5,-14.85),C.concrete,doorway,Enum.Material.Metal)
			glow("ServiceDoorIndicator",Vector3.new(2,.16,.12),Vector3.new(center,7.9,-14.49),trim,doorway)
		end
	end
	city:SetAttribute("EntryMarkerVersion", 1)
	city:SetAttribute("RouteLength",540)
	city:SetAttribute("BuildVersion","Nightfall-2-ThreeDistricts")
	return city
end

return WorldBuilder
