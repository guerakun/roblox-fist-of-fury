-- TEST ONLY: install temporarily in ServerScriptService, never in the Rojo tree.
-- Install MultiplayerDriver.client.lua in StarterPlayerScripts first, then launch:
-- StudioTestService:ExecuteMultiplayerTestAsync(2,{test="NightfallMultiplayerCampaign",timeout=600})
-- API: https://create.roblox.com/docs/reference/engine/classes/StudioTestService
local RunService = game:GetService("RunService")
if not RunService:IsStudio() or not RunService:IsServer() then return end
local StudioTestService = game:GetService("StudioTestService")
local okArgs, args = pcall(function() return StudioTestService:GetTestArgs() end)
if not okArgs or type(args) ~= "table" or args.test ~= "NightfallMultiplayerCampaign" then return end
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local Config = require(ReplicatedStorage.Nightfall.Shared.Config)
local heroIds = Config.CharacterOrder or {}
if #heroIds == 0 then for id in pairs(Config.Characters) do table.insert(heroIds,id) end table.sort(heroIds) end
local initialCount = math.clamp(math.floor(tonumber(args.initialPlayers) or 2), 2, 4)
local lateCount = math.clamp(math.floor(tonumber(args.latePlayers) or (initialCount==2 and 2 or 0)), 0, 4-initialCount)
local expectedTotal = initialCount + lateCount
local began = os.clock()
local timeout = math.clamp(tonumber(args.timeout) or 600, 60, 600)
local result = {test=args.test,passed=false,assertions={},transitions={},encounters={},clients={},lateJoin={players={}},failures={}}
local done = false
local qa = Instance.new("RemoteEvent")
qa.Name = "NightfallCampaignQA"
qa:SetAttribute("TestName", args.test)
qa.Parent = ReplicatedStorage
local hellos, clientReports, slots, initialPlayers = {}, {}, {}, {}
local Combat
local function snapshot(player)
    return Combat and player and Combat.GetSnapshot(player)
end
local function state()
    for _, player in ipairs(Players:GetPlayers()) do
        local value=snapshot(player)
        if value then return value end
    end
end
local function check(name, passed, detail)
    table.insert(result.assertions,{name=name,passed=passed==true,detail=detail})
    if not passed then table.insert(result.failures,name) end
    print("MULTIPLAYER_QA",passed and "PASS" or "FAIL",name)
    return passed
end
local function finish(reason)
    if done then return end
    done=true
    result.reason=reason
    result.elapsed=os.clock()-began
    result.final=state()
    result.connectedPlayers=#Players:GetPlayers()
    for _, player in ipairs(Players:GetPlayers()) do
        local key=tostring(player.UserId)
        result.clients[key]={name=player.Name,slot=slots[player],server=snapshot(player),driver=clientReports[player]}
    end
    result.passed=reason=="Victory" and #result.failures==0
    qa:FireAllClients({kind="Stop"})
    local encodedOK, encoded=pcall(HttpService.JSONEncode,HttpService,result)
    if encodedOK then print("MULTIPLAYER_CAMPAIGN_RESULT "..encoded) end
    StudioTestService:EndTest(result)
end
qa.OnServerEvent:Connect(function(player,kind,packet)
    if done then return end
    if kind=="Hello" then
        hellos[player]=true
    elseif kind=="Report" and type(packet)=="table" then
        clientReports[player]=packet
    elseif kind=="DriverError" then
        check("client driver runtime",false,player.Name..": "..tostring(packet))
        finish("DriverError")
    end
end)
local function awaitCondition(label,predicate,seconds)
    local deadline=math.min(began+timeout,os.clock()+(seconds or 30))
    while not done and os.clock()<deadline do
        if predicate() then return true end
        task.wait(.1)
    end
    if not done then check(label,false,"Timed out");finish("Timeout: "..label) end
    return false
end
local function command(player,packet)
    if player.Parent==Players then qa:FireClient(player,packet) end
end
local function allReadyForTest(players)
    for _,player in ipairs(players) do
        if not hellos[player] or not snapshot(player) or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return false end
    end
    return true
