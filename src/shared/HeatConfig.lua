-- Earned risk/reward only. Shared metadata; all options are validated again on the server.
local Heat = {}
Heat.Order = {'Frenzy','ShortFuse','IronHide','NoSafetyNet','OneLife','MutatedElites'}
Heat.Contracts = {
    Frenzy={Id='Frenzy',Name='FRENZY',Description='One extra attack token',Points=1,RewardPercent=10},
    ShortFuse={Id='ShortFuse',Name='SHORT FUSE',Description='Enemy warnings 20% faster; minimum 0.30 s',Points=2,RewardPercent=15},
    IronHide={Id='IronHide',Name='IRON HIDE',Description='Ordinary enemies take 30% more to KO',Points=2,RewardPercent=10},
    NoSafetyNet={Id='NoSafetyNet',Name='NO SAFETY NET',Description='Retry at the district entrance',Points=3,RewardPercent=20},
    OneLife={Id='OneLife',Name='ONE LIFE',Description='One stock; sharing disabled; channel revive available',Points=5,RewardPercent=35},
    MutatedElites={Id='MutatedElites',Name='MUTATED ELITES',Description='Bosses gain an extra phase-two move',Points=2,RewardPercent=15},
}
function Heat.Normalize(value)
    if value == nil then return {} end
    if type(value) ~= 'table' then return nil, 'Heat must be a list' end
    local count, seen, result = 0, {}, {}
    for key,id in pairs(value) do
        count += 1
        if count > 6 or type(key) ~= 'number' or key % 1 ~= 0 or key < 1 or key > 6
            or type(id) ~= 'string' or not Heat.Contracts[id] or seen[id] then return nil, 'Invalid Heat selection' end
        seen[id] = true
    end
    for i = 1,count do if value[i] == nil then return nil, 'Heat must be a dense list' end end
    for _,id in ipairs(Heat.Order) do if seen[id] then table.insert(result,id) end end
    return result
end
function Heat.Rules(value)
    local ids, reason = Heat.Normalize(value)
    if not ids then return nil, reason end
    local rules = {ids=ids,set={},points=0,rewardPercent=0,tokenBonus=0,windupScale=1,gruntHealthScale=1,
        stockCap=3,stockSharing=true,midCheckpoint=true,mutatedElites=false}
    for _,id in ipairs(ids) do
        rules.set[id] = true
        rules.points += Heat.Contracts[id].Points
        rules.rewardPercent += Heat.Contracts[id].RewardPercent
    end
    if rules.set.Frenzy then rules.tokenBonus=1 end
    if rules.set.ShortFuse then rules.windupScale=.8 end
    if rules.set.IronHide then rules.gruntHealthScale=1.3 end
    if rules.set.NoSafetyNet then rules.midCheckpoint=false end
    if rules.set.OneLife then rules.stockCap=1 rules.stockSharing=false end
    rules.mutatedElites = rules.set.MutatedElites == true
    return rules
end
function Heat.ApplyDifficulty(base,value)
    local rules = Heat.Rules(value)
    if type(base) ~= 'table' or not rules then return nil end
    local result = table.clone(base)
    result.TokenBonus = (base.TokenBonus or 0) + rules.tokenBonus
    result.WindupScale = (base.WindupScale or 1) * rules.windupScale
    return result
end
function Heat.Unlocked(completed,difficulty)
    completed = type(completed)=='table' and completed or {}
    return difficulty=='Normal' or difficulty=='Hard' and completed.Normal==true
        or difficulty=='Nightmare' and completed.Hard==true
end
return Heat
