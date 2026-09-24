-- Root only: ExecuteMultiplayerTestAsync(1,{test="PressureQA"}) with client companion.
if not game:GetService("RunService"):IsStudio()then return end
local Test=game:GetService("StudioTestService")
local okArgs,args=pcall(function()return Test:GetTestArgs()end)
if not okArgs or type(args)~="table"or args.test~="PressureQA"then return end
local qa=Instance.new("RemoteEvent");qa.Name="PressureQA";qa.Parent=game.ReplicatedStorage
local hello,acks={},{}
qa.OnServerEvent:Connect(function(p,kind,id)if kind=="Hello"then hello[p]=true elseif kind=="Ack"then acks[id]=p end end)
local C,result
local function await(label,predicate,seconds)
    local finish=os.clock()+seconds
    repeat if predicate()then return end task.wait(.03)until os.clock()>finish
    error("Timed out: "..label)
end
local ok,err=xpcall(function()
    C=require(game.ServerScriptService:WaitForChild("NightfallServer"):WaitForChild("CombatService"))
    local Players=game:GetService("Players")
    await("initialized client",function()local p=Players:GetPlayers()[1];return p and hello[p]and C.GetSnapshot(p)and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,40)
    local p=Players:GetPlayers()[1]
    task.wait(2) -- CharacterAdded assigns the model before its deferred reset finishes.
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    C.ClearEnemies();C.SetArena(Config.Stages[1],1);C.SetWalkingLimit(170);C.ResetPlayers(Vector3.new(90,4,0))
    C.SetEncounterState({status="Combat",wave=1,waves=4})
    local actor=C.SpawnEnemy("Husk",Vector3.new(95,0,0),1)
    C.GetEnemies()[actor].attackAt=workspace:GetServerTimeNow()+60
    actor.HumanoidRootPart.Anchored=true;p.Character.HumanoidRootPart.Anchored=true
    task.wait(2.2)
    local function hit(damage)
        return C.ApplyHit(actor,p,{Damage=damage or 1,Knockback=0,Growth=0,Lift=0,Stun=2},-1)
    end
    local serial=0
    local function dash()
        serial+=1;qa:FireClient(p,{action="Dash",serial=serial})
        await("real client action ack",function()return acks[serial]==p end,5);task.wait(.1)
    end
    assert(hit());task.wait(.17);assert(hit());task.wait(.17);assert(hit())
    task.wait(.2);assert(not hit(),"Third accepted hit must grant .8 protection")
    task.wait(.65);assert(hit());task.wait(.18)
    local before=C.GetSnapshot(p).percent;dash()
    local burst=C.GetSnapshot(p)
    assert(burst.percent==before+8 and burst.cooldowns.Burst>workspace:GetServerTimeNow()+3,"Burst cost/lock")
    task.wait(1.45);assert(hit());task.wait(.18)
    before=C.GetSnapshot(p).percent;local lockedDeadline=C.GetSnapshot(p).cooldowns.Dash;dash()
    assert(C.GetSnapshot(p).percent==before and C.GetSnapshot(p).cooldowns.Dash==lockedDeadline,"Locked Burst charged or escaped")
    task.wait(2.1);dash()
    assert(C.GetSnapshot(p).percent==before and C.GetSnapshot(p).cooldowns.Dash>workspace:GetServerTimeNow()+1,"Ordinary dash must be accepted and free")
    C.ResetPlayers(Vector3.new(90,4,0));p.Character.HumanoidRootPart.Anchored=true;task.wait(2.2)
    assert(hit());task.wait(.17);assert(hit());task.wait(.17);assert(hit());task.wait(.18)
    local protectedBefore=C.GetSnapshot(p).percent;dash()
    local protectedBurst=C.GetSnapshot(p)
    assert(protectedBurst.percent==protectedBefore+8 and protectedBurst.cooldowns.Dash>workspace:GetServerTimeNow()+1 and protectedBurst.cooldowns.Burst>workspace:GetServerTimeNow()+3,"Protected Burst was not accepted")
    task.wait(.3);assert(not hit(),"Burst shortened active combo-breaker protection")
    task.wait(.4);assert(hit(),"Combo-breaker protection never expired")
    C.ResetPlayers(Vector3.new(90,4,0));p.Character.HumanoidRootPart.Anchored=true;task.wait(2.2)
    local mods=require(game.ServerScriptService.NightfallServer.ProgressionService).GetCombatModifiers(p)
    local taken=(1-(mods.damageReduction or 0))*(mods.damageTakenMultiplier or 1)
    assert(hit(192.05/taken));task.wait(.18);dash()
    assert(C.GetSnapshot(p).stocks==Config.Stocks-1,"Burst self-cost at limit must KO")
    result={passed=true,comboBreaker=true,burstCost=true,burstLock=true,ordinaryDashFree=true,burstPreservesBreaker=true,costKO=true}
end,debug.traceback)
if C then
    C.ClearEnemies();C.ResetLobby();C.ResetPlayers(Vector3.new(28,4,0));C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0})
end
if not ok then result={passed=false,error=tostring(err)}end
print("PRESSURE_QA "..game:GetService("HttpService"):JSONEncode(result));Test:EndTest(result)
