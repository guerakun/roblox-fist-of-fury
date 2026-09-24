local Destruction = require(script.Parent.DestructionService)
local Progression = require(script.Parent.ProgressionService)
local EnemyFactory = require(script.Parent.EnemyFactory)
local EnemyMoves = require(script.Parent.EnemyMoves)
local CharacterFactory = require(script.Parent.CharacterFactory)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage.Nightfall.Shared.Config)
local CombatMath = require(ReplicatedStorage.Nightfall.Shared.CombatMath)
local Archetypes = require(ReplicatedStorage.Nightfall.Shared.EnemyArchetypes)
local CameraBounds = require(ReplicatedStorage.Nightfall.Shared.CameraBounds)
local ToolboxHitbox = require(ReplicatedStorage.Nightfall.Shared.ToolboxHitbox)
local Telemetry = require(script.Parent.CombatTelemetry)
local EnemyAI = require(script.Parent.EnemyAI)
local AttackDirector = require(script.Parent.AttackDirector)
local DifficultyPolicy = require(script.Parent.DifficultyPolicy)
local HeatConfig=require(ReplicatedStorage.Nightfall.Shared.HeatConfig)
local runHeat={}
local function runRules()return HeatConfig.Rules(runHeat)end
local PressurePolicy = require(script.Parent.PressurePolicy)
local SurvivalPolicy = require(script.Parent.SurvivalPolicy)
local StylePolicy=require(script.Parent.StylePolicy)
local Risk=require(script.Parent.RiskPolicy)
local ScorePickups=require(script.Parent.ScorePickupService)
local pickups
local bountyWaves={}
local styleEventSequence=0
local completedDistricts={}
local activeCampaign=nil
local reviveSnapshot=function()return false end
local Combat = {}
local records, enemies = {}, {}
local aiDirector = AttackDirector.New()
local enemySequence = 0
local difficulty = "Normal"
local function difficultyProfile() return Config.Difficulties[difficulty] end
local cameraEstimate, cameraSpan, cameraGoal, cameraGoalSpan
local lastCameraSample
-- Only disconnected players are cached; a legitimate campaign/checkpoint reset owns restoration.
local disconnectedSurvival = {}
local MAX_DISCONNECTED_SURVIVORS = 256
local arena, stageIndex = Config.Stages[1], 1
local checkpointPosition = Vector3.new(arena.SpawnX, 4, 0)
local walkingMaxX = arena.Waves[1].SpawnX + 30
local remotes, restartCallback, readyCallback
local initialized, battleEpoch = false, 0
local admissionValidator, travelLocked = nil, false
local pendingAdmissions, admissionSequence = {}, 0
local encounter = {wave = 0, waves = 4, enemiesRemaining = 0, status = "Waiting", waveTitle = "ENTER THE CURTAIN", encounterKind = "Wave", nextWaveAt = 0, checkpointLabel = "DISTRICT ENTRANCE", resultReason = "", targetX = 0, objective = "CHOOSE A HERO / READY UP"}
local function now() return workspace:GetServerTimeNow() end
local function root(model) return model and model:FindFirstChild("HumanoidRootPart") end
local function humanoid(model) return model and model:FindFirstChildOfClass("Humanoid") end
local function enemyPositionVisible(position)
    return cameraGoalSpan~=nil and cameraGoalSpan<160
        and CameraBounds.Visible(position,cameraEstimate,cameraSpan or 0)
        and CameraBounds.Visible(position,cameraGoal,cameraGoalSpan)
end
local function enemyVisible(model)
    local r=root(model)
    return r~=nil and enemyPositionVisible(r.Position)
end
local function enemySafePosition(position)
    return CameraBounds.SafePosition(position,cameraEstimate,cameraSpan,cameraGoal,cameraGoalSpan,arena)
end
local function modelOf(actor) return typeof(actor) == "Instance" and actor:IsA("Player") and actor.Character or actor end
local function recordOf(model)
    if typeof(model) ~= "Instance" or not model:IsA("Model") then return nil end
    local player = Players:GetPlayerFromCharacter(model)
    return player and records[player] or enemies[model], player
end
local function modifiers(player)
    local value = Progression.GetCombatModifiers(player) or {}
    return {damageMultiplier = math.clamp(value.damageMultiplier or 1, 1, 1.5), knockbackMultiplier = math.clamp(value.knockbackMultiplier or 1, 1, 1.5), moveSpeedBonus = math.clamp(value.moveSpeedBonus or 0, 0, 6), damageReduction = math.clamp(value.damageReduction or 0, 0, .3)}
end
local function fx(kind, position, fields)
    local packet = fields or {}
    packet.kind, packet.position = kind, position
    if remotes then remotes.FX:FireAllClients(packet) end
end
local function releaseGrab(enemy, rescued)
    local enemyData=enemies[enemy]
    local player=enemyData and enemyData.grabbedPlayer
    local data=player and records[player]
    if enemyData then enemyData.grabbedPlayer=nil end
    if data and data.grabbedBy==enemy then
        data.grabbedBy=nil
        if data.stunnedUntil==data.grabStunUntil then data.stunnedUntil=now() end
        data.grabStunUntil=nil
        fx("EnemyGrabRelease",root(enemy) and root(enemy).Position or Vector3.zero,{targetModel=enemy,targetUserId=player.UserId,rescued=rescued==true})
    end
end
local function styleState(data,create)
    if not data or not activeCampaign then return nil end
    data.styleDistricts=data.styleDistricts or {}
    local state=data.styleDistricts[stageIndex]
    if create and not state then
        state=StylePolicy.New(activeCampaign,stageIndex,now());data.styleDistricts[stageIndex]=state
    end
    return state
end
local function beginStyleWave(data)
    local state=styleState(data,true)
    if not state or state.result or encounter.status~="Combat"then return state end
    if state.attempt and state.attempt.wave~=encounter.wave then StylePolicy.Retry(state)end
    if not state.attempt then StylePolicy.BeginWave(state,encounter.wave,encounter.partySize or math.clamp(Combat.GetPlayerCount(),1,4),encounter.encounterKind,now())end
    return state
end
local function freshStats() return {kills = 0, damageDealt = 0, damageTaken = 0, coinsEarned = 0, duration = 0} end
local function desperationAllowed(player,data,t)
    local h=humanoid(player.Character)
    return Risk.Desperation(t,{alive=h~=nil and h.Health>0,downed=data.downed,respawning=data.respawning,
        grabbed=data.grabbedBy~=nil,travelLocked=travelLocked,status=encounter.status,stunnedUntil=data.stunnedUntil,
        busyUntil=data.busyUntil,desperationReadyAt=data.cooldowns.Desperation,specialReadyAt=data.cooldowns.Special})
end
function Combat.BeginRun(campaignId)
    activeCampaign=type(campaignId)=="string"and campaignId~=""and campaignId or nil
    if pickups then pickups:Clear()end
    table.clear(bountyWaves)
    pickups=activeCampaign and ScorePickups.new(activeCampaign,{
        Eligible=function(player,context)
            local data=records[player];local h=humanoid(player.Character)
            return data~=nil and player.Parent==Players and h~=nil and h.Health>0 and not data.downed
                and not data.respawning and not data.grabbedBy and not travelLocked and encounter.status=="Combat"
                and context.campaignId==activeCampaign and context.stage==stageIndex and context.wave==encounter.wave
        end,
        Claimed=function(player,record)
            local state=styleState(records[player],false)
            local before=StylePolicy.Snapshot(state).score
            if Combat.AwardStyle(player,"Orb","orb:"..record.id)then
                local delta=StylePolicy.Snapshot(state).score-before
                fx("ScoreOrbClaim",record.position,{playerUserId=player.UserId,score=delta})
            end
        end,
    })or nil
    table.clear(completedDistricts)
    enemySequence=0
    styleEventSequence=0
    Telemetry.Reset()
    table.clear(disconnectedSurvival)
    for _, data in pairs(records) do data.runStats = freshStats() data.runStart = now() data.runFinished = nil data.styleDistricts={} end
end
local SHARE_STATES = {Combat = true, Intermission = true, Traverse = true, Advance = true}
local function rescueTarget(player, requestedUserId)
    local data, donorRoot, donorHumanoid = records[player], root(player.Character), humanoid(player.Character)
    if not runRules().stockSharing or not data or not SHARE_STATES[encounter.status] or data.downed or data.respawning or data.stocks < 2
        or player.Parent ~= Players or not donorRoot or not donorHumanoid or donorHumanoid.Health <= 0 then return nil end
    if requestedUserId ~= nil and (type(requestedUserId) ~= "number" or requestedUserId ~= requestedUserId
        or math.abs(requestedUserId) == math.huge or requestedUserId % 1 ~= 0) then return nil end
    local selected, nearest = nil, math.huge
    for candidate, other in pairs(records) do
        if candidate ~= player and candidate.Parent == Players and other.downed and other.stocks == 0
            and not other.respawning and (requestedUserId == nil or candidate.UserId == requestedUserId) then
            local targetRoot = root(candidate.Character)
            local location = targetRoot and targetRoot.Position or checkpointPosition
            local offset = location - donorRoot.Position
            local distance = Vector2.new(offset.X, offset.Z).Magnitude
            if not selected or distance < nearest or (distance == nearest and candidate.UserId < selected.UserId) then
                selected, nearest = candidate, distance
            end
        end
    end
    return selected
