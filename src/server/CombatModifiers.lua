-- Normalize trusted profile modifiers at the combat boundary; all action enforcement remains server-side.
local Modifiers={}
local function number(value,default,minimum,maximum)
    if type(value)~="number"or value~=value or math.abs(value)==math.huge then return default end
    return math.clamp(value,minimum,maximum)
end
function Modifiers.Normalize(value)
    value=type(value)=="table"and value or {}
    return {damageMultiplier=number(value.damageMultiplier,1,1,1.5),knockbackMultiplier=number(value.knockbackMultiplier,1,1,1.5),
        moveSpeedBonus=number(value.moveSpeedBonus,0,0,6),damageReduction=number(value.damageReduction,0,0,.3),
        damageTakenMultiplier=number(value.damageTakenMultiplier,1,1,1.5),styleGainMultiplier=number(value.styleGainMultiplier,1,1,2),weightMultiplier=number(value.weightMultiplier,1,1,1.5),
        canBlock=value.canBlock~=false,canDash=value.canDash~=false}
end
function Modifiers.Incoming(damage,mods)return damage*(1-mods.damageReduction)*mods.damageTakenMultiplier end
function Modifiers.Weight(base,mods)return (base or 1)*mods.weightMultiplier end
return Modifiers
