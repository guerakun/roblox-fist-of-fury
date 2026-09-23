local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")
local Config = require(ReplicatedStorage.Nightfall.Shared.Config)
local CombatMath = require(ReplicatedStorage.Nightfall.Shared.CombatMath)
local ToolboxHitbox = require(ReplicatedStorage.Nightfall.Shared.ToolboxHitbox)
local CharacterFactory = require(script.Parent.CharacterFactory)
local Combat = {}
local records = {}
local enemies = {}
local arena = Config.Stages[1]
local stageIndex = 1
local remotes
local encounter = {wave = 0, waves = 3, enemiesRemaining = 0, status = "Waiting"}
local restartCallback
local initialized = false
local function now() return workspace:GetServerTimeNow() end
local function root(model) return model and model:FindFirstChild("HumanoidRootPart") end
local function humanoid(model) return model and model:FindFirstChildOfClass("Humanoid") end
local function modelOf(actor) return typeof(actor) == "Instance" and actor:IsA("Player") and actor.Character or actor end
local function recordOf(model)
	local player = Players:GetPlayerFromCharacter(model)
	return player and records[player] or enemies[model], player
end
local function fx(kind, position, fields)
	local packet = fields or {}
	packet.kind, packet.position = kind, position
	remotes.FX:FireAllClients(packet)
end
function Combat.GetSnapshot(player)
	local data = records[player]
	if not data then return nil end
	return {kind = "Snapshot", hero = data.hero, percent = math.floor(data.percent), stocks = data.stocks,
		stage = stageIndex, stageName = arena.Name, wave = encounter.wave, waves = encounter.waves,
		enemiesRemaining = encounter.enemiesRemaining, status = encounter.status, blocking = data.blocking,
		downed = data.downed, cooldowns = {Special = data.cooldowns.Special or 0, Dash = data.cooldowns.Dash or 0}}
end
function Combat.BroadcastState()
	for player in pairs(records) do
		if player.Parent then remotes.State:FireClient(player, Combat.GetSnapshot(player)) end
	end
end
function Combat.SetEncounterState(state)
	for key, value in pairs(state) do encounter[key] = value end
	Combat.BroadcastState()
end
function Combat.SetArena(stage, index)
	arena, stageIndex = stage, index or stageIndex
	workspace:SetAttribute("NightfallStage", stageIndex)
end
function Combat.SetRestartCallback(callback) restartCallback = callback end
function Combat.GetAlivePlayers()
	local alive = {}
	for player, data in pairs(records) do
		local h = humanoid(player.Character)
		if not data.downed and data.stocks > 0 and h and h.Health > 0 and root(player.Character) then table.insert(alive, player) end
	end
	return alive
end
function Combat.GetPlayerCount() local n = 0 for _ in pairs(records) do n += 1 end return n end
function Combat.GetEnemies() return enemies end
local function attributes(model, data)
	if model then
		model:SetAttribute("Percent", data.percent)
		model:SetAttribute("Stocks", data.stocks or 1)
		model:SetAttribute("Blocking", data.blocking or false)
		model:SetAttribute("Hero", data.hero or data.kind)
		model:SetAttribute("Downed", data.downed or false)
        local head = model:FindFirstChild("Head")
        local plate = head and head:FindFirstChild("EnemyPlate")
        if plate and data.threshold then
            plate.Percent.Text = tostring(math.floor(data.percent)) .. "%"
            plate.Track.Fill.Size = UDim2.fromScale(math.max(0, 1 - data.percent / data.threshold), 1)
        end
	end
end
local function setVisualIdentity(model, hero)
    if not model then return end
	local old = model:FindFirstChild("HeroAura")
	if old then old:Destroy() end
	local highlight = Instance.new("Highlight")
	highlight.Name = "HeroAura"
	highlight.FillColor = Config.Characters[hero].Color
	highlight.OutlineColor = Config.Characters[hero].Color
	highlight.FillTransparency = 0.92
	highlight.OutlineTransparency = 0.65
	highlight.Parent = model
