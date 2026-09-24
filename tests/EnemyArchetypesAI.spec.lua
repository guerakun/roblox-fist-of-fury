return function()
    local A=require(game.ReplicatedStorage.Nightfall.Shared.EnemyArchetypes)
    local Moves=require(game.ServerScriptService.NightfallServer.EnemyMoves)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local count=0
    for id,names in pairs(A.Moves)do
        local spec=A.Specs[id] or Config.Enemies[id]
        assert(spec,"configured archetype "..id)
        local seen={}
        for _,name in ipairs(names)do
            local move=Moves.Build(name,{origin=Vector3.new(90,3,0),target=Vector3.new(103,3,0),direction=1,arena=Config.Stages[1],partyPositions={},spec=spec,phase=1})
            assert(move.Windup>=.30 and move.Recovery>0 and #move.Volumes>0,name.." readable and punishable")
            assert(move.Pose and not seen[name],name.." distinct authored action")
            seen[name]=true;count+=1
            for _,volume in ipairs(move.Volumes)do
                assert(Moves.Contains(volume,volume.position+Vector3.new(0,3,0)),name.." center hit")
                assert(not Moves.Contains(volume,volume.position+Vector3.new(0,3,100)),name.." other lane safe")
                if volume.jumpable then assert(not Moves.Contains(volume,volume.position+Vector3.new(0,9,0)),name.." jump clearance")end
            end
            if move.Projectile then
                assert(move.Endpoint and move.Flight>0 and move.Windup>=.4,"ranged shimmer and server travel")
                assert(move.Volumes[1].size.X>=math.abs(move.Endpoint.X-90)+4,"warning covers swept projectile end padding")
            end
            if move.Grab then assert(move.Windup>=.6,"capture readable")end
            if move.MoveTo and move.Flight then assert(move.Arc>=0 and move.TellStyle=="Floor","locked travel landing warning")end
        end
    end
    for _,z in ipairs({-12,12})do
        local edge=Moves.Build("PitcherThrow",{origin=Vector3.new(90,3,z),target=Vector3.new(105,3,z),direction=1,arena=Config.Stages[1],partyPositions={},spec=A.Specs.Pitcher,phase=1})
        local footprint=edge.Volumes[1]
        assert(footprint.size.Z==math.abs(edge.Endpoint.Z-z)+4,"warning covers clamped lane diagonal")
        for _,alpha in ipairs({0,.1,.5,.9,1})do
            local point=Vector3.new(90,0,z):Lerp(edge.Endpoint,alpha)
            for _,dz in ipairs({-1.999,1.999})do
                assert(Moves.Contains(footprint,point+Vector3.new(0,3,dz)),"projectile body remains within locked lane warning")
            end
        end
    end
    assert(A.Select("Husk",5,{},0)=="HuskJab" and A.Select("Husk",14,{},0)=="HuskJumpKick","brawler range decisions")
    assert(A.Select("Strider",14,{},0)=="StriderSlide" and A.Select("Strider",5,{},0)=="StriderJab","rusher range decisions")
    assert(A.Select("Grappler",5,{blocking=true},1)=="GrapplerGrab","guard punish")
    assert(A.Select("Pitcher",17,{},0)=="PitcherThrow" and A.Select("Pitcher",4,{},0)=="PitcherShove","ranged retreat fallback")
    assert(A.Select("Warden",5,{action="Light",combo=3},0)=="WardenCounter","third-chain counter")
    assert(A.Select("Leaper",14,{},1)=="LeaperVaultKick" and A.Select("Leaper",5,{},1)=="LeaperJab","acrobat range decisions")
    assert(A.Select("Brute",13,{},1)=="BruteFlop" and A.Select("Brute",5,{},1)=="BruteSwing","brute range decisions")
    return "PASS: "..count.." archetype moves, warnings/geometry/travel, seven behavior selection policies"
end
