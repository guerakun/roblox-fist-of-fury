-- Studio-only observation. Does not grant attack permissions or alter combat/camera state.
local RunService=game:GetService("RunService")
if not RunService:IsStudio() then return end
local Players=game:GetService("Players")
local Http=game:GetService("HttpService")
local player=Players.LocalPlayer
local fx=game.ReplicatedStorage:WaitForChild("Nightfall"):WaitForChild("Remotes"):WaitForChild("FX")
local report={schema=1,measurement="attacker position projected through victim camera at Hit receipt",hits=0,invalidViewportHits=0,outside=0,events={},fixture=false}
local function publish()player:SetAttribute("EnemyFrustumAudit",Http:JSONEncode(report))end
local function project(camera,position)
    local point,onScreen=camera:WorldToViewportPoint(position)
    return onScreen and point.Z>0,point
end
local function fixture(camera)
    local size=camera.ViewportSize
    if size.X<2 or size.Y<2 then return false end
    local inRay=camera:ViewportPointToRay(size.X*.5,size.Y*.5)
    local outRay=camera:ViewportPointToRay(size.X*1.25,size.Y*.5)
    local inside=project(camera,inRay.Origin+inRay.Direction*30)
    local outside=project(camera,outRay.Origin+outRay.Direction*30)
    report.fixture={inside=inside,outside=outside,passed=inside and not outside,width=size.X,height=size.Y}
    return true
end
task.spawn(function()
    local deadline=os.clock()+15
    repeat
        local camera=workspace.CurrentCamera
        if camera then fixture(camera)end
        if report.fixture then publish()return end
        task.wait(.1)
    until os.clock()>deadline
end)
publish()
fx.OnClientEvent:Connect(function(event)
    if event.kind~="Hit" or event.enemyHit~=true or event.targetUserId~=player.UserId or typeof(event.sourcePosition)~="Vector3" then return end
    local current=workspace.CurrentCamera
    if not current then return end
    if not fixture(current)then report.invalidViewportHits+=1 publish()return end
    local visible,point=project(current,event.sourcePosition)
    report.hits+=1
    if not visible then report.outside+=1 end
    if #report.events<1000 then table.insert(report.events,{visible=visible,width=current.ViewportSize.X,height=current.ViewportSize.Y,x=point.X,y=point.Y,depth=point.Z,serverTime=event.serverTime,received=workspace:GetServerTimeNow()})end
    publish()
end)
