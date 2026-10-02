return function(B,Config)
    B=B or require(game.ReplicatedStorage.Nightfall.Shared.CameraBounds)
    Config=Config or require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local checks=0
    local function check(v,msg)checks+=1 assert(v,msg)end
    for _,stage in ipairs(Config.Stages)do
        check(#stage.Waves==4,"four arenas per district")
        for index,wave in ipairs(stage.Waves)do
            check(wave.Kind==({"Wave","Wave","Miniboss","Boss"})[index],"requested encounter order")
            local arena=wave.Bounds
            check(arena.MinX>=stage.MinX and arena.MaxX<=stage.MaxX and arena.MaxX>arena.MinX,"bounded district")
            check(arena.MinZ==-24 and arena.MaxZ==24,"full depth")
            check(wave.Checkpoint.X>arena.MinX and wave.Checkpoint.X<arena.MaxX,"checkpoint inside arena")
            if index>1 then check(arena.MinX==stage.Waves[index-1].Bounds.MaxX,"adjacent arena exits")end
            local center,span=B.Party({},arena)
            local moved,movedSpan=B.Party({Vector3.new(arena.MaxX,100,24)},arena)
            check(center==moved and span==movedSpan,"movement and jumping cannot drag camera")
            for _,aspect in ipairs({9/16,.7,1,4/3,16/9,2.4,32/9})do
                local focus,distance=B.Arena(arena,aspect)
                local frame=B.Frame(focus,distance)
                for _,x in ipairs({arena.MinX,arena.MaxX})do for _,z in ipairs({-24,24})do for _,y in ipairs({0,5,17})do
                    local p=Vector3.new(x,y,z)
                    check(B.InFrame(p,frame,distance,aspect,B.Margin),"arena corner and body height visible")
                    check(B.Visible(p,center,span),"same server envelope admits arena corner")
                end end end
            end
            local safe=B.SafePosition(Vector3.new(arena.MaxX+30,3,100),center,span,center,span,arena)
            check(safe and safe.X<=arena.MaxX-2 and safe.Z<=22,"AI guidance respects active bounds")
            check(not B.Visible(Vector3.new(center.X+1000,3,0),center,span),"distant attacks rejected")
        end
    end
    check(not B.Visible(Vector3.zero,nil,44),"unknown camera fails closed")
    return {passed=true,checks=checks,scope="Shared geometry and12arenaConfig; actual client rendering separate"}
end