end
function Combat.GetSnapshot(player)
    local data = records[player]
    if not data then return nil end
    local boss = false
    for _, enemy in pairs(enemies) do
        if enemy.spec.Role ~= "Grunt" then
            boss = {name = enemy.spec.Name, kind = enemy.kind, percent = enemy.percent, threshold = enemy.threshold, phase = enemy.phase, role = enemy.spec.Role, poise = enemy.poise, poiseLimit = enemy.spec.Poise, armored = now() < enemy.armoredUntil, exposed = now() >= (enemy.resolveAt or 0) and now() < enemy.recoveryUntil}
            break
        end
    end
    local ally = rescueTarget(player)
    local shareCooldown = math.max(0, (data.cooldowns.ShareStock or 0) - now())
    local style=styleState(data,false)
    local districtResult=style and style.result or false
    local districtReceipt=districtResult and Progression.GetDistrictReceipt(player,districtResult.id)or false
    local stats = table.clone(data.runStats)
    stats.duration = math.floor((data.runFinished or now()) - data.runStart)
    stats.damageDealt, stats.damageTaken = math.floor(stats.damageDealt), math.floor(stats.damageTaken)
    return {kind = "Snapshot", hero = data.hero, percent = math.floor(data.percent), stocks = data.stocks,
        style=StylePolicy.Snapshot(style),districtResult=districtResult,districtReceipt=districtReceipt,
        canDesperation=desperationAllowed(player,data,now()),desperationCost=Risk.DesperationCost,
        desperationCooldown=math.max(0,(data.cooldowns.Desperation or 0)-now()),
        stage = stageIndex, stageName = arena.Name, wave = encounter.wave, waves = encounter.waves, difficulty = difficulty, heat = {},
        enemiesRemaining = encounter.enemiesRemaining, pulse = encounter.pulse, pulses = encounter.pulses, status = encounter.status, blocking = data.blocking,
        downed = data.downed, downedRemaining = math.max(0,(data.downedUntil or 0)-now()), revive=reviveSnapshot(player), grabbed = data.grabbedBy ~= nil, cooldowns = {Special = data.cooldowns.Special or 0, Dash = data.cooldowns.Dash or 0, Burst = data.cooldowns.Burst or 0}, burstCost = difficultyProfile().Pressure.BurstCost,
        ready = data.ready, travelLocked = travelLocked, readyCount = Combat.GetReadyCount(), playersTotal = Combat.GetPlayerCount(),
        rescueTarget = ally and {name = ally.DisplayName, userId = ally.UserId} or false,
        canShareStock = ally ~= nil and shareCooldown <= 0, shareStockCooldown = shareCooldown,
        boss = boss, waveTitle = encounter.waveTitle, encounterName = encounter.waveTitle, encounterKind = encounter.encounterKind,
        targetX = encounter.targetX, objective = encounter.objective, walkingMaxX = walkingMaxX,
        nextWaveAt = encounter.nextWaveAt, checkpointLabel = encounter.checkpointLabel, resultReason = encounter.resultReason, runStats = stats}
end
function Combat.BroadcastState()
    for player in pairs(records) do if player.Parent then remotes.State:FireClient(player, Combat.GetSnapshot(player)) end end
end
function Combat.SetEncounterState(state)
    if state.status and state.status~="Combat"and pickups then pickups:Clear()end
    for key, value in pairs(state) do encounter[key] = value end
    Progression.SetRunState(encounter.status, stageIndex)
    if state.status == "Victory" or state.status == "Defeat" then
        for _, data in pairs(records) do data.runFinished = now() end
        Telemetry.Finish(state.status)
    elseif state.status == "Combat" then
        Telemetry.BeginEncounter(stageIndex, encounter.wave)
        for _, data in pairs(records) do data.runFinished = nil;beginStyleWave(data)end
    end
    Combat.BroadcastState()
end
function Combat.SetArena(stage, index)
    arena, stageIndex = stage, index or stageIndex
    for _,data in pairs(records)do styleState(data,true)end
    checkpointPosition = Vector3.new(stage.SpawnX, 4, 0)
    walkingMaxX = stage.SpawnX + 30
    workspace:SetAttribute("NightfallStage", stageIndex)
end
function Combat.SetWalkingLimit(maxX)
    local limit = math.clamp(maxX, arena.MinX + 8, arena.MaxX - 4)
    for _, player in ipairs(Combat.GetAlivePlayers()) do
        local r = root(player.Character)
        if r and r.Position.X >= arena.MinX and r.Position.X <= arena.MaxX then limit = math.max(limit, r.Position.X) end
    end
    walkingMaxX = math.min(arena.MaxX - 4, math.max(walkingMaxX, limit))
end
function Combat.SetCheckpoint(position, label)
    checkpointPosition = position
    encounter.checkpointLabel = label or "DISTRICT CHECKPOINT"
end
function Combat.SetRestartCallback(callback) restartCallback = callback end
function Combat.SetReadyCallback(callback) readyCallback = callback end
function Combat.SetAdmissionValidator(callback)
    assert(callback==nil or type(callback)=="function","Admission validator must be a function or nil")
    admissionValidator=callback
end
function Combat.GetRunStatus() return encounter.status end
function Combat.GetRunRules()return runRules()end
function Combat.SetRunOptions(selected,heat)
    if not DifficultyPolicy.ValidOptions(Config.Difficulties,selected,heat) then return false end
    if encounter.status~="Waiting" then return selected==difficulty end
    difficulty=selected
    Combat.BroadcastState()
    return true
end
function Combat.GetRunOptions() return {difficulty=difficulty,heat={}} end
function Combat.SetTravelLocked(locked)
    assert(type(locked)=="boolean","Travel lock must be boolean")
    travelLocked=locked
    Combat.BroadcastState()
end
function Combat.ReadyForMatch(players)
    if encounter.status~="Waiting" then return false end
    local changed=false
    for _,player in ipairs(players)do
        local data=records[player]
        if data and player.Parent==Players then data.ready=true;changed=true end
    end
    if changed then Combat.BroadcastState();if readyCallback then readyCallback()end end
    return changed
end
function Combat.GetReadyCount() local count = 0 for _, data in pairs(records) do if data.ready then count += 1 end end return count end
function Combat.ClearReady() for _, data in pairs(records) do data.ready = false end end
function Combat.GetAlivePlayers()
    local alive = {}
    for player, data in pairs(records) do
        local h = humanoid(player.Character)
        if not data.downed and data.stocks > 0 and h and h.Health > 0 and root(player.Character) then table.insert(alive, player) end
    end
    return alive
end
function Combat.GetPlayerCount() local count = 0 for _ in pairs(records) do count += 1 end return count end
function Combat.GetEnemies() return enemies end
function Combat.GetAIDiagnostics()
    if not RunService:IsStudio() then return nil end
    local function vector(v) return v and {x=v.X,y=v.Y,z=v.Z} or false end
    local t=now();local result={time=t,cameraGoal=vector(cameraGoal),cameraEstimate=vector(cameraEstimate),cameraSpan=cameraSpan,cameraGoalSpan=cameraGoalSpan,actors={},players={}}
    for _,player in ipairs(Combat.GetAlivePlayers())do table.insert(result.players,{id=player.UserId,position=vector(root(player.Character).Position)})end
    for model,data in pairs(enemies)do
        local r,h=root(model),humanoid(model);local slot,token=aiDirector.slots[model],aiDirector.tokens[model]
        local target=slot and root(slot.target.Character)
        table.insert(result.actors,{kind=data.kind,state=data.aiState,position=r and vector(r.Position),velocity=r and vector(r.AssemblyLinearVelocity),
            moveDirection=h and vector(h.MoveDirection),walkTo=h and vector(h.WalkToPoint),canAttack=enemyVisible(model),target=target and vector(target.Position),
            targetId=slot and slot.target.UserId,slot=slot and vector(slot.offset),token=token~=nil,tokenRemaining=token and token.expires-t,
            attackIn=data.attackAt-t,recoveryIn=data.recoveryUntil-t,resolveIn=(data.resolveAt or 0)-t,attacking=data.attacking,
            footworkGoal=vector(data.footworkGoal),nextMove=data.nextMove,lastMove=data.lastMove,lastAttackAgo=data.lastAttackAt and t-data.lastAttackAt,retreatIn=(data.retreatUntil or 0)-t})
    end
    return result
end
function Combat.AddCoinsEarned(player, amount)
    local data = records[player]
    if data then data.runStats.coinsEarned += math.max(0, amount) end
end
function Combat.BeginEncounter()
    if pickups then pickups:Clear()end
    battleEpoch += 1
    for _, data in pairs(records) do data.contribution = 0 end
end
function Combat.CommitStyleWave(campaignId,stage,wave)
    if campaignId~=activeCampaign or stage~=stageIndex or wave~=encounter.wave then return false end
    for _,data in pairs(records)do
        local state=styleState(data,false)
        if state then StylePolicy.CommitWave(state,wave,true)end
    end
    for _,saved in pairs(disconnectedSurvival)do
        local state=saved.styleDistricts and saved.styleDistricts[stage]
        if state and state.campaignId==activeCampaign then StylePolicy.CommitWave(state,wave,false)end
    end
    return true
end
function Combat.FinalizeDistrict(campaignId,stage)
    local results={}
    if campaignId~=activeCampaign or stage~=stageIndex then return results end
    for player,data in pairs(records)do
        local state=styleState(data,false)
        if state then
            local result=StylePolicy.Finalize(state,now(),{difficulty=difficulty,heat=runHeat})
            if result then results[player]=result end
        end
    end
    for _,saved in pairs(disconnectedSurvival)do
        local state=saved.styleDistricts and saved.styleDistricts[stage]
        if state and state.campaignId==activeCampaign then
            StylePolicy.Finalize(state,now(),{difficulty=difficulty,heat=runHeat})
        end
    end
    return results
