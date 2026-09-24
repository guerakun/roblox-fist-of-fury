-- Server-only profile math; all final warnings retain the fairness floor.
local Policy={}
function Policy.Windup(base,profile,heatScale)
    return math.max(.30,base*(profile.WindupScale or 1)*(heatScale or 1))
end
function Policy.Cooldown(base,profile)
    return base/math.max(.1,profile.Aggression or 1)
end
function Policy.Evade(data,profile)
    -- Deterministic quota preserves Normal's every-third-heavy behavior.
    data.evadeQuota=(data.evadeQuota or 0)+math.clamp(profile.EvadeChance or 1/3,0,1)
    if data.evadeQuota>=1-1e-8 then data.evadeQuota=math.max(0,data.evadeQuota-1);return true end
    return false
end
function Policy.ValidOptions(profiles,difficulty,heat)
    if type(difficulty)~="string" or not profiles[difficulty] then return false end
    -- Heat is deliberately unavailable until its server-owned M3 contract lands.
    return heat==nil or (type(heat)=="table" and next(heat)==nil)
end
return Policy
