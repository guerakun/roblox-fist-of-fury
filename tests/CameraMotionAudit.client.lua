-- Studio-only passive observation. No camera, settings, movement, action or gameplay writes.
-- Only publishes bounded diagnostic JSON on the local Player every two seconds.
local RunService=game:GetService("RunService")
if not RunService:IsStudio()then return end
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local player=Players.LocalPlayer
local remotes=game.ReplicatedStorage:WaitForChild("Nightfall"):WaitForChild("Remotes")
local started=os.clock()
local alive=true
local binding="CameraMotionAudit_"..Http:GenerateGUID(false)
local connections={}
local function connect(signal,callback)table.insert(connections,signal:Connect(callback))end
local function finite(n)return type(n)=="number"and n==n and math.abs(n)<math.huge end
local function angle(a,b)return math.deg(math.atan2(a:Cross(b).Magnitude,math.clamp(a:Dot(b),-1,1)))end
local function histogram()return {count=0,sum=0,max=0,over50ms=0,over100ms=0,bins=table.create(101,0)}end
local function addDt(h,seconds)
    local ms=seconds*1000
    h.count+=1;h.sum+=ms;h.max=math.max(h.max,ms)
    local bin=math.min(101,math.max(1,math.ceil(ms)))h.bins[bin]+=1
    if ms>50 then h.over50ms+=1 end
    if ms>100 then h.over100ms+=1 end
end
local function percentile(h,fraction)
    if h.count==0 then return false end
    local target=math.ceil(h.count*fraction)local count=0
    for i,n in ipairs(h.bins)do count+=n if count>=target then return i==101 and h.max or i end end
    return false
end
local function summarizeDt(h)
    return {samples=h.count,meanMs=h.count>0 and h.sum/h.count or false,maxMs=h.max,
        p50UpperMs=percentile(h,.5),p95UpperMs=percentile(h,.95),p99UpperMs=percentile(h,.99),
        over50ms=h.over50ms,over100ms=h.over100ms,bins=h.bins}
end
local function motion()return {pairs=0,maxLookStepDeg=0,maxUpStepDeg=0,maxFocusStudStep=0,maxFocusPixelStep=0,
    maxFocusViewportFraction=0,maxZoomStudsPerSecond=0,minEyeFocusDistance=math.huge,maxEyeFocusDistance=0}end
local report={schema=1,measurement="Passive Camera+2 desktop render samples; not a nausea or physical-device certification",
    pixelMetric="Previous and current world-focus positions projected through the current camera; not literal frame-to-frame screen trajectory",
    quantiles="1ms histogram upper bounds; overflow bin uses observed maximum; 101 bins, final bin >100ms",
    impactPolicy="Quiet pairs exclude two seconds after nearby potential shake FX and lifecycle/viewport changes; settings are never read or altered",
    cameraFrames=0,invalidFrames=0,impactExcludedFrames=0,lifecycleExcludedFrames=0,
    lifecycle={characterChanges=0,cameraChanges=0,viewportChanges=0,stageChanges=0,statusChanges=0,downedChanges=0,stockChanges=0},
    statusFrames={},impactEvents={},lastLifecycle={},largestSteps={},
    hero={samples=0,missing=0,invalidProjection=0,rootOffscreen=0,corePartiallyOutside=0,minCoreHeightPixels=math.huge,maxCoreHeightPixels=0,
        minCoreBorderPixels=math.huge,measurement="Six R6 core-part corners projected at <=10Hz; excludes cosmetic attachments and occlusion"},
    maxLookDeviationFromFirstDeg=0,maxUpDeviationFromFirstDeg=0,physicalInputVerified=false,comfortVerified=false}
local dtAll,dtQuiet=histogram(),histogram()
local all,quiet=motion(),motion()
local status,stage,downed,stocks="Unknown",0,false,nil
local knownStatus={Waiting=true,Combat=true,Intermission=true,Traverse=true,Advance=true,Victory=true,Defeat=true}
local impactUntil,lifecycleUntil=0,started+2
local last,firstLook,firstUp=nil,nil,nil
local lastCharacter,lastCamera,lastViewport=player.Character,nil,nil
local nextHeroSample=0
local function lifecycle(name)
    report.lifecycle[name]+=1
    report.lastLifecycle[name]=os.clock()-started
    lifecycleUntil=os.clock()+2
