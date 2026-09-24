return function(Policy,Config,Heat,Director)
    local n=0 local function check(v)assert(v)n+=1 end
    for mask=0,63 do
        local selected={}
        for i,id in ipairs(Heat.Order)do if bit32.band(mask,2^(i-1))~=0 then table.insert(selected,id)end end
        local rules=Heat.Rules(selected)
        for name,base in pairs(Config.Difficulties)do
            local windup,tokens=base.WindupScale,base.TokenBonus
            local p=Policy.Profile(Config.Difficulties,name,selected)
            check(p~=base and p.Pressure==base.Pressure)
            check(p.TokenBonus==tokens+rules.tokenBonus and p.WindupScale==windup*rules.windupScale)
            check(base.TokenBonus==tokens and base.WindupScale==windup)
            check(Policy.EnemyHealthScale('Grunt',p,selected)==rules.gruntHealthScale)
            check(Policy.EnemyHealthScale('Boss',p,selected)==base.EliteHealthScale)
            for party=1,4 do check(Director.Cap(party,p.TokenBonus)==party+1+tokens+rules.tokenBonus)end
            for _,value in ipairs({.1,.3,.4,.9})do check(Policy.Windup(value,p)>=.3)end
            check(Policy.ValidOptions(Config.Difficulties,name,selected)==(#selected==0 or Heat.Enabled==true))
        end
    end
    check(Policy.SameOptions('Hard',{'Frenzy','OneLife'},'Hard',{'OneLife','Frenzy'}))
    check(not Policy.SameOptions('Hard',{},'Normal',{}))
    check(not Policy.SameOptions('Normal',{'Frenzy'},'Normal',{}))
    check(not Policy.SameOptions('Forged',{},'Forged',{}))
    check(not Policy.SameOptions('Normal',{'Frenzy','Frenzy'},'Normal',{'Frenzy'}))
    check(Policy.Profile(Config.Difficulties,'Forged',{})==nil)
    check(Policy.Profile(Config.Difficulties,'Normal',{'Forged'})==nil)
    check(Policy.EnemyHealthScale('Grunt',{}, {'Forged'})==nil)
    return {passed=true,checks=n,combinations=64,tiers=3,productionHeatEnabled=Heat.Enabled,scope='profile composition/admission math; actual enemy effects and immutable options require integration tests'}
end