end
local function resetPosition(player, position)
	local model, data = player.Character, records[player]
	local r, h = root(model), humanoid(model)
	if not data or not r or not h then return end
	data.percent, data.blocking, data.downed = 0, false, false
	data.stunnedUntil, data.launchedUntil, data.recovered = 0, 0, false
    data.respawning = false
	data.invulnerableUntil = now() + 2
	r.Anchored = false
	r.AssemblyLinearVelocity = Vector3.zero
	model:PivotTo(CFrame.new(position) * CFrame.Angles(0, -math.pi / 2, 0))
	h.Health = h.MaxHealth
	h.WalkSpeed, h.JumpPower = Config.Characters[data.hero].Speed, Config.JumpPower
	attributes(model, data)
	fx("Spawn", position, {hero = data.hero, playerUserId = player.UserId})
end
local function spawnPlayer(player)
    local data = records[player]
    if not data or not player.Parent then return end
    local old = player.Character
    local model = CharacterFactory.Create(data.hero)
    model.Name = player.Name
    model.Parent = workspace
    player.Character = model
    if old then old:Destroy() end
end
function Combat.ResetPlayers(position)
	local index = 0
	for player, data in pairs(records) do
		data.stocks = Config.Stocks
		data.cooldowns = {}
		data.downed = false
		index += 1
		if humanoid(player.Character) and humanoid(player.Character).Health > 0 then
			resetPosition(player, position + Vector3.new(0, 0, (index - 1) * 3 - 4))
		else
			task.spawn(function() spawnPlayer(player) end)
		end
	end
	Combat.BroadcastState()
end
local function knockOut(model)
	local data, player = recordOf(model)
	if not data or data.downed or data.respawning then return end
	local r = root(model)
	fx("KO", r and r.Position or Vector3.zero, {hero = data.hero, playerUserId = player and player.UserId})
	if not player then
		enemies[model] = nil
		model:SetAttribute("Defeated", true)
		model:Destroy()
		return
	end
	data.stocks = math.max(0, data.stocks - 1)
	data.blocking = false
	data.respawning = true
	if r then r.Anchored = true end
	if data.stocks <= 0 then
		data.downed = true
		attributes(model, data)
		-- Keep the spectator's character above the safe checkpoint, outside combat.
		if r then model:PivotTo(CFrame.new(arena.SpawnX, 24, 0)) end
		local h = humanoid(model)
		if h then h.WalkSpeed = 0 end
		data.respawning = false
	else
		task.delay(1.15, function()
			if records[player] ~= data then return end
			data.respawning = false
			if player.Character == model and humanoid(model) and humanoid(model).Health > 0 then
				resetPosition(player, Vector3.new(arena.SpawnX, 4, 0))
			elseif player.Parent then
				spawnPlayer(player)
			end
		end)
	end
	Combat.BroadcastState()
end
function Combat.ApplyHit(attacker, target, attack, direction)
	local targetModel = modelOf(target)
	local sourceModel = modelOf(attacker)
	if not targetModel or not sourceModel or targetModel == sourceModel then return false end
	local data, victimPlayer = recordOf(targetModel)
	local sourceData, sourcePlayer = recordOf(sourceModel)
	local r = root(targetModel)
	if not data or not sourceData or not r or data.downed or data.respawning or now() < (data.invulnerableUntil or 0) then return false end
	if (victimPlayer ~= nil) == (sourcePlayer ~= nil) then return false end
	local blocked = data.blocking and data.facing == -direction
	local damage = attack.Damage * (blocked and 0.2 or 1)
	data.percent = math.min(999, data.percent + damage)
	data.stunnedUntil = now() + (blocked and 0.08 or attack.Stun)
	data.launchedUntil = now() + (blocked and 0.1 or 0.6)
	if blocked then
		data.guard += attack.Damage
		if data.guard >= 55 then
			data.blocking = false
			data.guard = 0
			data.stunnedUntil = now() + 1.5
			fx("GuardBreak", r.Position)
		end
	end
	local velocity = CombatMath.Knockback(data.percent, attack, data.weight or 1) * (blocked and 0.2 or 1)
	r.AssemblyLinearVelocity = Vector3.new(direction * velocity, blocked and 3 or attack.Lift, r.AssemblyLinearVelocity.Z * 0.3)
	attributes(targetModel, data)
	fx("Hit", r.Position, {direction = direction, damage = damage, heavy = attack.Damage >= 18, hero = sourceData.hero, playerUserId = sourcePlayer and sourcePlayer.UserId})
	if data.percent >= (victimPlayer and Config.PlayerPercentLimit or data.threshold) then knockOut(targetModel) end
	return true
