return function()
    local Config=require(game.ReplicatedStorage.Nightfall.Shared.Config)
    local Policy=require(game.ServerScriptService.NightfallServer.DifficultyPolicy)
    local Director=require(game.ServerScriptService.NightfallServer.AttackDirector)
    local normal=Config.Difficulties.Normal
    assert(Policy.Windup(.45,normal)==.45 and Policy.Cooldown(1.85,normal)==1.85,"Normal baseline changed")
    local quota={}
    for i=1,9 do assert(Policy.Evade(quota,normal)==(i%3==0),"Normal every-third-heavy quota")end
    local cases=0
    for name,profile in pairs(Config.Difficulties)do
        assert(Policy.ValidOptions(Config.Difficulties,name,{}) and Policy.ValidOptions(Config.Difficulties,name,nil),"Known profile")
        for _,base in ipairs({.10,.30,.40,.55,.90,1.40})do for _,heat in ipairs({1,.8,.01})do
            assert(Policy.Windup(base,profile,heat)>=.30,"Final post-difficulty/Heat warning floor")
            cases+=1
        end end
        for party=1,4 do assert(Director.Cap(party,profile.TokenBonus)==party+1+profile.TokenBonus,"Tier token budget")end
        assert(profile.ReactionDelay>=.15 and profile.EliteHealthScale>=1,"Bounded profile")
    end
    assert(Policy.Cooldown(2,Config.Difficulties.Hard)<2,"Hard aggression")
    assert(not Policy.ValidOptions(Config.Difficulties,"Forged",{}),"Unknown difficulty")
    for _,heat in ipairs({1,"bad",{Fast=true},{"Fast"}})do assert(not Policy.ValidOptions(Config.Difficulties,"Normal",heat),"Unimplemented Heat rejected")end
    return {warningFloorCases=cases,normalQuota=9,tiers=3,capCases=12,invalidOptions=5}
end
