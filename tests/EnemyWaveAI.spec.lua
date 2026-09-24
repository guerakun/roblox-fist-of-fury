return function()
    local Planner=require(game.ServerScriptService.NightfallServer.EnemyWavePlanner)
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local cases=0
    for _,stage in ipairs(Config.Stages)do for _,wave in ipairs(stage.Waves)do for party=1,4 do
        local pulses,total=Planner.Plan(wave,party)
        local expected,actual={},{}
        local expectedTotal=0
        for kind,count in pairs(wave.Enemies)do
            expected[kind]=count+(wave.Kind=="Wave" and math.floor((party-1)*.5) or 0)
            expectedTotal+=expected[kind]
        end
        local seen=0
        for _,pulse in ipairs(pulses)do
            assert(#pulse>0,"Empty reinforcement pulse")
            for _,entry in ipairs(pulse)do
                actual[entry.kind]=(actual[entry.kind] or 0)+1;seen+=1
                assert(table.find({"Left","Right","Door","Drop"},entry.entry),"Unknown entry")
            end
        end
        assert(total==expectedTotal and seen==total,"Frozen wave budget changed")
        for kind,count in pairs(expected)do assert(actual[kind]==count,"Archetype count changed")end
        if wave.Kind=="Wave" then
            assert(#pulses==(total>=6 and 3 or math.min(2,total)),"Skirmish pulse count")
            if party<=2 then assert(pulses[1][1].entry=="Left" and pulses[1][1].rear,"Small-party rear entry")end
        else
            assert(#pulses==1 and pulses[1][1].entry=="Door","Elite initial entrance; phase summons are separate")
        end
        cases+=1
    end end end
    assert(not Planner.ShouldSpawn(2,11.9,{After=12,AliveThreshold=1}),"Early pulse")
    assert(Planner.ShouldSpawn(1,0,{After=12,AliveThreshold=1}),"Alive threshold")
    assert(Planner.ShouldSpawn(9,12,{After=12,AliveThreshold=1}),"Timer reinforcement")
    assert(Planner.ShouldSpawn(0,0,{After=12,AliveThreshold=1}),"Empty current pulse must spawn pending enemies")
    return {wavePartyCases=cases,budgetsConserved=true,pulseTriggers=4}
end
