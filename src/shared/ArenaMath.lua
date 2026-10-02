-- Shared horizontal geometry. Character frames look forward; hitbox local X is forward.
local A={}
local function finite(n)return type(n)=="number" and n==n and math.abs(n)<math.huge end
function A.NormalizeDirection(value,fallback)
    if typeof(value)=="Vector3" and finite(value.X) and finite(value.Y) and finite(value.Z) then
        local v=Vector3.new(value.X,0,value.Z)
        local scale=math.max(math.abs(v.X),math.abs(v.Z))
        if scale>.001 then return (v/scale).Unit end
    elseif finite(value) and math.abs(value)>.1 then return value>0 and Vector3.xAxis or -Vector3.xAxis end
    if fallback~=nil then return A.NormalizeDirection(fallback)end
    return Vector3.xAxis
end
function A.Flat(v)return Vector3.new(v.X,0,v.Z)end
function A.Right(direction)local f=A.NormalizeDirection(direction);return Vector3.new(-f.Z,0,f.X)end
function A.FacingFrame(position,direction)return CFrame.lookAt(position,position+A.NormalizeDirection(direction))end
function A.BoxFrame(position,direction)
    local f=A.NormalizeDirection(direction)
    return CFrame.fromMatrix(position,f,Vector3.yAxis,A.Right(f))
end
function A.Clamp(position,bounds,inset)
    inset=inset or 2
    return Vector3.new(math.clamp(position.X,bounds.MinX+inset,bounds.MaxX-inset),position.Y,
        math.clamp(position.Z,(bounds.MinZ or -24)+inset,(bounds.MaxZ or 24)-inset))
end
function A.Bounds(bounds)return {MinX=bounds.MinX,MaxX=bounds.MaxX,MinZ=bounds.MinZ or -24,MaxZ=bounds.MaxZ or 24}end
function A.Union(a,b)return {MinX=math.min(a.MinX,b.MinX),MaxX=math.max(a.MaxX,b.MaxX),MinZ=math.min(a.MinZ,b.MinZ),MaxZ=math.max(a.MaxZ,b.MaxZ)}end
function A.Frontal(facing,incoming)return A.NormalizeDirection(facing):Dot(-A.NormalizeDirection(incoming))>=.5 end
function A.BoxContains(frame,size,position)
    local point=frame:PointToObjectSpace(position)
    return math.abs(point.X)<=size.X/2 and math.abs(point.Z)<=size.Z/2
end
return A