end
local function doHitbox(actor, attack, direction)
	local model = modelOf(actor)
	local r = root(model)
	if not r then return end
	local offset = attack.Omnidirectional and 0 or direction * attack.Range / 2
    local length = attack.Omnidirectional and attack.Range * 2 or attack.Range
    local parts = ToolboxHitbox.Query(CFrame.new(r.Position + Vector3.new(offset, 0, 0)), Vector3.new(length, 9, attack.Width), {model, workspace.NightfallCity})
	local hit = {}
	for _, part in ipairs(parts) do
		local candidate = part:FindFirstAncestorOfClass("Model")
		if candidate and not hit[candidate] and recordOf(candidate) then
			hit[candidate] = true
			local candidateRoot = root(candidate)
            local hitDirection = attack.Omnidirectional and candidateRoot and (candidateRoot.Position.X >= r.Position.X and 1 or -1) or direction
            Combat.ApplyHit(actor, candidate, attack, hitDirection)
		end
	end
end
local function performAttack(player, action, data)
	local model, r = player.Character, root(player.Character)
	if not r then return end
	local attack = table.clone(action == "Special" and Config.Characters[data.hero].Special or Config.Attacks[action])
	if action == "Light" then
		data.combo = now() - data.lastLight < 0.9 and (data.combo % 3 + 1) or 1
		data.lastLight = now()
		if data.combo == 3 then attack.Damage *= 1.5 attack.Knockback += 18 attack.Lift = 18 end
	end
	data.cooldowns[action] = now() + attack.Cooldown
	data.busyUntil = now() + attack.Windup + 0.13
	data.blocking = false
	local direction = data.facing
	r.CFrame = CFrame.lookAt(r.Position, r.Position + Vector3.new(direction, 0, 0))
	fx("Attack", r.Position, {hero = data.hero, action = action, direction = direction, playerUserId = player.UserId, combo = data.combo})
	task.delay(attack.Windup, function()
		if records[player] ~= data or player.Character ~= model or data.downed or data.respawning or now() < data.stunnedUntil then return end
		doHitbox(player, attack, direction)
	end)
end
local allowedActions = {Light = true, Heavy = true, Special = true, Dash = true, Block = true, Recovery = true, Jump = true, SelectCharacter = true, Restart = true}
local function actionReceived(player, action, payload)
	local data = records[player]
	if not data or type(action) ~= "string" or not allowedActions[action] then return end
	if payload ~= nil and type(payload) ~= "table" then return end
	payload = payload or {}
	local t = now()
	if t - data.rateStart >= 1 then data.rateStart, data.rateCount = t, 0 end
	data.rateCount += 1
	if data.rateCount > 30 then return end
	if action == "Restart" then
		if restartCallback and (encounter.status == "Defeat" or encounter.status == "Victory") then restartCallback() end
		return
	end
	if action == "SelectCharacter" then
		if type(payload.hero) == "string" and Config.Characters[payload.hero] and t >= data.selectAt then
            if data.downed or data.respawning or t < data.stunnedUntil or t < data.busyUntil then return end
            local currentRoot = root(player.Character)
            if not currentRoot then return end
            data.preserveSpawn = {position = currentRoot.Position, percent = data.percent, invulnerableUntil = data.invulnerableUntil, recovered = data.recovered}
            data.hero = payload.hero
            data.selectAt = t + 2
            spawnPlayer(player)
            Combat.BroadcastState()
		end
		return
	end
	if action == "Block" and payload.held == false then data.blocking = false return end
	if data.downed or data.respawning or encounter.status ~= "Combat" or t < data.stunnedUntil then return end
	local r, h = root(player.Character), humanoid(player.Character)
	if not r or not h or h.Health <= 0 then return end
	data.facing = CombatMath.Direction(payload.direction, data.facing)
	if t < data.busyUntil then return end
	if action == "Block" then
		if payload.held == true then data.blocking = true end
	elseif action == "Dash" and t >= (data.cooldowns.Dash or 0) then
		data.cooldowns.Dash = t + 1.4
		data.invulnerableUntil = t + 0.22
		data.blocking = false
		r.AssemblyLinearVelocity = Vector3.new(data.facing * 74, math.max(0, r.AssemblyLinearVelocity.Y), 0)
		data.launchedUntil = t + 0.18
		fx("Dash", r.Position, {direction = data.facing, hero = data.hero, playerUserId = player.UserId})
	elseif action == "Recovery" or action == "Jump" then
		if h.FloorMaterial == Enum.Material.Air and not data.recovered then
			data.recovered = true
			r.AssemblyLinearVelocity = Vector3.new(data.facing * 26, 58, 0)
			fx("Recovery", r.Position, {hero = data.hero, playerUserId = player.UserId})
		elseif h.FloorMaterial ~= Enum.Material.Air then h.Jump = true end
	elseif (Config.Attacks[action] or action == "Special") and t >= (data.cooldowns[action] or 0) then
		performAttack(player, action, data)
	end
