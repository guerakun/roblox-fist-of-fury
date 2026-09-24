local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage.Nightfall.Shared.Config)
local Progression = require(script.Parent.ProgressionService)
local Encounter = {}
local combat
local active, initialized = false, false
local checkpointStage, checkpointWave = 1, 1
local generation, campaignNumber = 0, 0
local campaignId = ""
local status = "Waiting"
local function setState(fields)
    if fields.status then status = fields.status end
    combat.SetEncounterState(fields)
end
local function waitCancelable(seconds, token)
    local finish = os.clock() + seconds
    repeat
        task.wait(.1)
        if token ~= generation then return false end
    until os.clock() >= finish
    return true
end
local function enemyCount()
    local count = 0
    for _ in pairs(combat.GetEnemies()) do count += 1 end
    return count
end
local function fx(kind, stage, fields)
    local packet = fields or {}
    packet.kind, packet.position = kind, Vector3.new(stage.CenterX, 4, 0)
    ReplicatedStorage.Nightfall.Remotes.FX:FireAllClients(packet)
end
local function setGate(index, opened)
    local city = workspace:FindFirstChild("NightfallCity")
    local gates = city and city:FindFirstChild("Gates")
    local gate = gates and gates:FindFirstChild("Gate" .. index)
    if gate then
        gate.CanCollide = false -- Server bounds stop walking; launches can still ring out.
        gate.Transparency = opened and 1 or .65
        gate:SetAttribute("Opened", opened)
    end
end
local function checkpointFor(stage, wave)
    return Vector3.new(wave >= 3 and stage.MinX + 92 or stage.SpawnX, 4, 0), wave >= 3 and "MINIBOSS CLEARED / MID-DISTRICT" or "DISTRICT ENTRANCE"
end
local function defeat()
    setState({status = "Defeat", resultReason = "The party exhausted its stocks. Retry from the last checkpoint.", nextWaveAt = 0})
    active = false
end
local function waitForWave(token)
    local emptySince
    while token == generation do
        local count = enemyCount()
        setState({enemiesRemaining = count})
        -- A simultaneous final KO is a clear if at least one stock-bearing player survives.
        local alive = combat.GetAlivePlayers()
        if count == 0 and #alive > 0 then return true end
        if #alive == 0 then
            emptySince = emptySince or os.clock()
            if os.clock() - emptySince >= 3.5 then defeat() return false end
        else emptySince = nil end
        if not waitCancelable(.3, token) then return false end
    end
    return false
end
local function awardClear(stageNumber, waveNumber, kind)
    local participants = combat.GetParticipants()
    local before = {}
    for _, player in ipairs(participants) do before[player] = Progression.GetSnapshot(player).coins or 0 end
    Progression.AwardEncounterClear(participants, stageNumber, kind, campaignId .. ":" .. stageNumber .. ":" .. waveNumber)
    for _, player in ipairs(participants) do
        combat.AddCoinsEarned(player, math.max(0, (Progression.GetSnapshot(player).coins or 0) - before[player]))
    end
end
local function waitForTraverse(stage, wave, token)
    local targetX = math.max(stage.SpawnX, wave.SpawnX - 25)
    setState({status = "Traverse", targetX = targetX, objective = "MOVE RIGHT / RALLY FOR " .. wave.Title, nextWaveAt = 0})
    local emptySince
    while token == generation do
        local alive = combat.GetAlivePlayers()
        local ready = #alive > 0
        for _, player in ipairs(alive) do
            local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not r or r.Position.X < targetX then ready = false break end
        end
        if ready then return true end
        if #alive == 0 then
            emptySince = emptySince or os.clock()
            if os.clock() - emptySince > 3.5 then defeat() return false end
        else emptySince = nil end
        if not waitCancelable(.2, token) then return false end
    end
    return false
end
local function waitForRally(stage, token)
    combat.SetWalkingLimit(stage.MaxX - 4)
    setState({status = "Advance", enemiesRemaining = 0, nextWaveAt = 0, targetX = stage.MaxX - 12, objective = "MOVE RIGHT / RALLY AT DISTRICT EXIT"})
    local emptySince
    while token == generation do
        local alive = combat.GetAlivePlayers()
        local allAtExit = #alive > 0
        for _, player in ipairs(alive) do
            local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if not r or r.Position.X < stage.MaxX - 12 then allAtExit = false break end
        end
        if allAtExit then return waitCancelable(.65, token) end
        if #alive == 0 then
            emptySince = emptySince or os.clock()
            if os.clock() - emptySince > 3.5 then defeat() return false end
        else emptySince = nil end
        if not waitCancelable(.25, token) then return false end
    end
    return false
