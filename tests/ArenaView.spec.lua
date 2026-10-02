-- Pure full-plane input and fixed-target interpolation contract; no physical-input claim.
return function(View,Bounds)
    View=View or require(game.Players.LocalPlayer.PlayerScripts.NightfallClient.ArenaView)
    local checks=0
    local function check(value,message)checks+=1 assert(value,message)end
    local bounds={MinX=4,MaxX=44,MinZ=-20,MaxZ=20}
    local previous=Vector3.xAxis
    for _,input in ipairs({Vector2.new(1,0),Vector2.new(-1,0),Vector2.new(0,1),Vector2.new(0,-1),Vector2.new(1,1)})do
        local move,facing=View.Movement(input,Vector3.new(20,3,0),bounds,previous)
        local expected=Vector3.new(input.X,0,input.Y).Unit
        check((move-expected).Magnitude<1e-6,"Equal-speed plane input")
        check((facing-expected).Magnitude<1e-6,"Full-plane facing")
    end
    for _,case in ipairs({{Vector3.new(4,3,0),Vector2.new(-1,0)},{Vector3.new(44,3,0),Vector2.new(1,0)},
        {Vector3.new(20,3,-20),Vector2.new(0,-1)},{Vector3.new(20,3,20),Vector2.new(0,1)}})do
        local move=View.Movement(case[2],case[1],bounds,previous)
        check(move.Magnitude==0,"Outward input suppressed before correction")
        local inward=View.Movement(-case[2],case[1],bounds,previous)
        check(inward.Magnitude==1,"Inward input preserved")
    end
    local idle,held=View.Movement(Vector2.zero,Vector3.new(20,3,0),bounds,Vector3.zAxis)
    check(idle==Vector3.zero and held==Vector3.zAxis,"Idle retains heading")
    local goal=Vector3.new(24,5,0)
    local center,distance=View.CameraStep(nil,0,goal,80,1/60)
    for _,dt in ipairs({1/30,1/60,1/144,.05})do
        center,distance=View.CameraStep(center,distance,goal,80,dt)
        check(center==goal and distance==80,"Unchanged arena has no camera chase")
    end
    local a,d=goal,80
    for _=1,60 do a,d=View.CameraStep(a,d,goal+Vector3.new(44,0,0),90,1/60)end
    local b,e=View.CameraStep(goal,80,goal+Vector3.new(44,0,0),90,1)
    check((a-b).Magnitude<.0001 and math.abs(d-e)<.0001,"Transition smoothing independent of frame rate")
    if Bounds then
        for _,aspect in ipairs({9/16,1,16/9,21/9})do
            local focus,range=Bounds.Arena({MinX=4,MaxX=48,MinZ=-24,MaxZ=24},aspect)
            local frame=Bounds.Frame(focus,range)
            for _,x in ipairs({4,48})do for _,z in ipairs({-24,24})do for _,y in ipairs({0,12})do
                check(Bounds.InFrame(Vector3.new(x,y,z),frame,range,aspect,0),"Arena body corners visible")
            end end end
            check(frame.RightVector:Dot(Vector3.xAxis)>.999,"D moves screen-right")
            check(frame.UpVector:Dot(-Vector3.zAxis)>0,"W moves screen-up")
        end
    end
    return {passed=true,checks=checks,physicalInputVerified=false,cameraRuntimeVerified=false}
end
