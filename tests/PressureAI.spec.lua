return function()
    local P=require(game.ServerScriptService.NightfallServer.PressurePolicy)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local checks=0
    for name,profile in pairs(Config.Difficulties)do
        local p=profile.Pressure
        for _,case in ipairs({{{},10,.15,1},{{9.4},10,.15,2},{{9,9.5},10,.8,0},{{8.5,9.5},10,.8,0},{{8.499,9.5},10,.15,2},{{1,2},10,.15,1}})do
            local duration,hits,breaker=P.HitProtection(case[1],case[2],p)
            assert(duration==case[3] and #hits==case[4] and breaker==(duration==.8),name.." hit cluster")
            checks+=1
        end
        for _,case in ipairs({{10,9,0,11,true,0},{10,11,9.85,0,false,0},{10,11,9.8,0,true,8},{10,11,9.8,10.01,false,0},{10,11,9.8,10,true,8}})do
            local allowed,cost=P.Burst(case[1],case[2],case[3],case[4],p)
            assert(allowed==case[5] and cost==case[6],name.." Burst lock")
            checks+=1
        end
    end
    local Planner=require(game.ServerScriptService.NightfallServer.EnemyWavePlanner)
    local budgets=0
    for _,stage in ipairs(Config.Stages)do for _,wave in ipairs(stage.Waves)do
        local _,base=Planner.Plan(wave,1)
        if wave.Kind=="Wave"then assert(base>=5 and base<=8,"Authored pressure budget")end
        for party=1,4 do
            local _,total=Planner.Plan(wave,party)
            assert(total==base+(wave.Kind=="Wave" and 2*(party-1)or 0),"Two TOTAL extras per player")
            budgets+=1
        end
    end end
    return {pressureCases=checks,wavePartyCases=budgets}
end
