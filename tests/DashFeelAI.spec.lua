-- Same observation protocol for old/new tuning. Always returns complete measured metrics before applying targets.
return function(driverTemplate)
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    local C=require(game.ServerScriptService.NightfallServer.CombatService)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local players=game.Players:GetPlayers();assert(#players==1 and C.GetRunStatus()=="Waiting","fresh one-client Waiting required")
    local p=players[1];local qa=Instance.new("RemoteEvent");qa.Name="DashFeelQA";qa.Parent=game.ReplicatedStorage.Nightfall.Remotes
    local driver=driverTemplate:Clone();local ready,sent=false,false
    local connection=qa.OnServerEvent:Connect(function(player,message)if player==p then if message=="Ready"then ready=true elseif message=="Sent"then sent=true end end end)
    local out={passed=false,samples={},scriptedIdleRequest=true,hardwareInputVerified=false}
    local function waitFor(predicate,message)
        local deadline=os.clock()+4
        repeat if predicate()then return end;task.wait(.05)until os.clock()>=deadline
        error(message)
    end
    local ok,problem=xpcall(function()
        C.SetArena(Config.Stages[1],1);C.ResetPlayers(Vector3.new(26,4,0));task.wait(2)
        C.ResetPlayers(Vector3.new(26,4,0));task.wait(.4)
        local root=p.Character.HumanoidRootPart
        local start=root.Position;out.cooldownBefore=C.GetSnapshot(p).cooldowns.Dash
        driver.Parent=p.PlayerGui;waitFor(function()return ready end,"driver ready")
        local began=os.clock();qa:FireClient(p,"Dash")
        repeat
            task.wait(.025)
            local velocity=root.AssemblyLinearVelocity
            table.insert(out.samples,{time=os.clock()-began,z=root.Position.Z-start.Z,x=root.Position.X-start.X,vx=velocity.X,vy=velocity.Y,vz=velocity.Z})
        until os.clock()-began>=.7
        local delta=root.Position-start;local velocity=root.AssemblyLinearVelocity
        out.delta={delta.X,delta.Y,delta.Z};out.endHorizontalSpeed=Vector2.new(velocity.X,velocity.Z).Magnitude
        out.cooldownAfter=C.GetSnapshot(p).cooldowns.Dash
        out.accepted=sent and out.cooldownAfter>out.cooldownBefore
        out.targets={minimumTravel=3,maximumTravel=14,maximumEndSpeed=2,maximumCrossDrift=1}
        out.passed=out.accepted and delta.Z>=3 and delta.Z<=14 and math.abs(delta.X)<=1 and out.endHorizontalSpeed<=2
        if not out.passed then out.targetFailure="Accepted idle dash must travel3..14 studs and settle below2 studs/s by.7s without side drift"end
    end,debug.traceback)
    connection:Disconnect();driver:Destroy();qa:Destroy()
    C.ClearEnemies();C.ResetLobby();C.ResetPlayers(Config.Stages[1].Waves[1].Checkpoint)
    C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0})
    if not ok then out.error=problem end
    return out
end
