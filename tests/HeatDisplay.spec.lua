-- Shared Heat metadata/UI intent gate; true-Enabled copy is test-only.
return function(Display,Heat)
    Display=Display or require(game.ServerScriptService.HeatDisplay)
    Heat=Heat or require(game.ReplicatedStorage.Nightfall.Shared.HeatConfig)
    local productionEnabled=Heat.Enabled
    local count=0 local function check(value)assert(value)count+=1 end
    local fixture={Enabled=true,Order=table.clone(Heat.Order),Contracts=Heat.Contracts}
    local definitions=Display.Definitions(Heat)check(#definitions==6)
    local selected={Unknown=true}
    local none=Display.Summary(fixture,selected)check(#none.ids==0 and none.points==0 and none.rewardPercent==0)
    for index,definition in ipairs(definitions)do
        local source=Heat.Contracts[Heat.Order[index]]
        check(definition.id==source.Id and definition.name==source.Name and definition.description==source.Description
            and definition.points==source.Points and definition.reward==source.RewardPercent)
        check(Display.Toggle(fixture,selected,definition.id,true,false))
        check(string.find(Display.Label(fixture,definition),tostring(source.Points).." HEAT",1,true)~=nil)
    end
    local all=Display.Summary(fixture,selected)check(#all.ids==6 and all.points==15 and all.rewardPercent==105)
    check(not Display.Toggle(fixture,selected,"Frenzy",false,false)and selected.Frenzy)
    check(not Display.Toggle(fixture,selected,"Frenzy",true,true)and selected.Frenzy)
    check(not Display.Toggle(fixture,selected,"Unknown",true,false))
    check(Display.Toggle(fixture,selected,"Frenzy",true,false)and selected.Frenzy==false)
    local changed=Display.Summary(fixture,selected)check(changed.points==14 and changed.rewardPercent==95 and #changed.ids==5)
    local disabled={Enabled=false,Order=fixture.Order,Contracts=fixture.Contracts}
    check(not Display.Toggle(disabled,selected,"Frenzy",true,false))
    check(#Display.Summary(disabled,selected).ids==0)
    for _,definition in ipairs(definitions)do check(Display.Label(disabled,definition)==definition.name.." / NOT AVAILABLE")end
    check(Heat.Enabled==productionEnabled,"Fixture must not change production Heat")
    return {passed=true,checks=count,definitions=6,allPoints=15,allRewardPercent=105,disabledGate=true,leaderQueueGates=true,productionEnabled=Heat.Enabled}
end
