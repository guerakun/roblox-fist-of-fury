return function(Policy)
    local checks = 0
    local function check(value) assert(value); checks += 1 end
    local base = {coins = 230, xp = 265}
    for rank, multiplier in pairs(Policy.Ranks) do
        local r = Policy.Bonus(base, rank, 'Normal', 0)
        check(r.coins == math.floor(230 * (multiplier - 1) + 1e-7))
        check(r.xp == math.floor(265 * (multiplier - 1) + 1e-7))
    end
    local maximum = Policy.Bonus(base, 'S', 'Nightmare', 105)
    check(maximum.coins == 689 and maximum.xp == 794)
    local late = Policy.Bonus({coins=120,xp=120}, 'S', 'Normal', 0)
    check(late.coins == 60 and late.xp == 60)
    for _, invalid in ipairs({-1, 106, math.huge, 0/0, '105'}) do check(Policy.Bonus(base, 'S', 'Normal', invalid) == nil) end
    check(Policy.Bonus(base, 'forged', 'Normal', 0) == nil)
    check(Policy.Bonus(base, 'S', 'forged', 0) == nil)
    check(Policy.Bonus({coins=-1,xp=265}, 'S', 'Normal', 0) == nil)
    local data, keys, order = {coins=0,xp=0}, {}, {}
    local r = Policy.Grant(data,keys,order,'campaign:1:rank',115,132)
    check(r.coins==115 and r.xp==132 and r.status=='paid')
    check(Policy.Grant(data,keys,order,'campaign:1:rank',500,500)==nil)
    check(data.coins==115 and data.xp==132)
    check(Policy.Grant(data,keys,order,'forged',-1,10)==nil)
    check(not keys.forged)
    data.coins, data.xp = Policy.Cap-2, Policy.Cap-1
    r = Policy.Grant(data,keys,order,'campaign:2:rank',115,132)
    check(r.coins==2 and r.xp==1 and r.status=='capped')
    check(Policy.Grant(data,keys,order,'campaign:2:rank',115,132)==nil)
    local big = Policy.Bonus({coins=Policy.Cap,xp=Policy.Cap}, 'S', 'Nightmare', 105)
    local fresh, seen, log = {coins=0,xp=0}, {}, {}
    check(Policy.Grant(fresh,seen,log,'maximum',big.coins,big.xp).status=='capped')
    for i=1,1023 do check(Policy.Grant(fresh,seen,log,'key:'..i,0,0)~=nil)end
    check(Policy.Grant(fresh,seen,log,'maximum',1,1)==nil)
    local overflow, reason = Policy.Grant(fresh,seen,log,'overflow',1,1)
    check(overflow==nil and reason=='capacity' and not seen.overflow)
    return {passed=true,checks=checks,scope='pure arithmetic and key deduplication; not Progression runtime'}
end