end
function Combat.AwardStyle(player,kind,id,fields)
    local data=records[player]
    if not data or data.downed or data.respawning or encounter.status~="Combat"then return false end
    local state=beginStyleWave(data)
    if not state then return false end
    local event=table.clone(fields or {});event.kind,event.id=kind,id
    event.gainMultiplier=(Progression.GetCombatModifiers(player)or {}).styleGainMultiplier or 1
    return StylePolicy.Award(state,event)
end
function Combat.GetParticipants()
    local participants = {}
    for player, data in pairs(records) do if player.Parent and data.contribution > 0 then table.insert(participants, player) end end
    return participants
end
local function attributes(model, data)
    if not model then return end
    model:SetAttribute("Percent", data.percent)
    model:SetAttribute("Stocks", data.stocks or 1)
    model:SetAttribute("Blocking", data.blocking or false)
    model:SetAttribute("Hero", data.hero or data.kind)
    model:SetAttribute("Downed", data.downed or false)
    if data.spec then
        model:SetAttribute("Phase", data.phase)
        model:SetAttribute("Poise", data.poise)
        model:SetAttribute("Armored", now() < data.armoredUntil)
    end
    local head = model:FindFirstChild("Head")
    local plate = head and head:FindFirstChild("EnemyPlate")
    if plate and data.threshold then
        plate.Percent.Text = tostring(math.floor(data.percent)) .. "%"
        plate.Track.Fill.Size = UDim2.fromScale(math.max(0, 1 - data.percent / data.threshold), 1)
    end
end
local function setVisualIdentity(model, hero)
    if not model then return end
    local old = model:FindFirstChild("HeroAura")
    if old then old:Destroy() end
    local highlight = Instance.new("Highlight")
    highlight.Name = "HeroAura"
    highlight.FillColor, highlight.OutlineColor = Config.Characters[hero].Color, Config.Characters[hero].Color
    highlight.FillTransparency, highlight.OutlineTransparency = .92, .65
    highlight.Parent = model
end
local function resetPosition(player, position, percent)
    local model, data = player.Character, records[player]
    local r, h = root(model), humanoid(model)
    if not data or not r or not h then return end
    data.percent, data.blocking, data.downed, data.respawning = percent or 0, false, false, false
    data.revive,data.downedUntil,data.downedPosition=nil,nil,nil
    data.stunnedUntil, data.launchedUntil, data.recovered = 0, 0, false
    data.recentHits = {}
    data.blockStartedAt,data.perfectBlockConsumed,data.lastBlockPressedAt=nil,false,nil
    data.invulnerableUntil = now() + 2
    r.Anchored = false
    r.AssemblyLinearVelocity = Vector3.zero
    model:PivotTo(CFrame.new(position) * CFrame.Angles(0, -math.pi / 2, 0))
    h.Health = h.MaxHealth
    h.WalkSpeed, h.JumpPower = Config.Characters[data.hero].Speed + modifiers(player).moveSpeedBonus, Config.JumpPower
    attributes(model, data)
    fx("Spawn", position, {hero = data.hero, playerUserId = player.UserId})
end
local function spawnPlayer(player)
    local data = records[player]
    if not data or not player.Parent then return end
    local old = player.Character
    local model = CharacterFactory.Create(data.hero)
    model.Name, model.Parent = player.Name, workspace
    player.Character = model
    if old then old:Destroy() end
end
-- A server-owned transfer: validate both records, then commit both stocks before any spawn work.
function Combat.ShareStock(player, requestedUserId)
    local target = rescueTarget(player, requestedUserId)
    if not target then return false end
    local donor, recipient, t = records[player], records[target], now()
    if t < (donor.cooldowns.ShareStock or 0) then return false end
    local donorRoot = root(player.Character)
    local z = donorRoot.Position.Z + (donorRoot.Position.Z > 0 and -4 or 4)
    local position = Vector3.new(math.clamp(donorRoot.Position.X - donor.facing * 4, arena.MinX + 6, math.max(arena.MinX + 6, walkingMaxX - 2)), 4,
        math.clamp(z, Config.LaneMin + 2, Config.LaneMax - 2))
    donor.stocks -= 1
    donor.cooldowns.ShareStock = t + 10
    recipient.stocks, recipient.percent, recipient.downed, recipient.respawning = 1, 0, false, true
    recipient.downedUntil,recipient.downedPosition,recipient.revive=nil,nil,nil
    recipient.lifeSerial += 1
    recipient.preserveSpawn, recipient.resumeSurvival = nil, nil
    recipient.busyUntil, recipient.guard = 0, 0
    recipient.spawnPosition = position
    attributes(player.Character, donor)
    local targetHumanoid = humanoid(target.Character)
    if targetHumanoid and targetHumanoid.Health > 0 and root(target.Character) then
        recipient.spawnPosition = nil
        resetPosition(target, position)
    else
        -- CharacterFactory builds synchronously; CharacterAdded completes normal protected setup.
        spawnPlayer(target)
    end
    fx("ShareStock", position, {playerUserId = player.UserId, targetUserId = target.UserId, targetModel = target.Character,
        donorName = player.DisplayName, targetName = target.DisplayName})
    Combat.BroadcastState()
    return true
end
local function relocatePlayers(position,mode)
    for _,saved in pairs(disconnectedSurvival)do
        saved.stocks,saved.percent=SurvivalPolicy.Reset(mode,saved.stocks,saved.percent,Config.Survival,runRules().stockCap)
        saved.downed=saved.stocks<=0;saved.cooldowns={}
        if not saved.downed then saved.downedUntil,saved.downedPosition=nil,nil end
    end
    local index = 0
    for player, data in pairs(records) do
        data.lifeSerial += 1
        data.resumeSurvival = nil
        data.stocks,data.percent=SurvivalPolicy.Reset(mode,data.stocks,data.percent,Config.Survival,runRules().stockCap)
        data.cooldowns,data.downed,data.respawning,data.revive={},data.stocks<=0,false,nil
        data.spawnPosition,data.spawnPercent = position,data.percent
        local downedUntil=data.downedUntil
        if data.stocks<=0 then
            data.resumeSurvival={stocks=0,percent=data.percent,downed=true,downedUntil=downedUntil,downedPosition=position}
        end
        index += 1
        if humanoid(player.Character) and humanoid(player.Character).Health > 0 then
            data.spawnPosition = nil
            resetPosition(player, position + Vector3.new(0, 0, (index - 1) * 3 - 4),data.percent)
            data.spawnPercent=nil
            if data.stocks<=0 then
                data.downed,data.downedUntil,data.downedPosition=true,downedUntil,position
                data.resumeSurvival=nil
                local r,h=root(player.Character),humanoid(player.Character)
                if r then r.Anchored=true end
                if h then h.WalkSpeed,h.JumpPower=0,0 end
                attributes(player.Character,data)
            end
        else task.spawn(spawnPlayer, player) end
    end
    Combat.BroadcastState()
end
function Combat.ResetPlayers(position)relocatePlayers(position,"Campaign")end
function Combat.EnterDistrict(position)relocatePlayers(position,"Travel")end
function Combat.RetryCheckpoint(position)
    for _,data in pairs(records)do local state=styleState(data,false);if state then StylePolicy.Retry(state)end end
    for _,saved in pairs(disconnectedSurvival)do
        local state=saved.styleDistricts and saved.styleDistricts[stageIndex];if state then StylePolicy.Retry(state)end
    end
    relocatePlayers(position,"Retry")
end
function Combat.CompleteDistrict(campaignId,stage)
    if not activeCampaign or campaignId~=activeCampaign or type(stage)~="number"or stage%1~=0
        or stage<1 or stage>#Config.Stages or stage~=stageIndex then return false end
    local key=tostring(campaignId)..":"..stage
    if completedDistricts[key]then return false end
    completedDistricts[key]=true
    for _,saved in pairs(disconnectedSurvival)do
        saved.stocks,saved.percent=SurvivalPolicy.Reset("Clear",saved.stocks,saved.downed and 0 or saved.percent,Config.Survival,runRules().stockCap)
        saved.downed,saved.downedUntil,saved.downedPosition=false,nil,nil
    end
    for player,data in pairs(records)do
        data.stocks,data.percent=SurvivalPolicy.Reset("Clear",data.stocks,(data.downed or data.respawning)and 0 or data.percent,Config.Survival,runRules().stockCap)
        if data.downed or data.respawning then
            data.lifeSerial+=1;data.spawnPosition=checkpointPosition;data.spawnPercent=data.percent
            data.downed,data.downedUntil,data.revive,data.respawning=false,nil,nil,false
            if root(player.Character)and humanoid(player.Character)and humanoid(player.Character).Health>0 then
                resetPosition(player,checkpointPosition,data.percent);data.spawnPosition,data.spawnPercent=nil,nil
            else task.spawn(spawnPlayer,player)end
        end
        attributes(player.Character,data)
    end
    Combat.BroadcastState();return true
end
local function reviveTarget(player,requested)
    local data=records[player];local r=root(player.Character);local h=humanoid(player.Character)
    if not h or h.Health<=0 then return nil end
    if not data or data.downed or data.respawning or data.grabbedBy or not r or not SHARE_STATES[encounter.status]
        or travelLocked or now()<data.stunnedUntil or now()<data.busyUntil then return nil end
    if requested~=nil and(type(requested)~="number"or requested~=requested or requested%1~=0)then return nil end
    local target,best=nil,Config.Survival.ReviveRange+.001
    for other,victim in pairs(records)do
        local otherRoot=root(other.Character)
        if other~=player and victim.downed and victim.stocks==0 and now()<(victim.downedUntil or 0)
            and otherRoot and(requested==nil or requested==other.UserId)then
            local d=(Vector2.new(r.Position.X,r.Position.Z)-Vector2.new(otherRoot.Position.X,otherRoot.Position.Z)).Magnitude
            if d<best then target,best=other,d end
        end
    end
    return target