end
local function countEnemies()
    local count=0
    for _ in pairs(Combat.GetEnemies()) do count+=1 end
    return count
end
-- Independent deadline still ends the test if a later orchestration wait stalls.
task.delay(timeout,function()
    if not done then check("campaign completes within deadline",false,timeout);finish("CampaignTimeout") end
end)
local function run()
    local server=game.ServerScriptService:WaitForChild("NightfallServer",30)
    if not server then error("NightfallServer missing") end
    Combat=require(server:WaitForChild("CombatService",15))
    if not awaitCondition("all initial client drivers",function()
        local players=Players:GetPlayers()
        return #players==initialCount and allReadyForTest(players)
    end,70) then return end
    initialPlayers=Players:GetPlayers()
    table.sort(initialPlayers,function(a,b)return a.UserId<b.UserId end)
    for index,player in ipairs(initialPlayers) do
        slots[player]=index
        command(player,{kind="Setup",slot=index,hero=heroIds[(index-1)%#heroIds+1]})
    end
    if not awaitCondition("different heroes selected",function()
        for index,player in ipairs(initialPlayers) do if snapshot(player).hero~=heroIds[(index-1)%#heroIds+1] then return false end end return true
    end,20) then return end
    check("configured hero selections match assignments",true,initialCount)
    if not check("initial waiting state",state().status=="Waiting",state().status) then finish("Unexpected initial state");return end
    command(initialPlayers[1],{kind="Ready"})
    if not awaitCondition("first ready acknowledged",function()return Combat.GetReadyCount()==1 end,12) then return end
    task.wait(1.25)
    local first=state()
    if not check("one ready keeps multiplayer lobby waiting",first.status=="Waiting" and first.readyCount==1 and first.playersTotal==initialCount and countEnemies()==0,
        {status=first.status,ready=first.readyCount,players=first.playersTotal,enemies=countEnemies()}) then finish("Ready gate failed");return end
    local firstSpawnCount=0
    local spawnConnection=workspace.Enemies.ChildAdded:Connect(function(model)
        if model:IsA("Model") then firstSpawnCount+=1 end
    end)
    if lateCount==0 then qa:FireAllClients({kind="ReleaseLateJoin"}) end
    for index=2,#initialPlayers do command(initialPlayers[index],{kind="Ready"}) end
    if not awaitCondition("all ready starts combat",function()return state().status=="Combat" end,18) then spawnConnection:Disconnect();return end
    task.wait(.35)
    spawnConnection:Disconnect()
    local firstCombat=state()
    local planner=require(game.ServerScriptService.NightfallServer.EnemyWavePlanner)
    local initialPulses=planner.Plan(Config.Stages[1].Waves[1],initialCount)
    local expectedInitial=#initialPulses[1] -- Reinforcements are reserved, not duplicate initial spawns.
    if not check("exactly one initial enemy set",firstCombat.stage==1 and firstCombat.wave==1 and firstSpawnCount==expectedInitial and countEnemies()==expectedInitial,
        {stage=firstCombat.stage,wave=firstCombat.wave,spawned=firstSpawnCount,enemies=countEnemies()}) then finish("Duplicate initial wave");return end
    for _,player in ipairs(initialPlayers) do command(player,{kind="Drive",enabled=true}) end
    local seen, lastTransition, lateStarted, lateComplete = {}, "", false, false
    local lateTaskError
    while not done do
        local current=state()
        if not current then error("All server player records disappeared") end
        local transition=current.stage..":"..current.wave..":"..current.status
        if transition~=lastTransition then
            table.insert(result.transitions,{at=os.clock()-began,state=transition,players=Combat.GetPlayerCount(),enemies=countEnemies()})
            print("MULTIPLAYER_QA transition",transition,Combat.GetPlayerCount())
            lastTransition=transition
        end
        if current.status=="Combat" then
            local key=current.stage..":"..current.wave
            if not seen[key] then
                seen[key]=true
                table.insert(result.encounters,{stage=current.stage,wave=current.wave,kind=current.encounterKind,party=Combat.GetPlayerCount(),enemies=countEnemies()})
            end
        end
        if lateCount>0 and current.status=="Combat" and current.stage==1 and current.wave==2 and not lateStarted then
            lateStarted=true
            -- Every driver independently holds attacks on this encounter until ReleaseLateJoin.
            task.spawn(function()
                local worked,err=xpcall(function()
                    local boss
                    for model in pairs(Combat.GetEnemies()) do if model:GetAttribute("EnemyKind")=="Executioner" then boss=model;break end end
                    if not boss then error("First miniboss was not present") end
                    local before=boss:GetAttribute("PercentLimit")
                    result.lateJoin.before=before
                    result.lateJoin.thresholdHistory={before}
                    local changed=boss:GetAttributeChangedSignal("PercentLimit"):Connect(function()
                        table.insert(result.lateJoin.thresholdHistory,boss:GetAttribute("PercentLimit"))
                    end)
                    StudioTestService:AddPlayers(lateCount)
                    local checkedStocks={}
                    if not awaitCondition("all late clients join and initialize",function()
                        local players=Players:GetPlayers()
                        for _,player in ipairs(players) do
                            if not slots[player] then
                                local snap=snapshot(player)
                                if snap and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and not checkedStocks[player] then
                                    checkedStocks[player]=true
                                    table.insert(result.lateJoin.players,{userId=player.UserId,name=player.Name,stocks=snap.stocks,percent=snap.percent})
                                    check("late client starts with three stocks: "..player.Name,snap.stocks==3,snap.stocks)
                                end
                            end
                        end
                        return #players==expectedTotal and allReadyForTest(players)
                    end,80) then changed:Disconnect();return end
                    local late={}
                    for _,player in ipairs(Players:GetPlayers()) do if not slots[player] then table.insert(late,player) end end
                    table.sort(late,function(a,b)return a.UserId<b.UserId end)
                    for index,player in ipairs(late) do
                        slots[player]=index+initialCount
                        command(player,{kind="Setup",slot=index+initialCount,hero=heroIds[1]})
                        command(player,{kind="Drive",enabled=true})
                    end
                    local after=boss:GetAttribute("PercentLimit")
                    changed:Disconnect()
                    result.lateJoin.after=after
                    result.lateJoin.sameBossPresent=boss.Parent==workspace.Enemies and Combat.GetEnemies()[boss]~=nil
                    local unchanged=type(before)=="number" and before==after and result.lateJoin.sameBossPresent
                    for _,value in ipairs(result.lateJoin.thresholdHistory) do if value~=before then unchanged=false end end
                    check("late joins do not rescale the active miniboss",unchanged,{before=before,after=after,sameBoss=result.lateJoin.sameBossPresent})
                    check("expected actual clients active",Combat.GetPlayerCount()==expectedTotal and #late==lateCount,Combat.GetPlayerCount())
                    lateComplete=true
                    qa:FireAllClients({kind="ReleaseLateJoin"})
                end,debug.traceback)
                if not worked then lateTaskError=tostring(err) end
            end)
        end
        if lateTaskError then error(lateTaskError) end
        if current.status=="Defeat" then check("campaign party survives",false,current.checkpointLabel);finish("Defeat");return end
        if current.status=="Victory" then
            check("all twelve encounters observed",#result.encounters==12,#result.encounters)
            check("late join scenario completed or disabled",lateCount==0 or lateComplete,lateComplete)
            check("expected clients remain at victory",#Players:GetPlayers()==expectedTotal and Combat.GetPlayerCount()==expectedTotal,Combat.GetPlayerCount())
            qa:FireAllClients({kind="ReportNow"})
            awaitCondition("all clients converge to final Victory",function()
                for _,player in ipairs(Players:GetPlayers()) do
                    local report=clientReports[player]
                    if not report or report.status~="Victory" or report.stage~=3 or report.wave~=4 then return false end
                end
                return true
            end,15)
            finish("Victory");return
        end
        task.wait(.1)
    end
end
local worked,err=xpcall(run,debug.traceback)
if not worked and not done then check("server harness runtime",false,tostring(err));finish("HarnessError") end