end
connect(remotes.State.OnClientEvent,function(state)
    if type(state)~="table"or state.kind~="Snapshot"then return end
    if state.status~=nil then
        local nextStatus=knownStatus[state.status]and state.status or "Other"
        if nextStatus~=status then status=nextStatus;lifecycle("statusChanges")end
    end
    if type(state.stage)=="number"and state.stage~=stage then stage=state.stage;lifecycle("stageChanges")end
    if type(state.downed)=="boolean"and state.downed~=downed then downed=state.downed;lifecycle("downedChanges")end
    if type(state.stocks)=="number"and state.stocks~=stocks then stocks=state.stocks;lifecycle("stockChanges")end
end)
local shakeKinds={Hit=true,KO=true,Attack=true,Special=true,Dash=true,Recovery=true,EnemyImpact=true,BossPhase=true}
connect(remotes.FX.OnClientEvent,function(event)
    if type(event)~="table"or not shakeKinds[event.kind]then return end
    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    local nearby=event.kind=="BossPhase"
    if root and root:IsA("BasePart")and typeof(event.position)=="Vector3"then
        nearby=nearby or (root.Position-event.position).Magnitude<(event.kind=="EnemyImpact"and 35 or 65)
    end
    if nearby then
        impactUntil=os.clock()+2
        report.impactEvents[event.kind]=(report.impactEvents[event.kind]or 0)+1
    end
end)
local function updateMotion(m,camera,frame,focus,distance,dt)
    m.pairs+=1
    m.maxLookStepDeg=math.max(m.maxLookStepDeg,angle(last.frame.LookVector,frame.LookVector))
    m.maxUpStepDeg=math.max(m.maxUpStepDeg,angle(last.frame.UpVector,frame.UpVector))
    m.maxFocusStudStep=math.max(m.maxFocusStudStep,(focus-last.focus).Magnitude)
    m.maxZoomStudsPerSecond=math.max(m.maxZoomStudsPerSecond,math.abs(distance-last.distance)/dt)
    m.minEyeFocusDistance=math.min(m.minEyeFocusDistance,distance)
    m.maxEyeFocusDistance=math.max(m.maxEyeFocusDistance,distance)
    local before=camera:WorldToViewportPoint(last.focus)
    local after=camera:WorldToViewportPoint(focus)
    local pixels=0
    if before.Z>0 and after.Z>0 then
        pixels=(Vector2.new(before.X,before.Y)-Vector2.new(after.X,after.Y)).Magnitude
        m.maxFocusPixelStep=math.max(m.maxFocusPixelStep,pixels)
        m.maxFocusViewportFraction=math.max(m.maxFocusViewportFraction,pixels/math.max(1,camera.ViewportSize.Y))
    end
    return pixels
end
local coreNames={"Head","Torso","Right Arm","Left Arm","Right Leg","Left Leg"}
local function sampleHero(camera,character)
    local h=report.hero
    local root=character and character:FindFirstChild("HumanoidRootPart")
    if not root or not root:IsA("BasePart")then h.missing+=1 return end
    local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
    local valid=true
    for _,name in ipairs(coreNames)do
        local part=character:FindFirstChild(name)
        if not part or not part:IsA("BasePart")then valid=false break end
        for _,x in ipairs({-1,1})do for _,y in ipairs({-1,1})do for _,z in ipairs({-1,1})do
            local point=camera:WorldToViewportPoint(part.CFrame*Vector3.new(x*part.Size.X/2,y*part.Size.Y/2,z*part.Size.Z/2))
            if point.Z<=0 then valid=false end
            minX=math.min(minX,point.X);maxX=math.max(maxX,point.X);minY=math.min(minY,point.Y);maxY=math.max(maxY,point.Y)
        end end end
    end
    if not valid then h.invalidProjection+=1 return end
    h.samples+=1
    local point,onScreen=camera:WorldToViewportPoint(root.Position)
    if not onScreen or point.Z<=0 then h.rootOffscreen+=1 end
    local size=camera.ViewportSize
    local border=math.min(minX,minY,size.X-maxX,size.Y-maxY)
    if border<0 then h.corePartiallyOutside+=1 end
    h.minCoreBorderPixels=math.min(h.minCoreBorderPixels,border)
    h.minCoreHeightPixels=math.min(h.minCoreHeightPixels,maxY-minY)
    h.maxCoreHeightPixels=math.max(h.maxCoreHeightPixels,maxY-minY)
