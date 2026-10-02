-- Disposable test camera staging only. Production Main remains the actual camera reporter.
local RunService=game:GetService("RunService")
if not RunService:IsStudio()then return end
local player=game.Players.LocalPlayer
local camera=workspace.CurrentCamera
local oldType,oldSubject,oldFrame,oldFocus=camera.CameraType,camera.CameraSubject,camera.CFrame,camera.Focus
local qa=game.ReplicatedStorage.Nightfall.Remotes:WaitForChild("ThirdPersonVisibilityQA")
local name="ThirdPersonVisibilityFixture"
local function restore()
    RunService:UnbindFromRenderStep(name)
    camera.CameraType=oldType;camera.CameraSubject=oldSubject;camera.CFrame=oldFrame;camera.Focus=oldFocus
end
qa.OnClientEvent:Connect(function(command)
    if command=="Restore"then restore();qa:FireServer("Restored")
    elseif command=="Special"then
        game.ReplicatedStorage.Nightfall.Remotes.Action:FireServer("Special",{direction=Vector3.zAxis})
        qa:FireServer("SpecialSent")
    end
end)
RunService:BindToRenderStep(name,Enum.RenderPriority.Camera.Value,function()
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root then return end
    camera.CameraType=Enum.CameraType.Scriptable
    local side=workspace:GetAttribute("ThirdPersonViewSide")or 1
    camera.CFrame=CFrame.lookAt(root.Position+Vector3.new(0,8,side*16),root.Position)
    camera.Focus=CFrame.new(root.Position)
end)
script.Destroying:Connect(restore)
qa:FireServer("Ready")