end
local function createRig(name, color, scale, position)
	local model = Instance.new("Model")
	model.Name = name
	local function part(partName, size, offset, transparency)
		local p = Instance.new("Part")
		p.Name, p.Size, p.Color = partName, size * scale, color
		p.CFrame = CFrame.new(position + offset * scale)
		p.Material = Enum.Material.SmoothPlastic
		p.Transparency = transparency or 0
		p.CanCollide = partName == "Torso"
		p.Massless = partName ~= "HumanoidRootPart"
		p.TopSurface, p.BottomSurface = Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
		p.Parent = model
		return p
	end
	local r = part("HumanoidRootPart", Vector3.new(2, 2, 1), Vector3.zero, 1)
	local torso = part("Torso", Vector3.new(2, 2, 1), Vector3.zero)
	local head = part("Head", Vector3.new(2, 1, 1), Vector3.new(0, 1.5, 0))
	local leftArm = part("Left Arm", Vector3.new(1, 2, 1), Vector3.new(-1.5, 0, 0))
	local rightArm = part("Right Arm", Vector3.new(1, 2, 1), Vector3.new(1.5, 0, 0))
	local leftLeg = part("Left Leg", Vector3.new(1, 2, 1), Vector3.new(-0.5, -2, 0))
	local rightLeg = part("Right Leg", Vector3.new(1, 2, 1), Vector3.new(0.5, -2, 0))
	local function joint(jointName, a, b)
		local motor = Instance.new("Motor6D")
		motor.Name, motor.Part0, motor.Part1 = jointName, a, b
		motor.C0 = a.CFrame:ToObjectSpace(b.CFrame)
		motor.Parent = a
	end
	joint("RootJoint", r, torso)
	joint("Neck", torso, head)
	joint("Left Shoulder", torso, leftArm)
	joint("Right Shoulder", torso, rightArm)
	joint("Left Hip", torso, leftLeg)
	joint("Right Hip", torso, rightLeg)
	local h = Instance.new("Humanoid")
	h.MaxHealth, h.Health, h.HipHeight = 100000, 100000, 0
	h.DisplayName = name
	h.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	h.BreakJointsOnDeath = false
	h.Parent = model
	Instance.new("Animator", h)
	model.PrimaryPart = r
	model.Parent = workspace.Enemies
	r:SetNetworkOwner(nil)
	local eye = Instance.new("Part")
	eye.Name, eye.Size, eye.Color = "CursedVisor", Vector3.new(1.65, 0.18, 0.12) * scale, Color3.fromRGB(255, 87, 199)
	eye.Material = Enum.Material.Neon
	eye.CanCollide, eye.Massless = false, true
	eye.CFrame = head.CFrame * CFrame.new(0, 0.05 * scale, -0.53 * scale)
	eye.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0, weld.Part1, weld.Parent = head, eye, eye
	return model
