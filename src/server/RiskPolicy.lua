-- Pure risk-action decisions; no client data is trusted by this module's callers.
local Risk={}
Risk.DesperationCost=12
Risk.DesperationCooldown=4
Risk.PerfectWindow=.12
Risk.PerfectRearm=.35
Risk.PerfectStagger=.6
Risk.BountyOpportunity=8
Risk.BountyFleeLimit=6
Risk.ScoreOrbLifetime=5
function Risk.Desperation(t,state)
    if not state.alive or state.downed or state.respawning or state.grabbed or state.travelLocked
        or state.status~="Combat"or t<(state.stunnedUntil or 0)or t<(state.busyUntil or 0)
        or t<(state.desperationReadyAt or 0)or t>=(state.specialReadyAt or 0)then return false end
    return true
end
function Risk.PayPercent(percent,cost,limit)
    local nextPercent=math.min(999,percent+cost)
    return nextPercent,nextPercent>=limit
end
function Risk.PerfectBlock(t,startedAt,blocked,unblockable,alreadyConsumed)
    return blocked==true and unblockable~=true and alreadyConsumed~=true and type(startedAt)=="number"
        and t>=startedAt and t-startedAt<=Risk.PerfectWindow
end
function Risk.ArmPerfect(t,lastPressedAt)
    -- Every fresh press restarts the rest period, including presses too early to parry.
    return lastPressedAt==nil or t-lastPressedAt>=Risk.PerfectRearm
end
function Risk.BountyPhase(t,spawnedAt,atEdge)
    local elapsed=t-spawnedAt
    if elapsed<Risk.BountyOpportunity then return "Opportunity"end
    if atEdge or elapsed>=Risk.BountyOpportunity+Risk.BountyFleeLimit then return "Escaped"end
    return "Flee"
end
function Risk.BountySelected(campaignId,stage,wave)
    local key=tostring(campaignId)..":"..stage..":"..wave
    local hash=5381
    for i=1,#key do hash=(hash*33+string.byte(key,i))%2147483647 end
    -- Final bounded integer mixing separates adjacent wave suffixes without rerolling retries.
    hash=bit32.bxor(hash,bit32.rshift(hash,16))
    hash=(hash*48271)%2147483647
    return hash%100<25
end
return Risk