end
local function run(startStage, startWave, token)
    for stageNumber = startStage, #Config.Stages do
        if token ~= generation then return end
        local stage = Config.Stages[stageNumber]
        local firstWave = stageNumber == startStage and startWave or 1
        checkpointStage, checkpointWave = stageNumber, firstWave
        combat.ClearEnemies()
        combat.SetArena(stage, stageNumber)
        combat.SetWalkingLimit(stage.Waves[firstWave].SpawnX + 30)
        local checkpoint, label = checkpointFor(stage, firstWave)
        combat.SetCheckpoint(checkpoint, label)
        for gateIndex = 1, #Config.Stages do setGate(gateIndex, gateIndex < stageNumber) end
        setState({status = "Intermission", wave = firstWave - 1, waves = #stage.Waves, enemiesRemaining = 0,
            waveTitle = stage.Name, encounterKind = "Wave", targetX = 0, objective = "PREPARE / NEXT ENCOUNTER", nextWaveAt = workspace:GetServerTimeNow() + 4, resultReason = ""})
        combat.ResetPlayers(checkpoint)
        fx("StageIntro", stage, {stage = stageNumber, title = stage.Name, subtitle = firstWave > 1 and "CHECKPOINT RESTORED" or "STAY TOGETHER. BREAK THE CURTAIN."})
        if not waitCancelable(4, token) then return end
        for waveNumber = firstWave, #stage.Waves do
            if token ~= generation then return end
            local wave = stage.Waves[waveNumber]
            combat.SetWalkingLimit(wave.SpawnX + 30)
            combat.BeginEncounter()
            -- Scale once per wave. Late joiners never heal an in-progress boss.
            local partySize = math.clamp(combat.GetPlayerCount(), 1, Config.MaxPlayers)
            local healthScale = 1 + (partySize - 1) * (wave.Kind == "Wave" and .18 or .28)
            local kinds = {}
            for kind in pairs(wave.Enemies) do table.insert(kinds, kind) end
            table.sort(kinds)
            local spawnIndex = 0
            for _, kind in ipairs(kinds) do
                local baseCount = wave.Enemies[kind]
                local total = baseCount + (wave.Kind == "Wave" and math.floor((partySize - 1) * .5) or 0)
                for _ = 1, total do
                    spawnIndex += 1
                    local x = wave.SpawnX + (wave.Kind == "Wave" and (spawnIndex % 3) * 5 or 0)
                    local z = wave.Kind == "Wave" and ((spawnIndex % 3) - 1) * 7 or 0
                    combat.SpawnEnemy(kind, Vector3.new(x, 0, z), healthScale)
                end
            end
            setState({status = "Combat", wave = waveNumber, waveTitle = wave.Title, encounterKind = wave.Kind,
                enemiesRemaining = enemyCount(), nextWaveAt = 0, targetX = wave.SpawnX, objective = "CLEAR / " .. wave.Title})
            fx("Wave", stage, {title = wave.Title, role = wave.Kind})
            if not waitForWave(token) then return end
            awardClear(stageNumber, waveNumber, wave.Kind)
            if wave.Kind == "Miniboss" then
                checkpointStage, checkpointWave = stageNumber, waveNumber + 1
                local midPosition, midLabel = checkpointFor(stage, waveNumber + 1)
                combat.SetCheckpoint(midPosition, midLabel)
                fx("Checkpoint", stage, {title = "MID-DISTRICT CHECKPOINT", subtitle = "Your next stock returns here."})
            end
            if waveNumber < #stage.Waves then
                local pause = wave.Kind == "Miniboss" and 5 or 4
                setState({status = "Intermission", enemiesRemaining = 0, nextWaveAt = workspace:GetServerTimeNow() + pause})
                if not waitCancelable(pause, token) then return end
                if not waitForTraverse(stage, stage.Waves[waveNumber + 1], token) then return end
            end
        end
        setGate(stageNumber, true)
        fx("StageClear", stage, {title = stage.Name})
        if stageNumber < #Config.Stages then
            if not waitForRally(stage, token) then return end
        end
    end
    setState({status = "Victory", enemiesRemaining = 0, nextWaveAt = 0, resultReason = "All three districts and six elite curses defeated."})
    fx("Victory", Config.Stages[#Config.Stages], {title = "THE CURTAIN IS BROKEN"})
    checkpointStage, checkpointWave, active = 1, 1, false
end
function Encounter.Restart()
    if active or not combat or combat.GetPlayerCount() == 0 then return end
    if campaignId == "" or status == "Victory" or status == "Waiting" then
        campaignNumber += 1
        campaignId = (game.JobId ~= "" and game.JobId or HttpService:GenerateGUID(false)) .. ":" .. campaignNumber
        checkpointStage, checkpointWave = 1, 1
        combat.BeginRun()
    end
    generation += 1
    active = true
    local token = generation
    task.spawn(run, checkpointStage, checkpointWave, token)
end
function Encounter.Init(combatService)
    if initialized then return end
    initialized, combat = true, combatService
    combat.SetRestartCallback(Encounter.Restart)
    local function evaluateReady()
        if status == "Waiting" and not active and combat.GetPlayerCount() > 0 and combat.GetReadyCount() == combat.GetPlayerCount() then Encounter.Restart() end
    end
    combat.SetReadyCallback(evaluateReady)
    Players.PlayerRemoving:Connect(function()
        task.defer(function()
            if #Players:GetPlayers() == 0 then
                generation += 1
                active, campaignId = false, ""
                combat.ResetLobby()
                for gateIndex = 1, #Config.Stages do setGate(gateIndex, false) end
                checkpointStage, checkpointWave = 1, 1
                combat.ClearEnemies()
                setState({status = "Waiting", wave = 0, enemiesRemaining = 0, nextWaveAt = 0})
            else evaluateReady() end
        end)
    end)

end
return Encounter
