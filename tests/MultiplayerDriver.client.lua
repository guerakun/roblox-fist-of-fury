-- TEST ONLY: temporarily install in StarterPlayerScripts, outside the Rojo tree.
-- Uses normal Humanoid movement/jump and the same validated Action remote as players.
-- Never sets CFrame/health/percent/stocks or invokes server combat internals.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() or not RunService:IsClient() then return end
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local player=Players.LocalPlayer
local qa=ReplicatedStorage:WaitForChild("NightfallCampaignQA",80)
if not qa or qa:GetAttribute("TestName")~="NightfallMultiplayerCampaign" then return end
local remotes=ReplicatedStorage:WaitForChild("Nightfall"):WaitForChild("Remotes")
local Config=require(ReplicatedStorage.Nightfall.Shared.Config)
local state={status="Waiting",stage=1,wave=0,cooldowns={}}
local began=os.clock()
local enabled,configured,readyRequested,lateReleased,stopped=false,false,false,false,false
local slot,desiredHero=0,nil
local hazards,transitions,actionCounts={},{},{}
local frames,totalDt,maxDt,longFrames=0,0,0,0
local lastAction,lastJump,lastReport,lastReady,lastSelect,lastHello=0,0,0,0,0,0
local previous=""
local function send(action,payload)
    actionCounts[action]=(actionCounts[action] or 0)+1
    remotes.Action:FireServer(action,payload)
end
local function report()
    qa:FireServer("Report",{slot=slot,elapsed=os.clock()-began,status=state.status,stage=state.stage,wave=state.wave,
        stocks=state.stocks,percent=state.percent,hero=state.hero,frames=frames,meanDt=frames>0 and totalDt/frames or 0,
        maxDt=maxDt,framesOver50ms=longFrames,runStats=state.runStats,actionRequests=actionCounts,transitions=transitions,
        controlledInputsOnly=true})
end
qa.OnClientEvent:Connect(function(packet)
    if type(packet)~="table" then return end
    if packet.kind=="Setup" then
        slot,desiredHero=packet.slot,packet.hero
        configured=true
    elseif packet.kind=="Ready" then readyRequested=true
    elseif packet.kind=="Drive" then enabled=packet.enabled==true
    elseif packet.kind=="ReleaseLateJoin" then lateReleased=true
    elseif packet.kind=="ReportNow" then report()
    elseif packet.kind=="Stop" then
        report();stopped=true;RunService:UnbindFromRenderStep("MultiplayerCampaignQA")
        local humanoid=player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:Move(Vector3.zero,false) end
    elseif packet.kind=="Leave" then
        -- Optional manual lifecycle probe; the default campaign retains all four clients.
        report()
        local service=game:GetService("StudioTestService")
        local ok,allowed=pcall(function()return service:CanLeaveTest()end)
        if ok and allowed then service:LeaveTest() end
    end
end)
remotes.State.OnClientEvent:Connect(function(packet)
    if type(packet)=="table" and packet.kind=="Snapshot" then state=packet end
end)
remotes.FX.OnClientEvent:Connect(function(packet)
    if packet.kind=="Telegraph" and typeof(packet.position)=="Vector3" and typeof(packet.size)=="Vector3" then
        table.insert(hazards,{position=packet.position,size=packet.size,radius=packet.radius,shape=packet.shape,
            jumpable=packet.jumpable,finish=os.clock()+(packet.duration or 1),owner=packet.targetModel})
    elseif packet.kind=="BossStagger" then
        for i=#hazards,1,-1 do if hazards[i].owner==packet.targetModel then table.remove(hazards,i) end end
    end
end)
local function inside(hazard,position,margin)
    local dx,dz=position.X-hazard.position.X,position.Z-hazard.position.Z
    if hazard.shape=="Circle" then return dx*dx+dz*dz<((hazard.radius or hazard.size.X/2)+margin)^2 end
    return math.abs(dx)<hazard.size.X/2+margin and math.abs(dz)<hazard.size.Z/2+margin
