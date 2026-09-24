-- Pure spawn budgeting. A wave freezes its party size before any entrance is spawned.
local Planner={}
function Planner.Plan(wave,partySize)
    local kinds,flat={},{}
    for kind in pairs(wave.Enemies)do table.insert(kinds,kind)end
    table.sort(kinds)
    for _,kind in ipairs(kinds)do
        local count=wave.Enemies[kind]+(wave.Kind=="Wave" and math.floor((partySize-1)*.5) or 0)
        for _=1,count do table.insert(flat,kind)end
    end
    local count=wave.Kind=="Wave" and (#flat>=6 and 3 or math.min(2,#flat)) or 1
    local pulses={}
    for i=1,count do pulses[i]={}end
    local entries=wave.Entries or {"Left","Right","Door","Drop"}
    for i,kind in ipairs(flat)do
        local pulse=math.min(count,math.floor((i-1)*count/#flat)+1)
        local entry=wave.Kind~="Wave" and "Door" or entries[(i-1)%#entries+1]
        -- One rear arrival for small parties. Boss waves receive their rear arrival at phase two.
        if wave.Kind=="Wave" and partySize<=2 and i==1 then entry="Left"end
        table.insert(pulses[pulse],{kind=kind,entry=entry,index=i,rear=partySize<=2 and entry=="Left"})
    end
    return pulses,#flat
end
function Planner.ShouldSpawn(alive,elapsed,settings)
    settings=settings or {}
    return alive<=(settings.AliveThreshold or 1) or elapsed>=(settings.After or 12)
end
return Planner
