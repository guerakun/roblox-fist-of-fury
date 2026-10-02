-- Camera-relative horizontal movement policy; no physical-input or CameraModule runtime claim.
return function(View)
    View=View or require(game.Players.LocalPlayer.PlayerScripts.NightfallClient.ArenaView)
    local n=0;local function check(value,message)n+=1 assert(value,message)end
    local bounds={MinX=-30,MaxX=30,MinZ=-30,MaxZ=30}
    for _,yaw in ipairs({0,math.pi/2,math.pi,math.pi*1.5,.71})do
        for _,pitch in ipairs({0,-.65,-math.pi/2})do
            local frame=CFrame.Angles(0,yaw,0)*CFrame.Angles(pitch,0,0)
            local look,right=View.Basis(frame)
            check(math.abs(look.Y)<1e-6 and math.abs(right.Y)<1e-6,"horizontal basis")
            check(math.abs(look:Dot(right))<1e-6 and math.abs(look.Magnitude-1)<1e-6,"stable orthonormal basis")
            for _,input in ipairs({Vector2.new(0,-1),Vector2.new(0,1),Vector2.new(1,0),Vector2.new(-1,0),Vector2.new(1,-1)})do
                local move,facing=View.Movement(input,Vector3.new(0,3,0),bounds,Vector3.xAxis,frame)
                local expected=(right*input.X-look*input.Y).Unit
                check((move-expected).Magnitude<1e-5,"screen-relative cardinal/diagonal motion")
                check((facing-expected).Magnitude<1e-5,"attack facing follows actual camera-relative intent")
            end
        end
    end
    for _,case in ipairs({{Vector3.new(-30,3,0),Vector2.new(-1,0)},{Vector3.new(30,3,0),Vector2.new(1,0)},
        {Vector3.new(0,3,-30),Vector2.new(0,-1)},{Vector3.new(0,3,30),Vector2.new(0,1)}})do
        check(View.Movement(case[2],case[1],bounds,Vector3.xAxis,CFrame.identity).Magnitude==0,"world boundary suppresses outward intent")
        check(View.Movement(-case[2],case[1],bounds,Vector3.xAxis,CFrame.identity).Magnitude==1,"inward remains available")
    end
    local move,facing=View.Movement(Vector2.zero,Vector3.zero,bounds,Vector3.zAxis,CFrame.Angles(0,2,0))
    check(move==Vector3.zero and facing==Vector3.zAxis,"orbit without movement preserves attack facing")
    local analog=View.Movement(Vector2.new(.2,0),Vector3.zero,bounds,Vector3.xAxis,CFrame.identity)
    check(math.abs(analog.Magnitude-.2)<1e-5,"analog strength preserved")
    return {passed=true,checks=n,physicalInputVerified=false}
end
