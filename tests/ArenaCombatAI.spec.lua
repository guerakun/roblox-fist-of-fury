-- Bounded geometry/slot contract checks for WO-3D.1. Root runs in Studio.
return function(A,Moves,Director,Config)
    A=A or require(game.ReplicatedStorage.Nightfall.Shared.ArenaMath)
    Moves=Moves or require(game.ServerScriptService.NightfallServer.EnemyMoves)
    Director=Director or require(game.ServerScriptService.NightfallServer.AttackDirector)
    Config=Config or require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local n=0
    local function check(value,message)n+=1;assert(value,message)end
    local directions={Vector3.xAxis,-Vector3.xAxis,Vector3.zAxis,-Vector3.zAxis,Vector3.new(1,0,1).Unit}
    local bounds={MinX=4,MaxX=48,MinZ=-24,MaxZ=24,CenterX=26}
    local origin=Vector3.new(26,3,0)
    for _,direction in ipairs(directions)do
        local f=A.NormalizeDirection(direction*7+Vector3.yAxis*3)
        check((f-direction).Magnitude<1e-5,"normalized horizontal direction")
        check(A.FacingFrame(origin,f).LookVector:Dot(f)>.999,"character LookVector")
        check(A.BoxFrame(origin,f).XVector:Dot(f)>.999,"hitbox XVector")
        check(A.Frontal(-f,f)and not A.Frontal(f,f),"front/back block cone")
        local move=Moves.Build("HuskJab",{origin=origin,target=origin+f*5,direction=f,arena=bounds,spec={Reach=6,Windup=.4},partyPositions={origin}})
        check(Moves.Contains(move.Volumes[1],origin+f*5),"jab hits forward XZ")
        check(not Moves.Contains(move.Volumes[1],origin-f*2),"jab rejects behind")
        check(not Moves.Contains(move.Volumes[1],origin+f*4+A.Right(f)*4),"jab rejects outside lateral width")
        local projectile=Moves.Build("PitcherThrow",{origin=origin,target=origin+f*18,direction=f,arena=bounds,spec={},partyPositions={origin}})
        local volume=projectile.Volumes[1]
        for j=0,10 do
            local point=origin:Lerp(projectile.Endpoint,j/10)
            local path=A.NormalizeDirection(projectile.Endpoint-origin)
            for _,side in ipairs({-1,1})do
                check(Moves.Contains(volume,Vector3.new(point.X,3,point.Z)+A.Right(path)*(1.99*side)),"projectile path fits warning")
            end
        end
    end
    local moveNames={HuskJab=true,HuskJumpKick=true,StriderSlide=true,StriderJab=true,GrapplerGrab=true,GrapplerThrow=true,PitcherThrow=true,PitcherShove=true,WardenCounter=true,WardenKick=true,LeaperVaultKick=true,LeaperJab=true,BruteFlop=true,BruteSwing=true,MutatedCrossfire=true}
    for _,spec in pairs(Config.Enemies)do
        for _,list in ipairs({spec.Moves or {},spec.PhaseMoves or {}})do for _,name in ipairs(list)do moveNames[name]=true end end
        if spec.DesperationMove then moveNames[spec.DesperationMove]=true end
    end
    for name in pairs(moveNames)do for _,direction in ipairs(directions)do
        local move=Moves.Build(name,{origin=origin,target=origin+direction*10,direction=direction,arena=bounds,spec={Reach=7,Windup=.5},partyPositions={origin+direction*8}})
        check(#move.Volumes>0 and move.Windup>=.3,"all oriented patterns retain tell")
        for _,volume in ipairs(move.Volumes)do
            check(Moves.Contains(volume,volume.position+Vector3.yAxis*3),"every locked footprint contains own center: "..name)
            if volume.shape=="Box"then check(typeof(volume.cframe)=="CFrame","every box has authoritative orientation")end
        end
    end end
    check(A.NormalizeDirection(-1)==-Vector3.xAxis,"legacy negative fallback")
    check(A.NormalizeDirection(Vector3.new(0/0,0,0),Vector3.zAxis)==Vector3.zAxis,"NaN direction rejected")
    local state=Director.New()
    local target={}
    local axes={}
    for i=1,4 do
        local actor={};local slot=Director.Assign(state,actor,target,origin,origin,bounds,function()return true end)
        check(slot.approachFeasible,"radial approach feasible")
        axes[#axes+1]=slot.offset
    end
    local zApproach=false
    for _,offset in ipairs(axes)do if math.abs(offset.Z)>1 then zApproach=true end end
    check(zApproach,"director uses depth approach slots")
    for stageIndex,stage in ipairs(Config.Stages)do
        check(#stage.Waves==4,"four arenas")
        for i,wave in ipairs(stage.Waves)do
            check(wave.Kind==({"Wave","Wave","Miniboss","Boss"})[i],"stage role order")
            check((A.Clamp(wave.Checkpoint,wave.Bounds,2)-wave.Checkpoint).Magnitude<.01,"checkpoint in active area")
            check(wave.EntryX>wave.Bounds.MinX+2 and wave.EntryX<wave.Bounds.MaxX-2,"rally enters legal next area")
            if i>1 then
                local previous=stage.Waves[i-1].Bounds
                local union=A.Union(previous,wave.Bounds)
                check(union.MinX==previous.MinX and union.MaxX==wave.Bounds.MaxX,"traverse opens union only")
                check(previous.MaxX==wave.Bounds.MinX,"adjacent gate boundary")
            end
        end
    end
    return {passed=true,assertions=n,directions=#directions,scope="Pure geometry and area metadata; physical gates/client actions unverified"}
end