end
reviveSnapshot=function(player)
    local data=records[player];local channel=data and data.revive
    local target=channel and channel.target or reviveTarget(player)
    local victim=target and records[target]
    if not victim then return false end
    return {targetUserId=target.UserId,name=target.DisplayName,canStart=reviveTarget(player,target.UserId)~=nil,
        channeling=channel~=nil,progress=channel and math.clamp((now()-channel.started)/Config.Survival.ReviveDuration,0,1)or 0,
        remaining=math.max(0,(victim.downedUntil or 0)-now())}
end
function Combat.Revive(player,held,requested)
    local data=records[player]
    if not data then return false end
    if held==false then data.revive=nil;return true end
    if held~=true then return false end
    local target=reviveTarget(player,requested)
    if not target then return false end
    if data.revive and data.revive.target==target then return true end
    data.blocking=false
    data.revive={target=target,started=now(),position=root(player.Character).Position,life=data.lifeSerial,
        targetLife=records[target].lifeSerial,hitAt=data.hitAt}
    attributes(player.Character,data);return true
end
local function stepRevives(t)
    for player,data in pairs(records)do
        local channel=data.revive
        if not channel then continue end
        local victim=records[channel.target];local r=root(player.Character);local other=root(channel.target.Character)
        local alive=player.Parent==Players and channel.target.Parent==Players and victim and victim.downed
            and data.lifeSerial==channel.life and victim.lifeSerial==channel.targetLife and not data.downed and not data.respawning
            and not data.grabbedBy and not travelLocked and SHARE_STATES[encounter.status]and r and other
            and humanoid(player.Character)and humanoid(player.Character).Health>0
        local distance=alive and Vector2.new(r.Position.X-other.Position.X,r.Position.Z-other.Position.Z).Magnitude or math.huge
        local moved=alive and(r.Position-channel.position).Magnitude or math.huge
        if not SurvivalPolicy.CanChannel(t,victim and victim.downedUntil or 0,distance,moved,data.hitAt~=channel.hitAt,alive)then
            data.revive=nil
        elseif t-channel.started>=Config.Survival.ReviveDuration then
            data.revive=nil;victim.lifeSerial+=1
            victim.stocks,victim.percent=1,Config.Survival.RevivePercent
            victim.spawnPosition,victim.spawnPercent=other.Position,Config.Survival.RevivePercent
            victim.downed,victim.downedUntil,victim.downedPosition,victim.respawning=false,nil,nil,false
            if humanoid(channel.target.Character)and humanoid(channel.target.Character).Health>0 then
                resetPosition(channel.target,other.Position,Config.Survival.RevivePercent)
                victim.spawnPosition,victim.spawnPercent=nil,nil
            else spawnPlayer(channel.target)end
            fx("Revive",other.Position,{playerUserId=player.UserId,targetUserId=channel.target.UserId,targetModel=channel.target.Character})
            Combat.BroadcastState()
        end
    end
end
local function knockOut(model)
    local knockedData, knockedPlayer=recordOf(model)
    if knockedData and knockedData.grabbedBy then releaseGrab(knockedData.grabbedBy,true) end
    if not knockedPlayer then releaseGrab(model,true) end
    local data, player = recordOf(model)
    if not data or data.downed or data.respawning then return end
    local r = root(model)
    fx("KO", r and r.Position or Vector3.zero, {hero = data.hero, playerUserId = player and player.UserId, enemy = data.kind})
    if not player then
        enemies[model] = nil
        AttackDirector.Release(aiDirector,model)
        if data.bounty and data.bounty.campaignId==activeCampaign and data.bounty.stage==stageIndex and data.bounty.wave==encounter.wave then
            local participants={}
            for contributor in pairs(data.contributors)do
                if records[contributor]and contributor.Parent==Players then table.insert(participants,contributor)end
            end
            Progression.AwardBounty(participants,data.bounty.campaignId,data.bounty.stage,data.bounty.wave)
        end
        -- Last-KO exception: orbs require another live enemy so collection remains a combat risk.
        if pickups and next(enemies)and r and encounter.status=="Combat"then
            local position=Vector3.new(math.clamp(r.Position.X,arena.MinX+6,walkingMaxX-2),2,math.clamp(r.Position.Z,-11,11))
            pickups:Spawn("ko:"..tostring(data.styleId),position,now()+Risk.ScoreOrbLifetime,
                {campaignId=activeCampaign,stage=stageIndex,wave=encounter.wave})
        end
        for contributor in pairs(data.contributors) do
            if records[contributor] then records[contributor].runStats.kills += 1 end
        end
        model:SetAttribute("Defeated", true)
        model:Destroy()
        return
    end
    Telemetry.StockLoss(player)
    data.stocks, data.blocking, data.respawning = math.max(0, data.stocks - 1), false, true
    data.lifeSerial += 1
    data.revive=nil
    local lifeSerial = data.lifeSerial
    if r then r.Anchored = true end
    if data.stocks <= 0 then
        data.downed, data.respawning = true, false
        data.downedUntil=now()+Config.Survival.DownedDuration
        local position=r and r.Position or checkpointPosition
        data.downedPosition=Vector3.new(math.clamp(position.X,arena.MinX+6,walkingMaxX-2),3,math.clamp(position.Z,Config.LaneMin+2,Config.LaneMax-2))
        attributes(model, data)
        if r then model:PivotTo(CFrame.new(data.downedPosition))end
        local h = humanoid(model)
        if h then h.WalkSpeed, h.JumpPower = 0, 0 end
    else
        task.delay(1.15, function()
            if records[player] ~= data or data.lifeSerial ~= lifeSerial then return end
            data.respawning = false
            if player.Character == model and humanoid(model) and humanoid(model).Health > 0 then resetPosition(player, checkpointPosition)
            elseif player.Parent then spawnPlayer(player) end
        end)
    end
    Combat.BroadcastState()
end
function Combat.ApplyHit(attacker, target, attack, direction)
    local targetModel, sourceModel = modelOf(target), modelOf(attacker)
    if not targetModel or not sourceModel or targetModel == sourceModel then return false end
    local data, victimPlayer = recordOf(targetModel)
    local sourceData, sourcePlayer = recordOf(sourceModel)
    local r, t = root(targetModel), now()
    if not data or not sourceData or not r or data.downed or data.respawning or sourceData.downed or t < data.invulnerableUntil then return false end
    if (victimPlayer ~= nil) == (sourcePlayer ~= nil) then return false end
    if victimPlayer and not enemyVisible(sourceModel) then Telemetry.BoundsRejected();return false end
    local enemyId=data.spec and Archetypes.Id(data.kind,data.spec)
    if not victimPlayer and data.grabbedPlayer and sourcePlayer then releaseGrab(targetModel,true) end
    if victimPlayer and data.grabbedBy and data.grabbedBy~=sourceModel then releaseGrab(data.grabbedBy,true) end
    local light=sourcePlayer and sourceData.lastAction=="Light"
    local blocked = not attack.Unblockable and data.blocking and data.facing == -direction
        and (victimPlayer~=nil or (enemyId=="Warden" and light))
    if victimPlayer and Risk.PerfectBlock(t,data.blockStartedAt,blocked,attack.Unblockable,data.perfectBlockConsumed)then
        data.perfectBlockConsumed=true
        sourceData.attackSerial+=1;sourceData.attacking=false;sourceData.engaging=false
        sourceData.resolveAt=t;sourceData.armoredUntil=0
        sourceData.stunnedUntil=math.max(sourceData.stunnedUntil,t+Risk.PerfectStagger)
        sourceData.recoveryUntil=math.max(sourceData.recoveryUntil,t+Risk.PerfectStagger)
        sourceData.attackAt=math.max(sourceData.attackAt,t+Risk.PerfectStagger)
        AttackDirector.Release(aiDirector,sourceModel);releaseGrab(sourceModel,true)
        local attackerRoot=root(sourceModel)
        if attackerRoot then attackerRoot.AssemblyLinearVelocity=Vector3.zero end
        styleEventSequence+=1
        Combat.AwardStyle(victimPlayer,"PerfectBlock","parry:"..styleEventSequence)
        data.contribution+=3
        fx("EnemyCancel",attackerRoot and attackerRoot.Position or r.Position,{targetModel=sourceModel,enemy=sourceData.kind})
        fx("PerfectBlock",r.Position,{targetModel=targetModel,attackerModel=sourceModel,duration=Risk.PerfectStagger})
        return false -- No damage, chip, grab, knockback or hit telemetry was accepted.
    end
    if enemyId=="Warden" and sourcePlayer and sourceData.lastAction=="Heavy" then data.guardBrokenUntil=t+1.1;data.blocking=false end
    local styleBackHit=sourcePlayer and data.facing==direction
    local targetHumanoid=humanoid(targetModel)
    local styleAirHit=sourcePlayer and t<(data.launchedUntil or 0)and targetHumanoid and targetHumanoid.FloorMaterial==Enum.Material.Air
    local damage = attack.Damage * (blocked and .2 or 1)
    local knockbackMultiplier = 1
    if sourcePlayer then
        local mods = modifiers(sourcePlayer)
        damage *= mods.damageMultiplier
        knockbackMultiplier = mods.knockbackMultiplier
    end
    if victimPlayer then damage *= 1 - modifiers(victimPlayer).damageReduction end
    local elite = data.spec and data.spec.Role ~= "Grunt"
    local lightArmor=enemyId=="Grappler" and light
    local armored = (elite or enemyId=="Brute") and t < data.armoredUntil or lightArmor
    if armored then damage *= .9 end
    data.percent = math.min(999, data.percent + damage)
    local stun = blocked and .08 or attack.Stun
    if victimPlayer then
        local duration,recent,breaker=PressurePolicy.HitProtection(data.recentHits,t,difficultyProfile().Pressure)
        data.recentHits=recent
        data.invulnerableUntil=t+duration
        if breaker then fx("ComboBreaker",r.Position,{targetUserId=victimPlayer.UserId,targetModel=targetModel,duration=duration})end
        data.hitAt = t
        data.revive=nil
        data.runStats.damageTaken += damage
        local style=beginStyleWave(data);if style then StylePolicy.TakenHit(style,damage)end
        Telemetry.Hit(victimPlayer, damage)
        data.contribution += damage + (blocked and 3 or 0)
    elseif lightArmor or (enemyId=="Brute" and armored) then
        stun=0
    elseif elite then
        stun = armored and 0 or math.min(stun, .16)
        if armored then
            data.poise += attack.Damage * (attack.Damage < 14 and .5 or 1)
            if data.poise >= data.spec.Poise then
                data.attackSerial += 1
                data.attacking, data.armoredUntil, data.poise, data.resolveAt = false, 0, 0, t
                data.recoveryUntil, data.attackAt = t + 2.0, t + 2.1
                stun = 1.6
                fx("BossStagger", r.Position, {enemy = data.kind, enemyName = data.spec.Name, targetModel = targetModel})
            end
        end
    end
    data.stunnedUntil = math.max(data.stunnedUntil, t + stun)
    data.launchedUntil = t + (lightArmor and 0 or elite and .12 or blocked and .1 or .55)
    if blocked then
        data.guard += attack.Damage
        if data.guard >= 55 then
            data.blocking, data.guard = false, 0
            data.stunnedUntil = t + 1.2
            fx("GuardBreak", r.Position, {targetUserId = victimPlayer and victimPlayer.UserId, targetModel = targetModel})
        end
    end
    local velocity = CombatMath.Knockback(data.percent, attack, data.weight or 1) * knockbackMultiplier
    velocity *= blocked and .2 or armored and .08 or elite and .5 or 1
    r.AssemblyLinearVelocity = Vector3.new(direction * velocity, blocked and 3 or armored and 0 or elite and math.min(attack.Lift, 8) or attack.Lift, r.AssemblyLinearVelocity.Z * .3)
    if sourcePlayer then
        sourceData.runStats.damageDealt += damage
        if not attack.StyleId then styleEventSequence+=1 end
        Combat.AwardStyle(sourcePlayer,attack.StyleKind or "Hit",tostring(attack.StyleId or styleEventSequence)..":"..tostring(data.styleId),
            {damage=damage,backHit=styleBackHit,airHit=styleAirHit})
        sourceData.contribution += damage
        data.contributors[sourcePlayer] = true
    end
    attributes(targetModel, data)
    fx("Hit", r.Position, {direction = direction, damage = damage, heavy = attack.Damage >= 18, hero = sourceData.hero,
        playerUserId = sourcePlayer and sourcePlayer.UserId, targetUserId = victimPlayer and victimPlayer.UserId, targetModel = targetModel, armored = armored, enemyHit = victimPlayer ~= nil, sourcePosition = root(sourceModel) and root(sourceModel).Position, serverTime = t})
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
            local heading = attack.Omnidirectional and candidateRoot and (candidateRoot.Position.X >= r.Position.X and 1 or -1) or direction
            Combat.ApplyHit(actor, candidate, attack, heading)
        end
    end
