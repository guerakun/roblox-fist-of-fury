return function()
    local D=require(game.ServerScriptService.NightfallServer.DeparturePreparation)
    local a,b={},{}local profiles={[a]={open=true},[b]={open=true}}local calls,fail=0,true
    local d=D.new({profile=function(p)return profiles[p]end,canMutate=function(p)return p.open end,
        release=function(p)calls+=1 p.open=false if p==profiles[b]and fail then fail=false return false end return true end})
    assert(not pcall(function()d:Prepare({a,b},'match')end),'second release fails')
    assert(d.owned[a].released and not d.owned[b].released,'first release retained')
    assert(d:Prepare({a,b},'match')and calls==3,'retry skips released member and completes closing member')
    assert(not pcall(function()d:Prepare({a},'other')end),'different departure cannot reuse released profile')
    d:Clear(a)assert(not d.owned[a],'departed cleanup')
    return 'PASS: whole-batch preflight, second-release failure/resume, first release not repeated, conflicting deployment rejected'
end
