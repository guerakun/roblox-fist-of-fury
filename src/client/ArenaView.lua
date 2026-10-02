-- Camera-relative input only. Roblox CameraModule owns camera motion; server owns hits/bounds.
local View={}
function View.Basis(frame)
    frame=frame or CFrame.identity
    local look=Vector3.new(frame.LookVector.X,0,frame.LookVector.Z)
    local right=Vector3.new(frame.RightVector.X,0,frame.RightVector.Z)
    if look.Magnitude>.001 then
        look=look.Unit;right=Vector3.new(-look.Z,0,look.X)
    elseif right.Magnitude>.001 then
        right=right.Unit;look=Vector3.new(right.Z,0,-right.X)
    else look=-Vector3.zAxis;right=Vector3.xAxis end
    return look,right
end
function View.Movement(input,position,bounds,previousFacing,cameraFrame)
    local look,right=View.Basis(cameraFrame)
    local raw=right*input.X-look*input.Y
    if raw.Magnitude>1 then raw=raw.Unit end
    local facing=raw.Magnitude>.1 and raw.Unit or previousFacing
    local x,z=raw.X,raw.Z
    if x<0 and position.X<=bounds.MinX+.4 or x>0 and position.X>=bounds.MaxX-.4 then x=0 end
    if z<0 and position.Z<=bounds.MinZ+.4 or z>0 and position.Z>=bounds.MaxZ-.4 then z=0 end
    return Vector3.new(x,0,z),facing
end
return View
