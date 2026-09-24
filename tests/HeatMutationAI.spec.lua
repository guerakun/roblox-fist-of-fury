-- Pure policy/geometry coverage for the actual mutation path, including all six elites.
return function()
    local server=game.ServerScriptService.NightfallServer
    local AI=require(server.EnemyAI);local Moves=require(server.EnemyMoves)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local Difficulty=require(server.DifficultyPolicy)
    local checks,elites=0,0
    local function check(value,message)assert(value,message);checks+=1 end
    for _,spec in pairs(Config.Enemies)do if spec.Role~="Grunt"then
        elites+=1
        local data={phase=1,percent=0,threshold=100,mutatedMove="MutatedCrossfire"}
        local context={distance=15,lanePlayers=2,airborne=false,time=20}
        check(AI.ChooseEliteMove(spec,data,context,.999999)~="MutatedCrossfire","Mutation appeared in phase1")
        data.phase=2
        check(AI.ChooseEliteMove(spec,data,context,.999999)=="MutatedCrossfire","Phase2 mutation missing")
        data.lastMutationAt=12.001
        check(AI.ChooseEliteMove(spec,data,context,.999999)~="MutatedCrossfire","Mutation cooldown ignored")
        data.lastMutationAt=12
        check(AI.ChooseEliteMove(spec,data,context,.999999)=="MutatedCrossfire","Mutation boundary remains locked")
        data.mutatedMove=nil
        check(AI.ChooseEliteMove(spec,data,context,.999999)~="MutatedCrossfire","Unselected Heat mutation leaked")
    end end
    check(elites==6)
    for _,stage in ipairs(Config.Stages)do
        local target=Vector3.new(stage.CenterX,3,0)
        local context={origin=Vector3.new(stage.CenterX-8,4,0),target=target,direction=1,arena=stage}
        local move=Moves.Build("MutatedCrossfire",context)
        check(move.Windup==.95 and move.Recovery==1.2 and move.TellStyle=="Floor"and move.Pose=="Heavy")
        check(#move.Volumes==2 and move.Volumes[1].size.X==24 and move.Volumes[1].size.Z==4)
        check(move.Volumes[2].size.X==4 and move.Volumes[2].size.Z==20)
        local center=Vector3.new(target.X,3,0)
        for _,volume in ipairs(move.Volumes)do
            check(Moves.Contains(volume,center))
            check(not Moves.Contains(volume,center+Vector3.new(4,0,4)),"Diagonal escape pocket missing")
        end
        context.target+=Vector3.new(15,0,8)
        check(move.Volumes[1].position.X==target.X and move.Volumes[1].position.Z==0,"Mutation retargeted after lock")
    end
    for _,tier in ipairs({"Normal","Hard","Nightmare"})do
        local profile=Difficulty.Profile(Config.Difficulties,tier,{"ShortFuse"})
        local followup=Difficulty.Windup(.46,profile)
        check(math.abs(followup-math.max(.30,.46*Config.Difficulties[tier].WindupScale*.8))<.000001,"Secondary warning scale/floor")
    end
    check(Difficulty.Windup(.46,Difficulty.Profile(Config.Difficulties,"Normal",{}))==.46,"Baseline followup changed")
    return {passed=true,checks=checks,elites=elites,phaseAndCooldown=true,lockedCross=true,diagonalSafePocket=true}
end
