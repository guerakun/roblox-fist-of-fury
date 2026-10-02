return function(Policy,Visibility)
    Policy=Policy or require(game.ServerScriptService.NightfallServer.CameraViewPolicy)
    Visibility=Visibility or require(game.ReplicatedStorage.Nightfall.Shared.CameraVisibility)
    local data={};local subject=Vector3.new(26,3,0)
    local payload={frame=CFrame.lookAt(subject+Vector3.new(0,8,16),subject),fov=70,aspect=16/9}
    local count=0;local function check(v,m)count+=1;assert(v,m)end
    check(Policy.Read(data,0,subject,1,Visibility)==nil,"absent fails closed")
    check(Policy.Receive(data,payload,1,subject,1,Visibility),"valid receipt")
    check(Policy.Read(data,1.79,subject,1,Visibility)~=nil,"fresh valid view")
    check(Policy.Read(data,1.81,subject,1,Visibility)==nil,"stale fails closed")
    check(Policy.Read(data,1.2,subject,2,Visibility)==nil,"life transition fails closed")
    check(Policy.Read(data,1.2,subject+Vector3.xAxis*100,1,Visibility)==nil,"camera distance rechecked")
    check(not Policy.Receive(data,payload,1.05,subject,1,Visibility),"bounded receipt rate")
    check(data.cameraView.receivedAt==1,"rate-limited client cannot renew receipt")
    check(not Policy.Receive(data,{frame=payload.frame,fov=0,aspect=1},2,subject,1,Visibility),"invalid report rejected")
    check(data.cameraView==nil,"invalid report clears previous view")
    check(Policy.Receive(data,payload,2.2,subject,1,Visibility),"valid receipt resumes")
    payload.frame=CFrame.new(999,999,999)
    check(data.cameraView.frame.Position.X==26,"receipt copies fields not mutable payload")
    return {passed=true,assertions=count,scope="Receipt freshness/life/rate/validation only"}
end
