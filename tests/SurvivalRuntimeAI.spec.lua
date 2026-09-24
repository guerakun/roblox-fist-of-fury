-- Root-only two-client lifecycle fixture with SurvivalRuntimeAI.client companion; real remote, no physical input.
return function()
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    local C=require(game.ServerScriptService.NightfallServer.CombatService)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local players=game.Players:GetPlayers();assert(#players>=2,"Two initialized clients required")
    local a,b=players[1],players[2]
    local qa=Instance.new("RemoteEvent");qa.Name="SurvivalQA";qa.Parent=game.ReplicatedStorage
    local hello,acks={},{}
    local connection=qa.OnServerEvent:Connect(function(p,kind,id)if kind=="Hello"then hello[p]=true elseif kind=="Ack"then acks[id]=p end end)
    local function await(label,fn,seconds)
        local finish=os.clock()+seconds
        repeat if fn()then return end task.wait(.03)until os.clock()>finish
        error("Timed out: "..label)
    end
    await("real revive client",function()return hello[b]end,20)
    local serial=0
    local function requestChannel(expected)
        serial+=1;qa:FireClient(b,{held=true,targetUserId=a.UserId,serial=serial})
        await("revive request ack",function()return acks[serial]==b end,5)
        if expected then await("server accepted revive",function()local r=C.GetSnapshot(b).revive;return r and r.channeling end,2)
        else task.wait(.15);local r=C.GetSnapshot(b).revive;assert(not r or not r.channeling,"Expired remote revive accepted")end
    end
    task.wait(2)
    local result
    local ok,err=xpcall(function()
        C.BeginRun("survival-fixture");C.ClearEnemies();C.SetArena(Config.Stages[1],1);C.SetWalkingLimit(170)
        C.SetCheckpoint(Vector3.new(90,4,0),"LIFECYCLE FIXTURE");C.ResetPlayers(Vector3.new(90,4,0));C.SetEncounterState({status="Combat",wave=1,waves=4})
        local enemy=C.SpawnEnemy("Husk",Vector3.new(95,0,0),1)
        C.GetEnemies()[enemy].attackAt=workspace:GetServerTimeNow()+180;enemy.HumanoidRootPart.Anchored=true
        local function anchor(p,x)p.Character:PivotTo(CFrame.new(x,3,0));p.Character.HumanoidRootPart.Anchored=true end
        anchor(a,90);anchor(b,86);task.wait(2.2)
        local function hit(p,damage)return C.ApplyHit(enemy,p,{Damage=damage,Knockback=0,Growth=0,Lift=0,Stun=.32},-1)end
        for i=1,3 do
            local accepted=false;local deadline=os.clock()+6
            repeat accepted=hit(a,300);if not accepted then task.wait(.1)end until accepted or os.clock()>deadline
            assert(accepted,"Registered enemy KO "..i.." failed: "..game:GetService("HttpService"):JSONEncode({snapshot=C.GetSnapshot(a),diagnostics=C.GetAIDiagnostics()}))
            if i<3 then task.wait(3.35);anchor(a,90)end
        end
        assert(C.GetSnapshot(a).stocks==0 and C.GetSnapshot(a).downedRemaining>10)
        requestChannel(true)
        serial+=1;qa:FireClient(b,{held=false,serial=serial,flood=true})
        await("throttled release ack",function()return acks[serial]==b end,5);task.wait(.1)
        assert(not C.GetSnapshot(b).revive or not C.GetSnapshot(b).revive.channeling,"Throttle swallowed release")
        task.wait(1.1);requestChannel(true);task.wait(.3);anchor(b,75);task.wait(.15)
        assert(not C.GetSnapshot(b).revive or not C.GetSnapshot(b).revive.channeling,"Movement failed to cancel revive")
        anchor(b,86);requestChannel(true);assert(hit(b,1));task.wait(.15)
        assert(not C.GetSnapshot(b).revive or not C.GetSnapshot(b).revive.channeling,"Damage failed to cancel revive")
        task.wait(.25);requestChannel(true);task.wait(2.65)
        assert(C.GetSnapshot(a).stocks==1 and C.GetSnapshot(a).percent==60 and not C.GetSnapshot(a).downed,"Channel survival restoration")
        assert(C.GetSnapshot(b).stocks==3,"Channel must not transfer donor stock")
        anchor(a,90);task.wait(2.1);assert(hit(a,300));task.wait(12.1)
        assert(C.GetSnapshot(a).downed and C.GetSnapshot(a).downedRemaining==0,"Expired channel window");requestChannel(false)
        assert(C.CompleteDistrict("survival-fixture",1));local restored=C.GetSnapshot(a)
        assert(restored.stocks==1 and restored.percent==0 and not restored.downed,"District clear earned stock should recover eliminated ally at new-life zero")
        local beforeB=C.GetSnapshot(b)
        assert(not C.CompleteDistrict("survival-fixture",1),"Clear survival benefit duplicated")
        assert(C.GetSnapshot(b).percent==beforeB.percent and C.GetSnapshot(b).stocks==beforeB.stocks)
        C.SetArena(Config.Stages[2],2);C.SetWalkingLimit(260);C.EnterDistrict(Vector3.new(208,4,0))
        assert(C.GetSnapshot(a).stocks==restored.stocks and C.GetSnapshot(a).percent==restored.percent,"Travel erased survival")
        C.RetryCheckpoint(Vector3.new(272,4,0))
        assert(C.GetSnapshot(a).stocks==2 and C.GetSnapshot(a).percent==0 and C.GetSnapshot(b).stocks==2,"Retry must restore two")
        result={passed=true,channel=true,throttledRelease=true,movementCancel=true,hitCancel=true,expiry=true,clearIdempotent=true,travelPersists=true,retryTwo=true,actualReviveRemote=true,physicalInputs=false}
    end,debug.traceback)
    C.ClearEnemies();C.ResetLobby();C.ResetPlayers(Vector3.new(28,4,0));C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0})
    connection:Disconnect();qa:Destroy()
    assert(ok,err);return result
end