end
function Combat.SpawnEnemy(kind, position, healthScale)
	local spec = Config.Enemies[kind]
	assert(spec, "Unknown enemy kind")
	local model = createRig(spec.Name, spec.Color, spec.Scale, position + Vector3.new(0, spec.Scale * 3, 0))
	local data = {kind = kind, percent = 0, threshold = spec.Threshold * (healthScale or 1), weight = spec.Weight,
		blocking = false, guard = 0, facing = -1, stunnedUntil = 0, launchedUntil = 0, invulnerableUntil = 0,
		attackAt = now() + 1.3, spec = spec, phase = 1}
	enemies[model] = data
	local plate = Instance.new("BillboardGui")
    plate.Name = "EnemyPlate"
    plate.Size = UDim2.fromOffset(kind == "Boss" and 240 or 155, 48)
    plate.StudsOffset = Vector3.new(0, spec.Scale + 0.7, 0)
    plate.AlwaysOnTop = false
    plate.MaxDistance = 140
    plate.Parent = model.Head
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(0.78, 0, 0, 24)
    title.Font = Enum.Font.GothamBold
    title.TextSize = kind == "Boss" and 13 or 10
    title.TextColor3 = Color3.fromRGB(237, 231, 249)
    title.TextStrokeTransparency = 0.5
    title.Text = string.upper(spec.Name)
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = plate
    local percent = title:Clone()
    percent.Name = "Percent"
    percent.Position = UDim2.fromScale(0.78, 0)
    percent.Size = UDim2.new(0.22, 0, 0, 24)
    percent.TextColor3 = spec.Color
    percent.TextXAlignment = Enum.TextXAlignment.Right
    percent.Text = "0%"
    percent.Parent = plate
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.BackgroundColor3 = Color3.fromRGB(22, 20, 32)
    track.BorderSizePixel = 0
    track.Position = UDim2.fromOffset(0, 24)
    track.Size = UDim2.new(1, 0, 0, 4)
    track.Parent = plate
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = spec.Color
    fill.BorderSizePixel = 0
    fill.Parent = track
    humanoid(model).DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    model:SetAttribute("EnemyKind", kind)
	model:SetAttribute("PercentLimit", data.threshold)
	attributes(model, data)
	humanoid(model).WalkSpeed = spec.Speed
	fx("Spawn", position, {enemy = kind})
	return model
end
function Combat.ClearEnemies()
	for model in pairs(enemies) do model:Destroy() end
	table.clear(enemies)
end
local function aiStep(t)
	local alive = Combat.GetAlivePlayers()
	for model, data in pairs(enemies) do
		local r, h = root(model), humanoid(model)
		if not r or not h or h.Health <= 0 then enemies[model] = nil continue end
		if CombatMath.InBlastZone(r.Position, arena, Config.BlastMargin) then knockOut(model) continue end
		if t < data.stunnedUntil or t < data.launchedUntil or encounter.status ~= "Combat" then h:Move(Vector3.zero) continue end
		local target, distance
		for _, player in ipairs(alive) do
			local targetRoot = root(player.Character)
			local targetData = records[player]
			if targetRoot and not targetData.respawning then
				local d = (targetRoot.Position - r.Position).Magnitude
				if not distance or d < distance then target, distance = player, d end
			end
		end
		if not target then h:Move(Vector3.zero) continue end
		local targetRoot = root(target.Character)
		local spec = data.spec
		data.facing = targetRoot.Position.X >= r.Position.X and 1 or -1
		if data.kind == "Boss" and data.percent > data.threshold * 0.5 and data.phase == 1 then
			data.phase = 2
			fx("BossPhase", r.Position, {phase = 2})
		end
		if data.attacking then h:Move(Vector3.zero)
		elseif distance > spec.Reach - 1 then
			h.WalkSpeed = spec.Speed * (data.phase == 2 and 1.35 or 1)
			h:MoveTo(Vector3.new(targetRoot.Position.X - data.facing * 3, r.Position.Y, math.clamp(targetRoot.Position.Z, -12, 12)))
		elseif t >= data.attackAt then
			data.attacking = true
			data.attackAt = t + spec.Cooldown
			h:Move(Vector3.zero)
			local direction = data.facing
			local isSlam = data.kind == "Boss" and data.phase == 2
			fx("Telegraph", r.Position, {direction = direction, duration = spec.Windup, radius = spec.Reach + 2, enemy = data.kind, heavy = isSlam})
			task.delay(spec.Windup, function()
				if enemies[model] ~= data then return end
				data.attacking = false
				if now() < data.stunnedUntil or encounter.status ~= "Combat" then return end
				local attack = {Damage = spec.Damage, Knockback = 28, Growth = 0.44, Lift = isSlam and 42 or 18,
					Range = spec.Reach + 2, Width = isSlam and 25 or 7, Stun = 0.38, Omnidirectional = isSlam}
				fx("Attack", root(model).Position, {direction = direction, enemy = data.kind, action = isSlam and "Slam" or "Heavy"})
				doHitbox(model, attack, direction)
				-- Omnidirectional query deduplicates the entire slam, preventing double hits.
			end)
		end
		-- Lightweight joint motion keeps custom enemies readable without external animation permissions.
		local torso = model:FindFirstChild("Torso")
		-- Clients sample reviewed Toolbox poses; keep server joints stable.

	end
