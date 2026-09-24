return function()
    local T=require(game.ServerScriptService.NightfallServer.CombatTelemetry)
    local model=Instance.new("Model");local r=Instance.new("Part");r.Name="HumanoidRootPart";r.Anchored=true;r.Position=Vector3.new(0,-200,0);r.Parent=model
    local h=Instance.new("Humanoid");h.Parent=model;model.Parent=workspace
    local character=Instance.new("Model");local pr=Instance.new("Part");pr.Name="HumanoidRootPart";pr.Anchored=true;pr.Position=Vector3.new(5,-200,0);pr.Parent=character;character.Parent=workspace
    local data={kind="Husk",spec={Role="Grunt"},stunnedUntil=0,launchedUntil=0,recoveryUntil=0,aiState="Approach"}
    local enemies={[model]=data};local players={{Character=character}}
    local ok,err=xpcall(function()
        T.Reset();T.Sample(enemies,players,10,true)
        T.Action(model,"Husk","HuskJab",12);T.Action(model,"Husk","HuskJumpKick",22)
        T.Sample(enemies,players,40.1,true)
        local s=T.Summary().actionDiversity
        assert(s.byKind.Husk.eligible==1 and s.byKind.Husk.passed==1,"Observer routes real action hooks into qualified window")
        T.Sample(enemies,players,45,false)
        assert(T.Summary().actionDiversity.pendingWindows==0,"Intermission closes incomplete window")
        T.Sample(enemies,players,70,true)
        pr.Position=Vector3.new(100,-200,0)
        T.Sample(enemies,players,75,true)
        assert(T.Summary().actionDiversity.byKind.Husk.eligible==1,"Out-of-range and intermission time cannot manufacture full windows")
    end,debug.traceback)
    model:Destroy();character:Destroy();T.Reset();assert(ok,err)
    return {integration=true,qualifiedWindows=1,intermissionExcluded=true,rangeExitExcluded=true}
end
