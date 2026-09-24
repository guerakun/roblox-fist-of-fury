-- Root-only scripted Studio fixture. Requires two actual connected clients without QA drivers.
-- Temporarily resets the practice campaign; never install in a shipped place or HumanBot run.
return function()
    local RunService=game:GetService("RunService")
    assert(RunService:IsStudio(),"Studio only")
    local players=game.Players:GetPlayers()
    assert(#players>=2,"Two actual clients are required for ally rescue evidence")
    table.sort(players,function(a,b)return a.UserId<b.UserId end)
    local victim,ally=players[1],players[2]
    local C=require(game.ServerScriptService.NightfallServer.CombatService)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local function await(label,predicate,timeout)
        local deadline=os.clock()+timeout
        repeat if predicate()then return end;task.wait(.03)until os.clock()>deadline
        error("Timed out: "..label)
    end
    local function prepare()
        C.ClearEnemies();C.SetArena(Config.Stages[1],1);C.SetWalkingLimit(170)
        C.ResetPlayers(Vector3.new(70,4,0));C.BeginRun()
        C.SetEncounterState({status="Combat",wave=1,waves=4})
        for i,p in ipairs(players)do
            local r=p.Character and p.Character:FindFirstChild("HumanoidRootPart")
            assert(r,"Initialized player rig required")
            r.CFrame=CFrame.new(70+(i-1)*15,3,0);r.AssemblyLinearVelocity=Vector3.zero
        end
        task.wait(2.1) -- Allow the legitimate spawn protection to expire.
        local enemy=C.SpawnEnemy("Grappler",Vector3.new(75,0,0),1)
        C.GetEnemies()[enemy].attackAt=workspace:GetServerTimeNow()+.1
        return enemy
    end
    local result={}
    local ok,err=xpcall(function()
        local enemy=prepare()
        await("victim captured",function()return C.GetSnapshot(victim).grabbed end,5)
        local before=C.GetSnapshot(victim).runStats.damageTaken
        assert(C.ApplyHit(ally,enemy,{Damage=1,Knockback=0,Growth=0,Lift=0,Stun=.05},1),"ally's real server hit accepted")
        assert(not C.GetSnapshot(victim).grabbed,"ally hit immediately frees victim")
        task.wait(1.15)
        assert(C.GetSnapshot(victim).runStats.damageTaken==before,"rescued capture cannot deliver delayed throw")
        result.allyRescue=true;result.cancelledThrow=true
        enemy=prepare()
        await("unrescued capture",function()return C.GetSnapshot(victim).grabbed end,5)
        local held=C.GetSnapshot(victim).runStats.damageTaken
        await("unrescued throw resolves",function()return not C.GetSnapshot(victim).grabbed end,2)
        assert(C.GetSnapshot(victim).runStats.damageTaken>held,"unrescued throw applies authoritative damage")
        result.timedThrow=true
    end,debug.traceback)
    C.ClearEnemies();C.ResetLobby();C.ResetPlayers(Vector3.new(28,4,0))
    C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0})
    assert(ok,err)
    return result
end
