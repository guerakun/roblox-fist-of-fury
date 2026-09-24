-- Studio-only 12-enemy/four-client instrumentation scenario. Not a human difficulty run.
if not game:GetService('RunService'):IsStudio()then return end
local T=game:GetService('StudioTestService')local ok,args=pcall(function()return T:GetTestArgs()end)
if not ok or type(args)~='table'or args.test~='ProfilerHarness'then return end
local S=game.ServerScriptService.NightfallServer local C=require(S.CombatService)
local Telemetry=require(S.CombatTelemetry)local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
workspace:SetAttribute('PerfReady',false)
local deadline=os.clock()+60
repeat task.wait(.1)until #C.GetAlivePlayers()==4 or os.clock()>deadline
if #C.GetAlivePlayers()~=4 then T:EndTest({passed=false,error='four clients did not initialize'})return end
-- GetAlivePlayers can precede the deferred CharacterAdded setup reset.
-- Settle that callback, then prove the placement survives a subsequent interval.
task.wait(2)
C.ClearEnemies()C.SetArena(Config.Stages[1],1)C.SetWalkingLimit(170)C.ResetPlayers(Vector3.new(90,4,0))
local initialCharacters={}
for i,p in ipairs(game.Players:GetPlayers())do initialCharacters[p]=p.Character p.Character:PivotTo(CFrame.new(90,4,(i-2.5)*5))end
task.wait(1)
if #C.GetAlivePlayers()~=4 then T:EndTest({passed=false,orchestrationPassed=false,error='party changed during placement'})return end
for p,character in pairs(initialCharacters)do
    local root=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
    if p.Character~=character or not root or math.abs(root.Position.X-90)>2 then
        T:EndTest({passed=false,orchestrationPassed=false,error='initial character placement did not settle before capture'})return
    end
end
C.SetEncounterState({status='Combat',wave=1,waves=4})Telemetry.Reset()Telemetry.BeginEncounter(1,1)
for i,kind in ipairs({'Husk','Strider','Grappler','Pitcher','Warden','Leaper'})do
    for side=-1,1,2 do C.SpawnEnemy(kind,Vector3.new(90+side*(10+i),0,(i%3-1)*7),1)end
end
-- Population validity is latched across every observed Heartbeat after the root's
-- absolute-frame barrier. A later respawn cannot erase an earlier mismatch.
local began=os.clock()local samples={}local diagnostics={}local diagnosticTimes={10,30,60}
local diagnosticIndex=1 local aliases={}local aliasCount=0
local function alias(id)
    if id==nil then return nil end
    local key=tostring(id)
    if not aliases[key]then aliasCount+=1 aliases[key]='Player'..aliasCount end
    return aliases[key]
end
for _,p in ipairs(game.Players:GetPlayers())do alias(p.UserId)end
local function population()
    local count=0 for _ in pairs(C.GetEnemies())do count+=1 end
    return {elapsed=os.clock()-began,alive=#C.GetAlivePlayers(),enemies=count}
end
workspace:SetAttribute('PerfFirstAbsoluteFrame',nil)
workspace:SetAttribute('PerfFinish',nil)
workspace:SetAttribute('PerfPopulationChecks',0)
workspace:SetAttribute('PerfPopulationMismatchCount',0)
workspace:SetAttribute('PerfPopulationValid',false)
workspace:SetAttribute('PerfPopulationFirstMismatch',nil)
workspace:SetAttribute('PerfPopulationBarrier',nil)
local checks,mismatches,barrier=0,0,nil
local function checkPopulation()
    local requested=workspace:GetAttribute('PerfFirstAbsoluteFrame')
    if requested==nil and barrier==nil then return end
    if barrier==nil then barrier=requested workspace:SetAttribute('PerfPopulationBarrier',barrier)end
    local sample=population()checks+=1
    if sample.alive~=4 or sample.enemies~=12 or requested~=barrier then
        mismatches+=1
        if mismatches==1 then
            sample.reason=requested==nil and 'capture barrier removed' or (requested~=barrier and 'capture barrier changed' or 'population mismatch')
            workspace:SetAttribute('PerfPopulationFirstMismatch',game.HttpService:JSONEncode(sample))
        end
    end
    workspace:SetAttribute('PerfPopulationChecks',checks)
    workspace:SetAttribute('PerfPopulationMismatchCount',mismatches)
    workspace:SetAttribute('PerfPopulationValid',mismatches==0)
end
local heartbeat=game:GetService('RunService').Heartbeat:Connect(checkPopulation)
local barrierChanged=workspace:GetAttributeChangedSignal('PerfFirstAbsoluteFrame'):Connect(checkPopulation)
workspace:SetAttribute('PerfReady',true)
repeat
    table.insert(samples,population())
    if diagnosticIndex<=#diagnosticTimes and os.clock()-began>=diagnosticTimes[diagnosticIndex]then
        local diagnostic=C.GetAIDiagnostics and C.GetAIDiagnostics()
        if diagnostic then
            diagnostic.elapsed=os.clock()-began
            diagnostic.requestedElapsed=diagnosticTimes[diagnosticIndex]
            for _,p in ipairs(diagnostic.players or {})do p.id=alias(p.id)end
            for _,actor in ipairs(diagnostic.actors or {})do actor.targetId=alias(actor.targetId)end
            table.insert(diagnostics,diagnostic)
        end
        diagnosticIndex+=1
    end
    workspace:SetAttribute('PerfPopulation',game.HttpService:JSONEncode(samples[#samples]))
    task.wait(.5)
until workspace:GetAttribute('PerfFinish')or os.clock()-began>100
checkPopulation()heartbeat:Disconnect()barrierChanged:Disconnect()
local finished=workspace:GetAttribute('PerfFinish')==true
local result={passed=finished,orchestrationPassed=finished,passMeaning='Harness finished on request only; CPU target is reported separately by MicroProfilerCapture',
    populationValidity={firstAbsoluteFrame=barrier,checks=checks,mismatches=mismatches,valid=checks>0 and mismatches==0,
        firstMismatch=workspace:GetAttribute('PerfPopulationFirstMismatch'),method='Heartbeat plus barrier-change observations; mismatch latched'},
    populations=samples,diagnostics=diagnostics,telemetry=Telemetry.Summary(),scope='stationary four-client/12-enemy Studio CPU instrumentation; not phone FPS or HumanBot difficulty'}
C.ClearEnemies()C.SetEncounterState({status='Waiting'})T:EndTest(result)
