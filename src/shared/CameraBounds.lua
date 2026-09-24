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
return Bounds
