-- Shared fixed-yaw arena camera and conservative server attack envelope.
-- Every supported viewport fits the complete active XZ rectangle, including actor height.
local Bounds={Fov=44,MinimumAspect=9/16,Margin=4,HeightRatio=.9,ArenaDepth=48}
local tanHalf=math.tan(math.rad(Bounds.Fov/2))
local offset=Vector3.new(0,Bounds.HeightRatio,1)
local rotation=CFrame.lookAt(Vector3.zero,-offset.Unit)
function Bounds.Frame(center,distance)
    return CFrame.lookAt(center+offset*distance,center)
end
-- Reduce the eight-corner fit to two constraints; no per-frame corner allocations.
local maxDepthOffset,verticalDistance=-math.huge,42
for _,y in ipairs({-5,12})do
    for _,z in ipairs({-Bounds.ArenaDepth/2,Bounds.ArenaDepth/2})do
        local p=rotation:VectorToObjectSpace(Vector3.new(0,y,z))
        maxDepthOffset=math.max(maxDepthOffset,p.Z)
        verticalDistance=math.max(verticalDistance,(p.Z+(math.abs(p.Y)+Bounds.Margin+2)/tanHalf)/offset.Magnitude)
    end
end
function Bounds.Distance(span,aspect)
    aspect=math.max(Bounds.MinimumAspect,aspect or 1)
    local halfX=math.max(0,span or 44)/2
    return math.max(42,verticalDistance,((halfX+Bounds.Margin+2)/(tanHalf*aspect)+maxDepthOffset)/offset.Magnitude)
end
function Bounds.InFrame(position,frame,distance,aspect,margin)
    local p=frame:PointToObjectSpace(position)
    local depth=-p.Z
    if depth<=0 then return false end
    local halfY=depth*tanHalf
    margin=margin or 0
    return math.abs(p.X)+margin<=halfY*aspect and math.abs(p.Y)+margin<=halfY
end
function Bounds.Party(positions,arena)
    if type(arena)=="table"then
        return Vector3.new((arena.MinX+arena.MaxX)/2,5,((arena.MinZ or -24)+(arena.MaxZ or 24))/2),arena.MaxX-arena.MinX
    end
    -- Legacy callers remain usable for preserved fixtures; production passes the active arena.
    if #positions==0 then return nil end
    local lo,hi=positions[1].X,positions[1].X
    for _,position in ipairs(positions)do lo=math.min(lo,position.X);hi=math.max(hi,position.X)end
    local stageMin=arena or 0
    return Vector3.new(math.clamp((lo+hi)/2,stageMin+26,stageMin+156),5,0),math.max(44,hi-lo)
end
function Bounds.Arena(arena,aspect)
    local center,span=Bounds.Party({},arena)
    return center,Bounds.Distance(span,aspect)
end
function Bounds.Visible(position,center,span)
    if not center then return false end
    -- Distance is the maximum of constant, horizontal-fit, and vertical-fit terms.
    -- At every aspect the complete arena is visible; these include narrow and wide extremes.
    for _,aspect in ipairs({Bounds.MinimumAspect,1,16/9,32/9})do
        local distance=Bounds.Distance(span,aspect)
        if not Bounds.InFrame(position,Bounds.Frame(center,distance),distance,aspect,Bounds.Margin)then return false end
    end
    return true
end
function Bounds.SafePosition(position,center,span,goal,goalSpan,arena)
    if not center or not goal then return nil end
    local candidate=Vector3.new(math.clamp(position.X,arena.MinX+2,arena.MaxX-2),position.Y,
        math.clamp(position.Z,(arena.MinZ or -24)+2,(arena.MaxZ or 24)-2))
    local function visible(p)return Bounds.Visible(p,center,span)and Bounds.Visible(p,goal,goalSpan)end
    if visible(candidate)then return candidate end
    -- During arena transitions the two frames may differ; move only to their overlap.
    local midpoint=Vector3.new((arena.MinX+arena.MaxX)/2,position.Y,((arena.MinZ or -24)+(arena.MaxZ or 24))/2)
    if not visible(midpoint)then return nil end
    local lo,hi=0,1
    for _=1,12 do local t=(lo+hi)/2;if visible(midpoint:Lerp(candidate,t))then lo=t else hi=t end end
    return midpoint:Lerp(candidate,lo)
end
return Bounds