end
local function step(dt)
    if stopped then return end
    local t=os.clock()
    frames+=1;totalDt+=dt;maxDt=math.max(maxDt,dt)
    if dt>.05 then longFrames+=1 end
    if not configured and t-lastHello>1 then lastHello=t;qa:FireServer("Hello") end
    if t-lastReport>1 then lastReport=t;report() end
    local key=tostring(state.stage)..":"..tostring(state.wave)..":"..state.status
    if previous~=key then
        if #transitions<160 then table.insert(transitions,{at=t-began,state=key}) end
        previous=key
    end
    local model=player.Character
    local root=model and model:FindFirstChild("HumanoidRootPart")
    local humanoid=model and model:FindFirstChildOfClass("Humanoid")
    if not root or not humanoid then return end
    if desiredHero and state.hero~=desiredHero and state.status=="Waiting" and t-lastSelect>1.2 then
        lastSelect=t;send("SelectCharacter",{hero=desiredHero})
    end
    if readyRequested and state.status=="Waiting" and not state.ready and t-lastReady>.75 then
        lastReady=t;send("Ready",{ready=true})
    end
    local movement=Vector3.zero
    if enabled and (state.status=="Traverse" or state.status=="Advance") and not state.downed then
        local targetX=state.targetX or ((state.stage or 1)*180-8)
        movement=Vector3.new(targetX-root.Position.X+1,0,-root.Position.Z*.3)
    elseif enabled and state.status=="Combat" and not state.downed then
        local nearest,distance
        local enemies=workspace:FindFirstChild("Enemies")
        if enemies then
            for _,enemy in ipairs(enemies:GetChildren()) do
                local er=enemy:FindFirstChild("HumanoidRootPart")
                if er then
                    local d=(er.Position-root.Position).Magnitude
                    if not distance or d<distance then nearest,distance=er,d end
                end
            end
        end
        if nearest then
            local delta=nearest.Position-root.Position
            local direction=delta.X>=0 and 1 or -1
            local xmove=math.abs(delta.X)>4 and delta.X-direction*3.5 or 0
            movement=Vector3.new(xmove,0,delta.Z)
            local holdForJoin=state.stage==1 and state.wave==2 and not lateReleased
            local danger
            for i=#hazards,1,-1 do
                local hazard=hazards[i]
                if t>hazard.finish+.1 then table.remove(hazards,i)
                elseif inside(hazard,root.Position,.8) and (not danger or hazard.finish<danger.finish) then danger=hazard end
            end
            if holdForJoin then
                -- Kite normally while the server observes late-join threshold invariance.
                local targetX=nearest.Position.X+(root.Position.X>=nearest.Position.X and 22 or -22)
                local maxX=state.walkingMaxX or state.stage*180-4
                targetX=math.clamp(targetX,(state.stage-1)*180+5,maxX-2)
                local targetZ=(slot%2==0 and 11 or -11)
                movement=Vector3.new(targetX-root.Position.X,0,targetZ-root.Position.Z)
            end
            if danger then
                if danger.jumpable and danger.finish-t<.43 and t-lastJump>.7 and humanoid.FloorMaterial~=Enum.Material.Air then
                    lastJump=t
                    -- Same normal character jump pathway as the existing autoplay driver.
                    humanoid.Jump=true;humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                elseif not danger.jumpable then
                    local candidates={}
                    for _,z in ipairs({-12,0,12}) do
                        for _,x in ipairs({root.Position.X,math.max((state.stage-1)*180+5,root.Position.X-16),math.min(state.walkingMaxX or state.stage*180-4,root.Position.X+16)}) do
                            local point=Vector3.new(x,root.Position.Y,z)
                            local safe=true
                            for _,hazard in ipairs(hazards) do
                                if hazard.finish>t and not hazard.jumpable and inside(hazard,point,1) then safe=false;break end
                            end
                            if safe then table.insert(candidates,point) end
                        end
                    end
                    table.sort(candidates,function(a,b)return(a-root.Position).Magnitude<(b-root.Position).Magnitude end)
                    if candidates[1] then movement=candidates[1]-root.Position end
                end
            end
            if not holdForJoin and t-lastAction>.17 and (not danger or danger.jumpable) then
                lastAction=t
                local hero=Config.Characters[state.hero or "Naruto"]
                local cooldowns=state.cooldowns or {}
                if workspace:GetServerTimeNow()>=(cooldowns.Special or 0) and math.abs(delta.X)<hero.Special.Range-1 and math.abs(delta.Z)<hero.Special.Width/2 then
                    send("Special",{direction=direction})
                elseif math.abs(delta.X)<8 and math.abs(delta.Z)<3 then
                    send(math.floor((t-began)*5+slot)%5==0 and "Heavy" or "Light",{direction=direction})
                end
            end
        end
    end
    movement=Vector3.new(movement.X,0,movement.Z)
    if movement.Magnitude>1 then movement=movement.Unit end
    humanoid:Move(movement,false)
end
RunService:BindToRenderStep("MultiplayerCampaignQA",Enum.RenderPriority.Last.Value+50,function(dt)
    local ok,err=xpcall(function()step(dt)end,debug.traceback)
    if not ok then
        stopped=true
        RunService:UnbindFromRenderStep("MultiplayerCampaignQA")
        qa:FireServer("DriverError",tostring(err))
    end
end)
qa:FireServer("Hello")