end
local function performAttack(player, action, data)
    local model, r = player.Character, root(player.Character)
    if not r then return end
    local attack = table.clone(action == "Special" and Config.Characters[data.hero].Special or Config.Attacks[action])
    if action == "Light" then
        data.combo = now() - data.lastLight < .9 and (data.combo % 3 + 1) or 1
        data.lastLight = now()
        if data.combo == 3 then attack.Damage *= 1.5 attack.Knockback += 18 attack.Lift = 18 end
    end
    styleEventSequence+=1;attack.StyleId=styleEventSequence
    data.lastAction, data.attackStartedAt = action, now()
    data.cooldowns[action], data.busyUntil, data.blocking = now() + attack.Cooldown, now() + attack.Windup + .13, false
    local direction, epoch, lifeSerial = data.facing, battleEpoch, data.lifeSerial
    r.CFrame = CFrame.lookAt(r.Position, r.Position + Vector3.new(direction, 0, 0))
    fx("Attack", r.Position, {hero = data.hero, action = action, direction = direction, playerUserId = player.UserId, combo = data.combo})
    task.delay(attack.Windup, function()
        if epoch ~= battleEpoch or encounter.status ~= "Combat" or records[player] ~= data or data.lifeSerial ~= lifeSerial or player.Character ~= model or data.downed or data.respawning or now() < data.stunnedUntil then return end
        doHitbox(player, attack, direction)
        if action == "Heavy" or action == "Special" then Destruction.BreakNearby(r.Position + Vector3.new(direction * attack.Range / 2, 0, 0), math.clamp(attack.Width, 8, 14), direction) end
    end)
end
local allowedActions = {Light = true, Heavy = true, Special = true, Dash = true, Block = true, Recovery = true, Jump = true, SelectCharacter = true, Restart = true, Ready = true, ShareStock = true, Revive = true, Desperation = true}
local function actionReceived(player, action, payload)
    -- Cancellation is cheap and cannot grant an action; never lose release to the request throttle.
    if action=="Revive"and type(payload)=="table"and payload.held==false then
        local releasing=records[player];if releasing then releasing.revive=nil end;return
    end
    if action=="Block"and type(payload)=="table"and payload.held==false then
        local releasing=records[player]
        if releasing then releasing.blocking=false;releasing.blockStartedAt=nil;attributes(player.Character,releasing)end
        return
    end
    if travelLocked then return end
    local data = records[player]
    if not data or type(action) ~= "string" or not allowedActions[action] or (payload ~= nil and type(payload) ~= "table") then return end
    payload = payload or {}
    local t = now()
    if t - data.rateStart >= 1 then data.rateStart, data.rateCount = t, 0 end
    data.rateCount += 1
    if data.rateCount > 30 then return end
    if action == "Revive"then Combat.Revive(player,payload.held,payload.targetUserId);return end
    if action == "ShareStock" then data.revive=nil;Combat.ShareStock(player, payload.targetUserId) return end
    if action == "Ready" then
        if admissionValidator then return end -- Only the server arrival gate readies reserved matches.
        if encounter.status == "Waiting" and (payload.ready == nil or type(payload.ready) == "boolean") then
            data.ready = payload.ready ~= false
            Combat.BroadcastState()
            if readyCallback then readyCallback() end
        end
        return
    end
    if action == "Restart" then
        if restartCallback and (encounter.status == "Defeat" or encounter.status == "Victory") then restartCallback() end
        return
    end
    if action == "SelectCharacter" then
        if type(payload.hero) == "string" and Config.Characters[payload.hero] and t >= data.selectAt and encounter.status ~= "Combat" then
            if data.downed or data.respawning then return end
            local currentRoot = root(player.Character)
            if not currentRoot then return end
            data.preserveSpawn = {position = currentRoot.Position, percent = data.percent, invulnerableUntil = data.invulnerableUntil, recovered = data.recovered}
            data.hero, data.selectAt = payload.hero, t + 1
            spawnPlayer(player)
            Combat.BroadcastState()
        end
        return
    end
    if action == "Block" and payload.held == false then data.blocking = false attributes(player.Character, data) return end
    if data.downed or data.respawning or data.grabbedBy then return end
    data.revive=nil
    local movementAction = action == "Dash" or action == "Recovery" or action == "Jump"
    if encounter.status ~= "Combat" and not (movementAction and (encounter.status == "Intermission" or encounter.status == "Advance" or encounter.status == "Traverse" or encounter.status == "Waiting")) then return end
    local pressure=difficultyProfile().Pressure
    local dashAllowed,burstCost=PressurePolicy.Burst(t,data.stunnedUntil,data.hitAt,data.cooldowns.Burst,pressure)
    if t < data.stunnedUntil and not (action == "Dash" and dashAllowed) then return end
    local r, h = root(player.Character), humanoid(player.Character)
    if not r or not h or h.Health <= 0 then return end
    data.facing = CombatMath.Direction(payload.direction, data.facing)
    if t < data.busyUntil then return end
    if action == "Block" then
        if payload.held == true then
            if not data.blocking then
                data.blockStartedAt=Risk.ArmPerfect(t,data.lastBlockPressedAt)and t or nil
                data.lastBlockPressedAt=t;data.perfectBlockConsumed=false
            end
            data.blocking=true;attributes(player.Character,data)
        end
    elseif action=="Desperation"then
        if not desperationAllowed(player,data,t)then return end
        data.cooldowns.Desperation=t+Risk.DesperationCooldown
        local paid,ko=Risk.PayPercent(data.percent,Risk.DesperationCost,Config.PlayerPercentLimit)
        data.percent=paid;attributes(player.Character,data)
        fx("Desperation",r.Position,{targetModel=player.Character,playerUserId=player.UserId,cost=Risk.DesperationCost})
        if ko then knockOut(player.Character);return end
        performAttack(player,"Special",data)
    elseif action == "Dash" and t >= (data.cooldowns.Dash or 0) then
        if not dashAllowed then return end
        if burstCost>0 then
            data.percent=math.min(999,data.percent+burstCost)
            data.cooldowns.Burst=t+pressure.BurstCooldown
            attributes(player.Character,data)
            if data.percent>=Config.PlayerPercentLimit then knockOut(player.Character);return end
        end
        data.cooldowns.Dash, data.invulnerableUntil = t + 1.4, math.max(data.invulnerableUntil,t + .24)
        data.blocking, data.stunnedUntil = false, 0
        r.AssemblyLinearVelocity = Vector3.new(data.facing * 74, math.max(0, r.AssemblyLinearVelocity.Y), 0)
        data.launchedUntil = t + .18
        fx("Dash", r.Position, {direction = data.facing, hero = data.hero, playerUserId = player.UserId,burst=burstCost>0,cost=burstCost})
    elseif action == "Recovery" or action == "Jump" then
        if h.FloorMaterial == Enum.Material.Air and not data.recovered then
            data.recovered = true
            r.AssemblyLinearVelocity = Vector3.new(data.facing * 26, 58, 0)
            fx("Recovery", r.Position, {hero = data.hero, playerUserId = player.UserId})
        elseif h.FloorMaterial ~= Enum.Material.Air then h.Jump = true end
    elseif (Config.Attacks[action] or action == "Special") and t >= (data.cooldowns[action] or 0) then performAttack(player, action, data) end
