-- Root-only Studio fixture: proves physical displacement and a resolved two-move sequence.
return function()
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    local C=require(game.ServerScriptService.NightfallServer.CombatService)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    assert(#C.GetAlivePlayers()>=1,"Initialized player required")
    local result={}
    local ok,err=xpcall(function()
        C.ClearEnemies();C.SetArena(Config.Stages[1],1);C.SetWalkingLimit(170);C.ResetPlayers(Vector3.new(90,4,0))
        C.SetEncounterState({status="Combat",wave=1,waves=4})
        local model=C.SpawnEnemy("Husk",Vector3.new(95,0,0),1);local data=C.GetEnemies()[model]
        data.attackAt=workspace:GetServerTimeNow()+30
        local previous=model.HumanoidRootPart.Position;local travel,holdSamples=0,0
        for _=1,25 do
            task.wait(.1)
            local position=model.HumanoidRootPart.Position
            travel+=Vector2.new(position.X-previous.X,position.Z-previous.Z).Magnitude;previous=position
            if data.aiState=="Hold" then holdSamples+=1 end
        end
        assert(holdSamples>=5 and travel>5,"Hold must cause real horizontal travel, not just an intent/counter")
        data.nextMove="HuskJab";data.attackAt=workspace:GetServerTimeNow()
        local deadline=os.clock()+10;local jab=false
        repeat
            task.wait(.05);jab=jab or data.lastMove=="HuskJab"
        until (jab and data.lastMove=="HuskJumpKick") or os.clock()>deadline
        assert(jab and data.lastMove=="HuskJumpKick","Resolved jab/backstep must lead to real jump attack")
        result={physicalHoldTravel=travel,holdSamples=holdSamples,jabThenJump=true}
    end,debug.traceback)
    C.ClearEnemies();C.ResetLobby();C.ResetPlayers(Vector3.new(28,4,0));C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0})
    assert(ok,err);return result
end
