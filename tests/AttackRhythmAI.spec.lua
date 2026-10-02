-- Fresh one-client actual remote acceptance. Does not claim hardware clicking or client prediction coverage.
return function(driverTemplate)
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    local C=require(game.ServerScriptService.NightfallServer.CombatService)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local players=game.Players:GetPlayers();assert(#players==1 and C.GetRunStatus()=="Waiting","fresh one-client Waiting required")
    local p=players[1];local qa=Instance.new("RemoteEvent");qa.Name="AttackRhythmQA";qa.Parent=game.ReplicatedStorage.Nightfall.Remotes
    local driver=driverTemplate:Clone();local ready,sent,report=false,false,nil
    local connection=qa.OnServerEvent:Connect(function(player,message,payload)
        if player~=p then return end
        if message=="Ready"then ready=true elseif message=="Sent"then sent=true elseif message=="Echoes"then report=payload end
    end)
    local out={passed=false,requests=12,hardwareClicksVerified=false}
    local function waitFor(predicate,label)
        local deadline=os.clock()+4
        repeat if predicate()then return end;task.wait(.025)until os.clock()>=deadline
        error(label)
    end
    local ok,problem=xpcall(function()
        C.BeginRun("studio-attack-rhythm");C.SetArena(Config.Stages[1],1);C.ResetPlayers(Vector3.new(26,4,0));task.wait(2)
        C.ResetPlayers(Vector3.new(26,4,0));task.wait(.4)
        C.BeginEncounter();C.SetEncounterState({status="Combat",wave=1,encounterKind="Wave"})
        local h=p.Character.Humanoid;local baseSpeed=h.WalkSpeed
        driver.Parent=p.PlayerGui;waitFor(function()return ready end,"driver ready")
        waitFor(function()local r=C.GetAIDiagnostics().players[1];return r and r.viewAge and r.viewAge<.4 end,"fresh native view")
        local before=C.GetSnapshot(p);qa:FireClient(p,"Burst")
        waitFor(function()return sent and C.GetSnapshot(p).acceptedActionId>before.acceptedActionId end,"accepted remote burst")
        local during=C.GetSnapshot(p)
        out.accepted=during.acceptedActionId-before.acceptedActionId
        out.busyRemaining=during.busyRemaining;out.duringSpeed=h.WalkSpeed;out.baseSpeed=baseSpeed
        assert(out.accepted==1,"rapid requests accepted multiple swings")
        assert(during.busyRemaining>0 and h.AutoRotate==false,"full swing owns busy/yaw")
        task.wait(.06)
        out.duringSpeed=h.WalkSpeed
        assert(math.abs(out.duringSpeed-baseSpeed*Config.AttackMoveScale)<.01,"attack movement factor")
        task.wait(Config.Attacks.Light.ActionDuration+.2)
        local after=C.GetSnapshot(p)
        assert(after.acceptedActionId==during.acceptedActionId,"rejected queued clicks did not start later swings")
        assert(after.busyRemaining==0 and h.AutoRotate==true,"swing restores normal locomotion")
        assert(math.abs(h.WalkSpeed-baseSpeed)<.01,"normal walking speed restored")
        qa:FireClient(p,"Report");waitFor(function()return report~=nil end,"accepted echo report")
        assert(type(report)=="table"and type(report.echoes)=="table","client observation report")
        local echoes=report.echoes
        assert(#echoes==1,"one accepted FX event per swing")
        local echo=echoes[1]
        assert(echo.requestId==1 and echo.attackId==during.acceptedActionId and echo.actorLife==during.actorLife,"accepted identity matches first request/current life")
        assert(echo.duration==Config.Attacks.Light.ActionDuration and math.abs(during.cooldowns.Light-echo.startAt-Config.Attacks.Light.Cooldown)<.002,"authoritative timing metadata")
        local initial,final=report.presentationBefore,report.presentationAfter
        assert(type(initial)=="table"and type(final)=="table"and type(initial.starts)=="number"and type(final.starts)=="number","actual Main presentation counters")
        out.presentationStarts=final.starts-initial.starts
        out.presentationPoseStart=final.poseStart
        assert(out.presentationStarts==1,"actual Main must begin exactly one pose for the accepted direct-remote swing")
        assert(type(final.poseStart)=="number"and math.abs(final.poseStart-echo.startAt)<.002,"actual Main pose uses authoritative accepted start time")
        out.actualMainAcceptedPlaybackVerified=true
        out.localPredictionVerified=false
        out.echo=echo;out.restoredSpeed=h.WalkSpeed;out.passed=true
    end,debug.traceback)
    connection:Disconnect();driver:Destroy();qa:Destroy()
    C.ClearEnemies();C.ResetLobby();C.ResetPlayers(Config.Stages[1].Waves[1].Checkpoint);C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0})
    if not ok then out.error=problem end
    return out
end
