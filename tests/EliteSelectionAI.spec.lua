return function()
    local AI=require(game.ServerScriptService.NightfallServer.EnemyAI)
    local Moves=require(game.ServerScriptService.NightfallServer.EnemyMoves)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local spec={Reach=12,Moves={"Cleaver","SirenLine"},PhaseMoves={"SplitAlarm"},SignatureCooldown=8,DesperationMove="CoreMeltdown",DesperationAt=.8}
    local data={phase=2,percent=55,threshold=100}
    local function counts(distance,extra)
        local result={}
        local context={distance=distance,lanePlayers=1,airborne=false,time=20}
        for k,v in pairs(extra or {})do context[k]=v end
        for i=0,99 do local name=AI.ChooseEliteMove(spec,data,context,(i+.5)/100);result[name]=(result[name] or 0)+1 end
        return result
    end
    local near,far=counts(5),counts(35)
    assert((near.Cleaver or 0)>(far.Cleaver or 0),"distance weights close moves")
    local clustered=counts(5,{lanePlayers=3})
    assert((clustered.Cleaver or 0)<(near.Cleaver or 0),"clustered party increases area priority")
    data.lastSignatureAt=19
    local limited=counts(35)
    assert(not limited.SplitAlarm,"signature cooldown removes repeat signature")
    data.lastSignatureAt=nil;data.lastMove="Cleaver"
    assert((counts(5).Cleaver or 0)<(near.Cleaver or 0),"repeat suppression")
    data.percent=80
    assert(AI.ChooseEliteMove(spec,data,{distance=35,lanePlayers=1,time=20},0)=="CoreMeltdown","one desperation at final20percent")
    data.desperationUsed=true
    assert(AI.ChooseEliteMove(spec,data,{distance=35,lanePlayers=1,time=20},0)~="CoreMeltdown","desperation cannot repeat")
    local lowSpec={Reach=12,Moves={"Cleaver","CrossingSweep"},PhaseMoves={}}
    local grounded,airborne=0,0
    for i=0,99 do
        local d={phase=1,percent=0,threshold=100}
        if AI.ChooseEliteMove(lowSpec,d,{distance=5,lanePlayers=1,airborne=false,time=20},(i+.5)/100)=="CrossingSweep" then grounded+=1 end
        if AI.ChooseEliteMove(lowSpec,d,{distance=5,lanePlayers=1,airborne=true,time=20},(i+.5)/100)=="CrossingSweep" then airborne+=1 end
    end
    assert(airborne<grounded,"delayed airborne observation reduces jumpable choice")
    local checked=0
    for kind,enemy in pairs(Config.Enemies)do if enemy.Role~="Grunt" then
        assert(enemy.DesperationMove and enemy.PhaseSummons==2,"elite metadata "..kind)
        local move=Moves.Build(enemy.DesperationMove,{origin=Vector3.new(90,3,0),target=Vector3.new(100,3,0),direction=1,arena=Config.Stages[1],partyPositions={},spec=enemy,phase=2})
        assert(move.Windup>=1 and move.Recovery>=1.3 and #move.Volumes>=2,"desperation tell/punish/geometry "..kind)
        checked+=1
    end end
    assert(checked==6,"six elite desperation moves")
    return {elites=checked,weightedDistance=true,partyLayout=true,signatureCooldown=true,repeatSuppression=true,airborneObservation=true,oneDesperation=true}
end