end
-- Deterministic arithmetic self-checks; these are not gameplay samples.
do
    local h=histogram()for _,ms in ipairs({10,20,30,40,120})do addDt(h,ms/1000)end
    report.fixture={passed=percentile(h,.5)==30 and percentile(h,.95)==120 and h.over50ms==1 and h.over100ms==1
        and angle(Vector3.xAxis,Vector3.xAxis)<1e-6 and math.abs(angle(Vector3.xAxis,Vector3.yAxis)-90)<1e-6,
        scope="Histogram boundaries and angular arithmetic only"}
end
RunService:BindToRenderStep(binding,Enum.RenderPriority.Camera.Value+2,function(dt)
    local now=os.clock()
    if not finite(dt)or dt<=0 then report.invalidFrames+=1;last=nil return end
    addDt(dtAll,dt)
    local camera=workspace.CurrentCamera
    local character=player.Character
    if character~=lastCharacter then lastCharacter=character;lifecycle("characterChanges")end
    if camera~=lastCamera then lastCamera=camera;last=nil;lifecycle("cameraChanges")end
    if not camera or camera.ViewportSize.X<2 or camera.ViewportSize.Y<2 then report.invalidFrames+=1;last=nil return end
    local viewport=camera.ViewportSize
    if lastViewport~=viewport then lastViewport=viewport;last=nil;lifecycle("viewportChanges")end
    local frame,focus=camera.CFrame,camera.Focus.Position
    local distance=(frame.Position-focus).Magnitude
    if not finite(distance)or distance<=0 then report.invalidFrames+=1;last=nil return end
    report.cameraFrames+=1
    report.statusFrames[status]=(report.statusFrames[status]or 0)+1
    report.viewport={width=viewport.X,height=viewport.Y}
    report.lastState={stage=stage,status=status,downed=downed,stocks=stocks or 0}
    firstLook=firstLook or frame.LookVector;firstUp=firstUp or frame.UpVector
    report.maxLookDeviationFromFirstDeg=math.max(report.maxLookDeviationFromFirstDeg,angle(firstLook,frame.LookVector))
    report.maxUpDeviationFromFirstDeg=math.max(report.maxUpDeviationFromFirstDeg,angle(firstUp,frame.UpVector))
    local impacted=now<impactUntil
    local transitioning=now<lifecycleUntil
    if impacted then report.impactExcludedFrames+=1 end
    if transitioning then report.lifecycleExcludedFrames+=1 end
    local isQuiet=not impacted and not transitioning
    if isQuiet then addDt(dtQuiet,dt)end
    if last then
        local pixels=updateMotion(all,camera,frame,focus,distance,dt)
        if isQuiet and last.quiet then updateMotion(quiet,camera,frame,focus,distance,dt)end
        if #report.largestSteps<8 or pixels>report.largestSteps[#report.largestSteps].pixels then
            table.insert(report.largestSteps,{seconds=now-started,pixels=pixels,studs=(focus-last.focus).Magnitude,
                stage=stage,status=status,impactExcluded=impacted,lifecycleExcluded=transitioning})
            table.sort(report.largestSteps,function(a,b)return a.pixels>b.pixels end)
            if #report.largestSteps>8 then table.remove(report.largestSteps)end
        end
    end
    last={frame=frame,focus=focus,distance=distance,quiet=isQuiet}
    if now>=nextHeroSample then nextHeroSample=now+.1;sampleHero(camera,character)end
end)
local function cleanMotion(m)
    local copy=table.clone(m)
    if copy.minEyeFocusDistance==math.huge then copy.minEyeFocusDistance=false end
    return copy
end
local function publish()
    local copy=table.clone(report)
    copy.elapsed=os.clock()-started;copy.dt=summarizeDt(dtAll);copy.quietDt=summarizeDt(dtQuiet)
    copy.allMotion=cleanMotion(all);copy.quietMotion=cleanMotion(quiet)
    copy.hero=table.clone(report.hero)
    if copy.hero.minCoreHeightPixels==math.huge then copy.hero.minCoreHeightPixels=false end
    if copy.hero.minCoreBorderPixels==math.huge then copy.hero.minCoreBorderPixels=false end
    player:SetAttribute("CameraMotionAudit",Http:JSONEncode(copy))
end
connect(script.Destroying,function()
    alive=false;RunService:UnbindFromRenderStep(binding)
    for _,connection in ipairs(connections)do connection:Disconnect()end
    publish()
end)
publish()
task.spawn(function()while alive do task.wait(2)if alive then publish()end end end)
