-- Root-only fresh one-client Studio fixture. Actual camera/Main reports; scripted orientation, not hardware orbit.
return function(driverTemplate)
    assert(game:GetService("RunService"):IsStudio(),"Studio only")
    local C=require(game.ServerScriptService.NightfallServer.CombatService)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local players=game.Players:GetPlayers();assert(#players==1 and C.GetRunStatus()=="Waiting","fresh one-client Waiting required")
    local player=players[1];local remotes=game.ReplicatedStorage.Nightfall.Remotes
    local viewRemote=remotes:WaitForChild("CameraView")
    local qa=Instance.new("RemoteEvent");qa.Name="ThirdPersonVisibilityQA";qa.Parent=remotes
    local driver=driverTemplate:Clone();local ready,restored,specialSent=false,false,false
    local connection=qa.OnServerEvent:Connect(function(p,message)if p==player then if message=="Ready"then ready=true elseif message=="Restored"then restored=true elseif message=="SpecialSent"then specialSent=true end end end)
    local result={passed=false,hardwareOrbitVerified=false,realMainReports=true}
    local function waitFor(predicate,label)
        local deadline=os.clock()+4
        repeat if predicate()then return end;task.wait(.1)until os.clock()>=deadline
        error("Timed out: "..label)
    end
    local function states()
        local output={};local report=C.GetAIDiagnostics()
        for _,actor in ipairs(report.actors)do output[actor.kind]=actor.canAttack end
        return output,report
    end
    local ok,problem=xpcall(function()
        C.BeginRun("studio-third-person-view");C.SetArena(Config.Stages[1],1)
        C.ResetPlayers(Vector3.new(26,4,0));task.wait(2)
        C.ResetPlayers(Vector3.new(26,4,0));player.Character.HumanoidRootPart.Anchored=true
        local actors={}
        for kind,z in pairs({Husk=-24,Strider=24})do
            local model=C.SpawnEnemy(kind,Vector3.new(26,0,z),1)
            model.HumanoidRootPart.Anchored=true
            C.GetEnemies()[model].stunnedUntil=workspace:GetServerTimeNow()+60
            actors[kind]=model
        end
        C.SetEncounterState({status="Combat",wave=1,encounterKind="Wave"})
        workspace:SetAttribute("ThirdPersonViewSide",1);driver.Parent=player.PlayerGui
        waitFor(function()return ready end,"client staging ready")
        waitFor(function()local s=states();return s.Husk==true and s.Strider==false end,"front visible/back invisible")
        result.first=states()
        task.wait(2.2) -- Exclude spawn protection from the incoming acceptance controls.
        local attack={Damage=1,Knockback=0,Growth=0,Lift=0,Stun=0}
        assert(C.ApplyHit(player,actors.Husk,attack,-Vector3.zAxis),"visible outgoing control")
        assert(not C.ApplyHit(player,actors.Strider,attack,Vector3.zAxis),"offscreen outgoing blocked")
        assert(C.ApplyHit(actors.Husk,player,attack,Vector3.zAxis),"visible incoming control")
        task.wait(.2)
        assert(not C.ApplyHit(actors.Strider,player,attack,-Vector3.zAxis),"offscreen incoming blocked")
        result.symmetricVisibleControls=true
        workspace:SetAttribute("ThirdPersonViewSide",-1)
        waitFor(function()local s=states();return s.Husk==false and s.Strider==true end,"actual camera rotated180")
        result.rotated=states()
        viewRemote.Name="CameraViewPausedForFixture"
        task.wait(1.1)
        local stale,report=states();result.stale=stale;result.staleViewAge=report.players[1].viewAge
        assert(stale.Husk==false and stale.Strider==false and result.staleViewAge>.8,"stale view must reject all attacks")
        assert(not C.ApplyHit(player,actors.Strider,attack,Vector3.zAxis),"stale outgoing blocked")
        assert(not C.ApplyHit(actors.Strider,player,attack,-Vector3.zAxis),"stale incoming blocked")
        local before=C.GetSnapshot(player).cooldowns.Special
        qa:FireClient(player,"Special");waitFor(function()return specialSent end,"actual Special request sent")
        task.wait(.3)
        assert(C.GetSnapshot(player).cooldowns.Special==before,"stale action takes no cooldown")
        result.staleOutgoingRequestBlocked=true
        viewRemote.Name="CameraView"
        waitFor(function()local s=states();return s.Strider==true end,"fresh report resumes visibility")
        result.resumed=true;result.passed=true
    end,debug.traceback)
    viewRemote.Name="CameraView"
    qa:FireClient(player,"Restore")
    local cleanupOk=pcall(function()waitFor(function()return restored end,"camera restored")end)
    result.cameraRestored=cleanupOk and restored
    if not result.cameraRestored then result.passed=false;result.cleanupError="Camera restore acknowledgement missing"end
    connection:Disconnect();driver:Destroy();qa:Destroy();workspace:SetAttribute("ThirdPersonViewSide",nil)
    C.ClearEnemies();C.ResetLobby();C.ResetPlayers(Config.Stages[1].Waves[1].Checkpoint)
    C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0})
    if not ok then result.error=problem end
    return result
end
