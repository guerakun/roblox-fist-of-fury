-- Server-only profile math; all final warnings retain the fairness floor.
local Policy={}
local Heat=require(game.ReplicatedStorage.Nightfall.Shared.HeatConfig)
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
    local normalized=Heat.Normalize(heat)
    return normalized~=nil and (#normalized==0 or Heat.Enabled==true)
end
function Policy.SameOptions(firstTier,firstHeat,secondTier,secondHeat)
    return ({Normal=true,Hard=true,Nightmare=true})[firstTier]==true
        and firstTier==secondTier and Heat.SameSelection(firstHeat,secondHeat)
end
function Policy.Profile(profiles,difficulty,heat)
    local base=type(difficulty)=='string' and profiles[difficulty]
    if not base then return nil end
    -- Composition can be inspected while rollout is disabled; admission must call ValidOptions.
    return Heat.ApplyDifficulty(base,heat)
end
function Policy.EnemyHealthScale(role,profile,heat)
    local rules=Heat.Rules(heat)
    if not rules or type(profile)~='table' then return nil end
    return role=='Grunt' and rules.gruntHealthScale or (profile.EliteHealthScale or 1)
end
return Policy
