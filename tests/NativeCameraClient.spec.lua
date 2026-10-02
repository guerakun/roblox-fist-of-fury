-- Actual client configuration and noninterference only; scripted probe, not orbit/input hardware proof.
-- Root runs in a fresh Waiting session. Restores native camera after a three-frame test-only sentinel.
return function()
    local p=game.Players.LocalPlayer
    local camera=workspace.CurrentCamera
    local h=p.Character and p.Character:FindFirstChildOfClass("Humanoid")
    local run=game:GetService("RunService")
    task.wait(.1)
    assert(camera.CameraType==Enum.CameraType.Custom and camera.CameraSubject==h,"native subject/mode missing")
    assert(p.CameraMode==Enum.CameraMode.Classic,"classic mode missing")
    assert(p.CameraMinZoomDistance==8 and p.CameraMaxZoomDistance==28,"zoom limits not restored")
    assert(camera.FieldOfView==70,"native FOV not configured")
    local playerModule=p.PlayerScripts:FindFirstChild("PlayerModule")
    assert(playerModule and playerModule:FindFirstChild("CameraModule"),"Roblox CameraModule missing")
    local oldType,oldFrame,oldFocus=camera.CameraType,camera.CFrame,camera.Focus
    local ok,problem=xpcall(function()
        camera.CameraType=Enum.CameraType.Scriptable
        local sentinel=oldFrame*CFrame.Angles(0,.27,0)
        camera.CFrame=sentinel
        for _=1,3 do
            run.RenderStepped:Wait()
            assert(camera.CameraType==Enum.CameraType.Scriptable,"presentation forced camera mode each frame")
            assert((camera.CFrame.Position-sentinel.Position).Magnitude<.001 and camera.CFrame.LookVector:Dot(sentinel.LookVector)>.99999,"presentation overwrote external camera transform")
        end
    end,debug.traceback)
    camera.CFrame=oldFrame;camera.Focus=oldFocus;camera.CameraType=oldType
    assert(ok,problem)
    return {passed=true,nativeMode=true,subjectCorrect=true,zoom={8,28},noninterferenceFrames=3,
        scriptedProbe=true,physicalOrbitVerified=false}
end
