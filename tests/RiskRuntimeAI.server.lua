-- Root-only one actual Studio client. Real intent remotes; timed accepted hits are server fixtures.
if not game:GetService("RunService"):IsStudio()then return end
local Test=game:GetService("StudioTestService")
local okArgs,args=pcall(function()return Test:GetTestArgs()end)
if not okArgs or type(args)~="table"or args.test~="RiskQA"then return end
local qa=Instance.new("RemoteEvent");qa.Name="RiskQA";qa.Parent=game.ReplicatedStorage
local hello,acks={},{}
qa.OnServerEvent:Connect(function(p,kind,id)if kind=="Hello"then hello[p]=true elseif kind=="Ack"then acks[id]=p end end)
local C,result
local function await(label,predicate,seconds)
    local finish=os.clock()+seconds
    repeat if predicate()then return end task.wait(.01)until os.clock()>finish
    error("Timed out: "..label)
end
local ok,err=xpcall(function()
    C=require(game.ServerScriptService:WaitForChild("NightfallServer"):WaitForChild("CombatService"))
    local P=require(game.ServerScriptService.NightfallServer.ProgressionService)
    local Risk=require(game.ServerScriptService.NightfallServer.RiskPolicy)
    local Players=game:GetService("Players")
    await("initialized client",function()local p=Players:GetPlayers()[1];return p and hello[p]and C.GetSnapshot(p)and p.Character and p.Character:FindFirstChild("HumanoidRootPart")end,40)
    local p=Players:GetPlayers()[1];task.wait(2)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local campaign="campaign-2" -- Golden deterministic selected stage1/wave1.
    C.BeginRun(campaign);P.BeginCampaign({p},campaign);C.ClearEnemies()
    C.SetArena(Config.Stages[1],1);C.SetWalkingLimit(170);C.SetCheckpoint(Vector3.new(90,4,0),"RISK FIXTURE")
    C.ResetPlayers(Vector3.new(90,4,0));p.Character.HumanoidRootPart.Anchored=true
    C.SetEncounterState({status="Combat",wave=1,waves=4,encounterKind="Wave",partySize=1})
    local function enemy(x)
        local model=C.SpawnEnemy("Husk",Vector3.new(x,0,0),1)
        local data=C.GetEnemies()[model];data.threshold=99999;data.attackAt=workspace:GetServerTimeNow()+120
        model.HumanoidRootPart.Anchored=true
        return model,data
    end
    local actor,npc=enemy(95)
    local serial=0
    local function request(action,payload)
        serial+=1;qa:FireClient(p,{action=action,payload=payload or {direction=1},serial=serial})
        await("real client action ack",function()return acks[serial]==p end,5)
        -- The production Action remote is sent before this distinct QA acknowledgement.
        task.wait(.015)
    end
    task.wait(2.2)
    local initial=C.GetSnapshot(p)
    request("Desperation");assert(C.GetSnapshot(p).percent==initial.percent and C.GetSnapshot(p).cooldowns.Special==initial.cooldowns.Special,"Ready special cannot be bypassed")
    request("Special")
    await("ordinary special becomes risk eligible",function()return C.GetSnapshot(p).canDesperation end,3)
    local before=C.GetSnapshot(p)
    request("Desperation")
    local paid=C.GetSnapshot(p)
    assert(paid.percent==before.percent+12 and paid.desperationCooldown>3.5,"Desperation cost/cooldown")
    task.wait(.7);request("Desperation")
    assert(C.GetSnapshot(p).percent==paid.percent,"Repeated desperation charged while locked")
    C.ResetPlayers(Vector3.new(90,4,0));p.Character.HumanoidRootPart.Anchored=true;task.wait(2.2)
    local hit={Damage=10,Knockback=0,Growth=0,Lift=0,Stun=0}
    request("Block",{held=true,direction=1})
    before=C.GetSnapshot(p);local oldSerial=npc.attackSerial
    assert(not C.ApplyHit(actor,p,hit,-1),"Perfect block accepted chip")
    local parry=C.GetSnapshot(p)
    assert(parry.percent==before.percent and parry.style.multiplier==math.min(4,before.style.multiplier+1),"Perfect reward/no chip")
    assert(npc.attackSerial==oldSerial+1 and npc.stunnedUntil>workspace:GetServerTimeNow()+.4,"Perfect stagger/cancel")
    assert(C.ApplyHit(actor,p,hit,-1),"Same hold incorrectly parried twice")
    assert(C.GetSnapshot(p).percent>parry.percent,"Consumed parry must allow chip")
    task.wait(.17);request("Block",{held=false});request("Block",{held=true,direction=1})
    before=C.GetSnapshot(p)
    assert(C.ApplyHit(actor,p,hit,-1)and C.GetSnapshot(p).percent>before.percent,"Rapid toggle bypassed perfect rearm")
    task.wait(.4);request("Block",{held=false});request("Block",{held=true,direction=1});task.wait(.15)
    before=C.GetSnapshot(p);request("Block",{held=true,direction=1})
    assert(C.ApplyHit(actor,p,hit,-1)and C.GetSnapshot(p).percent>before.percent,"Repeated held request refreshed window")
    request("Block",{held=false})
    -- New deterministic bounty; actual contributor hit + KO pays once, escape pays nothing.
    local bounty,bd=enemy(98);assert(C.TryMarkBounty(bounty,campaign,1,1))
    local balance=P.GetSnapshot(p).coins
    bd.threshold=1
    assert(C.ApplyHit(p,bounty,{Damage=2,Knockback=0,Growth=0,Lift=0,Stun=0},1))
    assert(P.GetSnapshot(p).coins==balance+25,"Bounty contributor payout")
    local retry=enemy(98);assert(not C.TryMarkBounty(retry,campaign,1,1),"Retry rerolled bounty")
    assert(P.GetSnapshot(p).coins==balance+25)
    local coins=P.GetSnapshot(p).coins
    local escapeCampaign
    for i=1,100 do
        local candidate="escape-runtime:"..i
        if Risk.BountySelected(candidate,1,1)then escapeCampaign=candidate;break end
    end
    assert(escapeCampaign)
    C.BeginRun(escapeCampaign);P.BeginCampaign({p},escapeCampaign)
    local flee,fd=enemy(100);assert(C.TryMarkBounty(flee,escapeCampaign,1,1))
    assert(fd.bounty.maxX<=C.GetSnapshot(p).walkingMaxX-2,"Bounty escape goal leaves playable region")
    fd.bounty.spawnedAt=workspace:GetServerTimeNow()-8.1
    task.wait(.25);assert(flee:GetAttribute("AIState")=="Flee","Bounty never entered flee state")
    fd.bounty.spawnedAt=workspace:GetServerTimeNow()-14.1
    await("anti-stuck escape",function()return C.GetEnemies()[flee]==nil end,2)
    assert(P.GetSnapshot(p).coins==coins,"Escaped bounty paid coins")
    -- Cost itself can exhaust a stock, before a new special resolver is scheduled.
    C.ResetPlayers(Vector3.new(90,4,0));p.Character.HumanoidRootPart.Anchored=true;task.wait(2.2)
    request("Special");await("self KO eligible",function()return C.GetSnapshot(p).canDesperation end,3)
    local mods=P.GetCombatModifiers(p);local taken=(1-(mods.damageReduction or 0))*(mods.damageTakenMultiplier or 1)
    assert(C.ApplyHit(actor,p,{Damage=188.05/taken,Knockback=0,Growth=0,Lift=0,Stun=0},-1))
    local stocks=C.GetSnapshot(p).stocks;request("Desperation")
    assert(C.GetSnapshot(p).stocks==stocks-1,"Desperation self-cost KO")
    result={passed=true,realIntentRemotes=true,desperationCostLock=true,readyBypassRejected=true,perfectBlock=true,
        heldWindowNotRefreshed=true,rapidToggleOrdinaryBlock=true,bountyPaidOnce=true,bountyEscapeNoReward=true,costKO=true,physicalPickupVerified=false}
end,debug.traceback)
if C then C.ClearEnemies();C.ResetLobby();C.ResetPlayers(Vector3.new(28,4,0));C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0})end
if not ok then result={passed=false,error=tostring(err)}end
print("RISK_QA "..game:GetService("HttpService"):JSONEncode(result));Test:EndTest(result)
