-- Client input/camera interpolation only. Server retains position/hit authority.
local View={}
function View.Movement(input,position,bounds,previousFacing)
    local raw=Vector3.new(input.X,0,input.Y)
    if raw.Magnitude>1 then raw=raw.Unit end
    local facing=raw.Magnitude>.1 and raw.Unit or previousFacing
    local x,z=raw.X,raw.Z
    if x<0 and position.X<=bounds.MinX+.4 or x>0 and position.X>=bounds.MaxX-.4 then x=0 end
    if z<0 and position.Z<=bounds.MinZ+.4 or z>0 and position.Z>=bounds.MaxZ-.4 then z=0 end
    return Vector3.new(x,0,z),facing
end
function View.CameraStep(center,distance,target,targetDistance,dt)
    if not center then return target,targetDistance end
    local alpha=1-math.exp(-6*math.max(0,dt))
    return center:Lerp(target,alpha),distance+(targetDistance-distance)*alpha
end
return View
