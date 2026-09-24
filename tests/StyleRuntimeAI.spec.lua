-- Root-only accepted-hit + campaign reward integration. Direct server hit setup is not human input.
return function()
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    local C=require(game.ServerScriptService.NightfallServer.CombatService)
    local P=require(game.ServerScriptService.NightfallServer.ProgressionService)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local p=game.Players:GetPlayers()[1];assert(p and C.GetSnapshot(p),"Initialized player required")
    task.wait(2)
    local result
    local ok,err=xpcall(function()
        local campaign="style-runtime:"..game:GetService("HttpService"):GenerateGUID(false)
        C.BeginRun(campaign);assert(P.BeginCampaign({p},campaign));C.ClearEnemies()
        C.SetArena(Config.Stages[1],1);C.SetWalkingLimit(170);C.SetCheckpoint(Vector3.new(90,4,0),"STYLE FIXTURE")
        C.ResetPlayers(Vector3.new(90,4,0));p.Character.HumanoidRootPart.Anchored=true
        local before=P.GetSnapshot(p).coins;assert(type(before)=="number","Profile must finish loading")
        local enemy=C.SpawnEnemy("Husk",Vector3.new(95,0,0),1)
        local npc=C.GetEnemies()[enemy];npc.threshold=99999;npc.attackAt=workspace:GetServerTimeNow()+120
        enemy.HumanoidRootPart.Anchored=true
        local attack={Damage=10,Knockback=0,Growth=0,Lift=0,Stun=.1}
        local firstScore
        for wave=1,4 do
            local kind=wave==2 and "Miniboss"or wave==4 and "Boss"or "Wave"
            C.SetEncounterState({status="Combat",wave=wave,waves=4,encounterKind=kind,partySize=1})
            if wave==4 then
                task.wait(2.2)
                assert(C.ApplyHit(enemy,p,attack,-1),"Boss encounter damage accepted")
                C.RetryCheckpoint(Vector3.new(90,4,0));p.Character.HumanoidRootPart.Anchored=true
                C.SetEncounterState({status="Combat",wave=wave,waves=4,encounterKind=kind,partySize=1})
            end
            for _=1,6 do assert(C.ApplyHit(p,enemy,attack,1),"Actual style hit accepted")end
            local snapshot=C.GetSnapshot(p)
            assert(snapshot.style.score>0 and snapshot.style.multiplier>=2,"Accepted hits did not drive style")
            if wave==1 then firstScore=snapshot.style.score end
            assert(C.CommitStyleWave(campaign,1,wave))
            P.AwardEncounterClear({p},1,kind,campaign..":1:"..wave)
        end
        local final=C.FinalizeDistrict(campaign,1)[p]
        assert(final and final.eligibleWaves==4 and final.bossDamageTaken>0,"Boss damage across retry lost")
        assert(final.score>=firstScore and final.parTime==180 and final.damageTaken>=final.bossDamageTaken)
        local receipt=P.AwardDistrict(p,final)
        assert(receipt and(receipt.status=="paid"or receipt.status=="capped"),"Actual district receipt not paid")
        local paid=P.GetSnapshot(p).coins
        assert(C.GetSnapshot(p).runStats.coinsEarned==paid-before,"Reward observer missing or double-counted")
        assert(C.FinalizeDistrict(campaign,1)[p]==final,"Finalization identity changed")
        P.AwardDistrict(p,final)
        assert(P.GetSnapshot(p).coins==paid and C.GetSnapshot(p).runStats.coinsEarned==paid-before,"Finalization retry paid again")
        local snapshot=C.GetSnapshot(p)
        assert(snapshot.districtResult.id==final.id and snapshot.districtReceipt.resultId==final.id,"Snapshot/result receipt mismatch")
        C.SetArena(Config.Stages[2],2)
        snapshot=C.GetSnapshot(p)
        assert(snapshot.districtResult==false and snapshot.districtReceipt==false and snapshot.style.score==0,"Next district retained result")
        result={passed=true,acceptedHits=true,bossRetryDamage=true,immutableResult=true,actualReceipt=true,
            rewardObserverExact=true,replayNoPayment=true,nextDistrictClear=true,rank=final.rank,score=final.score,coins=paid-before}
    end,debug.traceback)
    C.ClearEnemies();C.ResetLobby();C.ResetPlayers(Vector3.new(28,4,0));C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0})
    assert(ok,err);return result
end
