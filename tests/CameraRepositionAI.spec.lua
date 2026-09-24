return function()
    local B=require(game.ReplicatedStorage.Nightfall.Shared.CameraBounds)
    local AI=require(game.ServerScriptService.NightfallServer.EnemyAI)
    local D=require(game.ServerScriptService.NightfallServer.AttackDirector)
    local arena={MinX=0,MaxX=180,CenterX=90}
    local cases=0
    for _,span in ipairs({0,70,140})do for _,x in ipairs({-50,220})do for _,z in ipairs({-11,0,11})do
        local center,goal=Vector3.new(85,5,0),Vector3.new(95,5,0)
        local safe=B.SafePosition(Vector3.new(x,3,z),center,span,goal,span,arena)
        assert(safe and B.Visible(safe,center,span) and B.Visible(safe,goal,span),"Walk goal inside both unchanged permission envelopes")
        assert(safe.X>=6 and safe.X<=174 and safe.Y==3 and safe.Z==z,"Movement remains within arena and lane")
        cases+=1
    end end end
    assert(not B.SafePosition(Vector3.new(90,3,0),Vector3.new(38,5,0),0,Vector3.new(142,5,0),0,arena),"Disjoint camera envelopes fail closed")
    assert(not B.SafePosition(Vector3.new(90,3,0),nil,0,Vector3.new(90,5,0),0,arena),"Unknown camera fails closed")
    local impossible=D.New();local farTarget={};local farActor={}
    local fallback=D.Assign(impossible,farActor,farTarget,Vector3.new(40,3,0),Vector3.new(80,3,0),arena,function(p)return p.X<=50 end)
    assert(fallback.offset.X<0 and fallback.approachFeasible==false,"Impossible fallback preserves physical side and cannot claim approach")
    local actor={SetAttribute=function()end};local target={Character={}}
    local r={Position=Vector3.new(99,3,0),CFrame=CFrame.new(99,3,0)};local pr={Position=Vector3.new(94,3,0)}
    local moves={};local attacks=0
    local h={Health=100,FloorMaterial=Enum.Material.Concrete,Move=function()end,MoveTo=function(_,p)table.insert(moves,p)end}
    local data={kind="Husk",spec={Archetype="Husk",Role="Grunt",Reach=7,Speed=12},stunnedUntil=0,launchedUntil=0,recoveryUntil=0,phase=1,
        moveIndex=0,targetHistory={},attackAt=0,attacking=false,attackSerial=0}
    local director=D.New()
    local c={director=director,enemies={[actor]=data},records={[target]={facing=1}},Combat={GetAlivePlayers=function()return{target}end},
        arena=arena,Config={BlastMargin=24},encounter={status="Combat"},CombatMath={InBlastZone=function()return false end},
        root=function(model)return model==target.Character and pr or r end,humanoid=function()return h end,
        attributes=function()end,fx=function()end,knockOut=function()error("Unexpected KO")end,
        CanAttack=function()return r.Position.X<=90 end,VisiblePosition=function(p)return p.X<=90 end,
        SafePosition=function(p)return Vector3.new(math.clamp(p.X,6,89.5),p.Y,math.clamp(p.Z,-11,11))end,
        beginEnemyAttack=function()attacks+=1;data.attacking=true end}
    AI.Step(10,c)
    assert(data.aiState=="Reposition" and not director.tokens[actor] and attacks==0,"Offscreen actor releases capacity and cannot attack")
    assert(moves[#moves].X<=90 and director.slots[actor].offset.X<0,"Move and slot both choose visible side")
    r.Position=Vector3.new(89,3,0);r.CFrame=CFrame.new(r.Position)
    AI.Step(10.1,c)
    assert(attacks==1,"Actor can engage after entering view without returning to impossible side")
    data.attacking=false;D.Release(director,actor);data.kind="Warden";data.spec.Archetype="Warden"
    r.Position=Vector3.new(85,3,0);pr.Position=Vector3.new(100,3,0)
    AI.Step(20,c)
    assert(not director.tokens[actor] and attacks==1,"Visible actor cannot reserve unreachable melee approach")
    pr.Position=Vector3.new(94,3,0);AI.Step(20.1,c)
    assert(director.tokens[actor],"Stable slot refreshes approach feasibility as target re-enters view")
    return {geometryCases=cases,unknownOrDisjointRejected=2,offscreenNoToken=true,visibleSideReassignment=true,attackAfterEntry=true}
end