end
function Combat.SpawnEnemy(kind, position, healthScale)
    local spec = Config.Enemies[kind]
    assert(spec, "Unknown enemy kind: " .. tostring(kind))
    local model = EnemyFactory.Create(kind, spec)
    model.Parent = workspace.Enemies
    model:PivotTo(CFrame.new(position + Vector3.new(0, spec.Scale * 3, 0)) * CFrame.Angles(0, math.pi / 2, 0))
    root(model):SetNetworkOwner(nil)
    local data = {kind = kind, percent = 0, threshold = spec.Threshold * (healthScale or 1) * (spec.Role~="Grunt" and (difficultyProfile().EliteHealthScale or 1) or 1), weight = spec.Weight,
        blocking = false, guard = 0, facing = -1, stunnedUntil = 0, launchedUntil = 0, invulnerableUntil = 0,
        attackAt = now() + 1.6, spec = spec, phase = 1, poise = 0, armoredUntil = 0, recoveryUntil = 0,
        moveIndex = 0, attackSerial = 0, contributors = {}, targetHistory = {}}
    enemySequence+=1
    data.styleId=enemySequence
    data.aiRng=Random.new(enemySequence*97+stageIndex*1009)
    enemies[model] = data
    model:SetAttribute("EnemyKind", kind)
    model:SetAttribute("Role", spec.Role)
    model:SetAttribute("PercentLimit", data.threshold)
    model:SetAttribute("PoiseLimit", spec.Poise or 0)
    local plate = Instance.new("BillboardGui")
    plate.Name, plate.Size, plate.StudsOffset = "EnemyPlate", UDim2.fromOffset(spec.Role ~= "Grunt" and 210 or 140, 44), Vector3.new(0, spec.Scale + .7, 0)
    plate.AlwaysOnTop, plate.MaxDistance, plate.Parent = false, 140, model.Head
    local title = Instance.new("TextLabel")
    title.Name, title.BackgroundTransparency, title.Size = "Title", 1, UDim2.new(.78, 0, 0, 24)
    title.Font, title.TextSize, title.TextColor3 = Enum.Font.GothamBold, spec.Role ~= "Grunt" and 12 or 10, Color3.fromRGB(237, 231, 249)
    title.TextStrokeTransparency, title.Text, title.TextXAlignment, title.Parent = .5, string.upper(spec.Name), Enum.TextXAlignment.Left, plate
    local percent = title:Clone()
    percent.Name, percent.Position, percent.Size = "Percent", UDim2.fromScale(.78, 0), UDim2.new(.22, 0, 0, 24)
    percent.TextColor3, percent.TextXAlignment, percent.Text, percent.Parent = spec.Color, Enum.TextXAlignment.Right, "0%", plate
    local track = Instance.new("Frame")
    track.Name, track.BackgroundColor3, track.BorderSizePixel = "Track", Color3.fromRGB(22, 20, 32), 0
    track.Position, track.Size, track.Parent = UDim2.fromOffset(0, 24), UDim2.new(1, 0, 0, 4), plate
    local fill = Instance.new("Frame")
    fill.Name, fill.Size, fill.BackgroundColor3, fill.BorderSizePixel, fill.Parent = "Fill", UDim2.fromScale(1, 1), spec.Color, 0, track
    attributes(model, data)
    humanoid(model).WalkSpeed = spec.Speed
    fx("Spawn", position, {enemy = kind, enemyName = spec.Name, role = spec.Role})
    return model
end
function Combat.TryMarkBounty(model,campaignId,stage,wave)
    local data=enemies[model]
    if campaignId~=activeCampaign or stage~=stageIndex or not data or data.kind~="Husk"
        or type(wave)~="number"or wave%1~=0 or wave<1 or wave>4 then return false end
    local key=stage..":"..wave
    if bountyWaves[key]or not Risk.BountySelected(campaignId,stage,wave)then return false end
    bountyWaves[key]=true
    data.bounty={campaignId=campaignId,stage=stage,wave=wave,spawnedAt=now(),minX=arena.MinX+6,maxX=math.min(arena.MaxX-6,walkingMaxX-2)}
    EnemyFactory.MarkBounty(model)
    local title=model.Head:FindFirstChild("EnemyPlate")
    if title then title.Title.Text="GILDED HUSK"end
    fx("BountySpawn",root(model).Position,{targetModel=model})
    return true
end
function Combat.EscapeBounty(model)
    local data=enemies[model]
    if not data or not data.bounty then return false end
    releaseGrab(model,true);AttackDirector.Release(aiDirector,model)
    data.attackSerial+=1;data.attacking=false
    fx("EnemyCancel",root(model)and root(model).Position or Vector3.zero,{targetModel=model,enemy=data.kind})
    fx("BountyEscape",root(model)and root(model).Position or Vector3.zero,{targetModel=model})
    enemies[model]=nil;model:Destroy()
    return true
end
function Combat.SpawnEnemyEntry(kind,entryKind,stageNumber,waveNumber,healthScale,index,rear)
    local stage=Config.Stages[stageNumber]
    local wave=stage.Waves[waveNumber]
    local city=workspace:FindFirstChild("NightfallCity")
    local folder=city and city:FindFirstChild("EnemyEntries")
    local group=folder and folder:FindFirstChild("Stage"..stageNumber.."_Wave"..waveNumber)
    local marker=group and group:FindFirstChild(entryKind)
    local position=marker and marker.Position or Vector3.new(wave.SpawnX,entryKind=="Drop" and 14 or 0,entryKind=="Door" and -12 or 0)
    local low,high=math.huge,-math.huge
    for _,player in ipairs(Combat.GetAlivePlayers())do local pr=root(player.Character);if pr then low=math.min(low,pr.Position.X);high=math.max(high,pr.Position.X)end end
    local stagger=((index or 1)-1)%3*2
    if entryKind=="Left" and low~=math.huge then position=Vector3.new(low-14-stagger,0,position.Z)
    elseif entryKind=="Right" and high~=-math.huge then position=Vector3.new(high+18+stagger,0,position.Z)end
    position=Vector3.new(math.clamp(position.X,stage.MinX+6,math.min(stage.MaxX-6,walkingMaxX-2)),position.Y,math.clamp(position.Z,-12,12))
    local model=Combat.SpawnEnemy(kind,position,healthScale)
    local data=enemies[model]
    data.entryUntil=now()+.6;data.entryKind=entryKind;data.entryDirection=entryKind=="Right" and -1 or 1
    model:SetAttribute("EntryKind",entryKind);model:SetAttribute("EntryUntil",data.entryUntil)
    model:SetAttribute("EntryMarkerFound",marker~=nil)
    model:SetAttribute("RearEntryAchieved",rear==true and low~=math.huge and position.X<low-3)
    local landing=Vector3.new(position.X,0,position.Z)
    fx("EnemyEntry",root(model).Position,{targetModel=model,entry=entryKind,duration=.6,sourcePosition=marker and marker.Position or position,landingPosition=landing})
    return model
