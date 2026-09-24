-- Root-only Studio fixture: actual AI transitions, no live persistence/reward services touched.
return function()
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    assert(#game.Players:GetPlayers()>=1,"Initialized player required")
    local C=require(game.ServerScriptService.NightfallServer.CombatService)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local function await(label,predicate,seconds)
        local deadline=os.clock()+seconds
        repeat if predicate()then return end;task.wait(.03)until os.clock()>deadline
        error("Timed out: "..label)
    end
    local result={}
    local ok,err=xpcall(function()
        C.ClearEnemies();C.SetArena(Config.Stages[1],1);C.SetWalkingLimit(170);C.ResetPlayers(Vector3.new(70,4,0))
        C.SetEncounterState({status="Combat",wave=1,waves=4})
        task.wait(2.1) -- Damage assertions must run after ordinary spawn protection.
        local boss=C.SpawnEnemy("Executioner",Vector3.new(76,0,0),1)
        local data=C.GetEnemies()[boss]
        data.percent=data.threshold*.55;data.attackAt=workspace:GetServerTimeNow()+10
        await("phase2 summons",function()
            local adds=0;for _,d in pairs(C.GetEnemies())do if d.kind=="Husk" then adds+=1 end end
            return data.phase==2 and adds==2
        end,2)
        for _,d in pairs(C.GetEnemies())do if d.kind=="Husk" then
            assert(not d.attacking and d.entryUntil>workspace:GetServerTimeNow(),"side entry grants safe grace")
            assert(d.entryKind=="Left" or d.entryKind=="Right","authored entry kind")
        end end
        C.SpawnPhaseAdds(boss,data);task.wait(.1)
        local count=0;for _ in pairs(C.GetEnemies())do count+=1 end
        assert(count==3,"phase summon is one-shot")
        result.summons=2;result.oneShot=true;result.entryGrace=true
        C.ClearEnemies()
        boss=C.SpawnEnemy("Executioner",Vector3.new(76,0,0),1);data=C.GetEnemies()[boss]
        data.spec=table.clone(data.spec);data.spec.PhaseSummons=0;data.spec.FeintChance=1
        data.percent=data.threshold*.55;data.attackAt=workspace:GetServerTimeNow()+.1
        await("forced harmless phase2 feint",function()return data.lastFeintAt~=nil end,3)
        local victim=game.Players:GetPlayers()[1]
        local before=C.GetSnapshot(victim).runStats.damageTaken
        task.wait(.65)
        assert(C.GetSnapshot(victim).runStats.damageTaken==before,"feint applies no damage")
        result.feintNoDamage=true
        data.percent=data.threshold*.81;data.attackAt=workspace:GetServerTimeNow()
        await("desperation bypasses feint",function()return data.desperationUsed and data.lastMove==data.spec.DesperationMove end,4)
        result.desperationStarted=true
    end,debug.traceback)
    C.ClearEnemies();C.ResetLobby();C.ResetPlayers(Vector3.new(28,4,0));C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0})
    assert(ok,err)
    return result
end
