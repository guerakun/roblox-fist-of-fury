return function()
    local Policy=require(game.ServerScriptService.NightfallServer.SurvivalPolicy)
    local cfg=require(game.ReplicatedStorage.Nightfall.Shared.Config).Survival
    local checks=0
    for _,cap in ipairs({1,3})do
        for stocks=0,3 do
            local s,p=Policy.Reset("Travel",stocks,78,cfg,cap)
            assert(s==math.min(stocks,cap)and p==78);checks+=1
            s,p=Policy.Reset("Clear",stocks,78,cfg,cap)
            assert(s==math.min(stocks+1,cap)and p==63);checks+=1
            s,p=Policy.Reset("Retry",stocks,78,cfg,cap)
            assert(s==math.min(2,cap)and p==0);checks+=1
            s,p=Policy.Reset("Campaign",stocks,78,cfg,cap)
            assert(s==math.min(3,cap)and p==0);checks+=1
        end
    end
    local _,percent=Policy.Reset("Clear",2,10,cfg,3);assert(percent==0)
    assert(Policy.CanChannel(10,12,8,1.5,false,true))
    for _,case in ipairs({{12,12,1,0,false,true},{10,12,8.01,0,false,true},{10,12,1,1.51,false,true},{10,12,1,0,true,true},{10,12,1,0,false,false}})do
        assert(not Policy.CanChannel(table.unpack(case)));checks+=1
    end
    return {passed=true,survivalCases=checks+2,oneLifePolicyOnly=true}
end
