-- Pure accepted-hit and Burst decisions. Callers own eligibility and life identity.
local Policy={}
function Policy.HitProtection(history,t,settings)
    local recent={}
    for _,at in ipairs(history or {})do
        if at<=t and t-at<=settings.ComboWindow then table.insert(recent,at)end
    end
    table.insert(recent,t)
    if #recent>=settings.ComboHits then return settings.ComboInvulnerability,{},true end
    return settings.HitInvulnerability,recent,false
end
function Policy.Burst(t,stunnedUntil,hitAt,readyAt,settings)
    if t>=stunnedUntil then return true,0 end
    if t-(hitAt or t)<settings.BurstDelay or t<(readyAt or 0)then return false,0 end
    return true,settings.BurstCost
end
return Policy
