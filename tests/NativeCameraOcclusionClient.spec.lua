-- Scripted native-camera perimeter collision probe; not physical input acceptance.
return function()
 local p=game.Players.LocalPlayer;local r=p.Character.HumanoidRootPart;local h=p.Character.Humanoid
 local c=workspace.CurrentCamera;local run=game:GetService("RunService")
 local V=require(p.PlayerScripts.NightfallClient.ArenaView);local b=require(game.ReplicatedStorage.Nightfall.Shared.Config).Stages[1].Waves[1].Bounds
 local bounds={MinX=b.MinX+2,MaxX=b.MaxX-2,MinZ=b.MinZ+2,MaxZ=b.MaxZ-2}
 local oldFrame=c.CFrame;local moving=true;local bind="NativeOcclusionQA";local result={passed=false,scriptedInput=true,physicalOrbitVerified=false}
 c.CFrame=CFrame.lookAt(r.Position+Vector3.new(0,7,16),r.Position+Vector3.new(0,2,0))
 run:BindToRenderStep(bind,Enum.RenderPriority.Last.Value,function()
  local move=V.Movement(moving and Vector2.new(0,1)or Vector2.zero,r.Position,bounds,Vector3.zAxis,c.CFrame);h:Move(move,false)
 end)
 local ok,problem=xpcall(function()
  task.wait(2);moving=false;task.wait(.25)
  local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Include;params.FilterDescendantsInstances={workspace.NightfallCity.ArenaSurrounds};params.RespectCanCollide=true
  local focus=c.Focus.Position;local desired=focus-c.CFrame.LookVector*16
  local obstruction=workspace:Raycast(focus,desired-focus,params)
  -- Native Popper resolves the rendered near plane; camera origin can sit slightly behind it.
  local nearPoint=c.CFrame.Position+c.CFrame.LookVector*math.abs(c.NearPlaneZ)
  local actual=workspace:Raycast(focus,nearPoint-focus,params)
  result.rootZ=r.Position.Z;result.cameraZ=c.CFrame.Position.Z;result.distance=(c.CFrame.Position-focus).Magnitude
  result.obstruction=obstruction and obstruction.Instance.Name or false;result.actualObstructed=actual~=nil
  assert(r.Position.Z<=bounds.MaxZ+.15 and r.Position.Z>bounds.MaxZ-2,"physical arena edge not reached/clamped")
  assert(c.CameraType==Enum.CameraType.Custom and obstruction and not actual,"native camera did not resolve visible perimeter")
  assert(result.distance<15,"native camera did not pull closer at wall")
  result.passed=true
 end,debug.traceback)
 moving=false;run:UnbindFromRenderStep(bind);h:Move(Vector3.zero,false);c.CFrame=oldFrame
 assert(ok,problem);return result
end
