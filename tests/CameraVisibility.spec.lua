-- Read-only report validation/frustum math; no claim of trusted client orientation.
return function(View)
    View=View or require(game.ReplicatedStorage.Nightfall.Shared.CameraVisibility)
    local n=0;local function check(v,m)n+=1;assert(v,m)end
    local subject=Vector3.new(0,3,0)
    for _,yaw in ipairs({0,math.pi/2,math.pi,math.pi*1.5})do
        local frame=CFrame.lookAt(subject+Vector3.new(math.sin(yaw)*12,3,math.cos(yaw)*12),subject)
        for _,aspect in ipairs({.45,1,16/9,3.5})do
            check(View.Validate(frame,70,aspect,subject),"valid rotated report")
            check(View.Contains(frame.Position+frame.LookVector*12,frame,70,aspect,1),"forward visible")
            check(not View.Contains(frame.Position-frame.LookVector*12,frame,70,aspect,0),"behind rejected")
            check(not View.Contains(frame.Position+frame.RightVector*50+frame.LookVector*12,frame,70,aspect,0),"outside side rejected")
        end
    end
    check(not View.Validate(CFrame.new(0,50,0),70,1,subject),"distant camera rejected")
    check(not View.Validate(CFrame.new(),0/0,1,subject),"invalid FOV rejected")
    check(not View.Validate(CFrame.new(),70,math.huge,subject),"invalid aspect rejected")
    check(not View.Validate(CFrame.new(),70,.2,subject),"invalid narrow aspect rejected")
    check(not View.Validate(CFrame.new(),70,1,Vector3.new(0/0,0,0)),"invalid subject rejected")
    check(not View.Validate({},70,1,subject),"wrong camera type rejected")
    check(not View.Validate(CFrame.lookAt(subject+Vector3.new(0,3,12),subject+Vector3.new(0,3,24)),70,1,subject),"camera must frame own character")
    check(not View.Validate(CFrame.new(0,0,0,2,0,0,0,1,0,0,0,1),70,1,subject),"scaled matrix rejected")
    return {passed=true,checks=n,scope="Camera geometry only; runtime receipt gates separately tested"}
end
