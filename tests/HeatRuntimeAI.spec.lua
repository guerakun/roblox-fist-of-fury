-- Root-only disposable two-client Studio fixture. Restores rollout flag; sticky admitted choices remain until server ends.
return function()
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    local server=game.ServerScriptService.NightfallServer
    local C=require(server.CombatService);local P=require(server.ProgressionService)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local Heat=require(game.ReplicatedStorage.Nightfall.Shared.HeatConfig)
    local Telemetry=require(server.CombatTelemetry)
    local players=game.Players:GetPlayers();assert(#players==2,"Two initialized clients required")
    local a,b=players[1],players[2]
    local originalEnabled=Heat.Enabled
    local qa=Instance.new("RemoteEvent");qa.Name="HeatQA";qa.Parent=game.ReplicatedStorage
    local hello,acks,tells,jabTells={},{},{},{}
    local connection=qa.OnServerEvent:Connect(function(p,kind,value)
        if kind=="Hello"then hello[p]=true elseif kind=="Ack"then acks[value]=p
        elseif kind=="MutationTell"and p==a then table.insert(tells,value)
        elseif kind=="JabTell"and p==a then table.insert(jabTells,value)end
    end)
    local function await(label,fn,seconds)
        local finish=os.clock()+seconds
        repeat if fn()then return end task.wait(.03)until os.clock()>finish
        error("Timed out: "..label)
    end
    local function anchor(p,x)p.Character:PivotTo(CFrame.new(x,3,0));p.Character.HumanoidRootPart.Anchored=true end
    local result
    local ok,err=xpcall(function()
        await("clients and profiles",function()
            return hello[a]and hello[b]and C.GetSnapshot(a)and C.GetSnapshot(b)and P.GetSnapshot(a).loading~=true and P.GetSnapshot(b).loading~=true
        end,30)
        for _,p in ipairs(players)do assert(P.GetTravelProfile(p).mode~="Saved","No persistent profile mutation in fixture")end
        task.wait(2)
        C.ClearEnemies();C.ResetLobby();C.SetEncounterState({status="Waiting",wave=0})
        Heat.Enabled=false
        assert(not C.SetRunOptions("Normal",{"Frenzy"}),"Disabled Heat accepted")
        assert(not C.SetRunOptions("Forged",{})and not C.SetRunOptions("Normal",{"Unknown"}))
        Heat.Enabled=true
        local all=table.clone(Heat.Order)
        assert(not C.SetRunOptions("Normal",all,"true"),"Malformed admission lock accepted")
        assert(C.SetRunOptions("Normal",all,true))
        table.clear(all)
        local options=C.GetRunOptions();assert(#options.heat==6 and options.locked and options.admissionLocked)
        table.clear(options.heat);assert(#C.GetRunOptions().heat==6,"Getter leaked mutable options")
        local reversed={};for i=#Heat.Order,1,-1 do table.insert(reversed,Heat.Order[i])end
        assert(C.SetRunOptions("Normal",reversed,true)and not C.SetRunOptions("Hard",Heat.Order,true))
        assert(not C.SetRunOptions("Normal",{"Frenzy"}),"Waiting admitted Heat changed")
        C.ResetLobby();assert(C.GetRunOptions().locked and #C.GetRunOptions().heat==6,"Empty admitted lobby lost choices")
        C.BeginRun("heat-runtime");C.SetArena(Config.Stages[1],1);C.SetWalkingLimit(170)
        C.SetCheckpoint(Vector3.new(90,4,0),"DISTRICT ENTRANCE");C.ResetPlayers(Vector3.new(90,4,0))
        anchor(a,90);anchor(b,86)
        C.SetEncounterState({status="Combat",wave=1,encounterKind="Wave",partySize=2})
        assert(C.SetRunOptions("Normal",reversed,true)and not C.SetRunOptions("Normal",{},true),"Late admission mutated active options")
        local snapshot=C.GetSnapshot(a)
        assert(snapshot.heatPoints==15 and #snapshot.heat==6 and snapshot.runOptionsLocked and snapshot.stocks==1)
        assert(not C.GetRunRules().stockSharing and not C.GetRunRules().midCheckpoint)
        local grunt=C.SpawnEnemy("Husk",Vector3.new(96,0,0),1.18)
        local gd=C.GetEnemies()[grunt];gd.attackAt=workspace:GetServerTimeNow()+120;grunt.HumanoidRootPart.Anchored=true
        assert(math.abs(gd.threshold-Config.Enemies.Husk.Threshold*1.18*1.3)<.001,"Iron Hide/party health composition")
        local boss=C.SpawnEnemy("Executioner",Vector3.new(98,0,0),1.28)
        local bd=C.GetEnemies()[boss];bd.attackAt=workspace:GetServerTimeNow()+120;boss.HumanoidRootPart.Anchored=true
        assert(math.abs(bd.threshold-Config.Enemies.Executioner.Threshold*1.28)<.001,"Iron Hide leaked into elites")
        assert(bd.mutatedMove=="MutatedCrossfire")
        task.wait(2.2)
        assert(C.ApplyHit(grunt,a,{Damage=300,Knockback=0,Growth=0,Lift=0,Stun=0},-1))
        assert(C.GetSnapshot(a).stocks==0 and not C.ShareStock(b,a.UserId),"One Life/share restriction")
        qa:FireClient(b,{held=true,targetUserId=a.UserId,serial=1})
        await("real revive request",function()return acks[1]==b and C.GetSnapshot(b).revive and C.GetSnapshot(b).revive.channeling end,4)
        await("One Life channel revive",function()return C.GetSnapshot(a).stocks==1 and not C.GetSnapshot(a).downed end,4)
        assert(C.GetSnapshot(a).percent==60 and C.GetSnapshot(b).stocks==1)
        C.RetryCheckpoint(Vector3.new(90,4,0));anchor(a,90);anchor(b,86)
        assert(C.GetSnapshot(a).stocks==1 and C.GetSnapshot(a).percent==0,"One Life retry exceeded cap")
        assert(C.CompleteDistrict("heat-runtime",1)and C.GetSnapshot(a).stocks==1,"One Life clear exceeded cap")
        C.ClearEnemies();Telemetry.Reset()
        for i=1,4 do
            local actor=C.SpawnEnemy("Executioner",Vector3.new(93+i*2,0,0),1)
            local data=C.GetEnemies()[actor];data.attackAt=workspace:GetServerTimeNow()+.2
            actor.HumanoidRootPart.Anchored=true
        end
        await("four simultaneous Frenzy windups",function()return Telemetry.Summary().windupPeak>=4 end,4)
        assert(Telemetry.Summary().capViolations==0 and C.GetAIDiagnostics().tokenCap==4)
        C.ClearEnemies()
        local jabber=C.SpawnEnemy("Husk",Vector3.new(95,0,0),1)
        local jd=C.GetEnemies()[jabber];jd.nextMove="HuskJab";jd.attackAt=workspace:GetServerTimeNow()+.15
        jabber.HumanoidRootPart.Anchored=true
        await("scaled primary and secondary jab tells",function()return #jabTells>=2 end,4)
        assert(math.abs(jabTells[1].duration-.48*.8)<.001 and math.abs(jabTells[2].duration-.46*.8)<.001,"Followup did not scale exactly once")
        C.ClearEnemies()
        boss=C.SpawnEnemy("Executioner",Vector3.new(96,0,0),1);bd=C.GetEnemies()[boss]
        boss.HumanoidRootPart.Anchored=true
        bd.spec=table.clone(bd.spec);bd.spec.PhaseSummons=0;bd.spec.FeintChance=0
        bd.percent=bd.threshold*.55;bd.attackAt=workspace:GetServerTimeNow()+.15
        bd.aiRng={NextNumber=function()return .999999 end}
        await("real phase2 mutation attack",function()return bd.lastMove=="MutatedCrossfire"and bd.attacking end,4)
        await("replicated mutation tells",function()return #tells>=2 end,3)
        for _,tell in ipairs(tells)do
            assert(tell.shape=="Box"and math.abs(tell.duration-.95*.8)<.001 and tell.duration>=.30,"Short Fuse real warning")
            assert((tell.size.X==24 and tell.size.Z==4)or(tell.size.X==4 and tell.size.Z==20),"Real mutation cross geometry")
        end
        C.ClearEnemies()
        -- Exercise the actual EncounterService miniboss-clear branch, using scripted KOs/traversal.
        C.ResetLobby();C.ResetPlayers(Vector3.new(28,4,0));C.ClearReady();C.SetEncounterState({status="Waiting",wave=0})
        assert(C.ReadyForMatch(players))
        local deadline=os.clock()+35;local miniClear=false
        repeat
            local state=C.GetSnapshot(a)
            if state.status=="Traverse"then
                for _,p in ipairs(players)do anchor(p,state.targetX+1)end
            elseif state.status=="Combat"then
                local targets={};for model in pairs(C.GetEnemies())do table.insert(targets,model)end
                for _,model in ipairs(targets)do C.ApplyHit(a,model,{Damage=9999,Knockback=0,Growth=0,Lift=0,Stun=0},1)end
            elseif state.wave==2 and state.status=="Intermission"then
                assert(state.checkpointLabel=="DISTRICT ENTRANCE","No Safety Net retained miniboss checkpoint")
                miniClear=true;break
            end
            task.wait(.06)
        until os.clock()>deadline
        assert(miniClear,"Actual miniboss checkpoint branch not reached")
        result={passed=true,disabledGate=true,immutableAdmission=true,stickyEmptyLobby=true,lateAdmission=true,
            copiedSelections=true,heatPoints=15,ironHide=true,oneLifeCap=true,actualOneLifeRevive=true,
            frenzyWindups=4,shortFusePrimary=.384,shortFuseFollowup=.368,shortFuseWarning=.76,actualMutation=true,actualNoSafetyMiniClear=true,
            publishedTeleportVerified=false,humanInputVerified=false}
    end,debug.traceback)
    Heat.Enabled=originalEnabled;connection:Disconnect();qa:Destroy()
    -- The real campaign loop is active at completion: caller must end this disposable Studio server immediately.
    if not ok then error(err)end
    return result
end
