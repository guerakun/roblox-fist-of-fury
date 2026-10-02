-- Pure gate lifecycle check. Never change stocks, revive deadlines, or character positions.
local Policy={}
function Policy.CanSeal(records,bounds,t,positionOf)
    local waiting=0
    for actor,data in pairs(records)do
        if data.downed and t<(data.downedUntil or 0)then
            local position=positionOf(actor,data)
            if not position or position.X<bounds.MinX+2 or position.X>bounds.MaxX-2
                or position.Z<(bounds.MinZ or -24)+2 or position.Z>(bounds.MaxZ or 24)-2 then
                waiting+=1
            end
        end
    end
    return waiting==0,waiting
end
return Policy
