-- Studio only; scripted accepted hits/traversal isolate checkpoint and reward lifecycle.
if not game:GetService('RunService'):IsStudio()then return end
local T=game:GetService('StudioTestService')local ok,args=pcall(function()return T:GetTestArgs()end)
if not ok or type(args)~='table'or args.test~='CheckpointLifecycle'then return end
local P=game.Players local S=game.ServerScriptService.NightfallServer
local C=require(S.CombatService)local Progression=require(S.ProgressionService)
local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
local qa=Instance.new('RemoteEvent')qa.Name='LobbyLifecycleQA'qa.Parent=game.ReplicatedStorage
local hello={}qa.OnServerEvent:Connect(function(p,kind)if kind=='Hello'then hello[p]=true end end)
local result={passed=false,assertions={},scope='connected-player checkpoint/reward/fresh-run lifecycle; scripted hits/traversal, not human difficulty'}local ended=false
local function finish(err)if ended then return end ended=true result.error=err result.passed=err==nil T:EndTest(result)end
local function await(label,predicate,seconds)
    local deadline=os.clock()+seconds repeat if predicate()then table.insert(result.assertions,label)return end task.wait(.1)until os.clock()>deadline error(label..' timed out')
end
task.delay(300,function()finish('deadline')end)
local worked,err=xpcall(function()
    await('two clients initialized',function()if #P:GetPlayers()~=2 then return false end for _,p in ipairs(P:GetPlayers())do if not hello[p]or not C.GetSnapshot(p)or Progression.GetSnapshot(p).loading then return false end end return true end,45)
    local ps=P:GetPlayers()local a,b=ps[1],ps[2]
    qa:FireClient(a,'Ready',true)qa:FireClient(b,'Ready',true)
    local function driveUntil(label,predicate,seconds)
        local deadline=os.clock()+seconds
        repeat
            local snap=C.GetSnapshot(a)
            if predicate(snap)then table.insert(result.assertions,label)return end
            for enemy in pairs(C.GetEnemies())do
                C.ApplyHit(a,enemy,{Damage=1,Knockback=0,Growth=0,Lift=0,Stun=0},1)
                C.ApplyHit(b,enemy,{Damage=9999,Knockback=0,Growth=0,Lift=0,Stun=0},1)
            end
            if snap.status=='Traverse'or snap.status=='Advance'then
                for _,p in ipairs(ps)do local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart')if r then r.CFrame=CFrame.new(snap.targetX,4,0)end end
            end
            task.wait(.1)
        until os.clock()>deadline error(label..' timed out')
    end
    driveUntil('cleared miniboss and wave3 before boss',function(s)return s.stage==1 and s.wave==4 and s.status=='Combat'end,90)
    local before={Progression.GetSnapshot(a).coins,Progression.GetSnapshot(b).coins}
    local enemy for m,d in pairs(C.GetEnemies())do enemy=m d.stunnedUntil=workspace:GetServerTimeNow()+120 d.attackAt=d.stunnedUntil end
    assert(enemy,'boss exists for registered test damage')
    local deadline=os.clock()+35
    repeat
        for _,p in ipairs(ps)do
            local s=C.GetSnapshot(p)local r=p.Character and p.Character:FindFirstChild('HumanoidRootPart')
            if r and not s.downed then enemy:PivotTo(CFrame.new(r.Position+Vector3.new(3,0,0)))C.ApplyHit(enemy,p,{Damage=9999,Knockback=0,Growth=0,Lift=0,Stun=0,Unblockable=true},1)end
        end
        task.wait(.15)
    until (C.GetSnapshot(a).downed and C.GetSnapshot(b).downed)or os.clock()>deadline
    await('full party wipe produces Defeat',function()return C.GetRunStatus()=='Defeat'end,10)
    qa:FireClient(b,'Restart')
    await('retry restores mid-district checkpoint',function()
        for _,p in ipairs(ps)do local s=C.GetSnapshot(p)if not(s.status=='Intermission'and s.stage==1 and s.wave==2 and s.stocks==(Config.RetryStocks or Config.Stocks)and s.percent==0 and not s.downed)then return false end end return true
    end,10)
    driveUntil('retry resumes wave3 and reaches boss again',function(s)return s.stage==1 and s.wave==4 and s.status=='Combat'end,40)
    assert(Progression.GetSnapshot(a).coins==before[1]and Progression.GetSnapshot(b).coins==before[2],'checkpoint replay paid duplicate encounter rewards')
    table.insert(result.assertions,'same-campaign cleared encounter pays no duplicate coins')
    driveUntil('full campaign reaches Victory',function(s)return s.status=='Victory'end,140)
    local victoryCoins={Progression.GetSnapshot(a).coins,Progression.GetSnapshot(b).coins}
    qa:FireClient(a,'Restart')
    await('fresh campaign resets run state',function()
        for _,p in ipairs(ps)do local s=C.GetSnapshot(p)if not(s.status=='Intermission'and s.stage==1 and s.wave==0 and s.stocks==Config.Stocks and s.percent==0 and not s.downed and s.runStats.damageTaken==0 and s.runStats.coinsEarned==0)then return false end end return true
    end,10)
    driveUntil('fresh campaign clears first encounter',function(s)return s.stage==1 and s.wave==1 and s.status=='Intermission'end,30)
    assert(Progression.GetSnapshot(a).coins>victoryCoins[1]and Progression.GetSnapshot(b).coins>victoryCoins[2],'fresh campaign did not receive new reward keys')
    table.insert(result.assertions,'new campaign legitimately awards same content again')
end,debug.traceback)
if worked then finish()else finish(tostring(err))end