end
function Combat.SpawnPhaseAdds(model,data)
    if data.summonsIssued then return end
    data.summonsIssued=true
    local epoch=battleEpoch
    task.defer(function()
        if enemies[model]~=data or epoch~=battleEpoch or encounter.status~="Combat" then return end
        local alive=Combat.GetAlivePlayers()
        if #alive==0 then return end
        for i=1,math.clamp(data.spec.PhaseSummons or 2,0,2)do
            Combat.SpawnEnemyEntry("Husk",i%2==1 and "Left" or "Right",stageIndex,math.max(1,encounter.wave),1+(Combat.GetPlayerCount()-1)*.18,i,#alive<=2 and i%2==1)
        end
    end)
end
function Combat.ClearEnemies()
    if pickups then pickups:Clear()end
    AttackDirector.Reset(aiDirector)
    battleEpoch += 1
    for model in pairs(enemies) do releaseGrab(model,true); model:Destroy() end
    table.clear(enemies)
end
local function attackCount()
    return AttackDirector.CountActive(enemies, now)
end
local function beginEnemyAttack(model,data,target,moveName,alive)
    local r,targetRoot=root(model),root(target.Character)
    if not r or not targetRoot or not enemyVisible(model) then AttackDirector.Release(aiDirector,model);return end
    local t,positions=now(),{}
    for _,player in ipairs(alive)do local pr=root(player.Character);if pr and not records[player].respawning then table.insert(positions,pr.Position)end end
    local direction=data.facing
    local attackOrigin=r.Position
    local move=EnemyMoves.Build(moveName,{origin=attackOrigin,target=targetRoot.Position,direction=direction,arena=arena,partyPositions=positions,spec=data.spec,phase=data.phase})
    move.Windup=DifficultyPolicy.Windup(move.Windup,difficultyProfile())
    local desperate=moveName==data.spec.DesperationMove
    if data.spec.Role~="Grunt" and data.phase==2 and not desperate and t-(data.lastFeintAt or -100)>=6
        and data.aiRng:NextNumber()<(data.spec.FeintChance or .2) then
        data.lastFeintAt=t;data.plannedMove=nil
        data.attacking=true;data.attackSerial+=1
        local serial,epoch=data.attackSerial,battleEpoch
        data.resolveAt=t+.4;data.recoveryUntil=t+.6;data.attackAt=t+.8
        AttackDirector.BeginAttack(aiDirector,model,t,data.recoveryUntil)
        Telemetry.Action(model,data.kind,"Feint",t)
        Telemetry.Windup(data.kind,"Feint",.4,attackCount(),AttackDirector.Cap(#alive,difficultyProfile().TokenBonus))
        humanoid(model):Move(Vector3.zero)
        fx("EnemyFeint",r.Position,{targetModel=model,enemy=data.kind,duration=.4,direction=direction,moveId=moveName})
        task.delay(.4,function()
            if enemies[model]~=data or data.attackSerial~=serial or battleEpoch~=epoch or not root(model) then return end
            fx("EnemyCancel",root(model).Position,{targetModel=model,enemy=data.kind})
            task.delay(.2,function()
                if enemies[model]==data and data.attackSerial==serial and battleEpoch==epoch then data.attacking=false;AttackDirector.Release(aiDirector,model)end
            end)
        end)
        return
    end
    data.plannedMove=nil;data.nextMove=nil;data.lastMove=moveName
    if moveName==(data.spec.PhaseMoves or {})[1] then data.lastSignatureAt=t end
    if desperate then data.desperationUsed=true end
    local tellStyle=move.TellStyle or (data.spec.Role=="Grunt" and "Body" or "Floor")
    data.attacking,data.attackSerial,data.moveIndex=true,data.attackSerial+1,data.moveIndex+1
    local serial,epoch=data.attackSerial,battleEpoch
    data.resolveAt=t+move.Windup+(move.Flight or 0)+(move.FollowUp or 0)+(move.Grab and 1 or 0)
    data.recoveryUntil=data.resolveAt+move.Recovery
    local profile=difficultyProfile()
    local cooldown=data.spec.Role=="Grunt" and math.min(data.spec.Cooldown,profile.Pressure.GruntCooldownMax)or data.spec.Cooldown
    data.attackAt=math.max(t+DifficultyPolicy.Cooldown(cooldown,profile),data.recoveryUntil+.15)
    AttackDirector.BeginAttack(aiDirector,model,t,data.recoveryUntil)
    data.targetHistory[target]=t
    Telemetry.Action(model,data.kind,move.Grab and "Grab" or moveName,t)
    Telemetry.Windup(data.kind,moveName,move.Windup,attackCount(),AttackDirector.Cap(#alive,difficultyProfile().TokenBonus))
    data.armoredUntil=move.Armored and data.resolveAt or 0
    humanoid(model):Move(Vector3.zero)
    r.CFrame=CFrame.lookAt(r.Position,r.Position+Vector3.new(direction,0,0))
    attributes(model,data)
    local function valid()
        return enemies[model]==data and data.attackSerial==serial and battleEpoch==epoch and encounter.status=="Combat" and root(model)~=nil
    end
    local function warn(duration,volumes)
        for _,volume in ipairs(volumes)do
            fx("Telegraph",volume.position,{shape=volume.shape,size=volume.size,radius=volume.radius,height=volume.height,
                jumpable=volume.jumpable,direction=direction,duration=duration,enemy=data.kind,enemyName=data.spec.Name,
                mechanic=move.Name,color=volume.color,heavy=data.spec.Role~="Grunt",targetModel=model,
                tellStyle=tellStyle,pose=move.Pose or "Heavy",moveId=moveName})
        end
    end
    warn(move.Windup+(not move.Projectile and move.Flight or 0),move.Volumes)
    local function impact(volumes,alreadyHit)
        local hit=alreadyHit or {}
        for _,volume in ipairs(volumes)do
            for _,player in ipairs(Combat.GetAlivePlayers())do
                if not valid()then return hit end
                local pr=root(player.Character)
                if pr and not hit[player] and EnemyMoves.Contains(volume,pr.Position)then
                    hit[player]=true
                    local heading=volume.shape=="Box" and direction or (pr.Position.X>=volume.position.X and 1 or -1)
                    local accepted=Combat.ApplyHit(model,player,{Damage=data.spec.Damage*volume.multiplier,Knockback=27,Growth=.40,Lift=volume.jumpable and 24 or 15,Stun=.32,Unblockable=move.Grab==true},heading)
                    if move.Grab and accepted and not data.grabbedPlayer then
                        local victim=records[player]
                        if victim and not victim.downed and not victim.respawning then
                            data.grabbedPlayer=player;victim.grabbedBy=model;victim.blocking=false
                            victim.grabStunUntil=now()+1;victim.stunnedUntil=victim.grabStunUntil
                            pr.AssemblyLinearVelocity=Vector3.zero
                            Telemetry.Action(model,data.kind,"Grab",now())
                            fx("EnemyGrab",pr.Position,{targetModel=model,targetUserId=player.UserId,duration=1,moveId=moveName})
                            local life=victim.lifeSerial
                            task.delay(1,function()
                                if not valid() or records[player]~=victim or victim.lifeSerial~=life or victim.grabbedBy~=model then releaseGrab(model,true);return end
                                releaseGrab(model,false)
                                Telemetry.Action(model,data.kind,"Throw",now())
                                Combat.ApplyHit(model,player,{Damage=data.spec.Damage*.8,Knockback=65,Growth=.5,Lift=24,Stun=.45,Unblockable=true},move.BackThrow and -direction or direction)
                                fx("Attack",root(model).Position,{direction=direction,enemy=data.kind,action="Heavy",targetModel=model,moveId="GrapplerThrow"})
                            end)
                        end
                    end
                end
            end
        end
        return hit
    end
    local function impactVisual()
        for _,volume in ipairs(move.Volumes)do
            fx("EnemyImpact",volume.position,{shape=volume.shape,size=volume.size,radius=volume.radius,height=volume.height,color=volume.color,
                mechanic=move.Name,enemy=data.kind,targetModel=model,tellStyle=tellStyle,moveId=moveName})
        end
    end
    task.delay(move.Windup,function()
        if not valid() then return end
        fx("Attack",root(model).Position,{direction=direction,enemy=data.kind,action=move.Pose or "Heavy",targetModel=model,moveId=moveName})
        if move.Flight then
            local start=move.Projectile and attackOrigin or root(model).Position
            local endpoint=(move.Projectile and move.Endpoint or move.MoveTo)+Vector3.new(0,data.spec.Scale*3,0)
            if move.Projectile then fx("EnemyProjectile",start,{origin=start,endpoint=endpoint,duration=move.Flight,targetModel=model,moveId=moveName}) end
            local began=now();local hit={};local previous=start
            repeat
                if not valid() then return end
                local alpha=math.clamp((now()-began)/move.Flight,0,1)
                local point=start:Lerp(endpoint,alpha)
                if move.Projectile then
                    local midpoint=(previous+point)/2
                    impact({{position=Vector3.new(midpoint.X,0,midpoint.Z),size=Vector3.new(math.abs(point.X-previous.X)+4,12,math.abs(point.Z-previous.Z)+4),height=12,shape="Box",multiplier=1}},hit)
                    previous=point
                else
                    model:PivotTo(CFrame.new(point+Vector3.new(0,math.sin(alpha*math.pi)*(move.Arc or 0),0))*CFrame.Angles(0,-direction*math.pi/2,0))
                    root(model).AssemblyLinearVelocity=Vector3.zero
                end
                if alpha>=1 then break end
                RunService.Heartbeat:Wait()
            until false
        elseif move.MoveTo then
            model:PivotTo(CFrame.new(move.MoveTo+Vector3.new(0,data.spec.Scale*3,0))*CFrame.Angles(0,-direction*math.pi/2,0))
            root(model).AssemblyLinearVelocity=Vector3.zero
        end
        if not valid() then return end
        if moveName=="LeaperVaultKick" then
            local slot=aiDirector.slots[model]
            if slot then slot.offset=Vector3.new(-slot.offset.X,0,slot.offset.Z)end
        end
        if not move.Projectile then impact(move.Volumes)end
        if not valid()then return end -- A perfect block invalidates the whole captured resolver.
        impactVisual()
        if move.FollowUp then
            warn(move.FollowUp,move.Volumes)
            task.wait(move.FollowUp)
            if not valid() then return end
            fx("Attack",root(model).Position,{direction=direction,enemy=data.kind,action="Light",targetModel=model,moveId=moveName})
            impact(move.Volumes)
            if not valid()then return end
            impactVisual()
        end
        if not valid()then return end
        data.armoredUntil=0
        local followup=Archetypes.AfterMove(Archetypes.Id(data.kind,data.spec),moveName)
        local retreat=followup.retreat or move.Retreat
        if retreat then data.retreatUntil=data.recoveryUntil+retreat;data.retreatDistance=followup.distance or 17 end
        data.nextMove=followup.nextMove
        attributes(model,data)
        task.delay(math.max(0,data.recoveryUntil-now()),function()
            if valid() then data.attacking=false;releaseGrab(model,true);AttackDirector.Release(aiDirector,model)end
        end)
    end)
end
local function aiStep(t)
    local positions={}
    for _,player in ipairs(Combat.GetAlivePlayers())do local r=root(player.Character);if r then table.insert(positions,r.Position)end end
    cameraGoal,cameraGoalSpan=CameraBounds.Party(positions,arena.MinX)
    if cameraGoal then
        local alpha=1-math.exp(-6*math.max(0,t-(lastCameraSample or t-.1)))
        cameraEstimate=cameraEstimate and cameraEstimate:Lerp(cameraGoal,alpha) or cameraGoal
        cameraSpan=cameraSpan and cameraSpan+(cameraGoalSpan-cameraSpan)*alpha or cameraGoalSpan
    else cameraEstimate,cameraSpan=nil,nil end
    lastCameraSample=t
    EnemyAI.Step(t, {Combat = Combat, enemies = enemies, records = records, director = aiDirector, difficulty = difficultyProfile(), RecordAction = Telemetry.Action, CanAttack = enemyVisible, VisiblePosition = enemyPositionVisible, SafePosition = enemySafePosition, SummonPhase = Combat.SpawnPhaseAdds,
        root = root, humanoid = humanoid, knockOut = knockOut, CombatMath = CombatMath,
        Config = Config, arena = arena, encounter = encounter, attributes = attributes,
        fx = fx, beginEnemyAttack = beginEnemyAttack, now = now})
end
local function setupCharacter(player, model)
    local data = records[player]
    local h, r = model:WaitForChild("Humanoid", 10), model:WaitForChild("HumanoidRootPart", 10)
    if not data or not h or not r or player.Character ~= model then return end
    h.UseJumpPower, h.JumpPower, h.BreakJointsOnDeath = true, Config.JumpPower, false
    setVisualIdentity(model, data.hero)
    local preserved = data.preserveSpawn
    data.preserveSpawn = nil
    resetPosition(player, preserved and preserved.position or data.spawnPosition or checkpointPosition,data.spawnPercent)
    data.spawnPosition,data.spawnPercent = nil,nil
    if preserved then
        data.percent, data.invulnerableUntil, data.recovered = preserved.percent, preserved.invulnerableUntil, preserved.recovered
        attributes(model, data)
    end
    if data.resumeSurvival then
        data.percent = data.resumeSurvival.percent
        data.stocks = data.resumeSurvival.stocks
        data.downed = data.resumeSurvival.downed
        data.downedUntil,data.downedPosition=data.resumeSurvival.downedUntil,data.resumeSurvival.downedPosition
        data.resumeSurvival = nil
        attributes(model, data)
    end
    if data.stocks <= 0 or data.downed then
        data.downed = true
        r.Anchored = true
        h.WalkSpeed, h.JumpPower = 0, 0
        model:PivotTo(CFrame.new(data.downedPosition or checkpointPosition))
        attributes(model, data)
    end
    h.Died:Connect(function() if player.Character == model and not data.respawning then knockOut(model) end end)
    Combat.BroadcastState()
end
local function addPlayer(player)
    if records[player] or pendingAdmissions[player] then return end
    admissionSequence+=1
    local ticket=admissionSequence
    pendingAdmissions[player]=ticket
    local validator=admissionValidator
    if validator then
        local ok,allowed=pcall(validator,player)
        if not ok or allowed~=true then
            if pendingAdmissions[player]==ticket then pendingAdmissions[player]=nil end
            if player.Parent==Players then player:Kick("This campaign join could not be validated. Return to the hub and try again.")end
            return
        end
    end
    if player.Parent~=Players or pendingAdmissions[player]~=ticket then return end
    local preferred="Gale"
    -- Profile loading may yield too; admission must succeed before consulting it.
    if type(Progression.GetPreferredHero)=="function" then
        local ok,hero=pcall(Progression.GetPreferredHero,player)
        if ok then preferred=Config.NormalizeHeroId(hero)end
    end
    if player.Parent~=Players or pendingAdmissions[player]~=ticket then return end
    pendingAdmissions[player]=nil
    records[player] = {hero = preferred, percent = 0, stocks = Config.Stocks, cooldowns = {}, stunnedUntil = 0,
        launchedUntil = 0, invulnerableUntil = 0, busyUntil = 0, selectAt = 0, facing = 1, combo = 0, lastLight = 0,
        blocking = false, guard = 0, downed = false, recovered = false, rateStart = now(), rateCount = 0,
        hitAt = 0, lifeSerial = 0, contribution = 0, ready = false, runStats = freshStats(), runStart = now()}
    local saved = disconnectedSurvival[player.UserId]
    if saved then
        disconnectedSurvival[player.UserId] = nil
        local data = records[player]
        data.hero, data.stocks, data.percent, data.downed = Config.NormalizeHeroId(saved.hero), saved.stocks, saved.percent, saved.downed
        data.cooldowns, data.runStats, data.runStart, data.runFinished = saved.cooldowns, saved.runStats, saved.runStart, saved.runFinished
        data.styleDistricts=saved.styleDistricts
        data.resumeSurvival = {stocks = saved.stocks, percent = saved.percent, downed = saved.downed,downedUntil=saved.downedUntil,downedPosition=saved.downedPosition}
    end
    if activeCampaign then
        for _,state in pairs(records[player].styleDistricts or {})do
            if state.result and state.result.campaignId==activeCampaign and state.result.stage<=stageIndex then
                Progression.AwardDistrict(player,state.result)
            end
        end
        beginStyleWave(records[player])
    end
    player.CharacterAdded:Connect(function(model) setupCharacter(player, model) end)
    task.spawn(spawnPlayer, player)
end
local function removePlayer(player)
    pendingAdmissions[player]=nil
    local data = records[player]
    if not data then return end
    local count, oldestId, oldestTime = 0, nil, math.huge
    for id, saved in pairs(disconnectedSurvival) do
        count += 1
        if saved.disconnectedAt < oldestTime then oldestId, oldestTime = id, saved.disconnectedAt end
    end
    if count >= MAX_DISCONNECTED_SURVIVORS and oldestId then disconnectedSurvival[oldestId] = nil end
    disconnectedSurvival[player.UserId] = {
        hero = data.hero, stocks = data.stocks, percent = data.respawning and 0 or data.percent,
        downed = data.downed or data.stocks <= 0, downedUntil=data.downedUntil,downedPosition=data.downedPosition,cooldowns = table.clone(data.cooldowns),
        runStats = table.clone(data.runStats), runStart = data.runStart, runFinished = data.runFinished,styleDistricts=data.styleDistricts,
        disconnectedAt = now(),
    }
    records[player] = nil
end
function Combat.ResetLobby()
    if pickups then pickups:Clear();pickups=nil end
    table.clear(bountyWaves)
    activeCampaign=nil
    difficulty="Normal"
    table.clear(disconnectedSurvival)
    Combat.SetArena(Config.Stages[1], 1)
    walkingMaxX = arena.Waves[1].SpawnX + 30
    Combat.SetCheckpoint(Vector3.new(arena.SpawnX, 4, 0), "DISTRICT ENTRANCE")
    Combat.ClearReady()
    encounter.waveTitle, encounter.encounterKind = "ENTER THE CURTAIN", "Wave"
    encounter.targetX, encounter.objective, encounter.resultReason = 0, "CHOOSE A HERO / READY UP", ""
end
function Combat.Init()
    if initialized then return end
    initialized = true
    remotes = ReplicatedStorage.Nightfall.Remotes
    Players.CharacterAutoLoads = false
    remotes.Action.OnServerEvent:Connect(actionReceived)
    Players.PlayerAdded:Connect(addPlayer)
    Players.PlayerRemoving:Connect(removePlayer)
    for _, player in ipairs(Players:GetPlayers()) do addPlayer(player) end
    local aiAccum, stateAccum = 0, 0
    RunService.Heartbeat:Connect(function(dt)
        local t = now()
        stepRevives(t)
        if pickups then pickups:Step(t)end
        for player, data in pairs(records) do
            local model = player.Character
            local r, h = root(model), humanoid(model)
            if not r or not h or data.downed or data.respawning then continue end
            if CombatMath.InBlastZone(r.Position, arena, Config.BlastMargin) then knockOut(model) continue end
            local pos = r.Position
            local x = t > data.launchedUntil and math.clamp(pos.X, arena.MinX + 4, walkingMaxX) or pos.X
            local z = math.clamp(pos.Z, Config.LaneMin, Config.LaneMax)
            if x ~= pos.X or z ~= pos.Z then r.CFrame += Vector3.new(x - pos.X, 0, z - pos.Z) end
            local speed = Config.Characters[data.hero].Speed + modifiers(player).moveSpeedBonus
            h.WalkSpeed = t < data.stunnedUntil and 0 or (data.blocking and 8 or speed)
            h.JumpPower = (data.blocking or t < data.stunnedUntil) and 0 or Config.JumpPower
            if h.FloorMaterial ~= Enum.Material.Air then data.recovered = false end
            data.guard = math.max(0, data.guard - dt * (data.blocking and 3 or 14))
        end
        aiAccum += dt
        stateAccum += dt
        if aiAccum >= .1 then
            aiAccum = 0
            local aiStart = os.clock()
            debug.profilebegin("CurtainBreakEnemyAI")
            aiStep(t)
            debug.profileend()
            if encounter.status == "Combat" and next(enemies) then Telemetry.AICost(os.clock() - aiStart) end
            Telemetry.Sample(enemies, Combat.GetAlivePlayers(), t, encounter.status == "Combat")
        end
        if stateAccum >= .2 then stateAccum = 0 Combat.BroadcastState() end
    end)
end
return Combat
