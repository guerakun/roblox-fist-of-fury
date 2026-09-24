-- Studio-only automated action driver; never included in the published project tree.
-- Uses ordinary movement, jumps and validated Action requests. Never teleports or forces damage/KO.
local Players=game:GetService("Players")
local RunService=game:GetService("RunService")
local HttpService=game:GetService("HttpService")
local p=Players.LocalPlayer
local R=game.ReplicatedStorage.Nightfall.Remotes
local config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
local state={status="Waiting",stage=1,wave=0,cooldowns={}}
local hazards={}
local start=os.clock()
local frames,totalDt,maxDt=0,0,0
local lastAction,lastJump,lastReport,lastReady=0,0,0,0
local transitions={}
local previous=""
local connection
R.State.OnClientEvent:Connect(function(packet)if packet.kind=="Snapshot" then state=packet end end)
R.FX.OnClientEvent:Connect(function(packet)
 if packet.kind=="Telegraph" and typeof(packet.position)=="Vector3" and packet.size then
  table.insert(hazards,{position=packet.position,size=packet.size,radius=packet.radius,shape=packet.shape,jumpable=packet.jumpable,finish=os.clock()+(packet.duration or 1),owner=packet.targetModel})
 elseif packet.kind=="BossStagger" then
  for i=#hazards,1,-1 do if hazards[i].owner==packet.targetModel then table.remove(hazards,i)end end
 end
end)
local function inside(h,pos,margin)
 local dx,dz=pos.X-h.position.X,pos.Z-h.position.Z
 if h.shape=="Circle" then return dx*dx+dz*dz<((h.radius or h.size.X/2)+margin)^2 end
 return math.abs(dx)<h.size.X/2+margin and math.abs(dz)<h.size.Z/2+margin
end
local function report(done)
 p:SetAttribute("AutoplayReport",HttpService:JSONEncode({done=done or false,elapsed=os.clock()-start,status=state.status,stage=state.stage,wave=state.wave,stocks=state.stocks,percent=state.percent,frames=frames,meanDt=frames>0 and totalDt/frames or 0,maxDt=maxDt,runStats=state.runStats,transitions=transitions}))
end
RunService:BindToRenderStep("AutoplayQA",Enum.RenderPriority.Last.Value+50,function(dt)
 local t=os.clock()
 frames+=1;totalDt+=dt;maxDt=math.max(maxDt,dt)
 local key=tostring(state.stage)..":"..tostring(state.wave)..":"..state.status
 if key~=previous then table.insert(transitions,{at=math.floor(t-start),state=key});previous=key end
 if state.status=="Victory" or t-start>1200 then
  report(true);RunService:UnbindFromRenderStep("AutoplayQA");return
 end
 if t-lastReport>1 then lastReport=t;report(false)end
 local model=p.Character
 local r=model and model:FindFirstChild("HumanoidRootPart")
 local h=model and model:FindFirstChildOfClass("Humanoid")
 if not r or not h then return end
 if state.status=="Waiting" and t-lastReady>2 then lastReady=t;R.Action:FireServer("Ready",{ready=true});return end
 if state.status=="Defeat" and t-lastReady>3 then lastReady=t;R.Action:FireServer("Restart",{});return end
 local movement=Vector3.zero
 if state.status=="Traverse" or state.status=="Advance" then
  local targetX=state.targetX or ((state.stage or 1)*180-8)
  movement=Vector3.new(targetX-r.Position.X+1,0,-r.Position.Z*.3)
 elseif state.status=="Combat" and not state.downed then
  local nearest,dist
  for _,enemy in ipairs(workspace.Enemies:GetChildren())do
   local er=enemy:FindFirstChild("HumanoidRootPart")
   if er then local d=(er.Position-r.Position).Magnitude;if not dist or d<dist then nearest,dist=er,d end end
  end
  if nearest then
   local delta=nearest.Position-r.Position
   local direction=delta.X>=0 and 1 or -1
   local xmove=math.abs(delta.X)>4 and delta.X-direction*3.5 or 0
   movement=Vector3.new(xmove,0,delta.Z)
   local danger
   for i=#hazards,1,-1 do
    local hazard=hazards[i]
    if t>hazard.finish+.1 then table.remove(hazards,i)
    elseif inside(hazard,r.Position,.8) then danger=hazard end
   end
   if danger then
    if danger.jumpable and danger.finish-t<.43 and t-lastJump>.7 and h.FloorMaterial~=Enum.Material.Air then
     lastJump=t;h.Jump=true;h:ChangeState(Enum.HumanoidStateType.Jumping)
    elseif not danger.jumpable then
     local candidates={}
     for _,z in ipairs({-12,0,12})do
      for _,x in ipairs({r.Position.X,math.max((state.stage-1)*180+5,r.Position.X-16),math.min(state.walkingMaxX or state.stage*180-4,r.Position.X+16)})do
       local point=Vector3.new(x,r.Position.Y,z);local safe=true
       for _,hazard in ipairs(hazards)do if hazard.finish>t and not hazard.jumpable and inside(hazard,point,1)then safe=false;break end end
       if safe then table.insert(candidates,point)end
      end
     end
     table.sort(candidates,function(a,b)return(a-r.Position).Magnitude<(b-r.Position).Magnitude end)
     if candidates[1]then movement=candidates[1]-r.Position end
    end
   end
   if t-lastAction>.16 and (not danger or danger.jumpable) then
    lastAction=t
    local serverNow=workspace:GetServerTimeNow()
    local hero=config.Characters[state.hero or "Naruto"]
    if serverNow>=(state.cooldowns.Special or 0) and math.abs(delta.X)<hero.Special.Range-1 and math.abs(delta.Z)<hero.Special.Width/2 then
     R.Action:FireServer("Special",{direction=direction})
    elseif math.abs(delta.X)<8 and math.abs(delta.Z)<3 then
     if math.floor((t-start)*5)%5==0 then R.Action:FireServer("Heavy",{direction=direction})else R.Action:FireServer("Light",{direction=direction})end
    end
   end
  end
 end
 movement=Vector3.new(movement.X,0,movement.Z)
 if movement.Magnitude>1 then movement=movement.Unit end
 h:Move(movement,false)
end)
