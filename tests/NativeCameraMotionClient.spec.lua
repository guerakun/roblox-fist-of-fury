-- Actual Humanoid/native CameraModule motion with scripted orientation/input, not hardware orbit proof.
return function()
 local p=game.Players.LocalPlayer;local r=p.Character.HumanoidRootPart;local h=p.Character.Humanoid
 local camera=workspace.CurrentCamera;local run=game:GetService("RunService")
 local V=require(p.PlayerScripts.NightfallClient.ArenaView)
 local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
 local b=Config.Stages[1].Waves[1].Bounds
 local bounds={MinX=b.MinX+2,MaxX=b.MaxX-2,MinZ=b.MinZ+2,MaxZ=b.MaxZ-2}
 local input=Vector2.zero;local facing=Vector3.xAxis;local oldFrame=camera.CFrame
 local result={passed=false,scriptedInput=true,physicalOrbitVerified=false,cases={}}
 local bind="NativeCameraMotionQA"
 run:BindToRenderStep(bind,Enum.RenderPriority.Last.Value,function()
  local move;move,facing=V.Movement(input,r.Position,bounds,facing,camera.CFrame);h:Move(move,false)
 end)
 local ok,problem=xpcall(function()
  for _,direction in ipairs({Vector3.xAxis,-Vector3.zAxis,-Vector3.xAxis,Vector3.zAxis})do
   local desired=CFrame.lookAt(r.Position-direction*16+Vector3.new(0,7,0),r.Position+Vector3.new(0,2,0))
   camera.CFrame=desired;task.wait(.2)
   assert(camera.CameraType==Enum.CameraType.Custom,"native mode changed")
   assert(camera.CFrame.LookVector:Dot(desired.LookVector)>.995,"orbit forced back")
   local start=r.Position;local startCamera=camera.CFrame.Position
   input=Vector2.new(0,-1);task.wait(.45);input=Vector2.zero;task.wait(.1)
   local delta=r.Position-start;local flat=Vector3.new(delta.X,0,delta.Z)
   local cameraDelta=camera.CFrame.Position-startCamera
   assert(flat:Dot(direction)>4,"camera-relative forward did not move")
   assert((flat-direction*flat:Dot(direction)).Magnitude<1.5,"forward direction drifted")
   assert((cameraDelta-delta).Magnitude<1.5,"native camera did not follow character")
   table.insert(result.cases,{heading={direction.X,direction.Y,direction.Z},travel=flat:Dot(direction),followError=(cameraDelta-delta).Magnitude})
  end
  result.passed=true
 end,debug.traceback)
 input=Vector2.zero;h:Move(Vector3.zero,false);run:UnbindFromRenderStep(bind);camera.CFrame=oldFrame
 assert(ok,problem);return result
end
