-- Configuration ownership policy with fake surfaces; actual native orbit is a separate client check.
return function(Native)
    Native=Native or require(game.Players.LocalPlayer.PlayerScripts.NightfallClient.NativeCamera)
    local p={};local waits=0;local n=0
    local function check(value,message)n+=1 assert(value,message)end
    local run={RenderStepped={Wait=function()waits+=1 end}}
    local frame=CFrame.new(7,8,9);local focus=CFrame.new(1,2,3)
    local camera={CFrame=frame,Focus=focus}
    local subject={};local replacement={}
    local api=Native.new(p,run)
    api:Subject(camera,subject);task.wait()
    check(camera.CameraType==Enum.CameraType.Custom,"native camera enabled")
    check(camera.CameraSubject==subject,"current humanoid selected")
    check(p.CameraMode==Enum.CameraMode.Classic,"third person classic")
    check(p.CameraMinZoomDistance==8 and p.CameraMaxZoomDistance==28,"native zoom restored")
    check(camera.FieldOfView==70,"normal vertical FOV")
    check(waits==2,"native initial distance seeded for two frames only")
    check(camera.CFrame==frame and camera.Focus==focus,"no transform/focus writer")
    camera.FieldOfView=75;api:Subject(camera,replacement);task.wait()
    check(camera.CameraSubject==replacement and waits==2,"respawn changes subject without resetting zoom")
    check(camera.FieldOfView==75,"same-camera subject updates preserve native settings")
    local fresh={CFrame=frame,Focus=focus};api:Subject(fresh,replacement)
    check(fresh.CameraType==Enum.CameraType.Custom and fresh.FieldOfView==70,"camera replacement initialized")
    check(fresh.CFrame==frame and fresh.Focus==focus,"replacement transform untouched")
    return {passed=true,checks=n,physicalInputVerified=false,cameraModuleRuntimeVerified=false}
end
