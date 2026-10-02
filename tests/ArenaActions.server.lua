-- Root-only fresh Studio Waiting fixture. Uses real Action remote with scripted directions.
-- Temporarily stages stationary enemies/player; not a difficulty, hardware or movement-origin security test.
if not game:GetService("RunService"):IsStudio()then return end
local C=require(game.ServerScriptService.NightfallServer.CombatService)
local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
local p=game.Players:GetPlayers()[1]
assert(p and C.GetRunStatus()=="Waiting","fresh Waiting session required")
local out={passed=false,cases={},scriptedInput=true,hardwareInputVerified=false}
local value=Instance.new("StringValue");value.Name="ArenaActionsResult";value.Parent=game.ServerStorage
local driver=game.ServerStorage:WaitForChild("ArenaActionDriver"):Clone()
local ok,problem=xpcall(function()
 C.BeginRun("studio-arena-actions");C.SetArena(Config.Stages[1],1);C.ResetPlayers(Vector3.new(26,4,0))
 C.BeginEncounter();C.SetEncounterState({status="Combat",wave=1,encounterKind="Wave"})
 workspace:SetAttribute("ArenaActionCase",0)
 driver.Parent=p:WaitForChild("PlayerGui");task.wait(.3)
 for i,f in ipairs({Vector3.xAxis,-Vector3.xAxis,Vector3.zAxis,-Vector3.zAxis,Vector3.new(1,0,1).Unit})do
  C.ClearEnemies();local origin=p.Character.HumanoidRootPart.Position
  local right=Vector3.new(-f.Z,0,f.X)
  local targets={}
  for name,offset in pairs({front=f*5,rear=-f*5,side=f*3+right*7})do
   local m=C.SpawnEnemy("Husk",Vector3.new(origin.X,0,origin.Z)+offset,1)
   local d=C.GetEnemies()[m];d.stunnedUntil=workspace:GetServerTimeNow()+20
   m.HumanoidRootPart.Anchored=true;targets[name]=m
  end
  workspace:SetAttribute("ArenaActionDirection",f);workspace:SetAttribute("ArenaActionName","Light");workspace:SetAttribute("ArenaActionCase",i)
  task.wait(.55)
  local front=targets.front:GetAttribute("Percent")or 0
  local rear=targets.rear:GetAttribute("Percent")or 0
  local side=targets.side:GetAttribute("Percent")or 0
  assert(front>0 and rear==0 and side==0,"oriented actual hitbox mismatch case"..i)
  table.insert(out.cases,{direction={f.X,f.Y,f.Z},frontDamage=front,rearDamage=rear,sideDamage=side})
 end
 C.ClearEnemies();C.ResetPlayers(Vector3.new(26,4,0));task.wait(.1)
 local r=p.Character.HumanoidRootPart;local start=r.Position
 out.dashCooldownBefore=C.GetSnapshot(p).cooldowns.Dash;out.dashSamples={}
 workspace:SetAttribute("ArenaActionDirection",Vector3.zAxis);workspace:SetAttribute("ArenaActionName","Dash");workspace:SetAttribute("ArenaActionCase",6)
 local deadline=os.clock()+.6
 repeat task.wait(.03);local v=r.AssemblyLinearVelocity;table.insert(out.dashSamples,{z=r.Position.Z-start.Z,vz=v.Z})until os.clock()>=deadline
 out.dashCooldownAfter=C.GetSnapshot(p).cooldowns.Dash
 local delta=r.Position-start;out.dashDelta={delta.X,delta.Y,delta.Z};assert(delta.Z>2 and math.abs(delta.X)<1,"depth dash failed")
 out.passed=true
end,debug.traceback)
if not ok then out.error=problem end
driver:Destroy();C.ClearEnemies();C.ResetLobby();C.SetEncounterState({status="Waiting",wave=0,enemiesRemaining=0});value.Value=game:GetService("HttpService"):JSONEncode(out)
