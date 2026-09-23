local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage.Nightfall.Shared.Config)
local Encounter = {}
local combat
local active = false
local checkpoint = 1
local generation = 0
local function waitCancelable(seconds, token)
    local finish = os.clock() + seconds
    repeat
        task.wait(0.15)
        if token ~= generation then return false end
    until os.clock() >= finish
    return true
end
local function enemyCount()
    local count = 0
    for _ in pairs(combat.GetEnemies()) do count += 1 end
    return count
end
local function fx(kind, stage)
    ReplicatedStorage.Nightfall.Remotes.FX:FireAllClients({kind = kind, position = Vector3.new(stage.CenterX, 4, 0)})
end
local function setGate(index, opened)
    local city = workspace:FindFirstChild("NightfallCity")
    local gates = city and city:FindFirstChild("Gates")
    local gate = gates and gates:FindFirstChild("Gate" .. index)
    if gate then
        -- Server bounds lock walking; non-solid curtains preserve knockback ringouts.
        gate.CanCollide = false
        gate.Transparency = opened and 1 or 0.65
        gate:SetAttribute("Opened", opened)
    end
end
local function run(startStage, token)
    active = true
    for stageNumber = startStage, #Config.Stages do
        if token ~= generation then return end
        local stage = Config.Stages[stageNumber]
        checkpoint = stageNumber
        for gateIndex = 1, #Config.Stages do setGate(gateIndex, gateIndex < stageNumber) end
        combat.ClearEnemies()
        combat.SetArena(stage, stageNumber)
        combat.SetEncounterState({status = "Intermission", wave = 0, waves = #stage.Waves, enemiesRemaining = 0})
        combat.ResetPlayers(Vector3.new(stage.SpawnX, 4, 0))
        if not waitCancelable(2.5, token) then return end
        for waveNumber, wave in ipairs(stage.Waves) do
            if token ~= generation then return end
            combat.SetEncounterState({status = "Combat", wave = waveNumber})
            fx("Wave", stage)
            local partySize = math.clamp(combat.GetPlayerCount(), 1, Config.MaxPlayers)
            local healthScale = 1 + (partySize - 1) * 0.3
            local spawnIndex = 0
            for _, kind in ipairs({"Grunt", "Runner", "Brute", "Boss"}) do
                local baseCount = wave[kind] or 0
                local total = baseCount > 0 and (baseCount + (kind ~= "Boss" and math.floor((partySize - 1) * 0.5) or 0)) or 0
                for _ = 1, total do
                    spawnIndex += 1
                    local x = stage.CenterX + 24 + (spawnIndex % 3) * 10
                    local z = ((spawnIndex % 5) - 2) * 5
                    combat.SpawnEnemy(kind, Vector3.new(x, 0, z), healthScale)
                end
            end
            combat.SetEncounterState({enemiesRemaining = enemyCount()})
            local emptySince
            while token == generation do
                local count = enemyCount()
                combat.SetEncounterState({enemiesRemaining = count})
                if count == 0 then break end
                if #combat.GetAlivePlayers() == 0 then
                    emptySince = emptySince or os.clock()
                    -- Grace covers stock respawns and avatars joining.
                    if os.clock() - emptySince >= 3.5 then
                        combat.SetEncounterState({status = "Defeat"})
                        active = false
                        return
                    end
                else emptySince = nil end
                if not waitCancelable(0.4, token) then return end
            end
            if token ~= generation then return end
            if waveNumber < #stage.Waves then
                combat.SetEncounterState({status = "Intermission", enemiesRemaining = 0})
                if not waitCancelable(2, token) then return end
            end
        end
        setGate(stageNumber, true)
        fx("StageClear", stage)
        if stageNumber < #Config.Stages then
            combat.SetEncounterState({status = "Advance", enemiesRemaining = 0})
            local emptySince
            while token == generation do
                local alive = combat.GetAlivePlayers()
                local allAtExit = #alive > 0
                for _, player in ipairs(alive) do
                    local r = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    if not r or r.Position.X < stage.MaxX - 12 then allAtExit = false break end
                end
                if allAtExit then break end
                if #alive == 0 then
                    emptySince = emptySince or os.clock()
                    if os.clock() - emptySince > 3.5 then
                        combat.SetEncounterState({status = "Defeat"})
                        active = false
                        return
                    end
                else emptySince = nil end
                if not waitCancelable(0.3, token) then return end
            end
            if token ~= generation then return end
            if not waitCancelable(0.7, token) then return end
        end
    end
    combat.SetEncounterState({status = "Victory", enemiesRemaining = 0})
    fx("Victory", Config.Stages[#Config.Stages])
    checkpoint = 1
    active = false
end
function Encounter.Restart()
    if active or combat.GetPlayerCount() == 0 then return end
    generation += 1
    local token = generation
    active = true
    task.spawn(run, checkpoint, token)
end
function Encounter.Init(combatService)
    combat = combatService
    combat.SetRestartCallback(Encounter.Restart)
    task.spawn(function()
        while combat.GetPlayerCount() == 0 do task.wait(0.25) end
        task.wait(3)
        Encounter.Restart()
    end)
    Players.PlayerRemoving:Connect(function()
        task.defer(function()
            if #Players:GetPlayers() == 0 then
                generation += 1
                active = false
                checkpoint = 1
                combat.ClearEnemies()
                combat.SetEncounterState({status = "Waiting", wave = 0, enemiesRemaining = 0})
            end
        end)
    end)
    Players.PlayerAdded:Connect(function()
        if not active then task.delay(3, function() if not active then Encounter.Restart() end end) end
    end)
end
return Encounter
