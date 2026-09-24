-- Shared projection math for conservative server attack permission and test-only viewport audits.
-- Client viewports are never authoritative. Supported geometry assumes aspect >= 9:16.
local Bounds={Fov=44,MinimumAspect=9/16,Margin=4}
local tanHalf=math.tan(math.rad(Bounds.Fov/2))
function Bounds.Frame(center,distance)
    return CFrame.lookAt(center+Vector3.new(0,distance*.37,distance),center)
end
function Bounds.Distance(span,aspect)
    return math.clamp((span+54)/(2*tanHalf*aspect),52,140)
end
function Bounds.InFrame(position,frame,distance,aspect,margin)
    local p=frame:PointToObjectSpace(position)
    local depth=-p.Z
    if depth<=0 then return false end
    local halfY=depth*tanHalf
    margin=margin or 0
    return math.abs(p.X)+margin<=halfY*aspect and math.abs(p.Y)+margin<=halfY
end
function Bounds.Party(positions,stageMin)
    if #positions==0 then return nil end
    local lo,hi=positions[1].X,positions[1].X
    for _,position in ipairs(positions)do lo=math.min(lo,position.X);hi=math.max(hi,position.X)end
    return Vector3.new(math.clamp((lo+hi)/2,stageMin+38,stageMin+142),5,0),hi-lo
end
function Bounds.Visible(position,center,span)
    if not center then return false end
    -- Check the portrait minimum, square, and landscape clamp crossover.
    -- Together these bound the horizontal/vertical minima of this camera formula.
    local crossover=(span+54)/(2*tanHalf*52)
    for _,aspect in ipairs({Bounds.MinimumAspect,1,math.max(1,crossover),16/9})do
        local distance=Bounds.Distance(span,aspect)
        if not Bounds.InFrame(position,Bounds.Frame(center,distance),distance,aspect,Bounds.Margin)then return false end
    end
    return true
end
-- Return the nearest horizontal walking point accepted by BOTH existing camera envelopes.
-- This guides movement only; Visible remains the independent authority for attacks and hits.
function Bounds.SafePosition(position,center,span,goal,goalSpan,arena)
    if not center or not goal then return nil end
    local z=math.clamp(position.Z,-11,11)
    local low,high=arena.MinX+6,arena.MaxX-6
    for _,sample in ipairs({{center,span},{goal,goalSpan}})do
        local focus,width=sample[1],sample[2] or 0
        local crossover=(width+54)/(2*tanHalf*52)
        for _,aspect in ipairs({Bounds.MinimumAspect,1,math.max(1,crossover),16/9})do
            local distance=Bounds.Distance(width,aspect)
            local projected=Bounds.Frame(focus,distance):PointToObjectSpace(Vector3.new(focus.X,position.Y,z))
            local depth=-projected.Z;local halfY=depth*tanHalf
            if depth<=0 or math.abs(projected.Y)+Bounds.Margin>halfY then return nil end
            local halfX=halfY*aspect-Bounds.Margin-.5
            low=math.max(low,focus.X-halfX);high=math.min(high,focus.X+halfX)
        end
    end
    if low>high then return nil end
    return Vector3.new(math.clamp(position.X,low,high),position.Y,z)
end
return Bounds
