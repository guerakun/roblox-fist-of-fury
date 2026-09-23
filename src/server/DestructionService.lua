-- Server-only cosmetic destruction. Only explicitly tagged city prop Models are eligible.
-- Road, buildings, rails and encounter gates are never candidates.
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Destruction = {}
local MAX_DEBRIS = 30
local RESTORE_SECONDS = 20
local debrisCount = 0
local liveDebris = {}
local random = Random.new()
local debrisFolder

function Destruction.Init()
	if debrisFolder and debrisFolder.Parent then return end
	debrisFolder = workspace:FindFirstChild("NightfallDebris")
	if not debrisFolder then
		debrisFolder = Instance.new("Folder")
		debrisFolder.Name = "NightfallDebris"
		debrisFolder.Parent = workspace
	end
end

local function distanceToAssembly(model, point)
	local frame, size = model:GetBoundingBox()
	local localPoint = frame:PointToObjectSpace(point)
	local half = size / 2
	local nearest = Vector3.new(math.clamp(localPoint.X, -half.X, half.X), math.clamp(localPoint.Y, -half.Y, half.Y), math.clamp(localPoint.Z, -half.Z, half.Z))
	return (localPoint - nearest).Magnitude
end

local function clearPiece(piece)
	if not liveDebris[piece] then return end
	liveDebris[piece] = nil
	debrisCount = math.max(0, debrisCount - 1)
	piece:Destroy()
end

local function spawnDebris(source, direction)
	if debrisCount >= MAX_DEBRIS then return end
	local piece = source:Clone()
	-- Clone only visual geometry, never welds, emitters, scripts or gameplay children.
	piece:ClearAllChildren()
	for _, tag in ipairs(CollectionService:GetTags(piece)) do CollectionService:RemoveTag(piece, tag) end
	piece.Name = "CosmeticFragment"
	piece.Size = Vector3.new(math.clamp(source.Size.X * .35, .25, 1.8), math.clamp(source.Size.Y * .35, .25, 1.5), math.clamp(source.Size.Z * .35, .25, 1.5))
	piece.CFrame = source.CFrame * CFrame.new(random:NextNumber(-.5, .5), .2, random:NextNumber(-.4, .4))
	piece.Transparency = math.min(source.Transparency, .25)
	piece.Anchored = false
	piece.Massless = false
	piece.CanCollide = false
	piece.CanTouch = false
	piece.CanQuery = false
	piece.CastShadow = false
	piece.Parent = debrisFolder
	piece:SetNetworkOwner(nil)
	piece.AssemblyLinearVelocity = Vector3.new(direction * random:NextNumber(14, 28), random:NextNumber(14, 23), random:NextNumber(-9, 9))
	piece.AssemblyAngularVelocity = Vector3.new(random:NextNumber(-8, 8), random:NextNumber(-8, 8), random:NextNumber(-8, 8))
	liveDebris[piece] = true
	debrisCount += 1
	-- No-collision fragments cannot obstruct characters or damage the combat floor.
	task.delay(1, function()
		if not liveDebris[piece] then return end
		if piece.Parent then TweenService:Create(piece, TweenInfo.new(.45), {Transparency = 1}):Play() end
		task.delay(.5, function() clearPiece(piece) end)
	end)
end

local function breakAssembly(assembly, direction)
	if assembly:GetAttribute("Broken") then return false end
	assembly:SetAttribute("Broken", true)
	local health = assembly:GetAttribute("Health")
	assembly:SetAttribute("Health", 0)
	local saved, pieces = {}, {}
	for _, item in ipairs(assembly:GetDescendants()) do
		if item:IsA("BasePart") then
			table.insert(saved, {instance = item, transparency = item.Transparency, collide = item.CanCollide, touch = item.CanTouch, query = item.CanQuery, shadow = item.CastShadow})
			if item.Transparency < 1 then table.insert(pieces, item) end
		elseif item:IsA("ParticleEmitter") or item:IsA("Light") then
			table.insert(saved, {instance = item, enabled = item.Enabled})
			item.Enabled = false
		end
	end
	table.sort(pieces, function(a, b) return a.Size.X * a.Size.Y * a.Size.Z > b.Size.X * b.Size.Y * b.Size.Z end)
	for index = 1, math.min(4, #pieces) do spawnDebris(pieces[index], direction) end
	for _, state in ipairs(saved) do
		if state.transparency ~= nil then
			local item = state.instance
			item.Transparency = 1
			item.CanCollide = false
			item.CanTouch = false
			item.CanQuery = false
			item.CastShadow = false
		end
	end
	task.delay(RESTORE_SECONDS, function()
		-- A rebuilt stage destroys the old assembly, so old timers cannot affect its replacement.
		if not assembly.Parent then return end
		for _, state in ipairs(saved) do
			local item = state.instance
			if item.Parent then
				if state.transparency ~= nil then
					item.Transparency = state.transparency
					item.CanCollide = state.collide
					item.CanTouch = state.touch
					item.CanQuery = state.query
					item.CastShadow = state.shadow
				else item.Enabled = state.enabled end
			end
		end
		assembly:SetAttribute("Health", health)
		assembly:SetAttribute("Broken", false)
	end)
	return true
end

function Destruction.BreakNearby(position, radius, direction)
	if typeof(position) ~= "Vector3" or type(radius) ~= "number" or radius ~= radius or position.X ~= position.X or position.Y ~= position.Y or position.Z ~= position.Z then return 0 end
	local city = workspace:FindFirstChild("NightfallCity")
	if not city then return 0 end
	Destruction.Init()
	radius = math.clamp(radius, 0, 24)
	local heading = type(direction) == "number" and direction < 0 and -1 or 1
	local count = 0
	for _, assembly in ipairs(CollectionService:GetTagged("Destructible")) do
		if assembly:IsA("Model") and assembly.PrimaryPart and assembly:IsDescendantOf(city) and not assembly:GetAttribute("Broken") and distanceToAssembly(assembly, position) <= radius then
			if breakAssembly(assembly, heading) then count += 1 end
		end
	end
	return count
end

return Destruction