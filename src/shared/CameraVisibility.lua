-- Read-only camera geometry. Server validates receipts and still owns every attack/hit.
local View={MaximumDistance=40,MinimumFov=40,MaximumFov=100,MinimumAspect=.4,MaximumAspect=4}
local function finite(n)return type(n)=="number" and n==n and math.abs(n)<math.huge end
function View.Validate(frame,fov,aspect,subject)
    if typeof(frame)~="CFrame" or typeof(subject)~="Vector3" then return false end
    if not finite(fov) or fov<View.MinimumFov or fov>View.MaximumFov
        or not finite(aspect) or aspect<View.MinimumAspect or aspect>View.MaximumAspect then return false end
    for _,n in ipairs({frame:GetComponents()})do if not finite(n)then return false end end
    for _,n in ipairs({subject.X,subject.Y,subject.Z})do if not finite(n)then return false end end
    local right,up,back=frame.RightVector,frame.UpVector,-frame.LookVector
    if math.abs(right.Magnitude-1)>.002 or math.abs(up.Magnitude-1)>.002 or math.abs(back.Magnitude-1)>.002
        or math.abs(right:Dot(up))>.002 or math.abs(right:Dot(back))>.002 or math.abs(up:Dot(back))>.002
        or right:Cross(up):Dot(back)<.998 then return false end
    return (frame.Position-subject).Magnitude<=View.MaximumDistance and View.Contains(subject,frame,fov,aspect,0)
end
function View.Contains(position,frame,fov,aspect,margin)
    local p=frame:PointToObjectSpace(position);local depth=-p.Z
    if depth<=0 then return false end
    local halfHeight=depth*math.tan(math.rad(fov/2));margin=margin or 0
    return math.abs(p.X)+margin<=halfHeight*aspect and math.abs(p.Y)+margin<=halfHeight
end
return View
