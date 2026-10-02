-- Actual client physics through production movement helper; scripted input, not hardware proof.
-- Run in a fresh Waiting lobby without enemies. Root owns Studio execution.
return function()
 local p=game.Players.LocalPlayer
 local r=p.Character.HumanoidRootPart;local h=p.Character.Humanoid
 local V=require(p.PlayerScripts.NightfallClient.ArenaView)
 local C=require(game.ReplicatedStorage.Nightfall.Shared.Config)
 local b=C.Stages[1].Waves[1].Bounds
 local bounds={MinX=b.MinX+2,MaxX=b.MaxX-2,MinZ=b.MinZ+2,MaxZ=b.MaxZ-2}
 local run=game:GetService("RunService")local input=Vector2.zero local facing=Vector3.xAxis
 local result={passed=false,scriptedInput=true,hardwareInputVerified=false,cases={},maxCameraTranslation=0,minCameraLookDot=1}
 local initialCamera=workspace.CurrentCamera.CFrame
 local samples={}
 run:BindToRenderStep("ArenaLocomotionFixture",Enum.RenderPriority.Last.Value,function()
  local move,nextFacing=V.Movement(input,r.Position,bounds,facing);facing=nextFacing;h:Move(move,false)
  local camera=workspace.CurrentCamera.CFrame
  result.maxCameraTranslation=math.max(result.maxCameraTranslation,(camera.Position-initialCamera.Position).Magnitude)
  result.minCameraLookDot=math.min(result.minCameraLookDot,camera.LookVector:Dot(initialCamera.LookVector))
  table.insert(samples,r.Position)
 end)
 local ok,problem=xpcall(function()
  for _,case in ipairs({{name="south",input=Vector2.new(0,1),axis=Vector3.zAxis},{name="east",input=Vector2.new(1,0),axis=Vector3.xAxis},
   {name="north",input=Vector2.new(0,-1),axis=-Vector3.zAxis},{name="west",input=Vector2.new(-1,0),axis=-Vector3.xAxis}})do
   local before=r.Position;input=case.input;task.wait(.35);input=Vector2.zero;task.wait(.12)
   local delta=r.Position-before;local travel=delta:Dot(case.axis)
   assert(travel>3,"full-plane physics movement missing: "..case.name)
   table.insert(result.cases,{direction=case.name,travel=travel,vertical=delta.Y})
  end
  input=Vector2.new(1,0);task.wait(2.5);input=Vector2.zero;task.wait(.15)
  assert(r.Position.X<=bounds.MaxX+.2 and r.Position.X>=bounds.MaxX-2,"closed area walking bound")
  result.boundaryX=r.Position.X;result.frames=#samples
  assert(result.maxCameraTranslation<.01 and result.minCameraLookDot>.99999,"arena camera must not chase locomotion")
  result.passed=true
 end,debug.traceback)
 run:UnbindFromRenderStep("ArenaLocomotionFixture");h:Move(Vector3.zero,false)
 assert(ok,problem)return result
end
