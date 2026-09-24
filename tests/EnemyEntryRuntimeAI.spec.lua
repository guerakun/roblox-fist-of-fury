-- Root-only Studio fixture. Checks server entrance policy, not human play or camera visibility.
return function()
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    local C=require(game.ServerScriptService.NightfallServer.CombatService)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    assert(#C.GetAlivePlayers()>=1,"Initialized player required")
    local result={}
    local ok,err=xpcall(function()
        C.ClearEnemies();C.SetArena(Config.Stages[1],1);C.SetWalkingLimit(170)
        C.ResetPlayers(Vector3.new(70,4,0));C.SetEncounterState({status="Combat",wave=1,waves=4})
        local models={}
        for i,kind in ipairs({"Left","Right","Door","Drop"})do
            local model=C.SpawnEnemyEntry("Husk",kind,1,1,1,i,kind=="Left")
            local data=C.GetEnemies()[model]
            assert(model:GetAttribute("EntryMarkerFound"),"Authored marker missing: "..kind)
            assert(data.entryUntil-workspace:GetServerTimeNow()>.5,"Minimum entry grace")
            if kind=="Left" then assert(model:GetAttribute("RearEntryAchieved"),"Rear entry at mid-arena")end
            models[kind]=model
        end
        local drop=models.Drop;local dropRoot=drop.HumanoidRootPart
        dropRoot.Anchored=true -- Hold airborne longer than grace to isolate grounded guard.
        task.wait(.2)
        for _,model in pairs(models)do
            assert(model:GetAttribute("AIState")=="Enter" and not C.GetEnemies()[model].attacking,"Entry may not attack during grace")
        end
        task.wait(.6)
        assert(drop:GetAttribute("AIState")=="Enter" and not C.GetEnemies()[drop].attacking,"Airborne Drop bypassed grounded guard")
        dropRoot.Anchored=false
        dropRoot:SetNetworkOwner(nil) -- Unanchoring restores automatic ownership; restore production ownership.
        drop.Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
        assert(dropRoot:GetNetworkOwner()==nil,"Drop fixture lost server physics ownership")
        local deadline=os.clock()+3
        repeat task.wait(.05)until drop.Humanoid.FloorMaterial~=Enum.Material.Air or os.clock()>deadline
        assert(drop.Humanoid.FloorMaterial~=Enum.Material.Air,"Drop never landed")
        task.wait(.2)
        assert(drop:GetAttribute("AIState")~="Enter","Grounded Drop never exited Enter")
        result={entryKinds=4,markersFound=true,rearAtMidArena=true,minimumGrace=true,dropGroundedGate=true}
    end,debug.traceback)
    C.ClearEnemies();C.ResetLobby();C.ResetPlayers(Vector3.new(28,4,0));C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0})
    assert(ok,err)
    return result
end
