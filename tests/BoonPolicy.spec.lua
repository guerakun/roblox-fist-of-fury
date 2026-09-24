return function(Policy,Config)
    local n=0 local function check(v)assert(v)n+=1 end
    for _,data in ipairs({false,'profile',{}, {boon='Guardian'}})do
        check(not Policy.Unlocked(Config,data,'Guardian'))
        check(Policy.Modifiers(Config,data).damageMultiplier==1)
    end
    check(not Policy.Unlocked(Config,nil,'Guardian'))
    for _,id in ipairs({'GlassCannon','Berserker','Anchor'})do
        local boon=assert(Config.FindBoon(id),'Missing planned trade-off boon')
        if boon.Enabled==false then
            local data={boon=id,xp=100000000,premium=true,coins=100000000,owned={[id]=true}}
            check(not Policy.Unlocked(Config,data,id))
            local m=Policy.Modifiers(Config,data)
            check(m.damageMultiplier==1 and m.damageTakenMultiplier==1 and m.styleGainMultiplier==1 and m.weightMultiplier==1 and m.canBlock and m.canDash)
        end
        -- Isolate configured values from the rollout gate; actual combat remains a separate test.
        local available=table.clone(boon);available.Enabled=true
        local staged={FindBoon=function(key)return key==id and available or nil end}
        check(not Policy.Unlocked(staged,{xp=boon.XP-1},id))
        check(Policy.Unlocked(staged,{xp=boon.XP},id))
        local m=Policy.Modifiers(staged,{boon=id,xp=boon.XP})
        if id=='GlassCannon'then check(m.damageMultiplier==1.2 and m.damageTakenMultiplier==1.2 and m.canBlock and m.canDash)
        elseif id=='Berserker'then check(m.styleGainMultiplier==2 and not m.canBlock and m.canDash and m.damageMultiplier==1)
        else check(m.weightMultiplier==1.3 and not m.canDash and m.canBlock and m.damageMultiplier==1)end
    end
    local neutral=Policy.Modifiers(Config,nil)
    check(neutral.damageMultiplier==1 and neutral.damageTakenMultiplier==1 and neutral.canBlock and neutral.canDash)
    for _,boon in ipairs(Config.Boons)do
        if boon.Enabled~=false then
            local data={boon=boon.Id,xp=boon.XP,premium=false,coins=0}
            check(Policy.Unlocked(Config,data,boon.Id))
            local m=Policy.Modifiers(Config,data)
            check(m.damageMultiplier==(boon.DamageMultiplier or 1))
            check(m.damageTakenMultiplier==(boon.DamageTakenMultiplier or 1))
            check(m.styleGainMultiplier==(boon.StyleGainMultiplier or 1))
            check(m.weightMultiplier==(boon.WeightMultiplier or 1))
            check(m.canBlock==(boon.CanBlock~=false) and m.canDash==(boon.CanDash~=false))
            if boon.XP>0 then
                data.xp=boon.XP-1;data.coins=100000000;data.premium=true
                check(not Policy.Unlocked(Config,data,boon.Id))
                m=Policy.Modifiers(Config,data)
                check(m.damageMultiplier==1 and m.styleGainMultiplier==1 and m.canBlock and m.canDash)
            end
        end
    end
    for _,xp in ipairs({-1,0/0,math.huge,'1000'})do
        check(not Policy.Unlocked(Config,{xp=xp},'Guardian'))
    end
    check(not Policy.Unlocked(Config,{xp=100000000},'ForgedBoon'))
    local forged=Policy.Modifiers(Config,{xp=100000000,boon='ForgedBoon',damageMultiplier=999})
    check(forged.damageMultiplier==1 and forged.canBlock)
    return {passed=true,checks=n,scope='earned-only unlock and modifier policy; actual combat restrictions require runtime checks'}
end
