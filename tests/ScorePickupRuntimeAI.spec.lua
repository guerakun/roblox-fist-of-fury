-- Root-only actual physics contact. Scripted MoveTo is not human input/device verification.
return function()
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    local C=require(game.ServerScriptService.NightfallServer.CombatService)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local p=game.Players:GetPlayers()[1];assert(p and C.GetSnapshot(p),"Initialized client required")
    local result
    local ok,err=xpcall(function()
        task.wait(2)
        C.BeginRun("score-contact:"..game:GetService("HttpService"):GenerateGUID(false));C.ClearEnemies()
        C.SetArena(Config.Stages[1],1);C.SetWalkingLimit(170);C.SetCheckpoint(Vector3.new(90,4,0),"ORB FIXTURE")
        C.ResetPlayers(Vector3.new(90,4,0));C.SetEncounterState({status="Combat",wave=1,encounterKind="Wave",partySize=1})
        local root=p.Character.HumanoidRootPart;root.Anchored=true
        local function spawn(x)
            local model=C.SpawnEnemy("Husk",Vector3.new(x,0,0),1)
            local data=C.GetEnemies()[model];data.attackAt=workspace:GetServerTimeNow()+120
            model.HumanoidRootPart.Anchored=true;return model,data
        end
        local keeper,kd=spawn(108);kd.threshold=99999
        local victim,vd=spawn(99);vd.threshold=1
        assert(C.ApplyHit(p,victim,{Damage=2,Knockback=0,Growth=0,Lift=0,Stun=0},1))
        local folder=workspace:FindFirstChild("CombatPickups");assert(folder and #folder:GetChildren()==1,"Nonfinal KO did not spawn orb")
        local orb=folder:GetChildren()[1];assert(orb:FindFirstChild("ServerTouchSensor"),"No physical sensor")
        local before=C.GetSnapshot(p).style.score
        root.Anchored=false;root:SetNetworkOwner(nil)
        p.Character.Humanoid:MoveTo(Vector3.new(99,3,0))
        local finish=os.clock()+4
        repeat task.wait(.05)until not orb.Parent or os.clock()>finish
        assert(not orb.Parent,"Actual physical contact did not claim pickup before expiry")
        assert(C.GetSnapshot(p).style.score==before+20*C.GetSnapshot(p).style.multiplier,"Orb score missing/duplicated")
        local after=C.GetSnapshot(p).style.score;task.wait(.2)
        assert(C.GetSnapshot(p).style.score==after,"Multiple limb touches paid twice")
        -- Another orb remains untouched and expires. Same encounter retains the keeper.
        local expiring,ed=spawn(140);ed.threshold=1
        assert(C.ApplyHit(p,expiring,{Damage=2,Knockback=0,Growth=0,Lift=0,Stun=0},1))
        assert(#folder:GetChildren()==1);task.wait(5.2)
        assert(#folder:GetChildren()==0,"Five-second expiry failed")
        kd.threshold=1
        assert(C.ApplyHit(p,keeper,{Damage=2,Knockback=0,Growth=0,Lift=0,Stun=0},1))
        assert(#folder:GetChildren()==0,"Final KO incorrectly spawned risk-free orb")
        result={passed=true,physicalTouch=true,oneClaimAcrossLimbs=true,expiry=true,finalKOException=true,humanInputVerified=false}
    end,debug.traceback)
    C.ClearEnemies();C.ResetLobby();C.ResetPlayers(Vector3.new(28,4,0));C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0})
    assert(ok,err);return result
end
