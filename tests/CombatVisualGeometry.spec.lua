-- Authoritative footprint interpretation, not rendered/hardware evidence.
return function(Geometry,ArenaMath)
    Geometry=Geometry or require(game.Players.LocalPlayer.PlayerScripts.NightfallClient.CombatVisualGeometry)
    ArenaMath=ArenaMath or require(game.ReplicatedStorage.Nightfall.Shared.ArenaMath)
    local checks=0
    local function check(v,m)checks+=1 assert(v,m)end
    local origin=Vector3.new(24,3,0)
    for _,direction in ipairs({1,-1,Vector3.zAxis,-Vector3.zAxis,Vector3.new(1,0,1).Unit})do
        local f=ArenaMath.NormalizeDirection(direction)
        local r=ArenaMath.Right(f)
        local point=Geometry.Point(origin,direction,7,2,3)
        check((point-(origin+f*7+Vector3.yAxis*2+r*3)).Magnitude<1e-5,"Special basis")
        local frame=ArenaMath.BoxFrame(origin+f*5,direction)
        local event={shape="Box",position=origin+f*5,size=Vector3.new(10,9,6),cframe=frame,direction=direction}
        local actual,size=Geometry.Footprint(event)
        check((actual.Position-frame.Position).Magnitude<1e-5 and actual.RightVector:Dot(f)>.999,"Authoritative box orientation")
        check(size.X==10 and size.Z==6,"Box forward/lateral dimensions preserved")
        check(Geometry.Contains(event,origin+f*9+r*2.9,0),"Rotated inside point")
        check(not Geometry.Contains(event,origin+f*5+r*3.2,0),"Rotated lateral miss")
        check(not Geometry.Contains(event,origin-f,0),"Rear miss")
        check(Geometry.Contains(event,origin+f*5+r*3.2,.3),"HUD warning margin only")
        local legacy={position=origin,direction=direction,radius=8}
        local fallback=Geometry.Footprint(legacy)
        check((fallback.Position-(origin+f*4)).Magnitude<1e-5,"Legacy forward offset")
    end
    local circle={shape="Circle",position=origin,radius=6}
    check(Geometry.Contains(circle,origin+Vector3.zAxis*5.9,0),"Circle inside")
    check(not Geometry.Contains(circle,origin+Vector3.xAxis*6.1,0),"Circle outside")
    return {passed=true,checks=checks,renderedVerified=false}
end
