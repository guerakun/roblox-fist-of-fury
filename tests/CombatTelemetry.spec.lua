-- Studio-only observer contract; never changes live persistence or gameplay records.
return function()
    local T=require(game.ServerScriptService.NightfallServer.CombatTelemetry)
    T.Reset();T.BeginEncounter(2,3)
    local p={UserId=901}
    T.Hit(p,12.5);T.Hit(p,2.5);T.StockLoss(p)
    T.Windup("Fixture","Jab",.4,2,2)
    T.Windup("Fixture","Kick",.3,3,2)
    T.AICost(.001);T.AICost(.003)
    local s=T.Summary()
    assert(s.hits['901']==2 and s.damage['901']==15,'accepted-hit counters')
    assert(s.stocks['901']['2']==1 and s.encounters['2:3'].stocks==1,'stock attribution')
    assert(s.windupPeak==3 and s.capViolations==1 and s.minWindup==.3,'windup budget metrics')
    assert(s.actions.Fixture.Jab==1 and s.actions.Fixture.Kick==1,'distinct action counters')
    assert(math.abs(s.aiMeanMs-2)<.00001,'mean AI duration')
    assert(s.cameraFrustum=='not measured' and s.flankRatio==false,'unsupported/unobserved is not zero')
    T.Reset()
    local models,records={},{}
    for _,x in ipairs({-5,5}) do
        local m=Instance.new("Model");local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Anchored=true;root.Position=Vector3.new(x,3,0);root.Parent=m
        local h=Instance.new("Humanoid");h.Parent=m;m.Parent=workspace;table.insert(models,m)
        records[m]={spec={Role="Grunt"},stunnedUntil=0,launchedUntil=0,recoveryUntil=0}
    end
    local character=Instance.new("Model");local root=Instance.new("Part");root.Name="HumanoidRootPart";root.Position=Vector3.new(0,3,0);root.Anchored=true;root.Parent=character;character.Parent=workspace
    local player={Character=character}
    T.Sample(records,{player},10,true);T.Sample(records,{player},15.1,true)
    local counted=T.Summary();assert(counted.eligibleGruntTicks==4 and counted.idleGruntTicks==4,'stationary eligible ticks')
    assert(counted.flankWindows==1 and counted.flankedWindows==1,'five-second surround window')
    records[models[1]].stunnedUntil=20;records[models[2]].recoveryUntil=20
    T.Sample(records,{player},16,true)
    assert(T.Summary().eligibleGruntTicks==4,'stun/recovery excluded')
    for _,m in ipairs(models)do m:Destroy()end;character:Destroy()
    T.Reset()
    return 'PASS: hit/damage, stock/encounter attribution, windup caps, action diversity and honest missing metrics'
end