end
local function setupCharacter(player, model)
	local data = records[player]
	local h = model:WaitForChild("Humanoid", 10)
	local r = model:WaitForChild("HumanoidRootPart", 10)
	if not data or not h or not r or player.Character ~= model then return end
	h.UseJumpPower = true
	h.JumpPower = Config.JumpPower
	h.BreakJointsOnDeath = false
	setVisualIdentity(model, data.hero)
	local preserved = data.preserveSpawn
    data.preserveSpawn = nil
    resetPosition(player, preserved and preserved.position or Vector3.new(arena.SpawnX, 4, (#Players:GetPlayers() % 3 - 1) * 4))
    if preserved then
        data.percent = preserved.percent
        data.invulnerableUntil = preserved.invulnerableUntil
        data.recovered = preserved.recovered
        attributes(model, data)
    end
	if data.stocks <= 0 then data.downed = true r.Anchored = true model:PivotTo(CFrame.new(arena.SpawnX, 24, 0)) end
	h.Died:Connect(function()
		if player.Character == model and not data.respawning then knockOut(model) end
	end)
	Combat.BroadcastState()
end
local function addPlayer(player)
	if records[player] then return end
	records[player] = {hero = "Naruto", percent = 0, stocks = Config.Stocks, cooldowns = {}, stunnedUntil = 0,
		launchedUntil = 0, invulnerableUntil = 0, busyUntil = 0, selectAt = 0, facing = 1, combo = 0, lastLight = 0,
		blocking = false, guard = 0, downed = false, recovered = false, rateStart = now(), rateCount = 0}
	player.CharacterAdded:Connect(function(model) setupCharacter(player, model) end)
	task.spawn(function() spawnPlayer(player) end)
end
function Combat.Init()
	if initialized then return end
	initialized = true
	remotes = ReplicatedStorage.Nightfall.Remotes
	Players.CharacterAutoLoads = false
	remotes.Action.OnServerEvent:Connect(actionReceived)
	Players.PlayerAdded:Connect(addPlayer)
	Players.PlayerRemoving:Connect(function(player) records[player] = nil end)
	for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
	local aiAccum, stateAccum = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		local t = now()
		for player, data in pairs(records) do
			local model = player.Character
			local r, h = root(model), humanoid(model)
			if not r or not h or data.downed or data.respawning then continue end
			if CombatMath.InBlastZone(r.Position, arena, Config.BlastMargin) then knockOut(model) continue end
			local pos = r.Position
			local x = t > data.launchedUntil and math.clamp(pos.X, arena.MinX + 4, arena.MaxX - 4) or pos.X
			local z = math.clamp(pos.Z, Config.LaneMin, Config.LaneMax)
			if x ~= pos.X or z ~= pos.Z then r.CFrame += Vector3.new(x - pos.X, 0, z - pos.Z) end
			local speed = Config.Characters[data.hero].Speed
			h.WalkSpeed = t < data.stunnedUntil and 0 or (data.blocking and 8 or speed)
			h.JumpPower = data.blocking and 0 or Config.JumpPower
			if h.FloorMaterial ~= Enum.Material.Air then data.recovered = false end
			data.guard = math.max(0, data.guard - dt * (data.blocking and 3 or 14))
		end
		aiAccum += dt
		stateAccum += dt
		if aiAccum >= 0.12 then aiAccum = 0 aiStep(t) end
		if stateAccum >= 0.2 then stateAccum = 0 Combat.BroadcastState() end
	end)
end
return Combat
