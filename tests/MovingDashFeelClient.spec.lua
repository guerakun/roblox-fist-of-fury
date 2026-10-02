-- Actual held-movement physics through a real Dash request; scripted input, not device input.
return function()
 local p=game.Players.LocalPlayer;local r=p.Character.HumanoidRootPart;local h=p.Character.Humanoid
 local Run=game:GetService("RunService");local remote=game.ReplicatedStorage.Nightfall.Remotes.Action
 task.wait(1.5) -- Let a preceding fixture dash cooldown expire.
 local accepted=false;local peak=0
 local echo=game.ReplicatedStorage.Nightfall.Remotes.FX.OnClientEvent:Connect(function(e)if e.kind=="Dash"and e.playerUserId==p.UserId then accepted=true end end)
 local bind="MovingDashFeelQA";local moving=true;local out={passed=false,scriptedInput=true,hardwareInputVerified=false}
 Run:BindToRenderStep(bind,Enum.RenderPriority.Last.Value,function()h:Move(moving and Vector3.zAxis or Vector3.zero,false);peak=math.max(peak,r.AssemblyLinearVelocity.Z)end)
 local ok,problem=xpcall(function()
  task.wait(.3);local start=r.Position;remote:FireServer("Dash",{direction=Vector3.zAxis})
  task.wait(.65)
  local delta=r.Position-start;local v=r.AssemblyLinearVelocity
  out.travelZ=delta.Z;out.crossDrift=math.abs(delta.X);out.forwardSpeed=v.Z;out.walkSpeed=h.WalkSpeed;out.accepted=accepted;out.peakForwardSpeed=peak
  assert(accepted and peak>40,"actual dash was not accepted/applied")
  assert(delta.Z>5 and delta.Z<25 and out.crossDrift<1,"moving dash displacement outside expected envelope")
  assert(v.Z>h.WalkSpeed*.65 and v.Z<h.WalkSpeed+3,"normal held locomotion did not resume")
  out.passed=true
 end,debug.traceback)
 moving=false;h:Move(Vector3.zero,false);Run:UnbindFromRenderStep(bind);echo:Disconnect()
 assert(ok,problem);return out
end
