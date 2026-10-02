-- Server footprint interpretation shared by floor meshes and HUD warnings.
local ArenaMath=require(game.ReplicatedStorage.Nightfall.Shared.ArenaMath)
local Geometry={}
function Geometry.Point(origin,direction,x,y,z)
    local forward=ArenaMath.NormalizeDirection(direction,Vector3.xAxis)
    return origin+forward*x+Vector3.yAxis*y+ArenaMath.Right(forward)*z
end
function Geometry.Footprint(event)
    local radius=math.clamp(tonumber(event.radius)or 6,1,60)
    local position=event.position
    local direction=ArenaMath.NormalizeDirection(event.direction,Vector3.xAxis)
    if event.shape=="Circle"then
        return CFrame.new(position),Vector3.new(radius*2,.07,radius*2),radius
    end
    local size=event.size
    if typeof(size)~="Vector3"then
        position+=direction*(event.heavy and 0 or radius*.5)
        size=Vector3.new(event.heavy and radius*2 or radius,.07,event.heavy and 25 or 7)
    end
    local frame=typeof(event.cframe)=="CFrame"and event.cframe or ArenaMath.BoxFrame(position,direction)
    return frame,Vector3.new(math.max(.1,size.X),.07,math.max(.1,size.Z)),nil
end
function Geometry.Contains(event,position,margin)
    local frame,size,radius=Geometry.Footprint(event)
    margin=margin or 0
    local delta=frame:PointToObjectSpace(position)
    if radius then return Vector2.new(delta.X,delta.Z).Magnitude<=radius+margin end
    return math.abs(delta.X)<=size.X*.5+margin and math.abs(delta.Z)<=size.Z*.5+margin
end
return Geometry
