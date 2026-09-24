-- Earned profile XP is the only unlock input. Paid ownership is deliberately irrelevant.
local Policy={}
function Policy.Unlocked(config,data,id)
    if type(data)~='table' or type(data.xp)~='number' or data.xp~=data.xp or data.xp<0 or data.xp==math.huge then return false end
    local boon=config.FindBoon(id)
    return boon~=nil and boon.Enabled~=false and data.xp>=boon.XP
end
function Policy.Modifiers(config,data)
    local result={damageMultiplier=1,knockbackMultiplier=1,moveSpeedBonus=0,damageReduction=0,
        damageTakenMultiplier=1,styleGainMultiplier=1,weightMultiplier=1,canBlock=true,canDash=true}
    if type(data)~='table' or not Policy.Unlocked(config,data,data.boon)then return result end
    local boon=config.FindBoon(data.boon)
    result.damageMultiplier=boon.DamageMultiplier or 1
    result.moveSpeedBonus=boon.MoveSpeedBonus or 0
    result.damageReduction=boon.DamageReduction or 0
    result.damageTakenMultiplier=boon.DamageTakenMultiplier or 1
    result.styleGainMultiplier=boon.StyleGainMultiplier or 1
    result.weightMultiplier=boon.WeightMultiplier or 1
    result.canBlock=boon.CanBlock~=false
    result.canDash=boon.CanDash~=false
    return result
end
return Policy
